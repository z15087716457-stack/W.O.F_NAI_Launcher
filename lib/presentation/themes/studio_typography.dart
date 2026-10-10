import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import 'core/theme_modules.dart';

/// Records whether the application uses prototype font roles or an explicit
/// user override. Nested gallery/viewer scopes must preserve that choice.
class StudioFontProfile extends ThemeExtension<StudioFontProfile> {
  const StudioFontProfile({this.usePrototypeFamilies = true});
  final bool usePrototypeFamilies;

  @override
  StudioFontProfile copyWith({bool? usePrototypeFamilies}) => StudioFontProfile(
    usePrototypeFamilies: usePrototypeFamilies ?? this.usePrototypeFamilies,
  );

  @override
  StudioFontProfile lerp(StudioFontProfile? other, double t) =>
      t < .5 ? this : other ?? this;
}

/// Bundled, offline typography. Roles remain stable across color themes.
abstract final class StudioTypography {
  static const sans = 'Geist';
  static const mono = 'Geist Mono';
  static const pixel = 'Geist Pixel Line';
  static const pixelSquare = 'Geist Pixel Square';
  static const pixelCircle = 'Geist Pixel Circle';
  static const cjk = 'HarmonyOS Sans SC';
  static const korean = 'Pretendard';
  static const fallback = [cjk, korean];

  // mock.html: body { font: 13px/1.45 HOS,sans-serif }. CSS uses
  // half-leading, unlike Flutter's default proportional distribution.
  static const body = TextStyle(
    fontFamily: cjk,
    fontFamilyFallback: fallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
    height: 1.45,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 0,
    wordSpacing: 0,
  );

  static const data = TextStyle(
    fontFamily: mono,
    fontFamilyFallback: fallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 0,
    wordSpacing: 0,
  );

  static TextTheme textTheme(Color ink) {
    TextStyle text(double size, [FontWeight weight = FontWeight.w400]) =>
        body.copyWith(color: ink, fontSize: size, fontWeight: weight);
    return TextTheme(
      displayLarge: text(48, FontWeight.w700),
      displayMedium: text(36, FontWeight.w700),
      displaySmall: text(30, FontWeight.w700),
      headlineLarge: text(28, FontWeight.w700),
      headlineMedium: text(24, FontWeight.w700),
      headlineSmall: text(22, FontWeight.w700),
      titleLarge: text(20, FontWeight.w700),
      titleMedium: text(15, FontWeight.w700),
      titleSmall: text(14, FontWeight.w600),
      bodyLarge: text(14),
      bodyMedium: text(13),
      bodySmall: text(12),
      labelLarge: text(13),
      labelMedium: text(12.5),
      labelSmall: text(11),
    );
  }

  /// A font choice must also reach component themes with explicit text styles.
  /// TextTheme.apply alone leaves buttons, menus, tabs and inputs on old fonts.
  static ThemeData applyFamily(
    ThemeData theme,
    String family, {
    List<String> familyFallback = fallback,
    double? height,
  }) {
    TextStyle? style(TextStyle? value) => value?.copyWith(
      fontFamily: family,
      fontFamilyFallback: familyFallback,
      height: height,
    );
    TextTheme texts(TextTheme value) => TextTheme(
      displayLarge: style(value.displayLarge),
      displayMedium: style(value.displayMedium),
      displaySmall: style(value.displaySmall),
      headlineLarge: style(value.headlineLarge),
      headlineMedium: style(value.headlineMedium),
      headlineSmall: style(value.headlineSmall),
      titleLarge: style(value.titleLarge),
      titleMedium: style(value.titleMedium),
      titleSmall: style(value.titleSmall),
      bodyLarge: style(value.bodyLarge),
      bodyMedium: style(value.bodyMedium),
      bodySmall: style(value.bodySmall),
      labelLarge: style(value.labelLarge),
      labelMedium: style(value.labelMedium),
      labelSmall: style(value.labelSmall),
    );
    ButtonStyle? button(ButtonStyle? value) => value?.copyWith(
      textStyle: value.textStyle == null
          ? null
          : WidgetStateProperty.resolveWith(
              (states) => style(value.textStyle!.resolve(states)),
            ),
    );
    return theme.copyWith(
      textTheme: texts(theme.textTheme),
      primaryTextTheme: texts(theme.primaryTextTheme),
      filledButtonTheme: FilledButtonThemeData(
        style: button(theme.filledButtonTheme.style),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: button(theme.elevatedButtonTheme.style),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: button(theme.outlinedButtonTheme.style),
      ),
      textButtonTheme: TextButtonThemeData(
        style: button(theme.textButtonTheme.style),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: button(theme.segmentedButtonTheme.style),
      ),
      chipTheme: theme.chipTheme.copyWith(
        labelStyle: style(theme.chipTheme.labelStyle),
        secondaryLabelStyle: style(theme.chipTheme.secondaryLabelStyle),
      ),
      tabBarTheme: theme.tabBarTheme.copyWith(
        labelStyle: style(theme.tabBarTheme.labelStyle),
        unselectedLabelStyle: style(theme.tabBarTheme.unselectedLabelStyle),
      ),
      popupMenuTheme: theme.popupMenuTheme.copyWith(
        textStyle: style(theme.popupMenuTheme.textStyle),
        labelTextStyle: theme.popupMenuTheme.labelTextStyle == null
            ? null
            : WidgetStateProperty.resolveWith(
                (states) =>
                    style(theme.popupMenuTheme.labelTextStyle!.resolve(states)),
              ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: button(theme.menuButtonTheme.style),
      ),
      dropdownMenuTheme: theme.dropdownMenuTheme.copyWith(
        textStyle: style(theme.dropdownMenuTheme.textStyle),
      ),
      tooltipTheme: theme.tooltipTheme.copyWith(
        textStyle: style(theme.tooltipTheme.textStyle),
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        labelStyle: style(theme.inputDecorationTheme.labelStyle),
        floatingLabelStyle: style(
          theme.inputDecorationTheme.floatingLabelStyle,
        ),
        hintStyle: style(theme.inputDecorationTheme.hintStyle),
        helperStyle: style(theme.inputDecorationTheme.helperStyle),
        errorStyle: style(theme.inputDecorationTheme.errorStyle),
        prefixStyle: style(theme.inputDecorationTheme.prefixStyle),
        suffixStyle: style(theme.inputDecorationTheme.suffixStyle),
        counterStyle: style(theme.inputDecorationTheme.counterStyle),
      ),
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: style(theme.appBarTheme.titleTextStyle),
        toolbarTextStyle: style(theme.appBarTheme.toolbarTextStyle),
      ),
      listTileTheme: theme.listTileTheme.copyWith(
        titleTextStyle: style(theme.listTileTheme.titleTextStyle),
        subtitleTextStyle: style(theme.listTileTheme.subtitleTextStyle),
        leadingAndTrailingTextStyle: style(
          theme.listTileTheme.leadingAndTrailingTextStyle,
        ),
      ),
      dialogTheme: theme.dialogTheme.copyWith(
        titleTextStyle: style(theme.dialogTheme.titleTextStyle),
        contentTextStyle: style(theme.dialogTheme.contentTextStyle),
      ),
      snackBarTheme: theme.snackBarTheme.copyWith(
        contentTextStyle: style(theme.snackBarTheme.contentTextStyle),
      ),
    );
  }

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
  String get displayFontFamily => StudioTypography.cjk;

  @override
  String get bodyFontFamily => StudioTypography.cjk;

  @override
  TextTheme get textTheme => StudioTypography.textTheme(Colors.black);
}
