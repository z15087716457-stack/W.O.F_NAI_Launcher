import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/wiki/visible_tag_translation_cache.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test(
    'the version-one sidecar upgrades without losing an existing article',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'wiki_cache_upgrade_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = p.join(directory.path, 'cache.db');
      final legacy = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) => db.execute(
            'CREATE TABLE tag_translations(tag TEXT NOT NULL,route TEXT NOT NULL,prompt_version INTEGER NOT NULL,wiki_hash TEXT NOT NULL,name_zh TEXT NOT NULL,wiki_zh TEXT,updated_at INTEGER NOT NULL,PRIMARY KEY(tag,route,prompt_version))',
          ),
        ),
      );
      await legacy.insert('tag_translations', {
        'tag': 'medium_hair',
        'route': 'model',
        'prompt_version': 3,
        'wiki_hash': 'source',
        'name_zh': '中发',
        'wiki_zh': '现有译文',
        'updated_at': 0,
      });
      await legacy.close();
      final cache = VisibleTagTranslationCache(databasePath: () async => path);
      addTearDown(cache.close);
      final restored = await cache.get(
        tag: 'medium_hair',
        route: 'model',
        promptVersion: 4,
        wikiHash: 'source',
        allowEarlierVersion: true,
      );
      expect(restored?.wikiZh, '现有译文');
      expect(restored?.wikiOriginal, isNull);
      await cache.put(
        tag: 'medium_hair',
        route: 'model',
        promptVersion: 4,
        wikiHash: 'source',
        nameZh: '中发',
        wikiZh: '示例\n- 中发',
        wikiOriginal: 'Examples\n- Medium hair',
      );
      expect(
        (await cache.get(
          tag: 'medium_hair',
          route: 'model',
          promptVersion: 4,
          wikiHash: 'source',
        ))?.wikiOriginal,
        'Examples\n- Medium hair',
      );
    },
  );
  test(
    'persists names and only reuses wiki for the same source hash',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'visible_wiki_cache_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = p.join(directory.path, 'translations.db');
      final writer = VisibleTagTranslationCache(databasePath: () async => path);
      await writer.put(
        tag: 'blue_eyes',
        route: 'model-a',
        promptVersion: 1,
        wikiHash: 'hash-a',
        nameZh: '蓝眼',
        wikiZh: '蓝色眼睛。',
        wikiOriginal: 'Blue eyes.\n\n- [Blue eyes](wof-tag:blue_eyes)',
      );
      await writer.close();

      final reader = VisibleTagTranslationCache(databasePath: () async => path);
      expect(
        (await reader.get(
          tag: 'blue_eyes',
          route: 'model-a',
          promptVersion: 1,
          wikiHash: 'hash-a',
        ))?.wikiZh,
        '蓝色眼睛。',
      );
      final changedWiki = await reader.get(
        tag: 'blue_eyes',
        route: 'model-a',
        promptVersion: 1,
        wikiHash: 'hash-b',
      );
      expect(changedWiki?.nameZh, '蓝眼');
      expect(changedWiki?.wikiZh, isNull);
      expect(changedWiki?.wikiOriginal, isNull);
      expect(
        (await reader.get(
          tag: 'blue_eyes',
          route: 'model-a',
          promptVersion: 1,
          wikiHash: 'hash-a',
        ))?.wikiOriginal,
        'Blue eyes.\n\n- [Blue eyes](wof-tag:blue_eyes)',
      );
      expect(
        await reader.get(
          tag: 'blue_eyes',
          route: 'model-b',
          promptVersion: 1,
          wikiHash: 'hash-a',
        ),
        isNull,
      );
      await reader.close();
    },
  );
  test(
    'legacy articles remain readable until an explicit retranslation upgrades them',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'wiki_legacy_cache_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final cache = VisibleTagTranslationCache(
        databasePath: () async => p.join(directory.path, 'cache.db'),
      );
      addTearDown(cache.close);
      await cache.put(
        tag: 'hat',
        route: 'route',
        promptVersion: 2,
        wikiHash: 'same',
        nameZh: '帽子',
        wikiZh: '帽子以及 visor。',
      );
      expect(
        await cache.get(
          tag: 'hat',
          route: 'route',
          promptVersion: 3,
          wikiHash: 'same',
        ),
        isNull,
      );
      expect(
        (await cache.get(
          tag: 'hat',
          route: 'route',
          promptVersion: 3,
          wikiHash: 'same',
          allowEarlierVersion: true,
        ))?.wikiZh,
        '帽子以及 visor。',
      );
      expect(
        (await cache.get(
          tag: 'hat',
          route: 'route',
          promptVersion: 3,
          wikiHash: 'changed',
          allowEarlierVersion: true,
        ))?.wikiZh,
        isNull,
      );
      expect(
        await cache.get(
          tag: 'hat',
          route: 'different',
          promptVersion: 3,
          wikiHash: 'same',
          allowEarlierVersion: true,
        ),
        isNull,
      );
      await cache.put(
        tag: 'hat',
        route: 'route',
        promptVersion: 3,
        wikiHash: 'same',
        nameZh: '帽子',
        wikiZh: '[帽子](wof-tag:hat)',
      );
      expect(
        (await cache.get(
          tag: 'hat',
          route: 'route',
          promptVersion: 3,
          wikiHash: 'same',
          allowEarlierVersion: true,
        ))?.wikiZh,
        '[帽子](wof-tag:hat)',
      );
      expect(
        (await cache.get(
          tag: 'hat',
          route: 'route',
          promptVersion: 2,
          wikiHash: 'same',
        ))?.wikiZh,
        '帽子以及 visor。',
      );
    },
  );
}
