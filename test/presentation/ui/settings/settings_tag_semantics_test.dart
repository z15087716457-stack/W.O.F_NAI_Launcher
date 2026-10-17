import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets(
    'semantic supplements stay separate from cache clearing in every settings locale',
    (t) async {
      for (final language in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
        for (final dark in [false, true]) {
          for (final width in [900.0, 1280.0]) {
            final rec = await pumpSettings(
              t,
              page: SettingsPageId.dictionaries,
              locale: language,
              dark: dark,
              window: width,
              height: 1100,
            );
            final l = AppLocalizations.of(
              t.element(find.byType(SettingsHost)),
            )!;
            expect(find.text(l.set_dcTranslate), findsOneWidget);
            expect(find.text(l.set_dcSemantics), findsOneWidget);
            await t.ensureVisible(find.text(l.set_importIt));
            await t.tap(find.text(l.set_importIt));
            await t.ensureVisible(find.text(l.set_exportIt));
            await t.tap(find.text(l.set_exportIt));
            expect(rec.calls, ['importTagSemantics', 'exportTagSemantics']);
            expect(t.takeException(), isNull);
            final output = Platform.environment['TAG_SEMANTICS_CAPTURE'];
            if (output != null && language == 'zh' && width == 1280) {
              final box = t.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('settings-capture')),
              );
              await t.runAsync(() async {
                final bitmap = await box.toImage(pixelRatio: 1);
                try {
                  final data = await bitmap.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  await Directory(output).create(recursive: true);
                  await File(
                    '$output/settings-${dark ? 'dark' : 'light'}.png',
                  ).writeAsBytes(data!.buffer.asUint8List());
                } finally {
                  bitmap.dispose();
                }
              });
            }
          }
        }
      }
    },
  );
}
