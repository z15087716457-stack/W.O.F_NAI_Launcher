import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Glass finish for compact in-app surfaces. The optional backdrop pass samples
/// only pixels behind this clipped surface; child text and controls stay sharp.
class StudioGlassSurface extends StatelessWidget {
  const StudioGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.nativeBackdrop = false,
    this.backdropBlur = false,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final bool nativeBackdrop;
  final bool backdropBlur;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final highContrast = MediaQuery.highContrastOf(context);
    if (nativeBackdrop && !highContrast) {
      // The window's own page colour laid flat over the DWM acrylic: mostly
      // solid, letting only a soft hint of what is behind show through. No
      // gradient or edge light, so the bar never reads as a grey strip.
      return ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        child: ColoredBox(
          color: theme.colorScheme.surface.withValues(alpha: dark ? .80 : .78),
          child: child,
        ),
      );
    }
    if (backdropBlur && !highContrast) {
      final base = theme.colorScheme.surfaceContainerLow;
      final colors = dark
          ? [
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: .64),
              base.withValues(alpha: .61),
              theme.colorScheme.surface.withValues(alpha: .66),
            ]
          : [
              Colors.white.withValues(alpha: .60),
              base.withValues(alpha: .55),
              theme.colorScheme.outline.withValues(alpha: .60),
            ];
      return ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
            tileMode: ui.TileMode.clamp,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
            child: CustomPaint(
              painter: _GlassGrain(dark),
              foregroundPainter: _GlassEdge(
                borderRadius,
                Colors.white.withValues(alpha: dark ? .22 : .92),
                theme.colorScheme.outline.withValues(alpha: dark ? .4 : .32),
              ),
              child: child,
            ),
          ),
        ),
      );
    }
    final base = theme.colorScheme.surfaceContainerLow;
    final top = Color.alphaBlend(
      Colors.white.withValues(alpha: dark ? .065 : .8),
      base,
    );
    final bottom = Color.alphaBlend(
      (dark ? Colors.black : theme.colorScheme.outlineVariant).withValues(
        alpha: dark ? .03 : .55,
      ),
      base,
    );
    return ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: highContrast ? theme.colorScheme.surface : null,
          gradient: highContrast
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [top, bottom],
                ),
        ),
        child: CustomPaint(
          painter: highContrast ? null : _GlassGrain(dark),
          foregroundPainter: _GlassEdge(
            borderRadius,
            highContrast
                ? theme.colorScheme.outline
                : Colors.white.withValues(alpha: dark ? .15 : .92),
            highContrast
                ? theme.colorScheme.outline
                : theme.colorScheme.outline.withValues(alpha: dark ? .32 : .38),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassGrain extends CustomPainter {
  const _GlassGrain(this.dark);
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (dark ? Colors.white : Colors.black).withValues(
        alpha: dark ? .027 : .018,
      );
    // Fixed integer hashing: no animation, image assets or backdrop blur passes.
    for (var y = 1; y < size.height; y += 4) {
      for (var x = 1; x < size.width; x += 4) {
        final hash = (((x * 73856093) ^ (y * 19349663)) >> 7) & 15;
        if (hash < 5) {
          canvas.drawRect(
            Rect.fromLTWH(x + hash * .35, y.toDouble(), .65, .65),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GlassGrain oldDelegate) => oldDelegate.dark != dark;
}

class _GlassEdge extends CustomPainter {
  const _GlassEdge(this.radius, this.top, this.bottom);
  final BorderRadius radius;
  final Color top;
  final Color bottom;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      radius.toRRect(rect.deflate(.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassEdge oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.top != top ||
      oldDelegate.bottom != bottom;
}
