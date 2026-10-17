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
    'installed versions keep Check updates available and checks never trigger downloads',
    (t) async {
      final data = _view(SettingsDictionaryPhase.idle).copyWith(
        dictionaries: const SettingsDictionaryData(
          update: SettingsDictionaryUpdate(
            tagInstalled: true,
            wikiInstalled: true,
            tagDate: '2026-10-01',
            wikiDate: '2026-06-01',
          ),
        ),
      );
      final rec = await pumpSettings(t, data: data);
      for (final key in ['dictionary-update-tags', 'dictionary-update-wiki']) {
        expect(t.widget<SettingsBtn>(find.byKey(Key(key))).onTap, isNull);
      }
      await t.tap(find.byKey(const Key('dictionary-check-updates')));
      expect(rec.calls, ['checkDictionaryUpdates']);
    },
  );
  testWidgets(
    'checking, checked, failed and legacy refresh states fit every locale',
    (t) async {
      final checked = DateTime(2026, 10, 17, 13, 40);
      final states = {
        'checking': const SettingsDictionaryUpdate(
          tagDate: '2026-10-01',
          wikiDate: '2026-06-01',
          checking: true,
          tagInstalled: true,
          wikiInstalled: true,
        ),
        'latest': SettingsDictionaryUpdate(
          tagDate: '2026-10-01',
          wikiDate: '2026-06-01',
          checkedAt: checked,
          tagInstalled: true,
          wikiInstalled: true,
        ),
        'available': SettingsDictionaryUpdate(
          tagDate: '2026-10-01',
          wikiDate: '2026-06-01',
          checkedAt: checked,
          tagInstalled: false,
          wikiInstalled: true,
        ),
        'failed': SettingsDictionaryUpdate(
          tagDate: '2026-10-01',
          wikiDate: '2026-06-01',
          checkedAt: checked,
          checkFailed: true,
          tagInstalled: true,
          wikiInstalled: true,
        ),
        'refresh': SettingsDictionaryUpdate(
          tagDate: '2026-10-01',
          wikiDate: '2026-06-01',
          checkedAt: checked,
          tagInstalled: true,
          wikiInstalled: true,
          wikiNeedsRefresh: true,
        ),
      };
      for (final language in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
        for (final dark in [false, true]) {
          for (final width in [900.0, 1280.0]) {
            for (final entry in states.entries) {
              await t.pumpWidget(const SizedBox.shrink());
              final data = _view(SettingsDictionaryPhase.idle).copyWith(
                dictionaries: SettingsDictionaryData(
                  tagCount: 305815,
                  wikiCount: 288187,
                  cooccurrence: 3236959,
                  translationModel: 'fixture-model',
                  update: entry.value,
                ),
              );
              await pumpSettings(
                t,
                data: data,
                locale: language,
                dark: dark,
                window: width,
                height: 1200,
              );
              final l = AppLocalizations.of(
                t.element(find.byType(SettingsHost)),
              )!;
              final check = t.widget<SettingsBtn>(
                find.byKey(const Key('dictionary-check-updates')),
              );
              expect(check.onTap == null, entry.value.checking);
              if (entry.key == 'checking') {
                expect(
                  t
                      .widget<SettingsBtn>(
                        find.byKey(const Key('dictionary-update-tags')),
                      )
                      .onTap,
                  isNull,
                );
                expect(find.textContaining(l.set_dcLatest), findsNothing);
              }
              if (entry.key == 'refresh') {
                expect(find.text(l.set_dcRefreshWiki), findsOneWidget);
                expect(
                  t
                      .widget<SettingsBtn>(
                        find.byKey(const Key('dictionary-update-wiki')),
                      )
                      .onTap,
                  isNotNull,
                );
              }
              if (entry.key == 'failed') {
                expect(find.textContaining(l.set_dcLatest), findsNothing);
              }
              expect(
                t.takeException(),
                isNull,
                reason: '$language $dark $width ${entry.key}',
              );
              if (language == 'zh' &&
                  width == 1280 &&
                  ['latest', 'available', 'refresh'].contains(entry.key)) {
                await _capture(
                  t,
                  'check-${entry.key}-${dark ? 'dark' : 'light'}',
                );
              }
            }
          }
        }
      }
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
            if (phase == SettingsDictionaryPhase.idle && scale == 1 ||
                locale == 'zh' &&
                    width == 1600 &&
                    scale == 1 &&
                    (phase == SettingsDictionaryPhase.downloading ||
                        phase == SettingsDictionaryPhase.done)) {
              await _capture(t, '$locale-${width.toInt()}-${phase.name}');
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
