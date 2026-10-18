// 服务商工作台基准截图（中文浅色 / 深色 + 关键状态）：固定假数据、真实字体，锁定视觉。
// 只有界面方确认新样子后才更新：
//   flutter test --update-goldens test/presentation/ui/model_providers/model_providers_golden_test.dart
// 接线侧不准 --update-goldens。基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_providers_harness.dart';

Finder _field(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

void main() {
  setUpAll(loadStudioCaptureFonts);
  final skip = !Platform.isWindows;

  final scenes = <(String, double, bool, Future<void> Function(WidgetTester)?)>[
    ('ready', 1600, false, null),
    ('ready-dark', 1600, true, null),
    (
      'pro',
      1600,
      false,
      (t) => t.tap(find.byKey(const Key('mp-model-deepseek-v4-pro'))),
    ),
    (
      'catalog',
      1600,
      false,
      (t) async {
        await t.tap(find.byKey(const Key('mp-provider-or')));
        await t.pumpAndSettle();
        await t.tap(find.text('服务商目录 342'));
        await t.pumpAndSettle();
        await t.enterText(_field('mp-filter-catalog'), 'claude');
        await t.pump(const Duration(milliseconds: 400));
        await t.tap(find.byKey(const Key('mp-cat-anthropic/claude-opus-5')));
        await t.tap(find.byKey(const Key('mp-cat-anthropic/claude-haiku-5')));
      },
    ),
    (
      'catalog-dark',
      1600,
      true,
      (t) async {
        await t.tap(find.byKey(const Key('mp-provider-or')));
        await t.pumpAndSettle();
        await t.tap(find.text('服务商目录 342'));
      },
    ),
    (
      'error',
      1600,
      false,
      (t) => t.tap(find.byKey(const Key('mp-provider-relay'))),
    ),
    (
      'headers',
      1600,
      false,
      (t) => t.tap(find.byKey(const Key('mp-provider-or'))),
    ),
    (
      'unsaved',
      1600,
      false,
      (t) async {
        await t.tap(find.byKey(const Key('mp-level-medium')));
        await t.tap(find.byKey(const Key('mp-cap-search')));
      },
    ),
    ('add', 1600, false, (t) => t.tap(find.byKey(const Key('mp-add')))),
    ('add-dark', 1600, true, (t) => t.tap(find.byKey(const Key('mp-add')))),
    ('narrow', 1100, false, null),
  ];

  for (final (name, w, dark, act) in scenes) {
    testWidgets(name, skip: skip, (t) async {
      await pumpProviders(t, window: w, height: 1100, dark: dark);
      if (act != null) {
        await act(t);
        await t.pumpAndSettle();
      }
      await expectLater(
        find.byKey(const Key('settings-capture')),
        matchesGoldenFile('goldens/mp-$name.png'),
      );
    });
  }
}
