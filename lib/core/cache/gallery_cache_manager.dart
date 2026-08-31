import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;

import '../../core/constants/storage_keys.dart';
import '../../core/utils/app_logger.dart';
import '../../data/services/image_metadata_service.dart';
import '../database/datasources/gallery_data_source.dart';

/// 缓存层级类型
enum CacheLayer {
  /// L1 内存缓存
  memory,

  /// L2 Hive 持久化缓存
  hive,

  /// L3 SQLite 数据库缓存
  database,
}

/// 缓存统计信息
class CacheStatistics {
  /// L1 内存缓存大小（条目数）
  final int l1MemorySize;

  /// L1 内存缓存命中率（0.0 - 1.0）
  final double l1HitRate;

  /// L1 内存缓存占用（估算字节数）
  final int l1MemoryBytes;

  /// L2 Hive 缓存大小（条目数）
  final int l2HiveSize;

  /// L2 Hive 缓存命中率（0.0 - 1.0）
  final double l2HitRate;

  /// L2 Hive 缓存占用（字节数）
  final int l2HiveBytes;

  /// L3 数据库图片记录数
  final int l3DatabaseImageCount;

  /// L3 数据库元数据记录数
  final int l3DatabaseMetadataCount;

  /// 总缓存命中率（加权平均）
  final double totalHitRate;

  /// 最后更新时间
  final DateTime lastUpdated;

  const CacheStatistics({
    required this.l1MemorySize,
    required this.l1HitRate,
    required this.l1MemoryBytes,
    required this.l2HiveSize,
    required this.l2HitRate,
    required this.l2HiveBytes,
    required this.l3DatabaseImageCount,
    required this.l3DatabaseMetadataCount,
    required this.totalHitRate,
    required this.lastUpdated,
  });

  /// 获取指定层级的缓存大小（字节数）
  int getLayerBytes(CacheLayer layer) {
    return switch (layer) {
      CacheLayer.memory => l1MemoryBytes,
      CacheLayer.hive => l2HiveBytes,
      CacheLayer.database => 0, // 数据库大小需要单独计算
    };
  }

  /// 获取指定层级的缓存命中率
  double getLayerHitRate(CacheLayer layer) {
    return switch (layer) {
      CacheLayer.memory => l1HitRate,
      CacheLayer.hive => l2HitRate,
      CacheLayer.database => 0.0, // 数据库不计算命中率
    };
  }

  /// 获取总缓存条目数（估算）
  int get totalEntryCount => l1MemorySize + l2HiveSize + l3DatabaseImageCount;

  /// 获取总缓存大小（字节数）
  int get totalBytes => l1MemoryBytes + l2HiveBytes;

  @override
  String toString() =>
      'CacheStatistics(L1: $l1MemorySize entries, ${(l1HitRate * 100).toStringAsFixed(1)}% hit, ${_formatBytes(l1MemoryBytes)}, '
      'L2: $l2HiveSize entries, ${(l2HitRate * 100).toStringAsFixed(1)}% hit, ${_formatBytes(l2HiveBytes)}, '
      'DB: $l3DatabaseImageCount images, $l3DatabaseMetadataCount metadata, '
      'Total: ${(totalHitRate * 100).toStringAsFixed(1)}% hit, ${_formatBytes(totalBytes)})';

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
    'l1MemorySize': l1MemorySize,
    'l1HitRate': l1HitRate,
    'l1MemoryBytes': l1MemoryBytes,
    'l2HiveSize': l2HiveSize,
    'l2HitRate': l2HitRate,
    'l2HiveBytes': l2HiveBytes,
    'l3DatabaseImageCount': l3DatabaseImageCount,
    'l3DatabaseMetadataCount': l3DatabaseMetadataCount,
    'totalHitRate': totalHitRate,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  /// 从 JSON 创建
  factory CacheStatistics.fromJson(Map<String, dynamic> json) {
    return CacheStatistics(
      l1MemorySize: json['l1MemorySize'] as int? ?? 0,
      l1HitRate: json['l1HitRate'] as double? ?? 0.0,
      l1MemoryBytes: json['l1MemoryBytes'] as int? ?? 0,
      l2HiveSize: json['l2HiveSize'] as int? ?? 0,
      l2HitRate: json['l2HitRate'] as double? ?? 0.0,
      l2HiveBytes: json['l2HiveBytes'] as int? ?? 0,
      l3DatabaseImageCount: json['l3DatabaseImageCount'] as int? ?? 0,
      l3DatabaseMetadataCount: json['l3DatabaseMetadataCount'] as int? ?? 0,
      totalHitRate: json['totalHitRate'] as double? ?? 0.0,
      lastUpdated:
          DateTime.tryParse(json['lastUpdated'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// 缓存清理策略
enum CacheCleanupStrategy {
  /// 清理所有层级
  all,

  /// 仅清理内存缓存
  memoryOnly,

  /// 仅清理 Hive 缓存
  hiveOnly,

  /// 仅清理数据库缓存（谨慎使用）
  databaseOnly,

  /// 自动清理（根据大小阈值）
  auto,
}

/// 画廊缓存管理器
///
/// 提供统一接口管理三层缓存：
/// - L1: 内存缓存 (ImageMetadataService._memoryCache)
/// - L2: Hive 缓存 (ImageMetadataService._persistentBox)
/// - L3: SQLite 数据库 (GalleryDataSource)
///
/// 特性：
/// - 精确的缓存统计（包含字节数估算）
/// - 自动缓存清理（基于大小和时间）
/// - 缓存序列化/压缩
/// - 分层清理策略
class GalleryCacheManager {
  static final GalleryCacheManager _instance = GalleryCacheManager._internal();
  factory GalleryCacheManager() => _instance;
  GalleryCacheManager._internal();

  final List<VoidCallback> _onClearedCallbacks = [];

  /// 统计信息刷新回调列表
  final List<VoidCallback> _onStatisticsInvalidatedCallbacks = [];

  /// 缓存统计信息缓存
  CacheStatistics? _cachedStatistics;

  /// 统计信息缓存时间
  DateTime? _statisticsCacheTime;

  /// 统计信息缓存有效期
  static const Duration _statisticsCacheValidity = Duration(seconds: 30);

  /// 自动清理大小阈值（MB）
  static const int _autoCleanupThresholdMB = 500;

  /// 注册缓存清除回调
  void registerOnCacheCleared(VoidCallback callback) {
    _onClearedCallbacks.add(callback);
  }

  /// 注销缓存清除回调
  void unregisterOnCacheCleared(VoidCallback callback) {
    _onClearedCallbacks.remove(callback);
  }

  /// 注册统计信息刷新回调
  ///
  /// 当统计信息缓存失效时，会通知所有注册的监听者（如设置页面的统计组件）。
  /// 注意：此回调与缓存清除回调是分开的，不会触发状态重置。
  void registerOnStatisticsInvalidated(VoidCallback callback) {
    _onStatisticsInvalidatedCallbacks.add(callback);
  }

  /// 注销统计信息刷新回调
  void unregisterOnStatisticsInvalidated(VoidCallback callback) {
    _onStatisticsInvalidatedCallbacks.remove(callback);
  }

  /// 通知统计信息已失效
  void _notifyStatisticsInvalidated() {
    for (final callback in _onStatisticsInvalidatedCallbacks.toList()) {
      try {
        callback();
      } catch (e) {
        AppLogger.w(
          'Statistics invalidation callback failed: $e',
          'GalleryCacheManager',
        );
      }
    }
  }

  void _notifyCacheCleared() {
    // 创建列表副本以避免并发修改错误
    for (final callback in _onClearedCallbacks.toList()) {
      try {
        callback();
      } catch (e) {
        AppLogger.w('Cache clear callback failed: $e', 'GalleryCacheManager');
      }
    }
  }

  /// 清除所有层级缓存
  Future<void> clearAll() async {
    await clearL1MemoryCache();
    await clearL2HiveCache();
    await clearL3DatabaseCache();
    _notifyCacheCleared();
    _invalidateStatisticsCache();
    AppLogger.i('All cache layers cleared', 'GalleryCacheManager');
  }

  /// 根据策略清理缓存
  Future<void> clearByStrategy(CacheCleanupStrategy strategy) async {
    switch (strategy) {
      case CacheCleanupStrategy.all:
        await clearAll();
      case CacheCleanupStrategy.memoryOnly:
        await clearL1MemoryCache();
      case CacheCleanupStrategy.hiveOnly:
        await clearL2HiveCache();
      case CacheCleanupStrategy.databaseOnly:
        await clearL3DatabaseCache();
      case CacheCleanupStrategy.auto:
        await _autoCleanup();
    }
    _invalidateStatisticsCache();
  }

  /// 自动清理缓存
  Future<void> _autoCleanup() async {
    final stats = await getStatistics();

    // 如果 L2 Hive 缓存超过阈值，触发清理
    if (stats.l2HiveBytes > _autoCleanupThresholdMB * 1024 * 1024) {
      AppLogger.i(
        'Auto cleanup triggered: L2 cache ${(stats.l2HiveBytes / 1024 / 1024).toStringAsFixed(1)}MB exceeds threshold ${_autoCleanupThresholdMB}MB',
        'GalleryCacheManager',
      );
      await L2CacheCleaner().performCleanup();
    }

    // 如果 L1 内存缓存过大，清理内存
    if (stats.l1MemoryBytes > 100 * 1024 * 1024) {
      // 100MB
      AppLogger.i(
        'Auto cleanup triggered: L1 cache ${(stats.l1MemoryBytes / 1024 / 1024).toStringAsFixed(1)}MB exceeds threshold 100MB',
        'GalleryCacheManager',
      );
      await clearL1MemoryCache();
    }
  }

  /// 清除 L1 内存缓存
  Future<void> clearL1MemoryCache() async {
    await ImageMetadataService().clearCache();
    GalleryDataSource().clearCache();
    _invalidateStatisticsCache();
    AppLogger.i('L1 memory cache cleared', 'GalleryCacheManager');
  }

  /// 清除 L2 Hive 缓存
  Future<void> clearL2HiveCache() async {
    await ImageMetadataService().clearPersistentCache();
    _invalidateStatisticsCache();
    AppLogger.i('L2 Hive cache cleared', 'GalleryCacheManager');
  }

  /// 清除 L3 数据库（谨慎使用）
  Future<void> clearL3DatabaseCache() async {
    final dataSource = GalleryDataSource();
    await dataSource.deleteAllImages();
    await dataSource.deleteAllMetadata();
    _invalidateStatisticsCache();
    AppLogger.i('L3 database cache cleared', 'GalleryCacheManager');
  }

  /// 使统计信息缓存失效（私有）
  void _invalidateStatisticsCache() {
    _cachedStatistics = null;
    _statisticsCacheTime = null;
  }

  /// 使统计信息缓存失效（公共接口）
  ///
  /// 当外部操作（如扫描新文件）修改了数据库后，调用此方法使统计缓存失效，
  /// 下次获取统计时将重新计算。
  /// 同时通知统计信息监听者（如设置页面的统计组件）立即刷新。
  ///
  /// 注意：此方法不会触发缓存清除回调，仅用于刷新统计信息显示。
  void invalidateStatistics() {
    _invalidateStatisticsCache();
    _notifyStatisticsInvalidated(); // 通知设置页面的统计组件刷新
    AppLogger.d(
      'Cache statistics invalidated and notified',
      'GalleryCacheManager',
    );
  }

  /// 获取缓存统计（带缓存）
  Future<CacheStatistics> getStatistics() async {
    // 检查缓存是否有效
    if (_cachedStatistics != null &&
        _statisticsCacheTime != null &&
        DateTime.now().difference(_statisticsCacheTime!) <
            _statisticsCacheValidity) {
      return _cachedStatistics!;
    }

    // 重新计算统计信息
    final stats = await _computeStatistics();
    _cachedStatistics = stats;
    _statisticsCacheTime = DateTime.now();
    return stats;
  }

  /// 计算缓存统计
  Future<CacheStatistics> _computeStatistics() async {
    final imageService = ImageMetadataService();
    final dataSource = GalleryDataSource();

    // 获取 L1 缓存统计
    final l1Size = imageService.memoryCacheSize;
    final l1HitRate = imageService.memoryCacheHitRate;
    final l1Bytes = await _estimateMemoryCacheBytes();

    // 获取 L2 缓存统计
    final l2Size = await imageService.persistentCacheSize;
    final l2HitRate = imageService.persistentCacheHitRate;
    final l2Bytes = await _getHiveCacheBytes();

    // 获取 L3 数据库统计
    final imageCount = await dataSource.countImages();
    final metadataCount = await _getMetadataCount(dataSource);

    // 计算总命中率（加权平均）
    final totalRequests =
        (l1HitRate > 0 ? l1Size / l1HitRate : 0) +
        (l2HitRate > 0 ? l2Size / l2HitRate : 0);
    final totalHits = l1Size + l2Size;
    final totalHitRate = totalRequests > 0 ? totalHits / totalRequests : 0.0;

    return CacheStatistics(
      l1MemorySize: l1Size,
      l1HitRate: l1HitRate,
      l1MemoryBytes: l1Bytes,
      l2HiveSize: l2Size,
      l2HitRate: l2HitRate,
      l2HiveBytes: l2Bytes,
      l3DatabaseImageCount: imageCount,
      l3DatabaseMetadataCount: metadataCount,
      totalHitRate: totalHitRate.isFinite ? totalHitRate : 0.0,
      lastUpdated: DateTime.now(),
    );
  }

  /// 估算内存缓存字节数
  Future<int> _estimateMemoryCacheBytes() async {
    try {
      // 获取 Hive 缓存目录大小作为估算参考
      final appDir = await _getAppDirectory();
      if (appDir == null) return 0;

      final metadataCacheDir = Directory(p.join(appDir, 'metadata_cache'));
      if (!await metadataCacheDir.exists()) return 0;

      int totalBytes = 0;
      await for (final entity in metadataCacheDir.list()) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
      return totalBytes ~/ 10; // 内存缓存约为磁盘缓存的 1/10
    } catch (e) {
      return 0;
    }
  }

  /// 获取 Hive 缓存字节数
  Future<int> _getHiveCacheBytes() async {
    try {
      final appDir = await _getAppDirectory();
      if (appDir == null) return 0;

      final metadataCacheDir = Directory(p.join(appDir, 'metadata_cache'));
      if (!await metadataCacheDir.exists()) return 0;

      int totalBytes = 0;
      await for (final entity in metadataCacheDir.list()) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
      return totalBytes;
    } catch (e) {
      return 0;
    }
  }

  /// 获取应用目录
  Future<String?> _getAppDirectory() async {
    try {
      // 尝试从 Hive 路径推断
      final box = Hive.box(StorageKeys.settingsBox);
      final path = box.path;
      if (path != null) {
        return p.dirname(path);
      }
    } catch (_) {
      // 忽略错误
    }
    return null;
  }

  Future<int> _getMetadataCount(GalleryDataSource dataSource) async {
    try {
      final health = await dataSource.checkHealth();
      return health.details['metadataCount'] as int? ?? 0;
    } catch (e) {
      AppLogger.w('Failed to get metadata count: $e', 'GalleryCacheManager');
      return 0;
    }
  }

  /// 重置所有缓存统计计数器
  Future<void> resetStatistics() async {
    ImageMetadataService().resetStatistics();
    _invalidateStatisticsCache();
    AppLogger.i('Cache statistics reset', 'GalleryCacheManager');
  }

  /// 导出缓存统计到 JSON
  Future<String> exportStatisticsToJson() async {
    final stats = await getStatistics();
    return jsonEncode(stats.toJson());
  }

  /// 从 JSON 导入缓存统计
  Future<CacheStatistics?> importStatisticsFromJson(String json) async {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return CacheStatistics.fromJson(map);
    } catch (e) {
      AppLogger.w('Failed to import statistics: $e', 'GalleryCacheManager');
      return null;
    }
  }

  /// 压缩缓存数据
  ///
  /// 将 Hive 缓存压缩以节省磁盘空间
  Future<bool> compressCache() async {
    try {
      final box = ImageMetadataService().persistentBox;
      if (box == null || !box.isOpen) {
        AppLogger.w(
          'Persistent box not available for compression',
          'GalleryCacheManager',
        );
        return false;
      }

      AppLogger.i('Starting cache compression...', 'GalleryCacheManager');

      int compressedCount = 0;
      final keysToRemove = <String>[];

      for (final key in box.keys) {
        if (key is! String) continue;
        if (key.startsWith('_')) continue;

        final value = box.get(key);
        if (value == null) continue;

        // 检查是否有重复或过期数据
        final paths = ImageMetadataService().getPathsForHash(key);
        bool hasValidPaths = false;
        for (final path in paths) {
          if (await File(path).exists()) {
            hasValidPaths = true;
            break;
          }
        }

        if (!hasValidPaths) {
          keysToRemove.add(key);
        }
      }

      // 批量删除无效条目
      for (final key in keysToRemove) {
        await box.delete(key);
        compressedCount++;
      }

      // 尝试压缩 Hive 文件
      try {
        await box.compact();
      } catch (_) {
        // 压缩可能被某些平台不支持，忽略错误
      }

      AppLogger.i(
        'Cache compression completed: $compressedCount entries removed',
        'GalleryCacheManager',
      );
      _invalidateStatisticsCache();
      return true;
    } catch (e, stack) {
      AppLogger.e('Failed to compress cache', e, stack, 'GalleryCacheManager');
      return false;
    }
  }
}

/// L2 Hive 缓存清理器
///
/// 定期清理策略：
/// 1. 应用启动时检查
/// 2. 每7天执行一次完整清理
/// 3. 清理不存在的文件对应的缓存条目
/// 4. 支持基于大小的自动清理
class L2CacheCleaner {
  static const String _lastCleanupKey = 'l2_cache_last_cleanup';
  static const String _lastSizeCheckKey = 'l2_cache_last_size_check';
  static const Duration _cleanupInterval = Duration(days: 7);
  static const Duration _sizeCheckInterval = Duration(hours: 1);

  /// 缓存大小阈值（MB）
  static const int _sizeThresholdMB = 500;
  static const int _automaticCleanupHardLimitMB = 2048;

  /// 检查并执行清理
  Future<void> checkAndClean() async {
    try {
      final box = await _getSettingsBox();
      final lastCleanup = box.get(_lastCleanupKey);
      final lastCleanupTime = lastCleanup != null
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(lastCleanup))
          : DateTime(2000);
      final now = DateTime.now();

      // 检查是否需要定期清理
      if (now.difference(lastCleanupTime) > _cleanupInterval) {
        if (await _shouldSkipAutomaticCleanupForSize()) {
          await box.put(_lastCleanupKey, now.millisecondsSinceEpoch.toString());
          return;
        }

        AppLogger.i(
          'L2 cache cleanup due (last: $lastCleanupTime)',
          'L2CacheCleaner',
        );
        await performCleanup(compactAfterCleanup: false);
        await box.put(_lastCleanupKey, now.millisecondsSinceEpoch.toString());
      } else {
        // 检查是否需要基于大小的清理
        await _checkSizeAndClean(box);
      }
    } catch (e, stack) {
      AppLogger.e(
        'Failed to check L2 cache cleanup',
        e,
        stack,
        'L2CacheCleaner',
      );
    }
  }

  /// 基于大小检查并清理
  Future<void> _checkSizeAndClean(Box box) async {
    try {
      final lastCheck = box.get(_lastSizeCheckKey);
      final lastCheckTime = lastCheck != null
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(lastCheck))
          : DateTime(2000);
      final now = DateTime.now();

      if (now.difference(lastCheckTime) < _sizeCheckInterval) {
        return; // 检查太频繁，跳过
      }

      // 获取缓存大小
      final cacheSizeMB = await _getCacheSizeMB();

      if (cacheSizeMB > _sizeThresholdMB) {
        if (cacheSizeMB > _automaticCleanupHardLimitMB) {
          AppLogger.w(
            'L2 cache size ($cacheSizeMB MB) exceeds automatic cleanup hard limit '
                '($_automaticCleanupHardLimitMB MB); skipping background cleanup to avoid UI stalls. '
                'Use manual cache clear if disk space needs to be reclaimed.',
            'L2CacheCleaner',
          );
          await box.put(
            _lastSizeCheckKey,
            now.millisecondsSinceEpoch.toString(),
          );
          return;
        }

        AppLogger.i(
          'L2 cache size ($cacheSizeMB MB) exceeds threshold ($_sizeThresholdMB MB), performing cleanup',
          'L2CacheCleaner',
        );
        await performCleanup(compactAfterCleanup: false);
      }

      await box.put(_lastSizeCheckKey, now.millisecondsSinceEpoch.toString());
    } catch (e) {
      // 忽略错误
    }
  }

  /// 获取缓存大小（MB）
  Future<int> _getCacheSizeMB() async {
    try {
      final bytes = await GalleryCacheManager().getStatistics().then(
        (s) => s.l2HiveBytes,
      );
      return bytes ~/ (1024 * 1024);
    } catch (_) {
      return 0;
    }
  }

  Future<bool> _shouldSkipAutomaticCleanupForSize() async {
    final cacheSizeMB = await _getCacheSizeMB();
    if (cacheSizeMB <= _automaticCleanupHardLimitMB) {
      return false;
    }

    AppLogger.w(
      'Skipping scheduled L2 cleanup because cache is $cacheSizeMB MB, above '
          'the automatic cleanup hard limit ($_automaticCleanupHardLimitMB MB). '
          'This avoids a long Hive scan/compact on the UI process.',
      'L2CacheCleaner',
    );
    return true;
  }

  /// 执行清理
  Future<void> performCleanup({bool compactAfterCleanup = true}) async {
    try {
      final box = ImageMetadataService().persistentBox;

      if (box == null || !box.isOpen) {
        AppLogger.w(
          'Persistent box not available for cleanup',
          'L2CacheCleaner',
        );
        return;
      }

      final keysToDelete = <String>[];
      int checkedCount = 0;
      int freedEntries = 0;

      for (final key in box.keys) {
        if (key is! String) continue;
        // 跳过版本键
        if (key.startsWith('_')) continue;

        checkedCount++;

        // 获取该哈希对应的所有路径
        final paths = ImageMetadataService().getPathsForHash(key);

        bool anyExists = false;
        for (final path in paths) {
          try {
            if (await File(path).exists()) {
              anyExists = true;
              break;
            }
          } catch (_) {
            // 忽略文件访问错误
          }
        }

        // 如果没有文件存在，标记为待删除
        if (!anyExists && paths.isNotEmpty) {
          keysToDelete.add(key);
        }

        // 每检查 100 个条目，让出时间片
        if (checkedCount % 100 == 0) {
          await Future.delayed(Duration.zero);
        }
      }

      // 批量删除
      for (final key in keysToDelete) {
        await box.delete(key);
        freedEntries++;

        // 每删除 50 个条目，让出时间片
        if (freedEntries % 50 == 0) {
          await Future.delayed(Duration.zero);
        }
      }

      if (compactAfterCleanup) {
        // 尝试压缩
        try {
          await box.compact();
        } catch (_) {
          // 忽略压缩错误
        }
      }

      AppLogger.i(
        'L2 cache cleaned: $freedEntries entries removed, $checkedCount checked, '
            'compacted=$compactAfterCleanup',
        'L2CacheCleaner',
      );
    } catch (e, stack) {
      AppLogger.e(
        'Failed to perform L2 cache cleanup',
        e,
        stack,
        'L2CacheCleaner',
      );
    }
  }

  Future<Box> _getSettingsBox() async {
    if (Hive.isBoxOpen(StorageKeys.settingsBox)) {
      return Hive.box(StorageKeys.settingsBox);
    }
    return await Hive.openBox(StorageKeys.settingsBox);
  }
}
