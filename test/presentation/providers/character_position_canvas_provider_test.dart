import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/character_position_canvas_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_maximize_provider.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';

final _availabilityProvider = StateProvider<bool>((ref) => true);

class _Repository extends CharacterPromptRepository {
  @override
  CharacterPromptConfig load() =>
      const CharacterPromptConfig(characters: [CharacterPrompt(id: 'one')]);
  @override
  Future<bool> save(CharacterPromptConfig config) async => true;
}

void main() {
  test('availability requires V4 characters and an idle non-error state', () {
    expect(
      isCharacterPositionCanvasAvailable(
        isV4Model: true,
        hasCharacters: true,
        isGenerating: false,
        hasError: false,
      ),
      isTrue,
    );
    expect(
      isCharacterPositionCanvasAvailable(
        isV4Model: false,
        hasCharacters: true,
        isGenerating: false,
        hasError: false,
      ),
      isFalse,
    );
    expect(
      isCharacterPositionCanvasAvailable(
        isV4Model: true,
        hasCharacters: false,
        isGenerating: false,
        hasError: false,
      ),
      isFalse,
    );
    expect(
      isCharacterPositionCanvasAvailable(
        isV4Model: true,
        hasCharacters: true,
        isGenerating: true,
        hasError: false,
      ),
      isFalse,
    );
    expect(
      isCharacterPositionCanvasAvailable(
        isV4Model: true,
        hasCharacters: true,
        isGenerating: false,
        hasError: true,
      ),
      isFalse,
    );
  });

  group('CharacterPositionCanvas', () {
    test(
      'AI choice closes editing; custom keeps saved positions without reopening',
      () async {
        final container = _buildContainer(_FakeCanvasStorage());
        addTearDown(container.dispose);
        final subscription = container.listen(
          characterPositionCanvasProvider,
          (_, _) {},
        );
        addTearDown(subscription.close);
        container.read(characterPositionCanvasProvider.notifier).open();
        expect(
          container.read(characterPromptNotifierProvider).globalAiChoice,
          isFalse,
        );
        final character = container
            .read(characterPromptNotifierProvider)
            .characters
            .single;
        final moved = character.copyWith(
          customPosition: const CharacterPosition(
            mode: CharacterPositionMode.custom,
            row: .3,
            column: .8,
          ),
        );
        container
            .read(characterPromptNotifierProvider.notifier)
            .updateCharacter(moved);
        container
            .read(characterPromptNotifierProvider.notifier)
            .setGlobalAiChoice(true);
        expect(container.read(characterPositionCanvasProvider), isFalse);
        container
            .read(characterPromptNotifierProvider.notifier)
            .setGlobalAiChoice(false);
        expect(container.read(characterPositionCanvasProvider), isFalse);
        expect(
          container
              .read(characterPromptNotifierProvider)
              .characters
              .single
              .customPosition,
          moved.customPosition,
        );
      },
    );
    test('opening the canvas exits maximized prompt editing', () async {
      final storage = _FakeCanvasStorage(promptMaximized: true);
      final container = _buildContainer(storage);
      addTearDown(container.dispose);
      final subscription = container.listen<bool>(
        characterPositionCanvasProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      container.read(characterPositionCanvasProvider.notifier).open();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(characterPositionCanvasProvider), isTrue);
      expect(container.read(promptMaximizeNotifierProvider), isFalse);
      expect(storage.promptMaximized, isFalse);
    });

    test('closing the canvas restores the previous maximize state', () async {
      final storage = _FakeCanvasStorage(promptMaximized: true);
      final container = _buildContainer(storage);
      addTearDown(container.dispose);
      final subscription = container.listen<bool>(
        characterPositionCanvasProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      container.read(characterPositionCanvasProvider.notifier).open();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(promptMaximizeNotifierProvider), isFalse);

      container.read(characterPositionCanvasProvider.notifier).close();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(characterPositionCanvasProvider), isFalse);
      expect(container.read(promptMaximizeNotifierProvider), isTrue);
      expect(storage.promptMaximized, isTrue);
    });

    test('becoming unavailable closes an open canvas', () async {
      final container = _buildContainer(_FakeCanvasStorage());
      addTearDown(container.dispose);
      final subscription = container.listen<bool>(
        characterPositionCanvasProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      container.read(characterPositionCanvasProvider.notifier).open();
      expect(container.read(characterPositionCanvasProvider), isTrue);

      container.read(_availabilityProvider.notifier).state = false;
      await Future<void>.delayed(Duration.zero);

      expect(container.read(characterPositionCanvasProvider), isFalse);
    });

    test('cannot open while the canvas is unavailable', () {
      final container = _buildContainer(_FakeCanvasStorage());
      addTearDown(container.dispose);
      container.read(_availabilityProvider.notifier).state = false;

      container.read(characterPositionCanvasProvider.notifier).open();

      expect(container.read(characterPositionCanvasProvider), isFalse);
    });
  });
}

ProviderContainer _buildContainer(_FakeCanvasStorage storage) {
  return ProviderContainer(
    overrides: [
      characterPromptRepositoryProvider.overrideWithValue(_Repository()),
      localStorageServiceProvider.overrideWith((ref) => storage),
      characterPositionCanvasAvailableProvider.overrideWith(
        (ref) => ref.watch(_availabilityProvider),
      ),
    ],
  );
}

class _FakeCanvasStorage extends LocalStorageService {
  _FakeCanvasStorage({this.promptMaximized = false});

  bool promptMaximized;

  @override
  bool getPromptMaximized() => promptMaximized;

  @override
  Future<void> setPromptMaximized(bool value) async {
    promptMaximized = value;
  }
}
