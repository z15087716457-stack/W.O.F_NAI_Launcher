import '../../../core/utils/nai_resolution_adapter.dart';
import '../../../data/models/image/image_params.dart';
import '../../../data/models/upscale/local_upscale_models.dart';
import 'image_workflow_controller.dart';

/// Persistent generation configuration, excluding canvas-tool/job/UI ownership.
Map<String, dynamic> encodeImageWorkflowConfiguration(
  ImageWorkflowState? workflow,
  ImageParams image,
) {
  final value = _reconcile(workflow, image);
  final enhance = value.enhance, upscale = value.upscale;
  return {
    'version': 1,
    'mode': value.mode.name,
    'sourceWidth': value.sourceWidth,
    'sourceHeight': value.sourceHeight,
    'sourceImageWidth': value.sourceImageWidth,
    'sourceImageHeight': value.sourceImageHeight,
    'baseWidth': value.baseWidth,
    'baseHeight': value.baseHeight,
    'baseStrength': value.baseStrength,
    'baseNoise': value.baseNoise,
    'isOutpaint': image.isOutpaint,
    'enhance': {
      'magnitude': enhance.magnitude,
      'showIndividualSettings': enhance.showIndividualSettings,
      'upscaleFactor': enhance.upscaleFactor,
      'strength': enhance.strength,
      'noise': enhance.noise,
      'maxUpscale': enhance.maxUpscale,
      'localUpscale': enhance.localUpscale,
    },
    'upscale': {
      'backend': upscale.backend.name,
      'localModel': upscale.localModel,
      'localScale': upscale.localScale,
      'localSeedvr2Model': upscale.localSeedvr2Model,
      'localSeedvr2Options': {
        for (final e in upscale.localSeedvr2Options.entries)
          e.key: e.value.toJson(),
      },
      'comfyModule': upscale.comfyModule.name,
      'comfyScale': upscale.comfyScale,
      'comfyModel': upscale.comfyModel,
      'comfyRegularModel': upscale.comfyRegularModel,
      'comfySeedvr2Model': upscale.comfySeedvr2Model,
      'seedvr2VaeTileSize': upscale.seedvr2VaeTileSize,
      'seedvr2Tiled': upscale.seedvr2Tiled,
      'seedvr2TileSize': upscale.seedvr2TileSize,
      'seedvr2BlocksToSwap': upscale.seedvr2BlocksToSwap,
    },
  };
}

/// Older snapshots lack workflow settings. Derive image mode/geometry and retain
/// current preferences, rather than inventing a saved enhance/upscale selection.
ImageWorkflowState decodeImageWorkflowConfiguration(
  Object? json,
  ImageParams image, {
  ImageWorkflowState? legacyPreferences,
}) {
  final size = image.sourceImage == null
      ? null
      : NaiResolutionAdapter.readImageSize(image.sourceImage!);
  final focus = image.inpaintFocusRegion;
  if (image.sourceImage != null && size == null ||
      image.action != ImageGenerationAction.generate && size == null ||
      image.action == ImageGenerationAction.infill && image.maskImage == null ||
      image.maskImage != null &&
          NaiResolutionAdapter.readImageSize(image.maskImage!) != size ||
      focus != null &&
          (size == null ||
              focus.x < 0 ||
              focus.y < 0 ||
              focus.width < 1 ||
              focus.height < 1 ||
              focus.context < 0 ||
              focus.x + focus.width > size.$1 ||
              focus.y + focus.height > size.$2)) {
    throw const FormatException('Invalid snapshot source/mask/focus geometry');
  }
  if (json == null) {
    return _reconcile(
      ImageWorkflowState(
        enhance: legacyPreferences?.enhance ?? const EnhanceWorkflowSettings(),
        upscale: legacyPreferences?.upscale ?? const UpscaleWorkflowSettings(),
      ),
      image,
    );
  }
  final map = _map(json), e = _map(map['enhance']), u = _map(map['upscale']);
  if (map['version'] != 1) {
    throw const FormatException('Unknown image workflow configuration');
  }
  final mode = ImageWorkflowMode.values.asNameMap()[map['mode']];
  final backend = UpscaleBackend.values.asNameMap()[u['backend']];
  final module = ComfyUpscaleModule.values.asNameMap()[u['comfyModule']];
  if (mode == null || backend == null || module == null) {
    throw const FormatException('Unknown image workflow mode/backend');
  }
  final options = _map(u['localSeedvr2Options']);
  if (options.length > 32) {
    throw const FormatException('Too many upscale model settings');
  }
  final value = ImageWorkflowState(
    mode: mode,
    sourceWidth: _dimension(map, 'sourceWidth'),
    sourceHeight: _dimension(map, 'sourceHeight'),
    sourceImageWidth: _dimension(map, 'sourceImageWidth'),
    sourceImageHeight: _dimension(map, 'sourceImageHeight'),
    baseWidth: _dimension(map, 'baseWidth'),
    baseHeight: _dimension(map, 'baseHeight'),
    baseStrength: _optionalNumber(map, 'baseStrength'),
    baseNoise: _optionalNumber(map, 'baseNoise'),
    isOutpaint: _boolean(map, 'isOutpaint'),
    enhance: EnhanceWorkflowSettings(
      magnitude: _number(e, 'magnitude', 0, 1),
      showIndividualSettings: _boolean(e, 'showIndividualSettings'),
      upscaleFactor: _number(e, 'upscaleFactor', 1, 2),
      strength: _number(e, 'strength', 0, 1),
      noise: _number(e, 'noise', 0, 1),
      maxUpscale: _boolean(e, 'maxUpscale'),
      localUpscale: _boolean(e, 'localUpscale'),
    ),
    upscale: UpscaleWorkflowSettings(
      backend: backend,
      localModel: _string(u, 'localModel'),
      localScale: _number(u, 'localScale', 1, 4),
      localSeedvr2Model: _string(u, 'localSeedvr2Model'),
      localSeedvr2Options: Map.unmodifiable({
        for (final entry in options.entries)
          _validModelName(entry.key): _seedOptions(entry.key, entry.value),
      }),
      comfyModule: module,
      comfyScale: _number(u, 'comfyScale', 1, 2),
      comfyModel: _string(u, 'comfyModel'),
      comfyRegularModel: _string(u, 'comfyRegularModel'),
      comfySeedvr2Model: _string(u, 'comfySeedvr2Model'),
      seedvr2VaeTileSize: _integer(u, 'seedvr2VaeTileSize', 128, 4096),
      seedvr2Tiled: _boolean(u, 'seedvr2Tiled'),
      seedvr2TileSize: _integer(u, 'seedvr2TileSize', 256, 4096),
      seedvr2BlocksToSwap: _integer(u, 'seedvr2BlocksToSwap', 0, 36),
    ),
  );
  if ((value.baseWidth == null) != (value.baseHeight == null) ||
      (value.sourceWidth == null) != (value.sourceHeight == null) ||
      (size == null &&
          (mode != ImageWorkflowMode.base || value.sourceWidth != null)) ||
      (size != null &&
          (value.sourceWidth == null ||
              value.sourceImageWidth != size.$1 ||
              value.sourceImageHeight != size.$2)) ||
      value.isOutpaint != image.isOutpaint ||
      (image.action == ImageGenerationAction.infill &&
          mode != ImageWorkflowMode.inpaint)) {
    throw const FormatException(
      'Image workflow does not match snapshot images',
    );
  }
  return value;
}

ImageWorkflowState _reconcile(ImageWorkflowState? state, ImageParams image) {
  final size = image.sourceImage == null
      ? null
      : NaiResolutionAdapter.readImageSize(image.sourceImage!);
  final original = state ?? const ImageWorkflowState();
  final mode = size == null
      ? ImageWorkflowMode.base
      : image.action == ImageGenerationAction.infill
      ? ImageWorkflowMode.inpaint
      : image.enhanceWorkflow
      ? ImageWorkflowMode.enhance
      : original.mode;
  return ImageWorkflowState(
    mode: mode,
    sourceWidth: size == null ? null : original.sourceWidth ?? image.width,
    sourceHeight: size == null ? null : original.sourceHeight ?? image.height,
    sourceImageWidth: size?.$1,
    sourceImageHeight: size?.$2,
    baseWidth: original.baseWidth,
    baseHeight: original.baseHeight,
    baseStrength: original.baseStrength,
    baseNoise: original.baseNoise,
    enhance: original.enhance,
    upscale: original.upscale,
    isOutpaint: image.isOutpaint,
  );
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) throw const FormatException('Expected workflow object');
  return Map<String, dynamic>.from(value);
}

double _number(Map map, String key, double min, double max) {
  final value = map[key];
  if (value is! num || !value.isFinite || value < min || value > max) {
    throw FormatException('Invalid workflow $key');
  }
  return value.toDouble();
}

double? _optionalNumber(Map map, String key) =>
    map[key] == null ? null : _number(map, key, 0, 1);
int? _dimension(Map map, String key) =>
    map[key] == null ? null : _integer(map, key, 1, 16384);
int _integer(Map map, String key, int min, int max) {
  final value = map[key];
  if (value is! int || value < min || value > max) {
    throw FormatException('Invalid workflow $key');
  }
  return value;
}

bool _boolean(Map map, String key) {
  if (map[key] is! bool) throw FormatException('Invalid workflow $key');
  return map[key] as bool;
}

String _string(Map map, String key) {
  if (map[key] is! String || (map[key] as String).length > 512) {
    throw FormatException('Invalid workflow $key');
  }
  return map[key] as String;
}

String _validModelName(String key) {
  if (key.isEmpty || key.length > 512) {
    throw const FormatException('Invalid upscale model ID');
  }
  return key;
}

Seedvr2Options _seedOptions(String model, Object? json) {
  final map = _map(json);
  if (!Seedvr2Options.colors.contains(map['colorCorrection'])) {
    throw const FormatException('Invalid SeedVR2 color correction');
  }
  final tile = _integer(map, 'vaeTileSize', 128, 4096);
  final overlap = _integer(map, 'vaeTileOverlap', 0, tile - 64);
  if (tile % 64 != 0 || overlap % 8 != 0) {
    throw const FormatException('Invalid SeedVR2 tile alignment');
  }
  return Seedvr2Options(
    colorCorrection: map['colorCorrection'] as String,
    seed: _integer(map, 'seed', 0, 0xffffffff),
    blocksToSwap: _integer(
      map,
      'blocksToSwap',
      0,
      Seedvr2Options.maxBlocks(model),
    ),
    vaeTiled: _boolean(map, 'vaeTiled'),
    vaeTileSize: tile,
    vaeTileOverlap: overlap,
    inputNoise: _number(map, 'inputNoise', 0, 1),
    latentNoise: _number(map, 'latentNoise', 0, 1),
  );
}
