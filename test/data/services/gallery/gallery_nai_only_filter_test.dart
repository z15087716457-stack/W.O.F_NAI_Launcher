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

    test('naiOnly excludes WebUI/A1111 parameter images', () async {
      await addImage('/n/webui.png');
      final id = (await dataSource.getImageIdByPath('/n/webui.png'))!;
      await dataSource.upsertMetadata(
        id,
        const NaiImageMetadata(
          prompt: '1girl',
          seed: 401227857,
          sampler: 'Euler',
          steps: 50,
          scale: 5.0,
          model: '3c1868387a',
          software: 'Stable Diffusion WebUI',
          rawJson: '1girl\nNegative prompt: lowres\nSteps: 50, Sampler: Euler',
        ),
      );

      final result = await filterService.applyFilters(
        allFiles(['/n/webui.png']),
        const FilterCriteria(naiOnly: true),
      );

      expect(result.files, isEmpty);
    });

    test(
      'naiOnly keeps stealth NAI images without software fingerprint',
      () async {
        await addImage('/n/stealth.png');
        final id = (await dataSource.getImageIdByPath('/n/stealth.png'))!;
        await dataSource.upsertMetadata(
          id,
          const NaiImageMetadata(
            prompt: '1girl',
            seed: 123,
            rawJson:
                '{"prompt":"1girl","uc":"lowres","ucPreset":0,'
                '"request_type":"TextToImageRequest","noise_schedule":"karras"}',
          ),
        );

        final result = await filterService.applyFilters(
          allFiles(['/n/stealth.png']),
          const FilterCriteria(naiOnly: true),
        );

        expect(result.files.map((f) => f.path).toSet(), {'/n/stealth.png'});
      },
    );

    test('naiOnly keeps official downloads by NovelAI software tag', () async {
      await addImage('/n/official.png');
      final id = (await dataSource.getImageIdByPath('/n/official.png'))!;
      await dataSource.upsertMetadata(
        id,
        const NaiImageMetadata(prompt: '1girl', software: 'NovelAI'),
      );

      final result = await filterService.applyFilters(
        allFiles(['/n/official.png']),
        const FilterCriteria(naiOnly: true),
      );

      expect(result.files.map((f) => f.path).toSet(), {'/n/official.png'});
    });

    test(
      'backfillModelColumn fills model from V5 source fingerprint',
      () async {
        await addImage('/n/v5_src.png');
        final id = (await dataSource.getImageIdByPath('/n/v5_src.png'))!;
        await dataSource.upsertMetadata(
          id,
          const NaiImageMetadata(
            prompt: '1girl',
            source: 'NovelAI Diffusion V5 0ADF9AB7',
            software: 'NovelAI',
          ),
        );

        final updated = await dataSource.backfillModelColumn();
        expect(updated, greaterThanOrEqualTo(1));

        final result = await filterService.applyFilters(
          allFiles(['/n/v5_src.png']),
          const FilterCriteria(filterModels: ['nai-diffusion-5-full']),
        );
        expect(result.files.map((f) => f.path).toSet(), {'/n/v5_src.png'});
      },
    );

    test('backfillModelColumn fills model from V5 params envelope', () async {
      await addImage('/n/v5_params.png');
      final id = (await dataSource.getImageIdByPath('/n/v5_params.png'))!;
      await dataSource.upsertMetadata(
        id,
        const NaiImageMetadata(
          prompt: '1girl',
          rawJson:
              '{"description":"d","software":"NovelAI",'
              '"params":{"prompt":"1girl","seed":1,'
              '"model_name":"NovelAI Diffusion V5",'
              '"model_hash":"0ADF9AB7","version":1}}',
        ),
      );

      await dataSource.backfillModelColumn();

      final result = await filterService.applyFilters(
        allFiles(['/n/v5_params.png']),
        const FilterCriteria(filterModels: ['nai-diffusion-5-full']),
      );
      expect(result.files.map((f) => f.path).toSet(), {'/n/v5_params.png'});
    });

    test('backfillModelColumn leaves underivable rows untouched', () async {
      await addImage('/n/stealth45.png');
      final id = (await dataSource.getImageIdByPath('/n/stealth45.png'))!;
      await dataSource.upsertMetadata(
        id,
        const NaiImageMetadata(
          prompt: '1girl',
          rawJson: '{"prompt":"1girl","uc":"lowres","seed":1}',
        ),
      );

      await dataSource.backfillModelColumn();

      final result = await filterService.applyFilters(
        allFiles(['/n/stealth45.png']),
        const FilterCriteria(filterModels: ['nai-diffusion-4-5-full']),
      );
      expect(result.files, isEmpty);
    });

    test(
      'backfillModelColumn fills model from software-column fingerprint',
      () async {
        // 转存件把 Source 指纹写进 software 列（EXIF 工具链），也要能回填
        await addImage('/n/v3_sw.png');
        final id = (await dataSource.getImageIdByPath('/n/v3_sw.png'))!;
        await dataSource.upsertMetadata(
          id,
          const NaiImageMetadata(
            prompt: '1girl',
            software: 'Stable Diffusion XL 7BCCAA2C',
          ),
        );

        await dataSource.backfillModelColumn();

        final result = await filterService.applyFilters(
          allFiles(['/n/v3_sw.png']),
          const FilterCriteria(filterModels: ['nai-diffusion-3']),
        );
        expect(result.files.map((f) => f.path).toSet(), {'/n/v3_sw.png'});
      },
    );

    test(
      'backfillModelColumn defaults unknown V4/V4.5 hashes to Full',
      () async {
        await addImage('/n/v4_hash.png');
        final id = (await dataSource.getImageIdByPath('/n/v4_hash.png'))!;
        await dataSource.upsertMetadata(
          id,
          const NaiImageMetadata(
            prompt: '1girl',
            source: 'NovelAI Diffusion V4 37442FCA',
            software: 'NovelAI',
          ),
        );
        await addImage('/n/v45_hash.png');
        final id2 = (await dataSource.getImageIdByPath('/n/v45_hash.png'))!;
        await dataSource.upsertMetadata(
          id2,
          const NaiImageMetadata(
            prompt: '1girl',
            source: 'NovelAI Diffusion V4.5 1229B44F',
            software: 'NovelAI',
          ),
        );

        await dataSource.backfillModelColumn();

        final v4 = await filterService.applyFilters(
          allFiles(['/n/v4_hash.png']),
          const FilterCriteria(filterModels: ['nai-diffusion-4-full']),
        );
        final v45 = await filterService.applyFilters(
          allFiles(['/n/v45_hash.png']),
          const FilterCriteria(filterModels: ['nai-diffusion-4-5-full']),
        );
        expect(v4.files.map((f) => f.path).toSet(), {'/n/v4_hash.png'});
        expect(v45.files.map((f) => f.path).toSet(), {'/n/v45_hash.png'});
      },
    );

    test('backfillModelColumn fills model from nested tEXt envelope', () async {
      // 转存件把整张 tEXt 表序列化进单个 Comment 字段：source/software
      // 列为空，指纹在 raw_json 信封内层 Source 键
      await addImage('/n/v45_envelope.png');
      final id = (await dataSource.getImageIdByPath('/n/v45_envelope.png'))!;
      await dataSource.upsertMetadata(
        id,
        const NaiImageMetadata(
          prompt: '1girl',
          rawJson:
              '{"Description":"1girl","Software":"NovelAI",'
              '"Source":"NovelAI Diffusion V4.5 4BDE2A90",'
              '"Comment":"{\\"prompt\\":\\"1girl\\",\\"seed\\":1,'
              '\\"v4_prompt\\":{\\"caption\\":{\\"base_caption\\":\\"1girl\\"}}}"}',
        ),
      );

      await dataSource.backfillModelColumn();

      final result = await filterService.applyFilters(
        allFiles(['/n/v45_envelope.png']),
        const FilterCriteria(filterModels: ['nai-diffusion-4-5-full']),
      );
      expect(result.files.map((f) => f.path).toSet(), {'/n/v45_envelope.png'});
    });

    test(
      'backfillModelColumn fills V3 model from nested envelope SDXL hash',
      () async {
        await addImage('/n/v3_envelope.png');
        final id = (await dataSource.getImageIdByPath('/n/v3_envelope.png'))!;
        await dataSource.upsertMetadata(
          id,
          const NaiImageMetadata(
            prompt: '1girl',
            rawJson:
                '{"Description":"1girl","Software":"NovelAI",'
                '"Source":"Stable Diffusion XL 7BCCAA2C",'
                '"Comment":"{\\"prompt\\":\\"1girl\\",\\"seed\\":1,'
                '\\"signed_hash\\":\\"abc\\"}"}',
          ),
        );

        await dataSource.backfillModelColumn();

        final result = await filterService.applyFilters(
          allFiles(['/n/v3_envelope.png']),
          const FilterCriteria(filterModels: ['nai-diffusion-3']),
        );
        expect(result.files.map((f) => f.path).toSet(), {'/n/v3_envelope.png'});
      },
    );
  });
}
