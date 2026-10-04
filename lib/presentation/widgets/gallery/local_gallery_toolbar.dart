import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/shortcuts/default_shortcuts.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/gallery/gallery_category.dart';
import '../../../data/services/gallery/gallery_column_width_store.dart';
import '../../../data/services/gallery/gallery_sort.dart';
import '../../../data/services/gallery/gallery_sort_store.dart';
import '../../../data/services/gallery/gallery_view_mode.dart';
import '../../../data/services/gallery/gallery_view_mode_store.dart';
import '../../providers/collection_provider.dart';
import '../../providers/gallery_category_provider.dart';
import '../../providers/local_gallery_provider.dart';
import '../../providers/selection_mode_provider.dart';
import '../../providers/tips_provider.dart';
import '../shortcuts/shortcut_tooltip.dart';
import '../navigation/window_chrome_layout.dart';
import '../tag_expansion/tag_expansion_wrapper.dart';
import '../common/studio_icons.dart';

/// 顶栏高度（与块库等资料页一致）
const double localGalleryToolbarHeight = 62;

/// 搜索框最宽值：1080p 及以下窗口正好占满，更宽的窗口也不拉成整条横线。
const double _searchMaxWidth = 880;

enum _MoreAction { openFolder, refresh, undo, redo, toggleSidebar }

/// 本地画廊顶栏：当前范围与数量、搜索、排序、视图、缩略图大小、
/// 多选与详情面板开关；不常用的操作收进「更多」。
class LocalGalleryToolbar extends ConsumerStatefulWidget {
  const LocalGalleryToolbar({
    super.key,
    required this.searchFocusNode,
    required this.inspectorVisible,
    required this.inspectorAvailable,
    required this.onToggleInspector,
    required this.onOpenFolder,
    required this.onRefresh,
    required this.showCategoryPanel,
    required this.onToggleCategoryPanel,
    this.onUndo,
    this.onRedo,
    this.enableSearchAutocomplete = true,
  });

  final FocusNode searchFocusNode;
  final bool inspectorVisible;

  /// 窗口过窄时详情面板自动收起，按钮不可用
  final bool inspectorAvailable;
  final VoidCallback onToggleInspector;
  final VoidCallback onOpenFolder;
  final VoidCallback onRefresh;
  final bool showCategoryPanel;
  final VoidCallback onToggleCategoryPanel;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  /// Whether explicit tag search is enabled for the gallery search field.
  final bool enableSearchAutocomplete;

  @override
  ConsumerState<LocalGalleryToolbar> createState() =>
      _LocalGalleryToolbarState();
}

class _LocalGalleryToolbarState extends ConsumerState<LocalGalleryToolbar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  /// 挂载时的 tip 轮次：首轮固定出使用说明句（FEAT-60）。
  /// 懒初始化而非 initState 赋值——热重载不重跑 initState。
  int? _tipMountEpoch;

  @override
  void initState() {
    super.initState();
    widget.searchFocusNode.onKeyEvent = _handleSearchKeyEvent;
    widget.searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void didUpdateWidget(LocalGalleryToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchFocusNode != widget.searchFocusNode) {
      oldWidget.searchFocusNode.removeListener(_onSearchFocusChanged);
      widget.searchFocusNode.onKeyEvent = _handleSearchKeyEvent;
      widget.searchFocusNode.addListener(_onSearchFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  /// Search with debounce
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(localGalleryNotifierProvider.notifier).setSearchQuery(value);
    });
  }

  KeyEventResult _handleSearchKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        _searchController.text.isEmpty) {
      node.unfocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey != LogicalKeyboardKey.keyA) {
      return KeyEventResult.ignored;
    }
    if (!keyboard.isControlPressed && !keyboard.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localGalleryChromeStateProvider);
    final selectionActive = ref.watch(
      localGallerySelectionNotifierProvider.select((s) => s.isActive),
    );
    final theme = Theme.of(context);

    // 空白处（标题、搜索框右侧留白）都能拖动窗口；按钮与搜索框照常响应。
    return SizedBox(
      height: localGalleryToolbarHeight,
      child: Stack(
        children: [
          if (WindowChromeScope.activeOf(context))
            const Positioned.fill(
              child: WindowDragArea(key: Key('gallery-toolbar-drag')),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: LayoutBuilder(
              builder: (context, constraints) => _buildRow(
                theme,
                state,
                selectionActive,
                compact: constraints.maxWidth < 900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    ThemeData theme,
    LocalGalleryState state,
    bool selectionActive, {
    required bool compact,
  }) {
    final l10n = context.l10n;
    return Row(
      children: [
        Flexible(
          flex: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 200 : 340),
            child: IgnorePointer(child: _buildBreadcrumb(theme, state)),
          ),
        ),
        const SizedBox(width: 16),
        // 搜索框随窗口宽度伸缩，占满标题与工具之间的空间（上限
        // [_searchMaxWidth]）；超出的部分和右侧留缝都是拖动区。
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _searchMaxWidth),
              child: _buildSearchField(theme, state),
            ),
          ),
        ),
        SizedBox(width: compact ? 12 : 24),
        _buildSortButton(theme, state, showLabel: !compact),
        const SizedBox(width: 4),
        _ViewModeSegment(
          value: state.viewMode,
          onChanged: (mode) {
            ref.read(localGalleryNotifierProvider.notifier).setViewMode(mode);
            unawaited(const GalleryViewModeStore().save(mode));
          },
        ),
        if (!compact) ...[
          const SizedBox(width: 4),
          _ThumbnailSizeSlider(value: state.columnWidth),
        ],
        _divider(theme),
        _ToolbarIconButton(
          key: const Key('gallery-toolbar-multiselect'),
          icon: StudioIcons.gallerySelect,
          tooltip: l10n.common_multiSelect,
          shortcutId: ShortcutIds.enterSelectionMode,
          active: selectionActive,
          onPressed: () {
            final notifier = ref.read(
              localGallerySelectionNotifierProvider.notifier,
            );
            selectionActive ? notifier.exit() : notifier.enter();
          },
        ),
        _ToolbarIconButton(
          key: const Key('gallery-toolbar-inspector'),
          icon: StudioIcons.galleryPanelRight,
          tooltip: widget.inspectorVisible
              ? l10n.localGallery_hideInspector
              : l10n.localGallery_showInspector,
          active: widget.inspectorVisible && widget.inspectorAvailable,
          onPressed: widget.inspectorAvailable
              ? widget.onToggleInspector
              : null,
        ),
        _buildMoreMenu(),
      ],
    );
  }

  Widget _divider(ThemeData theme) => Container(
    width: 1,
    height: 20,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: theme.dividerColor,
  );

  /// 当前浏览范围（文件夹路径 / 收藏集 / 收藏 / 全部）+ 结果数
  Widget _buildBreadcrumb(ThemeData theme, LocalGalleryState state) {
    final l10n = context.l10n;
    final colors = theme.colorScheme;
    final segments = _scopeSegments(state);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final count = NumberFormat.decimalPattern(locale).format(state.resultCount);
    final children = <Widget>[];
    for (var i = 0; i < segments.length; i++) {
      final last = i == segments.length - 1;
      if (i > 0) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              StudioIcons.galleryChevronRight,
              size: 14,
              color: colors.onSurfaceVariant,
            ),
          ),
        );
      }
      children.add(
        Flexible(
          flex: last ? 0 : 1,
          child: Text(
            segments[i],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: last
                ? theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
          ),
        ),
      );
    }
    if (!state.isIndexing) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            l10n.localGallery_imageCountLabel(state.resultCount, count),
            key: const Key('gallery-toolbar-count'),
            maxLines: 1,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  List<String> _scopeSegments(LocalGalleryState state) {
    final l10n = context.l10n;
    final criteria = state.filterCriteria;
    if (criteria.showFavoritesOnly) return [l10n.common_favorite];
    final collectionId = criteria.collectionId;
    if (collectionId != null) {
      final collections = ref.watch(collectionNotifierProvider).collections;
      final byId = {for (final c in collections) c.id: c};
      final path = <String>[];
      var current = byId[collectionId];
      var guard = 0;
      while (current != null && guard++ < 32) {
        path.insert(0, current.name);
        current = current.parentId == null ? null : byId[current.parentId];
      }
      if (path.isNotEmpty) return path;
    }
    final categoryId = criteria.categoryId;
    if (categoryId != null) {
      final categories = ref.watch(galleryCategoryNotifierProvider).categories;
      final path = categories.getPath(categoryId);
      if (path.isNotEmpty) return [for (final c in path) c.displayName];
    }
    return [l10n.localGallery_allImages];
  }

  /// 当前搜索范围名称（收藏/收藏集/分类/日期范围），无范围时返回 null
  String? _searchScopeLabel(LocalGalleryState state) {
    final criteria = state.filterCriteria;
    if (criteria.showFavoritesOnly || criteria.categoryId == 'favorites') {
      return context.l10n.common_favorite;
    }
    if (criteria.collectionId != null) {
      final collection = ref
          .read(collectionNotifierProvider)
          .collections
          .where((c) => c.id == criteria.collectionId)
          .firstOrNull;
      if (collection != null) return collection.name;
    }
    if (criteria.categoryId != null) {
      final category = ref
          .read(galleryCategoryNotifierProvider)
          .categories
          .findById(criteria.categoryId!);
      if (category != null) return category.displayName;
    }
    return null;
  }

  Widget _buildSearchField(ThemeData theme, LocalGalleryState state) {
    final colors = theme.colorScheme;
    final scopeLabel = _searchScopeLabel(state);
    final focused = widget.searchFocusNode.hasFocus;
    final hasText = _searchController.text.isNotEmpty;
    final searchField = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 34,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: focused ? colors.primary : Colors.transparent,
          width: 1,
        ),
      ),
      child: Center(
        child: TextField(
          key: const Key('gallery-search-field'),
          controller: _searchController,
          focusNode: widget.searchFocusNode,
          style: theme.textTheme.bodyMedium,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: scopeLabel != null
                ? context.l10n.localGallery_searchInScope(scopeLabel)
                : watchTipHint(
                    ref,
                    context.l10n,
                    TipSurface.gallerySearch,
                    firstEpoch: _tipMountEpoch ??= currentTipEpoch(),
                  ),
            hintMaxLines: 1,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            prefixIcon: Icon(
              StudioIcons.gallerySearch,
              size: 17,
              color: colors.onSurfaceVariant,
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            suffixIcon: hasText
                ? IconButton(
                    icon: Icon(
                      StudioIcons.galleryClose,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    tooltip: context.l10n.common_clear,
                    onPressed: () {
                      _searchController.clear();
                      ref
                          .read(localGalleryNotifierProvider.notifier)
                          .setSearchQuery('');
                      setState(() {});
                    },
                  )
                : focused
                ? null
                : const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: _KeyHint(label: 'Ctrl F'),
                  ),
            suffixIconConstraints: const BoxConstraints(minWidth: 30),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          onChanged: (value) {
            setState(() {}); // 更新清除按钮可见性
            _onSearchChanged(value);
          },
          onSubmitted: (value) {
            _debounceTimer?.cancel();
            ref
                .read(localGalleryNotifierProvider.notifier)
                .setSearchQuery(value);
          },
        ),
      ),
    );

    if (!widget.enableSearchAutocomplete) return searchField;

    return TagExpansionWrapper(
      controller: _searchController,
      focusNode: widget.searchFocusNode,
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

  /// 排序：字段与方向在同一菜单里（当前项打勾）
  Widget _buildSortButton(
    ThemeData theme,
    LocalGalleryState state, {
    required bool showLabel,
  }) {
    final l10n = context.l10n;
    final colors = theme.colorScheme;
    final fields = <(GallerySortField, String)>[
      (GallerySortField.modifiedAt, l10n.localGallery_sortFieldModified),
      (GallerySortField.createdAt, l10n.localGallery_sortFieldCreated),
      (GallerySortField.fileName, l10n.localGallery_sortFieldName),
      (GallerySortField.fileSize, l10n.localGallery_sortFieldSize),
      (GallerySortField.imageDimensions, l10n.localGallery_sortFieldDimensions),
    ];
    final current = fields.firstWhere((f) => f.$1 == state.sortField).$2;
    final descending = state.sortDirection == GallerySortDirection.descending;

    void apply(GallerySortField field, GallerySortDirection direction) {
      ref.read(localGalleryNotifierProvider.notifier).setSort(field, direction);
      unawaited(
        const GallerySortStore().save(
          GallerySort(field: field, direction: direction),
        ),
      );
    }

    return PopupMenuButton<Object>(
      key: const Key('gallery-toolbar-sort'),
      tooltip: l10n.localGallery_sortButton,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      onSelected: (value) {
        if (value is GallerySortField) {
          apply(value, GallerySort.defaultDirectionFor(value));
        } else if (value is GallerySortDirection) {
          apply(state.sortField, value);
        }
      },
      itemBuilder: (context) => [
        for (final (field, label) in fields)
          CheckedPopupMenuItem<Object>(
            value: field,
            checked: field == state.sortField,
            child: Text(label),
          ),
        const PopupMenuDivider(),
        CheckedPopupMenuItem<Object>(
          value: GallerySortDirection.descending,
          checked: descending,
          child: Text(l10n.localGallery_sortDescending),
        ),
        CheckedPopupMenuItem<Object>(
          value: GallerySortDirection.ascending,
          checked: !descending,
          child: Text(l10n.localGallery_sortAscending),
        ),
      ],
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              descending
                  ? StudioIcons.gallerySortDesc
                  : StudioIcons.gallerySortAsc,
              size: 15,
              color: colors.onSurfaceVariant,
            ),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(current, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoreMenu() {
    return PopupMenuButton<_MoreAction>(
      key: const Key('gallery-toolbar-more'),
      tooltip: context.l10n.localGallery_moreActions,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      icon: const Icon(StudioIcons.galleryMore, size: 20),
      onSelected: (action) {
        switch (action) {
          case _MoreAction.openFolder:
            widget.onOpenFolder();
          case _MoreAction.refresh:
            widget.onRefresh();
          case _MoreAction.undo:
            widget.onUndo?.call();
          case _MoreAction.redo:
            widget.onRedo?.call();
          case _MoreAction.toggleSidebar:
            widget.onToggleCategoryPanel();
        }
      },
      itemBuilder: (context) {
        final l10n = context.l10n;
        PopupMenuItem<_MoreAction> item(
          _MoreAction value,
          IconData icon,
          String label, {
          bool enabled = true,
          String? shortcut,
        }) => PopupMenuItem(
          value: value,
          enabled: enabled,
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(label)),
              if (shortcut != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    shortcut,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        );
        return [
          item(
            _MoreAction.openFolder,
            StudioIcons.galleryFolder,
            l10n.shortcut_action_open_folder,
          ),
          item(
            _MoreAction.refresh,
            StudioIcons.galleryRefresh,
            l10n.common_refresh,
          ),
          const PopupMenuDivider(),
          item(
            _MoreAction.undo,
            StudioIcons.galleryUndo,
            l10n.common_undo,
            enabled: widget.onUndo != null,
            shortcut: 'Ctrl+Z',
          ),
          item(
            _MoreAction.redo,
            StudioIcons.galleryRedo,
            l10n.common_redo,
            enabled: widget.onRedo != null,
            shortcut: 'Ctrl+Y',
          ),
          const PopupMenuDivider(),
          item(
            _MoreAction.toggleSidebar,
            StudioIcons.galleryPanelLeft,
            widget.showCategoryPanel
                ? l10n.localGallery_hideCategoryPanel
                : l10n.localGallery_showCategoryPanel,
          ),
        ];
      },
    );
  }
}

/// 视图切换（网格 / 瀑布流 / 火车流）分段控件
class _ViewModeSegment extends StatelessWidget {
  const _ViewModeSegment({required this.value, required this.onChanged});

  final GalleryViewMode value;
  final ValueChanged<GalleryViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final dark = theme.brightness == Brightness.dark;
    final items = <(GalleryViewMode, IconData, String)>[
      (GalleryViewMode.grid, StudioIcons.galleryViewGrid, l10n.common_grid),
      (
        GalleryViewMode.masonry,
        StudioIcons.galleryViewMasonry,
        l10n.localGallery_masonryViewLabel,
      ),
      // 火车流按用户选择保留原来的 Material 图标（更能看出是一行行排的）
      (
        GalleryViewMode.justified,
        Icons.view_day_outlined,
        l10n.localGallery_justifiedViewLabel,
      ),
    ];
    return Container(
      key: const Key('gallery-toolbar-view-mode'),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (mode, icon, label) in items)
            Tooltip(
              message: label,
              waitDuration: const Duration(milliseconds: 400),
              child: Semantics(
                button: true,
                selected: mode == value,
                label: label,
                child: InkWell(
                  key: ValueKey('gallery-view-${mode.name}'),
                  onTap: () => onChanged(mode),
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: mode == value
                        ? BoxDecoration(
                            color: dark
                                ? colors.surfaceContainerHigh
                                : colors.surface,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: dark
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                          )
                        : null,
                    child: Icon(
                      icon,
                      size: 16,
                      color: mode == value
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 缩略图大小滑块（改变排版目标边长，松手后持久化）
class _ThumbnailSizeSlider extends ConsumerWidget {
  const _ThumbnailSizeSlider({required this.value});

  final double value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Tooltip(
      message: context.l10n.localGallery_thumbnailSize,
      waitDuration: const Duration(milliseconds: 600),
      child: Row(
        key: const Key('gallery-toolbar-size'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            StudioIcons.gallerySizeSmall,
            size: 14,
            color: colors.onSurfaceVariant,
          ),
          SizedBox(
            width: 84,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                inactiveTrackColor: colors.surfaceContainerHigh,
              ),
              child: Slider(
                value: value.clamp(
                  GalleryColumnWidthStore.minColumnWidth,
                  GalleryColumnWidthStore.maxColumnWidth,
                ),
                min: GalleryColumnWidthStore.minColumnWidth,
                max: GalleryColumnWidthStore.maxColumnWidth,
                divisions:
                    ((GalleryColumnWidthStore.maxColumnWidth -
                                GalleryColumnWidthStore.minColumnWidth) /
                            GalleryColumnWidthStore.columnWidthStep)
                        .round(),
                onChanged: (next) => ref
                    .read(localGalleryNotifierProvider.notifier)
                    .setColumnWidth(next),
                onChangeEnd: (next) =>
                    unawaited(const GalleryColumnWidthStore().save(next)),
              ),
            ),
          ),
          Icon(
            StudioIcons.gallerySizeLarge,
            size: 16,
            color: colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
    this.shortcutId,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;
  final String? shortcutId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final button = IconButton(
      onPressed: onPressed,
      isSelected: active,
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
        fixedSize: const Size(32, 32),
        minimumSize: const Size(32, 32),
        backgroundColor: active ? colors.surfaceContainerHighest : null,
        foregroundColor: active ? colors.onSurface : colors.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
    if (shortcutId == null) return Tooltip(message: tooltip, child: button);
    return ShortcutTooltip(
      message: tooltip,
      shortcutId: shortcutId!,
      child: button,
    );
  }
}

/// 搜索框右侧的快捷键提示
class _KeyHint extends StatelessWidget {
  const _KeyHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
