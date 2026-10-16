// 设置页基准截图：用固定假数据锁定视觉。任何人改了界面导致截图变化，这里会失败。
// 只有界面方确认新样子后才更新基准：
//   flutter test --update-goldens test/presentation/ui/settings/settings_golden_test.dart
// 基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  final skip = !Platform.isWindows;

  final scenes = <(String, Future<void> Function(WidgetTester))>[
    for (final p in SettingsPageId.values)
      (p.name, (t) => pumpSettings(t, page: p)),
    for (final p in [
      SettingsPageId.overview,
      SettingsPageId.appearance,
      SettingsPageId.shortcuts,
      SettingsPageId.models,
      SettingsPageId.upscale,
    ])
      ('${p.name}-dark', (t) => pumpSettings(t, page: p, dark: true)),
    ('search', (t) => pumpSettings(t, initialQuery: 'anlas')),
    (
      'toast',
      (t) => pumpSettings(
        t,
        page: SettingsPageId.generation,
        scene: SettingsScene.toast,
      ),
    ),
    (
      'restart',
      (t) => pumpSettings(
        t,
        page: SettingsPageId.network,
        scene: SettingsScene.restart,
      ),
    ),
    ('fresh', (t) => pumpSettings(t, scene: SettingsScene.fresh)),
    ('narrow', (t) => pumpSettings(t, window: 1100)),
  ];

  for (final (name, pump) in scenes) {
    testWidgets(name, skip: skip, (t) async {
      await pump(t);
      await expectLater(
        find.byKey(const Key('settings-capture')),
        matchesGoldenFile('goldens/settings-$name.png'),
      );
      await t.pump(const Duration(seconds: 5));
    });
  }
}
