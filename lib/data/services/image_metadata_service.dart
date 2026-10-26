import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import '../../core/utils/app_logger.dart';
import '../../core/utils/gallery_path_utils.dart';
import '../models/gallery/nai_image_metadata.dart';
import 'metadata/cache_manager.dart';
import 'metadata/hash_calculator.dart';
import 'metadata/isolate_metadata_service.dart';
import 'metadata/preloader.dart';
import 'metadata/unified_metadata_parser.dart';

/// 解析任务取消 Token
class ParseCancelToken {
  bool _isCancelled = false;
  final _completer = Completer<void>();

  bool get isCancelled => _isCancelled;
  Future<void> get onCancelled => _completer.future;

  void cancel() {
    if (!_isCancelled) {
      _isCancelled = true;
      _completer.complete();
    }
  }
}

/// 解析任务信息
class _ParseTaskInfo {
  final String key;
  final Completer<NaiImageMetadata?> completer;

  _ParseTaskInfo({required this.key, required this.completer});
}

/// 解析统计信息
class ParseStatistics {
  int totalParseCount = 0;
  int successfulParseCount = 0;
  int failedParseCount = 0;
  int cancelledParseCount = 0;
  int timeoutParseCount = 0;
  int cacheHitCount = 0;
  final Map<String, int> errorTypeCounts = {};
  Duration totalParseTime = Duration.zero;

  double get averageParseTimeMs =>
      totalParseCount > 0 ? totalParseTime.inMilliseconds / totalParseCount : 0;

  double get successRate =>
      totalParseCount > 0 ? successfulParseCount / totalParseCount : 0;

  Map<String, dynamic> toMap() => {
    'totalParseCount': totalParseCount,
    'successfulParseCount': successfulParseCount,
    'failedParseCount': failedParseCount,
    'cancelledParseCount': cancelledParseCount,
    'timeoutParseCount': timeoutParseCount,
    'cacheHitCount': cacheHitCount,
    'averageParseTimeMs': averageParseTimeMs.toStringAsFixed(2),
    'successRate': '${(successRate * 100).toStringAsFixed(1)}%',
    'errorTypeCounts': errorTypeCounts,
  };

  void recordSuccess(Duration duration) {
    totalParseCount++;
    successfulParseCount++;
    totalParseTime += duration;
  }

  void recordFailure(String errorType, Duration duration) {
    totalParseCount++;
    failedParseCount++;
    totalParseTime += duration;
    errorTypeCounts[errorType] = (errorTypeCounts[errorType] ?? 0) + 1;
  }

  void recordCancelled() {
    totalParseCount++;
    cancelledParseCount++;
  }

  void recordTimeout() {
    totalParseCount++;
    timeoutParseCount++;
  }

  void recordCacheHit() {
    cacheHitCount++;
  }

  void reset() {
    totalParseCount = 0;
    successfulParseCount = 0;
    failedParseCount = 0;
    cancelledParseCount = 0;
    timeoutParseCount = 0;
    cacheHitCount = 0;
    errorTypeCounts.clear();
    totalParseTime = Duration.zero;
  }
}

/// 图像元数据服务
///
/// 统一的元数据解析服务入口，使用文件内容哈希作为缓存键，支持重命名免疫。
///
/// 架构分层：
/// - ImageMetadataService: 主服务，协调各组件
/// - MetadataCacheManager: L1/L2 缓存管理
/// - FileHashCalculator: 文件哈希计算
/// - MetadataPreloader: 后台预加载队列
/// - UnifiedMetadataParser: 统一元数据解析器
///
/// 新特性：
/// - 单文件解析超时控制（默认 5 秒）
/// - 解析任务取消支持
/// - 详细的解析统计
/// - 增强的错误处理
class ImageMetadataService {
  static final ImageMetadataService _instance =
      ImageMetadataService._internal();
  factory ImageMetadataService() => _instance;
  ImageMetadataService._internal();

  // 子组件
  final _cacheManager = MetadataCacheManager();
  final _hashCalculator = FileHashCalculator();
  final _preloader = MetadataPreloader();

  // 并发控制
  final _fileSemaphore = _Semaphore(3);
  final _highPrioritySemaphore = _Semaphore(2);

  // 任务管理
  final _pendingTasks = <String, _ParseTaskInfo>{};
  final _activeTimeouts = <String, Timer>{};

  // 统计
  final _statistics = ParseStatistics();

  // 配置
  static const Duration _defaultParseTimeout = Duration(seconds: 5);
  static const Duration _highPriorityTimeout = Duration(seconds: 3);

  /// 初始化服务
  Future<void> initialize() async {
    await _cacheManager.initialize();
  }

  /// 前台立即获取元数据（高优先级）
  ///
  /// [path] 文件路径
  /// [cancelToken] 可选的取消令牌
  Future<NaiImageMetadata?> getMetadataImmediate(
    String path, {
    ParseCancelToken? cancelToken,
  }) => _getFileMetadata(
    path,
    cancelToken: cancelToken,
    timeout: _highPriorityTimeout,
    semaphore: _highPrioritySemaphore,
  );

  /// 扫描读取：与前台共用内容哈希缓存和常驻 worker 的单次文件读取。
  /// 有效图片无参数时返回空对象；读取失败抛出文件异常，超时／取消返回 null。
  Future<NaiImageMetadata?> getMetadataForScan(String path) =>
      _readFileMetadata(path);

  Future<NaiImageMetadata?> _readFileMetadata(
    String path, {
    Duration timeout = const Duration(seconds: 10),
    bool Function()? isCurrent,
  }) async {
    bool active() => isCurrent?.call() ?? true;
    if (!active()) return null;
    final stopwatch = Stopwatch()..start();

    // 快速路径：路径哈希已知且缓存命中时不进 isolate、不做任何文件读取
    final knownHash = _hashCalculator.lookupCachedHash(path);
    if (knownHash != null) {
      final memoryCached = _cacheManager.getFromMemory(knownHash);
      if (memoryCached != null) {
        stopwatch.stop();
        _statistics.recordCacheHit();
        return memoryCached;
      }

      final persistentCached = _cacheManager.getFromPersistent(knownHash);
      if (persistentCached != null) {
        stopwatch.stop();
        _statistics.recordCacheHit();
        return persistentCached;
      }
    }

    // 慢路径：worker 单次读取文件 → SHA256 +（按缓存决策）解析
    NaiImageMetadata? cachedCandidate;
    final result = await IsolateMetadataService.instance.parseMetadataWithHash(
      path,
      config: IsolateParseConfig(
        timeout: timeout,
        useGradualRead: true,
        useCache: false,
      ),
      shouldParseWithHash: (hash) {
        if (!active()) return false;
        // 已知哈希的缓存未命中在快速路径已查过同一份缓存，无需重复计数
        if (hash == knownHash) return true;

        final memoryCached = _cacheManager.getFromMemory(hash);
        if (memoryCached != null) {
          cachedCandidate = memoryCached;
          return false;
        }

        final persistentCached = _cacheManager.getFromPersistent(hash);
        if (persistentCached != null) {
          cachedCandidate = persistentCached;
          return false;
        }
        return true;
      },
    );

    if (!active()) return null;
    final hash = result.fileHash;
    if (hash == null) {
      stopwatch.stop();
      _statistics.recordFailure(
        result.error ?? 'file_read_failed',
        stopwatch.elapsed,
      );
      if (result.wasTimeout || result.wasCancelled) return null;
      throw FileSystemException(
        result.error ?? 'Failed to read image metadata',
        path,
      );
    }

    // 哈希回填路径映射，语义等同旧实现 calculate() 的缓存写入
    _hashCalculator.registerComputedHash(path, hash);

    if (result.wasSkipped) {
      // 仅当前任务的缓存命中会跳过 worker 解析。
      stopwatch.stop();
      _statistics.recordCacheHit();
      return cachedCandidate!;
    }

    stopwatch.stop();

    final metadata = result.success ? result.metadata : null;
    if (metadata != null && metadata.hasData) {
      await _cacheManager.save(hash, metadata);
      if (!active()) return null;
      _statistics.recordSuccess(stopwatch.elapsed);
    } else {
      _statistics.recordFailure(
        result.error ?? 'no_metadata',
        stopwatch.elapsed,
      );
    }

    if (stopwatch.elapsedMilliseconds > 100) {
      AppLogger.w(
        '[PERF] Slow getMetadataForScan: ${stopwatch.elapsedMilliseconds}ms for $path',
        'ImageMetadataService',
      );
    }

    return metadata;
  }

  /// 从文件路径获取元数据（标准入口）
  ///
  /// [path] 文件路径
  /// [cancelToken] 可选的取消令牌
  /// [timeout] 解析超时时间（默认 5 秒）
  Future<NaiImageMetadata?> getMetadata(
    String path, {
    ParseCancelToken? cancelToken,
    Duration? timeout,
  }) => _getFileMetadata(
    path,
    cancelToken: cancelToken,
    timeout: timeout ?? _defaultParseTimeout,
    semaphore: _fileSemaphore,
  );

  Future<NaiImageMetadata?> _getFileMetadata(
    String path, {
    required Duration timeout,
    required _Semaphore semaphore,
    ParseCancelToken? cancelToken,
  }) {
    if (cancelToken?.isCancelled ?? false) {
      _statistics.recordCancelled();
      return Future.value(null);
    }
    final key = 'file:${galleryFilePathKey(path)}';
    final existing = _pendingTasks[key];
    if (existing != null) return existing.completer.future;
    final task = _ParseTaskInfo(
      key: key,
      completer: Completer<NaiImageMetadata?>(),
    );
    _pendingTasks[key] = task;
    bool active() =>
        identical(_pendingTasks[key], task) && !task.completer.isCompleted;
    _activeTimeouts[key] = Timer(timeout, () {
      if (!active()) return;
      _statistics.recordTimeout();
      task.completer.complete(null);
      _cleanupTask(task);
    });
    if (cancelToken != null) {
      unawaited(
        cancelToken.onCancelled.then((_) {
          if (active()) _cancelTask(key);
        }),
      );
    }
    // 首调用也只观察 task.completer；排队、读取与解析共享同一个期限。
    unawaited(() async {
      await semaphore.acquire();
      try {
        if (!active()) return;
        final result = await _readFileMetadata(
          path,
          timeout: timeout,
          isCurrent: active,
        );
        if (active()) task.completer.complete(result);
      } catch (e, stack) {
        if (active()) {
          AppLogger.e(
            'Failed to read image metadata: $path',
            e,
            stack,
            'ImageMetadataService',
          );
          task.completer.complete(null);
        }
      } finally {
        _cleanupTask(task);
        semaphore.release();
      }
    }());
    return task.completer.future;
  }

  /// 从字节数组获取元数据
  Future<NaiImageMetadata?> getMetadataFromBytes(Uint8List bytes) async {
    final hash = _hashCalculator.calculateFromBytes(bytes);

    // 检查 L1 内存缓存
    final memoryCached = _cacheManager.getFromMemory(hash);
    if (memoryCached != null) return memoryCached;

    // 检查 L2 持久化缓存
    final persistentCached = _cacheManager.getFromPersistent(hash);
    if (persistentCached != null) {
      return persistentCached;
    }

    // 检查是否有正在进行的解析
    final existingTask = _pendingTasks[hash];
    if (existingTask != null) {
      return existingTask.completer.future;
    }

    // 创建任务
    final taskCompleter = Completer<NaiImageMetadata?>();
    final taskInfo = _ParseTaskInfo(key: hash, completer: taskCompleter);
    _pendingTasks[hash] = taskInfo;

    try {
      final result = await _parseBytesAndCache(bytes, hash: hash);

      if (!taskCompleter.isCompleted) {
        taskCompleter.complete(result);
      }

      return result;
    } catch (e, stack) {
      AppLogger.e('Parse bytes failed', e, stack, 'ImageMetadataService');
      if (!taskCompleter.isCompleted) {
        taskCompleter.complete(null);
      }
      return null;
    } finally {
      _cleanupTask(taskInfo);
    }
  }

  /// 手动缓存元数据
  Future<void> cacheMetadata(String path, NaiImageMetadata metadata) async {
    if (!metadata.hasData) return;
    final hash = await _hashCalculator.calculate(path);
    await _cacheManager.save(hash, metadata);
  }

  /// 将图像加入预加载队列
  void enqueuePreload({
    required String taskId,
    String? filePath,
    Uint8List? bytes,
  }) {
    _preloader.enqueue(taskId: taskId, filePath: filePath, bytes: bytes);
  }

  /// 批量添加预加载任务
  void enqueuePreloadBatch(List<GeneratedImageInfo> images) {
    for (final image in images) {
      enqueuePreload(
        taskId: image.id,
        filePath: image.filePath,
        bytes: image.bytes,
      );
    }
  }

  /// 从缓存获取元数据（同步检查）
  NaiImageMetadata? getCached(String path) {
    // AppLogger.d('[MetadataFlow] getCached called: path=$path', 'ImageMetadataService');

    final hash = _hashCalculator.getHashForPath(path);
    if (hash == null) return null;

    // 检查 L1 内存缓存
    final memoryCached = _cacheManager.getFromMemory(hash);
    if (memoryCached != null) {
      return memoryCached;
    }

    // 检查 L2 持久化缓存
    final persistentCached = _cacheManager.getFromPersistent(hash);
    if (persistentCached != null) {
      return persistentCached;
    }
    return null;
  }

  /// 取消指定路径的解析任务
  void cancelParse(String path) {
    _cancelTask('file:${galleryFilePathKey(path)}');
  }

  /// 取消所有进行中的解析任务
  void cancelAllParses() {
    final hashes = List<String>.from(_pendingTasks.keys);
    for (final hash in hashes) {
      _cancelTask(hash);
    }
  }

  /// 清除所有缓存
  Future<void> clearCache() async {
    await _cacheManager.clear();
    _hashCalculator.clearCache();
    // AppLogger.i('All caches cleared', 'ImageMetadataService');
  }

  /// 清除持久化缓存
  Future<void> clearPersistentCache() async {
    await _cacheManager.clearPersistent();
  }

  /// 通知路径变更（文件重命名检测）
  void notifyPathChanged(String oldPath, String newPath) {
    _hashCalculator.notifyPathChanged(oldPath, newPath);
  }

  /// 预加载（简写）
  void preload(String path) => enqueuePreload(taskId: path, filePath: path);

  /// 批量预加载
  void preloadBatch(List<GeneratedImageInfo> images) =>
      enqueuePreloadBatch(images);

  // ==================== 统计信息 ====================

  /// L1 内存缓存大小
  int get memoryCacheSize => _cacheManager.memorySize;

  /// L1 内存缓存命中率
  double get memoryCacheHitRate => _cacheManager.memoryHitRate;

  /// L2 持久化缓存大小
  Future<int> get persistentCacheSize async => _cacheManager.persistentSize;

  /// L2 持久化缓存命中率
  double get persistentCacheHitRate => _cacheManager.persistentHitRate;

  /// Hive 缓存 Box（用于 L2CacheCleaner 访问）
  Box<String>? get persistentBox => _cacheManager.box;

  /// 获取哈希对应的所有路径
  List<String> getPathsForHash(String hash) =>
      _hashCalculator.getPathsForHash(hash);

  /// 获取解析统计
  ParseStatistics get parseStatistics => _statistics;

  /// 重置统计
  void resetStatistics() {
    _cacheManager.resetStatistics();
    _hashCalculator.resetStatistics();
    _preloader.resetStatistics();
    _statistics.reset();
    // AppLogger.i('ImageMetadataService statistics reset', 'ImageMetadataService');
  }

  /// 获取完整统计
  Map<String, dynamic> getStats() => {
    ..._cacheManager.getStatistics(),
    ..._hashCalculator.getStatistics(),
    ..._preloader.getStatistics(),
    ..._statistics.toMap(),
    'pendingTasks': _pendingTasks.length,
    'activeTimeouts': _activeTimeouts.length,
  };

  /// 获取预加载队列状态
  Map<String, dynamic> getPreloadQueueStatus() => _preloader.getStatistics();

  // ==================== 私有方法 ====================

  void _cleanupTask(_ParseTaskInfo task) {
    if (!identical(_pendingTasks[task.key], task)) return;
    _pendingTasks.remove(task.key);
    _activeTimeouts.remove(task.key)?.cancel();
  }

  void _cancelTask(String key) {
    final task = _pendingTasks[key];
    if (task != null && !task.completer.isCompleted) {
      _statistics.recordCancelled();
      task.completer.complete(null);
      _cleanupTask(task);
    }
  }

  Future<NaiImageMetadata?> _parseBytesAndCache(
    Uint8List bytes, {
    required String hash,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (bytes.length < 8) {
        _statistics.recordFailure('bytes_too_small', stopwatch.elapsed);
        return null;
      }

      final result = UnifiedMetadataParser.parseFromImageBytes(bytes);
      final metadata = result.success ? result.metadata : null;

      if (metadata != null && metadata.hasData) {
        await _cacheManager.save(hash, metadata);
        _statistics.recordSuccess(stopwatch.elapsed);
      } else {
        _statistics.recordFailure(
          result.errorMessage ?? 'unknown',
          stopwatch.elapsed,
        );
      }

      return metadata;
    } catch (e, stack) {
      _statistics.recordFailure(
        'exception: ${e.runtimeType}',
        stopwatch.elapsed,
      );
      AppLogger.e('Parse bytes failed', e, stack, 'ImageMetadataService');
      return null;
    }
  }
}

/// 生成图像信息
class GeneratedImageInfo {
  final String id;
  final String? filePath;
  final Uint8List? bytes;

  GeneratedImageInfo({required this.id, this.filePath, this.bytes});
}

class _Semaphore {
  final int maxCount;
  int _currentCount = 0;
  final _waitQueue = <Completer<void>>[];

  _Semaphore(this.maxCount);

  Future<void> acquire() async {
    if (_currentCount < maxCount) {
      _currentCount++;
      return;
    }
    final completer = Completer<void>();
    _waitQueue.add(completer);
    await completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      _waitQueue.removeAt(0).complete();
    } else {
      _currentCount--;
    }
  }
}
