// 工具条落下的面板（增强 / 放大设置）和工具条本身的新状态：悬停提示、选中、放大进度。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'tools_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  group('工具条', () {
    testWidgets('面板开着时落在工具条下面，尖角指着按钮', (t) async {
      final r = ToolsRecorder();
      await pumpToolsGen(t, r: r, sheet: GenToolSheet.enhance);
      final bar = t.getRect(find.byKey(const Key('gen-bar-top')));
      final sheet = t.getRect(find.byKey(const Key('tools-enhance-sheet')));
      final btn = t.getRect(find.byKey(const Key('gen-enhance')));
      final caret = t.getRect(find.byKey(const Key('gen-sheet-caret')));
      expect(sheet.top - bar.bottom, 12);
      expect(sheet.center.dx, closeTo(bar.center.dx, 1));
      expect(caret.center.dx, closeTo(btn.center.dx, .5));
      expect(caret.center.dy, closeTo(sheet.top, 1.5));
    });

    testWidgets('放大旁的箭头开放大设置（有 onUpscaleSettings 时不弹老菜单）', (t) async {
      final r = ToolsRecorder();
      await pumpToolsGen(t, r: r);
      await tapKey(t, 'gen-upscale-menu');
      expect(r.calls, ['onUpscaleSettings']);
    });

    testWidgets('悬停变体：名字、说明、价格', (t) async {
      final r = ToolsRecorder();
      await pumpToolsGen(t, r: r);
      await hoverOver(t, find.byKey(const Key('gen-variations')));
      await t.pump(const Duration(milliseconds: 400));
      final tip = find.byKey(const Key('gen-bar-tip'));
      expect(tip, findsOneWidget);
      expect(
        find.descendant(of: tip, matching: find.textContaining('4 张')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tip, matching: find.text('48')),
        findsOneWidget,
      );
      await t.pump(const Duration(seconds: 1));
    });

    testWidgets('本地放大免费：价格块写“免费”', (t) async {
      final r = ToolsRecorder();
      await pumpToolsGen(t, r: r);
      expect(
        find.descendant(
          of: find.byKey(const Key('gen-upscale')),
          matching: find.text('免费'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('放大进行中：进度圈 + 进度条，取消回调 onUpscale', (t) async {
      final r = ToolsRecorder();
      await pumpToolsGen(t, r: r, progress: .37);
      expect(find.byKey(const Key('gen-upscale-ring')), findsOneWidget);
      expect(find.byKey(const Key('gen-upscale-menu')), findsNothing);
      expect(find.text('37%'), findsOneWidget);
      expect(find.byKey(const Key('gen-upscale-strip')), findsOneWidget);
      await tapKey(t, 'gen-upscale-cancel');
      expect(r.last('onUpscale('), startsWith('onUpscale('));
    });
  });

  group('增强面板', () {
    testWidgets('放大档、幅度、自定义开关、运行和关闭', (t) async {
      final r = ToolsRecorder();
      await pumpToolsGen(t, r: r, sheet: GenToolSheet.enhance);
      await tapKey(t, 'tools-scale-1.5');
      await tapKey(t, 'tools-mag-5');
      await tapKey(t, 'tools-enhance-custom-switch');
      await tapKey(t, 'tools-enhance-run');
      await tapKey(t, 'tools-sheet-close');
      expect(r.calls, [
        'onScale(1.5)',
        'onMagnitude(5)',
        'onCustom(true)',
        'onRun',
        'onClose',
      ]);
    });

    testWidgets('Esc 关闭、Ctrl+Enter 运行', (t) async {
      final r = ToolsRecorder();
      await pumpToolsGen(t, r: r, sheet: GenToolSheet.enhance);
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(r.calls, ['onRun', 'onClose']);
    });

    testWidgets('自定义：幅度分段变灰不可点，出强度 / 噪声滑杆', (t) async {
      final r = ToolsRecorder();
      await pumpToolsGen(t, r: r, sheet: GenToolSheet.enhance, custom: true);
      expect(find.byKey(const Key('tools-enhance-custom')), findsOneWidget);
      expect(find.text('0.62'), findsOneWidget);
      await t.tap(find.byKey(const Key('tools-mag-2')));
      await t.pumpAndSettle();
      expect(r.calls, isEmpty);
    });

    testWidgets('本地放大档：本机模型卡代替幅度，按钮去放大设置', (t) async {
      final r = ToolsRecorder();
      await pumpToolsGen(t, r: r, sheet: GenToolSheet.enhance, local: true);
      expect(find.byKey(const Key('tools-enhance-magnitude')), findsNothing);
      expect(find.text('SeedVR2 3B FP8 · 2×'), findsOneWidget);
      expect(find.text('增强并本地放大'), findsOneWidget);
      await tapKey(t, 'tools-enhance-local-settings');
      expect(r.calls, ['onOpenUpscaleSettings']);
    });
  });

  group('放大设置', () {
    testWidgets('换方式、方法、模型（菜单里标未安装）、管理模型、运行', (t) async {
      final r = ToolsRecorder();
      await pumpToolsGen(t, r: r, sheet: GenToolSheet.upscale);
      await tapKey(t, 'tools-backend-novelai');
      await tapKey(t, 'tools-method-rtx');
      await tapKey(t, 'tools-upscale-model');
      expect(find.text('未安装'), findsOneWidget);
      await tapKey(t, 'tools-model-seedvr2-3b-q4');
      await tapKey(t, 'tools-upscale-manage');
      await tapKey(t, 'tools-upscale-run');
      expect(r.calls, [
        'onBackend(novelai)',
        'onMethod(rtx)',
        'onModel(seedvr2-3b-q4)',
        'onManageModels',
        'onRun',
      ]);
    });

    testWidgets('高级设置折叠展开', (t) async {
      final r = ToolsRecorder();
      await pumpToolsGen(t, r: r, sheet: GenToolSheet.upscale);
      expect(find.byKey(const Key('tools-upscale-fields')), findsNothing);
      await tapKey(t, 'tools-upscale-advanced');
      expect(find.byKey(const Key('tools-upscale-fields')), findsOneWidget);
      expect(find.text('显存分块'), findsOneWidget);
    });
  });
}
