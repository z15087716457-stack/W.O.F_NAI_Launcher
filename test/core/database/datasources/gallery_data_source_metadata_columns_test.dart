import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';

/// P6 等价回归：网格页路径的列收窄查询。
///
/// - `includeFullPromptText: false` 与完整查询除 full_prompt_text 外逐字段一致
/// - `getFullPromptTextsByImageIds` 与完整查询的 full_prompt_text 逐行一致
void main() {
  group('GalleryDataSource metadata column narrowing', () {
    late GalleryDataSource dataSource;
    late String testDbPath;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);
      final tempDir = Directory.systemTemp.createTempSync('gallery_cols_');
      testDbPath = '${tempDir.path}/cols.db';
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
      try {
        final dbFile = File(testDbPath);
        if (await dbFile.exists()) {
          await dbFile.delete();
        }
      } catch (_) {}
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
      try {
        final dbFile = File(testDbPath);
        if (await dbFile.exists()) {
          await dbFile.delete();
        }
      } catch (_) {}
    });

    Future<int> seedImage(String name) => dataSource.upsertImage(
      filePath: '/cols/$name',
      fileName: name,
      fileSize: 1000,
      createdAt: DateTime(2026, 9, 10),
      modifiedAt: DateTime(2026, 9, 10),
    );

    test('窄查询与完整查询除 full_prompt_text 外逐字段一致', () async {
      final idWithout = await seedImage('without_raw.png');
      await dataSource.upsertMetadata(
        idWithout,
        const NaiImageMetadata(prompt: 'only prompt', negativePrompt: ''),
      );

      final idFull = await seedImage('full_raw.png');
      const rawJson =
          '{"Comment":"{\\"prompt\\":\\"a,b,c\\",\\"uc\\":\\"d\\",'
          '\\"steps\\":28,\\"seed\\":12345}","Software":"NovelAI"}';
      await dataSource.upsertMetadata(
        idFull,
        const NaiImageMetadata(
          prompt: 'a,b,c',
          negativePrompt: 'd',
          seed: 12345,
          sampler: 'k_euler_ancestral',
          steps: 28,
          scale: 7.5,
          width: 832,
          height: 1216,
          model: 'nai-diffusion-4-5-full',
          smea: true,
          smeaDyn: true,
          noiseSchedule: 'karras',
          cfgRescale: 0.0,
          ucPreset: 3,
          qualityToggle: true,
          isImg2Img: true,
          strength: 0.66,
          noise: 0.02,
          software: 'NovelAI',
          source: 'NovelAI',
          version: '4.5',
          rawJson: rawJson,
        ),
      );

      final full = await dataSource.getMetadataByImageIds([idWithout, idFull]);
      final slim = await dataSource.getMetadataByImageIds([
        idWithout,
        idFull,
      ], includeFullPromptText: false);

      expect(slim.keys, full.keys);
      for (final id in full.keys) {
        final f = full[id];
        final s = slim[id];
        if (f == null) {
          expect(s, isNull);
          continue;
        }
        expect(s!.imageId, f.imageId);
        expect(s.prompt, f.prompt);
        expect(s.negativePrompt, f.negativePrompt);
        expect(s.seed, f.seed);
        expect(s.sampler, f.sampler);
        expect(s.steps, f.steps);
        expect(s.scale, f.scale);
        expect(s.width, f.width);
        expect(s.height, f.height);
        expect(s.model, f.model);
        expect(s.smea, f.smea);
        expect(s.smeaDyn, f.smeaDyn);
        expect(s.noiseSchedule, f.noiseSchedule);
        expect(s.cfgRescale, f.cfgRescale);
        expect(s.ucPreset, f.ucPreset);
        expect(s.qualityToggle, f.qualityToggle);
        expect(s.isImg2Img, f.isImg2Img);
        expect(s.strength, f.strength);
        expect(s.noise, f.noise);
        expect(s.software, f.software);
        expect(s.source, f.source);
        expect(s.version, f.version);
        expect(s.rawJson, f.rawJson);
      }
      // 完整查询带 full_prompt_text，窄查询不带（页路径不消费该列）
      expect(full[idFull]!.fullPromptText, isNotEmpty);
      expect(slim[idFull]!.fullPromptText, isEmpty);
    });

    test('getFullPromptTextsByImageIds 与完整查询的该列逐行一致', () async {
      final ids = <int>[];
      for (var i = 0; i < 3; i++) {
        final id = await seedImage('p$i.png');
        await dataSource.upsertMetadata(
          id,
          NaiImageMetadata(
            prompt: 'prompt-$i with 角色' * (i + 1),
            negativePrompt: 'neg-$i',
            rawJson: '{"Comment":"{\\"prompt\\":\\"p$i\\"}"}',
          ),
        );
        ids.add(id);
      }
      final orphan = await seedImage('orphan.png');

      final full = await dataSource.getMetadataByImageIds([...ids, orphan]);
      final texts = await dataSource.getFullPromptTextsByImageIds([
        ...ids,
        orphan,
      ]);

      for (final id in ids) {
        expect(texts[id], full[id]!.fullPromptText);
        expect(texts[id], isNotEmpty);
      }
      // 无元数据的图不出现（与 getMetadataByImageIds 的 null 语义对齐）
      expect(texts.containsKey(orphan), isFalse);
    });

    test('空输入返回空映射（两条窄路径）', () async {
      expect(await dataSource.getFullPromptTextsByImageIds([]), isEmpty);
      expect(
        await dataSource.getMetadataByImageIds(
          [],
          includeFullPromptText: false,
        ),
        isEmpty,
      );
    });

    test('默认参数保持完整列（既有调用方零影响）', () async {
      final id = await seedImage('default.png');
      await dataSource.upsertMetadata(
        id,
        const NaiImageMetadata(
          prompt: 'keep full',
          negativePrompt: 'n',
          rawJson: '{"Comment":"{}"}',
        ),
      );

      final result = await dataSource.getMetadataByImageIds([id]);
      expect(result[id]!.fullPromptText, isNotEmpty);
    });
  });
}
