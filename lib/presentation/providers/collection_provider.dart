import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../data/models/gallery/image_collection.dart';
import '../../data/repositories/collection_repository.dart';

part 'collection_provider.freezed.dart';
part 'collection_provider.g.dart';

/// Provider for CollectionRepository
@Riverpod(keepAlive: true)
CollectionRepository collectionRepository(Ref ref) {
  return CollectionRepository.instance;
}

/// 集合状态
@freezed
class CollectionState with _$CollectionState {
  const factory CollectionState({
    /// 所有集合
    @Default([]) List<ImageCollection> collections,

    /// 是否正在加载
    @Default(false) bool isLoading,

    /// 当前正在操作的集合ID
    String? activeCollectionId,

    /// 错误信息
    String? error,
  }) = _CollectionState;

  const CollectionState._();

  /// 集合数量
  int get collectionCount => collections.length;

  /// 是否有错误
  bool get hasError => error != null;

  /// 获取当前活动的集合
  ImageCollection? get activeCollection {
    if (activeCollectionId == null) return null;
    return collections.where((c) => c.id == activeCollectionId).firstOrNull;
  }
}

/// 集合 Notifier
@Riverpod(keepAlive: true)
class CollectionNotifier extends _$CollectionNotifier {
  @override
  CollectionState build() {
    _repository = ref.read(collectionRepositoryProvider);
    // Don't auto-load - wait for explicit initialize() call
    // This allows tests to override the repository before loading
    return const CollectionState();
  }

  late final CollectionRepository _repository;

  /// 加载所有集合
  Future<void> _loadCollections() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final collections = await _repository.getAllCollections();
      state = state.copyWith(
        collections: collections,
        isLoading: false,
      );
      AppLogger.d(
        'Loaded ${collections.length} collections',
        'CollectionNotifier',
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      AppLogger.e(
        'Failed to load collections',
        e,
        null,
        'CollectionNotifier',
      );
    }
  }

  /// 初始化：加载所有集合
  Future<void> initialize() async {
    // Only load if not already loaded
    if (state.collections.isEmpty) {
      await _loadCollections();
    }
  }

  /// 刷新集合列表
  Future<void> refresh() async {
    await _loadCollections();
  }

  /// 创建新集合
  ///
  /// [name] 集合名称
  /// [description] 集合描述（可选）
  /// 返回创建的集合，失败返回 null
  Future<ImageCollection?> createCollection(
    String name, {
    String? description,
  }) async {
    try {
      // 清除之前的错误
      state = state.copyWith(error: null);

      final collection = await _repository.createCollection(
        name,
        description: description,
      );

      // 重新加载集合列表
      await _loadCollections();

      AppLogger.i(
        'Created collection: ${collection.name}',
        'CollectionNotifier',
      );

      return collection;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      AppLogger.e(
        'Failed to create collection: $name',
        e,
        null,
        'CollectionNotifier',
      );
      return null;
    }
  }

  /// 更新集合
  ///
  /// [collection] 要更新的集合
  /// 返回更新是否成功
  Future<bool> updateCollection(ImageCollection collection) async {
    try {
      state = state.copyWith(error: null);

      final success = await _repository.updateCollection(collection);

      if (success) {
        // 重新加载集合列表
        await _loadCollections();

        AppLogger.i(
          'Updated collection: ${collection.name}',
          'CollectionNotifier',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      AppLogger.e(
        'Failed to update collection: ${collection.id}',
        e,
        null,
        'CollectionNotifier',
      );
      return false;
    }
  }

  /// 删除集合
  ///
  /// [id] 集合ID
  /// 返回删除是否成功
  Future<bool> deleteCollection(String id) async {
    try {
      state = state.copyWith(error: null);

      final success = await _repository.deleteCollection(id);

      if (success) {
        // 如果删除的是当前活动集合，清除活动集合
        if (state.activeCollectionId == id) {
          state = state.copyWith(activeCollectionId: null);
        }

        // 重新加载集合列表
        await _loadCollections();

        AppLogger.i(
          'Deleted collection: $id',
          'CollectionNotifier',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      AppLogger.e(
        'Failed to delete collection: $id',
        e,
        null,
        'CollectionNotifier',
      );
      return false;
    }
  }

  /// 添加图片到集合
  ///
  /// [collectionId] 集合ID
  /// [imagePaths] 图片路径列表
  /// 返回添加结果（新插入数/已在集合数/未解析数）
  Future<CollectionAddResult> addImagesToCollection(
    String collectionId,
    List<String> imagePaths,
  ) async {
    try {
      state = state.copyWith(error: null);

      final result =
          await _repository.addImagesToCollection(collectionId, imagePaths);

      // 重新加载集合列表以更新数据
      await _loadCollections();

      if (result.added > 0) {
        AppLogger.i(
          'Added ${result.added} images to collection: $collectionId',
          'CollectionNotifier',
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      AppLogger.e(
        'Failed to add images to collection: $collectionId',
        e,
        null,
        'CollectionNotifier',
      );
      return (
        added: 0,
        alreadyIn: 0,
        unresolved: imagePaths.length,
      );
    }
  }

  /// 从集合移除图片
  ///
  /// [collectionId] 集合ID
  /// [imagePaths] 要移除的图片路径列表
  /// 返回移除的图片数量
  Future<int> removeImagesFromCollection(
    String collectionId,
    List<String> imagePaths,
  ) async {
    try {
      state = state.copyWith(error: null);

      final removedCount = await _repository
          .removeImagesFromCollection(collectionId, imagePaths);

      // 重新加载集合列表以更新数据
      await _loadCollections();

      if (removedCount > 0) {
        AppLogger.i(
          'Removed $removedCount images from collection: $collectionId',
          'CollectionNotifier',
        );
      }

      return removedCount;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      AppLogger.e(
        'Failed to remove images from collection: $collectionId',
        e,
        null,
        'CollectionNotifier',
      );
      return 0;
    }
  }

  /// 重命名集合
  ///
  /// [id] 集合ID
  /// [newName] 新名称
  /// 返回重命名是否成功
  Future<bool> renameCollection(String id, String newName) async {
    try {
      state = state.copyWith(error: null);

      final success = await _repository.renameCollection(id, newName);

      if (success) {
        await _loadCollections();
        AppLogger.i('Renamed collection: $id', 'CollectionNotifier');
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      AppLogger.e(
        'Failed to rename collection: $id',
        e,
        null,
        'CollectionNotifier',
      );
      return false;
    }
  }

  /// 重新排序集合（同级内拖拽排序）
  Future<bool> reorder(int oldIndex, int newIndex) async {
    final collections = state.collections;
    if (oldIndex < 0 ||
        oldIndex >= collections.length ||
        newIndex < 0 ||
        newIndex >= collections.length) {
      return false;
    }

    try {
      final orderedIds = collections.map((c) => c.id).toList();
      final id = orderedIds.removeAt(oldIndex);
      orderedIds.insert(newIndex, id);

      final success = await _repository.reorderCollections(orderedIds);
      if (success) {
        await _loadCollections();
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      AppLogger.e(
        'Failed to reorder collections',
        e,
        null,
        'CollectionNotifier',
      );
      return false;
    }
  }

  /// 切换图片在集合中的成员关系，返回切换后的成员状态
  Future<bool> toggleImageInCollection(
    String collectionId,
    String imagePath,
  ) async {
    try {
      state = state.copyWith(error: null);

      final imageId = await _repository.getImageIdByPath(imagePath);
      if (imageId == null) return false;

      final memberIds = await _repository.getCollectionImageIds(collectionId);
      final isMember = memberIds.contains(imageId);

      if (isMember) {
        await _repository.removeImagesFromCollection(collectionId, [
          imagePath,
        ]);
      } else {
        await _repository.addImagesToCollection(collectionId, [imagePath]);
      }

      await _loadCollections();
      return !isMember;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      AppLogger.e(
        'Failed to toggle image in collection: $collectionId',
        e,
        null,
        'CollectionNotifier',
      );
      return false;
    }
  }

  /// 图片所在的集合 ID 集合
  Future<Set<String>> getCollectionIdsForImage(String imagePath) {
    return _repository.getCollectionIdsForImage(imagePath);
  }

  /// 各集合与给定图片路径的交集数（collectionId → 张数）
  Future<Map<String, int>> countMembershipByPaths(List<String> imagePaths) {
    return _repository.countMembershipByPaths(imagePaths);
  }

  /// 检查图片是否在集合中
  Future<bool> isImageInCollection(
    String collectionId,
    String imagePath,
  ) async {
    return _repository.isImageInCollection(collectionId, imagePath);
  }

  /// 获取指定集合
  ///
  /// [id] 集合ID
  /// 返回集合，不存在返回 null
  Future<ImageCollection?> getCollection(String id) async {
    return _repository.getCollection(id);
  }

  /// 设置当前活动的集合
  ///
  /// [id] 集合ID，null 表示清除活动集合
  void setActiveCollection(String? id) {
    state = state.copyWith(activeCollectionId: id);
    AppLogger.d(
      'Set active collection: ${id ?? "none"}',
      'CollectionNotifier',
    );
  }

  /// 清除错误状态
  void clearError() {
    state = state.copyWith(error: null);
  }
}
