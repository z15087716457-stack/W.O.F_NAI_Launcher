import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

const _setting = SettingKey.ragContextTokens;
const _sliderKey = Key('slider-ragContextTokens');

Finder _track() => find.descendant(
  of: find.byKey(_sliderKey),
  matching: find.byType(GestureDetector),
);

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets('context slider commits taps and drags only on release', (
    t,
  ) async {
    final rec = await pumpSettings(t, page: SettingsPageId.rag);
    await t.ensureVisible(find.byKey(_sliderKey));
    await t.pumpAndSettle();
    expect(find.text('120 tokens'), findsOneWidget);
    final rect = t.getRect(_track());
    final gesture = await t.startGesture(
      Offset(rect.left + 20, rect.center.dy),
    );
    await t.pump(const Duration(milliseconds: 300));
    expect(rec.changes, isEmpty);
    await gesture.moveBy(const Offset(24, 0));
    await gesture.moveTo(Offset(rect.right + 10, rect.center.dy));
    await t.pump();
    expect(rec.changes, isEmpty);
    expect(find.text('512 tokens'), findsOneWidget);
    await gesture.up();
    await t.pump();
    expect(rec.changes, [(_setting, 512.0)]);
    await t.tapAt(Offset(rect.left, rect.center.dy));
    await t.pump();
    expect(rec.changes.last, (_setting, 32.0));
    expect(t.takeException(), isNull);
  });

  testWidgets('modified context length keeps the existing reset action', (
    t,
  ) async {
    final base = SettingsFixture.view(page: SettingsPageId.rag);
    final rec = await pumpSettings(
      t,
      data: base.copyWith(
        values: base.values.copyWith(_setting, 256.0),
        modified: {_setting},
      ),
    );
    final row = find.byKey(const Key('setting-ragContextTokens'));
    await t.ensureVisible(row);
    await t.pumpAndSettle();
    final reset = find.descendant(
      of: row,
      matching: find.byType(SettingsIconBtn),
    );
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(t.getCenter(row));
    await t.pumpAndSettle();
    await t.tap(reset);
    await t.pump();
    await mouse.removePointer();
    expect(rec.has('reset:ragContextTokens'), isTrue);
    expect(t.takeException(), isNull);
  });

  testWidgets('context length is adjustable from settings search', (t) async {
    final rec = await pumpSettings(t, initialQuery: 'Gemma tokens');
    expect(find.byKey(_sliderKey), findsOneWidget);
    expect(find.text('120 tokens'), findsWidgets);
    final rect = t.getRect(_track());
    await t.tapAt(Offset(rect.right - .01, rect.center.dy));
    await t.pump();
    expect(rec.changes.last, (_setting, 512.0));
    expect(t.takeException(), isNull);
  });

  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets('context length layout $locale dark=$dark', (t) async {
        for (final window in [900.0, 1600.0]) {
          await pumpSettings(
            t,
            page: SettingsPageId.rag,
            locale: locale,
            dark: dark,
            window: window,
          );
          await t.ensureVisible(find.byKey(_sliderKey));
          await t.pumpAndSettle();
          final l = AppLocalizations.of(t.element(find.byType(SettingsHost)))!;
          expect(find.text(l.set_rgRange), findsOneWidget);
          final slider = t.widget<SettingsSlider>(find.byKey(_sliderKey));
          expect(
            (slider.min, slider.max, slider.value, slider.step),
            (32, 512, 120, 1),
          );
          expect(t.takeException(), isNull);
        }
      });
    }
  }
}
