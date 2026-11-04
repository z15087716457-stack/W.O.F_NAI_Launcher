// 图像编辑器的选区蚂蚁线：只在画面上有蚂蚁线（框选中、或有选区）时转；没有选区时
// 编辑器开着也不再按刷新率一直要帧。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/canvas/editor_canvas.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ui/refs/refs_test_harness.dart' show refsApp;

Future<EditorState> _pumpEditor(WidgetTester t, {required bool inpaint}) async {
  final state = EditorState(inpaint: inpaint)
    ..initNewCanvas(const Size(128, 128));
  addTearDown(state.dispose);
  await t.pumpWidget(
    refsApp(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 256,
          height: 256,
          child: EditorCanvas(state: state),
        ),
      ),
    ),
  );
  await t.pump();
  return state;
}

/// 编辑器开着、什么都不做的时候还要不要帧。
Future<bool> _idleFrames(WidgetTester t) async {
  await t.pump(const Duration(milliseconds: 600));
  await t.pump(const Duration(milliseconds: 600));
  return t.binding.transientCallbackCount > 0 || t.binding.hasScheduledFrame;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final inpaint in [true, false]) {
    testWidgets('没有选区时不转，有选区才转，清掉又停 inpaint=$inpaint', (t) async {
      final state = await _pumpEditor(t, inpaint: inpaint);
      expect(await _idleFrames(t), isFalse, reason: '刚打开、没有选区');

      state.selectionManager.setSelection(
        Path()..addRect(const Rect.fromLTWH(10, 10, 40, 30)),
        saveHistory: false,
      );
      await t.pump();
      expect(t.binding.transientCallbackCount, greaterThan(0), reason: '蚂蚁线在走');

      state.selectionManager.clearSelection(saveHistory: false);
      await t.pump();
      await t.pump();
      expect(await _idleFrames(t), isFalse, reason: '选区清掉以后');
    });
  }

  testWidgets('框选拖动中（预览选区）也转，松手取消后停', (t) async {
    final state = await _pumpEditor(t, inpaint: true);
    state.selectionManager.setPreviewPath(
      Path()..addRect(const Rect.fromLTWH(5, 5, 20, 20)),
    );
    await t.pump();
    expect(t.binding.transientCallbackCount, greaterThan(0));

    state.selectionManager.clearPreview();
    await t.pump();
    await t.pump();
    expect(await _idleFrames(t), isFalse);
  });
}
