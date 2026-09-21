import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
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
    theme: theme ?? GeistTheme.dark,
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
    'scrolling across chunks preserves shared pixels at negative offsets and zoom',
    () async {
      for (final scale in [0.5, 1.0, 1.375, 3.25]) {
        for (final dpr in [1.0, 1.5]) {
          const offset = Offset(-12005.25, 853.5);
          final initial = await _pixels(
            CanvasCamera(offset: offset, scale: scale),
            dpr: dpr,
          );
          final moved = await _pixels(
            CanvasCamera(offset: offset + const Offset(64, 80), scale: scale),
            dpr: dpr,
          );
          final width = (640 * dpr).round();
          final height = (560 * dpr).round();
          final dx = (64 * dpr).round();
          final dy = (80 * dpr).round();
          final originalCrop = BytesBuilder();
          final movedCrop = BytesBuilder();
          for (var y = 2; y < height - dy - 2; y++) {
            originalCrop.add(
              initial.sublist(
                (y * width + 2) * 4,
                (y * width + width - dx - 2) * 4,
              ),
            );
            movedCrop.add(
              moved.sublist(
                ((y + dy) * width + dx + 2) * 4,
                ((y + dy) * width + width - 2) * 4,
              ),
            );
          }
          expect(
            movedCrop.takeBytes(),
            originalCrop.takeBytes(),
            reason: 'scale=$scale, dpr=$dpr',
          );
        }
      }
    },
  );

  test(
    'layout is sparse and no longer repeats every 512 world pixels',
    () async {
      final pixels = await _pixels(CanvasCamera.init);
      for (final offset in [
        const Offset(512, 0),
        const Offset(0, 512),
        const Offset(640, 640),
      ]) {
        final shifted = await _pixels(CanvasCamera(offset: offset, scale: 1));
        expect(shifted, isNot(orderedEquals(pixels)));
      }

      var marked = 0;
      for (var i = 0; i < pixels.length; i += 4) {
        if (pixels[i] != 0) marked++;
        expect(pixels[i + 3], 255);
      }
      expect(marked / (640 * 560), inExclusiveRange(0.002, 0.04));
    },
  );

  test(
    'returning from distant canvas regions restores the same arrangement',
    () async {
      const camera = CanvasCamera(offset: Offset(315, -701), scale: 0.5);
      final before = await _pixels(camera);
      for (var index = 0; index < 20; index++) {
        await _pixels(
          CanvasCamera(
            offset: Offset(index * 12000 + 30000, -index * 9000 - 30000),
            scale: 0.5,
          ),
        );
      }
      expect(await _pixels(camera), before);
    },
  );

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
      expect(pixels.toSet(), {0, 255});
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

  test('captures scattered pattern at wide and portrait sizes', () async {
    if (Platform.environment['CAPTURE_OFFICIAL_UI'] != '1') return;
    for (final (name, camera, size) in [
      (
        'pixel-scatter-wide',
        const CanvasCamera(offset: Offset(-48, -72), scale: 1),
        const Size(1440, 900),
      ),
      (
        'pixel-scatter-portrait',
        const CanvasCamera(offset: Offset(-680, -708), scale: 0.8125),
        const Size(1040, 1240),
      ),
    ]) {
      final image = await _render(camera, size: size);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('.dart_tool/pixel-scatter-captures/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    }
  });
}
