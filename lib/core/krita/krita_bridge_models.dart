import 'dart:typed_data';

import '../constants/api_constants.dart';
import '../../data/models/image/image_params.dart';

enum KritaBridgeErrorCode {
  invalidRequest('invalid_request'),
  unsupportedMessage('unsupported_message'),
  payloadTooLarge('payload_too_large'),
  authFailed('auth_failed'),
  unauthorizedBridgeClient('unauthorized_bridge_client'),
  busy('busy'),
  emptyMask('empty_mask'),
  timeout('timeout'),
  rateLimited('rate_limited'),
  insufficientAnlas('insufficient_anlas'),
  serverError('server_error'),
  streamInterrupted('stream_interrupted'),
  streamingUnsupported('streaming_unsupported'),
  unsupportedDocumentFormat('unsupported_document_format');

  const KritaBridgeErrorCode(this.value);

  final String value;
}

class KritaBridgeError {
  const KritaBridgeError({
    required this.code,
    required this.message,
    this.id,
  });

  final KritaBridgeErrorCode code;
  final String message;
  final String? id;

  Map<String, dynamic> toJson() => {
        'type': 'error',
        if (id != null) 'id': id,
        'code': code.value,
        'message': message,
      };
}

class KritaBridgeDecodeResult {
  const KritaBridgeDecodeResult._({
    this.message,
    this.error,
  });

  factory KritaBridgeDecodeResult.message(KritaBridgeMessage message) {
    return KritaBridgeDecodeResult._(message: message);
  }

  factory KritaBridgeDecodeResult.error(KritaBridgeError error) {
    return KritaBridgeDecodeResult._(error: error);
  }

  final KritaBridgeMessage? message;
  final KritaBridgeError? error;
}

abstract class KritaBridgeMessage {
  const KritaBridgeMessage();

  String get type;
  String? get id;
}

class KritaPingMessage extends KritaBridgeMessage {
  const KritaPingMessage({
    required this.version,
    required this.secret,
  });

  @override
  String get type => 'ping';

  @override
  String? get id => null;

  final int version;
  final String secret;
}

class KritaUnsupportedPingVersionMessage extends KritaBridgeMessage {
  const KritaUnsupportedPingVersionMessage({
    required this.requestedVersion,
    required this.supportedVersions,
  });

  @override
  String get type => 'ping_version_mismatch';

  @override
  String? get id => null;

  final int requestedVersion;
  final List<int> supportedVersions;
}

class KritaGetParamsMessage extends KritaBridgeMessage {
  const KritaGetParamsMessage({
    required this.id,
  });

  @override
  String get type => 'get_params';

  @override
  final String id;
}

class KritaCancelMessage extends KritaBridgeMessage {
  const KritaCancelMessage({
    required this.id,
  });

  @override
  String get type => 'cancel';

  @override
  final String id;
}

class KritaSelectionRect {
  const KritaSelectionRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;
}

class KritaImageParamsMapping {
  const KritaImageParamsMapping({
    required this.params,
    required this.focusedInpaintEnabled,
    required this.minimumContextPixels,
    this.selectionRect,
  });

  final ImageParams params;
  final bool focusedInpaintEnabled;
  final int minimumContextPixels;
  final KritaSelectionRect? selectionRect;
}

class KritaInpaintMessage extends KritaBridgeMessage {
  const KritaInpaintMessage({
    required this.id,
    required this.image,
    required this.mask,
    required this.prompt,
    required this.negativePrompt,
    required this.strength,
    required this.noise,
    required this.inpaintStrength,
    required this.minimumContextPixels,
    required this.maskClosingIterations,
    required this.maskExpansionIterations,
    required this.focusedInpaint,
    this.selectionRect,
  });

  @override
  String get type => 'inpaint';

  @override
  final String id;
  final Uint8List image;
  final Uint8List mask;
  final KritaSelectionRect? selectionRect;
  final String prompt;
  final String negativePrompt;
  final double strength;
  final double noise;
  final double inpaintStrength;
  final int minimumContextPixels;
  final int maskClosingIterations;
  final int maskExpansionIterations;
  final bool focusedInpaint;

  KritaImageParamsMapping toImageParams(ImageParams baseParams) {
    final clampedContext = minimumContextPixels.clamp(16, 192).toInt();
    final hasFocusedRect = focusedInpaint && selectionRect != null;

    return KritaImageParamsMapping(
      params: baseParams.copyWith(
        action: ImageGenerationAction.infill,
        model: ImageModels.resolveInpaintingModel(baseParams.model),
        sourceImage: image,
        maskImage: mask,
        prompt: prompt,
        negativePrompt: negativePrompt,
        strength: strength,
        noise: noise,
        inpaintStrength: inpaintStrength,
        inpaintMaskClosingIterations: maskClosingIterations,
        inpaintMaskExpansionIterations: maskExpansionIterations,
      ),
      focusedInpaintEnabled: hasFocusedRect,
      minimumContextPixels: clampedContext,
      selectionRect: selectionRect,
    );
  }
}

/// AI 接管扩展：set_params 消息。
/// 将参数写入应用 UI 状态（GenerationParamsNotifier），用户在界面上实时可见。
class KritaSetParamsMessage extends KritaBridgeMessage {
  const KritaSetParamsMessage({
    required this.id,
    required this.payload,
  });

  @override
  String get type => 'set_params';

  @override
  final String id;

  /// 原始参数表（snake_case 键），由服务层映射到 GenerationParamsNotifier。
  final Map<String, dynamic> payload;
}

/// AI 接管扩展：generate 消息。
/// 在当前 UI 参数基础上静默覆盖参数并生成，不改变 UI 状态。
/// payload 为空时等价于远程按下 Generate 按钮。
class KritaGenerateMessage extends KritaBridgeMessage {
  const KritaGenerateMessage({
    required this.id,
    required this.payload,
  });

  @override
  String get type => 'generate';

  @override
  final String id;

  final Map<String, dynamic> payload;

  KritaImageParamsMapping toImageParams(ImageParams baseParams) {
    return KritaImageParamsMapping(
      params: applyKritaParamsOverlay(baseParams, payload),
      focusedInpaintEnabled: false,
      minimumContextPixels: 0,
    );
  }
}

/// 将 JSON 覆盖层应用到 [base] 参数上（generate 消息用）。
/// 未出现的键保持 base 原值；characters 键为整体替换；
/// clear_characters=true 清空角色列表。
ImageParams applyKritaParamsOverlay(
  ImageParams base,
  Map<String, dynamic> p,
) {
  String? str(String k) => p[k] is String ? p[k] as String : null;
  int? integer(String k) => p[k] is num ? (p[k] as num).toInt() : null;
  double? dbl(String k) => p[k] is num ? (p[k] as num).toDouble() : null;
  bool? flag(String k) => p[k] is bool ? p[k] as bool : null;

  final charactersValue = p['characters'];
  List<CharacterPrompt>? characters;
  if (charactersValue is List) {
    characters = [
      for (final entry in charactersValue)
        if (entry is Map && entry['prompt'] is String)
          CharacterPrompt(
            prompt: entry['prompt'] as String,
            negativePrompt:
                entry['uc'] is String ? entry['uc'] as String : '',
            position: entry['position'] is String
                ? entry['position'] as String
                : null,
            positionX:
                entry['x'] is num ? (entry['x'] as num).toDouble() : null,
            positionY:
                entry['y'] is num ? (entry['y'] as num).toDouble() : null,
          ),
    ];
  }

  return base.copyWith(
    prompt: str('prompt') ?? base.prompt,
    negativePrompt: str('negative_prompt') ?? base.negativePrompt,
    model: str('model') ?? base.model,
    width: integer('width') ?? base.width,
    height: integer('height') ?? base.height,
    steps: integer('steps') ?? base.steps,
    scale: dbl('cfg_scale') ?? base.scale,
    sampler: str('sampler') ?? base.sampler,
    seed: integer('seed') ?? base.seed,
    nSamples: integer('n_samples') ?? base.nSamples,
    ucPreset: integer('uc_preset') ?? base.ucPreset,
    qualityToggle: flag('quality_toggle') ?? base.qualityToggle,
    cfgRescale: dbl('cfg_rescale') ?? base.cfgRescale,
    noiseSchedule: str('noise_schedule') ?? base.noiseSchedule,
    varietyPlus: flag('variety_plus') ?? base.varietyPlus,
    transparentBackground:
        flag('transparent_background') ?? base.transparentBackground,
    smeaAuto: flag('smea_auto') ?? base.smeaAuto,
    smea: flag('smea') ?? base.smea,
    smeaDyn: flag('smea_dyn') ?? base.smeaDyn,
    decrisp: flag('decrisp') ?? base.decrisp,
    useCoords: flag('use_coords') ?? base.useCoords,
    characters: characters ??
        (flag('clear_characters') == true ? const [] : base.characters),
  );
}

class KritaImg2ImgMessage extends KritaBridgeMessage {
  const KritaImg2ImgMessage({
    required this.id,
    required this.image,
    required this.prompt,
    required this.negativePrompt,
    required this.strength,
    required this.noise,
  });

  @override
  String get type => 'img2img';

  @override
  final String id;
  final Uint8List image;
  final String prompt;
  final String negativePrompt;
  final double strength;
  final double noise;

  KritaImageParamsMapping toImageParams(ImageParams baseParams) {
    return KritaImageParamsMapping(
      params: baseParams.copyWith(
        action: ImageGenerationAction.img2img,
        sourceImage: image,
        prompt: prompt,
        negativePrompt: negativePrompt,
        strength: strength,
        noise: noise,
      ),
      focusedInpaintEnabled: false,
      minimumContextPixels: 0,
    );
  }
}
