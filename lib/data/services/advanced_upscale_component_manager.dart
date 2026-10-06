import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/fatal_diagnostics.dart';
import '../models/upscale/local_upscale_models.dart';
import 'owned_upscale_process.dart';

class AdvancedUpscaleCommand {
  const AdvancedUpscaleCommand(this.host, this.executable, this.arguments);
  final String host;
  final String executable;
  final List<String> arguments;
}

/// Optional components. Listing and resolving never download a missing file.
/// Every installer process belongs to the bundled Windows job host.
class AdvancedUpscaleComponentManager {
  AdvancedUpscaleComponentManager({
    Future<Directory> Function()? rootDirectory,
    Future<Uint8List> Function(String)? loadAsset,
    Dio? dio,
    this.startProcess,
    this.proxyAddress,
    this.manifestDigest = manifestSha256,
  }) : _rootDirectory = rootDirectory ?? _defaultDirectory,
       _loadAsset = loadAsset ?? _bundleBytes,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 30),
               receiveTimeout: const Duration(minutes: 3),
             ),
           );

  static const manifestSha256 =
      '7d72744fc08f883bfd754d48ab35c0349c77caa3d16af41c1add37649a4ce337';
  final String manifestDigest;
  final Future<Directory> Function() _rootDirectory;
  final Future<Uint8List> Function(String) _loadAsset;
  final Dio _dio;
  final OwnedUpscaleStarter? startProcess;
  final String? Function()? proxyAddress;
  late Directory directory;
  late Map<String, dynamic> _manifest;
  Future<void>? _initializing;
  bool _ready = false;
  bool _busy = false;
  void claimInference() {
    if (_busy) throw const LocalUpscaleException(LocalUpscaleError.busy);
    _busy = true;
  }

  void releaseInference() => _busy = false;
  void dispose() => _dio.close(force: true);

  static Map<String, String> get seedRuntimeEnvironment => {
    'PYTORCH_CUDA_ALLOC_CONF':
        Platform.environment['PYTORCH_CUDA_ALLOC_CONF'] ??
        'backend:cudaMallocAsync',
    'PYTHONUTF8': '1',
    'PYTHONIOENCODING': 'utf-8',
    'PYTHONFAULTHANDLER': '1',
    'HF_HUB_OFFLINE': '1',
    'TRANSFORMERS_OFFLINE': '1',
    'HF_HUB_DISABLE_TELEMETRY': '1',
  };

  static String safeDiagnostics(String value) {
    final safe = FatalDiagnostics.redactSensitiveText(
      value.replaceAll(RegExp(r'https?://[^\s]+'), '[URL]'),
    ).replaceAll(RegExp(r'\x1b\[[0-9;]*[A-Za-z]'), '').trim();
    return safe.length > 4096
        ? '${safe.substring(0, 2048)}\n...\n${safe.substring(safe.length - 2000)}'
        : safe;
  }

  static Future<Directory> _defaultDirectory() async => Directory(
    p.join(
      (await getApplicationSupportDirectory()).path,
      'upscale',
      'advanced',
      'v1',
    ),
  );
  static Future<Uint8List> _bundleBytes(String name) async =>
      (await rootBundle.load(
        'assets/local_upscale/$name',
      )).buffer.asUint8List();

  Future<void> initialize() async {
    if (_ready) return;
    if (_initializing != null) return _initializing!;
    final work = _initialize();
    _initializing = work;
    try {
      await work;
      _ready = true;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize() async {
    final bytes = await _loadAsset('advanced_manifest.json');
    if (sha256.convert(bytes).toString() != manifestDigest) {
      throw const LocalUpscaleException(LocalUpscaleError.integrity);
    }
    _manifest = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    directory = await _rootDirectory();
    await directory.create(recursive: true);
  }

  String _key(String id) => switch (id) {
    'seedvr2-3b' => 'seedvr2',
    'rtx-vsr' => 'rtx',
    _ => throw const LocalUpscaleException(LocalUpscaleError.invalidModel),
  };
  File _pointer(String id) => File(p.join(directory.path, '${_key(id)}.json'));
  Future<Map<String, dynamic>?> _receipt(String id) async {
    final file = _pointer(id);
    if (!await file.exists()) return null;
    try {
      final value =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if ((value['manifest'] != manifestDigest &&
              (id != 'rtx-vsr' ||
                  value['manifest'] !=
                      'c89c13dbf28b78b3a09ee8820715ac7c2850d84c4ec98742c56e46406cb7924b')) ||
          value['ready'] != true ||
          !RegExp(r'^[a-z0-9-]+$').hasMatch(value['installation'] as String)) {
        return null;
      }
      final root = Directory(
        p.join(directory.path, 'installs', value['installation']),
      );
      if (!await root.exists()) return null;
      await _contained(root.path);
      final spec = _manifest[_key(id)] as Map<String, dynamic>;
      final expected = _key(id) == 'rtx'
          ? (spec['files'] as List)
                .cast<Map<String, dynamic>>()
                .map((f) => {...f, 'path': f['name']})
                .toList()
          : [
              ...(spec['source']['files'] as List)
                  .cast<Map<String, dynamic>>()
                  .map((f) => {...f, 'path': 'source/${f['path']}'}),
              ...(spec['models'] as List).cast<Map<String, dynamic>>().map(
                (f) => {...f, 'path': 'models/${f['name']}'},
              ),
              for (final name in ['runner', 'requirements'])
                {
                  ...spec[name] as Map<String, dynamic>,
                  'path': p.basename(spec[name]['asset'] as String),
                },
            ];
      final stored = (value['files'] as List).cast<Map<String, dynamic>>();
      for (final file in expected) {
        final match = stored
            .where((item) => item['path'] == file['path'])
            .firstOrNull;
        if (match == null ||
            match['sha256'] != file['sha256'] ||
            file['bytes'] != null && match['bytes'] != file['bytes']) {
          return null;
        }
      }
      for (final item
          in (value['files'] as List).cast<Map<String, dynamic>>()) {
        final path = _child(root.path, item['path'] as String);
        await _contained(path);
        final f = File(path);
        if (!await f.exists() || await f.length() != item['bytes']) return null;
      }
      return value;
    } catch (_) {
      return null;
    }
  }

  Future<List<LocalUpscaleModel>> models() async {
    await initialize();
    final result = <LocalUpscaleModel>[];
    for (final model in advancedUpscaleCatalog) {
      final receipt = await _receipt(model.id);
      result.add(
        model.withInstalled(
          receipt != null,
          diskBytes: receipt?['disk_bytes'] as int? ?? 0,
        ),
      );
    }
    return result;
  }

  Future<void> _contained(String path) async {
    // Resolve the nearest existing ancestor too: an absent child of a junction
    // must not bypass the same boundary enforced before recursive deletion.
    var ancestor = path;
    while (await FileSystemEntity.type(ancestor) ==
        FileSystemEntityType.notFound) {
      final parent = p.dirname(ancestor);
      if (parent == ancestor) break;
      ancestor = parent;
    }
    final resolved = await File(ancestor).resolveSymbolicLinks();
    final base = await directory.resolveSymbolicLinks();
    if (resolved != base && !p.isWithin(base, resolved)) {
      throw const LocalUpscaleException(LocalUpscaleError.integrity);
    }
  }

  static String _child(String root, String relative) {
    if (p.isAbsolute(relative) ||
        relative.contains('\\') ||
        relative.split('/').any((part) => part == '..' || part.isEmpty)) {
      throw const LocalUpscaleException(LocalUpscaleError.integrity);
    }
    final path = p.normalize(p.join(root, relative));
    if (!p.isWithin(root, path)) {
      throw const LocalUpscaleException(LocalUpscaleError.integrity);
    }
    return path;
  }

  Future<void> _remove(Directory target) async {
    if (!await target.exists()) return;
    await _contained(target.path);
    await target.delete(recursive: true);
  }

  static Future<String> _hash(File file) => Isolate.run(
    () async => (await sha256.bind(file.openRead()).first).toString(),
  );
  Future<void> _verify(File file, Map<String, dynamic> spec) async {
    await _contained(file.path);
    if (!await file.exists() ||
        (spec['bytes'] != null && await file.length() != spec['bytes']) ||
        await _hash(file) != spec['sha256']) {
      throw const LocalUpscaleException(LocalUpscaleError.integrity);
    }
  }

  Future<String> worker() async {
    await initialize();
    final spec = _manifest['worker'] as Map<String, dynamic>;
    final target = File(
      p.join(directory.path, 'tools', 'studio_upscale_worker.exe'),
    );
    await _contained(target.path);
    if (!await target.exists() || await _hash(target) != spec['sha256']) {
      final bytes = await _loadAsset(spec['asset'] as String);
      if (sha256.convert(bytes).toString() != spec['sha256']) {
        throw const LocalUpscaleException(LocalUpscaleError.integrity);
      }
      await target.parent.create(recursive: true);
      await target.writeAsBytes(bytes, flush: true);
    }
    return target.path;
  }

  /// Bounded, hash-checked resumable downloads. Some hosts send several partial
  /// responses; do not mistake the first response for a complete model.
  Future<File> _download(
    Map<String, dynamic> spec,
    LocalUpscaleCancellation cancellation,
    void Function(String, double?)? progress,
    String phase,
  ) async {
    cancellation.check();
    final cache = Directory(p.join(directory.path, 'downloads'));
    await _contained(cache.path);
    await cache.create(recursive: true);
    final expected = spec['bytes'] as int;
    final digest = spec['sha256'] as String;
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) {
      throw const LocalUpscaleException(LocalUpscaleError.integrity);
    }
    final complete = File(p.join(cache.path, digest));
    final partial = File('${complete.path}.part');
    await _contained(partial.path);
    await _contained(complete.path);
    if (await complete.exists()) {
      await _verify(complete, spec);
      return complete;
    }
    var received = await partial.exists() ? await partial.length() : 0;
    if (received > expected) {
      await partial.delete();
      received = 0;
    }
    final token = CancelToken();
    final stop = cancellation.listen(() => token.cancel());
    try {
      while (received < expected) {
        cancellation.check();
        progress?.call(phase, received / expected);
        final response = await _dio.get<ResponseBody>(
          spec['url'] as String,
          options: Options(
            responseType: ResponseType.stream,
            headers: received == 0 ? {} : {'Range': 'bytes=$received-'},
          ),
          cancelToken: token,
        );
        if (response.statusCode == 206) {
          final range = response.headers.value('content-range') ?? '';
          final match = RegExp(r'^bytes (\d+)-(\d+)/(\d+)$').firstMatch(range);
          if (match == null ||
              int.parse(match[1]!) != received ||
              int.parse(match[3]!) != expected) {
            throw const LocalUpscaleException(LocalUpscaleError.integrity);
          }
        } else if (response.statusCode == 200) {
          received = 0; // Server does not support resume: replace the partial.
        } else {
          throw const LocalUpscaleException(
            LocalUpscaleError.modelOperationFailed,
          );
        }
        final before = received;
        final sink = partial.openWrite(
          mode: received == 0 ? FileMode.write : FileMode.append,
        );
        try {
          await for (final chunk in response.data!.stream) {
            cancellation.check();
            received += chunk.length;
            if (received > expected) {
              throw const LocalUpscaleException(LocalUpscaleError.integrity);
            }
            sink.add(chunk);
            progress?.call(phase, received / expected);
          }
          await sink.flush();
        } finally {
          await sink.close();
        }
        if (received == before) {
          throw const LocalUpscaleException(
            LocalUpscaleError.modelOperationFailed,
          );
        }
      }
      cancellation.check();
      try {
        await _verify(partial, spec);
      } on LocalUpscaleException {
        await partial.delete();
        rethrow;
      }
      cancellation.check();
      return partial.rename(complete.path);
    } on DioException {
      cancellation.check();
      rethrow;
    } finally {
      stop();
    }
  }

  Future<void> _extract(
    File archive,
    Directory destination,
    List<Map<String, dynamic>> files, {
    String prefix = '',
  }) async {
    await _contained(destination.path);
    for (final item in files) {
      await _contained(
        _child(destination.path, (item['name'] ?? item['path']) as String),
      );
    }
    await Isolate.run(() async {
      final decoded = ZipDecoder().decodeBytes(await archive.readAsBytes());
      for (final item in files) {
        final input = decoded.findFile('$prefix${item['path']}');
        if (input == null ||
            !input.isFile ||
            (item['bytes'] != null && input.size != item['bytes'])) {
          throw const LocalUpscaleException(LocalUpscaleError.integrity);
        }
        final bytes = input.content as List<int>;
        if (sha256.convert(bytes).toString() != item['sha256']) {
          throw const LocalUpscaleException(LocalUpscaleError.integrity);
        }
        final target = File(
          _child(destination.path, (item['name'] ?? item['path']) as String),
        );
        await target.parent.create(recursive: true);
        await target.writeAsBytes(bytes, flush: true);
      }
    });
  }

  Future<void> install(
    String id, {
    required LocalUpscaleCancellation cancellation,
    void Function(String, double?)? onProgress,
  }) async {
    final key = _key(id);
    claimInference();
    Directory? stage;
    try {
      await initialize();
      cancellation.check();
      final existing = await _receipt(id);
      if (existing != null) return;
      if (!Platform.isWindows) {
        throw const LocalUpscaleException(
          LocalUpscaleError.unsupportedPlatform,
        );
      }
      final host = await worker();
      final name = '$key-${const Uuid().v4()}';
      stage = Directory(p.join(directory.path, 'installs', name));
      await _contained(stage.path);
      await stage.create(recursive: true);
      final spec = _manifest[key] as Map<String, dynamic>;
      final verified = <Map<String, dynamic>>[];
      late OwnedUpscaleProcessResult probe;
      if (key == 'rtx') {
        final zip = await _download(
          spec['archive'],
          cancellation,
          onProgress,
          'component',
        );
        cancellation.check();
        final files = (spec['files'] as List).cast<Map<String, dynamic>>();
        await _extract(zip, stage, files);
        cancellation.check();
        onProgress?.call('checking', null);
        probe = await runOwnedUpscaleProcess(
          host: host,
          executable: host,
          arguments: ['--rtx-probe', stage.path],
          cancellation: cancellation,
          startProcess: startProcess,
        );
        verified.addAll(files.map((f) => {...f, 'path': f['name']}));
      } else {
        final src = spec['source'] as Map<String, dynamic>;
        final zip = await _download(src, cancellation, onProgress, 'component');
        final files = (src['files'] as List).cast<Map<String, dynamic>>();
        final source = Directory(p.join(stage.path, 'source'));
        cancellation.check();
        await _extract(zip, source, files, prefix: src['prefix']);
        verified.addAll(
          files.map((f) => {...f, 'path': 'source/${f['path']}'}),
        );
        final uv = spec['uv'] as Map<String, dynamic>;
        final uvZip = await _download(
          uv,
          cancellation,
          onProgress,
          'component',
        );
        await _extract(uvZip, Directory(p.join(stage.path, 'tools')), [
          {'path': 'uv.exe', 'sha256': uv['executable_sha256']},
        ]);
        for (final entry in ['runner', 'requirements']) {
          final item = spec[entry] as Map<String, dynamic>;
          final bytes = await _loadAsset(item['asset']);
          if (sha256.convert(bytes).toString() != item['sha256']) {
            throw const LocalUpscaleException(LocalUpscaleError.integrity);
          }
          final relative = p.basename(item['asset'] as String);
          await File(
            p.join(stage.path, relative),
          ).writeAsBytes(bytes, flush: true);
          verified.add({
            'path': relative,
            'sha256': item['sha256'],
            'bytes': bytes.length,
          });
        }
        final uvExe = p.join(stage.path, 'tools', 'uv.exe');
        final python = p.join(stage.path, 'venv', 'Scripts', 'python.exe');
        final proxy = proxyAddress?.call();
        final env = <String, String>{
          'UV_PYTHON_INSTALL_DIR': p.join(stage.path, 'python'),
          'UV_CACHE_DIR': p.join(directory.path, 'uv-cache'),
          'UV_LINK_MODE': 'copy',
          'UV_NO_CONFIG': '1',
          'PYTHONIOENCODING': 'utf-8',
          for (final key in [
            'HTTP_PROXY',
            'HTTPS_PROXY',
            'http_proxy',
            'https_proxy',
          ])
            key: proxy == null ? '' : 'http://$proxy',
          'ALL_PROXY': '',
          'all_proxy': '',
        };
        await _contained(env['UV_CACHE_DIR']!);
        for (final args in [
          [
            'venv',
            '--python',
            spec['python'] as String,
            '--managed-python',
            '--no-config',
            p.join(stage.path, 'venv'),
          ],
          [
            'pip',
            'sync',
            '--python',
            python,
            '--require-hashes',
            '--no-config',
            '--extra-index-url',
            'https://download.pytorch.org/whl/cu128',
            '--index-strategy',
            'unsafe-best-match',
            p.join(stage.path, 'requirements.lock'),
          ],
        ]) {
          onProgress?.call(args.first == 'venv' ? 'python' : 'runtime', null);
          final result = await runOwnedUpscaleProcess(
            host: host,
            executable: uvExe,
            arguments: args,
            environment: env,
            cancellation: cancellation,
            timeout: const Duration(hours: 12),
            startProcess: startProcess,
          );
          if (result.exitCode != 0) {
            throw LocalUpscaleException(
              LocalUpscaleError.modelOperationFailed,
              details: safeDiagnostics(
                'uv ${args.first}: exit ${result.exitCode}\n${result.diagnostics}',
              ),
            );
          }
        }
        onProgress?.call('checking', null);
        probe = await runOwnedUpscaleProcess(
          host: host,
          executable: python,
          arguments: [p.join(stage.path, 'worker.py'), source.path, '--probe'],
          environment: seedRuntimeEnvironment,
          cancellation: cancellation,
          startProcess: startProcess,
        );
        if (probe.exitCode != 0) {
          throw LocalUpscaleException(
            probe.exitCode == 12
                ? LocalUpscaleError.noCuda
                : LocalUpscaleError.modelOperationFailed,
            details: safeDiagnostics(
              'SeedVR2 probe: exit ${probe.exitCode}\n${probe.diagnostics}',
            ),
          );
        }
        verified.add({
          'path': 'venv/Scripts/python.exe',
          'bytes': await File(python).length(),
          'sha256': await _hash(File(python)),
        });
        for (final item
            in (spec['models'] as List).cast<Map<String, dynamic>>()) {
          final file = await _download(
            item,
            cancellation,
            onProgress,
            'weights',
          );
          final target = File(p.join(stage.path, 'models', item['name']));
          await target.parent.create(recursive: true);
          // Keep one copy of large weights, on the same owned volume.
          await file.rename(target.path);
          verified.add({...item, 'path': 'models/${item['name']}'});
        }
      }
      cancellation.check();
      if (probe.exitCode != 0 ||
          !probe.diagnostics.contains('"available":true') &&
              !probe.diagnostics.contains('"available": true')) {
        throw LocalUpscaleException(
          key == 'rtx' ? LocalUpscaleError.noRtx : LocalUpscaleError.noCuda,
        );
      }
      onProgress?.call('checking', null);
      var diskBytes = 0;
      await for (final file in stage.list(
        recursive: true,
        followLinks: false,
      )) {
        if (file is File) diskBytes += await file.length();
      }
      final receipt = {
        'ready': true,
        'manifest': manifestDigest,
        'installation': name,
        'files': verified,
        'disk_bytes': diskBytes,
      };
      final pointer = _pointer(id);
      await _contained(pointer.path);
      final temporary = File('${pointer.path}.part');
      await _contained(temporary.path);
      await temporary.writeAsString(jsonEncode(receipt), flush: true);
      if (await pointer.exists()) await pointer.delete();
      await temporary.rename(pointer.path);
      stage = null; // The venv must remain at its original absolute path.
    } finally {
      try {
        if (stage != null) await _remove(stage);
      } finally {
        releaseInference();
      }
    }
  }

  Future<void> delete(String id) async {
    claimInference();
    try {
      await initialize();
      final receipt = await _receipt(id);
      if (receipt != null) {
        await _remove(
          Directory(
            p.join(directory.path, 'installs', receipt['installation']),
          ),
        );
      }
      final pointer = _pointer(id);
      await _contained(pointer.path);
      if (await pointer.exists()) await pointer.delete();
    } finally {
      releaseInference();
    }
  }

  Future<AdvancedUpscaleCommand> command(
    String id,
    String input,
    String output,
    int width,
    int height,
    LocalUpscaleCancellation cancellation,
  ) async {
    await initialize();
    final receipt = await _receipt(id);
    if (receipt == null) {
      throw const LocalUpscaleException(LocalUpscaleError.modelMissing);
    }
    final root = p.join(directory.path, 'installs', receipt['installation']);
    for (final spec
        in (receipt['files'] as List).cast<Map<String, dynamic>>()) {
      cancellation.check();
      await _verify(File(_child(root, spec['path'])), spec);
    }
    cancellation.check();
    final host = await worker();
    if (_key(id) == 'rtx') {
      return AdvancedUpscaleCommand(host, host, [
        '--rtx',
        root,
        input,
        output,
        '$width',
        '$height',
      ]);
    }
    return AdvancedUpscaleCommand(
      host,
      p.join(root, 'venv', 'Scripts', 'python.exe'),
      [
        p.join(root, 'worker.py'),
        p.join(root, 'source'),
        input,
        '--output',
        output,
        '--output_format',
        'png',
        '--model_dir',
        p.join(root, 'models'),
        '--dit_model',
        'seedvr2_ema_3b_fp8_e4m3fn.safetensors',
        '--resolution',
        '${width < height ? width : height}',
        '--max_resolution',
        '${width > height ? width : height}',
        '--batch_size',
        '1',
        '--seed',
        '0',
        '--cuda_device',
        '0',
        '--attention_mode',
        'sdpa',
        '--dit_offload_device',
        'cpu',
        '--vae_offload_device',
        'cpu',
        '--tensor_offload_device',
        'cpu',
        '--vae_encode_tiled',
        '--vae_decode_tiled',
      ],
    );
  }
}
