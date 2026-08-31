import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';

/// GalleryDataSource 批量查询方法单元测试
///
/// 运行: flutter test test/core/database/datasources/gallery_data_source_batch_test.dart
void main() {
  group('GalleryDataSource Batch Query Tests', () {
    late GalleryDataSource dataSource;
    late String testDbPath;

    setUpAll(() async {
      // 初始化 sqflite_ffi
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      // 初始化日志
      await AppLogger.initialize(isTestEnvironment: true);

      // 创建临时测试数据库路径
      final tempDir = Directory.systemTemp.createTempSync('gallery_test_');
      testDbPath = '${tempDir.path}/test_gallery.db';

      AppLogger.i('Test database path: $testDbPath', 'GalleryBatchTest');
    });

    tearDownAll(() async {
      // 清理资源
      await ConnectionPoolHolder.dispose();

      // 删除测试数据库文件
      try {
        final dbFile = File(testDbPath);
        if (await dbFile.exists()) {
          await dbFile.delete();
        }
        final tempDir = Directory(testDbPath).parent;
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (e) {
        AppLogger.w('Failed to clean up test database: $e', 'GalleryBatchTest');
      }
    });

    setUp(() async {
      // 每个测试前重置并初始化连接池
      if (ConnectionPoolHolder.isInitialized) {
        await ConnectionPoolHolder.dispose();
      }

      // 确保数据库文件不存在
      try {
        final dbFile = File(testDbPath);
        if (await dbFile.exists()) {
          await dbFile.delete();
        }
      } catch (_) {}

      // 初始化连接池
      await ConnectionPoolHolder.initialize(
        dbPath: testDbPath,
        maxConnections: 2,
      );

      // 创建数据源并初始化
      dataSource = GalleryDataSource();
      await dataSource.initialize();
    });

    tearDown(() async {
      // 每个测试后清理
      await dataSource.dispose();
      await ConnectionPoolHolder.dispose();

      // 删除测试数据库文件
      try {
        final dbFile = File(testDbPath);
        if (await dbFile.exists()) {
          await dbFile.delete();
        }
      } catch (_) {}
    });

    // ============================================================
    // getImageIdsByPaths 测试
    // ============================================================

    group('getImageIdsByPaths', () {
      test('should return empty map when input list is empty', () async {
        final result = await dataSource.getImageIdsByPaths([]);

        expect(result, isEmpty);
      });

      test(
        'should return map with null values for non-existent paths',
        () async {
          final paths = ['/non/existent/path1.png', '/non/existent/path2.png'];

          final result = await dataSource.getImageIdsByPaths(paths);

          expect(result.length, equals(2));
          expect(result[paths[0]], isNull);
          expect(result[paths[1]], isNull);
        },
      );

      test('should return correct IDs for existing paths', () async {
        // 插入测试数据
        final id1 = await dataSource.upsertImage(
          filePath: '/test/path1.png',
          fileName: 'path1.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        final id2 = await dataSource.upsertImage(
          filePath: '/test/path2.png',
          fileName: 'path2.png',
          fileSize: 2000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        final paths = ['/test/path1.png', '/test/path2.png'];
        final result = await dataSource.getImageIdsByPaths(paths);

        expect(result.length, equals(2));
        expect(result[paths[0]], equals(id1));
        expect(result[paths[1]], equals(id2));
      });

      test('should handle mix of existing and non-existent paths', () async {
        final id1 = await dataSource.upsertImage(
          filePath: '/test/existing.png',
          fileName: 'existing.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        final paths = ['/test/existing.png', '/test/nonexistent.png'];
        final result = await dataSource.getImageIdsByPaths(paths);

        expect(result.length, equals(2));
        expect(result[paths[0]], equals(id1));
        expect(result[paths[1]], isNull);
      });

      test('should not include deleted images', () async {
        await dataSource.upsertImage(
          filePath: '/test/deleted.png',
          fileName: 'deleted.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        // 标记为删除
        await dataSource.markAsDeleted('/test/deleted.png');

        final result = await dataSource.getImageIdsByPaths([
          '/test/deleted.png',
        ]);

        expect(result['/test/deleted.png'], isNull);
      });
    });

    // ============================================================
    // getImagesByIds 测试
    // ============================================================

    group('getImagesByIds', () {
      test('should return empty list when input list is empty', () async {
        final result = await dataSource.getImagesByIds([]);

        expect(result, isEmpty);
      });

      test('should return images for valid IDs', () async {
        final now = DateTime.now();
        final id1 = await dataSource.upsertImage(
          filePath: '/test/img1.png',
          fileName: 'img1.png',
          fileSize: 1000,
          createdAt: now,
          modifiedAt: now,
        );

        final id2 = await dataSource.upsertImage(
          filePath: '/test/img2.png',
          fileName: 'img2.png',
          fileSize: 2000,
          createdAt: now,
          modifiedAt: now,
        );

        final result = await dataSource.getImagesByIds([id1, id2]);

        expect(result.length, equals(2));
        expect(
          result.any((img) => img.id == id1 && img.fileName == 'img1.png'),
          isTrue,
        );
        expect(
          result.any((img) => img.id == id2 && img.fileName == 'img2.png'),
          isTrue,
        );
      });

      test('should return only existing images and skip deleted', () async {
        final id1 = await dataSource.upsertImage(
          filePath: '/test/existing.png',
          fileName: 'existing.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        final id2 = await dataSource.upsertImage(
          filePath: '/test/to_delete.png',
          fileName: 'to_delete.png',
          fileSize: 2000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        // 标记第二个为删除
        await dataSource.markAsDeleted('/test/to_delete.png');

        final result = await dataSource.getImagesByIds([id1, id2, 99999]);

        expect(result.length, equals(1));
        expect(result.first.id, equals(id1));
      });

      test('should return results in original ID order', () async {
        final now = DateTime.now();

        // 按顺序插入，但获取时按相反顺序
        final id1 = await dataSource.upsertImage(
          filePath: '/test/order1.png',
          fileName: 'order1.png',
          fileSize: 1000,
          createdAt: now,
          modifiedAt: now,
        );

        final id2 = await dataSource.upsertImage(
          filePath: '/test/order2.png',
          fileName: 'order2.png',
          fileSize: 2000,
          createdAt: now,
          modifiedAt: now,
        );

        final id3 = await dataSource.upsertImage(
          filePath: '/test/order3.png',
          fileName: 'order3.png',
          fileSize: 3000,
          createdAt: now,
          modifiedAt: now,
        );

        final result = await dataSource.getImagesByIds([id3, id1, id2]);

        expect(result.length, equals(3));
        expect(result[0].id, equals(id3));
        expect(result[1].id, equals(id1));
        expect(result[2].id, equals(id2));
      });

      test('should use cache for subsequent queries', () async {
        final id = await dataSource.upsertImage(
          filePath: '/test/cached.png',
          fileName: 'cached.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        // 第一次查询，应该从数据库获取
        final result1 = await dataSource.getImagesByIds([id]);
        expect(result1.length, equals(1));

        // 第二次查询，应该从缓存获取
        final result2 = await dataSource.getImagesByIds([id]);
        expect(result2.length, equals(1));
        expect(result2.first.fileName, equals('cached.png'));
      });
    });

    // ============================================================
    // getMetadataByImageIds 测试
    // ============================================================

    group('getMetadataByImageIds', () {
      test('should return empty map when input list is empty', () async {
        final result = await dataSource.getMetadataByImageIds([]);

        expect(result, isEmpty);
      });

      test('should return null values for images without metadata', () async {
        final id = await dataSource.upsertImage(
          filePath: '/test/no_metadata.png',
          fileName: 'no_metadata.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        final result = await dataSource.getMetadataByImageIds([id]);

        expect(result.length, equals(1));
        expect(result[id], isNull);
      });

      test('should return metadata for images with metadata', () async {
        final id = await dataSource.upsertImage(
          filePath: '/test/with_metadata.png',
          fileName: 'with_metadata.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        const metadata = NaiImageMetadata(
          prompt: 'test prompt',
          negativePrompt: 'test negative',
          seed: 12345,
          sampler: 'k_euler',
          steps: 28,
          scale: 7.5,
          width: 512,
          height: 768,
          model: 'nai-diffusion-3',
        );

        await dataSource.upsertMetadata(id, metadata);

        final result = await dataSource.getMetadataByImageIds([id]);

        expect(result.length, equals(1));
        expect(result[id], isNotNull);
        expect(result[id]!.prompt, equals('test prompt'));
        expect(result[id]!.negativePrompt, equals('test negative'));
        expect(result[id]!.seed, equals(12345));
        expect(result[id]!.sampler, equals('k_euler'));
        expect(result[id]!.model, equals('nai-diffusion-3'));
      });

      test('should handle mix of images with and without metadata', () async {
        final id1 = await dataSource.upsertImage(
          filePath: '/test/meta1.png',
          fileName: 'meta1.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        final id2 = await dataSource.upsertImage(
          filePath: '/test/meta2.png',
          fileName: 'meta2.png',
          fileSize: 2000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        const metadata = NaiImageMetadata(
          prompt: 'prompt for meta1',
          negativePrompt: '',
        );

        await dataSource.upsertMetadata(id1, metadata);

        final result = await dataSource.getMetadataByImageIds([id1, id2]);

        expect(result.length, equals(2));
        expect(result[id1], isNotNull);
        expect(result[id1]!.prompt, equals('prompt for meta1'));
        expect(result[id2], isNull);
      });

      test('should use cache for subsequent queries', () async {
        final id = await dataSource.upsertImage(
          filePath: '/test/meta_cached.png',
          fileName: 'meta_cached.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        const metadata = NaiImageMetadata(
          prompt: 'cached prompt',
          negativePrompt: '',
        );

        await dataSource.upsertMetadata(id, metadata);

        // 第一次查询
        final result1 = await dataSource.getMetadataByImageIds([id]);
        expect(result1[id]!.prompt, equals('cached prompt'));

        // 第二次查询应该使用缓存
        final result2 = await dataSource.getMetadataByImageIds([id]);
        expect(result2[id]!.prompt, equals('cached prompt'));
      });
    });

    // ============================================================
    // 搜索测试
    // ============================================================

    group('search', () {
      test('should find prompt substrings inside tag-like tokens', () async {
        final now = DateTime.now();
        final imageId = await dataSource.upsertImage(
          filePath: '/test/prompt_substring.png',
          fileName: 'prompt_substring.png',
          fileSize: 1000,
          createdAt: now,
          modifiedAt: now,
        );

        await dataSource.upsertMetadata(
          imageId,
          const NaiImageMetadata(
            prompt: 'artist:shycocoa, 1girl, blue_eyes',
            negativePrompt: '',
            seed: 1,
          ),
        );

        final cocoaResults = await dataSource.advancedSearch(
          textQuery: 'cocoa',
          limit: 10,
        );
        final eyesResults = await dataSource.advancedSearch(
          textQuery: 'eyes',
          limit: 10,
        );

        expect(cocoaResults, contains(imageId));
        expect(eyesResults, contains(imageId));
      });

      test('should find model and sampler metadata fields', () async {
        final now = DateTime.now();
        final imageId = await dataSource.upsertImage(
          filePath: '/test/model_sampler.png',
          fileName: 'model_sampler.png',
          fileSize: 1000,
          createdAt: now,
          modifiedAt: now,
        );

        await dataSource.upsertMetadata(
          imageId,
          const NaiImageMetadata(
            prompt: 'unrelated prompt',
            negativePrompt: '',
            seed: 1,
            model: 'nai-diffusion-v45-full',
            sampler: 'k_euler_ancestral',
          ),
        );

        final modelResults = await dataSource.advancedSearch(
          textQuery: 'v45',
          limit: 10,
        );
        final samplerResults = await dataSource.advancedSearch(
          textQuery: 'euler',
          limit: 10,
        );

        expect(modelResults, contains(imageId));
        expect(samplerResults, contains(imageId));
      });

      test('should filter selected prompt tags by intersection', () async {
        final now = DateTime.now();
        final matchingFile = File('/test/tag_intersection_match.png');
        final blueOnlyFile = File('/test/tag_intersection_blue_only.png');
        final blondeOnlyFile = File('/test/tag_intersection_blonde_only.png');

        final matchingId = await dataSource.upsertImage(
          filePath: matchingFile.path,
          fileName: 'tag_intersection_match.png',
          fileSize: 1024,
          createdAt: now,
          modifiedAt: now,
        );
        final blueOnlyId = await dataSource.upsertImage(
          filePath: blueOnlyFile.path,
          fileName: 'tag_intersection_blue_only.png',
          fileSize: 1024,
          createdAt: now,
          modifiedAt: now,
        );
        final blondeOnlyId = await dataSource.upsertImage(
          filePath: blondeOnlyFile.path,
          fileName: 'tag_intersection_blonde_only.png',
          fileSize: 1024,
          createdAt: now,
          modifiedAt: now,
        );

        await dataSource.batchUpsertMetadata([
          MapEntry(
            matchingId,
            const NaiImageMetadata(
              prompt: '1girl, blue eyes, blonde hair',
              negativePrompt: '',
              seed: 1,
            ),
          ),
          MapEntry(
            blueOnlyId,
            const NaiImageMetadata(
              prompt: '1girl, blue eyes, black hair',
              negativePrompt: '',
              seed: 2,
            ),
          ),
          MapEntry(
            blondeOnlyId,
            const NaiImageMetadata(
              prompt: '1girl, green eyes, blonde hair',
              negativePrompt: '',
              seed: 3,
            ),
          ),
        ]);

        final filterService = GalleryFilterService(dataSource);
        final result = await filterService.applyFilters([
          matchingFile,
          blueOnlyFile,
          blondeOnlyFile,
        ], const FilterCriteria(selectedTags: ['blue_eyes', 'blonde_hair']));

        expect(result.files.map((file) => file.path), [matchingFile.path]);
      });

      test('should intersect text search results with selected tags', () async {
        final now = DateTime.now();
        final matchingFile = File('/test/text_and_tags_match.png');
        final missingTagFile = File('/test/text_and_tags_missing_tag.png');
        final missingTextFile = File('/test/text_and_tags_missing_text.png');

        final matchingId = await dataSource.upsertImage(
          filePath: matchingFile.path,
          fileName: 'text_and_tags_match.png',
          fileSize: 1024,
          createdAt: now,
          modifiedAt: now,
        );
        final missingTagId = await dataSource.upsertImage(
          filePath: missingTagFile.path,
          fileName: 'text_and_tags_missing_tag.png',
          fileSize: 1024,
          createdAt: now,
          modifiedAt: now,
        );
        final missingTextId = await dataSource.upsertImage(
          filePath: missingTextFile.path,
          fileName: 'text_and_tags_missing_text.png',
          fileSize: 1024,
          createdAt: now,
          modifiedAt: now,
        );

        await dataSource.batchUpsertMetadata([
          MapEntry(
            matchingId,
            const NaiImageMetadata(
              prompt: 'shared_scene, blue eyes, blonde hair',
              negativePrompt: '',
              seed: 1,
            ),
          ),
          MapEntry(
            missingTagId,
            const NaiImageMetadata(
              prompt: 'shared_scene, blue eyes, black hair',
              negativePrompt: '',
              seed: 2,
            ),
          ),
          MapEntry(
            missingTextId,
            const NaiImageMetadata(
              prompt: 'private_scene, blue eyes, blonde hair',
              negativePrompt: '',
              seed: 3,
            ),
          ),
        ]);

        final filterService = GalleryFilterService(dataSource);
        final result = await filterService.applyFilters(
          [matchingFile, missingTagFile, missingTextFile],
          const FilterCriteria(
            searchQuery: 'shared_scene',
            selectedTags: ['blue_eyes', 'blonde_hair'],
          ),
        );

        expect(result.files.map((file) => file.path), [matchingFile.path]);
      });

      test(
        'should split comma search query and match segments by containment',
        () async {
          final now = DateTime.now();
          final matchingFile = File('/test/comma_search_match.png');
          final sweetoneOnlyFile = File('/test/comma_search_sweetone_only.png');
          final shycocoaOnlyFile = File('/test/comma_search_shycocoa_only.png');

          final matchingId = await dataSource.upsertImage(
            filePath: matchingFile.path,
            fileName: 'comma_search_match.png',
            fileSize: 1024,
            createdAt: now,
            modifiedAt: now,
          );
          final sweetoneOnlyId = await dataSource.upsertImage(
            filePath: sweetoneOnlyFile.path,
            fileName: 'comma_search_sweetone_only.png',
            fileSize: 1024,
            createdAt: now,
            modifiedAt: now,
          );
          final shycocoaOnlyId = await dataSource.upsertImage(
            filePath: shycocoaOnlyFile.path,
            fileName: 'comma_search_shycocoa_only.png',
            fileSize: 1024,
            createdAt: now,
            modifiedAt: now,
          );

          await dataSource.batchUpsertMetadata([
            MapEntry(
              matchingId,
              const NaiImageMetadata(
                prompt: 'artist:shycocoa, sweetonedollar, 1girl',
                negativePrompt: '',
                seed: 1,
              ),
            ),
            MapEntry(
              sweetoneOnlyId,
              const NaiImageMetadata(
                prompt: 'sweetonedollar, solo, blue eyes',
                negativePrompt: '',
                seed: 2,
              ),
            ),
            MapEntry(
              shycocoaOnlyId,
              const NaiImageMetadata(
                prompt: 'artist:shycocoa, solo, blonde hair',
                negativePrompt: '',
                seed: 3,
              ),
            ),
          ]);

          final filterService = GalleryFilterService(dataSource);
          final result = await filterService.applyFilters([
            matchingFile,
            sweetoneOnlyFile,
            shycocoaOnlyFile,
          ], const FilterCriteria(searchQuery: 'sweetone,shycocoa'));

          expect(result.files.map((file) => file.path), [matchingFile.path]);

          final partialResult = await filterService.applyFilters([
            matchingFile,
            sweetoneOnlyFile,
            shycocoaOnlyFile,
          ], const FilterCriteria(searchQuery: 'sweetone,'));

          expect(partialResult.files.map((file) => file.path), [
            matchingFile.path,
            sweetoneOnlyFile.path,
          ]);
        },
      );

      test(
        'should apply comma search inside database prefiltered results',
        () async {
          final now = DateTime.now();
          final favoriteMatch = File('/test/comma_prefilter_favorite.png');
          final decoyA = File('/test/comma_prefilter_decoy_a.png');
          final decoyB = File('/test/comma_prefilter_decoy_b.png');

          final favoriteId = await dataSource.upsertImage(
            filePath: favoriteMatch.path,
            fileName: 'comma_prefilter_favorite.png',
            fileSize: 1024,
            createdAt: now.subtract(const Duration(days: 3)),
            modifiedAt: now.subtract(const Duration(days: 3)),
          );
          final decoyAId = await dataSource.upsertImage(
            filePath: decoyA.path,
            fileName: 'comma_prefilter_decoy_a.png',
            fileSize: 1024,
            createdAt: now,
            modifiedAt: now,
          );
          final decoyBId = await dataSource.upsertImage(
            filePath: decoyB.path,
            fileName: 'comma_prefilter_decoy_b.png',
            fileSize: 1024,
            createdAt: now.subtract(const Duration(hours: 1)),
            modifiedAt: now.subtract(const Duration(hours: 1)),
          );

          await dataSource.batchUpsertMetadata([
            MapEntry(
              favoriteId,
              const NaiImageMetadata(
                prompt: 'artist:shycocoa, sweetonedollar, selected favorite',
                negativePrompt: '',
                seed: 10,
              ),
            ),
            MapEntry(
              decoyAId,
              const NaiImageMetadata(
                prompt: 'artist:shycocoa, sweetonedollar, newer decoy',
                negativePrompt: '',
                seed: 11,
              ),
            ),
            MapEntry(
              decoyBId,
              const NaiImageMetadata(
                prompt: 'artist:shycocoa, sweetonedollar, second newer decoy',
                negativePrompt: '',
                seed: 12,
              ),
            ),
          ]);

          await dataSource.toggleFavorite(favoriteId);

          final filterService = GalleryFilterService(dataSource);
          final result = await filterService.applyFilters(
            [favoriteMatch, decoyA, decoyB],
            const FilterCriteria(
              searchQuery: 'sweetone,shycocoa',
              showFavoritesOnly: true,
            ),
          );

          expect(result.files.map((file) => file.path), [favoriteMatch.path]);
        },
      );
    });

    group('GalleryFilterService date filtering', () {
      test(
        'should filter date range across more than one legacy batch',
        () async {
          final tempDir = Directory.systemTemp.createTempSync(
            'gallery_filter_date_',
          );
          addTearDown(() async {
            if (await tempDir.exists()) {
              await tempDir.delete(recursive: true);
            }
          });

          final files = <File>[];
          final outsideDate = DateTime(2026, 1, 9, 12);
          final insideDate = DateTime(2026, 1, 10, 12);

          for (var i = 0; i < 51; i++) {
            final file = File('${tempDir.path}/image_$i.png');
            await file.writeAsBytes([i]);
            await file.setLastModified(i == 50 ? insideDate : outsideDate);
            files.add(file);
          }

          final filterService = GalleryFilterService(dataSource);
          final result = await filterService.applyFilters(
            files,
            FilterCriteria(
              dateStart: DateTime(2026, 1, 10),
              dateEnd: DateTime(2026, 1, 10),
            ),
          );

          expect(result.files.map((file) => file.path), [files.last.path]);
        },
      );
    });

    // ============================================================
    // getFavoritesByImageIds 测试
    // ============================================================

    group('getFavoritesByImageIds', () {
      test('should return empty map when input list is empty', () async {
        final result = await dataSource.getFavoritesByImageIds([]);

        expect(result, isEmpty);
      });

      test('should return false for non-favorited images', () async {
        final id = await dataSource.upsertImage(
          filePath: '/test/not_favorite.png',
          fileName: 'not_favorite.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        final result = await dataSource.getFavoritesByImageIds([id]);

        expect(result.length, equals(1));
        expect(result[id], isFalse);
      });

      test('should return true for favorited images', () async {
        final id = await dataSource.upsertImage(
          filePath: '/test/favorite.png',
          fileName: 'favorite.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        // 添加到收藏
        await dataSource.toggleFavorite(id);

        final result = await dataSource.getFavoritesByImageIds([id]);

        expect(result.length, equals(1));
        expect(result[id], isTrue);
      });

      test('should handle mix of favorited and non-favorited images', () async {
        final id1 = await dataSource.upsertImage(
          filePath: '/test/fav1.png',
          fileName: 'fav1.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        final id2 = await dataSource.upsertImage(
          filePath: '/test/fav2.png',
          fileName: 'fav2.png',
          fileSize: 2000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        final id3 = await dataSource.upsertImage(
          filePath: '/test/fav3.png',
          fileName: 'fav3.png',
          fileSize: 3000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        // 收藏 id1 和 id3
        await dataSource.toggleFavorite(id1);
        await dataSource.toggleFavorite(id3);

        final result = await dataSource.getFavoritesByImageIds([id1, id2, id3]);

        expect(result.length, equals(3));
        expect(result[id1], isTrue);
        expect(result[id2], isFalse);
        expect(result[id3], isTrue);
      });

      test('should return false for non-existent image IDs', () async {
        final result = await dataSource.getFavoritesByImageIds([99999, 88888]);

        expect(result.length, equals(2));
        expect(result[99999], isFalse);
        expect(result[88888], isFalse);
      });
    });

    // ============================================================
    // getTagsByImageIds 测试
    // ============================================================

    group('getTagsByImageIds', () {
      test('should return empty map when input list is empty', () async {
        final result = await dataSource.getTagsByImageIds([]);

        expect(result, isEmpty);
      });

      test('should return empty list for images without tags', () async {
        final id = await dataSource.upsertImage(
          filePath: '/test/no_tags.png',
          fileName: 'no_tags.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        final result = await dataSource.getTagsByImageIds([id]);

        expect(result.length, equals(1));
        expect(result[id], isEmpty);
      });

      test('should return tags for images with tags', () async {
        final id = await dataSource.upsertImage(
          filePath: '/test/with_tags.png',
          fileName: 'with_tags.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        await dataSource.addTag(id, 'landscape');
        await dataSource.addTag(id, 'anime');
        await dataSource.addTag(id, 'sunset');

        final result = await dataSource.getTagsByImageIds([id]);

        expect(result.length, equals(1));
        expect(result[id], contains('landscape'));
        expect(result[id], contains('anime'));
        expect(result[id], contains('sunset'));
        expect(result[id]!.length, equals(3));
      });

      test('should handle multiple images with different tags', () async {
        final id1 = await dataSource.upsertImage(
          filePath: '/test/tags1.png',
          fileName: 'tags1.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        final id2 = await dataSource.upsertImage(
          filePath: '/test/tags2.png',
          fileName: 'tags2.png',
          fileSize: 2000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        await dataSource.addTag(id1, 'portrait');
        await dataSource.addTag(id1, 'character');
        await dataSource.addTag(id2, 'landscape');

        final result = await dataSource.getTagsByImageIds([id1, id2]);

        expect(result.length, equals(2));
        expect(result[id1], contains('portrait'));
        expect(result[id1], contains('character'));
        expect(result[id1]!.length, equals(2));
        expect(result[id2], contains('landscape'));
        expect(result[id2]!.length, equals(1));
      });

      test('should share tags across images correctly', () async {
        final id1 = await dataSource.upsertImage(
          filePath: '/test/shared1.png',
          fileName: 'shared1.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        final id2 = await dataSource.upsertImage(
          filePath: '/test/shared2.png',
          fileName: 'shared2.png',
          fileSize: 2000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        // 两个图片共享一个标签
        await dataSource.addTag(id1, 'shared_tag');
        await dataSource.addTag(id2, 'shared_tag');
        await dataSource.addTag(id1, 'unique_tag');

        final result = await dataSource.getTagsByImageIds([id1, id2]);

        expect(result[id1], contains('shared_tag'));
        expect(result[id1], contains('unique_tag'));
        expect(result[id2], contains('shared_tag'));
        expect(result[id2], isNot(contains('unique_tag')));
      });
    });

    // ============================================================
    // batchMarkAsDeleted 测试
    // ============================================================

    group('batchMarkAsDeleted', () {
      test('should do nothing when input list is empty', () async {
        await dataSource.batchMarkAsDeleted([]);

        // 验证数据库仍然正常
        final count = await dataSource.countImages();
        expect(count, equals(0));
      });

      test('should mark multiple images as deleted', () async {
        final id1 = await dataSource.upsertImage(
          filePath: '/test/delete1.png',
          fileName: 'delete1.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        final id2 = await dataSource.upsertImage(
          filePath: '/test/delete2.png',
          fileName: 'delete2.png',
          fileSize: 2000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        final initialCount = await dataSource.countImages();
        expect(initialCount, equals(2));

        // 批量删除
        await dataSource.batchMarkAsDeleted([
          '/test/delete1.png',
          '/test/delete2.png',
        ]);

        // 验证删除后不计入总数
        final finalCount = await dataSource.countImages();
        expect(finalCount, equals(0));

        // 验证图片已标记为删除（通过 getImageById）
        final img1 = await dataSource.getImageById(id1);
        final img2 = await dataSource.getImageById(id2);
        expect(img1, isNull);
        expect(img2, isNull);
      });

      test('should handle mix of existing and non-existent paths', () async {
        final id = await dataSource.upsertImage(
          filePath: '/test/exists_delete.png',
          fileName: 'exists_delete.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        // 批量删除，包含存在的和不存在的路径
        await dataSource.batchMarkAsDeleted([
          '/test/exists_delete.png',
          '/test/nonexistent.png',
        ]);

        // 验证存在的被删除
        final img = await dataSource.getImageById(id);
        expect(img, isNull);
      });

      test('should clear cache for deleted images', () async {
        final id = await dataSource.upsertImage(
          filePath: '/test/cache_delete.png',
          fileName: 'cache_delete.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        // 先查询一次，使其进入缓存
        final img1 = await dataSource.getImageById(id);
        expect(img1, isNotNull);

        // 批量删除
        await dataSource.batchMarkAsDeleted(['/test/cache_delete.png']);

        // 验证缓存已被清除（getImageById 返回 null）
        final img2 = await dataSource.getImageById(id);
        expect(img2, isNull);
      });

      test('should handle single path deletion', () async {
        final id = await dataSource.upsertImage(
          filePath: '/test/single_delete.png',
          fileName: 'single_delete.png',
          fileSize: 1000,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        await dataSource.batchMarkAsDeleted(['/test/single_delete.png']);

        final img = await dataSource.getImageById(id);
        expect(img, isNull);
      });
    });

    // ============================================================
    // 综合场景测试
    // ============================================================

    group('Integration Scenarios', () {
      test('should handle complete image workflow', () async {
        // 1. 创建图片
        final id = await dataSource.upsertImage(
          filePath: '/test/workflow.png',
          fileName: 'workflow.png',
          fileSize: 5000,
          width: 512,
          height: 768,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        // 2. 添加元数据
        const metadata = NaiImageMetadata(
          prompt: 'beautiful landscape with mountains',
          negativePrompt: 'blurry, low quality',
          seed: 42,
          sampler: 'k_euler_ancestral',
          steps: 30,
          scale: 8.0,
          width: 512,
          height: 768,
          model: 'nai-diffusion-4',
          smea: true,
          smeaDyn: false,
        );
        await dataSource.upsertMetadata(id, metadata);

        // 3. 添加标签
        await dataSource.addTag(id, 'landscape');
        await dataSource.addTag(id, 'mountains');
        await dataSource.addTag(id, 'scenic');

        // 4. 添加到收藏
        final isFav = await dataSource.toggleFavorite(id);
        expect(isFav, isTrue);

        // 5. 批量查询验证所有数据
        final idsResult = await dataSource.getImageIdsByPaths([
          '/test/workflow.png',
        ]);
        expect(idsResult['/test/workflow.png'], equals(id));

        final imagesResult = await dataSource.getImagesByIds([id]);
        expect(imagesResult.length, equals(1));
        expect(imagesResult.first.fileName, equals('workflow.png'));

        final metaResult = await dataSource.getMetadataByImageIds([id]);
        expect(metaResult[id], isNotNull);
        expect(
          metaResult[id]!.prompt,
          equals('beautiful landscape with mountains'),
        );

        final favsResult = await dataSource.getFavoritesByImageIds([id]);
        expect(favsResult[id], isTrue);

        final tagsResult = await dataSource.getTagsByImageIds([id]);
        expect(tagsResult[id], contains('landscape'));
        expect(tagsResult[id], contains('mountains'));
        expect(tagsResult[id], contains('scenic'));

        // 6. 批量删除
        await dataSource.batchMarkAsDeleted(['/test/workflow.png']);

        // 7. 验证删除后无法获取
        final afterDelete = await dataSource.getImageById(id);
        expect(afterDelete, isNull);
      });

      test('should handle batch operations with large datasets', () async {
        // 创建多个图片
        final ids = <int>[];
        final paths = <String>[];

        for (var i = 0; i < 50; i++) {
          final path = '/test/batch_$i.png';
          paths.add(path);

          final id = await dataSource.upsertImage(
            filePath: path,
            fileName: 'batch_$i.png',
            fileSize: 1000 + i,
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
          );
          ids.add(id);

          // 为部分图片添加元数据
          if (i % 2 == 0) {
            final metadata = NaiImageMetadata(
              prompt: 'prompt for image $i',
              negativePrompt: '',
              seed: i,
            );
            await dataSource.upsertMetadata(id, metadata);
          }

          // 为部分图片添加收藏
          if (i % 3 == 0) {
            await dataSource.toggleFavorite(id);
          }

          // 为部分图片添加标签
          if (i % 4 == 0) {
            await dataSource.addTag(id, 'tag_$i');
          }
        }

        // 批量查询所有图片ID
        final idsResult = await dataSource.getImageIdsByPaths(paths);
        expect(idsResult.length, equals(50));
        for (final id in ids) {
          expect(idsResult.values, contains(id));
        }

        // 批量查询所有图片
        final imagesResult = await dataSource.getImagesByIds(ids);
        expect(imagesResult.length, equals(50));

        // 批量查询所有元数据
        final metaResult = await dataSource.getMetadataByImageIds(ids);
        expect(metaResult.length, equals(50));
        var metaCount = 0;
        for (var i = 0; i < 50; i++) {
          if (i % 2 == 0) {
            expect(metaResult[ids[i]], isNotNull);
            metaCount++;
          } else {
            expect(metaResult[ids[i]], isNull);
          }
        }
        expect(metaCount, equals(25));

        // 批量查询所有收藏
        final favsResult = await dataSource.getFavoritesByImageIds(ids);
        expect(favsResult.length, equals(50));
        for (var i = 0; i < 50; i++) {
          if (i % 3 == 0) {
            expect(favsResult[ids[i]], isTrue);
          } else {
            expect(favsResult[ids[i]], isFalse);
          }
        }

        // 批量查询所有标签
        final tagsResult = await dataSource.getTagsByImageIds(ids);
        expect(tagsResult.length, equals(50));

        // 批量删除一半图片
        final deletePaths = paths.sublist(0, 25);
        await dataSource.batchMarkAsDeleted(deletePaths);

        // 验证剩余数量
        final remainingCount = await dataSource.countImages();
        expect(remainingCount, equals(25));
      });
    });

    // ============================================================
    // 批量元数据 upsert 保留 is_nsfw（P0-3）
    // ============================================================

    group('batchUpsertMetadata preserves is_nsfw', () {
      test('REPLACE 批量覆盖不冲掉导入器写入的分级', () async {
        final id = await dataSource.upsertImage(
          filePath: '/test/nsfw_preserve.png',
          fileName: 'nsfw_preserve.png',
          fileSize: 1000,
          createdAt: DateTime(2026, 1, 1),
          modifiedAt: DateTime(2026, 1, 1),
        );

        // 先经导入路径写入 is_nsfw=1
        await dataSource.importTagIndexEntries([
          TagIndexImportEntry(
            filePath: '/test/nsfw_preserve.png',
            fileName: 'nsfw_preserve.png',
            fileSize: 1000,
            modifiedAt: DateTime(2026, 1, 1),
            nsfw: true,
          ),
        ]);

        // 批量元数据覆盖（NaiImageMetadata 不含分级语义）
        await dataSource.batchUpsertMetadata([
          MapEntry(
            id,
            const NaiImageMetadata(
              prompt: 'replaced by batch',
              negativePrompt: '',
              seed: 7,
            ),
          ),
        ]);

        final nsfwIds = await dataSource.advancedSearch(
          nsfwMode: 'nsfw',
          limit: 10,
        );
        expect(nsfwIds, contains(id));
      });
    });

    // ============================================================
    // advancedSearch 分块 + 候选路径限定（P0-5）
    // ============================================================

    group('advancedSearch chunking with candidate paths', () {
      test('文本候选超 IN 变量上限时分块并集，视图内全部命中', () async {
        // 1200 张图共享同一文本词：文本候选 1200 > 900 分块上限，
        // 修复前直接拼 IN 会触发 SQLite 变量上限（>900 就够验证分块路径）
        final now = DateTime(2026, 2, 1);
        final paths = [for (var i = 0; i < 1200; i++) '/test/chunk_$i.png'];
        final entries = <MapEntry<int, NaiImageMetadata>>[];
        for (var i = 0; i < 1200; i++) {
          final id = await dataSource.upsertImage(
            filePath: paths[i],
            fileName: 'chunk_$i.png',
            fileSize: 100 + i,
            createdAt: now,
            modifiedAt: now.add(Duration(minutes: i)),
          );
          entries.add(
            MapEntry(
              id,
              NaiImageMetadata(
                prompt: 'shared_chunk_word',
                negativePrompt: '',
                seed: i,
              ),
            ),
          );
        }
        await dataSource.batchUpsertMetadata(entries);

        // 视图=全部 1200 → 全部命中
        final allIds = await dataSource.advancedSearch(
          textQuery: 'shared_chunk_word',
          candidatePaths: paths,
          limit: 1200,
        );
        expect(allIds.length, 1200);

        // 视图=前 500 → 只返回视图内文件（源外候选被求交剔除）
        final subset = paths.sublist(0, 500);
        final subsetIds = await dataSource.advancedSearch(
          textQuery: 'shared_chunk_word',
          candidatePaths: subset,
          limit: 1200,
        );
        expect(subsetIds.length, 500);
      });

      test('无文本查询：路径分块限定 + 视图外残留行不占 LIMIT 名额', () async {
        // 1500 张匹配图，其中视图外 500 张修改时间更新：
        // 修复前 SQL LIMIT 会被视图外行占满，真实文件被挤掉
        final now = DateTime(2026, 3, 1);
        final inViewPaths = [
          for (var i = 0; i < 1000; i++) '/test/residual_in_$i.png',
        ];
        final outViewPaths = [
          for (var i = 0; i < 500; i++) '/test/residual_out_$i.png',
        ];
        final entries = <MapEntry<int, NaiImageMetadata>>[];
        for (var i = 0; i < 1000; i++) {
          final id = await dataSource.upsertImage(
            filePath: inViewPaths[i],
            fileName: 'residual_in_$i.png',
            fileSize: 100 + i,
            createdAt: now,
            modifiedAt: now.add(Duration(minutes: i)),
          );
          entries.add(
            MapEntry(
              id,
              NaiImageMetadata(
                prompt: 'residual_stale_word',
                negativePrompt: '',
                seed: i,
              ),
            ),
          );
        }
        // 视图外：修改时间更晚（会先排进 LIMIT）
        for (var i = 0; i < 500; i++) {
          final id = await dataSource.upsertImage(
            filePath: outViewPaths[i],
            fileName: 'residual_out_$i.png',
            fileSize: 100 + i,
            createdAt: now,
            modifiedAt: now
                .add(const Duration(days: 10))
                .add(Duration(minutes: i)),
          );
          entries.add(
            MapEntry(
              id,
              NaiImageMetadata(
                prompt: 'residual_stale_word',
                negativePrompt: '',
                seed: 1000 + i,
              ),
            ),
          );
        }
        await dataSource.batchUpsertMetadata(entries);

        final viewIds = await dataSource.advancedSearch(
          textQuery: 'residual_stale_word',
          candidatePaths: inViewPaths,
          limit: 1000,
        );

        // 必须全部来自视图内文件（修复前只剩 500）
        expect(viewIds.length, 1000);
        final viewIdSet = (await dataSource.getImageIdsByPaths(
          inViewPaths,
        )).values.whereType<int>().toSet();
        expect(viewIds.every(viewIdSet.contains), isTrue);
      });

      test('无文本搜索：宽度过滤 + 路径分块（800/块）同样只在视图内生效', () async {
        final now = DateTime(2026, 4, 1);
        final paths = [for (var i = 0; i < 1200; i++) '/test/width_$i.png'];
        for (var i = 0; i < 1200; i++) {
          await dataSource.upsertImage(
            filePath: paths[i],
            fileName: 'width_$i.png',
            fileSize: 100 + i,
            width: i < 700 ? 200 : 50,
            height: 100,
            createdAt: now,
            modifiedAt: now,
          );
        }

        final ids = await dataSource.advancedSearch(
          minWidth: 100,
          candidatePaths: paths,
          limit: 1200,
        );
        expect(ids.length, 700);

        // 视图收窄到前 400 张（全是宽图）→ 只返回视图内
        final subset = paths.sublist(0, 400);
        final subsetIds = await dataSource.advancedSearch(
          minWidth: 100,
          candidatePaths: subset,
          limit: 1200,
        );
        expect(subsetIds.length, 400);
      });
    });
  });
}
