import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Geometric oracle for the archived official variations.d35c8a3a.svg.
/// The source's 3-unit centered strokes are masked to each rectangle, leaving
/// 1.5 units inside. Drawing those regions independently catches mask overflow.
class _OfficialVariationsGeometry extends CustomPainter {
  const _OfficialVariationsGeometry(this.ink);
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 18, size.height / 19);
    canvas.translate(
      (size.width - 18 * scale) / 2,
      (size.height - 19 * scale) / 2,
    );
    canvas.scale(scale);
    final paint = Paint()..color = ink;
    for (final bounds in [
      const Rect.fromLTWH(.5, 0, 8.22222, 8.22222),
      const Rect.fromLTWH(10.3672, 1.64453, 6.57778, 6.57778),
      const Rect.fromLTWH(.5, 9.8667, 8.22222, 8.22222),
    ]) {
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRRect(RRect.fromRectAndRadius(bounds, const Radius.circular(1)))
          ..addRect(bounds.deflate(1.5)),
        paint,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(14.8885, 13.3334)
        ..lineTo(14.8885, 10.8667)
        ..lineTo(13.244, 10.8667)
        ..lineTo(13.244, 13.3334)
        ..lineTo(10.7773, 13.3334)
        ..lineTo(10.7773, 14.9778)
        ..lineTo(13.244, 14.9778)
        ..lineTo(13.244, 17.4445)
        ..lineTo(14.8885, 17.4445)
        ..lineTo(14.8885, 14.9778)
        ..lineTo(17.3551, 14.9778)
        ..lineTo(17.3551, 13.3334)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_OfficialVariationsGeometry old) => old.ink != ink;
}

void main() {
  for (final dpr in [1.0, 1.25, 1.5, 2.0]) {
    for (final dark in [false, true]) {
      testWidgets('官方变体图标 17px 内描边不外扩 DPR=$dpr dark=$dark', (tester) async {
        tester.view.devicePixelRatio = dpr;
        tester.view.physicalSize = Size(320 * dpr, 200 * dpr);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final actual = GlobalKey();
        final expected = GlobalKey();
        final ink = dark ? Colors.white : Colors.black;
        final background = dark ? Colors.black : Colors.white;
        Widget tile(GlobalKey key, Widget child) => RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: background,
            child: SizedBox.square(dimension: 17, child: child),
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    tile(
                      actual,
                      // Check SVG geometry independently of the shared icon's
                      // user-selected low-density edge resampling.
                      SvgPicture.asset(
                        'assets/icons/nai-icon-variations.svg',
                        width: 17,
                        height: 17,
                        colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
                      ),
                    ),
                    tile(
                      expected,
                      CustomPaint(painter: _OfficialVariationsGeometry(ink)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          Future<ByteData> raster(GlobalKey key) async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: dpr);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            image.dispose();
            return bytes!;
          }

          final actualPixels = await raster(actual);
          final expectedPixels = await raster(expected);
          expect(actualPixels.lengthInBytes, expectedPixels.lengthInBytes);
          var delta = 0;
          for (
            var offset = 0;
            offset < actualPixels.lengthInBytes;
            offset += 4
          ) {
            delta +=
                (actualPixels.getUint8(offset) -
                        expectedPixels.getUint8(offset))
                    .abs();
          }
          // Allow normal SVG arc / RRect antialias differences. The original
          // mask overflow averaged 19–42 grayscale levels across the icon.
          expect(delta / (actualPixels.lengthInBytes / 4), lessThan(3));
        });
        expect(tester.takeException(), isNull);
      });
    }
  }
}
