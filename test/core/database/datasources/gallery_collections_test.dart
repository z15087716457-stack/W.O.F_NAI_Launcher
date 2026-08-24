import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';

/// 收藏集（collections）数据访问单元测试：
/// CRUD / 成员关系 / 计数 / 级联删除 / 排序持久化 / 反查
void main() {
  group('Gallery Collections Tests', () {
    late GalleryDataSource dataSource;
    late String testDbPath;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);

      final tempDir = Directory.systemTemp.createTempSync('gallery_col_');
      testDbPath = '${tempDir.path}/collections.db';
    });

    tearDownAll(() async {
      await ConnectionPoolHolder.dispose();
      try {
        final dbFile = File(testDbPath);
        if (await dbFile.exists()) await dbFile.delete();
        final tempDir = Directory(testDbPath).parent;
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    setUp(() async {
      if (ConnectionPoolHolder.isInitialized) {
        await ConnectionPoolHolder.dispose();
      }
      final dbFile = File(testDbPath);
      if (await dbFile.exists()) await dbFile.delete();

      await ConnectionPoolHolder.initialize(
        dbPath: testDbPath,
        maxConnections: 2,
      );
      dataSource = GalleryDataSource();
      await dataSource.initialize();
    });

    tearDown(() async {
      await dataSource.dispose();
      await ConnectionPoolHolder.dispose();
      final dbFile = File(testDbPath);
      if (await dbFile.exists()) await dbFile.delete();
    });

    final now = DateTime.now();

    Future<int> addImage(String path) {
      return dataSource.upsertImage(
        filePath: path,
        fileName: path.split('/').last,
        fileSize: 1024,
        createdAt: now,
        modifiedAt: now,
      );
    }

    test('collections tables exist after initialization', () async {
      final tables = await dataSource.execute(
        'test_tables',
        (db) => db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' "
          "AND name IN ('gallery_collections', 'gallery_collection_items')",
        ),
      );
      expect(tables.map((t) => t['name']), containsAll([
        'gallery_collections',
        'gallery_collection_items',
      ]));
    });

    test('create/list with counts, ordered by sort_order then created_at',
        () async {
      final idA = await dataSource.createCollection('A');
      final idB = await dataSource.createCollection('B');
      await dataSource.createCollection('C');

      // 成员：A 两张，B 一张
      final img1 = await addImage('/col/a1.png');
      final img2 = await addImage('/col/a2.png');
      final img3 = await addImage('/col/b1.png');
      await dataSource.addImageToCollection(idA, img1);
      await dataSource.addImageToCollection(idA, img2);
      await dataSource.addImageToCollection(idB, img3);

      final list = await dataSource.listCollectionsWithCounts();
      expect(list.map((c) => c.name).toList(), ['A', 'B', 'C']);
      expect(list[0].imageCount, 2);
      expect(list[1].imageCount, 1);
      expect(list[2].imageCount, 0);
      expect(list[0].id, idA);
    });

    test('rename updates name', () async {
      final id = await dataSource.createCollection('old');
      expect(await dataSource.renameCollection(id, 'new'), isTrue);
      final list = await dataSource.listCollectionsWithCounts();
      expect(list.single.name, 'new');
    });

    test('add/remove membership is idempotent and reversible', () async {
      final id = await dataSource.createCollection('M');
      final img = await addImage('/col/m1.png');

      expect(await dataSource.addImageToCollection(id, img), isTrue);
      // 重复添加幂等
      expect(await dataSource.addImageToCollection(id, img), isFalse);

      expect(await dataSource.getCollectionImageIds(id), [img]);
      expect(await dataSource.getCollectionIdsForImage(img), {id});

      // 移除
      expect(await dataSource.removeImageFromCollection(id, img), isTrue);
      // 再移除（不存在）返回 false
      expect(await dataSource.removeImageFromCollection(id, img), isFalse);
      expect(await dataSource.getCollectionImageIds(id), isEmpty);
      expect(await dataSource.getCollectionIdsForImage(img), isEmpty);
    });

    test('deleteCollection cascades items without touching images', () async {
      final id = await dataSource.createCollection('D');
      final img = await addImage('/col/d1.png');
      await dataSource.addImageToCollection(id, img);

      expect(await dataSource.deleteCollection(id), isTrue);

      final list = await dataSource.listCollectionsWithCounts();
      expect(list, isEmpty);
      // 图片仍在
      expect(await dataSource.getImageById(img), isNotNull);
      // 反查空
      expect(await dataSource.getCollectionIdsForImage(img), isEmpty);
    });

    test('reorderCollections persists sort order across re-reads', () async {
      final idA = await dataSource.createCollection('A');
      final idB = await dataSource.createCollection('B');
      final idC = await dataSource.createCollection('C');

      expect(await dataSource.reorderCollections([idC, idA, idB]), isTrue);

      final list = await dataSource.listCollectionsWithCounts();
      expect(list.map((c) => c.id).toList(), [idC, idA, idB]);
    });

    test('counts exclude soft-deleted images', () async {
      final id = await dataSource.createCollection('S');
      final img1 = await addImage('/col/s1.png');
      final img2 = await addImage('/col/s2.png');
      await dataSource.addImageToCollection(id, img1);
      await dataSource.addImageToCollection(id, img2);

      // 软删一张
      await dataSource.execute(
        'test_soft_delete',
        (db) => db.update(
          'gallery_images',
          {'is_deleted': 1},
          where: 'id = ?',
          whereArgs: [img1],
        ),
      );

      final list = await dataSource.listCollectionsWithCounts();
      expect(list.single.imageCount, 1);
    });

    // 收藏根-子集模型：根（gallery_favorites）= 总收藏，子集 = 根的细分
    test('addFavorite is idempotent and removeFavorites batches', () async {
      final img1 = await addImage('/col/f1.png');
      final img2 = await addImage('/col/f2.png');

      expect(await dataSource.addFavorite(img1), isTrue);
      expect(await dataSource.addFavorite(img1), isFalse); // 幂等
      expect(await dataSource.isFavorite(img1), isTrue);
      expect(await dataSource.getFavoriteCount(), 1);

      // 批量取消：img1 在收藏表、img2 不在 → 返回实际取消数 1
      expect(await dataSource.removeFavorites([img1, img2]), 1);
      expect(await dataSource.isFavorite(img1), isFalse);
      expect(await dataSource.getFavoriteCount(), 0);
    });

    test('removeImagesFromAllCollections clears every membership', () async {
      final idA = await dataSource.createCollection('A');
      final idB = await dataSource.createCollection('B');
      final img1 = await addImage('/col/m1.png');
      final img2 = await addImage('/col/m2.png');
      await dataSource.addImageToCollection(idA, img1);
      await dataSource.addImageToCollection(idA, img2);
      await dataSource.addImageToCollection(idB, img2);

      expect(
        await dataSource.removeImagesFromAllCollections([img1, img2]),
        3,
      );
      expect(await dataSource.getCollectionImageIds(idA), isEmpty);
      expect(await dataSource.getCollectionImageIds(idB), isEmpty);
      // 只清成员关系，不碰收藏表
      expect(await dataSource.getCollectionIdsForImage(img2), isEmpty);
    });

    test('migration backfills existing collection members into favorites',
        () async {
      final id = await dataSource.createCollection('M');
      final img = await addImage('/col/mig1.png');
      await dataSource.addImageToCollection(id, img);
      expect(await dataSource.isFavorite(img), isFalse); // 旧数据：未入收藏表

      // 清除迁移完成标记并重置数据源状态，模拟旧库下次启动重跑迁移
      await dataSource.execute(
        'test_clear_migration_flag',
        (db) => db.delete(
          'gallery_meta',
          where: "key = 'favorites_collection_members_v1'",
        ),
      );
      await dataSource.dispose();
      await dataSource.initialize();

      expect(await dataSource.isFavorite(img), isTrue);
      expect(await dataSource.getFavoriteCount(), 1);

      // 幂等：标记已落，再次初始化不重复补写
      await dataSource.dispose();
      await dataSource.initialize();
      expect(await dataSource.getFavoriteCount(), 1);
    });
  });
}
