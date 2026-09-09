import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';

void main() {
  group('LocalGalleryService sort', () {
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
      tempDir = await Directory.systemTemp.createTemp(
        'nai_launcher_gallery_service_sort_',
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

      // b.png：修改时间最旧（8-01）、大小 100 字节
      fileB = File(p.join(galleryRoot.path, 'b.png'));
      await fileB.writeAsBytes(List.filled(100, 1));
      fileB.setLastModifiedSync(DateTime(2026, 8, 1, 10));

      // c.png：修改时间中间（8-02）、大小 50 字节
      fileC = File(p.join(galleryRoot.path, 'c.png'));
      await fileC.writeAsBytes(List.filled(50, 1));
      fileC.setLastModifiedSync(DateTime(2026, 8, 2, 10));

      // a.png：修改时间最新（8-03）、大小 200 字节
      fileA = File(p.join(galleryRoot.path, 'a.png'));
      await fileA.writeAsBytes(List.filled(200, 1));
      fileA.setLastModifiedSync(DateTime(2026, 8, 3, 10));

      await service.initialize();
    });

    tearDown(() async {
      // initialize() starts a tiny background scan; let it release sqlite locks.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await service.dispose();
      await dataSource.dispose();
      await ConnectionPoolHolder.dispose();
      await Hive.close();

      if (await tempDir.exists()) {
        await _deleteDirectoryWithRetry(tempDir);
      }
    });

    test('default order is modifiedAt descending (newest first)', () async {
      final records = await service.getPage(0, pageSize: 10);

      expect(records.map((record) => p.basename(record.path)), [
        'a.png',
        'c.png',
        'b.png',
      ]);
    });

    test('setSort by file name ascending reorders pages', () async {
      await service.setSort(
        const GallerySort(
          field: GallerySortField.fileName,
          direction: GallerySortDirection.ascending,
        ),
      );

      final records = await service.getPage(0, pageSize: 10);
      expect(records.map((record) => p.basename(record.path)), [
        'a.png',
        'b.png',
        'c.png',
      ]);
    });

    test('setSort by file name descending reverses pages', () async {
      await service.setSort(
        const GallerySort(
          field: GallerySortField.fileName,
          direction: GallerySortDirection.descending,
        ),
      );

      final records = await service.getPage(0, pageSize: 10);
      expect(records.map((record) => p.basename(record.path)), [
        'c.png',
        'b.png',
        'a.png',
      ]);
    });

    test('setSort by file size descending puts largest first', () async {
      await service.setSort(
        const GallerySort(
          field: GallerySortField.fileSize,
          direction: GallerySortDirection.descending,
        ),
      );

      final records = await service.getPage(0, pageSize: 10);
      expect(records.map((record) => record.size), [200, 100, 50]);
      expect(records.map((record) => p.basename(record.path)), [
        'a.png',
        'b.png',
        'c.png',
      ]);
    });

    test('filtered results honor the active sort', () async {
      await service.setSort(
        const GallerySort(
          field: GallerySortField.fileName,
          direction: GallerySortDirection.ascending,
        ),
      );

      // 日期过滤走本地内存路径；排序在过滤结果上同样生效
      await service.applyFilter(
        const FilterCriteria(dateStart: null, dateEnd: null),
      );
      await service.setDateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 2));

      final records = await service.getPage(0, pageSize: 10);
      expect(records.map((record) => p.basename(record.path)), [
        'b.png',
        'c.png',
      ]);
    });

    test('sort state survives filter changes', () async {
      await service.setSort(
        const GallerySort(
          field: GallerySortField.fileSize,
          direction: GallerySortDirection.ascending,
        ),
      );
      await service.setDateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 3));

      final records = await service.getPage(0, pageSize: 10);
      expect(records.map((record) => record.size), [50, 100, 200]);
      expect(records.map((record) => p.basename(record.path)), [
        'c.png',
        'b.png',
        'a.png',
      ]);
    });

    test(
      'setSort by image dimensions backfills area from DB records',
      () async {
        // 初始化时 _fileStats 全部以 area: 0 入缓存；等待后台扫描落库后，
        // 显式写入 width/height，再按尺寸排序——验证 _ensureFileStats 对
        // area==0 的既有条目也走 DB 补齐（修复前面积恒 0、比较器退化名序）。
        await Future<void>.delayed(const Duration(milliseconds: 600));

        // b.png: 100×100=10000 / c.png: 200×200=40000 / a.png: 300×300=90000
        await dataSource.upsertImage(
          filePath: fileB.path,
          fileName: 'b.png',
          fileSize: 100,
          width: 100,
          height: 100,
          createdAt: DateTime(2026, 8, 1, 10),
          modifiedAt: DateTime(2026, 8, 1, 10),
        );
        await dataSource.upsertImage(
          filePath: fileC.path,
          fileName: 'c.png',
          fileSize: 50,
          width: 200,
          height: 200,
          createdAt: DateTime(2026, 8, 2, 10),
          modifiedAt: DateTime(2026, 8, 2, 10),
        );
        await dataSource.upsertImage(
          filePath: fileA.path,
          fileName: 'a.png',
          fileSize: 200,
          width: 300,
          height: 300,
          createdAt: DateTime(2026, 8, 3, 10),
          modifiedAt: DateTime(2026, 8, 3, 10),
        );

        await service.setSort(
          const GallerySort(
            field: GallerySortField.imageDimensions,
            direction: GallerySortDirection.descending,
          ),
        );

        var records = await service.getPage(0, pageSize: 10);
        expect(records.map((record) => p.basename(record.path)), [
          'a.png',
          'c.png',
          'b.png',
        ]);

        await service.setSort(
          const GallerySort(
            field: GallerySortField.imageDimensions,
            direction: GallerySortDirection.ascending,
          ),
        );
        records = await service.getPage(0, pageSize: 10);
        expect(records.map((record) => p.basename(record.path)), [
          'b.png',
          'c.png',
          'a.png',
        ]);
      },
    );

    test(
      'non-dimension sort skips dimension query and sentinel prevents repeated query for null/zero dimensions',
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 600));

        // fileA: 300x300=90000; fileB: null 尺寸; fileC: 0 尺寸
        await dataSource.upsertImage(
          filePath: fileA.path,
          fileName: 'a.png',
          fileSize: 200,
          width: 300,
          height: 300,
          createdAt: DateTime(2026, 8, 3, 10),
          modifiedAt: DateTime(2026, 8, 3, 10),
        );
        await dataSource.upsertImage(
          filePath: fileB.path,
          fileName: 'b.png',
          fileSize: 100,
          width: null,
          height: null,
          createdAt: DateTime(2026, 8, 1, 10),
          modifiedAt: DateTime(2026, 8, 1, 10),
        );
        await dataSource.upsertImage(
          filePath: fileC.path,
          fileName: 'c.png',
          fileSize: 50,
          width: 0,
          height: 0,
          createdAt: DateTime(2026, 8, 2, 10),
          modifiedAt: DateTime(2026, 8, 2, 10),
        );

        // 1. 非尺寸排序（修改时间）：跳过尺寸补齐
        await service.setSort(
          const GallerySort(
            field: GallerySortField.modifiedAt,
            direction: GallerySortDirection.descending,
          ),
        );
        var records = await service.getPage(0, pageSize: 10);
        expect(records.map((r) => p.basename(r.path)), [
          'a.png',
          'c.png',
          'b.png',
        ]);

        // 2. 切换至尺寸排序：面积 90000 的 a.png 排最前，b 和 c 记为哨兵（视同 0）
        await service.setSort(
          const GallerySort(
            field: GallerySortField.imageDimensions,
            direction: GallerySortDirection.descending,
          ),
        );
        records = await service.getPage(0, pageSize: 10);
        expect(p.basename(records.first.path), 'a.png');

        // 3. 升序排序：a.png 应排最后，哨兵 b 和 c 仍视同 0 面积排在前面
        await service.setSort(
          const GallerySort(
            field: GallerySortField.imageDimensions,
            direction: GallerySortDirection.ascending,
          ),
        );
        records = await service.getPage(0, pageSize: 10);
        expect(p.basename(records.last.path), 'a.png');
      },
    );
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
