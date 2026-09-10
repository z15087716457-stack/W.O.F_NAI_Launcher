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
import 'package:nai_launcher/data/services/image_metadata_service.dart';

/// 扫描一致性（P4 孤儿判定差集化）回归
///
/// 覆盖：
/// 1. 真孤儿（DB 有记录、文件已不存在）→ 扫描后标删；
/// 2. 遍历未见但文件仍在盘上（如扩展名不在扫描白名单）→ 不误标；
/// 3. 正常记录（遍历可见）→ 不标删且保持 skip；
/// 4. 已配置源之外的记录 → 一律不动（源移除保护语义不变）。
void main() {
  group('GalleryStreamScanner data consistency (P4 diff-set)', () {
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
        'gallery_stream_scanner_consistency_',
      );
      testDbPath = p.join(tempDir.path, 'gallery_consistency.db');
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

    test('真孤儿（记录在、文件不在）扫描后标记删除', () async {
      final goneFile = File(p.join(tempDir.path, 'gone.png'));
      await goneFile.writeAsBytes(_buildBasePngBytes());
      final goneId = await _seedRecord(dataSource, goneFile);
      // 文件被外部删除（模拟移出/手删），DB 记录仍在
      await goneFile.delete();

      final scanner = GalleryStreamScanner(dataSource: dataSource);
      await scanner.startScanning([tempDir]);

      final record = await dataSource.getImageById(goneId);
      expect(record, isNull, reason: '孤儿记录应被 batchMarkAsDeleted（is_deleted=1）');
    });

    test('遍历未见但文件仍在盘上（扩展名不在白名单）不误标', () async {
      // .txt 不被扫描白名单收录 → 目录遍历全集不含它；
      // 差集候选逐个 exists 确认时必须命中并放行（遍历截断容忍）
      final noteFile = File(p.join(tempDir.path, 'note.txt'));
      await noteFile.writeAsString('still here');
      final noteId = await _seedRecord(dataSource, noteFile);

      final scanner = GalleryStreamScanner(dataSource: dataSource);
      await scanner.startScanning([tempDir]);

      final record = await dataSource.getImageById(noteId);
      expect(record, isNotNull, reason: '文件仍存在，不得误标删除');
      expect(record!.isDeleted, isFalse);
    });

    test('正常记录（遍历可见）不标删且保持 skip', () async {
      final file = File(p.join(tempDir.path, 'normal.png'));
      await file.writeAsBytes(_buildBasePngBytes());
      final id = await _seedRecord(dataSource, file);

      final scanner = GalleryStreamScanner(dataSource: dataSource);
      StreamScanStats? lastStats;
      final sub = scanner.statsStream.listen((stats) => lastStats = stats);
      await scanner.startScanning([tempDir]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      final record = await dataSource.getImageById(id);
      expect(record, isNotNull);
      expect(record!.isDeleted, isFalse);
      expect(lastStats?.processed, 0);
      expect(lastStats?.skipped, 1);
    });

    test('已配置源之外的记录不动（源移除保护）', () async {
      // 记录路径在另一个目录（不在本次扫描 roots 内），文件同样不存在
      final outsideDir = await Directory.systemTemp.createTemp(
        'gallery_outside_',
      );
      addTearDown(() async {
        if (await outsideDir.exists()) {
          await _deleteDirectoryWithRetry(outsideDir);
        }
      });
      final outsidePath = p.join(outsideDir.path, 'outside.png');
      final outsideId = await dataSource.upsertImage(
        filePath: outsidePath,
        fileName: 'outside.png',
        fileSize: 123,
        createdAt: DateTime(2026, 1, 1),
        modifiedAt: DateTime(2026, 1, 1),
        metadataStatus: MetadataStatus.success,
        lastScannedAt: DateTime(2026, 1, 1),
      );

      final scanner = GalleryStreamScanner(dataSource: dataSource);
      await scanner.startScanning([tempDir]);

      final record = await dataSource.getImageById(outsideId);
      expect(record, isNotNull, reason: '源外记录不受一致性检查影响');
      expect(record!.isDeleted, isFalse);
    });
  });
}

Future<int> _seedRecord(GalleryDataSource dataSource, File file) async {
  final stat = await file.stat();
  return dataSource.upsertImage(
    filePath: file.path,
    fileName: p.basename(file.path),
    fileSize: stat.size,
    createdAt: stat.modified,
    modifiedAt: stat.modified,
    metadataStatus: MetadataStatus.success,
    lastScannedAt: DateTime.now(),
  );
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
