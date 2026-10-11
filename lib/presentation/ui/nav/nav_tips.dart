import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_text.dart';
import 'nav_contract.dart';
import 'nav_labels.dart';

/// 导航栏的悬停提示气泡：深底（深色主题是浅底）、圆角 7、左边一个小尖角。
class NavTipBubble extends StatelessWidget {
  const NavTipBubble({
    super.key,
    required this.child,
    this.width,
    this.rich = false,
  });

  final Widget child;
  final double? width;

  /// 富提示：宽 250、圆角 10、内边距 10 / 12 / 12，尖角离顶 28。
  final bool rich;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final body = Container(
      width: width,
      height: rich ? null : 30,
      padding: rich
          ? const EdgeInsets.fromLTRB(12, 10, 12, 12)
          : const EdgeInsets.fromLTRB(10, 0, 6, 0),
      decoration: BoxDecoration(
        color: c.tipBg,
        borderRadius: BorderRadius.circular(rich ? 10 : 7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: rich ? .28 : .22),
            blurRadius: rich ? 25 : 16.5,
            offset: Offset(0, rich ? 10 : 6),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: UiText.sans(12.5, weight: FontWeight.w500, color: c.tipInk),
        child: child,
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        body,
        Positioned(
          left: -4,
          top: rich ? 24 : 11,
          child: Transform.rotate(
            angle: .785398,
            child: Container(width: 8, height: 8, color: c.tipBg),
          ),
        ),
      ],
    );
  }
}

/// 普通提示：页面名 + 快捷键键帽。
class NavSimpleTip extends StatelessWidget {
  const NavSimpleTip({super.key, required this.label, this.keys});
  final String label;
  final List<String>? keys;

  @override
  Widget build(BuildContext context) => NavTipBubble(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (keys case final k?) ...[
          const SizedBox(width: 6),
          UiKeycaps(k, style: UiKeycapStyle.tip, gap: 6),
        ],
      ],
    ),
  );
}

/// 生图在生成中 / 刚完成 / 失败时的富提示。
class NavGenerationTip extends StatelessWidget {
  const NavGenerationTip({super.key, required this.generation, this.keys});
  final NavGeneration generation;
  final List<String>? keys;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final g = generation;
    // 气泡底色反着来：深气泡上用亮蓝，浅气泡上用主题蓝。
    final blue = c.dark ? c.accent : const Color(0xFF5AA2FF);
    final sub = UiText.sans(11.5, color: c.tipInk.withValues(alpha: .62));
    final Widget body = switch (g.state) {
      NavGenerationState.running => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (g.preview case final p?) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image(
                image: p,
                width: 52,
                height: 76,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
            const SizedBox(width: 11),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.total > 1
                      ? l.navShell_genRunningCount(g.current, g.total)
                      : l.navShell_genRunning,
                  style: UiText.sans(
                    12.5,
                    weight: FontWeight.w600,
                    color: blue,
                  ),
                ),
                const SizedBox(height: 7),
                _TipBar(
                  value: g.ringFraction,
                  color: c.dark ? c.accent : const Color(0xFF3D8BFF),
                ),
                const SizedBox(height: 5),
                Text(
                  l.navShell_genPercent((g.ringFraction * 100).round()),
                  style: sub,
                ),
                const SizedBox(height: 6),
                Text(l.navShell_genBack, style: sub),
              ],
            ),
          ),
        ],
      ),
      NavGenerationState.failed => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.navShell_genFailed,
            style: UiText.sans(12.5, weight: FontWeight.w600, color: c.error),
          ),
          if (g.error case final e?) ...[
            const SizedBox(height: 4),
            Text(
              e.split('\n').first,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: sub,
            ),
          ],
          const SizedBox(height: 6),
          Text(l.navShell_genBack, style: sub),
        ],
      ),
      _ => Text(l.navShell_genDone(g.total), style: sub),
    };
    return NavTipBubble(
      rich: true,
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                NavPage.generation.label(context),
                style: UiText.sans(12.5, weight: FontWeight.w700),
              ),
              const Spacer(),
              if (keys case final k?)
                UiKeycaps(k, style: UiKeycapStyle.tip, gap: 6),
            ],
          ),
          const SizedBox(height: 9),
          body,
        ],
      ),
    );
  }
}

class _TipBar extends StatelessWidget {
  const _TipBar({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(2),
    child: SizedBox(
      height: 4,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: context.ui.tipInk.withValues(alpha: .16)),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
