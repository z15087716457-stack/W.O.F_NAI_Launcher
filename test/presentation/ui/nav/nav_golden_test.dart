// 主导航基准截图（中文浅色 / 深色）：用固定假数据锁定视觉。界面变了这里会失败。
// 只有界面方确认新样子后才更新基准：
//   flutter test --update-goldens test/presentation/ui/nav/nav_golden_test.dart
// 基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_contract.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/approved_visual_regions.dart';
import 'nav_test_harness.dart';

const _small = Size(640, 760);

void main() {
  setUpAll(loadStudioCaptureFonts);
  final skip = !Platform.isWindows;

  Future<void> tap(WidgetTester t, String key) async {
    await t.tap(find.byKey(Key(key)));
    await t.pumpAndSettle();
  }

  final scenes =
      <(String, NavViewData, Size, Future<void> Function(WidgetTester)?)>[
        (
          'rail',
          NavFixture.view(
            update: const NavUpdateData(
              status: NavUpdateStatus.available,
              version: '2.3.3',
            ),
          ),
          _small,
          null,
        ),
        (
          'status',
          NavFixture.view(
            generation: NavFixture.running,
            tasks: NavFixture.tasks,
          ),
          _small,
          (t) => hoverOver(t, find.byKey(const Key('main-nav-generation'))),
        ),
        (
          'ctrl',
          NavFixture.view(ctrlHintSeen: false),
          const Size(760, 760),
          (t) async {
            await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
            await t.pump(const Duration(milliseconds: 500));
          },
        ),
        ('expand', NavFixture.view(), _small, (t) => tap(t, 'main-nav-toggle')),
        ('pinned', NavFixture.view(pinned: true), _small, null),
        (
          'account',
          NavFixture.view(),
          _small,
          (t) => tap(t, 'main-nav-avatar'),
        ),
        (
          'tasks',
          NavFixture.view(
            generation: NavFixture.running,
            tasks: NavFixture.tasks,
          ),
          _small,
          (t) => tap(t, 'main-nav-tasks'),
        ),
        (
          'customize',
          NavFixture.view(hidden: {NavPage.tagWiki, NavPage.statistics}),
          _small,
          (t) async {
            await t.tapAt(const Offset(24, 190), buttons: kSecondaryButton);
            await t.pumpAndSettle();
            await tap(t, 'main-nav-customize-menu');
          },
        ),
        (
          'short-window',
          NavFixture.view(tasks: NavFixture.tasks),
          const Size(480, 440),
          null,
        ),
      ];

  for (final dark in [false, true]) {
    for (final (name, data, size, interact) in scenes) {
      final file = '$name${dark ? '-dark' : ''}';
      testWidgets(file, skip: skip, (tester) async {
        debugDisableShadows = false;
        await pumpNav(tester, data: data, size: size, dark: dark);
        if (interact != null) {
          await interact(tester);
          await tester.pumpAndSettle();
        }
        final masks = <Rect>[];
        for (final key in [
          'main-nav-avatar',
          'main-nav-panel-account',
          if (data.update != null) 'main-nav-update',
        ]) {
          final anchor = find.byKey(Key(key));
          if (anchor.evaluate().isNotEmpty) masks.add(tester.getRect(anchor));
        }
        if (data.update != null) {
          // 只排除已移除的旧设置红点，不放宽整个设置按钮的比对。
          final center = tester.getCenter(
            find.byKey(const Key('main-nav-settings')),
          );
          masks.add(Rect.fromLTWH(center.dx + 7, center.dy - 15, 8, 8));
        }
        await expectOutsideApprovedRegions(
          tester,
          find.byKey(const Key('nav-capture')),
          'test/presentation/ui/nav/goldens/$file.png',
          masks,
        );
        if (name == 'ctrl') {
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        }
        debugDisableShadows = true;
      });
    }
  }
}
