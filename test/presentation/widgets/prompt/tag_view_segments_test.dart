import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt/prompt_tag.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_settings_notifiers.dart';
import 'package:nai_launcher/presentation/widgets/prompt/tag_view.dart';

class _DisabledAutocomplete extends AutocompleteSettings {
  @override
  bool build() => false;
}

void main() {
  testWidgets('TagView adds complete numeric, alias and bracket segments', (
    tester,
  ) async {
    List<PromptTag>? added;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          autocompleteSettingsProvider.overrideWith(_DisabledAutocomplete.new),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TagView(
              tags: const [],
              compact: true,
              onTagsChanged: (tags) => added = tags,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    final input = find.byType(TextField).first;
    await tester.enterText(
      input,
      '1.4::a, b::，<alias:x, y>, (a, b), blue dress',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(added?.map((tag) => tag.text), [
      '1.4::a, b::',
      '<alias:x, y>',
      '(a, b)',
      'blue dress',
    ]);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
  });
}
