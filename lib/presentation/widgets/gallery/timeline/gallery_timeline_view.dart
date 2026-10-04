import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/cache/thumbnail_cache_service.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/gallery/local_image_record.dart';
import '../../../../data/services/gallery/gallery_group_mode.dart';
import '../../../../data/services/gallery/gallery_sort.dart';
import '../../../../data/services/gallery/gallery_view_mode.dart';
import '../../../../data/services/gallery/unified_gallery_service.dart'
    show GalleryTimelineEntry;
import '../../../../data/services/thumbnail_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/canvas_settings_provider.dart';
import '../../../providers/krita/krita_bridge_notifier.dart';
import '../../../providers/local_gallery_focus_provider.dart';
import '../../../providers/local_gallery_provider.dart';
import '../../../providers/selection_mode_provider.dart';
import '../draggable_image_card.dart';
import '../gallery_state_views.dart';
import '../local_image_card.dart';
import '../local_image_context_menu.dart';
import 'gallery_timeline_layout.dart';
import 'gallery_timeline_scrubber.dart';
import '../../common/studio_icons.dart';

/// 卡片间距与内容边距（右侧留出时间轴宽度）
const double galleryTimelineGap = 4;
const double galleryTimelineLeftPadding = 16;
const double galleryTimelineRightPadding = 48;
const double galleryTimelineHeaderHeight = 44;

/// 外部（快捷键、日期跳转）控制时间线滚动。
class GalleryTimelineController {
  _GalleryTimelineViewState? _state;

  bool get isAttached => _state != null;

  /// 按视口高度翻页（正数向下）
  void scrollByViewport(double factor) => _state?._scrollByViewport(factor);

  /// 跳到不晚于 [date] 的第一组（时间排序下）
  void jumpToDate(DateTime date) => _state?._jumpToDate(date);

  /// 让指定条目完整可见
  void reveal(int index) => _state?._reveal(index);
}

/// 连续画廊：整库一次排版、只构建可见附近的卡片，按天/月分组，
/// 右侧时间轴快速定位。
class GalleryTimelineView extends ConsumerStatefulWidget {
  const GalleryTimelineView({
    super.key,
    this.controller,
    required this.onOpenViewer,
    required this.onContextMenu,
    required this.onSendAction,
    required this.onFavoriteMenu,
    required this.onClearFilters,
    this.onDeleteRequested,
  });

  final GalleryTimelineController? controller;

  /// 打开大图（双击、空格、回车）
  final void Function(int index) onOpenViewer;
  final void Function(LocalImageRecord record, Offset position) onContextMenu;
  final Future<void> Function(
    LocalImageRecord record,
    LocalImageContextAction action,
  )
  onSendAction;
  final void Function(LocalImageRecord record, Offset anchor) onFavoriteMenu;
  final VoidCallback onClearFilters;

  /// Delete 键：删除多选内容或当前查看的图片（由宿主确认）
  final VoidCallback? onDeleteRequested;

  @override
  ConsumerState<GalleryTimelineView> createState() =>
      _GalleryTimelineViewState();
}

class _GalleryTimelineViewState extends ConsumerState<GalleryTimelineView> {
  final ScrollController _scroll = ScrollController();
  final FocusNode _focusNode = FocusNode(debugLabel: 'gallery-timeline');

  GalleryTimelineLayout _layout = GalleryTimelineLayout.empty;
  _LayoutKey? _layoutKey;
  int? _datasetId;
  double _viewportHeight = 0;

  /// 已构建区域（内容坐标），滚动离开时才重建可见卡片
  double _builtTop = 0;
  double _builtBottom = 0;
  String? _lastPreloadKey;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _scroll.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(GalleryTimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<GalleryTimelineEntry> get _entries =>
      ref.read(localGalleryNotifierProvider).timeline.entries;

  // ============================================================
  // 滚动与可见窗口
  // ============================================================

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final offset = _scroll.offset;
    final viewport = _viewportHeight;
    final needTop = offset - viewport * 0.5;
    final needBottom = offset + viewport * 1.5;
    if (needTop < _builtTop || needBottom > _builtBottom) {
      setState(() => _resetWindow(offset));
    }
  }

  void _resetWindow(double offset) {
    final viewport = math.max(_viewportHeight, 400.0);
    _builtTop = offset - viewport * 1.25;
    _builtBottom = offset + viewport * 2.25;
  }

  void _scrollByViewport(double factor) {
    if (!_scroll.hasClients) return;
    final target = (_scroll.offset + _viewportHeight * 0.9 * factor).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.jumpTo(target);
  }

  void _jumpToDate(DateTime date) {
    if (!_scroll.hasClients) return;
    final state = ref.read(localGalleryNotifierProvider);
    final target = DateTime(date.year, date.month, date.day);
    final descending = state.sortDirection == GallerySortDirection.descending;
    for (final section in _layout.sections) {
      final entry = _entries[section.start].modifiedAt;
      final day = DateTime(entry.year, entry.month, entry.day);
      final reached = descending ? !day.isAfter(target) : !day.isBefore(target);
      if (reached) {
        final top = section.hasHeader
            ? section.headerTop
            : _layout.tiles[section.start].top;
        _scroll.jumpTo(top.clamp(0.0, _scroll.position.maxScrollExtent));
        return;
      }
    }
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  void _reveal(int index) {
    if (!_scroll.hasClients || index < 0 || index >= _layout.tiles.length) {
      return;
    }
    final rect = _layout.tiles[index];
    final offset = _scroll.offset;
    final top = rect.top - _layout.headerHeight - 8;
    final bottom = rect.bottom + 8;
    double? target;
    if (top < offset) {
      target = top;
    } else if (bottom > offset + _viewportHeight) {
      target = bottom - _viewportHeight;
    }
    if (target != null) {
      _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
    }
  }

  // ============================================================
  // 选择与查看
  // ============================================================

  void _handleTap(int index) {
    final entries = _entries;
    if (index < 0 || index >= entries.length) return;
    final path = entries[index].path;
    final selection = ref.read(localGallerySelectionNotifierProvider);
    final selectionNotifier = ref.read(
      localGallerySelectionNotifierProvider.notifier,
    );
    final focusNotifier = ref.read(localGalleryFocusNotifierProvider.notifier);
    final keyboard = HardwareKeyboard.instance;
    final isCtrl = keyboard.isControlPressed || keyboard.isMetaPressed;
    final isShift = keyboard.isShiftPressed;
    _focusNode.requestFocus();

    if (isShift) {
      final anchorPath =
          selection.lastSelectedId ??
          ref.read(localGalleryFocusNotifierProvider);
      final timeline = ref.read(localGalleryNotifierProvider).timeline;
      final anchor = anchorPath == null ? -1 : timeline.indexOfPath(anchorPath);
      if (anchor >= 0) {
        final from = math.min(anchor, index);
        final to = math.max(anchor, index);
        selectionNotifier.enter();
        selectionNotifier.selectAll([
          for (var i = from; i <= to; i++) entries[i].path,
        ]);
      } else {
        selectionNotifier.enterAndSelect(path);
      }
      focusNotifier.focus(path);
      return;
    }

    if (selection.isActive || isCtrl) {
      if (!selection.isActive) {
        final focused = ref.read(localGalleryFocusNotifierProvider);
        selectionNotifier.enter();
        if (focused != null && focused != path) {
          selectionNotifier.select(focused);
        }
      }
      selectionNotifier.toggle(path);
      focusNotifier.focus(path);
      return;
    }

    focusNotifier.focus(path);
  }

  void _toggleSelection(int index) {
    final path = _entries[index].path;
    final notifier = ref.read(localGallerySelectionNotifierProvider.notifier);
    if (ref.read(localGallerySelectionNotifierProvider).isActive) {
      notifier.toggle(path);
    } else {
      notifier.enterAndSelect(path);
    }
    ref.read(localGalleryFocusNotifierProvider.notifier).focus(path);
  }

  void _toggleSection(GalleryTimelineSection section) {
    final entries = _entries;
    final paths = [
      for (var i = section.start; i < section.end; i++) entries[i].path,
    ];
    final selection = ref.read(localGallerySelectionNotifierProvider);
    final notifier = ref.read(localGallerySelectionNotifierProvider.notifier);
    final allSelected = paths.every(selection.selectedIds.contains);
    if (allSelected) {
      notifier.deselectAll(paths);
      if (ref.read(localGallerySelectionNotifierProvider).selectedIds.isEmpty) {
        notifier.exit();
      }
    } else {
      notifier.enter();
      notifier.selectAll(paths);
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final entries = _entries;
    final focused = ref.read(localGalleryFocusNotifierProvider);
    final timeline = ref.read(localGalleryNotifierProvider).timeline;
    final current = focused == null ? -1 : timeline.indexOfPath(focused);

    if (key == LogicalKeyboardKey.escape) {
      final selection = ref.read(localGallerySelectionNotifierProvider);
      if (selection.isActive) {
        ref.read(localGallerySelectionNotifierProvider.notifier).exit();
        return KeyEventResult.handled;
      }
      if (focused != null) {
        ref.read(localGalleryFocusNotifierProvider.notifier).clear();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (current < 0) return KeyEventResult.ignored;
      widget.onOpenViewer(current);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      if (widget.onDeleteRequested == null) return KeyEventResult.ignored;
      widget.onDeleteRequested!();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      return KeyEventResult.handled;
    }

    int? next;
    if (key == LogicalKeyboardKey.arrowRight) {
      next = current < 0 ? 0 : current + 1;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      next = current < 0 ? 0 : current - 1;
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      next = current < 0
          ? 0
          : _verticalNeighbor(
              current,
              down: key == LogicalKeyboardKey.arrowDown,
            );
    }
    if (next == null) return KeyEventResult.ignored;
    if (entries.isEmpty) return KeyEventResult.handled;
    next = next.clamp(0, entries.length - 1);
    ref
        .read(localGalleryFocusNotifierProvider.notifier)
        .focus(entries[next].path);
    _reveal(next);
    return KeyEventResult.handled;
  }

  /// 上下方向键：在上一行/下一行找水平中心最近的条目
  int _verticalNeighbor(int index, {required bool down}) {
    final rect = _layout.tiles[index];
    final probeX = rect.center.dx;
    var probeY = down ? rect.bottom + galleryTimelineGap + 1 : rect.top - 2;
    for (var attempt = 0; attempt < 6; attempt++) {
      final candidates = _layout.indicesIn(probeY - 1, probeY + 1);
      if (candidates.isNotEmpty) {
        var best = candidates.first;
        var bestDistance = double.infinity;
        for (final candidate in candidates) {
          if (candidate == index) continue;
          final distance = (_layout.tiles[candidate].center.dx - probeX).abs();
          if (distance < bestDistance) {
            best = candidate;
            bestDistance = distance;
          }
        }
        if (bestDistance.isFinite) return best;
      }
      probeY += down ? 24 : -24;
    }
    return index;
  }

  // ============================================================
  // 构建
  // ============================================================

  GalleryTimelineLayout _layoutFor(LocalGalleryState state, double width) {
    final key = _LayoutKey(
      timeline: state.timeline,
      width: width,
      viewMode: state.viewMode,
      groupMode: state.effectiveGroupMode,
      tileSize: state.columnWidth,
    );
    if (key != _layoutKey) {
      _layoutKey = key;
      _layout = computeGalleryTimelineLayout(
        entries: state.timeline.entries,
        viewMode: state.viewMode,
        groupMode: state.effectiveGroupMode,
        width: width,
        tileSize: state.columnWidth,
        gap: galleryTimelineGap,
        leftPadding: galleryTimelineLeftPadding,
        rightPadding: galleryTimelineRightPadding,
        headerHeight: galleryTimelineHeaderHeight,
      );
    }
    return _layout;
  }

  void _syncDataset(GalleryTimeline timeline) {
    if (_datasetId == timeline.datasetId) return;
    final isFirst = _datasetId == null;
    _datasetId = timeline.datasetId;
    if (isFirst) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (_scroll.offset != 0) _scroll.jumpTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      localGalleryNotifierProvider.select(
        (s) => (
          timeline: s.timeline,
          viewMode: s.viewMode,
          groupMode: s.effectiveGroupMode,
          tileSize: s.columnWidth,
          isInitialized: s.isInitialized,
          isLoading: s.isLoading,
          hasFilters: s.hasFilters,
        ),
      ),
    );
    final galleryState = ref.read(localGalleryNotifierProvider);
    _syncDataset(state.timeline);

    if (!state.isInitialized || (state.isLoading && state.timeline.isEmpty)) {
      return const GalleryLoadingView();
    }
    if (state.timeline.isEmpty) {
      return state.hasFilters
          ? GalleryNoResultsView(onClearFilters: widget.onClearFilters)
          : const GalleryEmptyView();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _layoutFor(galleryState, constraints.maxWidth);
        if (_viewportHeight != constraints.maxHeight) {
          _viewportHeight = constraints.maxHeight;
          _resetWindow(_scroll.hasClients ? _scroll.offset : 0);
        }
        final extent = math.max(layout.extent, constraints.maxHeight);
        return Focus(
          focusNode: _focusNode,
          onKeyEvent: _handleKey,
          child: Stack(
            children: [
              Positioned.fill(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    key: const Key('gallery-timeline-scroll'),
                    controller: _scroll,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        _focusNode.requestFocus();
                        ref
                            .read(localGalleryFocusNotifierProvider.notifier)
                            .clear();
                      },
                      child: SizedBox(
                        height: extent,
                        width: constraints.maxWidth,
                        child: _TimelineTiles(
                          layout: layout,
                          builtTop: _builtTop,
                          builtBottom: _builtBottom,
                          scrollController: _scroll,
                          viewportHeight: _viewportHeight,
                          onTap: _handleTap,
                          onDoubleTap: widget.onOpenViewer,
                          onToggleSelection: _toggleSelection,
                          onToggleSection: _toggleSection,
                          onContextMenu: widget.onContextMenu,
                          onSendAction: widget.onSendAction,
                          onFavoriteMenu: widget.onFavoriteMenu,
                          onWindowBuilt: _afterWindowBuilt,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (layout.headerHeight > 0)
                Positioned(
                  left: 0,
                  right: galleryTimelineRightPadding,
                  top: 0,
                  height: layout.headerHeight,
                  child: _StickyHeader(
                    layout: layout,
                    scrollController: _scroll,
                    onToggleSection: _toggleSection,
                  ),
                ),
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: galleryTimelineRightPadding,
                child: GalleryTimelineScrubber(
                  layout: layout,
                  entries: state.timeline.entries,
                  groupMode: state.groupMode,
                  scrollController: _scroll,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 可见窗口重建后：请求可见记录、预取下一屏缩略图。
  void _afterWindowBuilt(List<int> visibleIndices) {
    final entries = _entries;
    if (entries.isEmpty) return;
    ref.read(localGalleryNotifierProvider.notifier).ensureRecords([
      for (final index in visibleIndices)
        if (index < entries.length) entries[index].path,
    ]);

    final quality = ref.read(localGalleryNotifierProvider).thumbnailQuality;
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final ahead = _layout.indicesIn(
      _builtBottom,
      _builtBottom + _viewportHeight,
    );
    if (ahead.isEmpty) return;
    final preloadKey = '${ahead.first}-${ahead.last}-$quality';
    if (preloadKey == _lastPreloadKey) return;
    _lastPreloadKey = preloadKey;
    unawaited(
      () async {
        final service = ThumbnailService.instance;
        await service.initialize();
        for (final index in ahead) {
          if (index >= entries.length) continue;
          unawaited(
            service.preloadThumbnail(
              entries[index].path,
              size: resolveThumbnailTier(
                _layout.tiles[index].width,
                dpr,
                quality,
              ),
              priority: ThumbnailPriority.low,
            ),
          );
        }
      }().catchError((Object _) {}),
    );
  }
}

class _LayoutKey {
  const _LayoutKey({
    required this.timeline,
    required this.width,
    required this.viewMode,
    required this.groupMode,
    required this.tileSize,
  });

  final GalleryTimeline timeline;
  final double width;
  final GalleryViewMode viewMode;
  final GalleryGroupMode groupMode;
  final double tileSize;

  @override
  bool operator ==(Object other) =>
      other is _LayoutKey &&
      identical(other.timeline, timeline) &&
      other.width == width &&
      other.viewMode == viewMode &&
      other.groupMode == groupMode &&
      other.tileSize == tileSize;

  @override
  int get hashCode => Object.hash(
    identityHashCode(timeline),
    width,
    viewMode,
    groupMode,
    tileSize,
  );
}

/// 已构建窗口内的卡片与分组标题。
class _TimelineTiles extends ConsumerStatefulWidget {
  const _TimelineTiles({
    required this.layout,
    required this.builtTop,
    required this.builtBottom,
    required this.scrollController,
    required this.viewportHeight,
    required this.onTap,
    required this.onDoubleTap,
    required this.onToggleSelection,
    required this.onToggleSection,
    required this.onContextMenu,
    required this.onSendAction,
    required this.onFavoriteMenu,
    required this.onWindowBuilt,
  });

  final GalleryTimelineLayout layout;
  final double builtTop;
  final double builtBottom;
  final ScrollController scrollController;
  final double viewportHeight;
  final void Function(int index) onTap;
  final void Function(int index) onDoubleTap;
  final void Function(int index) onToggleSelection;
  final void Function(GalleryTimelineSection section) onToggleSection;
  final void Function(LocalImageRecord record, Offset position) onContextMenu;
  final Future<void> Function(
    LocalImageRecord record,
    LocalImageContextAction action,
  )
  onSendAction;
  final void Function(LocalImageRecord record, Offset anchor) onFavoriteMenu;
  final void Function(List<int> visibleIndices) onWindowBuilt;

  @override
  ConsumerState<_TimelineTiles> createState() => _TimelineTilesState();
}

class _TimelineTilesState extends ConsumerState<_TimelineTiles> {
  Object? _notifiedWindow;

  void _notifyWindow(List<int> indices) {
    final window = (widget.layout, widget.builtTop, widget.builtBottom);
    if (window == _notifiedWindow) return;
    _notifiedWindow = window;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onWindowBuilt(indices);
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeline = ref.watch(
      localGalleryNotifierProvider.select((s) => s.timeline),
    );
    ref.watch(localGalleryNotifierProvider.select((s) => s.recordsRevision));
    final notifier = ref.read(localGalleryNotifierProvider.notifier);
    final selection = ref.watch(localGallerySelectionNotifierProvider);
    final focused = ref.watch(localGalleryFocusNotifierProvider);
    final isKritaConnected = ref.watch(
      kritaBridgeNotifierProvider.select(
        (state) => state.status == KritaBridgeStatus.connected,
      ),
    );
    final entries = timeline.entries;
    final layout = widget.layout;
    final offset = widget.scrollController.hasClients
        ? widget.scrollController.offset
        : 0.0;
    final visibleTop = offset - widget.viewportHeight * 0.25;
    final visibleBottom = offset + widget.viewportHeight * 1.25;
    final indices = layout.indicesIn(widget.builtTop, widget.builtBottom);
    _notifyWindow(indices);

    final children = <Widget>[];
    for (final section in layout.sections) {
      if (!section.hasHeader) continue;
      if (section.headerTop + layout.headerHeight < widget.builtTop) continue;
      if (section.headerTop > widget.builtBottom) break;
      children.add(
        Positioned(
          key: ValueKey('header-${section.start}'),
          left: 0,
          right: galleryTimelineRightPadding,
          top: section.headerTop,
          height: layout.headerHeight,
          child: GalleryTimelineSectionHeader(
            section: section,
            onToggle: () => widget.onToggleSection(section),
          ),
        ),
      );
    }

    for (final index in indices) {
      if (index >= entries.length) continue;
      final entry = entries[index];
      final rect = layout.tiles[index];
      final record = notifier.recordFor(entry);
      final isSelected = selection.selectedIds.contains(entry.path);
      final isVisible = rect.bottom > visibleTop && rect.top < visibleBottom;
      children.add(
        Positioned(
          key: ValueKey(entry.path),
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: RepaintBoundary(
            child: LocalImageCard(
              record: record,
              width: rect.width,
              height: rect.height,
              imageWidth: entry.width,
              imageHeight: entry.height,
              isSelected: isSelected,
              isFocused: focused == entry.path,
              selectionMode: selection.isActive,
              isVisible: isVisible,
              priority: isVisible
                  ? ThumbnailPriority.highest
                  : ThumbnailPriority.normal,
              onTap: () => widget.onTap(index),
              onDoubleTap: () => widget.onDoubleTap(index),
              onLongPress: () => widget.onToggleSelection(index),
              onSelectionToggle: () => widget.onToggleSelection(index),
              onSecondaryTapDown: (details) =>
                  widget.onContextMenu(record, details.globalPosition),
              onFavoriteToggle: (anchor) =>
                  widget.onFavoriteMenu(record, anchor),
              onSendAction: (action) => widget.onSendAction(record, action),
              isKritaConnected: isKritaConnected,
              dragWrapper: DraggableImageCard.createDragWrapper(
                record: record,
                selectedPaths: selection.isActive && isSelected
                    ? selection.selectedIds.toList()
                    : null,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(clipBehavior: Clip.none, children: children);
  }
}

/// 分组标题：日期 + 数量，悬停或有选中时出现整组选择圈。
class GalleryTimelineSectionHeader extends ConsumerStatefulWidget {
  const GalleryTimelineSectionHeader({
    super.key,
    required this.section,
    required this.onToggle,
    this.opaque = false,
  });

  final GalleryTimelineSection section;
  final VoidCallback onToggle;

  /// 吸顶标题需要实心底遮住下方内容
  final bool opaque;

  @override
  ConsumerState<GalleryTimelineSectionHeader> createState() =>
      _GalleryTimelineSectionHeaderState();
}

class _GalleryTimelineSectionHeaderState
    extends ConsumerState<GalleryTimelineSectionHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final section = widget.section;
    final date = section.date!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final groupMode = ref.watch(
      localGalleryNotifierProvider.select((s) => s.effectiveGroupMode),
    );
    final selection = ref.watch(localGallerySelectionNotifierProvider);
    final entries = ref.watch(
      localGalleryNotifierProvider.select((s) => s.timeline.entries),
    );
    var selectedCount = 0;
    if (selection.selectedIds.isNotEmpty) {
      for (var i = section.start; i < section.end && i < entries.length; i++) {
        if (selection.selectedIds.contains(entries[i].path)) selectedCount++;
      }
    }
    final allSelected = selectedCount > 0 && selectedCount == section.count;
    final showCheck = _hovered || selectedCount > 0;
    final reducedMotion =
        ref.watch(canvasReducedMotionNotifierProvider) ||
        MediaQuery.disableAnimationsOf(context);

    final count = NumberFormat.decimalPattern(locale).format(section.count);
    final countText = l10n.localGallery_groupImageCount(section.count, count);
    final (title, detail) = _labels(date, groupMode, locale, l10n);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        color: widget.opaque ? colors.surface : null,
        padding: const EdgeInsets.only(left: galleryTimelineLeftPadding),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            AnimatedContainer(
              duration: reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              width: showCheck ? 26 : 0,
              child: showCheck
                  ? Semantics(
                      button: true,
                      selected: allSelected,
                      label: l10n.localGallery_selectGroup,
                      child: GestureDetector(
                        key: const Key('gallery-group-select'),
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onToggle,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: allSelected ? colors.primary : null,
                              border: Border.all(
                                color: allSelected
                                    ? colors.primary
                                    : colors.outline,
                                width: 1.5,
                              ),
                            ),
                            child: allSelected
                                ? Icon(
                                    StudioIcons.galleryCheckBold,
                                    size: 13,
                                    color: colors.onPrimary,
                                  )
                                : selectedCount > 0
                                ? Center(
                                    child: Container(
                                      width: 8,
                                      height: 2,
                                      color: colors.primary,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                detail == null ? countText : '$detail · $countText',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, String?) _labels(
    DateTime date,
    GalleryGroupMode mode,
    String locale,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    if (mode == GalleryGroupMode.month) {
      return (
        date.year == now.year
            ? DateFormat.MMMM(locale).format(date)
            : DateFormat.yMMMM(locale).format(date),
        null,
      );
    }
    final today = DateTime(now.year, now.month, now.day);
    final weekday = DateFormat.E(locale).format(date);
    final dayText = date.year == now.year
        ? DateFormat.MMMd(locale).format(date)
        : DateFormat.yMMMd(locale).format(date);
    if (date == today) {
      return (l10n.localGallery_group_today, '$dayText $weekday');
    }
    if (date == today.subtract(const Duration(days: 1))) {
      return (l10n.localGallery_group_yesterday, '$dayText $weekday');
    }
    return (dayText, weekday);
  }
}

/// 吸顶分组标题：当前分组固定在顶部，下一组标题接近时被推上去。
class _StickyHeader extends StatelessWidget {
  const _StickyHeader({
    required this.layout,
    required this.scrollController,
    required this.onToggleSection,
  });

  final GalleryTimelineLayout layout;
  final ScrollController scrollController;
  final void Function(GalleryTimelineSection section) onToggleSection;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: scrollController,
        builder: (context, _) {
          final offset = scrollController.hasClients
              ? scrollController.offset
              : 0.0;
          if (offset <= 0) return const SizedBox.shrink();
          final index = layout.sectionIndexAt(offset);
          if (index < 0) return const SizedBox.shrink();
          final section = layout.sections[index];
          if (!section.hasHeader || section.headerTop >= offset) {
            return const SizedBox.shrink();
          }
          var shift = 0.0;
          if (index + 1 < layout.sections.length) {
            final nextTop = layout.sections[index + 1].headerTop - offset;
            if (nextTop < layout.headerHeight) {
              shift = nextTop - layout.headerHeight;
            }
          }
          return Transform.translate(
            offset: Offset(0, shift),
            child: GalleryTimelineSectionHeader(
              key: ValueKey('sticky-${section.start}'),
              section: section,
              opaque: true,
              onToggle: () => onToggleSection(section),
            ),
          );
        },
      ),
    );
  }
}
