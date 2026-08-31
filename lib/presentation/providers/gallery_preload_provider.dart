import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../data/models/gallery/local_image_record.dart';
import '../../data/services/image_metadata_service.dart';

/// 预加载任务优先级
enum PreloadPriority { high, medium, low }

/// 预加载任务
class PreloadTask {
  final String path;
  final PreloadPriority priority;

  PreloadTask({required this.path, this.priority = PreloadPriority.medium});

  @override
  bool operator ==(Object other) => other is PreloadTask && other.path == path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'PreloadTask($path, $priority)';
}

/// 预加载队列 - 管理图片元数据的预加载任务
class PreloadQueue {
  final _highPriority = Queue<PreloadTask>();
  final _mediumPriority = Queue<PreloadTask>();
  final _lowPriority = Queue<PreloadTask>();
  final _inProgress = <String>{};
  final _completed = <String>{};

  final int maxConcurrent;
  final int maxQueueSize;
  void Function(int loaded, int pending)? onStatsUpdated;

  bool _isRunning = false;
  bool _isPaused = false;

  PreloadQueue({
    this.maxConcurrent = 2,
    this.maxQueueSize = 100,
    this.onStatsUpdated,
  });

  void add(PreloadTask task) {
    if (_completed.contains(task.path)) return;

    switch (task.priority) {
      case PreloadPriority.high:
        _addToQueue(_highPriority, task);
      case PreloadPriority.medium:
        _addToQueue(_mediumPriority, task);
      case PreloadPriority.low:
        _addToQueue(_lowPriority, task);
    }

    _notifyStatsUpdate();
  }

  void _addToQueue(Queue<PreloadTask> queue, PreloadTask task) {
    if (queue.any((t) => t.path == task.path)) return;
    if (_inProgress.contains(task.path)) return;

    if (queue.length >= maxQueueSize) {
      if (queue == _lowPriority && queue.isNotEmpty) {
        queue.removeFirst();
      } else if (queue == _mediumPriority && _lowPriority.isNotEmpty) {
        _lowPriority.removeFirst();
      } else {
        return;
      }
    }

    queue.add(task);
  }

  void addAll(List<PreloadTask> tasks) {
    for (final task in tasks) {
      add(task);
    }
  }

  void _notifyStatsUpdate() => onStatsUpdated?.call(_completed.length, length);

  PreloadTask? _nextTask() {
    if (_highPriority.isNotEmpty) return _highPriority.removeFirst();
    if (_mediumPriority.isNotEmpty) return _mediumPriority.removeFirst();
    if (_lowPriority.isNotEmpty) return _lowPriority.removeFirst();
    return null;
  }

  Future<void> start() async {
    if (_isRunning || _isPaused) return;
    _isRunning = true;

    AppLogger.d('Preload queue started', 'PreloadQueue');

    while (_isRunning && !_isPaused) {
      if (_inProgress.length >= maxConcurrent) {
        await Future.delayed(const Duration(milliseconds: 10));
        continue;
      }

      final task = _nextTask();
      if (task == null) {
        await Future.delayed(const Duration(milliseconds: 50));
        continue;
      }

      _inProgress.add(task.path);
      _executeTask(task);
      _notifyStatsUpdate();
    }

    _isRunning = false;
  }

  Future<void> _executeTask(PreloadTask task) async {
    try {
      if (!task.path.toLowerCase().endsWith('.png')) {
        _completed.add(task.path);
        _inProgress.remove(task.path);
        return;
      }

      await ImageMetadataService().getMetadata(task.path);
      _completed.add(task.path);

      AppLogger.d(
        'Preloaded: ${task.path.split(Platform.pathSeparator).last}',
        'PreloadQueue',
      );
    } catch (e) {
      AppLogger.w('Failed to preload ${task.path}: $e', 'PreloadQueue');
    } finally {
      _inProgress.remove(task.path);
      _notifyStatsUpdate();
    }
  }

  void pause() {
    _isPaused = true;
    AppLogger.d('Preload queue paused', 'PreloadQueue');
  }

  void resume() {
    if (!_isPaused) return;
    _isPaused = false;
    if (!_isRunning) start();
    AppLogger.d('Preload queue resumed', 'PreloadQueue');
  }

  void stop() {
    _isRunning = false;
    _isPaused = false;
    AppLogger.d('Preload queue stopped', 'PreloadQueue');
  }

  void clear() {
    _highPriority.clear();
    _mediumPriority.clear();
    _lowPriority.clear();
    _inProgress.clear();
    _notifyStatsUpdate();
    AppLogger.d('Preload queue cleared', 'PreloadQueue');
  }

  void markCompleted(String path) {
    _completed.add(path);
    _notifyStatsUpdate();
  }

  void resetCompleted() {
    _completed.clear();
    _notifyStatsUpdate();
  }

  void remove(String path) {
    _highPriority.removeWhere((t) => t.path == path);
    _mediumPriority.removeWhere((t) => t.path == path);
    _lowPriority.removeWhere((t) => t.path == path);
  }

  Map<String, int> get stats => {
    'high': _highPriority.length,
    'medium': _mediumPriority.length,
    'low': _lowPriority.length,
    'inProgress': _inProgress.length,
    'completed': _completed.length,
  };

  int get length =>
      _highPriority.length + _mediumPriority.length + _lowPriority.length;

  bool get isIdle =>
      _highPriority.isEmpty &&
      _mediumPriority.isEmpty &&
      _lowPriority.isEmpty &&
      _inProgress.isEmpty;
}

/// 预加载配置
class PreloadConfig {
  final int forwardPages;
  final int backwardPages;
  final int highPriorityBuffer;
  final int mediumPriorityBuffer;

  const PreloadConfig({
    this.forwardPages = 2,
    this.backwardPages = 1,
    this.highPriorityBuffer = 10,
    this.mediumPriorityBuffer = 30,
  });

  static const defaultConfig = PreloadConfig();
}

/// 预加载状态
class PreloadState {
  final bool isLoading;
  final int loadedCount;
  final int pendingCount;
  final int errorCount;

  const PreloadState({
    this.isLoading = false,
    this.loadedCount = 0,
    this.pendingCount = 0,
    this.errorCount = 0,
  });

  PreloadState copyWith({
    bool? isLoading,
    int? loadedCount,
    int? pendingCount,
    int? errorCount,
  }) => PreloadState(
    isLoading: isLoading ?? this.isLoading,
    loadedCount: loadedCount ?? this.loadedCount,
    pendingCount: pendingCount ?? this.pendingCount,
    errorCount: errorCount ?? this.errorCount,
  );
}

/// 预加载状态 Notifier
class PreloadNotifier extends StateNotifier<PreloadState> {
  PreloadQueue? _queue;
  PreloadConfig _config = PreloadConfig.defaultConfig;

  PreloadNotifier() : super(const PreloadState()) {
    _initQueue();
  }

  void _initQueue() {
    _queue = PreloadQueue(
      onStatsUpdated: (loaded, pending) {
        state = state.copyWith(loadedCount: loaded, pendingCount: pending);
      },
    );
  }

  PreloadQueue get _ensureQueue {
    _queue ??= PreloadQueue(
      onStatsUpdated: (loaded, pending) {
        state = state.copyWith(loadedCount: loaded, pendingCount: pending);
      },
    );
    return _queue!;
  }

  void setConfig(PreloadConfig config) => _config = config;

  void updateVisibleRange(
    List<int> visibleIndices,
    List<LocalImageRecord> allRecords,
  ) {
    if (visibleIndices.isEmpty || allRecords.isEmpty) return;

    final queue = _ensureQueue;
    final newTasks = <PreloadTask>[];

    // 高优先级：当前可见项
    for (final index in visibleIndices) {
      if (index >= 0 && index < allRecords.length) {
        newTasks.add(
          PreloadTask(
            path: allRecords[index].path,
            priority: PreloadPriority.high,
          ),
        );
      }
    }

    // 计算可见范围边界
    var minVisible = visibleIndices.first;
    var maxVisible = visibleIndices.first;
    for (final i in visibleIndices.skip(1)) {
      if (i < minVisible) minVisible = i;
      if (i > maxVisible) maxVisible = i;
    }

    // 中优先级：即将进入可视区域的项
    final mediumStart = (minVisible - _config.mediumPriorityBuffer).clamp(
      0,
      allRecords.length,
    );
    final mediumEnd = (maxVisible + _config.mediumPriorityBuffer).clamp(
      0,
      allRecords.length,
    );

    for (var i = mediumStart; i < mediumEnd; i++) {
      if (!visibleIndices.contains(i)) {
        newTasks.add(
          PreloadTask(
            path: allRecords[i].path,
            priority: PreloadPriority.medium,
          ),
        );
      }
    }

    // 低优先级：更远处的项
    final lowStart = (minVisible - _config.mediumPriorityBuffer * 2).clamp(
      0,
      allRecords.length,
    );
    final lowEnd = (maxVisible + _config.mediumPriorityBuffer * 2).clamp(
      0,
      allRecords.length,
    );

    for (var i = lowStart; i < lowEnd; i++) {
      if (i < mediumStart || i >= mediumEnd) {
        newTasks.add(
          PreloadTask(path: allRecords[i].path, priority: PreloadPriority.low),
        );
      }
    }

    queue.clear();
    queue.addAll(newTasks);
    _startIfNeeded();
  }

  void preloadRange(
    int startIndex,
    int endIndex,
    List<LocalImageRecord> records,
    PreloadPriority priority,
  ) {
    final queue = _ensureQueue;

    for (var i = startIndex; i <= endIndex && i < records.length; i++) {
      if (i >= 0) {
        queue.add(PreloadTask(path: records[i].path, priority: priority));
      }
    }

    _startIfNeeded();
  }

  void preloadNextPage(
    int currentPage,
    int pageSize,
    List<LocalImageRecord> allRecords,
  ) {
    final startIndex = (currentPage + 1) * pageSize;
    final endIndex = startIndex + pageSize - 1;

    preloadRange(startIndex, endIndex, allRecords, PreloadPriority.medium);
  }

  void _startIfNeeded() {
    final queue = _ensureQueue;
    if (queue.isIdle) return;

    state = state.copyWith(isLoading: true);
    queue.start().then((_) {
      state = state.copyWith(isLoading: false);
    });
  }

  void pause() {
    _ensureQueue.pause();
    state = state.copyWith(isLoading: false);
  }

  void resume() {
    _ensureQueue.resume();
    state = state.copyWith(isLoading: true);
  }

  void stop() {
    _ensureQueue.stop();
    state = state.copyWith(isLoading: false);
  }

  void clear() {
    _ensureQueue.clear();
    state = state.copyWith(pendingCount: 0, isLoading: false);
  }

  void reset() {
    _ensureQueue.resetCompleted();
    state = const PreloadState();
  }

  Map<String, int> getStats() => _ensureQueue.stats;

  @override
  void dispose() {
    _queue?.stop();
    _queue = null;
    super.dispose();
  }
}

/// 画廊预加载 Provider
final galleryPreloadProvider =
    StateNotifierProvider<PreloadNotifier, PreloadState>(
      (ref) => PreloadNotifier(),
    );

/// 当前可见索引 Provider
final visibleGalleryIndicesProvider = StateProvider<Set<int>>((ref) => {});
