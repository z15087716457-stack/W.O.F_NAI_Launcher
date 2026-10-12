import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_text.dart';
import 'gen_contract.dart';
import 'gen_page.dart';
import 'gen_parts.dart';

/// 生成条（原型 `.gbar`）：内边距 6 10、上边线、窗口底 50%；里面一颗 40 高的生成按钮。
class GenGenerateBar extends StatelessWidget {
  const GenGenerateBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      key: const Key('gen-generate-bar'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.bg.withValues(alpha: .5),
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: const GenGenerateButton(),
    );
  }
}

/// 生成按钮（原型 `.gbtn`）：40 高、圆角 6、品牌蓝、左 14 右 9；14 / w500 白字，右端价格角标。
/// 生成中：控件底 + 整批进度铺底，“停止生成 · 2 / 4”，点了停止。冷却 / 不能点：控件底、弱色。
class GenGenerateButton extends StatelessWidget {
  const GenGenerateButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    final g = scope.data.generate;
    final l = context.l10n;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final running = g.state == GenRunState.generating;
    final ready = g.state == GenRunState.ready;
    final onTap = switch (g.state) {
      GenRunState.ready => scope.actions.onGenerate,
      GenRunState.generating => scope.actions.onStop,
      _ => null,
    };
    final button = UiPressable(
      key: const Key('gen-generate'),
      onTap: onTap,
      builder: (context, hover) {
        final bg = ready
            ? (hover ? Color.lerp(c.brand, Colors.black, .08)! : c.brand)
            : (running && hover ? c.hover : c.control);
        final fg = ready ? c.onBrand : (running ? c.ink : c.faint);
        return Container(
          height: 40,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (running && g.progress != null)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedFractionallySizedBox(
                      duration: reduce
                          ? Duration.zero
                          : const Duration(milliseconds: 300),
                      widthFactor: g.progress!.clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: ColoredBox(
                        key: const Key('gen-generate-progress'),
                        color: c.accent.withValues(alpha: .16),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 9),
                child: Row(
                  spacing: 8,
                  children: [
                    if (running)
                      UiGlyph(UiGlyphs.stop, size: 13, filled: true, color: fg)
                    else if (g.state == GenRunState.cooldown)
                      UiGlyph(UiGlyphs.clock, size: 15, color: fg),
                    Expanded(
                      child: Text(
                        switch (g.state) {
                          GenRunState.generating => l.gen_stop,
                          GenRunState.cooldown => l.gen_cooldown(g.cooldown),
                          _ => g.label,
                        },
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          14,
                          weight: FontWeight.w500,
                          color: fg,
                        ),
                      ),
                    ),
                    if (running && g.total > 1)
                      Text(
                        '${g.done} / ${g.total}',
                        style: UiText.mono(
                          12.5,
                          weight: FontWeight.w500,
                          color: c.muted,
                        ),
                      ),
                    if (running && g.total <= 1 && g.progress != null)
                      Text(
                        '${(g.progress! * 100).round()}%',
                        style: UiText.mono(
                          12.5,
                          weight: FontWeight.w500,
                          color: c.muted,
                        ),
                      ),
                    if (ready || g.state == GenRunState.blocked)
                      _Cost(
                        cost: g.cost,
                        insufficient: g.insufficient,
                        dim: !ready,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    final tip = switch (g.state) {
      GenRunState.blocked => g.blocked,
      GenRunState.ready when g.insufficient => l.gen_insufficient,
      GenRunState.ready when g.cost == 0 => l.gen_free,
      _ => null,
    };
    return tip == null ? button : Tooltip(message: tip, child: button);
  }
}

/// 价格角标（原型 `.cost`）：22 高、左右 6、圆角 5、白底 #111 字 12 / w700 + Anlas 10；余额不够红底白字。
class _Cost extends StatelessWidget {
  const _Cost({
    required this.cost,
    required this.insufficient,
    this.dim = false,
  });
  final int? cost;
  final bool insufficient;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final ink = insufficient ? Colors.white : const Color(0xFF111111);
    return Opacity(
      opacity: dim ? .6 : 1,
      child: Container(
        key: const Key('gen-cost'),
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: insufficient ? c.error : Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: cost == null
            ? const SizedBox(
                width: 22,
                child: Center(child: UiSpinner(size: 12)),
              )
            : GenAnlas('$cost', color: ink),
      ),
    );
  }
}
