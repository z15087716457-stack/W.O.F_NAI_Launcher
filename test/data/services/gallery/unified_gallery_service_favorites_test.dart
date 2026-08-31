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

void main() {
  group('LocalGalleryService favorites', () {
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
        'nai_launcher_gallery_service_favorites_',
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

    test(
      'toggles the scanned gallery record when history uses mixed separators',
      () async {
        if (!Platform.isWindows) {
          markTestSkipped('Windows separator regression');
          return;
        }

        final file = File(p.join(galleryRoot.path, 'already_scanned.png'));
        await file.writeAsBytes(<int>[137, 80, 78, 71]);
        final scannedPath = file.path;
        final visibleImageId = await dataSource.upsertImage(
          filePath: scannedPath,
          fileName: p.basename(scannedPath),
          fileSize: await file.length(),
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );
        await service.initialize();

        final historyPath = scannedPath.replaceAll(r'\', '/');
        final isFavorite = await service.toggleFavorite(historyPath);

        expect(isFavorite, isTrue);
        expect(await dataSource.isFavorite(visibleImageId), isTrue);

        final records = await service.getPage(0);
        expect(records.single.path, scannedPath);
        expect(records.single.isFavorite, isTrue);
      },
    );

    test(
      'indexes a newly saved history image before applying favorite filters',
      () async {
        await service.initialize();
        final file = File(p.join(galleryRoot.path, 'saved_from_history.png'));
        await file.writeAsBytes(<int>[137, 80, 78, 71]);

        final isFavorite = await service.toggleFavorite(file.path);
        await service.setShowFavoritesOnly(true);

        final favorites = await service.getPage(0);
        expect(isFavorite, isTrue);
        expect(favorites, hasLength(1));
        expect(favorites.single.path, file.path);
        expect(favorites.single.isFavorite, isTrue);
      },
    );

    test(
      'counts favorites without changing the active favorites filter',
      () async {
        final favoriteFile = File(p.join(galleryRoot.path, 'favorite.png'));
        final otherFile = File(p.join(galleryRoot.path, 'ordinary.png'));
        await favoriteFile.writeAsBytes(<int>[137, 80, 78, 71]);
        await otherFile.writeAsBytes(<int>[137, 80, 78, 71]);

        await service.initialize();
        expect(await service.toggleFavorite(favoriteFile.path), isTrue);
        await service.setShowFavoritesOnly(true);

        final beforeCount = service.filteredCount;
        final beforeRecords = await service.getPage(0);
        expect(beforeCount, 1);
        expect(beforeRecords.map((record) => record.path), [favoriteFile.path]);

        final count = await service.getFavoriteCount();

        expect(count, 1);
        expect(service.currentFilter.showFavoritesOnly, isTrue);
        expect(service.filteredCount, beforeCount);

        final afterRecords = await service.getPage(0);
        expect(afterRecords.map((record) => record.path), [favoriteFile.path]);
      },
    );

    test('queries favorite image records directly in modified order', () async {
      final olderFile = File(p.join(galleryRoot.path, 'older.png'));
      final newerFile = File(p.join(galleryRoot.path, 'newer.png'));
      final ordinaryFile = File(p.join(galleryRoot.path, 'ordinary.png'));
      await olderFile.writeAsBytes(<int>[137, 80, 78, 71]);
      await newerFile.writeAsBytes(<int>[137, 80, 78, 71]);
      await ordinaryFile.writeAsBytes(<int>[137, 80, 78, 71]);

      final olderId = await dataSource.upsertImage(
        filePath: olderFile.path,
        fileName: p.basename(olderFile.path),
        fileSize: await olderFile.length(),
        createdAt: DateTime(2026),
        modifiedAt: DateTime(2026),
      );
      final newerId = await dataSource.upsertImage(
        filePath: newerFile.path,
        fileName: p.basename(newerFile.path),
        fileSize: await newerFile.length(),
        createdAt: DateTime(2026, 1, 2),
        modifiedAt: DateTime(2026, 1, 2),
      );
      await dataSource.upsertImage(
        filePath: ordinaryFile.path,
        fileName: p.basename(ordinaryFile.path),
        fileSize: await ordinaryFile.length(),
        createdAt: DateTime(2026, 1, 3),
        modifiedAt: DateTime(2026, 1, 3),
      );
      expect(await dataSource.toggleFavorite(olderId), isTrue);
      expect(await dataSource.toggleFavorite(newerId), isTrue);

      final favorites = await dataSource.queryFavoriteImages(limit: 10);

      expect(favorites.map((record) => record.filePath), [
        newerFile.path,
        olderFile.path,
      ]);
    });

    test(
      'counts only favorites that are still visible in the local gallery root',
      () async {
        final visibleFile = File(p.join(galleryRoot.path, 'visible.png'));
        await visibleFile.writeAsBytes(<int>[137, 80, 78, 71]);

        final outsideDir = Directory(p.join(tempDir.path, 'outside'));
        await outsideDir.create();
        final outsideFile = File(p.join(outsideDir.path, 'outside.png'));
        await outsideFile.writeAsBytes(<int>[137, 80, 78, 71]);

        await service.initialize();
        expect(await service.toggleFavorite(visibleFile.path), isTrue);

        final outsideId = await dataSource.upsertImage(
          filePath: outsideFile.path,
          fileName: p.basename(outsideFile.path),
          fileSize: await outsideFile.length(),
          createdAt: DateTime(2026),
          modifiedAt: DateTime(2026),
        );
        expect(await dataSource.toggleFavorite(outsideId), isTrue);

        expect(await service.getFavoriteCount(), 1);
      },
    );

    // 根-子集模型：从「收藏」根移除 = 取消心形收藏并清空所有收藏集成员关系
    test(
      'unfavoriteImages batch-removes from favorites and all collections',
      () async {
        final favFile = File(p.join(galleryRoot.path, 'fav.png'));
        final plainFile = File(p.join(galleryRoot.path, 'plain.png'));
        await favFile.writeAsBytes(<int>[137, 80, 78, 71]);
        await plainFile.writeAsBytes(<int>[137, 80, 78, 71]);

        final now = DateTime.now();
        final favId = await dataSource.upsertImage(
          filePath: favFile.path,
          fileName: p.basename(favFile.path),
          fileSize: await favFile.length(),
          createdAt: now,
          modifiedAt: now,
        );
        final plainId = await dataSource.upsertImage(
          filePath: plainFile.path,
          fileName: p.basename(plainFile.path),
          fileSize: await plainFile.length(),
          createdAt: now,
          modifiedAt: now,
        );

        await service.initialize();
        expect(await service.toggleFavorite(favFile.path), isTrue);

        // 模拟集合成员关系（数据层直插，不经 repo 的自动入根）
        final collectionId = await dataSource.createCollection('batch');
        await dataSource.addImageToCollection(collectionId, favId);
        await dataSource.addImageToCollection(collectionId, plainId);

        final removed = await service.unfavoriteImages([
          favFile.path,
          plainFile.path,
        ]);

        // 返回=实际取消的心形数（fav）；plain 未心形不计入
        expect(removed, 1);
        expect(await dataSource.isFavorite(favId), isFalse);
        // 从根移除 = 同时移出所有子集：两张图的集合成员关系全清
        expect(await dataSource.getCollectionImageIds(collectionId), isEmpty);
      },
    );

    test(
      'soft-deleted favorites are no longer counted, even after refresh',
      () async {
        final fileA = File(p.join(galleryRoot.path, 'del_a.png'));
        final fileB = File(p.join(galleryRoot.path, 'del_b.png'));
        await fileA.writeAsBytes(<int>[137, 80, 78, 71]);
        await fileB.writeAsBytes(<int>[137, 80, 78, 71]);

        await service.initialize();
        await service.toggleFavorite(fileA.path);
        await service.toggleFavorite(fileB.path);
        expect(await service.getFavoriteCount(), 2);

        await dataSource.batchMarkAsDeleted([fileA.path]);
        expect(await dataSource.getFavoriteCount(), 1);
        expect(await service.getFavoriteCount(), 1);

        // 软删后重扫/重放也不复活（DB is_deleted 为权威）
        await service.refresh(scan: false);
        expect(await service.getFavoriteCount(), 1);
      },
    );

    test('toggling favorite off also leaves all collections', () async {
      final file = File(p.join(galleryRoot.path, 'toggle_off.png'));
      await file.writeAsBytes(<int>[137, 80, 78, 71]);

      await service.initialize();
      expect(await service.toggleFavorite(file.path), isTrue);

      final imageId = (await dataSource.getImageIdByPath(file.path))!;
      final collectionId = await dataSource.createCollection('toggle');
      await dataSource.addImageToCollection(collectionId, imageId);

      expect(await service.toggleFavorite(file.path), isFalse);
      expect(await dataSource.isFavorite(imageId), isFalse);
      expect(await dataSource.getCollectionImageIds(collectionId), isEmpty);
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
