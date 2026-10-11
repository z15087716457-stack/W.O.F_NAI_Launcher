import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'explore_contract.dart';
import 'explore_format.dart';
import 'explore_page.dart';
import 'explore_parts.dart';

/// 卡片下方画师串的高度（2 行 11.5 / 1.45 + 上 6）。
const _captionHeight = 6.0 + 11.5 * 1.45 * 2 + 1;

/// 候选墙每行几张：大卡最窄 180、小卡最窄 120，列距 12。
int exploreColumns(double width, ExploreCardSize size) {
  final min = size == ExploreCardSize.large ? 180.0 : 120.0;
  return math.max(2, ((width + 12) / (min + 12)).floor());
}

/// 候选墙：按轮分组（默认新的在上），每轮一个标题行 + 卡片网格（按需构建）。
class ExploreWall extends StatelessWidget {
  const ExploreWall({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final ctrl = scope.controller;
    final run = scope.data.run!;
    final visible = ctrl.visibleKeys.toSet();
    final byKey = {for (final x in run.candidates) x.key: x};
    final rounds = [
      for (final r in run.rounds)
        if (r.kind == ExploreRoundKind.basic) r,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final ordered = ctrl.newestFirst ? rounds.reversed.toList() : rounds;

    if (visible.isEmpty) {
      return Center(
        key: const Key('explore-wall-empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            UiGlyph(UiGlyphs.inbox, size: 30, color: c.faint),
            Text(l.explore_filterEmpty, style: UiText.sans(13, color: c.muted)),
            UiBtn(
              key: const Key('explore-filter-reset'),
              onTap: () => ctrl.setFilter(ExploreFilter.all),
              children: [Text(l.explore_showAll)],
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, box) {
        final inner = box.maxWidth - 28;
        final cols = exploreColumns(inner, scope.data.cardSize);
        ctrl.columns = cols;
        final w = (inner - 12 * (cols - 1)) / cols;
        final slivers = <Widget>[];
        for (final r in ordered) {
          final keys = [
            for (final k in r.keys)
              if (visible.contains(k)) k,
          ];
          if (keys.isEmpty) continue;
          final first = byKey[keys.first];
          final aspect = first?.aspect ?? 832 / 1216;
          slivers
            ..add(SliverToBoxAdapter(child: _RoundHeader(round: r)))
            ..add(
              SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 14,
                  mainAxisExtent: w / aspect + _captionHeight,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => ExploreCard(
                    key: ValueKey(keys[i]),
                    candidate: byKey[keys[i]]!,
                  ),
                  childCount: keys.length,
                ),
              ),
            );
        }
        return Scrollbar(
          child: CustomScrollView(
            key: const Key('explore-wall'),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  4,
                  14,
                  ctrl.selecting ? 84 : 18,
                ),
                sliver: SliverMainAxisGroup(slivers: slivers),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 轮标题（原型 `.rh`）：上 14 下 10、间距 10；“第 3 轮”13 / w700 · 时间和张数 12 次要色 · 细线 · 挑几张去进化。
class _RoundHeader extends StatelessWidget {
  const _RoundHeader({required this.round});
  final ExploreRound round;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final run = scope.data.run!;
    final ctrl = scope.controller;
    final cands = [
      for (final k in round.keys)
        if (run.candidate(k) case final x?) x,
    ];
    final failed = cands
        .where((x) => x.state == ExploreCandidateState.failed)
        .length;
    final p = run.progress;
    final live = p != null && p.round == round.number;
    final meta = [
      ExploreFormat.when(context, round.createdAt, scope.data.now),
      l.explore_count(round.keys.length),
      if (live) l.explore_generatingShort(p.done, p.total),
    ].join(' · ');
    return Padding(
      key: Key('explore-round-${round.id}'),
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
      child: Row(
        spacing: 10,
        children: [
          Text(
            l.explore_round(round.number),
            style: UiText.sans(13, weight: FontWeight.w700, color: c.ink),
          ),
          Text(meta, style: UiText.sans(12, color: live ? c.accent : c.muted)),
          if (failed > 0)
            UiPressable(
              key: Key('explore-retry-${round.id}'),
              onTap: scope.actions.onRetryFailed,
              builder: (context, hover) => Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  UiGlyph(UiGlyphs.alert, size: 13, color: c.error),
                  Text(
                    l.explore_failedRetry(failed),
                    style: UiText.sans(12, color: c.error).copyWith(
                      decoration: hover ? TextDecoration.underline : null,
                      decorationColor: c.error,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: Container(height: 1, color: c.line)),
          if (!ctrl.selecting)
            UiBtn(
              key: Key('explore-pick-${round.id}'),
              tone: UiBtnTone.ghost,
              size: UiBtnSize.small,
              tooltip: l.explore_pickTip,
              onTap: () => ctrl.setSelected([
                for (final x in cands)
                  if (x.favorite && x.done) x.key,
              ]),
              children: [
                UiGlyph(UiGlyphs.evo, size: 13, color: c.evo),
                Text(l.explore_pick),
              ],
            ),
        ],
      ),
    );
  }
}

/// 候选右键 / “更多”菜单：大图 · 收藏 · 进化 · 存为块 · 套用 · 复制 │ 分组（勾选）· 新分组 · 移出 │ 删除。
List<UiMenuItem> exploreCandidateMenu(
  BuildContext context,
  ExploreCandidate x, {
  bool detail = true,
}) {
  final l = context.l10n;
  final scope = ExploreScope.of(context);
  final ctrl = scope.controller;
  final a = scope.actions;
  final run = scope.data.run!;
  final keys = ctrl.selecting && ctrl.selected.contains(x.key)
      ? [...ctrl.selected]
      : [x.key];
  final single = keys.length == 1;
  return [
    if (detail && single)
      UiMenuItem(
        label: l.explore_openLarge,
        glyph: UiGlyphs.expand,
        trailing: 'Enter',
        onTap: () => ctrl.openDetail(x.key),
      ),
    UiMenuItem(
      label: x.favorite ? l.explore_unfavorite : l.explore_favorite,
      glyph: UiGlyphs.heartLib,
      trailing: 'F',
      onTap: () => a.onSetFavorite(keys, !x.favorite),
    ),
    UiMenuItem(
      label: l.explore_addToEvolution,
      glyph: UiGlyphs.evo,
      trailing: 'E',
      onTap: () => ctrl.startEvolution(keys),
    ),
    UiMenuItem(
      label: l.explore_saveBlock,
      glyph: UiGlyphs.archive,
      onTap: () => ctrl.saveBlock(keys),
    ),
    if (single)
      UiMenuItem(
        label: l.explore_applyToEditor,
        glyph: UiGlyphs.enter,
        onTap: () => a.onApplyToEditor(x.key),
      ),
    UiMenuItem(
      label: l.explore_copyArtists,
      glyph: UiGlyphs.copy,
      trailing: 'Ctrl C',
      onTap: () => a.onCopyArtists(keys),
    ),
    for (final (i, g) in run.groups.indexed)
      UiMenuItem(
        key: Key('explore-menu-group-${g.id}'),
        label: g.name,
        glyph: UiGlyphs.folder,
        divider: i == 0,
        checked: x.groupId == g.id,
        trailing: i < 9 ? '${i + 1}' : null,
        onTap: () => a.onAssignGroup(keys, x.groupId == g.id ? null : g.id),
      ),
    UiMenuItem(
      key: const Key('explore-menu-new-group'),
      label: l.explore_newGroup,
      glyph: UiGlyphs.folderPlus,
      divider: run.groups.isEmpty,
      onTap: () => ctrl.beginAddGroup(keys),
    ),
    if (x.groupId != null)
      UiMenuItem(
        label: l.explore_ungroup,
        glyph: UiGlyphs.inbox,
        trailing: '0',
        onTap: () => a.onAssignGroup(keys, null),
      ),
    UiMenuItem(
      key: const Key('explore-menu-delete'),
      label: single ? l.explore_delete : l.explore_deleteN(keys.length),
      glyph: UiGlyphs.trash,
      danger: true,
      divider: true,
      trailing: 'Del',
      onTap: () => ctrl.delete(keys),
    ),
  ];
}

/// 候选卡：图（圆角 8、控件底）+ 2 行画师串。悬停出底部操作条和左上角勾选圈；
/// 单击看检查器，0.3 秒内再点一次开大图，Ctrl / Shift 单击多选，右键菜单。
class ExploreCard extends StatefulWidget {
  const ExploreCard({super.key, required this.candidate});
  final ExploreCandidate candidate;

  @override
  State<ExploreCard> createState() => _ExploreCardState();
}

class _ExploreCardState extends State<ExploreCard> {
  var _hover = false;
  DateTime? _lastTap;

  void _tap() {
    final scope = ExploreScope.of(context);
    final ctrl = scope.controller;
    final x = widget.candidate;
    final hw = HardwareKeyboard.instance;
    if (hw.isShiftPressed && x.done) return ctrl.selectRange(x.key);
    if ((hw.isControlPressed || hw.isMetaPressed || ctrl.selecting) && x.done) {
      return ctrl.toggleSelect(x.key);
    }
    final now = DateTime.now();
    final again =
        _lastTap != null &&
        now.difference(_lastTap!) < const Duration(milliseconds: 300);
    _lastTap = now;
    if (again && ctrl.focusKey == x.key) {
      _lastTap = null;
      ctrl.openDetail(x.key);
    } else {
      ctrl.focus(x.key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final ctrl = scope.controller;
    final x = widget.candidate;
    final focused = ctrl.focusKey == x.key && !ctrl.selecting;
    final selected = ctrl.selected.contains(x.key);
    final group = scope.data.run!.groups
        .where((g) => g.id == x.groupId)
        .firstOrNull;
    final showHover = _hover && x.done;

    final Widget image = switch (x.state) {
      ExploreCandidateState.done => ExploreImage(x.thumb ?? x.image),
      ExploreCandidateState.pending => _StateFace(
        glyph: UiGlyphs.dice,
        color: c.faint,
        text: l.explore_queued(x.number),
      ),
      ExploreCandidateState.running => _Running(number: x.number),
      ExploreCandidateState.failed => Tooltip(
        message: x.error ?? l.explore_failed,
        child: _StateFace(
          glyph: UiGlyphs.alert,
          color: c.error,
          text: l.explore_failed,
          sub: l.explore_failedHover,
          background: Color.alphaBlend(
            c.error.withValues(alpha: .08),
            c.control,
          ),
        ),
      ),
    };

    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ColoredBox(
                    color: c.control,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        image,
                        if (selected)
                          ColoredBox(color: c.accent.withValues(alpha: .14)),
                        if (x.done && (x.favorite || showHover))
                          Positioned(
                            top: 6,
                            right: 6,
                            child: _Heart(candidate: x),
                          ),
                        if (x.done && (ctrl.selecting || showHover || selected))
                          Positioned(
                            top: 6,
                            left: 6,
                            child: _Check(
                              key: Key('explore-check-${x.key}'),
                              on: selected,
                              onTap: () => ctrl.toggleSelect(x.key),
                            ),
                          ),
                        if (!showHover && x.inEvolution)
                          Positioned(
                            left: 6,
                            bottom: 6,
                            child: Tooltip(
                              message: l.explore_parentTip,
                              child: Container(
                                width: 20,
                                height: 20,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: c.evo,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: UiGlyph(
                                  UiGlyphs.evo,
                                  size: 12,
                                  strokeWidth: 2.2,
                                  color: c.onEvo,
                                ),
                              ),
                            ),
                          ),
                        if (!showHover && group != null)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: _Badge(
                              glyph: UiGlyphs.folder,
                              text: group.name,
                              background: const Color(0xE0FFFFFF),
                              ink: const Color(0xFF222222),
                            ),
                          ),
                        if (showHover && !ctrl.selecting)
                          Positioned(
                            left: 6,
                            right: 6,
                            bottom: 6,
                            child: _HoverBar(candidate: x),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (focused || selected)
                Positioned(
                  left: -4,
                  top: -4,
                  right: -4,
                  bottom: -4,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: c.accent, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: _captionHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
            child: x.done
                ? ExploreArtistsText(x.atoms, empty: l.explore_noArtists)
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        key: Key('explore-card-${x.key}'),
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        onSecondaryTapUp: (d) => ctrl.openMenu(
          UiPopoverAnchor(d.globalPosition),
          exploreCandidateMenu(context, x),
        ),
        child: card,
      ),
    );
  }
}

/// 排队 / 失败的卡面：图标 22 + 一行字 12（+ 一行 11 弱色）。
class _StateFace extends StatelessWidget {
  const _StateFace({
    required this.glyph,
    required this.color,
    required this.text,
    this.sub,
    this.background,
  });
  final String glyph;
  final Color color;
  final String text;
  final String? sub;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return ColoredBox(
      color: background ?? c.control,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            UiGlyph(glyph, size: 22, color: color),
            Text(
              text,
              style: UiText.sans(12, weight: FontWeight.w500, color: color),
            ),
            if (sub != null) Text(sub!, style: UiText.sans(11, color: c.faint)),
          ],
        ),
      ),
    );
  }
}

/// 正在生成：控件底上一道斜向流光 + 转圈 + “生成中 #35”。
class _Running extends StatefulWidget {
  const _Running({required this.number});
  final int number;

  @override
  State<_Running> createState() => _RunningState();
}

class _RunningState extends State<_Running>
    with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _anim.stop();
    } else if (!_anim.isAnimating) {
      _anim.repeat();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1 + _anim.value * 4 - 1.5, -.6),
            end: Alignment(1 + _anim.value * 4 - 1.5, .6),
            colors: [c.control, c.hover, c.control],
          ),
        ),
        child: child,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            const UiSpinner(size: 22),
            Text(
              l.explore_generatingN(widget.number),
              style: UiText.sans(12, weight: FontWeight.w500, color: c.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// 右上角收藏（原型 `.heart`）：26 圆、黑 42% 底白心；已收藏白底红心。
class _Heart extends StatelessWidget {
  const _Heart({required this.candidate});
  final ExploreCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ExploreScope.of(context);
    final on = candidate.favorite;
    return Tooltip(
      message: on
          ? context.l10n.explore_unfavorite
          : context.l10n.explore_favorite,
      child: UiPressable(
        key: Key('explore-heart-${candidate.key}'),
        onTap: () => scope.actions.onSetFavorite([candidate.key], !on),
        builder: (context, hover) => Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on
                ? Colors.white
                : Colors.black.withValues(alpha: hover ? .6 : .42),
            shape: BoxShape.circle,
          ),
          child: Icon(
            on ? StudioIcons.galleryHeartFilled : StudioIcons.galleryHeart,
            size: 14,
            color: on ? c.fav : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// 左上角勾选（原型 `.chk`）：22 圆、2px 白边、黑 25% 底；勾上强调色实心 + 白勾。
class _Check extends StatelessWidget {
  const _Check({super.key, required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on
              ? c.accent
              : Colors.black.withValues(alpha: hover ? .4 : .25),
          shape: BoxShape.circle,
          border: Border.all(color: on ? c.accent : Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
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
      ),
    );
  }
}

/// 卡片角标（原型 `.bdg`）：20 高、圆角 6、11 / w600，图标 11。
class _Badge extends StatelessWidget {
  const _Badge({
    required this.glyph,
    required this.text,
    required this.background,
    required this.ink,
  });
  final String glyph;
  final String text;
  final Color background;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    height: 20,
    constraints: const BoxConstraints(maxWidth: 110),
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        UiGlyph(glyph, size: 11, color: ink),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.sans(
              11,
              weight: FontWeight.w600,
              color: ink,
              height: 1,
            ),
          ),
        ),
      ],
    ),
  );
}

/// 悬停操作条（原型 `.hov`）：34 高、圆角 8、深色 72% 底；收藏 · 加入进化 · 存为块 · 看大图 · 更多。
class _HoverBar extends StatelessWidget {
  const _HoverBar({required this.candidate});
  final ExploreCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final ctrl = scope.controller;
    final x = candidate;
    Widget b(String tip, Widget icon, VoidCallback onTap, String key) =>
        Tooltip(
          message: tip,
          child: UiPressable(
            key: Key('explore-hover-$key-${x.key}'),
            onTap: onTap,
            builder: (context, hover) => Container(
              width: 30,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hover ? const Color(0x2EFFFFFF) : null,
                borderRadius: BorderRadius.circular(6),
              ),
              child: icon,
            ),
          ),
        );
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xB8141414),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          b(
            x.favorite ? l.explore_unfavorite : l.explore_favorite,
            Icon(
              x.favorite
                  ? StudioIcons.galleryHeartFilled
                  : StudioIcons.galleryHeart,
              size: 15,
              color: x.favorite ? context.ui.fav : Colors.white,
            ),
            () => scope.actions.onSetFavorite([x.key], !x.favorite),
            'fav',
          ),
          b(
            l.explore_addToEvolution,
            const UiGlyph(UiGlyphs.evo, size: 15, color: Colors.white),
            () => ctrl.startEvolution([x.key]),
            'evo',
          ),
          b(
            l.explore_saveBlock,
            const UiGlyph(UiGlyphs.archive, size: 15, color: Colors.white),
            () => ctrl.saveBlock([x.key]),
            'block',
          ),
          b(
            l.explore_openLarge,
            const UiGlyph(UiGlyphs.expand, size: 15, color: Colors.white),
            () => ctrl.openDetail(x.key),
            'open',
          ),
          Builder(
            builder: (bctx) => b(
              l.explore_more,
              const UiGlyph(UiGlyphs.more, size: 15, color: Colors.white),
              () {
                final box = bctx.findRenderObject()! as RenderBox;
                ctrl.openMenu(
                  UiPopoverAnchor(
                    box.localToGlobal(Offset(0, box.size.height + 4)),
                  ),
                  exploreCandidateMenu(context, x),
                );
              },
              'more',
            ),
          ),
        ],
      ),
    );
  }
}

/// 多选浮条（原型 `.selbar`）：圆角 12、正文色底、窗口底色字；已选 N 张 │ 收藏 · 分组 ▾ · 存为块 · 开始进化 │ 删除 · 关闭。
class ExploreSelectionBar extends StatelessWidget {
  const ExploreSelectionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final ctrl = scope.controller;
    final run = scope.data.run!;
    final keys = [...ctrl.selected];
    final any = keys.isNotEmpty;
    final allFav =
        any && keys.every((k) => run.candidate(k)?.favorite ?? false);
    final fg = c.bg;

    Widget sep() => Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: fg.withValues(alpha: .25),
    );

    Widget b(
      String key,
      List<Widget> children,
      VoidCallback? onTap, {
      Color? bg,
      Color? ink,
      String? tip,
    }) {
      final w = UiPressable(
        key: Key('explore-sel-$key'),
        onTap: any ? onTap : null,
        builder: (context, hover) => Opacity(
          opacity: any ? 1 : .45,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: bg != null
                  ? (hover ? Color.lerp(bg, Colors.black, .08) : bg)
                  : (hover ? fg.withValues(alpha: .14) : null),
              borderRadius: BorderRadius.circular(7),
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: ink ?? fg),
              child: DefaultTextStyle.merge(
                style: UiText.sans(
                  12.5,
                  weight: FontWeight.w500,
                  color: ink ?? fg,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      );
      return tip == null ? w : Tooltip(message: tip, child: w);
    }

    return Container(
      key: const Key('explore-selection-bar'),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ExploreFormat.shadow(c),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Text(
            any ? l.explore_selectedN(keys.length) : l.explore_selectHint,
            style: UiText.sans(12.5, weight: FontWeight.w600, color: fg),
          ),
          const SizedBox(width: 4),
          sep(),
          b('fav', [
            Icon(
              allFav
                  ? StudioIcons.galleryHeartFilled
                  : StudioIcons.galleryHeart,
              size: 15,
              color: fg,
            ),
            Text(allFav ? l.explore_unfavorite : l.explore_favorite),
          ], () => scope.actions.onSetFavorite(keys, !allFav)),
          Builder(
            builder: (bctx) => b(
              'group',
              [
                UiGlyph(UiGlyphs.folder, size: 15, color: fg),
                Text(l.explore_group),
                UiGlyph(UiGlyphs.chevronDown, size: 12, color: fg),
              ],
              () {
                final box = bctx.findRenderObject()! as RenderBox;
                ctrl.openMenu(
                  UiPopoverAnchor(
                    box.localToGlobal(Offset.zero) - const Offset(0, 6),
                    alignBottom: true,
                  ),
                  [
                    for (final (i, g) in run.groups.indexed)
                      UiMenuItem(
                        key: Key('explore-sel-group-${g.id}'),
                        label: g.name,
                        glyph: UiGlyphs.folder,
                        trailing: i < 9 ? '${i + 1}' : null,
                        onTap: () => scope.actions.onAssignGroup(keys, g.id),
                      ),
                    UiMenuItem(
                      label: l.explore_newGroup,
                      glyph: UiGlyphs.folderPlus,
                      divider: run.groups.isNotEmpty,
                      onTap: () => ctrl.beginAddGroup(keys),
                    ),
                    UiMenuItem(
                      label: l.explore_ungroup,
                      glyph: UiGlyphs.inbox,
                      trailing: '0',
                      onTap: () => scope.actions.onAssignGroup(keys, null),
                    ),
                  ],
                );
              },
            ),
          ),
          b('block', [
            UiGlyph(UiGlyphs.archive, size: 15, color: fg),
            Text(l.explore_saveBlock),
          ], () => ctrl.saveBlock(keys)),
          b(
            'evo',
            [
              UiGlyph(UiGlyphs.evo, size: 15, color: c.onEvo),
              Text(l.explore_startEvolution),
            ],
            () => ctrl.startEvolution(keys),
            bg: c.evo,
            ink: c.onEvo,
          ),
          sep(),
          b(
            'delete',
            [UiGlyph(UiGlyphs.trash, size: 15, color: c.fav)],
            () => ctrl.delete(keys),
            tip: l.explore_deleteN(keys.length),
          ),
          UiPressable(
            key: const Key('explore-sel-close'),
            onTap: () => ctrl.setSelecting(false),
            builder: (context, hover) => Tooltip(
              message: l.explore_selectExit,
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hover ? fg.withValues(alpha: .14) : null,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: UiGlyph(UiGlyphs.close, size: 14, color: fg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 子代 / 小图卡：给进化页签复用的点击逻辑（单击看检查器，0.3 秒内再点开大图）。
mixin ExploreQuickOpen<T extends StatefulWidget> on State<T> {
  DateTime? _quickTap;

  void quickTap(ExploreController ctrl, String key) {
    final now = DateTime.now();
    final again =
        _quickTap != null &&
        now.difference(_quickTap!) < const Duration(milliseconds: 300);
    _quickTap = now;
    if (again && ctrl.focusKey == key) {
      _quickTap = null;
      ctrl.openDetail(key);
    } else {
      ctrl.focus(key);
    }
  }
}
