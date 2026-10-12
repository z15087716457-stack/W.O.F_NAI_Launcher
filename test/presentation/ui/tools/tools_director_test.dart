// 导演工具的交互。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'tools_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets('布局：工具清单 256、右栏 320；价格（0 写免费、像素对齐本机免费）', (t) async {
    await pumpToolsDirector(t, data: ToolsFixture.director());
    expect(t.getSize(find.byKey(const Key('tools-director-tools'))).width, 256);
    expect(t.getSize(find.byKey(const Key('tools-director-side'))).width, 320);
    expect(
      find.descendant(
        of: find.byKey(const Key('tools-dt-removeBackground')),
        matching: find.text('65'),
      ),
      findsOneWidget,
    );
    expect(find.text('本机 · 免费'), findsOneWidget);
    expect(find.text('运行草图化'), findsOneWidget);
    expect(find.textContaining('Opus'), findsOneWidget);
  });

  testWidgets('选工具、选结果、沿用设置（悬停出按钮）', (t) async {
    final r = ToolsRecorder();
    await pumpToolsDirector(t, data: ToolsFixture.director(), r: r);
    await tapKey(t, 'tools-dt-colorize');
    await tapKey(t, 'tools-run-r3');
    await hoverOver(t, find.byKey(const Key('tools-run-r2')));
    await t.tap(find.byKey(const Key('tools-run-reuse-r2')));
    await t.pumpAndSettle();
    expect(r.calls, [
      'onTool(colorize)',
      'onSelectRun(r3)',
      'onReuseSettings(r2)',
    ]);
  });

  testWidgets('对比方式：并排 → 滑动（拖手柄）→ 只看结果', (t) async {
    await pumpToolsDirector(t, data: ToolsFixture.director());
    expect(find.byKey(const Key('tools-pane-original')), findsOneWidget);
    await tapKey(t, 'tools-compare-wipe');
    expect(find.byKey(const Key('tools-pane-wipe')), findsOneWidget);
    final handle = find.byKey(const Key('tools-wipe-handle'));
    final x0 = t.getCenter(handle).dx;
    await t.drag(handle, const Offset(-120, 0));
    await t.pumpAndSettle();
    expect(t.getCenter(handle).dx, lessThan(x0 - 100));
    await tapKey(t, 'tools-compare-result');
    expect(find.byKey(const Key('tools-pane-original')), findsNothing);
    expect(find.byKey(const Key('tools-pane-result')), findsOneWidget);
  });

  testWidgets('结果操作：继续处理、复制、存到图库、放大、用作底图', (t) async {
    final r = ToolsRecorder();
    await pumpToolsDirector(t, data: ToolsFixture.director(), r: r);
    for (final k in ['continue', 'copy', 'save', 'upscale', 'init']) {
      await tapKey(t, 'tools-act-$k');
    }
    expect(r.calls, [
      'onContinue',
      'onCopy',
      'onSave',
      'onUpscale',
      'onUseAsInit',
    ]);
  });

  testWidgets('输入队列：切换、悬停移除、加号菜单三项', (t) async {
    final r = ToolsRecorder();
    await pumpToolsDirector(t, data: ToolsFixture.director(), r: r);
    await tapKey(t, 'tools-queue-in2');
    await hoverOver(t, find.byKey(const Key('tools-queue-in3')));
    await t.tap(find.byKey(const Key('tools-queue-remove-in3')));
    await t.pumpAndSettle();
    await tapKey(t, 'tools-queue-add');
    await tapKey(t, 'tools-queue-history');
    expect(r.calls, [
      'onSelectInput(in2)',
      'onRemoveInput(in3)',
      'onPickHistory',
    ]);
  });

  testWidgets('快捷键：Ctrl+Enter 运行、Ctrl+V 粘贴、Esc 回生图', (t) async {
    final r = ToolsRecorder();
    await pumpToolsDirector(t, data: ToolsFixture.director(), r: r);
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.sendKeyEvent(LogicalKeyboardKey.keyV);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(r.calls, ['onRun', 'onPaste', 'onBack']);
  });

  testWidgets('表情修复运行前：16 个表情 + 更多 8 个、强度、补充提示词；结果操作不可点', (t) async {
    final r = ToolsRecorder();
    await pumpToolsDirector(t, data: ToolsFixture.emotion(), r: r);
    expect(find.byKey(const Key('tools-result-empty')), findsOneWidget);
    expect(find.text('选好表情后按“运行”'), findsOneWidget);
    expect(find.byKey(const Key('tools-emo-love')), findsNothing);
    await tapKey(t, 'tools-emo-more');
    expect(find.byKey(const Key('tools-emo-love')), findsOneWidget);
    await tapKey(t, 'tools-emo-love');
    await tapKey(t, 'tools-defry-3');
    await t.enterText(
      find.byKey(const Key('tools-dt-prompt-field')),
      'heart eyes',
    );
    await tapKey(t, 'tools-act-copy');
    expect(r.calls, ['onEmotion(love)', 'onDefry(3)', 'onPrompt(heart eyes)']);
  });

  testWidgets('背景移除三张：分段切换', (t) async {
    final r = ToolsRecorder();
    await pumpToolsDirector(t, data: ToolsFixture.removeBg(), r: r);
    expect(find.text('背景移除 · 合成 · 832 × 1216'), findsOneWidget);
    await tapKey(t, 'tools-variant-0');
    expect(r.calls, ['onVariant(0)']);
  });

  testWidgets('运行中：右格转圈、工具清单和运行按钮不可点', (t) async {
    final r = ToolsRecorder();
    await pumpToolsDirector(t, data: ToolsFixture.running(), r: r);
    expect(find.byKey(const Key('tools-result-running')), findsOneWidget);
    await t.tap(find.byKey(const Key('tools-dt-sketch')));
    await t.tap(find.byKey(const Key('tools-dt-run')));
    await t.pump();
    expect(r.calls, isEmpty);
  });

  testWidgets('失败：说明 + 重试 / 关闭', (t) async {
    final r = ToolsRecorder();
    await pumpToolsDirector(t, data: ToolsFixture.failed(), r: r);
    expect(find.textContaining('429'), findsOneWidget);
    await tapKey(t, 'tools-result-retry');
    await tapKey(t, 'tools-result-dismiss');
    expect(r.calls, ['onRun', 'onDismissError']);
  });

  testWidgets('像素对齐：调色板、颜色数、两个开关', (t) async {
    final r = ToolsRecorder();
    await pumpToolsDirector(t, data: ToolsFixture.pixel(), r: r);
    expect(find.byKey(const Key('tools-pixel-colors')), findsOneWidget);
    expect(find.text('运行像素对齐'), findsOneWidget);
    await tapKey(t, 'tools-palette-auto');
    await tapKey(t, 'tools-pixel-upscale');
    expect(r.calls, [
      'onPixel(auto, 48, false, false)',
      'onPixel(custom, 48, false, true)',
    ]);
  });

  testWidgets('队列为空：舞台给投放说明，运行按钮不可点', (t) async {
    final r = ToolsRecorder();
    await pumpToolsDirector(t, data: ToolsFixture.empty, r: r);
    expect(find.byKey(const Key('tools-no-input')), findsOneWidget);
    await t.tap(find.byKey(const Key('tools-dt-run')));
    await t.pump();
    expect(r.calls, isEmpty);
    expect(find.text('先在下面放一张输入'), findsOneWidget);
  });

  testWidgets('窄窗：工具清单收成图标列', (t) async {
    await pumpToolsDirector(t, data: ToolsFixture.director(), width: 1200);
    expect(t.getSize(find.byKey(const Key('tools-director-tools'))).width, 64);
    expect(t.takeException(), isNull);
  });
}
