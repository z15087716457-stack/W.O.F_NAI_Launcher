import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_contract.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_editor.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/canvas/editor_canvas.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/image_editor_screen.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/history_manager.dart';
import 'package:nai_launcher/presentation/wiring/tools_editor_layer_actions.dart';
import '../../ui/refs/refs_test_harness.dart' show refsApp;
import '../../../helpers/studio_capture_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadStudioCaptureFonts);
  for (final merge in [false, true]) {
    test(
      'raster ${merge ? 'merge' : 'duplicate'} redo keeps pixels and later stroke identity',
      () async {
        SharedPreferences.setMockInitialValues({});
        final state = EditorState()..initNewCanvas(const Size(32, 32));
        ui.Image solid(Color color) {
          final recorder = ui.PictureRecorder();
          Canvas(recorder).drawColor(color, BlendMode.src);
          final picture = recorder.endRecording();
          final image = picture.toImageSync(32, 32);
          picture.dispose();
          return image;
        }

        final bottom = state.layerManager.activeLayer!;
        bottom.setBaseImageSync(solid(Colors.red), Uint8List.fromList([1]));
        final top = state.layerManager.addLayer(name: 'green');
        top.setBaseImageSync(solid(Colors.green), Uint8List.fromList([2]));
        top.setBaseImageOffset(const Offset(3, 4));
        state.historyManager.execute(
          ToolsEditorLayerAction((state) {
            if (merge) {
              toolsMergeLayers(state, top, bottom);
            } else {
              toolsDuplicateLayer(state, top);
            }
          }, description: 'Raster layer operation'),
          state,
        );
        final id = state.layerManager.activeLayerId!;
        final expected = await state.layerManager.activeLayer!.baseImage!
            .toByteData();
        final offset = state.layerManager.activeLayer!.baseImageOffset;
        state.historyManager.execute(
          AddStrokeAction(
            layerId: id,
            stroke: StrokeData(
              points: const [Offset(10, 10)],
              size: 4,
              color: Colors.blue,
              opacity: 1,
              hardness: 1,
            ),
          ),
          state,
        );
        state.undo();
        state.undo();
        state.redo();
        state.redo();
        final restored = state.layerManager.getLayerById(id)!;
        expect(restored.strokes, hasLength(1));
        expect(restored.baseImageOffset, offset);
        expect(
          (await restored.baseImage!.toByteData())!.buffer.asUint8List(),
          expected!.buffer.asUint8List(),
        );
        state.dispose();
      },
    );
  }
  for (final operation in ToolsLayerAction.values) {
    testWidgets('layer $operation survives repeated undo and redo', (t) async {
      SharedPreferences.setMockInitialValues({});
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(1600, 1000);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        refsApp(
          const ImageEditorScreen(
            initialSize: Size(128, 128),
            debugDisableDropRegion: true,
          ),
        ),
      );
      for (
        var i = 0;
        i < 12 && find.byType(EditorCanvas).evaluate().isEmpty;
        i++
      ) {
        await t.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 25));
        });
        await t.pump(const Duration(milliseconds: 80));
      }
      expect(find.byType(EditorCanvas), findsOneWidget);
      final dynamic session = t.state(find.byType(ImageEditorScreen));
      final dynamic editor = session.debugEditorState;
      ToolsEditorActions actions() =>
          t.widget<ToolsEditorPage>(find.byType(ToolsEditorPage)).actions;
      actions().onAddLayer();
      await t.pump();
      final String middleId = editor.layerManager.activeLayer.id;
      editor.layerManager.renameLayer(middleId, 'audit-middle');
      actions().onAddLayer();
      await t.pump();
      final String topId = editor.layerManager.activeLayer.id;
      editor.layerManager.renameLayer(topId, 'audit-top');
      List<String> order() => List<String>.from(
        editor.layerManager.layers.map((dynamic layer) => layer.id),
      );
      final before = order();
      final dynamic originalTop = editor.layerManager.getLayerById(topId);
      final targetId = operation == ToolsLayerAction.up ? middleId : topId;
      actions().onLayerAction(targetId, operation);
      await t.pump();
      final afterFirst = order();
      expect(afterFirst, isNot(before));
      final activeAfter = editor.layerManager.activeLayerId;
      actions().onUndo();
      await t.pump();
      expect(order(), before);
      expect(
        identical(editor.layerManager.getLayerById(topId), originalTop),
        isFalse,
      );
      expect(
        t.widget<ToolsEditorPage>(find.byType(ToolsEditorPage)).data.canRedo,
        isTrue,
      );
      actions().onRedo();
      await t.pump();
      expect(order(), afterFirst);
      expect(editor.layerManager.activeLayerId, activeAfter);
      actions().onUndo();
      await t.pump();
      expect(order(), before);
      actions().onRedo();
      await t.pump();
      expect(order(), afterFirst);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
    });
  }
}
