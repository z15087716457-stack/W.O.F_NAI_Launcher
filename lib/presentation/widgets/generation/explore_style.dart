import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

abstract final class ExploreStyle {
  static bool _dark(ThemeData t) => t.brightness == Brightness.dark;
  static Color panel(ThemeData t) => Color(_dark(t) ? 0xff161616 : 0xfffafafa);
  static Color raised(ThemeData t) => Color(_dark(t) ? 0xff1b1b1b : 0xffffffff);
  static Color faint(ThemeData t) => Color(_dark(t) ? 0xff7a7a7a : 0xff8f8f8f);
  static Color strong(ThemeData t) => Color(_dark(t) ? 0xff454545 : 0xffc9c9c9);
  static Color heart(ThemeData t) => Color(_dark(t) ? 0xffff6369 : 0xffe5484d);
  static Color ok(ThemeData t) => Color(_dark(t) ? 0xff3dd68c : 0xff2b9a66);
  static Color pink(ThemeData t) => Color(_dark(t) ? 0xfff06595 : 0xffd6336c);
  static Color prompt(ThemeData t) => Color(_dark(t) ? 0xff0c0c0c : 0xffffffff);
  static Color evolutionBg(ThemeData theme) =>
      theme.brightness == Brightness.dark
      ? const Color(0xff1d1830)
      : const Color(0xfff3f0ff);
  static Color evolution(ThemeData theme, {bool highContrast = false}) =>
      highContrast
      ? theme.colorScheme.primary
      : Color(_dark(theme) ? 0xff9e8cfc : 0xff6e56cf);
  static Color evolutionForeground(
    ThemeData theme, {
    bool highContrast = false,
  }) => highContrast
      ? theme.colorScheme.onPrimary
      : theme.brightness == Brightness.dark
      ? const Color(0xff140f2b)
      : Colors.white;
}
