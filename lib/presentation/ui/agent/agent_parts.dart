import 'package:flutter/material.dart';

import '../kit/ui_colors.dart';
import '../kit/ui_text.dart';
import 'agent_glyphs.dart';

/// 方案 B 的通用小件：图标按钮、描边按钮、黑色主按钮、小标签、分段、眉题。

/// 28 × 28（[small] 24）图标按钮，悬停灰底。
class AgentIconButton extends StatefulWidget {
  const AgentIconButton({
    super.key,
    required this.glyph,
    required this.tooltip,
    this.onPressed,
    this.small = false,
    this.active = false,
    this.color,
    this.child,
  });
  final String glyph;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool small;
  final bool active;
  final Color? color;

  /// 代替图标画的内容（例如上下文圆环）。
  final Widget? child;

  @override
  State<AgentIconButton> createState() => _AgentIconButtonState();
}

class _AgentIconButtonState extends State<AgentIconButton> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final size = widget.small ? 24.0 : 28.0;
    final enabled = widget.onPressed != null;
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.active || (_hover && enabled) ? c.hover : null,
              borderRadius: BorderRadius.circular(widget.small ? 6 : 7),
            ),
            child:
                widget.child ??
                AgentIcon(
                  widget.glyph,
                  size: widget.small ? 14 : 16,
                  color: !enabled
                      ? c.faint
                      : widget.color ??
                            (_hover || widget.active ? c.ink : c.muted),
                ),
          ),
        ),
      ),
    );
  }
}

enum AgentButtonStyle { outline, primary, ghost, danger }

/// 文字按钮：描边（默认）/ 黑色主按钮 / 无框 / 红色。
class AgentButton extends StatefulWidget {
  const AgentButton({
    super.key,
    required this.label,
    this.onPressed,
    this.glyph,
    this.style = AgentButtonStyle.outline,
    this.height = 30,
    this.expand = false,
    this.trailing,
  });
  final String label;
  final VoidCallback? onPressed;
  final String? glyph;
  final AgentButtonStyle style;
  final double height;
  final bool expand;
  final Widget? trailing;

  @override
  State<AgentButton> createState() => _AgentButtonState();
}

class _AgentButtonState extends State<AgentButton> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final enabled = widget.onPressed != null;
    final (Color? bg, Color fg, Color? border) = switch (widget.style) {
      _ when !enabled && widget.style == AgentButtonStyle.primary => (
        c.control,
        c.faint,
        c.control,
      ),
      _ when !enabled => (null, c.faint, c.border),
      AgentButtonStyle.primary => (
        _hover ? Color.lerp(c.ink, c.bg, .14) : c.ink,
        c.bg,
        null,
      ),
      AgentButtonStyle.danger => (
        _hover ? Color.lerp(c.error, Colors.black, .1) : c.error,
        Colors.white,
        null,
      ),
      AgentButtonStyle.ghost => (_hover ? c.hover : null, c.muted, null),
      AgentButtonStyle.outline => (_hover ? c.hover : c.card, c.ink, c.border),
    };
    final small = widget.height < 28;
    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 5,
      children: [
        if (widget.glyph != null)
          AgentIcon(widget.glyph!, size: small ? 13 : 14, color: fg),
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.sans(
              small ? 12 : 12.5,
              weight: FontWeight.w500,
              color: fg,
              height: 1.2,
            ),
          ),
        ),
        ?widget.trailing,
      ],
    );
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: Container(
          height: widget.height,
          padding: EdgeInsets.symmetric(horizontal: small ? 8 : 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(small ? 7 : 8),
            border: border == null ? null : Border.all(color: border),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// 眉题：等宽小写字母、宽字距（「当前草稿」「最近」）。
class AgentEyebrow extends StatelessWidget {
  const AgentEyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: UiText.mono(
      10.5,
      weight: FontWeight.w500,
      color: color ?? context.ui.faint,
      letterSpacing: .8,
      height: 1.2,
    ),
  );
}

/// 圆角小底色数字（标签上的「14」）。
class AgentCount extends StatelessWidget {
  const AgentCount(this.value, {super.key});
  final int value;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value',
        style: UiText.mono(
          10.5,
          weight: FontWeight.w500,
          color: c.muted,
          height: 1,
        ),
      ),
    );
  }
}

/// 卡片：白底、细描边、12 圆角、极浅阴影。
class AgentCard extends StatelessWidget {
  const AgentCard({
    super.key,
    required this.child,
    this.borderColor,
    this.borderWidth = 1,
  });
  final Widget child;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? c.border, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.dark ? .4 : .04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 卡片里的一节：上方细分隔线（第一节没有）。
class AgentSection extends StatelessWidget {
  const AgentSection({
    super.key,
    required this.child,
    this.first = false,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 12),
  });
  final Widget child;
  final bool first;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      border: first ? null : Border(top: BorderSide(color: context.ui.line)),
    ),
    child: child,
  );
}

/// 分段：控件底 + 选中项卡片底（输入区的只读 / 询问 / 自动、产物筛选）。
class AgentSegments<T> extends StatelessWidget {
  const AgentSegments({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.glyph,
    this.tooltip,
  });
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final String? Function(T)? glyph;
  final String? Function(T)? tooltip;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 26,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (final v in values)
            _Seg(
              key: ValueKey(v),
              label: label(v),
              glyph: glyph?.call(v),
              tooltip: tooltip?.call(v),
              on: v == selected,
              onTap: () => onChanged(v),
            ),
        ],
      ),
    );
  }
}

class _Seg extends StatefulWidget {
  const _Seg({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
    this.glyph,
    this.tooltip,
  });
  final String label;
  final String? glyph;
  final String? tooltip;
  final bool on;
  final VoidCallback onTap;

  @override
  State<_Seg> createState() => _SegState();
}

class _SegState extends State<_Seg> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final fg = widget.on || _hover ? c.ink : c.muted;
    Widget seg = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: widget.on ? c.card : null,
            borderRadius: BorderRadius.circular(6),
            boxShadow: widget.on
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: c.dark ? .5 : .08),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              if (widget.glyph != null)
                AgentIcon(widget.glyph!, size: 12, color: fg),
              Text(
                widget.label,
                style: UiText.sans(
                  11.5,
                  weight: widget.on ? FontWeight.w500 : FontWeight.w400,
                  color: fg,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (widget.tooltip != null) {
      seg = Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 500),
        child: seg,
      );
    }
    return seg;
  }
}

/// 上下文圆环（18px）；[fraction] 为 null 时画虚线圈。
class AgentRing extends StatelessWidget {
  const AgentRing({super.key, required this.fraction, this.size = 18});
  final double? fraction;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return CustomPaint(
      size: Size.square(size),
      painter: _RingPainter(
        fraction: fraction,
        track: c.border,
        ink: (fraction ?? 0) > .85 ? c.warn : c.muted,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.track,
    required this.ink,
  });
  final double? fraction;
  final Color track, ink;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 2;
    final center = size.center(Offset.zero);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = track;
    if (fraction == null) {
      const n = 12;
      for (var i = 0; i < n; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r),
          i * 2 * 3.14159 / n,
          3.14159 / n,
          false,
          base,
        );
      }
      return;
    }
    canvas.drawCircle(center, r, base);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -3.14159 / 2,
      2 * 3.14159 * fraction!,
      false,
      base
        ..color = ink
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.ink != ink || old.track != track;
}

/// 步骤状态圈（16px）：完成绿勾 / 进行中蓝转圈 / 等你橙手 / 失败红叉 / 未开始虚线。
class AgentStepDot extends StatefulWidget {
  const AgentStepDot({super.key, required this.kind});
  final AgentDotKind kind;

  @override
  State<AgentStepDot> createState() => _AgentStepDotState();
}

enum AgentDotKind { done, running, waiting, failed, pending }

class _AgentStepDotState extends State<AgentStepDot>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant AgentStepDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final spin =
        widget.kind == AgentDotKind.running &&
        !MediaQuery.disableAnimationsOf(context);
    if (spin && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!spin && _spin.isAnimating) {
      _spin.stop();
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
    return SizedBox.square(
      dimension: 16,
      child: switch (widget.kind) {
        AgentDotKind.done => _filled(
          c.ok.withValues(alpha: .14),
          AgentIcon(AgentGlyphs.check, size: 11, color: c.ok, stroke: 2.2),
        ),
        AgentDotKind.failed => _filled(
          c.error.withValues(alpha: .12),
          AgentIcon(AgentGlyphs.close, size: 10, color: c.error, stroke: 2.2),
        ),
        AgentDotKind.waiting => _filled(
          c.warn,
          const AgentIcon(
            AgentGlyphs.hand,
            size: 11,
            color: Colors.white,
            stroke: 2,
          ),
        ),
        AgentDotKind.running => RotationTransition(
          turns: _spin,
          child: CustomPaint(painter: _ArcPainter(c.accent)),
        ),
        AgentDotKind.pending => CustomPaint(painter: _DashPainter(c.strong)),
      },
    );
  }

  Widget _filled(Color bg, Widget child) => Container(
    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: child,
  );
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawArc(
    Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
    0,
    4.6,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = color,
  );
  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;
    const n = 10;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        i * 2 * 3.14159 / n,
        3.14159 / n,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// 按键帽（「↵」「1」）。
class AgentKey extends StatelessWidget {
  const AgentKey(this.label, {super.key, this.inverted = false});
  final String label;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: inverted ? c.ink : c.card,
        borderRadius: BorderRadius.circular(5),
        border: Border(
          top: BorderSide(color: inverted ? c.ink : c.border),
          left: BorderSide(color: inverted ? c.ink : c.border),
          right: BorderSide(color: inverted ? c.ink : c.border),
          bottom: BorderSide(color: inverted ? c.ink : c.border, width: 2),
        ),
      ),
      child: Text(
        label,
        style: UiText.mono(
          10.5,
          weight: FontWeight.w500,
          color: inverted ? c.bg : c.muted,
          height: 1,
        ),
      ),
    );
  }
}

/// 无边框输入框外观：主题里的 enabled / focused 边框、填充也一并关掉。
InputDecoration agentBareInput({
  String? hint,
  TextStyle? hintStyle,
  EdgeInsets padding = EdgeInsets.zero,
  BoxConstraints? constraints,
  int? hintMaxLines,
}) => InputDecoration(
  isCollapsed: true,
  isDense: true,
  filled: false,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
  hoverColor: Colors.transparent,
  contentPadding: padding,
  constraints: constraints,
  hintText: hint,
  hintStyle: hintStyle,
  hintMaxLines: hintMaxLines,
);

/// 凹陷底（差异框、排队行）：原型里的 `--sunk`。
Color agentSunk(UiColors c) =>
    c.dark ? const Color(0xFF131313) : const Color(0xFFF7F7F7);

/// 千分位。
String agentNumber(int value) {
  final s = value.abs().toString();
  final b = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// 紧凑 tokens：43.2k / 1.2M。
String agentTokens(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value >= 100000 ? 0 : 1)}k';
  }
  return '$value';
}

/// 「16:40」。
String agentClock(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// 聊天列表里的相对时间：今天「16:12」，昨天「昨天」（交给调用方传入本地化词），更早「10-16」。
String agentDay(DateTime t, DateTime now, String yesterday) {
  final d = DateTime(t.year, t.month, t.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(d).inDays;
  if (diff <= 0) return agentClock(t);
  if (diff == 1) return yesterday;
  return '${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}

/// 「0.2s」「3.1s」「1m 04s」。
String agentDuration(Duration d) {
  final ms = d.inMilliseconds;
  if (ms < 60000) return '${(ms / 1000).toStringAsFixed(1)}s';
  final s = d.inSeconds;
  return '${s ~/ 60}m ${(s % 60).toString().padLeft(2, '0')}s';
}
