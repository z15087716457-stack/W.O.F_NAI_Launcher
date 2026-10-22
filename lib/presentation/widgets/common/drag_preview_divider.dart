import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Drag-only state. Updating this notifier never invalidates the page layout.
class DragPreviewController extends ValueNotifier<double?> {
  DragPreviewController() : super(null);

  double? _startWidth;
  double _delta = 0;
  double? _width;

  void start(double width, double position) {
    cancel();
    _startWidth = _width = width;
    _delta = 0;
    FocusManager.instance.addEarlyKeyEventHandler(_onKey);
    value = position;
  }

  void move(
    double delta, {
    required double Function(double) resolve,
    required double Function(double) position,
  }) {
    final start = _startWidth;
    if (start == null) return;
    _delta += delta;
    _width = resolve(start + _delta);
    value = position(_width!);
  }

  /// Null also covers an Esc-cancelled gesture whose pointer is still down.
  double? finish() {
    final width = _width;
    final changed = width != _startWidth;
    cancel();
    return changed ? width : null;
  }

  KeyEventResult _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      cancel();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void cancel() {
    FocusManager.instance.removeEarlyKeyEventHandler(_onKey);
    _startWidth = _width = null;
    value = null;
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(_onKey);
    super.dispose();
  }
}

/// A permanent Stack child keeps the content's element/parent stable. Only the
/// isolated overlay rebuilds/layouts during moves; the page is not a listener.
class DragPreviewDivider extends StatelessWidget {
  const DragPreviewDivider({
    super.key,
    required this.controller,
    required this.color,
  });

  final DragPreviewController controller;
  final Color color;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: RepaintBoundary(
      child: ValueListenableBuilder<double?>(
        valueListenable: controller,
        builder: (context, position, _) => position == null
            ? const SizedBox.expand()
            : MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                hitTestBehavior: HitTestBehavior.translucent,
                child: CustomPaint(
                  painter: DragPreviewPainter(
                    position,
                    color.withValues(alpha: .8),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
      ),
    ),
  );
}

class DragPreviewPainter extends CustomPainter {
  const DragPreviewPainter(this.position, this.color);
  final double position;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    Rect.fromLTWH(position - 1, 0, 2, size.height),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(DragPreviewPainter oldDelegate) =>
      position != oldDelegate.position || color != oldDelegate.color;
}
