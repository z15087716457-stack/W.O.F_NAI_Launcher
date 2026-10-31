import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/tag_expansion/tag_semantics_repository.dart';
import 'package:nai_launcher/core/tag_expansion/tag_semantics_store.dart';
import 'package:nai_launcher/core/wiki/visible_tag_translation_cache.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory folder;
  late TagSemanticsStore store;
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('semantic-supplements-');
    store = TagSemanticsStore(
      databasePath: () async => '${folder.path}/supplements.db',
    );
  });
  tearDown(() async {
    await store.close();
    await folder.delete(recursive: true);
  });
  Future<void> save({String summary = '', String hash = ''}) => store.put(
    tag: 'grass',
    coreZh: '草坪',
    synonymsZh: ['草坪', '草'],
    summaryZh: summary,
    wikiHash: hash,
    promptVersion: 7,
    provenance: 'fixture',
  );

  test(
    'supplements use WAL and independent readers survive a write transaction',
    () async {
      await save();
      final path = await store.readyPath();
      final writer = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      final reader = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );
      try {
        expect(
          (await reader.rawQuery('PRAGMA journal_mode')).single.values.single,
          'wal',
        );
        await writer.transaction((txn) async {
          await txn.rawUpdate(
            "UPDATE tag_semantics SET core_zh='uncommitted' WHERE tag='grass'",
          );
          expect((await reader.query('tag_semantics')).single['core_zh'], '草坪');
        });
        expect(
          (await reader.query('tag_semantics')).single['core_zh'],
          'uncommitted',
        );
      } finally {
        await reader.close();
        await writer.close();
      }
    },
  );

  test(
    'fill gaps preserves existing fields and revision ignores attempt-only changes',
    () async {
      await save();
      final path = await store.readyPath();
      Future<int> revision() async {
        final db = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
        );
        try {
          return (await db.query('semantic_state')).single['revision'] as int;
        } finally {
          await db.close();
        }
      }

      expect(await revision(), 1);
      await save();
      expect(await revision(), 1);
      await store.put(
        tag: 'grass',
        coreZh: '不应覆盖',
        synonymsZh: ['不应覆盖'],
        summaryZh: '植物覆盖的地面',
        wikiHash: '',
        promptVersion: 7,
        provenance: 'fixture',
      );
      expect(await revision(), 2);
      final row = (await store.findAll(['grass']))['grass']!;
      expect(row['core_zh'], '草坪');
      expect(row['summary_zh'], '植物覆盖的地面');
    },
  );

  test(
    'cache clearing does not delete durable data; partial overlay reuses bundle',
    () async {
      await save();
      final cache = VisibleTagTranslationCache(
        databasePath: () async => '${folder.path}/translation.db',
      );
      await cache.clear();
      await cache.close();
      final repository = TagSemanticsRepository(
        () async => File('assets/databases/tag_semantics.db').absolute.path,
        supplements: store,
      );
      final profile = await repository.find('grass');
      expect(profile!.coreZh, '草坪');
      expect(profile.summaryZh, isNotEmpty);
      expect(profile.complete, isTrue);
      expect(await store.attempted('grass', '', 7), isTrue);
      expect(await store.attempted('grass', 'new-source', 7), isFalse);
    },
  );

  test(
    'export import roundtrip preserves source hash, missing fields and backups',
    () async {
      final hash = List.filled(64, 'a').join();
      await save(summary: '植物覆盖的地面', hash: hash);
      final exported = await store.exportJson();
      final second = TagSemanticsStore(
        databasePath: () async => '${folder.path}/restored.db',
      );
      try {
        await second.importJson(exported);
        expect((await second.findAll(['grass']))['grass']!['wiki_hash'], hash);
        expect(await second.attempted('grass', hash, 7), isTrue);
        expect(
          (await folder.list().toList()).whereType<File>().any(
            (f) => f.path.contains('.before-import-'),
          ),
          isTrue,
        );
        await second.put(
          tag: 'grass',
          coreZh: '新的本地名称',
          synonymsZh: ['新的本地名称'],
          summaryZh: '',
          wikiHash: hash,
          promptVersion: 7,
          provenance: 'manual',
          replace: true,
        );
        await second.importJson(exported);
        expect(
          (await second.findAll(['grass']))['grass']!['core_zh'],
          '新的本地名称',
        );
        expect(
          (await second.findAll(['grass']))['grass']!['summary_zh'],
          '植物覆盖的地面',
        );
      } finally {
        await second.close();
      }
    },
  );

  test('invalid import is atomic and does not overwrite data', () async {
    await save();
    final before = await store.exportJson();
    final value = jsonDecode(before) as Map<String, dynamic>;
    (value['profiles'] as List).add({
      'tag': 'other',
      'core_zh': 'bad\nvalue',
      'synonyms_zh': [],
      'summary_zh': '',
    });
    await expectLater(
      store.importJson(jsonEncode(value)),
      throwsFormatException,
    );
    expect(await store.exportJson(), before);
  });

  test('a new attempt cannot relabel an old summary as current', () async {
    final first = List.filled(64, 'a').join(),
        second = List.filled(64, 'b').join();
    await save(summary: '旧来源的说明', hash: first);
    await save(hash: second);
    var row = (await store.findAll(['grass']))['grass']!;
    expect(row['wiki_hash'], second);
    expect(row['summary_hash'], first);
    await save(summary: '新来源的说明', hash: second);
    row = (await store.findAll(['grass']))['grass']!;
    expect(row['summary_zh'], '新来源的说明');
    expect(row['summary_hash'], second);
  });
  test('stale generated summary falls back to source data', () async {
    await save(summary: '过时生成说明');
    final repository = TagSemanticsRepository(
      () async => File('assets/databases/tag_semantics.db').absolute.path,
      supplements: store,
      currentWikiHash: (_) async => 'different',
    );
    expect((await repository.find('grass'))!.summaryZh, isNot('过时生成说明'));
    expect((await repository.find('grass'))!.coreZh, '草坪');
  });
  test(
    'Chinese name search includes saved supplements and treats SQL syntax as data',
    () async {
      await save();
      final repository = TagSemanticsRepository(
        () async => File('assets/databases/tag_semantics.db').absolute.path,
        supplements: store,
      );
      expect(await repository.searchNames('草坪'), contains('grass'));
      expect(await repository.searchNames("草坪' OR 1=1 --"), isEmpty);
    },
  );
}
