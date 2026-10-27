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
import 'resource_window_contract.dart';

/// E05 独立资源窗口整页（原型 `.devin/mockups/d04-window/mock.html`）。
///
/// 自上而下：顶栏（四类资源标签页 · 置顶 / 新开窗口）· 工具条（搜索 · 筛选片 · 排序 ·
/// 大小 · 排布）· 主体（左侧分组 · 卡片墙）· 详情条（选中项与操作）· 状态行。
/// 窗口框与系统按钮由原生窗口提供；窄于 780 时侧栏收成图标、隐藏次要工具。
class ResourceWindowPage extends StatefulWidget {
  const ResourceWindowPage({
    super.key,
    required this.data,
    required this.actions,
  });

  final ResourceWindowViewData data;
  final ResourceWindowActions actions;

  static const narrow = 780.0;
  static const tight = 620.0;

  @override
  State<ResourceWindowPage> createState() => _ResourceWindowPageState();
}

class _ResourceWindowPageState extends State<ResourceWindowPage> {
  final _search = FocusNode();
  final _scroll = ScrollController();

  /// 大小滑杆拖动中的预览值；松手才回调持久化。
  double? _cell;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void didUpdateWidget(covariant ResourceWindowPage old) {
    super.didUpdateWidget(old);
    if (old.data.kind != widget.data.kind ||
        old.data.groupId != widget.data.groupId) {
      _cell = null;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    final d = widget.data;
    if (!d.hasMore || d.loading || !_scroll.hasClients) return;
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
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            _search.requestFocus(),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _move(1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _move(-1),
        const SingleActivator(LogicalKeyboardKey.enter): _primary,
      },
      child: Focus(
        autofocus: true,
        // 子窗口入口直接挂在 MaterialApp 下：页面自带 Material（输入框需要）。
        child: Material(
          color: c.card,
          child: LayoutBuilder(
            builder: (context, box) {
              final narrow = box.maxWidth < ResourceWindowPage.narrow;
              final tight = box.maxWidth < ResourceWindowPage.tight;
              return Column(
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
                    onCellEnd: (v) {
                      widget.actions.onCellSize(v);
                    },
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Side(
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

String _count(int n) {
  final s = '$n';
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

// ── 顶栏 ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.data,
    required this.actions,
    required this.tight,
  });
  final ResourceWindowViewData data;
  final ResourceWindowActions actions;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        spacing: 10,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  key: const Key('rw-tabs'),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: c.control,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    spacing: 2,
                    children: [
                      for (final k in FloatingResourceKind.values)
                        _Tab(
                          kind: k,
                          on: k == data.kind,
                          count: tight ? null : data.counts[k],
                          onTap: () => actions.onKind(k),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          UiIconBox(
            key: const Key('rw-pin'),
            glyph: UiGlyphs.pin,
            size: 28,
            tone: data.alwaysOnTop ? UiIconBoxTone.on : UiIconBoxTone.plain,
            tooltip: l.resourceWindow_pin,
            onTap: () => actions.onAlwaysOnTop(!data.alwaysOnTop),
          ),
          UiIconBox(
            key: const Key('rw-new'),
            glyph: UiGlyphs.external,
            size: 28,
            tooltip: l.resourceWindow_newWindow,
            onTap: actions.onNewWindow,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.kind,
    required this.on,
    required this.count,
    required this.onTap,
  });
  final FloatingResourceKind kind;
  final bool on;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      key: Key('rw-tab-${kind.name}'),
      onTap: on ? null : onTap,
      builder: (context, hover) => Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
            Text(
              _kindLabel(context, kind),
              style: UiText.sans(
                12.5,
                weight: on ? FontWeight.w500 : FontWeight.w400,
                color: on || hover ? c.ink : c.muted,
                height: 1,
              ),
            ),
            if (count != null)
              Text(
                _count(count!),
                style: UiText.mono(11, color: c.faint, height: 1),
              ),
          ],
        ),
      ),
    );
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
            UiPopover(
              anchor: _sortAt,
              onDismiss: () => setState(() => _sortAt = null),
              builder: (_) => UiMenu(
                width: 170,
                onClose: () => setState(() => _sortAt = null),
                items: [
                  for (final s in d.sorts)
                    UiMenuItem(
                      key: Key('rw-sort-${s.id}'),
                      label: s.label,
                      checked: s.id == d.sortId,
                      onTap: () => widget.actions.onSort(s.id),
                    ),
                ],
              ),
              child: Builder(
                builder: (context) => UiDropChip(
                  key: const Key('rw-sort'),
                  glyph: UiGlyphs.sort,
                  label: sort.label,
                  onTap: () {
                    final box = context.findRenderObject()! as RenderBox;
                    setState(
                      () => _sortAt = UiPopoverAnchor(
                        box.localToGlobal(box.size.bottomRight(Offset.zero)) +
                            const Offset(0, 4),
                        alignRight: true,
                      ),
                    );
                  },
                ),
              ),
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

/// 火车流：三行不等宽的块（一行行排）。
const _justifiedGlyph =
    'M4 5h9v4H4zM15 5h5v4h-5zM4 11h5v4H4zM11 11h9v4h-9zM4 17h12v2H4z';

// ── 侧栏 ───────────────────────────────────────────────────────────────

class _Side extends StatelessWidget {
  const _Side({
    required this.data,
    required this.actions,
    required this.collapsed,
  });
  final ResourceWindowViewData data;
  final ResourceWindowActions actions;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      key: const Key('rw-side'),
      width: collapsed ? 56 : 212,
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
                children: [
                  for (final s in data.sections) ...[
                    if (!collapsed)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                        child: Text(
                          s.title,
                          style: UiText.sans(
                            11,
                            color: c.faint,
                            letterSpacing: .2,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                    for (final g in s.groups)
                      _GroupRow(
                        group: g,
                        on: g.id == data.groupId,
                        collapsed: collapsed,
                        onTap: () => actions.onGroup(g.id),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (data.statusNote != null)
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                mainAxisAlignment: collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                spacing: 6,
                children: [
                  _Dot(color: data.connected ? c.ok : c.warn),
                  if (!collapsed)
                    Expanded(
                      child: Text(
                        data.statusNote!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(11, color: c.faint),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.on,
    required this.collapsed,
    required this.onTap,
  });
  final ResourceGroup group;
  final bool on, collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final icon = group.color != null
        ? Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: group.color,
              borderRadius: BorderRadius.circular(3),
            ),
          )
        : UiGlyph(
            group.glyph ?? UiGlyphs.folder,
            size: 14,
            color: on ? c.ink : c.muted,
          );
    final row = UiPressable(
      key: Key('rw-group-${group.id}'),
      onTap: onTap,
      builder: (context, hover) => Container(
        height: 30,
        padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 8),
        decoration: BoxDecoration(
          color: on ? c.card : (hover ? c.hover : null),
          borderRadius: BorderRadius.circular(7),
          border: on ? Border.all(color: c.border) : null,
        ),
        child: collapsed
            ? Center(
                child: SizedBox(width: 14, child: Center(child: icon)),
              )
            : Row(
                spacing: 8,
                children: [
                  SizedBox(width: 14, child: Center(child: icon)),
                  Expanded(
                    child: Text(
                      group.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(
                        12.5,
                        weight: on ? FontWeight.w500 : FontWeight.w400,
                        color: on || hover ? c.ink : c.muted,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (group.count != null)
                    Text(
                      _count(group.count!),
                      style: UiText.mono(11, color: c.faint),
                    ),
                ],
              ),
      ),
    );
    return collapsed ? Tooltip(message: group.label, child: row) : row;
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
            Text(_count(data.total), style: UiText.mono(11.5, color: c.faint)),
            if (data.loading) const UiSpinner(size: 12),
            const Spacer(),
            Text(
              data.kind == FloatingResourceKind.blocks
                  ? l.resourceWindow_dragHintBlocks
                  : l.resourceWindow_dragHint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12, color: c.faint),
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

  static const gap = 10.0;
  static const pad = EdgeInsets.fromLTRB(14, 0, 14, 14);

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
    final blocks = data.kind == FloatingResourceKind.blocks;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth - pad.horizontal;
          final slivers = <Widget>[
            if (data.layout == ResourceLayout.list)
              _list(context)
            else if (blocks)
              _blockGrid(context, width)
            else if (data.kind == FloatingResourceKind.gallery)
              ..._galleryDays(context, width)
            else
              _imageGrid(data.items, width),
            if (data.hasMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: UiSpinner(size: 14)),
                ),
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

  Widget _imageCard(ResourceItem it) => _wrap(
    it,
    _ImageCard(
      key: Key('rw-item-${it.id}'),
      item: it,
      kind: data.kind,
      selected: it.id == data.selectedId,
      showMeta: data.layout != ResourceLayout.justified,
      fit: data.layout == ResourceLayout.grid,
      onTap: () => actions.onSelect(it.id),
      onDouble: () => actions.onOpen(it.id),
      onFavorite: () => actions.onFavorite(it.id),
      onHover: (a) => actions.onAction(it.id, a),
    ),
  );

  Widget _imageGrid(List<ResourceItem> items, double width) {
    final cols = math.max(1, ((width + gap) / (cell + gap)).floor());
    return switch (data.layout) {
      ResourceLayout.masonry => SliverMasonryGrid.count(
        crossAxisCount: cols,
        mainAxisSpacing: gap,
        crossAxisSpacing: gap,
        childCount: items.length,
        itemBuilder: (_, i) => _imageCard(items[i]),
      ),
      ResourceLayout.justified => _justified(items, width),
      _ => SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
          // 2:3 图 + 22 高的说明行。
          childAspectRatio:
              ((width - gap * (cols - 1)) / cols) /
              ((width - gap * (cols - 1)) / cols * 1.5 + 22),
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _imageCard(items[i]),
      ),
    };
  }

  Widget _justified(List<ResourceItem> items, double width) {
    final rows = computeJustifiedRows(
      aspectRatios: [for (final it in items) it.aspect ?? 2 / 3],
      availableWidth: width,
      targetHeight: cell,
      spacing: 6,
    );
    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (_, r) {
        final row = rows[r];
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: SizedBox(
            height: row.height,
            child: Row(
              spacing: 6,
              children: [
                for (var i = row.start; i < row.end; i++)
                  SizedBox(
                    width: row.height * (items[i].aspect ?? 2 / 3),
                    child: _imageCard(items[i]),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 图库按天分段（今天 / 昨天 / 具体日期）。
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
        _imageGrid(items, width),
      ],
    ];
  }

  Widget _blockGrid(BuildContext context, double width) {
    final cols = math.max(1, ((width + gap) / (232 + gap)).floor());
    Widget card(int i) {
      final it = data.items[i];
      return _wrap(
        it,
        _BlockCard(
          key: Key('rw-item-${it.id}'),
          item: it,
          selected: it.id == data.selectedId,
          onTap: () => actions.onSelect(it.id),
          onDouble: () => actions.onOpen(it.id),
        ),
      );
    }

    return data.layout == ResourceLayout.masonry
        ? SliverMasonryGrid.count(
            crossAxisCount: cols,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            childCount: data.items.length,
            itemBuilder: (_, i) => card(i),
          )
        : SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
              // 方格：等高卡片，预览两行裁掉；随文字缩放留余量。
              mainAxisExtent: MediaQuery.textScalerOf(context).scale(112),
            ),
            itemCount: data.items.length,
            itemBuilder: (_, i) => card(i),
          );
  }

  Widget _list(BuildContext context) => SliverList.builder(
    itemCount: data.items.length,
    itemBuilder: (_, i) {
      final it = data.items[i];
      return _wrap(
        it,
        _ListRow(
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

class _DayHead extends StatelessWidget {
  const _DayHead({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        spacing: 8,
        children: [
          Text(
            title,
            style: UiText.sans(11.5, weight: FontWeight.w500, color: c.muted),
          ),
          Text('· $count', style: UiText.mono(11, color: c.faint)),
          Expanded(child: Container(height: 1, color: c.border)),
        ],
      ),
    );
  }
}

Color _badgeBg(BuildContext context, ResourceBadgeTone t) {
  final c = context.ui;
  return switch (t) {
    ResourceBadgeTone.plain => const Color(0x73000000),
    ResourceBadgeTone.ok => c.ok.withValues(alpha: .85),
    ResourceBadgeTone.warn => c.warn.withValues(alpha: .88),
    ResourceBadgeTone.accent => c.brand.withValues(alpha: .85),
  };
}

class _ImageCard extends StatefulWidget {
  const _ImageCard({
    super.key,
    required this.item,
    required this.kind,
    required this.selected,
    required this.showMeta,
    required this.fit,
    required this.onTap,
    required this.onDouble,
    required this.onFavorite,
    required this.onHover,
  });
  final ResourceItem item;
  final FloatingResourceKind kind;
  final bool selected, showMeta, fit;
  final VoidCallback onTap, onDouble, onFavorite;
  final ValueChanged<String> onHover;

  @override
  State<_ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<_ImageCard> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final it = widget.item;
    final gallery = widget.kind == FloatingResourceKind.gallery;
    Widget image = Container(
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (it.thumb != null)
            AnimatedScale(
              scale: _hover ? 1.03 : 1,
              duration: const Duration(milliseconds: 250),
              child: Image(
                image: it.thumb!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => Center(
                  child: UiGlyph(UiGlyphs.picture, size: 18, color: c.faint),
                ),
              ),
            )
          else
            Center(child: UiGlyph(UiGlyphs.picture, size: 18, color: c.faint)),
          if (it.badge != null)
            Positioned(
              left: 7,
              top: 7,
              child: Container(
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _badgeBg(context, it.badgeTone),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  it.badge!,
                  style: UiText.sans(
                    10.5,
                    weight: FontWeight.w500,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
          if (_hover || it.favorite)
            Positioned(
              right: 7,
              top: 7,
              child: GestureDetector(
                key: Key('rw-fav-${it.id}'),
                onTap: widget.onFavorite,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: it.favorite ? c.fav : const Color(0x59000000),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: UiGlyph(
                    gallery ? UiGlyphs.heart : UiGlyphs.star,
                    size: 13,
                    filled: it.favorite,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    image = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.selected ? c.brand : Colors.transparent,
          width: 2,
        ),
      ),
      child: image,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDouble,
        child: widget.showMeta
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.fit)
                    Expanded(child: image)
                  else
                    AspectRatio(aspectRatio: it.aspect ?? 2 / 3, child: image),
                  SizedBox(
                    height: 22,
                    child: Row(
                      spacing: 6,
                      children: [
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            it.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.sans(11.5, color: c.muted, height: 1),
                          ),
                        ),
                        if (it.meta != null)
                          Text(
                            it.meta!,
                            style: UiText.mono(11, color: c.faint, height: 1),
                          ),
                        const SizedBox(width: 2),
                      ],
                    ),
                  ),
                ],
              )
            : image,
      ),
    );
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onDouble,
  });
  final ResourceItem item;
  final bool selected;
  final VoidCallback onTap, onDouble;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final tint = item.color ?? c.accent;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => GestureDetector(
        onDoubleTap: onDouble,
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? c.brand : (hover ? c.strong : c.border),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 7,
            children: [
              Row(
                spacing: 8,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: UiBlockIcon(item.iconKey, size: 15, color: tint),
                  ),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(
                        12.5,
                        weight: FontWeight.w500,
                        color: c.ink,
                      ),
                    ),
                  ),
                  if (item.favorite)
                    UiGlyph(UiGlyphs.star, size: 13, color: c.star),
                ],
              ),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (item.positive?.isNotEmpty ?? false)
                        TextSpan(text: item.positive),
                      if (item.negative?.isNotEmpty ?? false) ...[
                        if (item.positive?.isNotEmpty ?? false)
                          const TextSpan(text: '\n'),
                        TextSpan(
                          text: '− ${item.negative}',
                          style: TextStyle(color: c.fav.withValues(alpha: .85)),
                        ),
                      ],
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.mono(11.5, color: c.muted, height: 1.5),
                ),
              ),
              Row(
                spacing: 6,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (item.folder != null)
                    Flexible(
                      child: Text(
                        item.folder!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(11, color: c.faint),
                      ),
                    ),
                  const Spacer(),
                  if (item.positive?.isNotEmpty ?? false)
                    UiMini(l.blocks_positive),
                  if (item.negative?.isNotEmpty ?? false)
                    UiMini(l.blocks_negative, foreground: c.fav),
                  if (item.meta != null)
                    Text(item.meta!, style: UiText.mono(11, color: c.faint)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    super.key,
    required this.item,
    required this.kind,
    required this.selected,
    required this.onTap,
    required this.onDouble,
    required this.onFavorite,
  });
  final ResourceItem item;
  final FloatingResourceKind kind;
  final bool selected;
  final VoidCallback onTap, onDouble, onFavorite;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final blocks = kind == FloatingResourceKind.blocks;
    final tint = item.color ?? c.accent;
    final body = blocks
        ? [item.positive, item.negative].whereType<String>().join('  ·  − ')
        : item.positive;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => GestureDetector(
        onDoubleTap: onDouble,
        child: Container(
          height: 48,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? c.accent.withValues(alpha: c.dark ? .14 : .07)
                : hover
                ? c.hover
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            spacing: 10,
            children: [
              if (blocks)
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: UiBlockIcon(item.iconKey, size: 15, color: tint),
                )
              else
                Container(
                  width: 30,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.control,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.thumb == null
                      ? null
                      : Image(
                          image: item.thumb!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox(),
                        ),
                ),
              SizedBox(
                width: 160,
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(
                    12.5,
                    weight: FontWeight.w500,
                    color: c.ink,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  body ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.mono(11.5, color: c.muted),
                ),
              ),
              if (item.badge != null)
                UiMini(
                  item.badge!,
                  tone: switch (item.badgeTone) {
                    ResourceBadgeTone.ok => UiMiniTone.ok,
                    ResourceBadgeTone.warn => UiMiniTone.warn,
                    ResourceBadgeTone.accent => UiMiniTone.accent,
                    ResourceBadgeTone.plain => UiMiniTone.plain,
                  },
                ),
              if (item.meta != null)
                Text(item.meta!, style: UiText.mono(11, color: c.faint)),
              UiIconBox(
                glyph: blocks || kind != FloatingResourceKind.gallery
                    ? UiGlyphs.star
                    : UiGlyphs.heart,
                size: 26,
                glyphSize: 13,
                filled: item.favorite,
                color: item.favorite
                    ? (kind == FloatingResourceKind.gallery ? c.fav : c.star)
                    : null,
                onTap: onFavorite,
              ),
            ],
          ),
        ),
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
