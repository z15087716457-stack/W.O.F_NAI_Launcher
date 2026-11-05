import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';

import 'settings_test_harness.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('system theme quick toggle follows effective dark=$dark', (
      t,
    ) async {
      final rec = await pumpSettings(
        t,
        dark: dark,
        data: SettingsFixture.view().copyWith(
          values: const SettingsValues({SettingKey.themeMode: 'system'}),
        ),
      );
      final toggle = find.byKey(const Key('quick-dark'));
      expect(t.widget<SettingsSwitch>(toggle).value, dark);
      await t.ensureVisible(toggle);
      await t.tap(toggle);
      await t.pumpAndSettle();
      expect(rec.changes.single, (
        SettingKey.themeMode,
        dark ? 'light' : 'dark',
      ));
      await t.pump(const Duration(seconds: 5));
    });
  }
}
