import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/model_spec.dart';
import '../../data/models/image/image_operation.dart';
import '../../data/models/image/image_params.dart';
import '../../data/models/image/resolution_preset.dart';
import '../providers/generation/generation_models.dart';
import '../providers/generation/preview_selection_provider.dart';
import '../screens/generation/widgets/history_batch.dart';
import '../ui/gen/gen_contract.dart';
import '../ui/gen/gen_page.dart';

({double left, double right}) generationCanvasInsets(
  GenLayout layout,
  double width,
) {
  final dock = layout.dockOpen ? GenerationPage.dockWidth : 0.0;
  var left = layout.leftOpen
      ? layout.leftWidth.clamp(GenLayout.minLeft, GenLayout.maxLeft)
      : GenerationPage.strip;
  var right = layout.historyOpen
      ? layout.historyWidth.clamp(GenLayout.minHistory, GenLayout.maxHistory)
      : GenerationPage.strip;
  if (width - left - dock - right < GenerationPage.minCanvas &&
      layout.historyOpen) {
    right = GenerationPage.strip;
  }
  if (width - left - dock - right < GenerationPage.minCanvas &&
      layout.leftOpen) {
    left = math.max(
      GenLayout.minLeft,
      width - dock - right - GenerationPage.minCanvas,
    );
  }
  return (left: left + dock, right: right);
}

String generationBatchKey(GeneratedImage image) =>
    image.generationRunId != null && image.generationRunId! > 0
    ? 'run:${image.generationRunId}'
    : 'img:${image.id}';

double resolveHistoryPreviewAspectRatio(
  double aspectRatio, {
  double fallback = 1.0,
}) {
  if (!aspectRatio.isFinite || aspectRatio <= 0) {
    return fallback;
  }
  return aspectRatio;
}

double resolveCurrentHistoryPreviewAspectRatio(
  double batchAspectRatio, {
  double? completedImageAspectRatio,
}) {
  return resolveHistoryPreviewAspectRatio(
    completedImageAspectRatio ?? batchAspectRatio,
    fallback: resolveHistoryPreviewAspectRatio(batchAspectRatio),
  );
}

GenParamsData generationParamsView(ImageParams params, {int? lastSeed}) {
  final spec = ModelSpecs.of(params.model);
  final supportsSmea =
      params.isV3Model &&
      spec.smea &&
      params.sampler != Samplers.ddim &&
      params.sampler != Samplers.ddimV3;
  return GenParamsData(
    fixedSampling: spec.isTurbo,
    cfgRescaleSupported: spec.cfgRescale,
    steps: params.effectiveSteps,
    scale: params.scale,
    cfgRescale: params.effectiveCfgRescale,
    seed: params.seed == -1 ? lastSeed : params.seed,
    seedPinned: params.seed != -1,
    sampler: params.effectiveSampler,
    samplers: [
      for (final sampler in Samplers.samplersForModel(params.model))
        GenOption(
          id: sampler,
          label: Samplers.samplerDisplayNames[sampler] ?? sampler,
          detail: Samplers.recommendedSamplers.contains(sampler) ? '' : null,
        ),
    ],
    noise: spec.noiseSchedule ? params.noiseSchedule : null,
    noises: spec.noiseSchedule
        ? [
            for (final noise in NoiseSchedules.all)
              GenOption(
                id: noise,
                label: NoiseSchedules.displayNames[noise] ?? noise,
              ),
          ]
        : const [],
    varietyPlus: spec.varietyPlus ? params.varietyPlus : null,
    decrisp: params.isV3Model ? params.decrisp : null,
    smea: supportsSmea
        ? GenSmea(auto: params.smeaAuto, smea: params.smea, dyn: params.smeaDyn)
        : null,
  );
}

GenImageData generationImageView(
  ImageParams params, {
  required int imagesPerRequest,
}) => GenImageData(
  width: params.width,
  height: params.height,
  count: imagesPerRequest,
  repeat: params.nSamples,
  maxRepeat: math.max(99, params.nSamples),
  presets: [
    for (final preset in ResolutionPreset.presets)
      if (preset.type != ResolutionType.custom)
        GenSizePreset(
          GenSizeGroup.values.byName(preset.group.name),
          GenOrientation.values.byName(preset.type.name),
          preset.width,
          preset.height,
        ),
  ],
);

GenOp? generationOperation(ImageOperation? operation) => switch (operation) {
  ImageOperation.upscale => GenOp.upscale,
  ImageOperation.enhance => GenOp.enhance,
  ImageOperation.variations => GenOp.variation,
  ImageOperation.inpaint => GenOp.inpaint,
  ImageOperation.imageToImage => GenOp.img2img,
  _ => null,
};

GenHistoryData generationHistoryView(
  ImageGenerationState state, {
  String? selected,
  Set<String> favorites = const {},
  bool autoSave = true,
  int pinned = 0,
  DateTime? now,
  bool singleImages = false,
}) {
  final batches = buildHistoryBatches(state)
      .expand(
        (batch) => singleImages && !batch.isGenerating
            ? batch.images.map(
                (image) => HistoryBatch(
                  key: 'img:${image.id}',
                  images: [image],
                  isGenerating: false,
                  count: 1,
                ),
              )
            : [batch],
      )
      .toList();
  DateTime time(HistoryBatch batch) => batch.images.isEmpty
      ? now ?? DateTime.now()
      : batch.images
            .map((image) => image.createdAt)
            .reduce((a, b) => a.isBefore(b) ? a : b)
            .toLocal();
  batches.sort((a, b) {
    if (a.isGenerating != b.isGenerating) return a.isGenerating ? -1 : 1;
    return time(b).compareTo(time(a));
  });
  return GenHistoryData(
    selected: selected,
    autoSave: autoSave,
    pinned: pinned,
    batches: [
      for (final batch in batches)
        GenBatch(
          id: batch.key,
          time: time(batch),
          images: [
            for (final image in batch.images)
              GenHistoryImage(
                id: image.id,
                thumb: MemoryImage(image.bytes),
                width: image.width,
                height: image.height,
                favorite: favorites.contains(image.id),
                op: generationOperation(image.operation),
              ),
          ],
          pendingPreview: batch.isGenerating
              ? _historyPendingPreview(state, batch)
              : null,
          pending: math.max(0, batch.count - batch.images.length),
          pendingWidth: batch.isGenerating
              ? state.batchWidth ?? state.displayWidth
              : null,
          pendingHeight: batch.isGenerating
              ? state.batchHeight ?? state.displayHeight
              : null,
        ),
    ],
  );
}

// Weak keys keep old streaming frames collectible while sharing providers with
// the canvas for the same immutable byte buffer.
final _previewImages = Expando<MemoryImage>();
MemoryImage? _previewImage(Uint8List? bytes) => bytes == null || bytes.isEmpty
    ? null
    : _previewImages[bytes] ??= MemoryImage(bytes);

MemoryImage? _historyPendingPreview(
  ImageGenerationState state,
  HistoryBatch batch,
) {
  final done = <int>{};
  var next = 0;
  for (final image in batch.images.where(
    (image) => !image.isVariationOriginal,
  )) {
    while (done.contains(next)) {
      next++;
    }
    done.add(image.batchIndex ?? next++);
  }
  final index = Iterable<int>.generate(
    state.totalImages,
  ).where((index) => !done.contains(index)).firstOrNull;
  if (index == null) return null;
  final slot = state.streamPreviewSlots
      .where((slot) => slot.imageNumber == index + 1)
      .firstOrNull;
  return _previewImage(
    slot?.previewBytes ??
        (state.currentImage == index + 1 ? state.streamPreview : null),
  );
}

GenTile generationTileView(GeneratedImage image) => GenTile(
  id: image.id,
  width: image.width,
  height: image.height,
  image: MemoryImage(image.bytes),
  originalImage: image.canCompareOriginal
      ? MemoryImage(image.originalBytes!)
      : null,
  inpaintMaskBytes: image.canCompareOriginal ? image.inpaintMaskBytes : null,
  state: image.isFailedStreamSnapshot ? GenTileState.failed : GenTileState.done,
);

GenGroup? generationFocusView(
  ImageGenerationState state, {
  CanvasFocus? focus,
  String? selectedImage,
  List<GeneratedImage> pinned = const [],
  bool singleImages = false,
}) {
  if (singleImages && !state.isGenerating) {
    final image =
        pinned.where((image) => image.id == selectedImage).firstOrNull ??
        state.findImageById(selectedImage) ??
        state.displayImages.lastOrNull ??
        state.mergedPanelImages.firstOrNull;
    if (image == null) return null;
    return GenGroup(id: 'img:${image.id}', tiles: [generationTileView(image)]);
  }
  final images = <String, GeneratedImage>{};
  for (final image in [...state.mergedPanelImages, ...state.displayImages]) {
    images.putIfAbsent(image.id, () => image);
  }
  final activeKey = state.isGenerating
      ? state.generationRunId == null
            ? 'inflight'
            : 'run:${state.generationRunId}'
      : null;
  var key = focus?.group;
  if (key != null && key.startsWith('pin:')) {
    final selected = pinned
        .where((image) => 'pin:${image.id}' == key)
        .firstOrNull;
    if (selected != null) {
      return GenGroup(id: key, tiles: [generationTileView(selected)]);
    }
    key = null;
  }
  if (key != null &&
      key != activeKey &&
      !images.values.any((image) => generationBatchKey(image) == key)) {
    key = null;
  }
  final fallback = state.displayImages.firstOrNull ?? images.values.firstOrNull;
  key ??= selectedImage != null && images.containsKey(selectedImage)
      ? generationBatchKey(images[selectedImage]!)
      : activeKey ?? (fallback == null ? null : generationBatchKey(fallback));
  if (key == null) return null;
  final members =
      images.values.where((image) => generationBatchKey(image) == key).toList()
        ..sort((a, b) => (a.batchIndex ?? 0).compareTo(b.batchIndex ?? 0));
  if (key != activeKey) {
    return GenGroup(id: key, tiles: members.map(generationTileView).toList());
  }
  final done = <int, GeneratedImage>{};
  var next = 0;
  for (final image in members.where((image) => !image.isVariationOriginal)) {
    while (done.containsKey(next)) {
      next++;
    }
    done[image.batchIndex ?? next++] = image;
  }
  final previews = {
    for (final slot in state.streamPreviewSlots) slot.imageNumber - 1: slot,
  };
  final total = math.max(
    state.totalImages,
    done.keys.fold(0, (max, value) => math.max(max, value + 1)),
  );
  return GenGroup(
    id: key,
    tiles: [
      for (final image in members.where((image) => image.isVariationOriginal))
        generationTileView(image),
      for (var index = 0; index < total; index++)
        if (done[index] case final image?)
          generationTileView(image)
        else
          _pendingTile(state, key, index, previews[index]),
    ],
  );
}

GenTile _pendingTile(
  ImageGenerationState state,
  String key,
  int index,
  StreamPreviewSlot? slot,
) {
  final current = state.currentImage == index + 1;
  final preview = slot?.previewBytes ?? (current ? state.streamPreview : null);
  final streaming =
      preview?.isNotEmpty == true || current || (slot?.progress ?? 0) > 0;
  return GenTile(
    id: 'slot:$key:$index',
    width: state.batchWidth ?? state.displayWidth ?? 832,
    height: state.batchHeight ?? state.displayHeight ?? 1216,
    preview: _previewImage(preview),
    state: streaming ? GenTileState.streaming : GenTileState.pending,
    progress: streaming ? (slot?.progress ?? state.progress).clamp(0, 1) : null,
  );
}
