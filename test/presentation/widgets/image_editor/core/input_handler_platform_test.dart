// 图片编辑器的按键：macOS 上 ⌘ 是主修饰键（⌘= 放大、⌘Z 撤销），按着 ⌘ 的字母不切工具（⌘C 复制、⌘S 存图）。
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/input_handler.dart';

Future<(EditorState, InputHandler)> _pump(WidgetTester t) async {
  final state = EditorState();
  addTearDown(state.dispose);
  final node = FocusNode(debugLabel: 'editor');
  addTearDown(node.dispose);
  final handler = InputHandler(
    state: state,
    focusNode: node,
    onStateChanged: () {},
  );
  HardwareKeyboard.instance.addHandler(handler.handleHardwareKey);
  addTearDown(
    () => HardwareKeyboard.instance.removeHandler(handler.handleHardwareKey),
  );
  await t.pumpWidget(
    Focus(
      focusNode: node,
      autofocus: true,
      onKeyEvent: handler.handleKeyEvent,
      child: const SizedBox.expand(),
    ),
  );
  await t.pump();
  return (state, handler);
}

Future<void> _chord(
  WidgetTester t,
  LogicalKeyboardKey modifier,
  LogicalKeyboardKey key,
) async {
  await t.sendKeyDownEvent(modifier);
  await t.sendKeyEvent(key);
  await t.sendKeyUpEvent(modifier);
  await t.pump();
}

void main() {
  testWidgets('macOS：⌘C、⌘E、⌘S 不切工具，⌘= 放大、Control+= 不放大', (t) async {
    final (state, _) = await _pump(t);
    final tool = state.currentTool?.id;
    await _chord(t, LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyC);
    await _chord(t, LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyE);
    await _chord(t, LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyS);
    expect(state.currentTool?.id, tool);
    await t.sendKeyEvent(LogicalKeyboardKey.keyE);
    expect(state.currentTool?.id, 'eraser');

    final scale = state.canvasController.scale;
    await _chord(t, LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.equal);
    expect(state.canvasController.scale, scale);
    await _chord(t, LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.equal);
    expect(state.canvasController.scale, greaterThan(scale));
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('macOS：Control+[ 和 Control+] 不调笔刷，单按 [ 照常调', (t) async {
    final (state, _) = await _pump(t);
    final size = state.brushSize;
    await _chord(
      t,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.bracketLeft,
    );
    expect(state.brushSize, size);
    await _chord(
      t,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.bracketRight,
    );
    expect(state.brushSize, size);
    await t.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
    expect(state.brushSize, lessThan(size));
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('Windows：照旧 Ctrl+= 放大，Ctrl+E 不切工具', (t) async {
    final (state, _) = await _pump(t);
    final tool = state.currentTool?.id;
    await _chord(t, LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyE);
    expect(state.currentTool?.id, tool);
    final scale = state.canvasController.scale;
    await _chord(t, LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.equal);
    expect(state.canvasController.scale, greaterThan(scale));
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
