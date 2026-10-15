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
import 'package:nai_launcher/presentation/ui/viewer/viewer_page.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/approved_visual_regions.dart';
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
    // This fixture's drag hits the bottom. Compare at the same scroll position
    // as the old prototype, compensating only F05's added per-role spacing.
    final position = t
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(const Key('viewer-info-scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    final roles =
        t
            .widget<ImageViewerPage>(find.byType(ImageViewerPage))
            .data
            .detail
            ?.characters
            .length ??
        0;
    if (position.pixels >= position.maxScrollExtent - 1) {
      position.jumpTo(
        (position.maxScrollExtent - roles * 4.5).clamp(
          0,
          position.maxScrollExtent,
        ),
      );
      await t.pumpAndSettle();
    }
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
        // Keep the original prototype PNGs. F05/F06 explicitly change only
        // translation controls and the info-body flow below character headers.
        // Geometry/hover tests verify those regions; the image, frame, metadata,
        // fixed footer and all other pixels still match the old prototype.
        final approved = <Rect>[];
        for (final element
            in find
                .byWidgetPredicate(
                  (w) =>
                      w.key is ValueKey<String> &&
                      (w.key! as ValueKey<String>).value.startsWith(
                        'viewer-translate-',
                      ),
                  skipOffstage: false,
                )
                .evaluate()) {
          approved.add(t.getRect(find.byWidget(element.widget)));
        }
        final scroll = find.byKey(const Key('viewer-info-scroll'));
        if (scroll.evaluate().isNotEmpty) {
          final viewport = t.getRect(scroll);
          for (final element
              in find
                  .byWidgetPredicate(
                    (w) =>
                        w.key is ValueKey<String> &&
                        (w.key! as ValueKey<String>).value.startsWith(
                          'viewer-info-character-',
                        ),
                  )
                  .evaluate()) {
            final role = t.getRect(find.byWidget(element.widget));
            if (role.top < viewport.bottom) {
              approved.add(
                Rect.fromLTRB(
                  viewport.left,
                  role.top.clamp(viewport.top, viewport.bottom),
                  viewport.right,
                  viewport.bottom,
                ),
              );
            }
          }
        }
        await expectOutsideApprovedRegions(
          t,
          find.byKey(const Key('viewer-capture')),
          'test/presentation/ui/viewer/goldens/$file.png',
          approved,
        );
        // 卸掉页面：撤销 / 放大提示的计时器随页面取消。
        await t.pumpWidget(const SizedBox());
        debugDisableShadows = true;
      });
    }
  }
}
