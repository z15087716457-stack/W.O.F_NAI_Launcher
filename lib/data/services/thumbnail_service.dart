import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/cache/thumbnail_cache_service.dart';
import '../../core/utils/app_logger.dart';

part 'thumbnail_service.g.dart';

/// 缩略图任务优先级
///
/// 数字越小优先级越高
class ThumbnailPriority {
  /// 最高优先级（当前可见项）
  static const int highest = 1;

  /// 高优先级（即将可见项）
  static const int high = 3;

  /// 正常优先级（默认）
  static const int normal = 5;

  /// 低优先级（后台预生成）
  static const int low = 10;

  /// 最低优先级（批量迁移）
  static const int lowest = 20;
}

/// 缩略图任务状态
enum ThumbnailTaskState {
  /// 等待中
  pending,

  /// 生成中
  generating,

  /// 已完成
  completed,

  /// 失败
  failed,

  /// 已取消
  cancelled,
}

/// 缩略图任务
class ThumbnailTask {
  /// 任务ID
  final String id;

  /// 原始图片路径
  final String originalPath;

  /// 缩略图尺寸
  final ThumbnailSize size;

  /// 基础优先级
  final int basePriority;

  /// 任务状态
  ThumbnailTaskState state;

  /// 创建时间
  final DateTime createdAt;

  /// 开始时间
  DateTime? startedAt;

  /// 完成时间
  DateTime? completedAt;

  /// 错误信息
  String? error;

  /// 重试次数
  int retryCount;

  /// 完成回调
  final List<void Function(String? path)> _onCompleteCallbacks = [];

  /// 是否可见
  bool isVisible;

  ThumbnailTask({
    required this.id,
    required this.originalPath,
    this.size = ThumbnailSize.small,
    this.basePriority = ThumbnailPriority.normal,
    this.isVisible = false,
    this.state = ThumbnailTaskState.pending,
    this.retryCount = 0,
  }) : createdAt = DateTime.now();

  /// 获取完整任务键
  ThumbnailTaskKey get key => ThumbnailTaskKey(originalPath, size);

  /// 获取有效优先级
  int get effectivePriority => isVisible ? basePriority - 2 : basePriority;

  /// 添加完成回调
  void onComplete(void Function(String? path) callback) {
    _onCompleteCallbacks.add(callback);
  }

  /// 通知完成
  void notifyComplete(String? path) {
    for (final callback in _onCompleteCallbacks) {
      try {
        callback(path);
      } catch (e) {
        AppLogger.w('Task complete callback failed: $e', 'ThumbnailTask');
      }
    }
    _onCompleteCallbacks.clear();
  }

  @override
  String toString() =>
      'ThumbnailTask($id: $originalPath, size=$size, priority=$effectivePriority, state=$state)';
}

/// 缩略图服务状态
enum ThumbnailServiceState {
  /// 未初始化
  uninitialized,

  /// 初始化中
  initializing,

  /// 运行中
  running,

  /// 已暂停
  paused,

  /// 已销毁
  disposed,
}

/// 统一缩略图服务
///
/// 整合 ThumbnailCacheService 和队列管理功能，提供：
/// - 统一的缩略图生成和缓存接口
/// - 可见性感知的优先级队列
/// - 批量任务管理
/// - 详细的统计和监控
///
/// 设计目标：
/// 1. 简化调用方代码，隐藏内部复杂性
/// 2. 提供可见性感知的加载优化
/// 3. 支持批量生成任务
/// 4. 统一的错误处理和重试机制
class ThumbnailService {
  static ThumbnailService? _instance;

  static ThumbnailService get instance {
    _instance ??= ThumbnailService._internal();
    return _instance!;
  }

  ThumbnailService._internal();

  // ==================== 依赖 ====================

  ThumbnailCacheService? _cacheService;

  // ==================== 状态 ====================

  ThumbnailServiceState _state = ThumbnailServiceState.uninitialized;
  ThumbnailServiceState get state => _state;

  // ==================== 队列 ====================

  /// 任务队列（按优先级排序）
  final PriorityQueue<ThumbnailTask> _taskQueue = PriorityQueue<ThumbnailTask>(
    (a, b) => a.effectivePriority.compareTo(b.effectivePriority),
  );

  /// 活跃任务映射（完整任务键 -> 任务）
  final Map<ThumbnailTaskKey, ThumbnailTask> _activeTasks = {};

  /// 等待重新入队的重试定时器（任务键 -> Timer），
  /// 服务暂停/销毁或任务取消时一并清理，避免悬挂定时器。
  final Map<ThumbnailTaskKey, Timer> _retryTimers = {};

  /// 当前正在进行的生成任务数
  int _activeGenerationCount = 0;

  /// 最大并发生成数
  static const int maxConcurrentGenerations = 3;

  /// 最大重试次数
  static const int maxRetryAttempts = 3;

  /// 最大队列长度
  static const int maxQueueSize = 500;

  // ==================== 流控制器 ====================

  /// 状态流
  final _stateController = StreamController<ThumbnailServiceState>.broadcast();
  Stream<ThumbnailServiceState> get stateStream => _stateController.stream;

  /// 任务流
  final _taskController = StreamController<ThumbnailTask>.broadcast();
  Stream<ThumbnailTask> get taskStream => _taskController.stream;

  // ==================== 统计 ====================

  final _ThumbnailServiceStats _stats = _ThumbnailServiceStats();

  // ==================== 初始化 ====================

  /// 初始化服务
  ///
  /// 线程安全，防止重复初始化
  Future<void> initialize({ThumbnailCacheService? cacheService}) async {
    if (_state == ThumbnailServiceState.running ||
        _state == ThumbnailServiceState.initializing) {
      return;
    }

    _setState(ThumbnailServiceState.initializing);

    try {
      // 初始化缓存服务
      _cacheService = cacheService ?? ThumbnailCacheService.instance;
      await _cacheService!.init();

      _setState(ThumbnailServiceState.running);
    } catch (e, stack) {
      _setState(ThumbnailServiceState.uninitialized);
      AppLogger.e(
        'Failed to initialize ThumbnailService',
        e,
        stack,
        'ThumbnailService',
      );
      rethrow;
    }
  }

  void _setState(ThumbnailServiceState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  // ==================== 核心 API ====================

  /// 获取缩略图
  ///
  /// 如果缓存存在，直接返回路径
  /// 如果不存在，加入生成队列并等待完成
  ///
  /// [originalPath] 原始图片路径
  /// [size] 缩略图尺寸
  /// [priority] 生成优先级
  ///
  /// 返回缩略图路径，失败返回 null
  Future<String?> getThumbnail(
    String originalPath, {
    ThumbnailSize size = ThumbnailSize.small,
    int priority = ThumbnailPriority.normal,
  }) async {
    _ensureInitialized();

    // 首先检查缓存
    final cachedPath = await _cacheService!.getThumbnailPath(
      originalPath,
      size: size,
    );
    if (cachedPath != null) {
      return cachedPath;
    }

    // 创建或复用任务，并在入队前注册等待回调
    final key = ThumbnailTaskKey(originalPath, size);
    final activeTask = _activeTasks[key];
    final task =
        activeTask != null &&
            (activeTask.state == ThumbnailTaskState.pending ||
                activeTask.state == ThumbnailTaskState.generating)
        ? activeTask
        : _createTask(originalPath, size: size, priority: priority);

    final completer = Completer<String?>();
    task.onComplete((path) {
      if (!completer.isCompleted) completer.complete(path);
    });

    if (!identical(task, activeTask)) {
      _enqueueTask(task);
    }

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        AppLogger.w(
          'Thumbnail generation timeout: $originalPath',
          'ThumbnailService',
        );
        return null;
      },
    );
  }

  /// 预加载缩略图
  ///
  /// 不等待结果，仅将任务加入队列
  ///
  /// [originalPath] 原始图片路径
  /// [size] 缩略图尺寸
  /// [priority] 生成优先级
  Future<void> preloadThumbnail(
    String originalPath, {
    ThumbnailSize size = ThumbnailSize.small,
    int priority = ThumbnailPriority.low,
  }) async {
    _ensureInitialized();

    // 检查缓存（异步检查：同步 existsSync 会阻塞主 isolate，
    // 一次翻页预取约 100 次；重复入队由 _enqueueTask 的键去重兜底）
    if (await _cacheService!.thumbnailExistsAsync(originalPath, size: size)) {
      return; // 已存在，跳过
    }

    // 检查是否已在队列中或生成中
    if (_activeTasks.containsKey(ThumbnailTaskKey(originalPath, size))) {
      return; // 已在处理中
    }

    final task = _createTask(originalPath, size: size, priority: priority);

    _enqueueTask(task);
  }

  // ==================== 可见性感知 API ====================

  /// 更新缩略图可见性
  ///
  /// 用于可见性感知的优先级调整
  ///
  /// [originalPath] 原始图片路径
  /// [isVisible] 是否可见
  /// [priority] 可见时的优先级
  void updateVisibility(
    String originalPath, {
    required bool isVisible,
    int priority = ThumbnailPriority.highest,
  }) {
    if (_cacheService == null) return;

    _cacheService!.updateThumbnailVisibility(
      originalPath,
      isVisible: isVisible,
      priority: priority,
    );

    // 更新队列中相关任务的优先级
    bool needsReorder = false;
    for (final task in _taskQueue.toList()) {
      if (task.originalPath == originalPath) {
        task.isVisible = isVisible;
        needsReorder = true;
      }
    }

    if (needsReorder) {
      _resortQueue();
    }

    // 如果变为可见且正在运行，可能触发队列处理
    if (isVisible && _state == ThumbnailServiceState.running) {
      _processQueue();
    }
  }

  // ==================== 队列管理 ====================

  ThumbnailTask _createTask(
    String originalPath, {
    required ThumbnailSize size,
    required int priority,
  }) {
    return ThumbnailTask(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}_${_activeTasks.length}',
      originalPath: originalPath,
      size: size,
      basePriority: priority,
    );
  }

  void _enqueueTask(ThumbnailTask task) {
    final existingTask = _activeTasks[task.key];
    if (existingTask != null && !identical(existingTask, task)) {
      return;
    }

    // 队列大小限制
    if (_taskQueue.length >= maxQueueSize) {
      _evictLowestPriorityTask();
    }

    _taskQueue.add(task);
    _activeTasks[task.key] = task;

    _taskController.add(task);

    // 触发队列处理
    if (_state == ThumbnailServiceState.running) {
      _processQueue();
    }
  }

  void _evictLowestPriorityTask() {
    if (_taskQueue.isEmpty) return;

    // 找到优先级最低的任务
    final lowestPriorityTask = _taskQueue.toList().reduce((a, b) {
      return a.effectivePriority > b.effectivePriority ? a : b;
    });

    // 从队列中移除
    final tempList = _taskQueue.toList();
    tempList.remove(lowestPriorityTask);

    _taskQueue.clear();
    for (final task in tempList) {
      _taskQueue.add(task);
    }

    // 标记为取消
    lowestPriorityTask.state = ThumbnailTaskState.cancelled;
    lowestPriorityTask.notifyComplete(null);
    _activeTasks.remove(lowestPriorityTask.key);

    // AppLogger.d(
    //   'Evicted lowest priority task: ${lowestPriorityTask.originalPath}',
    //   'ThumbnailService',
    // );
  }

  void _resortQueue() {
    final tasks = _taskQueue.toList();
    _taskQueue.clear();
    for (final task in tasks) {
      _taskQueue.add(task);
    }
  }

  void _processQueue() {
    if (_state != ThumbnailServiceState.running) return;
    if (_taskQueue.isEmpty) return;
    if (_activeGenerationCount >= maxConcurrentGenerations) return;

    while (_activeGenerationCount < maxConcurrentGenerations &&
        _taskQueue.isNotEmpty) {
      final task = _taskQueue.removeFirst();

      if (task.state == ThumbnailTaskState.cancelled) {
        _activeTasks.remove(task.key);
        continue;
      }

      _activeGenerationCount++;
      task.state = ThumbnailTaskState.generating;
      task.startedAt = DateTime.now();

      _generateThumbnail(task).then((path) {
        _activeGenerationCount--;

        if (task.state == ThumbnailTaskState.pending) {
          // 重试已由 _scheduleRetry 延迟安排（等失败冷却结束再入队）：
          // 这里不删活跃映射、也不立即重入队，避免重试在冷却期内被弹回、
          // 次数被毫秒级烧完。
          return;
        }

        _activeTasks.remove(task.key);

        if (path != null) {
          task.state = ThumbnailTaskState.completed;
          _stats.recordSuccess();
        } else {
          task.state = ThumbnailTaskState.failed;
          _stats.recordFailed();
        }

        task.completedAt = DateTime.now();
        task.notifyComplete(path);
        _taskController.add(task);

        _processQueue();
      });
    }
  }

  Future<String?> _generateThumbnail(ThumbnailTask task) async {
    try {
      if (_cacheService == null) {
        throw Exception('Cache service not initialized');
      }

      final path = await _cacheService!.generateThumbnail(
        task.originalPath,
        size: task.size,
        priority: task.effectivePriority,
      );

      if (path == null) {
        // 尝试重试：本回合失败立即告知等待者（调用方转轻量占位并自挂
        // 延迟重试），后台重试入队延迟到失败冷却截止之后——避免重试在
        // 冷却期内被直接弹回、3 次机会被毫秒级烧完。
        if (task.retryCount < maxRetryAttempts) {
          task.retryCount++;
          task.state = ThumbnailTaskState.pending;
          task.notifyComplete(null);
          _scheduleRetry(task);
          return null;
        }
      }

      return path;
    } catch (e, stack) {
      AppLogger.e(
        'Failed to generate thumbnail for ${task.originalPath}',
        e,
        stack,
        'ThumbnailService',
      );
      task.error = e.toString();
      return null;
    }
  }

  /// 重试延迟余量：保证重试排队时间落在冷却截止之后。
  static const Duration _retryCooldownMargin = Duration(milliseconds: 50);

  /// 把重试任务延迟到失败冷却截止后重新入队。
  void _scheduleRetry(ThumbnailTask task) {
    final remaining =
        _cacheService?.failureCooldownRemaining(
          task.originalPath,
          size: task.size,
        ) ??
        Duration.zero;
    final delay = remaining <= Duration.zero
        ? Duration.zero
        : remaining + _retryCooldownMargin;

    _retryTimers[task.key]?.cancel();
    _retryTimers[task.key] = Timer(delay, () {
      _retryTimers.remove(task.key);
      if (_state != ThumbnailServiceState.running) {
        // 服务已暂停/销毁：终止任务，避免等待者悬挂到超时。
        _activeTasks.remove(task.key);
        task.state = ThumbnailTaskState.failed;
        task.notifyComplete(null);
        return;
      }
      _activeTasks.remove(task.key);
      _enqueueTask(task);
    });
  }

  /// 取消所有待触发的重试定时器。
  void _cancelRetryTimers() {
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();
  }

  // ==================== 控制方法 ====================

  /// 暂停服务
  void pause() {
    if (_state == ThumbnailServiceState.running) {
      _setState(ThumbnailServiceState.paused);
    }
  }

  /// 恢复服务
  void resume() {
    if (_state == ThumbnailServiceState.paused) {
      _setState(ThumbnailServiceState.running);
      _processQueue();
    }
  }

  /// 取消任务
  bool cancelTask(String taskId) {
    // 从队列中查找
    for (final task in _taskQueue.toList()) {
      if (task.id == taskId) {
        final tempList = _taskQueue.toList();
        tempList.remove(task);

        _taskQueue.clear();
        for (final t in tempList) {
          _taskQueue.add(t);
        }

        task.state = ThumbnailTaskState.cancelled;
        task.notifyComplete(null);
        _activeTasks.remove(task.key);
        _retryTimers.remove(task.key)?.cancel();

        // AppLogger.d('Cancelled task: $taskId', 'ThumbnailService');
        return true;
      }
    }

    return false;
  }

  /// 取消所有任务
  void cancelAll() {
    // 取消队列中所有任务
    while (_taskQueue.isNotEmpty) {
      final task = _taskQueue.removeFirst();
      task.state = ThumbnailTaskState.cancelled;
      task.notifyComplete(null);
    }

    _activeTasks.clear();
    _cancelRetryTimers();

    // AppLogger.i('All tasks cancelled', 'ThumbnailService');
  }

  // ==================== 查询方法 ====================

  /// 获取队列长度
  int get queueLength => _taskQueue.length;

  /// 获取活跃任务数
  int get activeTaskCount => _activeGenerationCount;

  // ==================== 统计 ====================

  /// 获取统计信息
  Map<String, dynamic> getStats() {
    return {
      'state': _state.toString(),
      'queueLength': queueLength,
      'activeTasks': activeTaskCount,
      ..._stats.toMap(),
    };
  }

  /// 重置统计
  void resetStats() {
    _stats.reset();
  }

  // ==================== 缓存代理 ====================

  /// 清除缓存
  Future<int> clearCache(
    String rootPath, {
    Map<String, dynamic>? options,
  }) async {
    _ensureInitialized();
    return await _cacheService!.clearCache(rootPath, options: options);
  }

  /// 删除缩略图
  Future<bool> deleteThumbnail(
    String originalPath, {
    ThumbnailSize? size,
  }) async {
    _ensureInitialized();
    return await _cacheService!.deleteThumbnail(originalPath, size: size);
  }

  /// 获取缓存大小
  Future<Map<String, dynamic>> getCacheSize(String rootPath) async {
    _ensureInitialized();
    return await _cacheService!.getCacheSize(rootPath);
  }

  /// 按 LRU 淘汰超限的缩略图磁盘缓存
  ///
  /// [rootPath] 图库源根目录；[targetSizeMB] / [targetFileCount] 省略时
  /// 使用缓存服务默认上限。只删除 `.thumbs` 目录内的 `.thumb.jpg` 文件，
  /// 不触碰原图。
  Future<ThumbnailEvictionResult> evictThumbnailCache(
    String rootPath, {
    int? targetSizeMB,
    int? targetFileCount,
  }) async {
    _ensureInitialized();
    return await _cacheService!.evictLRU(
      rootPath,
      targetSizeMB: targetSizeMB,
      targetFileCount: targetFileCount,
    );
  }

  /// 清理嵌套的缩略图目录
  ///
  /// 修复缩略图递归生成bug遗留的嵌套目录问题
  Future<int> cleanupNestedThumbs(String rootPath) async {
    _ensureInitialized();
    return await _cacheService!.cleanupNestedThumbs(rootPath);
  }

  // ==================== 私有方法 ====================

  void _ensureInitialized() {
    if (_state != ThumbnailServiceState.running) {
      throw StateError(
        'ThumbnailService not initialized. Call initialize() first.',
      );
    }
  }

  /// 释放资源
  void dispose() {
    cancelAll();
    _setState(ThumbnailServiceState.disposed);
    _stateController.close();
    _taskController.close();
  }
}

/// 服务统计
class _ThumbnailServiceStats {
  int successCount = 0;
  int failedCount = 0;

  void recordSuccess() => successCount++;
  void recordFailed() => failedCount++;

  void reset() {
    successCount = 0;
    failedCount = 0;
  }

  Map<String, dynamic> toMap() {
    final total = successCount + failedCount;
    return {
      'successCount': successCount,
      'failedCount': failedCount,
      'totalCount': total,
      'successRate': total > 0
          ? '${(successCount / total * 100).toStringAsFixed(1)}%'
          : '0.0%',
    };
  }
}

// ==================== Providers ====================

/// ThumbnailService Provider
///
/// 返回单例实例
@Riverpod(keepAlive: true)
ThumbnailService thumbnailService(Ref ref) {
  final service = ThumbnailService.instance;

  // 确保初始化
  service.initialize();

  // 监听状态变化（日志已禁用，避免频繁输出）
  // service.stateStream.listen((state) {
  //   AppLogger.d('ThumbnailService state: $state', 'ThumbnailServiceProvider');
  // });

  return service;
}

/// 缩略图队列状态 Provider
///
/// 用于监听队列状态变化
@riverpod
Stream<int> thumbnailQueueLength(Ref ref) async* {
  final service = ref.watch(thumbnailServiceProvider);

  yield service.queueLength;

  await for (final _ in service.taskStream) {
    yield service.queueLength;
  }
}

/// 缩略图服务状态 Provider
@riverpod
Stream<ThumbnailServiceState> thumbnailServiceState(Ref ref) {
  final service = ref.watch(thumbnailServiceProvider);
  return service.stateStream;
}
