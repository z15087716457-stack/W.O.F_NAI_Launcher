import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
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

/// Explain real overflow failures without suppressing the framework exception.
String uiuxOverflowDetails(WidgetTester tester) {
  final result = <String>[];
  for (final element in find.byType(Row).evaluate()) {
    final row = element.renderObject;
    if (row is! RenderFlex || !row.hasSize) continue;
    final widths = <String>[];
    var overflow = false;
    for (
      var child = row.firstChild;
      child != null;
      child = (child.parentData! as FlexParentData).nextSibling
    ) {
      if (!child.hasSize) continue;
      final offset = (child.parentData! as FlexParentData).offset;
      widths.add('${child.runtimeType} ${child.size} at $offset');
      if (offset.dx + child.size.width > row.size.width + .1) overflow = true;
    }
    if (overflow) {
      result.add(
        '${element.debugGetCreatorChain(24)} width=${row.size.width} '
        'children=${widths.join("; ")}',
      );
    }
  }
  return result.join('\n');
}
