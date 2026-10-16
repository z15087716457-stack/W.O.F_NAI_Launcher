// 保留原设置页基准；用户授权的正文整体居中只允许水平平移。
// 归一横向锚点后，正文排版、侧栏和顶栏仍须逐像素匹配原图。
// 基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
      await _expectCenteredGolden(t, name);
      await t.pump(const Duration(seconds: 5));
    });
  }
}

// 只将已授权改变的横向锚点临时还原再实绘，避免平移旧 PNG 时
// Skia 圆角边缘的栅格差异；正文尺寸、排版、所有控件及外围像素照常锁定。
// 居中后的几何、窗口缩放和实际画面由 settings_centering_test 验证。
Future<void> _expectCenteredGolden(WidgetTester t, String name) async {
  final scroll = t.widget<SingleChildScrollView>(
    find.byKey(const Key('settings-scroll')),
  );
  final align = t.renderObject<RenderPositionedBox>(
    find.byWidget(scroll.child! as Align),
  );
  final current = align.alignment;
  expect(current, Alignment.topCenter);
  try {
    align.alignment = Alignment.topLeft;
    await t.pump();
    await expectLater(
      find.byKey(const Key('settings-capture')),
      matchesGoldenFile('goldens/settings-$name.png'),
    );
  } finally {
    align.alignment = current;
    await t.pump();
  }
}
