import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/inpaint_outpaint_utils.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/edit_image_actions.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/canvas/layer_painter.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/layers/layer.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/tools/clone_stamp_tool.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/tools/color_picker_tool.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/panels/edit_hsv_panel.dart';

ui.Image sample({Color color = const Color(0xffff0000)}) {
  final recorder = ui.PictureRecorder(), c = Canvas(recorder);
  c.drawRect(
    const Rect.fromLTWH(0, 0, 128, 128),
    Paint()..color = Colors.white,
  );
  c.drawRect(const Rect.fromLTWH(8, 8, 24, 24), Paint()..color = color);
  final picture = recorder.endRecording(),
      image = picture.toImageSync(128, 128);
  picture.dispose();
  return image;
}

Future<Uint8List> pixels(EditorState state, {Layer? layer}) async {
  final image = renderEditLayer(
    layer ?? state.layerManager.activeLayer!,
    state.canvasSize,
  );
  try {
    return (await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    ))!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

List<int> pixel(Uint8List bytes, int x, int y, {int width = 128}) =>
    bytes.sublist((y * width + x) * 4, (y * width + x) * 4 + 4);
EditorState setup() {
  final state = EditorState();
  state.initNewCanvas(const Size(128, 128));
  state.canvasController.setViewportSize(const Size(128, 128));
  state.layerManager.activeLayer!.setBaseImageSync(sample(), null);
  return state;
}

void tap(
  EditorState state,
  Offset p, {
  ui.PointerDeviceKind kind = ui.PointerDeviceKind.mouse,
  double pressure = 1,
}) {
  state.currentTool!.onPointerDown(
    PointerDownEvent(position: p, kind: kind, pressure: pressure),
    state,
  );
  state.currentTool!.onPointerUp(
    PointerUpEvent(position: p, kind: kind),
    state,
  );
}

Future<Uint8List> visiblePixels(EditorState state) async {
  final recorder = ui.PictureRecorder();
  LayerPainter(
    state: state,
    showTransparentCanvasBackground: true,
  ).paint(Canvas(recorder), state.canvasSize);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(128, 128);
  picture.dispose();
  try {
    return (await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    ))!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'picker samples one composite pixel, returns to Draw and protects later color edits',
    (tester) async {
      final s = setup();
      s.setToolById('color_picker');
      await tester.runAsync(() async {
        tap(s, const Offset(20, 20));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      expect(s.foregroundColor, const Color(0xffff0000));
      expect(s.currentTool!.id, 'brush');
      final c = await tester.runAsync(
        () => ColorPickerTool.pickColorAt(const Offset(40, 20), s),
      );
      expect(c, Colors.white);
      s.setToolById('color_picker');
      await tester.runAsync(() async {
        tap(s, const Offset(20, 20));
        s.setForegroundColor(const Color(0xff0000ff));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      expect(s.foregroundColor, const Color(0xff0000ff));
      s.dispose();
      await tester.pump(const Duration(milliseconds: 200));
    },
  );

  for (final toolId in ['brush', 'eraser', 'blur', 'clone_stamp']) {
    testWidgets(
      '$toolId live pixels match commit and do not change history while dragging',
      (tester) async {
        final s = setup();
        s.setToolById(toolId);
        s.setBrushSize(20);
        s.setForegroundColor(const Color(0xff0000ff));
        if (toolId == 'clone_stamp') {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
          tap(s, const Offset(20, 20));
          await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        }
        final original = await tester.runAsync(() => pixels(s));
        final p = toolId == 'blur'
            ? const Offset(32, 20)
            : const Offset(70, 70);
        s.currentTool!.onPointerDown(PointerDownEvent(position: p), s);
        s.currentTool!.onPointerMove(
          PointerMoveEvent(position: p + const Offset(0, 8)),
          s,
        );
        final live = await tester.runAsync(() => visiblePixels(s));
        final unchanged = await tester.runAsync(() => pixels(s));
        expect(unchanged, original);
        expect(s.historyManager.canUndo, false);
        s.currentTool!.onPointerUp(
          PointerUpEvent(position: p + const Offset(0, 8)),
          s,
        );
        final committed = await tester.runAsync(() => visiblePixels(s));
        expect(committed, live);
        expect(s.historyManager.canUndo, true);
        s.undo();
        expect(await tester.runAsync(() => pixels(s)), original);
        s.dispose();
        await tester.pump(const Duration(milliseconds: 200));
      },
    );
  }
  testWidgets(
    'upper layers cover the active drawing preview and committed pixels',
    (tester) async {
      final s = setup(), base = s.layerManager.activeLayer!;
      final upper = s.layerManager.addLayer();
      final rec = ui.PictureRecorder();
      Canvas(rec).drawRect(
        const Rect.fromLTWH(0, 0, 128, 128),
        Paint()..color = const Color(0xff00ff00),
      );
      final pic = rec.endRecording();
      upper.setBaseImageSync(pic.toImageSync(128, 128), null);
      pic.dispose();
      s.layerManager.setActiveLayer(base.id);
      s.setForegroundColor(const Color(0xff0000ff));
      s.currentTool!.onPointerDown(
        const PointerDownEvent(position: Offset(70, 70)),
        s,
      );
      var b = await tester.runAsync(() => visiblePixels(s));
      expect(pixel(b!, 70, 70), [0, 255, 0, 255]);
      s.currentTool!.onPointerUp(
        const PointerUpEvent(position: Offset(70, 70)),
        s,
      );
      b = await tester.runAsync(() => visiblePixels(s));
      expect(pixel(b!, 70, 70), [0, 255, 0, 255]);
      s.dispose();
      await tester.pump(const Duration(milliseconds: 200));
    },
  );

  testWidgets(
    'draw pressure, soft/square tips and erase preserve real pixels and undo',
    (tester) async {
      final s = setup();
      s.setForegroundColor(const Color(0xff0000ff));
      s.setBrushSize(20);
      tap(
        s,
        const Offset(60, 60),
        kind: ui.PointerDeviceKind.stylus,
        pressure: .25,
      );
      var b = await tester.runAsync(() => pixels(s));
      expect(pixel(b!, 60, 60), [0, 0, 255, 255]);
      expect(pixel(b, 65, 60), [255, 255, 255, 255]);
      s.undo();
      s.setBrushTip(EditorBrushTip.square);
      tap(s, const Offset(60, 60));
      b = await tester.runAsync(() => pixels(s));
      expect(pixel(b!, 68, 68), [0, 0, 255, 255]);
      s.undo();
      s.setBrushTip(EditorBrushTip.softRound);
      tap(s, const Offset(60, 60));
      b = await tester.runAsync(() => pixels(s));
      final soft = pixel(b!, 66, 60);
      expect(soft[0], greaterThan(0));
      expect(soft[0], lessThan(255));
      s.undo();
      s.setToolById('eraser');
      s.setBrushTip(EditorBrushTip.round);
      tap(s, const Offset(20, 20));
      b = await tester.runAsync(() => pixels(s));
      expect(pixel(b!, 20, 20)[3], 0);
      s.undo();
      b = await tester.runAsync(() => pixels(s));
      expect(pixel(b!, 20, 20), [255, 0, 0, 255]);
      s.dispose();
      await tester.pump(const Duration(milliseconds: 200));
    },
  );
  testWidgets(
    'fill stays inside a contiguous region, uses official tolerance and undoes',
    (tester) async {
      final s = setup();
      s.setToolById('fill');
      s.setForegroundColor(const Color(0xff00ff00));
      await tester.runAsync(() async {
        tap(s, const Offset(15, 15));
        for (var i = 0; i < 50 && !s.historyManager.canUndo; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      final b = await tester.runAsync(() => pixels(s));
      expect(pixel(b!, 20, 20), [0, 255, 0, 255]);
      expect(pixel(b, 40, 20), [255, 255, 255, 255]);
      s.undo();
      final before = await tester.runAsync(() => pixels(s));
      expect(pixel(before!, 20, 20), [255, 0, 0, 255]);
      s.dispose();
      await tester.pump(const Duration(milliseconds: 200));
    },
  );
  testWidgets(
    'selection moves and scales pixels, cancel/undo preserve complete source',
    (tester) async {
      final s = setup();
      final original = await tester.runAsync(() => pixels(s));
      s.setSelection(Path()..addRect(const Rect.fromLTWH(8, 8, 24, 24)));
      expect(s.editSelection.pointerDown(const Offset(20, 20)), true);
      s.editSelection.pointerMove(const Offset(70, 70));
      s.editSelection.pointerUp();
      s.editSelection.commit();
      var b = await tester.runAsync(() => pixels(s));
      expect(pixel(b!, 20, 20)[3], 0);
      expect(pixel(b, 70, 70), [255, 0, 0, 255]);
      s.undo();
      b = await tester.runAsync(() => pixels(s));
      expect(b, original);
      s.setSelection(Path()..addRect(const Rect.fromLTWH(8, 8, 24, 24)));
      s.editSelection.pointerDown(const Offset(32, 32));
      s.editSelection.pointerMove(const Offset(56, 56));
      s.editSelection.pointerUp();
      s.editSelection.commit();
      b = await tester.runAsync(() => pixels(s));
      expect(pixel(b!, 48, 48), [255, 0, 0, 255]);
      s.undo();
      s.setSelection(Path()..addRect(const Rect.fromLTWH(8, 8, 24, 24)));
      s.editSelection.pointerDown(const Offset(20, 20));
      s.editSelection.pointerMove(const Offset(70, 70));
      s.editSelection.cancel();
      b = await tester.runAsync(() => pixels(s));
      expect(b, original);
      s.dispose();
      await tester.pump(const Duration(milliseconds: 200));
    },
  );
  testWidgets(
    'lasso extracts only its path; copy/cut to layer have atomic undo',
    (tester) async {
      final s = setup();
      final base = s.layerManager.activeLayer!;
      final triangle = Path()
        ..moveTo(8, 8)
        ..lineTo(32, 8)
        ..lineTo(8, 32)
        ..close();
      s.setSelection(triangle);
      s.editSelection.copyToLayer(cut: true);
      expect(s.layerManager.layerCount, 2);
      var b = await tester.runAsync(() => pixels(s));
      expect(pixel(b!, 10, 10), [255, 0, 0, 255]);
      expect(pixel(b, 30, 30)[3], 0);
      b = await tester.runAsync(() => pixels(s, layer: base));
      expect(pixel(b!, 10, 10)[3], 0);
      expect(pixel(b, 30, 30), [255, 0, 0, 255]);
      s.undo();
      expect(s.layerManager.layerCount, 1);
      b = await tester.runAsync(() => pixels(s));
      expect(pixel(b!, 10, 10), [255, 0, 0, 255]);
      s.redo();
      expect(s.layerManager.layerCount, 2);
      s.dispose();
      await tester.pump(const Duration(milliseconds: 200));
    },
  );
  testWidgets('resize pads transparency and cropped pixels survive undo/redo', (
    tester,
  ) async {
    final s = setup();
    final original = await tester.runAsync(() => pixels(s));
    s.historyManager.execute(
      ShiftEditCanvasAction(
        delta: const OutpaintFrameDelta(left: 64, right: -64),
      ),
      s,
    );
    var b = await tester.runAsync(() => pixels(s));
    expect(pixel(b!, 20, 20)[3], 0);
    expect(pixel(b, 84, 20), [255, 0, 0, 255]);
    s.undo();
    b = await tester.runAsync(() => pixels(s));
    expect(b, original);
    s.redo();
    b = await tester.runAsync(() => pixels(s));
    expect(pixel(b!, 84, 20), [255, 0, 0, 255]);
    s.dispose();
    await tester.pump(const Duration(milliseconds: 200));
  });
  testWidgets(
    'clone uses selected source pixels; blur modifies an edge and undo restores it',
    (tester) async {
      final s = setup();
      s.setToolById('clone_stamp');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      tap(s, const Offset(20, 20));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      tap(s, const Offset(70, 70));
      var b = await tester.runAsync(() => pixels(s));
      expect(pixel(b!, 70, 70), [255, 0, 0, 255]);
      s.undo();
      final original = await tester.runAsync(() => pixels(s));
      s.setToolById('blur');
      tap(s, const Offset(32, 20));
      b = await tester.runAsync(() => pixels(s));
      expect(pixel(b!, 32, 20)[1], lessThan(255));
      s.undo();
      b = await tester.runAsync(() => pixels(s));
      expect(b, original);
      expect((s.currentTool is CloneStampTool), false);
      s.dispose();
      await tester.pump(const Duration(milliseconds: 200));
    },
  );
  test(
    'HSV matches hue shift and multiplicative S/V gains; alpha stays intact',
    () {
      final b = adjustEditHsv({
        'bytes': Uint8List.fromList([255, 0, 0, 123, 4, 5, 6, 0]),
        'hue': 120.0,
        'saturation': 0.0,
        'brightness': 0.0,
      });
      expect(b, [0, 255, 0, 123, 4, 5, 6, 0]);
      final dark = adjustEditHsv({
        'bytes': Uint8List.fromList([255, 0, 0, 255]),
        'hue': 0.0,
        'saturation': -100.0,
        'brightness': -50.0,
      });
      expect(dark, [128, 128, 128, 255]);
    },
  );
}
