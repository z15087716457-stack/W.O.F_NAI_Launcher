import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_parts.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_slider.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets('precise rows accept 1.5, Vibe retains its 0..1 input range', (
    t,
  ) async {
    final recorder = GenRecorder();
    await pumpGen(t, data: GenFixture.refsFull(), actions: recorder.actions);
    for (final section in ['precise', 'vibe']) {
      await tapKey(t, 'gen-ref-$section-row');
    }
    final rows = find
        .byType(GenSliderRow)
        .evaluate()
        .map((e) => e.widget as GenSliderRow)
        .toList();
    final precise = rows
        .where((r) => r.key.toString().contains('gen-precise-'))
        .toList();
    final vibes = rows
        .where((r) => r.key.toString().contains('gen-vibe-'))
        .toList();
    expect(precise, hasLength(2));
    expect(precise.every((r) => r.max == 1 && r.inputMax == 10), isTrue);
    expect(vibes.every((r) => r.inputMax == null), isTrue);
    // Exercise the real row widgets in a small, fully visible host.
    for (final row in [...precise, vibes.first]) {
      double? submitted;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              child: GenSliderRow(
                label: row.label,
                value: 1.5,
                min: row.min,
                max: row.max,
                inputMax: row.inputMax,
                onChanged: (v) => submitted = v,
              ),
            ),
          ),
        ),
      );
      expect(t.widget<UiSlider>(find.byType(UiSlider)).value, 1);
      await t.tap(find.byType(UiNumBox));
      await t.pump();
      await t.enterText(find.byType(TextField), '1.5');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
      expect(submitted, row.inputMax == 10 ? 1.5 : 1);
    }
  });
}
