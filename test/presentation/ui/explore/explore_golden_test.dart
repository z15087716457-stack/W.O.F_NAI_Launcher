// 画风探索基准截图（中文浅色 / 深色）：用固定假数据锁定视觉。界面变了这里会失败。
// 只有界面方确认新样子后才更新基准：
//   flutter test --update-goldens test/presentation/ui/explore/explore_golden_test.dart
// 基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_contract.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/approved_visual_regions.dart';
import 'explore_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  final skip = !Platform.isWindows;

  Future<void> select(WidgetTester t, List<int> numbers) async {
    await tapKey(t, 'explore-select');
    for (final n in numbers) {
      await t.tap(find.byKey(Key('explore-card-c$n')));
      await t.pumpAndSettle();
    }
  }

  Future<void> evo(WidgetTester t) async {
    await tapKey(t, 'explore-tab-evolution');
    for (final k in ['k3-2', 'k3-5', 'k3-8']) {
      await tapKey(t, 'explore-kid-check-$k');
    }
  }

  // (文件名, 数据, 窗口宽, 窗口高, 是否也拍深色, v4.5, 交互)
  final scenes =
      <
        (
          String,
          ExploreViewData,
          double,
          double,
          bool,
          bool,
          Future<void> Function(WidgetTester)?,
        )
      >[
        ('main', ExploreFixture.view(), 1600, 1000, true, false, null),
        (
          'hover',
          ExploreFixture.view(),
          1600,
          1000,
          false,
          false,
          (t) async {
            await hoverOver(t, find.byKey(const Key('explore-card-c29')));
          },
        ),
        (
          'generating',
          ExploreFixture.view(running: true),
          1600,
          1000,
          true,
          false,
          null,
        ),
        (
          'failed',
          ExploreFixture.view(failed: true),
          1600,
          1000,
          false,
          false,
          (t) async => tapKey(t, 'explore-card-c32'),
        ),
        (
          'selection',
          ExploreFixture.view(),
          1600,
          1000,
          true,
          false,
          (t) => select(t, [27, 29, 30, 34]),
        ),
        ('evolution', ExploreFixture.view(), 1600, 1000, true, false, evo),
        (
          'child',
          ExploreFixture.view(),
          1600,
          1000,
          false,
          false,
          (t) async {
            await tapKey(t, 'explore-tab-evolution');
            await tapKey(t, 'explore-kid-k3-2');
          },
        ),
        (
          'runs',
          ExploreFixture.view(),
          1600,
          1000,
          true,
          false,
          (t) => tapKey(t, 'explore-run-button'),
        ),
        ('empty', ExploreFixture.empty(), 1600, 1000, true, false, null),
        (
          'empty-novars',
          ExploreFixture.empty(vars: const []),
          1600,
          1000,
          false,
          false,
          null,
        ),
        (
          'detail',
          ExploreFixture.view(),
          1600,
          1000,
          true,
          false,
          (t) async {
            await t.sendKeyEvent(LogicalKeyboardKey.enter);
            await t.pumpAndSettle();
          },
        ),
        (
          'compare',
          ExploreFixture.view(),
          1600,
          1000,
          true,
          false,
          (t) async {
            await tapKey(t, 'explore-tab-evolution');
            await tapKey(t, 'explore-compare');
          },
        ),
        (
          'start-evolution',
          ExploreFixture.view(),
          1600,
          1000,
          true,
          false,
          (t) async {
            await select(t, [27, 29, 30, 33]);
            await tapKey(t, 'explore-sel-evo');
          },
        ),
        (
          'save-block',
          ExploreFixture.view(),
          1600,
          1000,
          true,
          false,
          (t) async {
            await select(t, [27, 29, 34]);
            await tapKey(t, 'explore-sel-block');
          },
        ),
        ('v45', ExploreFixture.view(), 1600, 1000, false, true, null),
        (
          'small',
          ExploreFixture.view(cardSize: ExploreCardSize.small),
          1600,
          1000,
          false,
          false,
          null,
        ),
        ('narrow', ExploreFixture.view(), 1200, 860, false, false, null),
        (
          'narrow-drawer',
          ExploreFixture.view(),
          1200,
          860,
          false,
          false,
          (t) => tapKey(t, 'explore-inspector-toggle'),
        ),
        (
          'novars',
          ExploreFixture.view(vars: const []),
          1600,
          1000,
          false,
          false,
          null,
        ),
        (
          'undo',
          ExploreFixture.view(undo: const ExploreUndo(id: 'u1', count: 3)),
          1600,
          1000,
          false,
          false,
          null,
        ),
      ];

  for (final (name, data, window, height, both, v45, interact) in scenes) {
    for (final dark in both ? [false, true] : [false]) {
      final file = '$name${dark ? '-dark' : ''}';
      testWidgets(file, skip: skip, (t) async {
        debugDisableShadows = false;
        await pumpExplore(
          t,
          data: data,
          window: window,
          height: height,
          dark: dark,
          v45: v45,
        );
        if (interact != null) {
          await interact(t);
          await t.pumpAndSettle();
        }
        final approved = <Rect>[
          for (var i = 0; i < data.variables.length; i++)
            if (find
                .byKey(Key('explore-variable-genetic-$i'))
                .evaluate()
                .isNotEmpty)
              t.getRect(find.byKey(Key('explore-variable-genetic-$i'))),
          if (find
              .byKey(const Key('explore-genetic-summary'))
              .evaluate()
              .isNotEmpty)
            t.getRect(find.byKey(const Key('explore-genetic-summary'))),
        ];
        if (approved.isEmpty) {
          await expectLater(
            find.byKey(const Key('explore-capture')),
            matchesGoldenFile('goldens/$file.png'),
          );
        } else {
          await expectOutsideApprovedRegions(
            t,
            find.byKey(const Key('explore-capture')),
            'test/presentation/ui/explore/goldens/$file.png',
            approved,
          );
        }
        await t.pumpWidget(const SizedBox());
        debugDisableShadows = true;
      });
    }
  }
}
