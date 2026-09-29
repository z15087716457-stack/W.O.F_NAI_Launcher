import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_translation_provider.dart';

void main() {
  test(
    'clear translations restores the selected side including disabled roles',
    () {
      final container = ProviderContainer(
        overrides: [
          characterPromptNotifierProvider.overrideWith(_Characters.new),
          promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
        ],
      );
      addTearDown(container.dispose);
      for (final scope in [
        PillScopes.main,
        PillScopes.charPos('active'),
        PillScopes.charPos('disabled'),
      ]) {
        container
            .read(pillWorkspaceProvider(scope).notifier)
            .insertTranslationAt(offset: 0, source: '$scope text', zh: '译文');
      }
      container
          .read(pillWorkspaceProvider(PillScopes.negative).notifier)
          .insertTranslationAt(offset: 0, source: 'negative text', zh: '负面');

      final coordinator = container.read(promptTranslationCoordinatorProvider);
      expect(coordinator.hasAnyTranslations(false), isTrue);
      expect(coordinator.clearTranslations(false), 3);
      for (final scope in [
        PillScopes.main,
        PillScopes.charPos('active'),
        PillScopes.charPos('disabled'),
      ]) {
        final state = container.read(pillWorkspaceProvider(scope));
        expect(state.document.text, '$scope text');
        expect(state.document.instances, isEmpty);
      }
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.negative))
            .document
            .instances
            .length,
        1,
      );
      expect(coordinator.hasAnyTranslations(false), isFalse);
      final main = container.read(
        pillWorkspaceProvider(PillScopes.main).notifier,
      );
      main.setText('\uE000');
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.main))
            .document
            .instances,
        isEmpty,
      );
    },
  );
}

class _Characters extends CharacterPromptNotifier {
  @override
  CharacterPromptConfig build() => const CharacterPromptConfig(
    characters: [
      CharacterPrompt(id: 'active'),
      CharacterPrompt(id: 'disabled', enabled: false),
    ],
  );
}

class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: [], folders: []);
}
