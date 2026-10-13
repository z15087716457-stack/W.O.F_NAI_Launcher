import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/atom_chip.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';

void main() {
  testWidgets('wrapped atom keeps the gap between line frames unpainted', (
    tester,
  ) async {
    for (final theme in [GeistTheme.light, GeistTheme.dark]) {
      final boundaryKey = GlobalKey();
      final background = theme.colorScheme.surface;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: boundaryKey,
                child: ColoredBox(
                  color: background,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 300,
                      child: AtomChip(
                        text: List.filled(115, '1').join(),
                        theme: theme,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final textRows = find.descendant(
        of: find.byType(AtomChip),
        matching: find.byType(Text),
      );
      expect(textRows, findsAtLeastNWidgets(2));
      final boundaryTop = tester.getTopLeft(find.byKey(boundaryKey));
      final firstFrame = find.ancestor(
        of: textRows.at(0),
        matching: find.byType(CustomPaint),
      );
      final secondFrame = find.ancestor(
        of: textRows.at(1),
        matching: find.byType(CustomPaint),
      );
      final firstBottom = tester.getBottomLeft(firstFrame.first).dy;
      final secondTop = tester.getTopLeft(secondFrame.first).dy;
      expect(secondTop - firstBottom, closeTo(6, 0.1));
      final chipLeft = tester.getTopLeft(find.byType(AtomChip)).dx;
      final gapX = (chipLeft + 2.5 - boundaryTop.dx).round();
      // 旧连接线从空隙顶端起画，取其原本会落色的位置。
      final gapY = (firstBottom + 2 - boundaryTop.dy).round();

      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final pixels = bytes!.buffer.asUint8List();
        final index = (gapY * image.width + gapX) * 4;
        final rgb = background.toARGB32();
        expect(pixels[index], (rgb >> 16) & 0xff);
        expect(pixels[index + 1], (rgb >> 8) & 0xff);
        expect(pixels[index + 2], rgb & 0xff);
      });
      expect(tester.takeException(), isNull);
    }
  });
}
