import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

SettingsViewData _view(
  SettingsDictionaryPhase phase, {
  bool cancelling = false,
}) => SettingsFixture.view(page: SettingsPageId.dictionaries).copyWith(
  dictionaries: SettingsDictionaryData(
    tagCount: 221787,
    wikiCount: 141802,
    dataVersion: 'private-version-hash',
    cooccurrence: 3236959,
    update: SettingsDictionaryUpdate(
      phase: phase,
      kind: SettingsDictionaryKind.tags,
      total: 5602650,
      received: 2800000,
      rows: 1000,
      added: 84028,
      tagDate: '2026-10-01',
      wikiDate: '2026-06-01',
      tagSource: 'DraconicDragon / Danbooru',
      wikiSource: 'patvessel / Danbooru Wiki',
      cancelling: cancelling,
    ),
  ),
);

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets(
    'base counts replace the hash and supplementary actions sit directly below',
    (t) async {
      final rec = await pumpSettings(
        t,
        data: _view(SettingsDictionaryPhase.idle),
      );
      final l = AppLocalizations.of(t.element(find.byType(SettingsHost)))!;
      expect(
        find.text(l.set_dcBaseValue('221,787', '141,802')),
        findsOneWidget,
      );
      expect(find.textContaining('private-version-hash'), findsNothing);
      final base = t.getRect(find.byKey(const Key('dictionary-base-row')));
      final update = t.getRect(
        find.byKey(const Key('dictionary-supplement-row')),
      );
      expect(update.top, greaterThanOrEqualTo(base.bottom));
      await t.tap(find.byKey(const Key('dictionary-update-tags')));
      await t.tap(find.byKey(const Key('dictionary-update-wiki')));
      expect(rec.calls, ['updateDictionary:tags', 'updateDictionary:wiki']);
    },
  );
  testWidgets(
    'an active job disables both downloads and exposes a single cancel action',
    (t) async {
      final rec = await pumpSettings(
        t,
        data: _view(SettingsDictionaryPhase.downloading),
      );
      for (final key in ['dictionary-update-tags', 'dictionary-update-wiki']) {
        expect(t.widget<SettingsBtn>(find.byKey(Key(key))).onTap, isNull);
      }
      await t.tap(find.byKey(const Key('dictionary-update-cancel')));
      expect(rec.calls, ['cancelDictionaryUpdate']);
      t
          .state<SettingsHostState>(find.byType(SettingsHost))
          .updateData(
            _view(SettingsDictionaryPhase.downloading, cancelling: true),
          );
      await t.pumpAndSettle();
      expect(
        t
            .widget<SettingsBtn>(
              find.byKey(const Key('dictionary-update-cancel')),
            )
            .onTap,
        isNull,
      );
    },
  );
  testWidgets(
    'counts and the update row fit five languages, narrow windows and large text',
    (t) async {
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
        for (final (width, scale) in [
          (1600.0, 1.0),
          (900.0, 1.0),
          (1600.0, 1.5),
        ]) {
          for (final phase in [
            SettingsDictionaryPhase.idle,
            SettingsDictionaryPhase.downloading,
            SettingsDictionaryPhase.importing,
            SettingsDictionaryPhase.done,
            SettingsDictionaryPhase.failed,
          ]) {
            await t.pumpWidget(const SizedBox.shrink());
            t.platformDispatcher.textScaleFactorTestValue = scale;
            await pumpSettings(
              t,
              data: _view(phase),
              window: width,
              height: 1392,
              locale: locale,
              dark: width == 900,
            );
            expect(
              t.takeException(),
              isNull,
              reason: '$locale $width $scale $phase',
            );
            if (phase == SettingsDictionaryPhase.idle && scale == 1) {
              await _capture(t, '$locale-${width.toInt()}');
            }
          }
        }
      }
    },
  );
}

Future<void> _capture(WidgetTester t, String name) async {
  final output = Platform.environment['DICTIONARY_UPDATE_CAPTURE_DIR'];
  if (output == null) return;
  final boundary = t.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('settings-capture')),
  );
  await t.runAsync(() async {
    final bitmap = await boundary.toImage(pixelRatio: 1);
    final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
    Directory(output).createSync(recursive: true);
    File('$output/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    bitmap.dispose();
  });
}
