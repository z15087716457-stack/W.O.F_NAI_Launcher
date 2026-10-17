import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/database/dictionary_data_store.dart';
import 'package:nai_launcher/core/database/dictionary_downloader.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/sqlite3.dart' as native;

class _Bytes implements HttpClientAdapter {
  _Bytes(this.bytes);
  final List<int> bytes;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromBytes(
    bytes,
    200,
    headers: {
      Headers.contentLengthHeader: ['${bytes.length}'],
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory root;
  late DictionaryDataStore store;
  late File tags, wiki;
  setUp(() {
    sqfliteFfiInit();
    root = Directory.systemTemp.createTempSync('dictionary_update_test_');
    store = DictionaryDataStore(Directory('${root.path}/updates'));
    tags = File('${root.path}/tags.db');
    wiki = File('${root.path}/wiki.db');
    final db = native.sqlite3.open(tags.path);
    db.execute('''
      CREATE TABLE metadata(key TEXT PRIMARY KEY, value TEXT NOT NULL);
      CREATE TABLE tags(id INTEGER PRIMARY KEY,name TEXT UNIQUE COLLATE NOCASE,category INTEGER,post_count INTEGER);
      CREATE TABLE aliases(id INTEGER PRIMARY KEY,tag_id INTEGER,alias TEXT COLLATE NOCASE,UNIQUE(tag_id,alias));
      CREATE VIRTUAL TABLE tag_search USING fts5(term,search_key,tag_id UNINDEXED,kind UNINDEXED);
      INSERT INTO tags VALUES(1,'blue_eyes',0,5),(2,'wolf',12,30);
      INSERT INTO aliases(tag_id,alias) VALUES(1,'aqua_eyes');
      INSERT INTO tag_search VALUES('blue_eyes','blue eyes',1,0),('wolf','wolf',2,0),('aqua_eyes','aqua eyes',1,1);
      INSERT INTO metadata VALUES('tag_count','2'),('data_version','bundle');
    ''');
    db.dispose();
    final w = native.sqlite3.open(wiki.path);
    w.execute(
      '''CREATE TABLE metadata(key TEXT PRIMARY KEY,value TEXT NOT NULL);
      CREATE TABLE wiki_pages(tag TEXT PRIMARY KEY,body TEXT NOT NULL,source_url TEXT NOT NULL);
      INSERT INTO wiki_pages VALUES('blue_eyes','Keep original article','https://example.invalid');''',
    );
    w.dispose();
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  DictionarySource source(DictionaryKind kind, String text) {
    final bytes = utf8.encode(text);
    return DictionarySource(
      kind,
      'https://fixture.invalid/data',
      sha256.convert(bytes).toString(),
      bytes.length,
      '2026-10-01',
      'Fixture',
    );
  }

  DictionaryDownloader downloader(String text) => DictionaryDownloader(
    store,
    dio: Dio()..httpClientAdapter = _Bytes(utf8.encode(text)),
  );

  test(
    'tag supplement is merged, searchable, immutable and persists after reopening',
    () async {
      const payload =
          'blue_eyes,0,20,"new_eyes,aqua_eyes"\nnew_character,4,12,"new_alias"\n';
      final original = tags.readAsBytesSync();
      var path = tags.path;
      final reader = TagCatalogRepository(path: () async => path);
      addTearDown(reader.dispose);
      expect(await reader.postCount('blue_eyes'), 5);
      final result = await downloader(
        payload,
      ).install(source(DictionaryKind.tags, payload), tags.path, (_) {});
      expect(result['added'], 1);
      expect(result['count'], 3);
      expect(tags.readAsBytesSync(), original);
      path = store.activePath(DictionaryKind.tags)!;
      expect(await reader.postCount('new_character'), 12);
      expect(await reader.postCount('blue_eyes'), 20);
      expect(
        (await reader.exactAliases(['new_alias']))['new_alias']!.canonicalTag,
        'new_character',
      );
      expect(
        (await reader.recordsByCanonicalTag(['wolf']))['wolf']!.category.name,
        'species',
      );
      final reopened = DictionaryDataStore(store.root);
      expect(await reopened.resolve(DictionaryKind.tags, tags.path), path);
      expect(reopened.record(DictionaryKind.tags)!['count'], 3);
      // A new bundled file remains separate from the selected supplement.
      final replacement = File('${root.path}/new-bundle.db');
      await tags.copy(replacement.path);
      expect(
        await reopened.resolve(DictionaryKind.tags, replacement.path),
        path,
      );
    },
  );

  test(
    'wiki adds missing articles, refreshes upstream text and preserves the original database',
    () async {
      final payload = [
        {'title': 'blue_eyes', 'body': 'Do not overwrite', 'is_deleted': false},
        {
          'title': 'New Tag',
          'body': 'h4. Heading\n\n[[blue_eyes]]',
          'is_deleted': false,
        },
        {'title': 'empty', 'body': '  ', 'is_deleted': false},
        {'title': 'deleted', 'body': 'gone', 'is_deleted': true},
      ].map(jsonEncode).join('\n');
      final original = wiki.readAsBytesSync();
      final result = await downloader(
        payload,
      ).install(source(DictionaryKind.wiki, payload), wiki.path, (_) {});
      expect(result['added'], 1);
      expect(result['count'], 2);
      expect(result['updated'], 1);
      expect(wiki.readAsBytesSync(), original);
      expect(store.record(DictionaryKind.wiki)!['mergeVersion'], 2);
      final reader = AssetTagWikiRepository(
        () async => store.activePath(DictionaryKind.wiki)!,
      );
      expect((await reader.find('blue_eyes'))!.body, 'Do not overwrite');
      expect(
        (await reader.find('new_tag'))!.body,
        'h4. Heading\n\n[[blue_eyes]]',
      );
      expect(await reader.find('empty'), isNull);
      expect(await reader.find('deleted'), isNull);
      final repeated = await downloader(payload).install(
        source(DictionaryKind.wiki, payload),
        store.activePath(DictionaryKind.wiki)!,
        (_) {},
      );
      expect(repeated['added'], 0);
      expect(repeated['updated'], 0);
      expect(
        await DictionaryDataStore(
          store.root,
        ).resolve(DictionaryKind.wiki, wiki.path),
        store.activePath(DictionaryKind.wiki),
      );
    },
  );

  for (final good in [true, false]) {
    test(
      'Git blob verification ${good ? 'publishes a SHA256 revision' : 'rejects substituted bytes'}',
      () async {
        const payload = 'new_tag,0,20,""\n';
        final bytes = utf8.encode(payload);
        final blob = sha1.convert([
          ...utf8.encode('blob ${bytes.length}\u0000'),
          ...bytes,
        ]).toString();
        final candidate = DictionarySource(
          DictionaryKind.tags,
          'https://fixture.invalid/data',
          '',
          bytes.length,
          '2026-10-01',
          'Fixture',
          gitBlobSha1: good ? blob : '0' * 40,
        );
        final job = downloader(payload);
        if (good) {
          await job.install(candidate, tags.path, (_) {});
          expect(
            store.record(DictionaryKind.tags)!['sourceHash'],
            sha256.convert(bytes).toString(),
          );
          expect(store.record(DictionaryKind.tags)!['sourceBlobSha1'], blob);
        } else {
          await expectLater(
            job.install(candidate, tags.path, (_) {}),
            throwsStateError,
          );
          expect(store.activePath(DictionaryKind.tags), isNull);
        }
      },
    );
  }

  test(
    'duplicate Wiki titles prefer the newest dated text and count each existing article once',
    () async {
      final payload = [
        {
          'title': 'blue_eyes',
          'body': 'middle',
          'is_deleted': false,
          'updated_at': '2026-10-01T00:00:00Z',
        },
        {
          'title': 'BLUE_EYES',
          'body': 'old',
          'is_deleted': false,
          'updated_at': '2025-01-01T00:00:00Z',
        },
        {
          'title': 'blue_eyes',
          'body': 'newest',
          'is_deleted': false,
          'updated_at': '2026-10-17T00:00:00Z',
        },
        {
          'title': 'blue_eyes',
          'body': 'newest',
          'is_deleted': false,
          'updated_at': '2026-10-17T00:00:00Z',
        },
        {
          'title': 'new_tag',
          'body': 'first',
          'is_deleted': false,
          'updated_at': '2026-10-01T00:00:00Z',
        },
        {
          'title': 'new_tag',
          'body': 'last',
          'is_deleted': false,
          'updated_at': '2026-10-17T00:00:00Z',
        },
      ].map(jsonEncode).join('\n');
      final result = await downloader(
        payload,
      ).install(source(DictionaryKind.wiki, payload), wiki.path, (_) {});
      expect(result['added'], 1);
      expect(result['updated'], 1);
      final reader = AssetTagWikiRepository(
        () async => store.activePath(DictionaryKind.wiki)!,
      );
      expect((await reader.find('blue_eyes'))!.body, 'newest');
      expect((await reader.find('new_tag'))!.body, 'last');
    },
  );

  for (final phase in [
    DictionaryPhase.downloading,
    DictionaryPhase.verifying,
    DictionaryPhase.importing,
  ]) {
    test(
      'cancel during ${phase.name} keeps the current database and removes only staging',
      () async {
        const payload = 'new_tag,0,20,""\n';
        final job = downloader(payload);
        await expectLater(
          job.install(source(DictionaryKind.tags, payload), tags.path, (p) {
            if (p.phase == phase) job.cancel();
          }),
          throwsA(anything),
        );
        expect(store.activePath(DictionaryKind.tags), isNull);
        expect(validateDictionary(tags.path, DictionaryKind.tags), 2);
        expect(await store.root.list().toList(), isEmpty);
      },
    );
  }

  test(
    'cancel after worker progress stops an active import without activating its output',
    () async {
      final payload = List.generate(
        25000,
        (i) => 'new_tag_$i,0,20,""\n',
      ).join();
      final job = downloader(payload);
      var sawProgress = false;
      await expectLater(
        job.install(source(DictionaryKind.tags, payload), tags.path, (p) {
          if (p.phase == DictionaryPhase.importing && p.rows >= 1000) {
            sawProgress = true;
            job.cancel();
          }
        }),
        throwsA(anything),
      );
      expect(sawProgress, isTrue);
      expect(store.activePath(DictionaryKind.tags), isNull);
      expect(validateDictionary(tags.path, DictionaryKind.tags), 2);
      expect(await store.root.list().toList(), isEmpty);
    },
  );

  test(
    'publishing finishes atomically even if cancellation arrives at the commit point',
    () async {
      const payload = 'new_tag,0,20,""\n';
      final job = downloader(payload);
      await job.install(source(DictionaryKind.tags, payload), tags.path, (p) {
        if (p.phase == DictionaryPhase.publishing) job.cancel();
      });
      expect(
        validateDictionary(
          store.activePath(DictionaryKind.tags)!,
          DictionaryKind.tags,
        ),
        3,
      );
    },
  );

  test(
    'bad digest, truncated payload and invalid schema never publish a revision',
    () async {
      for (final (download, expected) in [
        ('corrupt', 'new_tag,0,20,""\n'),
        ('new_tag,0,20,XX\n', 'new_tag,0,20,YY\n'),
        ('new_tag,999,20,""\n', 'new_tag,999,20,""\n'),
      ]) {
        await expectLater(
          downloader(
            download,
          ).install(source(DictionaryKind.tags, expected), tags.path, (_) {}),
          throwsA(anything),
        );
        expect(store.activePath(DictionaryKind.tags), isNull);
        expect(validateDictionary(tags.path, DictionaryKind.tags), 2);
      }
    },
  );

  test(
    'invalid latest commit and path injection fall back to last verified revision',
    () async {
      const payload = 'new_tag,0,20,""\n';
      await downloader(
        payload,
      ).install(source(DictionaryKind.tags, payload), tags.path, (_) {});
      final path = store.activePath(DictionaryKind.tags)!;
      File(
        '${store.root.path}/commit-tags-9999999999999999999.json',
      ).writeAsStringSync(
        jsonEncode({
          'kind': 'tags',
          'sha256': '../../outside',
          'count': 999,
          'bytes': 1,
        }),
      );
      final reopened = DictionaryDataStore(store.root);
      expect(await reopened.resolve(DictionaryKind.tags, tags.path), path);
      final pending = File(
        '${store.root.path}/commit-tags-99999999999999999999.pending',
      );
      pending.writeAsStringSync('{}');
      expect(await reopened.resolve(DictionaryKind.tags, tags.path), path);
    },
  );
}
