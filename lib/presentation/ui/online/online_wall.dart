import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'online_contract.dart';
import 'online_format.dart';
import 'online_page.dart';
import 'online_parts.dart';
import 'online_popovers.dart';

/// 卡片墙区域：墙 + 收藏页底部提示 + 多选操作条。
class OnlineWallArea extends StatelessWidget {
  const OnlineWallArea({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = OnlineScope.of(context);
    final data = scope.data;
    final localFav =
        data.mode == OnlineMode.favorites && data.status.favoritesLocal;
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(child: OnlineWall()),
            if (localFav && data.list.items.isNotEmpty)
              Container(
                key: const Key('online-drag-hint'),
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: OnlineNote(context.l10n.online_dragHint),
              ),
          ],
        ),
        if (scope.controller.picking)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 22,
            child: Center(child: OnlineSelectionBar()),
          ),
      ],
    );
  }
}

class _Slot {
  const _Slot(this.index, this.col, this.rect);

  /// 在 items 里的下标；< 0 是追加中的骨架。
  final int index;
  final int col;
  final Rect rect;
}

/// 瀑布流卡片墙：按可用宽度取整列，依次放进最矮的一列；只画视口附近的卡片。
class OnlineWall extends StatefulWidget {
  const OnlineWall({super.key});

  /// 方向键：在当前布局里找 [from] 的邻居（左右换列，上下同列）。
  static String? neighbor(
    BuildContext context,
    String? from,
    AxisDirection dir,
  ) => _OnlineWallState._current?._neighbor(from, dir);

  @override
  State<OnlineWall> createState() => _OnlineWallState();
}

class _OnlineWallState extends State<OnlineWall> {
  static _OnlineWallState? _current;

  ScrollController _scroll = ScrollController();
  String? _listKey;
  List<_Slot> _slots = const [];
  List<OnlineWork> _items = const [];
  String? _lastSelected;

  static const _skeletonAspects = [
    .68,
    1.46,
    .68,
    1.76,
    .68,
    1.0,
    .68,
    2.39,
    .68,
    1.46,
    .68,
    .77,
    .68,
    1.6,
    .68, //
  ];

  @override
  void initState() {
    super.initState();
    _current = this;
  }

  @override
  void dispose() {
    if (_current == this) _current = null;
    _scroll.dispose();
    super.dispose();
  }

  void _syncList(OnlineList list) {
    if (_listKey == list.key) return;
    _listKey = list.key;
    final old = _scroll;
    _scroll = ScrollController(initialScrollOffset: list.initialOffset)
      ..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  void _onScroll() {
    final scope = OnlineScope.of(context);
    final list = scope.data.list;
    final p = _scroll.position;
    if (list.hasMore &&
        !list.loading &&
        !list.loadingMore &&
        list.appendError == null &&
        p.maxScrollExtent - p.pixels < 200) {
      scope.actions.onLoadMore();
    }
  }

  String? _neighbor(String? from, AxisDirection dir) {
    final at = _slots.where((s) => s.index >= 0 && _items[s.index].key == from);
    if (at.isEmpty) return _items.isEmpty ? null : _items.first.key;
    final cur = at.first;
    final same = _slots.where((s) => s.index >= 0 && s.col == cur.col).toList();
    final i = same.indexOf(cur);
    _Slot? next;
    switch (dir) {
      case AxisDirection.up:
        next = i > 0 ? same[i - 1] : null;
      case AxisDirection.down:
        next = i < same.length - 1 ? same[i + 1] : null;
      case AxisDirection.left || AxisDirection.right:
        final col = cur.col + (dir == AxisDirection.left ? -1 : 1);
        final cands = _slots.where((s) => s.index >= 0 && s.col == col);
        if (cands.isNotEmpty) {
          next = cands.reduce(
            (a, b) =>
                (a.rect.center.dy - cur.rect.center.dy).abs() <=
                    (b.rect.center.dy - cur.rect.center.dy).abs()
                ? a
                : b,
          );
        }
    }
    return next == null ? from : _items[next.index].key;
  }

  void _reveal(String key, double viewport) {
    final slot = _slots
        .where((s) => s.index >= 0 && _items[s.index].key == key)
        .firstOrNull;
    if (slot == null || !_scroll.hasClients) return;
    final top = slot.rect.top + OnlineLayout.padding.top;
    final bottom = slot.rect.bottom + OnlineLayout.padding.top;
    final o = _scroll.offset;
    final target = top < o
        ? top - 8
        : bottom > o + viewport
        ? bottom - viewport + 8
        : null;
    if (target != null) {
      _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = OnlineScope.of(context);
    final data = scope.data;
    final list = data.list;
    _syncList(list);
    final small = data.cardSize == OnlineCardSize.small;

    if (list.error != null && list.items.isEmpty) {
      return _ErrorState(message: list.error!);
    }
    if (!list.loading && list.items.isEmpty) {
      return const OnlineEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - OnlineLayout.padding.horizontal;
        final cols = OnlineLayout.columns(width, data.cardSize);
        final cw = (width - (cols - 1) * OnlineLayout.gap) / cols;
        final ai = data.status.promptQuery;
        final items = list.loading ? const <OnlineWork>[] : list.items;
        final skeletons = list.loading
            ? _skeletonAspects
            : (list.loadingMore
                  ? List<double>.filled(cols * 2, .75)
                  : const <double>[]);
        final aspects = [for (final w in items) w.aspect, ...skeletons];
        final capEst = OnlineLayout.captionEstimate(aiTag: ai, small: small);
        final cap = OnlineLayout.captionHeight(aiTag: ai, small: small);
        final estimates = [
          for (final a in aspects) OnlineLayout.imageHeight(cw, a) + capEst,
        ];
        final assigned = OnlineLayout.assign(estimates, cols);
        final slots = <_Slot>[];
        var height = 0.0;
        for (final (col, idx) in assigned.indexed) {
          var y = 0.0;
          for (final i in idx) {
            final h = OnlineLayout.imageHeight(cw, aspects[i]) + cap;
            slots.add(
              _Slot(
                i < items.length ? i : -(i - items.length) - 1,
                col,
                Rect.fromLTWH(col * (cw + OnlineLayout.gap), y, cw, h),
              ),
            );
            y += h + OnlineLayout.gap;
          }
          height = math.max(height, y - OnlineLayout.gap);
        }
        _slots = slots;
        _items = items;
        final viewport = constraints.maxHeight;
        if (data.selectedKey != _lastSelected) {
          _lastSelected = data.selectedKey;
          final key = data.selectedKey;
          if (key != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => mounted ? _reveal(key, viewport) : null,
            );
          }
        }

        final footer = <Widget>[
          if (list.appendError case final e?)
            _AppendError(error: e)
          else if (!list.hasMore && !list.loading && items.isNotEmpty)
            _EndLine(count: items.length, blocked: list.blocked),
        ];

        return NotificationListener<ScrollEndNotification>(
          onNotification: (n) {
            scope.actions.onScrollOffset(n.metrics.pixels);
            return false;
          },
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: !list.loading),
            child: SingleChildScrollView(
              key: const Key('online-wall'),
              controller: _scroll,
              physics: list.loading
                  ? const NeverScrollableScrollPhysics()
                  : null,
              padding: OnlineLayout.padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: height,
                    child: AnimatedBuilder(
                      animation: _scroll,
                      builder: (context, _) {
                        final o = _scroll.hasClients ? _scroll.offset : 0.0;
                        final lo = o - 600, hi = o + viewport + 600;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (final s in slots)
                              if (s.rect.bottom >= lo && s.rect.top <= hi)
                                Positioned.fromRect(
                                  key: ValueKey(
                                    s.index >= 0
                                        ? items[s.index].key
                                        : 'skeleton${s.index}',
                                  ),
                                  rect: s.rect,
                                  child: s.index >= 0
                                      ? OnlineCard(
                                          work: items[s.index],
                                          imageHeight: s.rect.height - cap,
                                          small: small,
                                        )
                                      : _SkeletonCard(
                                          imageHeight: s.rect.height - cap,
                                          caption: !small,
                                          aiTag: ai,
                                        ),
                                ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (footer.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ...footer,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 一张卡片：图片按原图比例 + 下面的文字区。悬停出底部操作条，单击选中，双击打开大图，右键菜单。
class OnlineCard extends StatefulWidget {
  const OnlineCard({
    super.key,
    required this.work,
    required this.imageHeight,
    required this.small,
  });

  final OnlineWork work;
  final double imageHeight;
  final bool small;

  @override
  State<OnlineCard> createState() => _OnlineCardState();
}

class _OnlineCardState extends State<OnlineCard> {
  var _hover = false;
  DateTime? _lastTap;

  void _tap(OnlineScope scope) {
    final w = widget.work;
    final ctrl = scope.controller;
    if (ctrl.picking) {
      ctrl.togglePick(w.key);
      return;
    }
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!) < const Duration(milliseconds: 320)) {
      _lastTap = null;
      ctrl.openViewer(w.key);
      return;
    }
    _lastTap = now;
    if (scope.data.selectedKey != w.key) scope.actions.onSelect(w.key);
  }

  List<OnlineMenuItem> _menu(BuildContext context, OnlineScope scope) {
    final l10n = context.l10n;
    final w = widget.work;
    final a = scope.actions;
    final s = scope.data.status;
    final fav = scope.data.favorites;
    final localFav =
        scope.data.mode == OnlineMode.favorites && s.favoritesLocal;
    return [
      OnlineMenuItem(
        glyph: UiGlyphs.external,
        label: l10n.online_openInBrowser,
        onTap: () => a.onOpenInBrowser(w.key),
      ),
      OnlineMenuItem(
        glyph: UiGlyphs.download,
        label: w.mediaCount > 1
            ? l10n.online_downloadAll(w.mediaCount)
            : l10n.online_download,
        onTap: () => a.onDownload([w.key], all: true),
      ),
      OnlineMenuItem(
        glyph: UiGlyphs.copy,
        label: s.promptQuery ? l10n.online_copyPrompt : l10n.online_copyTags,
        onTap: () => a.onCopyPrompt([w.key]),
      ),
      if (w.author != null && s.promptQuery)
        OnlineMenuItem(
          glyph: UiGlyphs.user,
          label: l10n.online_onlyAuthor,
          onTap: () => a.onOnlyAuthor(w.key),
        ),
      if (localFav && fav != null) ...[
        for (final (i, col) in [
          (OnlineFavorites.ungroupedId, l10n.online_ungrouped),
          for (final c in fav.collections) (c.id, c.name),
        ].indexed)
          OnlineMenuItem(
            glyph: i == 0 ? UiGlyphs.move : null,
            label: i == 0 ? '${l10n.online_moveTo} · ${col.$2}' : col.$2,
            divider: i == 0,
            onTap: () => a.onMoveToCollection([w.key], col.$1),
          ),
      ],
      if (w.favorited && s.favoritesWritable)
        OnlineMenuItem(
          glyph: UiGlyphs.heartLib,
          label: l10n.online_unfavorite,
          danger: true,
          divider: true,
          onTap: () => a.onToggleFavorite(w.key),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = OnlineScope.of(context);
    final data = scope.data;
    final ctrl = scope.controller;
    final w = widget.work;
    final picking = ctrl.picking;
    final picked = ctrl.picked.contains(w.key);
    final selected = !picking && data.selectedKey == w.key;
    final hover = _hover && !picking;
    final rank = data.mode == OnlineMode.ranking ? w.rank : null;
    final reduce =
        data.reducedMotion || MediaQuery.disableAnimationsOf(context);
    // 收藏页里每张都是已收藏，不再画心形角标。
    final favMark =
        w.favorited &&
        !picking &&
        w.rating == null &&
        data.mode != OnlineMode.favorites;

    final badges = <Widget>[
      if (rank != null)
        Positioned(
          left: 7,
          top: 7,
          child: OnlineBadge(
            text: '$rank',
            minWidth: 26,
            color: OnlinePalette.rank(rank),
          ),
        ),
      if (picking)
        Positioned(left: 7, top: 7, child: _PickMark(on: picked))
      else if (w.mediaLabel != null && rank == null)
        Positioned(left: 7, top: 7, child: OnlineBadge(text: w.mediaLabel!)),
      if (w.rating != null)
        Positioned(right: 7, top: 7, child: OnlineRatingBadge(w.rating!))
      else if (w.mediaCount > 1)
        Positioned(
          right: favMark ? null : 7,
          left: favMark ? 7 : null,
          top: 7,
          child: OnlineBadge(text: '${w.mediaCount}', glyph: UiGlyphs.layers),
        ),
      if (favMark) const Positioned(right: 7, top: 7, child: _FavMark()),
    ];

    final image = AnimatedContainer(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 120),
      height: widget.imageHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          if (selected) ...[
            BoxShadow(color: c.accent.withValues(alpha: .16), spreadRadius: 5),
            BoxShadow(color: c.accent, spreadRadius: 2),
          ] else if (hover)
            BoxShadow(
              color: Colors.black.withValues(alpha: c.dark ? .45 : .14),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: c.control),
            if (w.thumb != null)
              Image(
                image: w.thumb!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: c.ink.withValues(alpha: .07)),
              ),
            ),
            ...badges,
            if (hover) ...[
              Positioned(
                left: 7,
                bottom: 47,
                child: OnlineBadge(
                  text: [
                    if (w.model != null) w.model!,
                    if (w.width > 0) '${w.width}×${w.height}',
                  ].join(' · '),
                ),
              ),
              Positioned(
                left: 7,
                right: 7,
                bottom: 7,
                child: _HoverBar(work: w, menu: () => _menu(context, scope)),
              ),
            ],
          ],
        ),
      ),
    );

    Widget card = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: Key('online-card-${w.key}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _tap(scope),
        onSecondaryTapUp: (d) => ctrl.openMenu(
          UiPopoverAnchor(d.globalPosition),
          _menu(context, scope),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            image,
            if (!widget.small) _Caption(work: w),
          ],
        ),
      ),
    );

    if (data.mode == OnlineMode.favorites && data.status.favoritesLocal) {
      final keys = picking && picked ? ctrl.picked.toList() : [w.key];
      card = Draggable<List<String>>(
        data: keys,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: _DragFeedback(work: w, count: keys.length),
        childWhenDragging: Opacity(opacity: .4, child: card),
        child: card,
      );
    }
    return card;
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.work});
  final OnlineWork work;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final w = work;
    Widget stat(String? glyph, String text, {double stroke = 1.8}) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 3,
      children: [
        if (glyph != null)
          UiGlyph(glyph, size: 11, color: c.faint, strokeWidth: stroke),
        Text(text, style: UiText.mono(10.5, color: c.faint, height: 1.5)),
      ],
    );
    final ai = w.isAiTag;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ai)
            SizedBox(
              height: 17.5,
              child: Text(
                w.title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(
                  12.5,
                  weight: FontWeight.w600,
                  color: c.ink,
                  height: 1.4,
                ),
              ),
            ),
          SizedBox(
            height: ai ? 17.25 : 14,
            child: Row(
              spacing: 8,
              children: ai
                  ? [
                      Expanded(
                        child: Text(
                          w.author ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(11.5, color: c.muted, height: 1.5),
                        ),
                      ),
                      if (w.views != null)
                        stat(UiGlyphs.eye, OnlineFormat.count(w.views!)),
                      if (w.favorites != null)
                        stat(
                          UiGlyphs.heartLib,
                          OnlineFormat.count(w.favorites!),
                        ),
                    ]
                  : [
                      if (w.score != null)
                        stat(UiGlyphs.chevronUp, '${w.score}', stroke: 2.4),
                      if (w.favorites != null)
                        stat(UiGlyphs.heartLib, '${w.favorites}'),
                      const Spacer(),
                      stat(null, '#${w.id}'),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverBar extends StatelessWidget {
  const _HoverBar({required this.work, required this.menu});
  final OnlineWork work;
  final List<OnlineMenuItem> Function() menu;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final a = scope.actions;
    final s = scope.data.status;
    Widget btn(
      Widget child, {
      required VoidCallback? onTap,
      bool primary = false,
      String? tip,
      Key? key,
    }) {
      final b = UiPressable(
        key: key,
        onTap: onTap,
        builder: (context, hover) => Container(
          height: 28,
          width: primary ? null : 28,
          alignment: primary ? null : Alignment.center,
          padding: primary ? const EdgeInsets.symmetric(horizontal: 8) : null,
          decoration: BoxDecoration(
            color: primary
                ? (hover ? Color.lerp(c.brand, Colors.black, .08) : c.brand)
                : (hover ? Colors.white.withValues(alpha: .14) : null),
            borderRadius: BorderRadius.circular(6),
          ),
          child: child,
        ),
      );
      return tip == null ? b : Tooltip(message: tip, child: b);
    }

    return OnlineFrosted(
      radius: 9,
      color: const Color(0xCC121212),
      child: SizedBox(
        height: 34,
        child: LayoutBuilder(
          builder: (context, box) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Row(
              spacing: 2,
              children: [
                Builder(
                  builder: (ctx) => btn(
                    key: const Key('online-card-send'),
                    primary: true,
                    onTap: () {
                      final box = ctx.findRenderObject()! as RenderBox;
                      scope.controller.requestSend(
                        work.key,
                        UiPopoverAnchor(
                          box.localToGlobal(const Offset(-4, -8)),
                          alignBottom: true,
                        ),
                      );
                    },
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 5,
                      children: [
                        const UiGlyph(
                          UiGlyphs.send,
                          size: 13,
                          color: Colors.white,
                        ),
                        Text(
                          l10n.online_send,
                          maxLines: 1,
                          style: UiText.sans(
                            12,
                            weight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (s.favoritesWritable)
                  btn(
                    key: const Key('online-card-fav'),
                    tip: work.favorited
                        ? l10n.online_unfavorite
                        : l10n.online_favorite,
                    onTap: () => a.onToggleFavorite(work.key),
                    UiGlyph(
                      UiGlyphs.heartLib,
                      size: 14,
                      filled: work.favorited,
                      color: work.favorited ? c.fav : Colors.white,
                    ),
                  ),
                // 窄卡片（小于 200）放不下，复制留在 ⋯ 菜单和 Ctrl+C 里。
                if (box.maxWidth >= 200)
                  btn(
                    key: const Key('online-card-copy'),
                    tip: s.promptQuery
                        ? l10n.online_copyPrompt
                        : l10n.online_copyTags,
                    onTap: () => a.onCopyPrompt([work.key]),
                    const UiGlyph(UiGlyphs.copy, size: 14, color: Colors.white),
                  ),
                const Spacer(),
                Builder(
                  builder: (ctx) => btn(
                    key: const Key('online-card-more'),
                    tip: l10n.online_more,
                    onTap: () {
                      final box = ctx.findRenderObject()! as RenderBox;
                      scope.controller.openMenu(
                        UiPopoverAnchor(
                          box.localToGlobal(
                            box.size.bottomLeft(const Offset(0, 6)),
                          ),
                        ),
                        menu(),
                      );
                    },
                    const UiGlyph(
                      UiGlyphs.more,
                      size: 15,
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavMark extends StatelessWidget {
  const _FavMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Color(0xF0FFFFFF),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: UiGlyph(
      UiGlyphs.heartLib,
      size: 13,
      filled: true,
      color: context.ui.fav,
    ),
  );
}

class _PickMark extends StatelessWidget {
  const _PickMark({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? c.accent : const Color(0x38000000),
        shape: BoxShape.circle,
        border: Border.all(color: on ? c.accent : Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: on
          ? const UiGlyph(
              UiGlyphs.check,
              size: 12,
              strokeWidth: 3,
              color: Colors.white,
            )
          : null,
    );
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.work, required this.count});
  final OnlineWork work;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Transform.rotate(
      angle: -4 * math.pi / 180,
      child: Container(
        width: 96,
        height: 96 / work.aspect.clamp(.5, 1.6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.control,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.dark ? .45 : .14),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (work.thumb != null)
              Opacity(
                opacity: .92,
                child: Image(image: work.thumb!, fit: BoxFit.cover),
              ),
            if (count > 1)
              Positioned(
                right: 7,
                top: 7,
                child: OnlineBadge(text: '$count', color: c.accent),
              ),
          ],
        ),
      ),
    );
  }
}

/// 骨架卡片：按比例的图片块 + 两条文字线，1.2 秒闪烁一轮（减少动态效果时静止）。
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({
    required this.imageHeight,
    required this.caption,
    required this.aiTag,
  });
  final double imageHeight;
  final bool caption;
  final bool aiTag;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      OnlineShimmer(height: imageHeight, radius: 9),
      if (caption) ...[
        const SizedBox(height: 7),
        const FractionallySizedBox(
          widthFactor: .7,
          child: OnlineShimmer(height: 10, radius: 5),
        ),
        if (aiTag) ...[
          const SizedBox(height: 6),
          const FractionallySizedBox(
            widthFactor: .45,
            child: OnlineShimmer(height: 10, radius: 5),
          ),
        ],
      ],
    ],
  );
}

class OnlineShimmer extends StatefulWidget {
  const OnlineShimmer({super.key, required this.height, required this.radius});
  final double height;
  final double radius;

  @override
  State<OnlineShimmer> createState() => _OnlineShimmerState();
}

class _OnlineShimmerState extends State<OnlineShimmer>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
    value: .3,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = .3;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * 2.2 - 1.1;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - t, -.2),
              end: Alignment(1 - t, .2),
              colors: [c.control, c.hover, c.control],
              stops: const [.25, .45, .65],
            ),
          ),
        );
      },
    );
  }
}

class _AppendError extends StatelessWidget {
  const _AppendError({required this.error});
  final OnlineAppendError error;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    return Container(
      key: const Key('online-append-error'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.error.withValues(alpha: .06),
        border: Border.all(color: c.error.withValues(alpha: .22)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        children: [
          UiGlyph(UiGlyphs.alert, size: 15, color: c.error),
          Flexible(
            child: Text(
              l10n.online_appendError(error.page, error.reason),
              style: UiText.sans(13, color: c.error),
            ),
          ),
          UiBtn(
            key: const Key('online-retry-page'),
            size: UiBtnSize.small,
            color: c.error,
            onTap: OnlineScope.of(context).actions.onRetryPage,
            children: [
              const UiGlyph(UiGlyphs.refresh, size: 13),
              Text(l10n.online_retryPage),
            ],
          ),
        ],
      ),
    );
  }
}

class _EndLine extends StatelessWidget {
  const _EndLine({required this.count, required this.blocked});
  final int count;
  final int? blocked;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    Widget line() => Container(width: 120, height: 1, color: c.line);
    return Row(
      key: const Key('online-end'),
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 10,
      children: [
        line(),
        Text(
          blocked != null && blocked! > 0
              ? l10n.online_endBlocked(count, blocked!)
              : l10n.online_end(count),
          style: UiText.sans(12, color: c.faint),
        ),
        line(),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    return Center(
      child: Column(
        key: const Key('online-error'),
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          UiGlyph(UiGlyphs.alert, size: 30, color: c.error),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              l10n.online_loadError(message),
              textAlign: TextAlign.center,
              style: UiText.sans(13, color: c.muted),
            ),
          ),
          UiBtn(
            key: const Key('online-retry'),
            onTap: OnlineScope.of(context).actions.onRetry,
            children: [
              const UiGlyph(UiGlyphs.refresh, size: 14),
              Text(l10n.online_retry),
            ],
          ),
        ],
      ),
    );
  }
}

/// 没结果：按当前筛选给出能直接点的放宽建议。收藏为空时说怎么收藏。
class OnlineEmptyState extends StatelessWidget {
  const OnlineEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    final f = data.filters;
    final q = data.query;
    final s = data.status;
    final fav = data.mode == OnlineMode.favorites;
    final query = s.promptQuery
        ? [q.work, q.prompt].where((x) => x.isNotEmpty).join(', ')
        : q.tags.join(' ');
    final suggestions = fav
        ? const <Widget>[]
        : [
            if (s.promptQuery && f.naiOnly)
              _sug(l10n.online_sugNaiOff, () => a.onNaiOnlyChanged(false)),
            if (s.promptQuery && q.prompt.isNotEmpty)
              _sug(
                l10n.online_sugClearPrompt,
                () => a.onSearch(OnlineQuery(work: q.work, fuzzy: q.fuzzy)),
              ),
            if (s.promptQuery &&
                data.mode == OnlineMode.search &&
                f.timeRange != 'all')
              _sug(l10n.online_sugAllTime, () => a.onTimeRangeChanged('all')),
            if (s.promptQuery && f.model != null)
              _sug(l10n.online_sugAllModels, () => a.onModelChanged(null)),
            if (s.ratings && f.ratings.length < OnlineRating.values.length)
              _sug(
                l10n.online_sugAllRatings,
                () => a.onRatingsChanged(OnlineRating.values.toSet()),
              ),
            if (s.dateRange && f.dateRange != null)
              _sug(l10n.online_sugNoDate, () => a.onDateRangeChanged(null)),
          ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
      child: Align(
        alignment: const Alignment(0, -.4),
        child: OnlineDashedBox(
          key: const Key('online-empty'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              UiGlyph(
                fav ? UiGlyphs.heartLib : UiGlyphs.search,
                size: 30,
                color: c.faint,
              ),
              Text(
                fav
                    ? l10n.online_favEmpty
                    : query.isEmpty
                    ? l10n.online_emptyTitleNoQuery
                    : l10n.online_emptyTitle(query),
                textAlign: TextAlign.center,
                style: UiText.sans(15, weight: FontWeight.w700, color: c.ink),
              ),
              Text(
                fav ? l10n.online_favEmptyHint : l10n.online_emptyHint,
                style: UiText.sans(12, color: c.muted),
              ),
              if (suggestions.isNotEmpty)
                Wrap(spacing: 8, runSpacing: 8, children: suggestions),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _sug(String label, VoidCallback onTap) =>
      UiBtn(size: UiBtnSize.small, onTap: onTap, children: [Text(label)]);
}

/// Danbooru / Gelbooru 收藏要登录：说清为什么、去哪拿 API Key。
class OnlineLoginState extends StatelessWidget {
  const OnlineLoginState({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final source = scope.data.source;
    final a = scope.actions;
    final danbooru = source == OnlineSource.danbooru;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Container(
            key: const Key('online-login'),
            width: 520,
            padding: const EdgeInsets.fromLTRB(36, 40, 36, 32),
            decoration: BoxDecoration(
              color: c.panel,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              spacing: 12,
              children: [
                OnlineSourceMark(source, size: 56),
                Text(
                  danbooru
                      ? l10n.online_loginDbTitle
                      : l10n.online_loginGbTitle,
                  textAlign: TextAlign.center,
                  style: UiText.sans(18, weight: FontWeight.w700, color: c.ink),
                ),
                Text(
                  danbooru ? l10n.online_loginDbDesc : l10n.online_loginGbDesc,
                  textAlign: TextAlign.center,
                  style: UiText.sans(13, color: c.muted, height: 1.6),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      UiBtn(
                        key: const Key('online-login-go'),
                        size: UiBtnSize.large,
                        tone: UiBtnTone.primary,
                        onTap: () => a.onLogin(source),
                        children: [
                          const UiGlyph(UiGlyphs.login, size: 15),
                          Text(
                            danbooru
                                ? l10n.online_loginDb
                                : l10n.online_loginGb,
                          ),
                        ],
                      ),
                      UiBtn(
                        key: const Key('online-login-help'),
                        size: UiBtnSize.large,
                        onTap: () => a.onApiKeyHelp(source),
                        children: [
                          const UiGlyph(UiGlyphs.external, size: 15),
                          Text(l10n.online_apiKeyHelp),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 520,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: c.panel,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                UiGlyph(UiGlyphs.infoCircle, size: 15, color: c.muted),
                Expanded(
                  child: Text(
                    l10n.online_loginOther,
                    style: UiText.sans(12, color: c.muted, height: 1.55),
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
