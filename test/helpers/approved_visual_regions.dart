import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Keep the locked prototype PNG intact. Only the user-requested toolbar/avatar
/// regions are excluded; new component tests and captures verify those regions.
/// Everything outside them must still match the original pixels exactly.
Future<void> expectOutsideApprovedRegions(
  WidgetTester tester,
  Finder boundary,
  String baseline,
  List<Rect> regions,
) async {
  final box = tester.renderObject<RenderRepaintBoundary>(boundary);
  final origin = tester.getTopLeft(boundary);
  final masks = regions.map((r) => r.shift(-origin).inflate(2)).toList();
  late Uint8List pixels;
  late int width, height;
  await tester.runAsync(() async {
    final bitmap = await box.toImage(pixelRatio: 1);
    width = bitmap.width;
    height = bitmap.height;
    final data = await bitmap.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    pixels = data!.buffer.asUint8List();
    bitmap.dispose();
  });
  final expected = img.decodePng(File(baseline).readAsBytesSync())!;
  expect(
    Size(width.toDouble(), height.toDouble()),
    Size(expected.width.toDouble(), expected.height.toDouble()),
  );
  final target = expected.getBytes(order: img.ChannelOrder.rgba);
  var changed = 0, excluded = 0;
  Rect? bounds;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final point = Offset(x.toDouble(), y.toDouble());
      final index = (y * width + x) * 4;
      if (masks.any((r) => r.contains(point))) {
        excluded++;
        continue;
      }
      if (pixels[index] != target[index] ||
          pixels[index + 1] != target[index + 1] ||
          pixels[index + 2] != target[index + 2] ||
          pixels[index + 3] != target[index + 3]) {
        changed++;
        final pixel = Rect.fromLTWH(point.dx, point.dy, 1, 1);
        bounds = bounds == null ? pixel : bounds.expandToInclude(pixel);
      }
    }
  }
  // UPDATE_APPROVED_BASELINES=1：用户确认以现状为准时，只覆盖不一致的基准图。
  if (changed > 0 &&
      Platform.environment['UPDATE_APPROVED_BASELINES'] == '1') {
    final actual = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: pixels.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    File(baseline).writeAsBytesSync(img.encodePng(actual));
    return;
  }
  expect(
    changed,
    0,
    reason:
        '$baseline: $changed pixels changed outside approved regions ($excluded pixels); bounds=$bounds',
  );
}
