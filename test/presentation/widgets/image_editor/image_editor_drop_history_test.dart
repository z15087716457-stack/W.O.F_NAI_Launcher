import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_editor.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/canvas/editor_canvas.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/history_manager.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/image_editor_screen.dart';

import '../../../helpers/app_logger_test_isolation.dart';
import '../../../helpers/studio_capture_fonts.dart';
import '../../ui/refs/refs_test_harness.dart' show refsApp;

void main() {
  setUpAll(() async {
    AppLoggerTestIsolation.setUp();
    await loadStudioCaptureFonts();
  });
  tearDownAll(AppLoggerTestIsolation.tearDown);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final image = img.Image(width: 128, height: 128, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(40, 180, 90, 255));
  final bytes = Uint8List.fromList(img.encodePng(image));

  Future<dynamic> open(WidgetTester t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1600, 1000);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      refsApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ImageEditorScreen(
                  initialSize: Size(128, 128),
                  debugDisableDropRegion: true,
                ),
              ),
            ),
            child: const Text('open-editor'),
          ),
        ),
      ),
    );
    await t.tap(find.text('open-editor'));
    for (
      var i = 0;
      i < 12 && find.byType(EditorCanvas).evaluate().isEmpty;
      i++
    ) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await t.pump(const Duration(milliseconds: 80));
    }
    expect(find.byType(EditorCanvas), findsOneWidget);
    return t.state(find.byType(ImageEditorScreen));
  }

  testWidgets(
    'import participates in undo, redo, stable layer identity and pixels',
    (t) async {
      final dynamic session = await open(t);
      final EditorState state = session.debugEditorState;
      final before = state.layerManager.layers
          .map((layer) => layer.id)
          .toList();
      final previousActive = state.layerManager.activeLayerId;
      await t.runAsync(
        () =>
            session.debugImportDroppedImageLayer('overlay.png', bytes)
                as Future<void>,
      );
      await t.pump();
      final id = state.layerManager.activeLayerId!;
      expect(state.canUndo, isTrue);
      expect(
        t.widget<ToolsEditorPage>(find.byType(ToolsEditorPage)).data.dirty,
        isTrue,
      );
      state.historyManager.execute(
        AddStrokeAction(
          layerId: id,
          stroke: StrokeData(
            points: const [Offset(10, 10)],
            size: 8,
            color: Colors.red,
            opacity: 1,
            hardness: 1,
          ),
        ),
        state,
      );
      state.undo();
      state.undo();
      await t.pump();
      expect(state.layerManager.layers.map((layer) => layer.id), before);
      expect(state.layerManager.activeLayerId, previousActive);
      expect(
        t.widget<ToolsEditorPage>(find.byType(ToolsEditorPage)).data.dirty,
        isFalse,
      );
      state.redo();
      state.redo();
      final restored = state.layerManager.getLayerById(id)!;
      expect(restored.name, 'overlay.png');
      expect(restored.baseImageBytes, bytes);
      expect(restored.strokes, hasLength(1));
      final rgba = await t.runAsync(() => restored.baseImage!.toByteData());
      expect(rgba!.buffer.asUint8List().take(4), [40, 180, 90, 255]);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'back after importing asks to discard and Keep editing retains the layer',
    (t) async {
      final dynamic session = await open(t);
      await t.runAsync(
        () =>
            session.debugImportDroppedImageLayer('overlay.png', bytes)
                as Future<void>,
      );
      await t.pump();
      await t.tap(find.byKey(const Key('tools-editor-back')));
      await t.pump();
      expect(find.byKey(const Key('tools-discard')), findsOneWidget);
      expect(find.byType(ImageEditorScreen), findsOneWidget);
      final dialog = find.byKey(const Key('tools-discard'));
    await t.tap(find.descendant(of: dialog, matching: find.text('继续编辑')));
      await t.pump();
      expect(session.debugLayerNames, contains('overlay.png'));
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets('invalid image does not create a layer or history entry', (
    t,
  ) async {
    final dynamic session = await open(t);
    final EditorState state = session.debugEditorState;
    final count = state.layerManager.layerCount;
    await t.runAsync(
      () =>
          session.debugImportDroppedImageLayer(
                'invalid.png',
                Uint8List.fromList([1, 2, 3]),
              )
              as Future<void>,
    );
    await t.pump();
    expect(state.layerManager.layerCount, count);
    expect(state.canUndo, isFalse);
    await t.pumpWidget(const SizedBox());
  });
}
