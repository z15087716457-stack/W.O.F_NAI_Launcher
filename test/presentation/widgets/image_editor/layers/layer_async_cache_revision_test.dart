import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/history_manager.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/layers/layer.dart';

ui.Image solid(Color color) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawColor(color, BlendMode.src);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(32, 32);
  picture.dispose();
  return image;
}

StrokeData dot(Color color) => StrokeData(
  points: const [Offset(16, 16)],
  size: 16,
  color: color,
  opacity: 1,
  hardness: 1,
);

Future<List<int>> pixel(Layer layer) async {
  final recorder = ui.PictureRecorder();
  layer.render(Canvas(recorder), const Size(32, 32));
  final picture = recorder.endRecording();
  final image = picture.toImageSync(32, 32);
  picture.dispose();
  final bytes = (await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  ))!.buffer.asUint8List();
  final result = bytes.sublist((16 * 32 + 16) * 4, (16 * 32 + 16) * 4 + 4);
  image.dispose();
  return result;
}

void main() {
  for (final mutation in [
    'clear strokes',
    'remove stroke',
    'append stroke',
    'replace base',
    'clear base',
    'move base',
    'translate content',
  ]) {
    testWidgets('late composite is discarded after $mutation', (t) async {
      await t.runAsync(() async {
        final layer = Layer();
        final isBase = mutation.contains('base');
        if (isBase) {
          layer.setBaseImageFromImage(solid(Colors.red));
        } else {
          layer.addStroke(dot(Colors.red));
          await layer.rasterize(const Size(32, 32));
        }
        final pending = layer.updateCompositeCache(const Size(32, 32));
        switch (mutation) {
          case 'clear strokes':
            layer.clearStrokes();
          case 'remove stroke':
            layer.removeLastStroke();
          case 'append stroke':
            layer.addStroke(dot(Colors.green));
          case 'replace base':
            layer.setBaseImageFromImage(solid(Colors.green));
          case 'clear base':
            layer.clearBaseImage();
          case 'move base':
            layer.setBaseImageOffset(const Offset(32, 0));
          case 'translate content':
            layer.translateContent(const Offset(32, 0));
        }
        final expected = await pixel(layer);
        await pending;
        expect(await pixel(layer), expected);
        expect(layer.compositedCache, isNull);
        await layer.updateCompositeCache(const Size(32, 32));
        expect(await pixel(layer), expected);
        layer.dispose();
      });
    });
  }

  for (final stage in ['raster', 'composite']) {
    testWidgets('dispose during $stage releases the late image', (t) async {
      await t.runAsync(() async {
        final layer = Layer()..addStroke(dot(Colors.red));
        if (stage == 'composite') await layer.rasterize(const Size(32, 32));
        final pending = stage == 'raster'
            ? layer.rasterize(const Size(32, 32))
            : layer.updateCompositeCache(const Size(32, 32));
        layer.dispose();
        await pending;
        expect(layer.rasterizedImage, isNull);
        expect(layer.compositedCache, isNull);
      });
    });
  }

  testWidgets('clear during raster does not publish the removed pixels', (
    t,
  ) async {
    await t.runAsync(() async {
      final layer = Layer()..addStroke(dot(Colors.red));
      final pending = layer.rasterize(const Size(32, 32));
      layer.clearStrokes();
      await pending;
      expect(layer.rasterizedImage, isNull);
      expect((await pixel(layer)).last, 0);
      await layer.updateCompositeCache(const Size(32, 32));
      expect((await pixel(layer)).last, 0);
      layer.dispose();
    });
  });
  testWidgets('clear during incremental raster retires its previous cache', (
    t,
  ) async {
    await t.runAsync(() async {
      final layer = Layer()..addStroke(dot(Colors.red));
      await layer.rasterize(const Size(32, 32));
      layer.addStroke(dot(Colors.green));
      final pending = layer.rasterize(const Size(32, 32));
      layer.clearStrokes();
      await pending;
      await layer.updateCompositeCache(const Size(32, 32));
      expect((await pixel(layer)).last, 0);
      layer.dispose();
    });
  });
}
