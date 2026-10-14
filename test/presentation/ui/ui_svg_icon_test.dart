import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_svg_icon.dart';

void main() {
  for (final dpr in [1.0, 1.25, 1.5, 2.0, 3.0]) {
    testWidgets(
      'SVG icon keeps layout, sibling density, label and tap DPR=$dpr',
      (tester) async {
        tester.view.devicePixelRatio = dpr;
        tester.view.physicalSize = Size(320 * dpr, 200 * dpr);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final semantics = tester.ensureSemantics();
        var taps = 0;
        double? siblingDensity;
        const iconKey = Key('small-svg');
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => taps++,
                      child: const UiSvgIcon.asset(
                        'assets/icons/novelai-icon.svg',
                        key: iconKey,
                        size: 13,
                        semanticsLabel: 'NovelAI model',
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        siblingDensity = MediaQuery.devicePixelRatioOf(context);
                        return const SizedBox(width: 40, height: 20);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byKey(iconKey)), const Size.square(13));
        expect(siblingDensity, dpr);
        expect(find.bySemanticsLabel('NovelAI model'), findsOneWidget);
        await tester.tap(find.byKey(iconKey));
        expect(taps, 1);
        semantics.dispose();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('cached SVG updates tint and source without changing its box', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(160, 160);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final boundaryKey = GlobalKey();
    Future<List<int>> render(String shape, Color color) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: boundaryKey,
                child: ColoredBox(
                  color: Colors.white,
                  child: UiSvgIcon.string(
                    '<svg xmlns="http://www.w3.org/2000/svg" '
                    'viewBox="0 0 16 16"><path d="$shape"/></svg>',
                    size: 16,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(UiSvgIcon)), const Size.square(16));
      return tester
          .runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            try {
              final data = (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!;
              return [
                for (var i = 0; i < data.lengthInBytes; i++) data.getUint8(i),
              ];
            } finally {
              image.dispose();
            }
          })
          .then((value) => value!);
    }

    const square = 'M2 2H14V14H2Z';
    final red = await render(square, Colors.red);
    final blue = await render(square, Colors.blue);
    final small = await render('M6 6H10V10H6Z', Colors.blue);
    const center = (8 * 16 + 8) * 4;
    expect(red[center], greaterThan(red[center + 2]));
    expect(blue[center + 2], greaterThan(blue[center]));
    const corner = (3 * 16 + 3) * 4;
    expect(blue[corner], lessThan(255));
    expect(small.sublist(corner, corner + 3), [255, 255, 255]);
    expect(tester.takeException(), isNull);
  });
}
