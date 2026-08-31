import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_stream_scanner.dart';
import 'package:nai_launcher/data/services/gallery/scan_config.dart'
    show ScanType;
import 'package:nai_launcher/data/services/gallery/scan_state_manager.dart';
import 'package:nai_launcher/data/services/gallery/tag_index_import_service.dart';
import 'package:nai_launcher/data/services/image_metadata_service.dart';

void main() {
  group('TagIndexImportService', () {
    late GalleryDataSource dataSource;
    late Directory tempDir;
    late String testDbPath;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tag_index_import_');
      testDbPath = p.join(tempDir.path, 'gallery_import.db');
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
        await _deleteDirectoryWithRetry(tempDir);
      }
    });

    test('导入创建图片记录/元数据/标签并同步 FTS', () async {
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
          'tags': ['1girl', 'solo', 'rating:nsfw'],
          'nsfw': true,
        })}\n',
      );

      final service = TagIndexImportService(dataSource);
      final result = await service.importFromJsonl(
        jsonlPath,
        rootPaths: [tempDir.path],
      );

      expect(result.totalLines, 1);
      expect(result.imported, 1);
      expect(result.updated, 0);
      expect(result.skipped, 0);
      expect(result.errors, 0);

      // 图片记录：imported 状态 + size/mtime/宽高
      final imageId = await dataSource.getImageIdByPath(pngPath);
      expect(imageId, isNotNull);
      final record = await dataSource.getImageById(imageId!);
      expect(record, isNotNull);
      expect(record!.metadataStatus, MetadataStatus.imported);
      expect(record.fileSize, 12345);
      expect(record.width, 832);
      expect(record.height, 1216);

      // 元数据
      final metadata = (await dataSource.getMetadataByImageIds([
        imageId,
      ]))[imageId];
      expect(metadata, isNotNull);
      expect(metadata!.prompt, '1girl, solo, masterpiece');
      expect(metadata.negativePrompt, 'lowres, blurry');
      expect(metadata.source, 'NovelAI Diffusion V4.5 4BDE2A90');
      expect(metadata.software, 'NovelAI');
      expect(metadata.seed, 123);
      expect(metadata.rawJson, contains('"path"'));
      expect(metadata.fullPromptText, contains('1girl, solo, masterpiece'));
      expect(metadata.fullPromptText, contains('lowres, blurry'));

      // 标签关联
      final tags = await dataSource.getImageTags(imageId);
      expect(tags, containsAll(['1girl', 'solo', 'rating:nsfw']));

      // FTS 同步
      final ftsIds = await dataSource.searchFullText('masterpiece', limit: 10);
      expect(ftsIds, contains(imageId));

      // tag chips 过滤链路（gallery_tags ∪ full_prompt_text）
      final tagFilterIds = await dataSource.searchByDelimitedTextSegments(
        ['1girl'],
        limit: 10,
        candidatePaths: [pngPath],
      );
      expect(tagFilterIds, contains(imageId));
    });

    test('重导幂等：更新计数、标签整表替换', () async {
      final pngPath = p.join(tempDir.path, 'b.png');
      final jsonlPath = p.join(tempDir.path, 'index.jsonl');

      final entry = <String, dynamic>{
        'path': pngPath,
        'name': 'b.png',
        'size': 999,
        'mtime': 1787469000,
        'prompt': '1girl, solo',
        'tags': ['1girl', 'solo'],
      };
      await File(jsonlPath).writeAsString('${jsonEncode(entry)}\n');

      final service = TagIndexImportService(dataSource);
      final first = await service.importFromJsonl(
        jsonlPath,
        rootPaths: [tempDir.path],
      );
      expect(first.imported, 1);
      expect(first.updated, 0);

      // 第二次导入：替换 prompt 与 tags
      entry['prompt'] = '2girls, group';
      entry['tags'] = ['2girls', 'group'];
      await File(jsonlPath).writeAsString('${jsonEncode(entry)}\n');

      final second = await service.importFromJsonl(
        jsonlPath,
        rootPaths: [tempDir.path],
      );
      expect(second.imported, 0);
      expect(second.updated, 1);

      final imageId = (await dataSource.getImageIdByPath(pngPath))!;
      final metadata = (await dataSource.getMetadataByImageIds([
        imageId,
      ]))[imageId];
      expect(metadata!.prompt, '2girls, group');

      final tags = await dataSource.getImageTags(imageId);
      expect(tags, containsAll(['2girls', 'group']));
      expect(tags, isNot(contains('1girl')));
      expect(tags, isNot(contains('solo')));
    });

    test('tag chips 过滤链路：selectedTags 命中导入的标签（画廊过滤服务）', () async {
      final pngPath = p.join(tempDir.path, 'chip.png');
      final jsonlPath = p.join(tempDir.path, 'index.jsonl');

      await File(jsonlPath).writeAsString(
        '${jsonEncode({
          'path': pngPath,
          'size': 10,
          'mtime': 1787469000,
          'prompt': 'a photo of a girl',
          'tags': ['blue_hair', 'solo'],
        })}\n',
      );

      final service = TagIndexImportService(dataSource);
      await service.importFromJsonl(jsonlPath, rootPaths: [tempDir.path]);

      final filterService = GalleryFilterService(dataSource);

      // chips 中选中的标签 → 交集过滤命中
      final hit = await filterService.applyFilters([
        File(pngPath),
      ], const FilterCriteria(selectedTags: ['blue_hair']));
      expect(hit.files.map((f) => f.path), contains(pngPath));

      // 未导入的标签 → 过滤为空
      final miss = await filterService.applyFilters([
        File(pngPath),
      ], const FilterCriteria(selectedTags: ['nonexistent_tag']));
      expect(miss.files, isEmpty);
    });

    test('源外路径/非图片/坏 JSON 行分别计跳过与错误', () async {
      final outsidePath = p.join(Directory.systemTemp.path, 'outside_x.png');
      final jsonlPath = p.join(tempDir.path, 'index.jsonl');

      final lines = [
        // 源外路径 → 跳过
        jsonEncode({'path': outsidePath, 'size': 1, 'mtime': 1787469000}),
        // 源内但非图片 → 跳过
        jsonEncode({
          'path': p.join(tempDir.path, 'note.txt'),
          'size': 1,
          'mtime': 1787469000,
        }),
        // 坏 JSON → 错误
        '{bad json',
        // 合法 → 导入
        jsonEncode({
          'path': p.join(tempDir.path, 'ok.png'),
          'size': 1,
          'mtime': 1787469000,
          'tags': ['solo'],
        }),
      ];
      await File(jsonlPath).writeAsString('${lines.join('\n')}\n');

      final service = TagIndexImportService(dataSource);
      final result = await service.importFromJsonl(
        jsonlPath,
        rootPaths: [tempDir.path],
      );

      expect(result.totalLines, 4);
      expect(result.imported, 1);
      expect(result.updated, 0);
      expect(result.skipped, 2);
      expect(result.errors, 1);
      expect(result.errorMessages, isNotEmpty);
    });

    test('扫描器不会冲刷已导入的元数据与标签（解析失败只改状态）', () async {
      // 真实存在的普通 PNG（无 NAI 元数据，扫描器解析会失败）
      final pngPath = p.join(tempDir.path, 'plain.png');
      final pngBytes = _buildBasePngBytes();
      await File(pngPath).writeAsBytes(pngBytes);

      // 索引里的 size 故意写错（与实际不符），强制扫描器重新解析该文件
      final jsonlPath = p.join(tempDir.path, 'index.jsonl');
      await File(jsonlPath).writeAsString(
        '${jsonEncode({
          'path': pngPath,
          'name': 'plain.png',
          'size': pngBytes.length + 100,
          'mtime': 1787469000,
          'prompt': 'imported_prompt_tag',
          'uc': 'imported_uc',
          'tags': ['imported_tag'],
        })}\n',
      );

      final service = TagIndexImportService(dataSource);
      final result = await service.importFromJsonl(
        jsonlPath,
        rootPaths: [tempDir.path],
      );
      expect(result.imported, 1);

      final imageId = (await dataSource.getImageIdByPath(pngPath))!;
      var metadata = (await dataSource.getMetadataByImageIds([
        imageId,
      ]))[imageId];
      expect(metadata!.prompt, 'imported_prompt_tag');

      // 扫描（普通 PNG 解析失败 → metadata_status 变为 failed）
      final scanner = GalleryStreamScanner(dataSource: dataSource);
      await scanner.startScanning([tempDir]);

      final record = await dataSource.getImageById(imageId);
      expect(record, isNotNull);
      expect(record!.metadataStatus, MetadataStatus.failed);
      // size 被扫描器校正为实际值
      expect(record.fileSize, pngBytes.length);

      // 已导入的元数据/标签/全文索引必须保留
      metadata = (await dataSource.getMetadataByImageIds([imageId]))[imageId];
      expect(metadata!.prompt, 'imported_prompt_tag');
      expect(metadata.fullPromptText, contains('imported_uc'));

      final tags = await dataSource.getImageTags(imageId);
      expect(tags, contains('imported_tag'));

      final ftsIds = await dataSource.searchFullText('imported', limit: 10);
      expect(ftsIds, contains(imageId));
    });

    test('JSONL 缺 mtime 时 stat 文件取真实时间；文件不存在则跳过该行', () async {
      // 真实 PNG（无 mtime 字段）→ created_at 用文件系统 mtime
      final pngPath = p.join(tempDir.path, 'no_mtime.png');
      final pngBytes = _buildBasePngBytes();
      await File(pngPath).writeAsBytes(pngBytes);
      final expectedStat = await File(pngPath).stat();

      final jsonlPath = p.join(tempDir.path, 'index.jsonl');
      await File(jsonlPath).writeAsString(
        '${jsonEncode({
          'path': pngPath,
          'size': pngBytes.length,
          // 无 mtime 字段
          'prompt': 'no_mtime_prompt',
        })}\n'
        // 不存在的文件 + 无 mtime → stat 失败 → 跳过
        '${jsonEncode({'path': p.join(tempDir.path, 'ghost.png'), 'size': 1, 'prompt': 'ghost'})}\n',
      );

      final service = TagIndexImportService(dataSource);
      final result = await service.importFromJsonl(
        jsonlPath,
        rootPaths: [tempDir.path],
      );

      expect(result.imported, 1);
      expect(result.skipped, 1);
      expect(result.errors, 0);

      // created_at 不再落 epoch 0（1970），而是文件真实 mtime
      final imageId = (await dataSource.getImageIdByPath(pngPath))!;
      final record = await dataSource.getImageById(imageId);
      expect(record, isNotNull);
      expect(
        record!.createdAt.millisecondsSinceEpoch,
        closeTo(expectedStat.modified.millisecondsSinceEpoch, 5000),
      );
    });

    test('扫描进行中拒绝导入并抛 BlockedByScan（双向防护）', () async {
      final scanManager = ScanStateManager.instance;
      final started = await scanManager.startScanAsync(
        type: ScanType.incremental,
        rootPath: tempDir.path,
      );
      expect(started, isTrue);

      try {
        final jsonlPath = p.join(tempDir.path, 'index.jsonl');
        await File(jsonlPath).writeAsString(
          '${jsonEncode({'path': p.join(tempDir.path, 'ok.png'), 'size': 1, 'mtime': 1787469000})}\n',
        );

        final service = TagIndexImportService(dataSource);
        await expectLater(
          service.importFromJsonl(jsonlPath, rootPaths: [tempDir.path]),
          throwsA(isA<TagIndexImportBlockedByScanException>()),
        );

        // 被拒后导入标志不被占用
        expect(TagIndexImportService.isImporting, isFalse);
      } finally {
        scanManager.completeScan();
      }
    });
  });
}

Uint8List _buildBasePngBytes() {
  final image = img.Image(width: 4, height: 4);
  img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));
  return Uint8List.fromList(img.encodePng(image));
}

Future<void> _deleteDirectoryWithRetry(
  Directory dir, {
  int maxAttempts = 5,
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await dir.delete(recursive: true);
      return;
    } on PathAccessException {
      if (attempt == maxAttempts) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}
