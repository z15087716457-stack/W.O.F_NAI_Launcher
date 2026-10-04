import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import '../../../core/krita/krita_bridge_models.dart';
import '../../../core/models/image_generation_artifact.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/image/image_params.dart';
import '../../../core/krita/bridge_draft_guard.dart';
import '../../../data/models/image/image_stream_chunk.dart';

typedef KritaBridgeBaseParamsReader = ImageParams Function();
typedef KritaBridgeParamsPreparer =
    ImageParams Function(ImageParams params, Map<String, dynamic> overrides);
typedef KritaBridgePromptSnapshot = ({String prompt, String negativePrompt});
typedef KritaBridgePromptSnapshotReader =
    KritaBridgePromptSnapshot Function(ImageParams params);
typedef KritaBridgeBusyReader = bool Function();
typedef KritaBridgeSender = void Function(Map<String, dynamic> message);
typedef KritaBridgeStreamGenerator =
    Stream<ImageStreamChunk> Function(KritaBridgeGenerateRequest request);
typedef KritaBridgeFallbackGenerator =
    Future<List<ImageGenerationArtifact>> Function(
      KritaBridgeGenerateRequest request,
    );
typedef KritaBridgeExternalImageRegistrar =
    Future<String?> Function(
      Uint8List image, {
      required ImageParams params,
      bool? addToDisplay,
    });
typedef KritaBridgeCancelGeneration = void Function();
typedef KritaBridgeClock = DateTime Function();

class _BridgeQuote {
  const _BridgeQuote({
    required this.client,
    required this.account,
    required this.expires,
    required this.base,
    required this.prepared,
    required this.payload,
    required this.versions,
    required this.estimatedAnlas,
  });
  final String client;
  final String? account;
  final DateTime expires;
  final ImageParams base, prepared;
  final Map<String, dynamic> payload, versions;
  final Object? estimatedAnlas;
}

typedef KritaBridgeActiveRequestReporter = void Function(String? requestId);

/// AI 接管扩展：将 set_params 载荷写入 UI 参数状态，返回已应用的键列表。
typedef KritaBridgeParamsWriter =
    FutureOr<List<String>> Function(Map<String, dynamic> payload);

/// AI 接管扩展：读取种子锁状态（锁在 storage 而非 ImageParams）。
typedef KritaBridgeSeedLockReader = bool Function();

/// AI 接管扩展：读取 UI 角色框系统全量状态（get_params 回读用）。
typedef KritaBridgeCharactersReader = List<Map<String, dynamic>> Function();

/// AI 接管扩展：读取提示词 token 用量（与 UI 计数器同源，异步）。
typedef KritaBridgeTokensReader = Future<Map<String, dynamic>> Function();

abstract class KritaBridgeMessageService {
  Future<void> handle(KritaBridgeMessage message);

  void handleClientDisconnected();

  void setActiveRequestReporter(KritaBridgeActiveRequestReporter reporter) {}
}

class KritaBridgeGenerateRequest {
  const KritaBridgeGenerateRequest({required this.id, required this.params});

  final String id;
  final ImageParams params;
}

class KritaBridgeService implements KritaBridgeMessageService {
  KritaBridgeService({
    required KritaBridgeBaseParamsReader readBaseParams,
    required KritaBridgeSender send,
    required KritaBridgeBusyReader isUiGenerating,
    required KritaBridgeStreamGenerator generateStream,
    required KritaBridgeFallbackGenerator generateFallback,
    required KritaBridgeExternalImageRegistrar registerExternalImage,
    required KritaBridgeCancelGeneration cancelGeneration,
    void Function()? onGenerationEnqueued,
    KritaBridgeParamsPreparer? prepareParams,
    KritaBridgeParamsWriter? writeParams,
    KritaBridgeSeedLockReader? readSeedLock,
    KritaBridgeCharactersReader? readCharacters,
    KritaBridgeTokensReader? readTokens,
    KritaBridgePromptSnapshotReader? readPromptSnapshot,
    bool Function()? isAgentRequest,
    BridgeDraftSnapshot Function()? readDraft,
    Future<String> Function(BridgeDraftSnapshot)? backupDraft,
    Map<String, dynamic> Function(ImageParams)? readBilling,
    String Function()? requesterName,
    String? Function()? readAccountIdentity,
    bool Function()? isRequestAlive,
    KritaBridgeClock? clock,
    Duration failureCooldown = const Duration(seconds: 2),
  }) : _readBaseParams = readBaseParams,
       _readPromptSnapshot =
           readPromptSnapshot ??
           ((params) =>
               (prompt: params.prompt, negativePrompt: params.negativePrompt)),
       _send = send,
       _isUiGenerating = isUiGenerating,
       _generateStream = generateStream,
       _generateFallback = generateFallback,
       _registerExternalImage = registerExternalImage,
       _cancelGeneration = cancelGeneration,
       _onGenerationEnqueued = onGenerationEnqueued,
       _prepareParams = prepareParams ?? ((params, _) => params),
       _writeParams = writeParams,
       _readSeedLock = readSeedLock,
       _readCharacters = readCharacters,
       _readTokens = readTokens,
       _clock = clock ?? DateTime.now,
       _failureCooldown = failureCooldown,
       _isAgentRequest = isAgentRequest ?? (() => false),
       _readDraft = readDraft,
       _backupDraft = backupDraft,
       _readBilling = readBilling,
       _requesterName = requesterName ?? (() => 'External Agent'),
       _readAccountIdentity = readAccountIdentity,
       _isRequestAlive = isRequestAlive ?? (() => true);

  final KritaBridgeBaseParamsReader _readBaseParams;
  final KritaBridgePromptSnapshotReader _readPromptSnapshot;
  final KritaBridgeSender _send;
  final KritaBridgeBusyReader _isUiGenerating;
  final KritaBridgeStreamGenerator _generateStream;
  final KritaBridgeFallbackGenerator _generateFallback;
  final KritaBridgeExternalImageRegistrar _registerExternalImage;
  final KritaBridgeCancelGeneration _cancelGeneration;

  /// 请求参数冻结（mapping 已捕获）、确认受理后触发（P2.5 块实例随机：
  /// 本次请求用入队前的 roll，这里重 roll 让下一张/界面显示新内容）。
  final void Function()? _onGenerationEnqueued;
  final KritaBridgeParamsPreparer _prepareParams;
  final KritaBridgeParamsWriter? _writeParams;
  final KritaBridgeSeedLockReader? _readSeedLock;
  final KritaBridgeCharactersReader? _readCharacters;
  final KritaBridgeTokensReader? _readTokens;
  final KritaBridgeClock _clock;
  final Duration _failureCooldown;
  final bool Function() _isAgentRequest;
  final BridgeDraftSnapshot Function()? _readDraft;
  final Future<String> Function(BridgeDraftSnapshot)? _backupDraft;
  final Map<String, dynamic> Function(ImageParams)? _readBilling;
  final String Function() _requesterName;
  final String? Function()? _readAccountIdentity;
  final bool Function() _isRequestAlive;
  final _quotes = <String, _BridgeQuote>{};

  bool _isBridgeGenerating = false;
  String? _activeRequestId;
  bool _cancelled = false;
  DateTime? _failureCooldownUntil;
  KritaBridgeActiveRequestReporter? _activeRequestReporter;
  static const String _logTag = 'KritaBridge';

  bool get isBridgeGenerating => _isBridgeGenerating;

  @override
  void setActiveRequestReporter(KritaBridgeActiveRequestReporter reporter) {
    _activeRequestReporter = reporter;
  }

  @override
  void handleClientDisconnected() {
    if (!_isBridgeGenerating) {
      return;
    }

    _cancelled = true;
    _cancelGeneration();
    AppLogger.w(
      'Krita client disconnected during request $_activeRequestId; cancelled',
      _logTag,
    );
  }

  @override
  Future<void> handle(KritaBridgeMessage message) async {
    switch (message) {
      case KritaGetParamsMessage():
        await _sendParams(message);
      case KritaCancelMessage():
        _cancel(message);
      case KritaImg2ImgMessage():
        if (_isAgentRequest()) {
          _sendError(
            message.id,
            KritaBridgeErrorCode.invalidRequest,
            'Agents must quote the current image workflow before generating.',
          );
          return;
        }
        await _generate(message.id, message.toImageParams(_readBaseParams()));
      case KritaInpaintMessage():
        if (_isAgentRequest()) {
          _sendError(
            message.id,
            KritaBridgeErrorCode.invalidRequest,
            'Agents must quote the current image workflow before generating.',
          );
          return;
        }
        await _generate(message.id, message.toImageParams(_readBaseParams()));
      case KritaSetParamsMessage():
        await _setParams(message);
      case KritaGenerateMessage():
        if (_isAgentRequest() && message.payload['_authorized'] != true) {
          _sendError(
            message.id,
            KritaBridgeErrorCode.invalidRequest,
            'Generation requires explicit user authorization.',
          );
          return;
        }
        if (_isAgentRequest()) {
          final quote = _quotes.remove(message.payload['_quote_id']);
          final draft = _readDraft?.call();
          if (quote == null ||
              quote.client != _requesterName() ||
              quote.account != _readAccountIdentity?.call() ||
              _clock().isAfter(quote.expires) ||
              draft == null ||
              !draft.matches(draft.fields, quote.versions) ||
              _readBilling?.call(quote.prepared)['estimated_anlas'] !=
                  quote.estimatedAnlas ||
              _prepareParams(
                    applyKritaParamsOverlay(
                      quote.base,
                      quote.payload,
                    ).copyWith(nSamples: 1),
                    quote.payload,
                  ) !=
                  quote.prepared ||
              _readBaseParams() != quote.base) {
            _sendError(
              message.id,
              KritaBridgeErrorCode.conflict,
              'The quoted draft changed. Quote again before generating.',
            );
            return;
          }
          await _generate(
            message.id,
            KritaImageParamsMapping(params: quote.prepared),
            overrides: quote.payload,
            alreadyPrepared: true,
          );
          return;
        }
        await _generate(
          message.id,
          message.toImageParams(_readBaseParams()),
          overrides: message.payload,
        );
      case KritaPingMessage():
        break;
      case KritaQuoteMessage():
        try {
          validateBridgePatch(message.payload);
        } on FormatException {
          _sendError(
            message.id,
            KritaBridgeErrorCode.invalidRequest,
            'Invalid quote fields.',
          );
          return;
        }
        final base = _readBaseParams();
        final prepared = _prepareParams(
          applyKritaParamsOverlay(base, message.payload).copyWith(nSamples: 1),
          message.payload,
        );
        final random = Random.secure();
        final quoteId = base64UrlEncode(
          List.generate(24, (_) => random.nextInt(256)),
        );
        final versions = _readDraft?.call().fieldVersions ?? <String, String>{};
        _quotes.removeWhere((_, q) => _clock().isAfter(q.expires));
        if (_quotes.length >= 32) _quotes.remove(_quotes.keys.first);
        final billing = _readBilling?.call(prepared);
        _quotes[quoteId] = _BridgeQuote(
          client: _requesterName(),
          account: _readAccountIdentity?.call(),
          expires: _clock().add(const Duration(minutes: 5)),
          base: base,
          prepared: prepared,
          payload: Map.of(message.payload),
          versions: versions,
          estimatedAnlas: billing?['estimated_anlas'],
        );
        _send({
          'type': 'quote',
          'id': message.id,
          'payload': message.payload,
          'field_versions': versions,
          'quote_id': quoteId,
          'billing': billing,
          'quoted_at': _clock().toUtc().toIso8601String(),
        });
    }
  }

  Future<void> _setParams(KritaSetParamsMessage message) async {
    if (_isUiGenerating() || _isBridgeGenerating) {
      _sendError(
        message.id,
        KritaBridgeErrorCode.busy,
        'Launcher is already generating.',
      );
      return;
    }
    final writer = _writeParams;
    if (writer == null) {
      _sendError(
        message.id,
        KritaBridgeErrorCode.unsupportedMessage,
        'set_params is not supported by this build.',
      );
      return;
    }
    try {
      final patch = Map<String, dynamic>.from(message.payload)
        ..remove('_expected');
      validateBridgePatch(patch);
      String? backupPath;
      final expected = message.payload['_expected'];
      if (_isAgentRequest()) {
        final snapshot = _readDraft?.call();
        if (snapshot == null ||
            _backupDraft == null ||
            expected is! Map<String, dynamic>) {
          _sendError(
            message.id,
            KritaBridgeErrorCode.invalidRequest,
            'Read a draft snapshot and provide its field_versions before writing.',
          );
          return;
        }
        if (!snapshot.matches(patch, expected)) {
          _sendError(
            message.id,
            KritaBridgeErrorCode.conflict,
            'The edited fields have changed. Read the current draft again.',
          );
          return;
        }
        backupPath = await _backupDraft(snapshot);
        if (!_isRequestAlive()) return;
        if (!_readDraft!().matches(patch, expected)) {
          _sendError(
            message.id,
            KritaBridgeErrorCode.conflict,
            'The draft changed during backup. No fields were written.',
          );
          return;
        }
        if (_isUiGenerating()) {
          _sendError(
            message.id,
            KritaBridgeErrorCode.busy,
            'Launcher started generating. No fields were written.',
          );
          return;
        }
      }
      final applied = await writer(patch);
      _send({
        'type': 'params_set',
        'id': message.id,
        'applied': applied,
        if (backupPath != null) 'backup_path': backupPath,
      });
      AppLogger.i(
        'Applied set_params (${applied.length} keys): ${message.id}',
        _logTag,
      );
    } catch (error) {
      _sendError(
        message.id,
        KritaBridgeErrorCode.invalidRequest,
        'set_params failed: $error',
      );
    }
  }

  Future<void> _sendParams(KritaGetParamsMessage message) async {
    final tokens = _readTokens == null ? null : await _readTokens.call();
    final params = _readBaseParams();
    final promptSnapshot = _readPromptSnapshot(params);
    // 用局部变量 + collection-if 表达「值为 null 则整条省略」。
    // 等价写法 `'k': ?expr` 是 Dart 3.9 的 null-aware element，
    // build_runner 捆的 analyzer 尚不支持，会让四个 builder 全部报语法错。
    final seedLock = _readSeedLock?.call();
    final characters = _readCharacters?.call();
    _send({
      'type': 'params',
      'id': message.id,
      'prompt': promptSnapshot.prompt,
      'negative_prompt': promptSnapshot.negativePrompt,
      'model': params.model,
      'sampler': params.sampler,
      'steps': params.steps,
      'cfg_scale': params.scale,
      'seed': params.seed,
      'width': params.width,
      'height': params.height,
      'strength': params.strength,
      'noise': params.noise,
      'inpaint_strength': params.inpaintStrength,
      // AI 接管扩展：全量状态回读（键名与 set_params 对称，可 get→set 往返）
      'n_samples': params.nSamples,
      'noise_schedule': params.noiseSchedule,
      'cfg_rescale': params.cfgRescale,
      'uc_preset': params.ucPreset,
      'quality_toggle': params.effectiveQualityToggle,
      'quality_preset': params.effectiveQualityTagPreset.bridgeValue,
      'transparent_background': params.transparentBackground,
      'variety_plus': params.varietyPlus,
      'smea_auto': params.smeaAuto,
      'smea': params.smea,
      'smea_dyn': params.smeaDyn,
      'use_coords': params.useCoords,
      if (seedLock != null) 'seed_lock': seedLock,
      if (characters != null) 'characters': characters,
      // AI 接管扩展：UI 盲区三件套只读回读（桥接不可写，仅消除 get 盲区）
      'precise_references': [
        for (final r in params.preciseReferences)
          {
            'type': r.type.name,
            'strength': r.strength,
            'fidelity': r.fidelity,
            'enabled': r.enabled,
          },
      ],
      'vibe_references': [
        for (final v in params.vibeReferencesV4)
          {
            'name': v.displayName,
            'strength': v.strength,
            'info_extracted': v.infoExtracted,
            'enabled': v.enabled,
          },
      ],
      'img2img': params.sourceImage != null,
      if (tokens != null) ...tokens,
      if (_isAgentRequest() && _readDraft != null)
        '_draft': _readDraft().toJson(),
      if (_readBilling != null)
        'billing': _readBilling(params.copyWith(nSamples: 1)),
    });
    AppLogger.d('Sent params snapshot to Krita: ${message.id}', _logTag);
  }

  void _cancel(KritaCancelMessage message) {
    if (!_isBridgeGenerating || _activeRequestId != message.id) {
      _sendError(
        message.id,
        KritaBridgeErrorCode.invalidRequest,
        'No active Krita request matches this id.',
      );
      return;
    }

    _cancelled = true;
    _cancelGeneration();
    _send({'type': 'cancelled', 'id': message.id});
    AppLogger.i('Cancelled Krita request: ${message.id}', _logTag);
  }

  Future<void> _generate(
    String id,
    KritaImageParamsMapping mapping, {
    Map<String, dynamic> overrides = const {},
    bool alreadyPrepared = false,
  }) async {
    if (_isUiGenerating() || _isBridgeGenerating) {
      AppLogger.w('Rejected Krita request as busy: $id', _logTag);
      _sendError(
        id,
        KritaBridgeErrorCode.busy,
        'Launcher is already generating.',
      );
      return;
    }

    final cooldownUntil = _failureCooldownUntil;
    if (cooldownUntil != null && _clock().isBefore(cooldownUntil)) {
      AppLogger.w(
        'Rejected Krita request during failure cooldown: $id',
        _logTag,
      );
      _sendError(
        id,
        KritaBridgeErrorCode.rateLimited,
        'Please wait before retrying after a failed Krita request.',
      );
      return;
    }

    final request = KritaBridgeGenerateRequest(
      id: id,
      params: alreadyPrepared
          ? mapping.params
          : _prepareParams(mapping.params.copyWith(nSamples: 1), overrides),
    );

    // 角色、预设和规范化设置也已冻结，下一张的 roll 不影响流式或回退请求。
    _onGenerationEnqueued?.call();

    _isBridgeGenerating = true;
    _activeRequestId = id;
    _activeRequestReporter?.call(id);
    _cancelled = false;
    AppLogger.i(
      'Accepted Krita request: $id action=${request.params.action.name}',
      _logTag,
    );

    try {
      final artifact = await _generateImage(request);
      if (_cancelled) {
        _send({'type': 'cancelled', 'id': id});
        return;
      }
      if (artifact == null) {
        _startFailureCooldown();
        _sendError(
          id,
          KritaBridgeErrorCode.streamInterrupted,
          'Generation ended without a final image.',
        );
        return;
      }

      final savedPath = await _registerExternalImage(
        artifact.displayImageBytes,
        params: request.params,
        addToDisplay: true,
      );
      _sendResult(
        request,
        artifact.transparentPatchBytes ?? artifact.displayImageBytes,
        savedPath: savedPath,
      );
      AppLogger.i('Completed Krita request: ${request.id}', _logTag);
    } catch (error) {
      if (_cancelled) {
        _send({'type': 'cancelled', 'id': id});
      } else {
        final code = _mapErrorCode(error);
        AppLogger.e(
          'Krita request failed: $id code=${code.value}',
          null,
          null,
          _logTag,
        );
        _startFailureCooldown();
        _sendError(id, code, _publicErrorMessage(code));
      }
    } finally {
      _isBridgeGenerating = false;
      _activeRequestId = null;
      _activeRequestReporter?.call(null);
      _cancelled = false;
    }
  }

  Future<ImageGenerationArtifact?> _generateImage(
    KritaBridgeGenerateRequest request,
  ) async {
    if (_shouldUseDirectFallback(request)) {
      final fallback = await _generateFallback(request);
      return fallback.isEmpty ? null : fallback.first;
    }

    Uint8List? finalImage;
    var streamingUnsupported = false;

    try {
      await for (final chunk in _generateStream(request)) {
        if (_cancelled) {
          return null;
        }

        if (chunk.hasError) {
          if (_isStreamingUnsupported(chunk.error ?? '')) {
            streamingUnsupported = true;
            break;
          }
          throw Exception(chunk.error);
        }

        if (chunk.hasPreview) {
          _sendProgress(request, chunk);
        }

        if (chunk.isComplete && chunk.hasFinalImage) {
          finalImage = chunk.finalImage;
        }
      }
    } catch (error) {
      if (!_isStreamingUnsupported(error.toString())) {
        rethrow;
      }
      streamingUnsupported = true;
    }

    if (_cancelled) {
      return null;
    }

    if (!streamingUnsupported && finalImage != null) {
      return ImageGenerationArtifact(displayImageBytes: finalImage);
    }

    final fallback = await _generateFallback(request);
    if (_cancelled || fallback.isEmpty) {
      if (streamingUnsupported) {
        throw Exception(
          'streaming is not allowed and fallback did not return an image',
        );
      }
      return null;
    }
    AppLogger.i(
      'Used fallback generation for Krita request: ${request.id}',
      _logTag,
    );
    return fallback.first;
  }

  void _startFailureCooldown() {
    if (_failureCooldown <= Duration.zero) {
      _failureCooldownUntil = null;
      return;
    }
    _failureCooldownUntil = _clock().add(_failureCooldown);
  }

  void _sendProgress(
    KritaBridgeGenerateRequest request,
    ImageStreamChunk chunk,
  ) {
    _send({
      'type': 'progress',
      'id': request.id,
      if (chunk.currentStep != null) 'step': chunk.currentStep,
      if (chunk.totalSteps != null) 'total_steps': chunk.totalSteps,
      'progress': chunk.progress.clamp(0.0, 1.0),
      if (chunk.previewImage != null)
        'preview_image': base64Encode(chunk.previewImage!),
    });
  }

  void _sendResult(
    KritaBridgeGenerateRequest request,
    Uint8List image, {
    String? savedPath,
  }) {
    _send({
      'type': 'result',
      'id': request.id,
      'image': base64Encode(image),
      'name': _resultName(request.params.action),
      if (savedPath != null && savedPath.isNotEmpty) 'saved_path': savedPath,
      'params': _paramsMetadata(request.params),
    });
  }

  String _resultName(ImageGenerationAction action) {
    final now = DateTime.now();
    final time =
        '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}:${_twoDigits(now.second)}';
    return switch (action) {
      ImageGenerationAction.infill => 'NAI Inpaint $time',
      ImageGenerationAction.img2img => 'NAI Img2Img $time',
      ImageGenerationAction.generate => 'NAI Image $time',
    };
  }

  Map<String, dynamic> _paramsMetadata(ImageParams params) {
    return {
      'prompt': params.prompt,
      'negative_prompt': params.negativePrompt,
      'model': params.model,
      'sampler': params.sampler,
      'steps': params.steps,
      'cfg_scale': params.scale,
      'seed': params.seed,
      'width': params.width,
      'height': params.height,
      'strength': params.strength,
      'noise': params.noise,
      'inpaint_strength': params.inpaintStrength,
    };
  }

  void _sendError(String id, KritaBridgeErrorCode code, String message) {
    _send(KritaBridgeError(id: id, code: code, message: message).toJson());
  }

  KritaBridgeErrorCode _mapErrorCode(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('401') ||
        message.contains('unauthorized') ||
        message.contains('token')) {
      return KritaBridgeErrorCode.authFailed;
    }
    if (message.contains('402') ||
        message.contains('anlas') ||
        message.contains('insufficient')) {
      return KritaBridgeErrorCode.insufficientAnlas;
    }
    if (message.contains('429') || message.contains('rate')) {
      return KritaBridgeErrorCode.rateLimited;
    }
    if (message.contains('timeout')) {
      return KritaBridgeErrorCode.timeout;
    }
    if (message.contains('mask') && message.contains('empty')) {
      return KritaBridgeErrorCode.emptyMask;
    }
    if (_isStreamingUnsupported(message)) {
      return KritaBridgeErrorCode.streamingUnsupported;
    }
    return KritaBridgeErrorCode.serverError;
  }

  String _publicErrorMessage(KritaBridgeErrorCode code) {
    return switch (code) {
      KritaBridgeErrorCode.authFailed =>
        'Authentication failed, please re-login in Launcher.',
      KritaBridgeErrorCode.insufficientAnlas =>
        'Insufficient Anlas to complete this request.',
      KritaBridgeErrorCode.rateLimited =>
        'Request was rate limited. Please retry later.',
      KritaBridgeErrorCode.timeout => 'Generation request timed out.',
      KritaBridgeErrorCode.emptyMask => 'Inpaint mask is empty.',
      KritaBridgeErrorCode.streamingUnsupported =>
        'Streaming is not available for this request.',
      KritaBridgeErrorCode.serverError => 'NovelAI server error.',
      _ => 'Krita bridge request failed.',
    };
  }

  bool _isStreamingUnsupported(String message) {
    final lower = message.toLowerCase();
    return lower.contains('streaming is not allowed') ||
        lower.contains('streaming not allowed') ||
        lower.contains('stream is not allowed') ||
        lower.contains('stream not allowed');
  }

  bool _shouldUseDirectFallback(KritaBridgeGenerateRequest request) {
    return request.params.action == ImageGenerationAction.infill;
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
