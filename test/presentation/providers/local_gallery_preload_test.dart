import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/data/services/gallery/gallery_thumbnail_quality_store.dart';
import 'package:nai_launcher/data/services/gallery/gallery_view_mode.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGalleryServiceNotifier extends GalleryService {
  _FakeGalleryServiceNotifier(this.service);

  final LocalGalleryService service;

  @override
  LocalGalleryService build() => service;
}

class _FakeLocalGalleryService implements LocalGalleryService {
  _FakeLocalGalleryService(this.records);

  final List<LocalImageRecord> records;
  FilterCriteria filter = const FilterCriteria();
  int pageSize = 50;
  int getPageCount = 0;
  int getPagePreloadItemsCount = 0;

  @override
  bool get isInitialized => true;

  @override
  int get filteredCount => records.length;

  @override
  int get totalCount => records.length;

  @override
  FilterCriteria get currentFilter => filter;

  @override
  Future<List<File>> initialize() async => [];

  @override
  Future<List<LocalImageRecord>> getPage(int page, {int? pageSize}) async {
    getPageCount++;
    final size = pageSize ?? this.pageSize;
    final start = page * size;
    if (start >= records.length) return [];
    final end = (start + size).clamp(0, records.length);
    return records.sublist(start, end);
  }

  @override
  Future<List<GalleryPagePreloadItem>> getPagePreloadItems(
    int page, {
    int? pageSize,
  }) async {
    getPagePreloadItemsCount++;
    final size = pageSize ?? this.pageSize;
    final start = page * size;
    if (start >= records.length) return [];
    final end = (start + size).clamp(0, records.length);
    return [
      for (final record in records.sublist(start, end))
        GalleryPagePreloadItem(
          path: record.path,
          width: record.metadata?.width,
          height: record.metadata?.height,
        ),
    ];
  }

  @override
  Future<void> applyFilter(FilterCriteria criteria) async {
    filter = criteria;
  }

  @override
  Future<bool> toggleFavorite(String filePath) async => false;

  @override
  Future<bool> isFavorite(String filePath) async => false;

  @override
  Future<int> getFavoriteCount() async => 0;

  @override
  Future<int> unfavoriteImages(List<String> filePaths) async => 0;

  @override
  Future<NaiImageMetadata?> getMetadata(String filePath) async => null;

  @override
  Future<void> refresh({bool scan = true}) async {}

  @override
  Future<bool> addNewImageImmediately(
    String filePath, {
    NaiImageMetadata? metadata,
  }) async => false;

  @override
  Future<void> setSearchQuery(String query) async {}

  @override
  Future<void> setDateRange(DateTime? start, DateTime? end) async {}

  @override
  Future<void> setShowFavoritesOnly(bool value) async {}

  @override
  Future<void> setPageSize(int size) async {
    pageSize = size;
  }

  @override
  Future<void> setSort(GallerySort sort) async {}

  @override
  Future<void> clearFilters() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<List<LocalImageRecord>> getRecordsByPaths(List<String> paths) async =>
      records.where((record) => paths.contains(record.path)).toList();

  @override
  void removeImagesFromMemory(List<String> paths) {}

  @override
  Future<List<String>> getFilteredImagePaths() async =>
      records.map((record) => record.path).toList();
}

/// 三页 × 每页 10 张：page0 混三种画幅、page1 方图（当前页）、page2 横图。
List<LocalImageRecord> _buildRecords() {
  NaiImageMetadata meta(int? width, int? height) =>
      NaiImageMetadata(width: width, height: height);

  return [
    // page 0：4 竖图 + 3 方图 + 2 横图 + 1 无尺寸
    for (var i = 0; i < 4; i++)
      LocalImageRecord(
        path: 'portrait_$i.png',
        size: 1,
        modifiedAt: DateTime(2026, 1, 1),
        metadata: meta(832, 1216),
      ),
    for (var i = 0; i < 3; i++)
      LocalImageRecord(
        path: 'square_$i.png',
        size: 1,
        modifiedAt: DateTime(2026, 1, 1),
        metadata: meta(1024, 1024),
      ),
    for (var i = 0; i < 2; i++)
      LocalImageRecord(
        path: 'landscape_$i.png',
        size: 1,
        modifiedAt: DateTime(2026, 1, 1),
        metadata: meta(1216, 832),
      ),
    LocalImageRecord(
      path: 'nodims_0.png',
      size: 1,
      modifiedAt: DateTime(2026, 1, 1),
    ),
    // page 1：当前页（不该被预取）
    for (var i = 10; i < 20; i++)
      LocalImageRecord(
        path: 'current_$i.png',
        size: 1,
        modifiedAt: DateTime(2026, 1, 1),
        metadata: meta(1024, 1024),
      ),
    // page 2：横图
    for (var i = 20; i < 30; i++)
      LocalImageRecord(
        path: 'wide_$i.png',
        size: 1,
        modifiedAt: DateTime(2026, 1, 1),
        metadata: meta(1216, 832),
      ),
  ];
}

void main() {
  late _FakeLocalGalleryService service;
  late ProviderContainer container;
  late LocalGalleryNotifier notifier;
  late Map<String, ThumbnailSize> preloaded;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    service = _FakeLocalGalleryService(_buildRecords());
    container = ProviderContainer(
      overrides: [
        galleryServiceProvider.overrideWith(
          () => _FakeGalleryServiceNotifier(service),
        ),
      ],
    );
    notifier = container.read(localGalleryNotifierProvider.notifier);
    notifier.setThumbnailQualityStoreForTesting(
      const GalleryThumbnailQualityStore(),
    );
    preloaded = {};
    notifier.setThumbnailPreloadCallbackForTesting((
      path, {
      required size,
      required priority,
    }) {
      preloaded[path] = size;
    });
    notifier.updateDevicePixelRatio(1.0);
  });

  tearDown(() => container.dispose());

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 60));

  test('翻页预取走轻量路径：命中 getPagePreloadItems、不拉当前页记录', () async {
    await notifier.initialize();
    await notifier.setPageSize(10);
    await notifier.loadPage(1);
    await settle();

    // 当前页记录只由 loadPage 拉取：initialize(1) + setPageSize 触发的重载 + loadPage(1)
    // 预取侧全部走 getPagePreloadItems（每页一次），不再调用 getPage
    expect(service.getPagePreloadItemsCount, greaterThanOrEqualTo(3));
    expect(service.getPageCount, lessThanOrEqualTo(3));

    preloaded.clear();
    final pageCallsBefore = service.getPageCount;
    final preloadCallsBefore = service.getPagePreloadItemsCount;

    await notifier.loadPage(1); // 再翻一次同页：预取 {0, 2}
    await settle();

    // 只多了一次 getPage（当前页），预取两页都走轻量方法
    expect(service.getPageCount, pageCallsBefore + 1);
    expect(service.getPagePreloadItemsCount, preloadCallsBefore + 2);

    // 覆盖邻页全部条目、不含当前页
    expect(
      preloaded.keys,
      containsAll([
        ...List.generate(4, (i) => 'portrait_$i.png'),
        ...List.generate(3, (i) => 'square_$i.png'),
        ...List.generate(2, (i) => 'landscape_$i.png'),
        'nodims_0.png',
        ...List.generate(10, (i) => 'wide_${i + 20}.png'),
      ]),
    );
    expect(
      preloaded.keys.where((path) => path.startsWith('current_')),
      isEmpty,
    );
  });

  test('火车流按「列宽×宽高比」逐张选档（列宽 260 / DPR 1.0 / hd）', () async {
    notifier.setViewMode(GalleryViewMode.justified);

    await notifier.initialize();
    await notifier.setPageSize(10);
    await notifier.loadPage(1);
    await settle();

    // 832×1216 → 260×0.683≈177.6 → small
    expect(preloaded['portrait_0.png'], ThumbnailSize.small);
    // 1024×1024 → 260 → medium；无尺寸按 1.0 → medium
    expect(preloaded['square_0.png'], ThumbnailSize.medium);
    expect(preloaded['nodims_0.png'], ThumbnailSize.medium);
    // 1216×832 → 260×1.462≈380 → large
    expect(preloaded['landscape_0.png'], ThumbnailSize.large);
    expect(preloaded['wide_20.png'], ThumbnailSize.large);
  });

  test('网格视图按固定卡片宽 180 选档（DPR 1.0 → small，旧实现错档 medium）', () async {
    notifier.setViewMode(GalleryViewMode.grid);

    await notifier.initialize();
    await notifier.setPageSize(10);
    await notifier.loadPage(1);
    await settle();

    expect(preloaded.values, everyElement(ThumbnailSize.small));
  });

  test('瀑布流按列宽选档（260 / DPR 1.0 → medium）', () async {
    notifier.setViewMode(GalleryViewMode.masonry);

    await notifier.initialize();
    await notifier.setPageSize(10);
    await notifier.loadPage(1);
    await settle();

    expect(preloaded.values, everyElement(ThumbnailSize.medium));
  });
}
