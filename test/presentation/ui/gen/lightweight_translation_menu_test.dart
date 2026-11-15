import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture_editor.dart';
import 'package:nai_launcher/presentation/widgets/common/prompt_translation_guide.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_menu.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets(
        'lightweight menu $locale dark=$dark keeps mode and plain actions',
        (t) async {
          final calls = <String>[];
          final data = GenFixture.view().copyWith(
            prompt: const GenPromptData(
              translate: GenTranslate(
                mode: PromptTranslationMode.inline,
                hasTranslations: true,
                showing: true,
                route: 'Model',
              ),
              tools: GenPromptTools(translatePinned: true),
            ),
          );
          await pumpGen(
            t,
            data: data,
            actions: GenActions.logging(calls.add),
            slots: GenSlots(
              editor: GenFixtureEditor.builder,
              translationGuide: (_, back) =>
                  PromptTranslationGuide(onBack: back),
            ),
            window: 760,
            height: 760,
            locale: locale,
            dark: dark,
          );
          await t.tap(find.byKey(const Key('gen-translate-menu')));
          await t.pumpAndSettle();
          final l = AppLocalizations.of(t.element(find.byType(UiMenu)))!;
          final menu = t.widget<UiMenu>(find.byType(UiMenu));
          expect(menu.items[0].label, l.promptReading_mode);
          expect(menu.items[0].checked, isTrue);
          expect(menu.items[1].label, l.promptReading_blocks);
          expect(menu.items[1].checked, isFalse);
          expect(find.byKey(const Key('gen-translate-adjust')), findsNothing);
          expect(find.text(l.promptReading_update), findsOneWidget);
          expect(find.text(l.promptReading_hide), findsOneWidget);
          expect(find.text(l.promptReading_clear), findsOneWidget);
          await t.tap(find.byKey(const Key('gen-translation-tutorial')));
          await t.pumpAndSettle();
          expect(find.text(l.promptReading_guide), findsOneWidget);
          await t.tap(find.byKey(const Key('translation-guide-back')));
          await t.pumpAndSettle();
          await t.tap(find.text(l.promptReading_blocks));
          await t.pumpAndSettle();
          expect(
            calls,
            contains('onTranslationMode(PromptTranslationMode.blocks)'),
          );
          expect(t.takeException(), isNull);
        },
      );
    }
  }
}
