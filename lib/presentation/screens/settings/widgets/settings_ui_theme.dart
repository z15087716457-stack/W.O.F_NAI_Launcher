import 'package:flutter/material.dart';

/// Settings form values and popup menus share the same quiet type scale.
ThemeData settingsUiTheme(ThemeData base) {
  final colors = base.colorScheme;
  TextStyle? text(
    TextStyle? style,
    double size, [
    FontWeight weight = FontWeight.w400,
  ]) => style?.copyWith(fontSize: size, fontWeight: weight, height: 1.4);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(7),
    borderSide: BorderSide(color: colors.outlineVariant),
  );
  return base.copyWith(
    scaffoldBackgroundColor: colors.surface,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textTheme: base.textTheme.copyWith(
      bodyLarge: text(base.textTheme.bodyLarge, 13),
      bodyMedium: text(base.textTheme.bodyMedium, 13),
      bodySmall: text(base.textTheme.bodySmall, 11),
      titleMedium: text(base.textTheme.titleMedium, 13),
      titleSmall: text(base.textTheme.titleSmall, 13, FontWeight.w500),
      labelLarge: text(base.textTheme.labelLarge, 12, FontWeight.w500),
      labelMedium: text(base.textTheme.labelMedium, 12),
      labelSmall: text(base.textTheme.labelSmall, 11),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      border: border,
      enabledBorder: border,
      disabledBorder: border.copyWith(
        borderSide: BorderSide(
          color: colors.outlineVariant.withValues(alpha: .6),
        ),
      ),
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: colors.primary, width: 1.2),
      ),
      labelStyle: text(base.textTheme.bodySmall, 11),
      hintStyle: text(base.textTheme.bodyMedium, 12),
      helperStyle: text(base.textTheme.bodySmall, 11),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: text(base.textTheme.bodyMedium, 13),
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      textStyle: text(base.textTheme.bodyMedium, 12),
      color: colors.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.outlineVariant),
      ),
      elevation: 6,
    ),
  );
}

String settingsText(BuildContext context, String zh, String en, String ja) =>
    switch (Localizations.localeOf(context).languageCode) {
      'zh' => zh,
      'ja' => ja,
      _ => en,
    };
