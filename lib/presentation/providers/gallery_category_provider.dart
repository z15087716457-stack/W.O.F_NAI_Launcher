import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/app_logger.dart';
import '../../core/utils/gallery_path_utils.dart';
import '../../data/models/gallery/gallery_category.dart';
import '../../data/repositories/gallery_category_repository.dart';
import '../../data/repositories/gallery_folder_repository.dart';
import 'category_operation_error.dart';

part 'gallery_category_provider.freezed.dart';
part 'gallery_category_provider.g.dart';

/// 收藏集选中 ID 前缀：侧栏选中态用 'collection:<id>' 扩展 selectedCategoryId 语义
const String collectionSelectedIdPrefix = 'collection:';

/// 是否为收藏集选中 ID
bool isCollectionSelectedId(String id) =>
    id.startsWith(collectionSelectedIdPrefix);

/// 画廊分类状态
@freezed
class GalleryCategoryState with _$GalleryCategoryState {
  const factory GalleryCategoryState({
    /// 所有分类
    @Default([]) List<GalleryCategory> categories,

    /// 当前选中的分类ID（null表示全部，'favorites'表示收藏）
    String? selectedCategoryId,

    /// 是否正在加载
    @Default(false) bool isLoading,

    /// 是否正在同步
    @Default(false) bool isSyncing,

    /// 错误信息
    CategoryOperationError? error,
  }) = _GalleryCategoryState;

  const GalleryCategoryState._();

  /// 获取当前选中的分类
  GalleryCategory? get selectedCategory {
    if (selectedCategoryId == null || selectedCategoryId == 'favorites') {
      return null;
    }
    return categories.findById(selectedCategoryId!);
  }

  /// 是否选中"全部"
  bool get isAllSelected => selectedCategoryId == null;

  /// 是否选中"收藏"
  bool get isFavoritesSelected => selectedCategoryId == 'favorites';

  /// 根级分类
  List<GalleryCategory> get rootCategories => categories.rootCategories;

  /// 获取分类树
  Map<String?, List<GalleryCategory>> get categoryTree =>
      categories.buildTree();
}

/// 画廊分类状态管理
@riverpod
class GalleryCategoryNotifier extends _$GalleryCategoryNotifier {
  @visibleForTesting
  static GalleryCategoryRepository? testRepositoryOverride;

  GalleryCategoryRepository get _repository =>
      testRepositoryOverride ?? GalleryCategoryRepository.instance;

  Future<void>? _loadInFlight;
  Future<void>? _syncInFlight;

  @override
  GalleryCategoryState build() {
    // 初始化时加载分类
    Future.microtask(() => _loadCategories());
    return const GalleryCategoryState(isLoading: true);
  }

  /// 加载分类列表
  Future<void> _loadCategories() async {
    if (_loadInFlight != null) {
      return _loadInFlight!;
    }

    final future = _doLoadCategories();
    _loadInFlight = future;
    bool needsInitialSync = false;
    try {
      needsInitialSync = await future;
    } finally {
      if (_loadInFlight == future) {
        _loadInFlight = null;
      }
    }

    if (needsInitialSync) {
      await syncWithFileSystem();
    }
  }

  Future<bool> _doLoadCategories() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final categories = await _repository.loadCategories();

      // 新安装首次启动检查：若无分类配置文件且未读出分类，标记需要在加载完成后触发首次同步
      final hasConfigFile = await _repository.hasCategoriesConfigFile();
      if (!hasConfigFile && categories.isEmpty) {
        state = state.copyWith(isLoading: false);
        return true;
      }

      // 更新每个分类的图片数量
      final updatedCategories = <GalleryCategory>[];
      for (final category in categories) {
        final count = await _repository.countImagesInCategory(category);
        updatedCategories.add(category.updateImageCount(count));
      }

      state = state.copyWith(categories: updatedCategories, isLoading: false);
      return false;
    } catch (e) {
      AppLogger.e('加载分类失败', e);
      state = state.copyWith(
        isLoading: false,
        error: CategoryOperationError(
          CategoryOperationErrorCode.loadFailed,
          details: e.toString(),
        ),
      );
      return false;
    }
  }

  /// 刷新分类列表
  Future<void> refresh() async {
    await _loadCategories();
  }

  /// 与文件系统同步
  Future<void> syncWithFileSystem() async {
    if (_syncInFlight != null) {
      return _syncInFlight!;
    }

    final future = _doSyncWithFileSystem();
    _syncInFlight = future;
    try {
      await future;
    } finally {
      if (_syncInFlight == future) {
        _syncInFlight = null;
      }
    }
  }

  Future<void> _doSyncWithFileSystem() async {
    // 1. 若 _loadCategories 在途或 state.isLoading，等待其完成（有界等待，最多 10s）
    if (_loadInFlight != null) {
      try {
        await _loadInFlight!.timeout(const Duration(seconds: 10));
      } catch (e) {
        AppLogger.w('等待分类加载完成超时: $e', 'GalleryCategoryNotifier');
      }
    }

    var baseCategories = state.categories;

    // 2. 若 state.categories 仍为空（首次/加载异常），先从 repository 兜底重读
    if (baseCategories.isEmpty) {
      try {
        baseCategories = await _repository.loadCategories();
      } catch (e) {
        AppLogger.w('兜底读取分类失败: $e', 'GalleryCategoryNotifier');
      }
    }

    // 3. 守卫：如果存在配置文件但读出的分类仍为空（如 I/O 或解析异常），
    // 绝不能把空集当全量分类送入 sync，否则会导致所有目录被当成新目录重分配 UUID 覆写配置。
    final hasConfigFile = await _repository.hasCategoriesConfigFile();
    if (hasConfigFile && baseCategories.isEmpty) {
      final isGenuinelyEmpty = await _repository
          .isCategoriesConfigGenuinelyEmpty();
      if (!isGenuinelyEmpty) {
        AppLogger.e(
          '分类配置文件存在且非空，但读取结果为空，中止 syncWithFileSystem 以防止 UUID 重写破坏分类树',
          null,
          null,
          'GalleryCategoryNotifier',
        );
        state = state.copyWith(
          isSyncing: false,
          error: const CategoryOperationError(
            CategoryOperationErrorCode.syncFailed,
            details:
                'Categories config unreadable; sync aborted to protect category IDs',
          ),
        );
        return;
      }
    }

    state = state.copyWith(isSyncing: true, error: null);

    try {
      final syncedCategories = await _repository.syncWithFileSystem(
        baseCategories,
      );

      // 保存同步后的分类
      await _repository.saveCategories(syncedCategories);

      state = state.copyWith(categories: syncedCategories, isSyncing: false);
    } catch (e) {
      AppLogger.e('同步分类失败', e);
      state = state.copyWith(
        isSyncing: false,
        error: CategoryOperationError(
          CategoryOperationErrorCode.syncFailed,
          details: e.toString(),
        ),
      );
    }
  }

  /// 选择分类
  void selectCategory(String? categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  /// 删除池软删后的内存级计数调整。
  ///
  /// 分类计数是文件系统口径（数盘上文件），软删文件仍在盘上、
  /// 物理删除推迟到下次启动，因此这里按「路径位于分类文件夹内」做纯内存
  /// 减计数：命中最深的分类 + 其全部祖先（imageCount 是聚合口径）。
  /// 外部图库源分类（isExternal，根级无父链）按各自 folderPath 同样减。
  Future<void> applyDeletedPaths(List<String> paths) async {
    if (paths.isEmpty || state.categories.isEmpty) return;
    try {
      final rootPath = await GalleryFolderRepository.instance.getRootPath();
      if (rootPath == null || rootPath.isEmpty) return;

      final rootKey = galleryFilePathKey(rootPath);
      final byId = {for (final c in state.categories) c.id: c};
      final decrements = <String, int>{};

      for (final filePath in paths) {
        final key = galleryFilePathKey(filePath);

        // 外部图库源：命中其 folderPath 即减（根级，无祖先链）
        var handledExternally = false;
        for (final category in state.categories) {
          if (!category.isExternal) continue;
          final folder = _trimSeparators(
            galleryFilePathKey(category.folderPath),
          );
          if (folder.isEmpty) continue;
          final fileKey = _trimSeparators(key);
          if (fileKey == folder ||
              fileKey.startsWith('$folder\\') ||
              fileKey.startsWith('$folder/')) {
            decrements.update(category.id, (v) => v + 1, ifAbsent: () => 1);
            handledExternally = true;
            break;
          }
        }
        if (handledExternally) continue;

        if (!galleryPathIsWithin(rootPath, filePath)) continue;
        var rel = key.substring(rootKey.length);
        while (rel.startsWith(r'\') || rel.startsWith('/')) {
          rel = rel.substring(1);
        }
        if (rel.isEmpty) continue;

        // 命中最深分类（folderPath 最长者）
        GalleryCategory? deepest;
        for (final category in state.categories) {
          if (category.isExternal) continue;
          final folder = _trimSeparators(
            galleryFilePathKey(category.folderPath),
          );
          if (folder.isEmpty) continue;
          final isInside =
              rel == folder ||
              rel.startsWith('$folder\\') ||
              rel.startsWith('$folder/');
          if (isInside &&
              (deepest == null ||
                  folder.length >
                      _trimSeparators(
                        galleryFilePathKey(deepest.folderPath),
                      ).length)) {
            deepest = category;
          }
        }
        if (deepest == null) continue;

        decrements.update(deepest.id, (v) => v + 1, ifAbsent: () => 1);
        var parentId = deepest.parentId;
        while (parentId != null) {
          decrements.update(parentId, (v) => v + 1, ifAbsent: () => 1);
          parentId = byId[parentId]?.parentId;
        }
      }

      if (decrements.isEmpty) return;

      state = state.copyWith(
        categories: [
          for (final category in state.categories)
            (decrements[category.id] ?? 0) == 0
                ? category
                : category.updateImageCount(
                    _safeSubtract(
                      category.imageCount,
                      decrements[category.id]!,
                    ),
                  ),
        ],
      );
    } catch (e) {
      AppLogger.w('Failed to adjust category counts for deleted paths: $e');
    }
  }

  static int _safeSubtract(int value, int decrement) {
    final result = value - decrement;
    return result < 0 ? 0 : result;
  }

  static String _trimSeparators(String value) {
    var out = value;
    while (out.startsWith(r'\') || out.startsWith('/')) {
      out = out.substring(1);
    }
    while (out.endsWith(r'\') || out.endsWith('/')) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }

  /// 创建新分类
  Future<GalleryCategory?> createCategory(
    String name, {
    String? parentId,
  }) async {
    try {
      final category = await _repository.createCategory(
        name: name,
        parentId: parentId,
        existingCategories: state.categories,
      );

      if (category != null) {
        final updatedCategories = [...state.categories, category];
        await _repository.saveCategories(updatedCategories);

        state = state.copyWith(categories: updatedCategories);
        return category;
      }

      return null;
    } catch (e) {
      AppLogger.e('创建分类失败', e);
      state = state.copyWith(
        error: CategoryOperationError(
          CategoryOperationErrorCode.createFailed,
          details: e.toString(),
        ),
      );
      return null;
    }
  }

  /// 重命名分类
  Future<GalleryCategory?> renameCategory(
    String categoryId,
    String newName,
  ) async {
    final category = state.categories.findById(categoryId);
    if (category == null) {
      state = state.copyWith(
        error: const CategoryOperationError(
          CategoryOperationErrorCode.categoryNotFound,
        ),
      );
      return null;
    }

    try {
      final renamed = await _repository.renameCategory(
        category,
        newName,
        state.categories,
      );

      if (renamed != null) {
        // 更新分类列表
        var updatedCategories = state.categories
            .map((c) => c.id == categoryId ? renamed : c)
            .toList();

        // 更新所有子分类的路径
        final oldPath = category.folderPath;
        final newPath = renamed.folderPath;
        updatedCategories = _repository.updateDescendantPaths(
          oldPath,
          newPath,
          updatedCategories,
        );

        await _repository.saveCategories(updatedCategories);

        state = state.copyWith(categories: updatedCategories);
        return renamed;
      }

      return null;
    } catch (e) {
      AppLogger.e('重命名分类失败', e);
      state = state.copyWith(
        error: CategoryOperationError(
          CategoryOperationErrorCode.renameFailed,
          details: e.toString(),
        ),
      );
      return null;
    }
  }

  /// 移动分类到新父级
  Future<GalleryCategory?> moveCategory(
    String categoryId,
    String? newParentId,
  ) async {
    final category = state.categories.findById(categoryId);
    if (category == null) {
      state = state.copyWith(
        error: const CategoryOperationError(
          CategoryOperationErrorCode.categoryNotFound,
        ),
      );
      return null;
    }

    // 检查循环引用
    if (newParentId != null &&
        state.categories.wouldCreateCycle(categoryId, newParentId)) {
      state = state.copyWith(
        error: const CategoryOperationError(
          CategoryOperationErrorCode.invalidMove,
        ),
      );
      return null;
    }

    try {
      final moved = await _repository.moveCategory(
        category,
        newParentId,
        state.categories,
      );

      if (moved != null) {
        // 更新分类列表
        var updatedCategories = state.categories
            .map((c) => c.id == categoryId ? moved : c)
            .toList();

        // 更新所有子分类的路径
        final oldPath = category.folderPath;
        final newPath = moved.folderPath;
        updatedCategories = _repository.updateDescendantPaths(
          oldPath,
          newPath,
          updatedCategories,
        );

        await _repository.saveCategories(updatedCategories);

        state = state.copyWith(categories: updatedCategories);
        return moved;
      }

      return null;
    } catch (e) {
      AppLogger.e('移动分类失败', e);
      state = state.copyWith(
        error: CategoryOperationError(
          CategoryOperationErrorCode.moveFailed,
          details: e.toString(),
        ),
      );
      return null;
    }
  }

  /// 删除分类
  Future<bool> deleteCategory(
    String categoryId, {
    bool deleteFolder = true,
    bool recursive = false,
  }) async {
    final category = state.categories.findById(categoryId);
    if (category == null) {
      state = state.copyWith(
        error: const CategoryOperationError(
          CategoryOperationErrorCode.categoryNotFound,
        ),
      );
      return false;
    }

    // 检查是否有子分类
    final children = state.categories.getChildren(categoryId);
    if (children.isNotEmpty && !recursive) {
      state = state.copyWith(
        error: const CategoryOperationError(
          CategoryOperationErrorCode.hasSubcategories,
        ),
      );
      return false;
    }

    try {
      final success = await _repository.deleteCategory(
        category,
        state.categories,
        deleteFolder: deleteFolder,
        recursive: recursive,
      );

      if (success) {
        // 获取要删除的所有分类ID（包括子分类）
        final categoryIds = {
          categoryId,
          if (recursive) ...state.categories.getDescendantIds(categoryId),
        };

        // 从列表中移除
        final updatedCategories = state.categories
            .where((c) => !categoryIds.contains(c.id))
            .toList();

        await _repository.saveCategories(updatedCategories);

        // 如果删除的是当前选中的分类，切换到"全部"
        final newSelectedId =
            state.selectedCategoryId == categoryId ||
                (state.selectedCategoryId != null &&
                    categoryIds.contains(state.selectedCategoryId))
            ? null
            : state.selectedCategoryId;

        state = state.copyWith(
          categories: updatedCategories,
          selectedCategoryId: newSelectedId,
        );

        return true;
      }

      return false;
    } catch (e) {
      AppLogger.e('删除分类失败', e);
      state = state.copyWith(
        error: CategoryOperationError(
          CategoryOperationErrorCode.deleteFailed,
          details: e.toString(),
        ),
      );
      return false;
    }
  }

  /// 移动图片到分类
  Future<String?> moveImageToCategory(
    String imagePath,
    String? categoryId,
  ) async {
    GalleryCategory? category;
    if (categoryId != null &&
        categoryId != 'favorites' &&
        !isCollectionSelectedId(categoryId)) {
      category = state.categories.findById(categoryId);
    }

    try {
      final newPath = await _repository.moveImageToCategory(
        imagePath,
        category,
      );

      if (newPath != null) {
        // 刷新分类图片数量
        await _updateCategoryImageCounts();
      }

      return newPath;
    } catch (e) {
      AppLogger.e('移动图片失败', e);
      state = state.copyWith(
        error: CategoryOperationError(
          CategoryOperationErrorCode.moveImageFailed,
          details: e.toString(),
        ),
      );
      return null;
    }
  }

  /// 批量移动图片到分类
  Future<int> moveImagesToCategory(
    List<String> imagePaths,
    String? categoryId,
  ) async {
    GalleryCategory? category;
    if (categoryId != null &&
        categoryId != 'favorites' &&
        !isCollectionSelectedId(categoryId)) {
      category = state.categories.findById(categoryId);
    }

    try {
      final count = await _repository.moveImagesToCategory(
        imagePaths,
        category,
      );

      if (count > 0) {
        // 刷新分类图片数量
        await _updateCategoryImageCounts();
      }

      return count;
    } catch (e) {
      AppLogger.e('批量移动图片失败', e);
      state = state.copyWith(
        error: CategoryOperationError(
          CategoryOperationErrorCode.moveImagesFailed,
          details: e.toString(),
        ),
      );
      return 0;
    }
  }

  /// 更新所有分类的图片数量
  Future<void> _updateCategoryImageCounts() async {
    final updatedCategories = <GalleryCategory>[];

    for (final category in state.categories) {
      final count = await _repository.countImagesInCategory(category);
      updatedCategories.add(category.updateImageCount(count));
    }

    await _repository.saveCategories(updatedCategories);

    state = state.copyWith(categories: updatedCategories);
  }

  /// 重新排序分类
  Future<void> reorderCategories(
    String? parentId,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      // 获取同级分类
      final siblings = parentId == null
          ? state.categories.rootCategories.sortedByOrder()
          : state.categories.getChildren(parentId).sortedByOrder();

      if (oldIndex < 0 ||
          oldIndex >= siblings.length ||
          newIndex < 0 ||
          newIndex >= siblings.length) {
        return;
      }

      // 重新排序
      final reordered = [...siblings];
      final item = reordered.removeAt(oldIndex);
      reordered.insert(newIndex, item);

      // 更新排序顺序
      final updatedSiblings = reordered.asMap().entries.map((e) {
        return e.value.copyWith(sortOrder: e.key, updatedAt: DateTime.now());
      }).toList();

      // 更新完整分类列表
      final updatedCategories = state.categories.map((c) {
        final updated = updatedSiblings.where((s) => s.id == c.id).firstOrNull;
        return updated ?? c;
      }).toList();

      await _repository.saveCategories(updatedCategories);

      state = state.copyWith(categories: updatedCategories);
    } catch (e) {
      AppLogger.e('重新排序失败', e);
      state = state.copyWith(
        error: CategoryOperationError(
          CategoryOperationErrorCode.reorderFailed,
          details: e.toString(),
        ),
      );
    }
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 获取分类的完整路径
  String getCategoryPath(String categoryId) {
    return state.categories.getPathString(categoryId);
  }

  /// 获取分类及其所有子分类的ID
  Set<String> getCategoryWithDescendants(String categoryId) {
    return {categoryId, ...state.categories.getDescendantIds(categoryId)};
  }
}
