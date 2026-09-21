import 'package:flutter/material.dart';

import 'generation_canvas_controller.dart';

/// Sparse, seamless pixel circuits anchored to the same world as the images.
/// Rectangles are snapped to physical pixels; no large raster texture is needed.
class CanvasPixelBackgroundPainter extends CustomPainter {
  CanvasPixelBackgroundPainter({
    required this.camera,
    required this.theme,
    required this.devicePixelRatio,
  });

  final CanvasCamera camera;
  final ThemeData theme;
  final double devicePixelRatio;

  static const period = 512.0;
  static final List<Rect> _rects = _buildPattern();

  @override
  void paint(Canvas canvas, Size size) {
    final dark = theme.brightness == Brightness.dark;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = dark ? const Color(0xFF191919) : theme.colorScheme.surface,
    );

    final scale = camera.scale;
    // Subpixel circuits become visual noise at overview zoom. Fade them out
    // continuously before their two-pixel lines become too small to display.
    final visibility = ((scale - 0.12) / 0.38).clamp(0.0, 1.0);
    if (visibility == 0 || size.isEmpty) return;

    final paint = Paint()
      ..isAntiAlias = false
      ..color = (dark ? const Color(0xFF96ACC6) : const Color(0xFF45576A))
          .withValues(alpha: (dark ? 0.15 : 0.10) * visibility);
    final step = period * scale;
    final startX = camera.offset.dx % step - step;
    final startY = camera.offset.dy % step - step;
    double snap(double value) =>
        (value * devicePixelRatio).roundToDouble() / devicePixelRatio;

    // Include the preceding tile: motifs can extend beyond the right/bottom
    // edges. Drawing them here wraps those portions without clipping seams.
    for (var x = startX; x < size.width; x += step) {
      for (var y = startY; y < size.height; y += step) {
        for (final rect in _rects) {
          final screen = Rect.fromLTRB(
            snap(x + rect.left * scale),
            snap(y + rect.top * scale),
            snap(x + rect.right * scale),
            snap(y + rect.bottom * scale),
          );
          if (!screen.isEmpty && screen.overlaps(Offset.zero & size)) {
            canvas.drawRect(screen, paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(CanvasPixelBackgroundPainter oldDelegate) =>
      camera.offset != oldDelegate.camera.offset ||
      camera.scale != oldDelegate.camera.scale ||
      theme != oldDelegate.theme ||
      devicePixelRatio != oldDelegate.devicePixelRatio;

  static List<Rect> _buildPattern() {
    const anchors = [
      Offset(36, 52),
      Offset(234, 18),
      Offset(412, 106),
      Offset(132, 212),
      Offset(322, 276),
      Offset(22, 396),
      Offset(224, 462),
      Offset(466, 426),
    ];
    final rects = <Rect>[];
    for (var i = 0; i < anchors.length; i++) {
      _PixelMotif(rects, anchors[i], i % 4).draw(i % 5);
    }
    _PixelMotif(rects, const Offset(502, 502), 0).draw(0);
    return List.unmodifiable(rects);
  }
}

class _PixelMotif {
  _PixelMotif(this.rects, this.anchor, this.turns);

  final List<Rect> rects;
  final Offset anchor;
  final int turns;

  void rect(double x, double y, double width, double height) {
    final local = switch (turns) {
      1 => Rect.fromLTWH(-y - height, x, height, width),
      2 => Rect.fromLTWH(-x - width, -y - height, width, height),
      3 => Rect.fromLTWH(y, -x - width, height, width),
      _ => Rect.fromLTWH(x, y, width, height),
    };
    rects.add(local.shift(anchor));
  }

  void square(double x, double y, double size) {
    rect(x, y, size, 2);
    rect(x, y + size - 2, size, 2);
    rect(x, y, 2, size);
    rect(x + size - 2, y, 2, size);
  }

  void line(List<Offset> points) {
    for (var i = 1; i < points.length; i++) {
      final bounds = Rect.fromPoints(points[i - 1], points[i]);
      rect(bounds.left, bounds.top, bounds.width + 2, bounds.height + 2);
    }
  }

  void draw(int kind) {
    switch (kind) {
      case 0:
        square(0, 0, 8);
        line(const [
          Offset(8, 2),
          Offset(30, 2),
          Offset(30, 18),
          Offset(46, 18),
        ]);
        rect(46, 16, 6, 6);
      case 1:
        square(0, 0, 14);
        for (final p in [2.0, 8.0]) {
          rect(p, -6, 2, 4);
          rect(p, 16, 2, 4);
          rect(-6, p, 4, 2);
          rect(16, p, 4, 2);
        }
        rect(6, 6, 2, 2);
      case 2:
        line(const [
          Offset.zero,
          Offset(20, 0),
          Offset(20, -16),
          Offset(42, -16),
        ]);
        square(-6, -2, 6);
        rect(44, -16, 4, 4);
      case 3:
        rect(0, 0, 4, 4);
        rect(10, 0, 4, 4);
        rect(20, 0, 4, 4);
        line(const [Offset(0, 14), Offset(24, 14), Offset(24, 26)]);
      case 4:
        square(0, 0, 8);
        square(28, -20, 6);
        line(const [
          Offset(8, 2),
          Offset(16, 2),
          Offset(16, -18),
          Offset(28, -18),
        ]);
    }
  }
}
