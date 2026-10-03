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

  static Color fill(String value, Color color, {required bool dark}) {
    if (value == solid) return color;
    return color.withValues(alpha: dark ? .23 : .14);
  }

  static Color text(String value, Color color, Color fallback) {
    if (value != solid) return fallback;
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
    final paint = Paint()
      ..color = color.withValues(alpha: .14)
      ..strokeWidth = 1;
    if (appearance == PromptBlockAppearance.dots) {
      for (var x = 5.0; x < size.width; x += 10) {
        for (var y = 5.0; y < size.height; y += 10) {
          canvas.drawCircle(Offset(x, y), 1, paint);
        }
      }
      return;
    }
    if (appearance == PromptBlockAppearance.gradient) {
      final gradient = LinearGradient(
        colors: [color.withValues(alpha: .11), Colors.transparent],
      );
      canvas.drawRect(
        Offset.zero & size,
        Paint()..shader = gradient.createShader(Offset.zero & size),
      );
      return;
    }
    const step = 9.0;
    paint.color = color.withValues(alpha: .16);
    for (var x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(math.max(0, x), math.max(0, -x)),
        Offset(
          math.min(size.width, x + size.height),
          math.min(size.height, size.height + x),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(PromptBlockPatternPainter oldDelegate) =>
      oldDelegate.appearance != appearance || oldDelegate.color != color;
}
