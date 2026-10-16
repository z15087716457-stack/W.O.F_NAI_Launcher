import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as pixels;
import 'package:nai_launcher/presentation/ui/kit/ui_preview_image.dart';

Future<void> _load(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final source = MemoryImage(
    Uint8List.fromList(
      pixels.encodePng(
        pixels.Image(width: 2048, height: 3072)
          ..clear(pixels.ColorRgb8(20, 90, 160)),
      ),
    ),
  );
  for (final dpr in [1.0, 1.25, 1.5, 2.0, 3.0]) {
    testWidgets(
      'preview uses physical pixels at DPR $dpr and original stays full size',
      (tester) async {
        tester.view.devicePixelRatio = dpr;
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UiPreviewImage(image: source, width: 100, height: 150),
                  Image(image: source, width: 100, height: 150),
                ],
              ),
            ),
          ),
        );
        await _load(tester);
        final images = tester
            .renderObjectList<RenderImage>(find.byType(RawImage))
            .toList();
        final preview = images.first.image!;
        expect(preview.width, greaterThanOrEqualTo((100 * dpr * 1.5).ceil()));
        expect(preview.height, greaterThanOrEqualTo((150 * dpr * 1.5).ceil()));
        expect(
          preview.width * preview.height * 4,
          lessThan(2048 * 3072 * 4 ~/ 8),
        );
        expect(images.last.image!.width, 2048);
        expect(images.last.image!.height, 3072);
        expect(
          tester.getSize(find.byType(UiPreviewImage)),
          const Size(100, 150),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final size in [const Size(2048, 128), const Size(128, 2048)]) {
    testWidgets('cover keeps enough pixels on both axes for $size', (
      tester,
    ) async {
      final image = MemoryImage(
        Uint8List.fromList(
          pixels.encodePng(
            pixels.Image(
              width: size.width.toInt(),
              height: size.height.toInt(),
            ),
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: UiPreviewImage(image: image, width: 44, height: 58),
          ),
        ),
      );
      await _load(tester);
      final decoded = tester
          .renderObject<RenderImage>(find.byType(RawImage))
          .image!;
      expect(decoded.width, greaterThanOrEqualTo(66));
      expect(decoded.height, greaterThanOrEqualTo(87));
      expect(decoded.width / decoded.height, closeTo(size.aspectRatio, .15));
    });
  }

  testWidgets(
    'small images retain exact pixels; resize buckets share cache entries',
    (tester) async {
      final small = MemoryImage(
        Uint8List.fromList(
          pixels.encodePng(pixels.Image(width: 24, height: 30)),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UiPreviewImage(image: small, width: 100, height: 150),
                UiPreviewImage(image: small, width: 101, height: 151),
              ],
            ),
          ),
        ),
      );
      await _load(tester);
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images[0].image, images[1].image);
      final decoded = tester
          .renderObject<RenderImage>(find.byType(RawImage).first)
          .image!;
      expect(decoded.width, 24);
      expect(decoded.height, 30);
    },
  );

  testWidgets(
    'resize retains its frame while replacing a source keeps normal image policy',
    (tester) async {
      Future<void> pump(ImageProvider image, double width) => tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: UiPreviewImage(image: image, width: width, height: 150),
          ),
        ),
      );
      await pump(source, 100);
      await _load(tester);
      await pump(source, 200);
      expect(tester.widget<Image>(find.byType(Image)).gaplessPlayback, isTrue);
      expect(
        tester.renderObject<RenderImage>(find.byType(RawImage)).image,
        isNotNull,
      );
      await _load(tester);
      final replacement = MemoryImage(
        Uint8List.fromList(
          pixels.encodePng(pixels.Image(width: 24, height: 30)),
        ),
      );
      await pump(replacement, 200);
      expect(tester.widget<Image>(find.byType(Image)).gaplessPlayback, isFalse);
      await _load(tester);
    },
  );

  testWidgets(
    'downsampled cover preserves crop, color and fine structure at screen scale',
    (tester) async {
      final patterned = pixels.Image(width: 1024, height: 1536);
      for (var y = 0; y < patterned.height; y++) {
        for (var x = 0; x < patterned.width; x++) {
          patterned.setPixelRgb(
            x,
            y,
            x ~/ 4,
            y ~/ 6,
            ((x ~/ 64 + y ~/ 64).isEven ? 80 : 160),
          );
        }
      }
      final image = MemoryImage(
        Uint8List.fromList(pixels.encodePng(patterned)),
      );
      final keys = [GlobalKey(), GlobalKey()];
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RepaintBoundary(
                  key: keys[0],
                  child: UiPreviewImage(image: image, width: 100, height: 150),
                ),
                RepaintBoundary(
                  key: keys[1],
                  child: Image(
                    image: image,
                    width: 100,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await _load(tester);
      final frames = <Uint8List>[];
      await tester.runAsync(() async {
        for (final key in keys) {
          final bitmap =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          frames.add(
            (await bitmap.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!.buffer.asUint8List(),
          );
          bitmap.dispose();
        }
      });
      var absoluteError = 0;
      for (var i = 0; i < frames.first.length; i++) {
        absoluteError += (frames[0][i] - frames[1][i]).abs();
      }
      // Average difference stays below one 8-bit color step. No snapshot masks.
      expect(absoluteError / frames.first.length, lessThan(1));
    },
  );
}
