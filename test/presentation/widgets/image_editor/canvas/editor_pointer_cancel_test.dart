import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/canvas/editor_canvas.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/input_handler.dart';

import '../../../ui/refs/refs_test_harness.dart' show refsApp;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final tool in ['brush', 'eraser', 'rect_selection']) {
    testWidgets(
      '$tool cancel clears preview and does not commit on the next stroke',
      (t) async {
        final state = EditorState(inpaint: tool != 'rect_selection')
          ..initNewCanvas(const Size(128, 128));
        state.setToolById(tool);
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
        final origin = t.getTopLeft(find.byType(EditorCanvas));
        final gesture = await t.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: origin + const Offset(40, 40));
        await gesture.down(origin + const Offset(40, 40));
        await gesture.moveTo(origin + const Offset(60, 60));
        await t.pump();
        if (tool == 'rect_selection') {
          expect(state.previewPath, isNotNull);
        } else {
          expect(state.isDrawing, isTrue);
        }
        final undoCount = state.historyManager.undoStackSize;
        await gesture.cancel();
        await t.pump();
        expect(state.isDrawing, isFalse);
        expect(state.currentStrokePoints, isEmpty);
        expect(state.previewPath, isNull);
        expect(
          state.layerManager.layers.expand((layer) => layer.strokes),
          isEmpty,
        );
        expect(state.historyManager.undoStackSize, undoCount);
        state.setToolById('brush');
        await gesture.down(origin + const Offset(70, 70));
        await gesture.moveTo(origin + const Offset(80, 80));
        await gesture.up();
        await t.pump();
        expect(
          state.layerManager.layers.expand((layer) => layer.strokes),
          hasLength(1),
        );
        expect(state.canUndo, isTrue);
        await t.pumpWidget(const SizedBox());
        state.dispose();
      },
    );
  }

  for (final mode in ['middle pan', 'space pan', 'brush resize']) {
    testWidgets('cancel releases $mode and allows the next brush stroke', (
      t,
    ) async {
      final state = EditorState(inpaint: true)
        ..initNewCanvas(const Size(128, 128));
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final handler = InputHandler(
        state: state,
        focusNode: focus,
        onStateChanged: () {},
      );
      if (mode == 'brush resize') {
        await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      }
      if (mode == 'space pan') {
        handler.handleKeyEvent(
          focus,
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.space,
            logicalKey: LogicalKeyboardKey.space,
            timeStamp: Duration.zero,
          ),
        );
      }
      handler.handlePointerDown(
        PointerDownEvent(
          position: const Offset(20, 20),
          buttons: mode == 'middle pan' ? kMiddleMouseButton : kPrimaryButton,
        ),
      );
      if (mode == 'space pan') {
        handler.handleScaleStart(
          ScaleStartDetails(focalPoint: const Offset(20, 20)),
        );
      }
      handler.handlePointerCancel();
      expect(handler.gesture.isPrimaryButtonDown, isFalse);
      expect(handler.gesture.isPanning, isFalse);
      expect(handler.gesture.isMiddleButtonPanning, isFalse);
      expect(handler.gesture.isBrushSizeMode, isFalse);
      expect(handler.gesture.lastPanPosition, isNull);
      expect(handler.gesture.brushSizeStartPosition, isNull);
      if (mode == 'brush resize') {
        await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      }
      if (mode == 'space pan') handler.keyboard.isSpacePressed = false;
      handler.handlePointerDown(
        const PointerDownEvent(
          position: Offset(30, 30),
          buttons: kPrimaryButton,
        ),
      );
      handler.handlePointerUp(const PointerUpEvent(position: Offset(30, 30)));
      expect(
        state.layerManager.layers.expand((layer) => layer.strokes),
        hasLength(1),
      );
      state.dispose();
    });
  }

  for (final before in [null, const Rect.fromLTWH(8, 8, 64, 64)]) {
    testWidgets(
      'cancelled focus area restores $before without adding history',
      (t) async {
        final state = EditorState(inpaint: true)
          ..initNewCanvas(const Size(128, 128));
        state.setInpaintFocusRegion(before);
        final tool = state.tools.singleWhere(
          (tool) => tool.id == 'inpaint_focus',
        );
        tool.onPointerDown(
          const PointerDownEvent(position: Offset(25, 25)),
          state,
        );
        tool.onPointerMove(
          const PointerMoveEvent(position: Offset(85, 85)),
          state,
        );
        expect(state.inpaintFocusRegion, isNot(before));
        tool.onPointerCancel(state);
        expect(state.inpaintFocusRegion, before);
        state.dispose();
        expect(state.canUndo, isFalse);
        tool.onPointerMove(
          const PointerMoveEvent(position: Offset(110, 110)),
          state,
        );
        expect(state.inpaintFocusRegion, before);
      },
    );
  }
}
