import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';

/// 收藏集过滤路径（membership）单元测试：
/// FilterCriteria.collectionId → _filterByCollection
void main() {
  group('Gallery Collection Filter Tests', () {
    late GalleryDataSource dataSource;
    late GalleryFilterService filterService;
    late String testDbPath;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);

      final tempDir = Directory.systemTemp.createTempSync('gallery_colf_');
      testDbPath = '${tempDir.path}/collection_filter.db';
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
      filterService = GalleryFilterService(dataSource);
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

    test('filters files by collection membership', () async {
      await addImage('/c/a.png');
      await addImage('/c/b.png');
      await addImage('/c/c.png');

      final collectionId = await dataSource.createCollection('favs');
      await dataSource.addImageToCollection(
        collectionId,
        (await dataSource.getImageIdByPath('/c/a.png'))!,
      );
      await dataSource.addImageToCollection(
        collectionId,
        (await dataSource.getImageIdByPath('/c/c.png'))!,
      );

      final allFiles = [File('/c/a.png'), File('/c/b.png'), File('/c/c.png')];

      final result = await filterService.applyFilters(
        allFiles,
        const FilterCriteria().copyWith(collectionId: collectionId),
      );

      expect(result.files.map((f) => f.path).toSet(), {'/c/a.png', '/c/c.png'});
    });

    test('empty membership yields empty result', () async {
      await addImage('/c/e1.png');
      final collectionId = await dataSource.createCollection('empty');

      final result = await filterService.applyFilters([
        File('/c/e1.png'),
      ], const FilterCriteria().copyWith(collectionId: collectionId));

      expect(result.files, isEmpty);
    });

    test('combines collection filter with search query', () async {
      await addImage('/c/alpha_1.png');
      await addImage('/c/alpha_2.png');
      await addImage('/c/beta_1.png');

      final collectionId = await dataSource.createCollection('sel');
      await dataSource.addImageToCollection(
        collectionId,
        (await dataSource.getImageIdByPath('/c/alpha_1.png'))!,
      );
      await dataSource.addImageToCollection(
        collectionId,
        (await dataSource.getImageIdByPath('/c/beta_1.png'))!,
      );

      final allFiles = [
        File('/c/alpha_1.png'),
        File('/c/alpha_2.png'),
        File('/c/beta_1.png'),
      ];

      final result = await filterService.applyFilters(
        allFiles,
        const FilterCriteria().copyWith(
          collectionId: collectionId,
          searchQuery: 'alpha',
        ),
      );

      // 搜索（文件名匹配 alpha）+ 收藏集交集
      expect(result.files.map((f) => f.path).toList(), ['/c/alpha_1.png']);
      expect(result.files, isNot(contains(File('/c/alpha_2.png'))));
      expect(result.files, isNot(contains(File('/c/beta_1.png'))));
    });

    test('collectionId participates in cache key and equality', () {
      const base = FilterCriteria();
      final withCol = base.copyWith(collectionId: 'c1');
      final withColOther = base.copyWith(collectionId: 'c2');

      expect(withCol, isNot(base));
      expect(withCol, isNot(withColOther));
      expect(withCol.cacheKey, contains('colId:c1'));
      expect(withCol.hasFilters, isTrue);
      expect(base.copyWith(collectionId: null), base);
    });
  });
}
