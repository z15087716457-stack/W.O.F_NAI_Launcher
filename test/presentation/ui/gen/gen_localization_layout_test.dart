import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      for (final width in [352.0, 420.0, 560.0]) {
        testWidgets('generation $locale dark=$dark left=$width', (t) async {
          final data = GenFixture.view(layout: GenLayout(leftWidth: width));
          final recorder = GenRecorder();
          await pumpGen(
            t,
            data: data,
            actions: recorder.actions,
            locale: locale,
            dark: dark,
            window: 1600,
          );
          expect(t.takeException(), isNull);
          final module = t.getRect(find.byKey(const Key('gen-image')));
          for (final name in [
            'gen-size-group',
            'gen-orientation',
            'gen-width',
            'gen-height',
          ]) {
            final rect = t.getRect(find.byKey(Key(name)));
            expect(rect.left, greaterThanOrEqualTo(module.left));
            expect(rect.right, lessThanOrEqualTo(module.right));
          }
          await captureUiuxRegion(
            t,
            find.byKey(const Key('gen-capture')),
            'gen-$locale-$dark-$width',
            module,
          );
          await tapKey(t, 'gen-orientation-landscape');
          expect(recorder.called('onSizeChanged'), isTrue);
          await tapKey(t, 'gen-swap-size');
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
