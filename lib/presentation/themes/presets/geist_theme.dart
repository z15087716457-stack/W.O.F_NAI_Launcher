import 'package:flutter/material.dart';

import '../studio_typography.dart';
import '../theme_extension.dart';

/// Neutral surfaces and a blue action accent, based on vercel.com/geist/colors.
/// Every Material surface is explicit so seed/tint defaults cannot turn a whole
/// route blue. The brand blue is reserved for controls, never a page background.
abstract final class GeistTheme {
  static const blue = Color(0xFF005DFF);
  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static AppThemeExtension extension(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return AppThemeExtension(
      navBarStyle: AppNavBarStyle.defaultCompact,
      interactionStyle: AppInteractionStyle.material,
      borderColor: dark ? const Color(0xFF2E2E2E) : const Color(0xFFE6E6E6),
      borderWidth: 1,
      dividerColor: dark ? const Color(0xFF292929) : const Color(0xFFE6E6E6),
      enableInsetShadow: false,
      isLightTheme: !dark,
    );
  }

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    // Deep charcoal rather than black; surfaces sit only a few steps apart and
    // borders do the separating, as in Geist's dark scale.
    final background = dark ? const Color(0xFF111111) : Colors.white;
    final panel = dark ? const Color(0xFF161616) : const Color(0xFFFAFAFA);
    final raised = dark ? const Color(0xFF1B1B1B) : Colors.white;
    final control = dark ? const Color(0xFF222222) : const Color(0xFFF2F2F2);
    final hover = dark ? const Color(0xFF282828) : const Color(0xFFEBEBEB);
    final active = dark ? const Color(0xFF2E2E2E) : const Color(0xFFE6E6E6);
    final border = dark ? const Color(0xFF2E2E2E) : const Color(0xFFE6E6E6);
    final strongBorder = dark
        ? const Color(0xFF454545)
        : const Color(0xFFC9C9C9);
    final ink = dark ? const Color(0xFFEDEDED) : const Color(0xFF171717);
    final muted = dark ? const Color(0xFFA1A1A1) : const Color(0xFF666666);
    final accent = dark ? const Color(0xFF50A8FF) : const Color(0xFF0064E2);
    final error = dark ? const Color(0xFFFF6166) : const Color(0xFFC80029);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: dark ? Colors.black : Colors.white,
      primaryContainer: active,
      onPrimaryContainer: ink,
      secondary: muted,
      onSecondary: background,
      secondaryContainer: active,
      onSecondaryContainer: ink,
      tertiary: accent,
      onTertiary: dark ? Colors.black : Colors.white,
      tertiaryContainer: active,
      onTertiaryContainer: ink,
      error: error,
      onError: dark ? Colors.black : Colors.white,
      errorContainer: dark ? const Color(0xFF3C1618) : const Color(0xFFFFECEC),
      onErrorContainer: dark
          ? const Color(0xFFFFBFC1)
          : const Color(0xFF8C0020),
      surface: background,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceDim: panel,
      surfaceBright: raised,
      surfaceContainerLowest: background,
      surfaceContainerLow: panel,
      surfaceContainer: raised,
      surfaceContainerHigh: hover,
      surfaceContainerHighest: control,
      outline: strongBorder,
      outlineVariant: border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: ink,
      onInverseSurface: background,
      inversePrimary: dark ? const Color(0xFF0064E2) : const Color(0xFF50A8FF),
      surfaceTint: Colors.transparent,
    );
    const radius = BorderRadius.all(Radius.circular(6));
    const popoverRadius = BorderRadius.all(Radius.circular(12));
    const shape = RoundedRectangleBorder(borderRadius: radius);
    TextStyle text(double size, [FontWeight weight = FontWeight.w400]) =>
        StudioTypography.body.copyWith(
          color: ink,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: 0,
        );
    final textTheme = StudioTypography.textTheme(ink);
    final primaryButton = FilledButton.styleFrom(
      backgroundColor: blue,
      foregroundColor: Colors.white,
      disabledBackgroundColor: control,
      disabledForegroundColor: muted,
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      elevation: 0,
      shape: shape,
      textStyle: text(14, FontWeight.w500),
    );
    final secondaryButton = OutlinedButton.styleFrom(
      foregroundColor: ink,
      disabledForegroundColor: muted,
      side: BorderSide(color: strongBorder),
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shape: shape,
      textStyle: text(14, FontWeight.w500),
    );
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: raised,
      cardColor: raised,
      dividerColor: border,
      hoverColor: hover,
      focusColor: accent.withValues(alpha: .12),
      disabledColor: muted.withValues(alpha: .6),
      splashFactory: NoSplash.splashFactory,
      fontFamily: StudioTypography.cjk,
      fontFamilyFallback: StudioTypography.fallback,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: IconThemeData(color: muted, size: 20),
      primaryIconTheme: IconThemeData(color: accent, size: 20),
      extensions: [extension(brightness), const StudioFontProfile()],
      appBarTheme: AppBarThemeData(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text(16, FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: raised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: raised,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: popoverRadius,
          side: BorderSide(color: border),
        ),
        titleTextStyle: text(20, FontWeight.w600),
        contentTextStyle: text(14),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: raised,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: raised,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: raised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        labelStyle: text(14).copyWith(color: muted),
        hintStyle: text(14).copyWith(color: muted),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: inputBorder(strongBorder),
        enabledBorder: inputBorder(strongBorder),
        focusedBorder: inputBorder(accent, 1.5),
        disabledBorder: inputBorder(border),
        errorBorder: inputBorder(error),
        focusedErrorBorder: inputBorder(error, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(style: primaryButton),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButton),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          disabledForegroundColor: muted,
          shape: shape,
          textStyle: text(14, FontWeight.w500),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? muted.withValues(alpha: .5)
                : muted,
          ),
          iconSize: const WidgetStatePropertyAll(20),
          shape: const WidgetStatePropertyAll(shape),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: control,
        selectedColor: active,
        secondarySelectedColor: active,
        disabledColor: control,
        surfaceTintColor: Colors.transparent,
        labelStyle: text(13),
        secondaryLabelStyle: text(13),
        checkmarkColor: accent,
        side: BorderSide(color: border),
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? active : raised,
          ),
          foregroundColor: WidgetStatePropertyAll(ink),
          side: WidgetStatePropertyAll(BorderSide(color: border)),
          shape: const WidgetStatePropertyAll(shape),
          textStyle: WidgetStatePropertyAll(text(13, FontWeight.w500)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: raised,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        textStyle: text(13),
        shape: RoundedRectangleBorder(
          borderRadius: popoverRadius,
          side: BorderSide(color: border),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(raised),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: popoverRadius,
              side: BorderSide(color: border),
            ),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(textStyle: text(13)),
      tabBarTheme: TabBarThemeData(
        labelColor: ink,
        unselectedLabelColor: muted,
        indicatorColor: accent,
        dividerColor: border,
        labelStyle: text(13, FontWeight.w700),
        unselectedLabelStyle: text(13, FontWeight.w500),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: ink,
        selectedColor: accent,
        shape: shape,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: panel,
        indicatorColor: active,
        selectedIconTheme: IconThemeData(color: accent, size: 20),
        unselectedIconTheme: IconThemeData(color: muted, size: 20),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: panel,
        surfaceTintColor: Colors.transparent,
        indicatorColor: active,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: blue,
        linearTrackColor: active,
        circularTrackColor: active,
        linearMinHeight: 3,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: active,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: .12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? control
              : states.contains(WidgetState.selected)
              ? blue
              : active,
        ),
        trackOutlineColor: WidgetStatePropertyAll(strongBorder),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? blue : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: muted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(muted.withValues(alpha: .4)),
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(3),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: .25),
        selectionHandleColor: accent,
      ),
    );
  }
}
