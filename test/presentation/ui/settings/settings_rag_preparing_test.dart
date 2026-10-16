import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_controls.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets(
    'preparing keeps old counts visible and disables duplicate actions',
    (t) async {
      for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
        for (final dark in [false, true]) {
          for (final width in [900.0, 1280.0]) {
            final base = SettingsFixture.view(page: SettingsPageId.rag);
            final rec = await pumpSettings(
              t,
              locale: locale,
              dark: dark,
              window: width,
              data: base.copyWith(
                values: base.values.copyWith(SettingKey.ragEnabled, true),
                rag: const SettingsRagData(
                  runtimeReady: true,
                  preparing: SettingsRagSourceKind.gallery,
                  sources: [
                    SettingsRagSource(
                      kind: SettingsRagSourceKind.tags,
                      state: SettingsRagState.empty,
                    ),
                    SettingsRagSource(
                      kind: SettingsRagSourceKind.gallery,
                      state: SettingsRagState.paused,
                      done: 19488,
                      total: 48486,
                      secondary: 77920,
                    ),
                  ],
                ),
              ),
            );
            final l = AppLocalizations.of(
              t.element(find.byType(SettingsHost)),
            )!;
            expect(
              find.byKey(const Key('rag-preparing-gallery')),
              findsOneWidget,
            );
            expect(find.text(l.set_rgPreparing), findsOneWidget);
            expect(find.text(l.set_rgPreparingHint), findsOneWidget);
            expect(find.byType(UiSpinner), findsOneWidget);
            expect(
              t
                  .widget<SettingsBtn>(
                    find.byKey(const Key('rag-resume-gallery')),
                  )
                  .onTap,
              isNull,
            );
            expect(
              t
                  .widget<SettingsBtn>(find.byKey(const Key('rag-build-tags')))
                  .onTap,
              isNull,
            );
            expect(find.textContaining('19,488'), findsOneWidget);
            expect(rec.calls, isEmpty);
            expect(t.takeException(), isNull);
          }
        }
      }
    },
  );
}
