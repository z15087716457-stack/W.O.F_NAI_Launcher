import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/data/services/gallery/gallery_thumbnail_quality_store.dart';
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
    final size = pageSize ?? this.pageSize;
    final start = page * size;
    if (start >= records.length) return [];
    final end = (start + size).clamp(0, records.length);
    return records.sublist(start, end);
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

void main() {
  test('quality change preloads current, previous, and next pages', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final records = List.generate(
      25,
      (index) => LocalImageRecord(
        path: 'image_$index.png',
        size: 1,
        modifiedAt: DateTime(2026, 1, 1),
      ),
    );
    final service = _FakeLocalGalleryService(records);
    final container = ProviderContainer(
      overrides: [
        galleryServiceProvider.overrideWith(
          () => _FakeGalleryServiceNotifier(service),
        ),
      ],
    );
    addTearDown(container.dispose);

    final preloaded = <String, ThumbnailSize>{};
    final notifier = container.read(localGalleryNotifierProvider.notifier);
    notifier.setThumbnailQualityStoreForTesting(
      const GalleryThumbnailQualityStore(),
    );
    notifier.setThumbnailPreloadCallbackForTesting((
      path, {
      required size,
      required priority,
    }) {
      preloaded[path] = size;
    });

    await notifier.initialize();
    await notifier.setPageSize(10);
    await notifier.loadPage(1);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    preloaded.clear();

    await notifier.setThumbnailQuality(GalleryThumbnailQuality.sd);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(
      container.read(localGalleryNotifierProvider).thumbnailQuality,
      GalleryThumbnailQuality.sd,
    );
    expect(
      preloaded.keys,
      containsAll([
        ...List.generate(10, (index) => 'image_${index + 10}.png'),
        ...List.generate(10, (index) => 'image_$index.png'),
        ...List.generate(5, (index) => 'image_${index + 20}.png'),
      ]),
    );
    expect(preloaded.values, everyElement(ThumbnailSize.small));
  });
}
