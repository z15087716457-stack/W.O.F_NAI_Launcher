import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'dictionary_data_store.dart';
import 'dictionary_downloader.dart';

class DictionaryCheckResult {
  const DictionaryCheckResult(this.sources, this.checkedAt);
  final Map<DictionaryKind, DictionarySource> sources;
  final DateTime checkedAt;
}

/// Public file metadata only. No source file is fetched until Install is chosen.
class DictionaryUpdateChecker {
  DictionaryUpdateChecker({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'User-Agent': 'WOF-NAI-Studio-Dictionary/1.0'},
              followRedirects: false,
            ),
          );

  final Dio _dio;
  final _cancel = CancelToken();
  static const _repository = 'DraconicDragon/dbr-e621-lists-archive';
  static const _wiki = 'patvessel/danbooru-wiki-2606';
  static final _revision = RegExp(r'^[a-f0-9]{40}$');
  static final _sha256 = RegExp(r'^[a-f0-9]{64}$');
  static final _tagFile = RegExp(
    r'^danbooru_(\d{4}-\d{2}-\d{2})_pt20-ia-dd\.csv$',
  );

  void cancel() => _cancel.cancel();
  void close() => _dio.close(force: true);

  Future<dynamic> _json(String url) async {
    final response = await _dio.get<ResponseBody>(
      url,
      options: Options(responseType: ResponseType.stream),
      cancelToken: _cancel,
    );
    final chunks = <int>[];
    await for (final chunk in response.data!.stream) {
      if (chunks.length + chunk.length > 2 * 1024 * 1024) {
        throw const FormatException('dictionary_metadata_size');
      }
      chunks.addAll(chunk);
    }
    return jsonDecode(utf8.decode(chunks));
  }

  Future<DictionaryCheckResult> check() async {
    final sources = await Future.wait([_tags(), _wikiSource()]);
    if (_cancel.isCancelled) throw _cancel.cancelError!;
    return DictionaryCheckResult({
      for (final source in sources) source.kind: source,
    }, DateTime.now().toUtc());
  }

  Future<DictionarySource> _tags() async {
    final ref = await _json(
      'https://api.github.com/repos/$_repository/git/ref/heads/main',
    );
    final revision = ref is Map && ref['object'] is Map
        ? ref['object']['sha']
        : null;
    if (revision is! String || !_revision.hasMatch(revision)) {
      throw const FormatException('dictionary_revision');
    }
    final files = await _json(
      'https://api.github.com/repos/$_repository/contents/tag-lists/danbooru?ref=$revision',
    );
    if (files is! List) throw const FormatException('dictionary_metadata');
    final candidates = <Map>[];
    for (final file in files) {
      if (file is Map &&
          file['type'] == 'file' &&
          file['name'] is String &&
          _tagFile.hasMatch(file['name'])) {
        candidates.add(file);
      }
    }
    candidates.sort(
      (a, b) => (b['name'] as String).compareTo(a['name'] as String),
    );
    if (candidates.isEmpty) throw const FormatException('dictionary_missing');
    final file = candidates.first;
    final name = file['name'] as String;
    final date = _tagFile.firstMatch(name)!.group(1)!;
    final blob = file['sha'];
    final size = file['size'];
    if (blob is! String ||
        !_revision.hasMatch(blob) ||
        size is! int ||
        size <= 0 ||
        size > 64 * 1024 * 1024 ||
        !_validDate(date)) {
      throw const FormatException('dictionary_metadata');
    }
    final pinned = dictionarySources[DictionaryKind.tags]!;
    if (blob == pinned.gitBlobSha1) {
      if (size != pinned.bytes) {
        throw const FormatException('dictionary_metadata');
      }
      return pinned;
    }
    return DictionarySource(
      DictionaryKind.tags,
      'https://raw.githubusercontent.com/$_repository/$revision/tag-lists/danbooru/$name',
      '',
      size,
      date,
      pinned.name,
      gitBlobSha1: blob,
    );
  }

  Future<DictionarySource> _wikiSource() async {
    final info = await _json(
      'https://huggingface.co/api/datasets/$_wiki/revision/main',
    );
    final revision = info is Map ? info['sha'] : null;
    if (revision is! String || !_revision.hasMatch(revision)) {
      throw const FormatException('dictionary_revision');
    }
    final files = await _json(
      'https://huggingface.co/api/datasets/$_wiki/tree/$revision?expand=true&limit=100',
    );
    if (files is! List) throw const FormatException('dictionary_metadata');
    final file = files
        .whereType<Map>()
        .where(
          (f) => f['type'] == 'file' && f['path'] == 'danbooru-wiki-2606.jsonl',
        )
        .firstOrNull;
    final hash = file?['lfs'] is Map ? file!['lfs']['oid'] : null;
    final size = file?['size'];
    if (hash is! String ||
        !_sha256.hasMatch(hash) ||
        size is! int ||
        size <= 0 ||
        size > 512 * 1024 * 1024) {
      throw const FormatException('dictionary_metadata');
    }
    final pinned = dictionarySources[DictionaryKind.wiki]!;
    if (hash == pinned.sha256) {
      if (size != pinned.bytes) {
        throw const FormatException('dictionary_metadata');
      }
      return pinned;
    }
    final updated = file?['lastCommit'] is Map
        ? file!['lastCommit']['date']
        : null;
    final parsed = updated is String ? DateTime.tryParse(updated) : null;
    if (parsed == null) throw const FormatException('dictionary_metadata_date');
    return DictionarySource(
      DictionaryKind.wiki,
      'https://huggingface.co/datasets/$_wiki/resolve/$revision/danbooru-wiki-2606.jsonl',
      hash,
      size,
      parsed.toUtc().toIso8601String().substring(0, 10),
      pinned.name,
    );
  }

  static bool _validDate(String date) {
    final parsed = DateTime.tryParse(date);
    return parsed != null && parsed.toIso8601String().substring(0, 10) == date;
  }

  static Map<String, Object> _encodeSource(DictionarySource source) => {
    'kind': source.kind.name,
    'url': source.url,
    'sha256': source.sha256,
    'gitBlobSha1': source.gitBlobSha1,
    'bytes': source.bytes,
    'date': source.date,
    'name': source.name,
  };

  static Future<void> save(Directory root, DictionaryCheckResult result) async {
    await root.create(recursive: true);
    final pending = File(
      p.join(
        root.path,
        'check-${DateTime.now().microsecondsSinceEpoch}.pending',
      ),
    );
    try {
      await pending.writeAsString(
        jsonEncode({
          'schema': 1,
          'checkedAt': result.checkedAt.toIso8601String(),
          'sources': [for (final s in result.sources.values) _encodeSource(s)],
        }),
        flush: true,
      );
      await pending.rename(p.join(root.path, 'latest-check.json'));
    } finally {
      if (await pending.exists()) await pending.delete();
    }
  }

  static Future<DictionaryCheckResult?> load(Directory root) async {
    try {
      final file = File(p.join(root.path, 'latest-check.json'));
      if (await file.length() > 16384) return null;
      final data = jsonDecode(await file.readAsString());
      if (data is! Map || data['schema'] != 1 || data['sources'] is! List) {
        return null;
      }
      final time = DateTime.tryParse(data['checkedAt'] as String);
      if (time == null ||
          time.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 5)))) {
        return null;
      }
      final sources = <DictionaryKind, DictionarySource>{};
      for (final s in data['sources']) {
        if (s is! Map) return null;
        final kind = DictionaryKind.values.byName(s['kind'] as String);
        final value = DictionarySource(
          kind,
          s['url'] as String,
          s['sha256'] as String,
          s['bytes'] as int,
          s['date'] as String,
          s['name'] as String,
          gitBlobSha1: s['gitBlobSha1'] as String,
        );
        final uri = Uri.parse(value.url);
        final parts = uri.pathSegments;
        if (!_validDate(value.date) ||
            value.bytes <= 0 ||
            uri.scheme != 'https' ||
            uri.hasQuery ||
            uri.hasFragment ||
            uri.userInfo.isNotEmpty) {
          return null;
        }
        if (kind == DictionaryKind.tags) {
          if (value.bytes > 64 * 1024 * 1024 ||
              !_revision.hasMatch(value.gitBlobSha1) ||
              uri.host != 'raw.githubusercontent.com' ||
              parts.length != 6 ||
              parts.take(2).join('/') != _repository ||
              !_revision.hasMatch(parts[2]) ||
              parts[3] != 'tag-lists' ||
              parts[4] != 'danbooru' ||
              !_tagFile.hasMatch(parts[5]) ||
              _tagFile.firstMatch(parts[5])!.group(1) != value.date ||
              (value.sha256.isNotEmpty &&
                  value.sha256 != dictionarySources[kind]!.sha256)) {
            return null;
          }
        } else {
          if (value.bytes > 512 * 1024 * 1024 ||
              !_sha256.hasMatch(value.sha256) ||
              uri.host != 'huggingface.co' ||
              parts.length != 6 ||
              parts.take(3).join('/') != 'datasets/$_wiki' ||
              parts[3] != 'resolve' ||
              !_revision.hasMatch(parts[4]) ||
              parts[5] != 'danbooru-wiki-2606.jsonl') {
            return null;
          }
        }
        if (sources.containsKey(kind)) return null;
        sources[kind] = value;
      }
      return sources.length == 2 ? DictionaryCheckResult(sources, time) : null;
    } catch (_) {
      return null;
    }
  }
}
