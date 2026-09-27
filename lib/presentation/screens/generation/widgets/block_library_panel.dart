import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../../data/models/prompt_block/prompt_block_collection.dart';
import '../../../../data/models/prompt_block/prompt_block_folder.dart';
import '../../../../data/repositories/prompt_block_repository.dart';
import '../../../providers/layout_state_provider.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../providers/generation/generation_params_notifier.dart';
import '../../../providers/tips_provider.dart';
import '../../../utils/prompt_block_bundle_insertion.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_confirm_dialog.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/blocks/prompt_block_drag_data.dart';
import '../../../widgets/prompt/blocks/prompt_block_icons.dart';
import '../../prompt_block_library/widgets/prompt_block_detail.dart';
import '../../prompt_block_library/widgets/prompt_block_edit_dialog.dart';
import '../../prompt_block_library/widgets/prompt_block_folder_tree.dart';
import '../../prompt_block_library/widgets/prompt_block_organizer_popover.dart';

/// 生成页右侧块库面板（页面级非模态 dock）。
///
/// 两段式：上部为当前范围（全部块/选中文件夹/搜索结果）的块药丸流，
/// 下部为文件夹树（复用管理页 [PromptBlockFolderTree]）。
/// 点击药丸 = 插入到主提示词最近光标处；拖拽药丸 = 落点插入；
/// 悬停 800ms 显示内容预览；右键 = 编辑/收藏/移动/删除。
class BlockLibraryPanel extends ConsumerStatefulWidget {
  const BlockLibraryPanel({super.key, this.fallbackScope = PillScopes.main});

  /// 点击插入的回退 lane：从未聚焦过任何药丸框时插入到这里
  /// （生成页 = 主提示词；画风探索页 = 探索正向 lane）。
  final String fallbackScope;

  @override
  ConsumerState<BlockLibraryPanel> createState() => _BlockLibraryPanelState();
}

class _BlockLibraryPanelState extends ConsumerState<BlockLibraryPanel> {
  static const double _verticalFixedHeight = 64;

  late final TextEditingController _searchController;
  final GlobalKey _verticalBodyKey = GlobalKey();
  final GlobalKey _blocksAreaKey = GlobalKey();

  /// 选中「全部块」为 true；否则 [_selectedFolderId] 为 null 表示根目录/未分类。
  bool _allSelected = true;

  /// ⭐收藏过滤激活；与 [_selectedCollectionId] 互斥。
  bool _favoritesSelected = false;

  /// 选中的收藏集/收藏文件夹 id（非空时 [_favoritesSelected] 为 false）。
  String? _selectedCollectionId;
  String? _selectedFolderId;

  /// 异步加载或错误状态下的上部区域默认高度比例。
  static const double _blocksRatio = 0.4;

  /// 未拖拽时上部区域默认估算的可用高度占比上限：块多时给下方
  /// 文件夹区留位，手动拖动/持久化比例不受此约束。
  static const double _defaultBlocksMaxRatio = 0.6;
  double? _manualBlocksHeight;

  /// 上次拖动持久化的分割比例（跨页面切换/重启恢复）。
  double? _persistedBlocksRatio;

  /// BUG-4：未拖拽时首次估算高度算一次即锁定，此后切文件夹/搜索不再
  /// 重算；读取时与手动值同款 clamp（窗口 resize 随 availableHeight 收敛）。
  double? _lockedBlocksHeight;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()
      ..addListener(() => setState(() {}));
    _persistedBlocksRatio = ref
        .read(localStorageServiceProvider)
        .getBlockLibraryPanelBlocksSplit();
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, theme),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: _buildSearchField(context),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: LayoutBuilder(
              key: _verticalBodyKey,
              builder: (context, constraints) {
                final blocksHeight = _resolveBlocksHeight(
                  library,
                  constraints.maxHeight,
                  constraints.maxWidth,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      key: _blocksAreaKey,
                      child: SizedBox(
                        key: const Key('block-library-panel-block-area'),
                        height: blocksHeight,
                        child: library.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) => _buildError(context, error),
                          data: (state) => _buildBlockArea(context, state),
                        ),
                      ),
                    ),
                    _buildSplitHandle(theme),
                    _buildFolderSectionHeader(context, theme),
                    Expanded(
                      child: KeyedSubtree(
                        key: const Key('block-library-panel-folder-area'),
                        child: library.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (state) => _buildFolderTree(context, state),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _resolveBlocksHeight(
    AsyncValue<PromptBlockLibraryState> library,
    double bodyHeight,
    double panelWidth,
  ) {
    final availableHeight = (bodyHeight - _verticalFixedHeight)
        .clamp(0.0, double.infinity)
        .toDouble();
    if (availableHeight <= 0) return 0;

    final manualHeight = (availableHeight * _blocksRatio)
        .clamp(0.0, availableHeight)
        .toDouble();
    final fixedHeight =
        _manualBlocksHeight ??
        (_persistedBlocksRatio != null
            ? _persistedBlocksRatio! * availableHeight
            : _lockedBlocksHeight);
    if (fixedHeight != null) {
      return fixedHeight.clamp(0.0, availableHeight).toDouble();
    }
    final state = library.valueOrNull;
    if (state == null) return manualHeight;

    final blocks = _filteredBlocks(state);
    final double resolved;
    if (blocks.isEmpty) {
      resolved = availableHeight.clamp(0.0, 96.0).toDouble();
    } else {
      final contentWidth = (panelWidth - 20)
          .clamp(1.0, double.infinity)
          .toDouble();
      final columns = (contentWidth / 156).floor().clamp(1, 4).toInt();
      final rows = (blocks.length + columns - 1) ~/ columns;
      final estimatedHeight = 18.0 + rows * 39.0 + (rows - 1) * 6.0;
      // 默认估算封顶 60% 可用高：块多时下方文件夹区仍需可见。
      final maxEstimate = availableHeight * _defaultBlocksMaxRatio;
      final minEstimate = maxEstimate < 72 ? maxEstimate : 72.0;
      resolved = estimatedHeight.clamp(minEstimate, maxEstimate).toDouble();
    }
    return _lockedBlocksHeight = resolved;
  }

  List<PromptBlock> _filteredBlocks(PromptBlockLibraryState state) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      return state.blocks
          .where(
            (block) =>
                block.title.toLowerCase().contains(query) ||
                block.content.toLowerCase().contains(query),
          )
          .toList();
    }
    if (_allSelected) return state.blocks;
    if (_favoritesSelected) return state.favoriteBlocks;
    if (_selectedCollectionId != null) {
      return state.blocksInCollectionTree(_selectedCollectionId!);
    }
    // 与管理页同口径：文件夹范围 = 子树并集（直属 + 各后代文件夹），
    // 否则「块全在子文件夹里」的父文件夹会显示为空。
    return state.blocksInFolderTree(_selectedFolderId);
  }

  /// 上下两段的可拖分割条（视觉 1px 线，10px 热区）。
  Widget _buildSplitHandle(ThemeData theme) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        key: const Key('block-library-panel-split-handle'),
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) {
          final box = _blocksAreaKey.currentContext?.findRenderObject();
          if (box is! RenderBox || box.size.height <= 0) return;
          setState(() => _manualBlocksHeight = box.size.height);
        },
        onVerticalDragUpdate: (details) {
          final body = _verticalBodyKey.currentContext?.findRenderObject();
          final box = _blocksAreaKey.currentContext?.findRenderObject();
          if (body is! RenderBox || box is! RenderBox) return;
          final availableHeight = (body.size.height - _verticalFixedHeight)
              .clamp(0.0, double.infinity)
              .toDouble();
          if (availableHeight <= 0) return;
          final minHeight = availableHeight < 60 ? 0.0 : 60.0;
          final currentHeight = _manualBlocksHeight ?? box.size.height;
          setState(() {
            _manualBlocksHeight = (currentHeight + details.delta.dy)
                .clamp(minHeight, availableHeight)
                .toDouble();
          });
        },
        onVerticalDragEnd: (_) => _persistBlocksSplit(),
        onVerticalDragCancel: _persistBlocksSplit,
        child: Container(
          height: 10,
          alignment: Alignment.center,
          child: Divider(height: 1, color: theme.dividerColor),
        ),
      ),
    );
  }

  /// 拖动结束把上区高度按可用高度比例持久化（跨页面切换/重启恢复）。
  void _persistBlocksSplit() {
    final body = _verticalBodyKey.currentContext?.findRenderObject();
    if (body is! RenderBox) return;
    final availableHeight = (body.size.height - _verticalFixedHeight)
        .clamp(0.0, double.infinity)
        .toDouble();
    final height = _manualBlocksHeight;
    if (availableHeight <= 0 || height == null) return;
    final ratio = (height / availableHeight).clamp(0.0, 1.0).toDouble();
    _persistedBlocksRatio = ratio;
    ref
        .read(localStorageServiceProvider)
        .setBlockLibraryPanelBlocksSplit(ratio);
  }

  // ==================== 头部 ====================

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
      child: Row(
        children: [
          Icon(
            StudioIcons.promptBlocks,
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
    final theme = Theme.of(context);
    return SizedBox(
      height: 36,
      child: TextField(
        key: const Key('block-library-panel-search'),
        controller: _searchController,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: tipHint(
            context.l10n,
            TipModule.blockLibrary,
            epoch: watchTipEpoch(ref),
          ),
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 13,
          ),
          prefixIcon: const Icon(Icons.search, size: 18),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 30,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: context.l10n.common_clear,
                  visualDensity: VisualDensity.compact,
                  onPressed: _searchController.clear,
                  icon: const Icon(Icons.close, size: 16),
                ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 30,
          ),
          isDense: true,
          filled: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  // ==================== 上部：块药丸流 ====================

  Widget _buildBlockArea(BuildContext context, PromptBlockLibraryState state) {
    // 选中文件夹被删除时回退到「全部块」
    if (!_allSelected &&
        !_favoritesSelected &&
        _selectedCollectionId == null &&
        _selectedFolderId != null &&
        state.folderById(_selectedFolderId!) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _selectScope(all: true);
      });
    }
    // 选中收藏集/收藏文件夹被删 → 回退到「收藏」视图。
    if (_selectedCollectionId != null &&
        state.collectionById(_selectedCollectionId!) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedCollectionId != null) {
          _selectScope(favorites: true);
        }
      });
    }

    final query = _searchController.text.trim().toLowerCase();
    final blocks = _filteredBlocks(state);

    if (blocks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            query.isNotEmpty
                ? context.l10n.promptBlockLibrary_noSearchResults
                : _favoritesSelected
                ? context.l10n.promptBlockLibrary_emptyFavorites
                : _selectedCollectionId != null
                ? context.l10n.promptBlockLibrary_emptyCollection
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
        children: [
          for (final block in blocks)
            _buildBlockChip(block, folders: state.folders),
        ],
      ),
    );
  }

  Widget _buildBlockChip(
    PromptBlock block, {
    required List<PromptBlockFolder> folders,
  }) {
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

    // 悬停 800ms 出块库同款详情预览卡（含缩略图），取代旧纯文本 Tooltip。
    return PromptBlockHoverPreview(
      key: ValueKey('block-library-chip-${block.id}'),
      block: block,
      folders: folders,
      child: Draggable<PromptBlockDragData>(
        data: PromptBlockDragData(
          blockId: block.id,
          sourceCollectionId: _selectedCollectionId,
          sourceFavorites: _favoritesSelected,
        ),
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
          child: MouseRegion(cursor: SystemMouseCursors.click, child: chip),
        ),
      ),
    );
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
      collections: state.collections,
      allSelected: _allSelected,
      rootSelected:
          !_allSelected &&
          !_favoritesSelected &&
          _selectedCollectionId == null &&
          _selectedFolderId == null,
      favoritesSelected: _favoritesSelected,
      selectedFolderId: _allSelected ? null : _selectedFolderId,
      selectedCollectionId: _selectedCollectionId,
      onSelectAll: () => _selectScope(all: true),
      onSelectRoot: () => _selectScope(),
      onSelectFavorites: () => _selectScope(favorites: true),
      onSelectFolder: (folderId) => _selectScope(folderId: folderId),
      onSelectCollection: (id) => _selectScope(collectionId: id),
      onCreateFolder: (parentId) => _showFolderNameDialog(parentId: parentId),
      onRenameFolder: (folderId) {
        final folder = state.folderById(folderId);
        if (folder != null) _showFolderNameDialog(folder: folder);
      },
      onMoveFolderToRoot: (folderId) => ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .moveFolder(folderId, null),
      onDeleteFolder: (folderId) => _deleteFolder(state, folderId),
      onReorderFolders: (parentId, orderedIds) => ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .reorderFolders(parentId, orderedIds),
      onCreateCollection: (parentId, isFolder) =>
          _showCollectionNameDialog(parentId: parentId, isFolder: isFolder),
      onRenameCollection: (id) {
        final collection = state.collectionById(id);
        if (collection != null) {
          _showCollectionNameDialog(
            isFolder: collection.isFolder,
            collection: collection,
          );
        }
      },
      onMoveCollection: (id, newParentId) => ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .moveCollection(id, newParentId),
      onDeleteCollection: (id) => _deleteCollection(state, id),
      onReorderCollections: (parentId, orderedIds) => ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .reorderCollections(parentId, orderedIds),
      onAddBlockToCollection: _addBlockToCollection,
      onDropBlockOnFavorites: _favoriteBlockFromDrop,
      onDropBlocks: (data, target, offset) => showBlockOrganizerPopover(
        context,
        blockIds: data.transferIds,
        anchor: offset,
        page: target.kind == PromptBlockTransferKind.folder
            ? BlockOrganizerPage.folders
            : BlockOrganizerPage.favorites,
        dropTarget: target,
        sourceCollectionId: data.sourceCollectionId,
        sourceFavorites: data.sourceFavorites,
      ),
    );
  }

  /// 侧栏选中语义的统一收口：四类范围互斥（全部/收藏/收藏节点/文件夹）。
  void _selectScope({
    bool all = false,
    bool favorites = false,
    String? collectionId,
    String? folderId,
  }) {
    // 搜索中点击文件夹：清空搜索并切换范围，否则块区内容不会变
    if (_searchController.text.isNotEmpty) _searchController.clear();
    setState(() {
      _allSelected = all;
      _favoritesSelected = favorites;
      _selectedCollectionId = collectionId;
      _selectedFolderId = folderId;
    });
  }

  // ==================== 插入 ====================

  /// 点击插入：路由到「最近聚焦的药丸编辑框」（`pillActiveEditorTargetProvider`），
  /// 从未聚焦过任何框时回退到 [fallbackScope] 末尾。
  void _insertBlock(PromptBlock block) {
    final target = ref.read(pillActiveEditorTargetProvider);
    final lane = pillWorkspaceProvider(target?.scope ?? widget.fallbackScope);
    final document = ref.read(lane).document;
    final offset = (target?.caret ?? document.text.length).clamp(
      0,
      document.text.length,
    );
    insertPromptBlockBundle(
      ref,
      scope: target?.scope ?? widget.fallbackScope,
      offset: offset,
      blockId: block.id,
    );
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
        const PopupMenuItem(
          value: 'tags',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.sell_outlined, size: 18),
            title: Text('添加标签'),
          ),
        ),
        PopupMenuItem(
          value: 'folder',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.folder_outlined, size: 18),
            title: Text(l10n.promptBlockLibrary_moveToFolder),
          ),
        ),
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
          _showFavoriteMenu(block, globalPosition);
        case 'tags':
          showBlockOrganizerPopover(
            context,
            blockIds: [block.id],
            anchor: globalPosition,
            page: BlockOrganizerPage.tags,
          );
        case 'folder':
          showBlockOrganizerPopover(
            context,
            blockIds: [block.id],
            anchor: globalPosition,
            page: BlockOrganizerPage.folders,
          );
        case 'delete':
          _deleteBlock(block);
        default:
          break;
      }
    });
  }

  // ==================== 块/文件夹操作 ====================

  Future<void> _editBlock(PromptBlock block) async {
    final state = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    if (state == null) return;
    final result = await PromptBlockEditDialog.show(
      context: context,
      block: block,
      folders: state.folders,
      modelForTokenCount: ref.read(generationParamsNotifierProvider).model,
    );
    if (result == null || !mounted) return;
    try {
      final updated = await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .updateBlock(
            block.copyWith(
              title: result.title,
              content: result.content,
              atoms: result.atoms,
              negativeContent: result.negativeContent,
              negativeAtoms: result.negativeAtoms,
              generationSettings: result.generationSettings,
              color: result.color,
              iconName: result.iconName,
              thumbnail: result.thumbnail,
              thumbnailOffsetX: result.thumbnailOffsetX,
              thumbnailOffsetY: result.thumbnailOffsetY,
              thumbnailScale: result.thumbnailScale,
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

  /// 单块 ★ 入口。
  Future<void> _showFavoriteMenu(PromptBlock block, Offset anchor) {
    return showBlockOrganizerPopover(
      context,
      blockIds: [block.id],
      anchor: anchor,
      page: BlockOrganizerPage.favorites,
    );
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

  // ==================== 收藏集 ====================

  /// 新建或重命名收藏集 / 收藏文件夹的名称对话框。
  Future<void> _showCollectionNameDialog({
    String? parentId,
    required bool isFolder,
    PromptBlockCollection? collection,
  }) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: collection?.name ?? '');
    final title = collection != null
        ? (collection.isFolder
              ? l10n.promptBlockLibrary_renameCollectionFolder
              : l10n.promptBlockLibrary_renameCollection)
        : (isFolder
              ? l10n.promptBlockLibrary_newCollectionFolder
              : l10n.promptBlockLibrary_newCollection);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.promptBlockLibrary_collectionNameHint,
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
      final notifier = ref.read(promptBlockLibraryNotifierProvider.notifier);
      if (collection == null) {
        await notifier.createCollection(
          name: trimmed,
          parentId: parentId,
          isFolder: isFolder,
        );
      } else {
        await notifier.renameCollection(collection.id, trimmed);
      }
      if (mounted) {
        AppToast.success(context, l10n.promptBlockLibrary_saved);
      }
    } catch (error) {
      if (mounted) AppToast.error(context, '$error');
    }
  }

  /// 删除收藏集/收藏文件夹：连带子树删除，成员块本体不动。
  Future<void> _deleteCollection(
    PromptBlockLibraryState state,
    String id,
  ) async {
    final l10n = context.l10n;
    final node = state.collectionById(id);
    if (node == null) return;
    final label = node.name.isEmpty
        ? (node.isFolder
              ? l10n.promptBlockLibrary_unnamedCollectionFolder
              : l10n.promptBlockLibrary_unnamedCollection)
        : node.name;
    final confirmed = await ThemedConfirmDialog.show(
      context: context,
      title: l10n.common_delete,
      content: node.isFolder
          ? l10n.promptBlockLibrary_deleteCollectionFolderConfirm(label)
          : l10n.promptBlockLibrary_deleteCollectionConfirm(label),
      confirmText: l10n.common_delete,
      type: ThemedConfirmDialogType.danger,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .deleteCollection(id);
      if (mounted) {
        AppToast.success(context, l10n.promptBlockLibrary_deleted);
      }
    } catch (error) {
      if (mounted) AppToast.error(context, '$error');
    }
  }

  /// 块拖到收藏集行上：已在集内跳过，否则追加成员（入集即收藏）。
  Future<void> _addBlockToCollection(
    String collectionId,
    String blockId,
  ) async {
    final node = ref
        .read(promptBlockLibraryNotifierProvider)
        .valueOrNull
        ?.collectionById(collectionId);
    if (node == null || node.isFolder || node.blockIds.contains(blockId)) {
      return;
    }
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .toggleBlockInCollection(collectionId, blockId);
    } catch (error) {
      if (mounted) AppToast.error(context, '$error');
    }
  }

  /// 块拖到「收藏」行上：仅在未收藏时置收藏旗标。
  Future<void> _favoriteBlockFromDrop(String blockId) async {
    final block = ref
        .read(promptBlockLibraryNotifierProvider)
        .valueOrNull
        ?.blockById(blockId);
    if (block == null || block.isFavorite) return;
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .toggleFavorite(blockId);
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
