import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nai_launcher/presentation/providers/font_provider.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  test('old and withdrawn default keys restore the legacy default', () {
    for (final key in ['', 'system', 'system:', 'bundled:Geist']) {
      expect(FontConfig.fromKey(key), FontConfig.defaultFont);
    }
    expect(FontConfig.defaultFont.fontFamily, 'LXGW ZhenKai GB');
    expect(FontConfig.defaultFont.source, FontSource.system);
  });

  test('explicit system and Google font choices remain usable', () {
    for (final key in ['system:Segoe UI', 'google:Noto Sans SC']) {
      expect(FontConfig.fromKey(key).key, key);
    }
  });

  testWidgets('user font overrides still reach text, chips and tooltips', (
    tester,
  ) async {
    const custom = FontConfig(
      displayName: 'Test system font',
      fontFamily: 'Segoe UI',
      source: FontSource.system,
    );
    for (final brightness in Brightness.values) {
      final theme = AppTheme.getTheme(
        AppStyle.proAi,
        brightness,
        fontConfig: custom,
      );
      expect(theme.textTheme.bodyMedium!.fontFamily, custom.fontFamily);
      expect(theme.primaryTextTheme.bodyMedium!.fontFamily, custom.fontFamily);
      expect(theme.tooltipTheme.textStyle!.fontFamily, custom.fontFamily);
      expect(
        theme.chipTheme.labelStyle?.fontFamily,
        anyOf(isNull, custom.fontFamily),
      );
    }
  });
}
