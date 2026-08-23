import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';

/// 高级筛选元数据维度（model/sampler/resolution/方向/steps/cfg/NSFW）
/// 与候选查询、is_nsfw 列的单元测试
void main() {
  group('Gallery Metadata Filter Tests', () {
    late GalleryDataSource dataSource;
    late String testDbPath;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);

      final tempDir = Directory.systemTemp.createTempSync('gallery_meta_');
      testDbPath = '${tempDir.path}/metadata_filter.db';
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
    });

    tearDown(() async {
      await dataSource.dispose();
      await ConnectionPoolHolder.dispose();

      final dbFile = File(testDbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
    });

    final now = DateTime.now();

    Future<int> addImage(String path, {int? width, int? height}) async {
      return dataSource.upsertImage(
        filePath: path,
        fileName: path.split('/').last,
        fileSize: 1024,
        width: width,
        height: height,
        resolutionKey: (width != null && height != null)
            ? '${width}x$height'
            : null,
        createdAt: now,
        modifiedAt: now,
      );
    }

    Future<void> addMetadata(
      int imageId, {
      String? model,
      String? sampler,
      int? steps,
      double? scale,
    }) async {
      await dataSource.upsertMetadata(
        imageId,
        NaiImageMetadata(
          prompt: '1girl',
          model: model,
          sampler: sampler,
          steps: steps,
          scale: scale,
        ),
      );
    }

    // ============================================================
    // advancedSearch 元数据维度
    // ============================================================

    group('advancedSearch metadata filters', () {
      test('filters by model list (multi-select)', () async {
        final idA = await addImage('/test/m_a.png');
        final idB = await addImage('/test/m_b.png');
        final idC = await addImage('/test/m_c.png');
        await addMetadata(idA, model: 'nai-diffusion-3');
        await addMetadata(idB, model: 'nai-diffusion-4-full');
        await addMetadata(idC, model: 'nai-diffusion-5-full');

        final result = await dataSource.advancedSearch(
          models: ['nai-diffusion-3', 'nai-diffusion-4-full'],
          limit: 10,
        );

        expect(result.toSet(), {idA, idB});
      });

      test(
        'filters by sampler list and excludes images without metadata',
        () async {
          final idA = await addImage('/test/s_a.png');
          final idB = await addImage('/test/s_b.png');
          final idNoMeta = await addImage('/test/s_no_meta.png');
          await addMetadata(idA, sampler: 'k_euler');
          await addMetadata(idB, sampler: 'k_dpmpp_2m');

          final result = await dataSource.advancedSearch(
            samplers: ['k_euler'],
            limit: 10,
          );

          expect(result.toSet(), {idA});
          expect(result, isNot(contains(idNoMeta)));
        },
      );

      test('filters by resolution_key', () async {
        final idA = await addImage('/test/r_a.png', width: 832, height: 1216);
        final idB = await addImage('/test/r_b.png', width: 1216, height: 832);
        final idC = await addImage('/test/r_c.png', width: 1024, height: 1024);

        final result = await dataSource.advancedSearch(
          resolutions: ['832x1216', '1024x1024'],
          limit: 10,
        );

        expect(result.toSet(), {idA, idC});
        expect(result, isNot(contains(idB)));
      });

      test('filters by orientation (landscape/portrait/square)', () async {
        final landscape = await addImage(
          '/test/o_land.png',
          width: 1216,
          height: 832,
        );
        final portrait = await addImage(
          '/test/o_port.png',
          width: 832,
          height: 1216,
        );
        final square = await addImage(
          '/test/o_sq.png',
          width: 1024,
          height: 1024,
        );
        final noSize = await addImage('/test/o_no_size.png');

        final landscapeResult = await dataSource.advancedSearch(
          orientation: 'landscape',
          limit: 10,
        );
        expect(landscapeResult.toSet(), {landscape});

        final portraitResult = await dataSource.advancedSearch(
          orientation: 'portrait',
          limit: 10,
        );
        expect(portraitResult.toSet(), {portrait});

        final squareResult = await dataSource.advancedSearch(
          orientation: 'square',
          limit: 10,
        );
        expect(squareResult.toSet(), {square});

        // 无尺寸图片不落入任何方向
        expect(landscapeResult, isNot(contains(noSize)));
      });

      test('filters by steps range', () async {
        final idA = await addImage('/test/st_a.png');
        final idB = await addImage('/test/st_b.png');
        final idC = await addImage('/test/st_c.png');
        await addMetadata(idA, steps: 20);
        await addMetadata(idB, steps: 28);
        await addMetadata(idC, steps: 40);

        final minResult = await dataSource.advancedSearch(
          minSteps: 28,
          limit: 10,
        );
        expect(minResult.toSet(), {idB, idC});

        final maxResult = await dataSource.advancedSearch(
          maxSteps: 28,
          limit: 10,
        );
        expect(maxResult.toSet(), {idA, idB});

        final bothResult = await dataSource.advancedSearch(
          minSteps: 25,
          maxSteps: 30,
          limit: 10,
        );
        expect(bothResult.toSet(), {idB});
      });

      test('filters by cfg range', () async {
        final idA = await addImage('/test/c_a.png');
        final idB = await addImage('/test/c_b.png');
        final idC = await addImage('/test/c_c.png');
        await addMetadata(idA, scale: 5.0);
        await addMetadata(idB, scale: 7.5);
        await addMetadata(idC, scale: 10.0);

        final result = await dataSource.advancedSearch(
          minCfg: 6,
          maxCfg: 8,
          limit: 10,
        );

        expect(result.toSet(), {idB});
      });

      test('filters by nsfwMode', () async {
        final idA = await addImage('/test/n_a.png');
        final idB = await addImage('/test/n_b.png');
        final idNoMeta = await addImage('/test/n_no_meta.png');
        await addMetadata(idA, model: 'nai-diffusion-3');
        await addMetadata(idB, model: 'nai-diffusion-3');

        // 无公开写入 is_nsfw 的 API，走导入路径置位
        await dataSource.importTagIndexEntries([
          TagIndexImportEntry(
            filePath: '/test/n_b.png',
            fileName: 'n_b.png',
            fileSize: 1024,
            modifiedAt: now,
            nsfw: true,
          ),
        ]);

        final nsfwResult = await dataSource.advancedSearch(
          nsfwMode: 'nsfw',
          limit: 10,
        );
        expect(nsfwResult.toSet(), {idB});

        final sfwResult = await dataSource.advancedSearch(
          nsfwMode: 'sfw',
          limit: 10,
        );
        // 无 metadata 的行 COALESCE 为 0，也算 sfw
        expect(sfwResult.toSet(), {idA, idNoMeta});
      });

      test('combines metadata filters with text search', () async {
        final idA = await addImage('/test/x_combo_a.png');
        final idB = await addImage('/test/x_combo_b.png');
        await addMetadata(idA, model: 'nai-diffusion-3');
        await addMetadata(idB, model: 'nai-diffusion-4-full');

        final result = await dataSource.advancedSearch(
          textQuery: 'combo_a',
          models: ['nai-diffusion-3'],
          limit: 10,
        );

        expect(result.toSet(), {idA});
      });

      test('returns empty when no image matches', () async {
        final id = await addImage('/test/empty.png');
        await addMetadata(id, model: 'nai-diffusion-3');

        final result = await dataSource.advancedSearch(
          models: ['nai-diffusion-9-nonexistent'],
          limit: 10,
        );

        expect(result, isEmpty);
      });
    });

    // ============================================================
    // naiOnly（NAI-only）过滤
    // ============================================================

    group('naiOnly filter', () {
      test(
        'naiOnly keeps only images with metadata rows (has_metadata = 1)',
        () async {
          final idA = await addImage('/test/nai_a.png');
          final idB = await addImage('/test/nai_b.png');
          await addMetadata(idA, model: 'nai-diffusion-3');
          await addMetadata(idB, model: 'nai-diffusion-3');

          final result = await dataSource.advancedSearch(
            naiOnly: true,
            limit: 10,
          );

          expect(result.toSet(), {idA, idB});
        },
      );

      test('naiOnly excludes images without metadata', () async {
        final idA = await addImage('/test/nn_a.png');
        final idNoMeta = await addImage('/test/nn_no_meta.png');
        await addMetadata(idA, model: 'nai-diffusion-3');

        final result = await dataSource.advancedSearch(
          naiOnly: true,
          limit: 10,
        );

        expect(result.toSet(), {idA});
        expect(result, isNot(contains(idNoMeta)));
      });

      test('naiOnly combines with other metadata filters', () async {
        final idA = await addImage('/test/nc_a.png');
        final idB = await addImage('/test/nc_b.png');
        await addMetadata(idA, model: 'nai-diffusion-3');
        await addMetadata(idB, model: 'nai-diffusion-4-full');

        final result = await dataSource.advancedSearch(
          naiOnly: true,
          models: ['nai-diffusion-3'],
          limit: 10,
        );

        expect(result.toSet(), {idA});
      });

      test('naiOnly with text search keeps metadata rows only', () async {
        final idA = await addImage('/test/nt_keep.png');
        final idNoMeta = await addImage('/test/nt_drop.png');
        await addMetadata(idA, model: 'nai-diffusion-3');

        final result = await dataSource.advancedSearch(
          textQuery: 'nt_',
          naiOnly: true,
          limit: 10,
        );

        expect(result.toSet(), {idA});
        expect(result, isNot(contains(idNoMeta)));
      });

      test('getImageIdsWithMetadata returns has_metadata = 1 ids', () async {
        final idA = await addImage('/test/gm_a.png');
        final idB = await addImage('/test/gm_b.png');
        final idNoMeta = await addImage('/test/gm_no_meta.png');
        await addMetadata(idA, model: 'nai-diffusion-3');
        await addMetadata(idB, model: 'nai-diffusion-4-full');

        final ids = await dataSource.getImageIdsWithMetadata();

        expect(ids.toSet(), {idA, idB});
        expect(ids, isNot(contains(idNoMeta)));
      });
    });

    // ============================================================
    // 排序白名单（created_at / image_area）
    // ============================================================

    group('sort whitelist', () {
      test('orderByColumn created_at sorts by creation time', () async {
        final now = DateTime(2026, 8, 10);
        final oldImage = await dataSource.upsertImage(
          filePath: '/test/sort_old.png',
          fileName: 'sort_old.png',
          fileSize: 100,
          createdAt: now.subtract(const Duration(days: 2)),
          modifiedAt: now,
        );
        final newImage = await dataSource.upsertImage(
          filePath: '/test/sort_new.png',
          fileName: 'sort_new.png',
          fileSize: 100,
          createdAt: now,
          modifiedAt: now,
        );

        final byCreatedAsc = await dataSource.advancedSearch(
          orderByColumn: 'created_at',
          orderAscending: true,
          limit: 10,
        );
        expect(
          byCreatedAsc.indexOf(oldImage),
          lessThan(byCreatedAsc.indexOf(newImage)),
        );

        final byCreatedDesc = await dataSource.advancedSearch(
          orderByColumn: 'created_at',
          orderAscending: false,
          limit: 10,
        );
        expect(
          byCreatedDesc.indexOf(newImage),
          lessThan(byCreatedDesc.indexOf(oldImage)),
        );
      });

      test('orderByColumn image_area sorts by width×height area', () async {
        final small = await addImage(
          '/test/area_small.png',
          width: 512,
          height: 512,
        );
        final big = await addImage(
          '/test/area_big.png',
          width: 832,
          height: 1216,
        );

        final byAreaDesc = await dataSource.advancedSearch(
          orderByColumn: 'image_area',
          orderAscending: false,
          limit: 10,
        );
        expect(byAreaDesc.indexOf(big), lessThan(byAreaDesc.indexOf(small)));

        final byAreaAsc = await dataSource.advancedSearch(
          orderByColumn: 'image_area',
          orderAscending: true,
          limit: 10,
        );
        expect(byAreaAsc.indexOf(small), lessThan(byAreaAsc.indexOf(big)));
      });

      test(
        'unknown orderByColumn falls back to modified_at (injection guard)',
        () async {
          final result = await dataSource.advancedSearch(
            orderByColumn: 'file_name; DROP TABLE gallery_images',
            limit: 10,
          );

          // 白名单兜底后查询正常执行，不报错不注入
          expect(result, isA<List<int>>());
        },
      );
    });

    // ============================================================
    // 候选查询
    // ============================================================

    group('candidate queries', () {
      test('getDistinctModels returns values with counts, desc', () async {
        final idA = await addImage('/test/d_a.png');
        final idB = await addImage('/test/d_b.png');
        final idC = await addImage('/test/d_c.png');
        await addMetadata(idA, model: 'nai-diffusion-3');
        await addMetadata(idB, model: 'nai-diffusion-3');
        await addMetadata(idC, model: 'nai-diffusion-5-full');

        final candidates = await dataSource.getDistinctModels();

        expect(candidates.length, 2);
        expect(candidates.first.value, 'nai-diffusion-3');
        expect(candidates.first.count, 2);
        expect(candidates.last.value, 'nai-diffusion-5-full');
        expect(candidates.last.count, 1);
      });

      test('getDistinctSamplers returns values with counts', () async {
        final idA = await addImage('/test/ds_a.png');
        final idB = await addImage('/test/ds_b.png');
        await addMetadata(idA, sampler: 'k_euler');
        await addMetadata(idB, sampler: 'k_dpmpp_2m');

        final candidates = await dataSource.getDistinctSamplers();

        expect(candidates.map((c) => c.value).toSet(), {
          'k_euler',
          'k_dpmpp_2m',
        });
      });

      test('getDistinctResolutions reads images.resolution_key', () async {
        await addImage('/test/dr_a.png', width: 832, height: 1216);
        await addImage('/test/dr_b.png', width: 832, height: 1216);
        await addImage('/test/dr_c.png', width: 1024, height: 1024);

        final candidates = await dataSource.getDistinctResolutions();

        expect(candidates.first.value, '832x1216');
        expect(candidates.first.count, 2);
        expect(candidates.last.value, '1024x1024');
      });

      test('distinct candidates exclude soft-deleted images (P1-13)', () async {
        final idA = await addImage('/test/dd_a.png');
        final idB = await addImage('/test/dd_b.png');
        await addMetadata(idA, model: 'nai-diffusion-3');
        await addMetadata(idB, model: 'nai-diffusion-3');

        // 软删一张 → 计数与候选都应剔除
        await dataSource.markAsDeleted('/test/dd_b.png');

        final modelCandidates = await dataSource.getDistinctModels();
        expect(modelCandidates.first.value, 'nai-diffusion-3');
        expect(modelCandidates.first.count, 1);

        // 软删 resolution 行同样剔除
        await addImage('/test/dd_c.png', width: 832, height: 1216);
        await addImage('/test/dd_d.png', width: 832, height: 1216);
        await dataSource.markAsDeleted('/test/dd_d.png');
        final resCandidates = await dataSource.getDistinctResolutions();
        expect(resCandidates.first.value, '832x1216');
        expect(resCandidates.first.count, 1);
      });

      test(
        'autocompleteTags matches by usage_count and supports variants',
        () async {
          await addImage('/test/t_a.png');
          await addImage('/test/t_b.png');
          await addImage('/test/t_c.png');
          await addImage('/test/t_d.png');

          // 通过 getImageIdsByPaths 拿 id 后直接加标签
          for (final (path, tag) in [
            ('/test/t_a.png', 'blue_hair'),
            ('/test/t_b.png', 'blue_hair'),
            ('/test/t_c.png', 'blue_eyes'),
            ('/test/t_d.png', 'red_hair'),
          ]) {
            final imageId = await dataSource.getImageIdByPath(path);
            await dataSource.addTag(imageId!, tag);
          }

          // 下划线/空格变体互相命中（连续子串匹配）
          final underscore = await dataSource.autocompleteTags('blue_hair');
          expect(underscore, contains('blue_hair'));

          // 'blue' 命中两个标签，按 usage_count 降序：blue_hair(2) 在 blue_eyes(1) 前
          final generic = await dataSource.autocompleteTags('blue');
          expect(generic, containsAll(['blue_hair', 'blue_eyes']));
          expect(generic.first, 'blue_hair');
        },
      );

      test('autocompleteTags escapes LIKE wildcards', () async {
        final id = await addImage('/test/tw_a.png');
        final imageId = await dataSource.getImageIdByPath('/test/tw_a.png');
        await dataSource.addTag(imageId!, 'tag_100%_done');
        await dataSource.addTag(id, 'tag_100x_done');

        // '%' 被转义后不当作通配符：不命中 tag_100x_done
        final result = await dataSource.autocompleteTags('100%');
        expect(result, contains('tag_100%_done'));
        expect(result, isNot(contains('tag_100x_done')));
      });

      test('autocompleteTags returns empty for blank query', () async {
        expect(await dataSource.autocompleteTags('   '), isEmpty);
        expect(await dataSource.autocompleteTags(''), isEmpty);
      });
    });

    // ============================================================
    // is_nsfw 列
    // ============================================================

    group('is_nsfw column', () {
      test(
        'exists after initialization (migration for old databases)',
        () async {
          final tableInfo = await dataSource.execute(
            'test_table_info',
            (db) => db.rawQuery('PRAGMA table_info(gallery_metadata)'),
          );
          expect(tableInfo.map((col) => col['name']), contains('is_nsfw'));
        },
      );

      test('upsertMetadata preserves imported is_nsfw value', () async {
        await addImage('/test/np_a.png');
        final imageId = (await dataSource.getImageIdByPath('/test/np_a.png'))!;

        // 导入置位 NSFW
        await dataSource.importTagIndexEntries([
          TagIndexImportEntry(
            filePath: '/test/np_a.png',
            fileName: 'np_a.png',
            fileSize: 1024,
            modifiedAt: now,
            nsfw: true,
            model: 'nai-diffusion-3',
          ),
        ]);

        // 扫描路径 upsert 不应冲掉
        await dataSource.upsertMetadata(
          imageId,
          const NaiImageMetadata(prompt: '1girl'),
        );

        final nsfwResult = await dataSource.advancedSearch(
          nsfwMode: 'nsfw',
          limit: 10,
        );
        expect(nsfwResult, contains(imageId));
      });

      test('non-imported metadata defaults to sfw', () async {
        final id = await addImage('/test/nz_a.png');
        await addMetadata(id, model: 'nai-diffusion-3');

        final nsfwResult = await dataSource.advancedSearch(
          nsfwMode: 'nsfw',
          limit: 10,
        );
        expect(nsfwResult, isNot(contains(id)));
      });
    });
  });
}
