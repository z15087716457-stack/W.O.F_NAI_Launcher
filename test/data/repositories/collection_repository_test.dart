import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/repositories/collection_repository.dart';

/// 收藏集仓库单元测试：根-子集模型（入子集即入根）
void main() {
  group('CollectionRepository root model', () {
    late GalleryDataSource dataSource;
    late String testDbPath;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);

      final tempDir = Directory.systemTemp.createTempSync('collection_repo_');
      testDbPath = '${tempDir.path}/repo.db';
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

    test('addImagesToCollection auto-adds images to favorites root', () async {
      final repo = CollectionRepository.instance;
      const imagePath = '/col/auto_root.png';
      final imageId = await dataSource.upsertImage(
        filePath: imagePath,
        fileName: 'auto_root.png',
        fileSize: 1024,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      final collection = await repo.createCollection('auto');
      final collectionId = collection.id;

      // 入子集
      final result = await repo.addImagesToCollection(collectionId, [
        imagePath,
      ]);
      expect(result.added, 1);

      // 已自动成为根收藏成员（幂等入根）
      expect(await dataSource.isFavorite(imageId), isTrue);
      expect(await repo.getCollectionImageIds(collectionId), [imageId]);

      // 重复添加：已在集合，但入根保持幂等、不重复计数
      final again = await repo.addImagesToCollection(collectionId, [imagePath]);
      expect(again.added, 0);
      expect(again.alreadyIn, 1);
      expect(await dataSource.getFavoriteCount(), 1);
    });
  });
}
