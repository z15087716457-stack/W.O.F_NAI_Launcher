import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/prompt/prompt_formatter_wrapper.dart';

void main() {
  for (final autoFormat in [false, true]) {
    for (final sdAutoConvert in [false, true]) {
      testWidgets('blur gates: format=$autoFormat SD=$sdAutoConvert', (
        tester,
      ) async {
        final controller = TextEditingController();
        final focus = FocusNode();
        String? changed;
        await tester.pumpWidget(
          MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: PromptFormatterWrapper(
                controller: controller,
                focusNode: focus,
                enableAutoFormat: autoFormat,
                enableSdSyntaxAutoConvert: sdAutoConvert,
                onChanged: (text) => changed = text,
                child: TextField(controller: controller, focusNode: focus),
              ),
            ),
          ),
        );
        const input = 'girl，blue dress, (ralada747372:1.4)';
        await tester.tap(find.byType(TextField));
        await tester.enterText(find.byType(TextField), input);
        expect(controller.text, input);
        expect(changed, isNull);
        focus.unfocus();
        await tester.pump();
        final expected =
            '${autoFormat ? 'girl, blue dress' : 'girl，blue dress'}, '
            '${sdAutoConvert ? '1.4::ralada747372 ::' : '(ralada747372:1.4)'}';
        expect(controller.text, expected);
        expect(changed, autoFormat || sdAutoConvert ? expected : isNull);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        focus.dispose();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
