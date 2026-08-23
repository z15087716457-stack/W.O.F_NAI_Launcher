import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/services/gallery/gallery_stream_scanner.dart';
import 'package:nai_launcher/data/services/gallery/tag_index_import_service.dart';
import 'package:nai_launcher/data/services/image_metadata_service.dart';

/// JSONL 索引导入：生成参数（model/sampler/steps/cfg/nsfw）写入元数据的回归测试
void main() {
  group('TagIndexImport metadata fields', () {
    late GalleryDataSource dataSource;
    late Directory tempDir;
    late String testDbPath;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tag_index_meta_');
      testDbPath = p.join(tempDir.path, 'gallery_import_meta.db');
      final hivePath = p.join(tempDir.path, 'hive');
      await Directory(hivePath).create(recursive: true);
      Hive.init(hivePath);

      await ConnectionPoolHolder.initialize(
        dbPath: testDbPath,
        maxConnections: 2,
      );

      dataSource = GalleryDataSource();
      await dataSource.initialize();
      await ImageMetadataService().initialize();
      GalleryStreamScanner.resetInstance();
    });

    tearDown(() async {
      GalleryStreamScanner.resetInstance();
      await Hive.close();
      await dataSource.dispose();
      await ConnectionPoolHolder.dispose();

      if (await tempDir.exists()) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    });

    test('writes model/sampler/steps/cfg/nsfw from jsonl into metadata',
        () async {
      final pngPath = p.join(tempDir.path, 'a.png');
      final jsonlPath = p.join(tempDir.path, 'index.jsonl');

      await File(jsonlPath).writeAsString(
        '${jsonEncode({
          'path': pngPath,
          'name': 'a.png',
          'size': 12345,
          'mtime': 1787469000,
          'width': 832,
          'height': 1216,
          'source': 'NovelAI Diffusion V4.5 4BDE2A90',
          'software': 'NovelAI',
          'seed': 123,
          'prompt': '1girl, solo, masterpiece',
          'uc': 'lowres, blurry',
          'model': 'nai-diffusion-4-5-curated',
          'sampler': 'k_euler',
          'steps': 28,
          'cfg': 6.5,
          'noise_schedule': 'native',
          'tags': ['1girl', 'solo'],
          'nsfw': true,
        })}\n',
      );

      final service = TagIndexImportService(dataSource);
      final result = await service.importFromJsonl(
        jsonlPath,
        rootPaths: [tempDir.path],
      );

      expect(result.errors, 0);
      expect(result.imported, 1);

      final imageId = await dataSource.getImageIdByPath(pngPath);
      expect(imageId, isNotNull);

      final metadata =
          (await dataSource.getMetadataByImageIds([imageId!]))[imageId];
      expect(metadata, isNotNull);
      expect(metadata!.model, 'nai-diffusion-4-5-curated');
      expect(metadata.sampler, 'k_euler');
      expect(metadata.steps, 28);
      expect(metadata.scale, 6.5);
      expect(metadata.noiseSchedule, 'native');

      // fullPromptText 与扫描路径一致：追加 model/sampler/software/source
      expect(
        metadata.fullPromptText,
        contains('nai-diffusion-4-5-curated'),
      );
      expect(metadata.fullPromptText, contains('k_euler'));
      expect(metadata.fullPromptText, contains('NovelAI Diffusion V4.5'));
      expect(metadata.fullPromptText, contains('1girl, solo, masterpiece'));

      // is_nsfw 可被 advancedSearch 消费
      final nsfwIds = await dataSource.advancedSearch(
        nsfwMode: 'nsfw',
        limit: 10,
      );
      expect(nsfwIds, contains(imageId));

      final modelIds = await dataSource.advancedSearch(
        models: ['nai-diffusion-4-5-curated'],
        limit: 10,
      );
      expect(modelIds, contains(imageId));
    });

    test('missing optional keys stay null and default sfw', () async {
      final pngPath = p.join(tempDir.path, 'b.png');
      final jsonlPath = p.join(tempDir.path, 'index.jsonl');

      await File(jsonlPath).writeAsString(
        '${jsonEncode({
          'path': pngPath,
          'name': 'b.png',
          'size': 100,
          'mtime': 1787469000,
          'prompt': '1girl',
        })}\n',
      );

      final service = TagIndexImportService(dataSource);
      final result = await service.importFromJsonl(
        jsonlPath,
        rootPaths: [tempDir.path],
      );
      expect(result.errors, 0);

      final imageId = await dataSource.getImageIdByPath(pngPath);
      final metadata =
          (await dataSource.getMetadataByImageIds([imageId!]))[imageId];
      expect(metadata!.model, isNull);
      expect(metadata.sampler, isNull);
      expect(metadata.steps, isNull);

      final nsfwIds = await dataSource.advancedSearch(
        nsfwMode: 'sfw',
        limit: 10,
      );
      expect(nsfwIds, contains(imageId));
    });

    test('re-import without nsfw key preserves existing rating (三态)', () async {
      final pngPath = p.join(tempDir.path, 'c.png');
      final jsonlPath = p.join(tempDir.path, 'index.jsonl');
      final service = TagIndexImportService(dataSource);

      // 1. 首次导入带 nsfw: true
      await File(jsonlPath).writeAsString(
        '${jsonEncode({
          'path': pngPath,
          'size': 100,
          'mtime': 1787469000,
          'prompt': '1girl',
          'nsfw': true,
        })}\n',
      );
      await service.importFromJsonl(jsonlPath, rootPaths: [tempDir.path]);

      final imageId = (await dataSource.getImageIdByPath(pngPath))!;
      var nsfwIds = await dataSource.advancedSearch(
        nsfwMode: 'nsfw',
        limit: 10,
      );
      expect(nsfwIds, contains(imageId));

      // 2. 重导且 JSONL 无 nsfw 字段 → 保留已有分级（修复前落回 0）
      await File(jsonlPath).writeAsString(
        '${jsonEncode({
          'path': pngPath,
          'size': 100,
          'mtime': 1787469000,
          'prompt': '1girl, updated',
        })}\n',
      );
      final second = await service.importFromJsonl(
        jsonlPath,
        rootPaths: [tempDir.path],
      );
      expect(second.updated, 1);

      nsfwIds = await dataSource.advancedSearch(nsfwMode: 'nsfw', limit: 10);
      expect(nsfwIds, contains(imageId));
      final sfwIds = await dataSource.advancedSearch(
        nsfwMode: 'sfw',
        limit: 10,
      );
      expect(sfwIds, isNot(contains(imageId)));

      // 3. 显式 nsfw: false → 覆盖为 SFW
      await File(jsonlPath).writeAsString(
        '${jsonEncode({
          'path': pngPath,
          'size': 100,
          'mtime': 1787469000,
          'prompt': '1girl, final',
          'nsfw': false,
        })}\n',
      );
      await service.importFromJsonl(jsonlPath, rootPaths: [tempDir.path]);

      nsfwIds = await dataSource.advancedSearch(nsfwMode: 'nsfw', limit: 10);
      expect(nsfwIds, isNot(contains(imageId)));
    });
  });
}
