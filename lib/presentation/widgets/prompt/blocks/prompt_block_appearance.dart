import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Visual presets remain independent of block content and generation text.
abstract final class PromptBlockAppearance {
  static const classic = 'classic';
  static const stripes = 'stripes';
  static const dots = 'dots';
  static const solid = 'solid';
  static const gradient = 'gradient';
  static const translation = 'translation';

  static const selectable = [
    classic,
    stripes,
    dots,
    solid,
    gradient,
    translation,
  ];

  static String label(String value, AppLocalizations l10n) => switch (value) {
    stripes => l10n.blockAppearance_stripes,
    dots => l10n.blockAppearance_dots,
    solid => l10n.blockAppearance_solid,
    gradient => l10n.blockAppearance_gradient,
    translation => l10n.blockAppearance_translation,
    _ => l10n.blockAppearance_classic,
  };

  static Color fill(
    String value,
    Color color, {
    required bool dark,
    Color? translationSurface,
  }) {
    if (value == solid) return color;
    if (value == translation && translationSurface != null) {
      return translationSurface;
    }
    if (value == stripes || value == gradient) return Colors.transparent;
    if (value == dots) return color.withValues(alpha: .05);
    return color.withValues(alpha: dark ? .15 : .08);
  }

  static Color text(
    String value,
    Color color,
    Color fallback, {
    bool dark = false,
  }) {
    if (value == translation) return fallback;
    if (value != solid) return Color.lerp(fallback, color, dark ? .62 : .72)!;
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}

class PromptBlockPatternPainter extends CustomPainter {
  const PromptBlockPatternPainter({
    required this.appearance,
    required this.color,
  });
  final String appearance;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (appearance == PromptBlockAppearance.classic ||
        appearance == PromptBlockAppearance.solid ||
        appearance == PromptBlockAppearance.translation ||
        size.isEmpty) {
      return;
    }
    final paint = Paint();
    if (appearance == PromptBlockAppearance.dots) {
      paint.color = color.withValues(alpha: .34);
      for (var x = 3.0; x < size.width; x += 6) {
        for (var y = 3.0; y < size.height; y += 6) {
          canvas.drawCircle(Offset(x, y), .9, paint);
        }
      }
      return;
    }
    if (appearance == PromptBlockAppearance.gradient) {
      final gradient = LinearGradient(
        colors: [color.withValues(alpha: .24), color.withValues(alpha: .02)],
      );
      canvas.drawRect(
        Offset.zero & size,
        Paint()..shader = gradient.createShader(Offset.zero & size),
      );
      return;
    }
    // One shader pass avoids compounding two alpha layers at each stripe.
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      tileMode: TileMode.repeated,
      colors: [
        color.withValues(alpha: .17),
        color.withValues(alpha: .17),
        color.withValues(alpha: .05),
        color.withValues(alpha: .05),
      ],
      stops: const [0, 3 / 7, 3 / 7, 1],
    );
    canvas.drawRect(
      Offset.zero & size,
      paint
        ..shader = gradient.createShader(
          const Rect.fromLTWH(0, 0, 7 / math.sqrt2, 7 / math.sqrt2),
        ),
    );
  }

  @override
  bool shouldRepaint(PromptBlockPatternPainter oldDelegate) =>
      oldDelegate.appearance != appearance || oldDelegate.color != color;
}
