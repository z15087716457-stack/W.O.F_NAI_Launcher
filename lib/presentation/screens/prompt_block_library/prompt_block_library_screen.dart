import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/utils/file_picker_utils.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/prompt_block_exchange.dart';
import '../../../data/models/prompt_block/prompt_block.dart';
import '../../../data/models/prompt_block/prompt_block_collection.dart';
import '../../../data/models/prompt_block/prompt_block_folder.dart';
import '../../../data/models/prompt_block/prompt_block_sort.dart';
import '../../../data/repositories/prompt_block_repository.dart';
import '../../providers/prompt_block_library_provider.dart';
import '../../providers/generation/generation_params_notifier.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/themed_confirm_dialog.dart';
import '../../widgets/prompt/blocks/prompt_block_drag_data.dart';
import 'widgets/curation_import_preview_dialog.dart';
import 'widgets/prompt_block_card.dart';
import 'widgets/prompt_block_detail.dart';
import 'widgets/prompt_block_edit_dialog.dart';
import 'widgets/prompt_block_folder_delete_dialog.dart';
import 'widgets/prompt_block_folder_tree.dart';
import 'widgets/prompt_block_list_item.dart';
import 'widgets/prompt_block_organizer_popover.dart';
import 'widgets/prompt_block_waterfall_card.dart';

enum _PromptBlockViewMode { list, grid, waterfall }

/// 块右键菜单动作（单块语义 + 多选批量语义共用一个枚举）。
enum _BlockContextAction {
  edit,
  copy,
  favorite,
  unfavorite,
  moveTo,
  addTag,
  delete,
  enterMultiSelect,
  batchFavorite,
  batchTag,
  batchMoveTo,
  batchDelete,
  exitMultiSelect,
}

class PromptBlockLibraryScreen extends ConsumerStatefulWidget {
  const PromptBlockLibraryScreen({super.key});

  @override
  ConsumerState<PromptBlockLibraryScreen> createState() =>
      _PromptBlockLibraryScreenState();
}

class _PromptBlockLibraryScreenState
    extends ConsumerState<PromptBlockLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _selectedTag;

  bool _allSelected = true;

  /// ⭐收藏过滤激活；与 [_selectedCollectionId] 互斥。
  bool _favoritesSelected = false;

  /// 选中的收藏集/收藏文件夹 id（非空时 [_favoritesSelected] 为 false，
  /// 主区显示该收藏集成员或该文件夹子树成员并集）。
  String? _selectedCollectionId;
  String? _selectedFolderId;
  _PromptBlockViewMode _viewMode = _PromptBlockViewMode.grid;
  PromptBlockSortField _sortField = PromptBlockSortField.custom;
  bool _sortDescending = false;
  double _cardWidth = 220;
  String? _selectedBlockId;
  bool _detailPanelExpanded = false;

  // 屏幕级多选状态（与 [_selectedBlockId] 同层；本页消费者全在 screen 内，
  // 不引 provider——画廊用 provider 是因为跨 widget 消费）。
  bool _multiSelectMode = false;
  final Set<String> _multiSelectedIds = <String>{};
  String? _lastSelectedId;

  // ---- 详情栏开合的滚动锚定 ----
  // 详情栏展开/收起挤压主区宽度会重排网格，像素位置对应的内容漂移
  // （视图跳走）。切换前记录视口顶部可见卡的滚动偏移，在 200ms
  // 宽度动画的每一帧把该卡钉回原位置。
  final GlobalKey _contentAreaKey = GlobalKey();
  List<_CardAnchor>? _pendingAnchors;
  double _pendingAnchorRatio = 0;
  int _anchorFramesLeft = 0;

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final storedMode = prefs.getString(StorageKeys.promptBlockLibraryViewMode);
    final storedWidth = prefs.getDouble(
      StorageKeys.promptBlockLibraryCardWidth,
    );
    final storedSortField = PromptBlockSortField.fromStorage(
      prefs.getString(StorageKeys.promptBlockLibrarySortField),
    );
    final storedSortDescending = prefs.getBool(
      StorageKeys.promptBlockLibrarySortDescending,
    );
    setState(() {
      _viewMode = switch (storedMode) {
        'list' => _PromptBlockViewMode.list,
        'waterfall' => _PromptBlockViewMode.waterfall,
        _ => _PromptBlockViewMode.grid,
      };
      _cardWidth = _snapCardWidth(storedWidth ?? 220);
      if (storedSortField != null) _sortField = storedSortField;
      if (storedSortDescending != null) _sortDescending = storedSortDescending;
    });
  }

  Future<void> _setSortField(PromptBlockSortField field) async {
    setState(() => _sortField = field);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.promptBlockLibrarySortField,
      field.storageValue,
    );
  }

  Future<void> _toggleSortDirection() async {
    setState(() => _sortDescending = !_sortDescending);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      StorageKeys.promptBlockLibrarySortDescending,
      _sortDescending,
    );
  }

  Future<void> _setViewMode(_PromptBlockViewMode mode) async {
    setState(() => _viewMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.promptBlockLibraryViewMode,
      switch (mode) {
        _PromptBlockViewMode.list => 'list',
        _PromptBlockViewMode.waterfall => 'waterfall',
        _PromptBlockViewMode.grid => 'grid',
      },
    );
  }

  void _setCardWidth(double value) {
    setState(() => _cardWidth = _snapCardWidth(value));
  }

  Future<void> _persistCardWidth(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
      StorageKeys.promptBlockLibraryCardWidth,
      _snapCardWidth(value),
    );
  }

  double _snapCardWidth(double value) {
    final clamped = value.clamp(100.0, 320.0).toDouble();
    return 100 + ((clamped - 100) / 20).round() * 20;
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(promptBlockLibraryNotifierProvider);
    return Scaffold(
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (_multiSelectMode) _exitMultiSelect();
          },
        },
        child: Focus(
          autofocus: true,
          skipTraversal: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showSidebar = constraints.maxWidth >= 760;
              final state = library.valueOrNull;
              final visibleBlocks = state == null
                  ? const <PromptBlock>[]
                  : _visibleBlocks(state);
              final selectedBlock = _selectedVisibleBlock(visibleBlocks);
              if (_selectedCollectionId != null &&
                  state != null &&
                  state.collectionById(_selectedCollectionId!) == null) {
                // 选中收藏集/收藏文件夹被删 → 回退到「收藏」视图。
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _selectedCollectionId != null) {
                    _selectScope(favorites: true);
                  }
                });
              }
              if (_selectedBlockId != null && selectedBlock == null) {
                final staleId = _selectedBlockId;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _selectedBlockId != staleId) return;
                  setState(() {
                    _selectedBlockId = null;
                  });
                });
              }
              final showDetailPanel = constraints.maxWidth >= 720;
              return Row(
                children: [
                  if (showSidebar) _buildSidebar(context, library),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildToolbar(context, library),
                        if (!showSidebar && library.valueOrNull != null)
                          _buildCompactFolderSelector(library.requireValue),
                        Expanded(
                          child: KeyedSubtree(
                            key: _contentAreaKey,
                            child: _buildContent(context, library),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showDetailPanel)
                    _buildDetailRail(
                      selectedBlock,
                      state?.folders ?? const <PromptBlockFolder>[],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  PromptBlock? _selectedVisibleBlock(List<PromptBlock> blocks) {
    final selectedId = _selectedBlockId;
    if (selectedId == null) return null;
    for (final block in blocks) {
      if (block.id == selectedId) return block;
    }
    return null;
  }

  Widget _buildDetailRail(PromptBlock? block, List<PromptBlockFolder> folders) {
    final theme = Theme.of(context);
    final width = _detailPanelExpanded ? 320.0 : 40.0;
    return ClipRect(
      child: AnimatedContainer(
        key: const Key('prompt-block-detail-rail'),
        duration: const Duration(milliseconds: 200),
        width: width,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(left: BorderSide(color: theme.dividerColor)),
        ),
        child: !_detailPanelExpanded
            ? PromptBlockDetailRailCollapsed(
                onExpand: () => _setDetailPanelExpanded(true),
              )
            : _multiSelectMode
            ? _buildEmptyDetailPanel(
                icon: Icons.checklist,
                message:
                    '${context.l10n.promptBlockLibrary_selectedCount(_multiSelectedIds.length)}\n拖动已选块到左侧的收藏或文件夹，松开后选择复制或移动。',
              )
            : block != null
            ? PromptBlockDetailPanel(
                block: block,
                folders: folders,
                onEdit: () => _openBlockEdit(block),
                onToggleFavorite: (anchor) => _showFavoriteMenu(block, anchor),
                onCopy: () => AppToast.success(
                  context,
                  context.l10n.promptBlockLibrary_copied,
                ),
                onAddTag: (anchor) => _showTagMenu([block.id], anchor),
                onDelete: () => _deleteBlock(context, block),
                onTagTap: (tag) => setState(() => _selectedTag = tag),
                onCollapse: () => _setDetailPanelExpanded(false),
              )
            : _buildEmptyDetailPanel(),
      ),
    );
  }

  Widget _buildEmptyDetailPanel({
    IconData icon = Icons.touch_app_outlined,
    String? message,
  }) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 280) return const SizedBox.expand();
        return Material(
          key: const Key('prompt-block-detail-empty'),
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              SizedBox(
                height: promptBlockLibraryWideHeaderHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 19,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.promptBlockLibrary_details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('prompt-block-detail-collapse'),
                        tooltip: l10n.common_collapse,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _setDetailPanelExpanded(false),
                        icon: const Icon(Icons.keyboard_arrow_right),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 28,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message ?? l10n.promptBlockLibrary_noBlockSelected,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    AsyncValue<PromptBlockLibraryState> library,
  ) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 240,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          border: Border(
            right: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              // 与主工具栏同高（64）垂直居中，两边分隔线/基线对齐。
              height: promptBlockLibraryWideHeaderHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_copy_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.promptBlockLibrary_folders,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.promptBlockLibrary_newFolder,
                      onPressed: () => _showFolderNameDialog(context),
                      icon: const Icon(
                        Icons.create_new_folder_outlined,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            Expanded(
              child: library.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _buildRetryView(context, error),
                data: (state) => PromptBlockFolderTree(
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
                  selectedFolderId: _selectedFolderId,
                  selectedCollectionId: _selectedCollectionId,
                  onSelectAll: () => _selectScope(all: true),
                  onSelectRoot: () => _selectScope(),
                  onSelectFavorites: () => _selectScope(favorites: true),
                  onSelectFolder: (id) => _selectScope(folderId: id),
                  onSelectCollection: (id) => _selectScope(collectionId: id),
                  onCreateFolder: (parentId) =>
                      _showFolderNameDialog(context, parentId: parentId),
                  onRenameFolder: (id) => _renameFolder(context, state, id),
                  onMoveFolderToRoot: (id) => _moveFolderToRoot(context, id),
                  onDeleteFolder: (id) => _deleteFolder(context, state, id),
                  onReorderFolders: _reorderFolders,
                  onCreateCollection: (parentId, isFolder) =>
                      _showCollectionNameDialog(
                        context,
                        parentId: parentId,
                        isFolder: isFolder,
                      ),
                  onRenameCollection: (id) =>
                      _renameCollection(context, state, id),
                  onMoveCollection: (id, newParentId) =>
                      _moveCollection(context, id, newParentId),
                  onDeleteCollection: (id) =>
                      _deleteCollection(context, state, id),
                  onReorderCollections: _reorderCollections,
                  onAddBlockToCollection: _addBlockToCollection,
                  onDropBlockOnFavorites: _favoriteBlockFromDrop,
                  onDropBlocks: _handleSidebarDrop,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    AsyncValue<PromptBlockLibraryState> library,
  ) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, toolbarConstraints) {
        final compact = toolbarConstraints.maxWidth < 792;
        return Container(
          key: const Key('prompt-block-toolbar'),
          height: compact ? null : promptBlockLibraryWideHeaderHeight,
          constraints: compact ? const BoxConstraints(minHeight: 62) : null,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: compact ? 12 : 8,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final actions = _multiSelectMode
                  ? _buildMultiSelectActions(context, library)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<String>(
                          tooltip: context.l10n.promptBlockLibrary_importExport,
                          icon: const Icon(Icons.import_export),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'importTxt',
                              child: Text(
                                context.l10n.promptBlockLibrary_importTxtFiles,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'importFolder',
                              child: Text(
                                context
                                    .l10n
                                    .promptBlockLibrary_importFromFolder,
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'exportBackup',
                              child: Text(
                                context
                                    .l10n
                                    .promptBlockLibrary_exportLibraryBackup,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'importBackup',
                              child: Text(
                                context
                                    .l10n
                                    .promptBlockLibrary_importLibraryBackup,
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'importTxt':
                                _importTxtFiles();
                              case 'importFolder':
                                _importFromFolder();
                              case 'exportBackup':
                                _exportLibraryBackup();
                              case 'importBackup':
                                _importLibraryBackup();
                            }
                          },
                        ),
                        ToggleButtons(
                          key: const Key('prompt-block-view-mode'),
                          isSelected: [
                            _viewMode == _PromptBlockViewMode.list,
                            _viewMode == _PromptBlockViewMode.grid,
                            _viewMode == _PromptBlockViewMode.waterfall,
                          ],
                          onPressed: (index) => _setViewMode(switch (index) {
                            0 => _PromptBlockViewMode.list,
                            2 => _PromptBlockViewMode.waterfall,
                            _ => _PromptBlockViewMode.grid,
                          }),
                          borderRadius: BorderRadius.circular(8),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          children: [
                            Tooltip(
                              message: context.l10n.promptBlockLibrary_listView,
                              child: const Icon(
                                Icons.view_agenda_outlined,
                                size: 18,
                              ),
                            ),
                            Tooltip(
                              message: context.l10n.promptBlockLibrary_gridView,
                              child: const Icon(
                                Icons.grid_view_outlined,
                                size: 18,
                              ),
                            ),
                            Tooltip(
                              message:
                                  context.l10n.promptBlockLibrary_waterfallView,
                              child: const Icon(
                                Icons.view_quilt_outlined,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          key: const Key('prompt-block-multi-select-toggle'),
                          tooltip: context.l10n.promptBlockLibrary_multiSelect,
                          onPressed: () => _enterMultiSelectEmpty(),
                          icon: const Icon(Icons.checklist, size: 20),
                        ),
                        _buildSortControls(context),
                        IconButton(
                          tooltip: context.l10n.common_refresh,
                          onPressed: () => ref
                              .read(promptBlockLibraryNotifierProvider.notifier)
                              .refresh(),
                          icon: const Icon(Icons.refresh),
                        ),
                        FilledButton.icon(
                          onPressed: () => _showFolderNameDialog(context),
                          icon: const Icon(
                            Icons.create_new_folder_outlined,
                            size: 18,
                          ),
                          label: Text(
                            context.l10n.promptBlockLibrary_newFolder,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () => _showCreateBlock(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(context.l10n.promptBlockLibrary_newBlock),
                        ),
                      ],
                    );

              final heading = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    StudioIcons.promptBlocks,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.promptBlockLibrary_title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (library.valueOrNull != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${_visibleBlocks(library.requireValue).length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              );

              final search = _buildSearchField(context);
              if (compact) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: heading),
                        IconButton(
                          tooltip: context.l10n.common_refresh,
                          onPressed: () => ref
                              .read(promptBlockLibraryNotifierProvider.notifier)
                              .refresh(),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    search,
                    if (_selectedTag != null) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildActiveTagFilter(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: actions,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  heading,
                  const SizedBox(width: 16),
                  Expanded(child: search),
                  if (_selectedTag != null) ...[
                    const SizedBox(width: 8),
                    _buildActiveTagFilter(),
                  ],
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// 多选模式下工具栏右侧换出的批量操作行。
  Widget _buildMultiSelectActions(
    BuildContext context,
    AsyncValue<PromptBlockLibraryState> library,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = library.valueOrNull;
    final visible = state == null
        ? const <PromptBlock>[]
        : _visibleBlocks(state);
    final allSelected =
        visible.isNotEmpty &&
        visible.every((block) => _multiSelectedIds.contains(block.id));
    final hasSelection = _multiSelectedIds.isNotEmpty;
    return Row(
      key: const Key('prompt-block-multi-select-actions'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.promptBlockLibrary_selectedCount(_multiSelectedIds.length),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: const Key('prompt-block-multi-select-all'),
          tooltip: allSelected
              ? l10n.promptBlockLibrary_clearSelection
              : l10n.promptBlockLibrary_selectAllVisible,
          onPressed: () => allSelected
              ? setState(() => _multiSelectedIds.clear())
              : _selectAllVisible(visible),
          icon: Icon(allSelected ? Icons.deselect : Icons.select_all, size: 19),
        ),
        const SizedBox(width: 4),
        Builder(
          builder: (buttonContext) => IconButton(
            tooltip: l10n.common_favorite,
            onPressed: hasSelection
                ? () => _showOrganizerAtButton(
                    BlockOrganizerPage.favorites,
                    buttonContext,
                  )
                : null,
            icon: const Icon(Icons.star_border, size: 19),
          ),
        ),
        Builder(
          builder: (buttonContext) => IconButton(
            tooltip: '添加标签',
            onPressed: hasSelection
                ? () => _showOrganizerAtButton(
                    BlockOrganizerPage.tags,
                    buttonContext,
                  )
                : null,
            icon: const Icon(Icons.sell_outlined, size: 19),
          ),
        ),
        Builder(
          builder: (buttonContext) => IconButton(
            key: const Key('prompt-block-multi-select-move'),
            tooltip: l10n.promptBlockLibrary_moveTo,
            onPressed: hasSelection
                ? () => _showOrganizerAtButton(
                    BlockOrganizerPage.folders,
                    buttonContext,
                  )
                : null,
            icon: const Icon(Icons.drive_file_move_outline, size: 19),
          ),
        ),
        IconButton(
          key: const Key('prompt-block-multi-select-delete'),
          tooltip: l10n.promptBlockLibrary_deleteSelected(
            _multiSelectedIds.length,
          ),
          onPressed: hasSelection
              ? () => _deleteBlocks(context, _multiSelectedIds.toList())
              : null,
          icon: Icon(
            Icons.delete_outline,
            size: 19,
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          key: const Key('prompt-block-multi-select-exit'),
          tooltip: l10n.promptBlockLibrary_exitMultiSelect,
          onPressed: _exitMultiSelect,
          icon: const Icon(Icons.close, size: 19),
        ),
      ],
    );
  }

  void _selectAllVisible(List<PromptBlock> visible) {
    if (visible.isEmpty) return;
    setState(() {
      _multiSelectedIds.addAll(visible.map((block) => block.id));
      _lastSelectedId ??= visible.last.id;
    });
  }

  Offset _anchorOf(BuildContext buttonContext) {
    final box = buttonContext.findRenderObject();
    return box is RenderBox ? box.localToGlobal(Offset.zero) : Offset.zero;
  }

  void _showOrganizerAtButton(
    BlockOrganizerPage page,
    BuildContext buttonContext,
  ) {
    final ids = _multiSelectedIds.toList();
    if (ids.isEmpty) return;
    showBlockOrganizerPopover(
      context,
      blockIds: ids,
      anchor: _anchorOf(buttonContext),
      page: page,
      sourceCollectionId: _selectedCollectionId,
      sourceFavorites: _favoritesSelected,
    );
  }

  void _showTagMenu(List<String> ids, Offset anchor) =>
      showBlockOrganizerPopover(
        context,
        blockIds: ids,
        anchor: anchor,
        page: BlockOrganizerPage.tags,
      );

  void _handleSidebarDrop(
    PromptBlockDragData data,
    PromptBlockTransferTarget target,
    Offset offset,
  ) {
    showBlockOrganizerPopover(
      context,
      blockIds: data.transferIds,
      anchor: offset,
      page: target.kind == PromptBlockTransferKind.folder
          ? BlockOrganizerPage.folders
          : BlockOrganizerPage.favorites,
      dropTarget: target,
      sourceCollectionId: data.sourceCollectionId,
      sourceFavorites: data.sourceFavorites,
    );
  }

  Widget _dragSource(PromptBlock block, Widget child) {
    final ids = _multiSelectMode && _multiSelectedIds.contains(block.id)
        ? _multiSelectedIds.toList()
        : [block.id];
    final theme = Theme.of(context);
    return Draggable<PromptBlockDragData>(
      data: PromptBlockDragData(
        blockId: block.id,
        blockIds: ids,
        sourceCollectionId: _selectedCollectionId,
        sourceFavorites: _favoritesSelected,
      ),
      rootOverlay: true,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        elevation: 7,
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                StudioIcons.promptBlocks,
                size: 17,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 7),
              Text(ids.length == 1 ? block.displayTitle : '${ids.length} 个块'),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: child),
      child: child,
    );
  }

  Widget _buildSortControls(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<PromptBlockSortField>(
          key: const Key('prompt-block-sort-field'),
          tooltip: l10n.promptBlockLibrary_sortBy,
          initialValue: _sortField,
          position: PopupMenuPosition.under,
          onSelected: _setSortField,
          itemBuilder: (context) => [
            for (final field in PromptBlockSortField.values)
              PopupMenuItem(
                value: field,
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: field == _sortField
                          ? const Icon(Icons.check, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Text(_sortFieldLabel(context, field)),
                  ],
                ),
              ),
          ],
        ),
        IconButton(
          key: const Key('prompt-block-sort-direction'),
          tooltip: _sortDescending
              ? l10n.promptBlockLibrary_sortDescending
              : l10n.promptBlockLibrary_sortAscending,
          onPressed: _sortField.overridesManualOrder
              ? _toggleSortDirection
              : null,
          icon: Icon(
            _sortDescending ? Icons.south : Icons.north,
            size: 18,
            color: _sortField.overridesManualOrder
                ? theme.colorScheme.primary
                : null,
          ),
        ),
      ],
    );
  }

  String _sortFieldLabel(BuildContext context, PromptBlockSortField field) {
    final l10n = context.l10n;
    return switch (field) {
      PromptBlockSortField.custom => l10n.promptBlockLibrary_sortCustom,
      PromptBlockSortField.updated => l10n.promptBlockLibrary_sortUpdated,
      PromptBlockSortField.title => l10n.promptBlockLibrary_sortTitle,
      PromptBlockSortField.color => l10n.promptBlockLibrary_sortColor,
      PromptBlockSortField.icon => l10n.promptBlockLibrary_sortIcon,
    };
  }

  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: SizedBox(
        height: 36,
        child: TextField(
          key: const Key('prompt-block-library-search'),
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: theme.textTheme.bodyMedium,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: context.l10n.promptBlockLibrary_searchHint,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 13,
            ),
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: context.l10n.common_clear,
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close, size: 16),
                  ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            isDense: true,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTagFilter() {
    return InputChip(
      key: const Key('prompt-block-active-tag-filter'),
      avatar: const Icon(Icons.local_offer_outlined, size: 14),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 110),
        child: Text(
          _selectedTag!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      onDeleted: () => setState(() => _selectedTag = null),
      visualDensity: VisualDensity.compact,
    );
  }

  /// 窄布局备用：范围选择退化为下拉框。
  /// 编码约定：`__all__` 全部块 / `__fav__` 收藏 / `coll:<id>` 收藏集节点 /
  /// `__root__` 根目录 / 其余为文件夹 id。
  Widget _buildCompactFolderSelector(PromptBlockLibraryState state) {
    const favoritesValue = '__fav__';
    const collectionPrefix = 'coll:';
    final l10n = context.l10n;
    final value = _allSelected
        ? '__all__'
        : _favoritesSelected
        ? favoritesValue
        : _selectedCollectionId != null
        ? '$collectionPrefix$_selectedCollectionId'
        : (_selectedFolderId ?? '__root__');
    final folders = state.folders.toList()
      ..sort(
        (a, b) => a.sortOrder == b.sortOrder
            ? a.id.compareTo(b.id)
            : a.sortOrder.compareTo(b.sortOrder),
      );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: l10n.promptBlockLibrary_scope,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          DropdownMenuItem(
            value: '__all__',
            child: Text(l10n.promptBlockLibrary_allBlocks),
          ),
          DropdownMenuItem(
            value: favoritesValue,
            child: Text(
              '${l10n.promptBlockLibrary_favorites} · ${state.favoriteBlocks.length}',
            ),
          ),
          ...state.collectionTreeOrder().map(
            (id) => DropdownMenuItem(
              value: '$collectionPrefix$id',
              child: Text(
                state.collectionPath(id),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          DropdownMenuItem(
            value: '__root__',
            child: Text(l10n.promptBlockLibrary_rootFolder),
          ),
          ...folders.map(
            (folder) => DropdownMenuItem(
              value: folder.id,
              child: Text(
                folder.name.isEmpty
                    ? l10n.promptBlockLibrary_unnamedFolder
                    : folder.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: (value) {
          if (value == '__all__') {
            _selectScope(all: true);
          } else if (value == favoritesValue) {
            _selectScope(favorites: true);
          } else if (value != null && value.startsWith(collectionPrefix)) {
            _selectScope(
              collectionId: value.substring(collectionPrefix.length),
            );
          } else if (value == '__root__') {
            _selectScope();
          } else if (value != null) {
            _selectScope(folderId: value);
          }
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncValue<PromptBlockLibraryState> library,
  ) {
    return GestureDetector(
      // 点击空白区域退出多选；点在块上时子级 InkWell 消费事件，不会走到这里。
      onTap: _multiSelectMode ? _exitMultiSelect : null,
      child: library.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildRetryView(context, error),
        data: (state) {
          final blocks = _visibleBlocks(state);
          if (blocks.isEmpty) return _buildEmptyState(context, state);

          // 文件夹/根目录范围且子树跨多个有直属块的文件夹 → 分段 + sticky 标题；
          // 搜索/自定义排序/全部块/收藏/收藏集范围保持平铺。
          final sections = _folderSections(state);
          if (sections != null) {
            return _buildGroupedContent(context, sections, state.folders);
          }

          if (_viewMode == _PromptBlockViewMode.grid) {
            return _buildGrid(context, blocks, state.folders);
          }
          if (_viewMode == _PromptBlockViewMode.waterfall) {
            return _buildWaterfall(context, blocks, state.folders);
          }

          // 聚合视图里混有后代文件夹的块，跨文件夹拖排没有意义；
          // repository 的同级完整性校验也会拒绝这种重排，这里直接不提供把手。
          // 自定义排序下顺序由字段决定，手动拖排同样没有意义。
          final reorderable =
              !_allSelected &&
              !_favoritesSelected &&
              _selectedCollectionId == null &&
              !_sortField.overridesManualOrder &&
              _searchController.text.trim().isEmpty &&
              _selectedTag == null &&
              blocks.every((block) => block.folderId == _selectedFolderId);
          if (reorderable) {
            return ReorderableListView.builder(
              key: const Key('prompt-block-list'),
              padding: const EdgeInsets.all(16),
              buildDefaultDragHandles: false,
              itemCount: blocks.length,
              onReorderItem: (oldIndex, newIndex) =>
                  _reorderBlocks(state, blocks, oldIndex, newIndex),
              itemBuilder: (context, index) => _buildBlockItem(
                context,
                blocks[index],
                folders: state.folders,
                // 多选激活时禁用重排把手，避免选择态与拖排歧义。
                reorderIndex: _multiSelectMode ? null : index,
              ),
            );
          }

          return ListView.builder(
            key: const Key('prompt-block-list'),
            padding: const EdgeInsets.all(16),
            itemCount: blocks.length,
            itemBuilder: (context, index) =>
                _buildBlockItem(context, blocks[index], folders: state.folders),
          );
        },
      ),
    );
  }

  /// 分段判定：仅文件夹/根目录范围 + 无搜索 + custom 排序时分组；
  /// 返回 null 走平铺。DFS 序遍历子树，每个有直属块的文件夹成一段；
  /// 根目录范围先出「未分类」段，再按文件夹树逐段展开。
  List<_FolderSection>? _folderSections(PromptBlockLibraryState state) {
    if (_allSelected || _favoritesSelected || _selectedCollectionId != null) {
      return null;
    }
    if (_searchController.text.trim().isNotEmpty) return null;
    if (_selectedTag != null) return null;
    if (_sortField.overridesManualOrder) return null;
    if (_selectedFolderId != null &&
        state.folderById(_selectedFolderId!) == null) {
      return null;
    }

    final sections = <_FolderSection>[];

    void collect(String? folderId) {
      final direct = state.blocksInFolder(folderId);
      if (direct.isNotEmpty) {
        sections.add(
          _FolderSection(
            title: folderId == null
                ? context.l10n.promptBlockLibrary_unclassified
                : state.folderPath(folderId),
            blocks: direct,
          ),
        );
      }
      for (final folder in state.foldersIn(folderId)) {
        collect(folder.id);
      }
    }

    collect(_selectedFolderId);
    // 单段时标题栏是纯装饰，保持平铺。
    return sections.length > 1 ? sections : null;
  }

  /// 分段视图：统一 CustomScrollView，各段包在 SliverMainAxisGroup 里
  /// （pinned sticky 标题 + 段体 sliver；grid=SliverGrid / list=SliverList /
  /// 瀑布流=SliverToBoxAdapter(shrinkWrap MasonryGridView，原因见段内注释) /
  /// 药丸=SliverToBoxAdapter(Wrap)）。
  Widget _buildGroupedContent(
    BuildContext context,
    List<_FolderSection> sections,
    List<PromptBlockFolder> folders,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderWidth = (constraints.maxWidth - 74)
            .clamp(80.0, 164.0)
            .toDouble();
        final columnCount = (constraints.maxWidth / _cardWidth).floor().clamp(
          1,
          10,
        );
        final pillMode =
            _viewMode == _PromptBlockViewMode.grid && _cardWidth <= 160;
        final cardHeight = _cardWidth < 240 ? 174.0 : 208.0;

        Widget sectionSliver(_FolderSection section) {
          if (_viewMode == _PromptBlockViewMode.list) {
            return SliverList.builder(
              itemCount: section.blocks.length,
              itemBuilder: (context, index) => _buildBlockItem(
                context,
                section.blocks[index],
                folders: folders,
              ),
            );
          }
          if (_viewMode == _PromptBlockViewMode.waterfall) {
            // 分段里的瀑布流必须是盒式子树：SliverMasonryGrid 被整体滚出
            // 视口后 collectGarbage 只留末尾子节点，回插 leading child 时
            // 给出的 scrollOffsetCorrection 会把滚动位置弹回段首。
            return SliverToBoxAdapter(
              child: MasonryGridView.count(
                shrinkWrap: true,
                primary: false,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                crossAxisCount: columnCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemBuilder: (context, index) => _buildWaterfallCard(
                  context,
                  section.blocks[index],
                  folders: folders,
                ),
                itemCount: section.blocks.length,
              ),
            );
          }
          if (pillMode) {
            return SliverToBoxAdapter(
              child: Wrap(
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final block in section.blocks)
                    _buildBlockPill(
                      context,
                      block,
                      maxWidth: _cardWidth,
                      folders: folders,
                    ),
                ],
              ),
            );
          }
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: _cardWidth,
              mainAxisExtent: cardHeight,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildBlockCard(
                context,
                section.blocks[index],
                width: _cardWidth,
                folders: folders,
              ),
              childCount: section.blocks.length,
            ),
          );
        }

        return Stack(
          key: const Key('prompt-block-grouped-stack'),
          children: [
            Positioned.fill(
              child: CustomScrollView(
                key: const Key('prompt-block-grouped-scroll'),
                slivers: [
                  // 每段包一层 SliverMainAxisGroup：本机 SDK 的 pinned 头按
                  // constraints.overlap 堆叠而不互推，分组才能把「顶走上一
                  // 段标题」的语义找回来。
                  for (final section in sections)
                    SliverMainAxisGroup(
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _FolderSectionHeaderDelegate(
                            title: section.title,
                            count: section.blocks.length,
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          sliver: sectionSliver(section),
                        ),
                      ],
                    ),
                  // 底部留白避开悬浮滑杆。
                  const SliverToBoxAdapter(child: SizedBox(height: 70)),
                ],
              ),
            ),
            if (_viewMode != _PromptBlockViewMode.list)
              Positioned(
                right: 16,
                bottom: 12,
                child: _buildCardSizeControl(context, sliderWidth),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<PromptBlock> blocks,
    List<PromptBlockFolder> folders,
  ) {
    if (_cardWidth <= 160) return _buildPillGrid(context, blocks, folders);

    final cardHeight = _cardWidth < 240 ? 174.0 : 208.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderWidth = (constraints.maxWidth - 74)
            .clamp(80.0, 164.0)
            .toDouble();
        return Stack(
          key: const Key('prompt-block-grid-stack'),
          children: [
            Positioned.fill(
              child: GridView.builder(
                key: const Key('prompt-block-grid'),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 82),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: _cardWidth,
                  mainAxisExtent: cardHeight,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: blocks.length,
                itemBuilder: (context, index) => _buildBlockCard(
                  context,
                  blocks[index],
                  width: _cardWidth,
                  folders: folders,
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 12,
              child: _buildCardSizeControl(context, sliderWidth),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPillGrid(
    BuildContext context,
    List<PromptBlock> blocks,
    List<PromptBlockFolder> folders,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderWidth = (constraints.maxWidth - 74)
            .clamp(80.0, 164.0)
            .toDouble();
        return Stack(
          key: const Key('prompt-block-grid-stack'),
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                key: const Key('prompt-block-pill-grid-scroll'),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 82),
                child: Wrap(
                  alignment: WrapAlignment.start,
                  runAlignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final block in blocks)
                      _buildBlockPill(
                        context,
                        block,
                        maxWidth: _cardWidth,
                        folders: folders,
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 12,
              child: _buildCardSizeControl(context, sliderWidth),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlockPill(
    BuildContext context,
    PromptBlock block, {
    required double maxWidth,
    required List<PromptBlockFolder> folders,
  }) {
    final title = block.title.isEmpty
        ? context.l10n.promptBlockLibrary_unnamedBlock
        : block.title;
    return PromptBlockHoverPreview(
      // 按表面类型分 key：切视图/卡片尺寸跨档时旧 hover state 销毁，
      // 预览浮层随旧表面移除，不会钉到新表面上。
      key: ValueKey('pill-${block.id}'),
      block: block,
      folders: folders,
      enabled: !_multiSelectMode,
      child: _dragSource(
        block,
        PromptBlockPill(
          block: block,
          displayTitle: title,
          maxWidth: maxWidth,
          selected: _isBlockShownSelected(block.id),
          multiSelected: _isBlockMultiSelected(block.id),
          onSecondaryTap: (details) =>
              _showBlockContextMenu(context, block, details.globalPosition),
          onTap: () => _handleBlockTap(block),
        ),
      ),
    );
  }

  Widget _buildCardSizeControl(BuildContext context, double sliderWidth) {
    final theme = Theme.of(context);
    return Tooltip(
      message: context.l10n.promptBlockLibrary_cardSize,
      child: Material(
        elevation: 3,
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.view_module_outlined,
                size: 17,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(
                width: sliderWidth,
                child: Slider(
                  key: const Key('prompt-block-card-size-slider'),
                  value: _cardWidth,
                  min: 100,
                  max: 320,
                  divisions: 11,
                  label: '${_cardWidth.round()}',
                  onChanged: _setCardWidth,
                  onChangeEnd: _persistCardWidth,
                ),
              ),
              Icon(
                Icons.view_module,
                size: 19,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 瀑布流视图（FEAT-1）：有图块按真实宽高比排列，无图块呈老样式长条。
  /// 列数沿用卡片尺寸滑杆（逻辑列宽 = _cardWidth），与 grid 共用。
  Widget _buildWaterfall(
    BuildContext context,
    List<PromptBlock> blocks,
    List<PromptBlockFolder> folders,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderWidth = (constraints.maxWidth - 74)
            .clamp(80.0, 164.0)
            .toDouble();
        final columnCount = (constraints.maxWidth / _cardWidth).floor().clamp(
          1,
          10,
        );
        return Stack(
          key: const Key('prompt-block-waterfall-stack'),
          children: [
            Positioned.fill(
              child: MasonryGridView.count(
                key: const Key('prompt-block-waterfall'),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 82),
                crossAxisCount: columnCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: blocks.length,
                itemBuilder: (context, index) => _buildWaterfallCard(
                  context,
                  blocks[index],
                  folders: folders,
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 12,
              child: _buildCardSizeControl(context, sliderWidth),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWaterfallCard(
    BuildContext context,
    PromptBlock block, {
    required List<PromptBlockFolder> folders,
  }) {
    final title = block.title.isEmpty
        ? context.l10n.promptBlockLibrary_unnamedBlock
        : block.title;
    return PromptBlockHoverPreview(
      key: ValueKey('waterfall-${block.id}'),
      block: block,
      folders: folders,
      enabled: !_multiSelectMode,
      child: _dragSource(
        block,
        PromptBlockWaterfallCard(
          block: block,
          displayTitle: title,
          selected: _isBlockShownSelected(block.id),
          multiSelected: _isBlockMultiSelected(block.id),
          onSecondaryTap: (details) =>
              _showBlockContextMenu(context, block, details.globalPosition),
          onTap: () => _handleBlockTap(block),
        ),
      ),
    );
  }

  Widget _buildBlockItem(
    BuildContext context,
    PromptBlock block, {
    required List<PromptBlockFolder> folders,
    int? reorderIndex,
  }) {
    final title = block.title.isEmpty
        ? context.l10n.promptBlockLibrary_unnamedBlock
        : block.title;
    return PromptBlockHoverPreview(
      key: ValueKey('item-${block.id}'),
      block: block,
      folders: folders,
      enabled: !_multiSelectMode,
      child: _dragSource(
        block,
        PromptBlockListItem(
          block: block,
          displayTitle: title,
          reorderIndex: reorderIndex,
          selected: _isBlockShownSelected(block.id),
          multiSelected: _isBlockMultiSelected(block.id),
          onSecondaryTap: (details) =>
              _showBlockContextMenu(context, block, details.globalPosition),
          onTap: () => _handleBlockTap(block),
          onEdit: () => _handleBlockEditButton(block),
          onCopy: () =>
              AppToast.success(context, context.l10n.promptBlockLibrary_copied),
          onAddTag: (anchor) => _showTagMenu([block.id], anchor),
          onToggleFavorite: (anchor) => _showFavoriteMenu(block, anchor),
          onDelete: () => _deleteBlock(context, block),
        ),
      ),
    );
  }

  Widget _buildBlockCard(
    BuildContext context,
    PromptBlock block, {
    required double width,
    required List<PromptBlockFolder> folders,
  }) {
    final title = block.title.isEmpty
        ? context.l10n.promptBlockLibrary_unnamedBlock
        : block.title;
    return PromptBlockHoverPreview(
      key: ValueKey('card-${block.id}'),
      block: block,
      folders: folders,
      enabled: !_multiSelectMode,
      child: _dragSource(
        block,
        PromptBlockCard(
          block: block,
          displayTitle: title,
          width: width,
          selected: _isBlockShownSelected(block.id),
          multiSelected: _isBlockMultiSelected(block.id),
          onSecondaryTap: (details) =>
              _showBlockContextMenu(context, block, details.globalPosition),
          onTap: () => _handleBlockTap(block),
          onEdit: () => _handleBlockEditButton(block),
          onCopy: () =>
              AppToast.success(context, context.l10n.promptBlockLibrary_copied),
          onAddTag: (anchor) => _showTagMenu([block.id], anchor),
          onToggleFavorite: (anchor) => _showFavoriteMenu(block, anchor),
          onDelete: () => _deleteBlock(context, block),
        ),
      ),
    );
  }

  /// 详情栏开合统一入口：宽度动画期间把视口锚卡钉住，防止重排跳走。
  void _setDetailPanelExpanded(bool expanded) {
    if (_detailPanelExpanded == expanded) return;
    final anchors = _captureCardAnchors();
    setState(() => _detailPanelExpanded = expanded);
    _scheduleAnchorRestore(anchors);
  }

  /// 主区当前主滚动组件（分段视图外层 CustomScrollView / 平铺视图的
  /// GridView·MasonryGridView·ListView）；DFS 先命中外层。
  ScrollableState? _contentScrollable() {
    final ctx = _contentAreaKey.currentContext;
    if (ctx == null) return null;
    ScrollableState? result;
    void visit(Element element) {
      if (result != null) return;
      if (element.widget is Scrollable) {
        result = (element as StatefulElement).state as ScrollableState;
        return;
      }
      element.visitChildElements(visit);
    }

    ctx.visitChildElements(visit);
    return result;
  }

  /// 主滚动组件的外层 Viewport 渲染对象。嵌套 shrinkWrap 滚动组件
  /// 自带内层 viewport，锚定必须统一用外层坐标系。
  RenderAbstractViewport? _contentViewport(ScrollableState scrollable) {
    RenderAbstractViewport? result;
    void visit(Element element) {
      if (result != null) return;
      final ro = element.findRenderObject();
      if (ro is RenderAbstractViewport) {
        result = ro;
        return;
      }
      element.visitChildElements(visit);
    }

    scrollable.context.visitChildElements(visit);
    return result;
  }

  /// 记录视口顶部附近若干可见卡的锚点（多备几张：懒构建视图在
  /// 重排后锚卡可能被卸载，恢复时顺延到下一张仍挂载的）。
  List<_CardAnchor> _captureCardAnchors() {
    final scrollable = _contentScrollable();
    final position = scrollable?.position;
    if (scrollable == null ||
        position == null ||
        !position.hasPixels ||
        position.maxScrollExtent <= 0) {
      return const [];
    }
    final viewport = _contentViewport(scrollable);
    if (viewport == null) return const [];

    final anchors = <_CardAnchor>[];
    void visit(Element element) {
      if (element.widget is PromptBlockHoverPreview) {
        final key = element.widget.key;
        final ro = element.findRenderObject();
        if (key is ValueKey<String> && ro != null && ro.attached) {
          anchors.add(
            _CardAnchor(
              key.value,
              viewport.getOffsetToReveal(ro, 0).offset - position.pixels,
            ),
          );
        }
        return;
      }
      element.visitChildElements(visit);
    }

    scrollable.context.visitChildElements(visit);
    anchors.sort((a, b) => a.dy.compareTo(b.dy));
    // 视口顶上沿半张以内的卡也保留（部分可见卡同样可作锚点）。
    return anchors.where((a) => a.dy > -400).take(6).toList();
  }

  void _scheduleAnchorRestore(List<_CardAnchor> anchors) {
    final position = _contentScrollable()?.position;
    if (position == null || !position.hasPixels) return;
    _pendingAnchors = anchors;
    _pendingAnchorRatio = position.maxScrollExtent > 0
        ? position.pixels / position.maxScrollExtent
        : 0;
    if (_anchorFramesLeft == 0) {
      // 瞬时回调先于当帧 build/layout 执行，jumpTo 与宽度动画同帧
      // 生效，观感上是连续钉住而不是事后拉回。
      SchedulerBinding.instance.scheduleFrameCallback(_anchorFrame);
    }
    _anchorFramesLeft = 24; // ≈400ms @60fps，覆盖 200ms 动画余量
  }

  void _anchorFrame(Duration _) {
    if (!mounted) {
      _anchorFramesLeft = 0;
      _pendingAnchors = null;
      return;
    }
    _restoreCardAnchor();
    if (--_anchorFramesLeft > 0) {
      SchedulerBinding.instance.scheduleFrameCallback(_anchorFrame);
    } else {
      _pendingAnchors = null;
    }
  }

  void _restoreCardAnchor() {
    final scrollable = _contentScrollable();
    final position = scrollable?.position;
    if (scrollable == null ||
        position == null ||
        !position.hasContentDimensions) {
      return;
    }
    final viewport = _contentViewport(scrollable);
    if (viewport == null) return;

    final anchors = _pendingAnchors;
    if (anchors != null) {
      for (final anchor in anchors) {
        final ro = _findCardRenderObject(scrollable, anchor.cardKey);
        if (ro == null || !ro.attached) continue;
        final target = (viewport.getOffsetToReveal(ro, 0).offset - anchor.dy)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
        if ((target - position.pixels).abs() > 0.5) position.jumpTo(target);
        return;
      }
    }
    // 锚卡全部被卸载（懒构建滚出缓存）→ 按滚动比例兜底。
    final target = (_pendingAnchorRatio * position.maxScrollExtent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - position.pixels).abs() > 0.5) position.jumpTo(target);
  }

  RenderObject? _findCardRenderObject(
    ScrollableState scrollable,
    String cardKey,
  ) {
    RenderObject? found;
    void visit(Element element) {
      if (found != null) return;
      final w = element.widget;
      if (w is PromptBlockHoverPreview && w.key == ValueKey<String>(cardKey)) {
        found = element.findRenderObject();
        return;
      }
      element.visitChildElements(visit);
    }

    scrollable.context.visitChildElements(visit);
    return found;
  }

  void _selectBlock(PromptBlock block) {
    final expanding = !_detailPanelExpanded;
    final anchors = expanding ? _captureCardAnchors() : const <_CardAnchor>[];
    setState(() {
      _selectedBlockId = block.id;
      _detailPanelExpanded = true;
    });
    if (expanding) _scheduleAnchorRestore(anchors);
  }

  // ---- 多选状态机（屏幕级，方案见蓝图 L1） ----

  bool _isBlockShownSelected(String blockId) => _multiSelectMode
      ? _multiSelectedIds.contains(blockId)
      : _selectedBlockId == blockId;

  bool _isBlockMultiSelected(String blockId) =>
      _multiSelectMode && _multiSelectedIds.contains(blockId);

  bool _isCtrlPressed() {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight);
  }

  bool _isShiftPressed() {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight);
  }

  /// 块表面点击路由：多选模式内 toggle/范围选；Ctrl+点击进入多选；
  /// 其余走原有单选语义（打开右侧编辑栏）。
  void _handleBlockTap(PromptBlock block) {
    if (_multiSelectMode) {
      if (_isShiftPressed()) {
        _selectMultiRange(block);
      } else {
        _toggleMultiSelect(block.id);
      }
      return;
    }
    if (_isCtrlPressed()) {
      _enterMultiSelect(block.id);
      return;
    }
    _selectBlock(block);
  }

  /// 多选模式下点行尾/卡面「编辑」按钮：退出多选并打开完整编辑弹窗。
  void _handleBlockEditButton(PromptBlock block) {
    if (_multiSelectMode) _exitMultiSelect();
    _selectBlock(block);
    unawaited(_openBlockEdit(block));
  }

  /// 打开完整编辑弹窗并保存（详情面板的「编辑」入口）。
  Future<void> _openBlockEdit(PromptBlock block) async {
    final state = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    if (state == null || !mounted) return;
    final result = await PromptBlockEditDialog.show(
      context: context,
      block: block,
      folders: state.folders,
      knownTags: [for (final item in state.blocks) ...item.tags],
      modelForTokenCount: ref.read(generationParamsNotifierProvider).model,
    );
    if (result == null || !mounted) return;
    await _saveBlockEdit(context, block, result);
  }

  /// 工具栏「多选」开关:进入多选模式(空选集,再点块选择)。
  void _enterMultiSelectEmpty() {
    if (_multiSelectMode) return;
    setState(() {
      _multiSelectMode = true;
      _multiSelectedIds.clear();
      _lastSelectedId = null;
    });
  }

  void _enterMultiSelect(String blockId) {
    setState(() {
      _multiSelectMode = true;
      _multiSelectedIds
        ..clear()
        ..add(blockId);
      _lastSelectedId = blockId;
    });
  }

  void _toggleMultiSelect(String blockId) {
    setState(() {
      if (!_multiSelectedIds.remove(blockId)) {
        _multiSelectedIds.add(blockId);
      }
      _lastSelectedId = blockId;
    });
  }

  /// Shift+点击范围选：以 [_lastSelectedId] 为锚，沿当前可见序列框选
  /// （逻辑照抄本地画廊 selection_mode_provider.selectRange）。
  void _selectMultiRange(PromptBlock block) {
    final state = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    if (state == null) return;
    final allIds = _visibleBlocks(state).map((item) => item.id).toList();
    final anchorIndex = _lastSelectedId != null
        ? allIds.indexOf(_lastSelectedId!)
        : -1;
    final currentIndex = allIds.indexOf(block.id);
    if (anchorIndex == -1 || currentIndex == -1) {
      _toggleMultiSelect(block.id);
      return;
    }
    final start = anchorIndex < currentIndex ? anchorIndex : currentIndex;
    final end = anchorIndex < currentIndex ? currentIndex : anchorIndex;
    setState(() {
      _multiSelectedIds.addAll(allIds.sublist(start, end + 1));
      _lastSelectedId = block.id;
    });
  }

  void _exitMultiSelect() {
    if (!_multiSelectMode) return;
    setState(() {
      _multiSelectMode = false;
      _multiSelectedIds.clear();
      _lastSelectedId = null;
    });
  }

  // ---- 右键菜单 ----

  Future<void> _showBlockContextMenu(
    BuildContext context,
    PromptBlock block,
    Offset globalPosition,
  ) async {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) return;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition),
      Offset.zero & overlay.size,
    );

    // 桌面惯例：右键落在多选集合内出批量菜单；落在集合外则退出多选、
    // 单选该块、出单块菜单。
    final batch = _multiSelectMode && _multiSelectedIds.contains(block.id);
    if (_multiSelectMode && !batch) {
      setState(() {
        _multiSelectMode = false;
        _multiSelectedIds.clear();
        _lastSelectedId = null;
      });
      _selectBlock(block);
    }

    final errorStyle = TextStyle(color: theme.colorScheme.error);
    final count = _multiSelectedIds.length;

    final action = await showMenu<_BlockContextAction>(
      context: context,
      position: position,
      items: batch
          ? [
              PopupMenuItem<_BlockContextAction>(
                enabled: false,
                height: 34,
                child: Text(
                  l10n.promptBlockLibrary_selectedCount(count),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: _BlockContextAction.batchFavorite,
                child: Text(l10n.common_favorite),
              ),
              PopupMenuItem(
                value: _BlockContextAction.batchTag,
                child: Text(l10n.promptBlockLibrary_addTag),
              ),
              PopupMenuItem(
                value: _BlockContextAction.batchMoveTo,
                child: Text(l10n.promptBlockLibrary_moveToFolderTitle),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _BlockContextAction.batchDelete,
                child: Text(l10n.common_delete, style: errorStyle),
              ),
              PopupMenuItem(
                value: _BlockContextAction.exitMultiSelect,
                child: Text(l10n.promptBlockLibrary_exitMultiSelect),
              ),
            ]
          : [
              PopupMenuItem(
                value: _BlockContextAction.edit,
                child: Text(l10n.common_edit),
              ),
              PopupMenuItem(
                value: _BlockContextAction.copy,
                child: Text(l10n.common_copy),
              ),
              PopupMenuItem(
                value: block.isFavorite
                    ? _BlockContextAction.unfavorite
                    : _BlockContextAction.favorite,
                child: Text(
                  block.isFavorite
                      ? l10n.common_unfavorite
                      : l10n.common_favorite,
                ),
              ),
              PopupMenuItem(
                value: _BlockContextAction.moveTo,
                child: Text(l10n.promptBlockLibrary_moveTo),
              ),
              const PopupMenuItem(
                value: _BlockContextAction.addTag,
                child: Text('添加标签'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _BlockContextAction.delete,
                child: Text(l10n.common_delete, style: errorStyle),
              ),
              PopupMenuItem(
                value: _BlockContextAction.enterMultiSelect,
                child: Text(l10n.promptBlockLibrary_multiSelect),
              ),
            ],
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _BlockContextAction.edit:
        _selectBlock(block);
        unawaited(_openBlockEdit(block));
      case _BlockContextAction.copy:
        await Clipboard.setData(
          ClipboardData(
            text: block.content.isNotEmpty
                ? block.content
                : block.negativeContent,
          ),
        );
        if (context.mounted) {
          AppToast.success(context, l10n.promptBlockLibrary_copied);
        }
      case _BlockContextAction.favorite:
      case _BlockContextAction.unfavorite:
        if (context.mounted) await _showFavoriteMenu(block, globalPosition);
      case _BlockContextAction.moveTo:
        if (context.mounted) {
          await showBlockOrganizerPopover(
            context,
            blockIds: [block.id],
            anchor: globalPosition,
            page: BlockOrganizerPage.folders,
          );
        }
      case _BlockContextAction.addTag:
        _showTagMenu([block.id], globalPosition);
      case _BlockContextAction.delete:
        if (context.mounted) await _deleteBlock(context, block);
      case _BlockContextAction.enterMultiSelect:
        _enterMultiSelect(block.id);
      case _BlockContextAction.batchFavorite:
        if (context.mounted) {
          await showBlockOrganizerPopover(
            context,
            blockIds: _multiSelectedIds.toList(),
            anchor: globalPosition,
            page: BlockOrganizerPage.favorites,
          );
        }
      case _BlockContextAction.batchTag:
        _showTagMenu(_multiSelectedIds.toList(), globalPosition);
      case _BlockContextAction.batchMoveTo:
        if (context.mounted) {
          await showBlockOrganizerPopover(
            context,
            blockIds: _multiSelectedIds.toList(),
            anchor: globalPosition,
            page: BlockOrganizerPage.folders,
          );
        }
      case _BlockContextAction.batchDelete:
        if (context.mounted) {
          await _deleteBlocks(context, _multiSelectedIds.toList());
        }
      case _BlockContextAction.exitMultiSelect:
        _exitMultiSelect();
    }
  }

  // ---- 批量操作 ----

  Future<void> _deleteBlocks(BuildContext context, List<String> ids) async {
    final l10n = context.l10n;
    if (ids.isEmpty) return;
    final confirmed = await ThemedConfirmDialog.showDelete(
      context: context,
      itemName: '',
      content: l10n.promptBlockLibrary_deleteBlocksConfirm(ids.length),
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .deleteBlocks(ids);
      if (mounted) {
        setState(() {
          // 只清选中、保持右栏展开（009ea934 防跳动语义的批量版）。
          if (_selectedBlockId != null && ids.contains(_selectedBlockId)) {
            _selectedBlockId = null;
          }
          if (_multiSelectMode) {
            _multiSelectedIds.removeAll(ids);
          }
        });
      }
      if (context.mounted) {
        AppToast.success(context, l10n.promptBlockLibrary_deleted);
      }
    } catch (error) {
      if (context.mounted) AppToast.error(context, '$error');
    }
  }

  Widget _buildEmptyState(BuildContext context, PromptBlockLibraryState state) {
    final theme = Theme.of(context);
    final hasSearch =
        _searchController.text.trim().isNotEmpty || _selectedTag != null;
    final isEntireLibraryEmpty = state.blocks.isEmpty && _allSelected;
    final title = hasSearch
        ? context.l10n.promptBlockLibrary_noSearchResults
        : (isEntireLibraryEmpty
              ? context.l10n.promptBlockLibrary_empty
              : _favoritesSelected
              ? context.l10n.promptBlockLibrary_emptyFavorites
              : _selectedCollectionId != null
              ? context.l10n.promptBlockLibrary_emptyCollection
              : context.l10n.promptBlockLibrary_emptyFolder);
    final icon = hasSearch ? Icons.search_off : StudioIcons.promptBlocks;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? context.l10n.promptBlockLibrary_tryDifferentSearch
                : context.l10n.promptBlockLibrary_emptyHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (hasSearch)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedTag = null;
                  });
                },
                icon: const Icon(Icons.clear),
                label: Text(context.l10n.common_clear),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: FilledButton.icon(
                onPressed: () => _showCreateBlock(context),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.promptBlockLibrary_newBlock),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRetryView(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(context.l10n.promptBlockLibrary_loadFailed('$error')),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                ref.read(promptBlockLibraryNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.common_retry),
          ),
        ],
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
    setState(() {
      _allSelected = all;
      _favoritesSelected = favorites;
      _selectedCollectionId = collectionId;
      _selectedFolderId = folderId;
    });
  }

  List<PromptBlock> _visibleBlocks(PromptBlockLibraryState state) {
    final blocks = _allSelected
        ? state.blocks.toList()
        : _favoritesSelected
        ? state.favoriteBlocks
        : _selectedCollectionId != null
        ? state.blocksInCollectionTree(_selectedCollectionId!)
        : state.blocksInFolderTree(_selectedFolderId);
    final query = _searchController.text.trim().toLowerCase();
    final selectedTag = _selectedTag?.toLowerCase();
    if (selectedTag != null) {
      blocks.removeWhere(
        (block) =>
            !block.tags.any((tag) => tag.name.toLowerCase() == selectedTag),
      );
    }
    if (query.isNotEmpty) {
      blocks.removeWhere(
        (block) =>
            !block.title.toLowerCase().contains(query) &&
            !block.content.toLowerCase().contains(query) &&
            !block.negativeContent.toLowerCase().contains(query) &&
            !block.tags.any((tag) => tag.name.toLowerCase().contains(query)),
      );
    }
    if (_allSelected) {
      blocks.sort((a, b) {
        final title = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        return title != 0 ? title : a.id.compareTo(b.id);
      });
    }
    return sortPromptBlocks(
      blocks,
      _sortField,
      descending: _sortDescending,
      folderOrder: state.folderTreeOrder(),
    );
  }

  Future<void> _importTxtFiles() async {
    final l10n = context.l10n;
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: l10n.promptBlockLibrary_importTxtTitle,
      type: FileType.custom,
      allowedExtensions: ['txt'],
      allowMultiple: true,
    );
    final paths =
        result?.paths.whereType<String>().toList() ?? const <String>[];
    if (paths.isEmpty || !mounted) return;

    try {
      final summary = await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .importTxtFiles(
            paths: paths,
            folderId: _allSelected ? null : _selectedFolderId,
          );
      if (mounted) {
        AppToast.success(
          context,
          l10n.promptBlockLibrary_txtImportDone(
            summary.created,
            summary.skipped,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        AppToast.error(context, l10n.promptBlockLibrary_importFailed('$error'));
      }
    }
  }

  Future<void> _importFromFolder() async {
    final l10n = context.l10n;
    final root = await FilePickerUtils.pickDirectoryModal(
      dialogTitle: l10n.promptBlockLibrary_curationTitle,
    );
    if (root == null || root.isEmpty || !mounted) return;

    final List<PromptBlockExchangeFile> files;
    try {
      files = await PromptBlockExchange.scanTxtDirectory(root);
    } catch (error) {
      if (mounted) {
        AppToast.error(context, l10n.promptBlockLibrary_importFailed('$error'));
      }
      return;
    }
    if (files.isEmpty) {
      if (mounted) {
        AppToast.warning(context, l10n.promptBlockLibrary_curationEmpty);
      }
      return;
    }

    final state = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    if (state == null || !mounted) return;
    final plan = PromptBlockExchange.buildPlan(
      files: files,
      library: PromptBlockLibraryData(
        blocks: state.blocks,
        folders: state.folders,
      ),
      folderChainOf: (file) =>
          PromptBlockExchange.curationFolderChain(file, root),
    );

    final decision = await CurationImportPreviewDialog.show(
      context: context,
      rootPath: root,
      plan: plan,
    );
    if (decision == null || !mounted) return;

    try {
      final summary = await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .applyExchangePlan(plan, updateChanged: decision.updateChanged);
      if (mounted) {
        AppToast.success(
          context,
          l10n.promptBlockLibrary_curationDone(
            summary.created,
            summary.updated,
            summary.skipped,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        AppToast.error(context, l10n.promptBlockLibrary_importFailed('$error'));
      }
    }
  }

  Future<void> _exportLibraryBackup() async {
    final l10n = context.l10n;
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    final stamp =
        '${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}';
    final target = await FilePicker.platform.saveFile(
      dialogTitle: l10n.promptBlockLibrary_exportLibraryBackup,
      fileName: 'prompt-block-library-$stamp.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (target == null || !mounted) return;
    final path = target.toLowerCase().endsWith('.json')
        ? target
        : '$target.json';

    try {
      final json = await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .exportLibrary();
      final blockCount = (json['blocks'] as List?)?.length ?? 0;
      await File(path).writeAsString(
        const JsonEncoder.withIndent('  ').convert(json),
        flush: true,
      );
      if (mounted) {
        AppToast.success(
          context,
          l10n.promptBlockLibrary_libraryBackupDone(blockCount),
        );
      }
    } catch (error) {
      if (mounted) {
        AppToast.error(context, l10n.promptBlockLibrary_importFailed('$error'));
      }
    }
  }

  Future<void> _importLibraryBackup() async {
    final l10n = context.l10n;
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: l10n.promptBlockLibrary_libraryImportTitle,
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
      withData: true,
    );
    final pickedFiles = result?.files;
    final bytes = (pickedFiles == null || pickedFiles.isEmpty)
        ? null
        : pickedFiles.first.bytes;
    if (bytes == null || !mounted) return;

    Map<String, dynamic> parsed;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('backup is not a JSON object');
      }
      parsed = decoded;
    } catch (_) {
      if (mounted) {
        AppToast.error(context, l10n.promptBlockLibrary_libraryBackupInvalid);
      }
      return;
    }

    try {
      final summary = await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .importLibrary(parsed);
      if (mounted) {
        AppToast.success(
          context,
          l10n.promptBlockLibrary_libraryImportDone(
            summary.importedBlocks,
            summary.importedFolders,
            summary.skippedBlocks + summary.skippedFolders,
          ),
        );
      }
    } on FormatException {
      if (mounted) {
        AppToast.error(context, l10n.promptBlockLibrary_libraryBackupInvalid);
      }
    } catch (error) {
      if (mounted) {
        AppToast.error(context, l10n.promptBlockLibrary_importFailed('$error'));
      }
    }
  }

  Future<void> _showCreateBlock(BuildContext context) async {
    final l10n = context.l10n;
    final state = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    if (state == null) return;
    final result = await PromptBlockEditDialog.show(
      context: context,
      folders: state.folders,
      knownTags: [for (final item in state.blocks) ...item.tags],
      initialFolderId: _allSelected ? null : _selectedFolderId,
      modelForTokenCount: ref.read(generationParamsNotifierProvider).model,
    );
    if (result == null || !context.mounted) return;

    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .createBlock(
            title: result.title,
            content: result.content,
            atoms: result.atoms,
            negativeContent: result.negativeContent,
            negativeAtoms: result.negativeAtoms,
            generationSettings: result.generationSettings,
            tags: result.tags,
            folderId: result.folderId,
            color: result.color,
            iconName: result.iconName,
            thumbnail: result.thumbnail,
            thumbnailOffsetX: result.thumbnailOffsetX,
            thumbnailOffsetY: result.thumbnailOffsetY,
            thumbnailScale: result.thumbnailScale,
          );
      if (context.mounted) {
        AppToast.success(context, l10n.promptBlockLibrary_saved);
      }
    } catch (error) {
      if (context.mounted) AppToast.error(context, '$error');
    }
  }

  Future<void> _saveBlockEdit(
    BuildContext context,
    PromptBlock block,
    PromptBlockEditResult result,
  ) async {
    final l10n = context.l10n;
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
              tags: result.tags,
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
      if (context.mounted) {
        AppToast.success(context, l10n.promptBlockLibrary_saved);
      }
    } catch (error) {
      if (context.mounted) AppToast.error(context, '$error');
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

  Future<void> _deleteBlock(BuildContext context, PromptBlock block) async {
    final l10n = context.l10n;
    final title = block.title.isEmpty
        ? l10n.promptBlockLibrary_unnamedBlock
        : block.title;
    final confirmed = await ThemedConfirmDialog.showDelete(
      context: context,
      itemName: title,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .deleteBlock(block.id);
      if (mounted) {
        setState(() {
          // 只清选中,保持右栏展开(显示未选择块),避免连续删除时布局跳动。
          if (_selectedBlockId == block.id) {
            _selectedBlockId = null;
          }
          if (_multiSelectMode) {
            _multiSelectedIds.remove(block.id);
          }
        });
      }
      if (context.mounted) {
        AppToast.success(context, l10n.promptBlockLibrary_deleted);
      }
    } catch (error) {
      if (context.mounted) AppToast.error(context, '$error');
    }
  }

  Future<void> _showFolderNameDialog(
    BuildContext context, {
    String? parentId,
    PromptBlockFolder? folder,
  }) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: folder?.name ?? '');
    final title = folder == null
        ? l10n.promptBlockLibrary_newFolder
        : l10n.promptBlockLibrary_renameFolder;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.promptBlockLibrary_folderName,
            hintText: l10n.promptBlockLibrary_folderNameHint,
          ),
          onSubmitted: (_) =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.common_save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;

    try {
      final notifier = ref.read(promptBlockLibraryNotifierProvider.notifier);
      if (folder == null) {
        await notifier.createFolder(name: name, parentId: parentId);
      } else {
        await notifier.updateFolder(folder.copyWith(name: name));
      }
      if (context.mounted) {
        AppToast.success(context, l10n.promptBlockLibrary_saved);
      }
    } catch (error) {
      if (context.mounted) AppToast.error(context, '$error');
    }
  }

  Future<void> _renameFolder(
    BuildContext context,
    PromptBlockLibraryState state,
    String id,
  ) async {
    final folder = state.folderById(id);
    if (folder != null) {
      await _showFolderNameDialog(context, folder: folder);
    }
  }

  Future<void> _moveFolderToRoot(BuildContext context, String id) async {
    final l10n = context.l10n;
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .moveFolder(id, null);
      if (context.mounted) {
        AppToast.success(context, l10n.promptBlockLibrary_saved);
      }
    } catch (error) {
      if (context.mounted) AppToast.error(context, '$error');
    }
  }

  Future<void> _deleteFolder(
    BuildContext context,
    PromptBlockLibraryState state,
    String id,
  ) async {
    final l10n = context.l10n;
    final folder = state.folderById(id);
    if (folder == null) return;
    final blockedIds = <String>{id, ...state.folders.getDescendantIds(id)};
    final destinations = state.folders
        .where((candidate) => !blockedIds.contains(candidate.id))
        .toList();
    final decision = await PromptBlockFolderDeleteDialog.show(
      context: context,
      folder: folder,
      destinationFolders: destinations,
    );
    if (decision == null || !context.mounted) return;
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .deleteFolder(
            id,
            mode: decision.mode,
            destinationFolderId: decision.destinationFolderId,
          );
      if (_selectedFolderId != null && blockedIds.contains(_selectedFolderId)) {
        _selectScope();
      }
      if (context.mounted) {
        AppToast.success(context, l10n.promptBlockLibrary_deleted);
      }
    } catch (error) {
      if (context.mounted) AppToast.error(context, '$error');
    }
  }

  Future<void> _reorderFolders(
    String? parentId,
    List<String> orderedIds,
  ) async {
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .reorderFolders(parentId, orderedIds);
    } catch (error) {
      if (mounted) AppToast.error(context, '$error');
    }
  }

  Future<void> _reorderBlocks(
    PromptBlockLibraryState state,
    List<PromptBlock> blocks,
    int oldIndex,
    int newIndex,
  ) async {
    if (_viewMode != _PromptBlockViewMode.list ||
        _allSelected ||
        _sortField.overridesManualOrder ||
        _searchController.text.trim().isNotEmpty ||
        blocks.any((block) => block.folderId != _selectedFolderId)) {
      return;
    }
    final orderedIds = blocks.map((block) => block.id).toList();
    final moved = orderedIds.removeAt(oldIndex);
    orderedIds.insert(newIndex, moved);
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .reorderBlocks(_selectedFolderId, orderedIds);
    } catch (error) {
      if (mounted) AppToast.error(context, '$error');
    }
  }

  // ---- 收藏集 / 收藏文件夹 ----

  /// 新建或重命名收藏集 / 收藏文件夹的名称对话框。
  Future<void> _showCollectionNameDialog(
    BuildContext context, {
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
            labelText: l10n.promptBlockLibrary_collectionName,
            hintText: l10n.promptBlockLibrary_collectionNameHint,
          ),
          onSubmitted: (_) =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.common_save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !context.mounted) return;

    try {
      final notifier = ref.read(promptBlockLibraryNotifierProvider.notifier);
      if (collection == null) {
        await notifier.createCollection(
          name: name,
          parentId: parentId,
          isFolder: isFolder,
        );
      } else {
        await notifier.renameCollection(collection.id, name);
      }
      if (context.mounted) {
        AppToast.success(context, l10n.promptBlockLibrary_saved);
      }
    } catch (error) {
      if (context.mounted) AppToast.error(context, '$error');
    }
  }

  Future<void> _renameCollection(
    BuildContext context,
    PromptBlockLibraryState state,
    String id,
  ) async {
    final collection = state.collectionById(id);
    if (collection != null) {
      await _showCollectionNameDialog(
        context,
        isFolder: collection.isFolder,
        collection: collection,
      );
    }
  }

  Future<void> _moveCollection(
    BuildContext context,
    String id,
    String? newParentId,
  ) async {
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .moveCollection(id, newParentId);
      if (context.mounted) {
        AppToast.success(context, context.l10n.promptBlockLibrary_saved);
      }
    } catch (error) {
      if (context.mounted) AppToast.error(context, '$error');
    }
  }

  /// 删除收藏集/收藏文件夹：确认后连带子树删除，成员块本体不动。
  Future<void> _deleteCollection(
    BuildContext context,
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
    final confirmed = await ThemedConfirmDialog.showDelete(
      context: context,
      itemName: '',
      content: node.isFolder
          ? l10n.promptBlockLibrary_deleteCollectionFolderConfirm(label)
          : l10n.promptBlockLibrary_deleteCollectionConfirm(label),
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .deleteCollection(id);
      if (context.mounted) {
        AppToast.success(context, l10n.promptBlockLibrary_deleted);
      }
    } catch (error) {
      if (context.mounted) AppToast.error(context, '$error');
    }
  }

  Future<void> _reorderCollections(
    String? parentId,
    List<String> orderedIds,
  ) async {
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .reorderCollections(parentId, orderedIds);
    } catch (error) {
      if (mounted) AppToast.error(context, '$error');
    }
  }

  /// 块拖到收藏集行上：已在集内跳过，否则追加成员（入集即收藏）。
  Future<void> _addBlockToCollection(
    String collectionId,
    String blockId,
  ) async {
    final state = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    final node = state?.collectionById(collectionId);
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
}

/// 文件夹分段：标题 + 该段直属块列表。
class _FolderSection {
  const _FolderSection({required this.title, required this.blocks});

  final String title;
  final List<PromptBlock> blocks;
}

/// 分段 sticky 标题（pinned SliverPersistentHeader）：滚动时当前段的
/// 文件夹路径钉在顶部，被下一段标题顶走。
class _FolderSectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _FolderSectionHeaderDelegate({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  static const double height = 40;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return Container(
      // 不透明底色：后续段内容上滚时被标题遮住，形成「顶走」效果。
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FolderSectionHeaderDelegate oldDelegate) =>
      title != oldDelegate.title || count != oldDelegate.count;
}

/// 滚动锚点：详情栏开合前记录的可见卡位置。
class _CardAnchor {
  const _CardAnchor(this.cardKey, this.dy);

  /// 卡片 [ValueKey] 的完整字符串（含视图前缀，如 `waterfall-xxx`）。
  final String cardKey;

  /// 卡顶在主滚动空间中距视口顶部的偏移（负值 = 顶在视口上沿外）。
  final double dy;
}
