import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';

void main() {
  group('Gallery AdvancedSearch Without CandidatePaths Regression Tests', () {
    late GalleryDataSource dataSource;
    late String testDbPath;
    late int cocoaId;
    late int vanillaId;
    late int strawberryId;
    late int matchaId;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);

      final tempDir = Directory.systemTemp.createTempSync(
        'gallery_search_no_candidate_',
      );
      testDbPath = '${tempDir.path}/test.db';
    });

    tearDownAll(() async {
      await ConnectionPoolHolder.dispose();
      try {
        final dbFile = File(testDbPath);
        if (await dbFile.exists()) {
          await dbFile.delete();
        }
        final tempDir = Directory(testDbPath).parent;
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    setUp(() async {
      if (ConnectionPoolHolder.isInitialized) {
        await ConnectionPoolHolder.dispose();
      }

      final dbFile = File(testDbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      await ConnectionPoolHolder.initialize(
        dbPath: testDbPath,
        maxConnections: 2,
      );

      dataSource = GalleryDataSource();
      await dataSource.initialize();

      // 构造 4 条记录，只有 1 条 prompt 含 'cocoa'
      final now = DateTime(2026, 6, 1, 10);

      cocoaId = await dataSource.upsertImage(
        filePath: '/test/cocoa.png',
        fileName: 'cocoa.png',
        fileSize: 1000,
        createdAt: now.add(const Duration(minutes: 1)),
        modifiedAt: now.add(const Duration(minutes: 1)),
      );
      await dataSource.upsertMetadata(
        cocoaId,
        const NaiImageMetadata(
          prompt: '1girl, cocoa, sweet smile',
          negativePrompt: 'lowres',
        ),
      );

      vanillaId = await dataSource.upsertImage(
        filePath: '/test/vanilla.png',
        fileName: 'vanilla.png',
        fileSize: 1100,
        createdAt: now.add(const Duration(minutes: 2)),
        modifiedAt: now.add(const Duration(minutes: 2)),
      );
      await dataSource.upsertMetadata(
        vanillaId,
        const NaiImageMetadata(
          prompt: '1girl, vanilla, blue eyes',
          negativePrompt: 'lowres',
        ),
      );

      strawberryId = await dataSource.upsertImage(
        filePath: '/test/strawberry.png',
        fileName: 'strawberry.png',
        fileSize: 1200,
        createdAt: now.add(const Duration(minutes: 3)),
        modifiedAt: now.add(const Duration(minutes: 3)),
      );
      await dataSource.upsertMetadata(
        strawberryId,
        const NaiImageMetadata(
          prompt: '1girl, strawberry, red dress',
          negativePrompt: 'lowres',
        ),
      );

      matchaId = await dataSource.upsertImage(
        filePath: '/test/matcha.png',
        fileName: 'matcha.png',
        fileSize: 1300,
        createdAt: now.add(const Duration(minutes: 4)),
        modifiedAt: now.add(const Duration(minutes: 4)),
      );
      await dataSource.upsertMetadata(
        matchaId,
        const NaiImageMetadata(
          prompt: '1girl, matcha, green hair',
          negativePrompt: 'lowres',
        ),
      );
    });

    tearDown(() async {
      await dataSource.dispose();
      await ConnectionPoolHolder.dispose();

      final dbFile = File(testDbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
    });

    test(
      'textQuery 非空 + candidatePaths 为空时，结果仅包含命中 id 且不含其他任何 id（严格等值断言）',
      () async {
        final result = await dataSource.advancedSearch(
          textQuery: 'cocoa',
          limit: 10,
        );

        // 严格等值断言：只能返回 [cocoaId]，不能包含 vanilla, strawberry, matcha
        expect(result, [cocoaId]);
        expect(result.length, 1);
      },
    );

    test(
      'advancedSearchResult 在无 candidatePaths 且有文本时，正确对齐 ids 与 filePaths',
      () async {
        final searchResult = await dataSource.advancedSearchResult(
          textQuery: 'cocoa',
          limit: 10,
        );

        expect(searchResult.ids, [cocoaId]);
        expect(searchResult.filePaths, ['/test/cocoa.png']);
      },
    );

    test('无文本 + 无候选路径对照用例：确认全量返回所有未删除记录', () async {
      final result = await dataSource.advancedSearch(limit: 10);

      // 必须全量返回 4 条记录，不能丢失
      expect(result.length, 4);
      expect(result, containsAll([cocoaId, vanillaId, strawberryId, matchaId]));
    });
  });
}
