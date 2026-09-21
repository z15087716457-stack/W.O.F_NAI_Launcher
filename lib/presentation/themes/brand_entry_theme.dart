import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/font_provider.dart';

/// Entry screens share an appearance choice for this session. The studio's
/// chosen workspace theme stays independent, and no account state is touched.
final brandEntryBrightnessProvider = StateProvider<Brightness>(
  (ref) => Brightness.dark,
);

abstract final class BrandEntryTheme {
  static const blue = Color(0xFF005DFF);

  static ThemeData forBrightness(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xFF0B101A) : const Color(0xFFF3F5F9);
    final surface = dark ? const Color(0xFF111926) : Colors.white;
    final ink = dark ? const Color(0xFFF2F5FC) : const Color(0xFF152033);
    final muted = dark ? const Color(0xFF9AAAC0) : const Color(0xFF5A687D);
    final border = dark ? const Color(0xFF2A374B) : const Color(0xFFD7DFEC);
    final accent = dark ? const Color(0xFF80ADFF) : const Color(0xFF0053E6);
    final scheme = ColorScheme.fromSeed(seedColor: blue, brightness: brightness)
        .copyWith(
          primary: accent,
          onPrimary: dark ? const Color(0xFF0A1730) : Colors.white,
          primaryContainer: dark
              ? const Color(0xFF172E52)
              : const Color(0xFFEAF1FF),
          onPrimaryContainer: ink,
          surface: background,
          onSurface: ink,
          onSurfaceVariant: muted,
          surfaceContainer: surface,
          surfaceContainerHighest: surface,
          outline: border,
          outlineVariant: border,
        );
    const radius = BorderRadius.all(Radius.circular(6));
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: FontConfig.defaultFont.fontFamily,
      textTheme:
          (dark
                  ? Typography.material2021().white
                  : Typography.material2021().black)
              .apply(
                fontFamily: FontConfig.defaultFont.fontFamily,
                bodyColor: ink,
                displayColor: ink,
              ),
      iconTheme: IconThemeData(size: 20, color: muted),
      dividerColor: border,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        labelStyle: TextStyle(color: muted, fontSize: 14),
        hintStyle: TextStyle(color: muted.withValues(alpha: 0.7), fontSize: 14),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: const RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: border),
          minimumSize: const Size(0, 44),
          shape: const RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontSize: 13),
          shape: const RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: blue,
        linearMinHeight: 3,
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: TextStyle(color: background, fontSize: 12),
      ),
    );
  }
}
