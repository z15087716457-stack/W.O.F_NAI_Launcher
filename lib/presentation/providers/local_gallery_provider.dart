import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/cache/thumbnail_cache_service.dart';
import '../../core/cache/gallery_cache_manager.dart';
import '../../core/exceptions/gallery_exceptions.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/gallery_path_utils.dart';
import '../../data/models/gallery/local_image_record.dart';
import '../../data/models/gallery/nai_image_metadata.dart';
import '../../core/database/datasources/gallery_data_source.dart';
import '../../data/repositories/gallery_folder_repository.dart';
import '../../data/services/gallery/gallery_filter_service.dart';
import '../../data/services/gallery/gallery_thumbnail_quality_store.dart';
import '../../data/services/gallery/gallery_sort.dart';
import '../../data/services/gallery/gallery_stream_scanner.dart';
import '../../data/services/gallery/gallery_view_mode.dart';
import '../../data/services/gallery/scan_state_manager.dart';
import '../../data/services/gallery/unified_gallery_service.dart';
import '../../data/services/thumbnail_service.dart';
import '../../l10n/app_localizations.dart';
import 'collection_provider.dart';

part 'local_gallery_provider.freezed.dart';
part 'local_gallery_provider.g.dart';

enum LocalGalleryErrorCode {
  permissionDenied,
  scanFailed,
  initializationFailed,
  serviceInitializing,
  databaseFailed,
  refreshFailed,
  filterFailed,
  favoriteFailed,
  rebuildFailed,
}

class LocalGalleryError {
  const LocalGalleryError(this.code, {this.details});

  final LocalGalleryErrorCode code;
  final String? details;

  String localized(AppLocalizations l10n) {
    final errorDetails = details ?? '';
    return switch (code) {
      LocalGalleryErrorCode.permissionDenied =>
        l10n.localGallery_errorPermissionDenied,
      LocalGalleryErrorCode.scanFailed => l10n.localGallery_errorScanFailed(
        errorDetails,
      ),
      LocalGalleryErrorCode.initializationFailed =>
        l10n.localGallery_errorInitializationFailed(errorDetails),
      LocalGalleryErrorCode.serviceInitializing =>
        l10n.localGallery_errorServiceInitializing,
      LocalGalleryErrorCode.databaseFailed =>
        l10n.localGallery_errorDatabaseFailed(errorDetails),
      LocalGalleryErrorCode.refreshFailed =>
        l10n.localGallery_errorRefreshFailed(errorDetails),
      LocalGalleryErrorCode.filterFailed => l10n.localGallery_errorFilterFailed(
        errorDetails,
      ),
      LocalGalleryErrorCode.favoriteFailed =>
        l10n.localGallery_errorFavoriteFailed(errorDetails),
      LocalGalleryErrorCode.rebuildFailed =>
        l10n.localGallery_errorRebuildFailed(errorDetails),
    };
  }
}

typedef ThumbnailPreloadCallback =
    void Function(
      String originalPath, {
      required ThumbnailSize size,
      required int priority,
    });

/// 本地画廊状态
@freezed
class LocalGalleryState with _$LocalGalleryState {
  const factory LocalGalleryState({
    /// 当前页显示的记录
    @Default([]) List<LocalImageRecord> currentImages,
    @Default(0) int currentPage,
    @Default(50) int pageSize,
    @Default(false) bool isLoading,
    @Default(false) bool isIndexing,
    @Default(false) bool isPageLoading,

    /// 过滤条件
    @Default(FilterCriteria()) FilterCriteria filterCriteria,

    /// 排序字段（默认修改时间）
    @Default(GallerySortField.modifiedAt) GallerySortField sortField,

    /// 排序方向（默认降序 = 新→旧）
    @Default(GallerySortDirection.descending)
    GallerySortDirection sortDirection,

    /// 视图模式（默认瀑布流）
    @Default(GalleryViewMode.masonry) GalleryViewMode viewMode,

    /// 逻辑列宽（px，140~480，默认 260；瀑布流按它算列数）
    @Default(260.0) double columnWidth,

    /// 本地画廊缩略图质量（默认高清）
    @Default(GalleryThumbnailQuality.hd)
    GalleryThumbnailQuality thumbnailQuality,

    /// 分组视图
    @Default(false) bool isGroupedView,
    @Default([]) List<LocalImageRecord> groupedImages,
    @Default(false) bool isGroupedLoading,

    /// 后台扫描进度（0-100，null表示未开始）
    double? backgroundScanProgress,

    /// 扫描阶段
    String? scanPhase,

    /// 当前扫描的文件
    String? scanningFile,

    /// 已扫描文件数
    @Default(0) int scannedCount,

    /// 总文件数
    @Default(0) int totalScanCount,

    /// 是否正在重建索引
    @Default(false) bool isRebuildingIndex,

    /// 错误信息
    LocalGalleryError? error,

    /// 首次索引时检测到的图片数量
    int? firstTimeIndexCount,

    /// 过滤后的总数
    @Default(0) int filteredCount,

    /// 所有文件总数
    @Default(0) int totalCount,

    /// 总页数
    @Default(0) int totalPages,

    /// 是否已初始化
    @Default(false) bool isInitialized,
  }) = _LocalGalleryState;

  const LocalGalleryState._();

  /// 是否有过滤条件
  bool get hasFilters => filterCriteria.hasFilters;

  /// 是否有 naiOnly 之外的会话过滤条件（清除按钮按此显隐）
  bool get hasSessionFilters => filterCriteria.hasSessionFilters;

  /// 是否可以加载更多
  bool get canLoadMore => currentPage < totalPages - 1;

  /// 所有文件列表（兼容旧代码）
  List<LocalImageRecord> get allFiles => currentImages;

  /// 过滤后的文件列表（兼容旧代码）
  List<LocalImageRecord> get filteredFiles => currentImages;

  /// 是否是第一页
  bool get isFirstPage => currentPage == 0;

  /// 是否是最后一页
  bool get isLastPage => currentPage >= totalPages - 1;
}

/// 侧栏「收藏」节点计数——跟随画廊状态自动重查。
///
/// 任何本地画廊状态变化（删除/恢复/收藏增删/过滤重放等）都触发重查，
/// 保证侧栏计数与数据一致；状态未变时复用缓存，避免每次重建重复 SQL。
final galleryFavoriteCountProvider = FutureProvider<int>((ref) async {
  ref.watch(localGalleryNotifierProvider);
  return ref
      .read(localGalleryNotifierProvider.notifier)
      .getTotalFavoriteCount();
});

/// 本地画廊 Notifier（使用统一服务层）
///
/// 职责：
/// 1. 管理 UI 状态
/// 2. 调用统一服务层执行业务逻辑
/// 3. 处理错误并转换为友好的错误消息
@Riverpod(keepAlive: true)
class LocalGalleryNotifier extends _$LocalGalleryNotifier {
  LocalGalleryState? _cachedState;
  LocalGalleryService? _service;
  int _filterRequestSerial = 0;

  /// 最近软删路径键集（防复活屏）：服务层重建/重扫期间兜底 loadPage 会从
  /// 尚未摘除的内存文件列表取回含被删图的旧数据，这里在 loadPage 出口
  /// 强制过滤。撤销/垃圾桶恢复时经 [clearRecentlyDeleted] 解除。
  final Set<String> _recentlyDeletedKeys = {};

  /// 最近一次屏幕层的真实 DPR（页面层 didChangeDependencies 写入；
  /// 预取缩略图档位与卡片同算法同 DPR，避免档位失配重复生成）
  double _lastKnownDpr = 1.0;

  GalleryThumbnailQualityStore _thumbnailQualityStore =
      const GalleryThumbnailQualityStore();
  ThumbnailPreloadCallback? _thumbnailPreloadOverride;

  @override
  LocalGalleryState build() {
    if (_cachedState != null) return _cachedState!;

    // 监听缓存清理事件
    GalleryCacheManager().registerOnCacheCleared(_resetState);
    ref.onDispose(() {
      GalleryCacheManager().unregisterOnCacheCleared(_resetState);
    });

    return const LocalGalleryState();
  }

  void _setState(LocalGalleryState newState) {
    _cachedState = newState;
    state = newState;
  }

  void _resetState() {
    _cachedState = null;
    final service = _service;
    _service = null;
    _filterRequestSerial++;
    // 服务层排序同步回默认（修改时间 新→旧），与重置后的 state 一致
    if (service != null) {
      unawaited(service.setSort(const GallerySort.modifiedAtDesc()));
    }
    _setState(const LocalGalleryState());
  }

  /// 记录屏幕层真实 DPR（页面层 didChangeDependencies 调用），
  /// 供相邻页缩略图预取与卡片使用同一档位算法。
  void updateDevicePixelRatio(double devicePixelRatio) {
    if (devicePixelRatio <= 0) return;
    _lastKnownDpr = devicePixelRatio;
  }

  @visibleForTesting
  void setThumbnailQualityStoreForTesting(GalleryThumbnailQualityStore store) {
    _thumbnailQualityStore = store;
  }

  @visibleForTesting
  void setThumbnailPreloadCallbackForTesting(
    ThumbnailPreloadCallback? callback,
  ) {
    _thumbnailPreloadOverride = callback;
  }

  /// 获取服务实例
  ///
  /// 延迟初始化，确保在调用时才获取
  Future<LocalGalleryService> getService() async {
    if (_service == null) {
      // 等待服务初始化完成（最多10秒）
      var attempts = 0;
      const maxAttempts = 100; // 100 * 100ms = 10秒
      LocalGalleryService? lastService;
      while (attempts < maxAttempts) {
        final service = ref.read(galleryServiceProvider);
        lastService = service;

        // 【调试】记录服务类型变化
        if (attempts % 10 == 0) {
          AppLogger.d(
            'Waiting for gallery service: attempt=$attempts, type=${service.runtimeType}, isInitialized=${service.isInitialized}',
            'LocalGalleryNotifier',
          );
        }

        // 检查是否是错误状态的服务
        if (service is ErrorGalleryService) {
          throw GalleryDatabaseException(
            message: 'Gallery service initialization failed: ${service.error}',
          );
        }

        // 使用 isInitialized 检查服务是否已初始化
        if (service.isInitialized) {
          _service = service;
          AppLogger.d(
            'Gallery service ready after $attempts attempts, type=${service.runtimeType}',
            'LocalGalleryNotifier',
          );
          break;
        }
        // 等待后重试
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (_service == null) {
        final typeInfo = lastService != null
            ? ' (last type: ${lastService.runtimeType})'
            : '';
        throw GalleryDatabaseException(
          message: 'Gallery service initialization timed out$typeInfo',
        );
      }
    }
    return _service!;
  }

  // ============================================================
  // 初始化
  // ============================================================

  /// 初始化画廊
  ///
  /// 1. 初始化服务
  /// 2. 加载首页数据
  /// 3. 在后台执行索引扫描
  Future<void> initialize() async {
    // 检查是否需要初始化
    if (state.isInitialized && state.error == null) {
      return;
    }

    _setState(
      state.copyWith(
        isLoading: true,
        isIndexing: true,
        isPageLoading: true,
        error: null,
      ),
    );

    try {
      final service = await getService();

      // 检测是否为首次大量索引
      final totalCount = service.totalCount;
      final filteredCount = service.filteredCount;
      final isServiceInitialized = service.isInitialized;

      // 【调试日志】追踪计数问题
      AppLogger.d(
        'Gallery init: total=$totalCount, filtered=$filteredCount, '
            'isInitialized=$isServiceInitialized, serviceType=${service.runtimeType}',
        'LocalGalleryNotifier',
      );

      final firstTimeIndexCount = totalCount > 10000 ? totalCount : null;

      _setState(
        state.copyWith(
          totalCount: totalCount,
          filteredCount: service.filteredCount,
          firstTimeIndexCount: firstTimeIndexCount,
          isLoading: false,
          isInitialized: true,
        ),
      );

      // 加载首页
      await loadPage(0);

      // 后台扫描（通过服务层自动处理）
      _setState(state.copyWith(isIndexing: false, isPageLoading: false));
    } on GalleryPermissionDeniedException catch (e) {
      AppLogger.e('Gallery permission denied', e, null, 'LocalGalleryNotifier');
      _setState(
        state.copyWith(
          error: const LocalGalleryError(
            LocalGalleryErrorCode.permissionDenied,
          ),
          isLoading: false,
          isIndexing: false,
          isPageLoading: false,
        ),
      );
    } on GalleryScanException catch (e) {
      AppLogger.e('Gallery scan failed', e, null, 'LocalGalleryNotifier');
      _setState(
        state.copyWith(
          error: LocalGalleryError(
            LocalGalleryErrorCode.scanFailed,
            details: e.message,
          ),
          isLoading: false,
          isIndexing: false,
          isPageLoading: false,
        ),
      );
    } catch (e) {
      AppLogger.e(
        'Failed to initialize gallery',
        e,
        null,
        'LocalGalleryNotifier',
      );
      _setState(
        state.copyWith(
          error: LocalGalleryError(
            LocalGalleryErrorCode.initializationFailed,
            details: '$e',
          ),
          isLoading: false,
          isIndexing: false,
          isPageLoading: false,
        ),
      );
    }
  }

  // ============================================================
  // 数据加载
  // ============================================================

  /// 加载指定页面
  ///
  /// [page] 页码（从0开始）
  /// [showLoading] 是否显示加载状态
  Future<void> loadPage(int page, {bool showLoading = true}) async {
    if (!state.isInitialized) {
      AppLogger.w(
        'Gallery not initialized, cannot load page',
        'LocalGalleryNotifier',
      );
      return;
    }

    final requestedPage = page < 0 ? 0 : page;

    if (showLoading) {
      _setState(state.copyWith(isLoading: true, currentPage: requestedPage));
    }

    try {
      final service = await getService();

      // 计算总页数
      final totalItems = state.filterCriteria.hasFilters
          ? service.filteredCount
          : service.totalCount;
      final totalPages = (totalItems / state.pageSize).ceil();
      final maxPage = totalPages > 0 ? totalPages - 1 : 0;
      var normalizedPage = requestedPage > maxPage ? maxPage : requestedPage;

      var records = await service.getPage(
        normalizedPage,
        pageSize: state.pageSize,
      );

      // 防御性兜底：如果页码在边界变化后落入空页，自动回退到末页。
      if (records.isEmpty && normalizedPage > 0 && totalPages > 0) {
        final fallbackPage = totalPages - 1;
        if (fallbackPage != normalizedPage) {
          final fallbackRecords = await service.getPage(
            fallbackPage,
            pageSize: state.pageSize,
          );
          if (fallbackRecords.isNotEmpty) {
            normalizedPage = fallbackPage;
            records = fallbackRecords;
          }
        }
      }

      // 防复活屏：服务层重扫/重建期间 getPage 可能返回尚未摘除的软删图，
      // 这里按最近删除键集强制过滤（撤销/恢复后由 clearRecentlyDeleted 解除）
      if (_recentlyDeletedKeys.isNotEmpty) {
        final before = records.length;
        records = records
            .where(
              (r) => !_recentlyDeletedKeys.contains(galleryFilePathKey(r.path)),
            )
            .toList(growable: false);
        if (records.length != before) {}
      }
      _setState(
        state.copyWith(
          currentImages: records,
          currentPage: normalizedPage,
          totalPages: totalPages,
          filteredCount: service.filteredCount,
          totalCount: service.totalCount,
          isLoading: false,
          isPageLoading: false,
        ),
      );
      _preloadPageThumbnails(service, {
        if (normalizedPage + 1 < totalPages) normalizedPage + 1,
        if (normalizedPage > 0) normalizedPage - 1,
      }, state.pageSize);
    } on GalleryNotInitializedException {
      _setState(
        state.copyWith(
          error: const LocalGalleryError(
            LocalGalleryErrorCode.serviceInitializing,
          ),
          isLoading: false,
          isPageLoading: false,
        ),
      );
    } on GalleryDatabaseException catch (e) {
      AppLogger.e(
        'Database error loading page',
        e,
        null,
        'LocalGalleryNotifier',
      );
      _setState(
        state.copyWith(
          error: LocalGalleryError(
            LocalGalleryErrorCode.databaseFailed,
            details: e.message,
          ),
          isLoading: false,
          isPageLoading: false,
        ),
      );
    } catch (e) {
      AppLogger.e('Failed to load page $page', e, null, 'LocalGalleryNotifier');
      _setState(state.copyWith(isLoading: false, isPageLoading: false));
    }
  }

  void _preloadPageThumbnails(
    LocalGalleryService service,
    Set<int> pages,
    int pageSize, {
    GalleryThumbnailQuality? quality,
  }) {
    if (pages.isEmpty) return;
    final resolvedQuality = quality ?? state.thumbnailQuality;

    unawaited(
      () async {
        final thumbnailService = ThumbnailService.instance;
        await thumbnailService.initialize();
        final size = resolveThumbnailTier(
          state.columnWidth,
          _lastKnownDpr,
          resolvedQuality,
        );

        for (final targetPage in pages) {
          final records = await service.getPage(targetPage, pageSize: pageSize);
          for (final record in records) {
            final callback = _thumbnailPreloadOverride;
            if (callback != null) {
              callback(
                record.path,
                size: size,
                priority: ThumbnailPriority.low,
              );
            } else {
              thumbnailService.preloadThumbnail(
                record.path,
                size: size,
                priority: ThumbnailPriority.low,
              );
            }
          }
        }
      }().catchError((Object error, StackTrace stack) {
        AppLogger.w(
          'Thumbnail page preload failed: $error',
          'LocalGalleryNotifier',
        );
      }),
    );
  }

  /// 加载下一页
  Future<void> loadNextPage() async {
    if (state.isLastPage || state.isLoading) return;
    await loadPage(state.currentPage + 1);
  }

  /// 加载上一页
  Future<void> loadPreviousPage() async {
    if (state.isFirstPage || state.isLoading) return;
    await loadPage(state.currentPage - 1);
  }

  /// 刷新画廊
  ///
  /// 执行增量扫描，更新文件列表和索引
  Future<void> refresh({bool scan = true}) async {
    if (!state.isInitialized) {
      await initialize();
      return;
    }

    _setState(state.copyWith(isLoading: true));

    try {
      final service = await getService();
      await service.refresh(scan: scan);

      // 重新应用当前过滤
      await service.applyFilter(state.filterCriteria);

      _setState(
        state.copyWith(
          totalCount: service.totalCount,
          filteredCount: service.filteredCount,
          isLoading: false,
        ),
      );

      // 刷新当前页
      await loadPage(state.currentPage, showLoading: false);
    } on GalleryScanException catch (e) {
      _setState(
        state.copyWith(
          error: LocalGalleryError(
            LocalGalleryErrorCode.refreshFailed,
            details: e.message,
          ),
          isLoading: false,
        ),
      );
    } catch (e) {
      _setState(
        state.copyWith(
          error: LocalGalleryError(
            LocalGalleryErrorCode.refreshFailed,
            details: '$e',
          ),
          isLoading: false,
        ),
      );
    }
  }

  /// 添加新生成的图像到画廊（即时显示优化）
  ///
  /// 用于图像生成后即时显示新保存的图像，不触发全量扫描
  ///
  /// [filePaths] 新图像的文件路径列表
  ///
  /// 返回成功添加的图像数量
  Future<int> addNewlySavedImages(List<String> filePaths) async {
    if (!state.isInitialized || filePaths.isEmpty) {
      return 0;
    }

    var addedCount = 0;

    try {
      final service = await getService();

      for (final filePath in filePaths) {
        // 尝试即时添加新图像（不等待扫描）
        final success = await service.addNewImageImmediately(filePath);
        if (success) {
          addedCount++;
        }
      }

      if (addedCount > 0) {
        AppLogger.i(
          '[AddNewImages] Added $addedCount new images immediately',
          'LocalGalleryNotifier',
        );

        // 更新状态计数
        _setState(
          state.copyWith(
            totalCount: service.totalCount,
            filteredCount: service.filteredCount,
          ),
        );

        // 如果在第一页，刷新显示以包含新图像
        if (state.currentPage == 0) {
          await loadPage(0, showLoading: false);
        }
      }
    } catch (e) {
      AppLogger.e(
        '[AddNewImages] Failed to add new images',
        e,
        null,
        'LocalGalleryNotifier',
      );
    }

    return addedCount;
  }

  // ============================================================
  // 过滤和搜索
  // ============================================================

  Future<void> setSearchQuery(String query) async {
    final criteria = state.filterCriteria;
    if (criteria.searchQuery == query) return;

    _setState(
      state.copyWith(filterCriteria: criteria.copyWith(searchQuery: query)),
    );

    await _applyFilters();
  }

  Future<void> setSelectedTags(List<String> tags) async {
    final normalizedTags = _normalizeSelectedTags(tags);
    final criteria = state.filterCriteria;
    if (_sameStringList(criteria.selectedTags, normalizedTags)) return;

    _setState(
      state.copyWith(
        filterCriteria: criteria.copyWith(selectedTags: normalizedTags),
      ),
    );

    await _applyFilters();
  }

  Future<void> addSelectedTags(
    List<String> tags, {
    bool clearSearchQuery = false,
  }) async {
    final criteria = state.filterCriteria;
    final nextTags = _normalizeSelectedTags([
      ...criteria.selectedTags,
      ...tags,
    ]);

    if (_sameStringList(criteria.selectedTags, nextTags) &&
        (!clearSearchQuery || criteria.searchQuery.isEmpty)) {
      return;
    }

    _setState(
      state.copyWith(
        filterCriteria: criteria.copyWith(
          searchQuery: clearSearchQuery ? '' : criteria.searchQuery,
          selectedTags: nextTags,
        ),
      ),
    );

    await _applyFilters();
  }

  Future<void> removeSelectedTag(String tag) async {
    final normalizedTag = _normalizeTagKey(tag);
    if (normalizedTag.isEmpty) return;

    final criteria = state.filterCriteria;
    final nextTags = criteria.selectedTags
        .where((item) => _normalizeTagKey(item) != normalizedTag)
        .toList(growable: false);
    if (_sameStringList(criteria.selectedTags, nextTags)) return;

    _setState(
      state.copyWith(filterCriteria: criteria.copyWith(selectedTags: nextTags)),
    );

    await _applyFilters();
  }

  Future<void> setDateRange(DateTime? start, DateTime? end) async {
    final criteria = state.filterCriteria;
    if (criteria.dateStart == start && criteria.dateEnd == end) return;

    _setState(
      state.copyWith(
        filterCriteria: criteria.copyWith(
          dateStart: start,
          dateEnd: end,
          // copyWith 的默认语义是非 null 才覆盖，清空必须显式传 clear 标记
          clearDateStart: start == null,
          clearDateEnd: end == null,
        ),
      ),
    );

    await _applyFilters();
  }

  Future<void> setShowFavoritesOnly(bool value) async {
    final criteria = state.filterCriteria;
    if (criteria.showFavoritesOnly == value) return;

    _setState(
      state.copyWith(
        filterCriteria: criteria.copyWith(showFavoritesOnly: value),
      ),
    );

    await _applyFilters();
  }

  Future<void> setPageSize(int size) async {
    if (state.pageSize == size) return;

    _setState(state.copyWith(pageSize: size, currentPage: 0));

    // 更新服务层的分页大小
    try {
      final service = await getService();
      await service.setPageSize(size);
    } catch (e) {
      AppLogger.d(
        'Failed to update gallery service page size: $e',
        'LocalGallery',
      );
    }

    await loadPage(0);
  }

  /// 设置排序（字段 + 方向），生效于服务层分页与过滤链路
  Future<void> setSort(
    GallerySortField field,
    GallerySortDirection direction,
  ) async {
    if (state.sortField == field && state.sortDirection == direction) return;

    _setState(state.copyWith(sortField: field, sortDirection: direction));

    try {
      final service = await getService();
      await service.setSort(GallerySort(field: field, direction: direction));
    } catch (e) {
      AppLogger.d('Failed to update gallery sort: $e', 'LocalGallery');
    }

    await loadPage(0);
  }

  /// 设置视图模式（grid/masonry/justified），纯会话态，持久化由调用方负责
  void setViewMode(GalleryViewMode mode) {
    if (state.viewMode == mode) return;
    _setState(state.copyWith(viewMode: mode));
  }

  /// 设置逻辑列宽（实时生效于瀑布流列数；持久化由调用方负责）
  void setColumnWidth(double value) {
    if (state.columnWidth == value) return;
    _setState(state.copyWith(columnWidth: value));
  }

  /// 设置本地画廊缩略图质量：先更新画面状态，再持久化。
  Future<void> setThumbnailQuality(GalleryThumbnailQuality quality) async {
    if (state.thumbnailQuality == quality) return;
    _setState(state.copyWith(thumbnailQuality: quality));
    await _thumbnailQualityStore.save(quality);

    if (!state.isInitialized) return;
    try {
      final service = await getService();
      final totalPages = state.totalPages;
      final pages = <int>{
        if (totalPages > 0) state.currentPage,
        if (state.currentPage > 0) state.currentPage - 1,
        if (state.currentPage + 1 < totalPages) state.currentPage + 1,
      };
      _preloadPageThumbnails(service, pages, state.pageSize, quality: quality);
    } catch (e) {
      AppLogger.w(
        'Thumbnail quality preload failed: $e',
        'LocalGalleryNotifier',
      );
    }
  }

  /// 设置 NAI-only 过滤（进画廊时从持久化偏好恢复；切换时调用方负责持久化）
  Future<void> setNaiOnly(bool value) async {
    final criteria = state.filterCriteria;
    if (criteria.naiOnly == value) return;

    _setState(
      state.copyWith(filterCriteria: criteria.copyWith(naiOnly: value)),
    );

    await _applyFilters();
  }

  Future<void> setFilterModels(List<String> models) async {
    _setState(
      state.copyWith(
        filterCriteria: state.filterCriteria.copyWith(
          filterModels: models,
          clearFilterModels: models.isEmpty,
        ),
      ),
    );
    await _applyFilters();
  }

  Future<void> setFilterSamplers(List<String> samplers) async {
    _setState(
      state.copyWith(
        filterCriteria: state.filterCriteria.copyWith(
          filterSamplers: samplers,
          clearFilterSamplers: samplers.isEmpty,
        ),
      ),
    );
    await _applyFilters();
  }

  Future<void> setFilterSteps(int? min, int? max) async {
    _setState(
      state.copyWith(
        filterCriteria: state.filterCriteria.copyWith(
          filterMinSteps: min,
          filterMaxSteps: max,
          clearFilterMinSteps: min == null,
          clearFilterMaxSteps: max == null,
        ),
      ),
    );
    await _applyFilters();
  }

  Future<void> setFilterCfg(double? min, double? max) async {
    _setState(
      state.copyWith(
        filterCriteria: state.filterCriteria.copyWith(
          filterMinCfg: min,
          filterMaxCfg: max,
          clearFilterMinCfg: min == null,
          clearFilterMaxCfg: max == null,
        ),
      ),
    );
    await _applyFilters();
  }

  Future<void> setFilterResolutions(List<String> resolutions) async {
    _setState(
      state.copyWith(
        filterCriteria: state.filterCriteria.copyWith(
          filterResolutions: resolutions,
          clearFilterResolutions: resolutions.isEmpty,
        ),
      ),
    );
    await _applyFilters();
  }

  /// 设置画面方向过滤（null=全部 / 'landscape' / 'portrait' / 'square'）
  Future<void> setFilterOrientation(String? orientation) async {
    _setState(
      state.copyWith(
        filterCriteria: state.filterCriteria.copyWith(
          filterOrientation: orientation,
          clearFilterOrientation: orientation == null,
        ),
      ),
    );
    await _applyFilters();
  }

  /// 设置内容分级过滤（null=全部 / 'sfw' / 'nsfw'）
  Future<void> setNsfwMode(String? mode) async {
    _setState(
      state.copyWith(
        filterCriteria: state.filterCriteria.copyWith(
          nsfwMode: mode,
          clearNsfwMode: mode == null,
        ),
      ),
    );
    await _applyFilters();
  }

  /// 设置选中的分类
  ///
  /// [categoryId] 分类ID（null表示全部）
  /// [categoryFolderPath] 分类的文件夹路径
  Future<void> setSelectedCategory(
    String? categoryId,
    String? categoryFolderPath,
  ) async {
    final criteria = state.filterCriteria;

    // 检查是否有变化
    if (criteria.categoryId == categoryId &&
        criteria.categoryFolderPath == categoryFolderPath) {
      return;
    }

    _setState(
      state.copyWith(
        filterCriteria: criteria.copyWith(
          categoryId: categoryId,
          categoryFolderPath: categoryFolderPath,
          clearCategoryId: categoryId == null,
          clearCategoryFolderPath: categoryFolderPath == null,
        ),
      ),
    );

    await _applyFilters();
  }

  /// 设置选中的收藏集（membership 过滤；null 表示清除）
  Future<void> setSelectedCollection(String? collectionId) async {
    final criteria = state.filterCriteria;
    if (criteria.collectionId == collectionId) return;

    _setState(
      state.copyWith(
        filterCriteria: criteria.copyWith(
          collectionId: collectionId,
          clearCollectionId: collectionId == null,
        ),
      ),
    );

    await _applyFilters();
  }

  /// 设置分组视图。
  ///
  /// 视图切换不属于条件变更：切回网格只轻量重载当前页（保持页码），
  /// 不回第一页、不重跑过滤（分组期间筛选/收藏变更已同步服务层）。
  Future<void> setGroupedView(bool value) async {
    _setState(state.copyWith(isGroupedView: value));
    if (value) {
      await _loadGroupedImages();
    } else {
      await _reloadCurrentView();
    }
  }

  Future<void> _loadGroupedImages() async {
    _setState(state.copyWith(isGroupedLoading: true));
    try {
      // 加载所有过滤后的图片用于分组
      final service = await getService();
      final allRecords = <LocalImageRecord>[];

      // 分批加载所有图片
      const batchSize = 100;
      int page = 0;
      while (true) {
        final records = await service.getPage(page, pageSize: batchSize);
        if (records.isEmpty) break;
        allRecords.addAll(records);
        if (records.length < batchSize) break;
        page++;
      }

      _setState(
        state.copyWith(groupedImages: allRecords, isGroupedLoading: false),
      );
    } catch (e) {
      AppLogger.e(
        'Failed to load grouped images',
        e,
        null,
        'LocalGalleryNotifier',
      );
      _setState(state.copyWith(isGroupedLoading: false));
    }
  }

  Future<void> clearAllFilters() async {
    // 语义分界：
    // - 浏览范围（侧栏选择的表达式，清除时保留）：categoryId /
    //   categoryFolderPath / collectionId / showFavoritesOnly
    // - 常驻偏好（保留）：naiOnly（进画廊时恢复、切换时持久化）
    // - 会话筛选条件（清除）：搜索词、tag chips、日期范围、元数据/高级
    //   筛选全部维度
    // 用户在文件夹/收藏集/收藏里点「清除筛选」只清条件，停留在当前范围。
    final criteria = state.filterCriteria;
    _setState(
      state.copyWith(
        filterCriteria: FilterCriteria(
          categoryId: criteria.categoryId,
          categoryFolderPath: criteria.categoryFolderPath,
          collectionId: criteria.collectionId,
          showFavoritesOnly: criteria.showFavoritesOnly,
          naiOnly: criteria.naiOnly,
        ),
      ),
    );
    await _applyFilters();

    // 侧栏选中态（分类/收藏集）是「浏览范围」不是筛选条件，清除筛选不碰它。
  }

  /// 删除池软删后的内存级即时移除（不触发 rescan/refresh）。
  ///
  /// 文件仍在盘上（物理删除推迟到下次启动），DB 已标记 is_deleted=1；
  /// 这里把服务层内存列表与当前页/分组列表里的对应条目摘除，
  /// 图立刻从界面消失，计数同步减。后续 refresh 由 DB 软删标记兜底
  /// （扫描/文件列表均按 is_deleted 排除），不会复活。
  Future<void> removeDeletedImagesFromMemory(List<String> paths) async {
    if (paths.isEmpty) return;

    // ① state 层摘除（UI 最优先，不依赖 service——实测 getService 在
    // 服务重建/重扫期间会等待甚至 10s 超时抛出，把整个摘除链打断）
    final removedKeys = paths.map(galleryFilePathKey).toSet();
    _recentlyDeletedKeys.addAll(removedKeys);
    _setState(
      state.copyWith(
        currentImages: state.currentImages
            .where((r) => !removedKeys.contains(galleryFilePathKey(r.path)))
            .toList(growable: false),
        groupedImages: state.groupedImages
            .where((r) => !removedKeys.contains(galleryFilePathKey(r.path)))
            .toList(growable: false),
      ),
    );

    // ② 服务层内存列表摘除 + 计数/页数校正（可能等待服务就绪，不挡 UI）
    try {
      final service = await getService();
      service.removeImagesFromMemory(paths);
      _setState(
        state.copyWith(
          totalCount: service.totalCount,
          filteredCount: service.filteredCount,
        ),
      );

      // 页数校正与越界回退独立兜底（失败只影响页码，不影响列表内容）
      try {
        final nextTotalPages =
            ((state.filterCriteria.hasFilters
                        ? service.filteredCount
                        : service.totalCount) /
                    state.pageSize)
                .ceil();
        if (state.totalPages != nextTotalPages) {
          _setState(state.copyWith(totalPages: nextTotalPages));
        }
        // 当前页被删空/越界时回退到末页（不触发重扫）
        if (state.currentPage >= nextTotalPages && nextTotalPages > 0) {
          await loadPage(nextTotalPages - 1, showLoading: false);
        }
      } catch (e) {
        AppLogger.w(
          'Failed to adjust pagination after in-memory removal: $e',
          'LocalGalleryNotifier',
        );
      }
    } catch (e, stack) {
      AppLogger.e(
        'Failed to remove deleted images from memory',
        e,
        stack,
        'LocalGalleryNotifier',
      );
    }
  }

  /// 解除防复活屏（撤销/垃圾桶恢复后调用，让恢复的图能重新出现）。
  Future<void> clearRecentlyDeleted(List<String> paths) async {
    if (paths.isEmpty) return;
    _recentlyDeletedKeys.removeAll(paths.map(galleryFilePathKey));
  }

  /// 应用（重放）当前过滤条件——「条件变更」专用路径。
  ///
  /// 语义固定：重放过滤 → 回第一页。所有筛选/范围切换类调用方统一经此
  /// 入口，不再各自 pre-set currentPage（消除同函数行为依赖调用方前置
  /// 状态的隐式约定）。收藏增删等「内容变更」不走本方法，
  /// 见 [_reloadCurrentView]（保持页码）。
  Future<void> _applyFilters() async {
    // 回第一页是条件变更的固定语义，统一在此收敛。
    _setState(state.copyWith(currentPage: 0));
    try {
      final service = await getService();
      final criteria = state.filterCriteria;
      final requestSerial = ++_filterRequestSerial;

      // 【调试】记录过滤条件详情
      AppLogger.d(
        'Applying filters: hasFilters=${criteria.hasFilters}, search="${criteria.searchQuery}", '
            'dateStart=${criteria.dateStart}, dateEnd=${criteria.dateEnd}, favOnly=${criteria.showFavoritesOnly}, '
            'tags=${criteria.selectedTags}, models=${criteria.filterModels}, samplers=${criteria.filterSamplers}, '
            'steps=${criteria.filterMinSteps}-${criteria.filterMaxSteps}, cfg=${criteria.filterMinCfg}-${criteria.filterMaxCfg}, '
            'res=${criteria.filterResolutions}, orient=${criteria.filterOrientation}, nsfw=${criteria.nsfwMode}, '
            'width=${criteria.minWidth}-${criteria.maxWidth}, '
            'height=${criteria.minHeight}-${criteria.maxHeight}, fileSize=${criteria.minFileSize}-${criteria.maxFileSize}, '
            'metaStatuses=${criteria.metadataStatuses}',
        'LocalGalleryNotifier',
      );

      await service.applyFilter(criteria);

      if (requestSerial != _filterRequestSerial ||
          state.filterCriteria != criteria) {
        AppLogger.d(
          'Ignoring stale filter result: search="${criteria.searchQuery}", tags=${criteria.selectedTags}',
          'LocalGalleryNotifier',
        );
        return;
      }

      // 【调试】记录过滤结果
      AppLogger.d(
        'Filter result: total=${service.totalCount}, filtered=${service.filteredCount}, '
            'currentFilter=${service.currentFilter.hasFilters}',
        'LocalGalleryNotifier',
      );

      _setState(
        state.copyWith(
          filteredCount: service.filteredCount,
          totalCount: service.totalCount,
        ),
      );

      if (state.isGroupedView) {
        await _loadGroupedImages();
      } else {
        // 条件变更固定回第一页（本方法开头已置 currentPage=0）。
        await loadPage(0);
      }
    } on GalleryFilterException catch (e) {
      AppLogger.e('Filter failed', e, null, 'LocalGalleryNotifier');
      _setState(
        state.copyWith(
          error: LocalGalleryError(
            LocalGalleryErrorCode.filterFailed,
            details: e.message,
          ),
        ),
      );
    } catch (e) {
      AppLogger.e('Failed to apply filters', e, null, 'LocalGalleryNotifier');
    }
  }

  // ============================================================
  // 收藏
  // ============================================================

  Future<bool> toggleFavorite(String filePath) async {
    try {
      final service = await getService();
      final isFav = await service.toggleFavorite(filePath);
      final targetKey = galleryFilePathKey(filePath);

      // 更新当前页显示
      final updatedImages = state.currentImages.map((record) {
        if (galleryFilePathKey(record.path) == targetKey) {
          return record.copyWith(isFavorite: isFav);
        }
        return record;
      }).toList();

      _setState(state.copyWith(currentImages: updatedImages));

      // 取消收藏 = 从「收藏」根移除 = 同时移出所有收藏集：侧栏收藏集行计数
      // 依赖 collectionNotifier，不刷新会滞留旧值。
      if (!isFav) {
        await ref.read(collectionNotifierProvider.notifier).refresh();
      }

      // 如果启用了收藏过滤或按集合浏览，收藏/取消收藏都要重新应用：
      // 取消收藏（=从根移除=移出所有集合）会让图片从当前范围即时消失。
      // 服务层在收藏写入内部已重放过过滤，这里只轻量重载（保持页码）。
      if (state.filterCriteria.showFavoritesOnly ||
          state.filterCriteria.collectionId != null) {
        await _reloadCurrentView();
      }

      return isFav;
    } on GalleryDatabaseException catch (e) {
      AppLogger.e('Toggle favorite failed', e, null, 'LocalGalleryNotifier');
      _setState(
        state.copyWith(
          error: LocalGalleryError(
            LocalGalleryErrorCode.favoriteFailed,
            details: e.message,
          ),
        ),
      );
      return false;
    } catch (e) {
      AppLogger.e('Toggle favorite failed', e, null, 'LocalGalleryNotifier');
      return false;
    }
  }

  Future<bool> isFavorite(String filePath) async {
    try {
      final service = await getService();
      return await service.isFavorite(filePath);
    } catch (e) {
      AppLogger.e('Check favorite failed', e, null, 'LocalGalleryNotifier');
      return false;
    }
  }

  /// 从服务层重查单张图片的收藏状态并同步到当前页记录
  ///
  /// 收藏菜单「加入子集=入根」走的是 CollectionNotifier，不经过
  /// [toggleFavorite]，但卡片红心/预览图收藏按钮读的是当前页记录的
  /// [LocalImageRecord.isFavorite]——这里补一次同步，让红心即时点亮。
  /// 返回同步后的收藏状态；查询失败返回 null（不覆盖现有状态）。
  Future<bool?> syncFavoriteStatus(String filePath) async {
    try {
      final service = await getService();
      final isFav = await service.isFavorite(filePath);
      final targetKey = galleryFilePathKey(filePath);
      final updatedImages = state.currentImages.map((record) {
        if (galleryFilePathKey(record.path) == targetKey) {
          return record.copyWith(isFavorite: isFav);
        }
        return record;
      }).toList();
      _setState(state.copyWith(currentImages: updatedImages));
      return isFav;
    } catch (e) {
      AppLogger.e(
        'Sync favorite status failed',
        e,
        null,
        'LocalGalleryNotifier',
      );
      return null;
    }
  }

  /// 批量取消收藏（同时移出所有收藏集）——「从收藏根移除」语义。
  ///
  /// 返回实际取消收藏的图片数量。
  Future<int> unfavoriteImages(List<String> filePaths) async {
    try {
      final service = await getService();
      final removedCount = await service.unfavoriteImages(filePaths);

      // 更新当前页显示的收藏标记
      final targetKeys = {
        for (final path in filePaths) galleryFilePathKey(path),
      };
      final updatedImages = state.currentImages.map((record) {
        if (targetKeys.contains(galleryFilePathKey(record.path))) {
          return record.copyWith(isFavorite: false);
        }
        return record;
      }).toList();
      _setState(state.copyWith(currentImages: updatedImages));

      // 批量取消收藏同样清空所有集合的成员关系：刷新收藏集计数，
      // 否则侧栏集合行数字滞留（即使 removedCount=0 也可能有集合成员被清）。
      await ref.read(collectionNotifierProvider.notifier).refresh();

      // 按收藏根或任一集合过滤时，移除后的图片不再匹配当前范围，轻量重载
      // 当前页且保持页码（服务层在变更内部已重放过过滤，不再重复跑）。
      if (state.filterCriteria.showFavoritesOnly ||
          state.filterCriteria.collectionId != null) {
        await _reloadCurrentView();
      }
      return removedCount;
    } on GalleryDatabaseException catch (e) {
      AppLogger.e('Unfavorite batch failed', e, null, 'LocalGalleryNotifier');
      _setState(
        state.copyWith(
          error: LocalGalleryError(
            LocalGalleryErrorCode.favoriteFailed,
            details: e.message,
          ),
        ),
      );
      return 0;
    } catch (e) {
      AppLogger.e('Unfavorite batch failed', e, null, 'LocalGalleryNotifier');
      return 0;
    }
  }

  /// 轻量重载当前视图——「内容变更」专用路径。
  ///
  /// 前置契约（跨层约定）：服务层内存过滤列表必须已是变更后状态——
  /// 收藏写入由 `LocalGalleryServiceImpl._syncFileListsAfterFavoriteChange`
  /// 在内部重放过滤；删除由 `removeImagesFromMemory` 摘除。本方法只同步
  /// 计数并重载当前页/分组列表，保持页码（越界/空页由 loadPage 兜底回退
  /// 末页），不重复跑过滤——收藏视图下取消收藏卡顿的根源就是过滤被串行
  /// 跑两遍。调用方：收藏 toggle / 批量取消收藏 / 分组视图切回网格。
  Future<void> _reloadCurrentView() async {
    try {
      final service = await getService();
      _setState(
        state.copyWith(
          filteredCount: service.filteredCount,
          totalCount: service.totalCount,
        ),
      );
    } catch (e) {
      AppLogger.w(
        'Failed to sync counts after favorite change: $e',
        'LocalGalleryNotifier',
      );
    }
    if (state.isGroupedView) {
      await _loadGroupedImages();
    } else {
      await loadPage(state.currentPage, showLoading: false);
    }
  }

  Future<int> getTotalFavoriteCount() async {
    try {
      final service = await getService();
      return await service.getFavoriteCount();
    } catch (e) {
      AppLogger.e('Get favorite count failed', e, null, 'LocalGalleryNotifier');
      return 0;
    }
  }

  // ============================================================
  // 元数据
  // ============================================================

  Future<NaiImageMetadata?> getMetadata(String filePath) async {
    try {
      final service = await getService();
      return await service.getMetadata(filePath);
    } on GalleryMetadataException catch (e) {
      AppLogger.w('Get metadata failed: ${e.message}', 'LocalGalleryNotifier');
      return null;
    } catch (e) {
      AppLogger.e('Get metadata failed', e, null, 'LocalGalleryNotifier');
      return null;
    }
  }

  Future<List<String>> getFilteredImagePaths() async {
    try {
      final service = await getService();
      return await service.getFilteredImagePaths();
    } catch (e) {
      AppLogger.e(
        'Get filtered image paths failed',
        e,
        null,
        'LocalGalleryNotifier',
      );
      return [];
    }
  }

  // ============================================================
  // 索引管理
  // ============================================================

  bool _shouldCancelRebuild = false;

  /// 重新扫描（全量扫描）
  ///
  /// 使用统一的流式扫描逻辑：
  /// - 检查数据一致性（标记不存在的文件）
  /// - 查漏补缺（新文件、变更文件）
  /// - 提取元数据
  Future<void> performFullScan() async {
    if (state.isRebuildingIndex) {
      _shouldCancelRebuild = true;
      return;
    }

    // 检查是否已有扫描在进行中
    if (ScanStateManager.instance.isScanning) {
      AppLogger.w(
        '[LocalGallery] Scan already in progress, skipping',
        'LocalGalleryNotifier',
      );
      return;
    }

    _shouldCancelRebuild = false;
    _setState(state.copyWith(isRebuildingIndex: true, isLoading: true));

    try {
      // 主源 + 全部存在的额外源
      final rootDirs = await GalleryFolderRepository.instance.getAllRootDirs();
      if (rootDirs.isEmpty) {
        throw const GalleryScanException(
          message: 'Gallery directory is not configured',
        );
      }

      // 使用统一的流式扫描器
      final dataSource = GalleryDataSource();
      final scanner = GalleryStreamScanner(dataSource: dataSource);

      await scanner.startScanning(
        rootDirs,
        retryMissingMetadata: true,
        retryFailedMetadata: true,
        onFileProcessed: (result, stats) {
          AppLogger.d(
            '[FullScan] Processed: ${result.path.split(Platform.pathSeparator).last}, '
                'stage: ${result.stage}',
            'LocalGalleryNotifier',
          );
        },
      );

      if (_shouldCancelRebuild) {
        _shouldCancelRebuild = false;
        _setState(state.copyWith(isRebuildingIndex: false, isLoading: false));
        return;
      }

      // 刷新服务状态
      final service = await getService();

      // 刷新状态
      _setState(
        state.copyWith(
          totalCount: service.totalCount,
          filteredCount: service.filteredCount,
          isRebuildingIndex: false,
          isLoading: false,
        ),
      );

      // 刷新当前页
      await loadPage(0, showLoading: false);
    } on GalleryCancelledException {
      _setState(state.copyWith(isRebuildingIndex: false, isLoading: false));
    } on GalleryScanException catch (e) {
      AppLogger.e('Full scan failed', e, null, 'LocalGalleryNotifier');
      _setState(
        state.copyWith(
          error: LocalGalleryError(
            LocalGalleryErrorCode.rebuildFailed,
            details: e.message,
          ),
          isRebuildingIndex: false,
          isLoading: false,
        ),
      );
    } catch (e) {
      AppLogger.e('Full scan failed', e, null, 'LocalGalleryNotifier');
      _setState(
        state.copyWith(
          error: LocalGalleryError(
            LocalGalleryErrorCode.rebuildFailed,
            details: '$e',
          ),
          isRebuildingIndex: false,
          isLoading: false,
        ),
      );
    }
  }

  // ============================================================
  // 标签（保持向后兼容）
  // ============================================================

  Future<List<String>> getTags(String filePath) async {
    // 从当前加载的记录中查找
    final record = state.currentImages.firstWhere(
      (r) => r.path == filePath,
      orElse: () =>
          LocalImageRecord(path: filePath, size: 0, modifiedAt: DateTime.now()),
    );
    return record.tags;
  }

  Future<void> setTags(String filePath, List<String> tags) async {
    // 标签操作通过数据源直接处理
    // 这里只更新本地状态
    final updatedImages = state.currentImages.map((record) {
      if (record.path == filePath) {
        return record.copyWith(tags: tags);
      }
      return record;
    }).toList();

    _setState(state.copyWith(currentImages: updatedImages));
  }

  // ============================================================
  // 工具方法
  // ============================================================

  /// 清除错误状态
  void clearError() {
    _setState(state.copyWith(error: null));
  }

  List<String> _normalizeSelectedTags(List<String> tags) {
    final result = <String>[];
    final seen = <String>{};

    for (final tag in tags) {
      final trimmed = tag.trim();
      final key = _normalizeTagKey(trimmed);
      if (key.isEmpty || seen.contains(key)) continue;

      seen.add(key);
      result.add(trimmed);
    }

    return List.unmodifiable(result);
  }

  String _normalizeTagKey(String tag) {
    return tag
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _sameStringList(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }
}
