import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'rag_client.dart';

class RagModelDownloadProgress {
  const RagModelDownloadProgress(
    this.received,
    this.total, {
    this.checking = false,
  });
  final int received, total;
  final bool checking;
  double get fraction => total == 0 ? 0 : (received / total).clamp(0, 1);
}

/// Pinned official model files, streamed to disk. Never writes selected external
/// model folders; only publishes a managed path after every file is verified.
class RagModelDownloader {
  RagModelDownloader(
    this.root, {
    Dio? dio,
    Future<String> Function()? manifestLoader,
    Uri Function(String, String, String)? fileUri,
  }) : _dio = dio ?? Dio(),
       _manifestLoader =
           manifestLoader ??
           (() => rootBundle.loadString('assets/rag/model_manifest.json')),
       _fileUri =
           fileUri ??
           ((repo, revision, path) =>
               Uri.https('huggingface.co', '/$repo/resolve/$revision/$path'));
  final Directory root;
  final Dio _dio;
  final Future<String> Function() _manifestLoader;
  final Uri Function(String, String, String) _fileUri;
  final _cancel = CancelToken();
  void cancel() => _cancel.cancel();
  void dispose() {
    cancel();
    _dio.close(force: true);
  }

  void _check() {
    if (_cancel.isCancelled) throw const RagException('cancelled');
  }

  Future<String> _hash(File file) async =>
      (await sha256.bind(file.openRead()).first).toString();
  Future<bool> _valid(File file, Map<String, dynamic> spec) async =>
      await file.exists() &&
      await file.length() == spec['bytes'] &&
      await _hash(file) == spec['sha256'];

  Future<String> install(
    String kind,
    void Function(RagModelDownloadProgress) progress,
  ) async {
    if (kind != 'embedding' && kind != 'reranker') {
      throw const RagException('models_missing');
    }
    final manifest = jsonDecode(await _manifestLoader()) as Map;
    if (manifest['version'] != 1) throw const RagException('model_integrity');
    final spec = (manifest['models'] as List).cast<Map>().singleWhere(
      (m) => m['id'] == kind,
    );
    final repo = spec['repository'] as String,
        revision = spec['revision'] as String;
    if (!{
          'google/embeddinggemma-2',
          'Qwen/Qwen3-Reranker-0.6B',
        }.contains(repo) ||
        !RegExp(r'^[0-9a-f]{40}$').hasMatch(revision)) {
      throw const RagException('model_integrity');
    }
    final files = (spec['files'] as List)
        .map((f) => (f as Map).cast<String, dynamic>())
        .toList();
    for (final f in files) {
      final name = f['path'] as String;
      if (name.isEmpty ||
          p.posix.isAbsolute(name) ||
          name.contains('\\') ||
          name.contains(':') ||
          name.split('/').any((s) => s == '..' || s == '.' || s.isEmpty) ||
          f['bytes'] is! int ||
          (f['bytes'] as int) < 0 ||
          !RegExp(r'^[0-9a-f]{64}$').hasMatch(f['sha256'] as String)) {
        throw const RagException('model_integrity');
      }
    }
    if (files.map((f) => f['path']).toSet().length != files.length) {
      throw const RagException('model_integrity');
    }
    final directory = Directory(p.join(root.path, 'models', kind, revision));
    await directory.create(recursive: true);
    final safeRoot = await directory.resolveSymbolicLinks();
    final total = files.fold<int>(0, (n, f) => n + (f['bytes'] as int));
    var completed = 0;
    for (final file in files) {
      _check();
      final target = File(p.join(directory.path, file['path'] as String));
      await target.parent.create(recursive: true);
      if (!p.isWithin(safeRoot, await target.parent.resolveSymbolicLinks()) &&
          !p.equals(safeRoot, await target.parent.resolveSymbolicLinks())) {
        throw const RagException('model_integrity');
      }
      if (await FileSystemEntity.type(target.path, followLinks: false) ==
          FileSystemEntityType.link) {
        throw const RagException('model_integrity');
      }
      final bytes = file['bytes'] as int;
      if (!await _valid(target, file)) {
        final partial = File('${target.path}.part');
        if (await FileSystemEntity.type(partial.path, followLinks: false) ==
            FileSystemEntityType.link) {
          throw const RagException('model_integrity');
        }
        var offset = await partial.exists() ? await partial.length() : 0;
        if (offset > bytes ||
            (offset == bytes && !await _valid(partial, file))) {
          await partial.delete();
          offset = 0;
        }
        if (offset < bytes) {
          final response = await _dio.get<ResponseBody>(
            _fileUri(repo, revision, file['path'] as String).toString(),
            options: Options(
              responseType: ResponseType.stream,
              headers: {if (offset > 0) 'Range': 'bytes=$offset-'},
              receiveTimeout: const Duration(minutes: 2),
            ),
            cancelToken: _cancel,
          );
          final range = response.headers.value('content-range');
          if (response.statusCode == 206) {
            final match = RegExp(
              r'^bytes (\d+)-(\d+)/(\d+)$',
            ).firstMatch(range ?? '');
            if (match == null ||
                int.parse(match[1]!) != offset ||
                int.parse(match[3]!) != bytes) {
              throw const RagException('model_integrity');
            }
          } else if (response.statusCode == 200) {
            offset = 0;
          } else {
            throw const RagException('model_download_failed');
          }
          final sink = partial.openWrite(
            mode: offset == 0 ? FileMode.write : FileMode.append,
          );
          try {
            await for (final chunk in response.data!.stream) {
              _check();
              offset += chunk.length;
              if (offset > bytes) throw const RagException('model_integrity');
              sink.add(chunk);
              progress(RagModelDownloadProgress(completed + offset, total));
            }
            await sink.flush();
          } finally {
            await sink.close();
          }
        }
        _check();
        progress(
          RagModelDownloadProgress(completed + bytes, total, checking: true),
        );
        if (!await _valid(partial, file)) {
          if (await partial.exists()) await partial.delete();
          throw const RagException('model_integrity');
        }
        _check();
        await partial.rename(target.path);
      }
      completed += bytes;
      progress(RagModelDownloadProgress(completed, total));
    }
    _check();
    await File(p.join(directory.path, 'model-receipt.json')).writeAsString(
      jsonEncode({
        'version': 1,
        'repository': repo,
        'revision': revision,
        'files': files,
      }),
      flush: true,
    );
    return directory.path;
  }
}
