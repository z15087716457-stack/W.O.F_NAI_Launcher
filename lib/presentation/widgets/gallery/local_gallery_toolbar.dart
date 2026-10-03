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
import '../../providers/tips_provider.dart';
import '../bulk_action_bar.dart';
import '../common/compact_icon_button.dart';
import 'gallery_trash_panel.dart';
import '../gallery_filter_panel.dart';

import '../tag_expansion/tag_expansion_wrapper.dart';
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
  final VoidCallback? onCopyToFolder;

  /// Whether category panel is visible
  /// 是否显示分类面板
  final bool showCategoryPanel;

  /// Callback when category panel toggle is pressed
  /// 分类面板切换按钮回调
  final VoidCallback? onToggleCategoryPanel;

  /// Whether explicit tag search is enabled for the gallery search field.
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
    this.onCopyToFolder,
    this.showCategoryPanel = true,
    this.onToggleCategoryPanel,
    this.enableSearchAutocomplete = true,
    this.framed = true,
  });

  final bool framed;

  @override
  ConsumerState<LocalGalleryToolbar> createState() =>
      _LocalGalleryToolbarState();
}

class _LocalGalleryToolbarState extends ConsumerState<LocalGalleryToolbar> {
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocusNode;
  Timer? _debounceTimer;

  /// 挂载时的 tip 轮次：首轮固定出使用说明句（FEAT-60）。
  /// 懒初始化而非 initState 赋值——热重载不重跑 initState。
  int? _tipMountEpoch;

  /// NAI 模型版本过滤 chips 的展示顺序与 label。
  static const List<String> _naiVersionLabels = ['3', '4', '4.5', '5'];

  /// 标题 + 计数徽标的预留宽度（按中英日三语最长标题估算，略宽松）。
  static const double _kTitleBadgeReserve = 240;

  /// 搜索框的最小宽度：按钮簇宽度上限据此留出，防止被挤没。
  static const double _kSearchMinWidth = 160;

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

  /// 版本 → Full/Curated 变体子集（版本行悬停子菜单可选粒度）。
  /// 子集沿用该版本 inpainting 变体；NAI 3 无变体之分故不挂子菜单。
  static const Map<String, List<String>> _naiVersionFullIds = {
    '4': [
      ImageModels.animeDiffusionV4Full,
      ImageModels.animeDiffusionV4FullInpainting,
    ],
    '4.5': [
      ImageModels.animeDiffusionV45Full,
      ImageModels.animeDiffusionV45FullInpainting,
    ],
    '5': [
      ImageModels.animeDiffusionV5Full,
      ImageModels.animeDiffusionV5FullInpainting,
    ],
  };

  /// 见 [_naiVersionFullIds]。
  static const Map<String, List<String>> _naiVersionCuratedIds = {
    '4': [
      ImageModels.animeDiffusionV4Curated,
      ImageModels.animeDiffusionV4CuratedInpainting,
    ],
    '4.5': [
      ImageModels.animeDiffusionV45Curated,
      ImageModels.animeDiffusionV45CuratedInpainting,
    ],
    '5': [
      ImageModels.animeDiffusionV5Curated,
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
        framed: widget.framed,
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
            icon: Icons.file_copy_outlined,
            label: l10n.localGallery_copyTo,
            onPressed: widget.onCopyToFolder,
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
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: widget.framed ? 12 : 11,
          ),
          constraints: const BoxConstraints(minHeight: 62),
          decoration: widget.framed
              ? BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHigh.withValues(
                          alpha: 0.9,
                        )
                      : theme.colorScheme.surface.withValues(alpha: 0.8),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withValues(
                        alpha: isDark ? 0.2 : 0.3,
                      ),
                    ),
                  ),
                )
              : null,
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
                  // 右侧按钮簇的宽度上限：给标题/徽标和搜索框最小宽度留位。
                  // 横向 SingleChildScrollView 在松散约束下收缩到内容宽度
                  // （size = constraints.constrain(child.size)），配合
                  // Expanded 搜索框，按钮簇自然贴到工具栏最右端；超出
                  // clusterMax 时退回横向滚动而不是溢出。
                  final clusterMax =
                      (available -
                              _kTitleBadgeReserve -
                              20 - // SizedBox(12) + SizedBox(8) 间距
                              _kSearchMinWidth)
                          .clamp(0.0, double.infinity);
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
                      // Search field：占满中间全部剩余空间，窗口宽窄时随之
                      // 伸缩，把右侧按钮簇自然推到工具栏右端
                      Expanded(child: _buildSearchField(theme, state)),
                      const SizedBox(width: 8),
                      // 右侧控件簇：松散约束下收缩到按钮自然宽度并贴右；
                      // 超过 clusterMax（极窄窗口）时横向滚动兜底
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: clusterMax),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // NAI + 版本过滤合并胶囊（左 NAI 开关 / 右 Ver 菜单，
                              // 版本选中自动点亮 NAI，关 NAI 连带清版本）
                              _buildNaiVersionSegment(theme, state),
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
                              CompactIconButton(
                                icon: switch (state.viewMode) {
                                  GalleryViewMode.grid => Icons.grid_view,
                                  GalleryViewMode.masonry => Icons.view_quilt,
                                  GalleryViewMode.justified =>
                                    Icons.view_stream,
                                },
                                label: switch (state.viewMode) {
                                  GalleryViewMode.grid => l10n.common_grid,
                                  GalleryViewMode.masonry =>
                                    l10n.localGallery_masonryViewLabel,
                                  GalleryViewMode.justified =>
                                    l10n.localGallery_justifiedViewLabel,
                                },
                                // tooltip 指向「下一档」
                                tooltip: switch (state.viewMode) {
                                  GalleryViewMode.grid =>
                                    l10n.localGallery_switchToMasonryView,
                                  GalleryViewMode.masonry =>
                                    l10n.localGallery_switchToJustifiedView,
                                  GalleryViewMode.justified =>
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
      constraints: const BoxConstraints(minWidth: _kSearchMinWidth),
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
              : watchTipHint(
                  ref,
                  context.l10n,
                  TipSurface.gallerySearch,
                  firstEpoch: _tipMountEpoch ??= currentTipEpoch(),
                ),
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

    return TagExpansionWrapper(
      controller: _searchController,
      focusNode: _searchFocusNode,
      onTagSelected: (tag) {
        _debounceTimer?.cancel();
        ref.read(localGalleryNotifierProvider.notifier).addSelectedTags([
          tag,
        ], clearSearchQuery: true);
        _searchController.clear();
        setState(() {});
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

  /// 合并的「NAI + 版本」过滤胶囊：左半 NAI 开关、右半 Ver 版本菜单，
  /// 中间竖线分隔。
  ///
  /// 交互契约：
  /// - 右半选中版本 → 写入该版本模型 ID 集，并自动点亮 NAI（版本过滤
  ///   本就是 NAI 子集）；点已勾版本 = 清除版本，NAI 保持开
  /// - 左半点按 toggle NAI；关闭 NAI 时连带清除版本（NAI 都关了，
  ///   版本还留着没意义）
  ///
  /// 视觉契约：
  /// - NAI 激活 → 左半套「官网式反色内胆」：onSurface 实心底 + surface
  ///   反色图标文字（深浅主题自动镜像，与生图页模型胶囊同款）
  /// - 版本激活 → 外框底色/描边/竖线走 primary 高亮
  /// - 只开 NAI 不选版本 → 外框保持中性，仅靠左半反色胶囊表达
  Widget _buildNaiVersionSegment(ThemeData theme, LocalGalleryState state) {
    final l10n = context.l10n;
    final colorScheme = theme.colorScheme;
    final naiOnly = state.filterCriteria.naiOnly;

    String? activeVersion;
    String? activeVariantKind; // 'F' / 'C'：filterModels 精确命中某变体子集
    for (final version in _naiVersionLabels) {
      if (_isNaiVersionActive(state, version)) {
        activeVersion = version;
        break;
      }
    }
    if (activeVersion == null) {
      for (final version in _naiVersionLabels) {
        if (_matchesModels(state, _naiVersionFullIds[version])) {
          activeVersion = version;
          activeVariantKind = 'F';
          break;
        }
        if (_matchesModels(state, _naiVersionCuratedIds[version])) {
          activeVersion = version;
          activeVariantKind = 'C';
          break;
        }
      }
    }
    final versionActive = activeVersion != null;

    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant;

    return Tooltip(
      message: l10n.localGallery_naiOnlyTooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: versionActive
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            border: Border.all(
              color: versionActive
                  ? activeColor.withValues(alpha: 0.6)
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 左半：NAI 开关（novelai 图标 + NAI 文字；激活时套反色内胆）
              InkWell(
                onTap: () {
                  final notifier = ref.read(
                    localGalleryNotifierProvider.notifier,
                  );
                  final next = !naiOnly;
                  notifier.setNaiOnly(next);
                  unawaited(const GalleryNaiOnlyStore().save(next));
                  if (!next && versionActive) {
                    notifier.setFilterModels(const <String>[]);
                  }
                },
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(7),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SizedBox(
                    height: 22,
                    child: naiOnly
                        // 激活：官网式反色内胆（浅色底↔深色内容随主题镜像）
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/icons/novelai-icon.png',
                                  width: 12,
                                  height: 12,
                                  color: colorScheme.surface,
                                  filterQuality: FilterQuality.medium,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.localGallery_naiOnly,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.surface,
                                  ),
                                ),
                              ],
                            ),
                          )
                        // 未激活：纯文字形态
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/icons/novelai-icon.png',
                                width: 13,
                                height: 13,
                                color: inactiveColor,
                                filterQuality: FilterQuality.medium,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                l10n.localGallery_naiOnly,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              // 竖线分隔
              Container(
                width: 1,
                height: 16,
                color: versionActive
                    ? activeColor.withValues(alpha: 0.35)
                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              // 右半：Ver 版本菜单（无图标；未选显示 Ver，选中显示 Ver N）
              // PopupMenuPosition.under：菜单紧贴胶囊下缘展开（默认 over
              // 是从按钮中间弹出盖住胶囊）。child 撑满 32px 高让按钮下缘
              // 与胶囊下缘对齐，offset 留 2px 呼吸缝。
              PopupMenuButton<String>(
                tooltip: l10n.localGallery_naiVersionFilterTooltip,
                position: PopupMenuPosition.under,
                offset: const Offset(0, 2),
                padding: EdgeInsets.zero,
                onSelected: (version) {
                  _applyNaiVersionSelection(
                    version == activeVersion
                        ? const <String>[]
                        : (_naiVersionModelIds[version] ?? const []),
                    enableNai: !naiOnly && version != activeVersion,
                  );
                },
                itemBuilder: (context) => [
                  for (final version in _naiVersionLabels)
                    if (_naiVersionFullIds.containsKey(version))
                      _NaiVersionEntry(
                        version: version,
                        selected: version == activeVersion,
                        activeVariant: version == activeVersion
                            ? activeVariantKind
                            : null,
                        fullIds: _naiVersionFullIds[version]!,
                        curatedIds: _naiVersionCuratedIds[version]!,
                        onSelectVariant: (ids) =>
                            _applyNaiVersionSelection(ids, enableNai: !naiOnly),
                      )
                    else
                      PopupMenuItem(
                        value: version,
                        child: Row(
                          children: [
                            Expanded(child: Text('NAI $version')),
                            if (version == activeVersion)
                              Icon(
                                Icons.check,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    height: 32,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          versionActive
                              ? 'Ver $activeVersion${activeVariantKind ?? ''}'
                              : l10n.localGallery_naiVersionFilterLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: versionActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: versionActive ? activeColor : null,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 15,
                          color: versionActive ? activeColor : inactiveColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 当前 filterModels 是否正好等于某个版本 ID 集（集合级相等；空/非空区分）。
  bool _isNaiVersionActive(LocalGalleryState state, String version) {
    return _matchesModels(state, _naiVersionModelIds[version]);
  }

  /// filterModels 与给定 ID 集做集合级相等比较（[ids] 为 null 时不命中）。
  bool _matchesModels(LocalGalleryState state, List<String>? ids) {
    if (ids == null) return false;
    final current = state.filterCriteria.filterModels;
    if (current.length != ids.length) return false;
    return setEquals(current.toSet(), ids.toSet());
  }

  /// 版本/变体菜单共用的过滤写入：写 filterModels，选中时按需点亮 NAI。
  ///
  /// [enableNai] 为 true 时同步打开 NAI-only（版本过滤本就是 NAI 子集）。
  void _applyNaiVersionSelection(
    List<String> modelIds, {
    required bool enableNai,
  }) {
    final notifier = ref.read(localGalleryNotifierProvider.notifier);
    notifier.setFilterModels(modelIds);
    if (enableNai && modelIds.isNotEmpty) {
      notifier.setNaiOnly(true);
      unawaited(const GalleryNaiOnlyStore().save(true));
    }
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

/// NAI 版本菜单中带变体子菜单的条目（Full/Curated）。
///
/// 继承 [PopupMenuItem] 直接复用其行高/文字/内边距/语义实现（行高随
/// fontScale 与主菜单其他行严格一致）：点击 = 选该版本全部变体
/// （默认 handleTap pop 返回值走外层 PopupMenuButton.onSelected）；
/// 悬停 800ms 在条目外框右缘展开变体子菜单，悬停/展开期间行尾出现 `›`。
/// 子菜单挂 root overlay 以便盖在主菜单之上，条目中按右缘对齐。
class _NaiVersionEntry extends PopupMenuItem<String> {
  const _NaiVersionEntry({
    required this.version,
    required this.selected,
    required this.activeVariant,
    required this.fullIds,
    required this.curatedIds,
    required this.onSelectVariant,
  }) : super(value: version, child: const SizedBox.shrink());

  /// 版本标签（如 '4.5'）。
  final String version;

  /// 该版本是否处于激活态（全量或任一子集命中）。
  final bool selected;

  /// 激活的变体（'F'/'C'）；未激活或非变体命中为 null。
  final String? activeVariant;

  /// Full / Curated 子集对应的模型 ID 集。
  final List<String> fullIds;
  final List<String> curatedIds;

  /// 子菜单选中变体后的回调（宿主负责写过滤与关菜单收尾）。
  final ValueChanged<List<String>> onSelectVariant;

  /// 同一时刻只保留一个展开的子菜单；悬停切行时顶替旧的。
  static VoidCallback? _closeOpenSubmenu;

  @override
  PopupMenuItemState<String, _NaiVersionEntry> createState() =>
      _NaiVersionEntryState();
}

class _NaiVersionEntryState
    extends PopupMenuItemState<String, _NaiVersionEntry> {
  static const _kHoverDelay = Duration(milliseconds: 800);
  static const _kCloseGrace = Duration(milliseconds: 200);

  Timer? _openTimer;
  Timer? _closeTimer;
  OverlayEntry? _submenuEntry;
  final LayerLink _link = LayerLink();
  bool _hoverRow = false;
  bool _hoverSubmenu = false;

  bool get _submenuOpen => _submenuEntry != null;

  @override
  void dispose() {
    _openTimer?.cancel();
    _closeTimer?.cancel();
    _submenuEntry?.remove();
    _submenuEntry = null;
    if (identical(_NaiVersionEntry._closeOpenSubmenu, _hideSubmenu)) {
      _NaiVersionEntry._closeOpenSubmenu = null;
    }
    super.dispose();
  }

  void _onRowEnter() {
    _closeTimer?.cancel();
    setState(() => _hoverRow = true);
    // 已是展开状态（指针从子菜单折返行上）则不再计时
    if (!_submenuOpen) {
      _openTimer?.cancel();
      _openTimer = Timer(_kHoverDelay, _showSubmenu);
    }
  }

  void _onRowExit() {
    _openTimer?.cancel();
    setState(() => _hoverRow = false);
    _scheduleClose();
  }

  void _scheduleClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(_kCloseGrace, () {
      if (!_hoverRow && !_hoverSubmenu) _hideSubmenu();
    });
  }

  void _showSubmenu() {
    if (!mounted || _submenuOpen) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    const menuWidth = 140.0;

    _NaiVersionEntry._closeOpenSubmenu?.call();
    final popupTheme = PopupMenuTheme.of(context);
    // 子菜单纵向内边距与主菜单同源（M3 默认上下 8），跟随菜单主题
    final menuPadding =
        popupTheme.menuPadding?.resolve(Directionality.of(context)) ??
        const EdgeInsets.symmetric(vertical: 8);
    _submenuEntry = OverlayEntry(
      // OverlayEntry 的 child 是 overlay theatre（Stack）的直接子节点，
      // Positioned.fill 可直接做根。
      builder: (overlayContext) => Positioned.fill(
        // CompositedTransformFollower 直接挂在条目渲染对象的 layer 上：
        // 子菜单左缘贴条目右缘、顶边上移一个菜单内边距，让首项文字
        // 与所在行文字对齐（级联菜单惯例）。
        child: CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.topLeft,
          offset: Offset(0, -menuPadding.top),
          child: Align(
            alignment: Alignment.topLeft,
            child: MouseRegion(
              onEnter: (_) {
                _closeTimer?.cancel();
                _hoverSubmenu = true;
              },
              onExit: (_) {
                _hoverSubmenu = false;
                _scheduleClose();
              },
              // 与主菜单同一套 popupMenuTheme（底色/圆角/阴影/文字样式）
              child: Material(
                elevation: popupTheme.elevation ?? 8,
                shadowColor: popupTheme.shadowColor,
                surfaceTintColor: popupTheme.surfaceTintColor,
                shape: popupTheme.shape,
                clipBehavior: Clip.antiAlias,
                color:
                    popupTheme.color ??
                    Theme.of(context).colorScheme.surfaceContainer,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: menuWidth),
                  child: IntrinsicWidth(
                    child: Padding(
                      // 与主菜单一致的纵向 menuPadding
                      padding: menuPadding,
                      child: Semantics(
                        role: ui.SemanticsRole.menu,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _variantItem('Full', 'F', widget.fullIds),
                            _variantItem('Curated', 'C', widget.curatedIds),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_submenuEntry!);
    _NaiVersionEntry._closeOpenSubmenu = _hideSubmenu;
    setState(() {}); // 触发箭头显示
  }

  /// 子菜单项：关菜单必须经 [context]（挂在弹窗路由内部、归属持有该路由的
  /// 分支 Navigator）pop；子菜单 item 自己的 context 在根 Overlay 里，
  /// PopupMenuItem 默认 handleTap 的 pop 会弹掉根 Navigator 上的页面路由
  /// （嵌套 Navigator/StatefulShellRoute 下即整页白屏），故不能用默认实现。
  Widget _variantItem(String label, String kind, List<String> ids) {
    final colorScheme = Theme.of(context).colorScheme;
    return _VariantMenuItem(
      onSelect: () {
        final selectVariant = widget.onSelectVariant;
        // 先 pop 弹窗路由（沿用 PopupMenuItem.handleTap 的顺序：pop 在前，
        // 回调在后，避免回调里推新路由被 pop 误伤）；路由移除会连带 dispose
        // 本条目并清掉子菜单 OverlayEntry，随后回调写过滤。
        Navigator.of(context).pop();
        _hideSubmenu();
        selectVariant(ids);
      },
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (widget.activeVariant == kind)
            Icon(Icons.check, size: 16, color: colorScheme.primary),
        ],
      ),
    );
  }

  void _hideSubmenu() {
    _submenuEntry?.remove();
    _submenuEntry = null;
    if (identical(_NaiVersionEntry._closeOpenSubmenu, _hideSubmenu)) {
      _NaiVersionEntry._closeOpenSubmenu = null;
    }
    if (mounted) setState(() {});
  }

  /// 复用 PopupMenuItem 的 build 产出（AnimatedDefaultTextStyle +
  /// ConstrainedBox(minHeight) + M3 内边距 + Align + InkWell + 语义），
  /// 外层只补悬停检测的 MouseRegion。
  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        onEnter: (_) => _onRowEnter(),
        onExit: (_) => _onRowExit(),
        child: super.build(context),
      ),
    );
  }

  /// 菜单行内容：版本名 + 选中勾 + 悬停/展开时的级联箭头。
  @override
  Widget buildChild() {
    final colorScheme = Theme.of(context).colorScheme;
    final showArrow = _hoverRow || _submenuOpen;
    return Row(
      children: [
        Expanded(child: Text('NAI ${widget.version}')),
        if (widget.selected)
          Icon(Icons.check, size: 16, color: colorScheme.primary),
        if (showArrow)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// 变体子菜单项：视觉与 [PopupMenuItem] 完全一致（直接继承其 build），
/// 但点击不走默认 handleTap 的 pop——item 挂在根 Overlay 的 OverlayEntry
/// 里，默认 pop 弹掉的是根 Navigator 上的页面路由（白屏）。改由
/// [onSelect] 回调用条目宿主（弹窗路由内部）的 context 关菜单。
class _VariantMenuItem extends PopupMenuItem<String> {
  const _VariantMenuItem({required this.onSelect, required super.child});

  /// 点选回调：由宿主负责关弹窗 + 写过滤。
  final VoidCallback onSelect;

  @override
  PopupMenuItemState<String, _VariantMenuItem> createState() =>
      _VariantMenuItemState();
}

class _VariantMenuItemState
    extends PopupMenuItemState<String, _VariantMenuItem> {
  @override
  void handleTap() {
    widget.onSelect();
  }
}
