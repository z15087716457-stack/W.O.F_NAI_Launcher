// 画布编辑器（编辑图像 / 局部重绘）的交互。
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_contract.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'tools_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  ToolsEditorData edit({ToolsTool tool = ToolsTool.brush, bool dirty = true}) =>
      ToolsFixture.editor(tool: tool).copyWith(dirty: dirty);
  ToolsEditorData inpaint({bool focus = false, bool expand = false}) =>
      ToolsFixture.editor(
        mode: ToolsEditorMode.inpaint,
        focus: focus,
        expand: expand,
      );

  Future<void> ctrlEnter(WidgetTester t) async {
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
  }

  group('编辑图像', () {
    testWidgets('布局：顶栏 61、选项条 44、工具栏 56、右栏 280、状态栏 28', (t) async {
      await pumpToolsEditor(t, data: edit());
      expect(t.getSize(find.byKey(const Key('tools-editor-top'))).height, 61);
      expect(
        t.getSize(find.byKey(const Key('tools-editor-options'))).height,
        44,
      );
      expect(t.getSize(find.byKey(const Key('tools-editor-rail'))).width, 56);
      expect(t.getSize(find.byKey(const Key('tools-editor-side'))).width, 280);
      expect(
        t.getSize(find.byKey(const Key('tools-editor-status'))).height,
        28,
      );
      expect(find.text('用作图生图底图'), findsOneWidget);
      expect(find.byKey(const Key('tools-adjust')), findsOneWidget);
    });

    testWidgets('点工具 / 按字母切工具；[ ] 调大小；X 交换颜色', (t) async {
      final r = ToolsRecorder();
      await pumpToolsEditor(t, data: edit(), r: r);
      await tapKey(t, 'tools-tool-lasso');
      await t.sendKeyEvent(LogicalKeyboardKey.keyE);
      await t.sendKeyEvent(LogicalKeyboardKey.bracketRight);
      await t.sendKeyEvent(LogicalKeyboardKey.keyX);
      expect(r.calls[0], 'onTool(lasso)');
      expect(r.calls[1], 'onTool(eraser)');
      expect(r.calls[2], startsWith('onOptions(size: 20.0'));
      expect(r.calls[3], 'onSwapColors');
    });

    testWidgets('不同工具的选项条', (t) async {
      await pumpToolsEditor(t, data: edit());
      expect(find.byKey(const Key('tools-opt-tip')), findsOneWidget);
      expect(find.byKey(const Key('tools-opt-pressure')), findsOneWidget);
      await pumpToolsEditor(t, data: edit(tool: ToolsTool.fill));
      expect(find.byKey(const Key('tools-opt-tolerance')), findsOneWidget);
      expect(find.byKey(const Key('tools-opt-size')), findsNothing);
      await pumpToolsEditor(t, data: edit(tool: ToolsTool.lasso));
      expect(find.textContaining('Alt+L'), findsWidgets);
    });

    testWidgets('笔尖分段、色板选色、更多颜色', (t) async {
      final r = ToolsRecorder();
      await pumpToolsEditor(t, data: edit(), r: r);
      await tapKey(t, 'tools-tip-soft');
      await tapKey(t, 'tools-swatch-primary');
      await tapKey(t, 'tools-palette-8');
      // 背景色块大半压在前景色下面，点它露出来的右下角。
      await t.tapAt(
        t.getBottomRight(find.byKey(const Key('tools-swatch-secondary'))) -
            const Offset(3, 3),
      );
      await t.pumpAndSettle();
      expect(find.text('背景色'), findsOneWidget);
      await tapKey(t, 'tools-palette-more');
      expect(r.calls[0], contains('tip: soft'));
      expect(r.calls[1], 'onColor(ff4f8cff, secondary: false)');
      expect(r.calls[2], 'onMoreColors');
    });

    testWidgets('图层：选中、显隐、右键菜单删除（底图不能删）', (t) async {
      final r = ToolsRecorder();
      await pumpToolsEditor(t, data: edit(), r: r);
      await tapKey(t, 'tools-layer-base');
      await tapKey(t, 'tools-layer-eye-l1');
      await t.tap(
        find.byKey(const Key('tools-layer-l1')),
        buttons: kSecondaryButton,
      );
      await t.pumpAndSettle();
      await tapKey(t, 'tools-layer-delete');
      await tapKey(t, 'tools-layer-add');
      expect(r.calls, [
        'onSelectLayer(base)',
        'onLayerVisible(l1, false)',
        'onLayerAction(l1, delete)',
        'onAddLayer',
      ]);
    });

    testWidgets('调整颜色：重置 / 应用；更改尺寸', (t) async {
      final r = ToolsRecorder();
      await pumpToolsEditor(t, data: edit(), r: r);
      await tapKey(t, 'tools-adjust-reset');
      await tapKey(t, 'tools-adjust-apply');
      await tapKey(t, 'tools-canvas-resize');
      expect(r.calls, ['onAdjustReset', 'onAdjustApply', 'onResizeCanvas']);
      expect(find.text('+8'), findsOneWidget);
      expect(find.text('−3'), findsOneWidget);
    });

    testWidgets('有修改时返回先确认；没修改直接返回', (t) async {
      final r = ToolsRecorder();
      await pumpToolsEditor(t, data: edit(), r: r);
      await tapKey(t, 'tools-editor-back');
      expect(find.byKey(const Key('tools-discard')), findsOneWidget);
      expect(r.calls, isEmpty);
      await t.tap(find.text('放弃'));
      await t.pumpAndSettle();
      expect(r.calls, ['onBack']);

      r.calls.clear();
      await pumpToolsEditor(t, data: edit(dirty: false), r: r);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(r.calls, ['onBack']);
    });

    testWidgets('Ctrl+Enter 用作底图；缩放按钮', (t) async {
      final r = ToolsRecorder();
      await pumpToolsEditor(t, data: edit(), r: r);
      await ctrlEnter(t);
      await tapKey(t, 'tools-zoom-in');
      await tapKey(t, 'tools-zoom-fit');
      expect(r.calls, ['onApply', 'onZoomIn', 'onZoomFit']);
      expect(find.text('67%'), findsOneWidget);
    });

    testWidgets('窄窗：右栏收成抽屉，顶栏开关', (t) async {
      await pumpToolsEditor(t, data: edit(), width: 1000);
      expect(find.byKey(const Key('tools-editor-side')), findsNothing);
      await tapKey(t, 'tools-editor-side-toggle');
      expect(find.byKey(const Key('tools-editor-side')), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('局部重绘', () {
    testWidgets('工具栏 4 个工具 + 清空 / 扩展；右栏重绘设置', (t) async {
      await pumpToolsEditor(t, data: inpaint());
      expect(find.byKey(const Key('tools-tool-focus')), findsOneWidget);
      expect(find.byKey(const Key('tools-tool-blur')), findsNothing);
      expect(find.byKey(const Key('tools-inpaint-settings')), findsOneWidget);
      expect(find.text('18%'), findsOneWidget);
      expect(find.text('未设置（整张图）'), findsOneWidget);
      expect(find.text('画蒙版'), findsWidgets);
    });

    testWidgets('应用菜单：应用蒙版（Ctrl+Enter）/ 应用并生成带价格', (t) async {
      final r = ToolsRecorder();
      await pumpToolsEditor(t, data: inpaint(), r: r);
      await tapKey(t, 'tools-editor-apply-menu');
      expect(find.byKey(const Key('tools-apply-menu')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('tools-apply-menu')),
          matching: find.text('20'),
        ),
        findsOneWidget,
      );
      await tapKey(t, 'tools-apply-generate');
      expect(find.byKey(const Key('tools-apply-menu')), findsNothing);
      await tapKey(t, 'tools-editor-apply-main');
      await ctrlEnter(t);
      expect(r.calls, ['onApplyAndGenerate', 'onApply', 'onApply']);
    });

    testWidgets('方形笔刷、蒙版外观（花纹 / 不透明度 / 颜色）', (t) async {
      final r = ToolsRecorder();
      await pumpToolsEditor(t, data: inpaint(), r: r);
      await tapKey(t, 'tools-opt-square');
      await tapKey(t, 'tools-mask-pattern');
      await tapKey(t, 'tools-pattern-lines');
      await tapKey(t, 'tools-mask-color');
      await tapKey(t, 'tools-mask-color-1');
      expect(r.calls[0], contains('square: true'));
      expect(r.calls[1], 'onMaskLook(ff4f8cff, lines, 0.55, border: false)');
      expect(r.calls[2], 'onMaskLook(ff3dd68c, solid, 0.55, border: false)');
    });

    testWidgets('清空蒙版、进入扩展边缘', (t) async {
      final r = ToolsRecorder();
      await pumpToolsEditor(t, data: inpaint(), r: r);
      await tapKey(t, 'tools-tool-clear');
      await tapKey(t, 'tools-tool-expand');
      expect(r.calls, ['onClearMask', 'onExpanding(true)']);
    });

    testWidgets('聚焦：尺寸 + 上下文；Esc 先清聚焦不退出', (t) async {
      final r = ToolsRecorder();
      await pumpToolsEditor(t, data: inpaint(focus: true), r: r);
      expect(find.byKey(const Key('tools-opt-context')), findsOneWidget);
      expect(find.text('512 × 640'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await tapKey(t, 'tools-focus-clear');
      expect(r.calls, ['onClearFocus', 'onClearFocus']);
    });

    testWidgets('扩展边缘：四边数字、输出尺寸、重置 / 完成，Esc 退出扩展', (t) async {
      final r = ToolsRecorder();
      await pumpToolsEditor(t, data: inpaint(expand: true), r: r);
      expect(find.text('832×1216 → 960×1344'), findsOneWidget);
      expect(find.text('960 × 1344'), findsOneWidget);
      await tapKey(t, 'tools-expand-reset');
      await tapKey(t, 'tools-expand-done');
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(r.calls, [
        'onExpand(0, 0, 0, 0)',
        'onExpanding(false)',
        'onExpanding(false)',
      ]);
    });
  });
}
