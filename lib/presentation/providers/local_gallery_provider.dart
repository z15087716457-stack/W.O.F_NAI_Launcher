import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/cache/gallery_cache_manager.dart';
import '../../core/cache/thumbnail_cache_service.dart'
    show GalleryThumbnailQuality;
import '../../core/exceptions/gallery_exceptions.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/gallery_path_utils.dart';
import '../../data/models/gallery/local_image_record.dart';
import '../../data/models/gallery/nai_image_metadata.dart';
import '../../core/database/datasources/gallery_data_source.dart';
import '../../data/repositories/gallery_folder_repository.dart';
import '../../data/services/gallery/gallery_filter_service.dart';
import '../../data/services/gallery/gallery_file_changes.dart';
import '../../data/services/gallery/gallery_group_mode.dart';
import '../../data/services/gallery/gallery_thumbnail_quality_store.dart';
import '../../data/services/gallery/gallery_sort.dart';
import '../../data/services/gallery/gallery_stream_scanner.dart';
import '../../data/services/gallery/gallery_view_mode.dart';
import '../../data/services/gallery/scan_state_manager.dart';
import '../../data/services/gallery/unified_gallery_service.dart';
import '../../l10n/app_localizations.dart';
import '../../core/rag/rag_client.dart';
import '../../core/rag/rag_settings.dart';
import '../../core/rag/rag_gallery_search.dart';
import 'rag_provider.dart';
import 'gallery_rag_query_provider.dart';
import 'collection_provider.dart';
import 'gallery_category_provider.dart';

part 'local_gallery_provider.freezed.dart';
part 'local_gallery_provider.g.dart';

final galleryFileMonitorProvider = Provider<GalleryFileMonitor>((ref) {
  final folders = GalleryFolderRepository.instance;
  final monitor = GalleryFileMonitor(
    loadRoots: folders.getAllRootDirs,
    rootsChanged: folders.rootsChanged,
    apply: (changes) async {
      await ref
          .read(localGalleryNotifierProvider.notifier)
          .applyFileChanges(changes);
      await ref
          .read(galleryCategoryNotifierProvider.notifier)
          .applyFileChanges(changes);
    },
    onError: (error, stack) {
      AppLogger.e('Gallery file update failed', error, stack, 'LocalGallery');
      ref
          .read(localGalleryNotifierProvider.notifier)
          .reportFileChangeError(error);
    },
  );
  ref.onDispose(() => unawaited(monitor.dispose()));
  return monitor;
});

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

/// 连续画廊的数据集：当前过滤与排序下的全部轻量条目。
///
/// 按身份比较（不覆写 ==），整库条目不参与 freezed 深比较；
/// [datasetId] 只在筛选/范围/排序变化时递增，视图据此回到顶部，
/// 删除、收藏、新增等内容变化保持滚动位置。
class GalleryTimeline {
  const GalleryTimeline(
    this.entries, {
    required this.datasetId,
    this.semanticRanked = false,
  });

  static const empty = GalleryTimeline(<GalleryTimelineEntry>[], datasetId: 0);

  final List<GalleryTimelineEntry> entries;
  final int datasetId;
  final bool semanticRanked;

  static final Expando<Map<String, int>> _indexCache = Expando();

  int get length => entries.length;
  bool get isEmpty => entries.isEmpty;

  /// 路径 → 索引（按 [galleryFilePathKey] 归一化；首次查询时建表）
  int indexOfPath(String path) {
    final index = _indexCache[this] ??= {
      for (var i = 0; i < entries.length; i++)
        galleryFilePathKey(entries[i].path): i,
    };
    return index[galleryFilePathKey(path)] ?? -1;
  }
}

/// 本地画廊状态
@freezed
class LocalGalleryState with _$LocalGalleryState {
  const factory LocalGalleryState({
    /// 当前过滤与排序下的全部条目（连续滚动，无分页）
    @Default(GalleryTimeline.empty) GalleryTimeline timeline,

    /// 记录缓存版本：可见区域的完整记录加载完成后递增
    @Default(0) int recordsRevision,

    /// 内容版本：收藏、删除、新增、刷新等内容变化时递增
    @Default(0) int contentRevision,
    @Default(false) bool isLoading,
    @Default(false) bool isIndexing,

    /// 过滤条件
    @Default(FilterCriteria()) FilterCriteria filterCriteria,

    /// 排序字段（默认修改时间）
    @Default(GallerySortField.modifiedAt) GallerySortField sortField,

    /// 排序方向（默认降序 = 新→旧）
    @Default(GallerySortDirection.descending)
    GallerySortDirection sortDirection,

    /// 视图模式（默认等高行）
    @Default(GalleryViewMode.justified) GalleryViewMode viewMode,

    /// 按时间分组方式（仅按修改/创建时间排序时生效）
    @Default(GalleryGroupMode.day) GalleryGroupMode groupMode,

    /// 缩略图目标边长（px，140~480，默认 260）
    @Default(260.0) double columnWidth,

    /// 本地画廊缩略图质量（默认高清）
    @Default(GalleryThumbnailQuality.hd)
    GalleryThumbnailQuality thumbnailQuality,

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

    /// 是否已初始化
    @Default(false) bool isInitialized,
  }) = _LocalGalleryState;

  const LocalGalleryState._();

  /// 是否有过滤条件
  bool get hasFilters => filterCriteria.hasFilters;

  /// 是否有 naiOnly 之外的会话过滤条件（清除按钮按此显隐）
  bool get hasSessionFilters =>
      filterCriteria.hasSessionFilters || timeline.semanticRanked;

  /// 当前结果数（有过滤时为过滤结果数）
  int get resultCount =>
      hasFilters || timeline.semanticRanked ? filteredCount : totalCount;

  /// 当前排序是否按时间（按天/月分组只在时间排序下有意义）
  bool get isTimeSorted =>
      sortField == GallerySortField.modifiedAt ||
      sortField == GallerySortField.createdAt;

  /// 实际生效的分组方式
  GalleryGroupMode get effectiveGroupMode =>
      isTimeSorted && !timeline.semanticRanked
      ? groupMode
      : GalleryGroupMode.none;
}

/// 顶栏与筛选条用的画廊状态：去掉时间线与记录/内容版本，
/// 滚动加载记录、收藏等内容变化时不重建工具栏。
final localGalleryChromeStateProvider = Provider<LocalGalleryState>((ref) {
  return ref.watch(
    localGalleryNotifierProvider.select(
      (state) => state.copyWith(
        timeline: GalleryTimeline(
          const [],
          datasetId: 0,
          semanticRanked: state.timeline.semanticRanked,
        ),
        recordsRevision: 0,
        contentRevision: 0,
      ),
    ),
  );
});

/// 侧栏「收藏」节点计数——收藏、删除、刷新等内容变化时重查。
///
/// 只跟随内容版本与数据集，不随滚动加载记录重复查询。
final galleryFavoriteCountProvider = FutureProvider<int>((ref) async {
  ref.watch(
    localGalleryNotifierProvider.select(
      (state) => (state.contentRevision, state.timeline),
    ),
  );
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
  int _timelineSerial = 0;
  RagCancellation? _ragCancellation;
  Timer? _ragRefresh;
  ({FilterCriteria criteria, RagGalleryMode mode, String image})?
  _semanticQuery;

  /// 最近软删路径键集（防复活屏）：服务层重建/重扫期间时间线可能从
  /// 尚未摘除的内存文件列表取回含被删图的旧数据，这里在出口强制过滤。
  /// 撤销/垃圾桶恢复时经 [clearRecentlyDeleted] 解除。
  final Set<String> _recentlyDeletedKeys = {};

  /// 完整记录缓存（按路径键，LRU）：只为可见区域、详情面板与大图窗口加载。
  final LinkedHashMap<String, LocalImageRecord> _records = LinkedHashMap();

  /// 刷新后仍可显示、但需要重新读取的记录键
  final Set<String> _staleRecordKeys = {};
  final Map<String, String> _pendingRecordPaths = {};

  /// 请求过但服务层未返回记录的键（文件已不存在等），刷新前不再重复请求
  final Set<String> _unavailableRecordKeys = {};
  bool _recordFlushScheduled = false;
  int _recordGeneration = 0;

  static const int _recordCacheLimit = 6000;
  static const int _recordBatchSize = 160;

  GalleryThumbnailQualityStore _thumbnailQualityStore =
      const GalleryThumbnailQualityStore();

  @override
  LocalGalleryState build() {
    if (_cachedState != null) return _cachedState!;

    // 监听缓存清理事件
    GalleryCacheManager().registerOnCacheCleared(_resetState);
    ref.onDispose(() {
      GalleryCacheManager().unregisterOnCacheCleared(_resetState);
      _ragCancellation?.cancel();
      _ragRefresh?.cancel();
    });
    void refreshRag({bool preserveSemantic = false}) {
      _ragCancellation?.cancel();
      _ragRefresh?.cancel();
      _ragRefresh = Timer(const Duration(milliseconds: 180), () {
        if (state.isInitialized) {
          unawaited(
            _reloadTimeline(
              newDataset: false,
              preserveSemantic: preserveSemantic,
            ),
          );
        }
      });
    }

    ref.listen(
      ragSettingsProvider.select((s) => s.enabledFor(RagSource.gallery)),
      (_, __) => refreshRag(),
    );
    ref.listen(galleryRagQueryProvider, (_, __) => refreshRag());
    ref.listen(
      ragControllerProvider.select((s) {
        final g = s.forSource(RagSource.gallery);
        return (g.available, g.complete, s.suspended, g.indexed > 0);
      }),
      (previous, next) {
        // Temporary errors and GPU suspension do not invalidate already
        // completed results. Requery on recovery without first erasing them.
        if (next.$1) {
          refreshRag(preserveSemantic: true);
        } else if (previous?.$4 == true && !next.$4) {
          refreshRag(); // An explicitly cleared index has no semantic results.
        }
      },
    );

    return const LocalGalleryState();
  }

  void _setState(LocalGalleryState newState) {
    _cachedState = newState;
    state = newState;
  }

  void _resetState() {
    _ragCancellation?.cancel();
    _ragRefresh?.cancel();
    _cachedState = null;
    _semanticQuery = null;
    final service = _service;
    _service = null;
    _filterRequestSerial++;
    _timelineSerial++;
    _clearRecordCache();
    // 服务层排序同步回默认（修改时间 新→旧），与重置后的 state 一致
    if (service != null) {
      unawaited(service.setSort(const GallerySort.modifiedAtDesc()));
    }
    _setState(const LocalGalleryState());
  }

  @visibleForTesting
  void setThumbnailQualityStoreForTesting(GalleryThumbnailQualityStore store) {
    _thumbnailQualityStore = store;
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
  /// 2. 读取当前范围的全部轻量条目
  /// 3. 在后台执行索引扫描
  Future<void> initialize() async {
    // 检查是否需要初始化
    if (state.isInitialized && state.error == null) {
      return;
    }

    _setState(state.copyWith(isLoading: true, isIndexing: true, error: null));

    try {
      final service = await getService();

      // 一次性应用初始化前恢复的排序偏好
      if (state.sortField != GallerySortField.modifiedAt ||
          state.sortDirection != GallerySortDirection.descending) {
        await service.setSort(
          GallerySort(field: state.sortField, direction: state.sortDirection),
        );
      }

      // 一次性应用初始化前恢复的过滤偏好（如 NAI-only 等）
      if (state.filterCriteria.hasFilters) {
        await service.applyFilter(state.filterCriteria);
      }

      final totalCount = service.totalCount;
      AppLogger.d(
        'Gallery init: total=$totalCount, filtered=${service.filteredCount}, '
            'isInitialized=${service.isInitialized}, serviceType=${service.runtimeType}',
        'LocalGalleryNotifier',
      );

      _setState(
        state.copyWith(
          totalCount: totalCount,
          filteredCount: service.filteredCount,
          firstTimeIndexCount: totalCount > 10000 ? totalCount : null,
          isInitialized: true,
        ),
      );

      await _reloadTimeline(newDataset: true);

      // 后台扫描（通过服务层自动处理）
      _setState(state.copyWith(isIndexing: false, isLoading: false));
    } on GalleryPermissionDeniedException catch (e) {
      AppLogger.e('Gallery permission denied', e, null, 'LocalGalleryNotifier');
      _setState(
        state.copyWith(
          error: const LocalGalleryError(
            LocalGalleryErrorCode.permissionDenied,
          ),
          isLoading: false,
          isIndexing: false,
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
        ),
      );
    }
  }

  // ============================================================
  // 时间线与记录
  // ============================================================

  /// 重新读取当前范围的全部条目。
  ///
  /// [newDataset] 为 true 表示筛选/范围/排序变化（视图回到顶部）；
  /// false 表示内容变化（保持滚动位置）。
  Future<void> _reloadTimeline({
    required bool newDataset,
    bool preserveSemantic = false,
  }) async {
    final serial = ++_timelineSerial;
    _ragCancellation?.cancel();
    try {
      final service = await getService();
      var entries = await service.getTimelineEntries();
      if (serial != _timelineSerial) return;

      // 防复活屏：服务层重扫/重建期间可能返回尚未摘除的软删图
      if (_recentlyDeletedKeys.isNotEmpty) {
        entries = entries
            .where(
              (e) => !_recentlyDeletedKeys.contains(galleryFilePathKey(e.path)),
            )
            .toList(growable: false);
      }
      final current = state.timeline;
      final options = ref.read(galleryRagQueryProvider);
      final keepSemantic =
          preserveSemantic &&
          !newDataset &&
          current.semanticRanked &&
          _semanticQuery ==
              (
                criteria: state.filterCriteria,
                mode: options.mode,
                image: options.image,
              );
      if (!keepSemantic) {
        _semanticQuery = null;
        _setState(
          state.copyWith(
            timeline: GalleryTimeline(
              entries,
              datasetId: newDataset ? current.datasetId + 1 : current.datasetId,
            ),
            filteredCount: service.filteredCount,
            totalCount: service.totalCount,
            contentRevision: state.contentRevision + 1,
            isLoading: false,
          ),
        );
      }
      if (ref.read(ragSettingsProvider).enabledFor(RagSource.gallery)) {
        unawaited(
          _loadGalleryRag(
            serial,
            service,
            entries,
            state.filterCriteria,
            ref.read(galleryRagQueryProvider),
            preserveSemantic: keepSemantic,
          ),
        );
      }
    } on GalleryNotInitializedException {
      _setState(
        state.copyWith(
          error: const LocalGalleryError(
            LocalGalleryErrorCode.serviceInitializing,
          ),
          isLoading: false,
        ),
      );
    } on GalleryDatabaseException catch (e) {
      AppLogger.e(
        'Database error loading timeline',
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
        ),
      );
    } catch (e) {
      AppLogger.e('Failed to load timeline', e, null, 'LocalGalleryNotifier');
      _setState(state.copyWith(isLoading: false));
    }
  }

  Future<void> _loadGalleryRag(
    int serial,
    LocalGalleryService service,
    List<GalleryTimelineEntry> ordinary,
    FilterCriteria criteria,
    RagGalleryQueryOptions options, {
    bool preserveSemantic = false,
  }) async {
    if (criteria.searchQuery.trim().isEmpty && options.image.isEmpty) return;
    final status = ref.read(ragControllerProvider).forSource(RagSource.gallery);
    if (status.indexed == 0 || status.suspended) {
      return;
    }
    final cancellation = _ragCancellation = RagCancellation();
    try {
      final scope = await service.getTimelineForFilter(
        criteria.copyWith(searchQuery: ''),
      );
      if (cancellation.isCancelled || serial != _timelineSerial) return;
      final hits = await ref
          .read(ragControllerProvider.notifier)
          .searchGallery(
            query: criteria.searchQuery,
            allowed: scope.map((e) => e.path).toList(),
            image: options.image,
            mode: options.mode,
            cancellation: cancellation,
          );
      if (cancellation.isCancelled ||
          serial != _timelineSerial ||
          state.filterCriteria != criteria ||
          !ref.read(ragSettingsProvider).enabledFor(RagSource.gallery)) {
        return;
      }
      final allowed = {
        for (final entry in scope) galleryFilePathKey(entry.path): entry,
      };
      final seen = <String>{};
      final result = <GalleryTimelineEntry>[];
      if (options.image.isEmpty || criteria.searchQuery.trim().isNotEmpty) {
        for (final entry in ordinary) {
          final key = galleryFilePathKey(entry.path);
          if (!_recentlyDeletedKeys.contains(key) && seen.add(key)) {
            result.add(entry);
          }
        }
      }
      final count = result.length;
      for (final hit in hits) {
        final key = galleryFilePathKey(hit.path);
        if (allowed[key] != null &&
            !_recentlyDeletedKeys.contains(key) &&
            seen.add(key)) {
          result.add(allowed[key]!);
        }
      }
      if (result.length == count &&
          options.image.isEmpty &&
          !preserveSemantic) {
        return;
      }
      final ranked = result.length > count || options.image.isNotEmpty;
      _semanticQuery = ranked
          ? (criteria: criteria, mode: options.mode, image: options.image)
          : null;
      _setState(
        state.copyWith(
          timeline: GalleryTimeline(
            result,
            datasetId: state.timeline.datasetId,
            semanticRanked: ranked,
          ),
          filteredCount: result.length,
          contentRevision: state.contentRevision + 1,
        ),
      );
    } catch (_) {
      // Keep native filename/prompt search usable when vectors are unavailable.
    }
  }

  /// 内容变化后重读条目并保持滚动位置（删除池恢复、外部移动后调用）。
  Future<void> reloadTimeline() async {
    if (!state.isInitialized) return;
    await _reloadTimeline(newDataset: false);
  }

  /// 已缓存的完整记录（未加载时返回 null，不触发加载）。
  LocalImageRecord? cachedRecord(String path) =>
      _records[galleryFilePathKey(path)];

  /// 卡片显示用记录：已加载时返回完整记录，否则返回只含路径与时间的占位。
  LocalImageRecord recordFor(GalleryTimelineEntry entry) =>
      cachedRecord(entry.path) ??
      LocalImageRecord(path: entry.path, size: 0, modifiedAt: entry.modifiedAt);

  /// 为可见区域请求完整记录（合批、去重；已缓存且未过期的跳过）。
  void ensureRecords(Iterable<String> paths) {
    if (!state.isInitialized) return;
    var added = false;
    for (final path in paths) {
      final key = galleryFilePathKey(path);
      if (_records.containsKey(key) && !_staleRecordKeys.contains(key)) {
        continue;
      }
      if (_pendingRecordPaths.containsKey(key) ||
          _unavailableRecordKeys.contains(key)) {
        continue;
      }
      _pendingRecordPaths[key] = path;
      added = true;
    }
    if (added) _scheduleRecordFlush();
  }

  /// 按路径读取完整记录（详情面板、大图窗口用；按传入顺序返回已存在的记录）。
  Future<List<LocalImageRecord>> loadRecords(List<String> paths) async {
    final missing = <String>[
      for (final path in paths)
        if (!_records.containsKey(galleryFilePathKey(path)) ||
            _staleRecordKeys.contains(galleryFilePathKey(path)))
          path,
    ];
    if (missing.isNotEmpty) {
      try {
        final service = await getService();
        final generation = _recordGeneration;
        final loaded = await service.getRecordsForPaths(missing);
        if (generation == _recordGeneration) {
          _storeRecords(loaded);
          _setState(state.copyWith(recordsRevision: state.recordsRevision + 1));
        }
      } catch (e) {
        AppLogger.w('Failed to load gallery records: $e', 'LocalGallery');
      }
    }
    return [
      for (final path in paths)
        if (_records[galleryFilePathKey(path)] case final record?) record,
    ];
  }

  void _scheduleRecordFlush() {
    if (_recordFlushScheduled) return;
    _recordFlushScheduled = true;
    scheduleMicrotask(() => unawaited(_flushRecordRequests()));
  }

  Future<void> _flushRecordRequests() async {
    try {
      final service = await getService();
      while (_pendingRecordPaths.isNotEmpty) {
        final batchKeys = _pendingRecordPaths.keys
            .take(_recordBatchSize)
            .toList(growable: false);
        final batchPaths = [
          for (final key in batchKeys) _pendingRecordPaths[key]!,
        ];
        final generation = _recordGeneration;
        List<LocalImageRecord> loaded;
        try {
          loaded = await service.getRecordsForPaths(batchPaths);
        } catch (e) {
          AppLogger.w('Failed to load visible records: $e', 'LocalGallery');
          loaded = const [];
        }
        for (final key in batchKeys) {
          _pendingRecordPaths.remove(key);
        }
        if (generation != _recordGeneration) continue;
        _storeRecords(loaded);
        // 未返回的条目（文件已不存在等）刷新前不再反复请求
        final loadedKeys = {
          for (final record in loaded) galleryFilePathKey(record.path),
        };
        for (final key in batchKeys) {
          if (!loadedKeys.contains(key)) _unavailableRecordKeys.add(key);
        }
        _setState(state.copyWith(recordsRevision: state.recordsRevision + 1));
      }
    } catch (e) {
      AppLogger.w('Gallery records unavailable: $e', 'LocalGallery');
      _pendingRecordPaths.clear();
    } finally {
      _recordFlushScheduled = false;
      if (_pendingRecordPaths.isNotEmpty) _scheduleRecordFlush();
    }
  }

  void _storeRecords(List<LocalImageRecord> records) {
    for (final record in records) {
      final key = galleryFilePathKey(record.path);
      _records.remove(key);
      _records[key] = record;
      _staleRecordKeys.remove(key);
    }
    while (_records.length > _recordCacheLimit) {
      _records.remove(_records.keys.first);
    }
  }

  /// 刷新后保留旧记录用于显示，但下次可见时重新读取。
  void _markRecordsStale() {
    _staleRecordKeys.addAll(_records.keys);
    _unavailableRecordKeys.clear();
  }

  void _clearRecordCache() {
    _recordGeneration++;
    _records.clear();
    _staleRecordKeys.clear();
    _pendingRecordPaths.clear();
    _unavailableRecordKeys.clear();
  }

  /// 就地更新已缓存记录（收藏、标签等），并通知视图。
  void _updateCachedRecords(
    Set<String> keys,
    LocalImageRecord Function(LocalImageRecord record) update,
  ) {
    var changed = false;
    for (final key in keys) {
      final record = _records[key];
      if (record == null) continue;
      _records[key] = update(record);
      changed = true;
    }
    if (changed) {
      _setState(state.copyWith(recordsRevision: state.recordsRevision + 1));
    }
  }

  /// 刷新画廊
  ///
  /// 执行增量扫描，更新文件列表和索引
  Future<void> refresh({bool scan = true}) async {
    if (!state.isInitialized) {
      await initialize();
      return;
    }

    _setState(state.copyWith(isLoading: true, error: null));

    try {
      final service = await getService();
      await service.refresh(scan: scan);

      // 重新应用当前过滤
      await service.applyFilter(state.filterCriteria);
      _markRecordsStale();

      _setState(
        state.copyWith(
          totalCount: service.totalCount,
          filteredCount: service.filteredCount,
        ),
      );

      await _reloadTimeline(newDataset: false);
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

  /// Update event paths while keeping the dataset and unrelated record caches.
  Future<void> applyFileChanges(GalleryFileChanges changes) async {
    final service = await getService();
    final changed = await service.applyFileChanges(changes);
    if (changed.isEmpty) return;
    _recordGeneration++;
    for (final path in changed) {
      await FileImage(File(path)).evict();
      final key = galleryFilePathKey(path);
      _staleRecordKeys.add(key);
      _unavailableRecordKeys.remove(key);
    }
    await _reloadTimeline(newDataset: false);
  }

  void reportFileChangeError(Object error) {
    _setState(
      state.copyWith(
        error: LocalGalleryError(
          LocalGalleryErrorCode.refreshFailed,
          details: error.toString(),
        ),
      ),
    );
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
        await _reloadTimeline(newDataset: false);
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
    if (criteria.dateStart == start &&
        criteria.dateEnd == end &&
        !criteria.indexedDate &&
        !criteria.dateEndExclusive) {
      return;
    }

    _setState(
      state.copyWith(
        filterCriteria: criteria.copyWith(
          dateStart: start,
          dateEnd: end,
          indexedDate: false,
          dateEndExclusive: false,
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

  /// 设置排序（字段 + 方向），生效于服务层排序与过滤链路
  Future<void> setSort(
    GallerySortField field,
    GallerySortDirection direction,
  ) async {
    if (state.sortField == field && state.sortDirection == direction) return;

    _setState(state.copyWith(sortField: field, sortDirection: direction));

    // 未初始化时不触发底层服务查询与分页，由 initialize() 一次性应用
    if (!state.isInitialized) return;

    try {
      final service = await getService();
      await service.setSort(GallerySort(field: field, direction: direction));
    } catch (e) {
      AppLogger.d('Failed to update gallery sort: $e', 'LocalGallery');
    }

    await _reloadTimeline(newDataset: true);
  }

  /// 设置视图模式（grid/masonry/justified），纯会话态，持久化由调用方负责
  void setViewMode(GalleryViewMode mode) {
    if (state.viewMode == mode) return;
    _setState(state.copyWith(viewMode: mode));
  }

  /// 设置缩略图目标边长（实时重排；持久化由调用方负责）
  void setColumnWidth(double value) {
    if (state.columnWidth == value) return;
    _setState(state.copyWith(columnWidth: value));
  }

  /// 设置按时间分组方式（纯会话态，持久化由调用方负责）
  void setGroupMode(GalleryGroupMode mode) {
    if (state.groupMode == mode) return;
    _setState(state.copyWith(groupMode: mode));
  }

  /// 设置本地画廊缩略图质量：先更新画面状态，再持久化。
  ///
  /// 可见卡片监听质量自行换档；视图按新档位预取邻近缩略图。
  Future<void> setThumbnailQuality(GalleryThumbnailQuality quality) async {
    if (state.thumbnailQuality == quality) return;
    _setState(state.copyWith(thumbnailQuality: quality));
    await _thumbnailQualityStore.save(quality);
  }

  /// 设置 NAI-only 过滤（进画廊时从持久化偏好恢复；切换时调用方负责持久化）
  Future<void> setNaiOnly(bool value) async {
    final criteria = state.filterCriteria;
    if (criteria.naiOnly == value) return;

    _setState(
      state.copyWith(filterCriteria: criteria.copyWith(naiOnly: value)),
    );

    // 未初始化时不触发底层过滤查询，由 initialize() 一次性应用
    if (!state.isInitialized) return;

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

  /// A physical directory move keeps the current category identity and the
  /// user's other filters. The caller refreshes the same dataset afterward.
  void rebindCategoryFolderPaths(
    Map<String, String> paths, {
    Set<String> removed = const {},
  }) {
    final criteria = state.filterCriteria;
    final id = criteria.categoryId;
    if (id == null) return;
    if (removed.contains(id)) {
      _setState(
        state.copyWith(
          filterCriteria: criteria.copyWith(
            clearCategoryId: true,
            clearCategoryFolderPath: true,
          ),
        ),
      );
    } else if (paths.containsKey(id) &&
        paths[id] != criteria.categoryFolderPath) {
      _setState(
        state.copyWith(
          filterCriteria: criteria.copyWith(categoryFolderPath: paths[id]),
        ),
      );
    }
  }

  /// Show a newly imported gallery root in one filter update. Old search,
  /// collection and favorites filters must not hide the imported images.
  Future<void> showImportedCategory(
    String categoryId,
    String folderPath,
  ) async {
    _setState(
      state.copyWith(
        filterCriteria: FilterCriteria(
          categoryId: categoryId,
          categoryFolderPath: folderPath,
          naiOnly: state.filterCriteria.naiOnly,
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

  Future<void> applyExternalFilter(FilterCriteria criteria) async {
    _setState(state.copyWith(filterCriteria: criteria));
    await _applyFilters();
  }

  Future<void> clearAllFilters() async {
    ref.read(galleryRagQueryProvider.notifier).clearImage();
    // 语义分界：
    // - 浏览范围（侧栏选择的表达式，清除时保留）：categoryId /
    //   categoryFolderPath / collectionId / showFavoritesOnly
    // - 常驻偏好（保留）：naiOnly（进画廊时恢复、切换时持久化）
    // - 会话筛选条件（清除）：搜索词、tag chips、日期范围、模型版本
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
  /// 这里把服务层内存列表与时间线里的对应条目摘除，图立刻从界面消失，
  /// 计数同步减。后续 refresh 由 DB 软删标记兜底（扫描/文件列表均按
  /// is_deleted 排除），不会复活。
  Future<void> removeDeletedImagesFromMemory(List<String> paths) async {
    if (paths.isEmpty) return;

    // ① state 层摘除（UI 最优先，不依赖 service——实测 getService 在
    // 服务重建/重扫期间会等待甚至 10s 超时抛出，把整个摘除链打断）
    final removedKeys = paths.map(galleryFilePathKey).toSet();
    _recentlyDeletedKeys.addAll(removedKeys);
    for (final key in removedKeys) {
      _records.remove(key);
      _staleRecordKeys.remove(key);
    }
    final timeline = state.timeline;
    _setState(
      state.copyWith(
        timeline: GalleryTimeline(
          timeline.entries
              .where((e) => !removedKeys.contains(galleryFilePathKey(e.path)))
              .toList(growable: false),
          datasetId: timeline.datasetId,
          semanticRanked: timeline.semanticRanked,
        ),
        contentRevision: state.contentRevision + 1,
      ),
    );

    // ② 服务层内存列表摘除 + 计数校正（可能等待服务就绪，不挡 UI）
    try {
      final service = await getService();
      service.removeImagesFromMemory(paths);
      _setState(
        state.copyWith(
          totalCount: service.totalCount,
          filteredCount: state.timeline.semanticRanked
              ? state.timeline.length
              : service.filteredCount,
        ),
      );
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
  /// 语义固定：重放过滤 → 新数据集（视图回到顶部）。所有筛选/范围切换类
  /// 调用方统一经此入口。收藏增删等「内容变更」不走本方法，见
  /// [_reloadCurrentView]（保持滚动位置）。
  Future<void> _applyFilters() async {
    if (!state.isInitialized) return;

    final criteria = state.filterCriteria;
    final requestSerial = ++_filterRequestSerial;
    _setState(state.copyWith(isLoading: true, error: null));
    try {
      final service = await getService();

      AppLogger.d(
        'Applying filters: hasFilters=${criteria.hasFilters}, search="${criteria.searchQuery}", '
            'dateStart=${criteria.dateStart}, dateEnd=${criteria.dateEnd}, favOnly=${criteria.showFavoritesOnly}, '
            'tags=${criteria.selectedTags}, models=${criteria.filterModels}, '
            'category=${criteria.categoryId}, collection=${criteria.collectionId}, naiOnly=${criteria.naiOnly}',
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

      await _reloadTimeline(newDataset: true);
    } on GalleryFilterException catch (e) {
      if (requestSerial != _filterRequestSerial ||
          state.filterCriteria != criteria) {
        return;
      }
      AppLogger.e('Filter failed', e, null, 'LocalGalleryNotifier');
      _setState(
        state.copyWith(
          isLoading: false,
          error: LocalGalleryError(
            LocalGalleryErrorCode.filterFailed,
            details: e.message,
          ),
        ),
      );
    } catch (e) {
      if (requestSerial != _filterRequestSerial ||
          state.filterCriteria != criteria) {
        return;
      }
      AppLogger.e('Failed to apply filters', e, null, 'LocalGalleryNotifier');
      _setState(state.copyWith(isLoading: false));
    }
  }

  // ============================================================
  // 收藏
  // ============================================================

  Future<bool> toggleFavorite(String filePath) async {
    try {
      final service = await getService();
      final isFav = await service.toggleFavorite(filePath);

      _updateCachedRecords({
        galleryFilePathKey(filePath),
      }, (record) => record.copyWith(isFavorite: isFav));
      _setState(state.copyWith(contentRevision: state.contentRevision + 1));

      // 取消收藏 = 从「收藏」根移除 = 同时移出所有收藏集：侧栏收藏集行计数
      // 依赖 collectionNotifier，不刷新会滞留旧值。
      if (!isFav) {
        await ref.read(collectionNotifierProvider.notifier).refresh();
      }

      // 如果启用了收藏过滤或按集合浏览，收藏/取消收藏都要重新应用：
      // 取消收藏（=从根移除=移出所有集合）会让图片从当前范围即时消失。
      // 服务层在收藏写入内部已重放过过滤，这里只轻量重载（保持位置）。
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

  /// 从服务层重查单张图片的收藏状态并同步到已缓存记录
  ///
  /// 收藏菜单「加入子集=入根」走的是 CollectionNotifier，不经过
  /// [toggleFavorite]，但卡片红心/详情收藏按钮读的是缓存记录的
  /// [LocalImageRecord.isFavorite]——这里补一次同步，让红心即时点亮。
  /// 返回同步后的收藏状态；查询失败返回 null（不覆盖现有状态）。
  Future<bool?> syncFavoriteStatus(String filePath) async {
    try {
      final service = await getService();
      final isFav = await service.isFavorite(filePath);
      _updateCachedRecords({
        galleryFilePathKey(filePath),
      }, (record) => record.copyWith(isFavorite: isFav));
      _setState(state.copyWith(contentRevision: state.contentRevision + 1));
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

      _updateCachedRecords({
        for (final path in filePaths) galleryFilePathKey(path),
      }, (record) => record.copyWith(isFavorite: false));
      _setState(state.copyWith(contentRevision: state.contentRevision + 1));

      // 批量取消收藏同样清空所有集合的成员关系：刷新收藏集计数，
      // 否则侧栏集合行数字滞留（即使 removedCount=0 也可能有集合成员被清）。
      await ref.read(collectionNotifierProvider.notifier).refresh();

      // 按收藏根或任一集合过滤时，移除后的图片不再匹配当前范围，轻量重载
      // 并保持位置（服务层在变更内部已重放过过滤，不再重复跑）。
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
  /// 计数并重读条目，保持滚动位置，不重复跑过滤。
  Future<void> _reloadCurrentView() async {
    await _reloadTimeline(newDataset: false);
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

      _markRecordsStale();
      await _reloadTimeline(newDataset: false);
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
    return cachedRecord(filePath)?.tags ?? const [];
  }

  Future<void> setTags(String filePath, List<String> tags) async {
    // 标签操作通过数据源直接处理，这里只更新已缓存记录
    _updateCachedRecords({
      galleryFilePathKey(filePath),
    }, (record) => record.copyWith(tags: tags));
  }

  /// Re-read externally changed metadata without resetting the visible dataset.
  Future<void> refreshMetadataView() async {
    final service = await getService();
    final criteria = state.filterCriteria;
    final serial = _filterRequestSerial;
    await service.applyFilter(criteria);
    if (serial != _filterRequestSerial || state.filterCriteria != criteria) {
      return;
    }
    _markRecordsStale();
    _setState(
      state.copyWith(
        totalCount: service.totalCount,
        filteredCount: service.filteredCount,
        contentRevision: state.contentRevision + 1,
      ),
    );
    await _reloadTimeline(newDataset: false);
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
