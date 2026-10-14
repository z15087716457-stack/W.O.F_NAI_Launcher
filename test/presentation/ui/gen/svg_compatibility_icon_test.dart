import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_parts.dart';

void main() {
  const references = {
    'nai-icon-inpaint.svg': 'nai-icon-inpaint',
    'nai-icon-inpaint2.svg': 'nai-icon-inpaint',
    'director_remove_bg.svg': 'director_remove_bg',
    'inpaint_palette.svg': 'inpaint_palette',
  };
  for (final entry in references.entries) {
    for (final dark in [false, true]) {
      testWidgets('${entry.key} preserves browser SVG contour dark=$dark', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(160, 160);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: key,
                  child: ColoredBox(
                    color: dark ? Colors.black : Colors.white,
                    child: SizedBox.square(
                      dimension: 16,
                      child: GenNaiIcon(
                        entry.key,
                        size: 16,
                        color: dark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          // Supersampling exposes misplaced dash boundaries and hollow dots;
          // browser / Flutter edge antialiasing may still differ slightly.
          final actual = await boundary.toImage(pixelRatio: 8);
          final codec = await ui.instantiateImageCodec(
            File(
              'test/presentation/ui/gen/icon_reference/'
              '${entry.value}-browser-128.png',
            ).readAsBytesSync(),
          );
          final reference = (await codec.getNextFrame()).image;
          try {
            expect(actual.width, reference.width);
            expect(actual.height, reference.height);
            final actualBytes = (await actual.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            final referenceBytes = (await reference.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            var delta = 0;
            for (
              var offset = 0;
              offset < actualBytes.lengthInBytes;
              offset += 4
            ) {
              final value = referenceBytes.getUint8(offset);
              delta +=
                  (actualBytes.getUint8(offset) - (dark ? 255 - value : value))
                      .abs();
            }
            // Original dashed rects averaged 5.5–6.2 levels; the original
            // hollow palette dots averaged 2.7. Correct contours are < 1.3.
            expect(delta / (actual.width * actual.height), lessThan(2));
          } finally {
            actual.dispose();
            reference.dispose();
            codec.dispose();
          }
        });
        expect(tester.takeException(), isNull);
      });
    }
  }
}
