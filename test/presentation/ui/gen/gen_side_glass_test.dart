import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_parts.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';

import '../../../helpers/studio_capture_fonts.dart';

class _Bars extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF2060A0),
    );
    for (var x = 200.0; x < size.width; x += 4) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 4, size.height),
        Paint()..color = (x ~/ 4).isEven ? Colors.black : Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_Bars oldDelegate) => false;
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final dark in [false, true]) {
    for (final contrast in [false, true]) {
      testWidgets(
        'glass panel keeps 85% tint and sharp content: $dark $contrast',
        (tester) async {
          tester.view.physicalSize = const Size(400, 180);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          late Color base;
          final capture = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? GeistTheme.dark : GeistTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(highContrast: contrast),
                child: child!,
              ),
              home: Builder(
                builder: (context) {
                  base = context.ui.bg;
                  return RepaintBoundary(
                    key: capture,
                    child: Stack(
                      children: [
                        Positioned.fill(child: CustomPaint(painter: _Bars())),
                        const Positioned(
                          left: 20,
                          right: 20,
                          top: 20,
                          bottom: 20,
                          child: GenPanelSurface(
                            enabled: true,
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '清晰文字 Sharp text',
                                    style: TextStyle(fontSize: 14, height: 1),
                                  ),
                                  SizedBox(height: 8),
                                  GenModule(
                                    child: SizedBox(height: 60, width: 100),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byType(BackdropFilter),
            contrast ? findsNothing : findsOneWidget,
          );
          expect(find.byType(Opacity), findsNothing);
          await tester.runAsync(() async {
            final box =
                capture.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await box.toImage();
            final data = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            final expected = contrast
                ? base
                : Color.alphaBlend(
                    base.withValues(alpha: .85),
                    const Color(0xFF2060A0),
                  );
            for (final point in [
              const Offset(160, 140),
              if (!contrast) const Offset(80, 100),
            ]) {
              final offset = (point.dy.toInt() * 400 + point.dx.toInt()) * 4;
              expect(
                data.getUint8(offset),
                closeTo((expected.r * 255).round(), 2),
              );
              expect(
                data.getUint8(offset + 1),
                closeTo((expected.g * 255).round(), 2),
              );
              expect(
                data.getUint8(offset + 2),
                closeTo((expected.b * 255).round(), 2),
              );
            }
            final stripe = [
              for (var x = 250; x < 266; x++)
                data.getUint8((140 * 400 + x) * 4),
            ]..sort();
            expect(stripe.last - stripe.first, lessThan(5));
            image.dispose();
          });
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
