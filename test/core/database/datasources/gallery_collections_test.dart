import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/database/base_data_source.dart';
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
      expect(
        tables.map((t) => t['name']),
        containsAll(['gallery_collections', 'gallery_collection_items']),
      );
    });

    test(
      'create/list with counts, ordered by sort_order then created_at',
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
      },
    );

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

      expect(await dataSource.removeImagesFromAllCollections([img1, img2]), 3);
      expect(await dataSource.getCollectionImageIds(idA), isEmpty);
      expect(await dataSource.getCollectionImageIds(idB), isEmpty);
      // 只清成员关系，不碰收藏表
      expect(await dataSource.getCollectionIdsForImage(img2), isEmpty);
    });

    test(
      'migration backfills existing collection members into favorites',
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
      },
    );
  });

  /// 收藏集层级（文件夹无限嵌套）：
  /// parent_id 归属 / move 防环 / 非空文件夹删除拒绝 / 递归并集计数与成员
  group('Collection hierarchy tests', () {
    late GalleryDataSource dataSource;
    late String testDbPath;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);

      final tempDir = Directory.systemTemp.createTempSync('gallery_col_h_');
      testDbPath = '${tempDir.path}/collections.db';
    });

    tearDownAll(() async {
      await ConnectionPoolHolder.dispose();
      try {
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

    test('createCollection persists parent and folder kind', () async {
      final folderId = await dataSource.createCollection(
        'F',
        isFolder: true,
      );
      final childId = await dataSource.createCollection('C', parentId: folderId);
      final rootId = await dataSource.createCollection('R');

      final list = await dataSource.listCollectionsWithCounts();
      final folder = list.firstWhere((c) => c.id == folderId);
      final child = list.firstWhere((c) => c.id == childId);
      final root = list.firstWhere((c) => c.id == rootId);

      expect(folder.isFolder, isTrue);
      expect(folder.parentId, isNull);
      expect(child.isFolder, isFalse);
      expect(child.parentId, folderId);
      expect(root.parentId, isNull);
      expect(root.isFolder, isFalse);
    });

    test('createCollection rejects non-folder parent', () async {
      final plainId = await dataSource.createCollection('plain');
      // execute 包装会把 ArgumentError 转成 DataSourceOperationException
      await expectLater(
        dataSource.createCollection('bad', parentId: plainId),
        throwsA(isA<DataSourceOperationException>()),
      );
    });

    test('moveCollection moves node and appends to target order', () async {
      final folder = await dataSource.createCollection('F', isFolder: true);
      final sub1 = await dataSource.createCollection('S1', parentId: folder);
      final sub2 = await dataSource.createCollection('S2');
      final other = await dataSource.createCollection('X');

      // S2 移入文件夹：排在 S1 后
      expect(await dataSource.moveCollection(sub2, folder), isTrue);
      var list = await dataSource.listCollectionsWithCounts();
      final s2 = list.firstWhere((c) => c.id == sub2);
      expect(s2.parentId, folder);

      // 同父重排只动 S1/S2，不影响其他根级条目归属
      expect(
        await dataSource.reorderCollections([sub2, sub1], parentId: folder),
        isTrue,
      );
      list = await dataSource.listCollectionsWithCounts();
      expect(
        list.firstWhere((c) => c.id == sub1).parentId,
        folder,
      );
      expect(list.firstWhere((c) => c.id == other).parentId, isNull);

      // 移回根级
      expect(await dataSource.moveCollection(sub1, null), isTrue);
      list = await dataSource.listCollectionsWithCounts();
      expect(list.firstWhere((c) => c.id == sub1).parentId, isNull);
    });

    test('moveCollection prevents cycles and self-move', () async {
      final folderA = await dataSource.createCollection('A', isFolder: true);
      final folderB = await dataSource.createCollection(
        'B',
        parentId: folderA,
        isFolder: true,
      );

      // B 移到自身下方 → 拒绝
      expect(await dataSource.moveCollection(folderA, folderA), isFalse);
      // A 移到自己的子孙 B 下方 → 成环，拒绝
      expect(await dataSource.moveCollection(folderA, folderB), isFalse);
      // A 的祖先关系保持不变
      final list = await dataSource.listCollectionsWithCounts();
      expect(list.firstWhere((c) => c.id == folderA).parentId, isNull);
      expect(list.firstWhere((c) => c.id == folderB).parentId, folderA);
    });

    test('moveCollection rejects non-folder target', () async {
      final plain = await dataSource.createCollection('P');
      final node = await dataSource.createCollection('N');
      expect(await dataSource.moveCollection(node, plain), isFalse);
      expect(await dataSource.moveCollection(node, 'missing-id'), isFalse);
    });

    test('deleteCollection rejects non-empty folder', () async {
      final folder = await dataSource.createCollection('F', isFolder: true);
      await dataSource.createCollection('C', parentId: folder);

      expect(await dataSource.hasChildCollections(folder), isTrue);
      expect(await dataSource.deleteCollection(folder), isFalse);

      // 清空后可删
      final child = (await dataSource.listCollectionsWithCounts())
          .firstWhere((c) => c.parentId == folder)
          .id;
      expect(await dataSource.deleteCollection(child), isTrue);
      expect(await dataSource.hasChildCollections(folder), isFalse);
      expect(await dataSource.deleteCollection(folder), isTrue);
    });

    test('folder count is recursive union dedup across sub-collections', () async {
      final folder = await dataSource.createCollection('F', isFolder: true);
      final subFolder = await dataSource.createCollection(
        'SF',
        parentId: folder,
        isFolder: true,
      );
      final c1 = await dataSource.createCollection('C1', parentId: folder);
      final c2 = await dataSource.createCollection('C2', parentId: subFolder);
      final c3 = await dataSource.createCollection('C3'); // 根级，不参与

      final img1 = await addImage('/col/u1.png');
      final img2 = await addImage('/col/u2.png');
      final img3 = await addImage('/col/u3.png');
      await dataSource.addImageToCollection(c1, img1);
      await dataSource.addImageToCollection(c1, img2);
      // img1 同时在深层子集：并集去重后 folder 仍计 3 而非 4
      await dataSource.addImageToCollection(c2, img1);
      await dataSource.addImageToCollection(c2, img3);
      await dataSource.addImageToCollection(c3, img1);

      final list = await dataSource.listCollectionsWithCounts();
      expect(list.firstWhere((c) => c.id == folder).imageCount, 3);
      expect(list.firstWhere((c) => c.id == subFolder).imageCount, 2);
      expect(list.firstWhere((c) => c.id == c1).imageCount, 2);
      expect(list.firstWhere((c) => c.id == c3).imageCount, 1);
    });

    test('getCollectionImageIds returns folder recursive union dedup', () async {
      final folder = await dataSource.createCollection('F', isFolder: true);
      final sub = await dataSource.createCollection('S', parentId: folder);
      final img1 = await addImage('/col/g1.png');
      final img2 = await addImage('/col/g2.png');

      await dataSource.addImageToCollection(sub, img1);
      await dataSource.addImageToCollection(sub, img2);

      final union = await dataSource.getCollectionImageIds(folder);
      expect(union.toSet(), {img1, img2});
      expect(union.length, 2); // 去重：不因多层重复计入

      // img1 同时出现在两个子集时仍只出现一次
      final sub2 = await dataSource.createCollection('S2', parentId: folder);
      await dataSource.addImageToCollection(sub2, img1);
      expect((await dataSource.getCollectionImageIds(folder)).length, 2);
    });

    test('hierarchy migration backfills columns for legacy rows', () async {
      final legacyId = await dataSource.createCollection('legacy');

      // 模拟旧库：按旧 schema（无 parent_id/is_folder）重建 collections 表
      await dataSource.execute('test_downgrade', (db) async {
        await db.execute(
          'DROP TABLE IF EXISTS gallery_collection_items_legacy_tmp',
        );
        final items = await db.rawQuery(
          'SELECT collection_id, image_id, added_at '
          'FROM gallery_collection_items',
        );
        await db.execute('DROP TABLE gallery_collection_items');
        await db.execute('DROP TABLE gallery_collections');
        await db.execute('''
          CREATE TABLE gallery_collections (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE gallery_collection_items (
            collection_id TEXT NOT NULL,
            image_id INTEGER NOT NULL,
            added_at INTEGER NOT NULL,
            PRIMARY KEY (collection_id, image_id)
          )
        ''');
        final batch = db.batch();
        batch.insert('gallery_collections', {
          'id': legacyId,
          'name': 'legacy',
          'sort_order': 0,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
        for (final row in items) {
          batch.insert('gallery_collection_items', row);
        }
        await batch.commit(noResult: true);
      });

      // 重新初始化：迁移应幂等补列，旧行留在收藏根级
      await dataSource.dispose();
      await dataSource.initialize();

      final list = await dataSource.listCollectionsWithCounts();
      final legacy = list.singleWhere((c) => c.id == legacyId);
      expect(legacy.parentId, isNull);
      expect(legacy.isFolder, isFalse);
    });
  });
}
