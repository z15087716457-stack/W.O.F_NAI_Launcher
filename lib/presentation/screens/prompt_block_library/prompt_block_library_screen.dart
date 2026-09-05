import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
      body: LayoutBuilder(
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
                onClose: () => setState(() {
                  _selectedBlockId = null;
                  _quickPanelExpanded = false;
                }),
              )
            : _buildEmptyQuickPanel(),
      ),
    );
  }

  Widget _buildEmptyQuickPanel() {
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
                      IconButton(
                        key: const Key('prompt-block-quick-settings-close'),
                        tooltip: l10n.common_close,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() {
                          _selectedBlockId = null;
                          _quickPanelExpanded = false;
                        }),
                        icon: const Icon(Icons.close),
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
                        Icons.touch_app_outlined,
                        size: 28,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.promptBlockLibrary_noBlockSelected,
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
              final actions = Row(
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
                          context.l10n.promptBlockLibrary_importFromFolder,
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'exportBackup',
                        child: Text(
                          context.l10n.promptBlockLibrary_exportLibraryBackup,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'importBackup',
                        child: Text(
                          context.l10n.promptBlockLibrary_importLibraryBackup,
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
                        child: const Icon(Icons.view_agenda_outlined, size: 18),
                      ),
                      Tooltip(
                        message: context.l10n.promptBlockLibrary_gridView,
                        child: const Icon(Icons.grid_view_outlined, size: 18),
                      ),
                    ],
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
                    label: Text(context.l10n.promptBlockLibrary_newFolder),
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
    return library.when(
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
            itemBuilder: (context, index) =>
                _buildBlockItem(context, blocks[index], reorderIndex: index),
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
      selected: _selectedBlockId == block.id,
      onTap: () => _selectBlock(block),
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
      selected: _selectedBlockId == block.id,
      onTap: () => _selectBlock(block),
      onEdit: () => _selectBlock(block),
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
      selected: _selectedBlockId == block.id,
      onTap: () => _selectBlock(block),
      onEdit: () => _selectBlock(block),
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
      if (_selectedBlockId == block.id && mounted) {
        // 只清选中,保持右栏展开(显示未选择块),避免连续删除时布局跳动。
        setState(() {
          _selectedBlockId = null;
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
