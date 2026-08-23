import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../utils/app_logger.dart';
import '../utils/gallery_path_utils.dart';
import '../utils/isolate_pool.dart';

part 'thumbnail_cache_service.g.dart';

/// 缩略图尺寸类型
enum ThumbnailSize {
  /// 微型缩略图（列表预览）
  micro(80, 100),

  /// 小型缩略图（网格视图）
  small(180, 220),

  /// 中型缩略图（详情预览）
  medium(360, 440),

  /// 大型缩略图（全屏预览）
  large(720, 880);

  final int width;
  final int height;

  const ThumbnailSize(this.width, this.height);

  /// 获取尺寸标识符
  String get identifier => name;

  /// 获取文件后缀
  String get fileSuffix => '.$name';
}

/// 按显示尺寸挑选缩略图档位（纯函数，可单测）。
///
/// 物理需求宽度 = 逻辑卡片宽 × 设备像素比（DPR），
/// 选「宽度 ≥ 需求」的最小档：≤180 物理像素 → small，≤360 → medium，否则 large。
/// 宽屏少列大图自动走 medium/large（按需懒生成新缓存，旧小档留盘无害），
/// 窄列多列仍走 small 省资源。
ThumbnailSize pickThumbnailSize(
  double logicalCardWidth,
  double devicePixelRatio,
) {
  final physicalWidth = logicalCardWidth * devicePixelRatio;
  if (physicalWidth <= ThumbnailSize.small.width) {
    return ThumbnailSize.small;
  }
  if (physicalWidth <= ThumbnailSize.medium.width) {
    return ThumbnailSize.medium;
  }
  return ThumbnailSize.large;
}

/// 缩略图信息
class ThumbnailInfo {
  final String path;
  final int width;
  final int height;
  final DateTime createdAt;
  final ThumbnailSize size;
  DateTime lastAccessedAt;
  int accessCount;
  bool isVisible;
  int visibilityPriority;

  ThumbnailInfo({
    required this.path,
    required this.width,
    required this.height,
    required this.createdAt,
    required this.size,
    DateTime? lastAccessedAt,
    this.accessCount = 1,
    this.isVisible = false,
    this.visibilityPriority = 5,
  }) : lastAccessedAt = lastAccessedAt ?? createdAt;

  /// 记录访问
  void recordAccess() {
    accessCount++;
    lastAccessedAt = DateTime.now();
  }

  /// 更新可见性
  void updateVisibility(bool visible, {int priority = 5}) {
    isVisible = visible;
    visibilityPriority = visible ? priority : 10;
  }

  /// 转换为 JSON（用于持久化）
  Map<String, dynamic> toJson() => {
    'path': path,
    'width': width,
    'height': height,
    'createdAt': createdAt.toIso8601String(),
    'size': size.name,
    'lastAccessedAt': lastAccessedAt.toIso8601String(),
    'accessCount': accessCount,
    'isVisible': isVisible,
    'visibilityPriority': visibilityPriority,
  };

  /// 从 JSON 创建
  factory ThumbnailInfo.fromJson(Map<String, dynamic> json) {
    return ThumbnailInfo(
      path: json['path'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      size: ThumbnailSize.values.firstWhere(
        (s) => s.name == (json['size'] as String? ?? 'small'),
        orElse: () => ThumbnailSize.small,
      ),
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
          : null,
      accessCount: json['accessCount'] as int? ?? 1,
      isVisible: json['isVisible'] as bool? ?? false,
      visibilityPriority: json['visibilityPriority'] as int? ?? 5,
    );
  }
}

/// 缩略图缓存服务
///
/// 负责缩略图的生成、缓存和检索
///
/// 特性：
/// - 磁盘缓存缩略图，避免重复解码原始大图
/// - 支持多尺寸缩略图（micro/small/medium/large）
/// - 使用 LRU + 可见性优先级队列管理缓存
/// - 异步生成缩略图，不阻塞 UI
/// - 与原图保持相同目录结构，存储在.thumbs子目录下
/// - 防止重复初始化，确保全局状态一致性
/// - 优化的并发控制
class ThumbnailCacheService {
  static ThumbnailCacheService? _instance;
  static bool _initialized = false;

  static ThumbnailCacheService get instance {
    _instance ??= ThumbnailCacheService._internal();
    return _instance!;
  }

  ThumbnailCacheService._internal();

  /// 初始化任务缓存，防止重复初始化和轮询等待。
  Future<void>? _initFuture;

  /// 默认缩略图尺寸
  static const ThumbnailSize defaultSize = ThumbnailSize.small;

  /// 缩略图质量 (JPEG)
  static const int jpegQuality = 85;

  /// 缩略图子目录名称
  static const String thumbsDirName = '.thumbs';

  /// 缩略图文件扩展名
  static const String thumbnailExt = '.thumb.jpg';

  /// 最大并发生成数
  static const int maxConcurrentGenerations = 3;

  /// 正在生成的缩略图路径集合
  final Set<String> _generatingThumbnails = {};

  /// 等待缩略图生成的 Completer Map（路径 -> Completer）
  final Map<String, Completer<String?>> _generationCompleters = {};

  /// 缩略图生成队列（按优先级排序）
  final List<_ThumbnailTask> _taskQueue = [];

  /// 画廊根目录列表（主源 + 额外图库源，用于路径遍历验证）
  List<String> _rootPaths = const [];

  /// 最大队列长度限制
  static const int maxQueueSize = 200;

  /// 当前正在进行的生成任务数
  int _activeGenerationCount = 0;

  /// 统计信息
  final _ThumbnailStats _stats = _ThumbnailStats();

  /// 最近失败记录，避免同一路径在短时间内疯狂重试。
  final Map<String, DateTime> _recentFailureTimes = {};
  static const Duration _failureRetryCooldown = Duration(seconds: 10);

  /// 缓存限制配置
  static const int defaultMaxCacheSizeMB = 500;
  static const int defaultMaxFileCount = 10000;

  /// LRU 追踪：缩略图路径 -> 最后访问时间
  final Map<String, DateTime> _lastAccessTimes = {};

  /// 可见性追踪：缩略图路径 -> 可见性信息
  final Map<String, _VisibilityInfo> _visibilityInfo = {};

  /// 缓存大小限制（MB）
  int _maxCacheSizeMB = defaultMaxCacheSizeMB;

  /// 最大文件数限制
  int _maxFileCount = defaultMaxFileCount;

  /// 初始化完成标志
  bool get isInitialized => _initialized;

  /// 初始化服务
  ///
  /// 线程安全，防止重复初始化
  Future<void> init() {
    if (_initialized) return Future.value();
    return _initFuture ??= _runInit();
  }

  Future<void> _runInit() async {
    try {
      // 清理任何残留状态
      _cleanupStaleState();

      _initialized = true;
    } finally {
      _initFuture = null;
    }
  }

  /// 清理残留状态
  void _cleanupStaleState() {
    _generatingThumbnails.clear();
    _generationCompleters.clear();
    _taskQueue.clear();
    _activeGenerationCount = 0;
  }

  /// 设置根目录路径集合（主源 + 额外图库源，用于路径遍历验证）
  void setRootPaths(List<String> rootPaths) {
    _rootPaths = rootPaths;
  }

  /// 设置缓存限制
  ///
  /// [maxSizeMB] 最大缓存大小（MB）
  /// [maxFiles] 最大文件数量
  void setCacheLimits({int? maxSizeMB, int? maxFiles}) {
    if (maxSizeMB != null && maxSizeMB > 0) {
      _maxCacheSizeMB = maxSizeMB;
    }
    if (maxFiles != null && maxFiles > 0) {
      _maxFileCount = maxFiles;
    }
    AppLogger.d(
      'Cache limits updated: maxSize=${_maxCacheSizeMB}MB, maxFiles=$_maxFileCount',
      'ThumbnailCache',
    );
  }

  /// 获取缩略图路径
  ///
  /// 如果缩略图已存在，直接返回路径
  /// 如果不存在，返回 null，需要调用 generateThumbnail 生成
  ///
  /// [originalPath] 原始图片路径
  /// [size] 缩略图尺寸（默认 small）
  ///
  /// 注意：此方法使用异步文件检查，不会阻塞 UI 线程
  Future<String?> getThumbnailPath(
    String originalPath, {
    ThumbnailSize size = defaultSize,
  }) async {
    final thumbnailPath = _getThumbnailPath(originalPath, size: size);
    final file = File(thumbnailPath);

    if (await file.exists()) {
      _stats.recordHit();
      // 记录访问时间用于 LRU
      _lastAccessTimes[thumbnailPath] = DateTime.now();
      // AppLogger.d('Thumbnail cache HIT: $thumbnailPath', 'ThumbnailCache');
      return thumbnailPath;
    }

    _stats.recordMiss();
    // AppLogger.d('Thumbnail cache MISS: $originalPath', 'ThumbnailCache');
    return null;
  }

  /// 同步获取缩略图路径（仅用于已知缓存存在的情况）
  ///
  /// 警告：此方法使用同步文件检查，在主线程频繁调用可能阻塞 UI。
  /// 推荐使用异步版本的 [getThumbnailPath]。
  String? getThumbnailPathSync(
    String originalPath, {
    ThumbnailSize size = defaultSize,
  }) {
    final thumbnailPath = _getThumbnailPath(originalPath, size: size);
    final file = File(thumbnailPath);

    if (file.existsSync()) {
      _stats.recordHit();
      _lastAccessTimes[thumbnailPath] = DateTime.now();
      return thumbnailPath;
    }

    _stats.recordMiss();
    return null;
  }

  /// 异步获取或生成缩略图
  ///
  /// 如果缩略图已存在，直接返回路径
  /// 如果不存在，异步生成缩略图并返回路径
  ///
  /// [originalPath] 原始图片路径
  /// [size] 缩略图尺寸（默认 small）
  /// [priority] 生成优先级（数字越小优先级越高，默认 5）
  Future<String?> getOrGenerateThumbnail(
    String originalPath, {
    ThumbnailSize size = defaultSize,
    int priority = 5,
  }) async {
    if (_isInFailureCooldown(originalPath, size: size)) {
      return null;
    }

    // 首先检查缓存
    final existingPath = await getThumbnailPath(originalPath, size: size);
    if (existingPath != null) {
      return existingPath;
    }

    // 检查文件是否存在
    final originalFile = File(originalPath);
    if (!await originalFile.exists()) {
      AppLogger.w('Original file not found: $originalPath', 'ThumbnailCache');
      return null;
    }

    // 生成缩略图
    return generateThumbnail(originalPath, size: size, priority: priority);
  }

  /// 生成缩略图
  ///
  /// [originalPath] 原始图片路径
  /// [size] 缩略图尺寸（默认 small）
  /// [priority] 生成优先级（数字越小优先级越高，默认 5）
  /// 返回生成的缩略图路径，失败返回 null
  Future<String?> generateThumbnail(
    String originalPath, {
    ThumbnailSize size = defaultSize,
    int priority = 5,
  }) async {
    // 【修复】防止为缩略图生成缩略图
    if (originalPath.contains('.thumb.') ||
        originalPath.contains(
          '${Platform.pathSeparator}.thumbs${Platform.pathSeparator}',
        )) {
      // AppLogger.w('Refusing to generate thumbnail for thumbnail: $originalPath', 'ThumbnailCache');
      return null;
    }

    if (_isInFailureCooldown(originalPath, size: size)) {
      return null;
    }

    final thumbnailPath = _getThumbnailPath(originalPath, size: size);

    // 检查是否已在生成中
    if (_generatingThumbnails.contains(originalPath)) {
      // AppLogger.d('Thumbnail generation already in progress: $originalPath', 'ThumbnailCache');
      // 等待生成完成
      return _waitForGeneration(originalPath);
    }

    // 检查是否已存在（可能在等待期间其他任务已生成）
    final file = File(thumbnailPath);
    if (await file.exists()) {
      _stats.recordHit();
      return thumbnailPath;
    }

    // 如果并发数已达上限，加入队列
    if (_activeGenerationCount >= maxConcurrentGenerations) {
      // AppLogger.d('Thumbnail generation queued: $originalPath (priority: $priority)', 'ThumbnailCache');
      return _queueGeneration(originalPath, size: size, priority: priority);
    }

    // 直接生成
    _activeGenerationCount++;
    return _doGenerateThumbnail(originalPath, size: size);
  }

  /// 最大允许的文件大小 (50MB)
  static const int _maxFileSizeBytes = 50 * 1024 * 1024;

  /// 实际执行缩略图生成
  Future<String?> _doGenerateThumbnail(
    String originalPath, {
    required ThumbnailSize size,
  }) async {
    final thumbnailPath = _getThumbnailPath(originalPath, size: size);
    _generatingThumbnails.add(originalPath);

    final stopwatch = Stopwatch()..start();

    try {
      // 确保缩略图目录存在
      final thumbDir = Directory(_getThumbnailDir(originalPath));
      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }

      final result = await ComputeGate().runCompute(
        _generateThumbnailBytesInIsolate,
        <String, Object?>{
          'originalPath': originalPath,
          'maxFileSizeBytes': _maxFileSizeBytes,
          'targetWidth': size.width,
          'targetHeight': size.height,
          'jpegQuality': jpegQuality,
        },
        debugLabel: 'thumbnail_${p.basename(originalPath)}',
      );

      final thumbBytes = result['bytes'] as Uint8List;

      await File(thumbnailPath).writeAsBytes(thumbBytes);
      _recentFailureTimes.remove(_failureKey(originalPath, size: size));

      stopwatch.stop();
      _stats.recordGenerated();

      // AppLogger.i(
      //   'Thumbnail generated: ${originalPath.split('/').last} '
      //   '(${originalImage.width}x${originalImage.height} -> ${thumbnail.width}x${thumbnail.height}) '
      //   'in ${stopwatch.elapsedMilliseconds}ms',
      //   'ThumbnailCache',
      // );

      // 通知等待的 Completer 生成完成
      final completer = _generationCompleters.remove(originalPath);
      if (completer != null && !completer.isCompleted) {
        completer.complete(thumbnailPath);
      }

      return thumbnailPath;
    } catch (e, stack) {
      _stats.recordFailed();
      _recentFailureTimes[_failureKey(originalPath, size: size)] =
          DateTime.now();
      AppLogger.e(
        'Failed to generate thumbnail for $originalPath: $e',
        e,
        stack,
        'ThumbnailCache',
      );
      // 通知等待的 Completer 生成失败
      final completer = _generationCompleters.remove(originalPath);
      if (completer != null && !completer.isCompleted) {
        completer.complete(null);
      }
      return null;
    } finally {
      _generatingThumbnails.remove(originalPath);
      _activeGenerationCount--;
      _processQueue();
    }
  }

  /// 将生成任务加入队列
  Future<String?> _queueGeneration(
    String originalPath, {
    required ThumbnailSize size,
    required int priority,
  }) {
    // 检查队列是否已满
    if (_taskQueue.length >= maxQueueSize) {
      // 移除优先级最低的任务
      _taskQueue.sort(
        (a, b) => a.effectivePriority.compareTo(b.effectivePriority),
      );
      final lowestPriorityTask = _taskQueue.last;
      if (lowestPriorityTask.effectivePriority > priority) {
        _taskQueue.removeLast();
        AppLogger.w(
          'Removed lowest priority task from queue to make room',
          'ThumbnailCache',
        );
      } else {
        AppLogger.w(
          'Thumbnail generation queue is full (max $maxQueueSize), rejecting task: $originalPath',
          'ThumbnailCache',
        );
        return Future.value(null);
      }
    }

    final completer = Completer<String?>();
    _taskQueue.add(
      _ThumbnailTask(
        originalPath: originalPath,
        completer: completer,
        size: size,
        basePriority: priority,
      ),
    );

    // 重新排序队列（考虑可见性优先级）
    _sortQueueByPriority();

    return completer.future;
  }

  /// 按优先级排序队列
  void _sortQueueByPriority() {
    _taskQueue.sort(
      (a, b) => a.effectivePriority.compareTo(b.effectivePriority),
    );
  }

  /// 等待正在进行的生成任务完成
  Future<String?> _waitForGeneration(String originalPath) async {
    final completer = _generationCompleters.putIfAbsent(
      originalPath,
      () => Completer<String?>(),
    );

    try {
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          AppLogger.w(
            'Timeout waiting for thumbnail generation: $originalPath',
            'ThumbnailCache',
          );
          return null;
        },
      );
    } finally {
      _generationCompleters.remove(originalPath);
    }
  }

  /// 处理队列中的任务
  void _processQueue() {
    if (_taskQueue.isEmpty ||
        _activeGenerationCount >= maxConcurrentGenerations) {
      return;
    }

    _activeGenerationCount++;

    final task = _taskQueue.removeAt(0);
    _doGenerateThumbnail(task.originalPath, size: task.size)
        .then((path) {
          task.completer.complete(path);
        })
        .catchError((error) {
          task.completer.completeError(error);
        });
  }

  /// 更新缩略图可见性
  ///
  /// 用于可见性感知的优先级调整
  /// [originalPath] 原始图片路径
  /// [isVisible] 是否可见
  /// [priority] 可见时的优先级（默认 1，最高优先级）
  void updateThumbnailVisibility(
    String originalPath, {
    required bool isVisible,
    int priority = 1,
  }) {
    final info = _visibilityInfo[originalPath];
    if (info != null) {
      info.isVisible = isVisible;
      info.priority = isVisible ? priority : 5;
    } else {
      _visibilityInfo[originalPath] = _VisibilityInfo(
        isVisible: isVisible,
        priority: isVisible ? priority : 5,
      );
    }

    // 如果有相关任务在队列中，重新排序
    bool needsReorder = false;
    for (final task in _taskQueue) {
      if (task.originalPath == originalPath) {
        needsReorder = true;
        break;
      }
    }

    if (needsReorder) {
      _sortQueueByPriority();
    }
  }

  /// 批量更新可见性
  void batchUpdateVisibility(List<String> visiblePaths, {int priority = 1}) {
    // 重置所有可见性
    for (final entry in _visibilityInfo.entries) {
      entry.value.isVisible = false;
      entry.value.priority = 5;
    }

    // 设置新的可见性
    for (final path in visiblePaths) {
      updateThumbnailVisibility(path, isVisible: true, priority: priority);
    }

    // 重新排序队列
    _sortQueueByPriority();
  }

  /// 删除缩略图
  ///
  /// [originalPath] 原始图片路径
  /// [size] 缩略图尺寸（可选，不提供则删除所有尺寸）
  Future<bool> deleteThumbnail(
    String originalPath, {
    ThumbnailSize? size,
  }) async {
    try {
      if (size != null) {
        // 删除指定尺寸
        final thumbnailPath = _getThumbnailPath(originalPath, size: size);
        final file = File(thumbnailPath);

        if (await file.exists()) {
          await file.delete();
          return true;
        }
      } else {
        // 删除所有尺寸
        bool anyDeleted = false;
        for (final s in ThumbnailSize.values) {
          final thumbnailPath = _getThumbnailPath(originalPath, size: s);
          final file = File(thumbnailPath);

          if (await file.exists()) {
            await file.delete();
            anyDeleted = true;
          }
        }

        if (anyDeleted) {
          // AppLogger.d('All thumbnails deleted for: $originalPath', 'ThumbnailCache');
        }
        return anyDeleted;
      }

      return false;
    } catch (e, stack) {
      AppLogger.e(
        'Failed to delete thumbnail for $originalPath: $e',
        e,
        stack,
        'ThumbnailCache',
      );
      return false;
    }
  }

  /// 批量删除缩略图
  ///
  /// [originalPaths] 原始图片路径列表
  Future<int> deleteThumbnails(List<String> originalPaths) async {
    int deletedCount = 0;

    for (final path in originalPaths) {
      if (await deleteThumbnail(path)) {
        deletedCount++;
      }
    }

    // AppLogger.i('Batch deleted $deletedCount/${originalPaths.length} thumbnails', 'ThumbnailCache');

    return deletedCount;
  }

  /// 清理整个缩略图缓存
  ///
  /// [rootPath] 画廊根目录路径，用于定位所有 .thumbs 目录
  /// [options] 清理选项，可选参数：
  ///   - 'resetStats': bool - 是否重置统计信息（默认 true）
  ///   - 'preserveAccessTimes': bool - 是否保留访问时间记录（默认 false）
  /// 返回被删除的目录数量
  Future<int> clearCache(
    String rootPath, {
    Map<String, dynamic>? options,
  }) async {
    try {
      final rootDir = Directory(rootPath);
      if (!await rootDir.exists()) {
        AppLogger.w('Root directory not found: $rootPath', 'ThumbnailCache');
        return 0;
      }

      final resetStats = options?['resetStats'] as bool? ?? true;
      final preserveAccessTimes =
          options?['preserveAccessTimes'] as bool? ?? false;

      int deletedCount = 0;
      final List<String> deletedPaths = [];

      // 遍历所有子目录，删除 .thumbs 文件夹
      await for (final entity in rootDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is Directory) {
          final dirName = entity.path.split(Platform.pathSeparator).last;
          if (dirName == thumbsDirName) {
            // 收集要删除的文件路径
            await for (final file in entity.list(recursive: true)) {
              if (file is File) {
                deletedPaths.add(file.path);
              }
            }

            await entity.delete(recursive: true);
            deletedCount++;
          }
        }
      }

      // 清理访问时间记录
      if (!preserveAccessTimes) {
        _lastAccessTimes.clear();
        _visibilityInfo.clear();
      } else {
        // 只删除已不存在的文件的访问记录
        for (final path in deletedPaths) {
          _lastAccessTimes.remove(path);
        }
      }

      // 重置统计（可选）
      if (resetStats) {
        _stats.reset();
      }

      return deletedCount;
    } catch (e, stack) {
      AppLogger.e('Failed to clear cache: $e', e, stack, 'ThumbnailCache');
      return 0;
    }
  }

  /// 清理指定时间之前的缩略图（按创建时间）
  ///
  /// [rootPath] 画廊根目录路径
  /// [before] 清理此时间之前创建的缩略图
  /// 返回被删除的文件数量
  Future<int> clearCacheBefore(String rootPath, DateTime before) async {
    try {
      final rootDir = Directory(rootPath);
      if (!await rootDir.exists()) {
        return 0;
      }

      int deletedCount = 0;

      await for (final entity in rootDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is Directory) {
          final dirName = entity.path.split(Platform.pathSeparator).last;
          if (dirName == thumbsDirName) {
            await for (final file in entity.list(recursive: true)) {
              if (file is File) {
                try {
                  final stat = await file.stat();
                  if (stat.modified.isBefore(before)) {
                    await file.delete();
                    _lastAccessTimes.remove(file.path);
                    deletedCount++;
                  }
                } catch (_) {
                  // 忽略无法删除的文件
                }
              }
            }
          }
        }
      }

      return deletedCount;
    } catch (e, stack) {
      AppLogger.e(
        'Failed to clear cache before date: $e',
        e,
        stack,
        'ThumbnailCache',
      );
      return 0;
    }
  }

  /// 【修复】清理嵌套的.thumbs目录
  ///
  /// 修复缩略图递归生成bug遗留的嵌套目录问题
  /// [rootPath] 画廊根目录路径
  /// 返回清理的嵌套目录数量
  Future<int> cleanupNestedThumbs(String rootPath) async {
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) return 0;

    int cleanedCount = 0;

    try {
      // 找到所有.thumbs目录
      final thumbsDirs = <Directory>[];
      await for (final entity in rootDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is Directory) {
          final dirName = p.basename(entity.path);
          if (dirName == thumbsDirName) {
            thumbsDirs.add(entity);
          }
        }
      }

      // 检查每个.thumbs目录是否有嵌套的.thumbs子目录
      for (final thumbsDir in thumbsDirs) {
        await for (final entity in thumbsDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is Directory) {
            final dirName = p.basename(entity.path);
            if (dirName == thumbsDirName) {
              try {
                await entity.delete(recursive: true);
                cleanedCount++;
              } catch (e) {
                // AppLogger.w('Failed to delete nested thumbs: ${entity.path}', 'ThumbnailCache');
              }
            }
          }
        }
      }

      return cleanedCount;
    } catch (e, stack) {
      AppLogger.e(
        'Failed to cleanup nested thumbs: $e',
        e,
        stack,
        'ThumbnailCache',
      );
      return 0;
    }
  }

  /// 获取缓存统计
  ///
  /// 返回包含命中统计、队列状态、限制配置等信息的 Map
  Map<String, dynamic> getStats() {
    final stats = _stats.toMap();

    return {
      ...stats,

      // 队列状态
      'queueLength': _taskQueue.length,
      'activeGenerations': _activeGenerationCount,
      'maxConcurrentGenerations': maxConcurrentGenerations,

      // 限制配置
      'maxCacheSizeMB': _maxCacheSizeMB,
      'maxFileCount': _maxFileCount,

      // LRU 追踪数量
      'trackedAccessTimes': _lastAccessTimes.length,
      'trackedVisibility': _visibilityInfo.length,

      // 初始化状态
      'isInitialized': _initialized,
    };
  }

  /// 获取详细的缓存统计（包含磁盘使用情况）
  ///
  /// [rootPath] 画廊根目录路径
  Future<Map<String, dynamic>> getDetailedStats(String rootPath) async {
    final basicStats = getStats();
    final cacheSizeInfo = await getCacheSize(rootPath);

    return {...basicStats, 'diskCache': cacheSizeInfo};
  }

  /// 重置统计信息
  void resetStats() {
    _stats.reset();
    _lastAccessTimes.clear();
    _visibilityInfo.clear();
    AppLogger.d('Statistics reset', 'ThumbnailCache');
  }

  /// 获取指定目录的缩略图缓存大小
  ///
  /// [rootPath] 画廊根目录路径
  Future<Map<String, dynamic>> getCacheSize(String rootPath) async {
    try {
      final rootDir = Directory(rootPath);
      if (!await rootDir.exists()) {
        return {'fileCount': 0, 'totalSize': 0, 'totalSizeMB': 0.0};
      }

      int fileCount = 0;
      int totalSize = 0;
      final Map<String, int> sizeCounts = {};

      for (final size in ThumbnailSize.values) {
        sizeCounts[size.name] = 0;
      }

      await for (final entity in rootDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is Directory) {
          final dirName = entity.path.split(Platform.pathSeparator).last;
          if (dirName == thumbsDirName) {
            await for (final file in entity.list(recursive: true)) {
              if (file is File) {
                fileCount++;
                totalSize += await file.length();

                // 统计各尺寸数量
                for (final size in ThumbnailSize.values) {
                  if (file.path.contains(size.fileSuffix)) {
                    sizeCounts[size.name] = (sizeCounts[size.name] ?? 0) + 1;
                  }
                }
              }
            }
          }
        }
      }

      return {
        'fileCount': fileCount,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
        'sizeBreakdown': sizeCounts,
      };
    } catch (e, stack) {
      AppLogger.e('Failed to get cache size: $e', e, stack, 'ThumbnailCache');
      return {'fileCount': 0, 'totalSize': 0, 'totalSizeMB': 0.0};
    }
  }

  /// 检查缩略图是否存在（同步版本，仅用于快速检查）
  ///
  /// 警告：此方法是同步的，如果在主线程频繁调用可能阻塞 UI。
  /// 推荐使用 [thumbnailExistsAsync] 进行异步检查。
  bool thumbnailExists(
    String originalPath, {
    ThumbnailSize size = defaultSize,
  }) {
    final thumbnailPath = _getThumbnailPath(originalPath, size: size);
    return File(thumbnailPath).existsSync();
  }

  /// 异步检查缩略图是否存在
  ///
  /// 此方法是异步的，不会阻塞 UI 线程。
  Future<bool> thumbnailExistsAsync(
    String originalPath, {
    ThumbnailSize size = defaultSize,
  }) async {
    final thumbnailPath = _getThumbnailPath(originalPath, size: size);
    return await File(thumbnailPath).exists();
  }

  /// 执行 LRU 淘汰
  ///
  /// [rootPath] 画廊根目录路径
  /// [targetSizeMB] 目标缓存大小（MB），默认使用 _maxCacheSizeMB 的 80%
  /// [targetFileCount] 目标文件数，默认使用 _maxFileCount 的 80%
  /// 返回被淘汰的文件数量
  Future<int> evictLRU(
    String rootPath, {
    int? targetSizeMB,
    int? targetFileCount,
  }) async {
    try {
      final targetSize = (targetSizeMB ?? (_maxCacheSizeMB * 0.8)).toInt();
      final targetFiles = targetFileCount ?? (_maxFileCount * 0.8).toInt();

      // 获取所有缩略图文件信息
      final allThumbnails = await _getAllThumbnails(rootPath);

      if (allThumbnails.isEmpty) {
        return 0;
      }

      // 计算当前缓存状态
      int currentSizeMB = 0;
      for (final info in allThumbnails) {
        try {
          final file = File(info.path);
          if (await file.exists()) {
            currentSizeMB += await file.length();
          }
        } catch (_) {
          // 忽略无法访问的文件
        }
      }
      currentSizeMB = currentSizeMB ~/ (1024 * 1024);

      // 检查是否需要淘汰
      if (currentSizeMB <= targetSize && allThumbnails.length <= targetFiles) {
        AppLogger.d(
          'LRU eviction skipped: size=$currentSizeMB/${targetSize}MB, '
              'files=${allThumbnails.length}/$targetFiles',
          'ThumbnailCache',
        );
        return 0;
      }

      // 按优先级排序（可见性 > 最后访问时间）
      allThumbnails.sort((a, b) {
        // 首先比较可见性
        if (a.isVisible != b.isVisible) {
          return a.isVisible ? 1 : -1; // 不可见的先被淘汰
        }

        // 然后比较优先级
        if (a.visibilityPriority != b.visibilityPriority) {
          return a.visibilityPriority.compareTo(b.visibilityPriority);
        }

        // 最后比较访问时间
        final aTime = _lastAccessTimes[a.path] ?? a.createdAt;
        final bTime = _lastAccessTimes[b.path] ?? b.createdAt;
        return aTime.compareTo(bTime);
      });

      int evictedCount = 0;
      int evictedSizeMB = 0;

      // 淘汰直到满足限制
      for (final info in allThumbnails) {
        if (currentSizeMB - evictedSizeMB <= targetSize &&
            allThumbnails.length - evictedCount <= targetFiles) {
          break;
        }

        try {
          final file = File(info.path);
          if (await file.exists()) {
            final fileSize = await file.length();
            await file.delete();
            evictedSizeMB += fileSize ~/ (1024 * 1024);
            evictedCount++;
            _lastAccessTimes.remove(info.path);
            _visibilityInfo.remove(info.path);
          }
        } catch (e) {
          // AppLogger.w('Failed to evict thumbnail: ${info.path}', 'ThumbnailCache');
        }
      }

      _stats.recordEvicted(evictedCount);

      // AppLogger.i(
      //   'LRU eviction completed: $evictedCount files, ${evictedSizeMB}MB freed, '
      //   'remaining: ${allThumbnails.length - evictedCount} files, '
      //   '${currentSizeMB - evictedSizeMB}MB',
      //   'ThumbnailCache',
      // );

      return evictedCount;
    } catch (e, stack) {
      AppLogger.e('LRU eviction failed: $e', e, stack, 'ThumbnailCache');
      return 0;
    }
  }

  /// 获取所有缩略图信息
  Future<List<ThumbnailInfo>> _getAllThumbnails(String rootPath) async {
    final List<ThumbnailInfo> thumbnails = [];

    try {
      final rootDir = Directory(rootPath);
      if (!await rootDir.exists()) {
        return thumbnails;
      }

      await for (final entity in rootDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is Directory) {
          final dirName = entity.path.split(Platform.pathSeparator).last;
          if (dirName == thumbsDirName) {
            await for (final file in entity.list(recursive: true)) {
              if (file is File && file.path.endsWith(thumbnailExt)) {
                try {
                  final stat = await file.stat();

                  // 解析尺寸类型
                  ThumbnailSize size = ThumbnailSize.small;
                  for (final s in ThumbnailSize.values) {
                    if (file.path.contains(s.fileSuffix)) {
                      size = s;
                      break;
                    }
                  }

                  final visibility = _visibilityInfo[file.path];

                  thumbnails.add(
                    ThumbnailInfo(
                      path: file.path,
                      width: 0, // 磁盘缓存不保存具体尺寸
                      height: 0,
                      createdAt: stat.modified,
                      size: size,
                      lastAccessedAt:
                          _lastAccessTimes[file.path] ?? stat.accessed,
                      accessCount: 1,
                      isVisible: visibility?.isVisible ?? false,
                      visibilityPriority: visibility?.priority ?? 5,
                    ),
                  );
                } catch (_) {
                  // 忽略无法访问的文件
                }
              }
            }
          }
        }
      }
    } catch (e, stack) {
      AppLogger.e(
        'Failed to get all thumbnails: $e',
        e,
        stack,
        'ThumbnailCache',
      );
    }

    return thumbnails;
  }

  /// 获取缩略图文件路径
  String _getThumbnailPath(String originalPath, {required ThumbnailSize size}) {
    final dir = _getThumbnailDir(originalPath);
    final fileName = _getThumbnailFileName(originalPath, size: size);
    return '$dir${Platform.pathSeparator}$fileName';
  }

  /// 获取缩略图目录路径
  String _getThumbnailDir(String originalPath) {
    // 路径遍历防护：验证路径不包含上级目录引用
    final normalizedPath = _normalizePath(originalPath);

    if (originalPath.contains('..') ||
        originalPath.contains('%2e%2e') ||
        originalPath.contains('%2E%2E') ||
        normalizedPath.contains('..')) {
      throw ArgumentError(
        'Invalid path: path traversal detected in "$originalPath"',
      );
    }

    // 额外验证：如果设置了根目录，确保路径在任一图库源内
    if (_rootPaths.isNotEmpty &&
        !_rootPaths.any((root) => galleryPathIsWithin(root, originalPath))) {
      throw ArgumentError(
        'Invalid path: "$originalPath" is outside of configured gallery roots '
        '$_rootPaths',
      );
    }

    final originalDir = File(originalPath).parent.path;
    return '$originalDir${Platform.pathSeparator}$thumbsDirName';
  }

  /// 规范化路径，解码 URL 编码字符
  String _normalizePath(String path) {
    return path
        .replaceAll('%2e', '.')
        .replaceAll('%2E', '.')
        .replaceAll('%2f', '/')
        .replaceAll('%2F', '/')
        .replaceAll('%5c', '\\')
        .replaceAll('%5C', '\\');
  }

  /// 获取缩略图文件名
  String _getThumbnailFileName(
    String originalPath, {
    required ThumbnailSize size,
  }) {
    final originalFileName = extractOriginalFileNameForTest(originalPath);
    if (originalFileName.isEmpty) {
      throw ArgumentError('Invalid path: filename cannot be empty');
    }

    return _buildThumbnailFileName(originalFileName, size: size);
  }

  String _failureKey(String originalPath, {required ThumbnailSize size}) =>
      '$originalPath#${size.name}';

  bool _isInFailureCooldown(
    String originalPath, {
    required ThumbnailSize size,
  }) {
    final lastFailureAt =
        _recentFailureTimes[_failureKey(originalPath, size: size)];
    if (lastFailureAt == null) {
      return false;
    }

    if (DateTime.now().difference(lastFailureAt) >= _failureRetryCooldown) {
      _recentFailureTimes.remove(_failureKey(originalPath, size: size));
      return false;
    }

    return true;
  }

  static String _buildThumbnailFileName(
    String originalFileName, {
    required ThumbnailSize size,
  }) {
    if (originalFileName.isEmpty) {
      throw ArgumentError('Invalid path: originalFileName cannot be empty');
    }

    // 移除原始扩展名，添加尺寸标识和缩略图扩展名
    final dotIndex = originalFileName.lastIndexOf('.');
    final baseName = dotIndex > 0
        ? originalFileName.substring(0, dotIndex)
        : originalFileName;
    return '$baseName${size.fileSuffix}$thumbnailExt';
  }

  @visibleForTesting
  static String extractOriginalFileNameForTest(String originalPath) {
    final normalizedPath = originalPath.replaceAll('\\', '/');
    return p.posix.basename(normalizedPath);
  }

  @visibleForTesting
  static String buildThumbnailFileNameForTest(
    String originalPath, {
    required ThumbnailSize size,
  }) {
    final originalFileName = extractOriginalFileNameForTest(originalPath);
    return _buildThumbnailFileName(originalFileName, size: size);
  }
}

/// 缩略图生成任务
class _ThumbnailTask {
  final String originalPath;
  final Completer<String?> completer;
  final ThumbnailSize size;
  final int basePriority;

  _ThumbnailTask({
    required this.originalPath,
    required this.completer,
    required this.size,
    this.basePriority = 5,
  });

  /// 获取有效优先级（考虑可见性）
  int get effectivePriority {
    final service = ThumbnailCacheService.instance;
    final visibility = service._visibilityInfo[originalPath];
    if (visibility != null && visibility.isVisible) {
      return visibility.priority;
    }
    return basePriority;
  }
}

/// 可见性信息
class _VisibilityInfo {
  bool isVisible;
  int priority;

  _VisibilityInfo({required this.isVisible, required this.priority});
}

/// 缩略图统计
class _ThumbnailStats {
  int hitCount = 0;
  int missCount = 0;
  int generatedCount = 0;
  int failedCount = 0;
  int evictedCount = 0;

  void recordHit() => hitCount++;
  void recordMiss() => missCount++;
  void recordGenerated() => generatedCount++;
  void recordFailed() => failedCount++;
  void recordEvicted([int count = 1]) => evictedCount += count;

  void reset() {
    hitCount = 0;
    missCount = 0;
    generatedCount = 0;
    failedCount = 0;
    evictedCount = 0;
  }

  Map<String, dynamic> toMap() {
    final totalRequests = hitCount + missCount;
    final hitRate = totalRequests > 0 ? (hitCount / totalRequests * 100) : 0.0;

    return {
      'hitCount': hitCount,
      'missCount': missCount,
      'generatedCount': generatedCount,
      'failedCount': failedCount,
      'evictedCount': evictedCount,
      'hitRate': '${hitRate.toStringAsFixed(1)}%',
      'hitRateValue': hitRate,
    };
  }
}

Map<String, Object?> _generateThumbnailBytesInIsolate(
  Map<String, Object?> request,
) {
  final originalPath = request['originalPath'] as String;
  final maxFileSizeBytes = request['maxFileSizeBytes'] as int;
  final targetWidth = request['targetWidth'] as int;
  final targetHeight = request['targetHeight'] as int;
  final jpegQuality = request['jpegQuality'] as int;

  final file = File(originalPath);
  final fileSize = file.lengthSync();
  if (fileSize > maxFileSizeBytes) {
    throw Exception(
      'File too large: ${fileSize ~/ (1024 * 1024)}MB exceeds limit of '
      '${maxFileSizeBytes ~/ (1024 * 1024)}MB',
    );
  }

  final originalImage = img.decodeImage(file.readAsBytesSync());
  if (originalImage == null) {
    throw Exception('Failed to decode image: $originalPath');
  }

  final aspectRatio = originalImage.height > 0
      ? originalImage.width / originalImage.height
      : 1.0;
  var thumbWidth = targetWidth;
  var thumbHeight = targetHeight;

  final targetAspectRatio = targetHeight > 0 ? targetWidth / targetHeight : 1.0;
  if (aspectRatio > targetAspectRatio) {
    thumbHeight = aspectRatio > 0
        ? (targetWidth / aspectRatio).round()
        : targetHeight;
  } else {
    thumbWidth = (targetHeight * aspectRatio).round();
  }

  final thumbnail = img.copyResize(
    originalImage,
    width: thumbWidth,
    height: thumbHeight,
    interpolation: img.Interpolation.linear,
  );

  return {
    'bytes': Uint8List.fromList(img.encodeJpg(thumbnail, quality: jpegQuality)),
    'originalWidth': originalImage.width,
    'originalHeight': originalImage.height,
    'thumbnailWidth': thumbnail.width,
    'thumbnailHeight': thumbnail.height,
  };
}

/// ThumbnailCacheService Provider
///
/// 返回单例实例，确保全局状态一致性
@riverpod
ThumbnailCacheService thumbnailCacheService(Ref ref) {
  return ThumbnailCacheService.instance;
}
