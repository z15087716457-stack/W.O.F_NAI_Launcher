import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'app_logger.dart';

/// 性能指标类型
enum PerformanceMetricType {
  /// 启动时间
  startupTime,

  /// 内存使用
  memoryUsage,

  /// 缓存命中
  cacheHit,

  /// 缓存未命中
  cacheMiss,

  /// 查询执行
  queryExecution,

  /// 滚动性能
  scrollPerformance,

  /// 图片加载
  imageLoad,

  /// 扫描操作
  scanOperation,
}

/// 性能指标记录
class PerformanceMetric {
  /// 指标名称
  final String name;

  /// 指标类型
  final PerformanceMetricType type;

  /// 记录时间
  final DateTime timestamp;

  /// 持续时间（毫秒）
  final double durationMs;

  /// 附加数据
  final Map<String, dynamic> metadata;

  const PerformanceMetric({
    required this.name,
    required this.type,
    required this.timestamp,
    required this.durationMs,
    this.metadata = const {},
  });

  @override
  String toString() =>
      'PerformanceMetric($name, ${type.name}, ${durationMs.toStringAsFixed(2)}ms)';
}

/// 慢查询记录
class SlowQuery {
  /// SQL 语句
  final String sql;

  /// 执行时间（毫秒）
  final double executionTimeMs;

  /// 执行时间戳
  final DateTime timestamp;

  /// 查询参数
  final List<dynamic>? parameters;

  /// 调用栈（用于定位问题）
  final String? stackTrace;

  const SlowQuery({
    required this.sql,
    required this.executionTimeMs,
    required this.timestamp,
    this.parameters,
    this.stackTrace,
  });

  @override
  String toString() =>
      'SlowQuery(${executionTimeMs.toStringAsFixed(2)}ms): ${sql.substring(0, math.min(100, sql.length))}...';
}

/// 缓存统计
class CacheStats {
  /// 缓存名称
  final String name;

  /// 命中次数
  int hitCount = 0;

  /// 未命中次数
  int missCount = 0;

  /// 驱逐次数
  int evictionCount = 0;

  /// 当前大小
  int currentSize = 0;

  /// 最大容量
  final int maxSize;

  /// 最后更新时间
  DateTime lastUpdated = DateTime.now();

  CacheStats({required this.name, required this.maxSize});

  /// 总访问次数
  int get totalAccess => hitCount + missCount;

  /// 命中率（0.0 - 1.0）
  double get hitRate => totalAccess > 0 ? hitCount / totalAccess : 0.0;

  /// 使用率（0.0 - 1.0）
  double get usageRate => maxSize > 0 ? currentSize / maxSize : 0.0;

  void recordHit() {
    hitCount++;
    lastUpdated = DateTime.now();
  }

  void recordMiss() {
    missCount++;
    lastUpdated = DateTime.now();
  }

  void recordEviction() {
    evictionCount++;
    lastUpdated = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'hitCount': hitCount,
    'missCount': missCount,
    'evictionCount': evictionCount,
    'currentSize': currentSize,
    'maxSize': maxSize,
    'hitRate': hitRate,
    'usageRate': usageRate,
  };
}

/// 内存快照
class MemorySnapshot {
  /// 记录时间
  final DateTime timestamp;

  /// 已使用内存（MB）
  final double usedMemoryMb;

  /// 堆内存（MB）
  final double heapMemoryMb;

  /// 外部内存（MB）
  final double externalMemoryMb;

  /// RSS（MB）
  final double rssMemoryMb;

  MemorySnapshot({
    required this.timestamp,
    required this.usedMemoryMb,
    required this.heapMemoryMb,
    required this.externalMemoryMb,
    required this.rssMemoryMb,
  });

  /// 总内存使用
  double get totalMemoryMb => usedMemoryMb + externalMemoryMb;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'usedMemoryMb': usedMemoryMb,
    'heapMemoryMb': heapMemoryMb,
    'externalMemoryMb': externalMemoryMb,
    'rssMemoryMb': rssMemoryMb,
    'totalMemoryMb': totalMemoryMb,
  };
}

/// 性能监控器
///
/// 收集和报告画廊模块的性能指标，包括：
/// - 启动时间测量
/// - 内存使用监控
/// - 缓存命中率统计
/// - 慢查询检测
/// - 性能日志记录
class GalleryPerformanceMonitor {
  static final GalleryPerformanceMonitor _instance =
      GalleryPerformanceMonitor._internal();
  factory GalleryPerformanceMonitor() => _instance;
  GalleryPerformanceMonitor._internal();

  // ==================== 配置参数 ====================

  /// 慢查询阈值（毫秒）
  static const double slowQueryThresholdMs = 100.0;

  /// 性能问题阈值（毫秒）
  static const double performanceIssueThresholdMs = 500.0;

  /// 最大记录的指标数量
  static const int maxMetricsHistory = 1000;

  /// 最大慢查询记录数
  static const int maxSlowQueries = 100;

  /// 内存监控间隔
  static const Duration memoryCheckInterval = Duration(seconds: 30);

  // ==================== 内部状态 ====================

  /// 指标历史记录
  final Queue<PerformanceMetric> _metrics = Queue<PerformanceMetric>();

  /// 慢查询记录
  final Queue<SlowQuery> _slowQueries = Queue<SlowQuery>();

  /// 缓存统计映射
  final Map<String, CacheStats> _cacheStats = {};

  /// 内存快照历史
  final Queue<MemorySnapshot> _memorySnapshots = Queue<MemorySnapshot>();

  /// 启动时间记录
  final Map<String, DateTime> _startupMarks = {};

  /// 正在进行的计时器
  final Map<String, Stopwatch> _activeTimers = {};

  /// 内存监控定时器
  Timer? _memoryMonitorTimer;

  /// 是否正在监控
  bool _isMonitoring = false;

  // ==================== 公共方法 ====================

  /// 开始监控
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    AppLogger.i('性能监控已启动', 'GalleryPerformanceMonitor');

    // 启动内存监控
    _startMemoryMonitoring();
  }

  /// 停止监控
  void stopMonitoring() {
    _isMonitoring = false;
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
    AppLogger.i('性能监控已停止', 'GalleryPerformanceMonitor');
  }

  /// 记录启动时间点
  void markStartup(String markName) {
    _startupMarks[markName] = DateTime.now();
    AppLogger.d('启动标记: $markName', 'GalleryPerformanceMonitor');
  }

  /// 测量启动时间间隔
  double? measureStartup(String fromMark, String toMark) {
    final from = _startupMarks[fromMark];
    final to = _startupMarks[toMark];

    if (from == null || to == null) return null;

    final duration = to.difference(from).inMicroseconds / 1000.0;
    AppLogger.i(
      '启动时间 [$fromMark -> $toMark]: ${duration.toStringAsFixed(2)}ms',
      'GalleryPerformanceMonitor',
    );

    return duration;
  }

  /// 开始计时
  void startTimer(String operationName) {
    final stopwatch = Stopwatch()..start();
    _activeTimers[operationName] = stopwatch;
  }

  /// 结束计时并记录
  double stopTimer(
    String operationName, {
    PerformanceMetricType type = PerformanceMetricType.queryExecution,
    Map<String, dynamic> metadata = const {},
  }) {
    final stopwatch = _activeTimers.remove(operationName);
    if (stopwatch == null) return 0.0;

    stopwatch.stop();
    final durationMs = stopwatch.elapsedMicroseconds / 1000.0;

    recordMetric(
      name: operationName,
      type: type,
      durationMs: durationMs,
      metadata: metadata,
    );

    return durationMs;
  }

  /// 记录性能指标
  void recordMetric({
    required String name,
    required PerformanceMetricType type,
    required double durationMs,
    Map<String, dynamic> metadata = const {},
  }) {
    final metric = PerformanceMetric(
      name: name,
      type: type,
      timestamp: DateTime.now(),
      durationMs: durationMs,
      metadata: metadata,
    );

    _metrics.add(metric);

    // 限制历史记录数量
    while (_metrics.length > maxMetricsHistory) {
      _metrics.removeFirst();
    }

    // 检测性能问题
    if (durationMs > performanceIssueThresholdMs) {
      AppLogger.w(
        '性能问题检测: $name 耗时 ${durationMs.toStringAsFixed(2)}ms',
        'GalleryPerformanceMonitor',
      );
    }
  }

  /// 记录缓存命中
  void recordCacheHit(String cacheName) {
    _getOrCreateCacheStats(cacheName).recordHit();
  }

  /// 记录缓存未命中
  void recordCacheMiss(String cacheName) {
    _getOrCreateCacheStats(cacheName).recordMiss();
  }

  /// 记录缓存驱逐
  void recordCacheEviction(String cacheName) {
    _getOrCreateCacheStats(cacheName).recordEviction();
  }

  /// 更新缓存大小
  void updateCacheSize(String cacheName, int currentSize) {
    _getOrCreateCacheStats(cacheName).currentSize = currentSize;
  }

  /// 记录慢查询
  void recordSlowQuery({
    required String sql,
    required double executionTimeMs,
    List<dynamic>? parameters,
    String? stackTrace,
  }) {
    if (executionTimeMs < slowQueryThresholdMs) return;

    final query = SlowQuery(
      sql: sql,
      executionTimeMs: executionTimeMs,
      timestamp: DateTime.now(),
      parameters: parameters,
      stackTrace: stackTrace,
    );

    _slowQueries.add(query);

    while (_slowQueries.length > maxSlowQueries) {
      _slowQueries.removeFirst();
    }

    AppLogger.w(
      '慢查询检测 (${executionTimeMs.toStringAsFixed(2)}ms): '
          '${sql.substring(0, math.min(100, sql.length))}',
      'GalleryPerformanceMonitor',
    );
  }

  // ==================== 查询方法 ====================

  /// 获取所有指标
  List<PerformanceMetric> getAllMetrics() => _metrics.toList();

  /// 获取指定类型的指标
  List<PerformanceMetric> getMetricsByType(PerformanceMetricType type) {
    return _metrics.where((m) => m.type == type).toList();
  }

  /// 获取最近 N 个指标
  List<PerformanceMetric> getRecentMetrics(int count) {
    final list = _metrics.toList();
    return list.sublist(math.max(0, list.length - count));
  }

  /// 获取所有慢查询
  List<SlowQuery> getAllSlowQueries() => _slowQueries.toList();

  /// 获取指定时间范围内的慢查询
  List<SlowQuery> getSlowQueriesInRange(DateTime start, DateTime end) {
    return _slowQueries
        .where((q) => q.timestamp.isAfter(start) && q.timestamp.isBefore(end))
        .toList();
  }

  /// 获取缓存统计
  CacheStats? getCacheStats(String cacheName) => _cacheStats[cacheName];

  /// 获取所有缓存统计
  Map<String, CacheStats> getAllCacheStats() => Map.unmodifiable(_cacheStats);

  /// 获取内存快照历史
  List<MemorySnapshot> getMemorySnapshots() => _memorySnapshots.toList();

  /// 计算平均指标值
  double getAverageDuration(PerformanceMetricType type) {
    final metrics = getMetricsByType(type);
    if (metrics.isEmpty) return 0.0;

    final sum = metrics.fold<double>(0.0, (sum, m) => sum + m.durationMs);
    return sum / metrics.length;
  }

  /// 获取 P95 延迟
  double getP95Latency(PerformanceMetricType type) {
    final metrics = getMetricsByType(type)
      ..sort((a, b) => a.durationMs.compareTo(b.durationMs));
    if (metrics.isEmpty) return 0.0;

    final index = (metrics.length * 0.95).ceil() - 1;
    return metrics[math.max(0, index)].durationMs;
  }

  /// 获取 P99 延迟
  double getP99Latency(PerformanceMetricType type) {
    final metrics = getMetricsByType(type)
      ..sort((a, b) => a.durationMs.compareTo(b.durationMs));
    if (metrics.isEmpty) return 0.0;

    final index = (metrics.length * 0.99).ceil() - 1;
    return metrics[math.max(0, index)].durationMs;
  }

  // ==================== 报告生成 ====================

  /// 生成性能报告
  Map<String, dynamic> generateReport() {
    return {
      'generatedAt': DateTime.now().toIso8601String(),
      'summary': {
        'totalMetrics': _metrics.length,
        'slowQueries': _slowQueries.length,
        'cacheStatsCount': _cacheStats.length,
        'memorySnapshots': _memorySnapshots.length,
      },
      'startup': _generateStartupReport(),
      'cacheHitRates': _generateCacheReport(),
      'latencies': _generateLatencyReport(),
      'memory': _generateMemoryReport(),
    };
  }

  /// 打印性能报告
  void printReport() {
    final report = generateReport();
    AppLogger.i('=== 画廊性能报告 ===', 'GalleryPerformanceMonitor');
    AppLogger.i('生成时间: ${report['generatedAt']}', 'GalleryPerformanceMonitor');
    AppLogger.i(
      '指标总数: ${report['summary']['totalMetrics']}',
      'GalleryPerformanceMonitor',
    );
    AppLogger.i(
      '慢查询数: ${report['summary']['slowQueries']}',
      'GalleryPerformanceMonitor',
    );

    // 打印各类型平均延迟
    final latencies = report['latencies'] as Map<String, dynamic>;
    AppLogger.i('平均延迟:', 'GalleryPerformanceMonitor');
    latencies.forEach((type, stats) {
      final avg = (stats as Map<String, dynamic>)['average'] as double;
      AppLogger.i(
        '  $type: ${avg.toStringAsFixed(2)}ms',
        'GalleryPerformanceMonitor',
      );
    });

    // 打印缓存命中率
    final cacheRates = report['cacheHitRates'] as Map<String, dynamic>;
    AppLogger.i('缓存命中率:', 'GalleryPerformanceMonitor');
    cacheRates.forEach((name, stats) {
      final rate = (stats as Map<String, dynamic>)['hitRate'] as double;
      AppLogger.i(
        '  $name: ${(rate * 100).toStringAsFixed(1)}%',
        'GalleryPerformanceMonitor',
      );
    });
  }

  // ==================== 清理方法 ====================

  /// 清除所有数据
  void clearAll() {
    _metrics.clear();
    _slowQueries.clear();
    _cacheStats.clear();
    _memorySnapshots.clear();
    _startupMarks.clear();
    _activeTimers.clear();
    AppLogger.i('性能监控数据已清除', 'GalleryPerformanceMonitor');
  }

  /// 清除指标历史
  void clearMetrics() {
    _metrics.clear();
  }

  /// 清除慢查询记录
  void clearSlowQueries() {
    _slowQueries.clear();
  }

  // ==================== 私有方法 ====================

  CacheStats _getOrCreateCacheStats(String cacheName) {
    return _cacheStats.putIfAbsent(
      cacheName,
      () => CacheStats(name: cacheName, maxSize: 1000),
    );
  }

  void _startMemoryMonitoring() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = Timer.periodic(memoryCheckInterval, (_) {
      _captureMemorySnapshot();
    });
  }

  void _captureMemorySnapshot() {
    try {
      // 获取当前内存使用情况
      final currentRss = _getCurrentRss();

      final snapshot = MemorySnapshot(
        timestamp: DateTime.now(),
        usedMemoryMb: currentRss,
        heapMemoryMb: currentRss * 0.7, // 估算
        externalMemoryMb: currentRss * 0.3, // 估算
        rssMemoryMb: currentRss,
      );

      _memorySnapshots.add(snapshot);

      // 限制快照数量
      while (_memorySnapshots.length > 100) {
        _memorySnapshots.removeFirst();
      }

      // 检测内存异常
      if (currentRss > 1024) {
        // 超过 1GB
        AppLogger.w(
          '内存使用较高: ${currentRss.toStringAsFixed(0)}MB',
          'GalleryPerformanceMonitor',
        );
      }
    } catch (e, stack) {
      AppLogger.e('内存快照捕获失败', e, stack, 'GalleryPerformanceMonitor');
    }
  }

  double _getCurrentRss() {
    // 在 Flutter 中无法直接获取 RSS，使用近似值
    // 实际项目中可以使用 platform channel 获取准确值
    return 0.0;
  }

  Map<String, dynamic> _generateStartupReport() {
    final result = <String, dynamic>{};

    // 查找所有启动相关的标记
    final startupMarks = _startupMarks.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (var i = 0; i < startupMarks.length - 1; i++) {
      final from = startupMarks[i];
      final to = startupMarks[i + 1];
      final duration = to.value.difference(from.value).inMicroseconds / 1000.0;
      result['${from.key}_to_${to.key}'] = duration;
    }

    return result;
  }

  Map<String, dynamic> _generateCacheReport() {
    final result = <String, dynamic>{};

    _cacheStats.forEach((name, stats) {
      result[name] = stats.toJson();
    });

    return result;
  }

  Map<String, dynamic> _generateLatencyReport() {
    final result = <String, dynamic>{};

    for (final type in PerformanceMetricType.values) {
      final metrics = getMetricsByType(type);
      if (metrics.isEmpty) continue;

      final durations = metrics.map((m) => m.durationMs).toList()..sort();
      final sum = durations.fold<double>(0.0, (a, b) => a + b);

      result[type.name] = {
        'count': durations.length,
        'average': sum / durations.length,
        'min': durations.first,
        'max': durations.last,
        'p50': durations[(durations.length * 0.5).ceil() - 1],
        'p95': durations[(durations.length * 0.95).ceil() - 1],
        'p99': durations[(durations.length * 0.99).ceil() - 1],
      };
    }

    return result;
  }

  Map<String, dynamic> _generateMemoryReport() {
    if (_memorySnapshots.isEmpty) {
      return {'available': false};
    }

    final snapshots = _memorySnapshots.toList();
    final memoryValues = snapshots.map((s) => s.totalMemoryMb).toList()..sort();

    return {
      'available': true,
      'snapshotCount': snapshots.length,
      'currentMb': snapshots.last.totalMemoryMb,
      'averageMb': memoryValues.reduce((a, b) => a + b) / memoryValues.length,
      'minMb': memoryValues.first,
      'maxMb': memoryValues.last,
      'trend': _calculateMemoryTrend(snapshots),
    };
  }

  String _calculateMemoryTrend(List<MemorySnapshot> snapshots) {
    if (snapshots.length < 10) return 'insufficient_data';

    final recent = snapshots.sublist(snapshots.length - 10);
    final first = recent.first.totalMemoryMb;
    final last = recent.last.totalMemoryMb;
    final change = last - first;

    if (change > 50) return 'increasing';
    if (change < -50) return 'decreasing';
    return 'stable';
  }
}

/// 便捷访问实例
GalleryPerformanceMonitor get performanceMonitor => GalleryPerformanceMonitor();
