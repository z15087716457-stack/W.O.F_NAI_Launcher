import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/history_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('focus moves, resizes, clears and undoes on the mask grid', () {
    final state = EditorState(inpaint: true);
    final tool = state.tools.singleWhere((tool) => tool.id == 'inpaint_focus');
    tool.onPointerDown(const PointerDownEvent(position: Offset.zero), state);
    tool.onPointerMove(
      const PointerMoveEvent(position: Offset(1024, 1024)),
      state,
    );
    tool.onPointerUp(const PointerUpEvent(), state);
    expect(state.inpaintFocusRegion, const Rect.fromLTWH(0, 0, 768, 768));
    tool.onPointerDown(
      const PointerDownEvent(position: Offset(768, 768)),
      state,
    );
    tool.onPointerMove(
      const PointerMoveEvent(position: Offset(640, 512)),
      state,
    );
    tool.onPointerUp(const PointerUpEvent(), state);
    expect(state.inpaintFocusRegion, const Rect.fromLTWH(0, 0, 640, 512));
    state.undo();
    expect(state.inpaintFocusRegion, const Rect.fromLTWH(0, 0, 768, 768));
    state.undo();
    expect(state.inpaintFocusRegion, isNull);
    state.redo();
    expect(state.inpaintFocusRegion, const Rect.fromLTWH(0, 0, 768, 768));
    tool.onPointerDown(
      const PointerDownEvent(position: Offset(512, 512)),
      state,
    );
    tool.onPointerMove(
      const PointerMoveEvent(position: Offset(576, 576)),
      state,
    );
    tool.onPointerUp(const PointerUpEvent(), state);
    expect(state.inpaintFocusRegion, const Rect.fromLTWH(64, 64, 768, 768));
    state.historyManager.execute(ClearInpaintMasksAction(), state);
    expect(state.inpaintFocusRegion, isNull);
    state.undo();
    expect(state.inpaintFocusRegion, const Rect.fromLTWH(64, 64, 768, 768));
    state.dispose();
  });
  test('mask layer redo preserves identity and later stroke actions', () {
    final state = EditorState(inpaint: true);
    state.historyManager.execute(
      AddInpaintMaskLayerAction(name: 'mask'),
      state,
    );
    final id = state.layerManager.activeLayerId!;
    final stroke = StrokeData(
      points: const [Offset(30, 30)],
      size: 32,
      color: Colors.white,
      opacity: 1,
      hardness: 1,
    );
    state.historyManager.execute(
      AddStrokeAction(layerId: id, stroke: stroke),
      state,
    );
    state.undo();
    state.undo();
    state.redo();
    state.redo();
    expect(state.layerManager.activeLayerId, id);
    expect(state.layerManager.activeLayer!.inpaintMask, isTrue);
    expect(state.layerManager.activeLayer!.strokes, hasLength(1));
    state.historyManager.execute(DeleteInpaintLayerAction(layerId: id), state);
    state.undo();
    expect(state.layerManager.getLayerById(id)!.inpaintMask, isTrue);
    state.historyManager.execute(ClearInpaintMasksAction(), state);
    expect(state.layerManager.getLayerById(id)!.strokes, isEmpty);
    state.undo();
    expect(state.layerManager.getLayerById(id)!.strokes, hasLength(1));
    state.setBrushSize(1600);
    expect(state.brushSize, 1600);
    state.dispose();
  });
}
