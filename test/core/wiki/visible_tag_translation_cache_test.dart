import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/wiki/visible_tag_translation_cache.dart';
import 'package:path/path.dart' as p;

void main() {
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
