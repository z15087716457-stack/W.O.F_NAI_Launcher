import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_prompt.dart';

void main() {
  for (final brightness in Brightness.values) {
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
