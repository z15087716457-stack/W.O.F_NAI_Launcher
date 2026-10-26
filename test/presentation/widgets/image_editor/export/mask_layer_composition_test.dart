import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/utils/inpaint_mask_utils.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/history_manager.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/export/image_exporter_new.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/layers/layer_manager.dart';

Uint8List _solid(int width, int height, int value) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(value, value, value, 255));
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final cpu in [false, true]) {
    for (final square in [false, true]) {
      testWidgets(
        'eraser clears its own layer and reveals the lower mask; cpu=$cpu square=$square',
        (tester) async {
          await tester.runAsync(() async {
            final manager = LayerManager();
            try {
              final lower = manager.addLayer();
              await lower.setBaseImage(_solid(4, 8, 255));
              final upper = manager.addLayer();
              await upper.setBaseImage(_solid(8, 8, 255));
              upper.addStroke(
                StrokeData(
                  points: const [Offset(2, 4), Offset(6, 4)],
                  size: 2,
                  color: Colors.white,
                  opacity: 1,
                  hardness: 1,
                  square: square,
                  isEraser: true,
                ),
              );

              final recorder = ui.PictureRecorder();
              final canvas = Canvas(recorder);
              for (final layer in manager.layers) {
                layer.render(canvas, const Size(8, 8));
              }
              final picture = recorder.endRecording();
              final preview = await picture.toImage(8, 8);
              picture.dispose();
              final previewBytes = await preview.toByteData(
                format: ui.ImageByteFormat.png,
              );
              preview.dispose();
              final expected = img.decodePng(
                InpaintMaskUtils.normalizeMaskBytes(
                  previewBytes!.buffer.asUint8List(),
                ),
              )!;
              final exported = img.decodePng(
                await ImageExporterNew.exportMaskFromLayers(
                  manager,
                  const Size(8, 8),
                  forceHardEdges: true,
                  preferCpuHardEdgeExport: cpu,
                ),
              )!;
              expect(expected.getPixel(3, 4).r, 255);
              expect(expected.getPixel(5, 4).r, 0);
              for (final point in [(3, 4), (5, 4), (0, 0), (7, 7)]) {
                expect(
                  exported.getPixel(point.$1, point.$2).r,
                  expected.getPixel(point.$1, point.$2).r,
                  reason: 'pixel $point',
                );
              }
            } finally {
              manager.dispose();
            }
          });
        },
      );
    }

    testWidgets('an eraser-only layer leaves lower pixels intact; cpu=$cpu', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final manager = LayerManager();
        try {
          await manager.addLayer().setBaseImage(_solid(8, 8, 255));
          manager.addLayer().addStroke(
            StrokeData(
              points: const [Offset(4, 4)],
              size: 4,
              color: Colors.white,
              opacity: 1,
              hardness: 1,
              isEraser: true,
            ),
          );
          final exported = img.decodePng(
            await ImageExporterNew.exportMaskFromLayers(
              manager,
              const Size(8, 8),
              forceHardEdges: true,
              preferCpuHardEdgeExport: cpu,
            ),
          )!;
          expect(exported.getPixel(4, 4).r, 255);
          expect(exported.getPixel(0, 0).r, 255);
          if (cpu) {
            final raster =
                await ImageExporterNew.tryExportHardEdgeMaskRasterFromLayers(
                  manager,
                  const Size(8, 8),
                );
            expect(raster!.mask[4 * 8 + 4], 1);
          }
        } finally {
          manager.dispose();
        }
      });
    });

    testWidgets(
      'opaque black still covers lower pixels while an eraser reveals them; cpu=$cpu',
      (tester) async {
        await tester.runAsync(() async {
          final manager = LayerManager();
          try {
            await manager.addLayer().setBaseImage(_solid(8, 8, 255));
            final upper = manager.addLayer();
            await upper.setBaseImage(_solid(8, 8, 0));
            upper.addStroke(
              StrokeData(
                points: const [Offset(4, 4)],
                size: 2,
                color: Colors.white,
                opacity: 1,
                hardness: 1,
                isEraser: true,
              ),
            );
            final exported = img.decodePng(
              await ImageExporterNew.exportMaskFromLayers(
                manager,
                const Size(8, 8),
                forceHardEdges: true,
                preferCpuHardEdgeExport: cpu,
                additionalMaskRects: const [Rect.fromLTWH(0, 0, 1, 1)],
              ),
            )!;
            expect(exported.getPixel(4, 4).r, 255);
            expect(exported.getPixel(1, 1).r, 0);
            expect(exported.getPixel(0, 0).r, 255);
          } finally {
            manager.dispose();
          }
        });
      },
    );
  }
}
