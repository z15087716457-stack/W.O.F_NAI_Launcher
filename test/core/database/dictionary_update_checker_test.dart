import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/dictionary_data_store.dart';
import 'package:nai_launcher/core/database/dictionary_downloader.dart';
import 'package:nai_launcher/core/database/dictionary_update_checker.dart';

class _Metadata implements HttpClientAdapter {
  final calls = <String>[];
  String tagName = 'danbooru_2026-10-01_pt20-ia-dd.csv';
  String tagHash = dictionarySources[DictionaryKind.tags]!.gitBlobSha1;
  int tagSize = dictionarySources[DictionaryKind.tags]!.bytes;
  String wikiHash = dictionarySources[DictionaryKind.wiki]!.sha256;
  int status = 200;
  bool huge = false, missing = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? cancel,
  ) async {
    calls.add(o.uri.toString());
    Object value;
    if (o.path.contains('/git/ref/')) {
      value = {
        'object': {'sha': '1' * 40},
      };
    } else if (o.path.contains('/contents/')) {
      value = missing
          ? []
          : [
              {
                'type': 'file',
                'name': 'danbooru_2099-01-01_pt50-ia-dd.csv',
                'sha': '0' * 40,
                'size': 1,
              },
              {
                'type': 'file',
                'name': tagName,
                'sha': tagHash,
                'size': tagSize,
              },
            ];
    } else if (o.path.contains('/revision/')) {
      value = {'sha': '2' * 40};
    } else {
      value = [
        {
          'type': 'file',
          'path': 'danbooru-wiki-2606.jsonl',
          'size': 137932215,
          'lfs': {'oid': wikiHash},
          'lastCommit': {'date': '2026-10-17T01:02:03Z'},
        },
      ];
    }
    return ResponseBody.fromString(
      huge ? 'x' * (2 * 1024 * 1024 + 1) : jsonEncode(value),
      status,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Metadata adapter;
  late DictionaryUpdateChecker checker;
  setUp(() {
    adapter = _Metadata();
    checker = DictionaryUpdateChecker(dio: Dio()..httpClientAdapter = adapter);
  });
  tearDown(() => checker.close());

  test(
    'checks metadata only and ignores README commits and unrelated CSV variants',
    () async {
      final result = await checker.check();
      expect(
        result.sources[DictionaryKind.tags],
        same(dictionarySources[DictionaryKind.tags]),
      );
      expect(
        result.sources[DictionaryKind.wiki],
        same(dictionarySources[DictionaryKind.wiki]),
      );
      expect(adapter.calls, hasLength(4));
      expect(
        adapter.calls.where(
          (u) =>
              u.contains('/resolve/') ||
              u.contains('raw.githubusercontent.com'),
        ),
        isEmpty,
      );
      expect(adapter.calls.any((u) => u.contains('ref=${'1' * 40}')), isTrue);
      expect(adapter.calls.any((u) => u.contains('/tree/${'2' * 40}')), isTrue);
    },
  );
  test(
    'new Tag content is pinned to a verified Git blob and immutable revision',
    () async {
      adapter.tagName = 'danbooru_2027-01-01_pt20-ia-dd.csv';
      adapter.tagHash = 'a' * 40;
      adapter.tagSize = 1234;
      final source = (await checker.check()).sources[DictionaryKind.tags]!;
      expect(source.gitBlobSha1, 'a' * 40);
      expect(source.sha256, isEmpty);
      expect(
        source.url,
        contains(
          '/${'1' * 40}/tag-lists/danbooru/danbooru_2027-01-01_pt20-ia-dd.csv',
        ),
      );
      expect(source.date, '2027-01-01');
    },
  );
  test('changed Wiki content uses its LFS hash and file commit date', () async {
    adapter.wikiHash = 'b' * 64;
    final source = (await checker.check()).sources[DictionaryKind.wiki]!;
    expect(source.sha256, 'b' * 64);
    expect(source.url, contains('/resolve/${'2' * 40}/'));
    expect(source.date, '2026-10-17');
  });
  for (final fault in ['hash', 'size', 'date', 'missing', 'http', 'huge']) {
    test('metadata $fault cannot produce an available source', () async {
      switch (fault) {
        case 'hash':
          adapter.tagHash = 'invalid';
        case 'size':
          adapter.tagSize = 0;
        case 'date':
          adapter.tagName = 'danbooru_2026-02-31_pt20-ia-dd.csv';
        case 'missing':
          adapter.missing = true;
        case 'http':
          adapter.status = 503;
        case 'huge':
          adapter.huge = true;
      }
      await expectLater(checker.check(), throwsA(anything));
    });
  }
  test('cancellation does not return a successful check', () async {
    checker.cancel();
    await expectLater(checker.check(), throwsA(anything));
  });
  test(
    'successful checks persist and replace earlier metadata without changing source commits',
    () async {
      final root = await Directory.systemTemp.createTemp('dictionary-check-');
      addTearDown(() => root.delete(recursive: true));
      final result = await checker.check();
      await DictionaryUpdateChecker.save(root, result);
      final loaded = (await DictionaryUpdateChecker.load(root))!;
      expect(loaded.checkedAt, result.checkedAt);
      expect(
        loaded.sources[DictionaryKind.tags]!.sha256,
        dictionarySources[DictionaryKind.tags]!.sha256,
      );
      await DictionaryUpdateChecker.save(
        root,
        DictionaryCheckResult(
          result.sources,
          result.checkedAt.add(const Duration(seconds: 1)),
        ),
      );
      expect(
        (await DictionaryUpdateChecker.load(root))!.checkedAt,
        isNot(loaded.checkedAt),
      );
      expect(
        root.listSync().map((f) => f.path.split(Platform.pathSeparator).last),
        ['latest-check.json'],
      );
    },
  );
  test(
    'corrupt cache or mutable and foreign download URLs are ignored',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'dictionary-check-bad-',
      );
      addTearDown(() => root.delete(recursive: true));
      final result = await checker.check();
      for (final url in [
        'https://evil.invalid/file',
        'https://raw.githubusercontent.com/DraconicDragon/dbr-e621-lists-archive/main/tag-lists/danbooru/danbooru_2026-10-01_pt20-ia-dd.csv',
      ]) {
        await DictionaryUpdateChecker.save(root, result);
        final file = File('${root.path}/latest-check.json');
        final data = jsonDecode(await file.readAsString());
        data['sources'][0]['url'] = url;
        await file.writeAsString(jsonEncode(data));
        expect(await DictionaryUpdateChecker.load(root), isNull);
      }
      await File('${root.path}/latest-check.json').writeAsString('{broken');
      expect(await DictionaryUpdateChecker.load(root), isNull);
    },
  );
}
