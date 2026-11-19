import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_search.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets(
    'runtime timeout offers a retry and has the same status in search',
    (t) async {
      final base = SettingsFixture.view(page: SettingsPageId.rag);
      final recorder = await pumpSettings(
        t,
        data: base.copyWith(
          values: base.values.copyWith(SettingKey.ragEnabled, true),
          rag: const SettingsRagData(
            runtimeIssue: SettingsRagRuntimeIssue.timedOut,
          ),
        ),
      );
      final row = find.byKey(const Key('rag-runtime'));
      await t.ensureVisible(row);
      await t.pumpAndSettle();
      final l = AppLocalizations.of(t.element(row))!;
      expect(
        find.descendant(of: row, matching: find.text(l.set_rgEnvCheckFailed)),
        findsOneWidget,
      );
      expect(find.text(l.set_rgNotReadySub), findsNothing);
      expect(find.byKey(const Key('rag-install')), findsNothing);
      await t.tap(find.byKey(const Key('rag-check')));
      expect(recorder.calls, contains('ragCheckRuntime'));
      await t.enterText(
        find.byKey(const Key('settings-search-input')),
        l.set_rgEnv,
      );
      await t.pumpAndSettle();
      final result = find.byKey(const Key('hit-rag-runtime'));
      expect(
        find.descendant(
          of: result,
          matching: find.text(l.set_rgEnvCheckFailed),
        ),
        findsOneWidget,
      );
      expect(find.byType(SettingsSearchResults), findsOneWidget);
    },
  );

  testWidgets(
    'checking an environment never labels it missing or asks for installation',
    (t) async {
      for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
        for (final ready in [false, true]) {
          await t.pumpWidget(const SizedBox.shrink());
          final base = SettingsFixture.view(page: SettingsPageId.rag);
          await pumpSettings(
            t,
            locale: locale,
            window: 1280,
            data: base.copyWith(
              values: base.values.copyWith(SettingKey.ragEnabled, true),
              rag: SettingsRagData(
                checking: true,
                runtimeReady: ready,
                runtime: const SettingsRagStep(value: 'fixture-python.exe'),
              ),
            ),
          );
          final l = AppLocalizations.of(t.element(find.byType(SettingsHost)))!;
          expect(find.text(l.set_rgNotReady), findsNothing);
          expect(find.text(l.set_rgNotReadySub), findsNothing);
          final environment = find.byKey(const Key('rag-runtime'));
          expect(
            find.descendant(
              of: environment,
              matching: find.text(l.set_rgEnvMissing),
            ),
            findsNothing,
          );
          expect(
            find.descendant(
              of: environment,
              matching: find.text(l.set_rgInstall),
            ),
            findsNothing,
          );
          expect(find.text(l.set_testing), findsWidgets);
          expect(t.takeException(), isNull);
        }
      }
    },
  );
}
