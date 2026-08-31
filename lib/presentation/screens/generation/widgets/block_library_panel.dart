import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../../data/models/prompt_block/prompt_block_folder.dart';
import '../../../../data/repositories/prompt_block_repository.dart';
import '../../../providers/layout_state_provider.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_confirm_dialog.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/blocks/prompt_block_drag_data.dart';
import '../../../widgets/prompt/blocks/prompt_block_icons.dart';
import '../../prompt_block_library/widgets/prompt_block_edit_dialog.dart';
import '../../prompt_block_library/widgets/prompt_block_folder_tree.dart';

/// 生成页右侧块库面板（页面级非模态 dock）。
///
/// 两段式：上部为当前范围（全部块/选中文件夹/搜索结果）的块药丸流，
/// 下部为文件夹树（复用管理页 [PromptBlockFolderTree]）。
/// 点击药丸 = 插入到主提示词最近光标处；拖拽药丸 = 落点插入；
/// 悬停 800ms 显示内容预览；右键 = 编辑/收藏/移动/删除。
class BlockLibraryPanel extends ConsumerStatefulWidget {
  const BlockLibraryPanel({super.key});

  @override
  ConsumerState<BlockLibraryPanel> createState() => _BlockLibraryPanelState();
}

class _BlockLibraryPanelState extends ConsumerState<BlockLibraryPanel> {
  late final TextEditingController _searchController;
  final GlobalKey _bodyKey = GlobalKey();

  /// 选中「全部块」为 true；否则 [_selectedFolderId] 为 null 表示根目录/未分类。
  bool _allSelected = true;
  String? _selectedFolderId;

  /// 上部块区高度占比（0.3~0.78），分割条可拖。
  double _blocksRatio = 0.62;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final library = ref.watch(promptBlockLibraryNotifierProvider);

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        key: _bodyKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, theme),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: _buildSearchField(context),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            flex: (_blocksRatio * 1000).round(),
            child: library.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildError(context, error),
              data: (state) => _buildBlockArea(context, state),
            ),
          ),
          _buildSplitHandle(theme),
          _buildFolderSectionHeader(context, theme),
          Expanded(
            flex: 1000 - (_blocksRatio * 1000).round(),
            child: library.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (state) => _buildFolderTree(context, state),
            ),
          ),
        ],
      ),
    );
  }

  /// 上下两段的可拖分割条（视觉 1px 线，10px 热区）。
  Widget _buildSplitHandle(ThemeData theme) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) {
          final box = _bodyKey.currentContext?.findRenderObject();
          if (box is! RenderBox || box.size.height <= 0) return;
          setState(() {
            _blocksRatio = (_blocksRatio + details.delta.dy / box.size.height)
                .clamp(0.3, 0.78);
          });
        },
        child: Container(
          height: 10,
          alignment: Alignment.center,
          child: Divider(height: 1, color: theme.dividerColor),
        ),
      ),
    );
  }

  // ==================== 头部 ====================

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
      child: Row(
        children: [
          Icon(
            Icons.view_module_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              context.l10n.promptBlockEditor_library,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            key: const Key('block-library-panel-close'),
            tooltip: context.l10n.common_close,
            iconSize: 18,
            onPressed: () => ref
                .read(layoutStateNotifierProvider.notifier)
                .setBlockLibraryPanelExpanded(false),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      key: const Key('block-library-panel-search'),
      controller: _searchController,
      decoration: InputDecoration(
        hintText: context.l10n.promptBlockLibrary_searchHint,
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: context.l10n.common_clear,
                onPressed: _searchController.clear,
                icon: const Icon(Icons.close, size: 16),
              ),
        isDense: true,
        filled: true,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // ==================== 上部：块药丸流 ====================

  Widget _buildBlockArea(BuildContext context, PromptBlockLibraryState state) {
    // 选中文件夹被删除时回退到「全部块」
    if (!_allSelected &&
        _selectedFolderId != null &&
        state.folderById(_selectedFolderId!) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _allSelected = true;
            _selectedFolderId = null;
          });
        }
      });
    }

    final query = _searchController.text.trim().toLowerCase();
    final List<PromptBlock> blocks;
    if (query.isNotEmpty) {
      blocks = state.blocks
          .where(
            (block) =>
                block.title.toLowerCase().contains(query) ||
                block.content.toLowerCase().contains(query),
          )
          .toList();
    } else if (_allSelected) {
      blocks = state.blocks;
    } else {
      blocks = state.blocksInFolder(_selectedFolderId);
    }

    if (blocks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            query.isNotEmpty
                ? context.l10n.promptBlockLibrary_noSearchResults
                : context.l10n.promptBlockLibrary_emptyFolder,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      key: const Key('block-library-panel-blocks'),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [for (final block in blocks) _buildBlockChip(block)],
      ),
    );
  }

  Widget _buildBlockChip(PromptBlock block) {
    final theme = Theme.of(context);
    final color = promptBlockColorFromString(block.color);
    final title = block.title.trim().isEmpty
        ? context.l10n.promptBlockLibrary_unnamedBlock
        : block.title.trim();

    final chip = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.55), width: 0.9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              promptBlockIconFromName(block.iconName),
              size: 15,
              color: color,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  height: 1.1,
                ),
              ),
            ),
            if (block.isFavorite) ...[
              const SizedBox(width: 4),
              Icon(Icons.star, size: 13, color: color),
            ],
          ],
        ),
      ),
    );

    return Tooltip(
      key: ValueKey('block-library-chip-${block.id}'),
      waitDuration: const Duration(milliseconds: 800),
      preferBelow: true,
      richMessage: TextSpan(
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        children: [
          TextSpan(
            text: title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (block.content.trim().isNotEmpty)
            TextSpan(text: '\n${_previewOf(block.content)}'),
        ],
      ),
      child: Draggable<PromptBlockDragData>(
        data: PromptBlockDragData(blockId: block.id),
        rootOverlay: true,
        // feedback 以指针为中心：默认会把 feedback 左上角对准指针，
        // 用户以药丸视觉中心瞄准时落点系统性偏上一行。
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Opacity(opacity: 0.9, child: chip),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: chip),
        child: GestureDetector(
          onTap: () => _insertBlock(block),
          onSecondaryTapUp: (details) =>
              _showBlockContextMenu(block, details.globalPosition),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: chip,
          ),
        ),
      ),
    );
  }

  /// 悬停预览：整块内容截断约 3 行。
  String _previewOf(String content) {
    final trimmed = content.trim();
    const limit = 150;
    if (trimmed.length <= limit) return trimmed;
    return '${trimmed.substring(0, limit)}…';
  }

  // ==================== 下部：文件夹树 ====================

  Widget _buildFolderSectionHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.promptBlockLibrary_folders,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            key: const Key('block-library-panel-new-folder'),
            tooltip: context.l10n.promptBlockLibrary_newFolder,
            iconSize: 18,
            onPressed: () => _showFolderNameDialog(
              parentId: _allSelected ? null : _selectedFolderId,
            ),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderTree(BuildContext context, PromptBlockLibraryState state) {
    return PromptBlockFolderTree(
      blocks: state.blocks,
      folders: state.folders,
      allSelected: _allSelected,
      rootSelected: !_allSelected && _selectedFolderId == null,
      selectedFolderId: _allSelected ? null : _selectedFolderId,
      onSelectAll: () => _selectScope(all: true),
      onSelectRoot: () => _selectScope(all: false, folderId: null),
      onSelectFolder: (folderId) => _selectScope(all: false, folderId: folderId),
      onCreateFolder: (parentId) => _showFolderNameDialog(parentId: parentId),
      onRenameFolder: (folderId) {
        final folder = state.folderById(folderId);
        if (folder != null) _showFolderNameDialog(folder: folder);
      },
      onMoveFolderToRoot: (folderId) =>
          ref
              .read(promptBlockLibraryNotifierProvider.notifier)
              .moveFolder(folderId, null),
      onDeleteFolder: (folderId) => _deleteFolder(state, folderId),
      onReorderFolders: (parentId, orderedIds) => ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .reorderFolders(parentId, orderedIds),
    );
  }

  void _selectScope({required bool all, String? folderId}) {
    // 搜索中点击文件夹：清空搜索并切换范围，否则块区内容不会变
    if (_searchController.text.isNotEmpty) _searchController.clear();
    setState(() {
      _allSelected = all;
      _selectedFolderId = folderId;
    });
  }

  // ==================== 插入 ====================

  void _insertBlock(PromptBlock block) {
    final document = ref.read(pillWorkspaceNotifierProvider).document;
    final caret = ref.read(pillMainCaretOffsetProvider);
    final offset = (caret ?? document.text.length).clamp(
      0,
      document.text.length,
    );
    ref
        .read(pillWorkspaceNotifierProvider.notifier)
        .insertBlockAt(offset: offset, blockId: block.id);
  }

  // ==================== 块右键菜单 ====================

  void _showBlockContextMenu(PromptBlock block, Offset globalPosition) {
    final l10n = context.l10n;
    final state = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    if (state == null) return;

    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) return;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_outlined, size: 18),
            title: Text(l10n.promptBlockLibrary_editBlock),
          ),
        ),
        PopupMenuItem(
          value: 'favorite',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              block.isFavorite ? Icons.star : Icons.star_outline,
              size: 18,
            ),
            title: Text(
              block.isFavorite ? l10n.common_unfavorite : l10n.common_favorite,
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            l10n.promptBlockLibrary_moveToFolder,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        ..._moveTargetEntries(block, state),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_outline,
              size: 18,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.common_delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ],
    ).then((value) {
      if (!mounted || value == null) return;
      switch (value) {
        case 'edit':
          _editBlock(block);
        case 'favorite':
          _toggleFavorite(block);
        case 'delete':
          _deleteBlock(block);
        default:
          // value 形如 'move:<folderId>' 或 'move:'（根目录）
          if (value.startsWith('move:')) {
            final folderId = value.substring(5);
            ref
                .read(promptBlockLibraryNotifierProvider.notifier)
                .moveBlock(block.id, folderId.isEmpty ? null : folderId);
          }
      }
    });
  }

  List<PopupMenuEntry<String>> _moveTargetEntries(
    PromptBlock block,
    PromptBlockLibraryState state,
  ) {
    final entries = <PopupMenuEntry<String>>[];
    Widget label(String text, int depth, bool current) {
      return Padding(
        padding: EdgeInsets.only(left: 12.0 + depth * 12),
        child: Text(
          current ? '$text ✓' : text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    entries.add(
      PopupMenuItem(
        value: 'move:',
        enabled: block.folderId != null,
        child: label(
          context.l10n.promptBlockLibrary_rootFolder,
          0,
          block.folderId == null,
        ),
      ),
    );

    void walk(String? parentId, int depth) {
      for (final folder in state.foldersIn(parentId)) {
        final name = folder.name.isEmpty
            ? context.l10n.promptBlockLibrary_unnamedFolder
            : folder.name;
        entries.add(
          PopupMenuItem(
            value: 'move:${folder.id}',
            enabled: block.folderId != folder.id,
            child: label(name, depth + 1, block.folderId == folder.id),
          ),
        );
        walk(folder.id, depth + 1);
      }
    }

    walk(null, 0);
    return entries;
  }

  // ==================== 块/文件夹操作 ====================

  Future<void> _editBlock(PromptBlock block) async {
    final state = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    if (state == null) return;
    final result = await PromptBlockEditDialog.show(
      context: context,
      block: block,
      folders: state.folders,
    );
    if (result == null || !mounted) return;
    try {
      final updated = await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .updateBlock(
            block.copyWith(
              title: result.title,
              content: result.content,
              color: result.color,
              iconName: result.iconName,
            ),
          );
      if (updated.folderId != result.folderId) {
        await ref
            .read(promptBlockLibraryNotifierProvider.notifier)
            .moveBlock(updated.id, result.folderId);
      }
      if (mounted) {
        AppToast.success(context, context.l10n.promptBlockLibrary_saved);
      }
    } catch (error) {
      if (mounted) AppToast.error(context, '$error');
    }
  }

  Future<void> _toggleFavorite(PromptBlock block) async {
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .toggleFavorite(block.id);
      if (mounted) {
        AppToast.success(
          context,
          block.isFavorite
              ? context.l10n.toast_unfavorited
              : context.l10n.toast_favorited,
        );
      }
    } catch (error) {
      if (mounted) AppToast.error(context, '$error');
    }
  }

  Future<void> _deleteBlock(PromptBlock block) async {
    final l10n = context.l10n;
    final title = block.title.isEmpty
        ? l10n.promptBlockLibrary_unnamedBlock
        : block.title;
    final confirmed = await ThemedConfirmDialog.showDelete(
      context: context,
      itemName: title,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .deleteBlock(block.id);
      if (mounted) AppToast.success(context, l10n.promptBlockLibrary_deleted);
    } catch (error) {
      if (mounted) AppToast.error(context, '$error');
    }
  }

  Future<void> _showFolderNameDialog({
    String? parentId,
    PromptBlockFolder? folder,
  }) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: folder?.name ?? '');
    final title = folder == null
        ? (parentId == null
              ? l10n.promptBlockLibrary_newFolder
              : l10n.promptBlockLibrary_newSubfolder)
        : l10n.promptBlockLibrary_renameFolder;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.promptBlockLibrary_folderNameHint,
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.common_confirm),
          ),
        ],
      ),
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty || !mounted) return;
    try {
      if (folder == null) {
        await ref
            .read(promptBlockLibraryNotifierProvider.notifier)
            .createFolder(name: trimmed, parentId: parentId);
      } else {
        await ref
            .read(promptBlockLibraryNotifierProvider.notifier)
            .updateFolder(folder.copyWith(name: trimmed));
      }
    } catch (error) {
      if (mounted) AppToast.error(context, '$error');
    }
  }

  /// 面板内删除固定为「内容上移到根目录」，不丢块；更细的处置去管理页。
  Future<void> _deleteFolder(
    PromptBlockLibraryState state,
    String folderId,
  ) async {
    final folder = state.folderById(folderId);
    if (folder == null) return;
    final name = folder.name.isEmpty
        ? context.l10n.promptBlockLibrary_unnamedFolder
        : folder.name;
    final confirmed = await ThemedConfirmDialog.show(
      context: context,
      title: context.l10n.promptBlockLibrary_deleteFolderTitle(name),
      content: context.l10n.promptBlockLibrary_moveContentsToRoot,
      confirmText: context.l10n.common_delete,
      type: ThemedConfirmDialogType.danger,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .deleteFolder(
            folderId,
            mode: PromptBlockFolderDeleteMode.moveContentsToRoot,
          );
    } catch (error) {
      if (mounted) AppToast.error(context, '$error');
    }
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.promptBlockLibrary_loadFailed('$error'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref
                  .read(promptBlockLibraryNotifierProvider.notifier)
                  .refresh(),
              child: Text(context.l10n.common_retry),
            ),
          ],
        ),
      ),
    );
  }
}
