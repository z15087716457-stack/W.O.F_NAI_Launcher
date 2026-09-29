import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../../data/models/prompt_block/prompt_block_collection.dart';
import '../../../../data/models/prompt_block/prompt_block_folder.dart';
import '../../../widgets/prompt/blocks/prompt_block_drag_data.dart';
import '../../../providers/prompt_block_library_provider.dart';

/// 块库侧栏：上区 = 固定行（全部块/根目录/收藏）+ 收藏集树（独立滚动），
/// 下区 = 普通文件夹树（独立滚动），中间手柄可上下拖动调高度并持久化。
///
/// 收藏集树与画廊收藏区同构：收藏集（装成员）与收藏文件夹（纯组织容器，
/// 可无限嵌套）混合排序；同级拖把手重排，拖到收藏文件夹行上移入，
/// 拖到「收藏」行移回根级；块（[PromptBlockDragData]）拖到收藏集行上
/// = 直接收进该集，拖到「收藏」行 = 标记收藏。
class PromptBlockFolderTree extends StatefulWidget {
  const PromptBlockFolderTree({
    super.key,
    required this.blocks,
    required this.folders,
    this.collections = const [],
    required this.allSelected,
    required this.rootSelected,
    this.favoritesSelected = false,
    required this.selectedFolderId,
    this.selectedCollectionId,
    required this.onSelectAll,
    required this.onSelectRoot,
    this.onSelectFavorites,
    required this.onSelectFolder,
    this.onSelectCollection,
    required this.onCreateFolder,
    required this.onRenameFolder,
    required this.onMoveFolderToRoot,
    required this.onDeleteFolder,
    required this.onReorderFolders,
    this.onCreateCollection,
    this.onRenameCollection,
    this.onMoveCollection,
    this.onDeleteCollection,
    this.onReorderCollections,
    this.onAddBlockToCollection,
    this.onDropBlockOnFavorites,
    this.onDropBlocks,
  });

  final List<PromptBlock> blocks;
  final List<PromptBlockFolder> folders;
  final List<PromptBlockCollection> collections;
  final bool allSelected;
  final bool rootSelected;
  final bool favoritesSelected;
  final String? selectedFolderId;
  final String? selectedCollectionId;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectRoot;
  final VoidCallback? onSelectFavorites;
  final ValueChanged<String> onSelectFolder;
  final ValueChanged<String>? onSelectCollection;
  final ValueChanged<String?> onCreateFolder;
  final ValueChanged<String> onRenameFolder;
  final ValueChanged<String> onMoveFolderToRoot;
  final ValueChanged<String> onDeleteFolder;
  final void Function(String? parentId, List<String> orderedIds)
  onReorderFolders;

  /// 新建收藏集（[isFolder]=false）/ 收藏文件夹（=true）；
  /// [parentId]=null 为收藏区根级。
  final void Function(String? parentId, bool isFolder)? onCreateCollection;
  final ValueChanged<String>? onRenameCollection;

  /// 移动收藏集/收藏文件夹到新父级（null=收藏区根级）。
  final void Function(String id, String? newParentId)? onMoveCollection;
  final ValueChanged<String>? onDeleteCollection;
  final void Function(String? parentId, List<String> orderedIds)?
  onReorderCollections;

  /// 块拖入收藏集（成员追加 + 自动收藏）。
  final void Function(String collectionId, String blockId)?
  onAddBlockToCollection;

  /// 块拖到「收藏」行 = 标记收藏。
  final ValueChanged<String>? onDropBlockOnFavorites;

  /// 释放后由宿主在光标处提供复制 / 移动选项。
  final void Function(
    PromptBlockDragData data,
    PromptBlockTransferTarget target,
    Offset offset,
  )?
  onDropBlocks;

  @override
  State<PromptBlockFolderTree> createState() => _PromptBlockFolderTreeState();
}

class _PromptBlockFolderTreeState extends State<PromptBlockFolderTree> {
  final Set<String> _expandedIds = <String>{};
  double _splitRatio = 0.4;
  double _dragStartRatio = 0.4;
  double _dragStartGlobalY = 0.0;

  @override
  void initState() {
    super.initState();
    _splitRatio = LocalStorageService().getPromptBlockSidebarFavoritesSplit();
  }

  void _persistSplitRatio() {
    LocalStorageService().setPromptBlockSidebarFavoritesSplit(_splitRatio);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        // 极矮空间降级：固定行+手柄已超出可用高度时，合并为单一滚动列表，
        // 避免 Column 溢出（生成页面板拖拽压缩树区时会触发）。
        if (totalHeight.isFinite &&
            totalHeight < _kFixedRowsHeight + _kHandleHeight + 48) {
          return ListView(
            key: const Key('prompt-block-folder-tree'),
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              ..._fixedRows(context, theme),
              if (widget.collections.isEmpty)
                _buildEmptyPaneHint(
                  theme,
                  context.l10n.promptBlockLibrary_noCollections,
                  indent: 1,
                )
              else
                _buildCollectionList(
                  context,
                  theme,
                  parentId: null,
                  nodes: widget.collections.childrenOf(null),
                  depth: 1,
                  key: const Key('prompt-block-collection-root-reorder'),
                ),
              if (widget.folders.isEmpty)
                _buildEmptyPaneHint(
                  theme,
                  context.l10n.promptBlockLibrary_noFolders,
                )
              else
                _buildFolderList(
                  context,
                  theme,
                  parentId: null,
                  folders: widget.folders.childrenOf(null),
                  depth: 0,
                  key: const Key('prompt-block-root-folder-reorder'),
                ),
            ],
          );
        }
        final topFlex = (_splitRatio * 1000).round().clamp(1, 999);
        final bottomFlex = ((1.0 - _splitRatio) * 1000).round().clamp(1, 999);
        // 分割区高度 = 总高 - 固定三行 - 手柄；拖动位移按它换算比例才跟手。
        final splitHeight = totalHeight - _kFixedRowsHeight - _kHandleHeight;
        return Column(
          key: const Key('prompt-block-folder-tree'),
          children: [
            // 固定三行钉在分割区外（同画廊侧栏结构），不参与比例分配，
            // 两个 Expanded 只装可滚动列表，可安全压到 0。
            ..._fixedRows(context, theme),
            // 上区：收藏集列表独立滚动
            Expanded(flex: topFlex, child: _buildFavoritesPane(context, theme)),
            _SidebarResizeHandle(
              key: const Key('prompt-block-sidebar-resize-handle'),
              onVerticalDragStart: (details) {
                _dragStartRatio = _splitRatio;
                _dragStartGlobalY = details.globalPosition.dy;
              },
              onVerticalDragUpdate: (details) {
                if (splitHeight.isFinite && splitHeight > 0) {
                  final dy = details.globalPosition.dy - _dragStartGlobalY;
                  // 上下区各留一行像素下限，比例界限随可用高度换算。
                  final minRatio = (_kMinTopPaneHeight / splitHeight).clamp(
                    0.0,
                    0.5,
                  );
                  final maxRatio = (1 - _kMinBottomPaneHeight / splitHeight)
                      .clamp(0.5, 1.0);
                  final newRatio = minRatio <= maxRatio
                      ? (_dragStartRatio + dy / splitHeight).clamp(
                          minRatio,
                          maxRatio,
                        )
                      : 0.5;
                  if (newRatio != _splitRatio) {
                    setState(() => _splitRatio = newRatio);
                  }
                }
              },
              onVerticalDragEnd: (_) => _persistSplitRatio(),
              onVerticalDragCancel: _persistSplitRatio,
            ),
            // 下区：普通文件夹树（独立滚动）
            Expanded(
              flex: bottomFlex,
              child: _buildFoldersPane(context, theme),
            ),
          ],
        );
      },
    );
  }

  /// 固定三行 + 顶部间距的近似高度（8 + 3×~36）。
  static const double _kFixedRowsHeight = 116;

  /// 分割手柄高度（与 _SidebarResizeHandle 保持一致）。
  static const double _kHandleHeight = 10;

  /// 上区最小像素高度（≈ 一行提示/一行收藏集）。
  static const double _kMinTopPaneHeight = 44;

  /// 下区最小像素高度。
  static const double _kMinBottomPaneHeight = 80;

  // ==================== 上区：收藏集树 ====================

  /// 固定三行（全部块/根目录/收藏），双区与降级单列表共用。
  List<Widget> _fixedRows(BuildContext context, ThemeData theme) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _buildSpecialItem(
          context,
          theme,
          icon: Icons.all_inclusive,
          label: context.l10n.promptBlockLibrary_allBlocks,
          count: widget.blocks.length,
          selected: widget.allSelected,
          onTap: widget.onSelectAll,
        ),
      ),
      _blockDropTarget(
        theme,
        const PromptBlockTransferTarget(PromptBlockTransferKind.folder),
        _buildSpecialItem(
          context,
          theme,
          icon: Icons.folder_outlined,
          label: context.l10n.promptBlockLibrary_rootFolder,
          count: widget.blocks.where((block) => block.folderId == null).length,
          selected: widget.rootSelected,
          onTap: widget.onSelectRoot,
        ),
      ),
      _buildFavoritesRow(context, theme),
    ];
  }

  Widget _buildFavoritesPane(BuildContext context, ThemeData theme) {
    if (widget.collections.isEmpty) {
      return _buildEmptyPaneHint(
        theme,
        context.l10n.promptBlockLibrary_noCollections,
        indent: 1,
      );
    }
    return ListView(
      key: const Key('prompt-block-collection-list'),
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        _buildCollectionList(
          context,
          theme,
          parentId: null,
          nodes: widget.collections.childrenOf(null),
          depth: 1,
          key: const Key('prompt-block-collection-root-reorder'),
        ),
      ],
    );
  }

  /// 「⭐收藏」行：点击过滤收藏块；尾部 + 出新建菜单；
  /// 接收块拖入 = 标记收藏；接收收藏节点拖入 = 移回根级。
  Widget _buildFavoritesRow(BuildContext context, ThemeData theme) {
    Widget row = _FolderTreeRow(
      icon: widget.favoritesSelected ? Icons.star : Icons.star_border,
      iconColor: Colors.amber.shade700,
      label: context.l10n.common_favorite,
      count: widget.blocks.where((block) => block.isFavorite).length,
      selected: widget.favoritesSelected,
      indent: 0,
      onTap: widget.onSelectFavorites ?? () {},
      onSecondaryTapUp: widget.onCreateCollection == null
          ? null
          : (details) => _showCreateCollectionMenu(
              context,
              null,
              details.globalPosition,
            ),
      onAdd: widget.onCreateCollection == null
          ? null
          : () => _showCreateCollectionMenu(context, null, null),
    );

    final baseRow = row;
    row = _blockDropTarget(
      theme,
      const PromptBlockTransferTarget(PromptBlockTransferKind.favorites),
      baseRow,
      fallback: (id) => widget.onDropBlockOnFavorites?.call(id),
    );
    final wrappedRow = row;
    row = DragTarget<PromptBlockCollection>(
      onWillAcceptWithDetails: (details) =>
          widget.onMoveCollection != null && details.data.parentId != null,
      onAcceptWithDetails: (details) =>
          widget.onMoveCollection?.call(details.data.id, null),
      builder: (context, candidateData, rejectedData) =>
          _dropHighlight(theme, wrappedRow, candidateData.isNotEmpty),
    );
    return row;
  }

  /// 空区提示：收藏区/文件夹区无内容时给一句引导。
  /// 分区内垂直居中（内容超高时仍可滚动）；降级单列表高度无界，
  /// 直接按内容排版交给外层 ListView 滚动。
  Widget _buildEmptyPaneHint(
    ThemeData theme,
    String message, {
    int indent = 0,
  }) {
    final text = Padding(
      padding: EdgeInsets.only(
        left: 20.0 + indent * 16,
        right: 20,
        top: 14,
        bottom: 14,
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) return text;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: text),
          ),
        );
      },
    );
  }

  /// 拖拽悬停时给行加高亮描边/底色。
  Widget _dropHighlight(ThemeData theme, Widget child, bool accepting) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: accepting
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        border: accepting
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              )
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  Widget _blockDropTarget(
    ThemeData theme,
    PromptBlockTransferTarget target,
    Widget child, {
    ValueChanged<String>? fallback,
  }) {
    return DragTarget<PromptBlockDragData>(
      onWillAcceptWithDetails: (details) =>
          details.data.blockId.isNotEmpty &&
          (widget.onDropBlocks != null || fallback != null),
      onAcceptWithDetails: (details) {
        HapticFeedback.mediumImpact();
        if (widget.onDropBlocks != null) {
          widget.onDropBlocks!(details.data, target, details.offset);
        } else {
          fallback?.call(details.data.blockId);
        }
      },
      builder: (context, candidateData, rejectedData) =>
          _dropHighlight(theme, child, candidateData.isNotEmpty),
    );
  }

  // ==================== 收藏集树 ====================

  /// 「收藏」行 + 按钮/右键弹出菜单：新建收藏集 / 新建收藏文件夹。
  void _showCreateCollectionMenu(
    BuildContext context,
    String? parentId,
    Offset? globalPosition,
  ) {
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) return;
    final position = globalPosition == null
        ? RelativeRect.fromLTRB(
            200,
            140,
            MediaQuery.of(context).size.width - 200,
            MediaQuery.of(context).size.height - 140,
          )
        : RelativeRect.fromRect(
            Rect.fromPoints(globalPosition, globalPosition),
            Offset.zero & overlay.size,
          );
    showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          onTap: () => widget.onCreateCollection?.call(parentId, false),
          child: Row(
            children: [
              const Icon(Icons.collections_bookmark_outlined, size: 18),
              const SizedBox(width: 8),
              Text(context.l10n.promptBlockLibrary_newCollection),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => widget.onCreateCollection?.call(parentId, true),
          child: Row(
            children: [
              const Icon(Icons.create_new_folder_outlined, size: 18),
              const SizedBox(width: 8),
              Text(context.l10n.promptBlockLibrary_newCollectionFolder),
            ],
          ),
        ),
      ],
    );
  }

  /// 收藏节点右键菜单：文件夹多出「新建子收藏集/子文件夹」两项。
  void _showCollectionMenu(PromptBlockCollection node, Offset globalPosition) {
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) return;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition),
      Offset.zero & overlay.size,
    );
    showMenu<_CollectionAction>(
      context: context,
      position: position,
      items: [
        if (node.isFolder) ...[
          PopupMenuItem(
            value: _CollectionAction.newCollection,
            child: Text(context.l10n.promptBlockLibrary_newSubcollection),
          ),
          PopupMenuItem(
            value: _CollectionAction.newFolder,
            child: Text(context.l10n.promptBlockLibrary_newCollectionFolder),
          ),
        ],
        PopupMenuItem(
          value: _CollectionAction.rename,
          child: Text(context.l10n.common_rename),
        ),
        if (node.parentId != null)
          PopupMenuItem(
            value: _CollectionAction.moveToRoot,
            child: Text(context.l10n.promptBlockLibrary_moveToFavoritesRoot),
          ),
        PopupMenuItem(
          value: _CollectionAction.delete,
          child: Text(context.l10n.common_delete),
        ),
      ],
    ).then((action) {
      if (action == null || !mounted) return;
      switch (action) {
        case _CollectionAction.newCollection:
          widget.onCreateCollection?.call(node.id, false);
        case _CollectionAction.newFolder:
          widget.onCreateCollection?.call(node.id, true);
        case _CollectionAction.rename:
          widget.onRenameCollection?.call(node.id);
        case _CollectionAction.moveToRoot:
          widget.onMoveCollection?.call(node.id, null);
        case _CollectionAction.delete:
          widget.onDeleteCollection?.call(node.id);
      }
    });
  }

  Widget _buildCollectionList(
    BuildContext context,
    ThemeData theme, {
    required String? parentId,
    required List<PromptBlockCollection> nodes,
    required int depth,
    required Key key,
  }) {
    return ReorderableListView.builder(
      key: key,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: nodes.length,
      onReorderItem: (oldIndex, newIndex) {
        final orderedIds = nodes.map((node) => node.id).toList();
        final moved = orderedIds.removeAt(oldIndex);
        orderedIds.insert(newIndex, moved);
        widget.onReorderCollections?.call(parentId, orderedIds);
      },
      itemBuilder: (context, index) {
        final node = nodes[index];
        return Container(
          key: ValueKey('prompt-block-collection-item-${node.id}'),
          child: node.isFolder
              ? _buildCollectionFolderNode(context, theme, node, depth, index)
              : _buildCollectionNode(context, theme, node, depth, index),
        );
      },
    );
  }

  /// 收藏文件夹节点：展开/收起 + 接收收藏节点拖入（防环）。
  Widget _buildCollectionFolderNode(
    BuildContext context,
    ThemeData theme,
    PromptBlockCollection node,
    int depth,
    int reorderIndex,
  ) {
    final children = widget.collections.childrenOf(node.id);
    final hasChildren = children.isNotEmpty;
    final isExpanded = _expandedIds.contains(node.id);
    final count = _collectionTreeBlockCount(node.id);
    final label = node.name.isEmpty
        ? context.l10n.promptBlockLibrary_unnamedCollectionFolder
        : node.name;

    Widget row = _FolderTreeRow(
      icon: hasChildren
          ? (isExpanded ? Icons.folder_open : Icons.folder)
          : Icons.folder_outlined,
      iconColor: Colors.amber.shade700,
      label: label,
      count: count,
      selected: widget.selectedCollectionId == node.id,
      indent: depth,
      hasChildren: hasChildren,
      expanded: isExpanded,
      reorderIndex: reorderIndex,
      onTap: () => widget.onSelectCollection?.call(node.id),
      onToggleExpanded: hasChildren
          ? () {
              setState(() {
                if (isExpanded) {
                  _expandedIds.remove(node.id);
                } else {
                  _expandedIds.add(node.id);
                }
              });
            }
          : null,
      onSecondaryTapUp: (details) =>
          _showCollectionMenu(node, details.globalPosition),
    );

    // 接收拖入的收藏节点（移入该文件夹）。
    final folderRow = row;
    row = DragTarget<PromptBlockCollection>(
      onWillAcceptWithDetails: (details) {
        final dragged = details.data;
        if (widget.onMoveCollection == null) return false;
        if (dragged.id == node.id) return false;
        if (dragged.parentId == node.id) return false;
        if (widget.collections.wouldCreateCycle(dragged.id, node.id)) {
          return false;
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        HapticFeedback.mediumImpact();
        widget.onMoveCollection?.call(details.data.id, node.id);
        setState(() => _expandedIds.add(node.id));
      },
      builder: (context, candidateData, rejectedData) =>
          _dropHighlight(theme, folderRow, candidateData.isNotEmpty),
    );

    row = Draggable<PromptBlockCollection>(
      data: node,
      feedback: _buildDragFeedback(theme, icon: Icons.folder, label: label),
      childWhenDragging: Opacity(opacity: 0.4, child: row),
      child: row,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        if (hasChildren && isExpanded)
          _buildCollectionList(
            context,
            theme,
            parentId: node.id,
            nodes: children,
            depth: depth + 1,
            key: ValueKey('prompt-block-collection-reorder-${node.id}'),
          ),
      ],
    );
  }

  /// 收藏集节点：点击过滤成员块；接收块拖入 = 直接收进该集。
  Widget _buildCollectionNode(
    BuildContext context,
    ThemeData theme,
    PromptBlockCollection node,
    int depth,
    int reorderIndex,
  ) {
    final label = node.name.isEmpty
        ? context.l10n.promptBlockLibrary_unnamedCollection
        : node.name;

    Widget row = _FolderTreeRow(
      icon: Icons.collections_bookmark,
      iconColor: Colors.amber.shade700,
      label: label,
      count: node.blockIds.length,
      selected: widget.selectedCollectionId == node.id,
      indent: depth,
      reorderIndex: reorderIndex,
      onTap: () => widget.onSelectCollection?.call(node.id),
      onSecondaryTapUp: (details) =>
          _showCollectionMenu(node, details.globalPosition),
    );

    // 接收拖入的块：追加为该收藏集成员（顺带自动收藏）。
    final collectionRow = row;
    row = _blockDropTarget(
      theme,
      PromptBlockTransferTarget(PromptBlockTransferKind.collection, node.id),
      collectionRow,
      fallback: (id) => widget.onAddBlockToCollection?.call(node.id, id),
    );

    return Draggable<PromptBlockCollection>(
      data: node,
      feedback: _buildDragFeedback(
        theme,
        icon: Icons.collections_bookmark,
        label: label,
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: row),
      child: row,
    );
  }

  /// 收藏文件夹子树成员数（子孙收藏集成员并集去重）。
  int _collectionTreeBlockCount(String nodeId) {
    final subtreeIds = <String>{
      nodeId,
      ...widget.collections.getDescendantIds(nodeId),
    };
    final memberIds = <String>{};
    for (final node in widget.collections) {
      if (node.isFolder || !subtreeIds.contains(node.id)) continue;
      memberIds.addAll(node.blockIds);
    }
    return memberIds.length;
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
            Icon(icon, size: 18, color: Colors.amber.shade700),
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

  // ==================== 下区：文件夹树 ====================

  Widget _buildFoldersPane(BuildContext context, ThemeData theme) {
    if (widget.folders.isEmpty) {
      return _buildEmptyPaneHint(
        theme,
        context.l10n.promptBlockLibrary_noFolders,
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildFolderList(
          context,
          theme,
          parentId: null,
          folders: widget.folders.childrenOf(null),
          depth: 0,
          key: const Key('prompt-block-root-folder-reorder'),
        ),
      ],
    );
  }

  /// 文件夹行右键菜单（替代旧 ⋮ 按钮）。
  void _showFolderMenu(PromptBlockFolder folder, Offset globalPosition) {
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) return;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition),
      Offset.zero & overlay.size,
    );
    showMenu<_FolderAction>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: _FolderAction.newChild,
          child: Text(context.l10n.promptBlockLibrary_newSubfolder),
        ),
        PopupMenuItem(
          value: _FolderAction.rename,
          child: Text(context.l10n.common_rename),
        ),
        if (folder.parentId != null)
          PopupMenuItem(
            value: _FolderAction.moveToRoot,
            child: Text(context.l10n.promptBlockLibrary_moveToRoot),
          ),
        PopupMenuItem(
          value: _FolderAction.delete,
          child: Text(context.l10n.common_delete),
        ),
      ],
    ).then((action) {
      if (action == null || !mounted) return;
      switch (action) {
        case _FolderAction.newChild:
          widget.onCreateFolder(folder.id);
        case _FolderAction.rename:
          widget.onRenameFolder(folder.id);
        case _FolderAction.moveToRoot:
          widget.onMoveFolderToRoot(folder.id);
        case _FolderAction.delete:
          widget.onDeleteFolder(folder.id);
      }
    });
  }

  Widget _buildFolderList(
    BuildContext context,
    ThemeData theme, {
    required String? parentId,
    required List<PromptBlockFolder> folders,
    required int depth,
    required Key key,
  }) {
    return ReorderableListView.builder(
      key: key,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: folders.length,
      onReorderItem: (oldIndex, newIndex) {
        final orderedIds = folders.map((folder) => folder.id).toList();
        final moved = orderedIds.removeAt(oldIndex);
        orderedIds.insert(newIndex, moved);
        widget.onReorderFolders(parentId, orderedIds);
      },
      itemBuilder: (context, index) {
        final folder = folders[index];
        return Container(
          key: ValueKey('prompt-block-folder-item-${folder.id}'),
          child: _buildFolderNode(context, theme, folder, depth, index),
        );
      },
    );
  }

  Widget _buildSpecialItem(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _FolderTreeRow(
      icon: icon,
      label: label,
      count: count,
      selected: selected,
      onTap: onTap,
      indent: 0,
    );
  }

  Widget _buildFolderNode(
    BuildContext context,
    ThemeData theme,
    PromptBlockFolder folder,
    int depth,
    int reorderIndex,
  ) {
    final children = widget.folders.childrenOf(folder.id);
    final hasChildren = children.isNotEmpty;
    final isExpanded = _expandedIds.contains(folder.id);
    final descendants = <String>{
      folder.id,
      ...widget.folders.getDescendantIds(folder.id),
    };
    final count = widget.blocks
        .where(
          (block) =>
              block.folderId != null && descendants.contains(block.folderId),
        )
        .length;
    final label = folder.name.isEmpty
        ? context.l10n.promptBlockLibrary_unnamedFolder
        : folder.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _blockDropTarget(
          theme,
          PromptBlockTransferTarget(PromptBlockTransferKind.folder, folder.id),
          _FolderTreeRow(
            icon: hasChildren
                ? (isExpanded ? Icons.folder_open : Icons.folder)
                : Icons.folder_outlined,
            label: label,
            count: count,
            selected: widget.selectedFolderId == folder.id,
            indent: depth,
            hasChildren: hasChildren,
            expanded: isExpanded,
            reorderIndex: reorderIndex,
            onTap: () => widget.onSelectFolder(folder.id),
            onToggleExpanded: hasChildren
                ? () {
                    setState(() {
                      if (isExpanded) {
                        _expandedIds.remove(folder.id);
                      } else {
                        _expandedIds.add(folder.id);
                      }
                    });
                  }
                : null,
            onSecondaryTapUp: (details) =>
                _showFolderMenu(folder, details.globalPosition),
          ),
        ),
        if (hasChildren && isExpanded)
          _buildFolderList(
            context,
            theme,
            parentId: folder.id,
            folders: children,
            depth: depth + 1,
            key: ValueKey('prompt-block-folder-reorder-${folder.id}'),
          ),
      ],
    );
  }
}

enum _FolderAction { newChild, rename, moveToRoot, delete }

enum _CollectionAction { newCollection, newFolder, rename, moveToRoot, delete }

/// 文件夹树行。三列定宽对齐：展开箭头列 / 计数列 / 拖把手列，
/// 无箭头或无把手时用同宽空白占位，保证跨行左右缘全部对齐。
class _FolderTreeRow extends StatelessWidget {
  const _FolderTreeRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.indent,
    required this.onTap,
    this.iconColor,
    this.hasChildren = false,
    this.expanded = false,
    this.onToggleExpanded,
    this.onSecondaryTapUp,
    this.reorderIndex,
    this.onAdd,
  });

  final IconData icon;
  final Color? iconColor;
  final String label;
  final int count;
  final bool selected;
  final int indent;
  final VoidCallback onTap;
  final bool hasChildren;
  final bool expanded;
  final VoidCallback? onToggleExpanded;

  /// 右键呼出操作菜单（新建子项/重命名/移到根级/删除）。
  final ValueChanged<TapUpDetails>? onSecondaryTapUp;

  /// 非 null 时尾列渲染重排拖把手（ReorderableDragStartListener）。
  final int? reorderIndex;

  /// 非 null 时尾列渲染 + 钮（新建子项菜单入口，收藏行用）。
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final background = selected
        ? theme.colorScheme.primaryContainer
        : Colors.transparent;

    return Padding(
      padding: EdgeInsets.only(left: 8.0 + indent * 16, right: 8),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onSecondaryTapUp: onSecondaryTapUp,
          behavior: HitTestBehavior.translucent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 36,
              child: Row(
                children: [
                  // 展开箭头列（固定宽，无子文件夹留空）
                  SizedBox(
                    width: 26,
                    child: hasChildren
                        ? IconButton(
                            tooltip: expanded
                                ? context.l10n.common_collapse
                                : context.l10n.common_expand,
                            padding: EdgeInsets.zero,
                            onPressed: onToggleExpanded,
                            icon: Icon(
                              expanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_right,
                              size: 19,
                              color: foreground,
                            ),
                          )
                        : null,
                  ),
                  Icon(icon, size: 19, color: iconColor ?? foreground),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                  // 计数列（定宽右对齐）
                  SizedBox(
                    width: 26,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$count',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: foreground.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  // 尾列：+ 钮 / 拖把手 / 空白占位（定宽对齐）
                  SizedBox(
                    width: 26,
                    child: onAdd != null
                        ? Tooltip(
                            message:
                                context.l10n.promptBlockLibrary_newCollection,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(13),
                              onTap: onAdd,
                              child: Icon(
                                Icons.add,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : reorderIndex != null
                        ? Tooltip(
                            message:
                                context.l10n.promptBlockLibrary_reorderFolders,
                            child: ReorderableDragStartListener(
                              index: reorderIndex!,
                              child: Icon(
                                Icons.drag_handle,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 双区高度拖拽手柄（视觉 1px 线，10px 热区）；
/// 照抄画廊 `_GallerySidebarResizeHandle` 的观感。
class _SidebarResizeHandle extends StatefulWidget {
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final GestureDragCancelCallback? onVerticalDragCancel;

  const _SidebarResizeHandle({
    super.key,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    this.onVerticalDragCancel,
  });

  @override
  State<_SidebarResizeHandle> createState() => _SidebarResizeHandleState();
}

class _SidebarResizeHandleState extends State<_SidebarResizeHandle> {
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final normalDividerColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
    final highlightColor = theme.colorScheme.primary;
    final isActive = _hovered || _dragging;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (details) {
          setState(() => _dragging = true);
          widget.onVerticalDragStart(details);
        },
        onVerticalDragUpdate: widget.onVerticalDragUpdate,
        onVerticalDragEnd: (details) {
          setState(() => _dragging = false);
          widget.onVerticalDragEnd(details);
        },
        onVerticalDragCancel: () {
          setState(() => _dragging = false);
          widget.onVerticalDragCancel?.call();
        },
        child: Container(
          height: 10.0,
          color: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: isActive ? 2.0 : 1.0,
              margin: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: isActive
                    ? highlightColor.withValues(alpha: 0.8)
                    : normalDividerColor,
                borderRadius: BorderRadius.circular(1.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
