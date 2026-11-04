import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/widgets/navigation/workspace_navigation.dart';

import 'settings_test_harness.dart';

void main() {
  const desktop = TargetPlatformVariant({
    TargetPlatform.macOS,
    TargetPlatform.windows,
  });

  Future<SettingsRecorder> open(WidgetTester t, SettingsPageId page) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1400, 960);
    addTearDown(t.view.reset);
    final rec = SettingsRecorder();
    final departure = SettingsDeparture();
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: WorkspaceNavigation(
            select: (_) {},
            closeSettings: () => departure.leave(() => rec.calls.add('close')),
            settingsDeparture: departure,
            child: SettingsHost(
              data: SettingsFixture.view(page: page),
              rec: rec,
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    return rec;
  }

  testWidgets(
    'settings Escape commits the field on blur and keeps the page open',
    (t) async {
      final rec = await open(t, SettingsPageId.network);
      final host = find.descendant(
        of: find.byKey(const Key('input-proxyHost')),
        matching: find.byType(TextField),
      );
      await t.ensureVisible(host);
      await t.enterText(host, 'proxy.example.invalid');
      expect(rec.changes, isEmpty);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(rec.calls, isNot(contains('close')));
      expect(
        rec.changes,
        contains((SettingKey.proxyHost, 'proxy.example.invalid')),
      );
    },
    variant: desktop,
  );

  testWidgets(
    'settings Escape dismisses an open dropdown before the workspace',
    (t) async {
      final rec = await open(t, SettingsPageId.appearance);
      final dropdown = find.byKey(const Key('select-fontFamily'));
      await t.ensureVisible(dropdown);
      await t.tap(dropdown);
      await t.pumpAndSettle();
      final options = find.byWidgetPredicate(
        (w) => w.key.toString().contains('settings-option-'),
      );
      expect(options, findsWidgets);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(options, findsNothing);
      expect(rec.calls, isNot(contains('close')));
    },
    variant: desktop,
  );

  testWidgets('settings Escape in an empty Windows search stays on the page', (
    t,
  ) async {
    final rec = await open(t, SettingsPageId.network);
    await t.tap(find.byKey(const Key('settings-search-input')));
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pump();
    expect(rec.calls, isNot(contains('close')));
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
