import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ui_colors.dart';
import 'ui_glyph.dart';
import 'ui_text.dart';

/// 分段控件：控件底、内边距 2、圆角 8；选中项卡片底 + 细阴影 + 加粗。
class UiSegmented<T> extends StatelessWidget {
  const UiSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.height = 30,
    this.itemPadding = 11,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;
  final double height;
  final double itemPadding;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: height,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, v) in values.indexed) ...[
            if (i > 0) const SizedBox(width: 2),
            _Segment(
              label: labelOf(v),
              selected: v == selected,
              padding: itemPadding,
              onTap: () => onChanged(v),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatefulWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.padding,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double padding;
  final VoidCallback onTap;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final on = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: on ? null : widget.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: widget.padding),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? c.selectedSegment : null,
            borderRadius: BorderRadius.circular(6),
            boxShadow: on
                ? const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            maxLines: 1,
            style: UiText.sans(
              12.5,
              weight: on ? FontWeight.w600 : FontWeight.w400,
              color: on || _hover ? c.ink : c.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// 小开关：28 × 16。
class UiSwitch extends StatelessWidget {
  const UiSwitch({super.key, required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 140);
    return AnimatedContainer(
      duration: duration,
      width: 28,
      height: 16,
      decoration: BoxDecoration(
        color: value ? c.accent : c.strong,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedAlign(
        duration: duration,
        curve: Curves.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// 描边胶囊按钮：高 30、圆角 8、卡片底。开关、下拉、次要按钮都用它。
class UiChipButton extends StatefulWidget {
  const UiChipButton({
    super.key,
    required this.children,
    this.onPressed,
    this.height = 30,
    this.primary = false,
    this.semanticLabel,
  });

  final List<Widget> children;
  final VoidCallback? onPressed;
  final double height;

  /// 品牌蓝主按钮。
  final bool primary;
  final String? semanticLabel;

  @override
  State<UiChipButton> createState() => _UiChipButtonState();
}

class _UiChipButtonState extends State<UiChipButton> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final bg = widget.primary
        ? (_hover ? Color.lerp(c.brand, Colors.black, .08)! : c.brand)
        : (_hover ? c.hover : c.card);
    final fg = widget.primary ? c.onBrand : c.ink;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: widget.onPressed == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: widget.primary ? c.brand : c.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: fg),
              child: DefaultTextStyle.merge(
                style: UiText.sans(12.5, color: fg),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: widget.children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 30 × 30 描边图标按钮（刷新等）。
class UiIconButton extends StatefulWidget {
  const UiIconButton({
    super.key,
    required this.glyph,
    required this.tooltip,
    this.onPressed,
    this.glyphSize = 15,
    this.spinning = false,
  });

  final String glyph;
  final String tooltip;
  final VoidCallback? onPressed;
  final double glyphSize;

  /// 进行中时图标持续旋转（减少动态效果时不转）。
  final bool spinning;

  @override
  State<UiIconButton> createState() => _UiIconButtonState();
}

class _UiIconButtonState extends State<UiIconButton>
    with SingleTickerProviderStateMixin {
  var _hover = false;
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSpin();
  }

  @override
  void didUpdateWidget(covariant UiIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSpin();
  }

  void _syncSpin() {
    final run = widget.spinning && !MediaQuery.disableAnimationsOf(context);
    if (run && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!run && _spin.isAnimating) {
      _spin
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: widget.onPressed == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hover ? c.hover : c.card,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(7),
            ),
            child: RotationTransition(
              turns: _spin,
              child: UiGlyph(
                widget.glyph,
                size: widget.glyphSize,
                color: _hover ? c.ink : c.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 14px 进度圈：底圈描边色 + 四分之一强调色弧，转动（减少动态效果时静止）。
class UiSpinner extends StatefulWidget {
  const UiSpinner({super.key, this.size = 14});
  final double size;

  @override
  State<UiSpinner> createState() => _UiSpinnerState();
}

class _UiSpinnerState extends State<UiSpinner>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
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
    return RotationTransition(
      turns: _c,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _SpinnerPainter(track: c.border, arc: c.accent),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({required this.track, required this.arc});
  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: 9 * k,
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * k
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, p..color = track);
    canvas.drawArc(rect, -math.pi / 2, math.pi / 2, false, p..color = arc);
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) =>
      old.track != track || old.arc != arc;
}

/// 骨架占位块。
class UiSkeleton extends StatelessWidget {
  const UiSkeleton({
    super.key,
    this.width,
    required this.height,
    this.opacity = 1,
  });

  final double? width;
  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(colors: [c.control, c.hover, c.control]),
        ),
      ),
    );
  }
}

/// 鼠标悬停 + 点击的通用区域：悬停时手形光标，把悬停状态交给 [builder]。
class UiPressable extends StatefulWidget {
  const UiPressable({
    super.key,
    required this.builder,
    this.onTap,
    this.onSecondaryTap,
  });

  final Widget Function(BuildContext context, bool hover) builder;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;

  @override
  State<UiPressable> createState() => _UiPressableState();
}

class _UiPressableState extends State<UiPressable> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onSecondaryTap: widget.onSecondaryTap,
        child: widget.builder(context, enabled && _hover),
      ),
    );
  }
}
