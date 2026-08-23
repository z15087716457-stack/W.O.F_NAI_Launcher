import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/services/gallery/gallery_delete_pool_store.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';

/// 删除池语义测试（真实 GalleryDataSource + LocalGalleryServiceImpl）：
///
/// - 软删：DB is_deleted=1 + 路径入池 + 内存列表即时移除
/// - 撤销：DB is_deleted=0 + 出池，refresh 后回到列表
/// - is_deleted=1 的文件仍在盘上时，refresh 不出现（复活防线）
void main() {
  group('delete pool semantics', () {
    late Directory tempDir;
    late Directory galleryRoot;
    late GalleryDataSource dataSource;
    late LocalGalleryServiceImpl service;
    late File fileA;
    late File fileB;
    late File fileC;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp(
        'nai_launcher_gallery_delete_',
      );
      galleryRoot = Directory(p.join(tempDir.path, 'gallery'));
      await galleryRoot.create(recursive: true);

      Hive.init(p.join(tempDir.path, 'hive'));
      await Hive.openBox(StorageKeys.settingsBox);
      await Hive.box(
        StorageKeys.settingsBox,
      ).put(StorageKeys.imageSavePath, galleryRoot.path);

      await ConnectionPoolHolder.initialize(
        dbPath: p.join(tempDir.path, 'gallery.db'),
        maxConnections: 2,
      );

      dataSource = GalleryDataSource();
      await dataSource.initialize();
      service = LocalGalleryServiceImpl(
        dataSource: dataSource,
        filterService: GalleryFilterService(dataSource),
      );

      fileA = File(p.join(galleryRoot.path, 'a.png'));
      await fileA.writeAsBytes(List.filled(200, 1));
      fileA.setLastModifiedSync(DateTime(2026, 8, 3, 10));

      fileB = File(p.join(galleryRoot.path, 'b.png'));
      await fileB.writeAsBytes(List.filled(100, 1));
      fileB.setLastModifiedSync(DateTime(2026, 8, 1, 10));

      fileC = File(p.join(galleryRoot.path, 'c.png'));
      await fileC.writeAsBytes(List.filled(50, 1));
      fileC.setLastModifiedSync(DateTime(2026, 8, 2, 10));

      // 先显式建 DB 行（后台扫描是异步的，测试需要确定性）。
      // 顺序必须在 initialize() 之前：此时 DB 行数与文件系统数一致，
      // chooseStartupIndexAction 判定无需扫描，后台扫描不会启动，
      // 避免测试的写操作与扫描抢 sqlite 写锁（全量并发跑时 flaky）。
      for (final entry in [
        (fileA, DateTime(2026, 8, 3, 10)),
        (fileB, DateTime(2026, 8, 1, 10)),
        (fileC, DateTime(2026, 8, 2, 10)),
      ]) {
        final file = entry.$1;
        await dataSource.upsertImage(
          filePath: file.path,
          fileName: p.basename(file.path),
          fileSize: await file.length(),
          width: 100,
          height: 100,
          createdAt: entry.$2,
          modifiedAt: entry.$2,
        );
      }

      await service.initialize();
    });

    tearDown(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await service.dispose();
      await dataSource.dispose();
      await ConnectionPoolHolder.dispose();
      await Hive.close();

      if (await tempDir.exists()) {
        await _deleteDirectoryWithRetry(tempDir);
      }
    });

    test('soft delete marks is_deleted=1 and pools the path', () async {
      // 删除动作的两个持久化半环：DB 软删标记 + 路径入池
      await dataSource.batchMarkAsDeleted([fileB.path]);
      await const GalleryDeletePoolStore().addAll([fileB.path]);

      expect(await dataSource.getImageIdByPath(fileB.path), isNull);
      final deletedPaths = await dataSource.getDeletedImagePaths();
      expect(deletedPaths, contains(fileB.path));

      final pool = await const GalleryDeletePoolStore().load();
      expect(pool, contains(fileB.path));
    });

    test('is_deleted=1 file still on disk does not reappear after refresh',
        () async {
      // 文件仍在盘上
      expect(await fileB.exists(), isTrue);
      expect(
        (await service.getPage(0, pageSize: 10)).map((r) => p.basename(r.path)),
        contains('b.png'),
      );

      // 软删（不删物理文件）
      await dataSource.batchMarkAsDeleted([fileB.path]);

      // refresh（含扫描路径）：b.png 不得复活
      await service.refresh(scan: false);
      var records = await service.getPage(0, pageSize: 10);
      expect(
        records.map((r) => p.basename(r.path)),
        isNot(contains('b.png')),
      );
      expect(service.totalCount, 2);

      // 完整刷新（走流式扫描器）：同样不得复活
      await service.refresh(scan: true);
      records = await service.getPage(0, pageSize: 10);
      expect(
        records.map((r) => p.basename(r.path)),
        isNot(contains('b.png')),
      );
      expect(service.totalCount, 2);
      // DB 软删标记未被扫描器复位
      expect(await dataSource.getImageIdByPath(fileB.path), isNull);
    });

    test('removeImagesFromMemory removes paths without rescan', () async {
      expect(service.totalCount, 3);

      service.removeImagesFromMemory([fileB.path]);

      final records = await service.getPage(0, pageSize: 10);
      expect(records.map((r) => p.basename(r.path)), isNot(contains('b.png')));
      expect(service.totalCount, 2);
      // 物理文件仍在盘上（删除推迟到下次启动）
      expect(await fileB.exists(), isTrue);
    });

    test('undo restores the record: unmark + pool removal, refresh brings back',
        () async {
      await dataSource.batchMarkAsDeleted([fileB.path]);
      await const GalleryDeletePoolStore().addAll([fileB.path]);
      service.removeImagesFromMemory([fileB.path]);
      expect(service.totalCount, 2);

      // 撤销：DB 恢复 + 出池
      await dataSource.batchRestoreDeleted([fileB.path]);
      await const GalleryDeletePoolStore().removeAll([fileB.path]);

      expect(await dataSource.getImageIdByPath(fileB.path), isNotNull);
      expect(await const GalleryDeletePoolStore().load(), isEmpty);

      await service.refresh(scan: false);
      final records = await service.getPage(0, pageSize: 10);
      expect(records.map((r) => p.basename(r.path)), contains('b.png'));
      expect(service.totalCount, 3);
    });
  });
}

Future<void> _deleteDirectoryWithRetry(Directory directory) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
      return;
    } on FileSystemException {
      if (attempt == 9) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}
