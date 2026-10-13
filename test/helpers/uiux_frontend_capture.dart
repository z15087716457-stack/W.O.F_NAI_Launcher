import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Optional native widget captures; generated files stay outside the repository.
Future<void> captureUiuxRegion(
  WidgetTester tester,
  Finder boundary,
  String name,
  Rect region,
) async {
  final directory = Platform.environment['UIUX_FRONTEND_CAPTURE_DIR'];
  if (directory == null) return;
  await tester.runAsync(() async {
    final box = tester.renderObject<RenderRepaintBoundary>(boundary);
    final original = await box.toImage(pixelRatio: 1);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImage(original, -region.topLeft, ui.Paint());
    final picture = recorder.endRecording();
    final crop = await picture.toImage(
      region.width.ceil(),
      region.height.ceil(),
    );
    final bytes = await crop.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$directory/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    crop.dispose();
    picture.dispose();
    original.dispose();
  });
}
