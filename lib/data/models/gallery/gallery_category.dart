import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/gallery_path_utils.dart';

part 'gallery_category.freezed.dart';
part 'gallery_category.g.dart';

/// 画廊分类数据模型
///
/// 用于组织画廊图片，支持无限层级嵌套
/// 与文件夹系统同步
@freezed
class GalleryCategory with _$GalleryCategory {
  const GalleryCategory._();

  const factory GalleryCategory({
    /// 唯一标识
    required String id,

    /// 分类名称
    required String name,

    /// 文件夹路径 (相对于画廊根目录)
    required String folderPath,

    /// 父分类ID (null 表示根级分类)
    String? parentId,

    /// 排序顺序
    @Default(0) int sortOrder,

    /// 图片数量 (包含子分类)
    @Default(0) int imageCount,

    /// 创建时间
    required DateTime createdAt,

    /// 更新时间
    required DateTime updatedAt,
  }) = _GalleryCategory;

  factory GalleryCategory.fromJson(Map<String, dynamic> json) =>
      _$GalleryCategoryFromJson(json);

  /// 创建新分类
  factory GalleryCategory.create({
    required String name,
    required String folderPath,
    String? parentId,
    int sortOrder = 0,
  }) {
    final now = DateTime.now();
    return GalleryCategory(
      id: const Uuid().v4(),
      name: name.trim(),
      folderPath: folderPath,
      parentId: parentId,
      sortOrder: sortOrder,
      imageCount: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 是否为根级分类
  bool get isRoot => parentId == null;

  /// 是否属于外部图库源（folderPath 为绝对路径）
  ///
  /// 外部图库源只读：不允许重命名/移动/删除分类、移动图片进出
  bool get isExternal => isAbsoluteGalleryPath(folderPath);

  /// 显示名称
  String get displayName => name.isNotEmpty ? name : '未命名分类';

  /// 更新名称
  GalleryCategory updateName(String newName) {
    return copyWith(name: newName.trim(), updatedAt: DateTime.now());
  }

  /// 移动到新父分类
  GalleryCategory moveTo(String? newParentId, String newFolderPath) {
    return copyWith(
      parentId: newParentId,
      folderPath: newFolderPath,
      updatedAt: DateTime.now(),
    );
  }

  /// 更新文件夹路径
  GalleryCategory updateFolderPath(String newFolderPath) {
    return copyWith(folderPath: newFolderPath, updatedAt: DateTime.now());
  }

  /// 更新图片数量
  GalleryCategory updateImageCount(int count) {
    return copyWith(imageCount: count, updatedAt: DateTime.now());
  }
}

/// 画廊分类列表扩展
extension GalleryCategoryListExtension on List<GalleryCategory> {
  /// 获取根级分类
  List<GalleryCategory> get rootCategories =>
      where((c) => c.parentId == null).toList();

  /// 获取指定父分类的子分类
  List<GalleryCategory> getChildren(String parentId) =>
      where((c) => c.parentId == parentId).toList();

  /// 按排序顺序排列
  List<GalleryCategory> sortedByOrder() {
    final sorted = [...this];
    sorted.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted;
  }

  /// 按名称排序
  List<GalleryCategory> sortedByName() {
    final sorted = [...this];
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  /// 构建分类树
  Map<String?, List<GalleryCategory>> buildTree() {
    final tree = <String?, List<GalleryCategory>>{};
    for (final category in this) {
      final parentId = category.parentId;
      tree.putIfAbsent(parentId, () => []).add(category);
    }
    for (final children in tree.values) {
      children.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return tree;
  }

  /// 获取分类路径
  List<GalleryCategory> getPath(String categoryId) {
    final path = <GalleryCategory>[];
    String? currentId = categoryId;

    while (currentId != null) {
      final category = cast<GalleryCategory?>().firstWhere(
        (c) => c?.id == currentId,
        orElse: () => null,
      );
      if (category == null) break;
      path.insert(0, category);
      currentId = category.parentId;
    }

    return path;
  }

  /// 获取分类路径字符串
  String getPathString(String categoryId, {String separator = ' / '}) {
    try {
      return getPath(categoryId).map((c) => c.displayName).join(separator);
    } catch (_) {
      return '';
    }
  }

  /// 检查是否存在循环引用
  bool wouldCreateCycle(String categoryId, String? newParentId) {
    if (newParentId == null) return false;
    if (categoryId == newParentId) return true;

    String? currentId = newParentId;
    while (currentId != null) {
      if (currentId == categoryId) return true;
      final category = cast<GalleryCategory?>().firstWhere(
        (c) => c?.id == currentId,
        orElse: () => null,
      );
      currentId = category?.parentId;
    }

    return false;
  }

  /// 获取所有后代分类ID
  Set<String> getDescendantIds(String categoryId) {
    final descendants = <String>{};
    final queue = getChildren(categoryId).map((c) => c.id).toList();

    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      if (descendants.add(id)) {
        queue.addAll(getChildren(id).map((c) => c.id));
      }
    }

    return descendants;
  }

  /// 获取所有后代分类
  List<GalleryCategory> getDescendants(String categoryId) {
    final descendantIds = getDescendantIds(categoryId);
    return where((c) => descendantIds.contains(c.id)).toList();
  }

  /// 更新排序顺序
  List<GalleryCategory> reindex() {
    return asMap().entries
        .map(
          (e) => e.value.copyWith(sortOrder: e.key, updatedAt: DateTime.now()),
        )
        .toList();
  }

  /// 聚合图片数量：父节点 = 自身计数 + 所有后代计数之和（O(n)）。
  ///
  /// 入参各分类的 `imageCount` 视为「直系计数」（文件夹内不含子目录的图片数），
  /// 聚合后父节点口径与「选中后按路径前缀过滤的实际图数」一致。
  /// 实现：先按 parentId 建子节点索引，记忆化后序遍历累加（每个节点只算一次）；
  /// 环引用（异常数据）会被 visiting 标记截断，不无限递归。
  List<GalleryCategory> withAggregatedImageCounts() {
    final direct = {for (final c in this) c.id: c.imageCount};
    final childrenByParent = <String?, List<String>>{};
    for (final c in this) {
      childrenByParent.putIfAbsent(c.parentId, () => []).add(c.id);
    }

    final totals = <String, int>{};
    final visiting = <String>{};

    int aggregate(String id) {
      final cached = totals[id];
      if (cached != null) return cached;
      // 环截断：递归路径上重复出现的节点按直系计数收尾
      if (visiting.contains(id)) return direct[id] ?? 0;
      visiting.add(id);
      var total = direct[id] ?? 0;
      for (final childId in childrenByParent[id] ?? const <String>[]) {
        total += aggregate(childId);
      }
      visiting.remove(id);
      totals[id] = total;
      return total;
    }

    for (final c in this) {
      aggregate(c.id);
    }

    return [for (final c in this) c.updateImageCount(totals[c.id] ?? 0)];
  }

  /// 搜索分类
  List<GalleryCategory> search(String query) {
    if (query.isEmpty) return this;
    final lowerQuery = query.toLowerCase();
    return where((c) => c.name.toLowerCase().contains(lowerQuery)).toList();
  }

  /// 根据ID查找分类
  GalleryCategory? findById(String id) {
    try {
      return firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 获取分类的完整文件夹路径
  String? getFullFolderPath(String categoryId, String rootPath) {
    final category = findById(categoryId);
    if (category == null) return null;
    return '$rootPath/${category.folderPath}';
  }
}
