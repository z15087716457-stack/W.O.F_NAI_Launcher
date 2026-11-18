import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_resource_kind.dart';
import '../kit/ui_text.dart';
import 'gen_page.dart';
import 'gen_parts.dart';

class GenResourceWindowIcon extends StatelessWidget {
  const GenResourceWindowIcon({
    super.key,
    this.visibility = ResourceWindowVisibility.closed,
    this.size = 15,
  });
  final ResourceWindowVisibility visibility;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _WindowIconPainter(visibility, context.ui)),
  );
}

class _WindowIconPainter extends CustomPainter {
  _WindowIconPainter(this.visibility, this.colors);
  final ResourceWindowVisibility visibility;
  final UiColors colors;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final blue = colors.accent;
    void window(Offset offset, Color stroke, Color fill) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 19, 19),
          const Radius.circular(4),
        ),
        Paint()..color = fill,
      );
      canvas.scale(19 / 24);
      final pen = Paint()
        ..color = stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(2, 4, 20, 16),
          const Radius.circular(2),
        ),
        pen,
      );
      canvas.drawLine(const Offset(2, 8), const Offset(22, 8), pen);
      for (final x in [6.0, 10.0]) {
        canvas.drawLine(Offset(x, 4), Offset(x, 8), pen);
      }
      canvas.restore();
    }

    if (visibility == ResourceWindowVisibility.back) {
      window(const Offset(5, 5), blue, colors.card);
      window(Offset.zero, colors.muted, colors.card);
    } else {
      window(Offset.zero, colors.faint, colors.card);
      window(
        const Offset(5, 5),
        visibility == ResourceWindowVisibility.front ? blue : colors.muted,
        visibility == ResourceWindowVisibility.front
            ? Color.alphaBlend(blue.withValues(alpha: .14), colors.card)
            : colors.card,
      );
    }
  }

  @override
  bool shouldRepaint(_WindowIconPainter oldDelegate) =>
      visibility != oldDelegate.visibility || colors != oldDelegate.colors;
}

/// Both entry points use one action. A pointer click retains its native
/// pre-activation order; keyboard activation uses the current window order.
class GenResourceWindowToggle extends StatefulWidget {
  const GenResourceWindowToggle({super.key, this.menu = false});
  final bool menu;
  @override
  State<GenResourceWindowToggle> createState() => _ResourceToggleState();
}

class _ResourceToggleState extends State<GenResourceWindowToggle> {
  bool _fromPointer = false;
  @override
  Widget build(BuildContext context) {
    final scope = GenScope.of(context, GenAspect.prompt);
    final visibility = scope.data.prompt.tools.resourceWindowVisibility;
    final colors = context.ui;
    final l = context.l10n;
    final tooltip = switch (visibility) {
      ResourceWindowVisibility.closed => l.resourceWindow_show,
      ResourceWindowVisibility.front => l.resourceWindow_hide,
      ResourceWindowVisibility.back => l.resourceWindow_recall,
    };
    void toggle() {
      final pointer = _fromPointer;
      _fromPointer = false;
      if (widget.menu) scope.controller.closePopover();
      scope.actions.onToggleResourceWindow?.call(pointer);
    }

    final icon = GenResourceWindowIcon(visibility: visibility);
    return Listener(
      onPointerDown: (event) => _fromPointer = event.buttons == kPrimaryButton,
      onPointerCancel: (_) => _fromPointer = false,
      onPointerUp: (_) => scheduleMicrotask(() => _fromPointer = false),
      child: Semantics(
        toggled: visibility != ResourceWindowVisibility.closed,
        child: widget.menu
            ? UiPressable(
                onTap: toggle,
                builder: (context, hover) => Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: hover ? colors.control : null,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    spacing: 10,
                    children: [
                      SizedBox(width: 16, child: icon),
                      Expanded(
                        child: Text(
                          l.floating_open,
                          style: UiText.sans(13, color: colors.ink),
                        ),
                      ),
                      if (visibility != ResourceWindowVisibility.closed)
                        Text(
                          visibility == ResourceWindowVisibility.back
                              ? l.resourceWindow_inBackground
                              : l.resourceWindow_opened,
                          style: UiText.sans(11, color: colors.muted),
                        ),
                    ],
                  ),
                ),
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: visibility == ResourceWindowVisibility.front
                      ? colors.accent.withValues(alpha: .14)
                      : null,
                ),
                child: GenIb(
                  icon: icon,
                  plain: true,
                  tooltip: tooltip,
                  onTap: toggle,
                ),
              ),
      ),
    );
  }
}
