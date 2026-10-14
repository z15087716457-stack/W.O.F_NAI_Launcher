import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_block_pill.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'explore_contract.dart';
import 'explore_editor.dart';
import 'explore_format.dart';
import 'explore_page.dart';
import 'explore_parts.dart';

/// 舞台顶栏 61：探索切换（双击改名）· 张数 / 收藏 / 轮 / 进化线 —— 进度 · 卡片大小 · 检查器开关。
/// 检查器没停靠在右边时窗口按钮落在这里，让出位置。
class ExploreStageHeader extends StatelessWidget {
  const ExploreStageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final data = scope.data;
    final ctrl = scope.controller;
    final run = data.run!;
    final reserve = !ctrl.inspectorDocked;
    final chrome = WindowChromeScope.activeOf(context);
    final basic = [
      for (final r in run.rounds)
        if (r.kind == ExploreRoundKind.basic) r,
    ];
    final keys = {for (final r in basic) ...r.keys};
    final cands = run.candidates.where((x) => keys.contains(x.key));
    final favs = cands.where((x) => x.favorite).length;
    final p = run.progress;

    final meta = [
      l.explore_count(keys.length),
      l.explore_favoritesCount(favs),
      if (p == null) ...[
        l.explore_roundsCount(basic.length),
        if (run.lines.isNotEmpty) l.explore_linesCount(run.lines.length),
      ],
    ];

    return WindowHeader(
      key: const Key('explore-header'),
      enabled: reserve,
      minimumInlineWidth: 0,
      inlineDragWidth: 12,
      dragBackground: true,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Container(
        height: 60,
        padding: EdgeInsets.only(left: 14, right: reserve && chrome ? 0 : 12),
        child: Row(
          spacing: 10,
          children: [
            const _RunButton(),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    for (final (i, m) in meta.indexed) ...[
                      if (i > 0)
                        TextSpan(
                          text: '  ·  ',
                          style: TextStyle(color: c.strong),
                        ),
                      TextSpan(text: m),
                    ],
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(12, color: c.muted),
              ),
            ),
            if (p != null) _Progress(p),
            _SizeSeg(
              value: data.cardSize,
              onChanged: scope.actions.onCardSizeChanged,
            ),
            UiIconBox(
              key: const Key('explore-inspector-toggle'),
              glyph: UiGlyphs.panel,
              size: 28,
              glyphSize: 16,
              tone: ctrl.inspectorVisible
                  ? UiIconBoxTone.on
                  : UiIconBoxTone.plain,
              tooltip: l.explore_inspector,
              onTap: ctrl.toggleInspector,
            ),
          ],
        ),
      ),
    );
  }
}

/// 探索切换按钮（原型 `.runbtn`）：34 高、圆角 8、描边 + 抬起底、14 / w700、最宽 300；
/// 打开下拉时强调色描边 + 3px 浅环。双击名称原地改名。
class _RunButton extends StatelessWidget {
  const _RunButton();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ExploreScope.of(context);
    final ctrl = scope.controller;
    final run = scope.data.run!;
    final p = run.progress;
    if (ctrl.renamingRun) {
      return ExploreInlineInput(
        key: const Key('explore-run-rename'),
        initial: run.name,
        width: 260,
        height: 34,
        radius: 8,
        style: UiText.sans(14, weight: FontWeight.w700, color: c.ink),
        onSubmit: (v) {
          ctrl.setRenamingRun(false);
          scope.actions.onRenameRun(run.id, v);
        },
        onCancel: () => ctrl.setRenamingRun(false),
      );
    }
    final open = ctrl.runMenuOpen;
    final dotColor = p == null ? c.strong : (p.paused ? c.warn : c.accent);
    return Builder(
      builder: (bctx) => GestureDetector(
        onSecondaryTapUp: (d) =>
            ctrl.openMenu(UiPopoverAnchor(d.globalPosition), [
              UiMenuItem(
                key: const Key('explore-run-menu-rename-item'),
                label: context.l10n.explore_rename,
                glyph: UiGlyphs.pencil,
                onTap: () => ctrl.setRenamingRun(true),
              ),
              UiMenuItem(
                label: context.l10n.explore_deleteRun,
                glyph: UiGlyphs.trash,
                danger: true,
                divider: true,
                onTap: () => ctrl.confirmDeleteRun(run.id),
              ),
            ]),
        child: UiPressable(
          key: const Key('explore-run-button'),
          onTap: () {
            final box = bctx.findRenderObject()! as RenderBox;
            ctrl.openRunMenu(
              UiPopoverAnchor(
                box.localToGlobal(Offset(0, box.size.height + 6)),
              ),
            );
          },
          builder: (context, hover) => Container(
            height: 34,
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.only(left: 10, right: 8),
            decoration: BoxDecoration(
              color: hover ? c.hover : c.raised,
              border: Border.all(color: open ? c.accent : c.line),
              borderRadius: BorderRadius.circular(8),
              boxShadow: open
                  ? [
                      BoxShadow(
                        color: c.accent.withValues(alpha: .15),
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: p != null && !p.paused
                        ? [
                            BoxShadow(
                              color: c.accent.withValues(alpha: .2),
                              spreadRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                ),
                Flexible(
                  child: Text(
                    run.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(
                      14,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                ),
                UiGlyph(UiGlyphs.chevronDown, size: 15, color: c.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 进度胶囊（原型 `.prog`）：34 高、圆角 8、强调色 8% 底、12.5 / w600；转圈 · 第 3 轮 · 9 / 12 · 进度条 90 · 暂停 · 停止。
class _Progress extends StatelessWidget {
  const _Progress(this.p);
  final ExploreProgress p;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final actions = ExploreScope.of(context).actions;
    final ink = p.paused ? c.warn : c.accent;
    final where = p.round != null
        ? l.explore_progressRound(p.round!, p.done, p.total)
        : l.explore_progressChildren(
            p.lineName ?? '',
            p.generation ?? 1,
            p.done,
            p.total,
          );
    Widget btn(
      String glyph,
      String tip,
      VoidCallback onTap,
      String key, {
      bool fill = false,
      double size = 15,
    }) => UiIconBox(
      key: Key(key),
      glyph: glyph,
      size: 28,
      glyphSize: size,
      color: ink,
      filled: fill,
      tooltip: tip,
      onTap: onTap,
    );
    return Container(
      key: const Key('explore-progress'),
      height: 34,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          if (p.paused)
            UiGlyph(UiGlyphs.pause, size: 14, strokeWidth: 2.4, color: ink)
          else
            const UiSpinner(size: 14),
          Text(
            p.paused ? l.explore_paused(where) : where,
            style: UiText.sans(12.5, weight: FontWeight.w600, color: ink),
          ),
          SizedBox(
            width: 90,
            child: Theme(
              data: Theme.of(context),
              child: _Bar(
                value: p.total == 0 ? 0 : p.done / p.total,
                color: ink,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (p.round == null)
                p.paused
                    ? btn(
                        UiGlyphs.play,
                        l.explore_resume,
                        actions.onResume,
                        'explore-resume',
                        fill: true,
                        size: 13,
                      )
                    : btn(
                        UiGlyphs.pause,
                        l.explore_pause,
                        actions.onPause,
                        'explore-pause',
                      ),
              btn(
                UiGlyphs.stop,
                l.explore_stop,
                actions.onStop,
                'explore-stop',
                fill: true,
                size: 13,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(2),
    child: SizedBox(
      height: 4,
      child: ColoredBox(
        color: color.withValues(alpha: .18),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0, 1),
          child: ColoredBox(color: color),
        ),
      ),
    ),
  );
}

/// 卡片大小（原型 `.seg2`）：控件底、内边距 2、圆角 7；项 28 高、内边距 9、圆角 5。
class _SizeSeg extends StatelessWidget {
  const _SizeSeg({required this.value, required this.onChanged});
  final ExploreCardSize value;
  final ValueChanged<ExploreCardSize> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    Widget item(ExploreCardSize s, IconData icon, String tip) {
      final on = s == value;
      return Tooltip(
        message: tip,
        child: UiPressable(
          key: Key('explore-size-${s.name}'),
          onTap: on ? null : () => onChanged(s),
          builder: (context, hover) => Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? (c.dark ? c.hover : c.raised) : null,
              borderRadius: BorderRadius.circular(5),
              boxShadow: on && !c.dark
                  ? const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, size: 15, color: on || hover ? c.ink : c.muted),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          item(
            ExploreCardSize.small,
            StudioIcons.gallerySizeSmall,
            l.explore_sizeSmall,
          ),
          item(
            ExploreCardSize.large,
            StudioIcons.gallerySizeLarge,
            l.explore_sizeLarge,
          ),
        ],
      ),
    );
  }
}

/// 页签行 46（原型 `.trow`）：候选 / 进化 大页签 │ 筛选胶囊（横向滚动）—— 排序 · 多选。
/// 进化页签时筛选换成进化线切换。
class ExploreTabsRow extends StatelessWidget {
  const ExploreTabsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final ctrl = scope.controller;
    final run = scope.data.run!;
    final evo = ctrl.tab == ExploreTab.evolution;
    final basicKeys = {
      for (final r in run.rounds)
        if (r.kind == ExploreRoundKind.basic) ...r.keys,
    };
    final cands = [
      for (final x in run.candidates)
        if (basicKeys.contains(x.key)) x,
    ];

    final List<Widget> chips;
    if (evo) {
      chips = [
        for (final line in run.lines)
          ExploreChip(
            key: Key('explore-line-${line.id}'),
            label: line.name,
            countText: 'G${line.current.number}',
            selected: line.id == ctrl.lineId,
            selectedColor: c.evo,
            selectedInk: c.onEvo,
            onTap: () => ctrl.setLine(line.id),
            onSecondaryTap: (p) => ctrl.openMenu(UiPopoverAnchor(p), [
              UiMenuItem(
                label: l.explore_compareShort,
                glyph: UiGlyphs.sort,
                onTap: () => ctrl.compare(line.id),
              ),
              UiMenuItem(
                label: l.explore_deleteLine,
                glyph: UiGlyphs.trash,
                danger: true,
                divider: true,
                onTap: () => ctrl.confirmDeleteLine(line.id),
              ),
            ]),
          ),
        ExploreChip(
          key: const Key('explore-new-line'),
          label: l.explore_newLine,
          dashed: true,
          leading: UiGlyph(UiGlyphs.plus, size: 13, color: c.faint),
          onTap: () {
            ctrl.setTab(ExploreTab.candidates);
            ctrl.setSelecting(true);
          },
        ),
      ];
    } else {
      final groupCount = {
        for (final g in run.groups)
          g.id: cands.where((x) => x.groupId == g.id).length,
      };
      chips = [
        ExploreChip(
          key: const Key('explore-filter-all'),
          label: l.explore_filterAll,
          count: cands.length,
          selected: ctrl.filter == ExploreFilter.all,
          onTap: () => ctrl.setFilter(ExploreFilter.all),
        ),
        ExploreChip(
          key: const Key('explore-filter-favorites'),
          label: l.explore_filterFavorites,
          count: cands.where((x) => x.favorite).length,
          selected: ctrl.filter == ExploreFilter.favorites,
          leading: Icon(
            StudioIcons.galleryHeartFilled,
            size: 12,
            color: ctrl.filter == ExploreFilter.favorites ? c.bg : c.fav,
          ),
          onTap: () => ctrl.setFilter(ExploreFilter.favorites),
        ),
        ExploreChip(
          key: const Key('explore-filter-ungrouped'),
          label: l.explore_filterUngrouped,
          count: cands.where((x) => x.groupId == null).length,
          selected: ctrl.filter == ExploreFilter.ungrouped,
          leading: UiGlyph(
            UiGlyphs.inbox,
            size: 13,
            color: ctrl.filter == ExploreFilter.ungrouped ? c.bg : c.muted,
          ),
          onTap: () => ctrl.setFilter(ExploreFilter.ungrouped),
        ),
        for (final g in run.groups)
          ExploreChip(
            key: Key('explore-filter-${g.id}'),
            label: g.name,
            count: groupCount[g.id],
            selected: ctrl.filter == ExploreFilter.group(g.id),
            leading: UiGlyph(
              UiGlyphs.folder,
              size: 13,
              color: ctrl.filter == ExploreFilter.group(g.id) ? c.bg : c.muted,
            ),
            onTap: () => ctrl.setFilter(ExploreFilter.group(g.id)),
            onSecondaryTap: (p) => ctrl.openMenu(UiPopoverAnchor(p), [
              UiMenuItem(
                label: l.explore_deleteGroup,
                glyph: UiGlyphs.trash,
                danger: true,
                onTap: () => scope.actions.onDeleteGroup(g.id),
              ),
            ]),
          ),
        if (ctrl.addingGroup)
          ExploreInlineInput(
            key: const Key('explore-group-input'),
            hint: l.explore_groupName,
            onSubmit: (v) {
              final keys = ctrl.addingGroupKeys;
              ctrl.endAddGroup();
              scope.actions.onCreateGroup(v, keys);
            },
            onCancel: ctrl.endAddGroup,
          )
        else
          ExploreChip(
            key: const Key('explore-add-group'),
            label: l.explore_addGroup,
            dashed: true,
            leading: UiGlyph(UiGlyphs.plus, size: 13, color: c.faint),
            onTap: () => ctrl.beginAddGroup(const []),
          ),
      ];
    }

    return Container(
      height: 46,
      padding: const EdgeInsets.only(left: 14, right: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          _BigTab(
            key: const Key('explore-tab-candidates'),
            icon: Icon(
              StudioIcons.galleryImage,
              size: 16,
              color: evo ? c.muted : c.ink,
            ),
            label: l.explore_tabCandidates,
            count: cands.length,
            on: !evo,
            onTap: () => ctrl.setTab(ExploreTab.candidates),
          ),
          _BigTab(
            key: const Key('explore-tab-evolution'),
            icon: UiGlyph(UiGlyphs.evo, size: 16, color: evo ? c.evo : c.muted),
            label: l.explore_tabEvolution,
            count: run.lines.length,
            on: evo,
            color: c.evo,
            onTap: () => ctrl.setTab(ExploreTab.evolution),
          ),
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: c.line,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _FadeScroll(child: Row(spacing: 6, children: chips)),
          ),
          const SizedBox(width: 6),
          if (evo)
            UiBtn(
              key: const Key('explore-evo-help'),
              tone: UiBtnTone.ghost,
              tooltip: l.explore_evoHelpBody,
              children: [
                const UiGlyph(UiGlyphs.infoCircle, size: 14),
                Text(l.explore_evoHelp),
              ],
            )
          else if (ctrl.selecting) ...[
            UiBtn(
              key: const Key('explore-select-all'),
              tone: UiBtnTone.ghost,
              onTap: () => ctrl.setSelected(
                ctrl.visibleKeys.where((k) => run.candidate(k)?.done ?? false),
              ),
              children: [Text(l.explore_selectAll)],
            ),
            const SizedBox(width: 4),
            UiBtn(
              key: const Key('explore-select-done'),
              tone: UiBtnTone.accent,
              onTap: () => ctrl.setSelecting(false),
              children: [Text(l.explore_selectDone)],
            ),
          ] else ...[
            UiIconBox(
              key: const Key('explore-sort'),
              glyph: UiGlyphs.sort,
              size: 28,
              tooltip: ctrl.newestFirst
                  ? l.explore_sortNewest
                  : l.explore_sortOldest,
              onTap: ctrl.toggleOrder,
            ),
            const SizedBox(width: 6),
            UiBtn(
              key: const Key('explore-select'),
              onTap: () => ctrl.setSelecting(true),
              children: [
                const UiGlyph(UiGlyphs.select, size: 14),
                Text(l.explore_select),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 横向滚动、两端渐隐（筛选胶囊多了放不下时）。
class _FadeScroll extends StatefulWidget {
  const _FadeScroll({required this.child});
  final Widget child;

  @override
  State<_FadeScroll> createState() => _FadeScrollState();
}

class _FadeScrollState extends State<_FadeScroll> {
  final _ctrl = ScrollController();
  var _left = false;
  var _right = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _sync() {
    if (!mounted || !_ctrl.hasClients) return;
    final p = _ctrl.position;
    final l = p.pixels > 1;
    final r = p.pixels < p.maxScrollExtent - 1;
    if (l != _left || r != _right) {
      setState(() {
        _left = l;
        _right = r;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    final list = SingleChildScrollView(
      controller: _ctrl,
      scrollDirection: Axis.horizontal,
      child: widget.child,
    );
    if (!_left && !_right) return list;
    return ShaderMask(
      shaderCallback: (r) => LinearGradient(
        colors: [
          _left ? Colors.transparent : Colors.black,
          Colors.black,
          Colors.black,
          _right ? Colors.transparent : Colors.black,
        ],
        stops: const [0, .06, .94, 1],
      ).createShader(r),
      blendMode: BlendMode.dstIn,
      child: list,
    );
  }
}

/// 大页签（原型 `.bigtab`）：46 高、内边距 4、右外边距 10、14 / w600；选中正文色 + 底部 2px 指示线。
class _BigTab extends StatelessWidget {
  const _BigTab({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.on,
    required this.onTap,
    this.color,
  });
  final Widget icon;
  final String label;
  final int count;
  final bool on;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final ink = on ? (color ?? c.ink) : c.muted;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: UiPressable(
        onTap: on ? null : onTap,
        builder: (context, hover) => SizedBox(
          height: 45,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    icon,
                    Text(
                      label,
                      style: UiText.sans(
                        14,
                        weight: FontWeight.w600,
                        color: hover && !on ? c.ink : ink,
                      ),
                    ),
                    ExploreCount(count),
                  ],
                ),
              ),
              // 选中下划线压在页签栏底边线上（原型 `.bigtab.on::after` bottom:-1），一律墨色。
              if (on)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -1,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: c.ink,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 首次使用 / 空探索：标志 · 一句话 · 三步说明（第一步实时检测随机块）· 抽 N 张 / 打开以前的探索。
/// [compact] 是已经建了探索但还没抽过（顶栏在，去掉大标志）。
class ExploreOnboarding extends StatelessWidget {
  const ExploreOnboarding({super.key, this.compact = false});
  final bool compact;

  /// 舞台窄于这个宽度时步骤卡竖排。
  static const narrowWidth = 760.0;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final data = scope.data;
    final vars = data.variables;

    Widget th(String name, double r) => Transform.rotate(
      angle: r * math.pi / 180,
      child: Container(
        width: 62,
        height: 90,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: ExploreFormat.shadow(c),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/explore-example-$name.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => ColoredBox(color: c.control),
        ),
      ),
    );

    Widget step(int n, String title, String desc, Widget ill) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 8,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
                child: Text(
                  '$n',
                  style: UiText.sans(
                    12,
                    weight: FontWeight.w700,
                    color: c.bg,
                    height: 1,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(15, weight: FontWeight.w700, color: c.ink),
                ),
              ),
            ],
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Text(desc, style: UiText.sans(12, color: c.muted)),
          ),
          Container(
            height: 150,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ill,
          ),
        ],
      ),
    );

    final detected = vars.isEmpty
        ? Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 5,
                children: [
                  UiGlyph(UiGlyphs.alert, size: 13, color: c.warn),
                  Text(
                    l.explore_noVariables,
                    style: UiText.sans(12, color: c.warn),
                  ),
                ],
              ),
              UiBtn(
                key: const Key('explore-onboarding-library'),
                size: UiBtnSize.small,
                onTap: scope.actions.onOpenBlockLibrary,
                children: [
                  const UiGlyph(UiGlyphs.archive, size: 13),
                  Text(l.explore_openBlockLibrary),
                ],
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              for (final v in vars.take(3))
                UiBlockPill(
                  label: v.title,
                  color: v.color,
                  icon: v.icon,
                  badge: v.evolution
                      ? UiBlockBadge.evolution
                      : UiBlockBadge.random,
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 5,
                children: [
                  UiGlyph(
                    UiGlyphs.check,
                    size: 13,
                    strokeWidth: 2.6,
                    color: c.ok,
                  ),
                  Text(
                    l.explore_detected(vars.length),
                    style: UiText.sans(12, color: c.ok),
                  ),
                ],
              ),
            ],
          );

    // 舞台窄（块库侧栏打开、窗口小）时三张步骤卡改成竖排，边距收小。
    Widget body(bool narrow) => Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 26,
      children: [
        if (!compact)
          Opacity(
            opacity: c.dark ? .85 : .9,
            child: SvgPicture.asset(
              'assets/images/wof_nai_lab.svg',
              width: 230,
              colorFilter: c.dark
                  ? const ColorFilter.matrix([
                      -1, 0, 0, 0, 255, //
                      0, -1, 0, 0, 255,
                      0, 0, -1, 0, 255,
                      0, 0, 0, 1, 0,
                    ])
                  : null,
            ),
          ),
        Column(
          children: [
            Text(
              l.explore_onboardingTitle,
              textAlign: TextAlign.center,
              style: UiText.sans(22, weight: FontWeight.w700, color: c.ink),
            ),
            const SizedBox(height: 6),
            Text(
              l.explore_onboardingBody,
              textAlign: TextAlign.center,
              style: UiText.sans(14, color: c.muted),
            ),
          ],
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: narrow ? 420 : 980),
          child: IntrinsicHeight(
            child: Flex(
              key: const Key('explore-onboarding-steps'),
              direction: narrow ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                for (final card in [
                  step(
                    1,
                    l.explore_step1,
                    l.explore_step1Body,
                    _ScaleDown(child: detected),
                  ),
                  step(
                    2,
                    l.explore_step2,
                    l.explore_step2Body(data.generate.count),
                    _ScaleDown(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [th('c01', -6), th('c04', 2), th('c12', 7)],
                      ),
                    ),
                  ),
                  step(
                    3,
                    l.explore_step3,
                    l.explore_step3Body,
                    _ScaleDown(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          Icon(
                            StudioIcons.galleryHeartFilled,
                            size: 28,
                            color: c.fav,
                          ),
                          UiGlyph(
                            UiGlyphs.arrowRight,
                            size: 18,
                            color: c.faint,
                          ),
                          UiGlyph(UiGlyphs.evo, size: 30, color: c.evo),
                          UiGlyph(
                            UiGlyphs.arrowRight,
                            size: 18,
                            color: c.faint,
                          ),
                          UiGlyph(UiGlyphs.archive, size: 28, color: c.muted),
                        ],
                      ),
                    ),
                  ),
                ])
                  narrow ? card : Expanded(child: card),
              ],
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            const ExploreGenerateButton(compact: true),
            if (!compact && data.runs.isNotEmpty)
              Builder(
                builder: (bctx) => UiBtn(
                  key: const Key('explore-onboarding-runs'),
                  size: UiBtnSize.large,
                  onTap: () {
                    final box = bctx.findRenderObject()! as RenderBox;
                    scope.controller.openRunMenu(
                      UiPopoverAnchor(
                        box.localToGlobal(Offset(0, box.size.height + 6)),
                      ),
                    );
                  },
                  children: [
                    Text(l.explore_openPrevious),
                    const UiGlyph(UiGlyphs.chevronDown, size: 14),
                  ],
                ),
              ),
          ],
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact)
          WindowHeader(
            enabled: !scope.controller.inspectorDocked,
            minimumInlineWidth: 0,
            inlineDragWidth: 0,
            dragBackground: true,
            child: const SizedBox(height: 40),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final narrow = box.maxWidth < narrowWidth;
              final side = narrow ? 24.0 : 70.0;
              return SingleChildScrollView(
                key: const Key('explore-onboarding'),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      side,
                      compact || narrow ? 32 : 0,
                      side,
                      40,
                    ),
                    child: Center(child: body(narrow)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 读探索列表时的舞台：骨架卡片。
class ExploreLoadingStage extends StatelessWidget {
  const ExploreLoadingStage({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      WindowHeader(
        enabled: !ExploreScope.of(context).controller.inspectorDocked,
        minimumInlineWidth: 0,
        inlineDragWidth: 12,
        dragBackground: true,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.ui.line)),
        ),
        child: const SizedBox(
          height: 60,
          child: Padding(
            padding: EdgeInsets.only(left: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: UiSkeleton(width: 200, height: 34),
            ),
          ),
        ),
      ),
      Expanded(
        key: const Key('explore-loading'),
        child: LayoutBuilder(
          builder: (context, box) {
            final cols = math.max(2, ((box.maxWidth - 28 + 12) / 192).floor());
            final w = (box.maxWidth - 28 - 12 * (cols - 1)) / cols;
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 60, 14, 0),
              child: Wrap(
                spacing: 12,
                runSpacing: 14,
                children: [
                  for (var i = 0; i < cols * 2; i++)
                    UiSkeleton(
                      width: w,
                      height: w * 1216 / 832,
                      opacity: 1 - i * .04,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

/// 删除后的撤销提示：深底浅字胶囊“已删除 3 张 · 撤销”。
class ExploreUndoToast extends StatelessWidget {
  const ExploreUndoToast({super.key, required this.undo});
  final ExploreUndo undo;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final actions = ExploreScope.of(context).actions;
    return Container(
      key: const Key('explore-undo'),
      height: 40,
      padding: const EdgeInsets.only(left: 14, right: 6),
      decoration: BoxDecoration(
        color: c.tipBg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Text(
            l.explore_deleted(undo.count),
            style: UiText.sans(12.5, color: c.tipInk),
          ),
          const SizedBox(width: 6),
          UiPressable(
            key: const Key('explore-undo-button'),
            onTap: actions.onUndoDelete,
            builder: (context, hover) => Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.tipInk.withValues(alpha: hover ? .2 : .12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                l.explore_undo,
                style: UiText.sans(
                  12.5,
                  weight: FontWeight.w600,
                  color: c.tipInk,
                ),
              ),
            ),
          ),
          UiPressable(
            onTap: actions.onDismissUndo,
            builder: (context, hover) => SizedBox(
              width: 28,
              height: 28,
              child: Center(
                child: UiGlyph(
                  UiGlyphs.close,
                  size: 13,
                  color: c.tipInk.withValues(alpha: hover ? .9 : .6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 引导卡里的示意：放得下原样居中，卡片变窄时整体等比缩小，不溢出。
class _ScaleDown extends StatelessWidget {
  const _ScaleDown({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    ),
  );
}
