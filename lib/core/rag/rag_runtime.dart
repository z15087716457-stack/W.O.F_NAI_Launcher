import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'rag_client.dart';
import 'rag_process.dart';

/// Explicit optional installation. Merely opening settings never downloads.
class RagRuntimeInstaller {
  RagRuntimeInstaller(this.root, {Dio? dio}) : _dio = dio ?? Dio();
  final Directory root;
  final Dio _dio;
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
        'UV_NO_PROGRESS': '1',
        'PYTHONUTF8': '1',
      },
    );
    final out = process.stdout.drain<void>();
    final err = process.stderr.drain<void>();
    final code = await process.exitCode;
    await out;
    await err;
    _process = null;
    _check();
    if (code != 0) throw const RagException('runtime_install_failed');
  }

  Future<String> install({
    required bool cuda,
    required void Function(String) onPhase,
  }) async {
    if (!Platform.isWindows) throw const RagException('unsupported_platform');
    await root.create(recursive: true);
    onPhase('download');
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
    onPhase('create');
    await _run(uv.path, [
      'venv',
      '--python',
      '3.12.11',
      p.join(root.path, 'runtime'),
    ]);
    onPhase(cuda ? 'cuda' : 'packages');
    await _run(uv.path, [
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
    onPhase('packages');
    await _run(uv.path, [
      'pip',
      'install',
      '--python',
      python,
      '-r',
      requirements.path,
    ]);
    onPhase('check');
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
  }

  void dispose() {
    cancel();
    _dio.close(force: true);
  }
}
