import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' as harness;
import 'package:nai_launcher/core/utils/app_language.dart';
import '../../../helpers/chinese_script_test_support.dart';

/// Provider and model names in the sample configuration are user data.
const _fixtureNames = {'本地模型'};

List<String> _visibleHanText(WidgetTester tester) {
  final han = RegExp(r'[\u4e00-\u9fff]');
  return [
    for (final element in find.byType(RichText).evaluate())
      if ((element.widget as RichText).text.toPlainText() case final text
          when han.hasMatch(text) && !_fixtureNames.contains(text))
        text,
  ];
}

void main() {
  setUpAll(() async {
    await ModelCatalogRepository.load();
    // Real fonts keep the translated layout checks representative.
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final code in ['en', 'ja', 'zh_TW']) {
    for (final layout in [
      (const Size(1200, 820), 1.1, 'regular'),
      (const Size(960, 820), 1.3, 'compact'),
      (const Size(640, 900), 1.3, 'narrow'),
    ]) {
      testWidgets(
        'model settings stay localized and laid out in $code ${layout.$3}',
        (tester) async {
          final locale = AppLanguage.fromStorage(code).locale;
          final l10n = lookupAppLocalizations(locale);
          // The app keeps context-free text on the same locale.
          setCurrentL10nLocale(locale);
          addTearDown(() => setCurrentL10nLocale(const Locale('zh')));
          await harness.pumpManagement(
            tester,
            size: layout.$1,
            scale: layout.$2,
            locale: locale,
          );
          final tabs = [
            l10n.modelSettings_tabProviders,
            l10n.modelSettings_tabInterfaces,
            l10n.modelSettings_tabPresets,
            l10n.modelSettings_tabRequests,
          ];
          for (final (index, tab) in tabs.indexed) {
            await harness.tapVisible(tester, find.text(tab).first);
            expect(tester.takeException(), isNull, reason: tab);
            if (code == 'en') {
              expect(_visibleHanText(tester), isEmpty, reason: tab);
            }
            if (code == 'zh_TW') {
              expect(
                simplifiedOnlyTexts(_visibleHanText(tester)),
                isEmpty,
                reason: tab,
              );
            }
            await harness.capture(tester, 'l10n-$code-${layout.$3}-tab$index');
          }
          await harness.tapVisible(
            tester,
            find.text(l10n.modelSettings_tabProviders).first,
          );
          await harness.tapVisible(
            tester,
            find.byKey(const Key('service-add')),
          );
          expect(find.text(l10n.modelProvider_pickerTitle), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (code == 'en') expect(_visibleHanText(tester), isEmpty);
          if (code == 'zh_TW') {
            expect(simplifiedOnlyTexts(_visibleHanText(tester)), isEmpty);
          }
          await harness.capture(tester, 'l10n-$code-${layout.$3}-picker');
        },
      );
    }
  }
}
