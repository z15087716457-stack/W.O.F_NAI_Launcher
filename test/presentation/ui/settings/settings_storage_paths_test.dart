import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets(
    'storage shows resolved defaults, actual generated output and a wired PR folder',
    (t) async {
      final rec = await pumpSettings(
        t,
        page: SettingsPageId.storage,
        dark: true,
      );
      final keys = [
        SettingKey.imageSavePath,
        SettingKey.vibePath,
        SettingKey.preciseRefPath,
      ];
      final rects = <String, List<double>>{};
      for (final key in keys) {
        final box = find.byKey(Key('path-${key.name}'));
        await t.ensureVisible(box);
        await t.pumpAndSettle();
        final rect = t.getRect(box);
        rects[key.name] = [rect.left, rect.top, rect.width, rect.height];
        expect(rect.width, 380);
      }
      expect(find.text('生成图片保存目录'), findsOneWidget);
      expect(find.textContaining(r'outputs\Uncategorized'), findsOneWidget);
      expect(find.text(r'E:\NAI Studio\user-data\vibes'), findsOneWidget);
      expect(
        find.text(r'E:\NAI Studio\user-data\precise_refs'),
        findsOneWidget,
      );
      expect(find.text(r'Documents\NAI_Launcher\vibes'), findsNothing);
      final row = find.byKey(const Key('setting-preciseRefPath'));
      for (final (glyph, call) in [
        (SettingsGlyphs.folder, 'pickPath:preciseRefPath'),
        (SettingsGlyphs.external, 'openPath:preciseRefPath'),
      ]) {
        final button = find.descendant(
          of: row,
          matching: find.byWidgetPredicate(
            (w) => w is SettingsIconBtn && w.glyph == glyph,
          ),
        );
        await t.tap(button);
        await t.pumpAndSettle();
        expect(rec.calls.last, call);
      }
      final aside = find.byKey(const Key('open-folder-preciseRefs'));
      await t.ensureVisible(aside);
      await t.tap(aside);
      await t.pumpAndSettle();
      expect(rec.calls.last, 'openFolder:preciseRefs');
      expect(find.byKey(const Key('settings-unsaved-dot')), findsNothing);
      final directory = Platform.environment['UIUX_FRONTEND_CAPTURE_DIR'];
      if (directory != null) {
        await t.runAsync(() async {
          final file = File('$directory/path-metrics.json');
          await file.parent.create(recursive: true);
          await file.writeAsString(jsonEncode(rects));
        });
      }
      await Scrollable.ensureVisible(
        t.element(find.byKey(const Key('setting-imageSavePath'))),
        alignment: .2,
      );
      await t.pumpAndSettle();
      await captureUiuxRegion(
        t,
        find.byKey(const Key('settings-capture')),
        'storage-paths-dark',
        Offset.zero & t.getSize(find.byKey(const Key('settings-capture'))),
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('custom PR directory retains the existing reset action', (
    t,
  ) async {
    final base = SettingsFixture.view(page: SettingsPageId.storage);
    final rec = await pumpSettings(
      t,
      data: base.copyWith(
        values: base.values.copyWith(
          SettingKey.preciseRefPath,
          r'D:\custom\pr',
        ),
        modified: {SettingKey.preciseRefPath},
      ),
    );
    final row = find.byKey(const Key('setting-preciseRefPath'));
    await t.ensureVisible(row);
    await t.pumpAndSettle();
    final mouse = await t.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(t.getCenter(row));
    await t.pumpAndSettle();
    final reset = find.descendant(
      of: row,
      matching: find.byWidgetPredicate(
        (w) => w is SettingsIconBtn && w.glyph == SettingsGlyphs.undo,
      ),
    );
    await t.tap(reset);
    await t.pumpAndSettle();
    await mouse.removePointer();
    expect(rec.calls.last, 'reset:preciseRefPath');
    expect(find.byKey(const Key('settings-unsaved-dot')), findsNothing);
  });

  for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
    for (final dark in [true, false]) {
      testWidgets('resolved paths fit $locale dark=$dark at 150%', (t) async {
        await pumpSettings(
          t,
          page: SettingsPageId.storage,
          locale: locale,
          dark: dark,
          window: 900,
          uiScale: 1.5,
        );
        await Scrollable.ensureVisible(
          t.element(find.byKey(const Key('setting-vibePath'))),
          alignment: .2,
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        if (locale == 'zh' && !dark) {
          await captureUiuxRegion(
            t,
            find.byKey(const Key('settings-capture')),
            'storage-paths-narrow',
            Offset.zero & t.getSize(find.byKey(const Key('settings-capture'))),
          );
        }
      });
    }
  }

  testWidgets('PR directory can be found from settings search', (t) async {
    final rec = await pumpSettings(t, initialQuery: 'PR precise reference');
    expect(find.byKey(const Key('jump-preciseRefPath')), findsOneWidget);
    await t.tap(find.byKey(const Key('jump-preciseRefPath')));
    await t.pumpAndSettle();
    expect(rec.pages.last, SettingsPageId.storage);
    expect(find.byKey(const Key('setting-preciseRefPath')), findsOneWidget);
  });
}
