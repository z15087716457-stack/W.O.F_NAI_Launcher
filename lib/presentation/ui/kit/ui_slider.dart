import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui_colors.dart';
import 'ui_controls.dart';
import 'ui_lib_controls.dart';
import 'ui_text.dart';

/// 滑杆（库页原型 `.trk`）：18 高；3px 控件底槽 + 强调色填充；15px 白底圆钮、2px 强调色描边；
/// [defaultValue] 非 null 时在槽上画一道 2 × 11 的默认值刻度。取值 0–1，拖动按 0.01 取整。
class UiSlider extends StatelessWidget {
  const UiSlider({
    super.key,
    required this.value,
    this.onChanged,
    this.onChangeEnd,
    this.defaultValue,
    this.compact = false,
    this.empty = false,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double? defaultValue;

  /// 组合包网格里的小号：16 高、13px 圆钮。
  final bool compact;

  /// 多选“混合”：不画填充和圆钮。
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final enabled = onChanged != null;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        double at(Offset p) =>
            ((p.dx / w).clamp(0.0, 1.0) * 100).roundToDouble() / 100;
        return MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (d) => onChanged!(at(d.localPosition)) : null,
            onTapUp: enabled && onChangeEnd != null
                ? (d) => onChangeEnd!(at(d.localPosition))
                : null,
            onHorizontalDragUpdate: enabled
                ? (d) => onChanged!(at(d.localPosition))
                : null,
            onHorizontalDragEnd: enabled && onChangeEnd != null
                ? (_) => onChangeEnd!(value)
                : null,
            child: CustomPaint(
              size: Size(w, compact ? 16 : 18),
              painter: _SliderPainter(
                value: value.clamp(0, 1).toDouble(),
                defaultValue: defaultValue?.clamp(0, 1).toDouble(),
                track: c.control,
                fill: enabled ? c.accent : c.strong,
                tick: c.strong,
                compact: compact,
                empty: empty,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SliderPainter extends CustomPainter {
  _SliderPainter({
    required this.value,
    required this.defaultValue,
    required this.track,
    required this.fill,
    required this.tick,
    required this.compact,
    required this.empty,
  });
  final double value;
  final double? defaultValue;
  final Color track;
  final Color fill;
  final Color tick;
  final bool compact;
  final bool empty;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final top = compact ? 7.0 : 8.0;
    const r = Radius.circular(2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, top, w, 3), r),
      Paint()..color = track,
    );
    if (empty) return;
    if (value > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, top, w * value, 3), r),
        Paint()..color = fill,
      );
    }
    if (defaultValue != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * defaultValue! - 1, 4, 2, 11),
          const Radius.circular(1),
        ),
        Paint()..color = tick,
      );
    }
    final d = compact ? 13.0 : 15.0;
    final rect = Rect.fromLTWH(
      w * value - (compact ? 6 : 7),
      compact ? 1 : 2,
      d,
      d,
    );
    final center = rect.center;
    canvas.drawCircle(
      center + const Offset(0, 1),
      d / 2,
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawCircle(center, d / 2, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      d / 2 - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = fill,
    );
  }

  @override
  bool shouldRepaint(_SliderPainter old) =>
      old.value != value ||
      old.defaultValue != defaultValue ||
      old.fill != fill ||
      old.track != track ||
      old.empty != empty;
}

/// 数字框（原型 `.num`）：28 高、最小宽 54、圆角 6、控件底、Geist Mono 12.5 / 500，两位小数。
/// [changed] = 改过还没存：1px 强调色内描边 + 强调色字。点一下可以直接输入，回车 / 失焦确认。
class UiNumBox extends StatefulWidget {
  const UiNumBox({
    super.key,
    required this.value,
    this.onSubmitted,
    this.changed = false,
    this.placeholder,
    this.max = 1,
    this.compact = false,
  });

  final double value;
  final ValueChanged<double>? onSubmitted;
  final bool changed;

  /// 有值时显示这段弱色文字（多选的“混合”）。
  final String? placeholder;

  /// 输入上限（精准参考可以填超过 1 的值）。
  final double max;

  /// 组合包网格：24 高、最小宽 44、11.5 号字。
  final bool compact;

  @override
  State<UiNumBox> createState() => _UiNumBoxState();
}

class _UiNumBoxState extends State<UiNumBox> {
  TextEditingController? _edit;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void dispose() {
    _edit?.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _start() {
    final text = widget.placeholder == null
        ? widget.value.toStringAsFixed(2)
        : '';
    setState(
      () => _edit = TextEditingController(text: text)
        ..selection = TextSelection(baseOffset: 0, extentOffset: text.length),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _commit() {
    final e = _edit;
    if (e == null) return;
    final v = double.tryParse(e.text.trim());
    setState(() => _edit = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => e.dispose());
    if (v != null) {
      widget.onSubmitted?.call(
        (v.clamp(0, widget.max) * 100).roundToDouble() / 100,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final ink = widget.placeholder != null
        ? c.faint
        : (widget.changed ? c.accent : c.ink);
    final style = UiText.mono(
      widget.compact ? 11.5 : 12.5,
      weight: FontWeight.w500,
      color: ink,
      height: 1.2,
    );
    final box = Container(
      height: widget.compact ? 24 : 28,
      constraints: BoxConstraints(minWidth: widget.compact ? 44 : 54),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(6),
        border: widget.changed || _edit != null
            ? Border.all(color: c.accent)
            : null,
      ),
      child: _edit != null
          ? SizedBox(
              width: 38,
              child: Focus(
                onKeyEvent: (_, e) {
                  if (e is KeyDownEvent &&
                      e.logicalKey == LogicalKeyboardKey.escape) {
                    _edit!.text = '';
                    _focus.unfocus();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: _edit,
                  focusNode: _focus,
                  textAlign: TextAlign.center,
                  style: style.copyWith(color: c.ink),
                  cursorColor: c.accent,
                  cursorHeight: 14,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: uiBareDecoration(),
                  onSubmitted: (_) => _focus.unfocus(),
                ),
              ),
            )
          : Text(
              widget.placeholder ?? widget.value.toStringAsFixed(2),
              maxLines: 1,
              style: style,
            ),
    );
    if (widget.onSubmitted == null || _edit != null) return box;
    return UiPressable(onTap: _start, builder: (context, _) => box);
  }
}
