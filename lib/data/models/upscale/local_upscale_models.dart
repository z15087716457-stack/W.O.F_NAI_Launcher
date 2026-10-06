import 'dart:typed_data';

enum LocalUpscaleError {
  unsupportedPlatform,
  engineMissing,
  integrity,
  modelMissing,
  invalidModel,
  invalidImage,
  sizeLimit,
  noVulkan,
  noCuda,
  noRtx,
  outOfMemory,
  processFailed,
  modelOperationFailed,
  timeout,
  busy,
  cancelled,
}

class LocalUpscaleException implements Exception {
  const LocalUpscaleException(this.code, {this.details});
  final LocalUpscaleError code;
  final String? details;
  @override
  String toString() => 'LocalUpscaleException(${code.name})';
}

enum LocalUpscalePhase {
  preparing,
  encoding,
  inference,
  decoding,
  resizing,
  complete,
}

enum LocalUpscaleMethod { standard, seedvr2, rtx }

class LocalUpscaleProgress {
  const LocalUpscaleProgress(this.phase, [this.fraction]);
  final LocalUpscalePhase phase;
  final double? fraction;
}

class LocalUpscaleModel {
  const LocalUpscaleModel({
    required this.id,
    required this.name,
    required this.engineName,
    required this.scales,
    this.installed = false,
    this.bundled = false,
    this.custom = false,
    this.method = LocalUpscaleMethod.standard,
    this.diskBytes = 0,
  });
  final String id;
  final String name;
  final String engineName;
  final List<int> scales;
  final bool installed;
  final bool bundled;
  final bool custom;
  final LocalUpscaleMethod method;
  final int diskBytes;
  int inferenceScale(double requested) => scales.firstWhere(
    (scale) => scale >= requested,
    orElse: () => scales.last,
  );
  LocalUpscaleModel withInstalled(bool value, {int? diskBytes}) =>
      LocalUpscaleModel(
        id: id,
        name: name,
        engineName: engineName,
        scales: scales,
        installed: value,
        bundled: bundled,
        custom: custom,
        method: method,
        diskBytes: diskBytes ?? this.diskBytes,
      );
}

const localUpscaleDefaultModel = 'anime';
const localUpscaleCatalog = [
  LocalUpscaleModel(
    id: 'anime',
    name: 'Real-ESRGAN x4plus Anime',
    engineName: 'realesrgan-x4plus-anime',
    scales: [4],
    bundled: true,
  ),
  LocalUpscaleModel(
    id: 'anime-fast',
    name: 'RealESR AnimeVideo v3',
    engineName: 'realesr-animevideov3',
    scales: [2, 3, 4],
  ),
  LocalUpscaleModel(
    id: 'general',
    name: 'Real-ESRGAN x4plus',
    engineName: 'realesrgan-x4plus',
    scales: [4],
  ),
];

const advancedUpscaleCatalog = [
  LocalUpscaleModel(
    id: 'seedvr2-3b',
    name: 'SeedVR2 3B FP8',
    engineName: 'seedvr2',
    scales: [1, 2, 3, 4],
    method: LocalUpscaleMethod.seedvr2,
  ),
  LocalUpscaleModel(
    id: 'seedvr2-7b',
    name: 'SeedVR2 7B FP8',
    engineName: 'seedvr2',
    scales: [1, 2, 3, 4],
    method: LocalUpscaleMethod.seedvr2,
  ),
  LocalUpscaleModel(
    id: 'rtx-vsr',
    name: 'NVIDIA RTX Video Super Resolution',
    engineName: 'rtx-vsr',
    scales: [1, 2, 3, 4],
    method: LocalUpscaleMethod.rtx,
  ),
];

class Seedvr2Options {
  const Seedvr2Options({
    this.colorCorrection = 'lab',
    this.seed = 0,
    this.blocksToSwap = 0,
    this.vaeTiled = true,
    this.vaeTileSize = 1024,
    this.vaeTileOverlap = 128,
    this.inputNoise = 0,
    this.latentNoise = 0,
  });

  static const colors = [
    'lab',
    'wavelet',
    'wavelet_adaptive',
    'hsv',
    'adain',
    'none',
  ];
  static int maxBlocks(String modelId) => modelId == 'seedvr2-7b' ? 36 : 32;
  final String colorCorrection;
  final int seed, blocksToSwap, vaeTileSize, vaeTileOverlap;
  final bool vaeTiled;
  final double inputNoise, latentNoise;

  Seedvr2Options copyWith({
    String? colorCorrection,
    int? seed,
    int? blocksToSwap,
    bool? vaeTiled,
    int? vaeTileSize,
    int? vaeTileOverlap,
    double? inputNoise,
    double? latentNoise,
  }) => Seedvr2Options(
    colorCorrection: colorCorrection ?? this.colorCorrection,
    seed: seed ?? this.seed,
    blocksToSwap: blocksToSwap ?? this.blocksToSwap,
    vaeTiled: vaeTiled ?? this.vaeTiled,
    vaeTileSize: vaeTileSize ?? this.vaeTileSize,
    vaeTileOverlap: vaeTileOverlap ?? this.vaeTileOverlap,
    inputNoise: inputNoise ?? this.inputNoise,
    latentNoise: latentNoise ?? this.latentNoise,
  );

  Seedvr2Options normalized(String modelId) {
    final tile = (vaeTileSize.clamp(128, 4096) ~/ 64) * 64;
    return copyWith(
      colorCorrection: colors.contains(colorCorrection)
          ? colorCorrection
          : 'lab',
      seed: seed.clamp(0, 0xffffffff),
      blocksToSwap: blocksToSwap.clamp(0, maxBlocks(modelId)),
      vaeTileSize: tile,
      vaeTileOverlap: (vaeTileOverlap.clamp(0, tile - 64) ~/ 8) * 8,
      inputNoise: inputNoise.isFinite ? inputNoise.clamp(0, 1) : 0,
      latentNoise: latentNoise.isFinite ? latentNoise.clamp(0, 1) : 0,
    );
  }

  factory Seedvr2Options.fromJson(Object? value, {required String modelId}) {
    final map = value is Map ? value : const {};
    int integer(String key, int fallback) =>
        map[key] is num && (map[key] as num).isFinite
        ? (map[key] as num).toInt()
        : fallback;
    double number(String key) =>
        map[key] is num ? (map[key] as num).toDouble() : 0;
    return Seedvr2Options(
      colorCorrection: map['colorCorrection'] is String
          ? map['colorCorrection'] as String
          : 'lab',
      seed: integer('seed', 0),
      blocksToSwap: integer('blocksToSwap', 0),
      vaeTiled: map['vaeTiled'] is bool ? map['vaeTiled'] as bool : true,
      vaeTileSize: integer('vaeTileSize', 1024),
      vaeTileOverlap: integer('vaeTileOverlap', 128),
      inputNoise: number('inputNoise'),
      latentNoise: number('latentNoise'),
    ).normalized(modelId);
  }

  Map<String, Object> toJson() => {
    'colorCorrection': colorCorrection,
    'seed': seed,
    'blocksToSwap': blocksToSwap,
    'vaeTiled': vaeTiled,
    'vaeTileSize': vaeTileSize,
    'vaeTileOverlap': vaeTileOverlap,
    'inputNoise': inputNoise,
    'latentNoise': latentNoise,
  };

  List<String> arguments(String modelId) {
    final value = normalized(modelId);
    return [
      '--seed',
      '${value.seed}',
      '--color_correction',
      value.colorCorrection,
      '--input_noise_scale',
      '${value.inputNoise}',
      '--latent_noise_scale',
      '${value.latentNoise}',
      '--blocks_to_swap',
      '${value.blocksToSwap}',
      if (value.blocksToSwap >= 24) '--swap_io_components',
      if (value.vaeTiled) ...[
        '--vae_encode_tiled',
        '--vae_decode_tiled',
        '--vae_encode_tile_size',
        '${value.vaeTileSize}',
        '--vae_decode_tile_size',
        '${value.vaeTileSize}',
        '--vae_encode_tile_overlap',
        '${value.vaeTileOverlap}',
        '--vae_decode_tile_overlap',
        '${value.vaeTileOverlap}',
      ],
    ];
  }
}

class LocalUpscaleResult {
  const LocalUpscaleResult(this.bytes, this.width, this.height);
  final Uint8List bytes;
  final int width;
  final int height;
}

class LocalUpscaleCancellation {
  bool _cancelled = false;
  final _listeners = <void Function()>[];
  bool get isCancelled => _cancelled;
  void check() {
    if (_cancelled) {
      throw const LocalUpscaleException(LocalUpscaleError.cancelled);
    }
  }

  void Function() listen(void Function() callback) {
    if (_cancelled) {
      callback();
      return () {};
    }
    _listeners.add(callback);
    return () => _listeners.remove(callback);
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in List.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }
}
