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
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';

void main() {
  group('LocalGalleryService 时间线条目与 stat 缓存', () {
    late Directory tempDir;
    late Directory galleryRoot;
    late GalleryDataSource dataSource;
    late LocalGalleryServiceImpl service;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'nai_launcher_gallery_service_timeline_',
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

    test('getTimelineEntries 返回全部条目并带 DB 宽高，无尺寸条目为 null', () async {
      final portrait = File(p.join(galleryRoot.path, 'portrait.png'));
      final landscape = File(p.join(galleryRoot.path, 'landscape.png'));
      final nodims = File(p.join(galleryRoot.path, 'nodims.png'));
      await portrait.writeAsBytes(<int>[137, 80, 78, 71]);
      await landscape.writeAsBytes(<int>[137, 80, 78, 71]);
      await nodims.writeAsBytes(<int>[137, 80, 78, 71]);

      final now = DateTime.now();
      await dataSource.upsertImage(
        filePath: portrait.path,
        fileName: p.basename(portrait.path),
        fileSize: await portrait.length(),
        width: 832,
        height: 1216,
        createdAt: now,
        modifiedAt: now,
      );
      await dataSource.upsertImage(
        filePath: landscape.path,
        fileName: p.basename(landscape.path),
        fileSize: await landscape.length(),
        width: 1216,
        height: 832,
        createdAt: now,
        modifiedAt: now,
      );
      await dataSource.upsertImage(
        filePath: nodims.path,
        fileName: p.basename(nodims.path),
        fileSize: await nodims.length(),
        createdAt: now,
        modifiedAt: now,
      );

      await service.initialize();

      final items = await service.getTimelineEntries();
      expect(items, hasLength(3));
      for (final item in items) {
        expect(item.modifiedAt, (await File(item.path).stat()).modified);
      }

      final byPath = {for (final item in items) item.path: item};
      expect(byPath[portrait.path]?.width, 832);
      expect(byPath[portrait.path]?.height, 1216);
      expect(byPath[portrait.path]?.aspectRatio, closeTo(832 / 1216, 0.001));
      expect(byPath[landscape.path]?.aspectRatio, closeTo(1216 / 832, 0.001));
      expect(byPath[nodims.path]?.width, isNull);
      expect(byPath[nodims.path]?.aspectRatio, isNull);
      await service.applyFilter(const FilterCriteria(searchQuery: 'portrait'));
      final scope = await service.getTimelineForFilter(
        const FilterCriteria(searchQuery: 'landscape'),
      );
      expect(scope.map((e) => e.path), [landscape.path]);
      expect(service.currentFilter.searchQuery, 'portrait');
      expect((await service.getTimelineEntries()).map((e) => e.path), [
        portrait.path,
      ]);
    });

    test('getTimelineEntries 与分页同一排序源', () async {
      for (final (name, day) in [('a', 3), ('b', 1), ('c', 2)]) {
        File(p.join(galleryRoot.path, '$name.png'))
          ..writeAsBytesSync(<int>[137, 80, 78, 71])
          ..setLastModifiedSync(DateTime(2026, 8, day, 10));
      }

      await service.initialize();

      final entries = await service.getTimelineEntries();
      final page = await service.getPage(0, pageSize: 10);
      expect(entries.map((e) => e.path), page.map((r) => r.path));
      expect(entries.map((e) => p.basename(e.path)), [
        'a.png',
        'c.png',
        'b.png',
      ]);
      final ascending = await service.getTimelineForFilter(
        const FilterCriteria(),
        sort: const GallerySort(
          field: GallerySortField.modifiedAt,
          direction: GallerySortDirection.ascending,
        ),
      );
      expect(ascending.map((e) => p.basename(e.path)), [
        'b.png',
        'c.png',
        'a.png',
      ]);
      expect(ascending.map((e) => e.size), everyElement(4));
      expect(
        (await service.getTimelineEntries()).map((e) => e.path),
        entries.map((e) => e.path),
      );
    });

    test('getRecordsForPaths 按传入顺序返回并跳过不存在的文件', () async {
      final fileA = File(p.join(galleryRoot.path, 'a.png'));
      final fileB = File(p.join(galleryRoot.path, 'b.png'));
      await fileA.writeAsBytes(List.filled(10, 1));
      await fileB.writeAsBytes(List.filled(20, 1));

      await service.initialize();

      final records = await service.getRecordsForPaths([
        fileB.path,
        p.join(galleryRoot.path, 'missing.png'),
        fileA.path,
      ]);
      expect(records.map((r) => r.path), [fileB.path, fileA.path]);
      expect(records.map((r) => r.size), [20, 10]);
    });

    test('重复 getPage 走 stat 缓存：两次结果逐项一致', () async {
      final file = File(p.join(galleryRoot.path, 'stable.png'));
      await file.writeAsBytes(List.filled(64, 7));
      await service.initialize();

      final first = await service.getPage(0);
      final second = await service.getPage(0);

      expect(second.single.path, first.single.path);
      expect(second.single.size, first.single.size);
      expect(second.single.modifiedAt, first.single.modifiedAt);
      expect(second.single.size, 64);
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
