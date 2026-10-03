import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_token_counter_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';
import 'package:nai_launcher/presentation/widgets/character/inline_character_editor.dart';
import '../../../helpers/light_theme_contrast.dart';

class _EmptyLibrary extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: const [], folders: const []);
}

class _Repository extends CharacterPromptRepository {
  CharacterPromptConfig value = const CharacterPromptConfig(
    characters: [
      CharacterPrompt(
        id: 'one',
        name: 'First',
        prompt: 'first prompt',
        negativePrompt: 'first negative',
      ),
      CharacterPrompt(
        id: 'two',
        name: 'Second',
        prompt: 'second prompt',
        negativePrompt: 'second negative',
      ),
    ],
  );
  @override
  CharacterPromptConfig load() => value;
  @override
  Future<bool> save(CharacterPromptConfig next) async {
    value = next;
    return true;
  }
}

void main() {
  testWidgets(
    'X clears only the current field, immediately, without deleting roles',
    (tester) async {
      final repository = _Repository();
      final container = createStorageFreeContainer(
        overrides: [
          characterPromptRepositoryProvider.overrideWithValue(repository),
          promptBlockLibraryNotifierProvider.overrideWith(_EmptyLibrary.new),
          tipEpochProvider.overrideWith((ref) => Stream.value(0)),
          for (final target in PromptTokenCountTarget.values)
            promptTokenUsageProvider(target).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
            ),
          for (final negative in [false, true])
            characterPromptTokenUsageProvider((
              characterId: 'one',
              negative: negative,
            )).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
            ),
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
                builder: (context, ref, _) => Center(
                  child: SizedBox(
                    width: 340,
                    child: CharacterPromptEditor(
                      autoFocus: false,
                      character: ref
                          .watch(characterPromptNotifierProvider)
                          .characters
                          .first,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      var roles = container.read(characterPromptNotifierProvider).characters;
      expect(roles, hasLength(2));
      expect(roles.first.prompt, isEmpty);
      expect(roles.first.negativePrompt, 'first negative');
      expect(roles.last.prompt, 'second prompt');
      final l10n = AppLocalizations.of(
        tester.element(find.byType(CharacterPromptEditor)),
      )!;
      await tester.tap(find.text(l10n.prompt_negativeTab));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      roles = container.read(characterPromptNotifierProvider).characters;
      expect(roles.first.negativePrompt, isEmpty);
      expect(roles.first.name, 'First');
      expect(roles.last.negativePrompt, 'second negative');
      expect(roles, hasLength(2));
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
