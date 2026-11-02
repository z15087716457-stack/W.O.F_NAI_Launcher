import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_slider.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_fixture.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_sheets.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../gen/gen_test_harness.dart' show genApp;
import 'tools_test_harness.dart';

Finder scaleNumber() => find.descendant(
  of: find.byKey(const Key('tools-upscale-scale')),
  matching: find.byType(UiNumBox),
);

Finder scaleInput() =>
    find.descendant(of: scaleNumber(), matching: find.byType(TextField));

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets('本地倍率滑条能准确选中 2 倍并拖到 4 倍端点', (t) async {
    final r = ToolsRecorder();
    await pumpToolsGen(t, r: r, sheet: GenToolSheet.upscale);
    final slider = find.descendant(
      of: find.byKey(const Key('tools-upscale-scale')),
      matching: find.byType(UiSlider),
    );
    final rect = t.getRect(slider);
    await t.tapAt(Offset(rect.left + rect.width / 3, rect.center.dy));
    await t.pumpAndSettle();
    expect(r.calls, ['onScale(2.0)']);
    r.calls.clear();
    await t.dragFrom(rect.center, Offset(rect.width, 0));
    await t.pumpAndSettle();
    expect(r.calls, ['onScale(4.0)']);
  });

  testWidgets('点击倍率直接输入超过 2 倍，回车确认，Esc 取消', (t) async {
    final r = ToolsRecorder();
    await pumpToolsGen(t, r: r, sheet: GenToolSheet.upscale);
    await t.tap(scaleNumber());
    await t.pump();
    await t.enterText(scaleInput(), '2.5');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(r.calls, ['onScale(2.5)']);
    expect(scaleInput(), findsNothing);

    await t.tap(scaleNumber());
    await t.pump();
    await t.enterText(scaleInput(), '3');
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(r.calls, ['onScale(2.5)']);
    expect(find.byKey(const Key('tools-upscale-sheet')), findsOneWidget);
    expect(scaleInput(), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('倍率失焦确认并沿用 1–4 倍输入范围', (t) async {
    final r = ToolsRecorder();
    await pumpToolsGen(t, r: r, sheet: GenToolSheet.upscale);
    for (final value in ['3.25', '6', '0.5']) {
      await t.tap(scaleNumber());
      await t.pump();
      await t.enterText(scaleInput(), value);
      FocusManager.instance.primaryFocus!.unfocus();
      await t.pumpAndSettle();
    }
    expect(r.calls, ['onScale(3.25)', 'onScale(4.0)', 'onScale(1.0)']);
  });

  testWidgets('运行中倍率不可编辑或拖动', (t) async {
    final r = ToolsRecorder();
    await t.pumpWidget(
      genApp(
        Center(
          child: ToolsUpscaleSheet(
            data: ToolsFixture.upscale().copyWith(running: true),
            actions: r.upscale,
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(scaleNumber());
    final slider = find.descendant(
      of: find.byKey(const Key('tools-upscale-scale')),
      matching: find.byType(UiSlider),
    );
    await t.drag(slider, const Offset(100, 0));
    await t.pumpAndSettle();
    expect(scaleInput(), findsNothing);
    expect(r.calls, isEmpty);
  });

  for (final locale in ['zh', 'en', 'ja']) {
    for (final dark in [false, true]) {
      testWidgets('倍率输入布局 $locale dark=$dark', (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(720, 700);
        addTearDown(t.view.reset);
        final r = ToolsRecorder();
        await t.pumpWidget(
          genApp(
            Center(
              child: ToolsUpscaleSheet(
                data: ToolsFixture.upscale(),
                actions: r.upscale,
              ),
            ),
            locale: locale,
            dark: dark,
          ),
        );
        await t.pumpAndSettle();
        final row = t.getRect(find.byKey(const Key('tools-upscale-scale-row')));
        expect(t.getRect(scaleNumber()).height, 26);
        expect(row.contains(t.getRect(scaleNumber()).center), isTrue);
        await t.tap(scaleNumber());
        await t.pumpAndSettle();
        await t.enterText(scaleInput(), '3.25');
        await t.pump(const Duration(milliseconds: 100));
        expect(t.takeException(), isNull);
        final output = Platform.environment['NAI_UPSCALE_SCALE_CAPTURES'];
        if (output != null) {
          final boundary = t.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('gen-capture')),
          );
          await t.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File('$output/$locale-${dark ? 'dark' : 'light'}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await t.sendKeyEvent(LogicalKeyboardKey.escape);
        await t.pumpAndSettle();
        await t.pumpWidget(const SizedBox());
        await t.pump();
      });
    }
  }
}
