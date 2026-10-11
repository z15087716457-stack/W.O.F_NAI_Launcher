import 'package:flutter/material.dart';

import 'ui_colors.dart';

/// 细进度条：高 4、圆角 2，底槽是正文色 16%。[value] 为 null 时是来回滑动的不定状态
///（减少动态效果时停在中间）。
class UiProgressBar extends StatefulWidget {
  const UiProgressBar({super.key, this.value, this.height = 4});
  final double? value;
  final double height;

  @override
  State<UiProgressBar> createState() => _UiProgressBarState();
}

class _UiProgressBarState extends State<UiProgressBar>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant UiProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run =
        widget.value == null && !MediaQuery.disableAnimationsOf(context);
    if (run && !_c.isAnimating) {
      _c.repeat();
    } else if (!run && _c.isAnimating) {
      _c
        ..stop()
        ..value = .5;
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
    final r = BorderRadius.circular(widget.height / 2);
    final fill = DecoratedBox(
      decoration: BoxDecoration(color: c.accent, borderRadius: r),
    );
    return ClipRRect(
      borderRadius: r,
      child: SizedBox(
        height: widget.height,
        child: ColoredBox(
          color: c.ink.withValues(alpha: .16),
          child: widget.value != null
              ? FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widget.value!.clamp(0, 1),
                  child: fill,
                )
              : AnimatedBuilder(
                  animation: _c,
                  builder: (context, child) => FractionallySizedBox(
                    alignment: Alignment(-1.6 + 3.2 * _c.value, 0),
                    widthFactor: .35,
                    child: child,
                  ),
                  child: fill,
                ),
        ),
      ),
    );
  }
}
