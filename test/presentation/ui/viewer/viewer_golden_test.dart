// 大图查看器基准截图（中文浅色 / 深色）：用固定假数据锁定视觉。界面变了这里会失败。
// 只有界面方确认新样子后才更新基准：
//   flutter test --update-goldens test/presentation/ui/viewer/viewer_golden_test.dart
// 基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_contract.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'viewer_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  final skip = !Platform.isWindows;

  Future<void> zoom200(WidgetTester t) async {
    await tapKey(t, 'viewer-zoom-menu');
    await tapKey(t, 'viewer-zoom-200');
  }

  Future<void> scrollInfo(WidgetTester t) async {
    await t.drag(
      find.byKey(const Key('viewer-info-scroll')),
      const Offset(0, -560),
    );
    await t.pumpAndSettle();
  }

  // (文件名, 数据, 窗口宽, 窗口高, 主导航宽, 是否也拍深色, 交互)
  final scenes =
      <
        (
          String,
          ViewerViewData,
          double,
          double,
          double,
          bool,
          Future<void> Function(WidgetTester)?,
        )
      >[
        (
          'gallery',
          ViewerFixture.gallery(),
          1600,
          1000,
          viewerRail,
          true,
          null,
        ),
        (
          'zoom',
          ViewerFixture.gallery(),
          1600,
          1000,
          viewerRail,
          true,
          zoom200,
        ),
        (
          'characters',
          ViewerFixture.gallery(current: '29', position: 1289, favorite: false),
          1600,
          1000,
          viewerRail,
          true,
          scrollInfo,
        ),
        ('nometa', ViewerFixture.nometa(), 1600, 1000, viewerRail, true, null),
        (
          'generation',
          ViewerFixture.generation(),
          1600,
          1000,
          viewerRail,
          true,
          null,
        ),
        (
          'deleted',
          ViewerFixture.deleted(),
          1600,
          1000,
          viewerRail,
          false,
          null,
        ),
        (
          'more',
          ViewerFixture.gallery(),
          1600,
          1000,
          viewerRail,
          true,
          (t) async {
            await tapKey(t, 'viewer-info-more');
            await tapKey(t, 'viewer-more-collections');
          },
        ),
        (
          'collections',
          ViewerFixture.gallery(),
          1600,
          1000,
          viewerRail,
          false,
          (t) => tapKey(t, 'viewer-info-favorite'),
        ),
        (
          'help',
          ViewerFixture.gallery(),
          1600,
          1000,
          viewerRail,
          true,
          (t) async {
            await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
            await t.sendKeyEvent(LogicalKeyboardKey.slash);
            await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
            await t.pumpAndSettle();
          },
        ),
        (
          'fullscreen',
          ViewerFixture.gallery(fullscreen: true),
          1600,
          1000,
          0,
          false,
          null,
        ),
        (
          'loading',
          ViewerFixture.gallery(
            current: '16',
            loading: true,
            status: ViewerMetaStatus.loading,
          ),
          1600,
          1000,
          viewerRail,
          true,
          null,
        ),
        (
          'missing',
          ViewerFixture.gallery(current: '16', missing: true),
          1600,
          1000,
          viewerRail,
          false,
          null,
        ),
        (
          'info-closed',
          ViewerFixture.gallery(infoOpen: false),
          1600,
          1000,
          viewerRail,
          false,
          null,
        ),
        (
          'narrow',
          ViewerFixture.gallery(),
          1100,
          760,
          viewerRail,
          true,
          (t) async {
            await t.sendKeyEvent(LogicalKeyboardKey.keyI);
            await t.pumpAndSettle();
          },
        ),
      ];

  for (final (name, data, window, height, rail, both, interact) in scenes) {
    for (final dark in both ? [false, true] : [false]) {
      final file = '$name${dark ? '-dark' : ''}';
      testWidgets(file, skip: skip, (t) async {
        debugDisableShadows = false;
        await pumpViewer(
          t,
          data: data,
          window: window,
          height: height,
          rail: rail,
          dark: dark,
        );
        if (interact != null) {
          await interact(t);
          await t.pumpAndSettle();
        }
        await expectLater(
          find.byKey(const Key('viewer-capture')),
          matchesGoldenFile('goldens/$file.png'),
        );
        // 卸掉页面：撤销 / 放大提示的计时器随页面取消。
        await t.pumpWidget(const SizedBox());
        debugDisableShadows = true;
      });
    }
  }
}
