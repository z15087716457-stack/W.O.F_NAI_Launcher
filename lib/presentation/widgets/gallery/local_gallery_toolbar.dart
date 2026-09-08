import 'dart:async';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/shortcuts/default_shortcuts.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/gallery/gallery_category.dart';
import '../../../data/services/gallery/gallery_nai_only_store.dart';
import '../../../data/services/gallery/gallery_sort.dart';
import '../../../data/services/gallery/gallery_sort_store.dart';
import '../../../data/services/gallery/gallery_view_mode.dart';
import '../../../data/services/gallery/gallery_view_mode_store.dart';
import '../../providers/collection_provider.dart';
import '../../providers/gallery_category_provider.dart';
import '../../providers/local_gallery_provider.dart';
import '../../providers/selection_mode_provider.dart';
import '../bulk_action_bar.dart';
import '../common/compact_icon_button.dart';
import 'gallery_trash_panel.dart';
import '../gallery_filter_panel.dart';

import '../autocomplete/autocomplete_config.dart';
import '../autocomplete/autocomplete_wrapper.dart';
import 'date_range_picker_dialog.dart';

/// Local gallery toolbar with search, filter and actions
/// 本地画廊工具栏（搜索、过滤、操作按钮）
class LocalGalleryToolbar extends ConsumerStatefulWidget {
  /// Whether 3D card view mode is active
  /// 是否启用3D卡片视图模式
  final bool use3DCardView;

  /// Callback when view mode is toggled
  /// 视图模式切换回调
  final VoidCallback? onToggleViewMode;

  /// Callback when open folder button is pressed
  /// 打开文件夹按钮回调
  final VoidCallback? onOpenFolder;

  /// Callback when refresh button is pressed
  /// 刷新按钮回调
  final VoidCallback? onRefresh;

  /// Callback when enter selection mode button is pressed
  /// 进入选择模式按钮回调
  final VoidCallback? onEnterSelectionMode;

  /// Callback when undo button is pressed
  /// 撤销按钮回调
  final VoidCallback? onUndo;

  /// Callback when redo button is pressed
  /// 重做按钮回调
  final VoidCallback? onRedo;

  /// Whether undo is available
  /// 是否可撤销
  final bool canUndo;

  /// Whether redo is available
  /// 是否可重做
  final bool canRedo;

  /// Key for GroupedGridView to scroll to group
  /// 用于滚动到分组的 GroupedGridView key
  final GlobalKey? groupedGridViewKey;

  /// Callbacks for bulk actions
  /// 批量操作回调
  final VoidCallback? onAddToCollection;
  final VoidCallback? onRemoveFromCollection;
  final VoidCallback? onDeleteSelected;
  final VoidCallback? onPackSelected;
  final VoidCallback? onEditMetadata;
  final VoidCallback? onMoveToFolder;

  /// Whether category panel is visible
  /// 是否显示分类面板
  final bool showCategoryPanel;

  /// Callback when category panel toggle is pressed
  /// 分类面板切换按钮回调
  final VoidCallback? onToggleCategoryPanel;

  /// Whether search autocomplete is enabled.
  /// 是否启用搜索自动补全。
  final bool enableSearchAutocomplete;

  const LocalGalleryToolbar({
    super.key,
    this.use3DCardView = true,
    this.onToggleViewMode,
    this.onOpenFolder,
    this.onRefresh,
    this.onEnterSelectionMode,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
    this.groupedGridViewKey,
    this.onAddToCollection,
    this.onRemoveFromCollection,
    this.onDeleteSelected,
    this.onPackSelected,
    this.onEditMetadata,
    this.onMoveToFolder,
    this.showCategoryPanel = true,
    this.onToggleCategoryPanel,
    this.enableSearchAutocomplete = true,
  });

  @override
  ConsumerState<LocalGalleryToolbar> createState() =>
      _LocalGalleryToolbarState();
}

class _LocalGalleryToolbarState extends ConsumerState<LocalGalleryToolbar> {
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocusNode;
  Timer? _debounceTimer;

  /// NAI 模型版本过滤 chips 的展示顺序与 label。
  static const List<String> _naiVersionLabels = ['3', '4', '4.5', '5'];

  /// NAI 版本 → 该版本包含的模型 ID 集（单击该 chip 时作为 filterModels 写入）。
  /// 以 [ImageModels] 中实际存在的常量名为准；版本 4/4.5/5 含对应的
  /// inpainting 变体，版本 3 按需求只列基础模型。
  static const Map<String, List<String>> _naiVersionModelIds = {
    '3': [
      ImageModels.animeFull,
      ImageModels.animeV2,
      ImageModels.animeDiffusionV3,
      ImageModels.furryDiffusionV3,
    ],
    '4': [
      ImageModels.animeDiffusionV4Full,
      ImageModels.animeDiffusionV4Curated,
      ImageModels.animeDiffusionV4FullInpainting,
      ImageModels.animeDiffusionV4CuratedInpainting,
    ],
    '4.5': [
      ImageModels.animeDiffusionV45Full,
      ImageModels.animeDiffusionV45Curated,
      ImageModels.animeDiffusionV45FullInpainting,
      ImageModels.animeDiffusionV45CuratedInpainting,
    ],
    '5': [
      ImageModels.animeDiffusionV5Full,
      ImageModels.animeDiffusionV5Curated,
      ImageModels.animeDiffusionV5FullInpainting,
      ImageModels.animeDiffusionV5CuratedInpainting,
    ],
  };

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode(onKeyEvent: _handleSearchKeyEvent);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    // Future 不需要 dispose
    super.dispose();
  }

  /// Search with debounce
  /// 搜索防抖
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(localGalleryNotifierProvider.notifier).setSearchQuery(value);
    });
  }

  KeyEventResult _handleSearchKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.keyA) {
      return KeyEventResult.ignored;
    }

    final keyboard = HardwareKeyboard.instance;
    if (!keyboard.isControlPressed && !keyboard.isMetaPressed) {
      return KeyEventResult.ignored;
    }

    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
    return KeyEventResult.handled;
  }

  Future<void> _selectAllFilteredImages() async {
    final paths = await ref
        .read(localGalleryNotifierProvider.notifier)
        .getFilteredImagePaths();
    if (!mounted) return;

    ref
        .read(localGallerySelectionNotifierProvider.notifier)
        .replaceSelection(paths);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localGalleryNotifierProvider);
    final selectionState = ref.watch(localGallerySelectionNotifierProvider);
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    // Show bulk action bar when in selection mode
    // 选择模式时显示批量操作栏
    if (selectionState.isActive) {
      final currentPageImagePaths = state.currentImages
          .map((r) => r.path)
          .toList();
      final isCurrentPageSelected =
          currentPageImagePaths.isNotEmpty &&
          currentPageImagePaths.every(
            (p) => selectionState.selectedIds.contains(p),
          );
      final selectableResultCount = state.hasFilters
          ? state.filteredCount
          : state.totalCount;
      final isAllResultSelected =
          selectableResultCount > 0 &&
          selectionState.selectedIds.length == selectableResultCount;

      return BulkActionBar(
        selectedCount: selectionState.selectedIds.length,
        isAllSelected: isCurrentPageSelected,
        isAllAvailableSelected: isAllResultSelected,
        onExit: () =>
            ref.read(localGallerySelectionNotifierProvider.notifier).exit(),
        onSelectAll: () {
          if (isCurrentPageSelected) {
            ref
                .read(localGallerySelectionNotifierProvider.notifier)
                .deselectAll(currentPageImagePaths);
          } else {
            ref
                .read(localGallerySelectionNotifierProvider.notifier)
                .selectAll(currentPageImagePaths);
          }
        },
        onSelectAllAvailable: selectableResultCount > 0
            ? () {
                if (isAllResultSelected) {
                  ref
                      .read(localGallerySelectionNotifierProvider.notifier)
                      .clearSelection();
                } else {
                  unawaited(_selectAllFilteredImages());
                }
              }
            : null,
        selectAllLabel: l10n.localGallery_selectCurrentPage,
        deselectAllLabel: l10n.localGallery_deselectCurrentPage,
        selectAllAvailableLabel: l10n.localGallery_selectAllResults,
        deselectAllAvailableLabel: l10n.localGallery_deselectAllResults,
        actions: [
          BulkActionItem(
            icon: Icons.drive_file_move_outline,
            label: l10n.localGallery_moveSelected,
            onPressed: widget.onMoveToFolder,
            color: theme.colorScheme.secondary,
          ),
          BulkActionItem(
            icon: Icons.archive_outlined,
            label: l10n.localGallery_packSelected,
            onPressed: widget.onPackSelected,
            color: theme.colorScheme.tertiary,
          ),
          BulkActionItem(
            icon: Icons.edit_outlined,
            label: l10n.localGallery_editMetadata,
            onPressed: widget.onEditMetadata,
            color: theme.colorScheme.primary,
          ),
          BulkActionItem(
            icon: Icons.playlist_add,
            label: l10n.localGallery_addToCollection,
            onPressed: widget.onAddToCollection,
            color: theme.colorScheme.secondary,
          ),
          BulkActionItem(
            icon: Icons.playlist_remove,
            label: l10n.localGallery_removeFromCollection,
            onPressed: widget.onRemoveFromCollection,
            color: theme.colorScheme.secondary,
          ),
          BulkActionItem(
            icon: Icons.delete_outline,
            label: l10n.common_delete,
            onPressed: widget.onDeleteSelected,
            color: theme.colorScheme.error,
            isDanger: true,
            showDividerBefore: true,
          ),
        ],
      );
    }

    // Normal toolbar
    // 普通工具栏
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: const BoxConstraints(minHeight: 62),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.9)
                : theme.colorScheme.surface.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: isDark ? 0.2 : 0.3),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Single row: title + count + search + filter/action buttons
              LayoutBuilder(
                builder: (context, constraints) {
                  final available = constraints.maxWidth;
                  // 响应式分档（按中英日常见标题/徽标宽度估算，极端窄窗口仍由
                  // 横向滚动兜底）：宽裕=全标签；收窄=CompactIconButton 只留
                  // 图标（tooltip 保留）；更窄=排序/日期这类带状态按钮也压成图标。
                  final showLabels = available >= 1740;
                  final showStateLabels = available >= 1170;
                  return Row(
                    children: [
                      // Title
                      Text(
                        l10n.localGallery_title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Image count
                      if (!state.isIndexing)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.primaryContainer.withValues(
                                    alpha: 0.4,
                                  )
                                : theme.colorScheme.primaryContainer.withValues(
                                    alpha: 0.3,
                                  ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            state.hasFilters
                                ? '${state.filteredCount}/${state.totalCount}'
                                : '${state.totalCount}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      // Search field（弹性占位；剩余空间主要让给右侧控件簇，
                      // 否则 50/50 均分时控件簇被压缩到横向滚动）
                      Flexible(flex: 1, child: _buildSearchField(theme, state)),
                      const SizedBox(width: 8),
                      // 右侧控件簇：窄窗口下横向滚动，避免溢出
                      Flexible(
                        flex: 2,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // NAI-only 过滤 chip（默认开，持久化偏好）
                              _buildNaiOnlyChip(theme, state),
                              const SizedBox(width: 6),
                              // NAI 模型版本过滤（下拉菜单：单选 3/4/4.5/5，
                              // 点已勾选项清除）
                              _buildNaiVersionMenu(theme, state),
                              const SizedBox(width: 6),
                              // 排序（字段菜单 + 方向切换）
                              _buildSortButton(
                                theme,
                                state,
                                showLabel: showStateLabels,
                              ),
                              const SizedBox(width: 6),
                              // 日期范围过滤按钮（点选式日历面板）
                              _buildDateRangeFilterButton(
                                theme,
                                state,
                                showLabel: showStateLabels,
                              ),
                              const SizedBox(width: 6),
                              // 视图切换：网格 → 瀑布流 → 火车流 三档循环
                              // （mosaic 预留，不进循环）
                              CompactIconButton(
                                icon: switch (state.viewMode) {
                                  GalleryViewMode.grid => Icons.grid_view,
                                  GalleryViewMode.masonry => Icons.view_quilt,
                                  GalleryViewMode.justified =>
                                    Icons.view_stream,
                                  GalleryViewMode.mosaic => Icons.dashboard,
                                },
                                label: switch (state.viewMode) {
                                  GalleryViewMode.grid => l10n.common_grid,
                                  GalleryViewMode.masonry =>
                                    l10n.localGallery_masonryViewLabel,
                                  GalleryViewMode.justified =>
                                    l10n.localGallery_justifiedViewLabel,
                                  GalleryViewMode.mosaic =>
                                    l10n.localGallery_masonryViewLabel,
                                },
                                // tooltip 指向「下一档」
                                tooltip: switch (state.viewMode) {
                                  GalleryViewMode.grid =>
                                    l10n.localGallery_switchToMasonryView,
                                  GalleryViewMode.masonry =>
                                    l10n.localGallery_switchToJustifiedView,
                                  GalleryViewMode.justified =>
                                    l10n.localGallery_switchToGridLayout,
                                  GalleryViewMode.mosaic =>
                                    l10n.localGallery_switchToGridLayout,
                                },
                                isActive:
                                    state.viewMode != GalleryViewMode.grid,
                                showLabel: showLabels,
                                onPressed: () {
                                  final notifier = ref.read(
                                    localGalleryNotifierProvider.notifier,
                                  );
                                  final next = switch (state.viewMode) {
                                    GalleryViewMode.grid =>
                                      GalleryViewMode.masonry,
                                    GalleryViewMode.masonry =>
                                      GalleryViewMode.justified,
                                    GalleryViewMode.justified =>
                                      GalleryViewMode.grid,
                                    GalleryViewMode.mosaic =>
                                      GalleryViewMode.grid,
                                  };
                                  notifier.setViewMode(next);
                                  unawaited(
                                    const GalleryViewModeStore().save(next),
                                  );
                                },
                              ),
                              const SizedBox(width: 6),
                              CompactIconButton(
                                icon: Icons.tune,
                                label: l10n.common_filter,
                                tooltip: l10n.localGallery_openFilterPanel,
                                shortcutId: ShortcutIds.openFilterPanel,
                                showLabel: showLabels,
                                onPressed: () =>
                                    showGalleryFilterPanel(context),
                              ),
                              // 清除按钮只对「会话过滤条件」出现：naiOnly 是常驻
                              // 偏好（默认开），仅剩它时清除无意义，按钮不该常驻
                              if (state.hasSessionFilters) ...[
                                const SizedBox(width: 6),
                                CompactIconButton(
                                  icon: Icons.filter_alt_off,
                                  label: l10n.common_clear,
                                  tooltip: l10n.localGallery_clearFilters,
                                  shortcutId: ShortcutIds.clearFilter,
                                  showLabel: showLabels,
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(
                                          localGalleryNotifierProvider.notifier,
                                        )
                                        .clearAllFilters();
                                  },
                                  isDanger: true,
                                ),
                              ],
                              // Divider
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Container(
                                  width: 1,
                                  height: 24,
                                  color: theme.dividerColor.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              // Category panel toggle
                              if (widget.onToggleCategoryPanel != null) ...[
                                CompactIconButton(
                                  icon: widget.showCategoryPanel
                                      ? Icons.view_sidebar
                                      : Icons.view_sidebar_outlined,
                                  label: l10n.common_categories,
                                  tooltip: widget.showCategoryPanel
                                      ? l10n.localGallery_hideCategoryPanel
                                      : l10n.localGallery_showCategoryPanel,
                                  shortcutId: ShortcutIds.toggleCategoryPanel,
                                  showLabel: showLabels,
                                  onPressed: widget.onToggleCategoryPanel,
                                ),
                                const SizedBox(width: 6),
                              ],
                              // Undo/Redo
                              if (widget.canUndo || widget.canRedo) ...[
                                CompactIconButton(
                                  icon: Icons.undo,
                                  tooltip: l10n.common_undo,
                                  showLabel: showLabels,
                                  onPressed: widget.canUndo
                                      ? widget.onUndo
                                      : null,
                                ),
                                const SizedBox(width: 4),
                                CompactIconButton(
                                  icon: Icons.redo,
                                  tooltip: l10n.common_redo,
                                  showLabel: showLabels,
                                  onPressed: widget.canRedo
                                      ? widget.onRedo
                                      : null,
                                ),
                                const SizedBox(width: 6),
                              ],
                              // Multi-select
                              CompactIconButton(
                                icon: Icons.checklist,
                                label: l10n.common_multiSelect,
                                tooltip: l10n.localGallery_enterSelectionMode,
                                shortcutId: ShortcutIds.enterSelectionMode,
                                showLabel: showLabels,
                                onPressed: widget.onEnterSelectionMode,
                              ),
                              const SizedBox(width: 6),
                              // Open folder
                              CompactIconButton(
                                icon: Icons.folder_open,
                                label: l10n.common_folder,
                                tooltip: l10n.shortcut_action_open_folder,
                                shortcutId: ShortcutIds.openFolder,
                                showLabel: showLabels,
                                onPressed: widget.onOpenFolder,
                              ),
                              const SizedBox(width: 6),
                              // Refresh button
                              CompactIconButton(
                                icon: Icons.refresh,
                                label: l10n.common_refresh,
                                tooltip: l10n.localGallery_refreshTooltip,
                                shortcutId: ShortcutIds.refreshGallery,
                                showLabel: showLabels,
                                onPressed: widget.onRefresh,
                              ),
                              const SizedBox(width: 6),
                              // Trash (delete pool)：软删文件在此恢复/彻底删除
                              CompactIconButton(
                                icon: Icons.delete_outline,
                                label: l10n.localGallery_trashTitle,
                                tooltip: l10n.localGallery_trashTitle,
                                showLabel: showLabels,
                                onPressed: () =>
                                    showGalleryTrashPanel(context, ref),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (state.filterCriteria.selectedTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildSelectedTagChips(theme, state),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 当前搜索范围名称（收藏/收藏集/分类/日期范围），无范围时返回 null
  String? _searchScopeLabel(
    LocalGalleryState state,
    GalleryCategoryState categoryState,
  ) {
    final criteria = state.filterCriteria;
    if (criteria.showFavoritesOnly || criteria.categoryId == 'favorites') {
      return context.l10n.common_favorite;
    }
    if (criteria.collectionId != null) {
      final collectionState = ref.read(collectionNotifierProvider);
      final collection = collectionState.collections
          .where((c) => c.id == criteria.collectionId)
          .firstOrNull;
      if (collection != null) return collection.name;
    }
    if (criteria.categoryId != null) {
      final category = categoryState.categories.findById(criteria.categoryId!);
      if (category != null) return category.displayName;
    }
    if (criteria.dateStart != null || criteria.dateEnd != null) {
      return _formatDateRange(criteria.dateStart, criteria.dateEnd);
    }
    return null;
  }

  /// Build search field
  /// 构建搜索框 - 类似在线画廊的简洁圆角样式
  Widget _buildSearchField(ThemeData theme, LocalGalleryState state) {
    final categoryState = ref.watch(galleryCategoryNotifierProvider);
    final scopeLabel = _searchScopeLabel(state, categoryState);
    final searchField = Container(
      height: 36,
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: scopeLabel != null
              ? context.l10n.localGallery_searchInScope(scopeLabel)
              : context.l10n.localGallery_searchFilenamePromptPlaceholder,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    ref
                        .read(localGalleryNotifierProvider.notifier)
                        .setSearchQuery('');
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {}); // 更新清除按钮可见性
          _onSearchChanged(value);
        },
        onSubmitted: (value) {
          _debounceTimer?.cancel();
          ref.read(localGalleryNotifierProvider.notifier).setSearchQuery(value);
        },
      ),
    );

    if (!widget.enableSearchAutocomplete) {
      return searchField;
    }

    return AutocompleteWrapper(
      controller: _searchController,
      focusNode: _searchFocusNode,
      config: const AutocompleteConfig(
        minQueryLength: 2,
        showTranslation: true,
        showCategory: true,
        showCount: true,
        autoInsertComma: false,
      ),
      onSuggestionSelected: (value) {
        // 选中补全建议 → 转为标签 chip（取最后一个片段），清空搜索框
        _debounceTimer?.cancel();
        final segments = value.split(RegExp(r'[,，]+'));
        final tag = segments.isEmpty ? value.trim() : segments.last.trim();
        if (tag.isNotEmpty) {
          ref.read(localGalleryNotifierProvider.notifier).addSelectedTags([
            tag,
          ], clearSearchQuery: true);
        }
        _searchController.clear();
        setState(() {}); // 更新清除按钮可见性
      },
      child: searchField,
    );
  }

  Widget _buildSelectedTagChips(ThemeData theme, LocalGalleryState state) {
    final tags = state.filterCriteria.selectedTags;

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Text(
              context.l10n.localGallery_tagIntersection,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final tag in tags)
            InputChip(
              avatar: const Icon(Icons.tag, size: 14),
              label: Text(tag),
              onDeleted: () {
                ref
                    .read(localGalleryNotifierProvider.notifier)
                    .removeSelectedTag(tag);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
              ),
            ),
        ],
      ),
    );
  }

  /// Build NAI-only filter chip
  /// NAI-only 过滤切换 chip：点按切换并持久化偏好
  Widget _buildNaiOnlyChip(ThemeData theme, LocalGalleryState state) {
    final l10n = context.l10n;
    final naiOnly = state.filterCriteria.naiOnly;
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: l10n.localGallery_naiOnlyTooltip,
      child: FilterChip(
        avatar: Icon(
          Icons.auto_awesome,
          size: 14,
          color: naiOnly ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        label: Text(
          l10n.localGallery_naiOnly,
          style: TextStyle(
            fontSize: 12,
            fontWeight: naiOnly ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        selected: naiOnly,
        onSelected: (value) {
          ref.read(localGalleryNotifierProvider.notifier).setNaiOnly(value);
          unawaited(const GalleryNaiOnlyStore().save(value));
        },
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        showCheckmark: false,
        side: BorderSide(
          color: naiOnly
              ? colorScheme.primary.withValues(alpha: 0.6)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        selectedColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }

  /// 当前 filterModels 是否正好等于某个版本 ID 集（集合级相等；空/非空区分）。
  bool _isNaiVersionActive(LocalGalleryState state, String version) {
    final current = state.filterCriteria.filterModels;
    final ids = _naiVersionModelIds[version] ?? const <String>[];
    if (current.length != ids.length) return false;
    return setEquals(current.toSet(), ids.toSet());
  }

  /// Build NAI model version filter dropdown menu
  /// NAI 模型版本过滤下拉：按钮显示当前选中版本（未选显示通用标签），点击
  /// 向下展开 3/4/4.5/5；点未勾选项=写入该版本 ID 集，点已勾选项=清空
  /// （setFilterModels 整表替换天然满足单选）。
  /// 视觉壳套路同 [_buildSortButton]：IgnorePointer 让 PopupMenuButton 自己
  /// 收手势。
  Widget _buildNaiVersionMenu(ThemeData theme, LocalGalleryState state) {
    final l10n = context.l10n;
    final colorScheme = theme.colorScheme;

    String? activeVersion;
    for (final version in _naiVersionLabels) {
      if (_isNaiVersionActive(state, version)) {
        activeVersion = version;
        break;
      }
    }
    final active = activeVersion != null;

    return PopupMenuButton<String>(
      tooltip: l10n.localGallery_naiVersionFilterTooltip,
      onSelected: (version) {
        final notifier = ref.read(localGalleryNotifierProvider.notifier);
        notifier.setFilterModels(
          version == activeVersion
              ? const <String>[]
              : (_naiVersionModelIds[version] ?? const []),
        );
      },
      itemBuilder: (context) => [
        for (final version in _naiVersionLabels)
          PopupMenuItem(
            value: version,
            child: Row(
              children: [
                const Icon(Icons.memory, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('NAI $version')),
                if (version == activeVersion)
                  Icon(Icons.check, size: 16, color: colorScheme.primary),
              ],
            ),
          ),
      ],
      child: IgnorePointer(
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: Icon(
            Icons.memory,
            size: 16,
            color: active ? colorScheme.primary : null,
          ),
          label: Text(
            active
                ? 'NAI $activeVersion'
                : l10n.localGallery_naiVersionFilterLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? colorScheme.primary : null,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }

  /// Build sort control: field menu (left) + direction toggle (right)
  /// 两段式排序：左=字段菜单（当前项打勾），右=升降序切换（点一下反转）
  ///
  /// [showLabel] false 时字段菜单只留图标（tooltip 保留），用于窄窗口降级。
  Widget _buildSortButton(
    ThemeData theme,
    LocalGalleryState state, {
    bool showLabel = true,
  }) {
    final l10n = context.l10n;

    final fields = <(GallerySortField, IconData, String)>[
      (
        GallerySortField.modifiedAt,
        Icons.schedule,
        l10n.localGallery_sortFieldModified,
      ),
      (
        GallerySortField.createdAt,
        Icons.history,
        l10n.localGallery_sortFieldCreated,
      ),
      (
        GallerySortField.fileName,
        Icons.sort_by_alpha,
        l10n.localGallery_sortFieldName,
      ),
      (
        GallerySortField.fileSize,
        Icons.data_usage,
        l10n.localGallery_sortFieldSize,
      ),
      (
        GallerySortField.imageDimensions,
        Icons.photo_size_select_large,
        l10n.localGallery_sortFieldDimensions,
      ),
    ];

    final currentFieldLabel = fields
        .firstWhere((option) => option.$1 == state.sortField)
        .$3;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 左半：字段菜单（切字段时方向复位为该字段默认方向）
        PopupMenuButton<GallerySortField>(
          tooltip: l10n.localGallery_sortButton,
          onSelected: (field) {
            ref
                .read(localGalleryNotifierProvider.notifier)
                .setSort(field, GallerySort.defaultDirectionFor(field));
            unawaited(
              const GallerySortStore().save(
                GallerySort.withDefaultDirection(field),
              ),
            );
          },
          itemBuilder: (context) => [
            for (final (field, icon, label) in fields)
              PopupMenuItem(
                value: field,
                child: Row(
                  children: [
                    Icon(icon, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(label)),
                    if (field == state.sortField)
                      Icon(
                        Icons.check,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ),
          ],
          // 子组件只是视觉壳：若直接放可点击按钮，内层按钮会赢下手势
          // 竞技场吞掉 tap，PopupMenuButton 永远收不到点击（菜单打不开）。
          // 用 IgnorePointer 让 PopupMenuButton 自己的 InkWell 收手势。
          child: IgnorePointer(
            child: showLabel
                ? OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.sort, size: 16),
                    label: Text(
                      currentFieldLabel,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                : OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(32, 0),
                    ),
                    child: const Icon(Icons.sort, size: 16),
                  ),
          ),
        ),
        const SizedBox(width: 4),
        // 右半：升降序切换（直接反转当前字段方向）
        Tooltip(
          message: l10n.localGallery_sortToggleDirection,
          child: OutlinedButton(
            onPressed: () {
              final next = state.sortDirection == GallerySortDirection.ascending
                  ? GallerySortDirection.descending
                  : GallerySortDirection.ascending;
              ref
                  .read(localGalleryNotifierProvider.notifier)
                  .setSort(state.sortField, next);
              unawaited(
                const GallerySortStore().save(
                  GallerySort(field: state.sortField, direction: next),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(32, 0),
            ),
            child: Icon(
              state.sortDirection == GallerySortDirection.descending
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  /// Build date range filter button
  /// 构建日期范围过滤按钮（点选式日历面板）
  ///
  /// [showLabel] false 时只留图标（激活色保留），用于窄窗口降级。
  Widget _buildDateRangeFilterButton(
    ThemeData theme,
    LocalGalleryState state, {
    bool showLabel = true,
  }) {
    final hasDateRange =
        state.filterCriteria.dateStart != null ||
        state.filterCriteria.dateEnd != null;

    return OutlinedButton.icon(
      onPressed: () => _showDateRangeDialog(),
      icon: Icon(
        Icons.calendar_today,
        size: 16,
        color: hasDateRange ? theme.colorScheme.primary : null,
      ),
      label: !showLabel
          ? const SizedBox.shrink()
          : Text(
              hasDateRange
                  ? _formatDateRange(
                      state.filterCriteria.dateStart,
                      state.filterCriteria.dateEnd,
                    )
                  : context.l10n.common_date,
              style: TextStyle(
                fontSize: 12,
                color: hasDateRange ? theme.colorScheme.primary : null,
              ),
            ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        visualDensity: VisualDensity.compact,
        side: hasDateRange
            ? BorderSide(color: theme.colorScheme.primary)
            : null,
      ),
    );
  }

  /// Format date range display
  /// 格式化日期范围显示
  String _formatDateRange(DateTime? start, DateTime? end) {
    final format = DateFormat('MM-dd');
    if (start != null && end != null) {
      return '${format.format(start)}~${format.format(end)}';
    } else if (start != null) {
      return '${format.format(start)}~';
    } else if (end != null) {
      return '~${format.format(end)}';
    }
    return '';
  }

  /// Show date range picker dialog
  /// 打开点选式日期范围面板，确定后写入过滤条件（单日 = start == end）
  Future<void> _showDateRangeDialog() async {
    final criteria = ref.read(localGalleryNotifierProvider).filterCriteria;
    final result = await showDateRangePickerDialog(
      context,
      initialStart: criteria.dateStart,
      initialEnd: criteria.dateEnd,
    );
    if (result == null || !mounted) return;
    await ref
        .read(localGalleryNotifierProvider.notifier)
        .setDateRange(result.start, result.end);
  }
}
