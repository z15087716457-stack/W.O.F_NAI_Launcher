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

  static const _cellSize = 160.0;
  static const _cellsPerChunk = 4;
  static const _chunkSize = _cellSize * _cellsPerChunk;
  static final List<List<Rect>> _variants = _buildVariants();
  static final _chunks = <(int, int), List<_Circuit>>{};

  @override
  void paint(Canvas canvas, Size size) {
    final dark = theme.brightness == Brightness.dark;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = theme.colorScheme.surface,
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
    final viewport = Offset.zero & size;
    final world = camera.visibleWorldRect(size).inflate(64);
    double snap(double value) =>
        (value * devicePixelRatio + 0.5).floorToDouble() / devicePixelRatio;

    // Chunks only bound computation, not the artwork. Each motif has a stable
    // world position, including beyond chunk edges, and is never re-rolled.
    for (
      var x = (world.left / _chunkSize).floor();
      x <= (world.right / _chunkSize).floor();
      x++
    ) {
      for (
        var y = (world.top / _chunkSize).floor();
        y <= (world.bottom / _chunkSize).floor();
        y++
      ) {
        for (final circuit in _chunk(x, y)) {
          if (!world.contains(circuit.position)) continue;
          final origin = camera.worldToScreen(circuit.position);
          for (final rect in _variants[circuit.variant]) {
            final screen = Rect.fromLTRB(
              snap(origin.dx + rect.left * scale),
              snap(origin.dy + rect.top * scale),
              snap(origin.dx + rect.right * scale),
              snap(origin.dy + rect.bottom * scale),
            );
            if (!screen.isEmpty && screen.overlaps(viewport)) {
              canvas.drawRect(screen, paint);
            }
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

  static List<List<Rect>> _buildVariants() {
    return [
      for (var kind = 0; kind < 5; kind++)
        for (var turns = 0; turns < 4; turns++)
          (() {
            final rects = <Rect>[];
            _PixelMotif(rects, Offset.zero, turns).draw(kind);
            final bounds = rects.reduce((a, b) => a.expandToInclude(b));
            final center = Offset(
              (bounds.center.dx / 2).round() * 2,
              (bounds.center.dy / 2).round() * 2,
            );
            return List<Rect>.unmodifiable(
              rects.map((rect) => rect.shift(-center)),
            );
          })(),
    ];
  }

  static int _hash(int x, int y) {
    var value = (x * 374761393 + y * 668265263 + 0x574F46) & 0xFFFFFFFF;
    value = ((value ^ (value >> 13)) * 1274126177) & 0xFFFFFFFF;
    return value ^ (value >> 16);
  }

  static _Circuit _candidate(int x, int y) {
    final seed = _hash(x, y);
    return _Circuit(
      position: Offset(
        x * _cellSize + 16 + (seed & 63) * 2,
        y * _cellSize + 16 + ((seed >> 8) & 63) * 2,
      ),
      variant: (seed >> 16) % _variants.length,
      priority: seed,
    );
  }

  static List<_Circuit> _chunk(int chunkX, int chunkY) {
    final key = (chunkX, chunkY);
    final cached = _chunks.remove(key);
    if (cached != null) {
      _chunks[key] = cached;
      return cached;
    }
    final circuits = <_Circuit>[];
    for (
      var x = chunkX * _cellsPerChunk;
      x < (chunkX + 1) * _cellsPerChunk;
      x++
    ) {
      for (
        var y = chunkY * _cellsPerChunk;
        y < (chunkY + 1) * _cellsPerChunk;
        y++
      ) {
        final candidate = _candidate(x, y);
        var crowded = false;
        for (var dx = -1; dx <= 1 && !crowded; dx++) {
          for (var dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            final neighbor = _candidate(x + dx, y + dy);
            final earlier =
                neighbor.priority < candidate.priority ||
                (neighbor.priority == candidate.priority &&
                    (dx < 0 || (dx == 0 && dy < 0)));
            if (earlier &&
                (neighbor.position - candidate.position).distanceSquared <
                    80 * 80) {
              crowded = true;
              break;
            }
          }
        }
        if (!crowded) circuits.add(candidate);
      }
    }
    final result = List<_Circuit>.unmodifiable(circuits);
    // Bounded cache: an indefinitely scrolling canvas cannot grow memory forever.
    if (_chunks.length >= 256) _chunks.remove(_chunks.keys.first);
    _chunks[key] = result;
    return result;
  }
}

class _Circuit {
  const _Circuit({
    required this.position,
    required this.variant,
    required this.priority,
  });

  final Offset position;
  final int variant;
  final int priority;
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
