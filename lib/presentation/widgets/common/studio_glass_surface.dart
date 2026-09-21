import 'package:flutter/material.dart';

/// Quiet glass finish: static grain and edge light never blur foreground text.
/// Native translucency is opt-in and only used after DWM confirms availability.
class StudioGlassSurface extends StatelessWidget {
  const StudioGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.nativeBackdrop = false,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final bool nativeBackdrop;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final highContrast = MediaQuery.highContrastOf(context);
    final base = theme.colorScheme.surfaceContainerLow;
    final highlightOpacity = dark ? (nativeBackdrop ? .015 : .065) : .8;
    final top = Color.alphaBlend(
      Colors.white.withValues(alpha: highlightOpacity),
      base,
    );
    final bottom = Color.alphaBlend(
      (dark ? Colors.black : theme.colorScheme.outlineVariant).withValues(
        alpha: dark ? .03 : .12,
      ),
      base,
    );
    // Match each workspace with a stronger neutral tint, keeping only a hint
    // of desktop colour instead of a contrasting strip above the content.
    final topOpacity = nativeBackdrop ? (dark ? .90 : .84) : 1.0;
    final bottomOpacity = nativeBackdrop ? (dark ? .94 : .90) : 1.0;
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
                  colors: [
                    top.withValues(alpha: topOpacity),
                    bottom.withValues(alpha: bottomOpacity),
                  ],
                ),
        ),
        child: CustomPaint(
          painter: highContrast ? null : _GlassGrain(dark),
          foregroundPainter: _GlassEdge(
            borderRadius,
            highContrast
                ? theme.colorScheme.outline
                : Colors.white.withValues(
                    alpha: dark ? (nativeBackdrop ? .08 : .15) : .92,
                  ),
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
