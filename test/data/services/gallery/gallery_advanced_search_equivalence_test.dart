import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';

void main() {
  group('Gallery Advanced Search Equivalence Tests', () {
    late Directory tempDir;
    late GalleryDataSource dataSource;
    late GalleryFilterService filterService;
    late List<String> inViewPaths;
    late List<String> outViewPaths;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'nai_launcher_search_equiv_test_',
      );
      final dbPath = p.join(tempDir.path, 'gallery.db');

      await ConnectionPoolHolder.initialize(dbPath: dbPath, maxConnections: 2);
      dataSource = GalleryDataSource();
      await dataSource.initialize();
      filterService = GalleryFilterService(dataSource);

      inViewPaths = [];
      outViewPaths = [];
      final now = DateTime(2026, 5, 1, 12);

      for (var i = 0; i < 10; i++) {
        final filePath = p.join(tempDir.path, 'in_$i.png');
        inViewPaths.add(filePath);
        final id = await dataSource.upsertImage(
          filePath: filePath,
          fileName: 'in_$i.png',
          fileSize: 1000 + i * 100,
          width: i % 2 == 0 ? 1024 : 512,
          height: 768,
          createdAt: now.add(Duration(hours: i)),
          modifiedAt: now.add(Duration(hours: i)),
          isFavorite: i % 3 == 0,
        );
        await dataSource.upsertMetadata(
          id,
          NaiImageMetadata(
            prompt: i % 2 == 0
                ? 'masterpiece, 1girl, cat_ears'
                : 'masterpiece, landscape',
            negativePrompt: 'lowres',
            model: i % 2 == 0 ? 'nai-diffusion-4-curated' : 'nai-diffusion-3',
            steps: 28,
            scale: 5.0,
          ),
        );
      }

      for (var i = 0; i < 5; i++) {
        final filePath = p.join(tempDir.path, 'out_$i.png');
        outViewPaths.add(filePath);
        final id = await dataSource.upsertImage(
          filePath: filePath,
          fileName: 'out_$i.png',
          fileSize: 2000 + i * 100,
          width: 1024,
          height: 768,
          createdAt: now.add(Duration(days: 1, hours: i)),
          modifiedAt: now.add(Duration(days: 1, hours: i)),
          isFavorite: true,
        );
        await dataSource.upsertMetadata(
          id,
          const NaiImageMetadata(
            prompt: 'masterpiece, 1girl, cat_ears',
            negativePrompt: 'lowres',
            model: 'nai-diffusion-4-curated',
            steps: 28,
            scale: 5.0,
          ),
        );
      }
    });

    tearDown(() async {
      await dataSource.dispose();
      await ConnectionPoolHolder.dispose();
      if (await tempDir.exists()) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    });

    test('Mode A（有文本）+ 候选路径：命中小集合在 Dart 内存与 candidatePaths 正确求交', () async {
      // 搜索带词 'cat_ears'，限定候选路径在 inViewPaths
      // 应该只命中 in_0, in_2, in_4, in_6, in_8 (共 5 张)，outView 中的虽然也含 cat_ears 但必须被排除
      final searchResult = await dataSource.advancedSearchResult(
        textQuery: 'cat_ears',
        candidatePaths: inViewPaths,
        limit: 100,
      );

      expect(searchResult.ids.length, 5);
      expect(searchResult.filePaths.length, 5);
      expect(searchResult.filePaths.every(inViewPaths.contains), isTrue);

      // advancedSearch 便捷方法应返回完全一致的 IDs
      final idsOnly = await dataSource.advancedSearch(
        textQuery: 'cat_ears',
        candidatePaths: inViewPaths,
        limit: 100,
      );
      expect(idsOnly, searchResult.ids);
    });

    test('Mode B（无文本）+ 候选路径：单次 SQL 在内存求交，视图外行被排除且结果一致', () async {
      // 无词，条件 width >= 1000，限定候选路径为 inViewPaths
      // inView 里只有偶数序号 width=1024 (共 5 张)；outView 虽然也有 5 张且 modifiedAt 更晚，但必须被排除
      final searchResult = await dataSource.advancedSearchResult(
        minWidth: 1000,
        candidatePaths: inViewPaths,
        limit: 100,
      );

      expect(searchResult.ids.length, 5);
      expect(searchResult.filePaths.length, 5);
      expect(searchResult.filePaths.every(inViewPaths.contains), isTrue);

      final idsOnly = await dataSource.advancedSearch(
        minWidth: 1000,
        candidatePaths: inViewPaths,
        limit: 100,
      );
      expect(idsOnly, searchResult.ids);
    });

    test(
      'GalleryFilterService 通过 advancedSearchResult 直接消费 filePaths 过滤成功',
      () async {
        final inFiles = inViewPaths.map((p) => File(p)).toList();
        for (final f in inFiles) {
          await f.writeAsBytes(List.filled(10, 0));
        }

        // 带搜索词走数据库 advancedSearchResult
        final result = await filterService.applyFilters(
          inFiles,
          const FilterCriteria(searchQuery: 'cat_ears'),
        );

        // inView 中偶数图命中 cat_ears (in_0, in_2, in_4, in_6, in_8)
        expect(result.files.length, 5);
        final filteredNames = result.files
            .map((f) => p.basename(f.path))
            .toList();
        expect(
          filteredNames,
          containsAll([
            'in_0.png',
            'in_2.png',
            'in_4.png',
            'in_6.png',
            'in_8.png',
          ]),
        );
      },
    );
  });
}
