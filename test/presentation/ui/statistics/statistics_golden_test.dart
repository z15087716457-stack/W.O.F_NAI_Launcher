// 统计页基准截图：用固定假数据锁定视觉。任何人改了界面导致截图变化，这里会失败。
// 只有界面方确认新样子后才更新基准：
//   flutter test --update-goldens test/presentation/ui/statistics/statistics_golden_test.dart
// 基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_contract.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'stats_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  final skip = !Platform.isWindows;

  final scenes = <(String, Future<void> Function(WidgetTester))>[
    ('main', (t) => pumpStats(t, data: StatsFixture.view())),
    ('main-dark', (t) => pumpStats(t, data: StatsFixture.view(), dark: true)),
    (
      'narrow',
      (t) =>
          pumpStats(t, data: StatsFixture.view(), window: 1000, height: 2600),
    ),
    (
      'narrow-dark',
      (t) => pumpStats(
        t,
        data: StatsFixture.view(),
        window: 1000,
        height: 2600,
        dark: true,
      ),
    ),
    for (final l in ['en', 'ja', 'ko'])
      (
        'narrow-$l',
        (t) => pumpStats(
          t,
          data: StatsFixture.view(),
          window: 1000,
          height: 2600,
          locale: l,
        ),
      ),
    (
      'min-window',
      (t) => pumpStats(t, data: StatsFixture.view(), window: 800, height: 2800),
    ),
    (
      'r30',
      (t) => pumpStats(t, data: StatsFixture.view(range: StatsRange.days30)),
    ),
    (
      'loading',
      (t) => pumpStats(t, data: StatsFixture.view(loading: true), height: 900),
    ),
    (
      'empty-dark',
      (t) => pumpStats(
        t,
        data: StatsFixture.view(empty: true),
        height: 900,
        dark: true,
      ),
    ),
    (
      'error',
      (t) => pumpStats(
        t,
        data: StatsFixture.view(error: 'database is locked'),
        height: 900,
      ),
    ),
  ];

  for (final (name, pump) in scenes) {
    testWidgets(name, skip: skip, (tester) async {
      await pump(tester);
      await expectLater(
        find.byKey(const Key('stats-capture')),
        matchesGoldenFile('goldens/$name.png'),
      );
    });
  }
}
