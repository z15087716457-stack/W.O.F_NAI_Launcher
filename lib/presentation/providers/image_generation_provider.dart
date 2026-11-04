import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import '../../data/models/image/image_operation.dart';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:image/image.dart' as img;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/anlas_calculator.dart';
import '../../core/utils/localization_extension.dart';
import 'generation/image_workflow_controller.dart';
import 'generation/local_upscale_provider.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/image_save_utils.dart';
import '../../core/utils/image_share_sanitizer.dart';
import '../../core/utils/inpaint_mask_utils.dart';
import '../../core/utils/nai_resolution_adapter.dart';
import '../../core/utils/pica_lanczos_resizer.dart';
import '../../core/utils/prompt_input_normalization.dart';
import '../../core/utils/prompt_preset_resolution.dart';
import '../../core/services/character_conversion_service.dart';
import '../../data/services/image_metadata_service.dart';
import '../../data/models/upscale/local_upscale_models.dart';
import '../../data/datasources/remote/nai_image_generation_api_service.dart';
import '../../data/models/character/character_prompt.dart' as ui_character;

import '../../data/models/gallery/nai_image_metadata.dart';
import '../../data/models/image/image_params.dart';
import '../../data/models/image/image_stream_chunk.dart';
import '../../data/repositories/gallery_folder_repository.dart';
import '../../data/services/statistics_cache_service.dart';
import '../../data/services/alias_resolver_service.dart';
import 'character_prompt_provider.dart';
import 'auth_provider.dart';
import 'image_save_settings_provider.dart';
import 'local_gallery_provider.dart';
import 'pill_roll_coordinator.dart';
import 'pill_workspace_provider.dart';
import 'quality_preset_provider.dart';
import 'uc_preset_provider.dart';

import 'generation/generation_models.dart';
import 'generation/generation_retry_policy.dart';
import 'generation/generation_cooldown_provider.dart';
import 'generation/generation_params_notifier.dart';
import 'generation/generation_settings_notifiers.dart';

export 'generation/generation_models.dart';
export 'generation/generation_cooldown_provider.dart';
export 'generation/generation_params_notifier.dart';
export 'generation/generation_auxiliary_notifiers.dart';
export 'generation/generation_settings_notifiers.dart';
export 'generation/reference_panel_notifier.dart';

// Simplified ImageGenerationProvider - new exports
export 'generation/image_generation_service.dart';
export 'generation/batch_generation_notifier.dart';
export 'generation/stream_generation_notifier.dart';
export 'generation/metadata_preload_notifier.dart';
export 'generation/retry_policy_notifier.dart';

part 'image_generation_provider.g.dart';

class GenerationRetryRequest {
  const GenerationRetryRequest({
    required this.params,
    required this.count,
    required this.workflow,
    required this.accountId,
    this.operation,
    this.original,
    this.rejectedBatches,
  });
  final ImageParams params;
  final int count;
  final ImageWorkflowState workflow;
  final String? accountId;
  final ImageOperation? operation;
  final GeneratedImage? original;

  /// 停下之前已经被 NovelAI 拒绝（400）、跳过的请求。重试只补没发出去的，跳过
  /// 的那几次不再发；重试补完了，画布照样说明跳过了几次。
  final GenerationRejectedBatches? rejectedBatches;

  /// 换成 [value] 这组参数；[rejectedBatches] 不传就照旧。
  GenerationRetryRequest withParams(
    ImageParams value, {
    GenerationRejectedBatches? rejectedBatches,
  }) => GenerationRetryRequest(
    params: value,
    count: count,
    workflow: workflow,
    accountId: accountId,
    operation: operation,
    original: original,
    rejectedBatches: rejectedBatches ?? this.rejectedBatches,
  );
}

typedef _BatchStreamResult = ({
  Iterable<(int, Uint8List)> images,
  Object? interruption,
});

class _RememberedStreamPreview {
  const _RememberedStreamPreview({
    required this.bytes,
    required this.params,
    this.inpaintPreviewPlacement,
  });

  final Uint8List bytes;
  final ImageParams params;
  final InpaintStreamPreviewPlacement? inpaintPreviewPlacement;
}

/// 图像生成状态 Notifier
@Riverpod(keepAlive: true)
class ImageGenerationNotifier extends _$ImageGenerationNotifier {
  @override
  ImageGenerationState build() {
    return const ImageGenerationState();
  }

  void _retainSharePreparationCacheForCurrentHistory() {
    final retainedImageIds = <String>{
      for (final image in state.currentImages) image.id,
      for (final image in state.history) image.id,
    };
    unawaited(
      ShareImagePreparationService.instance.retainHistoryImageIds(
        retainedImageIds,
      ),
    );
  }

  /// 生成图像
  /// 重试延迟策略 (毫秒)
  static const List<int> _retryDelays = [1000, 2000, 4000];
  static const int _maxRetries = 3;
  static const int _randomSeedExclusiveUpperBound = 4294967295;

  bool _isCancelled = false;
  int _generationRunCounter = 0;
  int _activeGenerationRunId = 0;
  ImageOperation? _activeImageOperation;
  UpscaleWorkflowSettings? _activeLocalEnhance;
  GenerationRetryRequest? _lastRequest;
  GenerationRetryRequest? get lastRequest =>
      state.isExploreRun ? null : _lastRequest;

  Future<void> retry(GenerationRetryRequest request) => _generate(
    request.params,
    imagesPerRequestOverride: request.count,
    operation: request.operation,
    variationOriginal: request.original,
    workflowOverride: request.workflow,
    preserveSnapshot: true,
    rejectedBefore: request.rejectedBatches,
  );
  List<GeneratedImage> _pendingLocalEnhanceImages = [];
  final Map<String, _RememberedStreamPreview> _streamPreviewsForSnapshots =
      <String, _RememberedStreamPreview>{};
  final Set<String> _failedStreamSnapshotKeys = <String>{};

  int _startGenerationRun({ImageOperation? operation}) {
    _activeImageOperation = operation;
    _activeLocalEnhance = null;
    _pendingLocalEnhanceImages = [];
    _isCancelled = false;
    _activeGenerationRunId = ++_generationRunCounter;
    _streamPreviewsForSnapshots.clear();
    _failedStreamSnapshotKeys.clear();
    return _activeGenerationRunId;
  }

  void _invalidateGenerationRun() {
    _isCancelled = true;
    _activeGenerationRunId = ++_generationRunCounter;
    _interruptRetryWait();
  }

  /// 正在等的那次重试的取消信号：取消时立刻醒来，不等满这一段。
  /// 每次等待用自己的，等完就放掉，不在常驻的 notifier 上越攒越多。
  Completer<void>? _retryWaitInterrupt;

  Future<void> _waitBeforeRetry(Duration delay) async {
    final interrupt = Completer<void>();
    _retryWaitInterrupt = interrupt;
    try {
      // 换掉的等待（测试替身）不一定理会取消信号，取消时也照样醒。
      await Future.any<void>([
        ref.read(generationRetryDelayProvider)(delay, interrupt.future),
        interrupt.future,
      ]);
    } finally {
      if (identical(_retryWaitInterrupt, interrupt)) {
        _retryWaitInterrupt = null;
      }
    }
  }

  void _interruptRetryWait() {
    final interrupt = _retryWaitInterrupt;
    _retryWaitInterrupt = null;
    if (interrupt != null && !interrupt.isCompleted) interrupt.complete();
  }

  bool _isCurrentGenerationRun(int generationRunId) =>
      generationRunId == _activeGenerationRunId;

  bool _shouldAbortGenerationRun(int generationRunId) =>
      _isCancelled || !_isCurrentGenerationRun(generationRunId);

  Future<void> _emitBatchEvent(
    GenerationBatchCallback? callback,
    GenerationBatchEvent event,
  ) async {
    if (callback == null) return;
    try {
      await callback(event);
    } catch (error, stackTrace) {
      AppLogger.e(
        'Generation batch callback failed',
        error,
        stackTrace,
        'Generation',
      );
    }
  }

  Future<void> _emitBatchComplete({
    required GenerationBatchCallback? callback,
    required Set<int> completedBatches,
    required int generationRunId,
    required int batchIndex,
    required int slotStart,
    required int slotCount,
    required int totalSlots,
    List<GeneratedImage> images = const [],
    Object? error,
    int? elapsedMs,
  }) async {
    if (!completedBatches.add(batchIndex)) return;
    await _emitBatchEvent(
      callback,
      GenerationBatchEvent(
        kind: GenerationBatchEventKind.complete,
        generationRunId: generationRunId,
        batchIndex: batchIndex,
        slotStart: slotStart,
        slotCount: slotCount,
        totalSlots: totalSlots,
        images: images,
        error: error,
        elapsedMs: elapsedMs,
      ),
    );
  }

  Future<void> _emitCancelledBatchEvents({
    required GenerationBatchCallback? callback,
    required Set<int> completedBatches,
    required int generationRunId,
    required int firstBatch,
    required int batchCount,
    required int batchSize,
    required int totalSlots,
  }) => _emitUnfinishedBatchEvents(
    callback: callback,
    completedBatches: completedBatches,
    generationRunId: generationRunId,
    firstBatch: firstBatch,
    batchCount: batchCount,
    batchSize: batchSize,
    totalSlots: totalSlots,
    error: 'cancelled',
  );

  /// 从 [firstBatch] 起还没结束的批次都发一个带 [error] 的结束事件。
  Future<void> _emitUnfinishedBatchEvents({
    required GenerationBatchCallback? callback,
    required Set<int> completedBatches,
    required int generationRunId,
    required int firstBatch,
    required int batchCount,
    required int batchSize,
    required int totalSlots,
    required Object error,
  }) async {
    if (callback == null) return;
    for (var batch = firstBatch; batch < batchCount; batch++) {
      await _emitBatchComplete(
        callback: callback,
        completedBatches: completedBatches,
        generationRunId: generationRunId,
        batchIndex: batch,
        slotStart: batch * batchSize + 1,
        slotCount: batchSize,
        totalSlots: totalSlots,
        error: error,
      );
    }
  }

  ImageParams _materializeRandomSeed(ImageParams params) {
    if (params.seed != -1) return params;

    return params.copyWith(
      seed: Random().nextInt(_randomSeedExclusiveUpperBound),
    );
  }

  String _streamSnapshotKey(int generationRunId, int imageNumber) =>
      '$generationRunId:$imageNumber';

  void _rememberStreamPreview({
    required Uint8List bytes,
    required ImageParams params,
    required int generationRunId,
    required int imageNumber,
    InpaintStreamPreviewPlacement? inpaintPreviewPlacement,
  }) {
    if (_shouldAbortGenerationRun(generationRunId) || bytes.isEmpty) {
      return;
    }

    _streamPreviewsForSnapshots[_streamSnapshotKey(
      generationRunId,
      imageNumber,
    )] = _RememberedStreamPreview(
      bytes: Uint8List.fromList(bytes),
      params: params,
      inpaintPreviewPlacement: inpaintPreviewPlacement?.copyWith(
        sourceImage: Uint8List.fromList(inpaintPreviewPlacement.sourceImage),
        maskImage: inpaintPreviewPlacement.maskImage == null
            ? null
            : Uint8List.fromList(inpaintPreviewPlacement.maskImage!),
      ),
    );
  }

  void _clearRememberedStreamPreview({int? generationRunId, int? imageNumber}) {
    if (generationRunId != null && imageNumber != null) {
      _streamPreviewsForSnapshots.remove(
        _streamSnapshotKey(generationRunId, imageNumber),
      );
      return;
    }

    _streamPreviewsForSnapshots.clear();
  }

  bool _appendFailedStreamSnapshotToHistory({
    required int generationRunId,
    required int imageNumber,
  }) {
    if (!_isCurrentGenerationRun(generationRunId)) return false;

    final key = _streamSnapshotKey(generationRunId, imageNumber);
    final rememberedPreview = _streamPreviewsForSnapshots[key];
    if (rememberedPreview == null || rememberedPreview.bytes.isEmpty) {
      return false;
    }
    if (!_failedStreamSnapshotKeys.add(key)) return false;

    final previewBytes = _materializeRememberedStreamPreview(rememberedPreview);
    final params = rememberedPreview.params;
    final resolvedSize =
        _resolveImageSize(
          previewBytes,
          width: rememberedPreview.inpaintPreviewPlacement == null
              ? params.width
              : null,
          height: rememberedPreview.inpaintPreviewPlacement == null
              ? params.height
              : null,
        ) ??
        (params.width, params.height);
    final snapshot = GeneratedImage.create(
      previewBytes,
      width: resolvedSize.$1,
      height: resolvedSize.$2,
      kind: GeneratedImageKind.failedStreamSnapshot,
      sourceParams: params,
      operation: _activeImageOperation,
      metadata: _metadataFromParams(
        params,
        outputWidth: resolvedSize.$1,
        outputHeight: resolvedSize.$2,
      ),
      generationRunId: generationRunId,
      batchIndex: imageNumber - 1,
    );

    state = state.copyWith(
      history: [snapshot, ...state.history],
      clearStreamPreview: true,
    );
    _retainSharePreparationCacheForCurrentHistory();
    _clearRememberedStreamPreview(
      generationRunId: generationRunId,
      imageNumber: imageNumber,
    );
    return true;
  }

  Uint8List _materializeRememberedStreamPreview(
    _RememberedStreamPreview rememberedPreview,
  ) {
    final placement = rememberedPreview.inpaintPreviewPlacement;
    if (placement == null || !placement.isValid) {
      return rememberedPreview.bytes;
    }

    final materialized = _compositeInpaintStreamPreview(
      previewBytes: rememberedPreview.bytes,
      inpaintPreviewPlacement: placement,
    );
    return materialized ?? rememberedPreview.bytes;
  }

  Uint8List? _compositeInpaintStreamPreview({
    required Uint8List previewBytes,
    required InpaintStreamPreviewPlacement inpaintPreviewPlacement,
  }) {
    final source = img.decodeImage(inpaintPreviewPlacement.sourceImage);
    final preview = img.decodeImage(previewBytes);
    final mask = inpaintPreviewPlacement.maskImage == null
        ? null
        : img.decodeImage(inpaintPreviewPlacement.maskImage!);
    if (source == null || preview == null) {
      return null;
    }

    final dstX = (inpaintPreviewPlacement.xPercent * source.width)
        .round()
        .clamp(0, max(0, source.width - 1))
        .toInt();
    final dstY = (inpaintPreviewPlacement.yPercent * source.height)
        .round()
        .clamp(0, max(0, source.height - 1))
        .toInt();
    final dstW = (inpaintPreviewPlacement.widthPercent * source.width)
        .round()
        .clamp(1, max(1, source.width - dstX))
        .toInt();
    final dstH = (inpaintPreviewPlacement.heightPercent * source.height)
        .round()
        .clamp(1, max(1, source.height - dstY))
        .toInt();

    final img.Image resizedPreview;
    final img.Image? resizedMask;
    if (mask == null) {
      resizedPreview = PicaLanczosResizer.resizeImage(
        preview,
        width: dstW,
        height: dstH,
      );
      resizedMask = null;
    } else {
      final requestPreview = PicaLanczosResizer.resizeImage(
        preview,
        width: mask.width,
        height: mask.height,
      );
      final requestPatch = InpaintMaskUtils.applyCompositeMaskToGeneratedImage(
        requestPreview,
        mask,
      );
      resizedPreview = PicaLanczosResizer.resizeImage(
        requestPatch,
        width: dstW,
        height: dstH,
      );
      resizedMask = null;
    }
    final composed = img.Image.from(source, noAnimation: true);
    img.compositeImage(
      composed,
      resizedPreview,
      dstX: dstX,
      dstY: dstY,
      dstW: dstW,
      dstH: dstH,
      mask: resizedMask,
      blend: mask == null ? img.BlendMode.direct : img.BlendMode.alpha,
    );

    return Uint8List.fromList(img.encodePng(composed, level: 1));
  }

  bool _appendFailedStreamSnapshotsForCurrentSlots(int generationRunId) {
    var appended = false;
    final slots = state.streamPreviewSlots;
    if (slots.isNotEmpty) {
      for (final slot in slots.reversed) {
        appended =
            _appendFailedStreamSnapshotToHistory(
              generationRunId: generationRunId,
              imageNumber: slot.imageNumber,
            ) ||
            appended;
      }
      return appended;
    }

    if (state.currentImage > 0) {
      appended = _appendFailedStreamSnapshotToHistory(
        generationRunId: generationRunId,
        imageNumber: state.currentImage,
      );
    }
    return appended;
  }

  List<StreamPreviewSlot> _replaceStreamPreviewSlot(
    List<StreamPreviewSlot> slots,
    StreamPreviewSlot replacement,
  ) {
    var replaced = false;
    final updated = <StreamPreviewSlot>[
      for (final slot in slots)
        if (slot.imageNumber == replacement.imageNumber) replacement else slot,
    ];
    replaced = slots.any((slot) => slot.imageNumber == replacement.imageNumber);
    if (!replaced) updated.add(replacement);

    return updated..sort((a, b) => a.imageNumber.compareTo(b.imageNumber));
  }

  NaiImageMetadata _metadataFromParams(
    ImageParams params, {
    int? outputWidth,
    int? outputHeight,
  }) {
    assert(
      (outputWidth == null) == (outputHeight == null),
      'Output width and height must be provided together.',
    );
    final metadataParams = outputWidth != null && outputHeight != null
        ? params.copyWith(width: outputWidth, height: outputHeight)
        : params;
    final (charCaptions, charNegCaptions) = _buildCharacterCaptions(
      metadataParams,
    );
    final commentJson = ImageSaveUtils.buildCommentJson(
      params: metadataParams,
      actualSeed: metadataParams.seed,
      charCaptions: charCaptions,
      charNegCaptions: charNegCaptions,
      useCoords: metadataParams.useCoords,
    );
    final rawJson = jsonEncode(commentJson);
    return NaiImageMetadata.fromNaiComment({
      'Comment': rawJson,
      'Software': 'NovelAI',
      'Source': _modelSourceName(metadataParams.model),
    }, rawJson: rawJson);
  }

  (
    List<Map<String, dynamic>> charCaptions,
    List<Map<String, dynamic>> charNegCaptions,
  )
  _buildCharacterCaptions(ImageParams params) {
    final charCaptions = <Map<String, dynamic>>[];
    final charNegCaptions = <Map<String, dynamic>>[];

    for (final char in params.characters) {
      final useCharacterPosition =
          params.useCoords && char.positionX != null && char.positionY != null;
      final x = useCharacterPosition ? char.positionX!.clamp(0.0, 1.0) : 0.5;
      final y = useCharacterPosition ? char.positionY!.clamp(0.0, 1.0) : 0.5;
      charCaptions.add({
        'char_caption': char.prompt,
        'centers': [
          {'x': x, 'y': y},
        ],
      });
      charNegCaptions.add({
        'char_caption': char.negativePrompt,
        'centers': [
          {'x': x, 'y': y},
        ],
      });
    }

    return (charCaptions, charNegCaptions);
  }

  String _modelSourceName(String model) {
    if (model.contains('diffusion-5')) {
      if (model.contains('curated')) {
        return 'NovelAI Diffusion V5 Curated';
      }
      return 'NovelAI Diffusion V5 Full';
    }
    if (model.contains('diffusion-4-5')) {
      if (model.contains('curated')) {
        return 'NovelAI Diffusion V4.5 Curated';
      }
      return 'NovelAI Diffusion V4.5 Full';
    }
    if (model.contains('diffusion-4')) {
      if (model.contains('curated')) {
        return 'NovelAI Diffusion V4 Curated';
      }
      return 'NovelAI Diffusion V4 Full';
    }
    if (model.contains('furry') && model.contains('-3')) {
      return 'NovelAI Furry Diffusion V3';
    }
    if (model.contains('diffusion-3')) {
      return 'NovelAI Diffusion V3';
    }
    if (model.contains('diffusion-2')) {
      return 'NovelAI Diffusion V2';
    }
    if (model.contains('furry')) {
      return 'NovelAI Furry Diffusion';
    }
    return 'NovelAI';
  }

  Future<ImageParams> _prepareVibesForGeneration(
    ImageParams params, {
    bool syncCurrentState = true,
  }) async {
    if (!AnlasCalculator.usesVibeReferences(params)) {
      return params;
    }

    final notifier = ref.read(generationParamsNotifierProvider.notifier);
    final encodedVibes = await notifier.ensureVibeReferencesEncoded(
      params.vibeReferencesV4,
      model: params.model,
      requestParams: params,
      syncCurrentState: syncCurrentState,
    );

    if (identical(encodedVibes, params.vibeReferencesV4)) {
      return params;
    }

    return params.copyWith(vibeReferencesV4: encodedVibes);
  }

  Future<ImageParams?> _prepareGenerationParams(
    ImageParams params,
    int generationRunId, {
    bool preserveSnapshot = false,
  }) async {
    try {
      return await _prepareVibesForGeneration(
        preserveSnapshot ? params : _applyPromptPipeline(params),
        syncCurrentState: !preserveSnapshot,
      );
    } catch (error) {
      // 准备参数时占位已经出现；失败必须结束加载，旧请求不能改写新请求。
      if (!_shouldAbortGenerationRun(generationRunId)) {
        state = state.copyWith(
          status: GenerationStatus.error,
          errorMessage: error.toString(),
          progress: 0.0,
          currentImage: 0,
          totalImages: 0,
          clearStreamPreview: true,
        );
      }
      return null;
    }
  }

  PromptPresetResolution _resolvePromptPresets(ImageParams params) {
    final qualityState = ref.read(qualityPresetNotifierProvider);
    final qualityContent = ref
        .read(qualityPresetNotifierProvider.notifier)
        .getEffectiveContent(params.model);
    final ucState = ref.read(ucPresetNotifierProvider);
    final ucPresetContent = ref
        .read(ucPresetNotifierProvider.notifier)
        .getEffectiveContent(params.model);

    return resolvePromptPresetSettings(
      model: params.model,
      prompt: params.prompt,
      negativePrompt: params.negativePrompt,
      qualityMode: qualityState.mode,
      qualityContent: qualityContent,
      ucPresetType: ucState.presetType,
      ucPresetContent: ucPresetContent,
      useCustomUcPreset: ucState.isCustom,
    );
  }

  /// 请求副本管线：别名 → 固定词 → 预设 → 角色转换 → SD 转换 → 格式化。
  /// 批次循环每批重跑，让重 roll 的块实例投影逐张生效；
  /// vibes 编码（`_prepareVibesForGeneration`）不在其中，只跑一次。
  ImageParams preparePromptParams(
    ImageParams params, {
    bool useParamsCharacters = false,
    bool useParamsQualityPreset = false,
    bool useParamsUcPreset = false,
  }) {
    var effectiveParams = params;

    // 解析别名（将 <词库名> 展开为实际内容）
    final aliasResolver = ref.read(aliasResolverServiceProvider.notifier);
    final promptWithAliases = aliasResolver.resolveAliases(
      effectiveParams.prompt,
    );
    final negativeWithAliases = aliasResolver.resolveAliases(
      effectiveParams.negativePrompt,
    );
    if (promptWithAliases != effectiveParams.prompt ||
        negativeWithAliases != effectiveParams.negativePrompt) {
      AppLogger.d('Resolved aliases in prompts', 'AliasResolver');
      effectiveParams = effectiveParams.copyWith(
        prompt: promptWithAliases,
        negativePrompt: negativeWithAliases,
      );
    }

    final presetResolution = _resolvePromptPresets(effectiveParams);
    effectiveParams = effectiveParams.copyWith(
      prompt: useParamsQualityPreset
          ? effectiveParams.prompt
          : presetResolution.prompt,
      negativePrompt: useParamsUcPreset
          ? effectiveParams.negativePrompt
          : presetResolution.negativePrompt,
    );

    final characterConfig = ref.read(characterPromptNotifierProvider);
    final apiCharacters = useParamsCharacters
        ? [
            for (final character in effectiveParams.characters)
              character.copyWith(
                prompt: aliasResolver.resolveAliases(character.prompt),
                negativePrompt: aliasResolver.resolveAliases(
                  character.negativePrompt,
                ),
              ),
          ]
        : _convertCharactersToApiFormat(characterConfig);

    final autoFormat = ref.read(autoFormatPromptSettingsProvider);
    final sdAutoConvert = ref.read(sdSyntaxAutoConvertSettingsProvider);
    String normalize(String text) => PromptInputNormalization.normalize(
      text,
      autoFormat: autoFormat,
      sdAutoConvert: sdAutoConvert,
    ).text;

    // NAI 官方预设保持为 API 开关；自定义预设展开成显式提示词，避免官方预设重复生效。
    return effectiveParams
        .copyWith(
          prompt: normalize(effectiveParams.prompt),
          negativePrompt: normalize(effectiveParams.negativePrompt),
          qualityToggle: useParamsQualityPreset
              ? effectiveParams.effectiveQualityToggle
              : presetResolution.qualityToggle,
          qualityTagPreset: useParamsQualityPreset
              ? effectiveParams.effectiveQualityTagPreset
              : presetResolution.qualityTagPreset,
          ucPreset: useParamsUcPreset
              ? effectiveParams.ucPreset
              : presetResolution.ucPreset,
          characters: [
            for (final character in apiCharacters)
              character.copyWith(
                prompt: normalize(character.prompt),
                negativePrompt: normalize(character.negativePrompt),
              ),
          ],
          useCoords:
              apiCharacters.isNotEmpty &&
              (useParamsCharacters
                  ? effectiveParams.useCoords
                  : !characterConfig.globalAiChoice),
        )
        .constrainedForModel;
  }

  ImageParams _applyPromptPipeline(ImageParams params) =>
      preparePromptParams(params);

  /// [badRequestStopsRun]：批量里碰到 400 是否整次停下（[stopsGenerationRun]）。
  /// 画风探索页逐张抽候选，每张的画风串不同，传 false 让 400 只算那一张失败。
  /// 提示词里有随机块、每批重新抽词时，传 true 也只算那一批失败。
  Future<void> generate(
    ImageParams params, {
    GenerationBatchCallback? onBatchEvent,
    int? imagesPerRequestOverride,
    ImageOperation? operation,
    bool badRequestStopsRun = true,
  }) => _generate(
    params,
    onBatchEvent: onBatchEvent,
    imagesPerRequestOverride: imagesPerRequestOverride,
    operation: operation,
    badRequestStopsRun: badRequestStopsRun,
  );

  /// Official source-based action. Batch preferences and draft prompt lanes
  /// do not participate, and the original is displayed without saving it again.
  Future<void> generateOfficialVariations(
    ImageParams params, {
    required GeneratedImage original,
  }) => _generate(
    params.copyWith(nSamples: 1),
    imagesPerRequestOverride: 3,
    operation: ImageOperation.variations,
    variationOriginal: original,
  );

  /// Frozen source-image generation does not synchronize or roll the sidebar.
  Future<void> generateSourceImage(
    ImageParams params, {
    required ImageOperation operation,
    GeneratedImage? original,
    GenerationBatchCallback? onBatchEvent,
  }) => _generate(
    params.copyWith(nSamples: 1),
    imagesPerRequestOverride: operation == ImageOperation.variations ? 3 : 1,
    operation: operation,
    variationOriginal: operation == ImageOperation.variations ? original : null,
    onBatchEvent: onBatchEvent,
    preservePromptSnapshot: true,
  );

  /// 探索任务专用生成入口（画风探索阶段 B）：单张、强制 nSamples=1、
  /// 随机种子实体化后把真实 seed 随结果带回；**不清空主 UI 当前图、
  /// 不触发全局 roll**（探索 runner 自控 roll 节奏）。
  /// 失败/取消返回 null，错误信息留在 `state.errorMessage`。
  ///
  /// 与 [generate] 共享冷却门禁、提示词管线与 vibe 编码；
  /// 但绕开批次分支（批次循环按 imagesPerRequest 共享提示词，
  /// 探索每张候选有独立 roll 快照，不能共用）。
  Future<ExploreGenerationResult?> generateForExplore(ImageParams params) =>
      _generateForExplore(params);

  Future<ExploreGenerationResult?> _generateForExplore(
    ImageParams params,
  ) async {
    // 与 _generate 共用同一在途门禁：探索生成同样不得顶替
    // 当前 run 或把冷却计数花在注定被丢弃的调用上。
    if (state.isGenerating ||
        (ref.exists(imageWorkflowControllerProvider) &&
            ref.read(imageWorkflowControllerProvider).isToolRunning) ||
        (ref.exists(localUpscaleTaskProvider) &&
            ref.read(localUpscaleTaskProvider).running)) {
      return null;
    }

    final canStart = ref
        .read(generationCooldownProvider.notifier)
        .tryStartGeneration();
    if (!canStart) {
      return null;
    }

    final generationRunId = _startGenerationRun();

    // 不清空 currentImages：探索生成不该打断主 UI 当前图的展示；
    // 完成时 _generateSingle 会整体替换 currentImages（新列表实例），
    // 记账的 identical 判定与失败快照语义均不受影响。
    state = state.copyWith(
      generationRunId: generationRunId,
      isExploreRun: true,
      status: GenerationStatus.generating,
      progress: 0.0,
      currentImage: 1,
      totalImages: 1,
      clearStreamPreview: true,
      batchWidth: params.width,
      batchHeight: params.height,
    );

    final idsBefore = <String>{
      for (final image in state.currentImages) image.id,
      for (final image in state.history) image.id,
    };

    final stopwatch = Stopwatch()..start();
    final preparedParams = await _prepareGenerationParams(
      params.copyWith(nSamples: 1),
      generationRunId,
    );
    if (preparedParams == null || _shouldAbortGenerationRun(generationRunId)) {
      return null;
    }

    // 随机种子在进入请求前实体化，结果对象带回真实 seed（复现链）。
    final materializedParams = _materializeRandomSeed(preparedParams);
    await _generateSingle(materializedParams, 1, 1, generationRunId);
    stopwatch.stop();

    // 与生成前快照比 id 找新图：currentImages 优先，history 兜底。
    final produced =
        _findNewCompletedImage(state.currentImages, idsBefore) ??
        _findNewCompletedImage(state.history, idsBefore);
    if (produced == null) {
      return null;
    }
    return ExploreGenerationResult(
      imageBytes: produced.bytes,
      filePath: produced.filePath,
      seed: materializedParams.seed,
      elapsedMs: stopwatch.elapsedMilliseconds,
      imageWidth: produced.width,
      imageHeight: produced.height,
    );
  }

  GeneratedImage? _findNewCompletedImage(
    List<GeneratedImage> images,
    Set<String> idsBefore,
  ) {
    for (final image in images) {
      if (!idsBefore.contains(image.id) && image.canSave) return image;
    }
    return null;
  }

  Future<void> _generate(
    ImageParams params, {
    GenerationBatchCallback? onBatchEvent,
    int? imagesPerRequestOverride,
    ImageOperation? operation,
    GeneratedImage? variationOriginal,
    ImageWorkflowState? workflowOverride,
    bool preserveSnapshot = false,
    bool preservePromptSnapshot = false,
    bool badRequestStopsRun = true,
    GenerationRejectedBatches? rejectedBefore,
  }) async {
    preserveSnapshot = preserveSnapshot || preservePromptSnapshot;
    // 同步在途门禁：已有生成进行中时直接丢弃本次调用。
    // 必须先于冷却扣减与 _startGenerationRun——重入若走到 run 创建，
    // 会顶替当前 run 标识，使在途请求脱离取消/陈旧更新防护；
    // 取消后 isGenerating 已回落，cancel→重新生成不受影响。
    if (state.isGenerating ||
        (ref.exists(imageWorkflowControllerProvider) &&
            ref.read(imageWorkflowControllerProvider).isToolRunning) ||
        (ref.exists(localUpscaleTaskProvider) &&
            ref.read(localUpscaleTaskProvider).running)) {
      return;
    }

    final canStart = ref
        .read(generationCooldownProvider.notifier)
        .tryStartGeneration();
    if (!canStart) {
      return;
    }

    final generationRunId = _startGenerationRun();
    final original = variationOriginal?.copyWith(
      generationRunId: generationRunId,
      batchIndex: -1,
    );
    List<GeneratedImage> withOriginal(List<GeneratedImage> images) => [
      if (original != null) original,
      ...images,
    ];

    _activeImageOperation = operation;
    final requestWorkflow =
        workflowOverride ??
        (ref.exists(imageWorkflowControllerProvider)
            ? ref.read(imageWorkflowControllerProvider)
            : null) ??
        const ImageWorkflowState();
    if (operation == null) {
      final workflow = requestWorkflow;
      if (workflow.isEnhance && workflow.enhance.localUpscale) {
        _activeLocalEnhance = workflow.upscale;
      }
    }
    // Freeze the buffers before the first await, including OLD's full-source mask.
    final effectiveParams = params.copyWith(
      sourceImage: params.sourceImage == null
          ? null
          : Uint8List.fromList(params.sourceImage!),
      maskImage: params.maskImage == null
          ? null
          : Uint8List.fromList(params.maskImage!),
    );

    // 在参数准备/网络请求的首次 await 前发布完整占位信息。
    // nSamples 是请求次数，batchSize 是每次请求的图片数。
    final batchCount = effectiveParams.nSamples;
    final configuredBatchSize =
        imagesPerRequestOverride ?? ref.read(imagesPerRequestProvider) ?? 1;
    final batchSize = configuredBatchSize.clamp(1, 4).toInt();
    final totalImages = batchCount * batchSize;
    _lastRequest = GenerationRetryRequest(
      params: effectiveParams,
      count: batchSize,
      workflow: requestWorkflow,
      accountId: ref.exists(authNotifierProvider)
          ? ref.read(authNotifierProvider).accountId
          : null,
      operation: operation,
      original: variationOriginal,
      rejectedBatches: rejectedBefore,
    );
    state = state.copyWith(
      generationRunId: generationRunId,
      isExploreRun: !badRequestStopsRun,
      currentImages: withOriginal([]),
      status: GenerationStatus.generating,
      progress: 0.0,
      currentImage: 1,
      totalImages: totalImages,
      clearStreamPreview: true,
      batchWidth: effectiveParams.width,
      batchHeight: effectiveParams.height,
    );

    if (_activeLocalEnhance != null) {
      try {
        final models = await ref.read(localUpscaleModelsProvider.future);
        if (_shouldAbortGenerationRun(generationRunId)) return;
        if (!models.any(
          (model) =>
              model.installed && model.id == _activeLocalEnhance!.localModel,
        )) {
          state = state.copyWith(
            status: GenerationStatus.error,
            errorMessage: currentL10n.localUpscale_notInstalled,
            clearStreamPreview: true,
          );
          return;
        }
      } catch (_) {
        if (_shouldAbortGenerationRun(generationRunId)) return;
        state = state.copyWith(
          status: GenerationStatus.error,
          errorMessage: currentL10n.localUpscale_modelMissing,
          clearStreamPreview: true,
        );
        return;
      }
    }

    final preparedParams = await _prepareGenerationParams(
      effectiveParams,
      generationRunId,
      preserveSnapshot:
          preserveSnapshot || operation == ImageOperation.variations,
    );
    if (preparedParams == null || _shouldAbortGenerationRun(generationRunId)) {
      return;
    }
    _lastRequest = _lastRequest!.withParams(preparedParams);

    // 如果只生成 1 张，直接生成；随机种子在进入请求前实体化，便于失败快照保留真实 seed。
    if (batchCount == 1 && batchSize == 1) {
      final materializedParams = _materializeRandomSeed(preparedParams);
      _lastRequest = _lastRequest!.withParams(materializedParams);
      await _emitBatchEvent(
        onBatchEvent,
        GenerationBatchEvent(
          kind: GenerationBatchEventKind.start,
          generationRunId: generationRunId,
          batchIndex: 0,
          slotStart: 1,
          slotCount: 1,
          totalSlots: 1,
        ),
      );
      if (_shouldAbortGenerationRun(generationRunId)) {
        await _emitBatchEvent(
          onBatchEvent,
          GenerationBatchEvent(
            kind: GenerationBatchEventKind.complete,
            generationRunId: generationRunId,
            batchIndex: 0,
            slotStart: 1,
            slotCount: 1,
            totalSlots: 1,
            error: 'cancelled',
          ),
        );
        return;
      }

      final stopwatch = Stopwatch()..start();
      final singleFuture = _generateSingle(
        materializedParams,
        1,
        1,
        generationRunId,
        rejectedBatches: rejectedBefore,
      );
      // P2.5：入队后即刻重 roll 随机块实例——本张用入队前的投影，
      // UI 随即显示下一张的内容（roll 时机 4）。
      if (!preserveSnapshot && operation != ImageOperation.variations) {
        ref.read(pillRollCoordinatorProvider).rollAllLanesAndSync();
      }
      await singleFuture;
      stopwatch.stop();
      await _emitBatchEvent(
        onBatchEvent,
        GenerationBatchEvent(
          kind: GenerationBatchEventKind.complete,
          generationRunId: generationRunId,
          batchIndex: 0,
          slotStart: 1,
          slotCount: 1,
          totalSlots: 1,
          images: state.status == GenerationStatus.completed
              ? state.currentImages
              : const [],
          error: state.status == GenerationStatus.error
              ? state.errorMessage
              : state.status == GenerationStatus.cancelled
              ? 'cancelled'
              : null,
          elapsedMs: stopwatch.elapsedMilliseconds,
        ),
      );
      // 注意：生成完成音效由 GenerationCompletionWatcher 统一监听
      // 点数消耗由接口服务按每次请求的价记账（AnlasRequestLedger）
      return;
    }

    // 多张图片：按批次循环请求
    state = state.copyWith(
      status: GenerationStatus.generating,
      progress: 0.0,
      errorMessage: null,
      currentImage: 1,
      totalImages: totalImages,
      currentImages: withOriginal([]),
      batchWidth: preparedParams.width,
      batchHeight: preparedParams.height,
    );

    final allImages = <GeneratedImage>[];
    final random = Random();
    int generatedImages = 0;
    Object? lastBatchError;
    // 429 的等待预算按整次运行算。等满了，或者碰到 400、401、402、403、404，
    // 就记下停下的原因，剩下的批次不再发。
    final concurrencyBackoff = GenerationConcurrencyBackoff();
    String? runStopError;
    GenerationPartialBatch? partialBatch;
    // 提示词里有随机块（或顺序块）时每批重新抽词，一批 400 可能只是这一批
    // 抽到的词不行：只算这一批失败，接着发下一批。不重新抽的话每批发的都
    // 一样，400 照旧整次停下。发请求前按块的设置定下来，不比两批的提示词；
    // 请求不带的框（Turbo 的负面、V3 的角色框等）重抽了也不算。
    final redrawsEachBatch =
        !preserveSnapshot &&
        batchCount > 1 &&
        ref
            .read(pillRollCoordinatorProvider)
            .rollRedrawsRequest(preparedParams.model);
    // 每批重新抽词时被 400 跳过的批次记下来，出完后画布说明跳过了几次（生图
    // 页的运行；画风探索在候选上写原因，不记）。重试接着算停下之前跳过的
    // （[rejectedBefore]）。
    var rejectedBatches = 0;
    Object? lastRejected;
    GenerationRejectedBatches? rejectedSoFar() {
      final count = (rejectedBefore?.count ?? 0) + rejectedBatches;
      if (count == 0) return null;
      return GenerationRejectedBatches(
        count: count,
        lastError: lastRejected == null
            ? rejectedBefore!.lastError
            : '$lastRejected',
      );
    }

    final startedBatches = <int>{};
    final completedBatches = <int>{};

    // 当前使用的参数（P2.5：批次间重 roll 块实例后重跑提示词管线，逐张换内容）
    var currentParams = preparedParams;

    for (int batch = 0; batch < batchCount; batch++) {
      if (_shouldAbortGenerationRun(generationRunId)) {
        await _emitCancelledBatchEvents(
          callback: onBatchEvent,
          completedBatches: completedBatches,
          generationRunId: generationRunId,
          firstBatch: batch,
          batchCount: batchCount,
          batchSize: batchSize,
          totalSlots: totalImages,
        );
        return;
      }

      // 更新当前进度
      state = state.copyWith(
        currentImage: generatedImages + 1,
        progress: generatedImages / totalImages,
      );

      final slotStart = batch * batchSize + 1;
      if (startedBatches.add(batch)) {
        await _emitBatchEvent(
          onBatchEvent,
          GenerationBatchEvent(
            kind: GenerationBatchEventKind.start,
            generationRunId: generationRunId,
            batchIndex: batch,
            slotStart: slotStart,
            slotCount: batchSize,
            totalSlots: totalImages,
          ),
        );
      }
      if (_shouldAbortGenerationRun(generationRunId)) {
        await _emitCancelledBatchEvents(
          callback: onBatchEvent,
          completedBatches: completedBatches,
          generationRunId: generationRunId,
          firstBatch: batch,
          batchCount: batchCount,
          batchSize: batchSize,
          totalSlots: totalImages,
        );
        return;
      }

      // 每批使用不同的随机种子
      final noiseSeed = random.nextInt(_randomSeedExclusiveUpperBound);
      final batchParams = currentParams.copyWith(
        nSamples: batchSize,
        seed: operation == ImageOperation.variations
            ? noiseSeed + 1
            : noiseSeed,
        extraNoiseSeed: operation == ImageOperation.variations
            ? noiseSeed
            : null,
      );
      final batchStopwatch = Stopwatch()..start();

      try {
        // 使用流式 API 生成，支持预览
        final result = await _generateBatchWithStream(
          batchParams,
          slotStart,
          totalImages,
          generationRunId,
        );
        if (_shouldAbortGenerationRun(generationRunId)) {
          batchStopwatch.stop();
          await _emitCancelledBatchEvents(
            callback: onBatchEvent,
            completedBatches: completedBatches,
            generationRunId: generationRunId,
            firstBatch: batch,
            batchCount: batchCount,
            batchSize: batchSize,
            totalSlots: totalImages,
          );
          return;
        }
        final generatedList = await _completeGeneratedImages(
          result.images,
          batchParams,
          generationRunId,
          offset: slotStart - 1,
        );
        if (_shouldAbortGenerationRun(generationRunId)) return;
        if (generatedList.isNotEmpty) {
          // 将字节数据包装成带唯一ID的 GeneratedImage
          allImages.addAll(generatedList);
          // 立即更新显示和历史
          state = state.copyWith(
            currentImages: withOriginal(allImages),
            history: _prependCompletedHistory(withOriginal(generatedList)),
            clearStreamPreview: true,
          );
          _retainSharePreparationCacheForCurrentHistory();
        }
        generatedImages += batchSize;
        batchStopwatch.stop();
        if (result.interruption case final error?) {
          final remaining = batchCount - batch - 1;
          partialBatch = (
            received: generatedList.length,
            expected: batchSize,
            unsentRequests: remaining,
          );
          runStopError = generationFailureDetail(error.toString());
          // The service already processed this request. A manual retry can
          // only submit whole requests that have never started.
          _lastRequest = remaining == 0
              ? null
              : _lastRequest!.withParams(
                  currentParams.copyWith(nSamples: remaining),
                  rejectedBatches: rejectedSoFar(),
                );
        }
        await _emitBatchComplete(
          callback: onBatchEvent,
          completedBatches: completedBatches,
          generationRunId: generationRunId,
          batchIndex: batch,
          slotStart: slotStart,
          slotCount: batchSize,
          totalSlots: totalImages,
          images: generatedList,
          error:
              result.interruption ??
              (generatedList.isEmpty ? 'no image produced' : null),
          elapsedMs: batchStopwatch.elapsedMilliseconds,
        );
        if (result.interruption case final error?) {
          await _emitUnfinishedBatchEvents(
            callback: onBatchEvent,
            completedBatches: completedBatches,
            generationRunId: generationRunId,
            firstBatch: batch + 1,
            batchCount: batchCount,
            batchSize: batchSize,
            totalSlots: totalImages,
            error: error,
          );
          break;
        }
        concurrencyBackoff.reset();
      } catch (e) {
        if (_isCancelledError(e, generationRunId)) {
          batchStopwatch.stop();
          await _emitCancelledBatchEvents(
            callback: onBatchEvent,
            completedBatches: completedBatches,
            generationRunId: generationRunId,
            firstBatch: batch,
            batchCount: batchCount,
            batchSize: batchSize,
            totalSlots: totalImages,
          );
          if (_isCurrentGenerationRun(generationRunId)) {
            _appendFailedStreamSnapshotsForCurrentSlots(generationRunId);
            state = state.copyWith(
              status: GenerationStatus.cancelled,
              progress: 0.0,
              currentImage: 0,
              totalImages: 0,
              clearStreamPreview: true,
            );
          }
          // 取消的请求不记账：NovelAI 交回结果才记（AnlasRequestLedger）
          return;
        }
        String? stopError;
        // 并发限制：等 NAI 释放额度后重试当前批次（取消可随时中断）
        if (_isConcurrencyLimited(e)) {
          final delay = concurrencyBackoff.nextDelay(
            retryAfter: generationRetryAfterOf(e),
          );
          if (delay != null) {
            AppLogger.w(
              'NAI 并发限制(429)，${_formatRetryDelay(delay)} 后自动重试第 ${batch + 1} 批',
              'Generation',
            );
            await _waitBeforeRetry(delay);
            if (_shouldAbortGenerationRun(generationRunId)) {
              await _emitCancelledBatchEvents(
                callback: onBatchEvent,
                completedBatches: completedBatches,
                generationRunId: generationRunId,
                firstBatch: batch,
                batchCount: batchCount,
                batchSize: batchSize,
                totalSlots: totalImages,
              );
              return;
            }
            batch--;
            continue;
          }
          // 等满了：整次运行停下，剩下的批次不再发。
          stopError = generationConcurrencyStoppedError(e);
          AppLogger.w(
            'NAI 并发限制(429)：本次已等 ${_formatRetryDelay(concurrencyBackoff.waited)}，'
                '停止生成，剩下 ${batchCount - batch - 1} 批不再发送',
            'Generation',
          );
        } else if (stopsGenerationRun(
          e,
          badRequestStopsRun: badRequestStopsRun && !redrawsEachBatch,
        )) {
          // 请求无效、登录失效、余额不足、没有权限、找不到（400、401、402、
          // 403、404）不会自己好，后面的批次发了也是白发：整次运行停下
          // （每批重新抽词时 400 除外）。
          stopError = generationStatusStoppedError(e);
          AppLogger.w(
            '生成第 ${batch + 1} 批失败（HTTP ${generationFailureStatus(e)}），'
                '停止生成，剩下 ${batchCount - batch - 1} 批不再发送',
            'Generation',
          );
        }
        if (stopError != null) {
          runStopError = stopError;
          lastBatchError = stopError;
          // 失败卡上的「重试」只补没发出去的这几批（这一批和后面的），
          // 报价也按这几批算；出好的不再重出一遍。词用停下这一批的：每批
          // 重新抽词时，第一批抽到的可能正是被 400 拒掉的那组。停下之前
          // 被 400 跳过的几批也带上，重试补完了画布照样说明。
          _lastRequest = _lastRequest!.withParams(
            currentParams.copyWith(nSamples: batchCount - batch),
            rejectedBatches: rejectedSoFar(),
          );
          _appendFailedStreamSnapshotsForCurrentSlots(generationRunId);
          batchStopwatch.stop();
          await _emitBatchComplete(
            callback: onBatchEvent,
            completedBatches: completedBatches,
            generationRunId: generationRunId,
            batchIndex: batch,
            slotStart: slotStart,
            slotCount: batchSize,
            totalSlots: totalImages,
            error: stopError,
            elapsedMs: batchStopwatch.elapsedMilliseconds,
          );
          await _emitUnfinishedBatchEvents(
            callback: onBatchEvent,
            completedBatches: completedBatches,
            generationRunId: generationRunId,
            firstBatch: batch + 1,
            batchCount: batchCount,
            batchSize: batchSize,
            totalSlots: totalImages,
            error: stopError,
          );
          break;
        }
        // 本批次失败，继续下一批
        _appendFailedStreamSnapshotsForCurrentSlots(generationRunId);
        lastBatchError = e;
        if (badRequestStopsRun && generationFailureStatus(e) == 400) {
          rejectedBatches++;
          lastRejected = e;
        }
        AppLogger.e('生成第 ${batch + 1} 批失败: $e');
        generatedImages += batchSize;
        batchStopwatch.stop();
        await _emitBatchComplete(
          callback: onBatchEvent,
          completedBatches: completedBatches,
          generationRunId: generationRunId,
          batchIndex: batch,
          slotStart: slotStart,
          slotCount: batchSize,
          totalSlots: totalImages,
          error: e,
          elapsedMs: batchStopwatch.elapsedMilliseconds,
        );
      }

      // P2.5 逐张重抽：本批已结束（成功或失败），重 roll 随机块实例并把
      // 新投影重跑提示词管线，下一批生效；429 重试（continue）不消耗 roll。
      if (!preserveSnapshot && batch + 1 < batchCount) {
        final rolled = ref
            .read(pillRollCoordinatorProvider)
            .rollAllLanesAndSync();
        if (rolled.isNotEmpty) {
          final freshParams = ref.read(generationParamsNotifierProvider);
          currentParams =
              _applyPromptPipeline(
                params.copyWith(
                  prompt: rolled[PillScopes.main] ?? freshParams.prompt,
                  negativePrompt:
                      rolled[PillScopes.negative] ?? freshParams.negativePrompt,
                ),
              )
              // vibes 编码只跑一次：保留已准备结果，不被管线重建覆盖
              .copyWith(vibeReferencesV4: currentParams.vibeReferencesV4);
        }
      }
    }

    if (!_isCurrentGenerationRun(generationRunId)) return;

    if (!_isCancelled && allImages.isEmpty) {
      state = state.copyWith(
        status: GenerationStatus.error,
        errorMessage:
            lastBatchError?.toString() ?? 'No images returned from generation',
        progress: 0.0,
        currentImage: 0,
        totalImages: 0,
        clearStreamPreview: true,
      );
      return;
    }

    // 完成（不再随机，保持图像和提示词对应）。整次停下（429 等满，或者
    // 400、401、402、403、404）时已出的图照常展示和保存，状态记为失败，好让
    // 画布说明为什么没出完。出完了但有几批被 400 跳过，状态照旧是完成，另
    // 记下跳过了几批，画布据此说明；停下了就只说停下的原因，跳过的几批跟着
    // 重试走（[GenerationRetryRequest.rejectedBatches]），重试补完了再说明。
    state = state.copyWith(
      status: _isCancelled
          ? GenerationStatus.cancelled
          : runStopError != null
          ? GenerationStatus.error
          : GenerationStatus.completed,
      errorMessage: runStopError,
      partialBatch: partialBatch,
      rejectedBatches: !_isCancelled && runStopError == null
          ? rejectedSoFar()
          : null,
      clearStreamPreview: runStopError != null,
      currentImages: withOriginal(allImages),
      displayImages: withOriginal(allImages),
      displayWidth: allImages.isEmpty
          ? preparedParams.width
          : allImages.first.width,
      displayHeight: allImages.isEmpty
          ? preparedParams.height
          : allImages.first.height,
      progress: 1.0,
      currentImage: 0,
      totalImages: 0,
    );

    // 注意：生成完成音效由 GenerationCompletionWatcher 统一监听

    // 自动保存：如果启用且生成成功，保存所有图像
    if (!_isCancelled && allImages.isNotEmpty) {
      await _autoSaveIfEnabled(allImages, preparedParams);
    }
  }

  List<GeneratedImage> _prependCompletedHistory(List<GeneratedImage> images) {
    final ids = images.map((image) => image.id).toSet();
    return [
      ...images,
      ...state.history.where((image) => !ids.contains(image.id)),
    ];
  }

  /// Only publish the final enhanced image. Raw bytes stay temporary during
  /// inference and are recovered only when enhancement fails or is cancelled.
  Future<List<GeneratedImage>> _completeGeneratedImages(
    Iterable<(int, Uint8List)> images,
    ImageParams params,
    int runId, {
    int offset = 0,
  }) async {
    final settings = _activeLocalEnhance;
    final result = <GeneratedImage>[];
    final originals = [
      for (final (index, bytes) in images)
        GeneratedImage.create(
          bytes,
          width: params.width,
          height: params.height,
          sourceParams: params,
          operation: _activeImageOperation,
          generationRunId: runId,
          batchIndex: offset + index,
        ),
    ];
    if (settings != null) _pendingLocalEnhanceImages = List.of(originals);
    for (final raw in originals) {
      if (_shouldAbortGenerationRun(runId)) break;
      if (settings == null) {
        result.add(raw);
        continue;
      }
      state = state.copyWith(streamPreview: raw.bytes);
      _clearRememberedStreamPreview(
        generationRunId: runId,
        imageNumber: raw.batchIndex! + 1,
      );
      LocalUpscaleResult? upscaled;
      try {
        final source = ImageSaveUtils.hasEmbeddedNovelAiMetadata(raw.bytes)
            ? raw.bytes
            : await ImageSaveUtils.rebuildImageBytesWithMetadata(
                imageBytes: raw.bytes,
                params: params,
                actualSeed: params.seed,
              );
        if (_shouldAbortGenerationRun(runId)) break;
        upscaled = await ref
            .read(localUpscaleTaskProvider.notifier)
            .processGenerated(
              source,
              modelId: settings.localModel,
              scale: settings.localScale,
              seedvr2Options: settings.selectedSeedvr2Options,
            );
      } catch (error, stackTrace) {
        AppLogger.e(
          'Local enhancement failed',
          error,
          stackTrace,
          'Generation',
        );
      } finally {
        if (_isCurrentGenerationRun(runId)) {
          _pendingLocalEnhanceImages.removeWhere((image) => image.id == raw.id);
        }
      }
      if (_shouldAbortGenerationRun(runId)) break;
      final completed = upscaled == null
          ? raw
          : GeneratedImage.create(
              upscaled.bytes,
              width: upscaled.width,
              height: upscaled.height,
              operation: ImageOperation.upscale,
              generationRunId: runId,
              batchIndex: raw.batchIndex,
            );
      result.add(completed);
      state = state.copyWith(
        currentImages: [...state.currentImages, completed],
        history: _prependCompletedHistory([completed]),
        clearStreamPreview: true,
      );
    }
    return result;
  }

  /// 自动保存图像（如果启用）
  Future<void> _autoSaveIfEnabled(
    List<GeneratedImage> images,
    ImageParams params,
  ) async {
    final saveSettings = ref.read(imageSaveSettingsNotifierProvider);
    final currentVibes = ref
        .read(generationParamsNotifierProvider)
        .vibeReferencesV4;
    await _saveImagesToGallery(
      images,
      params.copyWith(vibeReferencesV4: currentVibes),
      saveImages: saveSettings.autoSave,
    );
  }

  /// Put a local source on the canvas without generating, saving or rebuilding
  /// metadata from the current draft. Repeated imports reuse the existing tile.
  GeneratedImage? registerSourceImage(Uint8List imageBytes) {
    if (state.isGenerating || imageBytes.isEmpty) return null;
    (int, int)? size;
    try {
      size = _resolveImageSize(imageBytes);
    } catch (_) {
      // Some decoders throw on truncated input instead of returning null.
      return null;
    }
    if (size == null || size.$1 <= 0 || size.$2 <= 0) return null;

    final existing = [...state.mergedPanelImages, ...state.displayImages]
        .where(
          (image) =>
              image.canUseAsGenerationInput &&
              listEquals(image.bytes, imageBytes),
        )
        .firstOrNull;
    final image =
        existing ??
        GeneratedImage.create(
          Uint8List.fromList(imageBytes),
          width: size.$1,
          height: size.$2,
        );
    state = state.copyWith(
      status: GenerationStatus.completed,
      currentImages: [
        image,
        ...state.currentImages.where((entry) => entry.id != image.id),
      ],
      history: state.history.any((entry) => entry.id == image.id)
          ? state.history
          : [image, ...state.history],
      displayImages: [
        image,
        ...state.displayImages.where((entry) => entry.id != image.id),
      ],
      displayWidth: image.width,
      displayHeight: image.height,
      clearStreamPreview: true,
    );
    _retainSharePreparationCacheForCurrentHistory();
    if (existing == null) _preloadMetadataInBackground([image]);
    return image;
  }

  /// 将外部结果登记到历史记录，并可选地直接保存到本地图库
  ///
  /// [addToDisplay] 为 true 时，将图像插入当前结果和中央预览列表首位。
  /// [replaceCurrentDisplay] 为 true 时，将当前结果和中央预览替换为该图像，
  /// 既有图像仍保留在历史记录中。
  Future<String?> registerExternalImage(
    Uint8List imageBytes, {
    required ImageParams params,
    int? width,
    int? height,
    bool saveToLocal = false,
    String? saveDirectoryPath,
    bool syncToGalleryIndex = true,
    bool addToDisplay = false,
    bool replaceCurrentDisplay = false,
    ImageOperation? operation,
    Uint8List? originalBytes,
    bool Function()? canApply,
    bool Function()? canReplaceDisplay,
    void Function(GeneratedImage image, bool displayed)? onRegistered,
  }) async {
    assert(
      !addToDisplay || !replaceCurrentDisplay,
      'addToDisplay and replaceCurrentDisplay cannot both be true.',
    );

    final resolvedSize =
        _resolveImageSize(imageBytes, width: width, height: height) ??
        (params.width, params.height);

    final effectiveParams = params.copyWith(
      width: resolvedSize.$1,
      height: resolvedSize.$2,
    );
    final alignedBytes = await ImageSaveUtils.alignEmbeddedResolution(
      imageBytes: imageBytes,
      width: resolvedSize.$1,
      height: resolvedSize.$2,
    );
    final Uint8List normalizedBytes;
    if (alignedBytes != null) {
      normalizedBytes = alignedBytes;
    } else if (operation != null && originalBytes != null) {
      normalizedBytes = await ImageSaveUtils.inheritSourceMetadata(
        imageBytes: imageBytes,
        sourceBytes: originalBytes,
        width: resolvedSize.$1,
        height: resolvedSize.$2,
      );
    } else {
      final existingMetadata = await ImageMetadataService()
          .getMetadataFromBytes(imageBytes);
      final (charCaptions, charNegCaptions) = _buildCharacterCaptions(
        effectiveParams,
      );
      normalizedBytes = await ImageSaveUtils.rebuildImageBytesWithMetadata(
        imageBytes: imageBytes,
        params: effectiveParams,
        actualSeed: existingMetadata?.seed,
        charCaptions: charCaptions,
        charNegCaptions: charNegCaptions,
        useCoords: effectiveParams.useCoords,
      );
    }

    final generatedImage = GeneratedImage.create(
      normalizedBytes,
      width: resolvedSize.$1,
      height: resolvedSize.$2,
      operation: operation,
      originalBytes: originalBytes,
    );

    if (canApply != null && !canApply()) return null;
    final replaceDisplay =
        replaceCurrentDisplay && (canReplaceDisplay?.call() ?? true);
    final appendDisplay = addToDisplay && (canReplaceDisplay?.call() ?? true);
    final shouldDisplay = appendDisplay || replaceDisplay;
    state = state.copyWith(
      currentImages: replaceDisplay
          ? [generatedImage]
          : appendDisplay
          ? [generatedImage, ...state.currentImages]
          : state.currentImages,
      history: [generatedImage, ...state.history],
      displayImages: replaceDisplay
          ? [generatedImage]
          : appendDisplay
          ? [generatedImage, ...state.displayImages]
          : state.displayImages,
      displayWidth: shouldDisplay ? resolvedSize.$1 : state.displayWidth,
      displayHeight: shouldDisplay ? resolvedSize.$2 : state.displayHeight,
      // 只登记一张图，不改状态：失败卡（比如 429 停下的说明）照旧。
      errorMessage: state.errorMessage,
    );
    _retainSharePreparationCacheForCurrentHistory();

    onRegistered?.call(generatedImage, shouldDisplay);

    if (saveToLocal) {
      await _saveImagesToGallery(
        [generatedImage],
        effectiveParams,
        saveImages: true,
        saveDirectoryPath: saveDirectoryPath,
        syncToGalleryIndex: syncToGalleryIndex,
      );
      return _firstSavedPathForImage(generatedImage.id);
    }

    _preloadMetadataInBackground([generatedImage]);
    return null;
  }

  /// Tool results keep their own identity and operation. They must not acquire
  /// the unrelated prompt currently typed in the generation sidebar.
  List<GeneratedImage> registerToolResults(
    List<Uint8List> images, {
    required ImageOperation operation,
    required Uint8List originalBytes,
  }) {
    final runId = ++_generationRunCounter;
    final results = <GeneratedImage>[];
    for (final entry in images.indexed) {
      final size = _resolveImageSize(entry.$2);
      if (size == null) continue;
      results.add(
        GeneratedImage.create(
          entry.$2,
          width: size.$1,
          height: size.$2,
          generationRunId: runId,
          batchIndex: entry.$1,
          operation: operation,
          originalBytes: originalBytes,
        ),
      );
    }
    if (results.isEmpty) return const [];
    state = state.copyWith(
      history: [...results, ...state.history],
      errorMessage: state.errorMessage,
    );
    _retainSharePreparationCacheForCurrentHistory();
    _preloadMetadataInBackground(results);
    return results;
  }

  String? _firstSavedPathForImage(String id) {
    for (final image in state.history) {
      if (image.id == id && image.filePath != null) {
        return image.filePath;
      }
    }
    return null;
  }

  Future<void> _saveImagesToGallery(
    List<GeneratedImage> images,
    ImageParams params, {
    required bool saveImages,
    String? saveDirectoryPath,
    bool syncToGalleryIndex = true,
  }) async {
    if (!saveImages) return;

    try {
      final saveDirPath =
          saveDirectoryPath ??
          await GalleryFolderRepository.instance.getRootPath();
      if (saveDirPath == null) return;
      final saveDir = Directory(saveDirPath);
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // 使用已解析别名的角色提示词（来自 params.characters）
      final characterConfig = ref.read(characterPromptNotifierProvider);

      // 构建 V4 多角色提示词结构（直接使用已解析的 params.characters）
      final charCaptions = <Map<String, dynamic>>[];
      final charNegCaptions = <Map<String, dynamic>>[];

      for (final char in params.characters) {
        charCaptions.add({
          'char_caption': char.prompt,
          'centers': [
            {'x': 0.5, 'y': 0.5},
          ],
        });
        charNegCaptions.add({
          'char_caption': char.negativePrompt,
          'centers': [
            {'x': 0.5, 'y': 0.5},
          ],
        });
      }

      int savedCount = 0;
      final savedFilePaths = <String>[];
      final savedImages = <GeneratedImage>[];

      for (final image in images) {
        try {
          // 从图片元数据中提取实际的 seed（文件名与元数据嵌入共用）
          final hasEmbeddedMetadata = ImageSaveUtils.hasEmbeddedNovelAiMetadata(
            image.bytes,
          );
          int actualSeed = params.seed;
          if (actualSeed < 0 || hasEmbeddedMetadata) {
            final extractedMeta = await ImageMetadataService()
                .getMetadataFromBytes(image.bytes);
            if (extractedMeta != null &&
                extractedMeta.seed != null &&
                extractedMeta.seed! >= 0) {
              actualSeed = extractedMeta.seed!;
            } else if (actualSeed < 0) {
              actualSeed = Random().nextInt(4294967295);
            }
          }

          // 原子保存：未分类路径 + 独占防冲突 + 失败清理，全部在工具内完成
          final filePath = await ImageSaveUtils.saveBytesToGalleryPath(
            rootPath: saveDirPath,
            bytes:
                hasEmbeddedMetadata || image.operation == ImageOperation.upscale
                ? image.bytes
                : await ImageSaveUtils.rebuildImageBytesWithMetadata(
                    imageBytes: image.bytes,
                    params: params.copyWith(
                      width: image.width,
                      height: image.height,
                    ),
                    actualSeed: actualSeed,
                    charCaptions: charCaptions,
                    charNegCaptions: charNegCaptions,
                    useCoords: !characterConfig.globalAiChoice,
                    useStealth: false,
                  ),
            seed: actualSeed,
          );
          savedCount++;
          savedFilePaths.add(filePath);

          // 更新 filePath 到 GeneratedImage
          final updatedImage = image.copyWithFilePath(filePath);
          _updateImageInState(image.id, updatedImage);
          savedImages.add(updatedImage);
        } catch (e) {
          AppLogger.e('自动保存图像失败: $e');
        }
      }

      if (savedCount > 0) {
        if (syncToGalleryIndex) {
          // 【优化】使用即时添加新图像，避免全量扫描延迟
          final galleryNotifier = ref.read(
            localGalleryNotifierProvider.notifier,
          );
          final addedCount = await galleryNotifier.addNewlySavedImages(
            savedFilePaths,
          );

          // 如果即时添加失败或数量不匹配，回退到传统刷新方式
          if (addedCount < savedCount) {
            AppLogger.w(
              '[AutoSave] Immediate add returned $addedCount, expected $savedCount. Falling back to refresh.',
              'AutoSave',
            );
            await galleryNotifier.refresh();
          } else {
            AppLogger.i(
              '[AutoSave] Added $addedCount new images immediately without full scan',
              'AutoSave',
            );
          }
        }

        // 增量更新统计缓存，避免下次启动时完全重新计算
        try {
          final cacheService = ref.read(statisticsCacheServiceProvider);
          await cacheService.incrementImageCount(savedCount);
        } catch (e) {
          AppLogger.w('统计缓存增量更新失败: $e', 'AutoSave');
        }

        if (savedImages.isNotEmpty) {
          _preloadMetadataInBackground(savedImages);
        }

        AppLogger.d('自动保存完成: $savedCount 张图像', 'AutoSave');
      }
    } catch (e) {
      AppLogger.e('自动保存失败: $e');
    }
  }

  /// 检查错误是否为取消操作
  bool _hasCancelledText(dynamic error) =>
      error.toString().toLowerCase().contains('cancelled');

  bool _isCancelledError(dynamic error, [int? generationRunId]) {
    final runWasCancelled = generationRunId == null
        ? _isCancelled
        : _shouldAbortGenerationRun(generationRunId);
    if (runWasCancelled) return true;

    // Current generation paths have run ids. Do not convert a remote
    // "Cancelled" error into a user cancellation unless this run is stale.
    return generationRunId == null && _hasCancelledText(error);
  }

  bool _isRemoteCancelledError(dynamic error, int generationRunId) =>
      !_shouldAbortGenerationRun(generationRunId) && _hasCancelledText(error);

  /// NAI 并发限制（429）自动等待重试。
  /// 取消生成后服务器仍会占用账号并发额度直至孤儿任务结束，
  /// 期间新请求会立即 429；按 [GenerationConcurrencyBackoff] 等释放，
  /// 一次运行最多等 90 秒，等满就停下并说明原因。
  bool _isConcurrencyLimited(Object error) =>
      classifyGenerationFailure(error) ==
      GenerationFailureKind.concurrencyLimited;

  /// 只有网络错误、超时和 5xx 值得重试；400、401、402 等客户端错误重试也没用。
  bool _isRetryableFailure(Object error) =>
      classifyGenerationFailure(error) == GenerationFailureKind.transient;

  static String _formatRetryDelay(Duration delay) =>
      delay.inMilliseconds % 1000 == 0
      ? '${delay.inSeconds}s'
      : '${(delay.inMilliseconds / 1000).toStringAsFixed(1)}s';

  /// 检查错误是否为流式不支持
  bool _isStreamingNotAllowed(String error) {
    final lower = error.toLowerCase();
    return lower.contains('streaming is not allowed') ||
        lower.contains('streaming not allowed') ||
        lower.contains('stream is not allowed') ||
        lower.contains('stream not allowed');
  }

  /// 带重试的生成
  Future<(List<Uint8List>, Map<int, String>)> _generateWithRetry(
    ImageParams params,
    int generationRunId,
  ) async {
    final apiService = ref.read(naiImageGenerationApiServiceProvider);

    for (int retry = 0; retry <= _maxRetries; retry++) {
      try {
        if (_shouldAbortGenerationRun(generationRunId)) {
          throw StateError('Generation cancelled');
        }

        final result = await apiService.generateImage(
          params,
          onProgress: (_, __) {},
        );
        if (_shouldAbortGenerationRun(generationRunId)) {
          throw StateError('Generation cancelled');
        }
        return result;
      } catch (e) {
        if (_isCancelledError(e, generationRunId)) rethrow;
        if (_isRemoteCancelledError(e, generationRunId)) rethrow;
        if (_isConcurrencyLimited(e)) rethrow; // 交给上层等待并发额度释放

        if (retry < _maxRetries && _isRetryableFailure(e)) {
          AppLogger.w(
            '生成失败，${_retryDelays[retry]}ms 后重试 (${retry + 1}/$_maxRetries): $e',
          );
          await _waitBeforeRetry(Duration(milliseconds: _retryDelays[retry]));
          if (_shouldAbortGenerationRun(generationRunId)) {
            throw StateError('Generation cancelled');
          }
        } else {
          rethrow;
        }
      }
    }

    return (<Uint8List>[], <int, String>{});
  }

  /// 保存 Vibe 编码哈希到状态
  ///
  /// [vibeEncodings] 索引到编码哈希的映射
  void _saveVibeEncodings(Map<int, String> vibeEncodings) {
    AppLogger.d(
      'Saving ${vibeEncodings.length} Vibe encodings to state',
      'Generation',
    );
    for (final entry in vibeEncodings.entries) {
      final index = entry.key;
      final encoding = entry.value;
      if (encoding.isNotEmpty) {
        ref
            .read(generationParamsNotifierProvider.notifier)
            .updateVibeReference(index, vibeEncoding: encoding);
        AppLogger.d(
          'Saved Vibe encoding for index $index (hash length: ${encoding.length})',
          'Generation',
        );
      }
    }
  }

  /// 使用流式 API 生成批次图像（支持预览）
  ///
  /// [params] 生成参数（nSamples 表示本次请求要生成的图片数量）
  /// [currentStart] 当前批次起始图像编号
  /// [total] 总图像数量
  Future<_BatchStreamResult> _generateBatchWithStream(
    ImageParams params,
    int currentStart,
    int total,
    int generationRunId,
  ) async {
    final apiService = ref.read(naiImageGenerationApiServiceProvider);
    final requestParams = _materializeRandomSeed(params);
    final batchSize = max(1, requestParams.nSamples);
    const _BatchStreamResult empty = (images: [], interruption: null);
    var useNonStreamFallback = false;

    int imageNumberForSample(int sampleIndex) {
      final sampleOffset = sampleIndex.clamp(0, batchSize - 1).toInt();
      return currentStart + sampleOffset;
    }

    double progressForBatch({
      required int completedSamples,
      double inFlightProgress = 0.0,
    }) {
      final batchProgress = (completedSamples + inFlightProgress)
          .clamp(0.0, batchSize.toDouble())
          .toDouble();
      return ((currentStart - 1) + batchProgress) / total;
    }

    void clearRememberedPreviewsForRequest(int count) {
      for (var i = 0; i < count; i++) {
        _clearRememberedStreamPreview(
          generationRunId: generationRunId,
          imageNumber: currentStart + i,
        );
      }
    }

    _BatchStreamResult delivered(
      Map<int, Uint8List> finalImages, [
      Object? error,
    ]) {
      final indices = finalImages.keys.toList()..sort();
      for (final index in indices) {
        _clearRememberedStreamPreview(
          generationRunId: generationRunId,
          imageNumber: imageNumberForSample(index),
        );
      }
      final interrupted = !hasAllRequestedImages(
        received: finalImages.length,
        requested: batchSize,
      );
      if (interrupted) {
        _appendFailedStreamSnapshotsForCurrentSlots(generationRunId);
      }
      clearRememberedPreviewsForRequest(batchSize);
      return (
        images: [for (final index in indices) (index, finalImages[index]!)],
        interruption: interrupted
            ? error ??
                  const GenerationStreamError(
                    'No final image received from stream',
                    source: ImageStreamErrorSource.noFinalImage,
                  )
            : null,
      );
    }

    Future<_BatchStreamResult> runNonStreamFallback() async {
      final images = await apiService.generateImageCancellable(
        requestParams,
        onProgress: (_, __) {},
      );
      if (_shouldAbortGenerationRun(generationRunId) || images.isEmpty) {
        return empty;
      }
      return delivered(images.asMap());
    }

    final initialSlots = [
      for (var i = 0; i < batchSize; i++)
        StreamPreviewSlot(
          imageNumber: currentStart + i,
          totalImages: total,
          progress: 0.0,
        ),
    ];
    state = state.copyWith(
      currentImage: currentStart,
      progress: progressForBatch(completedSamples: 0),
      streamPreviewSlots: initialSlots,
      clearStreamPreview: true,
    );

    for (int retry = 0; retry <= _maxRetries; retry++) {
      final finalImages = <int, Uint8List>{};

      try {
        if (useNonStreamFallback) {
          return await runNonStreamFallback();
        }

        await for (final chunk in apiService.generateImageStream(
          requestParams,
        )) {
          if (_shouldAbortGenerationRun(generationRunId)) {
            return empty;
          }

          if (chunk.hasError) {
            if (finalImages.isEmpty &&
                _isStreamingNotAllowed(chunk.error ?? '')) {
              AppLogger.w(
                'Streaming not allowed, falling back to non-stream API',
                'Generation',
              );
              useNonStreamFallback = true;
              break;
            }
            throw GenerationStreamError(
              chunk.error!,
              retryAfter: chunk.retryAfter,
              source: chunk.errorSource,
            );
          }

          final imageNumber = imageNumberForSample(chunk.sampleIndex);
          if (chunk.hasPreview) {
            _rememberStreamPreview(
              bytes: chunk.previewImage!,
              params: requestParams,
              generationRunId: generationRunId,
              imageNumber: imageNumber,
              inpaintPreviewPlacement: chunk.inpaintPreviewPlacement,
            );
            final slot = StreamPreviewSlot(
              imageNumber: imageNumber,
              totalImages: total,
              progress: chunk.progress.clamp(0.0, 0.99).toDouble(),
              previewBytes: chunk.previewImage,
              inpaintPreviewPlacement: chunk.inpaintPreviewPlacement,
            );
            state = state.copyWith(
              currentImage: imageNumber,
              progress: progressForBatch(
                completedSamples: finalImages.length,
                inFlightProgress: slot.progress,
              ),
              streamPreview: chunk.previewImage,
              inpaintPreviewPlacement: chunk.inpaintPreviewPlacement,
              streamPreviewSlots: _replaceStreamPreviewSlot(
                state.streamPreviewSlots,
                slot,
              ),
            );
          }

          if (chunk.isComplete && chunk.hasFinalImage) {
            finalImages[chunk.sampleIndex] = chunk.finalImage!;
            if (chunk.vibeEncodings?.isNotEmpty == true) {
              _saveVibeEncodings(chunk.vibeEncodings!);
            }
            _rememberStreamPreview(
              bytes: chunk.finalImage!,
              params: requestParams,
              generationRunId: generationRunId,
              imageNumber: imageNumber,
            );
            final slot = StreamPreviewSlot(
              imageNumber: imageNumber,
              totalImages: total,
              progress: 1.0,
              previewBytes: chunk.finalImage,
            );
            state = state.copyWith(
              currentImage: imageNumber,
              progress: progressForBatch(completedSamples: finalImages.length),
              streamPreview: chunk.finalImage,
              clearInpaintPreviewPlacement: true,
              streamPreviewSlots: _replaceStreamPreviewSlot(
                state.streamPreviewSlots,
                slot,
              ),
            );
          }
        }

        if (_shouldAbortGenerationRun(generationRunId)) {
          return empty;
        }

        if (finalImages.isNotEmpty) return delivered(finalImages);
        final fallback = await runNonStreamFallback();
        if (fallback.images.isNotEmpty) return fallback;
      } catch (e) {
        if (_isCancelledError(e, generationRunId)) {
          _appendFailedStreamSnapshotsForCurrentSlots(generationRunId);
          return empty;
        }
        if (finalImages.isNotEmpty) return delivered(finalImages, e);
        if (_isRemoteCancelledError(e, generationRunId)) {
          _appendFailedStreamSnapshotsForCurrentSlots(generationRunId);
          rethrow;
        }
        if (_isConcurrencyLimited(e)) rethrow; // 交给上层等待并发额度释放

        if (_isStreamingNotAllowed(e.toString())) {
          AppLogger.w(
            'Streaming not allowed (exception), falling back to non-stream API',
            'Generation',
          );
          useNonStreamFallback = true;
          try {
            final fallback = await runNonStreamFallback();
            if (fallback.images.isNotEmpty) return fallback;
          } catch (fallbackError) {
            _appendFailedStreamSnapshotsForCurrentSlots(generationRunId);
            AppLogger.e('非流式回退生成失败: $fallbackError');
          }
          break;
        }

        if (retry < _maxRetries && _isRetryableFailure(e)) {
          AppLogger.w(
            '生成失败，${_retryDelays[retry]}ms 后重试 (${retry + 1}/$_maxRetries): $e',
          );
          await _waitBeforeRetry(Duration(milliseconds: _retryDelays[retry]));
          if (_shouldAbortGenerationRun(generationRunId)) {
            return empty;
          }
        } else {
          AppLogger.e('生成第 $currentStart 批图像失败: $e');
          _appendFailedStreamSnapshotsForCurrentSlots(generationRunId);
          rethrow;
        }
      }
    }

    _appendFailedStreamSnapshotsForCurrentSlots(generationRunId);
    return empty;
  }

  /// 生成单张（使用流式 API 支持渐进式预览）
  ///
  /// [rejectedBatches]：重试只剩这一张要补时，停下之前被 400 跳过的请求；出完
  /// 了照样记进状态，画布说明跳过了几次。
  Future<void> _generateSingle(
    ImageParams params,
    int current,
    int total,
    int generationRunId, {
    GenerationConcurrencyBackoff? concurrencyBackoff,
    GenerationRejectedBatches? rejectedBatches,
  }) async {
    if (_shouldAbortGenerationRun(generationRunId)) return;

    state = state.copyWith(
      status: GenerationStatus.generating,
      progress: 0.0,
      errorMessage: null,
      currentImage: current,
      totalImages: total,
      clearStreamPreview: true,
      streamPreviewSlots: [
        StreamPreviewSlot(
          imageNumber: current,
          totalImages: total,
          progress: 0,
        ),
      ],
    );

    try {
      final apiService = ref.read(naiImageGenerationApiServiceProvider);

      final stream = apiService.generateImageStream(params);

      final finalImages = <int, Uint8List>{};
      bool streamingNotAllowed = false;

      await for (final chunk in stream) {
        if (_shouldAbortGenerationRun(generationRunId)) return;

        if (chunk.hasError) {
          if (_isStreamingNotAllowed(chunk.error ?? '')) {
            AppLogger.w(
              'Streaming not allowed, falling back to non-stream API',
              'Generation',
            );
            streamingNotAllowed = true;
            break;
          }
          String? stopError;
          if (_isConcurrencyLimited(chunk.error!)) {
            // 并发限制：等 NAI 释放额度后自动重试（取消可随时中断）
            final backoff =
                concurrencyBackoff ?? GenerationConcurrencyBackoff();
            final delay = backoff.nextDelay(retryAfter: chunk.retryAfter);
            if (delay != null) {
              AppLogger.w(
                'NAI 并发限制(429)，${_formatRetryDelay(delay)} 后自动重试',
                'Generation',
              );
              await _waitBeforeRetry(delay);
              if (_shouldAbortGenerationRun(generationRunId)) return;
              return await _generateSingle(
                params,
                current,
                total,
                generationRunId,
                concurrencyBackoff: backoff,
                rejectedBatches: rejectedBatches,
              );
            }
            // 等满了：停下并说明原因。
            stopError = generationConcurrencyStoppedError(chunk.error!);
            AppLogger.w(
              'NAI 并发限制(429)：本次已等 ${_formatRetryDelay(backoff.waited)}，停止生成',
              'Generation',
            );
          }
          _appendFailedStreamSnapshotToHistory(
            generationRunId: generationRunId,
            imageNumber: current,
          );
          state = state.copyWith(
            status: GenerationStatus.error,
            errorMessage: stopError ?? chunk.error,
            progress: 0.0,
            currentImage: 0,
            totalImages: 0,
            clearStreamPreview: true,
          );
          return;
        }

        if (chunk.hasPreview) {
          // 更新流式预览
          if (_shouldAbortGenerationRun(generationRunId)) return;
          _rememberStreamPreview(
            bytes: chunk.previewImage!,
            params: params,
            generationRunId: generationRunId,
            imageNumber: current,
            inpaintPreviewPlacement: chunk.inpaintPreviewPlacement,
          );
          state = state.copyWith(
            progress: chunk.progress,
            streamPreview: chunk.previewImage,
            inpaintPreviewPlacement: chunk.inpaintPreviewPlacement,
            streamPreviewSlots: [
              StreamPreviewSlot(
                imageNumber: current,
                totalImages: total,
                progress: chunk.progress,
                previewBytes: chunk.previewImage,
                inpaintPreviewPlacement: chunk.inpaintPreviewPlacement,
              ),
            ],
          );
        }

        if (chunk.isComplete && chunk.hasFinalImage) {
          finalImages[chunk.sampleIndex] = chunk.finalImage!;
          if (chunk.vibeEncodings?.isNotEmpty == true) {
            _saveVibeEncodings(chunk.vibeEncodings!);
          }
          _rememberStreamPreview(
            bytes: chunk.finalImage!,
            params: params,
            generationRunId: generationRunId,
            imageNumber: current,
          );
          state = state.copyWith(
            progress: 1.0,
            streamPreview: chunk.finalImage,
            clearInpaintPreviewPlacement: true,
            streamPreviewSlots: [
              StreamPreviewSlot(
                imageNumber: current,
                totalImages: total,
                progress: 1,
                previewBytes: chunk.finalImage,
              ),
            ],
          );
        }
      }

      // 如果流式不被支持，回退到非流式 API
      if (streamingNotAllowed) {
        final (imageBytes, vibeEncodings) = await _generateWithRetry(
          params,
          generationRunId,
        );
        if (_shouldAbortGenerationRun(generationRunId)) return;
        if (imageBytes.isEmpty) {
          throw Exception('No images returned from generation');
        }
        final generatedList = await _completeGeneratedImages(
          imageBytes.indexed,
          params,
          generationRunId,
          offset: 0,
        );
        if (_shouldAbortGenerationRun(generationRunId)) return;
        state = state.copyWith(
          status: GenerationStatus.completed,
          rejectedBatches: rejectedBatches,
          currentImages: generatedList,
          displayImages: generatedList,
          displayWidth: generatedList.first.width,
          displayHeight: generatedList.first.height,
          history: _prependCompletedHistory(generatedList),
          progress: 1.0,
          currentImage: 0,
          totalImages: 0,
          clearStreamPreview: true,
        );
        _retainSharePreparationCacheForCurrentHistory();
        _clearRememberedStreamPreview(
          generationRunId: generationRunId,
          imageNumber: current,
        );
        // 保存 Vibe 编码哈希到状态
        if (vibeEncodings.isNotEmpty) {
          _saveVibeEncodings(vibeEncodings);
        }
        // 自动保存
        await _autoSaveIfEnabled(generatedList, params);
        // 后台预解析元数据（不阻塞）
        _preloadMetadataInBackground(generatedList);
        return;
      }

      if (finalImages.isNotEmpty) {
        if (_shouldAbortGenerationRun(generationRunId)) return;
        final orderedImages = finalImages.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        final generatedList = await _completeGeneratedImages(
          orderedImages.map((entry) => (entry.key, entry.value)),
          params,
          generationRunId,
          offset: 0,
        );
        if (_shouldAbortGenerationRun(generationRunId)) return;
        state = state.copyWith(
          status: GenerationStatus.completed,
          rejectedBatches: rejectedBatches,
          currentImages: generatedList,
          displayImages: generatedList,
          displayWidth: generatedList.first.width,
          displayHeight: generatedList.first.height,
          history: _prependCompletedHistory(generatedList),
          progress: 1.0,
          currentImage: 0,
          totalImages: 0,
          clearStreamPreview: true,
        );
        _retainSharePreparationCacheForCurrentHistory();
        _clearRememberedStreamPreview(
          generationRunId: generationRunId,
          imageNumber: current,
        );
        // 自动保存
        await _autoSaveIfEnabled(generatedList, params);
        // 后台预解析元数据（不阻塞）
        _preloadMetadataInBackground(generatedList);
      } else {
        // 流式 API 未返回图像，回退到非流式 API
        AppLogger.w(
          'Stream API returned no image, falling back to non-stream API',
          'Generation',
        );
        final (imageBytes, vibeEncodings) = await _generateWithRetry(
          params,
          generationRunId,
        );
        if (_shouldAbortGenerationRun(generationRunId)) return;
        if (imageBytes.isEmpty) {
          throw Exception('No images returned from generation');
        }
        final generatedList = await _completeGeneratedImages(
          imageBytes.indexed,
          params,
          generationRunId,
          offset: 0,
        );
        if (_shouldAbortGenerationRun(generationRunId)) return;
        state = state.copyWith(
          status: GenerationStatus.completed,
          rejectedBatches: rejectedBatches,
          currentImages: generatedList,
          displayImages: generatedList,
          displayWidth: generatedList.first.width,
          displayHeight: generatedList.first.height,
          history: _prependCompletedHistory(generatedList),
          progress: 1.0,
          currentImage: 0,
          totalImages: 0,
          clearStreamPreview: true,
        );
        _retainSharePreparationCacheForCurrentHistory();
        _clearRememberedStreamPreview(
          generationRunId: generationRunId,
          imageNumber: current,
        );
        // 保存 Vibe 编码哈希到状态
        if (vibeEncodings.isNotEmpty) {
          _saveVibeEncodings(vibeEncodings);
        }
        // 自动保存
        await _autoSaveIfEnabled(generatedList, params);
        // 后台预解析元数据（不阻塞）
        _preloadMetadataInBackground(generatedList);
      }
    } catch (e) {
      if (_isCancelledError(e, generationRunId)) {
        if (_isCurrentGenerationRun(generationRunId)) {
          _appendFailedStreamSnapshotToHistory(
            generationRunId: generationRunId,
            imageNumber: current,
          );
          state = state.copyWith(
            status: GenerationStatus.cancelled,
            progress: 0.0,
            currentImage: 0,
            totalImages: 0,
            clearStreamPreview: true,
          );
        }
      } else if (_isConcurrencyLimited(e)) {
        // 并发限制：等 NAI 释放额度后自动重试（取消可随时中断）
        final backoff = concurrencyBackoff ?? GenerationConcurrencyBackoff();
        final delay = backoff.nextDelay(retryAfter: generationRetryAfterOf(e));
        if (delay == null) {
          // 等满了：停下并说明原因。
          if (!_isCurrentGenerationRun(generationRunId)) return;
          AppLogger.w(
            'NAI 并发限制(429)：本次已等 ${_formatRetryDelay(backoff.waited)}，停止生成',
            'Generation',
          );
          _appendFailedStreamSnapshotToHistory(
            generationRunId: generationRunId,
            imageNumber: current,
          );
          state = state.copyWith(
            status: GenerationStatus.error,
            errorMessage: generationConcurrencyStoppedError(e),
            progress: 0.0,
            currentImage: 0,
            totalImages: 0,
            clearStreamPreview: true,
          );
          return;
        }
        AppLogger.w(
          'NAI 并发限制(429)，${_formatRetryDelay(delay)} 后自动重试',
          'Generation',
        );
        await _waitBeforeRetry(delay);
        if (_shouldAbortGenerationRun(generationRunId)) return;
        return _generateSingle(
          params,
          current,
          total,
          generationRunId,
          concurrencyBackoff: backoff,
          rejectedBatches: rejectedBatches,
        );
      } else if (_isStreamingNotAllowed(e.toString())) {
        AppLogger.w(
          'Streaming not allowed (exception), falling back to non-stream API',
          'Generation',
        );
        try {
          final (imageBytes, vibeEncodings) = await _generateWithRetry(
            params,
            generationRunId,
          );
          if (_shouldAbortGenerationRun(generationRunId)) return;
          if (imageBytes.isEmpty) {
            throw Exception('No images returned from generation');
          }
          final generatedList = await _completeGeneratedImages(
            imageBytes.indexed,
            params,
            generationRunId,
            offset: 0,
          );
          if (_shouldAbortGenerationRun(generationRunId)) return;
          state = state.copyWith(
            status: GenerationStatus.completed,
            rejectedBatches: rejectedBatches,
            currentImages: generatedList,
            displayImages: generatedList,
            displayWidth: generatedList.first.width,
            displayHeight: generatedList.first.height,
            history: _prependCompletedHistory(generatedList),
            progress: 1.0,
            currentImage: 0,
            totalImages: 0,
            clearStreamPreview: true,
          );
          _retainSharePreparationCacheForCurrentHistory();
          _clearRememberedStreamPreview(
            generationRunId: generationRunId,
            imageNumber: current,
          );
          if (vibeEncodings.isNotEmpty) {
            _saveVibeEncodings(vibeEncodings);
          }
          await _autoSaveIfEnabled(generatedList, params);
          if (_shouldAbortGenerationRun(generationRunId)) return;
          // 后台预解析元数据（不阻塞）
          _preloadMetadataInBackground(generatedList);
        } catch (fallbackError) {
          if (_isCancelledError(fallbackError, generationRunId) ||
              !_isCurrentGenerationRun(generationRunId)) {
            if (_isCurrentGenerationRun(generationRunId)) {
              _appendFailedStreamSnapshotToHistory(
                generationRunId: generationRunId,
                imageNumber: current,
              );
            }
            return;
          }
          _appendFailedStreamSnapshotToHistory(
            generationRunId: generationRunId,
            imageNumber: current,
          );
          state = state.copyWith(
            status: GenerationStatus.error,
            errorMessage: fallbackError.toString(),
            progress: 0.0,
            currentImage: 0,
            totalImages: 0,
            clearStreamPreview: true,
          );
        }
      } else {
        if (!_isCurrentGenerationRun(generationRunId)) return;
        _appendFailedStreamSnapshotToHistory(
          generationRunId: generationRunId,
          imageNumber: current,
        );
        state = state.copyWith(
          status: GenerationStatus.error,
          errorMessage: e.toString(),
          progress: 0.0,
          currentImage: 0,
          totalImages: 0,
          clearStreamPreview: true,
        );
      }
    }
  }

  /// 取消当前请求并停止后续生成。
  void cancel() {
    final generationRunId = _activeGenerationRunId;
    final apiService = ref.exists(naiImageGenerationApiServiceProvider)
        ? ref.read(naiImageGenerationApiServiceProvider)
        : null;

    final pendingImages = _pendingLocalEnhanceImages;
    _pendingLocalEnhanceImages = [];
    if (pendingImages.isNotEmpty) {
      state = state.copyWith(
        currentImages: [...state.currentImages, ...pendingImages],
        history: _prependCompletedHistory(pendingImages),
      );
    }

    _appendFailedStreamSnapshotsForCurrentSlots(generationRunId);
    _invalidateGenerationRun();
    if (_activeLocalEnhance != null && ref.exists(localUpscaleTaskProvider)) {
      ref.read(localUpscaleTaskProvider.notifier).cancel();
    }
    apiService?.cancelGeneration();

    state = state.copyWith(
      status: GenerationStatus.cancelled,
      progress: 0.0,
      currentImage: 0,
      totalImages: 0,
      clearStreamPreview: true,
    );
  }

  /// 清除当前图像
  void clearCurrent() {
    state = state.copyWith(currentImages: [], status: GenerationStatus.idle);
    _retainSharePreparationCacheForCurrentHistory();
  }

  /// 清除错误（失败卡上的“关闭”）。批量出完、只是有几批被拒跳过的说明也收
  /// 起，状态和出好的图不动。
  void clearError() {
    if (state.status == GenerationStatus.error) {
      state = state.copyWith(status: GenerationStatus.idle, errorMessage: null);
    } else if (state.rejectedBatches != null) {
      state = state.copyWith(
        clearRejectedBatches: true,
        errorMessage: state.errorMessage,
      );
    }
  }

  /// 清除历史记录（包含当前批次图像）
  void clearHistory() {
    state = state.copyWith(
      currentImages: [],
      history: [],
      errorMessage: state.errorMessage,
    );
    _retainSharePreparationCacheForCurrentHistory();
  }

  /// 从历史/当前批次/显示列表中移除指定图像（官网底栏 delete image(s)）。
  /// 只移除内存记录；已保存到磁盘的文件保留不删。
  void removeImages(Set<String> imageIds) {
    if (imageIds.isEmpty) return;
    state = state.copyWith(
      currentImages: state.currentImages
          .where((img) => !imageIds.contains(img.id))
          .toList(),
      history: state.history
          .where((img) => !imageIds.contains(img.id))
          .toList(),
      displayImages: state.displayImages
          .where((img) => !imageIds.contains(img.id))
          .toList(),
      // 删图不改状态：失败卡上的说明（比如 429 停下的原因）要留着。
      errorMessage: state.errorMessage,
    );
    _retainSharePreparationCacheForCurrentHistory();
  }

  /// 更新显示图像列表
  ///
  /// 用于保存图像后更新 filePath 等信息
  void updateDisplayImages(List<GeneratedImage> images) {
    state = state.copyWith(
      displayImages: images,
      errorMessage: state.errorMessage,
    );
  }

  /// 更新指定生成图像的本地文件路径。
  void updateImageFilePath(String imageId, String filePath) {
    GeneratedImage? image;
    for (final candidate in [
      ...state.currentImages,
      ...state.history,
      ...state.displayImages,
    ]) {
      if (candidate.id == imageId) {
        image = candidate;
        break;
      }
    }

    if (image == null || image.filePath == filePath) return;
    _updateImageInState(imageId, image.copyWithFilePath(filePath));
  }

  /// 更新状态中的单个图像
  ///
  /// 用于自动保存后更新图像的 filePath
  void _updateImageInState(String imageId, GeneratedImage updatedImage) {
    // 更新 currentImages
    final updatedCurrentImages = state.currentImages.map((img) {
      return img.id == imageId ? updatedImage : img;
    }).toList();

    // 更新 history
    final updatedHistory = state.history.map((img) {
      return img.id == imageId ? updatedImage : img;
    }).toList();

    // 更新 displayImages
    final updatedDisplayImages = state.displayImages.map((img) {
      return img.id == imageId ? updatedImage : img;
    }).toList();

    state = state.copyWith(
      currentImages: updatedCurrentImages,
      history: updatedHistory,
      displayImages: updatedDisplayImages,
      // 保存已出的图不改状态，失败卡上的说明（比如 429 停下的原因）要留着。
      errorMessage: state.errorMessage,
    );
    _retainSharePreparationCacheForCurrentHistory();

    AppLogger.d(
      'Updated filePath for image $imageId: ${updatedImage.filePath}',
      'AutoSave',
    );
  }

  /// 将 UI 层的角色提示词配置转换为 API 层的格式
  ///
  /// [config] UI 层的角色提示词配置
  /// 返回 API 层的 CharacterPrompt 列表
  ///
  /// 注意：此方法会统一解析角色提示词中的别名
  List<CharacterPrompt> _convertCharactersToApiFormat(
    ui_character.CharacterPromptConfig config,
  ) {
    final aliasResolver = ref.read(aliasResolverServiceProvider.notifier);
    return CharacterConversionService(
      aliasResolver: aliasResolver.resolveAliases,
    ).convert(config).characters;
  }

  // ============================================================
  // 后台元数据解析（生成完成后立即启动）
  // ============================================================

  /// 后台并行解析图像元数据
  ///
  /// 在图像生成完成后立即启动，将图像加入预加载队列。
  /// 队列会按顺序处理，支持连续生成多张图像时的排队机制。
  /// 这样用户打开详情页时元数据已经准备好了，无需等待。
  void _preloadMetadataInBackground(List<GeneratedImage> images) {
    if (images.isEmpty) return;

    final service = ImageMetadataService();

    AppLogger.d(
      'Enqueuing ${images.length} images for metadata preloading',
      'MetadataPreload',
    );

    // 将图像加入预加载队列
    for (final image in images) {
      service.enqueuePreload(
        taskId: image.id,
        filePath: image.filePath,
        bytes: image.filePath == null ? image.bytes : null,
      );
    }

    // 输出队列状态
    final status = service.getPreloadQueueStatus();
    AppLogger.d(
      'Preload queue status: length=${status['queueLength']}, '
          'processing=${status['processingCount']}, isProcessing=${status['isProcessing']}',
      'MetadataPreload',
    );
  }

  (int, int)? _resolveImageSize(
    Uint8List imageBytes, {
    int? width,
    int? height,
  }) {
    final encodedSize = NaiResolutionAdapter.readImageSize(imageBytes);
    if (encodedSize != null) {
      return encodedSize;
    }

    if (width != null && height != null) {
      return (width, height);
    }

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      return null;
    }

    return (decoded.width, decoded.height);
  }
}
