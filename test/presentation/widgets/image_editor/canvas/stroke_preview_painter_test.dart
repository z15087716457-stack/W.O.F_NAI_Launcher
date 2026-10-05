import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/canvas/stroke_preview_painter.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';

Future<ByteData> _paintPreview(
  EditorState state, {
  Size size = const Size(48, 48),
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  StrokePreviewPainter(state: state).paint(canvas, size);
  final picture = recorder.endRecording();
  addTearDown(picture.dispose);

  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  addTearDown(image.dispose);

  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  expect(byteData, isNotNull);
  return byteData!;
}

Color _pixelAt(ByteData byteData, int width, int x, int y) {
  final bytes = byteData.buffer.asUint8List();
  final index = (y * width + x) * 4;
  return Color.fromARGB(
    bytes[index + 3],
    bytes[index],
    bytes[index + 1],
    bytes[index + 2],
  );
}

int _alphaByte(Color color) {
  return (color.a * 255).round().clamp(0, 255);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ordinary brush and eraser pixels are rendered in layer order, not duplicated on the overlay',()async {
    final state=EditorState()..setCanvasSize(const Size(48,48));addTearDown(state.dispose);
    state.startStroke(const Offset(24,24));var bytes=await _paintPreview(state);expect(_alphaByte(_pixelAt(bytes,48,24,24)),0);
    state.endStroke();state.setToolById('eraser');state.startStroke(const Offset(24,24));bytes=await _paintPreview(state);expect(_alphaByte(_pixelAt(bytes,48,24,24)),0);
  });

  test('ordinary blur uses real layer pixels, without a tinted overlay', () async {
    final state = EditorState()..setCanvasSize(const Size(48, 48));
    addTearDown(state.dispose);

    state.setToolById('blur');
    state.startStroke(const Offset(24, 24));

    final byteData = await _paintPreview(state);
    final center = _pixelAt(byteData, 48, 24, 24);

    expect(_alphaByte(center),0);
  });

  test('listens to canvas transform changes', () {
    final state = EditorState()..setCanvasSize(const Size(48, 48));
    addTearDown(state.dispose);

    state.startStroke(const Offset(24, 24));
    final painter = StrokePreviewPainter(state: state);

    var repaintCount = 0;
    void onRepaint() {
      repaintCount++;
    }

    painter.addListener(onRepaint);
    addTearDown(() => painter.removeListener(onRepaint));

    state.canvasController.setOffset(const Offset(10, 0));

    expect(repaintCount, 1);
  });

}
