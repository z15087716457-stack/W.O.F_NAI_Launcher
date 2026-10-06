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
    id: 'rtx-vsr',
    name: 'NVIDIA RTX Video Super Resolution',
    engineName: 'rtx-vsr',
    scales: [1, 2, 3, 4],
    method: LocalUpscaleMethod.rtx,
  ),
];

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
