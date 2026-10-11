import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import 'explore_contract.dart';
import 'explore_format.dart';
import 'explore_page.dart';
import 'explore_parts.dart';

/// 检查器 340：头部 61（#27 · 第 3 轮 · 18:54）+ 可滚动内容 + 底部（完整提示词 · 删除）。
/// 内容按当前对象切换：单张 / 子代 / 多选 / 排队失败 / 空。
/// [drawer] 时是窄窗口里盖在舞台上的抽屉（带关闭）。
class ExploreInspector extends StatelessWidget {
  const ExploreInspector({super.key, this.drawer = false});
  final bool drawer;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final ctrl = scope.controller;
    final run = scope.data.run!;
    final multi = ctrl.selecting && ctrl.selected.length > 1;
    final x = multi
        ? null
        : run.candidate(
            ctrl.selecting && ctrl.selected.length == 1
                ? ctrl.selected.first
                : ctrl.focusKey ?? '',
          );

    final Widget title;
    final Widget body;
    if (multi) {
      title = Text(l.explore_selectedN(ctrl.selected.length));
      body = _Multi(keys: [...ctrl.selected]);
    } else if (x == null) {
      title = Text(l.explore_inspector);
      body = const _Empty();
    } else {
      final round = run.rounds.where((r) => r.id == x.roundId).firstOrNull;
      title = Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(x.op != null ? l.explore_childN(x.number) : '#${x.number}'),
          if (x.op != null)
            ExplorePill(
              l.explore_genOp(
                x.generation ?? 1,
                ExploreFormat.opLabel(l, x.op!),
              ),
              tone: ExplorePillTone.evo,
            )
          else if (round != null)
            Text(
              '${l.explore_round(round.number)} · ${ExploreFormat.clock(x.createdAt ?? round.createdAt)}',
              style: UiText.sans(12, color: c.muted),
            ),
        ],
      );
      body = x.done
          ? _Single(key: ValueKey('insp-${x.key}'), candidate: x)
          : _State(candidate: x);
    }

    return Container(
      key: const Key('explore-inspector'),
      width: StyleExplorePage.inspectorWidth,
      decoration: BoxDecoration(
        color: c.panel,
        border: drawer ? null : Border(left: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WindowHeader(
            minimumInlineWidth: 0,
            inlineDragWidth: 8,
            dragBackground: true,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: SizedBox(
              height: 60,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 14,
                  right: WindowChromeScope.activeOf(context) ? 0 : 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: UiText.sans(
                          14,
                          weight: FontWeight.w700,
                          color: c.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: title,
                        ),
                      ),
                    ),
                    if (drawer)
                      UiIconBox(
                        key: const Key('explore-drawer-close'),
                        glyph: UiGlyphs.close,
                        size: 28,
                        tooltip: l.explore_hideInspector,
                        onTap: ctrl.closeDrawer,
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            Icon(StudioIcons.galleryImage, size: 30, color: c.faint),
            Text(
              context.l10n.explore_inspectorEmpty,
              textAlign: TextAlign.center,
              style: UiText.sans(12.5, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// 检查器大图（原型 `.iim`）：圆角 8、控件底，图完整显示；右上角放大、底部左右切换。
class _Image extends StatelessWidget {
  const _Image({required this.candidate, required this.height});
  final ExploreCandidate candidate;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final ctrl = scope.controller;
    final x = candidate;
    final list = ctrl.tab == ExploreTab.candidates
        ? ctrl.visibleKeys
        : scope.data.run!.lines
                  .where((e) => e.id == ctrl.lineId)
                  .firstOrNull
                  ?.current
                  .childKeys ??
              const <String>[];
    final i = list.indexOf(x.key);
    Widget btn(String glyph, String tip, VoidCallback? onTap, String key) =>
        Tooltip(
          message: tip,
          child: UiPressable(
            key: Key(key),
            onTap: onTap,
            builder: (context, hover) => Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: hover ? .62 : .45),
                borderRadius: BorderRadius.circular(7),
              ),
              child: UiGlyph(
                glyph,
                size: 15,
                color: onTap == null ? Colors.white38 : Colors.white,
              ),
            ),
          ),
        );
    return GestureDetector(
      onTap: () => ctrl.openDetail(x.key),
      child: Container(
        key: const Key('explore-inspector-image'),
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.control,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExploreImage(x.image ?? x.thumb, fit: BoxFit.contain),
            Positioned(
              top: 8,
              right: 8,
              child: btn(
                UiGlyphs.expand,
                l.explore_openLarge,
                () => ctrl.openDetail(x.key),
                'explore-inspector-open',
              ),
            ),
            if (list.length > 1)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Row(
                  children: [
                    btn(
                      UiGlyphs.chevronLeft,
                      l.explore_previous,
                      i > 0 ? () => ctrl.focus(list[i - 1]) : null,
                      'explore-inspector-prev',
                    ),
                    const Spacer(),
                    btn(
                      UiGlyphs.chevronRight,
                      l.explore_next,
                      i >= 0 && i < list.length - 1
                          ? () => ctrl.focus(list[i + 1])
                          : null,
                      'explore-inspector-next',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 单张 / 子代：图 · 本张抽到（子代：怎么来的）· 2 × 2 操作 · 分组 · 参数 —— 底部 完整提示词 / 删除。
class _Single extends StatefulWidget {
  const _Single({super.key, required this.candidate});
  final ExploreCandidate candidate;

  @override
  State<_Single> createState() => _SingleState();
}

class _SingleState extends State<_Single> {
  var _prompt = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final ctrl = scope.controller;
    final a = scope.actions;
    final run = scope.data.run!;
    final x = widget.candidate;
    final child = x.op != null;

    final List<Widget> origin;
    if (child) {
      final parents = [
        for (final k in x.parentKeys)
          if (run.candidate(k) case final p?) p,
      ];
      final color = ExploreFormat.opColor(x.op!);
      origin = [
        ExploreSect(l.explore_origin),
        ExploreBox(
          gap: 8,
          children: [
            for (final p in parents)
              UiPressable(
                onTap: () => ctrl.focus(p.key),
                builder: (context, hover) => Row(
                  spacing: 8,
                  children: [
                    Container(
                      width: 26,
                      height: 38,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ExploreImage(p.thumb ?? p.image),
                    ),
                    Expanded(
                      child: ExploreArtistsText(
                        p.atoms,
                        maxLines: 2,
                        size: 12,
                        color: hover ? c.accent : null,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              spacing: 6,
              children: [
                UiGlyph(UiGlyphs.arrowDown, size: 13, color: color),
                Expanded(
                  child: Text(
                    [ExploreFormat.opLabel(l, x.op!), ?x.opNote].join('：'),
                    style: UiText.sans(12, color: c.muted),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final atom in x.atoms)
                  ExploreAtomChip(
                    atom,
                    highlight: x.changedAtoms.contains(atom) ? color : null,
                  ),
              ],
            ),
          ],
        ),
      ];
    } else {
      origin = [
        ExploreSect(
          l.explore_drawn,
          trailing: ExploreLink(
            key: const Key('explore-copy-artists'),
            label: l.explore_copyArtists,
            glyph: UiGlyphs.copy,
            onTap: () => a.onCopyArtists([x.key]),
          ),
        ),
        for (final d in x.draws) ExploreDrawBox(d),
      ];
    }

    final acts = [
      ExploreActTile(
        key: const Key('explore-act-favorite'),
        glyph: UiGlyphs.heartLib,
        filled: x.favorite,
        on: x.favorite,
        label: x.favorite ? l.explore_favorited : l.explore_favorite,
        keyLabel: 'F',
        onTap: () => a.onSetFavorite([x.key], !x.favorite),
      ),
      if (!child)
        ExploreActTile(
          key: const Key('explore-act-evolution'),
          glyph: UiGlyphs.evo,
          color: c.evo,
          label: l.explore_addToEvolution,
          keyLabel: 'E',
          onTap: () => ctrl.startEvolution([x.key]),
        ),
      ExploreActTile(
        key: const Key('explore-act-block'),
        glyph: UiGlyphs.archive,
        label: l.explore_saveBlock,
        onTap: () => ctrl.saveBlock([x.key]),
      ),
      ExploreActTile(
        key: const Key('explore-act-apply'),
        glyph: UiGlyphs.enter,
        label: l.explore_applyToEditor,
        onTap: () => a.onApplyToEditor(x.key),
      ),
      if (child)
        ExploreActTile(
          key: const Key('explore-act-open'),
          glyph: UiGlyphs.expand,
          label: l.explore_openLarge,
          onTap: () => ctrl.openDetail(x.key),
        ),
    ];

    final kv = <(String, String)>[
      if (x.seed != null) (l.explore_seed, '${x.seed}'),
      if (x.elapsed != null)
        (l.explore_elapsed, ExploreFormat.seconds(x.elapsed!)),
      (
        l.explore_params,
        [
          '${x.width}×${x.height}',
          if (x.steps != null) l.explore_steps(x.steps!),
          if (x.scale != null) 'CFG ${ExploreFormat.scale(x.scale!)}',
        ].join(' · '),
      ),
      if (x.sampler != null) (l.explore_sampler, x.sampler!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: const Key('explore-inspector-scroll'),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Image(candidate: x, height: child ? 340 : 372),
                const SizedBox(height: 14),
                ...origin.expand((w) => [w, const SizedBox(height: 6)]),
                const SizedBox(height: 8),
                _Grid(children: acts),
                const SizedBox(height: 14),
                ExploreSect(
                  l.explore_groups,
                  trailing: Text(
                    l.explore_groupsHint,
                    style: UiText.sans(11, color: c.faint),
                  ),
                ),
                const SizedBox(height: 6),
                _GroupChips(keys: [x.key], current: x.groupId),
                const SizedBox(height: 14),
                for (final (k, v) in kv)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text(
                            k,
                            style: UiText.sans(12, color: c.muted),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(v, style: UiText.mono(12, color: c.ink)),
                        ),
                      ],
                    ),
                  ),
                if (_prompt) ...[
                  const SizedBox(height: 14),
                  ExploreSect(
                    l.explore_fullPrompt,
                    trailing: ExploreLink(
                      label: l.explore_copy,
                      glyph: UiGlyphs.copy,
                      onTap: () =>
                          Clipboard.setData(ClipboardData(text: x.prompt)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    key: const Key('explore-inspector-prompt'),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.raised,
                      border: Border.all(color: c.line),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ExplorePromptText(text: x.prompt, hits: x.hits),
                  ),
                  if (x.negative.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ExploreSect(l.explore_negative),
                    const SizedBox(height: 6),
                    Text(
                      x.negative,
                      style: UiText.sans(12, color: c.muted, height: 1.6),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Row(
            children: [
              UiBtn(
                key: const Key('explore-inspector-prompt-toggle'),
                tone: UiBtnTone.ghost,
                onTap: () => setState(() => _prompt = !_prompt),
                children: [
                  Text(l.explore_fullPrompt),
                  UiGlyph(
                    _prompt ? UiGlyphs.chevronUp : UiGlyphs.chevronDown,
                    size: 13,
                  ),
                ],
              ),
              const Spacer(),
              UiBtn(
                key: const Key('explore-inspector-delete'),
                tone: UiBtnTone.ghost,
                color: c.error,
                onTap: () => ctrl.delete([x.key]),
                children: [
                  UiGlyph(UiGlyphs.trash, size: 14, color: c.error),
                  Text(l.explore_delete),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 2 列网格（间距 6）。
class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    spacing: 6,
    children: [
      for (var i = 0; i < children.length; i += 2)
        Row(
          spacing: 6,
          children: [
            Expanded(child: children[i]),
            Expanded(
              child: i + 1 < children.length
                  ? children[i + 1]
                  : const SizedBox.shrink(),
            ),
          ],
        ),
    ],
  );
}

/// 分组胶囊（原型 `.fc`）：26 高、圆角 13、描边 + 抬起底、12 次要色；当前组强调色描边 + 7% 底 + 勾。
/// 行尾 “+ 新分组” 原地输入。
class _GroupChips extends StatefulWidget {
  const _GroupChips({required this.keys, required this.current});
  final List<String> keys;
  final String? current;

  @override
  State<_GroupChips> createState() => _GroupChipsState();
}

class _GroupChipsState extends State<_GroupChips> {
  var _adding = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final run = scope.data.run!;
    Widget chip(
      String label,
      bool on,
      VoidCallback onTap, {
      Key? key,
      String? glyph,
    }) => UiPressable(
      key: key,
      onTap: onTap,
      builder: (context, hover) => Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: on
              ? Color.alphaBlend(c.accent.withValues(alpha: .07), c.raised)
              : (hover ? c.hover : c.raised),
          border: Border.all(color: on ? c.accent : c.line),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (on)
              UiGlyph(
                UiGlyphs.check,
                size: 12,
                strokeWidth: 2.4,
                color: c.accent,
              )
            else if (glyph != null)
              UiGlyph(glyph, size: 12, color: c.faint),
            Text(
              label,
              style: UiText.sans(
                12,
                weight: on ? FontWeight.w600 : FontWeight.w400,
                color: on ? c.accent : c.muted,
              ),
            ),
          ],
        ),
      ),
    );
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final g in run.groups)
          chip(
            g.name,
            widget.current == g.id,
            () => scope.actions.onAssignGroup(
              widget.keys,
              widget.current == g.id ? null : g.id,
            ),
            key: Key('explore-insp-group-${g.id}'),
          ),
        if (_adding)
          ExploreInlineInput(
            key: const Key('explore-insp-group-input'),
            hint: l.explore_groupName,
            height: 26,
            radius: 13,
            style: UiText.sans(12, color: c.ink),
            onSubmit: (v) {
              setState(() => _adding = false);
              scope.actions.onCreateGroup(v, widget.keys);
            },
            onCancel: () => setState(() => _adding = false),
          )
        else
          chip(
            l.explore_newGroup,
            false,
            () => setState(() => _adding = true),
            key: const Key('explore-insp-new-group'),
            glyph: UiGlyphs.plus,
          ),
      ],
    );
  }
}

/// 排队 / 生成中 / 失败：占位图 + 状态说明（失败时原因和重试）。
class _State extends StatelessWidget {
  const _State({required this.candidate});
  final ExploreCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final x = candidate;
    final failed = x.state == ExploreCandidateState.failed;
    final (glyph, color, text) = switch (x.state) {
      ExploreCandidateState.failed => (
        UiGlyphs.alert,
        c.error,
        l.explore_failed,
      ),
      ExploreCandidateState.running => (
        UiGlyphs.dice,
        c.accent,
        l.explore_generatingN(x.number),
      ),
      _ => (UiGlyphs.dice, c.faint, l.explore_queued(x.number)),
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Container(
            height: 372,
            decoration: BoxDecoration(
              color: failed
                  ? Color.alphaBlend(c.error.withValues(alpha: .08), c.control)
                  : c.control,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  if (x.state == ExploreCandidateState.running)
                    const UiSpinner(size: 22)
                  else
                    UiGlyph(glyph, size: 24, color: color),
                  Text(
                    text,
                    style: UiText.sans(
                      13,
                      weight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (failed) ...[
            ExploreBox(
              children: [
                ExploreSect(l.explore_failReason, color: c.error),
                Text(
                  x.error ?? l.explore_failed,
                  style: UiText.sans(12.5, color: c.ink),
                ),
              ],
            ),
            UiBtn(
              key: const Key('explore-inspector-retry'),
              expand: true,
              onTap: ExploreScope.of(context).actions.onRetryFailed,
              children: [
                const UiGlyph(UiGlyphs.retry, size: 14),
                Text(l.explore_retryFailed),
              ],
            ),
          ] else
            Text(
              l.explore_waitHint,
              textAlign: TextAlign.center,
              style: UiText.sans(12, color: c.muted),
            ),
        ],
      ),
    );
  }
}

/// 多选：缩略图（2 列，最多 6 张，多了最后一张写 +N）· 合在一起的画师（去重）· 说明。
class _Multi extends StatelessWidget {
  const _Multi({required this.keys});
  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final run = scope.data.run!;
    final cands = [
      for (final k in keys)
        if (run.candidate(k) case final x?) x,
    ];
    final shown = cands.take(cands.length > 6 ? 5 : 6).toList();
    final more = cands.length - shown.length;
    final atoms = {for (final x in cands) ...x.atoms}.toList();
    final cells = <Widget>[
      for (final x in shown)
        AspectRatio(
          aspectRatio: x.aspect,
          child: ExploreImage(x.thumb ?? x.image, radius: 8),
        ),
      if (more > 0)
        AspectRatio(
          aspectRatio: shown.first.aspect,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.control,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$more',
              style: UiText.mono(16, weight: FontWeight.w600, color: c.muted),
            ),
          ),
        ),
    ];
    return SingleChildScrollView(
      key: const Key('explore-inspector-multi'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          _Grid(children: cells),
          ExploreSect(
            l.explore_mergedArtists(atoms.length),
            trailing: ExploreLink(
              label: l.explore_copyArtists,
              glyph: UiGlyphs.copy,
              onTap: () => scope.actions.onCopyArtists(keys),
            ),
          ),
          ExploreBox(
            children: [
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [for (final a in atoms) ExploreAtomChip(a)],
              ),
            ],
          ),
          Text(l.explore_multiHint, style: UiText.sans(11, color: c.faint)),
          const SizedBox(height: 4),
          ExploreSect(l.explore_groups),
          _GroupChips(
            keys: keys,
            current: cands.every((x) => x.groupId == cands.first.groupId)
                ? cands.first.groupId
                : null,
          ),
        ],
      ),
    );
  }
}
