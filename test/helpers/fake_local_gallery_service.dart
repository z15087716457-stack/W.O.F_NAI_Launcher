import 'dart:io';

import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_file_changes.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';

/// 替换 [galleryServiceProvider] 的 Notifier，直接返回给定服务。
class FakeGalleryServiceNotifier extends GalleryService {
  FakeGalleryServiceNotifier(this.service);

  final LocalGalleryService service;

  @override
  LocalGalleryService build() => service;
}

GalleryFileMonitor fakeGalleryFileMonitor() => GalleryFileMonitor(
  loadRoots: () async => [],
  rootsChanged: const Stream.empty(),
  apply: (_) async {},
  onError: (error, stack) => Error.throwWithStackTrace(error, stack),
);

/// 内存版本地画廊服务：按给定记录提供时间线、记录与收藏，记录调用次数。
///
/// 过滤只模拟测试需要的维度：仅收藏、搜索（路径包含）与日期范围；
/// 其他条件原样保留在 [currentFilter] 中供断言。
class FakeLocalGalleryService implements LocalGalleryService {
  FakeLocalGalleryService(
    List<LocalImageRecord> records, {
    Map<String, (int, int)> dimensions = const {},
  }) : _records = List.of(records),
       _dimensions = Map.of(dimensions),
       _favorites = {
         for (final record in records)
           if (record.isFavorite) record.path,
       };

  final List<LocalImageRecord> _records;
  final Map<String, (int, int)> _dimensions;
  final Set<String> _favorites;
  FilterCriteria _filter = const FilterCriteria();
  GallerySort sort = const GallerySort.modifiedAtDesc();

  int applyFilterCount = 0;
  int setSortCount = 0;
  int timelineRequests = 0;
  int refreshCount = 0;
  final List<GalleryFileChanges> fileChanges = [];

  @override
  Future<Set<String>> applyFileChanges(GalleryFileChanges changes) async {
    fileChanges.add(changes);
    return changes.files;
  }

  final List<List<String>> recordRequests = [];
  final List<String> addedImages = [];

  List<LocalImageRecord> get _effective {
    if (!_filter.hasFilters) return _records;
    return _records.where((record) {
      if (_filter.showFavoritesOnly && !_favorites.contains(record.path)) {
        return false;
      }
      final query = _filter.searchQuery.trim().toLowerCase();
      if (query.isNotEmpty && !record.path.toLowerCase().contains(query)) {
        return false;
      }
      final start = _filter.dateStart;
      final end = _filter.dateEnd;
      if (start != null && record.modifiedAt.isBefore(start)) return false;
      if (end != null &&
          record.modifiedAt.isAfter(end.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  }

  LocalImageRecord _withFavorite(LocalImageRecord record) =>
      record.copyWith(isFavorite: _favorites.contains(record.path));

  @override
  bool get isInitialized => true;

  @override
  int get filteredCount => _effective.length;

  @override
  int get totalCount => _records.length;

  @override
  FilterCriteria get currentFilter => _filter;

  @override
  Future<List<File>> initialize() async => [];

  @override
  Future<List<LocalImageRecord>> getPage(int page, {int? pageSize}) async {
    final size = pageSize ?? 50;
    final items = _effective.skip(page * size).take(size);
    return [for (final record in items) _withFavorite(record)];
  }

  @override
  Future<GalleryQueryPage> queryRecords(
    FilterCriteria criteria, {
    int offset = 0,
    int limit = 50,
    GallerySort sort = const GallerySort.modifiedAtDesc(),
  }) async {
    final items = _records
        .where(
          (r) =>
              (!criteria.showFavoritesOnly || _favorites.contains(r.path)) &&
              (criteria.searchQuery.isEmpty ||
                  r.path.contains(criteria.searchQuery)),
        )
        .toList();
    return GalleryQueryPage(
      records: items.skip(offset).take(limit).map(_withFavorite).toList(),
      totalCount: items.length,
      nextOffset: offset + limit < items.length ? offset + limit : null,
    );
  }

  @override
  Future<List<LocalImageRecord>> getLibraryRecordsForPaths(
    List<String> paths,
  ) async =>
      _records.where((r) => paths.contains(r.path)).map(_withFavorite).toList();

  @override
  Future<List<GalleryTimelineEntry>> getTimelineEntries() async {
    timelineRequests++;
    return [
      for (final record in _effective)
        GalleryTimelineEntry(
          path: record.path,
          modifiedAt: record.modifiedAt,
          width: _dimensions[record.path]?.$1 ?? record.metadata?.width,
          height: _dimensions[record.path]?.$2 ?? record.metadata?.height,
          size: record.size,
        ),
    ];
  }

  @override
  Future<List<GalleryTimelineEntry>> getTimelineForFilter(
    FilterCriteria criteria, {
    GallerySort? sort,
  }) async {
    final previous = _filter;
    try {
      _filter = criteria;
      return await getTimelineEntries();
    } finally {
      _filter = previous;
    }
  }

  @override
  Future<List<LocalImageRecord>> getRecordsForPaths(List<String> paths) async {
    recordRequests.add(List.of(paths));
    final byPath = {for (final record in _records) record.path: record};
    return [
      for (final path in paths)
        if (byPath[path] case final record?) _withFavorite(record),
    ];
  }

  @override
  Future<List<LocalImageRecord>> getRecordsByPaths(List<String> paths) =>
      getRecordsForPaths(paths);

  @override
  Future<void> applyFilter(FilterCriteria criteria) async {
    applyFilterCount++;
    _filter = criteria;
  }

  @override
  Future<void> setSort(GallerySort sort) async {
    setSortCount++;
    this.sort = sort;
  }

  @override
  Future<bool> toggleFavorite(String filePath) async {
    if (!_favorites.remove(filePath)) {
      _favorites.add(filePath);
      return true;
    }
    return false;
  }

  @override
  Future<bool> isFavorite(String filePath) async =>
      _favorites.contains(filePath);

  @override
  Future<int> getFavoriteCount() async => _favorites.length;

  @override
  Future<int> unfavoriteImages(List<String> filePaths) async {
    var removed = 0;
    for (final path in filePaths) {
      if (_favorites.remove(path)) removed++;
    }
    return removed;
  }

  @override
  Future<NaiImageMetadata?> getMetadata(String filePath) async {
    for (final record in _records) {
      if (record.path == filePath) return record.metadata;
    }
    return null;
  }

  @override
  Future<void> refresh({bool scan = true}) async {
    refreshCount++;
  }

  @override
  Future<bool> addNewImageImmediately(
    String filePath, {
    NaiImageMetadata? metadata,
  }) async {
    addedImages.add(filePath);
    _records.insert(
      0,
      LocalImageRecord(path: filePath, size: 1, modifiedAt: DateTime.now()),
    );
    return true;
  }

  @override
  Future<void> setSearchQuery(String query) =>
      applyFilter(_filter.copyWith(searchQuery: query));

  @override
  Future<void> setDateRange(DateTime? start, DateTime? end) =>
      applyFilter(_filter.copyWith(dateStart: start, dateEnd: end));

  @override
  Future<void> setShowFavoritesOnly(bool value) =>
      applyFilter(_filter.copyWith(showFavoritesOnly: value));

  @override
  Future<void> clearFilters() => applyFilter(const FilterCriteria());

  @override
  Future<void> dispose() async {}

  @override
  void removeImagesFromMemory(List<String> paths) {
    _records.removeWhere((record) => paths.contains(record.path));
  }

  @override
  Future<List<String>> getFilteredImagePaths() async => [
    for (final record in _effective) record.path,
  ];
}
