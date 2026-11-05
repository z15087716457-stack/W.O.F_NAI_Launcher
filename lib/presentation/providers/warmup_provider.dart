import 'dart:async';
import 'dart:ui' as ui;

import 'package:google_fonts/google_fonts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/proxy_service.dart';
import '../../core/enums/warmup_phase.dart';
import '../../core/services/data_migration_service.dart';
import '../../core/services/desktop_app_shutdown_service.dart';
import '../../core/services/warmup_task_scheduler.dart';

import '../../core/utils/app_logger.dart';
import '../../data/repositories/gallery_folder_repository.dart';
import '../../data/services/gallery/unified_gallery_service.dart';
import '../../data/services/thumbnail_service.dart';
import 'auth_provider.dart';
import 'font_provider.dart';
import 'subscription_provider.dart';
import 'local_gallery_provider.dart';
import 'thumbnail_cache_limit_provider.dart';
import '../../data/services/vibe_library_migration_service.dart';

part 'warmup_provider.g.dart';

// The existing splash waits here while main prepares services after first paint.
final appStartupReadyProvider = Provider<Future<void>>((ref) async {});

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
  var _completer = Completer<void>();
  bool _disposed = false;
  bool get _stopping => _disposed || DesktopAppShutdownService.isShuttingDown;

  @override
  WarmupState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
    });

    _scheduler = WarmupTaskScheduler();
    _registerTasks();

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
    _scheduler.clear();
    _completer = Completer<void>();
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
      if (_stopping) return;
      try {
        final result = await ProxyService.testNovelAIConnection(
          timeout: timeout,
        );

        if (result.success) {
          AppLogger.i(
            'Network check successful: ${result.latencyMs}ms',
            'Warmup',
          );
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
        return;
      }

      await Future.delayed(const Duration(seconds: 1));
    }
  }

  // ===========================================================================
  // 必要预热与后台诊断
  // ===========================================================================

  /// 注册所有预热任务
  void _registerTasks() {
    // ==== 阶段 1: Critical ====
    _registerCriticalPhaseTasks();

    _registerBackgroundPhaseTasks();
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
        task: () => DesktopAppShutdownService.runCriticalStartupTask(
          'Startup data migration',
          _runDataMigration,
        ),
      ),
    );

    // 基础 UI 服务：数据库等服务已经由 main 的就绪边界准备。
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

  void _registerBackgroundPhaseTasks() {
    _scheduler.registerTask(
      PhasedWarmupTask(
        name: 'warmup_networkCheck',
        displayName: 'warmup_networkCheck',
        phase: WarmupPhase.background,
        timeout: const Duration(seconds: 8),
        task: _checkNetworkEnvironment,
      ),
    );
    _scheduler.registerTask(
      PhasedWarmupTask(
        name: 'warmup_subscription',
        displayName: 'warmup_subscription',
        phase: WarmupPhase.background,
        task: _loadSubscriptionCached,
      ),
    );
  }

  /// 启动全局画廊扫描（预热结束后推迟启动，把 I/O 让给首屏渲染）
  ///
  /// 这会触发 galleryServiceProvider 的初始化，从而启动后台索引扫描
  void _startGlobalGalleryScan() {
    AppLogger.i('[Warmup] 预热完成，推迟启动全局画廊扫描以优先保障首屏渲染...', 'Warmup');

    // L8 性能优化：推迟 2.5 秒启动全局扫描，避免与首屏页面加载争夺磁盘 I/O 和数据库连接
    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (_stopping) return;
      try {
        await ref.read(galleryFileMonitorProvider).start();
        if (_stopping) return;
        // 【修复】读取 provider 会触发 GalleryService 的创建和初始化
        // 但需要等待真正的初始化完成，扫描才会开始
        var attempts = 0;
        const maxAttempts = 100; // 最多等待10秒

        while (attempts < maxAttempts) {
          if (_stopping) return;
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
      if (_stopping) return;
      try {
        final service = ThumbnailService.instance;
        if (service.state != ThumbnailServiceState.running) {
          return;
        }

        final roots = await GalleryFolderRepository.instance.getAllRootDirs();
        if (_stopping) return;
        ref.read(thumbnailCacheLimitGbProvider);
        final result = await service.evictThumbnailCaches(
          roots.map((dir) => dir.path),
        );
        final evictedCount = result.evictedCount;
        final evictedBytes = result.evictedBytes;

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
      if (_stopping) return;
      // Auto-login can overlap local service preparation.
      ref.read(authNotifierProvider);
      await ref.read(appStartupReadyProvider);
      if (_stopping) return;
      // 阶段 1: Critical
      await for (final progress in _scheduler.runPhase(WarmupPhase.critical)) {
        if (_stopping) return;
        state = state.copyWith(
          progress: WarmupProgress(
            progress: progress.progress,
            currentTask: progress.currentTask,
          ),
          clearSubTaskMessage: true,
        );
      }

      if (_stopping) return;
      // 完成，进入主界面
      state = WarmupState.complete();
      _completer.complete();

      // 【关键】预热完成后，自动启动全局画廊扫描（不绑定页面）
      _startGlobalGalleryScan();

      // P7：再启动后台缩略图缓存清理（低优先，避免与首屏渲染争抢磁盘 IO）
      _trimThumbnailCacheInBackground();
    } catch (e, stack) {
      if (_stopping) return;
      AppLogger.e('Warmup failed', e, stack, 'Warmup');
      state = state.copyWith(
        error: e.toString(),
        progress: WarmupProgress.error(e.toString()),
      );
      _completer.completeError(e);
      return;
    }
    // Background diagnostics do not change completed splash state.
    await for (final _ in _scheduler.runPhase(WarmupPhase.background)) {
      if (_stopping) break;
    }
  }

  /// 后台读取订阅缓存，必要时沿用现有刷新入口。
  Future<void> _loadSubscriptionCached() async {
    try {
      final authState = ref.read(authNotifierProvider);
      if (!authState.isAuthenticated) {
        AppLogger.i('User not authenticated, skip subscription', 'Warmup');
        return;
      }
      // 优先使用现有状态，未载入时刷新。
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
}
