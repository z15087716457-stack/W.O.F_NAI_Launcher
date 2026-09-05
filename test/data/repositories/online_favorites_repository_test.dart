import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/cache/danbooru_image_cache_manager.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_item.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_source.dart';
import 'package:nai_launcher/data/repositories/online_favorites_repository.dart';

void main() {
  group('GalleryItem snapshot roundtrip', () {
    test('AItag 风格条目快照序列化往返保真', () {
      const item = GalleryItem(
        id: 12345,
        sourceId: GallerySourceId.aiTag,
        title: 'sample work',
        author: 'some artist',
        description: 'desc',
        aiType: '1',
        createdAt: '2026-08-24',
        uploaderId: 7788,
        score: 99,
        tags: ['1girl', 'solo'],
        mediaCount: 3,
        viewCount: 1234,
        favoriteCount: 56,
        rank: 7,
        cover: GalleryMedia(
          id: 'file_p0',
          previewUrl: 'https://img.example/p/7788/p0.webp',
          displayUrl: 'https://img.example/p/7788/p0.webp',
          downloadUrl: 'https://img.example/p/7788/p0.webp',
          width: 1024,
          height: 1536,
          extension: 'webp',
        ),
      );

      final restored = GalleryItem.fromSnapshotJson(
        jsonDecode(jsonEncode(item.toSnapshotJson())) as Map<String, dynamic>,
      );

      expect(restored.id, item.id);
      expect(restored.sourceId, GallerySourceId.aiTag);
      expect(restored.title, item.title);
      expect(restored.author, item.author);
      expect(restored.uploaderId, item.uploaderId);
      expect(restored.tags, item.tags);
      expect(restored.mediaCount, 3);
      expect(restored.favoriteCount, 56);
      expect(restored.rank, 7);
      expect(restored.cover.previewUrl, item.cover.previewUrl);
      expect(restored.cover.width, 1024);
      expect(restored.cover.height, 1536);
    });
  });

  group('OnlineFavoritesRepository', () {
    late OnlineFavoritesRepository repo;
    late String dbPath;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      final dir = Directory.systemTemp.createTempSync('online_fav_test_');
      dbPath = '${dir.path}/fav.db';
      repo = OnlineFavoritesRepository.forTesting(dbPath);
      await repo.initialize();
    });

    tearDown(() async {
      await repo.close();
      final file = File(dbPath);
      if (await file.exists()) await file.delete();
    });

    GalleryItem makeItem(
      int id, {
      int uploader = 42,
      String author = 'author',
    }) {
      return GalleryItem(
        id: id,
        sourceId: GallerySourceId.aiTag,
        title: 'work $id',
        author: author,
        uploaderId: uploader,
        cover: const GalleryMedia(
          id: 'c',
          previewUrl: 'https://img.example/p/42/x.webp',
          displayUrl: 'https://img.example/p/42/x.webp',
          downloadUrl: 'https://img.example/p/42/x.webp',
          width: 800,
          height: 1200,
        ),
      );
    }

    test('还原 AI TAG 收藏注册全部存量封面 host 且不依赖当前配置', () async {
      const urls = [
        'https://legacy-preview-favorite.example/image.webp',
        'https://legacy-display-favorite.example/image.webp',
        'http://legacy-download-favorite.example/image.webp',
      ];
      await repo.addFavorite(
        makeItem(90).copyWith(
          cover: GalleryMedia(
            id: 'legacy',
            previewUrl: urls[0],
            displayUrl: urls[1],
            downloadUrl: urls[2],
          ),
        ),
      );
      await repo.close();
      repo = OnlineFavoritesRepository.forTesting(dbPath);
      registerAiTagImageHost('https://current-favorite-assets.example/');
      for (final url in urls) {
        expect(onlineGalleryImageHeadersForUrl(url), isEmpty);
      }
      final entries = await repo.listFavorites(GallerySourceId.aiTag);
      expect(entries.single.item.sourceId, GallerySourceId.aiTag);
      for (final url in urls) {
        expect(
          onlineGalleryImageHeadersForUrl(url)['Referer'],
          'https://aitag.win/',
        );
        expect(onlineGalleryImageCacheKeyForUrl(url), isNull);
      }
    });

    test('非 AI TAG 或来源不一致的快照不会注册 AI TAG host', () async {
      for (final (id, source) in [
        (91, GallerySourceId.danbooru),
        (92, GallerySourceId.aiTag),
      ]) {
        final url = 'https://untrusted-favorite-$id.example/image.webp';
        await repo.addFavorite(
          makeItem(id).copyWith(
            sourceId: source,
            cover: GalleryMedia(id: 'other', previewUrl: url),
          ),
        );
      }
      await repo.close();
      final db = await databaseFactoryFfi.openDatabase(dbPath);
      await db.update(
        'online_favorites',
        {
          'snapshot': jsonEncode({
            ...makeItem(92).toSnapshotJson(),
            'source': 'unknown-source',
            'cover': {
              'id': 'mismatch',
              'preview_url': 'https://untrusted-favorite-92.example/image.webp',
            },
          }),
        },
        where: 'work_id = ?',
        whereArgs: [92],
      );
      await db.close();
      repo = OnlineFavoritesRepository.forTesting(dbPath);
      await repo.listFavorites(GallerySourceId.danbooru);
      await repo.listFavorites(GallerySourceId.aiTag);
      for (final id in [91, 92]) {
        expect(
          onlineGalleryImageHeadersForUrl(
            'https://untrusted-favorite-$id.example/image.webp',
          ),
          isEmpty,
        );
      }
    });

    test('收藏快照中的非法资产 scheme 不注册 host', () async {
      await repo.addFavorite(
        makeItem(93).copyWith(
          cover: const GalleryMedia(
            id: 'invalid',
            previewUrl: 'ftp://invalid-favorite.example/a.png',
            displayUrl: 'https:///a.png',
            downloadUrl: '//missing-scheme-favorite.example/a.png',
          ),
        ),
      );
      await repo.listFavorites(GallerySourceId.aiTag);
      expect(
        onlineGalleryImageHeadersForUrl(
          'https://invalid-favorite.example/a.png',
        ),
        isEmpty,
      );
      expect(
        onlineGalleryImageHeadersForUrl(
          'https://missing-scheme-favorite.example/a.png',
        ),
        isEmpty,
      );
    });

    test('收藏/取消/已收藏查询，根收藏与子集过滤', () async {
      await repo.addFavorite(makeItem(1));
      await repo.addFavorite(makeItem(2));
      final setId = await repo.createCollection('子集A');
      await repo.addFavorite(makeItem(3), collectionId: setId);

      expect(await repo.isFavorite(GallerySourceId.aiTag, 1), isTrue);
      expect(await repo.favoritedWorkIds(GallerySourceId.aiTag), {1, 2, 3});

      final root = await repo.listFavorites(GallerySourceId.aiTag);
      expect(root.map((e) => e.item.id).toSet(), {1, 2});

      final inSet = await repo.listFavorites(
        GallerySourceId.aiTag,
        collectionId: setId,
      );
      expect(inSet.single.item.id, 3);

      final all = await repo.listFavorites(
        GallerySourceId.aiTag,
        includeAll: true,
      );
      expect(all, hasLength(3));

      await repo.removeFavorite(GallerySourceId.aiTag, 2);
      expect(await repo.isFavorite(GallerySourceId.aiTag, 2), isFalse);
    });

    test('重复收藏替换归属子集（移动语义，不重复计数）', () async {
      final setId = await repo.createCollection('子集B');
      await repo.addFavorite(makeItem(10));
      await repo.addFavorite(makeItem(10), collectionId: setId);

      final all = await repo.listFavorites(
        GallerySourceId.aiTag,
        includeAll: true,
      );
      expect(all, hasLength(1));
      expect(all.single.collectionId, setId);

      final collections = await repo.listCollectionsWithCounts(
        GallerySourceId.aiTag,
      );
      expect(collections.single.itemCount, 1);
    });

    test('删除子集成员回落根收藏', () async {
      final setId = await repo.createCollection('待删');
      await repo.addFavorite(makeItem(20), collectionId: setId);

      await repo.deleteCollection(setId);
      final root = await repo.listFavorites(GallerySourceId.aiTag);
      expect(root.single.item.id, 20);
      expect(root.single.collectionId, isNull);
    });

    test('作者聚合计数与作者过滤', () async {
      await repo.addFavorite(makeItem(30, uploader: 7, author: 'alice'));
      await repo.addFavorite(makeItem(31, uploader: 7, author: 'alice'));
      await repo.addFavorite(makeItem(32, uploader: 8, author: 'bob'));

      final counts = await repo.authorCounts(GallerySourceId.aiTag);
      expect(counts[7], ('alice', 2));
      expect(counts[8], ('bob', 1));

      final aliceWorks = await repo.listFavorites(
        GallerySourceId.aiTag,
        includeAll: true,
        authorId: 7,
      );
      expect(aliceWorks, hasLength(2));
    });

    test('作者收藏 toggle 与列表', () async {
      expect(
        await repo.toggleAuthor(GallerySourceId.aiTag, 7, 'alice'),
        isTrue,
      );
      expect(await repo.isAuthorFavorite(GallerySourceId.aiTag, 7), isTrue);
      final authors = await repo.listAuthors(GallerySourceId.aiTag);
      expect(authors.single.authorName, 'alice');
      expect(
        await repo.toggleAuthor(GallerySourceId.aiTag, 7, 'alice'),
        isFalse,
      );
      expect(await repo.listAuthors(GallerySourceId.aiTag), isEmpty);
    });

    test('显式删除作者仅删除一次且不会重新加入', () async {
      expect(
        await repo.toggleAuthor(GallerySourceId.aiTag, 7, 'alice'),
        isTrue,
      );

      expect(await repo.removeAuthor(GallerySourceId.aiTag, 7), isTrue);
      expect(await repo.removeAuthor(GallerySourceId.aiTag, 7), isFalse);
      expect(await repo.isAuthorFavorite(GallerySourceId.aiTag, 7), isFalse);
      expect(await repo.listAuthors(GallerySourceId.aiTag), isEmpty);
    });
  });
}
