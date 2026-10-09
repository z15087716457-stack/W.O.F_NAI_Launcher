import 'package:flutter/material.dart';
import '../../../widgets/prompt/pills/dna_icon.dart';

abstract final class ExploreStyle {
  static Color evolution(ThemeData theme, {bool highContrast = false}) =>
      highContrast
      ? theme.colorScheme.primary
      : DnaIcon.prototypeColor(theme.brightness);
  static Color evolutionForeground(
    ThemeData theme, {
    bool highContrast = false,
  }) => highContrast
      ? theme.colorScheme.onPrimary
      : theme.brightness == Brightness.dark
      ? const Color(0xff140f2b)
      : Colors.white;
}
