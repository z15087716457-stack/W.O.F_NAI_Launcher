import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_prompt.dart';

import '../../../helpers/studio_capture_fonts.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 1.4]) {
      testWidgets(
        'weight markers share body and selection height: $brightness $scale',
        (tester) async {
          await tester.runAsync(loadStudioCaptureFonts);
          final boundaryKey = GlobalKey();
          for (final weight in [-1.0, .3, .6, 1.5, 2.5]) {
            final prefix = '$weight::';
            const body = 'tianliang duohe';
            final text = '$prefix$body::, room';
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.getTheme(AppStyle.geist, brightness),
                home: Scaffold(
                  body: Builder(
                    builder: (context) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: TextScaler.linear(scale)),
                      child: Center(
                        child: RepaintBoundary(
                          key: boundaryKey,
                          child: SizedBox(
                            width: 500,
                            child: SelectionArea(
                              child: ViewerPromptBox(
                                spans: viewerPromptSpans(
                                  text,
                                  c: context.ui,
                                  highlight: true,
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
            await tester.pump();
            final rich = find.byWidgetPredicate(
              (w) => w is RichText && w.text.toPlainText() == text,
            );
            final paragraph = tester.renderObject<RenderParagraph>(rich);
            final bodyBox = paragraph
                .getBoxesForSelection(
                  TextSelection(
                    baseOffset: prefix.length,
                    extentOffset: prefix.length + body.length,
                  ),
                )
                .single;
            for (final range in [
              TextSelection(baseOffset: 0, extentOffset: prefix.length),
              TextSelection(
                baseOffset: prefix.length + body.length,
                extentOffset: prefix.length + body.length + 2,
              ),
              TextSelection(
                baseOffset: text.indexOf('room'),
                extentOffset: text.length,
              ),
            ]) {
              final box = paragraph.getBoxesForSelection(range).single;
              expect(box.top, closeTo(bodyBox.top, .01), reason: text);
              expect(box.bottom, closeTo(bodyBox.bottom, .01), reason: text);
            }
            expect(paragraph.text.toPlainText(), text);
            final capture = Platform.environment['VIEWER_WEIGHT_CAPTURE_DIR'];
            if (capture != null && weight == .6) {
              final origin = tester.getTopLeft(rich);
              final last = paragraph
                  .getBoxesForSelection(
                    TextSelection(
                      baseOffset: text.indexOf('room'),
                      extentOffset: text.length,
                    ),
                  )
                  .single;
              final y = (bodyBox.top + bodyBox.bottom) / 2;
              final drag = await tester.startGesture(
                origin + Offset(1, y),
                kind: ui.PointerDeviceKind.mouse,
              );
              await drag.moveTo(origin + Offset(last.right, y));
              await drag.up();
              await tester.pump();
              await tester.runAsync(() async {
                final boundary =
                    boundaryKey.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                final image = await boundary.toImage(pixelRatio: 2);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final file = File('$capture/${brightness.name}-$scale.png');
                await file.parent.create(recursive: true);
                await file.writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
          }
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
    test(
      'viewer maps all tiers and leaves neutral content unmarked ($brightness)',
      () {
        final c = UiColors.fromTheme(ThemeData(brightness: brightness));
        for (final (weight, background, ink) in [
          (2.5, c.weightTop, c.weightTopInk),
          (1.5, c.weightUp, c.weightUpInk),
          (.7, c.weightDown, c.weightDownInk),
          (.3, c.weightBottom, c.weightBottomInk),
          (-1.0, c.weightNeg, c.weightNegInk),
          (2.0, c.weightUp, c.weightUpInk),
          (.5, c.weightDown, c.weightDownInk),
        ]) {
          final text = '$weight::tag::';
          final span =
              viewerPromptSpans(text, c: c, highlight: true).single as TextSpan;
          expect(
            span.style!.background!.color.toARGB32(),
            uiSelectableTint(background, c.card).toARGB32(),
          );
          expect(
            (span.children!.first as TextSpan).style!.color,
            ink.withValues(alpha: .85),
          );
          expect(span.toPlainText(), text);
        }
        final plain =
            viewerPromptSpans('1::tag::', c: c, highlight: true).single
                as TextSpan;
        expect(plain.style?.background, isNull);
        expect(plain.toPlainText(), '1::tag::');
      },
    );
  }
}
