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

/// 收藏视图翻页浏览中「取消收藏」不得跳回第一页：
/// ① 第 2 页（index 2）取消一张后应停在第 2 页；
/// ② 末页唯一一张被取消后应回退到相邻末页（index 1），而不是第 0 页。
void main() {
  group('favorite toggle pagination (provider level)', () {
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
        'nai_launcher_fav_pagination_',
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

    Future<List<File>> createFavoriteFiles(int count) async {
      final files = <File>[];
      for (var i = 0; i < count; i++) {
        final file = File(p.join(galleryRoot.path, 'img_$i.png'));
        await file.writeAsBytes(<int>[137, 80, 78, 71]);
        await file.setLastModified(DateTime(2026, 1, 1).add(Duration(minutes: i)));
        files.add(file);
      }
      return files;
    }

    Future<void> indexAllFavorites(List<File> files) async {
      for (final file in files) {
        final stat = await file.stat();
        final id = await dataSource.upsertImage(
          filePath: file.path,
          fileName: p.basename(file.path),
          fileSize: stat.size,
          createdAt: stat.changed,
          modifiedAt: stat.modified,
        );
        await dataSource.toggleFavorite(id);
      }
      await service.initialize();
    }

    test('取消收藏后停留在原页（第 2 页）', () async {
      // 26 张收藏 + pageSize 10 → 3 页：page2 = 最旧的 6 张
      final files = await createFavoriteFiles(26);
      await indexAllFavorites(files);

      final notifier = container.read(localGalleryNotifierProvider.notifier);
      await notifier.initialize();
      await notifier.setShowFavoritesOnly(true);
      await notifier.setPageSize(10);
      await notifier.loadPage(2);

      var state = container.read(localGalleryNotifierProvider);
      expect(state.currentPage, 2, reason: '应停在第 2 页');
      expect(state.currentImages.length, 6);
      expect(state.totalPages, 3);

      final target = state.currentImages.first.path;
      await notifier.toggleFavorite(target);

      state = container.read(localGalleryNotifierProvider);
      expect(
        state.currentPage,
        2,
        reason: '取消收藏后不得跳回第 0 页',
      );
      expect(
        state.currentImages.map((r) => r.path),
        isNot(contains(target)),
        reason: '取消收藏的图应即时从当前页消失',
      );
      expect(state.currentImages.length, 5);
      expect(state.filteredCount, 25);
    });

    test('末页唯一一张被取消后回退到相邻末页而非第 0 页', () async {
      // 21 张收藏 + pageSize 10 → 3 页：page2 只有最旧的 1 张
      final files = await createFavoriteFiles(21);
      await indexAllFavorites(files);

      final notifier = container.read(localGalleryNotifierProvider.notifier);
      await notifier.initialize();
      await notifier.setShowFavoritesOnly(true);
      await notifier.setPageSize(10);
      await notifier.loadPage(2);

      var state = container.read(localGalleryNotifierProvider);
      expect(state.currentPage, 2);
      expect(state.currentImages.length, 1);

      final target = state.currentImages.single.path;
      await notifier.toggleFavorite(target);

      state = container.read(localGalleryNotifierProvider);
      expect(state.currentPage, 1, reason: '回退到相邻末页（index 1）');
      expect(state.totalPages, 2);
      expect(state.filteredCount, 20);
    });

    test('分组视图切换回网格保持页码（视图切换≠条件变更）', () async {
      final files = await createFavoriteFiles(26);
      await indexAllFavorites(files);

      final notifier = container.read(localGalleryNotifierProvider.notifier);
      await notifier.initialize();
      await notifier.setShowFavoritesOnly(true);
      await notifier.setPageSize(10);
      await notifier.loadPage(2);
      expect(container.read(localGalleryNotifierProvider).currentPage, 2);

      await notifier.setGroupedView(true);
      final grouped = container.read(localGalleryNotifierProvider);
      expect(grouped.isGroupedView, isTrue);
      expect(grouped.groupedImages, hasLength(26));

      await notifier.setGroupedView(false);
      final state = container.read(localGalleryNotifierProvider);
      expect(state.currentPage, 2, reason: '分组切回网格不得跳回第一页');
      expect(state.currentImages.length, 6);
    });

    test('取消收藏后侧栏收藏计数重查为减一（普通与收藏视图）', () async {
      final files = await createFavoriteFiles(5);
      await indexAllFavorites(files);

      final notifier = container.read(localGalleryNotifierProvider.notifier);
      await notifier.initialize();

      // 先让计数 provider 求一次值（侧栏显示口径）
      expect(await container.read(galleryFavoriteCountProvider.future), 5);

      // 场景 A：普通视图下取消收藏
      await notifier.toggleFavorite(files.first.path);
      expect(
        await container.read(galleryFavoriteCountProvider.future),
        4,
        reason: '普通视图取消收藏后计数应即时减 1',
      );

      // 场景 B：收藏视图（过滤重放）下取消收藏
      await notifier.setShowFavoritesOnly(true);
      expect(await container.read(galleryFavoriteCountProvider.future), 4);
      await notifier.toggleFavorite(files[1].path);
      expect(
        await container.read(galleryFavoriteCountProvider.future),
        3,
        reason: '收藏视图取消收藏后计数应即时减 1',
      );
    });

    test('取消收藏后收藏集行计数同步减一（根移除=全清成员）', () async {
      final files = await createFavoriteFiles(3);
      await indexAllFavorites(files);

      // 数据层直建集合 + 成员（心形已由 indexAllFavorites 写入）
      final collectionId = await dataSource.createCollection('test');
      for (final file in files) {
        final id = (await dataSource.getImageIdByPath(file.path))!;
        await dataSource.addImageToCollection(collectionId, id);
      }

      final collectionNotifier = container.read(
        collectionNotifierProvider.notifier,
      );
      await collectionNotifier.initialize();
      expect(
        container.read(collectionNotifierProvider).collections.first.imageCount,
        3,
        reason: '初始集合成员数 3',
      );

      final galleryNotifier = container.read(
        localGalleryNotifierProvider.notifier,
      );
      await galleryNotifier.initialize();

      // 单张取消收藏：根移除 = 移出所有集合，集合行计数应即时减一
      await galleryNotifier.toggleFavorite(files.first.path);
      expect(
        container.read(collectionNotifierProvider).collections.first.imageCount,
        2,
        reason: '取消收藏后集合行计数应同步减一',
      );

      // 批量取消收藏同理
      await galleryNotifier.unfavoriteImages([
        files[1].path,
        files[2].path,
      ]);
      expect(
        container.read(collectionNotifierProvider).collections.first.imageCount,
        0,
        reason: '批量取消收藏后所有集合成员关系清空，计数归零',
      );
    });
  });
}
