import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nai_launcher/core/constants/app_version.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/update_provider.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_lib_controls.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_system.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(() async {
    await loadStudioCaptureFonts();
    PackageInfo.setMockInitialValues(
      appName: 'nai_launcher',
      packageName: 'nai_launcher',
      version: '2.2.1',
      buildNumber: '61',
      buildSignature: '',
    );
    await AppVersion.initialize();
  });

  test('只有成功确认最新才能投影成最新版状态', () {
    const expected = {
      UpdateStatus.idle: SettingsUpdateState.unchecked,
      UpdateStatus.skipped: SettingsUpdateState.skipped,
      UpdateStatus.checking: SettingsUpdateState.checking,
      UpdateStatus.available: SettingsUpdateState.available,
      UpdateStatus.downloading: SettingsUpdateState.downloading,
      UpdateStatus.downloaded: SettingsUpdateState.available,
      UpdateStatus.installing: SettingsUpdateState.available,
      UpdateStatus.error: SettingsUpdateState.failed,
      UpdateStatus.upToDate: SettingsUpdateState.upToDate,
    };
    for (final status in UpdateStatus.values) {
      final about = settingsAboutData(UpdateState(status: status), null);
      expect(about.update, expected[status]);
      expect(about.build, '61');
    }
    expect(const SettingsAboutData().update, SettingsUpdateState.unchecked);
  });

  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets('关于页更新标签与颜色 $locale dark=$dark', (t) async {
        for (final status in [
          UpdateStatus.idle,
          UpdateStatus.skipped,
          UpdateStatus.error,
          UpdateStatus.upToDate,
        ]) {
          await pumpSettings(
            t,
            data: _data(status),
            locale: locale,
            dark: dark,
            window: dark ? 900 : 1600,
          );
          final l = AppLocalizations.of(t.element(find.byType(Scaffold)))!;
          final label = switch (status) {
            UpdateStatus.idle => l.set_abUnchecked,
            UpdateStatus.skipped => l.set_abSkipped,
            UpdateStatus.error => l.set_abCheckFailed,
            _ => l.set_abLatest,
          };
          final chip = find.ancestor(
            of: find.text(label),
            matching: find.byType(UiMini),
          );
          expect(chip, findsOneWidget);
          expect(t.widget<UiMini>(chip).tone, switch (status) {
            UpdateStatus.upToDate => UiMiniTone.ok,
            UpdateStatus.error => UiMiniTone.warn,
            _ => UiMiniTone.plain,
          });
          expect(
            find.text(l.set_abLatest),
            status == UpdateStatus.upToDate ? findsOneWidget : findsNothing,
          );
          expect(t.takeException(), isNull);
          final output = Platform.environment['NAI_UPDATE_STATUS_CAPTURES'];
          if (output != null &&
              ((locale == 'zh' && dark) || (locale == 'en' && !dark))) {
            await t.runAsync(
              () => precacheImage(
                const AssetImage('assets/images/wof_logo_full.png'),
                t.element(chip),
              ),
            );
            await t.pumpAndSettle();
            final boundary = t.renderObject<RenderRepaintBoundary>(
              find.byKey(const Key('settings-capture')),
            );
            await t.runAsync(() async {
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File('$output/$locale-${status.name}.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await t.pumpWidget(const SizedBox());
        }
      });
    }
  }
}

SettingsViewData _data(UpdateStatus status) {
  final d = SettingsFixture.view(page: SettingsPageId.about);
  return SettingsViewData(
    page: d.page,
    values: d.values,
    now: d.now,
    version: AppVersion.versionName,
    options: d.options,
    account: d.account,
    canvas: d.canvas,
    shortcuts: d.shortcuts,
    generation: d.generation,
    storage: d.storage,
    dictionaries: d.dictionaries,
    models: d.models,
    agent: d.agent,
    rag: d.rag,
    upscale: d.upscale,
    bridges: d.bridges,
    network: d.network,
    privacy: d.privacy,
    backup: d.backup,
    about: settingsAboutData(UpdateState(status: status), null),
  );
}
