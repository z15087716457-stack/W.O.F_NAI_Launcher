import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/notification_settings_provider.dart';

class _Memory extends LocalStorageService {
  final values = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values[key] as T? ?? defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async => values[key] = value;
}

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
  void emit(GenerationStatus status) => state = state.copyWith(status: status);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'completion sound requires an unfocused window; preview always works',
    () async {
      var focused = true;
      final sounds = <String?>[];
      final generation = _Generation();
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(_Memory()),
          imageGenerationNotifierProvider.overrideWith(() => generation),
          completionWindowIsFocusedProvider.overrideWithValue(
            () async => focused,
          ),
          notificationSoundPreviewProvider.overrideWithValue((path) async {
            sounds.add(path);
            return true;
          }),
        ],
      );
      addTearDown(container.dispose);
      container.read(generationCompletionWatcherProvider);
      await container
          .read(notificationSettingsNotifierProvider.notifier)
          .setCustomSoundPath('synthetic-sound.wav');
      generation.emit(GenerationStatus.generating);
      generation.emit(GenerationStatus.completed);
      await Future<void>.delayed(Duration.zero);
      expect(sounds, isEmpty);
      focused = false;
      generation.emit(GenerationStatus.generating);
      generation.emit(GenerationStatus.completed);
      await Future<void>.delayed(Duration.zero);
      expect(sounds, ['synthetic-sound.wav']);
      generation.emit(GenerationStatus.completed);
      generation.emit(GenerationStatus.generating);
      generation.emit(GenerationStatus.cancelled);
      generation.emit(GenerationStatus.generating);
      generation.emit(GenerationStatus.error);
      await Future<void>.delayed(Duration.zero);
      expect(sounds.length, 1);
      await container
          .read(notificationSettingsNotifierProvider.notifier)
          .setSoundEnabled(false);
      generation.emit(GenerationStatus.generating);
      generation.emit(GenerationStatus.completed);
      await Future<void>.delayed(Duration.zero);
      expect(sounds.length, 1);
      focused = true;
      await container.read(notificationSoundPreviewProvider)('preview.wav');
      expect(sounds.last, 'preview.wav');
    },
  );

  test(
    'pending focus query cannot play after disabling sound or disposal',
    () async {
      for (final dispose in [false, true]) {
        final focus = Completer<bool>();
        var sounds = 0;
        final generation = _Generation();
        final container = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWithValue(_Memory()),
            imageGenerationNotifierProvider.overrideWith(() => generation),
            completionWindowIsFocusedProvider.overrideWithValue(
              () => focus.future,
            ),
            notificationSoundPreviewProvider.overrideWithValue((_) async {
              sounds++;
              return true;
            }),
          ],
        );
        container.read(generationCompletionWatcherProvider);
        generation.emit(GenerationStatus.generating);
        generation.emit(GenerationStatus.completed);
        if (dispose) {
          container.dispose();
        } else {
          await container
              .read(notificationSettingsNotifierProvider.notifier)
              .setSoundEnabled(false);
        }
        focus.complete(false);
        await Future<void>.delayed(Duration.zero);
        expect(sounds, 0);
        if (!dispose) container.dispose();
      }
    },
  );
}
