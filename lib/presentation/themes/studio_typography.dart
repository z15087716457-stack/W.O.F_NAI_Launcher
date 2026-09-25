import 'package:flutter/material.dart';

import 'core/theme_modules.dart';

/// Bundled, offline typography. Roles remain stable across color themes.
abstract final class StudioTypography {
  static const sans = 'Geist';
  static const mono = 'Geist Mono';
  static const pixel = 'Geist Pixel Line';
  static const pixelSquare = 'Geist Pixel Square';
  static const pixelCircle = 'Geist Pixel Circle';
  static const cjk = 'HarmonyOS Sans SC';
  static const fallback = [cjk];

  static const body = TextStyle(fontFamily: sans, fontFamilyFallback: fallback);

  static const data = TextStyle(fontFamily: mono, fontFamilyFallback: fallback);

  // The Line variant needs enough physical pixels to keep its horizontal cuts.
  static const wordmark = TextStyle(
    fontFamily: pixel,
    fontFamilyFallback: fallback,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );
}

class StudioTypographyModule implements TypographyModule {
  const StudioTypographyModule();

  @override
  String get displayFontFamily => StudioTypography.sans;

  @override
  String get bodyFontFamily => StudioTypography.sans;

  @override
  TextTheme get textTheme => Typography.material2021().black.apply(
    fontFamily: StudioTypography.sans,
    fontFamilyFallback: StudioTypography.fallback,
  );
}
