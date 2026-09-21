import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/widgets/character/character_position_canvas.dart';
import 'package:nai_launcher/presentation/widgets/character/inline_character_editor.dart';
import '../../../helpers/light_theme_contrast.dart';

class _Repository extends CharacterPromptRepository {
  _Repository(this.config);
  CharacterPromptConfig config;
  int saves = 0;
  @override
  CharacterPromptConfig load() => config;
  @override
  Future<bool> save(CharacterPromptConfig next) async {
    config = next;
    saves++;
    return true;
  }
}

Future<ProviderContainer> _mount(
  WidgetTester tester,
  _Repository repository,
) async {
  final container = createStorageFreeContainer(
    overrides: [
      characterPromptRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              final character = ref
                  .watch(characterPromptNotifierProvider)
                  .characters
                  .single;
              return Center(
                child: SizedBox(
                  width: 280,
                  child: CharacterNameField(character: character, index: 0),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('empty name is a placeholder; custom name and clearing persist', (
    tester,
  ) async {
    final repository = _Repository(
      const CharacterPromptConfig().addCharacter(prompt: 'girl, Elsa'),
    );
    final container = await _mount(tester, repository);
    final field = find.byType(TextField);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(tester.widget<TextField>(field).decoration!.hintText, 'Character 1');
    await tester.enterText(field, ' Alice ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(repository.config.characters.single.name, 'Alice');
    expect(
      resolveCharacterChipDisplay(repository.config.characters.single).label,
      'Alice',
    );
    await tester.enterText(field, '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final character = container
        .read(characterPromptNotifierProvider)
        .characters
        .single;
    expect(character.name, isEmpty);
    expect(character.prompt, 'girl, Elsa');
    expect(resolveCharacterChipDisplay(character).label, isNull);
    expect(resolveCharacterChipDisplay(character).genderIcon, Icons.female);
  });

  testWidgets('legacy default stays raw and untouched after focus and blur', (
    tester,
  ) async {
    final repository = _Repository(
      const CharacterPromptConfig(
        characters: [
          CharacterPrompt(id: 'old', name: 'Character 1', prompt: 'girl, Elsa'),
        ],
      ),
    );
    await _mount(tester, repository);
    final field = find.byType(TextField);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    await tester.tap(field);
    await tester.pump();
    tester.widget<TextField>(field).focusNode!.unfocus();
    await tester.pumpAndSettle();
    expect(repository.saves, 0);
    expect(repository.config.characters.single.name, 'Character 1');
  });

  testWidgets(
    'rename preserves newer prompt; untouched focus preserves external rename',
    (tester) async {
      final repository = _Repository(
        const CharacterPromptConfig().addCharacter(),
      );
      final container = await _mount(tester, repository);
      final notifier = container.read(characterPromptNotifierProvider.notifier);
      final field = find.byType(TextField);
      await tester.enterText(field, 'Alice');
      notifier.updateCharacter(
        container
            .read(characterPromptNotifierProvider)
            .characters
            .single
            .copyWith(prompt: 'new prompt'),
      );
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(repository.config.characters.single.name, 'Alice');
      expect(repository.config.characters.single.prompt, 'new prompt');
      await tester.tap(field);
      await tester.pump();
      notifier.updateCharacter(
        container
            .read(characterPromptNotifierProvider)
            .characters
            .single
            .copyWith(name: 'External', nameIsCustom: true),
      );
      await tester.pump();
      tester.widget<TextField>(field).focusNode!.unfocus();
      await tester.pumpAndSettle();
      expect(repository.config.characters.single.name, 'External');
      expect(tester.widget<TextField>(field).controller!.text, 'External');
    },
  );
}
