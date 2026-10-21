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
      expect(restored?.definition, isNull);
      expect(await cache.chineseTerms(['medium_hair']), isEmpty);
      await cache.put(
        tag: 'medium_hair',
        route: 'model',
        promptVersion: 4,
        wikiHash: 'source',
        nameZh: '中发',
        wikiZh: '示例\n- 中发',
        wikiOriginal: 'Examples\n- Medium hair',
        definition: '长度介于短发和长发之间的头发。',
      );
      expect(
        (await cache.chineseTerms(['medium_hair']))['medium_hair']?.definition,
        '长度介于短发和长发之间的头发。',
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
      await cache.close();
      final previousReader = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(version: 2),
      );
      expect(
        (await previousReader.query(
          'tag_translations',
          columns: ['name_zh'],
          where: 'tag = ? AND prompt_version = ?',
          whereArgs: ['medium_hair', 4],
        )).single['name_zh'],
        '中发',
      );
      await previousReader.close();
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
        definition: '虹膜呈蓝色的眼睛。',
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
      expect(changedWiki?.definition, isNull);
      expect(
        (await reader.chineseTerms(['blue_eyes']))['blue_eyes']?.definition,
        '虹膜呈蓝色的眼睛。',
      );
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
    'terminology lookup excludes non-Chinese names and keeps definition language separate',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'tag_terms_languages_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final cache = VisibleTagTranslationCache(
        databasePath: () async => p.join(directory.path, 'cache.db'),
      );
      addTearDown(cache.close);
      await cache.put(
        tag: 'sun',
        route: 'ja',
        promptVersion: 6,
        wikiHash: 'same',
        nameZh: '太陽',
        definition: '恒星。',
        nameLanguage: 'ja',
        definitionLanguage: 'ja',
      );
      expect(await cache.chineseTerms(['sun']), isEmpty);
      await cache.put(
        tag: 'sun',
        route: 'zh',
        promptVersion: 6,
        wikiHash: 'same',
        nameZh: '太阳',
        definition: '恒星。',
        nameLanguage: 'zh',
        definitionLanguage: 'ja',
      );
      final term = (await cache.chineseTerms(['sun']))['sun']!;
      expect(term.nameZh, '太阳');
      expect(term.wikiHash, 'same');
      expect(term.definitionLanguage, 'ja');
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

  test(
    'wikiFromAnyRoute: same body and language across routes, newest first',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'wiki_cache_any_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final cache = VisibleTagTranslationCache(
        databasePath: () async => p.join(directory.path, 'cache.db'),
      );
      addTearDown(cache.close);
      Future<void> put(String route, String hash, String zh, String lang) =>
          cache.put(
            tag: 'blue_eyes',
            route: route,
            promptVersion: 7,
            wikiHash: hash,
            nameZh: '蓝眼',
            wikiZh: zh,
            nameLanguage: lang,
            definitionLanguage: lang,
          );
      await put('a', 'h1', '旧', 'zh');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await put('b', 'h1', '新', 'zh');
      await put('c', 'h2', '别的正文', 'zh');
      await put('d', 'h1', '日本語', 'ja');
      final hit = await cache.wikiFromAnyRoute(
        tag: 'blue_eyes',
        wikiHash: 'h1',
        language: 'zh',
        maxPromptVersion: 7,
      );
      expect(hit?.wikiZh, '新');
      expect(
        await cache.wikiFromAnyRoute(
          tag: 'blue_eyes',
          wikiHash: 'h3',
          language: 'zh',
          maxPromptVersion: 7,
        ),
        isNull,
      );
      expect(
        (await cache.wikiFromAnyRoute(
          tag: 'blue_eyes',
          wikiHash: 'h1',
          language: 'ja',
          maxPromptVersion: 7,
        ))?.wikiZh,
        '日本語',
      );
    },
  );
}
