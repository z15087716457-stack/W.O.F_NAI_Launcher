import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/presentation/providers/collection_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';

/// 注入已初始化服务的 GalleryService notifier（绕开 DatabaseManager 全量初始化）
class _InjectedGalleryService extends GalleryService {
  _InjectedGalleryService(this._injected);

  final LocalGalleryService _injected;

  @override
  LocalGalleryService build() => _injected;
}

/// 收藏菜单「加入子集=入根」后，当前页记录的 isFavorite 必须同步：
/// 缩略图红心/预览图收藏按钮读的就是它——不同步则红心不点亮（回归）。
void main() {
  group('collection membership syncs favorite flag (provider level)', () {
    late Directory tempDir;
    late Directory galleryRoot;
    late GalleryDataSource dataSource;
    late LocalGalleryServiceImpl service;
    late ProviderContainer container;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp(
        'nai_launcher_collection_fav_sync_',
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

      container = ProviderContainer(
        overrides: [
          galleryServiceProvider.overrideWith(
            () => _InjectedGalleryService(service),
          ),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await service.dispose();
      await dataSource.dispose();
      await ConnectionPoolHolder.dispose();
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<List<File>> createImageFiles(int count) async {
      final files = <File>[];
      for (var i = 0; i < count; i++) {
        final file = File(p.join(galleryRoot.path, 'img_$i.png'));
        await file.writeAsBytes(<int>[137, 80, 78, 71]);
        await file.setLastModified(DateTime(2026, 1, 1).add(Duration(minutes: i)));
        files.add(file);
      }
      return files;
    }

    Future<void> indexImages(List<File> files) async {
      for (final file in files) {
        final stat = await file.stat();
        await dataSource.upsertImage(
          filePath: file.path,
          fileName: p.basename(file.path),
          fileSize: stat.size,
          createdAt: stat.changed,
          modifiedAt: stat.modified,
        );
      }
      await service.initialize();
    }

    test('直接加入子集后当前页记录 isFavorite 同步为 true（未收藏起点）', () async {
      final files = await createImageFiles(3);
      await indexImages(files);

      final galleryNotifier = container.read(
        localGalleryNotifierProvider.notifier,
      );
      await galleryNotifier.initialize();

      var state = container.read(localGalleryNotifierProvider);
      final target = state.currentImages.first.path;
      expect(
        state.currentImages.firstWhere((r) => r.path == target).isFavorite,
        isFalse,
        reason: '初始未收藏',
      );

      // 直接加入子集（入子集即入根）
      final collectionId = await dataSource.createCollection('test');
      await container
          .read(collectionNotifierProvider.notifier)
          .toggleImageInCollection(collectionId, target);

      // 同步前 DB 已是收藏态，但当前页记录还是旧值（修复点）
      state = container.read(localGalleryNotifierProvider);
      expect(
        state.currentImages.firstWhere((r) => r.path == target).isFavorite,
        isFalse,
        reason: '未调同步前红心状态保持旧值（复现 bug 前提）',
      );

      final synced = await galleryNotifier.syncFavoriteStatus(target);
      state = container.read(localGalleryNotifierProvider);
      expect(synced, isTrue);
      expect(
        state.currentImages.firstWhere((r) => r.path == target).isFavorite,
        isTrue,
        reason: '同步后缩略图/预览图红心应点亮',
      );
    });

    test('已收藏图片移出子集后 isFavorite 保持 true（移出子集不动根）', () async {
      final files = await createImageFiles(2);
      await indexImages(files);

      final galleryNotifier = container.read(
        localGalleryNotifierProvider.notifier,
      );
      await galleryNotifier.initialize();

      var state = container.read(localGalleryNotifierProvider);
      final target = state.currentImages.first.path;
      await galleryNotifier.toggleFavorite(target);
      expect(
        container.read(localGalleryNotifierProvider).currentImages
            .firstWhere((r) => r.path == target)
            .isFavorite,
        isTrue,
        reason: '先收藏进根',
      );

      final collectionId = await dataSource.createCollection('test');
      final collectionNotifier = container.read(
        collectionNotifierProvider.notifier,
      );
      await collectionNotifier.toggleImageInCollection(collectionId, target);

      // 移出子集：根不动，红心应保持点亮
      state = container.read(localGalleryNotifierProvider);
      final synced = await galleryNotifier.syncFavoriteStatus(target);
      state = container.read(localGalleryNotifierProvider);
      expect(synced, isTrue);
      expect(
        state.currentImages.firstWhere((r) => r.path == target).isFavorite,
        isTrue,
        reason: '移出子集不应熄灭根收藏红心',
      );
    });
  });
}
