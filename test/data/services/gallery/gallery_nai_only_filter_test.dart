import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';

/// NAI-only 过滤路由测试：
/// FilterCriteria.naiOnly → 无 searchQuery 也走 DB 候选路径，只保留有元数据的文件
void main() {
  group('Gallery NAI-only Filter Tests', () {
    late GalleryDataSource dataSource;
    late GalleryFilterService filterService;
    late String testDbPath;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);

      final tempDir = Directory.systemTemp.createTempSync('gallery_nai_');
      testDbPath = '${tempDir.path}/nai_only_filter.db';
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

    Future<void> addImage(String path) async {
      await dataSource.upsertImage(
        filePath: path,
        fileName: path.split('/').last,
        fileSize: 1024,
        createdAt: now,
        modifiedAt: now,
      );
    }

    Future<void> addMetadata(String path) async {
      final id = await dataSource.getImageIdByPath(path);
      await dataSource.upsertMetadata(
        id!,
        const NaiImageMetadata(prompt: '1girl', model: 'nai-diffusion-3'),
      );
    }

    List<File> allFiles(List<String> paths) =>
        paths.map(File.new).toList(growable: false);

    test(
      'naiOnly without searchQuery still goes through DB candidate path',
      () async {
        await addImage('/n/a.png');
        await addImage('/n/b.png');
        await addImage('/n/no_meta.png');
        await addMetadata('/n/a.png');
        await addMetadata('/n/b.png');

        final result = await filterService.applyFilters(
          allFiles(['/n/a.png', '/n/b.png', '/n/no_meta.png']),
          const FilterCriteria(naiOnly: true),
        );

        expect(result.files.map((f) => f.path).toSet(), {
          '/n/a.png',
          '/n/b.png',
        });
      },
    );

    test('naiOnly=false returns everything (no filter applied)', () async {
      await addImage('/n/all_a.png');
      await addImage('/n/all_b.png');

      final result = await filterService.applyFilters(
        allFiles(['/n/all_a.png', '/n/all_b.png']),
        const FilterCriteria(),
      );

      expect(result.files.length, 2);
    });

    test('naiOnly combined with favorites-only filter', () async {
      await addImage('/n/fav_a.png');
      await addImage('/n/fav_no_meta.png');
      await addMetadata('/n/fav_a.png');

      await dataSource.toggleFavorite(
        (await dataSource.getImageIdByPath('/n/fav_a.png'))!,
      );
      await dataSource.toggleFavorite(
        (await dataSource.getImageIdByPath('/n/fav_no_meta.png'))!,
      );

      final result = await filterService.applyFilters(
        allFiles(['/n/fav_a.png', '/n/fav_no_meta.png']),
        const FilterCriteria(showFavoritesOnly: true, naiOnly: true),
      );

      // 收藏里的非 NAI 图被 naiOnly 排除
      expect(result.files.map((f) => f.path).toSet(), {'/n/fav_a.png'});
    });

    test('naiOnly with search query keeps only metadata files', () async {
      await addImage('/n/s_keep.png');
      await addImage('/n/s_drop.png');
      await addMetadata('/n/s_keep.png');

      final result = await filterService.applyFilters(
        allFiles(['/n/s_keep.png', '/n/s_drop.png']),
        const FilterCriteria(searchQuery: 's_', naiOnly: true),
      );

      expect(result.files.map((f) => f.path).toSet(), {'/n/s_keep.png'});
    });

    test('filter cache distinguishes naiOnly on/off', () async {
      await addImage('/n/c_a.png');
      await addMetadata('/n/c_a.png');

      final on = await filterService.applyFilters(
        allFiles(['/n/c_a.png']),
        const FilterCriteria(naiOnly: true),
      );
      final off = await filterService.applyFilters(
        allFiles(['/n/c_a.png']),
        const FilterCriteria(naiOnly: false),
      );

      expect(on.files.length, 1);
      expect(off.files.length, 1);
      expect(on.criteria, isNot(off.criteria));
    });
  });
}
