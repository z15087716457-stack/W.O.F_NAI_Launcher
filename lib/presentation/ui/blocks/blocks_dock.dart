import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../kit/ui_block_pill.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_inputs.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'blocks_contract.dart';
import 'blocks_parts.dart';
import 'blocks_rag_badge.dart';

/// 生图页块库侧栏（原型 `.dock`，默认宽 300，宽度由外面的 `BlockLibraryPanelSlot` 定）：
/// 标题行 44 · 搜索 32 · 一行分类筛选 · 收藏 / 最近使用置顶 · 按分类分组摆药丸 · 底部提示 34。
/// 悬停药丸 180ms 后在侧栏右缘外 10 弹出预览卡；点击插到光标处，拖进提示词放到指定位置，右键更多。
class BlocksDock extends StatefulWidget {
  const BlocksDock({super.key, required this.data, required this.actions});

  final BlocksDockViewData data;
  final BlocksDockActions actions;

  /// 每个分类先摆这么多颗，其余点“全部 N”。
  static const groupPreview = 12;

  @override
  State<BlocksDock> createState() => _BlocksDockState();
}

class _BlocksDockState extends State<BlocksDock> {
  final _portal = OverlayPortalController();
  final _key = GlobalKey();
  Timer? _hoverTimer;
  BlockData? _hover;
  Rect? _hoverRect;
  UiPopoverAnchor? _menu;
  List<UiMenuItem> _menuItems = const [];

  BlocksDockViewData get d => widget.data;
  BlocksDockActions get a => widget.actions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _portal.show();
    });
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }

  void _enter(BlockData b, BuildContext pill) {
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 180), () {
      if (!mounted || !pill.mounted) return;
      final box = pill.findRenderObject()! as RenderBox;
      setState(() {
        _hover = b;
        _hoverRect = box.localToGlobal(Offset.zero) & box.size;
      });
    });
  }

  void _exit() {
    _hoverTimer?.cancel();
    if (_hover != null) setState(() => _hover = null);
  }

  void _openMenu(BlockData b, Offset at) {
    final l10n = context.l10n;
    _exit();
    setState(() {
      _menu = UiPopoverAnchor(at);
      _menuItems = [
        UiMenuItem(
          glyph: UiGlyphs.plus,
          label: l10n.blocks_insertAtCursor,
          onTap: () => a.onInsert(b.id),
        ),
        UiMenuItem(
          glyph: UiGlyphs.pencil,
          label: l10n.blocks_edit,
          onTap: () => a.onEdit(b.id),
        ),
        UiMenuItem(
          glyph: UiGlyphs.star,
          label: b.favorite ? l10n.blocks_unfavorite : l10n.blocks_favorite,
          onTap: () => a.onSetFavorite(b.id, !b.favorite),
        ),
        UiMenuItem(
          glyph: UiGlyphs.box,
          label: l10n.blocks_addToPalette,
          onTap: () => a.onAddToPalette(b.id),
        ),
        UiMenuItem(
          glyph: UiGlyphs.external,
          label: l10n.blocks_showInLibrary,
          divider: true,
          onTap: () => a.onShowInLibrary(b.id),
        ),
      ];
    });
  }

  Widget _pill(BlockData b) => Builder(
    builder: (ctx) {
      final pill = BlockPill(b, open: _hover?.id == b.id);
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _enter(b, ctx),
        onExit: (_) => _exit(),
        child: GestureDetector(
          key: Key('dock-pill-${b.id}'),
          onTap: () {
            _exit();
            a.onInsert(b.id);
          },
          onSecondaryTapUp: (e) => _openMenu(b, e.globalPosition),
          child: Draggable<Object>(
            data: a.dragDataOf(b.id),
            // 页面在分支 Navigator 内，预览须与积木浮窗同处根浮层，
            // 否则拖到浮窗上方时会被卡片遮住。
            rootOverlay: true,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            onDragStarted: _exit,
            feedback: Material(
              type: MaterialType.transparency,
              child: UiBlockPill(
                label: b.title,
                color: b.color,
                icon: b.icon,
                look: b.look,
                dragging: true,
                translationMark: context.l10n.blocks_translationMark,
              ),
            ),
            childWhenDragging: Opacity(opacity: .35, child: pill),
            child: pill,
          ),
        ),
      );
    },
  );

  Widget _section({
    required Widget icon,
    required String title,
    int? count,
    required List<BlockData> blocks,
    VoidCallback? onTitle,
    String? more,
    VoidCallback? onMore,
    bool expanded = true,
    Key? key,
  }) {
    final c = context.ui;
    final shown = blocks.length > BlocksDock.groupPreview && more != null
        ? blocks.take(BlocksDock.groupPreview).toList()
        : blocks;
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiPressable(
            onTap: onTitle,
            builder: (context, hover) => SizedBox(
              height: 22,
              child: Row(
                spacing: 6,
                children: [
                  icon,
                  Expanded(
                    child: Row(
                      spacing: 6,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.sans(
                              11.5,
                              weight: FontWeight.w600,
                              color: hover ? c.ink : c.muted,
                            ),
                          ),
                        ),
                        if (count != null)
                          Text(
                            '$count',
                            style: UiText.mono(11, color: c.faint),
                          ),
                      ],
                    ),
                  ),
                  if (more != null && expanded)
                    UiPressable(
                      onTap: onMore,
                      builder: (context, hover) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          more,
                          style:
                              UiText.sans(
                                11.5,
                                weight: FontWeight.w500,
                                color: c.accent,
                              ).copyWith(
                                decoration: hover
                                    ? TextDecoration.underline
                                    : null,
                                decorationColor: c.accent,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 5,
              children: [for (final b in shown) _pill(b)],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final searching = d.query.trim().isNotEmpty;

    final body = <Widget>[
      if (d.loading)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: UiSpinner(size: 18)),
        )
      else if (searching) ...[
        _section(
          key: const Key('dock-results'),
          icon: UiGlyph(UiGlyphs.search, size: 13, color: c.muted),
          title: l10n.blocks_searchResults,
          count: d.results.length,
          blocks: d.results,
        ),
        if (d.results.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Text(
              l10n.blocks_noResults,
              style: UiText.sans(12, color: c.faint),
            ),
          ),
      ] else if (d.total == 0)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
          child: Column(
            spacing: 10,
            children: [
              Icon(StudioIcons.promptBlocks, size: 28, color: c.faint),
              Text(
                l10n.blocks_dockEmpty,
                textAlign: TextAlign.center,
                style: UiText.sans(12.5, color: c.muted, height: 1.6),
              ),
              UiBtn(
                size: UiBtnSize.small,
                onTap: a.onCreate,
                children: [
                  const UiGlyph(UiGlyphs.plus, size: 13),
                  Text(l10n.blocks_newBlock),
                ],
              ),
            ],
          ),
        )
      else ...[
        if (d.favorites.isNotEmpty)
          _section(
            key: const Key('dock-favorites'),
            icon: UiGlyph(UiGlyphs.star, size: 13, filled: true, color: c.star),
            title: l10n.blocks_favorites,
            blocks: d.favorites,
          ),
        if (d.recent.isNotEmpty)
          _section(
            key: const Key('dock-recent'),
            icon: UiGlyph(UiGlyphs.clock, size: 13, color: c.muted),
            title: l10n.blocks_recent,
            blocks: d.recent,
          ),
        if ((d.favorites.isNotEmpty || d.recent.isNotEmpty) &&
            d.groups.isNotEmpty)
          Container(
            height: 1,
            margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            color: c.line,
          ),
        for (final g in [
          ...d.groups.where((group) => group.blocks.isNotEmpty),
          ...d.groups.where((group) => group.blocks.isEmpty),
        ])
          _section(
            key: Key('dock-group-${g.id}'),
            icon: UiGlyph(
              g.expanded ? UiGlyphs.chevronDown : UiGlyphs.chevronRight,
              size: 13,
              color: c.muted,
            ),
            title: g.name,
            count: g.count,
            blocks: g.blocks,
            expanded: g.expanded,
            onTitle: () => a.onToggleGroup(g.id, !g.expanded),
            more: d.filter.folderId == g.id ? null : l10n.blocks_allN(g.count),
            onMore: () => a.onFilterChanged(BlocksDockFilter.folder(g.id)),
          ),
        if (d.filter.favorites && d.favorites.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
            child: Text(
              l10n.blocks_noFavorites,
              style: UiText.sans(12, color: c.faint),
            ),
          ),
      ],
      const SizedBox(height: 10),
    ];

    final dock = Container(
      key: _key,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(right: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 4),
              child: Row(
                spacing: 6,
                children: [
                  Icon(StudioIcons.promptBlocks, size: 16, color: c.muted),
                  Text(
                    l10n.blocks_title,
                    style: UiText.sans(
                      13.5,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  _Count(d.total),
                  const Spacer(),
                  UiIconBox(
                    key: const Key('dock-create'),
                    glyph: UiGlyphs.plus,
                    glyphSize: 17,
                    size: 28,
                    tooltip: l10n.blocks_newBlock,
                    onTap: a.onCreate,
                  ),
                  UiIconBox(
                    key: const Key('dock-library'),
                    glyph: UiGlyphs.external,
                    size: 28,
                    tooltip: l10n.blocks_openLibrary,
                    onTap: a.onOpenLibrary,
                  ),
                  UiIconBox(
                    key: const Key('dock-close'),
                    glyph: UiGlyphs.close,
                    glyphSize: 16,
                    size: 28,
                    tooltip: l10n.blocks_close,
                    onTap: a.onClose,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: UiSearchField(
              key: const Key('dock-search'),
              value: d.query,
              height: 32,
              hint: l10n.blocks_searchHint,
              onChanged: a.onQueryChanged,
              trailing: d.rag.enabled ? BlocksRagBadge(data: d.rag) : null,
            ),
          ),
          _Chips(data: d, onChanged: a.onFilterChanged),
          Container(height: 1, color: c.line),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.depth == 0 &&
                    notification is ScrollUpdateNotification) {
                  _exit();
                }
                return false;
              },
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: body,
                ),
              ),
            ),
          ),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.blocks_dockHint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(11.5, color: c.faint),
            ),
          ),
        ],
      ),
    );

    return UiPopover(
      anchor: _menu,
      onDismiss: () => setState(() => _menu = null),
      builder: (_) => UiMenu(
        items: _menuItems,
        onClose: () => setState(() => _menu = null),
      ),
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _preview,
        child: dock,
      ),
    );
  }

  /// 按卡片实际尺寸与药丸居中对齐；靠近窗口边缘时避边并连接两者中线。
  Widget _preview(BuildContext context) {
    final b = _hover;
    final r = _hoverRect;
    final dockBox = _key.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (b == null || r == null || dockBox == null || overlay == null) {
      return const SizedBox.shrink();
    }
    final dockRight = overlay
        .globalToLocal(dockBox.localToGlobal(Offset(dockBox.size.width, 0)))
        .dx;
    final pill = Rect.fromPoints(
      overlay.globalToLocal(r.topLeft),
      overlay.globalToLocal(r.bottomRight),
    );
    final line = _PreviewLine();
    final reduce = MediaQuery.disableAnimationsOf(context);
    final c = context.ui;
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomMultiChildLayout(
          delegate: _PreviewLayout(
            pill: pill,
            dockRight: dockRight,
            line: line,
          ),
          children: [
            LayoutId(
              id: _PreviewPart.line,
              child: CustomPaint(
                key: const Key('dock-preview-connector'),
                painter: _DashPainter(c.strong, line),
              ),
            ),
            LayoutId(
              id: _PreviewPart.card,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(b.id),
                tween: Tween(begin: reduce ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(-4 * (1 - t), 0),
                    child: child,
                  ),
                ),
                child: SingleChildScrollView(
                  primary: false,
                  child: BlockHoverCard(b),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PreviewPart { card, line }

// Layout fills the endpoints before painting, using the measured card size.
class _PreviewLine {
  Offset start = Offset.zero;
  Offset end = Offset.zero;
}

class _PreviewLayout extends MultiChildLayoutDelegate {
  _PreviewLayout({
    required this.pill,
    required this.dockRight,
    required this.line,
  });
  final Rect pill;
  final double dockRight;
  final _PreviewLine line;

  @override
  void performLayout(Size size) {
    final card = layoutChild(
      _PreviewPart.card,
      BoxConstraints(
        maxWidth: math.min(300, math.max(0, size.width - 16)),
        maxHeight: math.max(0, size.height - 16),
      ),
    );
    final left = (dockRight + 10)
        .clamp(8.0, math.max(8.0, size.width - card.width - 8))
        .toDouble();
    final top = (pill.center.dy - card.height / 2)
        .clamp(8.0, math.max(8.0, size.height - card.height - 8))
        .toDouble();
    positionChild(_PreviewPart.card, Offset(left, top));
    line.start = Offset(pill.right, pill.center.dy);
    line.end = Offset(left, top + card.height / 2);
    layoutChild(_PreviewPart.line, BoxConstraints.tight(size));
    positionChild(_PreviewPart.line, Offset.zero);
  }

  @override
  bool shouldRelayout(_PreviewLayout old) =>
      old.pill != pill || old.dockRight != dockRight || old.line != line;
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.line);
  final Color color;
  final _PreviewLine line;
  Offset get start => line.start;
  Offset get end => line.end;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    final delta = end - start;
    final distance = delta.distance;
    if (distance == 0) return;
    final direction = delta / distance;
    for (var x = 0.0; x < distance; x += 6) {
      canvas.drawLine(
        start + direction * x,
        start + direction * math.min(distance, x + 3),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) =>
      old.color != color || old.line != line;
}

/// 标题旁的计数（原型 `.cnt`）：18 高、圆角 9、控件底、11 / w600。
class _Count extends StatelessWidget {
  const _Count(this.n);
  final int n;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 18,
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$n',
        style: UiText.sans(
          11,
          weight: FontWeight.w600,
          color: c.muted,
          height: 1.2,
        ),
      ),
    );
  }
}

/// 一行分类筛选（原型 `.fchip`）：26 高、圆角 13、12 号；选中是正文色实心 + 窗口底色字。
/// “全部”固定；其余标签由滚轮左右滑动，两端按剩余内容渐隐。
class _Chips extends StatefulWidget {
  const _Chips({required this.data, required this.onChanged});
  final BlocksDockViewData data;
  final ValueChanged<BlocksDockFilter> onChanged;

  @override
  State<_Chips> createState() => _ChipsState();
}

class _ChipsState extends State<_Chips> {
  final _scroll = ScrollController();
  bool _left = false;
  bool _right = false;
  bool _refreshPending = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_refresh);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted ||
        !_scroll.hasClients ||
        !_scroll.position.hasContentDimensions) {
      return;
    }
    final left = _scroll.position.extentBefore > .5;
    final right = _scroll.position.extentAfter > .5;
    if (left != _left || right != _right) {
      setState(() {
        _left = left;
        _right = right;
      });
    }
  }

  bool _metrics(ScrollMetricsNotification notification) {
    if (notification.depth == 0 && !_refreshPending) {
      _refreshPending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshPending = false;
        _refresh();
      });
    }
    return false;
  }

  void _wheel(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) return;
    final delta = event.scrollDelta.dx != 0
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if (delta == 0) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
      if (!mounted || !_scroll.hasClients) return;
      final current = _scroll.position;
      _scroll.jumpTo(
        (current.pixels + delta).clamp(
          current.minScrollExtent,
          current.maxScrollExtent,
        ),
      );
      (resolved as PointerScrollEvent).respond(allowPlatformDefault: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final onChanged = widget.onChanged;
    final c = context.ui;
    final l10n = context.l10n;
    Widget chip(BlocksDockFilter f, String label, {int? count, String? glyph}) {
      final on = data.filter == f;
      return UiPressable(
        key: Key('dock-chip-${f.favorites ? 'fav' : f.folderId ?? 'all'}'),
        onTap: () => onChanged(f),
        builder: (context, hover) => Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: on ? c.ink : (hover ? c.hover : null),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              if (glyph != null)
                UiGlyph(glyph, size: 12, color: on ? c.bg : c.muted),
              Text(
                label,
                style: UiText.sans(
                  12,
                  weight: on ? FontWeight.w600 : FontWeight.w400,
                  color: on ? c.bg : c.muted,
                  height: 1.2,
                ),
              ),
              if (count != null)
                Opacity(
                  opacity: .7,
                  child: Text(
                    '$count',
                    style: UiText.mono(
                      10.5,
                      color: on ? c.bg : c.muted,
                      height: 1.2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          chip(const BlocksDockFilter.all(), l10n.blocks_filterAll),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: UiVSep(key: Key('dock-chips-divider'), height: 14),
          ),
          Expanded(
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: _metrics,
              child: Listener(
                onPointerSignal: _wheel,
                child: ShaderMask(
                  key: const Key('dock-chips-fade'),
                  shaderCallback: (r) => LinearGradient(
                    colors: [
                      _left ? const Color(0x00000000) : const Color(0xFF000000),
                      const Color(0xFF000000),
                      const Color(0xFF000000),
                      _right
                          ? const Color(0x00000000)
                          : const Color(0xFF000000),
                    ],
                    stops: const [0, .08, .92, 1],
                  ).createShader(r),
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    key: const Key('dock-chips-scroll'),
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 2,
                      children: [
                        chip(
                          const BlocksDockFilter.favorites(),
                          l10n.blocks_favorites,
                          glyph: UiGlyphs.star,
                        ),
                        for (final ch in [
                          ...data.chips.where((chip) => chip.count != 0),
                          ...data.chips.where((chip) => chip.count == 0),
                        ])
                          chip(
                            BlocksDockFilter.folder(ch.id),
                            ch.name,
                            count: ch.count,
                          ),
                      ],
                    ),
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
