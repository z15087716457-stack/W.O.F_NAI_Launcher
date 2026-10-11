import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'explore_contract.dart';
import 'explore_page.dart';
import 'explore_parts.dart';
import 'explore_wall.dart';

/// 进化页签：当前进化线按代从新到旧排。当前代展开（父本按偏好排 │ 子代可勾选培育下一代），
/// 历史代折叠成一行（点开只读）。
class ExploreEvolutionBody extends StatelessWidget {
  const ExploreEvolutionBody({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final ctrl = scope.controller;
    final run = scope.data.run!;
    final line = run.lines.where((e) => e.id == ctrl.lineId).firstOrNull;
    if (line == null) {
      return Center(
        key: const Key('explore-evo-empty'),
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.evoBg,
                  shape: BoxShape.circle,
                ),
                child: UiGlyph(UiGlyphs.evo, size: 26, color: c.evo),
              ),
              Text(
                l.explore_evoEmptyTitle,
                style: UiText.sans(15, weight: FontWeight.w700, color: c.ink),
              ),
              Text(
                l.explore_evoEmptyBody,
                textAlign: TextAlign.center,
                style: UiText.sans(12.5, color: c.muted, height: 1.6),
              ),
              const SizedBox(height: 2),
              UiBtn(
                key: const Key('explore-evo-go-pick'),
                onTap: () {
                  ctrl.setTab(ExploreTab.candidates);
                  ctrl.setSelecting(true);
                },
                children: [Text(l.explore_evoGoPick)],
              ),
            ],
          ),
        ),
      );
    }
    final gens = line.generations.reversed.toList();
    return Scrollbar(
      child: ListView(
        key: const Key('explore-evo'),
        padding: EdgeInsets.fromLTRB(14, 14, 14, ctrl.selecting ? 84 : 18),
        children: [
          for (final (i, g) in gens.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            i == 0
                ? _CurrentGen(
                    key: ValueKey('${line.id}-${g.number}'),
                    line: line,
                    gen: g,
                  )
                : _OldGen(key: ValueKey('${line.id}-${g.number}'), gen: g),
          ],
        ],
      ),
    );
  }
}

String _summary(BuildContext context, ExploreGeneration g) {
  final l = context.l10n;
  final kids = g.childKeys.length;
  if (g.fromGeneration == null) {
    return l.explore_genFirst(g.picked, kids);
  }
  return [
    l.explore_genFrom(g.parents.length, kids, g.fromGeneration!, g.picked),
    if (g.backcross) l.explore_backcross,
  ].join(' + ');
}

/// 代卡外框（原型 `.gen`）：圆角 12、描边、抬起底，内容按圆角裁。
class _GenFrame extends StatelessWidget {
  const _GenFrame({required this.children, this.dim = false});
  final List<Widget> children;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Opacity(
      opacity: dim ? .85 : 1,
      child: Container(
        clipBehavior: Clip.antiAlias,
        foregroundDecoration: BoxDecoration(
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(12),
        ),
        decoration: BoxDecoration(
          color: c.raised,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _CurrentGen extends StatefulWidget {
  const _CurrentGen({super.key, required this.line, required this.gen});
  final ExploreLine line;
  final ExploreGeneration gen;

  @override
  State<_CurrentGen> createState() => _CurrentGenState();
}

class _CurrentGenState extends State<_CurrentGen> {
  var _count = 8;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final ctrl = scope.controller;
    final a = scope.actions;
    final g = widget.gen;
    final line = widget.line;
    final run = scope.data.run!;
    final p = run.progress;
    final busy = p != null && p.round == null && p.lineName == line.name;

    final header = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        spacing: 10,
        children: [
          ExploreGenTag(l.explore_gen(g.number)),
          Text(
            l.explore_current,
            style: UiText.sans(14, weight: FontWeight.w700, color: c.ink),
          ),
          Expanded(
            child: Text(
              _summary(context, g),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12, color: c.muted),
            ),
          ),
          UiBtn(
            key: const Key('explore-compare'),
            tooltip: l.explore_compareTip,
            onTap: g.parents.length < 2 ? null : () => ctrl.compare(line.id),
            children: [
              const UiGlyph(UiGlyphs.sort, size: 14),
              Text(l.explore_compare),
            ],
          ),
          ExploreStepper(
            value: _count,
            min: 1,
            max: 32,
            height: 30,
            bordered: true,
            keyPrefix: 'explore-kids-count',
            onChanged: busy ? null : (v) => setState(() => _count = v),
          ),
          UiBtn(
            key: const Key('explore-generate-children'),
            tone: UiBtnTone.evo,
            onTap: busy ? null : () => a.onGenerateChildren(line.id, _count),
            children: [
              UiGlyph(UiGlyphs.play, size: 12, filled: true, color: c.onEvo),
              Text(l.explore_generateChildren(_count)),
            ],
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, box) => _frame(header, box.maxWidth),
    );
  }

  Widget _frame(Widget header, double width) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final ctrl = scope.controller;
    final a = scope.actions;
    final g = widget.gen;
    final line = widget.line;
    final run = scope.data.run!;
    final p = run.progress;
    final busy = p != null && p.round == null && p.lineName == line.name;
    final picked = [
      for (final k in ctrl.selected)
        if (g.childKeys.contains(k)) k,
    ];
    return _GenFrame(
      children: [
        header,
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 270,
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: c.line)),
                ),
                child: _Parents(gen: g),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [
                      SizedBox(
                        height: 28,
                        child: Row(
                          spacing: 8,
                          children: [
                            ExploreSect(l.explore_children(g.childKeys.length)),
                            const Spacer(),
                            if (picked.isNotEmpty)
                              Text(
                                l.explore_pickedN(picked.length),
                                style: UiText.sans(12, color: c.muted),
                              )
                            else if (g.childKeys.isNotEmpty)
                              Text(
                                l.explore_breedHint,
                                style: UiText.sans(12, color: c.faint),
                              ),
                            UiBtn(
                              key: const Key('explore-breed'),
                              tone: UiBtnTone.evo,
                              size: UiBtnSize.small,
                              onTap: picked.isEmpty || busy
                                  ? null
                                  : () {
                                      a.onBreed(line.id, picked);
                                      ctrl.setSelecting(false);
                                    },
                              children: [
                                UiGlyph(
                                  UiGlyphs.branch,
                                  size: 13,
                                  color: c.onEvo,
                                ),
                                Text(
                                  l.explore_breed(picked.length, g.number + 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (g.childKeys.isEmpty)
                        Container(
                          height: 160,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.panel,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l.explore_noChildren,
                            style: UiText.sans(12.5, color: c.muted),
                          ),
                        )
                      else
                        _Kids(
                          keys: g.childKeys,
                          width: _kidsWidth(width),
                          selectable: true,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 父本列表（原型 `.pp`）：按偏好从高到低；缩略图 36 × 52、画师串、偏好条 + 权重。点一行看来源候选。
class _Parents extends StatelessWidget {
  const _Parents({required this.gen, this.readOnly = false});
  final ExploreGeneration gen;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final ctrl = ExploreScope.of(context).controller;
    final parents = [...gen.parents]
      ..sort((a, b) => b.preference.compareTo(a.preference));
    final top = parents.map((p) => p.preference).fold(0.0, math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
          child: ExploreSect(l.explore_parentsByPref(parents.length)),
        ),
        for (final p in parents)
          UiPressable(
            key: Key('explore-parent-${p.id}'),
            onTap: p.candidateKey == null
                ? null
                : () => ctrl.focus(p.candidateKey!),
            builder: (context, hover) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: hover && p.candidateKey != null ? c.hover : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                spacing: 9,
                children: [
                  SizedBox(
                    width: 36,
                    height: 52,
                    child: p.image == null
                        ? Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.control,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: UiGlyph(
                              UiGlyphs.pencil,
                              size: 14,
                              color: c.faint,
                            ),
                          )
                        : ExploreImage(p.image, radius: 5),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 6,
                      children: [
                        ExploreArtistsText(p.atoms, maxLines: 2, size: 12),
                        Row(
                          spacing: 6,
                          children: [
                            Expanded(
                              child: ExplorePrefBar(
                                top <= 0 ? 0 : p.preference / top,
                              ),
                            ),
                            Text(
                              p.preference.toStringAsFixed(
                                p.preference == p.preference.roundToDouble()
                                    ? 1
                                    : 2,
                              ),
                              style: UiText.mono(11, color: c.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 子代网格（原型 `.kids`）：最窄 72、列距 8 行距 10；勾选圈常显，左下角来源角标，1 行画师串。
class _Kids extends StatelessWidget {
  const _Kids({
    required this.keys,
    required this.width,
    this.selectable = false,
  });
  final List<String> keys;

  /// 网格可用宽（外面量好传进来：网格在 IntrinsicHeight 里，不能再用 LayoutBuilder）。
  final double width;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final run = ExploreScope.of(context).data.run!;
    final cols = math.max(3, ((width + 8) / (72 + 8)).floor());
    final w = ((width - 8 * (cols - 1)) / cols).floorToDouble();
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: [
        for (final k in keys)
          if (run.candidate(k) case final x?)
            SizedBox(
              width: w,
              child: _Kid(
                key: ValueKey(k),
                candidate: x,
                selectable: selectable,
              ),
            ),
      ],
    );
  }
}

/// 代卡里子代区的宽：卡宽 − 父本列 270 − 左右内边距 24。
double _kidsWidth(double card) => card - 270 - 1 - 24;

class _Kid extends StatefulWidget {
  const _Kid({super.key, required this.candidate, required this.selectable});
  final ExploreCandidate candidate;
  final bool selectable;

  @override
  State<_Kid> createState() => _KidState();
}

class _KidState extends State<_Kid> with ExploreQuickOpen {
  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final ctrl = scope.controller;
    final x = widget.candidate;
    final selected = ctrl.selected.contains(x.key);
    final focused = ctrl.focusKey == x.key;
    final img = switch (x.state) {
      ExploreCandidateState.done => ExploreImage(x.thumb ?? x.image),
      ExploreCandidateState.running => const Center(child: UiSpinner(size: 18)),
      ExploreCandidateState.failed => Center(
        child: UiGlyph(UiGlyphs.alert, size: 18, color: c.error),
      ),
      ExploreCandidateState.pending => Center(
        child: UiGlyph(UiGlyphs.dice, size: 18, color: c.faint),
      ),
    };
    return GestureDetector(
      key: Key('explore-kid-${x.key}'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final hw = HardwareKeyboard.instance;
        if (widget.selectable &&
            x.done &&
            (ctrl.selecting || hw.isControlPressed || hw.isMetaPressed)) {
          ctrl.toggleSelect(x.key);
        } else if (widget.selectable && x.done && hw.isShiftPressed) {
          ctrl.selectRange(x.key);
        } else {
          quickTap(ctrl, x.key);
        }
      },
      onSecondaryTapUp: x.done
          ? (d) => ctrl.openMenu(
              UiPopoverAnchor(d.globalPosition),
              exploreCandidateMenu(context, x),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          AspectRatio(
            aspectRatio: x.aspect,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: ColoredBox(
                      color: c.control,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          img,
                          if (selected)
                            ColoredBox(color: c.evo.withValues(alpha: .16)),
                          if (widget.selectable && x.done)
                            Positioned(
                              top: 5,
                              left: 5,
                              child: _KidCheck(
                                key: Key('explore-kid-check-${x.key}'),
                                on: selected,
                                onTap: () => ctrl.toggleSelect(x.key),
                              ),
                            ),
                          if (x.favorite)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                width: 20,
                                height: 20,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  StudioIcons.galleryHeartFilled,
                                  size: 11,
                                  color: c.fav,
                                ),
                              ),
                            ),
                          if (x.op != null)
                            Positioned(
                              left: 5,
                              bottom: 5,
                              child: ExploreOpBadge(x.op!),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (selected || focused)
                  Positioned(
                    left: -3,
                    top: -3,
                    right: -3,
                    bottom: -3,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selected ? c.evo : c.accent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ExploreArtistsText(
            x.atoms,
            maxLines: 1,
            size: 11,
            empty: x.done ? l.explore_noArtists : '',
          ),
        ],
      ),
    );
  }
}

/// 子代勾选（20 圆，勾上紫色）。
class _KidCheck extends StatelessWidget {
  const _KidCheck({super.key, required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? c.evo : Colors.black.withValues(alpha: hover ? .4 : .25),
          shape: BoxShape.circle,
          border: Border.all(color: on ? c.evo : Colors.white, width: 2),
        ),
        child: on
            ? UiGlyph(UiGlyphs.check, size: 11, strokeWidth: 3, color: c.onEvo)
            : null,
      ),
    );
  }
}

/// 历史代：一行（代标签 · 概要 · 小图）点开只读的父本和子代。
class _OldGen extends StatefulWidget {
  const _OldGen({super.key, required this.gen});
  final ExploreGeneration gen;

  @override
  State<_OldGen> createState() => _OldGenState();
}

class _OldGenState extends State<_OldGen> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final run = ExploreScope.of(context).data.run!;
    final g = widget.gen;
    final thumbs = [
      for (final k in g.childKeys.take(8))
        if (run.candidate(k) case final x?) x,
    ];
    return LayoutBuilder(
      builder: (context, box) => _frame(box.maxWidth, thumbs),
    );
  }

  Widget _frame(double width, List<ExploreCandidate> thumbs) {
    final c = context.ui;
    final l = context.l10n;
    final g = widget.gen;
    return _GenFrame(
      dim: !_open,
      children: [
        UiPressable(
          key: Key('explore-gen-${g.number}'),
          onTap: () => setState(() => _open = !_open),
          builder: (context, hover) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: hover ? c.hover.withValues(alpha: .5) : null,
            child: Row(
              spacing: 10,
              children: [
                ExploreGenTag(l.explore_gen(g.number), current: false),
                Flexible(
                  child: Text(
                    _summary(context, g),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(12, color: c.muted),
                  ),
                ),
                if (!_open)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 3,
                    children: [
                      for (final x in thumbs)
                        SizedBox(
                          width: 22,
                          height: 32,
                          child: ExploreImage(x.thumb ?? x.image, radius: 3),
                        ),
                    ],
                  ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    Text(
                      _open ? l.explore_collapse : l.explore_expand,
                      style: UiText.sans(
                        12.5,
                        weight: FontWeight.w500,
                        color: c.muted,
                      ),
                    ),
                    UiGlyph(
                      _open ? UiGlyphs.chevronUp : UiGlyphs.chevronDown,
                      size: 13,
                      color: c.muted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 270,
                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: c.line)),
                    ),
                    child: _Parents(gen: g, readOnly: true),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 10,
                        children: [
                          ExploreSect(l.explore_children(g.childKeys.length)),
                          if (g.childKeys.isEmpty)
                            Text(
                              l.explore_noChildren,
                              style: UiText.sans(12, color: c.faint),
                            )
                          else
                            _Kids(keys: g.childKeys, width: _kidsWidth(width)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
