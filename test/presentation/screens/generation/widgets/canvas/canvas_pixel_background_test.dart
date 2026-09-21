import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_pixel_background.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_controller.dart';

Future<ui.Image> _render(
  CanvasCamera camera, {
  Size size = const Size(640, 560),
  double dpr = 1,
  ThemeData? theme,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(dpr);
  CanvasPixelBackgroundPainter(
    camera: camera,
    theme: theme ?? ThemeData.dark(),
    devicePixelRatio: dpr,
  ).paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (size.width * dpr).round(),
    (size.height * dpr).round(),
  );
  picture.dispose();
  return image;
}

Future<Uint8List> _pixels(CanvasCamera camera, {double dpr = 1}) async {
  final image = await _render(camera, dpr: dpr);
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  return bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'scrolling a whole tile is seamless at negative offsets and zoom',
    () async {
      for (final scale in [0.5, 1.0, 1.375, 3.25]) {
        for (final dpr in [1.0, 1.5]) {
          const offset = Offset(-12005.25, 853.5);
          final initial = await _pixels(
            CanvasCamera(offset: offset, scale: scale),
            dpr: dpr,
          );
          final repeated = await _pixels(
            CanvasCamera(
              offset: offset + Offset(512 * scale, -512 * scale),
              scale: scale,
            ),
            dpr: dpr,
          );
          expect(repeated, initial, reason: 'scale=$scale, dpr=$dpr');
        }
      }
    },
  );

  test('edge-crossing circuits continue across both tile boundaries', () async {
    final pixels = await _pixels(CanvasCamera.init);
    int red(int x, int y) => pixels[(y * 640 + x) * 4];
    expect(red(511, 504), greaterThan(25));
    expect(red(0, 504), red(511, 504));
    expect(red(20, 511), greaterThan(25));
    expect(red(20, 0), red(20, 511));

    var marked = 0;
    for (var i = 0; i < pixels.length; i += 4) {
      if (pixels[i] != 25) marked++;
      expect(pixels[i + 3], 255);
    }
    expect(marked / (640 * 560), inExclusiveRange(0.002, 0.04));
  });

  test(
    'one-pixel pan translates the artwork without changing its layout',
    () async {
      final initial = await _pixels(CanvasCamera.init);
      final moved = await _pixels(
        const CanvasCamera(offset: Offset(0, 1), scale: 1),
      );
      expect(
        moved.sublist(640 * 4),
        initial.sublist(0, initial.length - 640 * 4),
      );
    },
  );

  test(
    'overview zoom fades fine details and light themes retain a light base',
    () async {
      final pixels = await _pixels(
        const CanvasCamera(offset: Offset(-12, -7), scale: 0.1),
      );
      expect(pixels.toSet(), {25, 255});
      final image = await _render(
        const CanvasCamera(offset: Offset.zero, scale: 0.1),
        theme: ThemeData.light().copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
          ).copyWith(surface: const Color(0xFFF7F7F7)),
        ),
      );
      final light = (await image.toByteData())!.buffer.asUint8List();
      image.dispose();
      expect(light.toSet(), {247, 255});
    },
  );

  test('captures approved dark pattern and zoomed edge detail', () async {
    if (Platform.environment['CAPTURE_OFFICIAL_UI'] != '1') return;
    for (final (name, camera) in [
      ('pixel-circuit', const CanvasCamera(offset: Offset(-48, -72), scale: 1)),
      (
        'pixel-circuit-zoom',
        const CanvasCamera(offset: Offset(-680, -708), scale: 1.375),
      ),
    ]) {
      final image = await _render(camera, size: const Size(1024, 640));
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('.dart_tool/brand-background-captures/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    }
  });
}
