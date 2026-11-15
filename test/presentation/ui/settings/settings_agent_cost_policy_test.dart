import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_controls.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets(
    'paid confirmation defaults off and the existing switch persists the change',
    (t) async {
      final rec = await pumpSettings(t, page: SettingsPageId.agent, dark: true);
      final row = find.byKey(const Key('setting-agentSkipPaidConfirmation'));
      await Scrollable.ensureVisible(t.element(row), alignment: .35);
      await t.pumpAndSettle();
      expect(find.text('付费也无需确认'), findsOneWidget);
      expect(find.textContaining('仅完全权限生效'), findsOneWidget);
      expect(find.byKey(const Key('settings-unsaved-dot')), findsNothing);
      final toggle = find.descendant(of: row, matching: find.byType(SetSwitch));
      final directory = Platform.environment['UIUX_FRONTEND_CAPTURE_DIR'];
      if (directory != null) {
        final metric = <String, List<double>>{};
        for (final name in [
          'agentMaxRequests',
          'agentSkipPaidConfirmation',
          'agentNextSuggestion',
        ]) {
          final r = t.getRect(find.byKey(Key('setting-$name')));
          metric[name] = [r.left, r.top, r.width, r.height];
        }
        await t.runAsync(() async {
          final file = File('$directory/settings-cost-policy.json');
          await file.parent.create(recursive: true);
          await file.writeAsString(jsonEncode(metric));
        });
      }
      await captureUiuxRegion(
        t,
        find.byKey(const Key('settings-capture')),
        'settings-cost-policy-dark',
        Offset.zero & t.getSize(find.byKey(const Key('settings-capture'))),
      );
      await t.tap(toggle);
      await t.pumpAndSettle();
      expect(rec.changes.last, (SettingKey.agentSkipPaidConfirmation, true));
      await t.tap(toggle);
      await t.pumpAndSettle();
      expect(rec.changes.last, (SettingKey.agentSkipPaidConfirmation, false));
      expect(t.takeException(), isNull);
    },
  );

  for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
    for (final dark in [false, true]) {
      testWidgets('cost policy fits $locale dark=$dark at 150%', (t) async {
        await pumpSettings(
          t,
          page: SettingsPageId.agent,
          locale: locale,
          dark: dark,
          window: 900,
          uiScale: 1.5,
        );
        final row = find.byKey(const Key('setting-agentSkipPaidConfirmation'));
        await Scrollable.ensureVisible(t.element(row), alignment: .35);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        if (locale == 'zh' && !dark) {
          await captureUiuxRegion(
            t,
            find.byKey(const Key('settings-capture')),
            'settings-cost-policy-narrow',
            Offset.zero & t.getSize(find.byKey(const Key('settings-capture'))),
          );
        }
      });
    }
  }

  testWidgets('paid-confirmation search jumps to General from Instructions', (
    t,
  ) async {
    await pumpSettings(t, page: SettingsPageId.agent, agentTab: 'instructions');
    await t.enterText(find.byKey(const Key('settings-search-input')), '付费');
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('jump-agentSkipPaidConfirmation')));
    await t.pumpAndSettle();
    expect(
      find.byKey(const Key('setting-agentSkipPaidConfirmation')),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
  });
}
