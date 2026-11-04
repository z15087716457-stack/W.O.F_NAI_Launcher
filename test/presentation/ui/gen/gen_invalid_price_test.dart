import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets('high-price label is red and generation remains available', (
    t,
  ) async {
    final rec = GenRecorder();
    await pumpGen(
      t,
      data: GenFixture.view().copyWith(
        generate: const GenGenerateData(
          cost: 60,
          highCost: true,
          label: 'Generate fixture',
        ),
      ),
      actions: rec.actions,
    );
    await t.pumpAndSettle();
    final badge = find.byKey(const Key('gen-cost'));
    expect(
      (t.widget<Container>(badge).decoration! as BoxDecoration).color,
      t.element(badge).ui.error,
    );
    final price = find.descendant(of: badge, matching: find.text('60'));
    expect(t.widget<Text>(price).style!.color, Colors.white);
    await t.tap(find.byKey(const Key('gen-generate')));
    await t.pump();
    expect(rec.called('onGenerate'), isTrue);
  });
  testWidgets('invalid estimate is unavailable and cannot generate', (t) async {
    final rec = GenRecorder();
    await pumpGen(
      t,
      data: GenFixture.view().copyWith(
        generate: const GenGenerateData(cost: -3, label: 'Generate fixture'),
      ),
      actions: rec.actions,
    );
    await t.pumpAndSettle();
    expect(find.text('-3'), findsNothing);
    expect(find.text('—'), findsWidgets);
    await t.tap(find.byKey(const Key('gen-generate')));
    await t.pump();
    expect(rec.called('onGenerate'), isFalse);
  });
}
