import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'gen_contract.dart';
import 'gen_format.dart';
import 'gen_page.dart';
import 'gen_parts.dart';

/// 左栏顶栏（原型 `.lh`）：最小 37 高、内边距 4 4 4 8、间距 6、下边线。
/// 左：模型胶囊（点模型名弹菜单，点 Anime / Furry 切模式）；右：额度胶囊；最右收起钮。
/// 放不下时额度胶囊整块换到第二行靠左。
class GenHeader extends StatelessWidget {
  const GenHeader({super.key, this.collapsible = true});
  final bool collapsible;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.header);
    return Container(
      key: const Key('gen-header'),
      constraints: const BoxConstraints(minHeight: 37),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: WindowHeaderDragSurface(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              const Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 4,
                  spacing: 6,
                  children: [_ModelCapsule(), _QuotaCapsule()],
                ),
              ),
              if (collapsible)
                GenIb(
                  key: const Key('gen-collapse-left'),
                  glyph: UiGlyphs.chevronLeft,
                  glyphSize: 16,
                  tooltip: context.l10n.gen_collapse,
                  onTap: () => scope.actions.onLayoutChanged(
                    scope.data.layout.copyWith(leftOpen: false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 胶囊外框（原型 `.cap`）：28 高、1px `--capb` 描边、圆角 8、窗口底、12 号字。
class _Capsule extends StatelessWidget {
  const _Capsule({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: GenFormat.capsuleBorder(c)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle.merge(
        style: UiText.sans(12, color: c.ink),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

/// 胶囊里的竖分隔（原型 `.vs`）：1 × 16，比描边略深。
class _Vs extends StatelessWidget {
  const _Vs();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      width: 1,
      height: 16,
      color: Color.lerp(GenFormat.capsuleBorder(c), Colors.black, .1),
    );
  }
}

class _ModelCapsule extends StatelessWidget {
  const _ModelCapsule();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.header);
    final data = scope.data;
    final furry = data.furry;
    final open = scope.controller.popoverTag == #model;
    return _Capsule(
      key: const Key('gen-model-capsule'),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 6),
          child: Text(
            'Model',
            style: UiText.sans(12, color: GenFormat.ink55(c)),
          ),
        ),
        Builder(
          builder: (context) => UiPressable(
            key: const Key('gen-model'),
            onTap: () => scope.controller.openPopover(
              genBelow(context, dy: 6),
              (_) => const _ModelMenu(),
              tag: #model,
            ),
            builder: (context, hover) => Container(
              height: 22,
              margin: const EdgeInsets.only(right: 3),
              padding: const EdgeInsets.only(left: 7, right: 4),
              decoration: BoxDecoration(
                color: hover || open ? Color.lerp(c.ink, c.bg, .14) : c.ink,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                spacing: 5,
                children: [
                  // 素材是纯黑剪影，按反色内胆底色着色。
                  GenNaiIcon('novelai-icon.svg', size: 13, color: c.bg),
                  Text(
                    data.currentModel.name,
                    style: UiText.sans(
                      12,
                      weight: FontWeight.w700,
                      color: c.bg,
                    ),
                  ),
                  UiGlyph(
                    UiGlyphs.chevronDown,
                    size: 14,
                    strokeWidth: 2.4,
                    color: c.bg,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (furry != null) ...[
          if (data.turboVisible) const _TurboButton(),
          const _Vs(),
          UiPressable(
            key: const Key('gen-mode'),
            onTap: () => scope.actions.onFurryChanged(!furry),
            builder: (context, hover) {
              final compact = data.turboVisible;
              final mode = Row(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                spacing: 5,
                children: [
                  GenNaiIcon(
                    furry ? 'furry' : 'sakura',
                    size: 13,
                    color: hover ? c.ink : c.muted,
                  ),
                  Text(
                    compact ? (furry ? 'F' : 'A') : (furry ? 'Furry' : 'Anime'),
                    style: UiText.sans(
                      12,
                      weight: FontWeight.w700,
                      color: hover ? c.ink : c.muted,
                    ),
                  ),
                ],
              );
              return Tooltip(
                message: context.l10n.gen_modeTip,
                child: compact
                    ? SizedBox(
                        // V5 shares the old mode width with the 25px toggle.
                        width: _originalModeWidth(context, furry) - 25,
                        height: 26,
                        child: mode,
                      )
                    : Padding(
                        padding: const EdgeInsets.only(left: 10, right: 9),
                        child: mode,
                      ),
              );
            },
          ),
        ],
      ],
    );
  }
}

double _originalModeWidth(BuildContext context, bool furry) {
  final text = TextPainter(
    text: TextSpan(
      text: furry ? 'Furry' : 'Anime',
      style: UiText.sans(12, weight: FontWeight.w700),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  final width = text.width + 19 + 13 + 5;
  text.dispose();
  return width;
}

class _TurboButton extends StatelessWidget {
  const _TurboButton();

  @override
  Widget build(BuildContext context) {
    final scope = GenScope.of(context, GenAspect.header);
    final enabled =
        scope.data.turbo != null && scope.actions.onTurboChanged != null;
    final active = scope.data.turbo == true;
    final c = context.ui;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(right: 3),
      child: Tooltip(
        message: !enabled
            ? l.gen_turboUnavailable
            : active
            ? l.gen_turboDisable
            : l.gen_turboEnable,
        child: Semantics(
          button: true,
          enabled: enabled,
          toggled: active,
          label: 'Turbo (Medium Effort)',
          child: UiPressable(
            key: const Key('gen-turbo'),
            onTap: enabled
                ? () => scope.actions.onTurboChanged!(!active)
                : null,
            builder: (context, hover) => Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: active
                    ? c.warnBg
                    : hover && enabled
                    ? c.hover
                    : c.control,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: UiGlyph(
                active ? UiGlyphs.bolt : UiGlyphs.boltOff,
                size: 14,
                color: active
                    ? c.warn
                    : enabled
                    ? c.muted
                    : c.faint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuotaCapsule extends StatelessWidget {
  const _QuotaCapsule();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.header);
    final q = scope.data.quota;
    final opus = q.opusPercent;
    final capsule = UiPressable(
      key: const Key('gen-quota'),
      onTap: scope.actions.onOpenQuota,
      builder: (context, hover) => _Capsule(
        children: [
          if (opus != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                spacing: 4,
                children: [
                  UiGlyph(
                    UiGlyphs.bolt,
                    size: 13,
                    color: c.quotaAccent(
                      opus,
                      usingReserve: q.opusUsingReserve,
                    ),
                  ),
                  Text(
                    GenFormat.percent(opus),
                    style: UiText.sans(
                      12,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                ],
              ),
            ),
            const _Vs(),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              spacing: 4,
              children: [
                GenNaiIcon('anlas', size: 12, color: c.ink),
                Text(
                  q.anlas == null ? '—' : GenFormat.thousands(q.anlas!),
                  style: UiText.sans(12, weight: FontWeight.w700, color: c.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final tip = [
      ?q.opusTip,
      if (q.anlas != null)
        context.l10n.gen_anlasTip(GenFormat.thousands(q.anlas!)),
      if (q.subscriptionAnlas != null)
        '${context.l10n.anlas_subscription}: '
            '${GenFormat.thousands(q.subscriptionAnlas!)}',
      if (q.purchasedAnlas != null)
        '${context.l10n.anlas_purchased}: '
            '${GenFormat.thousands(q.purchasedAnlas!)}',
    ].join('\n');
    return tip.isEmpty ? capsule : Tooltip(message: tip, child: capsule);
  }
}

/// 模型菜单：“新模型 / 旧模型”两组，每项名字 + 一行说明，当前项打勾。
class _ModelMenu extends StatelessWidget {
  const _ModelMenu();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.header);
    final data = scope.data;
    final l = context.l10n;
    Widget header(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Text(
        t,
        style: UiText.sans(11, weight: FontWeight.w600, color: c.faint),
      ),
    );
    Widget item(GenModel m) {
      final on = m.id == (data.displayModel ?? data.model);
      return UiPressable(
        key: Key('gen-model-${m.id}'),
        onTap: () {
          scope.controller.closePopover();
          if (!on) scope.actions.onModelChanged(m.id);
        },
        builder: (context, hover) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: hover ? c.control : null,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            spacing: 10,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: UiText.sans(
                        13,
                        weight: on ? FontWeight.w600 : FontWeight.w500,
                        color: c.ink,
                      ),
                    ),
                    if (m.description != null)
                      Text(
                        m.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(11.5, color: c.muted),
                      ),
                  ],
                ),
              ),
              if (on)
                UiGlyph(
                  UiGlyphs.check,
                  size: 14,
                  strokeWidth: 2.4,
                  color: c.accent,
                ),
            ],
          ),
        ),
      );
    }

    final newer = data.models.where((m) => !m.legacy).toList();
    final legacy = data.models.where((m) => m.legacy).toList();
    return UiPopoverSurface(
      width: 260,
      padding: const EdgeInsets.all(4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (newer.isNotEmpty) header(l.gen_modelsNew),
              for (final m in newer) item(m),
              if (legacy.isNotEmpty) header(l.gen_modelsLegacy),
              for (final m in legacy) item(m),
            ],
          ),
        ),
      ),
    );
  }
}
