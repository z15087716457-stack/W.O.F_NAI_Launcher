import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../../core/utils/list_reorder.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/gallery/gallery_category.dart';
import '../../../data/models/gallery/image_collection.dart';
import '../../../data/models/gallery/local_image_record.dart';
import '../../providers/gallery_category_provider.dart'
    show collectionSelectedIdPrefix;
import '../common/themed_divider.dart';
import 'package:nai_launcher/presentation/widgets/common/themed_input.dart';
import 'gallery_scan_progress_panel.dart';
import '../../../core/storage/local_storage_service.dart';

String? galleryInternalDragPathFromLocalData(Object? localData) {
  if (localData is! Map) return null;

  final source = localData['source'];
  final path = localData['path'];
  if (source == 'gallery_internal' && path is String && path.isNotEmpty) {
    return path;
  }
  return null;
}

List<String>? galleryInternalDragPathsFromLocalData(Object? localData) {
  if (localData is! Map) return null;

  final source = localData['source'];
  if (source != 'gallery_internal') return null;

  final paths = localData['paths'];
  if (paths is List) {
    final list = paths.whereType<String>().where((p) => p.isNotEmpty).toList();
    if (list.isNotEmpty) return list;
  }

  final path = localData['path'];
  if (path is String && path.isNotEmpty) {
    return [path];
  }

  return null;
}

/// Gallery category tree view with drag-drop support
class GalleryCategoryTreeView extends StatefulWidget {
  final List<GalleryCategory> categories;
  final int totalImageCount;
  final int favoriteCount;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final void Function(String id, String newName)? onCategoryRename;
  final ValueChanged<String>? onCategoryDelete;
  final ValueChanged<String?>? onAddSubCategory;
  final void Function(String categoryId, String? newParentId)? onCategoryMove;
  final void Function(String? parentId, int oldIndex, int newIndex)?
  onCategoryReorder;
  final void Function(String imagePath, String? categoryId)? onImageDrop;
  final void Function(List<String> paths, String? categoryId)? onBatchImageDrop;
  final VoidCallback? onSyncWithFileSystem;

  /// 收藏集（渲染在「收藏」下方，'collection:<id>' 选中态；支持文件夹
  /// 无限嵌套，isFolder 节点为纯组织容器）
  final List<ImageCollection> collections;

  /// 新建收藏集/收藏文件夹（parentId=null 为收藏根级；isFolder 区分类型）
  final void Function(String? parentId, bool isFolder)? onCreateCollection;
  final void Function(String id, String newName)? onRenameCollection;
  final ValueChanged<String>? onDeleteCollection;
  final void Function(String? parentId, int oldIndex, int newIndex)?
  onCollectionReorder;
  final void Function(String id, String? newParentId)? onMoveCollection;

  const GalleryCategoryTreeView({
    super.key,
    required this.categories,
    required this.totalImageCount,
    this.favoriteCount = 0,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.onCategoryRename,
    this.onCategoryDelete,
    this.onAddSubCategory,
    this.onCategoryMove,
    this.onCategoryReorder,
    this.onImageDrop,
    this.onBatchImageDrop,
    this.onSyncWithFileSystem,
    this.collections = const [],
    this.onCreateCollection,
    this.onRenameCollection,
    this.onDeleteCollection,
    this.onCollectionReorder,
    this.onMoveCollection,
  });

  @override
  State<GalleryCategoryTreeView> createState() =>
      _GalleryCategoryTreeViewState();
}

class _GalleryCategoryTreeViewState extends State<GalleryCategoryTreeView> {
  final Set<String> _expandedIds = {};
  String? _hoveredCategoryId;
  Timer? _autoExpandTimer;

  @override
  void initState() {
    super.initState();
    // 恢复上次关闭时的展开状态（持久化记忆）
    _expandedIds.addAll(
      LocalStorageService().getGalleryCategoryTreeExpandedIds(),
    );
  }

  /// 展开状态持久化（分类与收藏集文件夹混存，id 命名空间不冲突）
  void _persistExpandedIds() {
    LocalStorageService().setGalleryCategoryTreeExpandedIds(
      _expandedIds.toList(),
    );
  }

  final Set<String> _superDraggingCategoryIds = {};

  @override
  void dispose() {
    _autoExpandTimer?.cancel();
    super.dispose();
  }

  void _startAutoExpandTimer(String categoryId) {
    _autoExpandTimer?.cancel();
    _autoExpandTimer = Timer(const Duration(milliseconds: 800), () {
      if (_hoveredCategoryId == categoryId && mounted) {
        setState(() => _expandedIds.add(categoryId));
        _persistExpandedIds();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onSecondaryTapUp: widget.onAddSubCategory != null
          ? (details) =>
                _showEmptyAreaContextMenu(context, details.globalPosition)
          : null,
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          // 分类树列表
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildImageDropTarget(
                  categoryId: null,
                  child: _CategoryItem(
                    icon: Icons.photo_library_outlined,
                    label: context.l10n.localGallery_allImages,
                    count: widget.totalImageCount,
                    isSelected: widget.selectedCategoryId == null,
                    onTap: () => widget.onCategorySelected(null),
                  ),
                ),
                _CategoryItem(
                  icon: widget.selectedCategoryId == 'favorites'
                      ? Icons.favorite
                      : Icons.favorite_border,
                  iconColor: Colors.red.shade400,
                  label: context.l10n.common_favorite,
                  count: widget.favoriteCount,
                  isSelected: widget.selectedCategoryId == 'favorites',
                  onTap: () => widget.onCategorySelected('favorites'),
                  onHoverAction: widget.onCreateCollection != null
                      ? () => _showCreateCollectionMenu(context, null)
                      : null,
                ),
                // 收藏集（「收藏」下方的缩进子条目，链接式成员）
                ..._buildCollectionItems(theme),
                if (widget.categories.isNotEmpty)
                  const ThemedDivider(height: 16, indent: 12, endIndent: 12),
                ..._buildRootCategoryEntries(theme),
              ],
            ),
          ),
          // 扫描进度面板（底部）
          const GalleryScanProgressPanel(),
        ],
      ),
    );
  }

  void _showEmptyAreaContextMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          onTap: () => widget.onAddSubCategory?.call(null),
          child: Row(
            children: [
              const Icon(Icons.create_new_folder, size: 18),
              const SizedBox(width: 8),
              Text(context.l10n.localGallery_createCategoryTitle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryNode(
    ThemeData theme,
    GalleryCategory category,
    int depth,
  ) {
    final children = widget.categories.getChildren(category.id).sortedByOrder();
    final hasChildren = children.isNotEmpty;
    final isExpanded = _expandedIds.contains(category.id);
    // 外部图库源分类只读：禁用重命名/删除/子分类/移动/移入
    final isReadOnly = category.isExternal;

    Widget categoryItem = _CategoryItem(
      icon: hasChildren
          ? (isExpanded ? Icons.folder_open : Icons.folder)
          : Icons.folder_outlined,
      label: category.displayName,
      count: category.imageCount,
      isSelected: widget.selectedCategoryId == category.id,
      depth: depth,
      hasChildren: hasChildren,
      isExpanded: isExpanded,
      onTap: () => widget.onCategorySelected(category.id),
      onExpand: hasChildren
          ? () {
              setState(() {
                if (isExpanded) {
                  _expandedIds.remove(category.id);
                } else {
                  _expandedIds.add(category.id);
                }
              });
              _persistExpandedIds();
            }
          : null,
      onRename: !isReadOnly && widget.onCategoryRename != null
          ? (newName) => widget.onCategoryRename!(category.id, newName)
          : null,
      onDelete: !isReadOnly && widget.onCategoryDelete != null
          ? () => widget.onCategoryDelete!(category.id)
          : null,
      onAddSubCategory: !isReadOnly && widget.onAddSubCategory != null
          ? () => widget.onAddSubCategory!(category.id)
          : null,
      onMoveToRoot:
          !isReadOnly &&
              category.parentId != null &&
              widget.onCategoryMove != null
          ? () => widget.onCategoryMove!(category.id, null)
          : null,
      // 拖拽小点：根级条目（含外部图源，用于同级排序）或可移动的内部分类
      showDragHandle: _isDraggableCategory(category, isReadOnly),
    );

    if (_isDraggableCategory(category, isReadOnly)) {
      categoryItem = _buildDraggableCategory(category, categoryItem);
    }

    if (!isReadOnly && widget.onCategoryMove != null) {
      categoryItem = _buildCategoryDragTarget(theme, category, categoryItem);
    }

    // 外部分类也接收图片移入（反向放开）
    categoryItem = _buildImageDropTarget(
      categoryId: category.id,
      child: categoryItem,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        categoryItem,
        if (hasChildren && isExpanded)
          ...children.map(
            (child) => _buildCategoryNode(theme, child, depth + 1),
          ),
      ],
    );
  }

  /// 根级条目是否可拖拽：根级（含外部图源，同级排序）或可移动的内部分类
  bool _isDraggableCategory(GalleryCategory category, bool isReadOnly) {
    if (category.parentId == null && widget.onCategoryReorder != null) {
      return true;
    }
    return !isReadOnly && widget.onCategoryMove != null;
  }

  /// 根级分类条目（条目间穿插插入条，支持同级拖拽排序）
  List<Widget> _buildRootCategoryEntries(ThemeData theme) {
    final roots = widget.categories.rootCategories.sortedByOrder();
    final entries = <Widget>[];

    for (var i = 0; i < roots.length; i++) {
      if (widget.onCategoryReorder != null) {
        entries.add(
          _buildInsertStrip<GalleryCategory>(
            canAccept: (dragged) =>
                dragged.parentId == null && dragged.id != roots[i].id,
            onAccept: (dragged) =>
                _handleRootReorder(roots, dragged, i, insertAfter: false),
          ),
        );
      }
      entries.add(_buildCategoryNode(theme, roots[i], 0));
    }

    // 末尾插入条：允许拖到列表最后
    if (widget.onCategoryReorder != null && roots.isNotEmpty) {
      entries.add(
        _buildInsertStrip<GalleryCategory>(
          canAccept: (dragged) => dragged.parentId == null,
          onAccept: (dragged) => _handleRootReorder(
            roots,
            dragged,
            roots.length - 1,
            insertAfter: true,
          ),
        ),
      );
    }

    return entries;
  }

  /// 收藏区条目（树形：文件夹可无限嵌套，同父级内插入条排序）
  List<Widget> _buildCollectionItems(ThemeData theme) {
    return _buildCollectionChildren(theme, null, 1);
  }

  /// 渲染某父级（null=收藏根级平铺）下的收藏子树
  List<Widget> _buildCollectionChildren(
    ThemeData theme,
    String? parentId,
    int depth,
  ) {
    final siblings = widget.collections
        .where((c) => c.parentId == parentId)
        .toList();
    final items = <Widget>[];

    for (var i = 0; i < siblings.length; i++) {
      final node = siblings[i];
      if (widget.onCollectionReorder != null) {
        items.add(
          _buildInsertStrip<ImageCollection>(
            canAccept: (dragged) =>
                dragged.parentId == parentId && dragged.id != node.id,
            onAccept: (dragged) => _handleCollectionReorder(
              parentId,
              siblings,
              dragged,
              i,
              insertAfter: false,
            ),
          ),
        );
      }
      items.add(
        node.isFolder
            ? _buildCollectionFolderNode(theme, node, depth)
            : _buildCollectionRow(theme, node, depth),
      );
    }

    // 末尾插入条：允许拖到该父级列表最后
    if (widget.onCollectionReorder != null && siblings.isNotEmpty) {
      items.add(
        _buildInsertStrip<ImageCollection>(
          canAccept: (dragged) => dragged.parentId == parentId,
          onAccept: (dragged) => _handleCollectionReorder(
            parentId,
            siblings,
            dragged,
            siblings.length - 1,
            insertAfter: true,
          ),
        ),
      );
    }

    return items;
  }

  /// 收藏文件夹节点（展开/收起子树 + 拖入移入 + 递归并集计数）
  Widget _buildCollectionFolderNode(
    ThemeData theme,
    ImageCollection folder,
    int depth,
  ) {
    final selectedId = '$collectionSelectedIdPrefix${folder.id}';
    final hasChildren = widget.collections.any((c) => c.parentId == folder.id);
    final isExpanded = _expandedIds.contains(folder.id);

    Widget row = _CategoryItem(
      icon: hasChildren
          ? (isExpanded ? Icons.folder_open : Icons.folder)
          : Icons.folder_outlined,
      iconColor: Colors.amber.shade700,
      label: folder.name,
      count: folder.imageCount,
      depth: depth,
      hasChildren: hasChildren,
      isExpanded: isExpanded,
      isSelected: widget.selectedCategoryId == selectedId,
      onTap: () => widget.onCategorySelected(selectedId),
      onExpand: hasChildren
          ? () {
              setState(() {
                if (isExpanded) {
                  _expandedIds.remove(folder.id);
                } else {
                  _expandedIds.add(folder.id);
                }
              });
              _persistExpandedIds();
            }
          : null,
      onRename: widget.onRenameCollection != null
          ? (newName) => widget.onRenameCollection!(folder.id, newName)
          : null,
      onAddSubCollection: widget.onCreateCollection != null
          ? () => widget.onCreateCollection!(folder.id, false)
          : null,
      onAddSubFolder: widget.onCreateCollection != null
          ? () => widget.onCreateCollection!(folder.id, true)
          : null,
      onMoveToRoot: folder.parentId != null && widget.onMoveCollection != null
          ? () => widget.onMoveCollection!(folder.id, null)
          : null,
      onDelete: widget.onDeleteCollection != null
          ? () => widget.onDeleteCollection!(folder.id)
          : null,
      showDragHandle:
          widget.onCollectionReorder != null || widget.onMoveCollection != null,
    );

    row = _buildDraggableCollection(theme, folder, row);
    row = _buildCollectionFolderDragTarget(theme, folder, row);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        if (hasChildren && isExpanded)
          ..._buildCollectionChildren(theme, folder.id, depth + 1),
      ],
    );
  }

  Widget _buildCollectionRow(
    ThemeData theme,
    ImageCollection collection,
    int depth,
  ) {
    final selectedId = '$collectionSelectedIdPrefix${collection.id}';

    final row = _CategoryItem(
      icon: Icons.collections_bookmark,
      iconColor: Colors.amber.shade700,
      label: collection.name,
      count: collection.imageCount,
      depth: depth,
      isSelected: widget.selectedCategoryId == selectedId,
      onTap: () => widget.onCategorySelected(selectedId),
      onRename: widget.onRenameCollection != null
          ? (newName) => widget.onRenameCollection!(collection.id, newName)
          : null,
      onMoveToRoot:
          collection.parentId != null && widget.onMoveCollection != null
          ? () => widget.onMoveCollection!(collection.id, null)
          : null,
      onDelete: widget.onDeleteCollection != null
          ? () => widget.onDeleteCollection!(collection.id)
          : null,
      showDragHandle: widget.onCollectionReorder != null,
    );

    return _buildDraggableCollection(theme, collection, row);
  }

  /// 收藏集/文件夹的拖拽包装（拖出本体）
  Widget _buildDraggableCollection(
    ThemeData theme,
    ImageCollection node,
    Widget child,
  ) {
    return Draggable<ImageCollection>(
      data: node,
      feedback: _buildDragFeedback(
        theme,
        icon: node.isFolder ? Icons.folder : Icons.collections_bookmark,
        label: node.name,
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: child),
      onDragStarted: () => HapticFeedback.mediumImpact(),
      onDragEnd: (_) {
        _autoExpandTimer?.cancel();
        setState(() => _hoveredCategoryId = null);
      },
      child: child,
    );
  }

  /// 文件夹节点作为拖入目标（接收收藏集/文件夹移入）
  ///
  /// 拒绝自身、已是直接子项的节点、以及会造成环的移动。
  Widget _buildCollectionFolderDragTarget(
    ThemeData theme,
    ImageCollection folder,
    Widget child,
  ) {
    return DragTarget<ImageCollection>(
      onWillAcceptWithDetails: (details) {
        final dragged = details.data;
        if (dragged.id == folder.id) return false;
        if (dragged.parentId == folder.id) return false;
        if (_wouldCreateCollectionCycle(dragged.id, folder.id)) return false;
        return true;
      },
      onAcceptWithDetails: (details) {
        HapticFeedback.heavyImpact();
        widget.onMoveCollection?.call(details.data.id, folder.id);
        setState(() {
          _expandedIds.add(folder.id);
          _hoveredCategoryId = null;
        });
        _persistExpandedIds();
        _autoExpandTimer?.cancel();
      },
      onMove: (details) {
        if (_hoveredCategoryId != folder.id) {
          setState(() => _hoveredCategoryId = folder.id);
          final hasChildren = widget.collections.any(
            (c) => c.parentId == folder.id,
          );
          if (hasChildren && !_expandedIds.contains(folder.id)) {
            _startAutoExpandTimer(folder.id);
          }
        }
      },
      onLeave: (_) {
        if (_hoveredCategoryId == folder.id) {
          setState(() => _hoveredCategoryId = null);
          _autoExpandTimer?.cancel();
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isAccepting = candidateData.isNotEmpty;
        final isRejected = rejectedData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isAccepting
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            border: isAccepting
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : isRejected
                ? Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                    width: 1,
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
      },
    );
  }

  /// 把节点移到 [newParentId] 下是否会成环（新父的祖先链含被移节点）
  bool _wouldCreateCollectionCycle(String draggedId, String newParentId) {
    final byId = {for (final c in widget.collections) c.id: c};
    var current = byId[newParentId];
    while (current != null) {
      if (current.id == draggedId) return true;
      current = byId[current.parentId];
    }
    return false;
  }

  void _handleRootReorder(
    List<GalleryCategory> roots,
    GalleryCategory dragged,
    int targetIndex, {
    required bool insertAfter,
  }) {
    final oldIndex = roots.indexWhere((c) => c.id == dragged.id);
    if (oldIndex < 0) return;

    final newIndex = computeReorderInsertIndex(
      oldIndex: oldIndex,
      targetIndex: targetIndex,
      insertAfter: insertAfter,
    );
    if (newIndex == oldIndex) return;

    widget.onCategoryReorder?.call(null, oldIndex, newIndex);
  }

  void _handleCollectionReorder(
    String? parentId,
    List<ImageCollection> siblings,
    ImageCollection dragged,
    int targetIndex, {
    required bool insertAfter,
  }) {
    final oldIndex = siblings.indexWhere((c) => c.id == dragged.id);
    if (oldIndex < 0) return;

    final newIndex = computeReorderInsertIndex(
      oldIndex: oldIndex,
      targetIndex: targetIndex,
      insertAfter: insertAfter,
    );
    if (newIndex == oldIndex) return;

    widget.onCollectionReorder?.call(parentId, oldIndex, newIndex);
  }

  /// 「收藏」行 + 按钮弹出菜单：新建收藏集 / 新建收藏文件夹
  void _showCreateCollectionMenu(BuildContext context, String? parentId) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        200,
        120,
        MediaQuery.of(context).size.width - 200,
        MediaQuery.of(context).size.height - 120,
      ),
      items: [
        PopupMenuItem(
          onTap: () => widget.onCreateCollection?.call(parentId, false),
          child: Row(
            children: [
              const Icon(Icons.add, size: 18),
              const SizedBox(width: 8),
              Text(context.l10n.localGallery_createCollectionTitle),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => widget.onCreateCollection?.call(parentId, true),
          child: Row(
            children: [
              const Icon(Icons.create_new_folder, size: 18),
              const SizedBox(width: 8),
              Text(context.l10n.localGallery_createCollectionFolderTitle),
            ],
          ),
        ),
      ],
    );
  }

  /// 条目间插入条：悬停显示主题色细线，松开完成同级插入
  Widget _buildInsertStrip<T extends Object>({
    required bool Function(T data) canAccept,
    required void Function(T data) onAccept,
  }) {
    return DragTarget<T>(
      onWillAcceptWithDetails: (details) => canAccept(details.data),
      onAcceptWithDetails: (details) {
        HapticFeedback.mediumImpact();
        onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        final theme = Theme.of(context);
        return SizedBox(
          height: 6,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: isActive ? 3 : 0,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragFeedback(
    ThemeData theme, {
    required IconData icon,
    required String label,
  }) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableCategory(GalleryCategory category, Widget child) {
    final theme = Theme.of(context);

    return Draggable<GalleryCategory>(
      data: category,
      feedback: _buildDragFeedback(
        theme,
        icon: Icons.folder,
        label: category.displayName,
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: child),
      onDragStarted: () => HapticFeedback.mediumImpact(),
      onDragEnd: (_) {
        _autoExpandTimer?.cancel();
        setState(() => _hoveredCategoryId = null);
      },
      child: child,
    );
  }

  Widget _buildCategoryDragTarget(
    ThemeData theme,
    GalleryCategory targetCategory,
    Widget child,
  ) {
    return DragTarget<GalleryCategory>(
      onWillAcceptWithDetails: (details) {
        final draggedCategory = details.data;
        if (draggedCategory.id == targetCategory.id) return false;
        if (widget.categories.wouldCreateCycle(
          draggedCategory.id,
          targetCategory.id,
        )) {
          return false;
        }
        if (draggedCategory.parentId == targetCategory.id) return false;
        return true;
      },
      onAcceptWithDetails: (details) {
        HapticFeedback.heavyImpact();
        widget.onCategoryMove?.call(details.data.id, targetCategory.id);
        setState(() {
          _expandedIds.add(targetCategory.id);
          _hoveredCategoryId = null;
        });
        _persistExpandedIds();
        _autoExpandTimer?.cancel();
      },
      onMove: (details) {
        if (_hoveredCategoryId != targetCategory.id) {
          setState(() => _hoveredCategoryId = targetCategory.id);
          final hasChildren = widget.categories
              .getChildren(targetCategory.id)
              .isNotEmpty;
          if (hasChildren && !_expandedIds.contains(targetCategory.id)) {
            _startAutoExpandTimer(targetCategory.id);
          }
        }
      },
      onLeave: (_) {
        if (_hoveredCategoryId == targetCategory.id) {
          setState(() => _hoveredCategoryId = null);
          _autoExpandTimer?.cancel();
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isAccepting = candidateData.isNotEmpty;
        final isRejected = rejectedData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isAccepting
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            border: isAccepting
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : isRejected
                ? Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                    width: 1,
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildImageDropTarget({
    required String? categoryId,
    required Widget child,
  }) {
    if (widget.onImageDrop == null) return child;

    // 构建 DragTarget 用于 Flutter 原生拖拽
    final dragTarget = DragTarget<LocalImageRecord>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        HapticFeedback.heavyImpact();
        widget.onImageDrop?.call(details.data.path, categoryId);
      },
      builder: (context, candidateData, rejectedData) {
        final isAccepting = candidateData.isNotEmpty;
        final isSuperDragging = _superDraggingCategoryIds.contains(
          categoryId ?? '__root__',
        );
        final showDropEffect = isAccepting || isSuperDragging;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: showDropEffect
                ? LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.15),
                      Colors.green.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            border: showDropEffect
                ? const Border(left: BorderSide(color: Colors.green, width: 4))
                : null,
            borderRadius: showDropEffect ? BorderRadius.circular(8) : null,
          ),
          child: child,
        );
      },
    );

    // 使用 DropRegion 包裹 DragTarget，支持 super_drag_and_drop 跨应用拖拽
    return DropRegion(
      formats: const [Formats.fileUri],
      onDropOver: (event) {
        if (event.session.allowedOperations.contains(DropOperation.copy)) {
          final key = categoryId ?? '__root__';
          if (!_superDraggingCategoryIds.contains(key)) {
            setState(() => _superDraggingCategoryIds.add(key));
          }
          return DropOperation.copy;
        }
        return DropOperation.none;
      },
      onDropLeave: (event) {
        final key = categoryId ?? '__root__';
        if (_superDraggingCategoryIds.contains(key)) {
          setState(() => _superDraggingCategoryIds.remove(key));
        }
      },
      onPerformDrop: (event) async {
        final key = categoryId ?? '__root__';
        if (_superDraggingCategoryIds.contains(key)) {
          setState(() => _superDraggingCategoryIds.remove(key));
        }

        // 处理拖拽的文件
        for (final item in event.session.items) {
          final internalPaths = galleryInternalDragPathsFromLocalData(
            item.localData,
          );
          if (internalPaths != null && internalPaths.isNotEmpty) {
            HapticFeedback.heavyImpact();
            if (internalPaths.length > 1 && widget.onBatchImageDrop != null) {
              widget.onBatchImageDrop!(internalPaths, categoryId);
            } else {
              for (final path in internalPaths) {
                widget.onImageDrop?.call(path, categoryId);
              }
            }
            continue;
          }

          final reader = item.dataReader;
          if (reader == null) continue;

          // 读取文件 URI
          if (reader.canProvide(Formats.fileUri)) {
            final filePath = await _getFilePathFromUri(reader);
            if (filePath != null) {
              HapticFeedback.heavyImpact();
              widget.onImageDrop?.call(filePath, categoryId);
            }
          }
        }
      },
      child: dragTarget,
    );
  }

  /// 从 DataReader 中提取文件路径
  Future<String?> _getFilePathFromUri(DataReader reader) async {
    final completer = Completer<String?>();

    final progress = reader.getValue(
      Formats.fileUri,
      (uri) {
        if (!completer.isCompleted) {
          if (uri == null) {
            completer.complete(null);
            return;
          }
          try {
            final filePath = uri.toFilePath();
            completer.complete(filePath);
          } catch (e) {
            completer.complete(null);
          }
        }
      },
      onError: (e) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );

    if (progress == null) {
      return null;
    }

    // 添加超时保护
    try {
      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
    } catch (e) {
      return null;
    }
  }
}

class _CategoryItem extends StatefulWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final int count;
  final bool isSelected;
  final int depth;
  final bool hasChildren;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onExpand;
  final void Function(String)? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onAddSubCategory;
  final VoidCallback? onAddSubCollection;
  final VoidCallback? onAddSubFolder;
  final VoidCallback? onMoveToRoot;

  /// 是否显示拖拽小点（悬停时；与 onRename 解耦，外部图源根级排序也显示）
  final bool showDragHandle;

  /// 悬停时显示的快捷操作（如「收藏」行的 + 按钮）
  final VoidCallback? onHoverAction;

  const _CategoryItem({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.count,
    required this.isSelected,
    this.depth = 0,
    this.hasChildren = false,
    this.isExpanded = false,
    required this.onTap,
    this.onExpand,
    this.onRename,
    this.onDelete,
    this.onAddSubCategory,
    this.onAddSubCollection,
    this.onAddSubFolder,
    this.onMoveToRoot,
    this.showDragHandle = false,
    this.onHoverAction,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _isHovering = false;
  bool _isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.label);
  }

  @override
  void didUpdateWidget(covariant _CategoryItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label && !_isEditing) {
      _editController.text = widget.label;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indent = 12.0 + widget.depth * 16.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onSecondaryTapUp: widget.onRename != null
            ? (details) => _showContextMenu(context, details.globalPosition)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? theme.colorScheme.primaryContainer
                : (_isHovering
                      ? theme.colorScheme.surfaceContainerHighest
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.only(
                left: indent,
                right: 8,
                top: 8,
                bottom: 8,
              ),
              child: Row(
                children: [
                  if (widget.hasChildren)
                    GestureDetector(
                      onTap: widget.onExpand,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          widget.isExpanded
                              ? Icons.expand_more
                              : Icons.chevron_right,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 20),
                  Icon(
                    widget.icon,
                    size: 18,
                    color:
                        widget.iconColor ??
                        (widget.isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isEditing
                        ? ThemedInput(
                            controller: _editController,
                            autofocus: true,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                widget.onRename?.call(value.trim());
                              }
                              setState(() => _isEditing = false);
                            },
                            onTapOutside: (_) =>
                                setState(() => _isEditing = false),
                          )
                        : Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: widget.isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: widget.isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  if (_isHovering && widget.onHoverAction != null)
                    InkWell(
                      onTap: widget.onHoverAction,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.add,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  if (_isHovering && widget.showDragHandle)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.drag_indicator,
                        size: 14,
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                  Text(
                    widget.count.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        if (widget.onRename != null)
          PopupMenuItem(
            onTap: () => Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) setState(() => _isEditing = true);
            }),
            child: Row(
              children: [
                const Icon(Icons.edit, size: 18),
                const SizedBox(width: 8),
                Text(context.l10n.common_rename),
              ],
            ),
          ),
        if (widget.onAddSubCategory != null)
          PopupMenuItem(
            onTap: widget.onAddSubCategory,
            child: Row(
              children: [
                const Icon(Icons.create_new_folder, size: 18),
                const SizedBox(width: 8),
                Text(context.l10n.localGallery_createSubCategoryTitle),
              ],
            ),
          ),
        if (widget.onAddSubCollection != null)
          PopupMenuItem(
            onTap: widget.onAddSubCollection,
            child: Row(
              children: [
                const Icon(Icons.add, size: 18),
                const SizedBox(width: 8),
                Text(context.l10n.localGallery_createCollectionTitle),
              ],
            ),
          ),
        if (widget.onAddSubFolder != null)
          PopupMenuItem(
            onTap: widget.onAddSubFolder,
            child: Row(
              children: [
                const Icon(Icons.create_new_folder, size: 18),
                const SizedBox(width: 8),
                Text(context.l10n.localGallery_createCollectionFolderTitle),
              ],
            ),
          ),
        if (widget.onMoveToRoot != null)
          PopupMenuItem(
            onTap: widget.onMoveToRoot,
            child: Row(
              children: [
                const Icon(Icons.drive_file_move_outline, size: 18),
                const SizedBox(width: 8),
                Text(context.l10n.localGallery_moveToRoot),
              ],
            ),
          ),
        if (widget.onDelete != null)
          PopupMenuItem(
            onTap: widget.onDelete,
            child: Row(
              children: [
                Icon(
                  Icons.delete,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.common_delete,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
