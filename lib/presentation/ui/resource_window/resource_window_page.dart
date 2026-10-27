import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/utils/justified_layout.dart';
import '../../../core/utils/localization_extension.dart';
import '../kit/ui_block_pill.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_inputs.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_resource_kind.dart';
import '../kit/ui_slider.dart';
import '../kit/ui_text.dart';
import 'resource_window_cards.dart';
import 'resource_window_contract.dart';
import 'resource_window_side.dart';

/// E05 独立资源窗口整页。
///
/// 无系统标题栏：最上面一条是一体顶栏（四类资源标签页 · 置顶 / 新开窗口 · 关闭），空白处
/// 拖动窗口、双击最大化（顶栏布局后经 [ResourceWindowActions.onDragRegion] 上报原生命中区）。
/// 其下：工具条（搜索 · 筛选片 · 排序字段 + 方向 · 大小 · 排布）· 主体（左侧分组树 ·
/// 卡片墙）· 详情条 · 状态行。卡片、侧栏外观照各主页面。
class ResourceWindowPage extends StatefulWidget {
  const ResourceWindowPage({
    super.key,
    required this.data,
    required this.actions,
    this.viewer,
  });

  final ResourceWindowViewData data;
  final ResourceWindowActions actions;
  final Widget? viewer;

  static const narrow = 780.0;
  static const tight = 620.0;
  static const topBarHeight = 40.0;

  @override
  State<ResourceWindowPage> createState() => _ResourceWindowPageState();
}

class _ResourceWindowPageState extends State<ResourceWindowPage> {
  final _search = FocusNode();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  /// 大小滑杆拖动中的预览值；松手才回调持久化。
  double? _cell;

  /// 正在显示的提示（几秒后收起）。
  ResourceNotice? _notice;
  Timer? _noticeTimer;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    _showNotice(widget.data.notice);
  }

  @override
  void didUpdateWidget(covariant ResourceWindowPage old) {
    super.didUpdateWidget(old);
    if (old.viewer != null && widget.viewer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
    if (old.data.kind != widget.data.kind ||
        old.data.groupId != widget.data.groupId) {
      _cell = null;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
    if (widget.data.notice?.id != old.data.notice?.id) {
      _showNotice(widget.data.notice);
    }
    // 新一页到了但还没填满视口 / 仍靠近底部：继续要（不依赖用户再滚一下）。
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
  }

  void _showNotice(ResourceNotice? n) {
    if (n == null) return;
    _noticeTimer?.cancel();
    setState(() => _notice = n);
    _noticeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _search.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    final d = widget.data;
    if (!mounted ||
        widget.viewer != null ||
        !d.hasMore ||
        d.loading ||
        !_scroll.hasClients) {
      return;
    }
    final p = _scroll.position;
    if (p.pixels > p.maxScrollExtent - 600) widget.actions.onLoadMore();
  }

  void _move(int delta) {
    final items = widget.data.items;
    if (items.isEmpty) return;
    final i = items.indexWhere((it) => it.id == widget.data.selectedId);
    final next = (i < 0 ? 0 : i + delta).clamp(0, items.length - 1);
    widget.actions.onSelect(items[next].id);
  }

  void _primary() {
    final d = widget.data.detail;
    if (d == null) return;
    for (final a in d.actions) {
      if (a.primary) return widget.actions.onAction(d.itemId, a.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return CallbackShortcuts(
      bindings: widget.viewer == null
          ? {
              const SingleActivator(
                LogicalKeyboardKey.keyF,
                control: true,
              ): () =>
                  _search.requestFocus(),
              const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                  _move(1),
              const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                  _move(-1),
              const SingleActivator(LogicalKeyboardKey.enter): _primary,
            }
          : const {},
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        // 子窗口入口直接挂在 MaterialApp 下：页面自带 Material（输入框需要）。
        child: Material(
          color: c.card,
          child: LayoutBuilder(
            builder: (context, box) {
              final narrow = box.maxWidth < ResourceWindowPage.narrow;
              final tight = box.maxWidth < ResourceWindowPage.tight;
              return Stack(
                children: [
                  ExcludeFocus(
                    excluding: widget.viewer != null,
                    child: Column(
                      children: [
                        _TopBar(
                          data: widget.data,
                          actions: widget.actions,
                          tight: tight,
                        ),
                        _Toolbar(
                          data: widget.data,
                          actions: widget.actions,
                          narrow: narrow,
                          focus: _search,
                          cell: _cell ?? widget.data.cellSize,
                          onCell: (v) => setState(() => _cell = v),
                          onCellEnd: widget.actions.onCellSize,
                        ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ResourceWindowSide(
                                data: widget.data,
                                actions: widget.actions,
                                collapsed: narrow,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    _MainHead(data: widget.data),
                                    Expanded(
                                      child: _Wall(
                                        data: widget.data,
                                        actions: widget.actions,
                                        scroll: _scroll,
                                        cell: _cell ?? widget.data.cellSize,
                                      ),
                                    ),
                                    if (widget.data.detail case final detail?)
                                      _DetailBar(
                                        data: widget.data,
                                        detail: detail,
                                        actions: widget.actions,
                                        narrow: narrow,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StatusRow(data: widget.data),
                      ],
                    ),
                  ),
                  if (widget.viewer case final viewer?)
                    Positioned.fill(
                      top: ResourceWindowPage.topBarHeight,
                      child: viewer,
                    ),
                  if (_notice case final n?)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 40,
                      child: Center(
                        child: _NoticeToast(
                          key: ValueKey('rw-notice-${n.id}'),
                          notice: n,
                          onClose: () => setState(() => _notice = null),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

String _kindLabel(BuildContext context, FloatingResourceKind k) {
  final l = context.l10n;
  return switch (k) {
    FloatingResourceKind.gallery => l.localGallery_title,
    FloatingResourceKind.blocks => l.blocks_title,
    FloatingResourceKind.vibe => l.refs_vibeTitle,
    FloatingResourceKind.precise => l.refs_preciseTitle,
  };
}

String _kindGlyph(FloatingResourceKind k) => switch (k) {
  FloatingResourceKind.gallery => UiGlyphs.picture,
  FloatingResourceKind.blocks => UiGlyphs.layers,
  FloatingResourceKind.vibe => UiGlyphs.spark,
  FloatingResourceKind.precise => UiGlyphs.personStar,
};

// ── 一体顶栏 ───────────────────────────────────────────────────────────

class _TopBar extends StatefulWidget {
  const _TopBar({
    required this.data,
    required this.actions,
    required this.tight,
  });
  final ResourceWindowViewData data;
  final ResourceWindowActions actions;
  final bool tight;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  final _tabs = GlobalKey();
  final _buttons = GlobalKey();
  List<Rect>? _reported;

  void _report() {
    final cb = widget.actions.onDragRegion;
    if (cb == null || !mounted) return;
    Rect? rectOf(GlobalKey k) {
      final box = k.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return null;
      return box.localToGlobal(Offset.zero) & box.size;
    }

    final blocked = [
      rectOf(_tabs),
      rectOf(_buttons),
    ].whereType<Rect>().toList();
    if (_reported != null &&
        _reported!.length == blocked.length &&
        Iterable.generate(
          blocked.length,
        ).every((i) => _reported![i] == blocked[i])) {
      return;
    }
    _reported = blocked;
    cb(ResourceWindowPage.topBarHeight, blocked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final d = widget.data;
    final a = widget.actions;
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
    return Container(
      key: const Key('rw-topbar'),
      height: ResourceWindowPage.topBarHeight,
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Flexible(
            fit: FlexFit.tight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                key: _tabs,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: c.control,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  key: const Key('rw-tabs'),
                  mainAxisSize: MainAxisSize.min,
                  spacing: 2,
                  children: [
                    for (final k in FloatingResourceKind.values)
                      _Tab(
                        kind: k,
                        on: k == d.kind,
                        iconOnly: widget.tight && k != d.kind,
                        count: widget.tight ? null : d.counts[k],
                        onTap: () => a.onKind(k),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // 拖动区：撑满中间空白。原生命中区（HTCAPTION）不可用时的退路：按下拖动、
          // 双击最大化。只包空白处，不包按钮（否则按钮要等双击判定）。
          Expanded(
            child: GestureDetector(
              key: const Key('rw-drag'),
              behavior: HitTestBehavior.opaque,
              onPanStart: a.onStartDrag == null
                  ? null
                  : (_) => a.onStartDrag!(),
              onDoubleTap: a.onToggleMaximize,
              child: const SizedBox.expand(),
            ),
          ),
          Row(
            key: _buttons,
            mainAxisSize: MainAxisSize.min,
            children: [
              UiIconBox(
                key: const Key('rw-pin'),
                glyph: UiGlyphs.pin,
                size: 28,
                tone: d.alwaysOnTop ? UiIconBoxTone.on : UiIconBoxTone.plain,
                tooltip: l.resourceWindow_pin,
                onTap: () => a.onAlwaysOnTop(!d.alwaysOnTop),
              ),
              const SizedBox(width: 4),
              UiIconBox(
                key: const Key('rw-new'),
                glyph: UiGlyphs.external,
                size: 28,
                tooltip: l.resourceWindow_newWindow,
                onTap: a.onNewWindow,
              ),
              const SizedBox(width: 6),
              if (a.onClose != null) _CloseButton(onTap: a.onClose!),
            ],
          ),
        ],
      ),
    );
  }
}

/// 关闭按钮：主程序标题栏同款（46 宽、贴满栏高、悬停红底白叉）。
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Tooltip(
      message: context.l10n.titleBar_close,
      waitDuration: const Duration(milliseconds: 500),
      child: UiPressable(
        key: const Key('rw-close'),
        onTap: onTap,
        builder: (context, hover) => Container(
          width: 46,
          height: ResourceWindowPage.topBarHeight - 1,
          color: hover ? const Color(0xFFE81123) : Colors.transparent,
          alignment: Alignment.center,
          child: Icon(
            Icons.close,
            size: 16,
            color: hover ? Colors.white : c.ink.withValues(alpha: .9),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.kind,
    required this.on,
    required this.iconOnly,
    required this.count,
    required this.onTap,
  });
  final FloatingResourceKind kind;
  final bool on, iconOnly;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final label = _kindLabel(context, kind);
    final tab = UiPressable(
      key: Key('rw-tab-${kind.name}'),
      onTap: on ? null : onTap,
      builder: (context, hover) => Container(
        height: 26,
        padding: EdgeInsets.symmetric(horizontal: iconOnly ? 8 : 10),
        decoration: BoxDecoration(
          color: on ? (c.dark ? c.hover : c.raised) : null,
          borderRadius: BorderRadius.circular(6),
          boxShadow: on && !c.dark
              ? [
                  const BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                  BoxShadow(color: c.border, spreadRadius: .5),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            UiGlyph(
              _kindGlyph(kind),
              size: 13,
              color: on || hover ? c.ink : c.muted,
            ),
            if (!iconOnly)
              Text(
                label,
                style: UiText.sans(
                  12.5,
                  weight: on ? FontWeight.w500 : FontWeight.w400,
                  color: on || hover ? c.ink : c.muted,
                  height: 1,
                ),
              ),
            if (count != null)
              Text(
                resourceCount(count!),
                key: Key('rw-tab-count-${kind.name}'),
                style: UiText.mono(11, color: c.faint, height: 1),
              ),
          ],
        ),
      ),
    );
    return iconOnly ? Tooltip(message: label, child: tab) : tab;
  }
}

// ── 工具条 ─────────────────────────────────────────────────────────────

class _Toolbar extends StatefulWidget {
  const _Toolbar({
    required this.data,
    required this.actions,
    required this.narrow,
    required this.focus,
    required this.cell,
    required this.onCell,
    required this.onCellEnd,
  });
  final ResourceWindowViewData data;
  final ResourceWindowActions actions;
  final bool narrow;
  final FocusNode focus;
  final double cell;
  final ValueChanged<double> onCell, onCellEnd;

  @override
  State<_Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<_Toolbar> {
  UiPopoverAnchor? _sortAt;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final d = widget.data;
    final (lo, hi) = d.cellRange;
    // 块卡片定宽（列数随窗口宽），没有大小可调。
    final showSize =
        d.layout != ResourceLayout.list &&
        d.kind != FloatingResourceKind.blocks &&
        !widget.narrow;
    final sort = d.sorts.where((s) => s.id == d.sortId).firstOrNull;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 140),
              child: UiSearchField(
                key: const Key('rw-search'),
                value: d.query,
                hint: d.queryHint,
                height: 30,
                focusNode: widget.focus,
                onChanged: (q) => widget.actions.onQuery(q, submit: true),
              ),
            ),
          ),
          for (final (i, chip) in d.chips.indexed)
            if (!widget.narrow || i < 2)
              UiFilterChip(
                key: Key('rw-chip-${chip.id}'),
                label: chip.label,
                selected: chip.on,
                leading: chip.glyph == null
                    ? null
                    : UiGlyph(
                        chip.glyph!,
                        size: 13,
                        color: chip.on ? c.accent : c.muted,
                      ),
                onTap: () => widget.actions.onChip(chip.id),
              ),
          if (sort != null && !widget.narrow)
            _SortControl(
              sort: sort,
              data: d,
              actions: widget.actions,
              anchor: _sortAt,
              onAnchor: (v) => setState(() => _sortAt = v),
            ),
          if (showSize)
            Tooltip(
              message: d.layout == ResourceLayout.justified
                  ? l.resourceWindow_rowHeight
                  : l.resourceWindow_cardSize,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  UiGlyph(UiGlyphs.sizes, size: 13, color: c.faint),
                  SizedBox(
                    key: const Key('rw-size'),
                    width: 76,
                    child: UiSlider(
                      value: ((widget.cell - lo) / (hi - lo)).clamp(0, 1),
                      onChanged: (v) => widget.onCell(lo + (hi - lo) * v),
                      onChangeEnd: (v) => widget.onCellEnd(lo + (hi - lo) * v),
                    ),
                  ),
                ],
              ),
            ),
          if (d.layouts.length > 1)
            UiSeg<ResourceLayout>(
              key: const Key('rw-layout'),
              values: d.layouts,
              selected: d.layout,
              onChanged: widget.actions.onLayout,
              glyphOf: (v) => switch (v) {
                ResourceLayout.grid => UiGlyphs.grid,
                ResourceLayout.masonry => UiGlyphs.masonryMedium,
                ResourceLayout.justified => _justifiedGlyph,
                ResourceLayout.list => UiGlyphs.list,
              },
              tooltipOf: (v) => switch (v) {
                ResourceLayout.grid => l.common_grid,
                ResourceLayout.masonry => l.localGallery_masonryViewLabel,
                ResourceLayout.justified => l.localGallery_justifiedViewLabel,
                ResourceLayout.list => l.blocks_viewList,
              },
            ),
        ],
      ),
    );
  }
}

/// 排序：左半是字段（点开菜单，只列字段），右半是方向箭头（点一下切升 / 降）。
/// 没有方向的字段（块库自定义顺序）不出箭头。
class _SortControl extends StatelessWidget {
  const _SortControl({
    required this.sort,
    required this.data,
    required this.actions,
    required this.anchor,
    required this.onAnchor,
  });
  final ResourceOption sort;
  final ResourceWindowViewData data;
  final ResourceWindowActions actions;
  final UiPopoverAnchor? anchor;
  final ValueChanged<UiPopoverAnchor?> onAnchor;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final d = data;
    final direction = sort.directional && actions.onSortDirection != null;
    return UiPopover(
      anchor: anchor,
      onDismiss: () => onAnchor(null),
      builder: (_) => UiMenu(
        width: 160,
        onClose: () => onAnchor(null),
        items: [
          for (final s in d.sorts)
            UiMenuItem(
              key: Key('rw-sort-${s.id}'),
              label: s.label,
              checked: s.id == d.sortId,
              onTap: () => actions.onSort(s.id),
            ),
        ],
      ),
      child: Container(
        key: const Key('rw-sort'),
        height: 28,
        decoration: BoxDecoration(
          color: c.control,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (context) => UiPressable(
                key: const Key('rw-sort-field'),
                onTap: () {
                  final box = context.findRenderObject()! as RenderBox;
                  onAnchor(
                    UiPopoverAnchor(
                      box.localToGlobal(box.size.bottomLeft(Offset.zero)) +
                          const Offset(0, 4),
                    ),
                  );
                },
                builder: (context, hover) => Container(
                  height: 28,
                  padding: EdgeInsets.only(left: 10, right: direction ? 6 : 8),
                  decoration: BoxDecoration(
                    color: hover ? c.hover : null,
                    borderRadius: BorderRadius.horizontal(
                      left: const Radius.circular(7),
                      right: Radius.circular(direction ? 0 : 7),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      UiGlyph(UiGlyphs.sort, size: 14, color: c.muted),
                      Text(
                        sort.label,
                        maxLines: 1,
                        style: UiText.sans(12.5, color: c.ink),
                      ),
                      UiGlyph(UiGlyphs.chevronDown, size: 12, color: c.muted),
                    ],
                  ),
                ),
              ),
            ),
            if (direction) ...[
              Container(width: 1, height: 14, color: c.border),
              Tooltip(
                message: d.descending
                    ? l.localGallery_sortDescending
                    : l.localGallery_sortAscending,
                child: UiPressable(
                  key: const Key('rw-sort-direction'),
                  onTap: () => actions.onSortDirection!(!d.descending),
                  builder: (context, hover) => Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hover ? c.hover : null,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(7),
                      ),
                    ),
                    child: UiGlyph(
                      d.descending ? UiGlyphs.arrowDown : UiGlyphs.arrowUp,
                      size: 14,
                      color: c.ink,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 火车流：三行不等宽的块（一行行排）。
const _justifiedGlyph =
    'M4 5h9v4H4zM15 5h5v4h-5zM4 11h5v4H4zM11 11h9v4h-9zM4 17h12v2H4z';

// ── 主区头 ─────────────────────────────────────────────────────────────

class _MainHead extends StatelessWidget {
  const _MainHead({required this.data});
  final ResourceWindowViewData data;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final group = data.sections
        .expand((s) => s.groups)
        .where((g) => g.id == data.groupId)
        .firstOrNull;
    return SizedBox(
      height: 36,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          spacing: 8,
          children: [
            if (group != null)
              Flexible(
                child: Text(
                  group.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(
                    12.5,
                    weight: FontWeight.w500,
                    color: c.ink,
                  ),
                ),
              ),
            Text(
              resourceCount(data.total),
              style: UiText.mono(11.5, color: c.faint),
            ),
            if (data.loading) const UiSpinner(size: 12),
            const Spacer(),
            Flexible(
              child: Text(
                data.kind == FloatingResourceKind.blocks
                    ? l.resourceWindow_dragHintBlocks
                    : l.resourceWindow_dragHint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(12, color: c.faint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 卡片墙 ─────────────────────────────────────────────────────────────

class _Wall extends StatelessWidget {
  const _Wall({
    required this.data,
    required this.actions,
    required this.scroll,
    required this.cell,
  });
  final ResourceWindowViewData data;
  final ResourceWindowActions actions;
  final ScrollController scroll;
  final double cell;

  /// 图库同本地画廊（间距 4）；块库 12 / 14；参考 12 / 16。
  static const galleryGap = 4.0;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    if (data.error != null && data.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            Text(data.error!, style: UiText.sans(12.5, color: c.muted)),
            if (actions.onRetry != null)
              UiBtn(
                size: UiBtnSize.small,
                onTap: actions.onRetry,
                children: [Text(l.common_retry)],
              ),
          ],
        ),
      );
    }
    if (data.items.isEmpty) {
      return Center(
        child: data.loading
            ? const UiSpinner(size: 16)
            : Text(l.floating_empty, style: UiText.sans(12.5, color: c.faint)),
      );
    }
    final pad = switch (data.kind) {
      FloatingResourceKind.gallery => const EdgeInsets.fromLTRB(12, 0, 12, 12),
      _ => const EdgeInsets.fromLTRB(18, 4, 18, 18),
    };
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth - pad.horizontal;
          final slivers = <Widget>[
            if (data.layout == ResourceLayout.list)
              _list()
            else if (data.kind == FloatingResourceKind.blocks)
              _blockGrid(width)
            else if (data.kind == FloatingResourceKind.gallery)
              ..._galleryDays(context, width)
            else
              _refsGrid(width),
            if (data.hasMore)
              SliverToBoxAdapter(
                child: _LoadMore(onVisible: actions.onLoadMore),
              ),
          ];
          return CustomScrollView(
            key: const Key('rw-wall'),
            controller: scroll,
            slivers: [
              for (final s in slivers) SliverPadding(padding: pad, sliver: s),
            ],
          );
        },
      ),
    );
  }

  Widget _wrap(ResourceItem it, Widget card) =>
      actions.dragWrap?.call(it, card) ?? card;

  Widget _galleryCard(ResourceItem it, double w, double h) => _wrap(
    it,
    ResourceGalleryCard(
      key: Key('rw-item-${it.id}'),
      item: it,
      width: w,
      height: h,
      selected: it.id == data.selectedId,
      onTap: () => actions.onSelect(it.id),
      onDouble: () => actions.onOpen(it.id),
      onFavorite: () => actions.onFavorite(it.id),
      onAction: (a) => actions.onAction(it.id, a),
    ),
  );

  Widget _galleryGrid(List<ResourceItem> items, double width) {
    const gap = galleryGap;
    final cols = math.max(1, ((width + gap) / (cell + gap)).floor());
    final w = (width - gap * (cols - 1)) / cols;
    return switch (data.layout) {
      ResourceLayout.masonry => SliverMasonryGrid.count(
        crossAxisCount: cols,
        mainAxisSpacing: gap,
        crossAxisSpacing: gap,
        childCount: items.length,
        itemBuilder: (_, i) {
          final h = w / (items[i].aspect ?? 2 / 3);
          return _galleryCard(items[i], w, h);
        },
      ),
      ResourceLayout.justified => _justified(items, width),
      _ => SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _galleryCard(items[i], w, w),
      ),
    };
  }

  Widget _justified(List<ResourceItem> items, double width) {
    const gap = galleryGap;
    final rows = computeJustifiedRows(
      aspectRatios: [for (final it in items) it.aspect ?? 2 / 3],
      availableWidth: width,
      targetHeight: cell,
      spacing: gap,
    );
    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (_, r) {
        final row = rows[r];
        return Padding(
          padding: const EdgeInsets.only(bottom: gap),
          child: SizedBox(
            height: row.height,
            child: Row(
              spacing: gap,
              children: [
                for (var i = row.start; i < row.end; i++)
                  _galleryCard(
                    items[i],
                    row.height * (items[i].aspect ?? 2 / 3),
                    row.height,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 图库按天分段（今天 / 昨天 / 具体日期），段头同本地画廊。
  List<Widget> _galleryDays(BuildContext context, double width) {
    final l = context.l10n;
    final now = data.now ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final groups = <(DateTime?, List<ResourceItem>)>[];
    for (final it in data.items) {
      final d = it.date == null
          ? null
          : DateTime(it.date!.year, it.date!.month, it.date!.day);
      if (groups.isEmpty || groups.last.$1 != d) {
        groups.add((d, [it]));
      } else {
        groups.last.$2.add(it);
      }
    }
    final loc = MaterialLocalizations.of(context);
    return [
      for (final (day, items) in groups) ...[
        if (day != null)
          SliverToBoxAdapter(
            child: _DayHead(
              title: day == today
                  ? l.localGallery_group_today
                  : day == today.subtract(const Duration(days: 1))
                  ? l.localGallery_group_yesterday
                  : loc.formatMediumDate(day),
              count: items.length,
            ),
          ),
        _galleryGrid(items, width),
      ],
    ];
  }

  Widget _blockCard(ResourceItem it, double w, double? coverH) => _wrap(
    it,
    ResourceBlockCard(
      key: Key('rw-item-${it.id}'),
      item: it,
      width: w,
      coverH: coverH,
      selected: it.id == data.selectedId,
      onTap: () => actions.onSelect(it.id),
      onDouble: () => actions.onOpen(it.id),
      onFavorite: () => actions.onFavorite(it.id),
      onAction: (a) => actions.onAction(it.id, a),
    ),
  );

  Widget _blockGrid(double width) {
    // 块库默认卡片大小（0.5 → 最小宽 220）；列数随窗口宽。
    const minCard = 220.0;
    final cols = math.max(1, ((width + 12) / (minCard + 12)).floor());
    final w = (width - 12 * (cols - 1)) / cols;
    final coverH = (w * .6).roundToDouble();
    return data.layout == ResourceLayout.masonry
        ? SliverMasonryGrid.count(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
            childCount: data.items.length,
            itemBuilder: (_, i) => _blockCard(data.items[i], w, null),
          )
        : SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              mainAxisExtent: coverH + ResourceBlockCard.titleH,
            ),
            itemCount: data.items.length,
            itemBuilder: (_, i) => _blockCard(data.items[i], w, coverH),
          );
  }

  Widget _refsGrid(double width) {
    const colGap = 12.0, rowGap = 16.0;
    final cols = math.max(1, ((width + colGap) / (cell + colGap)).ceil());
    final w = (width - colGap * (cols - 1)) / cols;
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: colGap,
        mainAxisSpacing: rowGap,
        mainAxisExtent: ResourceRefsCard.heightFor(w),
      ),
      itemCount: data.items.length,
      itemBuilder: (_, i) {
        final it = data.items[i];
        return _wrap(
          it,
          ResourceRefsCard(
            key: Key('rw-item-${it.id}'),
            item: it,
            kind: data.kind,
            selected: it.id == data.selectedId,
            onTap: () => actions.onSelect(it.id),
            onDouble: () => actions.onOpen(it.id),
            onFavorite: () => actions.onFavorite(it.id),
            onAction: (a) => actions.onAction(it.id, a),
          ),
        );
      },
    );
  }

  Widget _list() => SliverList.builder(
    itemCount: data.items.length,
    itemBuilder: (_, i) {
      final it = data.items[i];
      return _wrap(
        it,
        ResourceListRow(
          key: Key('rw-item-${it.id}'),
          item: it,
          kind: data.kind,
          selected: it.id == data.selectedId,
          onTap: () => actions.onSelect(it.id),
          onDouble: () => actions.onOpen(it.id),
          onFavorite: () => actions.onFavorite(it.id),
        ),
      );
    },
  );
}

/// 列表末尾的加载行：一出现在屏幕上就要下一页（不依赖滚动事件；失败 / 被打断后
/// 只要它还在视口里，下一帧会再要一次，控制器保证幂等）。
class _LoadMore extends StatefulWidget {
  const _LoadMore({required this.onVisible});
  final VoidCallback onVisible;

  @override
  State<_LoadMore> createState() => _LoadMoreState();
}

class _LoadMoreState extends State<_LoadMore> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onVisible();
    });
  }

  @override
  Widget build(BuildContext context) => const Padding(
    key: Key('rw-load-more'),
    padding: EdgeInsets.all(12),
    child: Center(child: UiSpinner(size: 14)),
  );
}

/// 图库日期段头（本地画廊时间线段头同款：标题 w600 + 计数弱色 13）。
class _DayHead extends StatelessWidget {
  const _DayHead({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return SizedBox(
      height: 44,
      child: Row(
        spacing: 8,
        children: [
          Text(
            title,
            style: UiText.sans(14, weight: FontWeight.w600, color: c.ink),
          ),
          Text(
            context.l10n.localGallery_groupImageCount(
              count,
              resourceCount(count),
            ),
            style: UiText.sans(13, color: c.muted),
          ),
        ],
      ),
    );
  }
}

/// 操作失败提示：底部居中的小条，几秒后收起；按 code 选文案。
class _NoticeToast extends StatelessWidget {
  const _NoticeToast({super.key, required this.notice, required this.onClose});
  final ResourceNotice notice;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final text = switch (notice.code) {
      'not_found' => l.resourceWindow_errorNotFound,
      'not_ready' => l.resourceWindow_errorNotReady,
      'unsupported' => l.resourceWindow_errorUnsupported,
      'disconnected' => l.resourceWindow_disconnected,
      _ => l.resourceWindow_errorFailed,
    };
    return Container(
      key: const Key('rw-notice'),
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          UiGlyph(UiGlyphs.alert, size: 15, color: c.warn),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: text),
                  if (notice.message?.isNotEmpty ?? false)
                    TextSpan(
                      text: '  ${notice.message}',
                      style: TextStyle(color: c.faint),
                    ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12.5, color: c.ink),
            ),
          ),
          UiIconBox(
            glyph: UiGlyphs.close,
            size: 22,
            glyphSize: 12,
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

// ── 详情条 ─────────────────────────────────────────────────────────────

class _DetailBar extends StatelessWidget {
  const _DetailBar({
    required this.data,
    required this.detail,
    required this.actions,
    required this.narrow,
  });
  final ResourceWindowViewData data;
  final ResourceDetail detail;
  final ResourceWindowActions actions;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final item = data.items.where((i) => i.id == detail.itemId).firstOrNull;
    final blocks = data.kind == FloatingResourceKind.blocks;
    final tint = item?.color ?? c.accent;
    final shown = narrow
        ? detail.actions.where((a) => a.primary).toList()
        : detail.actions;
    return Container(
      key: const Key('rw-detail'),
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        spacing: 14,
        children: [
          if (blocks)
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(7),
              ),
              child: UiBlockIcon(item?.iconKey, size: 20, color: tint),
            )
          else
            Container(
              width: 46,
              height: 64,
              decoration: BoxDecoration(
                color: c.control,
                borderRadius: BorderRadius.circular(7),
              ),
              clipBehavior: Clip.antiAlias,
              child: item?.thumb == null
                  ? null
                  : Image(
                      image: item!.thumb!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(),
                    ),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Text(
                      detail.title,
                      maxLines: 1,
                      style: UiText.sans(
                        13,
                        weight: FontWeight.w500,
                        color: c.ink,
                      ),
                    ),
                    if (detail.subtitle != null)
                      Expanded(
                        child: Text(
                          detail.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(11.5, color: c.faint),
                        ),
                      ),
                  ],
                ),
                if (detail.body != null || detail.negative != null)
                  Text.rich(
                    TextSpan(
                      children: [
                        if (detail.body != null) TextSpan(text: detail.body),
                        if (detail.negative != null)
                          TextSpan(
                            text:
                                '${detail.body == null ? '' : ' · '}− ${detail.negative}',
                            style: TextStyle(color: c.fav),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.mono(11.5, color: c.muted),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              for (final a in shown)
                UiBtn(
                  key: Key('rw-act-${a.id}'),
                  tone: a.primary ? UiBtnTone.primary : UiBtnTone.normal,
                  onTap: () => actions.onAction(detail.itemId, a.id),
                  children: [
                    if (a.glyph != null)
                      UiGlyph(
                        a.glyph!,
                        size: 14,
                        color: a.primary ? c.onBrand : c.ink,
                      ),
                    Text(a.label),
                    if (a.primary)
                      Text(
                        'Enter',
                        style: UiText.mono(
                          10.5,
                          color: c.onBrand.withValues(alpha: .75),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 状态行 ─────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.data});
  final ResourceWindowViewData data;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    Widget hint(String key, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        UiKeycap(key, style: UiKeycapStyle.compact),
        Text(text, style: UiText.sans(11, color: c.faint)),
      ],
    );
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        spacing: 14,
        children: [
          // 放不下的提示整条藏掉（Wrap 折到第二行再裁掉），不出现半截字。
          Expanded(
            child: ClipRect(
              child: Wrap(
                spacing: 14,
                runSpacing: 20,
                clipBehavior: Clip.hardEdge,
                children: [
                  hint(l.resourceWindow_keyDrag, l.resourceWindow_hintDrag),
                  hint(
                    l.resourceWindow_keyDouble,
                    data.kind == FloatingResourceKind.gallery
                        ? l.resourceWindow_hintView
                        : l.common_edit,
                  ),
                  hint('Enter', l.resourceWindow_hintPrimary),
                ],
              ),
            ),
          ),
          Text(
            data.connected
                ? l.resourceWindow_connected
                : l.resourceWindow_disconnected,
            style: UiText.sans(11, color: data.connected ? c.faint : c.warn),
          ),
          _Dot(color: data.connected ? c.ok : c.warn),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
