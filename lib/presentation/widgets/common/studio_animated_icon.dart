import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'studio_icon_paths.dart';
import 'studio_icons.dart';

/// Plays one feature-specific gesture when [trigger] changes. The enclosing
/// button owns activation, so pointer, keyboard and accessibility use one path.
/// Repeated activation never queues animations or delays the actual action.
class StudioAnimatedIcon extends StatefulWidget {
  const StudioAnimatedIcon({
    super.key,
    required this.icon,
    this.trigger = 0,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final int trigger;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  State<StudioAnimatedIcon> createState() => _StudioAnimatedIconState();
}

class _StudioAnimatedIconState extends State<StudioAnimatedIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _playing = false;
  bool _motionAllowed = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _playing = false);
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionAllowed =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (!_motionAllowed) _stop();
  }

  void _stop() {
    _controller.stop();
    _playing = false;
  }

  @override
  void didUpdateWidget(StudioAnimatedIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.icon != widget.icon) _stop();
    if (oldWidget.trigger != widget.trigger &&
        _motionAllowed &&
        !_playing &&
        StudioIcons.supportsMotion(widget.icon)) {
      _controller.duration = Duration(
        milliseconds: switch (widget.icon.codePoint) {
          0xe906 => 600, // Draw, lift, return.
          0xe900 => 580, // Parents to child.
          0xe908 => 560, // Staggered columns.
          _ => 500,
        },
      );
      _playing = true;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_playing) {
      return Icon(
        widget.icon,
        size: widget.size,
        color: widget.color,
        semanticLabel: widget.semanticLabel,
      );
    }
    final theme = IconTheme.of(context);
    final size = widget.size ?? theme.size ?? 24;
    final color =
        widget.color ?? theme.color ?? Theme.of(context).colorScheme.onSurface;
    return Semantics(
      label: widget.semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: StudioIconPainter(
              icon: widget.icon,
              progress: _controller,
              color: color.withValues(alpha: color.a * (theme.opacity ?? 1)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated paths are generated from the same SVG masters as StudioIcons.ttf.
/// Canvas transforms affect individual parts, never the button's hit region.
class StudioIconPainter extends CustomPainter {
  StudioIconPainter({
    required this.icon,
    required this.progress,
    required this.color,
  }) : super(repaint: progress);

  final IconData icon;
  final Animation<double> progress;
  final Color color;

  static double _ease(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  static double _mix(double a, double b, double t) => a + (b - a) * t;

  static double _keys(double t, List<(double, double)> frames) {
    if (t <= frames.first.$1) return frames.first.$2;
    for (var i = 1; i < frames.length; i++) {
      if (t <= frames[i].$1) {
        final a = frames[i - 1];
        final b = frames[i];
        return _mix(a.$2, b.$2, _ease((t - a.$1) / (b.$1 - a.$1)));
      }
    }
    return frames.last.$2;
  }

  static double _pulse(double t, double start, double end) =>
      t <= start || t >= end
      ? 0
      : math.sin(math.pi * (t - start) / (end - start));

  void _draw(
    Canvas canvas,
    StudioIconPart part, {
    double opacity = 1,
    double trim = 1,
  }) {
    final paint = Paint()
      ..color = color.withValues(alpha: color.a * opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = part.strokeWidth;
    if (trim >= 1) {
      canvas.drawPath(part.path, paint);
    } else if (trim > 0) {
      for (final metric in part.path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * trim), paint);
      }
    }
  }

  void _around(
    Canvas canvas,
    double x,
    double y, {
    double sx = 1,
    double sy = 1,
    double angle = 0,
  }) {
    canvas.translate(x, y);
    canvas.rotate(angle);
    canvas.scale(sx, sy);
    canvas.translate(-x, -y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final parts = studioIconPaths[icon.codePoint];
    if (parts == null) return;
    final t = progress.value.clamp(0.0, 1.0);
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    for (final part in parts) {
      canvas.save();
      var opacity = 1.0;
      var trim = 1.0;
      switch (icon.codePoint) {
        case 0xe900:
          final (x, y, start, end) = switch (part.name) {
            'left' => (6.5, 6.0, 0.0, .42),
            'right' => (17.5, 6.0, .12, .54),
            _ => (12.0, 18.0, .48, 1.0),
          };
          if (part.name == 'branches') {
            _draw(canvas, part, opacity: 1 - .65 * _pulse(t, .1, .9));
            trim = _ease((t - .2) / .5);
            opacity = _pulse(t, .1, .9);
          } else {
            final scale = 1 + .1 * _pulse(t, start, end);
            _around(canvas, x, y, sx: scale, sy: scale);
          }
        case 0xe901:
          final wave = math.sin(t * math.pi * 2) * math.sin(t * math.pi);
          _around(
            canvas,
            12,
            12,
            sx: part.name == 'rails'
                ? 1 - .18 * math.sin(math.pi * t)
                : 1 - .3 * math.sin(math.pi * t),
            angle: wave * .09,
          );
        case 0xe902:
          if (part.name == 'longitude') {
            final angle = math.pi * _ease(t);
            _around(canvas, 17, 17, sx: math.max(.08, math.cos(angle).abs()));
          }
        case 0xe903:
          if (part.name == 'loose') {
            final y = _keys(t, [
              (0, 0),
              (.24, -1.5),
              (.42, -1.5),
              (.69, .3),
              (.82, -.18),
              (1, 0),
            ]);
            final angle = _keys(t, [
              (0, 0),
              (.24, -13),
              (.42, -13),
              (.69, -1),
              (.82, 1.2),
              (1, 0),
            ]);
            canvas.translate(0, y);
            _around(canvas, 17, 6.7, angle: angle * math.pi / 180);
          }
        case 0xe904:
        case 0xe905:
          if (part.name != 'back') {
            final lift = _keys(t, [(0, 0), (.35, 1), (.6, 1), (1, 0)]);
            canvas.translate(lift * 1.1, -lift * .8);
            if (part.name == 'person') opacity = 1 - .55 * _pulse(t, 0, .7);
            if (part.name == 'arrow') {
              // Fade down gently before revealing; never pop to an empty card.
              opacity = _keys(t, [(0, 1), (.16, .12), (.38, 1), (1, 1)]);
              trim = _keys(t, [(0, 1), (.16, .02), (.66, 1), (1, 1)]);
            }
          }
        case 0xe906:
          if (part.name == 'frame') _paintStroke(canvas, t);
          if (part.name == 'brush') {
            double x, y, angle, scale;
            if (t < .25) {
              x = _keys(t, [(0, 8.5), (.1, 8.1), (.25, 6.2)]);
              y = _keys(t, [(0, 20.8), (.1, 19.7), (.25, 13.5)]);
              angle = _keys(t, [(0, 0), (.1, -5), (.25, 15)]);
              scale = _keys(t, [(0, 1), (.1, .96), (.25, .82)]);
            } else if (t < .62) {
              final v = _ease((t - .25) / .37);
              final u = 1 - v;
              x =
                  u * u * u * 6.2 +
                  3 * u * u * v * 7.6 +
                  3 * u * v * v * 8.5 +
                  v * v * v * 10.8;
              y =
                  u * u * u * 13.5 +
                  3 * u * u * v * 10.2 +
                  3 * u * v * v * 15.6 +
                  v * v * v * 12;
              angle = 15;
              scale = .82;
            } else {
              x = _keys(t, [(.62, 10.8), (.72, 11.4), (.9, 8.6), (1, 8.5)]);
              y = _keys(t, [(.62, 12), (.72, 10.7), (.9, 20.2), (1, 20.8)]);
              angle = _keys(t, [(.62, 15), (.72, 12), (.9, -2), (1, 0)]);
              scale = _keys(t, [(.62, .82), (.72, .86), (.9, 1), (1, 1)]);
            }
            canvas.translate(x, y);
            canvas.rotate(angle * math.pi / 180);
            canvas.scale(scale);
            canvas.translate(-8.5, -20.8);
          }
        case 0xe907:
          final open = _keys(t, [(0, 0), (.35, 1), (.55, 1), (1, 0)]);
          if (part.name == 'folder') {
            _around(canvas, 12, 21, sy: 1 - .12 * open);
          } else {
            canvas.translate(0, -2 * open);
          }
        case 0xe908:
          final delay = switch (part.name) {
            'first' => 0.0,
            'second' => .1,
            _ => .2,
          };
          final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
          final growth = _keys(local, [(0, 1), (.2, .28), (.75, 1.03), (1, 1)]);
          _around(canvas, 12, 21, sy: growth);
        case 0xe909:
          if (part.name == 'gear') {
            _around(canvas, 12, 12, angle: math.pi / 3 * _ease(t));
          }
        case 0xe90a:
          // The two studs lift and click back into the brick in sequence.
          if (part.name == 'leftStud' || part.name == 'rightStud') {
            final delay = part.name == 'rightStud' ? .08 : 0.0;
            final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
            final lift = _keys(local, [
              (0, 0),
              (.24, -2.1),
              (.42, -2.1),
              (.67, .45),
              (.82, -.18),
              (1, 0),
            ]);
            canvas.translate(0, lift);
          } else if (part.name == 'body') {
            final press = _pulse(t, .45, .8);
            _around(canvas, 12, 20, sy: 1 - .04 * press);
          } else if (part.name == 'seam') {
            opacity = 1 - .45 * _pulse(t, .3, .83);
          }
      }
      _draw(canvas, part, opacity: opacity, trim: trim);
      canvas.restore();
    }
    canvas.restore();
  }

  void _paintStroke(Canvas canvas, double t) {
    if (t < .25 || t >= .96) return;
    final stroke = Path()
      ..moveTo(6.2, 13.5)
      ..cubicTo(7.6, 10.2, 8.5, 15.6, 10.8, 12);
    _draw(
      canvas,
      StudioIconPart('ink', stroke, 1.4),
      opacity: 1 - _ease((t - .72) / .24),
      trim: _ease((t - .25) / .37),
    );
  }

  @override
  bool shouldRepaint(StudioIconPainter oldDelegate) =>
      icon != oldDelegate.icon ||
      color != oldDelegate.color ||
      progress != oldDelegate.progress;
}
