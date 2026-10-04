import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/bridge/bridge_link_icon.dart';

void main() {
  testWidgets('原生16px双环运动、停止、减少动态与TickerMode；24px槽不抖动', (tester) async {
    final boundary = GlobalKey();
    Future<void> icon({
      bool working = true,
      bool reduced = false,
      bool ticker = true,
    }) => tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: TickerMode(
            enabled: ticker,
            child: Center(
              child: RepaintBoundary(
                key: boundary,
                child: SizedBox(
                  width: 160,
                  height: 64,
                  child: ColoredBox(
                    color: const Color(0xFF202124),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 24,
                        child: Center(
                          child: BridgeLinkIcon(
                            color: Colors.blue,
                            working: working,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await icon();
    final rect = tester.getRect(find.byType(BridgeLinkIcon));
    expect(rect.size, const Size(16, 16));
    BridgeLinkPainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(BridgeLinkIcon),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as BridgeLinkPainter;
    expect(painter().progress, 0);
    await tester.pump(const Duration(milliseconds: 275));
    expect(painter().progress, greaterThan(0));
    expect(tester.getRect(find.byType(BridgeLinkIcon)), rect);
    await icon(reduced: true);
    await tester.pump(const Duration(milliseconds: 275));
    expect(painter().progress, 0);
    await icon(ticker: false);
    expect(painter().progress, 0);
    await icon(working: false);
    await tester.pumpAndSettle();
    expect(painter().progress, 0);
    expect(tester.takeException(), isNull);
    if (Platform.environment['CAPTURE_BRIDGE_MOTION'] == '1') {
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 4);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final file = File('.dart_tool/bridge-motion-captures/native-link.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
      });
    }
    await tester.pumpWidget(const SizedBox());
  });
}
