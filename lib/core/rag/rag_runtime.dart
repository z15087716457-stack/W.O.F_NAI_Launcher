import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'rag_client.dart';
import 'rag_platform.dart';
import 'rag_process.dart';
import 'rag_runtime_probe.dart';

/// One pinned official uv 0.13.1 build; the hash is the release's `.sha256`.
class RagUvRelease {
  const RagUvRelease({
    required this.url,
    required this.sha256,
    required this.entry,
    required this.file,
  });
  final String url, sha256;

  /// The executable inside the archive, and the name it is saved under.
  final String entry, file;
}

/// Explicit optional installation. Merely opening settings never downloads.
class RagRuntimeInstaller {
  /// [uv] and [start] replace the pinned download and process launch in tests.
  RagRuntimeInstaller(
    this.root, {
    Dio? dio,
    RagRuntimeProbe? probe,
    RagPlatform? platform,
    RagUvRelease? uv,
    RagProcessStarter start = Process.start,
  }) : platform = platform ?? RagPlatform.host,
       _dio = dio ?? Dio(),
       _probe = probe ?? RagRuntimeProbe(platform: platform),
       _uv = uv,
       _start = start;
  final Directory root;
  final RagPlatform platform;
  final Dio _dio;
  final RagRuntimeProbe _probe;
  final RagUvRelease? _uv;
  final RagProcessStarter _start;
  String _detail = '';
  String get diagnostic => _detail;
  final _cancel = CancelToken();
  Process? _process;
  bool _cancelled = false;
  static const windowsUv = RagUvRelease(
    url:
        'https://github.com/astral-sh/uv/releases/download/0.13.1/uv-x86_64-pc-windows-msvc.zip',
    sha256: '3b2661a463a5baea7f5076ea2b25ab71d77f36a6c0d809e5350651792f80a672',
    entry: 'uv.exe',
    file: 'uv-0.13.1.exe',
  );
  static const macOSArm64Uv = RagUvRelease(
    url:
        'https://github.com/astral-sh/uv/releases/download/0.13.1/uv-aarch64-apple-darwin.tar.gz',
    sha256: 'cfe454573412ff7380d15fc7dae5997ab53ffce72fce0a78e91ddbc84001acd2',
    entry: 'uv',
    file: 'uv-0.13.1',
  );

  /// No build is pinned for Intel Macs: PyTorch 2.10 has no wheels for them.
  static RagUvRelease? uvFor(RagPlatform platform) => switch (platform) {
    RagPlatform.windows => windowsUv,
    RagPlatform.macOSArm64 => macOSArm64Uv,
    RagPlatform.macOSX64 || RagPlatform.other => null,
  };

  String get python => platform.managedPython(root.path);
  void cancel() {
    _cancelled = true;
    _cancel.cancel();
    _process?.kill();
    _probe.cancel();
  }

  void _check() {
    if (_cancelled) throw const RagException('cancelled');
  }

  Future<void> _run(String exe, List<String> args) async {
    _check();
    final process = _process = await startRagProcess(
      directory: root,
      executable: exe,
      arguments: args,
      environment: {
        'UV_PYTHON_INSTALL_DIR': p.join(root.path, 'python'),
        'UV_CACHE_DIR': p.join(root.path, 'download-cache'),
        'NO_COLOR': '1',
        'PYTHONUTF8': '1',
      },
      platform: platform,
      start: _start,
    );
    String safeLine(String line) => line
        .replaceAll(RegExp(r'\[[0-9;]*[a-zA-Z]'), '')
        .replaceAll(RegExp(r'https?://\S+'), '[url]')
        .replaceAll(root.path, '[rag]');
    void output(List<int> bytes) {
      final text = safeLine(utf8.decode(bytes, allowMalformed: true)).trim();
      if (text.isNotEmpty &&
          !text.startsWith('DEBUG ') &&
          !text.startsWith('TRACE ')) {
        _detail = text.length > 200 ? text.substring(text.length - 200) : text;
      }
    }

    final out = process.stdout.listen(output);
    final err = process.stderr.listen(output);
    try {
      final code = await process.exitCode.timeout(const Duration(minutes: 30));
      _check();
      if (code != 0) throw const RagException('runtime_install_failed');
    } on TimeoutException {
      throw const RagException('runtime_install_timeout');
    } finally {
      process.kill();
      await out.cancel();
      await err.cancel();
      _process = null;
    }
  }

  Future<String> install({
    required bool cuda,
    required void Function(String) onPhase,
    String preferredPython = '',
    void Function(int elapsedSeconds, String detail)? onProgress,
  }) async {
    // Macs have no CUDA build; the worker picks the GPU (MPS) at run time.
    final useCuda = cuda && platform.supportsCuda;
    await root.create(recursive: true);
    final elapsed = Stopwatch()..start();
    void phase(String value) {
      elapsed.reset();
      _detail = '';
      onPhase(value);
    }

    final ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => onProgress?.call(elapsed.elapsed.inSeconds, _detail),
    );
    try {
      phase('existing');
      final existing = await _probe.inspect(root, preferredPython);
      _check();
      if (existing.ready && (!useCuda || existing.cuda)) {
        return existing.python;
      }
      final release = _uv ?? uvFor(platform);
      if (release == null) throw const RagException('unsupported_platform');
      phase('download');
      final response = await _dio.get<List<int>>(
        release.url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 5),
        ),
        cancelToken: _cancel,
        onReceiveProgress: (received, _) {
          if (received > 32 * 1024 * 1024) _cancel.cancel();
        },
      );
      _check();
      final bytes = response.data!;
      if (sha256.convert(bytes).toString() != release.sha256) {
        throw const RagException('runtime_integrity');
      }
      final archive = release.url.endsWith('.zip')
          ? ZipDecoder().decodeBytes(bytes, verify: true)
          : TarDecoder().decodeBytes(
              GZipDecoder().decodeBytes(bytes, verify: true),
            );
      final entry = archive.files
          .where(
            (f) =>
                p.basename(f.name) == release.entry &&
                f.isFile &&
                !f.isSymbolicLink,
          )
          .single;
      final uv = File(p.join(root.path, release.file));
      await uv.writeAsBytes(entry.content, flush: true);
      if (platform != RagPlatform.windows) {
        await _run('/bin/chmod', ['755', uv.path]);
      }
      phase('create');
      if (!await File(python).exists()) {
        await _run(uv.path, [
          'venv',
          '--python',
          '3.12.11',
          p.join(root.path, 'runtime'),
        ]);
      }
      phase(useCuda ? 'cuda' : 'packages');
      await _run(uv.path, [
        '-v',
        'pip',
        'install',
        '--python',
        python,
        '--index-url',
        if (platform == RagPlatform.windows) ...[
          useCuda
              ? 'https://download.pytorch.org/whl/cu128'
              : 'https://download.pytorch.org/whl/cpu',
          useCuda ? 'torch==2.10.0+cu128' : 'torch==2.10.0+cpu',
          useCuda ? 'torchvision==0.25.0+cu128' : 'torchvision==0.25.0+cpu',
        ] else ...[
          // PyPI's macOS build is the one with MPS (Apple GPU) support.
          'https://pypi.org/simple',
          'torch==2.10.0',
          'torchvision==0.25.0',
        ],
      ]);
      final requirements = File(p.join(root.path, 'requirements-v1.txt'));
      await requirements.writeAsString(
        await rootBundle.loadString('tool/rag/requirements.txt'),
        flush: true,
      );
      phase('packages');
      await _run(uv.path, [
        '-v',
        'pip',
        'install',
        '--python',
        python,
        '-r',
        requirements.path,
      ]);
      phase('check');
      await _run(python, [
        '-c',
        'import torch, torchvision, transformers, sentence_transformers, usearch; from transformers.models.embedding_gemma2 import EmbeddingGemma2Model',
      ]);
      await File(p.join(root.path, 'runtime-receipt.json')).writeAsString(
        jsonEncode({
          'version': 1,
          'uvArchiveSha256': release.sha256,
          'cuda': useCuda,
          'python': '3.12.11',
          'torch': '2.10.0',
          'torchvision': '0.25.0',
          'transformers': '5.19.0',
          'sentenceTransformers': '6.1.0',
        }),
        flush: true,
      );
      return python;
    } catch (_) {
      if (_cancelled) throw const RagException('cancelled');
      rethrow;
    } finally {
      ticker.cancel();
    }
  }

  void dispose() {
    cancel();
    _dio.close(force: true);
  }
}
