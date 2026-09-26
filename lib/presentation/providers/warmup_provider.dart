import 'dart:async';
import 'dart:ui' as ui;

import 'package:google_fonts/google_fonts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/proxy_service.dart';
import '../../core/enums/warmup_phase.dart';
import '../../core/database/database.dart';
import '../../core/database/datasources/gallery_data_source.dart';
import '../../core/services/danbooru_tags_lazy_service.dart';
import '../../core/services/data_migration_service.dart';
import '../../core/services/warmup_task_scheduler.dart';

import 'data_source_cache_provider.dart';
import '../../core/utils/app_logger.dart';
import '../../data/repositories/gallery_folder_repository.dart';
import '../../data/services/gallery/unified_gallery_service.dart';
import '../../data/services/thumbnail_service.dart';
import 'auth_provider.dart';
import 'font_provider.dart';
import 'subscription_provider.dart';
import '../../data/services/vibe_library_migration_service.dart';

part 'warmup_provider.g.dart';

/// 预加载进度
class WarmupProgress {
  /// 当前进度 (0.0 - 1.0)
  final double progress;

  /// 当前任务名称
  final String currentTask;

  /// 是否完成
  final bool isComplete;

  /// 错误信息
  final String? error;

  const WarmupProgress({
    required this.progress,
    required this.currentTask,
    this.isComplete = false,
    this.error,
  });

  factory WarmupProgress.initial() =>
      const WarmupProgress(progress: 0.0, currentTask: 'warmup_preparing');

  factory WarmupProgress.complete() => const WarmupProgress(
    progress: 1.0,
    currentTask: 'warmup_complete',
    isComplete: true,
  );

  factory WarmupProgress.error(String message) =>
      WarmupProgress(progress: 0.0, currentTask: message, error: message);
}

/// 预加载状态
class WarmupState {
  final WarmupProgress progress;
  final bool isComplete;
  final String? error;

  /// 子任务详细消息（如"下载中... 50%"）
  final String? subTaskMessage;

  const WarmupState({
    required this.progress,
    this.isComplete = false,
    this.error,
    this.subTaskMessage,
  });

  factory WarmupState.initial() =>
      WarmupState(progress: WarmupProgress.initial());

  factory WarmupState.complete() =>
      WarmupState(progress: WarmupProgress.complete(), isComplete: true);

  WarmupState copyWith({
    WarmupProgress? progress,
    bool? isComplete,
    String? error,
    String? subTaskMessage,
    bool clearSubTaskMessage = false,
  }) {
    return WarmupState(
      progress: progress ?? this.progress,
      isComplete: isComplete ?? this.isComplete,
      error: error ?? this.error,
      subTaskMessage: clearSubTaskMessage
          ? null
          : subTaskMessage ?? this.subTaskMessage,
    );
  }
}

/// 预加载状态 Notifier
@riverpod
class WarmupNotifier extends _$WarmupNotifier {
  late WarmupTaskScheduler _scheduler;
  StreamSubscription<PhaseProgress>? _phaseSubscription;
  final _completer = Completer<void>();

  @override
  WarmupState build() {
    ref.onDispose(() {
      _phaseSubscription?.cancel();
    });

    _scheduler = WarmupTaskScheduler();
    _registerTasks();

    // 延迟后台任务注册到 build 完成后，避免修改其他 provider
    Future.microtask(_registerBackgroundPhaseTasks);

    _startWarmup();

    return WarmupState.initial();
  }

  /// 等待预热完成
  Future<void> get whenComplete => _completer.future;

  // ===== 任务实现方法 =====

  Future<void> _runDataMigration() async {
    AppLogger.i('开始数据迁移阶段...', 'Warmup');
    final migrationService = DataMigrationService.instance;

    migrationService.onProgress = (stage, progress) {
      state = state.copyWith(
        subTaskMessage: '$stage (${(progress * 100).toInt()}%)',
      );
    };

    final result = await migrationService.migrateAll();
    migrationService.onProgress = null;

    await _runVibeLibraryMigration();
    state = state.copyWith(clearSubTaskMessage: true);

    if (result.isSuccess) {
      AppLogger.i('数据迁移完成: $result', 'Warmup');
    } else {
      AppLogger.w('数据迁移部分失败: ${result.error}', 'Warmup');
    }
  }

  Future<void> _runVibeLibraryMigration() async {
    try {
      final vibeResult = await VibeLibraryMigrationService().migrateIfNeeded();
      if (vibeResult.success) {
        AppLogger.i('Vibe 库迁移完成，导出 ${vibeResult.exportedCount} 条', 'Warmup');
      } else {
        AppLogger.w('Vibe 库迁移失败: ${vibeResult.error}', 'Warmup');
      }
    } catch (e) {
      AppLogger.w('Vibe 库迁移异常: $e', 'Warmup');
    }
  }

  // 【修复】移除了 _configureImageCache 方法
  // Image Cache 配置已在 main.dart 中统一处理（200MB）

  Future<void> _preloadFonts() async {
    final fontConfig = ref.read(fontNotifierProvider);
    if (fontConfig.source != FontSource.google ||
        fontConfig.fontFamily.isEmpty) {
      AppLogger.i('Using system font, skip preload', 'Warmup');
      return;
    }

    try {
      await GoogleFonts.pendingFonts([
        GoogleFonts.getFont(fontConfig.fontFamily),
      ]);
      AppLogger.i('Preloaded Google Font: ${fontConfig.fontFamily}', 'Warmup');
    } catch (e) {
      AppLogger.w('Font preload failed: $e', 'Warmup');
    }
  }

  Future<void> _warmupImageEditor() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint()..color = const ui.Color(0xFF000000);
      canvas.drawCircle(ui.Offset.zero, 10, paint);
      final picture = recorder.endRecording();
      final image = await picture.toImage(50, 50);
      image.dispose();
      picture.dispose();
      AppLogger.i('Image editor canvas warmed up', 'Warmup');
    } catch (e) {
      AppLogger.w('Image editor warmup failed: $e', 'Warmup');
    }
  }

  /// 重试预加载
  void retry() {
    _phaseSubscription?.cancel();
    _scheduler.clear();
    state = WarmupState.initial();
    _registerTasks();
    _startWarmup();
  }

  /// 检查网络环境（最多尝试2次，失败不阻塞启动）
  ///
  /// 总超时控制在 8 秒内（调度器 timeout），避免被强制终止
  Future<void> _checkNetworkEnvironment() async {
    const maxAttempts = 2;
    const timeout = Duration(seconds: 3);

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      state = state.copyWith(
        subTaskMessage: 'warmup_networkCheck_attempt|$attempt|$maxAttempts',
      );

      try {
        final result = await ProxyService.testNovelAIConnection(
          timeout: timeout,
        );

        if (result.success) {
          AppLogger.i(
            'Network check successful: ${result.latencyMs}ms',
            'Warmup',
          );
          state = state.copyWith(
            subTaskMessage: 'warmup_networkCheck_success|${result.latencyMs}',
          );
          await Future.delayed(const Duration(milliseconds: 300));
          return;
        }

        AppLogger.w(
          'Network check attempt $attempt/$maxAttempts failed: ${result.errorMessage}',
          'Warmup',
        );
      } catch (e) {
        AppLogger.w(
          'Network check attempt $attempt/$maxAttempts error: $e',
          'Warmup',
        );
      }

      if (attempt >= maxAttempts) {
        AppLogger.w(
          'Network check reached max attempts, continuing offline',
          'Warmup',
        );
        state = state.copyWith(subTaskMessage: 'warmup_networkCheck_timeout');
        return;
      }

      await Future.delayed(const Duration(seconds: 1));
    }
  }

  // ===========================================================================
  // 三阶段预热架构
  // ===========================================================================

  /// 注册所有预热任务
  void _registerTasks() {
    // ==== 阶段 1: Critical ====
    _registerCriticalPhaseTasks();

    // ==== 阶段 2: Quick ====
    _registerQuickPhaseTasks();

    // 注意: 阶段 3 (Background) 在 build() 完成后通过 Future.microtask 注册
    // 避免在 build() 中修改其他 provider
  }

  void _registerCriticalPhaseTasks() {
    // 1. 数据迁移
    _scheduler.registerTask(
      PhasedWarmupTask(
        name: 'warmup_dataMigration',
        displayName: 'warmup_dataMigration',
        phase: WarmupPhase.critical,
        weight: 2,
        timeout: const Duration(seconds: 60),
        task: _runDataMigration,
      ),
    );

    // 2. 基础UI服务（并行）- 移除了数据库初始化，让它在 Quick 阶段异步执行
    _scheduler.registerGroup(
      PhasedTaskGroup(
        name: 'basicUI',
        displayName: 'warmup_group_basicUI',
        phase: WarmupPhase.critical,
        parallel: true,
        tasks: [
          // 【修复】移除 warmup_imageCache 任务，因为 main.dart 已配置（200MB）
          // 避免重复配置和参数不一致问题
          PhasedWarmupTask(
            name: 'warmup_fonts',
            displayName: 'warmup_fonts',
            phase: WarmupPhase.critical,
            weight: 1,
            task: _preloadFonts,
          ),
          PhasedWarmupTask(
            name: 'warmup_imageEditor',
            displayName: 'warmup_imageEditor',
            phase: WarmupPhase.critical,
            weight: 1,
            task: _warmupImageEditor,
          ),
        ],
      ),
    );
  }

  void _registerQuickPhaseTasks() {
    // 1. 数据库初始化
    _scheduler.registerTask(
      PhasedWarmupTask(
        name: 'warmup_unifiedDbInit',
        displayName: 'warmup_initUnifiedDatabase',
        phase: WarmupPhase.quick,
        weight: 2,
        task: _initUnifiedDatabaseLightweight,
      ),
    );

    // 2. 共现数据初始化（轻量级检查，依赖数据库）
    _scheduler.registerTask(
      PhasedWarmupTask(
        name: 'warmup_cooccurrenceInit',
        displayName: 'warmup_cooccurrenceInit',
        phase: WarmupPhase.quick,
        weight: 1,
        task: () async {
          // 只执行轻量级检查，实际导入在 background 阶段
          await _initCooccurrenceData();
        },
      ),
    );

    // 4. 网络检测（8秒超时，防止无限等待）
    _scheduler.registerTask(
      PhasedWarmupTask(
        name: 'warmup_networkCheck',
        displayName: 'warmup_networkCheck',
        phase: WarmupPhase.quick,
        weight: 1,
        timeout: const Duration(seconds: 8),
        task: _checkNetworkEnvironment,
      ),
    );

    // 5. 画廊数据源初始化
    _scheduler.registerTask(
      PhasedWarmupTask(
        name: 'warmup_galleryDataSource',
        displayName: 'warmup_galleryDataSource',
        phase: WarmupPhase.quick,
        weight: 3,
        timeout: const Duration(seconds: 30),
        task: _initGalleryDataSource,
      ),
    );

    // 6. 画廊计数
    _scheduler.registerTask(
      PhasedWarmupTask(
        name: 'warmup_galleryFileCount',
        displayName: 'warmup_galleryFileCount',
        phase: WarmupPhase.quick,
        weight: 1,
        task: _countGalleryFiles,
      ),
    );

    // 7. 订阅信息（仅缓存，不强制网络）
    _scheduler.registerTask(
      PhasedWarmupTask(
        name: 'warmup_subscription',
        displayName: 'warmup_subscription',
        phase: WarmupPhase.quick,
        weight: 1,
        task: _loadSubscriptionCached,
      ),
    );

    // 标签 catalog 随应用提供并按需只读查询；启动阶段不再下载全量标签。
  }

  void _registerBackgroundPhaseTasks() {
    // 注意：共现数据是预打包的数据库，在 _initCooccurrenceData() 中已完成初始化
    // 不需要额外的后台导入任务
  }

  /// 启动全局画廊扫描（预热结束后推迟启动，把 I/O 让给首屏渲染）
  ///
  /// 这会触发 galleryServiceProvider 的初始化，从而启动后台索引扫描
  void _startGlobalGalleryScan() {
    AppLogger.i('[Warmup] 预热完成，推迟启动全局画廊扫描以优先保障首屏渲染...', 'Warmup');

    // L8 性能优化：推迟 2.5 秒启动全局扫描，避免与首屏页面加载争夺磁盘 I/O 和数据库连接
    Future.delayed(const Duration(milliseconds: 2500), () async {
      try {
        // 【修复】读取 provider 会触发 GalleryService 的创建和初始化
        // 但需要等待真正的初始化完成，扫描才会开始
        var attempts = 0;
        const maxAttempts = 100; // 最多等待10秒

        while (attempts < maxAttempts) {
          final service = ref.read(galleryServiceProvider);

          if (service.isInitialized) {
            AppLogger.i('[Warmup] 画廊服务已就绪，后台扫描进行中', 'Warmup');
            return;
          }

          // 服务还在初始化中，等待
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }

        AppLogger.w('[Warmup] 等待画廊服务初始化超时', 'Warmup');
      } catch (e) {
        // 画廊扫描失败不应影响主流程
        AppLogger.w('[Warmup] 画廊扫描启动失败（非关键）: $e', 'Warmup');
      }
    });
  }

  /// 启动后台缩略图磁盘缓存清理（P7）
  ///
  /// 超过上限的 `.thumbs` 缩略图按最久未使用淘汰（只删 `.thumbs` 内的
  /// `.thumb.jpg`，不触碰原图）。推迟到全局扫描推迟点（2.5s）之后再等 10s
  /// 执行，把启动期磁盘 IO 让给首屏渲染；失败不影响主流程。
  void _trimThumbnailCacheInBackground() {
    Future.delayed(const Duration(seconds: 10), () async {
      try {
        final service = ThumbnailService.instance;
        if (service.state != ThumbnailServiceState.running) {
          return;
        }

        final roots = await GalleryFolderRepository.instance.getAllRootDirs();
        var evictedCount = 0;
        var evictedBytes = 0;
        for (final dir in roots) {
          final result = await service.evictThumbnailCache(dir.path);
          evictedCount += result.evictedCount;
          evictedBytes += result.evictedBytes;
        }

        if (evictedCount > 0) {
          AppLogger.i(
            '[Warmup] 缩略图缓存 LRU 清理完成: 淘汰 $evictedCount 个文件, '
                '释放 ${(evictedBytes / 1024 / 1024).toStringAsFixed(1)}MB',
            'Warmup',
          );
        }
      } catch (e) {
        AppLogger.w('[Warmup] 缩略图缓存清理失败（非关键）: $e', 'Warmup');
      }
    });
  }

  /// 开始预热流程
  Future<void> _startWarmup() async {
    try {
      // 阶段 1: Critical
      await for (final progress in _scheduler.runPhase(WarmupPhase.critical)) {
        state = state.copyWith(
          progress: WarmupProgress(
            progress: progress.progress * 0.3, // critical 占 30%
            currentTask: progress.currentTask,
          ),
          clearSubTaskMessage: true,
        );
      }

      // 阶段 2: Quick
      await for (final progress in _scheduler.runPhase(WarmupPhase.quick)) {
        state = state.copyWith(
          progress: WarmupProgress(
            progress: 0.3 + progress.progress * 0.7, // quick 占 70%
            currentTask: progress.currentTask,
          ),
          clearSubTaskMessage: true,
        );
      }

      // 完成，进入主界面
      state = WarmupState.complete();
      _completer.complete();

      // 【关键】预热完成后，自动启动全局画廊扫描（不绑定页面）
      _startGlobalGalleryScan();

      // P7：再启动后台缩略图缓存清理（低优先，避免与首屏渲染争抢磁盘 IO）
      _trimThumbnailCacheInBackground();
    } catch (e, stack) {
      AppLogger.e('Warmup failed', e, stack, 'Warmup');
      state = state.copyWith(
        error: e.toString(),
        progress: WarmupProgress.error(e.toString()),
      );
      _completer.completeError(e);
    }
  }

  /// 轻量级初始化统一数据库（带进度反馈、错误处理和损坏检测）
  Future<void> _initUnifiedDatabaseLightweight() async {
    AppLogger.i('等待数据库准备就绪...', 'Warmup');

    try {
      // 数据库已在 main() 中初始化和恢复，这里只需等待就绪
      final manager = await ref.watch(databaseManagerProvider.future);
      await manager.initialized.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          AppLogger.w('Database initialization timeout', 'Warmup');
          throw TimeoutException(
            'Database initialization timed out. Check disk space.',
          );
        },
      );

      AppLogger.i('数据库已就绪', 'Warmup');
    } on TimeoutException {
      rethrow;
    } catch (e, stack) {
      AppLogger.e('Database initialization failed', e, stack, 'Warmup');
      // 数据库初始化失败不应阻塞启动，记录错误但继续
      AppLogger.w(
        'Continuing without database - will retry on first use',
        'Warmup',
      );
    }
  }

  /// 初始化画廊数据源
  Future<void> _initGalleryDataSource() async {
    try {
      // 获取 DatabaseManager 并等待初始化
      final dbManager = await ref.read(databaseManagerProvider.future);

      // 获取 GalleryDataSource
      final galleryDs = dbManager.getDataSource<GalleryDataSource>('gallery');
      if (galleryDs != null) {
        // 数据源已初始化（DatabaseManager 中已完成）
        AppLogger.i('GalleryDataSource initialized in warmup phase', 'Warmup');
      }
    } catch (e) {
      AppLogger.w('GalleryDataSource warmup failed: $e', 'Warmup');
      // 不抛出异常，避免阻塞启动
    }
  }

  /// 统计画廊文件数
  Future<void> _countGalleryFiles() async {
    try {
      final count = await GalleryFolderRepository.instance.getTotalImageCount();
      AppLogger.i('Gallery file count: $count', 'Warmup');
    } catch (e) {
      AppLogger.w('Gallery file count failed: $e', 'Warmup');
    }
  }

  /// 加载缓存的订阅信息（快速）
  Future<void> _loadSubscriptionCached() async {
    try {
      final authState = ref.read(authNotifierProvider);
      if (!authState.isAuthenticated) {
        AppLogger.i('User not authenticated, skip subscription', 'Warmup');
        return;
      }
      // 仅读取缓存，不强制网络请求
      final subState = ref.read(subscriptionNotifierProvider);
      if (!subState.isLoaded) {
        // 尝试快速加载，超时则跳过
        await ref
            .read(subscriptionNotifierProvider.notifier)
            .fetchSubscription()
            .timeout(const Duration(seconds: 2), onTimeout: () => null);
      }
    } catch (e) {
      AppLogger.w('Subscription load failed (non-critical): $e', 'Warmup');
    }
  }

  // ==== 后台任务方法 ====

  Future<void> _initCooccurrenceData() async {
    AppLogger.i('开始初始化共现数据...', 'Warmup');

    try {
      final cooccurrenceService = await ref.watch(
        cooccurrenceServiceProvider.future,
      );

      // 初始化共现服务
      final isReady = await cooccurrenceService.initialize();

      if (isReady) {
        final count = await cooccurrenceService.getCount();
        AppLogger.i('共现数据已就绪（$count 条记录）', 'Warmup');
      } else {
        final count = await cooccurrenceService.getCount();
        if (count > 0) {
          AppLogger.w('共现数据不完整（$count 条记录），将在后台继续导入', 'Warmup');
        } else {
          AppLogger.i('共现数据为空，将在后台导入', 'Warmup');
        }
      }
    } on StateError catch (e) {
      // 数据库正在恢复中，不阻塞启动
      AppLogger.w('共现数据初始化时数据库正在恢复，将在后台重试: $e', 'Warmup');
    } catch (e, stack) {
      AppLogger.e('共现数据初始化失败', e, stack, 'Warmup');
    }
  }

  /// 拉取画师标签（预热阶段同步执行）
  ///
  /// 使用 Provider 的 syncArtists 方法，在预热阶段同步完成
  /// 由于有热度限制，数据量不大，不会阻塞太久
  // ignore: unused_element
  Future<void> _fetchArtistTagsInWarmup() async {
    AppLogger.i('Starting artist tags fetch in warmup phase...', 'Warmup');

    try {
      // 使用 Provider 的 syncArtists 方法，确保完成后状态更新
      // 这会正确处理重复拉取的检查，并在完成后更新 Provider 状态
      await ref
          .read(danbooruTagsCacheNotifierProvider.notifier)
          .syncArtists(
            force: false, // 如果有数据则跳过
          );

      AppLogger.i('Artist tags fetch completed in warmup phase', 'Warmup');
    } catch (e, stack) {
      AppLogger.e(
        'Artist tags fetch error in warmup phase: $e',
        e,
        stack,
        'Warmup',
      );
      // 预热阶段失败不阻塞，进入主页后可能重试
    }
  }

  // ignore: unused_element
  Future<void> _checkAndRecoverData() async {
    AppLogger.i('检查数据完整性...', 'Warmup');

    try {
      // 使用新的 DatabaseManager 获取统计信息
      final manager = await ref.watch(databaseManagerProvider.future);

      // 等待初始化完成
      await manager.initialized;

      final runtimeStats = await manager.getStatistics();
      final tableStats = runtimeStats['tables'] as Map<String, int>? ?? {};
      final coreAssetStats = await manager.getCoreAssetStatistics();

      // 获取各表记录数
      final translationCount = coreAssetStats['translations'] ?? 0;
      final cooccurrenceCount = coreAssetStats['cooccurrences'] ?? 0;
      final danbooruCount = tableStats['danbooru_tags'] ?? 0;

      AppLogger.i(
        '核心资产数据库状态: translations=$translationCount, cooccurrences=$cooccurrenceCount, danbooru_tags=$danbooruCount',
        'Warmup',
      );

      // 1. 检查 translations 和 cooccurrences 资产库
      if (translationCount == 0 || cooccurrenceCount == 0) {
        AppLogger.w('核心资产数据为空，请检查本地打包数据库', 'Warmup');
      }

      // 2. 恢复 danbooru_tags（从API）
      // 不仅检查总数，还检查各分类数量
      final service = await ref.read(danbooruTagsLazyServiceProvider.future);
      final categoryStats = await service.getCategoryStats();

      final generalCount = categoryStats['general'] ?? 0;
      final characterCount = categoryStats['character'] ?? 0;
      final copyrightCount = categoryStats['copyright'] ?? 0;
      final metaCount = categoryStats['meta'] ?? 0;

      AppLogger.i(
        'Danbooru标签分类统计: general=$generalCount, character=$characterCount, '
            'copyright=$copyrightCount, meta=$metaCount',
        'Warmup',
      );

      // 判断哪些分类需要拉取
      final needsGeneralFetch = generalCount == 0;
      final needsCharacterFetch = characterCount == 0;
      final needsCopyrightFetch = copyrightCount == 0;
      final needsMetaFetch = metaCount == 0;

      final needsAnyFetch =
          needsGeneralFetch ||
          needsCharacterFetch ||
          needsCopyrightFetch ||
          needsMetaFetch;

      if (!needsAnyFetch) {
        AppLogger.i('所有标签分类数据已存在，跳过拉取', 'Warmup');
        return;
      }

      AppLogger.w(
        '部分标签分类为空，触发补充拉取: '
            'general=$needsGeneralFetch, character=$needsCharacterFetch, '
            'copyright=$needsCopyrightFetch, meta=$needsMetaFetch',
        'Warmup',
      );
      state = state.copyWith(
        subTaskMessage: 'warmup_fetchingTagDataFromServer',
      );

      // 定义标签拉取任务
      final fetchTasks = [
        if (needsGeneralFetch)
          (
            message: 'warmup_fetchingGeneralTags',
            fetch: () =>
                service.fetchGeneralTags(threshold: 1000, maxPages: 50),
          ),
        if (needsCharacterFetch)
          (
            message: 'warmup_fetchingCharacterTags',
            fetch: () =>
                service.fetchCharacterTags(threshold: 100, maxPages: 50),
          ),
        if (needsCopyrightFetch)
          (
            message: 'warmup_fetchingCopyrightTags',
            fetch: () =>
                service.fetchCopyrightTags(threshold: 500, maxPages: 50),
          ),
        if (needsMetaFetch)
          (
            message: 'warmup_fetchingMetaTags',
            fetch: () => service.fetchMetaTags(threshold: 10000, maxPages: 50),
          ),
      ];

      for (final task in fetchTasks) {
        state = state.copyWith(subTaskMessage: task.message);
        await task.fetch().timeout(
          const Duration(seconds: 60),
          onTimeout: () => AppLogger.w('${task.message}超时，将在后台继续', 'Warmup'),
        );
      }

      AppLogger.i('标签数据拉取完成', 'Warmup');
    } on StateError catch (e) {
      // 数据库正在恢复中，不阻塞启动
      AppLogger.w('检查数据完整性时数据库正在恢复，将在后台重试: $e', 'Warmup');
    } catch (e) {
      AppLogger.w('检查数据完整性失败: $e', 'Warmup');
      // 非致命错误，继续启动
    }
  }
}
