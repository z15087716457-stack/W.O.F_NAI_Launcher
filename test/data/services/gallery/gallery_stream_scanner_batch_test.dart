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
import 'package:nai_launcher/data/services/gallery/gallery_stream_scanner.dart';
import 'package:nai_launcher/data/services/gallery/tag_index_import_service.dart';
import 'package:nai_launcher/data/services/image_metadata_service.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';

/// 扫描器批处理 + 导入先行回归测试
///
/// 覆盖线上事故修复：
/// 1. 导入后的记录（imported 状态 + size/mtime 签名匹配）扫描时全 skip，
///    不触发任何元数据解析（UI 卡死根因防护）
/// 2. DB 写入批量刷盘（flushBatchSize 注入小值验证批边界）记录数正确
/// 3. 移动/重命名路径保持单写正确
/// 4. 导入进行中扫描器拒绝启动（导入先行保护）
void main() {
  group('GalleryStreamScanner batch & import-first', () {
    late GalleryDataSource dataSource;
    late Directory tempDir;
    late String testDbPath;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'gallery_stream_scanner_batch_',
      );
      testDbPath = p.join(tempDir.path, 'gallery_batch.db');
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
      ImageMetadataService().resetStatistics();
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

    test('导入后的记录扫描全 skip，不触发元数据解析', () async {
      // 真实存在的普通 PNG（无 NAI 元数据）
      final pngPath = p.join(tempDir.path, 'imported.png');
      final pngBytes = _buildBasePngBytes();
      await File(pngPath).writeAsBytes(pngBytes);
      final stat = await File(pngPath).stat();

      // JSONL 导入：size/mtime 与实际文件一致（签名匹配 → 扫描 skip）
      final jsonlPath = p.join(tempDir.path, 'index.jsonl');
      await File(jsonlPath).writeAsString(
        '${jsonEncode({
          'path': pngPath,
          'name': 'imported.png',
          'size': stat.size,
          'mtime': stat.modified.millisecondsSinceEpoch ~/ 1000,
          'prompt': 'imported_prompt',
          'tags': ['imported_tag'],
        })}\n',
      );

      final importResult = await TagIndexImportService(
        dataSource,
      ).importFromJsonl(jsonlPath, rootPaths: [tempDir.path]);
      expect(importResult.imported, 1);

      final imageId = (await dataSource.getImageIdByPath(pngPath))!;
      final record = await dataSource.getImageById(imageId);
      expect(record!.metadataStatus, MetadataStatus.imported);

      // 扫描前解析计数归零（ImageMetadataService 单例可能被其他测试用过）
      ImageMetadataService().resetStatistics();

      final scanner = GalleryStreamScanner(dataSource: dataSource);
      StreamScanStats? lastStats;
      final statsSub = scanner.statsStream.listen((stats) => lastStats = stats);
      await scanner.startScanning([tempDir]);
      // 非 sync 广播流事件异步投递，等一拍再断言最终统计
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await statsSub.cancel();

      // 全 skip：processed=0, skipped=1
      expect(lastStats, isNotNull);
      expect(lastStats!.processed, 0);
      expect(lastStats!.skipped, 1);

      // 未触发任何解析（UI 卡死根因：隔离解析 + 签名快进的双保险）
      expect(ImageMetadataService().parseStatistics.totalParseCount, 0);

      // 记录保持 imported 状态，元数据/标签未被扫描冲刷
      final afterRecord = await dataSource.getImageById(imageId);
      expect(afterRecord!.metadataStatus, MetadataStatus.imported);
      final tags = await dataSource.getImageTags(imageId);
      expect(tags, contains('imported_tag'));
    });

    test('批量刷盘正确性：N 个文件分批落库，记录/元数据/状态完整', () async {
      const fileCount = 5;
      for (var i = 0; i < fileCount; i++) {
        await _createWrappedNovelAiPng(
          tempDir,
          'batch_$i.png',
          prompt: 'artist:batchtest$i, 1girl, solo',
        );
      }

      // flushBatchSize=2：5 个文件跨 3 批刷盘
      GalleryStreamScanner.resetInstance();
      final scanner = GalleryStreamScanner(
        dataSource: dataSource,
        flushBatchSize: 2,
      );

      StreamScanStats? lastStats;
      final statsSub = scanner.statsStream.listen((stats) => lastStats = stats);
      await scanner.startScanning([tempDir]);
      // 非 sync 广播流事件异步投递，等一拍再断言最终统计
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await statsSub.cancel();

      expect(lastStats, isNotNull);
      expect(lastStats!.processed, fileCount);
      expect(lastStats!.skipped, 0);

      // 记录数正确 + 全部解析成功
      expect(await dataSource.countImages(), fileCount);
      final records = await dataSource.getAllImages();
      expect(records.length, fileCount);
      for (final record in records) {
        expect(record.metadataStatus, MetadataStatus.success);
        // 批处理必须写入 last_scanned_at，否则下次扫描会全量重扫
        expect(record.lastScannedAt, isNotNull);
      }

      // 元数据 + FTS 落库
      final ids = records.map((r) => r.id!).toList();
      final metadataMap = await dataSource.getMetadataByImageIds(ids);
      for (final id in ids) {
        final metadata = metadataMap[id];
        expect(metadata, isNotNull);
        expect(metadata!.prompt, contains('artist:batchtest'));
      }

      final searchIds = await dataSource.searchFullText(
        'batchtest3',
        limit: 10,
      );
      expect(searchIds, isNotEmpty);
    });

    test('移动/重命名路径保持单写正确（updateFilePath 路径）', () async {
      final fileA = await _createWrappedNovelAiPng(
        tempDir,
        'move_a.png',
        prompt: 'artist:mover, 1girl',
      );

      GalleryStreamScanner.resetInstance();
      var scanner = GalleryStreamScanner(dataSource: dataSource);
      await scanner.startScanning([tempDir]);

      final imageId = await dataSource.getImageIdByPath(fileA.path);
      expect(imageId, isNotNull);

      // 重命名文件，再扫描：应检测到移动并更新路径（不新增记录）
      final renamedPath = p.join(tempDir.path, 'move_a2.png');
      await fileA.rename(renamedPath);

      scanner = GalleryStreamScanner(dataSource: dataSource);
      await scanner.startScanning([tempDir]);

      expect(await dataSource.getImageIdByPath(renamedPath), isNotNull);
      expect(await dataSource.getImageIdByPath(fileA.path), isNull);
      expect(await dataSource.countImages(), 1);
      // 路径更新后记录可检索
      final movedId = (await dataSource.getImageIdByPath(renamedPath))!;
      expect(movedId, imageId);
    });

    test('防劫持：同签名副本入库不抢原 id（原记录路径/id 不变、副本成新记录）', () async {
      final fileA = await _createWrappedNovelAiPng(
        tempDir,
        'original.png',
        prompt: 'artist:original, 1girl',
      );

      GalleryStreamScanner.resetInstance();
      var scanner = GalleryStreamScanner(dataSource: dataSource);
      await scanner.startScanning([tempDir]);

      final originalId = await dataSource.getImageIdByPath(fileA.path);
      expect(originalId, isNotNull);

      // 复制一个同签名副本（保持相同的 size 和 mtime，且原文件仍然存在）
      final copyPath = p.join(tempDir.path, 'copy.png');
      final copyFile = await fileA.copy(copyPath);
      final mtime = await fileA.lastModified();
      await copyFile.setLastModified(mtime);

      // 再次扫描：由于原文件仍然存在，不应判定为移动，而是作为新文件入库
      scanner = GalleryStreamScanner(dataSource: dataSource);
      await scanner.startScanning([tempDir]);

      // 原图依然存在，id 不变
      final afterOriginalId = await dataSource.getImageIdByPath(fileA.path);
      expect(afterOriginalId, equals(originalId));

      // 副本作为新记录入库，拥有不同的 id
      final copyId = await dataSource.getImageIdByPath(copyPath);
      expect(copyId, isNotNull);
      expect(copyId, isNot(equals(originalId)));

      // 总记录数为 2
      expect(await dataSource.countImages(), 2);
    });

    test('导入进行中扫描器拒绝启动（导入先行保护）', () async {
      await _createWrappedNovelAiPng(
        tempDir,
        'guard.png',
        prompt: 'artist:guard, 1girl',
      );

      // 模拟导入中状态
      TagIndexImportService.isImporting = true;
      addTearDown(() => TagIndexImportService.isImporting = false);

      final scanner = GalleryStreamScanner(dataSource: dataSource);
      await scanner.startScanning([tempDir]);

      // 扫描被拒绝：无任何记录入库
      expect(await dataSource.countImages(), 0);
    });
  });
}

Future<File> _createWrappedNovelAiPng(
  Directory dir,
  String fileName, {
  required String prompt,
}) async {
  final innerComment = jsonEncode({
    'prompt': prompt,
    'uc': 'lowres, blurry',
    'seed': 42,
    'sampler': 'k_euler',
    'steps': 28,
    'scale': 6.5,
    'width': 64,
    'height': 64,
    'version': 1,
  });

  final outerComment = jsonEncode({
    'Description': prompt,
    'Software': 'NovelAI',
    'Source': 'NovelAI Diffusion V4.5 4BDE2A90',
    'Comment': innerComment,
  });

  var bytes = _buildBasePngBytes();
  bytes = UnifiedMetadataParser.embedTextChunkOnly(
    bytes,
    'Title',
    'NovelAI generated image',
  );
  bytes = UnifiedMetadataParser.embedTextChunkOnly(
    bytes,
    'Description',
    prompt,
  );
  bytes = UnifiedMetadataParser.embedTextChunkOnly(
    bytes,
    'Software',
    'NovelAI',
  );
  bytes = UnifiedMetadataParser.embedTextChunkOnly(
    bytes,
    'Source',
    'NovelAI Diffusion V4.5 4BDE2A90',
  );
  bytes = UnifiedMetadataParser.embedTextChunkOnly(
    bytes,
    'Comment',
    outerComment,
  );

  final file = File(p.join(dir.path, fileName));
  await file.writeAsBytes(bytes);
  return file;
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
