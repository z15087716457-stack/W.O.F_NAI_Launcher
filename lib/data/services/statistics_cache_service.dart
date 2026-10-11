import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/utils/app_logger.dart';
import '../models/gallery/gallery_dashboard_snapshot.dart';

part 'statistics_cache_service.g.dart';

/// 统计数据缓存元信息
class StatisticsCacheMetadata {
  /// 缓存的图片数量
  final int imageCount;

  /// 缓存创建时间
  final DateTime cachedAt;

  /// 画廊路径（用于验证）
  final String? galleryPath;

  const StatisticsCacheMetadata({
    required this.imageCount,
    required this.cachedAt,
    this.galleryPath,
  });

  Map<String, dynamic> toJson() => {
    'imageCount': imageCount,
    'cachedAt': cachedAt.toIso8601String(),
    'galleryPath': galleryPath,
  };

  factory StatisticsCacheMetadata.fromJson(Map<String, dynamic> json) {
    return StatisticsCacheMetadata(
      imageCount: json['imageCount'] as int,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      galleryPath: json['galleryPath'] as String?,
    );
  }
}

/// 统计数据持久化缓存服务
///
/// 将统计计算结果保存到 Hive，避免每次启动都重新计算
class StatisticsCacheService {
  Box get _cacheBox => Hive.box(StorageKeys.statisticsCacheBox);

  StatisticsDashboardCache? getDashboardCache(String key) {
    try {
      final json = _cacheBox.get('dashboard_v2:$key') as String?;
      return json == null
          ? null
          : StatisticsDashboardCache.fromJson(
              jsonDecode(json) as Map<String, dynamic>,
            );
    } catch (e, stack) {
      AppLogger.e(
        'Failed to read dashboard cache',
        e,
        stack,
        'StatisticsCacheService',
      );
      return null;
    }
  }

  Future<void> saveDashboardCache(String key, StatisticsDashboardCache cache) =>
      _cacheBox.put('dashboard_v2:$key', jsonEncode(cache.toJson()));

  Future<void> clearDashboardCache(String key) =>
      _cacheBox.delete('dashboard_v2:$key');

  /// 获取缓存元信息
  StatisticsCacheMetadata? getCacheMetadata() {
    try {
      final metaJson =
          _cacheBox.get(StorageKeys.statisticsCacheMetadata) as String?;
      if (metaJson == null) return null;
      return StatisticsCacheMetadata.fromJson(
        jsonDecode(metaJson) as Map<String, dynamic>,
      );
    } catch (e, stack) {
      AppLogger.e(
        'Failed to get cache metadata',
        e,
        stack,
        'StatisticsCacheService',
      );
      return null;
    }
  }

  /// 增量更新缓存（添加新图片）
  ///
  /// 当生成新图时调用，更新缓存中的图片数量，避免下次启动时完全重新计算
  /// [addedCount] 新增的图片数量
  Future<void> incrementImageCount(int addedCount) async {
    if (addedCount <= 0) return;
    try {
      final metadata = getCacheMetadata();
      if (metadata == null) return;
      final newMetadata = StatisticsCacheMetadata(
        imageCount: metadata.imageCount + addedCount,
        cachedAt: metadata.cachedAt, // 保持原有时间戳
        galleryPath: metadata.galleryPath,
      );
      await _cacheBox.put(
        StorageKeys.statisticsCacheMetadata,
        jsonEncode(newMetadata.toJson()),
      );
      AppLogger.d(
        'Statistics cache count updated: ${metadata.imageCount} -> ${newMetadata.imageCount}',
        'StatisticsCacheService',
      );
    } catch (e, stack) {
      AppLogger.e(
        'Failed to increment cache count',
        e,
        stack,
        'StatisticsCacheService',
      );
    }
  }

  /// 清除缓存
  Future<void> clearCache() async {
    try {
      await _cacheBox.deleteAll(
        _cacheBox.keys
            .where((key) => key is String && key.startsWith('dashboard_v2:'))
            .toList(),
      );
      await _cacheBox.delete(StorageKeys.statisticsCacheData);
      await _cacheBox.delete(StorageKeys.statisticsCacheMetadata);
      AppLogger.i('Statistics cache cleared', 'StatisticsCacheService');
    } catch (e, stack) {
      AppLogger.e(
        'Failed to clear statistics cache',
        e,
        stack,
        'StatisticsCacheService',
      );
    }
  }
}

class StatisticsDashboardCache {
  const StatisticsDashboardCache({
    required this.snapshot,
    required this.signature,
    required this.calculatedAt,
    this.artists,
  });

  final GalleryDashboardSnapshot snapshot;
  final String signature;
  final DateTime calculatedAt;
  final GalleryArtistStatistics? artists;

  Map<String, Object?> toJson() => {
    'snapshot': snapshot.toJson(),
    'signature': signature,
    'calculatedAt': calculatedAt.toIso8601String(),
    'artists': artists?.toJson(),
  };

  factory StatisticsDashboardCache.fromJson(Map<String, dynamic> json) =>
      StatisticsDashboardCache(
        snapshot: GalleryDashboardSnapshot.fromJson(
          json['snapshot'] as Map<String, dynamic>,
        ),
        signature: json['signature'] as String,
        calculatedAt: DateTime.parse(json['calculatedAt'] as String),
        artists: json['artists'] == null
            ? null
            : GalleryArtistStatistics.fromJson(
                json['artists'] as Map<String, dynamic>,
              ),
      );
}

/// StatisticsCacheService Provider
@Riverpod(keepAlive: true)
StatisticsCacheService statisticsCacheService(Ref ref) {
  return StatisticsCacheService();
}
