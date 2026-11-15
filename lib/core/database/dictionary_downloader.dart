import 'dart:io';
import 'dart:isolate';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'dictionary_builder.dart';
import 'dictionary_data_store.dart';

class DictionarySource {
  const DictionarySource(
    this.kind,
    this.url,
    this.sha256,
    this.bytes,
    this.date,
    this.name, {
    this.gitBlobSha1 = '',
  });
  final DictionaryKind kind;
  final String url, sha256, date, name;
  final int bytes;
  final String gitBlobSha1;

  bool matches(Map<String, dynamic>? record) =>
      record != null &&
      ((sha256.isNotEmpty && record['sourceHash'] == sha256) ||
          (gitBlobSha1.isNotEmpty && record['sourceBlobSha1'] == gitBlobSha1));
}

const dictionarySources = <DictionaryKind, DictionarySource>{
  DictionaryKind.tags: DictionarySource(
    DictionaryKind.tags,
    'https://raw.githubusercontent.com/z15087716457-stack/W.O.F_NAI_Launcher/main/tool/dictionary_updates/sources/tags-2026-11-03.csv',
    '86d2829874a494391fb1e96facdfabe0f99ec4648e48b6d5d84a89464ef0bc8b',
    5690115,
    '2026-11-03',
    'DraconicDragon / Danbooru',
    gitBlobSha1: '90aa0b57b0fd69dd211014554a46a4cd2a7625f3',
  ),
  DictionaryKind.wiki: DictionarySource(
    DictionaryKind.wiki,
    'https://media.githubusercontent.com/media/z15087716457-stack/W.O.F_NAI_Launcher/main/tool/dictionary_updates/sources/wiki-2026-09-02.jsonl',
    '0acd0b898421d866e38cc4a53d3522bf68b4c5d68526cd2fb6703e7d9e0b9e96',
    99870880,
    '2026-09-02',
    'dartags / Danbooru Wiki',
  ),
};

enum DictionaryPhase { downloading, verifying, importing, publishing }

class DictionaryProgress {
  const DictionaryProgress(
    this.phase, {
    this.received = 0,
    this.total = 0,
    this.rows = 0,
  });
  final DictionaryPhase phase;
  final int received, total, rows;
}

class DictionaryDownloader {
  DictionaryDownloader(this.store, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(minutes: 2),
              headers: {'User-Agent': 'WOF-NAI-Studio-Dictionary/1.0'},
            ),
          );
  final DictionaryDataStore store;
  final Dio _dio;
  final _cancel = CancelToken();
  File? _flag;
  bool _cancelled = false, _publishing = false;
  void cancel() {
    if (_publishing) return;
    _cancelled = true;
    _cancel.cancel();
    _flag?.writeAsStringSync('cancel');
  }

  Future<Map<String, int>> install(
    DictionarySource source,
    String seed,
    void Function(DictionaryProgress) report,
  ) async {
    await store.root.create(recursive: true);
    final work = await store.root.createTemp('job-');
    _flag = File(p.join(work.path, 'cancel'));
    final input = File(p.join(work.path, 'download'));
    final output = File(p.join(work.path, 'next.db'));
    final expected = store.activePath(source.kind);
    final port = ReceivePort();
    final listener = port.listen((rows) {
      // Progress and the isolate result use separate ports. Late progress must
      // not move the UI back from its non-cancellable activation step.
      if (!_publishing && !_cancelled) {
        report(
          DictionaryProgress(DictionaryPhase.importing, rows: rows as int),
        );
      }
    });
    try {
      if (_cancelled) throw StateError('dictionary_cancelled');
      report(
        DictionaryProgress(DictionaryPhase.downloading, total: source.bytes),
      );
      await _dio.download(
        source.url,
        input.path,
        cancelToken: _cancel,
        onReceiveProgress: (received, total) {
          if (received > source.bytes) {
            _cancel.cancel('size');
            return;
          }
          report(
            DictionaryProgress(
              DictionaryPhase.downloading,
              received: received,
              total: source.bytes,
            ),
          );
        },
      );
      checkDictionaryCancellation(_flag!.path);
      report(const DictionaryProgress(DictionaryPhase.verifying));
      final digest = (await sha256.bind(input.openRead()).first).toString();
      if (await input.length() != source.bytes ||
          (source.sha256.isEmpty && source.gitBlobSha1.isEmpty) ||
          (source.sha256.isNotEmpty && digest != source.sha256) ||
          (source.gitBlobSha1.isNotEmpty &&
              (await sha1.bind(_gitBlob(input, source.bytes)).first)
                      .toString() !=
                  source.gitBlobSha1)) {
        throw StateError('dictionary_integrity');
      }
      checkDictionaryCancellation(_flag!.path);
      report(const DictionaryProgress(DictionaryPhase.importing));
      final args = <String, Object>{
        'kind': source.kind.name,
        'seed': seed,
        'input': input.path,
        'output': output.path,
        'cancel': _flag!.path,
        'version': digest.substring(0, 12),
        'progress': port.sendPort,
      };
      final result = await buildDictionaryInBackground(args);
      checkDictionaryCancellation(_flag!.path);
      _publishing = true;
      report(const DictionaryProgress(DictionaryPhase.publishing));
      await store.publish(source.kind, output, {
        'count': result['count'],
        'added': result['added'],
        'updated': result['updated'] ?? 0,
        'mergeVersion': source.kind == DictionaryKind.wiki ? 2 : 1,
        'date': source.date,
        'sourceHash': digest,
        if (source.gitBlobSha1.isNotEmpty) 'sourceBlobSha1': source.gitBlobSha1,
        'sourceName': source.name,
        'sourceUrl': source.url,
        'installedAt': DateTime.now().toUtc().toIso8601String(),
      }, expectedPath: expected);
      return result;
    } finally {
      _flag = null;
      await listener.cancel();
      port.close();
      // Only our randomly-created job directory, after the worker closed SQLite.
      if (p.isWithin(p.absolute(store.root.path), p.absolute(work.path)) &&
          await work.exists()) {
        await work.delete(recursive: true);
      }
      _dio.close(force: true);
    }
  }
}

Stream<List<int>> _gitBlob(File input, int bytes) async* {
  yield utf8.encode('blob $bytes\u0000');
  yield* input.openRead();
}
