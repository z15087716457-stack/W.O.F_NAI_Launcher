import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_block_pill.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_slider.dart';
import '../kit/ui_text.dart';
import 'blocks_contract.dart';
import 'blocks_format.dart';
import 'blocks_parts.dart';

/// 点开药丸的实例卡（宽 348）。“调整”进抽取规则面板（宽 452），同一个浮层里切换，点“完成”才写回。
///
/// 定位、翻转、点外面关闭仍由接线方的 `buildPillInstanceOverlayEntry` 负责；这里只画卡片本身。
class BlockInstanceCard extends StatefulWidget {
  const BlockInstanceCard({
    super.key,
    required this.data,
    required this.actions,
    this.initialRules = false,
  });

  final BlockInstanceViewData data;
  final BlockInstanceActions actions;

  /// 直接打开抽取规则（预览 / 测试用）。
  final bool initialRules;

  static const width = 348.0;
  static const rulesWidth = 452.0;

  @override
  State<BlockInstanceCard> createState() => _BlockInstanceCardState();
}

class _BlockInstanceCardState extends State<BlockInstanceCard> {
  late var _rules = widget.initialRules;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, a) => FadeTransition(opacity: a, child: child),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, ?current],
      ),
      child: _rules
          ? _RulesPanel(
              key: const Key('block-rules'),
              data: widget.data,
              actions: widget.actions,
              onBack: () => setState(() => _rules = false),
            )
          : _Card(
              key: const Key('block-card'),
              data: widget.data,
              actions: widget.actions,
              onRules: () => setState(() => _rules = true),
            ),
    );
  }
}

class _Card extends StatefulWidget {
  const _Card({
    super.key,
    required this.data,
    required this.actions,
    required this.onRules,
  });
  final BlockInstanceViewData data;
  final BlockInstanceActions actions;
  final VoidCallback onRules;

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  var _negative = false;
  UiPopoverAnchor? _menu;

  BlockInstanceViewData get d => widget.data;
  BlockInstanceActions get a => widget.actions;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final b = d.block;
    final s = d.settings;
    final col = b.color;

    List<UiMenuItem> menu() => [
      UiMenuItem(
        glyph: UiGlyphs.external,
        label: l10n.blocks_showInLibrary,
        onTap: a.onShowInLibrary,
      ),
      UiMenuItem(
        glyph: UiGlyphs.copy,
        label: l10n.blocks_copySend,
        onTap: a.onCopySend,
      ),
      if (a.onEvolutionChanged != null && d.evolution != null)
        UiMenuItem(
          glyph: UiGlyphs.evo,
          label: d.evolution!
              ? l10n.blocks_evolutionOff
              : l10n.blocks_evolutionOn,
          enabled: d.enabled,
          onTap: () => a.onEvolutionChanged!(!d.evolution!),
        ),
      UiMenuItem(
        glyph: UiGlyphs.trash,
        label: l10n.blocks_removeInstance,
        danger: true,
        divider: true,
        onTap: a.onRemove,
      ),
    ];

    final more = Builder(
      builder: (ctx) => UiIconBox(
        key: const Key('block-card-more'),
        glyph: UiGlyphs.more,
        glyphSize: 16,
        size: 28,
        color: b.thumb != null ? Colors.white : null,
        tooltip: l10n.blocks_more,
        onTap: () {
          final box = ctx.findRenderObject()! as RenderBox;
          setState(
            () => _menu = UiPopoverAnchor(
              box.localToGlobal(box.size.bottomRight(const Offset(0, 4))),
              alignRight: true,
            ),
          );
        },
      ),
    );

    final Widget head = b.thumb != null
        ? SizedBox(
            key: const Key('block-card-thumb'),
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                BlockCover(b),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [.4, 1],
                      colors: [Color(0x00000000), Color(0x8C000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 6,
                  bottom: 6,
                  child: Row(
                    spacing: 8,
                    children: [
                      UiBlockIcon(b.icon, size: 16, color: Colors.white),
                      Expanded(
                        child: Text(
                          b.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(
                            15,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (b.folderName != null)
                        Text(
                          b.folderName!,
                          style: UiText.sans(
                            12,
                            color: Colors.white.withValues(alpha: .85),
                          ),
                        ),
                      more,
                    ],
                  ),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              spacing: 8,
              children: [
                UiBlockIcon(b.icon, size: 16, color: col),
                Expanded(
                  child: Text(
                    d.missing ? l10n.blocks_missing : b.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(
                      14.5,
                      weight: FontWeight.w700,
                      color: d.missing ? c.error : c.ink,
                    ),
                  ),
                ),
                if (b.folderName != null)
                  Text(b.folderName!, style: UiText.sans(12, color: c.faint)),
                more,
              ],
            ),
          );

    final pool = b.atoms.length;
    final body = <Widget>[
      if (s.mode != BlockMode.fixed)
        Row(
          spacing: 6,
          children: [
            UiGlyph(BlocksFormat.modeGlyph(s.mode), size: 13, color: c.muted),
            Expanded(
              child: Text(
                s.mode == BlockMode.random
                    ? l10n.blocks_summaryRandom(
                        BlocksFormat.range(s.countMin, s.countMax),
                        pool,
                      )
                    : l10n.blocks_summarySequential(
                        BlocksFormat.range(s.countMin, s.countMax),
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(12, color: c.muted),
              ),
            ),
          ],
        ),
      if (s.mode == BlockMode.random) _randomBox(context),
      if (s.mode == BlockMode.sequential) _seqBox(context),
      if (s.mode == BlockMode.fixed) ...[
        BlockLabel(
          l10n.blocks_content,
          count: l10n.blocks_items(
            _negative ? b.negativeAtoms.length : b.atoms.length,
          ),
          trailing: b.hasNegative && b.atoms.isNotEmpty
              ? BlockSeg<bool>(
                  mini: true,
                  values: const [false, true],
                  selected: _negative,
                  keyOf: (v) => Key('block-card-content-${v ? 'neg' : 'pos'}'),
                  labelOf: (v) => v
                      ? l10n.blocks_negativeN(b.negativeAtoms.length)
                      : l10n.blocks_positive,
                  onTap: (v) => setState(() => _negative = v),
                )
              : null,
        ),
        BlockAtoms(
          _negative ? b.negativeAtoms : b.atoms,
          mono: true,
          fontSize: 11,
          max: 24,
        ),
      ],
      if (b.hasParams) _paramsBox(context),
    ];

    final card = UiPopoverSurface(
      width: BlockInstanceCard.width,
      child: Opacity(
        opacity: d.enabled ? 1 : .55,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            head,
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: body,
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      BlockLabel(l10n.blocks_drawMode),
                      const Spacer(),
                      BlockSeg<BlockMode>(
                        key: const Key('block-card-modes'),
                        values: BlockMode.values,
                        selected: s.mode,
                        keyOf: (m) => Key('block-card-mode-${m.name}'),
                        labelOf: (m) => BlocksFormat.mode(context, m),
                        glyphOf: BlocksFormat.modeGlyph,
                        onTap: a.onModeChanged,
                      ),
                    ],
                  ),
                  if (s.mode == BlockMode.fixed)
                    Text(
                      l10n.blocks_fixedExplain(b.itemCount),
                      style: UiText.sans(11, color: c.faint, height: 1.5),
                    )
                  else
                    _RuleRow(settings: s, onTap: widget.onRules),
                ],
              ),
            ),
            Container(
              key: const Key('block-card-footer'),
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: BoxDecoration(
                color: c.panel,
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Row(
                spacing: 6,
                children: [
                  if (d.side case final side?) ...[
                    Text(
                      l10n.blocks_appliesTo,
                      style: UiText.sans(12, color: c.muted),
                    ),
                    BlockSeg<BlockScopeSide>(
                      key: const Key('block-card-side'),
                      mini: true,
                      values: const [
                        BlockScopeSide.positive,
                        BlockScopeSide.negative,
                      ],
                      isOn: (v) => side == BlockScopeSide.both || side == v,
                      enabledOf: (v) =>
                          v == BlockScopeSide.positive || b.hasNegative,
                      keyOf: (v) => Key('block-card-side-${v.name}'),
                      labelOf: (v) => v == BlockScopeSide.positive
                          ? l10n.blocks_positive
                          : l10n.blocks_negative,
                      onTap: (v) {
                        // 至少留一面：点掉唯一亮着的那面不生效。
                        final pos = side != BlockScopeSide.negative;
                        final neg = side != BlockScopeSide.positive;
                        final p2 = v == BlockScopeSide.positive ? !pos : pos;
                        final n2 = v == BlockScopeSide.negative ? !neg : neg;
                        if (!p2 && !n2) return;
                        a.onSideChanged(
                          p2 && n2
                              ? BlockScopeSide.both
                              : (p2
                                    ? BlockScopeSide.positive
                                    : BlockScopeSide.negative),
                        );
                      },
                    ),
                  ],
                  const Spacer(),
                  UiBtn(
                    key: const Key('block-card-toggle'),
                    size: UiBtnSize.small,
                    tone: UiBtnTone.ghost,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    onTap: () => a.onEnabledChanged(!d.enabled),
                    children: [
                      UiGlyph(
                        d.enabled ? UiGlyphs.eye : UiGlyphs.eyeOff,
                        size: 14,
                      ),
                      Text(
                        d.enabled ? l10n.blocks_disable : l10n.blocks_enable,
                      ),
                    ],
                  ),
                  UiBtn(
                    key: const Key('block-card-edit'),
                    size: UiBtnSize.small,
                    tone: UiBtnTone.ghost,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    onTap: d.missing ? null : a.onEditBlock,
                    children: [
                      const UiGlyph(UiGlyphs.pencil, size: 14),
                      Text(l10n.blocks_editBlock),
                    ],
                  ),
                  UiBtn(
                    key: const Key('block-card-remove'),
                    size: UiBtnSize.small,
                    tone: UiBtnTone.ghost,
                    color: c.error,
                    tooltip: l10n.blocks_removeInstanceTip,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    onTap: a.onRemove,
                    children: const [UiGlyph(UiGlyphs.trash, size: 14)],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return UiPopover(
      anchor: _menu,
      onDismiss: () => setState(() => _menu = null),
      builder: (_) =>
          UiMenu(items: menu(), onClose: () => setState(() => _menu = null)),
      child: card,
    );
  }

  /// 抽到框（原型 `.rollbox`）：圆角 9、内边距 10、块色 6% 底 + 块色 22% 内描边。
  Widget _rollBox(BuildContext context, List<Widget> children) {
    final c = context.ui;
    final col = d.block.color;
    return Container(
      key: const Key('block-card-roll'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(col.withValues(alpha: .06), c.raised),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: col.withValues(alpha: .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _lockButton(BuildContext context) {
    final l10n = context.l10n;
    return UiBtn(
      key: const Key('block-card-lock'),
      size: UiBtnSize.small,
      tone: UiBtnTone.ghost,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      tooltip: d.locked ? l10n.blocks_unlockTip : l10n.blocks_lockTip,
      onTap: () => a.onLockChanged(!d.locked),
      children: [
        UiGlyph(d.locked ? UiGlyphs.lock : UiGlyphs.unlock, size: 14),
        Text(d.locked ? l10n.blocks_unlock : l10n.blocks_lock),
      ],
    );
  }

  Widget _randomBox(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final col = d.block.color;
    return _rollBox(context, [
      Row(
        spacing: 6,
        children: [
          BlockLabel(
            l10n.blocks_drawnThisTime,
            color: Color.lerp(c.ink, col, .7),
          ),
          const Spacer(),
          _lockButton(context),
          UiBtn(
            key: const Key('block-card-reroll'),
            size: UiBtnSize.small,
            tooltip: d.locked ? l10n.blocks_rerollLocked : null,
            onTap: d.locked ? null : a.onReroll,
            children: [
              const UiGlyph(UiGlyphs.dice, size: 14),
              Text(l10n.blocks_reroll),
            ],
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (d.skipped)
        Text(
          l10n.blocks_skipped(BlocksFormat.percent(d.settings.probability)),
          style: UiText.sans(12, color: c.muted),
        )
      else
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            for (final x in d.drawn)
              BlockAtom(BlocksFormat.short(x.text), hit: col, weight: x.weight),
          ],
        ),
      if (d.send.isNotEmpty && !d.skipped) ...[
        const SizedBox(height: 8),
        Text(
          l10n.blocks_sendPrefix(d.send),
          style: UiText.mono(11, color: c.faint, height: 1.5),
        ),
      ],
    ]);
  }

  Widget _seqBox(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final col = d.block.color;
    final total = math.max(1, d.block.atoms.length);
    final cur = d.seqIndex.clamp(0, total - 1);
    final current = d.drawn.isNotEmpty
        ? d.drawn
        : [BlockDrawn(d.block.atoms.isEmpty ? '' : d.block.atoms[cur])];
    Widget step(String glyph, int delta, Key key, String tip) => UiPressable(
      key: key,
      onTap: () => a.onStep(delta),
      builder: (context, hover) => Tooltip(
        message: tip,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hover ? c.hover : c.raised,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.line),
          ),
          child: UiGlyph(glyph, size: 16, color: c.ink),
        ),
      ),
    );
    return _rollBox(context, [
      Row(
        spacing: 6,
        children: [
          BlockLabel(
            l10n.blocks_seqPosition(cur + 1, total),
            color: Color.lerp(c.ink, col, .7),
          ),
          Expanded(
            child: d.locked
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    spacing: 3,
                    children: [
                      UiGlyph(UiGlyphs.lock, size: 12, color: c.warn),
                      Flexible(
                        child: Text(
                          l10n.blocks_seqLocked,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(11, color: c.warn),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          _lockButton(context),
        ],
      ),
      const SizedBox(height: 8),
      _Progress(index: cur, count: d.seqCount, total: total, color: col),
      const SizedBox(height: 10),
      Row(
        spacing: 8,
        children: [
          step(
            UiGlyphs.arrowLeft,
            -1,
            const Key('block-card-step-prev'),
            l10n.blocks_prevItem,
          ),
          Expanded(
            child: BlockAtom(
              current.map((x) => x.text).join(', '),
              hit: col,
              weight: current.length == 1 ? current.first.weight : null,
              height: 34,
              fontSize: 13,
              expand: true,
            ),
          ),
          step(
            UiGlyphs.arrowRight,
            1,
            const Key('block-card-step-next'),
            l10n.blocks_nextItem,
          ),
        ],
      ),
      const SizedBox(height: 7),
      DefaultTextStyle.merge(
        style: UiText.sans(11, color: c.faint),
        child: Row(
          children: [
            Expanded(
              child: Text(
                d.prevText == null ? '' : l10n.blocks_prevValue(d.prevText!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                d.nextText == null ? '' : l10n.blocks_nextValue(d.nextText!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _paramsBox(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final p = d.block.params!;
    return Container(
      key: const Key('block-card-params'),
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(c.accent.withValues(alpha: .06), c.control),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: UiGlyph(UiGlyphs.bolt, size: 14, color: c.accent),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.blocks_paramsTitle,
                  style: UiText.sans(12, weight: FontWeight.w600, color: c.ink),
                ),
                Text(
                  BlocksFormat.params(context, p, d.catalog),
                  style: UiText.sans(11, color: c.muted),
                ),
                if (p.incompatible != null)
                  Text(p.incompatible!, style: UiText.sans(11, color: c.warn)),
              ],
            ),
          ),
          UiBtn(
            key: const Key('block-card-apply'),
            size: UiBtnSize.small,
            tone: UiBtnTone.primary,
            onTap: p.incompatible == null ? a.onApplyParams : null,
            children: [Text(l10n.blocks_apply)],
          ),
        ],
      ),
    );
  }
}

/// 顺序进度：池不超过 60 项时一项一格（6 高、间距 2；走过的块色 45%、当前块色），否则连续进度条。
class _Progress extends StatelessWidget {
  const _Progress({
    required this.index,
    required this.count,
    required this.total,
    required this.color,
  });
  final int index;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    if (total > 60) {
      return LayoutBuilder(
        builder: (context, box) => Container(
          height: 6,
          decoration: BoxDecoration(
            color: c.control,
            borderRadius: BorderRadius.circular(3),
          ),
          alignment: Alignment.centerLeft,
          child: Container(
            width: box.maxWidth * ((index + count) / total).clamp(0, 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 6,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 2,
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: i < index
                      ? color.withValues(alpha: .45)
                      : i < index + count
                      ? color
                      : c.control,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 规则摘要行（原型 `.rule`）：34 高、圆角 8、控件底、12 号；右端“调整 ›”。
class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.settings, required this.onTap});
  final BlockRollSettings settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final s = settings;
    final b = UiText.sans(12, weight: FontWeight.w600, color: c.ink);
    final dot = TextSpan(
      text: '  ·  ',
      style: TextStyle(color: c.faint),
    );
    final spans = s.mode == BlockMode.random
        ? [
            TextSpan(text: l10n.blocks_ruleCount),
            TextSpan(
              text: ' ${BlocksFormat.range(s.countMin, s.countMax)}',
              style: b,
            ),
            dot,
            TextSpan(text: l10n.blocks_ruleWeight),
            if (s.weightEnabled) ...[
              TextSpan(text: ' ${BlocksFormat.weightRange(s)}', style: b),
              TextSpan(text: ' ${BlocksFormat.dispersion(context, s)}'),
            ] else
              TextSpan(text: ' ${l10n.blocks_off}', style: b),
            dot,
            TextSpan(text: l10n.blocks_ruleShow),
            TextSpan(text: ' ${BlocksFormat.percent(s.probability)}', style: b),
          ]
        : [
            TextSpan(text: l10n.blocks_ruleEach),
            TextSpan(
              text: ' ${BlocksFormat.range(s.countMin, s.countMax)} ',
              style: b,
            ),
            TextSpan(text: l10n.blocks_ruleItemUnit),
            dot,
            TextSpan(text: l10n.blocks_ruleShow),
            TextSpan(text: ' ${BlocksFormat.percent(s.probability)}', style: b),
            dot,
            TextSpan(text: l10n.blocks_ruleWrap),
          ];
    return UiPressable(
      key: const Key('block-card-rules'),
      onTap: onTap,
      builder: (context, hover) => Container(
        height: 34,
        padding: const EdgeInsets.only(left: 10, right: 6),
        decoration: BoxDecoration(
          color: hover ? c.hover : c.control,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(children: spans),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(12, color: c.ink),
              ),
            ),
            Text(
              l10n.blocks_adjust,
              style: UiText.sans(12, weight: FontWeight.w500, color: c.accent),
            ),
            UiGlyph(UiGlyphs.chevronRight, size: 13, color: c.accent),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── 抽取规则 ─────────────────────────────

class _RulesPanel extends StatefulWidget {
  const _RulesPanel({
    super.key,
    required this.data,
    required this.actions,
    required this.onBack,
  });
  final BlockInstanceViewData data;
  final BlockInstanceActions actions;
  final VoidCallback onBack;

  @override
  State<_RulesPanel> createState() => _RulesPanelState();
}

class _RulesPanelState extends State<_RulesPanel> {
  late var _s = widget.data.settings.mode == BlockMode.fixed
      ? widget.data.settings.copyWith(mode: BlockMode.random)
      : widget.data.settings;
  var _advanced = false;
  var _samples = const <List<BlockDrawn>>[];

  bool get _dirty => _s != widget.data.settings;

  @override
  void initState() {
    super.initState();
    _resample();
  }

  void _set(BlockRollSettings s) {
    setState(() => _s = s);
    _resample();
  }

  void _resample() => setState(() => _samples = widget.actions.sample(_s, 4));

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final b = widget.data.block;
    final s = _s;
    final pool = b.atoms.length;

    Widget section(List<Widget> children, {Color? color, Key? key}) =>
        Container(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 9,
            children: children,
          ),
        );
    final title = UiText.sans(13, weight: FontWeight.w600, color: c.ink);
    final m12 = UiText.sans(12, color: c.muted);
    final f11 = UiText.sans(11, color: c.faint);

    Widget modeCard(BlockMode m, String desc) {
      final on = s.mode == m;
      return Expanded(
        child: UiPressable(
          key: Key('block-rules-mode-${m.name}'),
          onTap: () => _set(s.copyWith(mode: m)),
          builder: (context, hover) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: on
                  ? Color.alphaBlend(c.accent.withValues(alpha: .04), c.raised)
                  : (hover ? c.hover : c.raised),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: on ? c.accent : c.line),
              boxShadow: on
                  ? [
                      BoxShadow(
                        color: c.accent.withValues(alpha: .13),
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    UiGlyph(
                      BlocksFormat.modeGlyph(m),
                      size: 15,
                      color: on ? c.accent : c.ink,
                    ),
                    Text(
                      BlocksFormat.mode(context, m),
                      style: UiText.sans(
                        13,
                        weight: FontWeight.w600,
                        color: on ? c.accent : c.ink,
                      ),
                    ),
                  ],
                ),
                Text(
                  desc,
                  style: UiText.sans(11.5, color: c.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final random = s.mode == BlockMode.random;
    final fixed = s.mode == BlockMode.fixed;

    final panel = UiPopoverSurface(
      width: BlockInstanceCard.rulesWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.only(left: 10, right: 14),
            child: Row(
              spacing: 8,
              children: [
                UiIconBox(
                  key: const Key('block-rules-back'),
                  glyph: UiGlyphs.chevronLeft,
                  glyphSize: 17,
                  size: 28,
                  tooltip: l10n.blocks_back,
                  onTap: widget.onBack,
                ),
                Text(
                  l10n.blocks_rulesTitle,
                  style: UiText.sans(14, weight: FontWeight.w700, color: c.ink),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: BlockPill(
                      b,
                      badge: switch (s.mode) {
                        BlockMode.fixed => UiBlockBadge.none,
                        BlockMode.sequential => UiBlockBadge.sequential,
                        BlockMode.random => UiBlockBadge.random,
                      },
                    ),
                  ),
                ),
                Text(
                  _dirty ? l10n.blocks_rulesDirty : l10n.blocks_rulesHint,
                  key: const Key('block-rules-status'),
                  style: UiText.sans(11, color: _dirty ? c.accent : c.faint),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: c.line)),
                    ),
                    child: Row(
                      spacing: 8,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        modeCard(BlockMode.fixed, l10n.blocks_modeFixedDesc),
                        modeCard(
                          BlockMode.sequential,
                          l10n.blocks_modeSequentialDesc,
                        ),
                        modeCard(BlockMode.random, l10n.blocks_modeRandomDesc),
                      ],
                    ),
                  ),
                  if (!fixed)
                    section([
                      Row(
                        spacing: 8,
                        children: [
                          Text(
                            random
                                ? l10n.blocks_drawEach
                                : l10n.blocks_takeEach,
                            style: title,
                          ),
                          UiNumBox(
                            key: const Key('block-rules-min'),
                            value: s.countMin.toDouble(),
                            decimals: 0,
                            min: 1,
                            max: math.max(1, pool).toDouble(),
                            large: true,
                            onSubmitted: (v) => _set(
                              s.copyWith(
                                countMin: v.round(),
                                countMax: math.max(v.round(), s.countMax),
                              ),
                            ),
                          ),
                          Text(l10n.blocks_to, style: m12),
                          UiNumBox(
                            key: const Key('block-rules-max'),
                            value: s.countMax.toDouble(),
                            decimals: 0,
                            min: 1,
                            max: math.max(1, pool).toDouble(),
                            large: true,
                            onSubmitted: (v) => _set(
                              s.copyWith(
                                countMax: v.round(),
                                countMin: math.min(v.round(), s.countMin),
                              ),
                            ),
                          ),
                          Text(l10n.blocks_itemUnit, style: m12),
                          const Spacer(),
                          Text(l10n.blocks_poolSize(pool), style: f11),
                        ],
                      ),
                      if (random)
                        Row(
                          spacing: 8,
                          children: [
                            Text(l10n.blocks_outputOrder, style: m12),
                            BlockSeg<BlockOrder>(
                              key: const Key('block-rules-order'),
                              values: BlockOrder.values,
                              selected: s.order,
                              keyOf: (o) => Key('block-rules-order-${o.name}'),
                              labelOf: (o) => o == BlockOrder.drawn
                                  ? l10n.blocks_orderDrawn
                                  : l10n.blocks_orderOriginal,
                              onTap: (o) => _set(s.copyWith(order: o)),
                            ),
                          ],
                        )
                      else
                        Text(l10n.blocks_seqExplain, style: f11),
                    ]),
                  if (!fixed)
                    section([
                      Row(
                        spacing: 8,
                        children: [
                          Text(l10n.blocks_randomWeight, style: title),
                          Expanded(
                            child: Text(
                              l10n.blocks_randomWeightHint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: f11,
                            ),
                          ),
                          UiPressable(
                            key: const Key('block-rules-weight'),
                            onTap: () => _set(
                              s.copyWith(weightEnabled: !s.weightEnabled),
                            ),
                            builder: (_, _) => UiSwitch(
                              value: s.weightEnabled,
                              width: 30,
                              height: 18,
                            ),
                          ),
                        ],
                      ),
                      if (s.weightEnabled) ...[
                        _Histogram(settings: s),
                        _WeightRange(
                          settings: s,
                          onChanged: (v) => setState(() => _s = v),
                          onEnd: _set,
                        ),
                        Row(
                          spacing: 8,
                          children: [
                            Text(l10n.blocks_weightMin, style: m12),
                            UiNumBox(
                              key: const Key('block-rules-wmin'),
                              value: s.weightMin,
                              decimals: 1,
                              min: BlockRollSettings.weightFloor,
                              max: BlockRollSettings.weightCeiling,
                              large: true,
                              onSubmitted: (v) =>
                                  _set(_clampWeights(s.copyWith(weightMin: v))),
                            ),
                            Text(l10n.blocks_weightAverage, style: m12),
                            UiNumBox(
                              key: const Key('block-rules-wavg'),
                              value: s.weightAverage,
                              decimals: 1,
                              min: BlockRollSettings.weightFloor,
                              max: BlockRollSettings.weightCeiling,
                              large: true,
                              onSubmitted: (v) => _set(
                                _clampWeights(s.copyWith(weightAverage: v)),
                              ),
                            ),
                            Text(l10n.blocks_weightMax, style: m12),
                            UiNumBox(
                              key: const Key('block-rules-wmax'),
                              value: s.weightMax,
                              decimals: 1,
                              min: BlockRollSettings.weightFloor,
                              max: BlockRollSettings.weightCeiling,
                              large: true,
                              onSubmitted: (v) =>
                                  _set(_clampWeights(s.copyWith(weightMax: v))),
                            ),
                          ],
                        ),
                        Row(
                          spacing: 8,
                          children: [
                            Text(l10n.blocks_distribution, style: m12),
                            BlockSeg<double>(
                              values: const [
                                BlockRollSettings.focused,
                                BlockRollSettings.balanced,
                                BlockRollSettings.spread,
                              ],
                              selected: BlocksFormat.preset(s),
                              keyOf: (v) => Key('block-rules-dist-$v'),
                              labelOf: (v) => switch (v) {
                                BlockRollSettings.focused =>
                                  l10n.blocks_distFocused,
                                BlockRollSettings.balanced =>
                                  l10n.blocks_distBalanced,
                                _ => l10n.blocks_distSpread,
                              },
                              onTap: (v) => _set(
                                s.copyWith(
                                  leftDispersion: v,
                                  rightDispersion: v,
                                ),
                              ),
                            ),
                            const Spacer(),
                            UiPressable(
                              key: const Key('block-rules-advanced'),
                              onTap: () =>
                                  setState(() => _advanced = !_advanced),
                              builder: (context, hover) => Row(
                                spacing: 2,
                                children: [
                                  Text(
                                    l10n.blocks_advanced,
                                    style: UiText.sans(12, color: c.accent),
                                  ),
                                  UiGlyph(
                                    _advanced
                                        ? UiGlyphs.chevronUp
                                        : UiGlyphs.chevronDown,
                                    size: 13,
                                    color: c.accent,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_advanced) ...[
                          _SliderRow(
                            label: l10n.blocks_leftDispersion,
                            value: s.leftDispersion,
                            onChanged: (v) => setState(
                              () => _s = s.copyWith(leftDispersion: v),
                            ),
                            onEnd: (v) => _set(s.copyWith(leftDispersion: v)),
                          ),
                          _SliderRow(
                            label: l10n.blocks_rightDispersion,
                            value: s.rightDispersion,
                            onChanged: (v) => setState(
                              () => _s = s.copyWith(rightDispersion: v),
                            ),
                            onEnd: (v) => _set(s.copyWith(rightDispersion: v)),
                          ),
                          Row(
                            spacing: 8,
                            children: [
                              Text(l10n.blocks_softBalance, style: m12),
                              Expanded(
                                child: Text(
                                  l10n.blocks_softBalanceHint,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: f11,
                                ),
                              ),
                              UiPressable(
                                key: const Key('block-rules-soft'),
                                onTap: () => _set(
                                  s.copyWith(softBalance: !s.softBalance),
                                ),
                                builder: (_, _) =>
                                    UiSwitch(value: s.softBalance),
                              ),
                            ],
                          ),
                          if (s.softBalance)
                            _SliderRow(
                              label: l10n.blocks_softBalanceStrength,
                              value: s.softBalanceStrength,
                              onChanged: (v) => setState(
                                () => _s = s.copyWith(softBalanceStrength: v),
                              ),
                              onEnd: (v) =>
                                  _set(s.copyWith(softBalanceStrength: v)),
                            ),
                        ],
                      ],
                    ]),
                  section([
                    Row(
                      spacing: 8,
                      children: [
                        Text(l10n.blocks_probability, style: title),
                        const Spacer(),
                        UiNumBox(
                          key: const Key('block-rules-prob'),
                          value: s.probability * 100,
                          decimals: 0,
                          max: 100,
                          suffix: '%',
                          large: true,
                          onSubmitted: (v) =>
                              _set(s.copyWith(probability: v / 100)),
                        ),
                      ],
                    ),
                    UiSlider(
                      value: s.probability,
                      onChanged: (v) =>
                          setState(() => _s = s.copyWith(probability: v)),
                      onChangeEnd: (v) => _set(s.copyWith(probability: v)),
                    ),
                    Text(l10n.blocks_probabilityHint, style: f11),
                  ]),
                  if (!fixed)
                    section(color: c.panel, [
                      Row(
                        spacing: 8,
                        children: [
                          Text(l10n.blocks_preview, style: title),
                          Text(l10n.blocks_previewHint, style: f11),
                          const Spacer(),
                          UiBtn(
                            key: const Key('block-rules-resample'),
                            size: UiBtnSize.small,
                            onTap: _resample,
                            children: [
                              const UiGlyph(UiGlyphs.dice, size: 13),
                              Text(l10n.blocks_resample),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        key: const Key('block-rules-sample'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: c.panel,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: c.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final row in _samples)
                              Text.rich(
                                TextSpan(
                                  children: [
                                    for (final (i, x) in row.indexed) ...[
                                      if (i > 0) const TextSpan(text: ', '),
                                      if (x.weight != null) ...[
                                        TextSpan(
                                          text: BlocksFormat.num1(x.weight!),
                                          style: TextStyle(color: c.accent),
                                        ),
                                        TextSpan(text: '::${x.text}::'),
                                      ] else
                                        TextSpan(text: x.text),
                                    ],
                                    if (row.isEmpty)
                                      TextSpan(
                                        text: l10n.blocks_sampleSkipped,
                                        style: TextStyle(color: c.faint),
                                      ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: UiText.mono(
                                  11.5,
                                  color: c.ink,
                                  height: 1.65,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: Row(
              spacing: 8,
              children: [
                UiPressable(
                  key: const Key('block-rules-reset'),
                  onTap: () => _set(BlockRollSettings(mode: s.mode)),
                  builder: (context, hover) => Text(
                    l10n.blocks_resetDefault,
                    style: UiText.sans(12, color: c.accent).copyWith(
                      decoration: hover ? TextDecoration.underline : null,
                      decorationColor: c.accent,
                    ),
                  ),
                ),
                const Spacer(),
                UiBtn(
                  key: const Key('block-rules-cancel'),
                  onTap: () {
                    setState(() => _s = widget.data.settings);
                    widget.onBack();
                  },
                  children: [Text(l10n.blocks_discard)],
                ),
                UiBtn(
                  key: const Key('block-rules-done'),
                  tone: UiBtnTone.primary,
                  onTap: () {
                    if (_dirty) widget.actions.onSaveSettings(_s);
                    widget.onBack();
                  },
                  children: [Text(l10n.blocks_done)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return panel;
  }

  static BlockRollSettings _clampWeights(BlockRollSettings s) {
    final lo = math.min(s.weightMin, s.weightMax);
    final hi = math.max(s.weightMin, s.weightMax);
    return s.copyWith(
      weightMin: lo,
      weightMax: hi,
      weightAverage: s.weightAverage.clamp(lo, hi),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onEnd,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onEnd;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Row(
      spacing: 10,
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: UiText.sans(12, color: c.muted)),
        ),
        Expanded(
          child: UiSlider(
            value: value,
            onChanged: onChanged,
            onChangeEnd: onEnd,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            value.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: UiText.mono(11.5, color: c.muted),
          ),
        ),
      ],
    );
  }
}

/// 权重分布图（原型 `distSvg`）：高 64，−3…3 轴上 22 根柱（强调色 25%–85%），“最常见”一条虚线。
class _Histogram extends StatelessWidget {
  const _Histogram({required this.settings});
  final BlockRollSettings settings;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return CustomPaint(
      size: const Size.fromHeight(66),
      painter: _HistPainter(
        settings,
        BlocksFormat.histogram(settings, 22),
        c.accent,
        c.ink,
        c.line,
      ),
    );
  }
}

class _HistPainter extends CustomPainter {
  _HistPainter(this.s, this.bars, this.accent, this.ink, this.base);
  final BlockRollSettings s;
  final List<double> bars;
  final Color accent;
  final Color ink;
  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    const h = 64.0;
    double x(double v) => (v + 3) / 6 * size.width;
    canvas.drawLine(
      const Offset(0, h + .5),
      Offset(size.width, h + .5),
      Paint()..color = base,
    );
    final bw = (x(s.weightMax) - x(s.weightMin)) / bars.length;
    for (final (i, v) in bars.indexed) {
      final bh = 3 + v * (h - 7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x(s.weightMin) + i * bw + .5,
            h - bh,
            math.max(.5, bw - 1.5),
            bh,
          ),
          const Radius.circular(1.5),
        ),
        Paint()..color = accent.withValues(alpha: (25 + v * 60) / 100),
      );
    }
    final ax = x(s.weightAverage);
    final dash = Paint()
      ..color = ink
      ..strokeWidth = 1.2;
    for (var y = 0.0; y < h; y += 6) {
      canvas.drawLine(Offset(ax, y), Offset(ax, math.min(h, y + 3)), dash);
    }
  }

  @override
  bool shouldRepaint(_HistPainter old) => old.s != s || old.accent != accent;
}

/// 三钮范围条（原型 `.rng`）：3px 控件底槽 + 强调色填充；最小 / 最大是 15px 白底强调色描边圆钮，
/// “最常见”是 11px 正文色实心钮；下面 −3…3 刻度。拖动时按 0.1 取整，拖最近的钮。
class _WeightRange extends StatefulWidget {
  const _WeightRange({
    required this.settings,
    required this.onChanged,
    required this.onEnd,
  });
  final BlockRollSettings settings;
  final ValueChanged<BlockRollSettings> onChanged;
  final ValueChanged<BlockRollSettings> onEnd;

  @override
  State<_WeightRange> createState() => _WeightRangeState();
}

class _WeightRangeState extends State<_WeightRange> {
  int? _thumb;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        double v(double dx) =>
            ((dx / w * 6 - 3).clamp(-3.0, 3.0) * 10).roundToDouble() / 10;
        double px(double val) => (val + 3) / 6 * w;
        BlockRollSettings apply(int t, double val) {
          final s = widget.settings;
          return switch (t) {
            0 => s.copyWith(weightMin: math.min(val, s.weightAverage)),
            1 => s.copyWith(weightAverage: val.clamp(s.weightMin, s.weightMax)),
            _ => s.copyWith(weightMax: math.max(val, s.weightAverage)),
          };
        }

        int nearest(double dx) {
          final s = widget.settings;
          final d = [
            s.weightMin,
            s.weightAverage,
            s.weightMax,
          ].map((e) => (px(e) - dx).abs()).toList();
          var best = 0;
          for (var i = 1; i < 3; i++) {
            if (d[i] <= d[best]) best = i;
          }
          return best;
        }

        return GestureDetector(
          key: const Key('block-rules-range'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (e) => _thumb = nearest(e.localPosition.dx),
          onHorizontalDragUpdate: (e) =>
              widget.onChanged(apply(_thumb ?? 1, v(e.localPosition.dx))),
          onHorizontalDragEnd: (_) {
            widget.onEnd(widget.settings);
            _thumb = null;
          },
          onTapUp: (e) => widget.onEnd(
            apply(nearest(e.localPosition.dx), v(e.localPosition.dx)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CustomPaint(
              size: Size(w, 30),
              painter: _RangePainter(widget.settings, c),
            ),
          ),
        );
      },
    );
  }
}

class _RangePainter extends CustomPainter {
  _RangePainter(this.s, this.c);
  final BlockRollSettings s;
  final UiColors c;

  @override
  void paint(Canvas canvas, Size size) {
    double x(double v) => (v + 3) / 6 * size.width;
    const ty = 10.0;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, ty, size.width, 3),
      const Radius.circular(2),
    );
    canvas.drawRRect(track, Paint()..color = c.control);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(x(s.weightMin), ty, x(s.weightMax), ty + 3),
        const Radius.circular(2),
      ),
      Paint()..color = c.accent,
    );
    void thumb(double v) {
      final o = Offset(x(v), ty + 1.5);
      canvas
        ..drawCircle(
          o.translate(0, 1),
          7.5,
          Paint()
            ..color = Colors.black.withValues(alpha: .2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
        )
        ..drawCircle(o, 7.5, Paint()..color = Colors.white)
        ..drawCircle(
          o,
          6.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = c.accent,
        );
    }

    thumb(s.weightMin);
    thumb(s.weightMax);
    canvas.drawCircle(
      Offset(x(s.weightAverage), ty + 1.5),
      5.5,
      Paint()..color = c.ink,
    );
    for (var t = -3; t <= 3; t++) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$t',
          style: UiText.mono(10, color: c.faint, height: 1.2),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x(t.toDouble()) - tp.width / 2, 18));
    }
  }

  @override
  bool shouldRepaint(_RangePainter old) => old.s != s || old.c != c;
}
