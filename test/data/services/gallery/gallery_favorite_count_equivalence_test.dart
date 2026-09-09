import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/core/utils/gallery_path_utils.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';

/// 旧实现（全量拉取全部记录再在内存过滤计数）
Future<int> _legacyGetFavoriteCount(
  LocalGalleryServiceImpl service,
  GalleryDataSource dataSource,
) async {
  if (service.allFilesForTesting.isEmpty) return 0;

  final totalFavorites = await dataSource.getFavoriteCount();
  if (totalFavorites == 0) return 0;

  final favoriteRecords = await dataSource.queryFavoriteImages(
    limit: totalFavorites,
  );
  final visiblePaths = {
    for (final file in service.allFilesForTesting)
      galleryFilePathKey(file.path),
  };
  return favoriteRecords
      .where(
        (record) => visiblePaths.contains(galleryFilePathKey(record.filePath)),
      )
      .length;
}

Future<void> _deleteDirectoryWithRetry(Directory dir) async {
  for (var i = 0; i < 5; i++) {
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      return;
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}

void main() {
  group('getFavoriteCount equivalence (A-3)', () {
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
        'nai_launcher_fav_count_equiv_',
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
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await service.dispose();
      await dataSource.dispose();
      await ConnectionPoolHolder.dispose();
      await Hive.close();

      if (await tempDir.exists()) {
        await _deleteDirectoryWithRetry(tempDir);
      }
    });

    test('空库场景：新旧实现均为 0', () async {
      await service.initialize();

      final legacyCount = await _legacyGetFavoriteCount(service, dataSource);
      final newCount = await service.getFavoriteCount();

      expect(newCount, equals(0));
      expect(newCount, equals(legacyCount));
    });

    test('全部在盘场景：多张收藏图片新旧实现计数完全一致', () async {
      // 创建 4 张在盘图片，其中 3 张设为收藏
      final files = <File>[];
      for (var i = 1; i <= 4; i++) {
        final file = File(p.join(galleryRoot.path, 'img_$i.png'));
        await file.writeAsBytes(<int>[137, 80, 78, 71, i]);
        files.add(file);
      }

      await service.initialize();

      // 收藏前 3 张
      await service.toggleFavorite(files[0].path);
      await service.toggleFavorite(files[1].path);
      await service.toggleFavorite(files[2].path);

      final legacyCount = await _legacyGetFavoriteCount(service, dataSource);
      final newCount = await service.getFavoriteCount();

      expect(newCount, equals(3));
      expect(newCount, equals(legacyCount));
    });

    test('磁盘与DB不一致场景：盘上已不存在的孤立收藏记录与软删记录被新旧实现同等过滤', () async {
      // 1. 创建两张真实图片并收藏
      final file1 = File(p.join(galleryRoot.path, 'real1.png'));
      final file2 = File(p.join(galleryRoot.path, 'real2.png'));
      await file1.writeAsBytes(<int>[137, 80, 78, 71, 1]);
      await file2.writeAsBytes(<int>[137, 80, 78, 71, 2]);

      await service.initialize();
      await service.toggleFavorite(file1.path);
      await service.toggleFavorite(file2.path);

      // 2. 将 file2 软删（进入回收站，DB is_deleted = 1）
      await dataSource.batchMarkAsDeleted([file2.path]);

      // 3. 在 DB 插入一条盘上不存在的幽灵路径收藏记录
      final ghostPath = p.join(tempDir.path, 'ghost', 'ghost.png');
      final ghostId = await dataSource.upsertImage(
        filePath: ghostPath,
        fileName: 'ghost.png',
        fileSize: 1024,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      await dataSource.toggleFavorite(ghostId);

      // 对拍比较
      final legacyCount = await _legacyGetFavoriteCount(service, dataSource);
      final newCount = await service.getFavoriteCount();

      // DB 中共有 3 条收藏记录（real1, real2-deleted, ghost），
      // 但只有 real1 在盘且未软删，因此两版计数必须精确等于 1
      expect(newCount, equals(1));
      expect(newCount, equals(legacyCount));
    });
  });
}
