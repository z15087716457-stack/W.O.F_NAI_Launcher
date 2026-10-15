import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'rag_client.dart';
import 'rag_process.dart';
import 'rag_runtime_probe.dart';

/// Explicit optional installation. Merely opening settings never downloads.
class RagRuntimeInstaller {
  RagRuntimeInstaller(this.root, {Dio? dio, RagRuntimeProbe? probe})
    : _dio = dio ?? Dio(),
      _probe = probe ?? RagRuntimeProbe();
  final Directory root;
  final Dio _dio;
  final RagRuntimeProbe _probe;
  String _detail = '';
  String get diagnostic => _detail;
  final _cancel = CancelToken();
  Process? _process;
  bool _cancelled = false;
  static const uvUrl =
      'https://github.com/astral-sh/uv/releases/download/0.13.1/uv-x86_64-pc-windows-msvc.zip';
  static const uvSha256 =
      '3b2661a463a5baea7f5076ea2b25ab71d77f36a6c0d809e5350651792f80a672';
  String get python => p.join(root.path, 'runtime', 'Scripts', 'python.exe');
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
    if (!Platform.isWindows) throw const RagException('unsupported_platform');
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
      if (existing.ready && (!cuda || existing.cuda)) return existing.python;
      phase('download');
      final response = await _dio.get<List<int>>(
        uvUrl,
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
      if (sha256.convert(bytes).toString() != uvSha256) {
        throw const RagException('runtime_integrity');
      }
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      final entry = archive.files
          .where((f) => p.basename(f.name) == 'uv.exe' && f.isFile)
          .single;
      final uv = File(p.join(root.path, 'uv-0.13.1.exe'));
      await uv.writeAsBytes(entry.content, flush: true);
      phase('create');
      if (!await File(python).exists()) {
        await _run(uv.path, [
          'venv',
          '--python',
          '3.12.11',
          p.join(root.path, 'runtime'),
        ]);
      }
      phase(cuda ? 'cuda' : 'packages');
      await _run(uv.path, [
        '-v',
        'pip',
        'install',
        '--python',
        python,
        '--index-url',
        cuda
            ? 'https://download.pytorch.org/whl/cu128'
            : 'https://download.pytorch.org/whl/cpu',
        cuda ? 'torch==2.10.0+cu128' : 'torch==2.10.0+cpu',
        cuda ? 'torchvision==0.25.0+cu128' : 'torchvision==0.25.0+cpu',
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
          'uvArchiveSha256': uvSha256,
          'cuda': cuda,
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
