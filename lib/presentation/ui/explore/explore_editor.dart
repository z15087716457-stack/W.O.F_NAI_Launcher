import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_block_pill.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import 'explore_contract.dart';
import 'explore_format.dart';
import 'explore_page.dart';
import 'explore_parts.dart';

/// 编辑列模块外框（原型 `.mod`）：提示词底、1px 描边、圆角 8，内容按圆角裁。
class ExploreModule extends StatelessWidget {
  const ExploreModule({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      clipBehavior: Clip.antiAlias,
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(8),
      ),
      decoration: BoxDecoration(
        color: ExploreFormat.promptBg(c),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

/// 模块标题行（原型 `.mh`）：38 高、左 12 右 6、间距 6；标题 13 / w700。
class ExploreModuleHeader extends StatelessWidget {
  const ExploreModuleHeader({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    padding: const EdgeInsets.only(left: 12, right: 6),
    child: DefaultTextStyle.merge(
      style: UiText.sans(13, weight: FontWeight.w700, color: context.ui.ink),
      child: Row(spacing: 6, children: children),
    ),
  );
}

/// “随机变量”模块：列出提示词里的随机块，标出进化目标；点一行打开实例卡。
/// 没有随机块时直接说清楚要做什么，不等到进化那一步才报错。
class ExploreRandomVariables extends StatelessWidget {
  const ExploreRandomVariables({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final vars = scope.data.variables;
    final tint = vars.firstOrNull?.color ?? c.faint;
    return ExploreModule(
      key: const Key('explore-variables'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExploreModuleHeader(
            children: [
              UiGlyph(UiGlyphs.dice, size: 15, color: tint),
              Text(l.explore_variables),
              ExploreCount(vars.length),
              const Spacer(),
              Text(
                l.explore_variablesHint,
                style: UiText.sans(12, color: c.faint),
              ),
              UiIconBox(
                glyph: UiGlyphs.infoCircle,
                size: 28,
                tooltip: l.explore_variablesInfo,
              ),
            ],
          ),
          if (vars.isEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: Text(
                      l.explore_variablesEmpty,
                      style: UiText.sans(12, color: c.muted),
                    ),
                  ),
                  UiBtn(
                    key: const Key('explore-variables-library'),
                    size: UiBtnSize.small,
                    onTap: scope.actions.onOpenBlockLibrary,
                    children: [
                      const UiGlyph(UiGlyphs.archive, size: 13),
                      Text(l.explore_openBlockLibrary),
                    ],
                  ),
                ],
              ),
            )
          else
            for (final (i, v) in vars.indexed)
              UiPressable(
                key: Key('explore-variable-$i'),
                onTap: () => scope.actions.onOpenVariable(i),
                builder: (context, hover) => Container(
                  height: 40,
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  decoration: BoxDecoration(
                    color: hover ? c.hover.withValues(alpha: .6) : null,
                    border: Border(top: BorderSide(color: c.line)),
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: UiBlockPill(
                            label: v.title,
                            color: v.color,
                            icon: v.icon,
                            status: v.missing
                                ? UiBlockPillStatus.missing
                                : UiBlockPillStatus.normal,
                            badge: v.evolution
                                ? UiBlockBadge.evolution
                                : UiBlockBadge.random,
                          ),
                        ),
                      ),
                      if (v.missing)
                        Text(
                          l.explore_variableMissing,
                          style: UiText.sans(12, color: c.error),
                        )
                      else if (v.poolSize != null)
                        Text(
                          l.explore_poolSize(v.poolSize!),
                          style: UiText.sans(12, color: c.muted),
                        ),
                      if (v.evolution)
                        Text(
                          '· ${l.explore_evolutionTarget}',
                          style: UiText.sans(12, color: c.faint),
                        ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// 底部生成条（原型 `.gbar`）：上边线、内边距 8 / 10、间距 8；张数 + “抽 N 张候选”（40 高品牌蓝）。
/// 张数原型放在“图像”模块里，这里挪到按钮旁边：改张数和点抽取在同一处。
class ExploreGenerateBar extends StatelessWidget {
  const ExploreGenerateBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ExploreScope.of(context);
    final g = scope.data.generate;
    final idle = g.phase == ExploreGeneratePhase.ready;
    return Container(
      key: const Key('explore-generate-bar'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        spacing: 8,
        children: [
          ExploreStepper(
            value: g.count,
            max: g.maxCount,
            height: 40,
            onChanged: idle ? scope.actions.onCountChanged : null,
          ),
          const Expanded(child: ExploreGenerateButton()),
        ],
      ),
    );
  }
}

/// “抽 N 张候选”按钮（编辑列底部、首次使用页共用）。
class ExploreGenerateButton extends StatelessWidget {
  const ExploreGenerateButton({super.key, this.compact = false});

  /// 首次使用页：36 高、按内容宽。
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final g = scope.data.generate;
    final running = g.phase == ExploreGeneratePhase.running;
    final enabled = g.phase == ExploreGeneratePhase.ready || running;
    final label = switch (g.phase) {
      ExploreGeneratePhase.ready => l.explore_draw(g.count),
      ExploreGeneratePhase.running => l.explore_stopGenerating,
      ExploreGeneratePhase.busy => l.explore_busy,
      ExploreGeneratePhase.cooldown => l.explore_cooldown(g.cooldown),
    };
    final fg = running || !enabled ? c.ink : c.onBrand;
    final button = UiPressable(
      key: Key(compact ? 'explore-onboarding-draw' : 'explore-generate'),
      onTap: !enabled
          ? null
          : running
          ? scope.actions.onStop
          : scope.actions.onGenerate,
      builder: (context, hover) {
        final bg = running || !enabled
            ? (hover ? c.hover : c.control)
            : (hover ? Color.lerp(c.brand, Colors.black, .08)! : c.brand);
        return Container(
          height: compact ? 36 : 40,
          padding: EdgeInsets.only(left: 14, right: compact ? 14 : 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(compact ? 8 : 6),
          ),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            spacing: 8,
            children: [
              UiGlyph(
                running ? UiGlyphs.stop : UiGlyphs.play,
                size: running ? 15 : 14,
                filled: true,
                color: enabled ? fg : c.faint,
              ),
              Flexible(
                fit: compact ? FlexFit.loose : FlexFit.tight,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(
                    compact ? 13.5 : 14,
                    weight: FontWeight.w500,
                    color: enabled ? fg : c.faint,
                  ),
                ),
              ),
              if (running && g.total > 1)
                Text(
                  '${g.done} / ${g.total}',
                  style: UiText.mono(12, color: c.muted),
                ),
              if (g.phase == ExploreGeneratePhase.ready && !compact)
                _Cost(cost: g.cost, insufficient: g.insufficient),
            ],
          ),
        );
      },
    );
    return Opacity(opacity: enabled ? 1 : .6, child: button);
  }
}

/// 价格角标：22 高、圆角 5、白底黑字 12 / w700 + Anlas 图标 10；余额不够时红底。
class _Cost extends StatelessWidget {
  const _Cost({required this.cost, required this.insufficient});
  final int cost;
  final bool insufficient;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final ink = insufficient ? Colors.white : const Color(0xFF111111);
    return Tooltip(
      message: insufficient ? context.l10n.explore_insufficient : '',
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: insufficient ? c.error : Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: [
            Text(
              '$cost',
              style: UiText.sans(
                12,
                weight: FontWeight.w700,
                color: ink,
                height: 1,
              ),
            ),
            SvgPicture.asset(
              'assets/icons/nai-icon-anlas.svg',
              width: 10,
              height: 10,
              colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }
}
