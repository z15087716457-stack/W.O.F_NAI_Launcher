import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../../data/models/prompt_block/prompt_block_folder.dart';

class PromptBlockFolderTree extends StatefulWidget {
  const PromptBlockFolderTree({
    super.key,
    required this.blocks,
    required this.folders,
    required this.allSelected,
    required this.rootSelected,
    required this.selectedFolderId,
    required this.onSelectAll,
    required this.onSelectRoot,
    required this.onSelectFolder,
    required this.onCreateFolder,
    required this.onRenameFolder,
    required this.onMoveFolderToRoot,
    required this.onDeleteFolder,
    required this.onReorderFolders,
  });

  final List<PromptBlock> blocks;
  final List<PromptBlockFolder> folders;
  final bool allSelected;
  final bool rootSelected;
  final String? selectedFolderId;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectRoot;
  final ValueChanged<String> onSelectFolder;
  final ValueChanged<String?> onCreateFolder;
  final ValueChanged<String> onRenameFolder;
  final ValueChanged<String> onMoveFolderToRoot;
  final ValueChanged<String> onDeleteFolder;
  final void Function(String? parentId, List<String> orderedIds)
  onReorderFolders;

  @override
  State<PromptBlockFolderTree> createState() => _PromptBlockFolderTreeState();
}

class _PromptBlockFolderTreeState extends State<PromptBlockFolderTree> {
  final Set<String> _expandedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      key: const Key('prompt-block-folder-tree'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildSpecialItem(
          context,
          theme,
          icon: Icons.all_inclusive,
          label: context.l10n.promptBlockLibrary_allBlocks,
          count: widget.blocks.length,
          selected: widget.allSelected,
          onTap: widget.onSelectAll,
        ),
        _buildSpecialItem(
          context,
          theme,
          icon: Icons.folder_outlined,
          label: context.l10n.promptBlockLibrary_rootFolder,
          count: widget.blocks.where((block) => block.folderId == null).length,
          selected: widget.rootSelected,
          onTap: widget.onSelectRoot,
        ),
        if (widget.folders.isNotEmpty)
          Divider(
            height: 20,
            indent: 12,
            endIndent: 12,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        if (widget.folders.isNotEmpty)
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
    this.hasChildren = false,
    this.expanded = false,
    this.onToggleExpanded,
    this.onSecondaryTapUp,
    this.reorderIndex,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final int indent;
  final VoidCallback onTap;
  final bool hasChildren;
  final bool expanded;
  final VoidCallback? onToggleExpanded;

  /// 右键呼出操作菜单（新建子文件夹/重命名/移到根目录/删除）。
  final ValueChanged<TapUpDetails>? onSecondaryTapUp;

  /// 非 null 时尾列渲染重排拖把手（ReorderableDragStartListener）。
  final int? reorderIndex;

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
                  Icon(icon, size: 19, color: foreground),
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
                  // 拖把手列（固定宽，无把手留空）
                  SizedBox(
                    width: 26,
                    child: reorderIndex != null
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
