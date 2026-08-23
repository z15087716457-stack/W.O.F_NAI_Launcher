import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/database/datasources/gallery_data_source.dart';
import '../../core/utils/app_logger.dart';
import '../models/gallery/gallery_collection_info.dart';
import '../models/gallery/image_collection.dart';

/// 收藏集合仓库
///
/// 负责管理图片集合的 CRUD 操作。
/// 存储后端为画廊数据库（gallery_collections / gallery_collection_items），
/// 链接式成员关系（image_id），不复制文件。
class CollectionRepository {
  CollectionRepository._();
  static final CollectionRepository instance = CollectionRepository._();

  static const String _legacyMigrationDoneKey =
      'collection_legacy_hive_migrated_v1';

  GalleryDataSource get _dataSource => GalleryDataSource();

  /// 初始化仓库（确保画廊数据源就绪 + 一次性迁移旧 Hive 集合）
  Future<void> initialize() async {
    await _dataSource.initialize();
    await _migrateLegacyHiveCollectionsIfNeeded();
  }

  /// 旧版 Hive 集合（按路径存储）一次性迁移到 DB（按 image_id 链接）。
  /// 迁移失败不阻塞启动；成功（或无数据可迁）才落完成标记，
  /// 暂时性失败下次启动自动重试（Hive box 数据保留，不会丢）。
  Future<void> _migrateLegacyHiveCollectionsIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_legacyMigrationDoneKey) ?? false) return;

      if (Hive.isBoxOpen(StorageKeys.collectionsBox)) {
        final box = Hive.box(StorageKeys.collectionsBox);
        if (box.isNotEmpty &&
            (await _dataSource.listCollectionsWithCounts()).isEmpty) {
          final entries = box.values
              .map(
                (data) => ImageCollection.fromJson(
                  Map<String, dynamic>.from(data as Map),
                ),
              )
              .toList();
          final allPaths = {
            for (final entry in entries) ...entry.imagePaths,
          }.toList();
          final pathToId = await _dataSource.getImageIdsByPaths(allPaths);

          for (final entry in entries) {
            if (entry.name.trim().isEmpty) continue;
            final id = await _dataSource.createCollection(entry.name);
            for (final path in entry.imagePaths) {
              final imageId = pathToId[path];
              if (imageId != null) {
                await _dataSource.addImageToCollection(id, imageId);
              }
            }
          }
          AppLogger.i(
            'Migrated ${entries.length} legacy collections to gallery DB',
            'CollectionRepo',
          );
          await box.clear();
        }
      }
      await prefs.setBool(_legacyMigrationDoneKey, true);
    } catch (e) {
      // 失败不落标记：下次启动重试（用户数据仍在 Hive box 里不丢）
      AppLogger.w('Legacy collection migration failed: $e', 'CollectionRepo');
    }
  }

  /// 创建新集合
  Future<ImageCollection> createCollection(
    String name, {
    String? description,
  }) async {
    final id = await _dataSource.createCollection(name);
    final info = (await _dataSource.listCollectionsWithCounts())
        .where((c) => c.id == id)
        .firstOrNull;
    AppLogger.i(
      'Created collection: $name (${info?.imageCount ?? 0} images)',
      'CollectionRepo',
    );
    return _infoToCollection(
      info ??
          GalleryCollectionInfo(
            id: id,
            name: name.trim(),
            createdAt: DateTime.now(),
          ),
    );
  }

  /// 重命名集合
  Future<bool> renameCollection(String id, String newName) async {
    final ok = await _dataSource.renameCollection(id, newName);
    if (ok) {
      AppLogger.i('Renamed collection: $id -> $newName', 'CollectionRepo');
    }
    return ok;
  }

  /// 获取指定集合
  Future<ImageCollection?> getCollection(String id) async {
    try {
      final info = (await _dataSource.listCollectionsWithCounts())
          .where((c) => c.id == id)
          .firstOrNull;
      return info == null ? null : _infoToCollection(info);
    } catch (e) {
      AppLogger.e('Failed to get collection: $id', e, null, 'CollectionRepo');
      return null;
    }
  }

  /// 获取所有集合（按 DB 排序）
  Future<List<ImageCollection>> getAllCollections() async {
    try {
      final collections = [
        for (final info
            in await _dataSource.listCollectionsWithCounts())
          _infoToCollection(info),
      ];
      AppLogger.d(
        'Retrieved ${collections.length} collections',
        'CollectionRepo',
      );
      return collections;
    } catch (e) {
      AppLogger.e('Failed to get all collections', e, null, 'CollectionRepo');
      return [];
    }
  }

  /// 按新顺序持久化集合排序
  Future<bool> reorderCollections(List<String> orderedIds) async {
    try {
      return await _dataSource.reorderCollections(orderedIds);
    } catch (e) {
      AppLogger.e('Failed to reorder collections', e, null, 'CollectionRepo');
      return false;
    }
  }

  /// 更新集合（DB 后端仅名称可变）
  Future<bool> updateCollection(ImageCollection collection) async {
    return renameCollection(collection.id, collection.name);
  }

  /// 删除集合（级联删除成员关系，不删图片文件）
  Future<bool> deleteCollection(String id) async {
    try {
      final ok = await _dataSource.deleteCollection(id);
      if (ok) {
        AppLogger.i('Deleted collection: $id', 'CollectionRepo');
      }
      return ok;
    } catch (e) {
      AppLogger.e(
        'Failed to delete collection: $id',
        e,
        null,
        'CollectionRepo',
      );
      return false;
    }
  }

  /// 添加图片到集合（按路径解析为 image_id 链接；已存在跳过）
  Future<int> addImagesToCollection(
    String collectionId,
    List<String> imagePaths,
  ) async {
    try {
      final pathToId = await _dataSource.getImageIdsByPaths(imagePaths);
      var addedCount = 0;
      for (final path in imagePaths) {
        final imageId = pathToId[path];
        if (imageId == null) continue;
        if (await _dataSource.addImageToCollection(collectionId, imageId)) {
          addedCount++;
        }
      }
      AppLogger.i(
        'Added $addedCount images to collection: $collectionId',
        'CollectionRepo',
      );
      return addedCount;
    } catch (e) {
      AppLogger.e(
        'Failed to add images to collection: $collectionId',
        e,
        null,
        'CollectionRepo',
      );
      return 0;
    }
  }

  /// 从集合移除图片
  Future<int> removeImagesFromCollection(
    String collectionId,
    List<String> imagePaths,
  ) async {
    try {
      final pathToId = await _dataSource.getImageIdsByPaths(imagePaths);
      var removedCount = 0;
      for (final path in imagePaths) {
        final imageId = pathToId[path];
        if (imageId == null) continue;
        final existed = await _dataSource.removeImageFromCollection(
          collectionId,
          imageId,
        );
        if (existed) removedCount++;
      }
      AppLogger.i(
        'Removed $removedCount images from collection: $collectionId',
        'CollectionRepo',
      );
      return removedCount;
    } catch (e) {
      AppLogger.e(
        'Failed to remove images from collection: $collectionId',
        e,
        null,
        'CollectionRepo',
      );
      return 0;
    }
  }

  /// 检查图片是否在集合中
  Future<bool> isImageInCollection(
    String collectionId,
    String imagePath,
  ) async {
    final collection = await getCollection(collectionId);
    if (collection == null) return false;
    final imageId = await _dataSource.getImageIdByPath(imagePath);
    if (imageId == null) return false;
    final memberIds = await _dataSource.getCollectionImageIds(collectionId);
    return memberIds.contains(imageId);
  }

  /// 获取集合中图片数量
  Future<int> getCollectionImageCount(String collectionId) async {
    final collection = await getCollection(collectionId);
    return collection?.imageCount ?? 0;
  }

  /// 图片所在的集合 ID 集合
  Future<Set<String>> getCollectionIdsForImage(String imagePath) async {
    final imageId = await _dataSource.getImageIdByPath(imagePath);
    if (imageId == null) return {};
    return _dataSource.getCollectionIdsForImage(imageId);
  }

  /// 路径 → 图片 ID（null 表示未索引）
  Future<int?> getImageIdByPath(String imagePath) {
    return _dataSource.getImageIdByPath(imagePath);
  }

  /// 集合内图片 ID 列表
  Future<List<int>> getCollectionImageIds(String collectionId) {
    return _dataSource.getCollectionImageIds(collectionId);
  }

  /// 清空所有集合
  Future<void> clearAllCollections() async {
    final infos = await _dataSource.listCollectionsWithCounts();
    for (final info in infos) {
      await _dataSource.deleteCollection(info.id);
    }
    AppLogger.i('Cleared all collections', 'CollectionRepo');
  }

  ImageCollection _infoToCollection(GalleryCollectionInfo info) {
    return ImageCollection(
      id: info.id,
      name: info.name,
      imageCount: info.imageCount,
      createdAt: info.createdAt,
    );
  }
}
