// 生图页基准截图（中文浅色 / 深色）：用固定假数据锁定视觉。界面变了这里会失败。
// 只有界面方确认新样子后才更新基准：
//   flutter test --update-goldens test/presentation/ui/gen/gen_golden_test.dart
// 基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture_editor.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/approved_visual_regions.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  final skip = !Platform.isWindows;

  Future<void> expandRefs(WidgetTester t) async {
    for (final k in ['img2img', 'vibe', 'precise']) {
      await tapKey(t, 'gen-ref-$k-row');
    }
    await t.drag(
      find.byKey(const Key('gen-left-scroll')),
      const Offset(0, -340),
    );
    await t.pumpAndSettle();
  }

  final positioning = GenFixture.characters();
  final dockSlots = GenSlots(
    editor: GenFixtureEditor.builder,
    dock: Container(
      color: const Color(0x11000000),
      alignment: Alignment.center,
      child: const Text('BlocksDock'),
    ),
  );

  // (文件名, 数据, 窗口宽, 窗口高, 也拍深色, 槽位, 交互)
  final scenes =
      <
        (
          String,
          GenViewData,
          double,
          double,
          bool,
          GenSlots?,
          Future<void> Function(WidgetTester)?,
        )
      >[
        ('main', GenFixture.view(), 1600, 1120, true, null, null),
        ('v45', GenFixture.view(v45: true), 1600, 1120, true, null, null),
        ('v3', GenFixture.v3(), 1600, 1120, false, null, null),
        ('generating', GenFixture.generating(), 1600, 1120, true, null, null),
        ('failed', GenFixture.failed(), 1600, 1120, false, null, null),
        ('empty', GenFixture.empty(), 1600, 1120, true, null, null),
        ('refs', GenFixture.refsFull(), 1600, 1120, true, null, expandRefs),
        ('characters', GenFixture.characters(), 1600, 1120, false, null, null),
        (
          'positioning',
          positioning.copyWith(
            canvas: GenCanvasData(
              focus: positioning.canvas.focus,
              info: positioning.canvas.info,
              positioning: true,
            ),
          ),
          1600,
          1120,
          true,
          null,
          null,
        ),
        (
          'drawer',
          GenFixture.view(v45: true),
          1600,
          1120,
          true,
          null,
          (t) async => tapKey(t, 'gen-params-toggle'),
        ),
        (
          'model-menu',
          GenFixture.view(),
          1600,
          1120,
          false,
          null,
          (t) async => tapKey(t, 'gen-model'),
        ),
        (
          'tools-menu',
          GenFixture.view(),
          1600,
          1120,
          true,
          null,
          (t) async => tapKey(t, 'gen-tool-menu'),
        ),
        (
          'display',
          GenFixture.view(),
          1600,
          1120,
          false,
          null,
          (t) async => tapKey(t, 'gen-display'),
        ),
        (
          'history-select',
          GenFixture.view(),
          1600,
          1120,
          false,
          null,
          (t) async {
            await tapKey(t, 'gen-history-select');
            await tapKey(t, 'gen-batch-tile-b2');
            await tapKey(t, 'gen-batch-tile-b3');
          },
        ),
        (
          'history-menu',
          GenFixture.view(),
          1600,
          1120,
          false,
          null,
          (t) async {
            await t.tap(
              find.byKey(const Key('gen-batch-tile-b2')),
              buttons: kSecondaryButton,
            );
            await t.pumpAndSettle();
          },
        ),
        ('narrow', GenFixture.view(v45: true), 1100, 760, false, null, null),
        (
          'collapsed-dock',
          GenFixture.view(
            layout: const GenLayout(
              leftOpen: false,
              historyOpen: false,
              dockOpen: true,
            ),
          ),
          1600,
          1120,
          false,
          dockSlots,
          null,
        ),
      ];

  for (final (name, data, window, height, both, slots, interact) in scenes) {
    for (final dark in both ? [false, true] : [false]) {
      final file = '$name${dark ? '-dark' : ''}';
      testWidgets(file, skip: skip, (t) async {
        debugDisableShadows = false;
        await pumpGen(
          t,
          data: data,
          window: window,
          height: height,
          dark: dark,
          slots: slots,
        );
        if (interact != null) {
          await interact(t);
          await t.pumpAndSettle();
          await precacheGen(t, const []);
        }
        final masks = <Rect>[];
        // Only the user-approved Turbo + A/F area changes. Keep the model
        // button, quota, header size and all original PNGs under comparison.
        final turbo = find.byKey(const Key('gen-turbo'));
        final modelCapsule = find.byKey(const Key('gen-model-capsule'));
        if (turbo.evaluate().isNotEmpty && modelCapsule.evaluate().isNotEmpty) {
          final button = t.getRect(turbo), capsule = t.getRect(modelCapsule);
          final mode = find.byKey(const Key('gen-mode'));
          final furry = find
              .descendant(of: mode, matching: find.text('F'))
              .evaluate()
              .isNotEmpty;
          // Retain the same pre-Turbo right edge after the user-requested
          // narrowing; include only the pixels previously inside that capsule.
          final originalRight =
              capsule.right + (furry ? 43.164 : 48.312) - t.getSize(mode).width;
          masks.add(
            Rect.fromLTRB(
              button.left,
              capsule.top,
              originalRight,
              capsule.bottom,
            ),
          );
        }
        final tools = find.byKey(const Key('gen-tool-menu'));
        final prompt = find.byKey(const Key('gen-prompt'));
        if (tools.evaluate().isNotEmpty && prompt.evaluate().isNotEmpty) {
          final row = t.getRect(tools), card = t.getRect(prompt);
          masks.add(Rect.fromLTWH(card.left, row.top, card.width, row.height));
        }
        final translatePin = find.byKey(const Key('gen-pin-translate'));
        if (translatePin.evaluate().isNotEmpty) {
          final row = t.getRect(translatePin);
          masks.add(Rect.fromLTWH(row.left, row.top, 30, row.height));
        }
        // The user requested a persistent variation price slot. Preserve the
        // original prototype PNG and compare every pixel outside this bar.
        final canvasToolbar = find.byKey(const Key('gen-bar-top'));
        if (canvasToolbar.evaluate().isNotEmpty) {
          masks.add(
            t.getRect(canvasToolbar).inflate(22),
          ); // Includes its shadow.
        }
        // 10-25: the inline clear x was removed from prompt editors, giving
        // the editor text the freed 20px. Only editor slots are excluded.
        for (final e in find
            .byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith('gen-editor-'),
            )
            .evaluate()) {
          masks.add(t.getRect(find.byWidget(e.widget)));
        }
        await expectOutsideApprovedRegions(
          t,
          find.byKey(const Key('gen-capture')),
          'test/presentation/ui/gen/goldens/$file.png',
          masks,
        );
        await t.pumpWidget(const SizedBox());
        debugDisableShadows = true;
      });
    }
  }
}
