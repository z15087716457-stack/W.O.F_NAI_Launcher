import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/utils/file_picker_utils.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/prompt_block_exchange.dart';
import '../../../data/models/prompt_block/prompt_block.dart';
import '../../../data/models/prompt_block/prompt_block_folder.dart';
import '../../../data/models/prompt_block/prompt_block_sort.dart';
import '../../../data/repositories/prompt_block_repository.dart';
import '../../providers/prompt_block_library_provider.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/themed_confirm_dialog.dart';
import 'widgets/curation_import_preview_dialog.dart';
import 'widgets/prompt_block_card.dart';
import 'widgets/prompt_block_edit_dialog.dart';
import 'widgets/prompt_block_folder_delete_dialog.dart';
import 'widgets/prompt_block_folder_tree.dart';
import 'widgets/prompt_block_list_item.dart';
import 'widgets/prompt_block_quick_settings_panel.dart';

enum _PromptBlockViewMode { list, grid }

/// 块右键菜单动作（单块语义 + 多选批量语义共用一个枚举）。
enum _BlockContextAction {
  edit,
  copy,
  favorite,
  unfavorite,
  moveTo,
  export,
  delete,
  enterMultiSelect,
  batchFavorite,
  batchUnfavorite,
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

  bool _allSelected = true;
  String? _selectedFolderId;
  _PromptBlockViewMode _viewMode = _PromptBlockViewMode.grid;
  PromptBlockSortField _sortField = PromptBlockSortField.custom;
  bool _sortDescending = false;
  double _cardWidth = 220;
  String? _selectedBlockId;
  bool _quickPanelExpanded = false;

  // 屏幕级多选状态（与 [_selectedBlockId] 同层；本页消费者全在 screen 内，
  // 不引 provider——画廊用 provider 是因为跨 widget 消费）。
  bool _multiSelectMode = false;
  final Set<String> _multiSelectedIds = <String>{};
  String? _lastSelectedId;

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
      _viewMode = storedMode == 'list'
          ? _PromptBlockViewMode.list
          : _PromptBlockViewMode.grid;
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
      mode == _PromptBlockViewMode.list ? 'list' : 'grid',
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
              if (_selectedBlockId != null && selectedBlock == null) {
                final staleId = _selectedBlockId;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _selectedBlockId != staleId) return;
                  setState(() {
                    _selectedBlockId = null;
                  });
                });
              }
              final showQuickPanel = constraints.maxWidth >= 720;
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
                        Expanded(child: _buildContent(context, library)),
                      ],
                    ),
                  ),
                  if (showQuickPanel)
                    _buildQuickSettingsRail(
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

  Widget _buildQuickSettingsRail(
    PromptBlock? block,
    List<PromptBlockFolder> folders,
  ) {
    final theme = Theme.of(context);
    final width = _quickPanelExpanded ? 320.0 : 40.0;
    return ClipRect(
      child: AnimatedContainer(
        key: const Key('prompt-block-quick-settings-rail'),
        duration: const Duration(milliseconds: 200),
        width: width,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(left: BorderSide(color: theme.dividerColor)),
        ),
        child: !_quickPanelExpanded
            ? PromptBlockQuickSettingsCollapsed(
                onExpand: () => setState(() => _quickPanelExpanded = true),
              )
            : _multiSelectMode
            ? _buildEmptyQuickPanel(
                icon: Icons.checklist,
                message: context.l10n.promptBlockLibrary_selectedCount(
                  _multiSelectedIds.length,
                ),
              )
            : block != null
            ? PromptBlockQuickSettingsPanel(
                block: block,
                folders: folders,
                onToggleFavorite: () => _toggleFavorite(block),
                onCopy: () => AppToast.success(
                  context,
                  context.l10n.promptBlockLibrary_copied,
                ),
                onExport: () => _exportBlockAsTxt(block),
                onSave: (result) => _saveBlockEdit(context, block, result),
                onDelete: () => _deleteBlock(context, block),
                onCollapse: () => setState(() => _quickPanelExpanded = false),
              )
            : _buildEmptyQuickPanel(),
      ),
    );
  }

  Widget _buildEmptyQuickPanel({
    IconData icon = Icons.touch_app_outlined,
    String? message,
  }) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 280) return const SizedBox.expand();
        return Material(
          key: const Key('prompt-block-quick-settings-empty'),
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
                        Icons.tune,
                        size: 19,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.common_edit,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('prompt-block-quick-settings-collapse'),
                        tooltip: l10n.common_collapse,
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            setState(() => _quickPanelExpanded = false),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
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
                  allSelected: _allSelected,
                  rootSelected: !_allSelected && _selectedFolderId == null,
                  selectedFolderId: _selectedFolderId,
                  onSelectAll: () => setState(() {
                    _allSelected = true;
                    _selectedFolderId = null;
                  }),
                  onSelectRoot: () => setState(() {
                    _allSelected = false;
                    _selectedFolderId = null;
                  }),
                  onSelectFolder: (id) => setState(() {
                    _allSelected = false;
                    _selectedFolderId = id;
                  }),
                  onCreateFolder: (parentId) =>
                      _showFolderNameDialog(context, parentId: parentId),
                  onRenameFolder: (id) => _renameFolder(context, state, id),
                  onMoveFolderToRoot: (id) => _moveFolderToRoot(context, id),
                  onDeleteFolder: (id) => _deleteFolder(context, state, id),
                  onReorderFolders: _reorderFolders,
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
                          ],
                          onPressed: (index) => _setViewMode(
                            index == 0
                                ? _PromptBlockViewMode.list
                                : _PromptBlockViewMode.grid,
                          ),
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
                    Icons.view_module_outlined,
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
          tooltip: l10n.promptBlockLibrary_selectAllVisible,
          onPressed: allSelected ? null : () => _selectAllVisible(visible),
          icon: const Icon(Icons.select_all, size: 19),
        ),
        IconButton(
          key: const Key('prompt-block-multi-select-clear'),
          tooltip: l10n.promptBlockLibrary_clearSelection,
          onPressed: hasSelection
              ? () => setState(() => _multiSelectedIds.clear())
              : null,
          icon: const Icon(Icons.deselect, size: 19),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: l10n.common_favorite,
          onPressed: hasSelection ? () => _setBlocksFavorite(true) : null,
          icon: const Icon(Icons.star_border, size: 19),
        ),
        IconButton(
          tooltip: l10n.common_unfavorite,
          onPressed: hasSelection ? () => _setBlocksFavorite(false) : null,
          icon: const Icon(Icons.star, size: 19),
        ),
        IconButton(
          key: const Key('prompt-block-multi-select-move'),
          tooltip: l10n.promptBlockLibrary_moveTo,
          onPressed: hasSelection
              ? () => _moveBlocksToFolderDialog(_multiSelectedIds.toList())
              : null,
          icon: const Icon(Icons.drive_file_move_outline, size: 19),
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
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: context.l10n.promptBlockLibrary_searchHint,
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

  Widget _buildCompactFolderSelector(PromptBlockLibraryState state) {
    final l10n = context.l10n;
    final value = _allSelected ? '__all__' : (_selectedFolderId ?? '__root__');
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
            setState(() {
              _allSelected = true;
              _selectedFolderId = null;
            });
          } else if (value == '__root__') {
            setState(() {
              _allSelected = false;
              _selectedFolderId = null;
            });
          } else if (value != null) {
            setState(() {
              _allSelected = false;
              _selectedFolderId = value;
            });
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

          if (_viewMode == _PromptBlockViewMode.grid) {
            return _buildGrid(context, blocks);
          }

          // 聚合视图里混有后代文件夹的块，跨文件夹拖排没有意义；
          // repository 的同级完整性校验也会拒绝这种重排，这里直接不提供把手。
          // 自定义排序下顺序由字段决定，手动拖排同样没有意义。
          final reorderable =
              !_allSelected &&
              !_sortField.overridesManualOrder &&
              _searchController.text.trim().isEmpty &&
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
                _buildBlockItem(context, blocks[index]),
          );
        },
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<PromptBlock> blocks) {
    if (_cardWidth <= 160) return _buildPillGrid(context, blocks);

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
                itemBuilder: (context, index) =>
                    _buildBlockCard(context, blocks[index], width: _cardWidth),
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

  Widget _buildPillGrid(BuildContext context, List<PromptBlock> blocks) {
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
                      _buildBlockPill(context, block, maxWidth: _cardWidth),
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
  }) {
    final title = block.title.isEmpty
        ? context.l10n.promptBlockLibrary_unnamedBlock
        : block.title;
    return PromptBlockPill(
      key: ValueKey(block.id),
      block: block,
      displayTitle: title,
      maxWidth: maxWidth,
      selected: _isBlockShownSelected(block.id),
      multiSelected: _isBlockMultiSelected(block.id),
      onSecondaryTap: (details) =>
          _showBlockContextMenu(context, block, details.globalPosition),
      onTap: () => _handleBlockTap(block),
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

  Widget _buildBlockItem(
    BuildContext context,
    PromptBlock block, {
    int? reorderIndex,
  }) {
    final title = block.title.isEmpty
        ? context.l10n.promptBlockLibrary_unnamedBlock
        : block.title;
    return PromptBlockListItem(
      key: ValueKey(block.id),
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
      onExport: () => _exportBlockAsTxt(block),
      onToggleFavorite: () => _toggleFavorite(block),
      onDelete: () => _deleteBlock(context, block),
    );
  }

  Widget _buildBlockCard(
    BuildContext context,
    PromptBlock block, {
    required double width,
  }) {
    final title = block.title.isEmpty
        ? context.l10n.promptBlockLibrary_unnamedBlock
        : block.title;
    return PromptBlockCard(
      key: ValueKey(block.id),
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
      onExport: () => _exportBlockAsTxt(block),
      onToggleFavorite: () => _toggleFavorite(block),
      onDelete: () => _deleteBlock(context, block),
    );
  }

  void _selectBlock(PromptBlock block) {
    setState(() {
      _selectedBlockId = block.id;
      _quickPanelExpanded = true;
    });
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

  /// 多选模式下点行尾/卡面「编辑」按钮：退出多选并按单选打开右侧编辑栏。
  void _handleBlockEditButton(PromptBlock block) {
    if (_multiSelectMode) _exitMultiSelect();
    _selectBlock(block);
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
    final state = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    final anyFavorite = _multiSelectedIds.any((id) {
      final item = state?.blockById(id);
      return item != null && item.isFavorite;
    });
    final anyUnfavorite = _multiSelectedIds.any((id) {
      final item = state?.blockById(id);
      return item == null || !item.isFavorite;
    });

    final action = await showMenu<_BlockContextAction>(
      context: context,
      position: position,
      items: batch
          ? [
              if (anyUnfavorite)
                PopupMenuItem(
                  value: _BlockContextAction.batchFavorite,
                  child: Text(l10n.promptBlockLibrary_favoriteSelected(count)),
                ),
              if (anyFavorite)
                PopupMenuItem(
                  value: _BlockContextAction.batchUnfavorite,
                  child: Text(
                    l10n.promptBlockLibrary_unfavoriteSelected(count),
                  ),
                ),
              PopupMenuItem(
                value: _BlockContextAction.batchMoveTo,
                child: Text(l10n.promptBlockLibrary_moveToSelected(count)),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _BlockContextAction.batchDelete,
                child: Text(
                  l10n.promptBlockLibrary_deleteSelected(count),
                  style: errorStyle,
                ),
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
              PopupMenuItem(
                value: _BlockContextAction.export,
                child: Text(l10n.promptBlockLibrary_exportBlockAsTxt),
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
      case _BlockContextAction.copy:
        await Clipboard.setData(ClipboardData(text: block.content));
        if (context.mounted) {
          AppToast.success(context, l10n.promptBlockLibrary_copied);
        }
      case _BlockContextAction.favorite:
      case _BlockContextAction.unfavorite:
        await _toggleFavorite(block);
      case _BlockContextAction.moveTo:
        if (mounted) await _moveBlocksToFolderDialog([block.id]);
      case _BlockContextAction.export:
        await _exportBlockAsTxt(block);
      case _BlockContextAction.delete:
        if (context.mounted) await _deleteBlock(context, block);
      case _BlockContextAction.enterMultiSelect:
        _enterMultiSelect(block.id);
      case _BlockContextAction.batchFavorite:
        await _setBlocksFavorite(true);
      case _BlockContextAction.batchUnfavorite:
        await _setBlocksFavorite(false);
      case _BlockContextAction.batchMoveTo:
        if (mounted) {
          await _moveBlocksToFolderDialog(_multiSelectedIds.toList());
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

  Future<void> _setBlocksFavorite(bool favorite) async {
    final l10n = context.l10n;
    final ids = _multiSelectedIds.toList();
    if (ids.isEmpty) return;
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .setFavorite(ids, favorite);
      if (mounted) {
        AppToast.success(context, l10n.promptBlockLibrary_saved);
      }
    } catch (error) {
      if (mounted) AppToast.error(context, '$error');
    }
  }

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

  /// 「移动到…」：文件夹树平铺单选对话框（根目录 + DFS 顺序，层级缩进）。
  Future<void> _moveBlocksToFolderDialog(List<String> ids) async {
    final l10n = context.l10n;
    final state = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    if (state == null || ids.isEmpty) return;

    final flat = <(PromptBlockFolder, int)>[];
    void visit(String? parentId, int depth) {
      for (final folder in state.folders.childrenOf(parentId)) {
        flat.add((folder, depth));
        visit(folder.id, depth + 1);
      }
    }

    visit(null, 0);

    final initialFolderId = ids.length == 1
        ? state.blockById(ids.first)?.folderId
        : null;
    var picked = initialFolderId;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.promptBlockLibrary_moveToFolderTitle),
          content: SizedBox(
            width: 360,
            child: flat.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(l10n.promptBlockLibrary_rootFolder),
                  )
                : RadioGroup<String?>(
                    groupValue: picked,
                    onChanged: (value) => setDialogState(() => picked = value),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        RadioListTile<String?>(
                          key: const Key('prompt-block-move-folder-root'),
                          value: null,
                          title: Text(l10n.promptBlockLibrary_rootFolder),
                        ),
                        for (final (folder, depth) in flat)
                          RadioListTile<String?>(
                            value: folder.id,
                            title: Padding(
                              padding: EdgeInsets.only(left: 12.0 * depth),
                              child: Text(
                                folder.name.isEmpty
                                    ? l10n.promptBlockLibrary_unnamedFolder
                                    : folder.name,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('__cancelled__'),
              child: Text(l10n.common_cancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(picked ?? '__root__'),
              child: Text(l10n.common_confirm),
            ),
          ],
        ),
      ),
    );
    if (result == null || result == '__cancelled__' || !mounted) {
      return;
    }
    final folderId = result == '__root__' ? null : result;

    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .moveBlocks(ids, folderId);
      if (mounted) {
        AppToast.success(
          context,
          l10n.promptBlockLibrary_blocksMoved(ids.length),
        );
      }
    } catch (error) {
      if (mounted) AppToast.error(context, '$error');
    }
  }

  Widget _buildEmptyState(BuildContext context, PromptBlockLibraryState state) {
    final theme = Theme.of(context);
    final hasSearch = _searchController.text.trim().isNotEmpty;
    final isEntireLibraryEmpty = state.blocks.isEmpty && _allSelected;
    final title = hasSearch
        ? context.l10n.promptBlockLibrary_noSearchResults
        : (isEntireLibraryEmpty
              ? context.l10n.promptBlockLibrary_empty
              : context.l10n.promptBlockLibrary_emptyFolder);
    final icon = hasSearch ? Icons.search_off : Icons.view_module_outlined;

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
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? context.l10n.promptBlockLibrary_tryDifferentSearch
                : context.l10n.promptBlockLibrary_emptyHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline.withValues(alpha: 0.7),
            ),
          ),
          if (hasSearch)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
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

  List<PromptBlock> _visibleBlocks(PromptBlockLibraryState state) {
    final blocks = _allSelected
        ? state.blocks.toList()
        : state.blocksInFolderTree(_selectedFolderId);
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      blocks.removeWhere(
        (block) =>
            !block.title.toLowerCase().contains(query) &&
            !block.content.toLowerCase().contains(query),
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

  Future<void> _exportBlockAsTxt(PromptBlock block) async {
    final l10n = context.l10n;
    final rawTitle = block.title.trim().isEmpty ? 'block' : block.title.trim();
    final safeTitle = rawTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final target = await FilePicker.platform.saveFile(
      dialogTitle: l10n.promptBlockLibrary_exportBlockAsTxt,
      fileName: '$safeTitle.txt',
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (target == null || !mounted) return;
    final path = target.toLowerCase().endsWith('.txt') ? target : '$target.txt';

    try {
      await File(path).writeAsString(block.content, flush: true);
      if (mounted) {
        AppToast.success(context, l10n.promptBlockLibrary_exportTxtDone);
      }
    } catch (error) {
      if (mounted) {
        AppToast.error(
          context,
          l10n.promptBlockLibrary_exportTxtFailed('$error'),
        );
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
      initialFolderId: _allSelected ? null : _selectedFolderId,
    );
    if (result == null || !context.mounted) return;

    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .createBlock(
            title: result.title,
            content: result.content,
            folderId: result.folderId,
            color: result.color,
            iconName: result.iconName,
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
              color: result.color,
              iconName: result.iconName,
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

  Future<void> _toggleFavorite(PromptBlock block) async {
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .toggleFavorite(block.id);
    } catch (error) {
      if (mounted) AppToast.error(context, '$error');
    }
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
        setState(() {
          _allSelected = false;
          _selectedFolderId = null;
        });
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
}
