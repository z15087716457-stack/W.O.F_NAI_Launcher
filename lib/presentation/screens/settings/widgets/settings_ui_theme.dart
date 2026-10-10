import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

/// One visual system for settings, including routes opened above the page.
ThemeData settingsUiTheme(ThemeData base) {
  final colors = base.colorScheme;
  TextStyle? text(
    TextStyle? style,
    double size, [
    FontWeight weight = FontWeight.w400,
  ]) => style?.copyWith(fontSize: size, fontWeight: weight, height: 1.4);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: colors.outlineVariant),
  );
  final button = ButtonStyle(
    textStyle: WidgetStatePropertyAll(
      text(base.textTheme.bodyMedium, 12.5, FontWeight.w500),
    ),
    minimumSize: const WidgetStatePropertyAll(Size(0, 34)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    elevation: const WidgetStatePropertyAll(0),
    iconSize: const WidgetStatePropertyAll(16),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    animationDuration: const Duration(milliseconds: 140),
  );
  return base.copyWith(
    scaffoldBackgroundColor: colors.surface,
    // Settings rows keep their existing surface; controls own hover feedback.
    hoverColor: Colors.transparent,
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
      headlineSmall: text(base.textTheme.headlineSmall, 22, FontWeight.w600),
      titleLarge: text(base.textTheme.titleLarge, 18, FontWeight.w600),
    ),
    textButtonTheme: TextButtonThemeData(style: button),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: button.copyWith(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.onSurface.withValues(alpha: .38)
              : colors.onSurface,
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color:
                states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)
                ? colors.primary.withValues(alpha: .5)
                : colors.outlineVariant,
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? colors.onSurface.withValues(alpha: .035)
              : Colors.transparent,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: button),
    elevatedButtonTheme: ElevatedButtonThemeData(style: button),
    iconButtonTheme: IconButtonThemeData(
      style: button.copyWith(
        minimumSize: const WidgetStatePropertyAll(Size(32, 32)),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(7)),
        iconSize: const WidgetStatePropertyAll(17),
        foregroundColor: WidgetStatePropertyAll(colors.onSurfaceVariant),
      ),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      clipBehavior: Clip.antiAlias,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      titleTextStyle: text(
        base.textTheme.titleLarge,
        18,
        FontWeight.w600,
      )?.copyWith(color: colors.onSurface),
      contentTextStyle: text(
        base.textTheme.bodyMedium,
        13,
      )?.copyWith(color: colors.onSurfaceVariant),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      iconColor: colors.onSurfaceVariant,
    ),
    listTileTheme: base.listTileTheme.copyWith(
      titleTextStyle: text(
        base.textTheme.bodyMedium,
        13,
      )?.copyWith(color: colors.onSurface),
      subtitleTextStyle: text(
        base.textTheme.bodySmall,
        11,
      )?.copyWith(color: colors.onSurfaceVariant),
      minLeadingWidth: 24,
      horizontalTitleGap: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selectedColor: colors.primary,
      selectedTileColor: colors.primary.withValues(alpha: .08),
    ),
    dividerTheme: DividerThemeData(
      color: colors.outlineVariant.withValues(alpha: .5),
      thickness: 1,
      space: 1,
    ),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: text(base.textTheme.bodyMedium, 12),
      color: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.primary.withValues(alpha: .10)
            : colors.surface,
      ),
      selectedColor: colors.primary.withValues(alpha: .10),
      backgroundColor: colors.surface,
      checkmarkColor: colors.primary,
      side: BorderSide(color: colors.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    ),
    switchTheme: base.switchTheme.copyWith(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      splashRadius: 0,
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.primary
            : colors.onSurface.withValues(alpha: .22),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: button.copyWith(
        textStyle: WidgetStatePropertyAll(
          text(base.textTheme.bodyMedium, 12.5),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary.withValues(alpha: .10)
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.onSurfaceVariant,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: colors.outlineVariant)),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      hoverColor: Colors.transparent,
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
      labelTextStyle: WidgetStatePropertyAll(
        text(
          base.textTheme.bodyMedium,
          12.5,
        )?.copyWith(color: colors.onSurface),
      ),
      elevation: 5,
    ),
  );
}

/// Open property fields use their arrow instead of a full-width hover wash.
/// Focus and press fall back to the button's normal state feedback.
final settingsFieldOverlay = WidgetStateProperty.resolveWith<Color?>(
  (states) =>
      states.contains(WidgetState.hovered) &&
          !states.contains(WidgetState.pressed)
      ? Colors.transparent
      : null,
);

WidgetStateProperty<Color?> settingsFieldIconColor(ColorScheme colors) =>
    WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? colors.onSurfaceVariant.withValues(alpha: .4)
          : states.contains(WidgetState.focused)
          ? colors.primary
          : states.contains(WidgetState.hovered)
          ? colors.onSurface
          : colors.onSurfaceVariant,
    );
