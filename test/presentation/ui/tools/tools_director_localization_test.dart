import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_director.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../gen/gen_test_harness.dart';
import 'tools_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets('director actions and fee $locale $dark', (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(852, 1000);
        addTearDown(t.view.reset);
        final recorder = ToolsRecorder();
        await t.pumpWidget(
          genApp(
            ToolsDirectorPage(
              data: ToolsFixture.removeBg(),
              actions: recorder.director,
            ),
            locale: locale,
            dark: dark,
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        final root = find.byKey(const Key('tools-director-actions'));
        final l = AppLocalizations.of(t.element(root))!;
        final fee = find.descendant(
          of: root,
          matching: find.textContaining(l.tools_anlasN(65)),
        );
        expect(fee, findsOneWidget);
        expect(t.renderObject<RenderParagraph>(fee).didExceedMaxLines, isFalse);
        for (final action in ['continue', 'copy', 'save', 'upscale', 'init']) {
          final finder = find.byKey(Key('tools-act-$action'));
          final rect = t.getRect(finder);
          expect(rect.right, lessThanOrEqualTo(852));
          expect(rect.bottom, lessThanOrEqualTo(1000));
          await t.tap(finder);
          await t.pumpAndSettle();
        }
        expect(recorder.calls, [
          'onContinue',
          'onCopy',
          'onSave',
          'onUpscale',
          'onUseAsInit',
        ]);
        await t.pumpWidget(const SizedBox());
        expect(t.takeException(), isNull);
      });
    }
  }
}
