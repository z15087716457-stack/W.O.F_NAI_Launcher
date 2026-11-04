import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_retry_policy.dart';
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
  void finish(ImageGenerationState value) => state = value;
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

  for (final platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
    test('${platform.name}: a run stopped by 429 after making images still '
        'plays the sound', () async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final sounds = <String?>[];
      final generation = _Generation();
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(_Memory()),
          imageGenerationNotifierProvider.overrideWith(() => generation),
          completionWindowIsFocusedProvider.overrideWithValue(
            () async => false,
          ),
          notificationSoundPreviewProvider.overrideWithValue((path) async {
            sounds.add(path);
            return true;
          }),
        ],
      );
      addTearDown(container.dispose);
      container.read(generationCompletionWatcherProvider);
      final stopped = generationConcurrencyStoppedError('API_ERROR_429|busy');
      final made = GeneratedImage.create(Uint8List(0), width: 8, height: 8);
      Future<int> run(ImageGenerationState end) async {
        generation.emit(GenerationStatus.generating);
        generation.finish(end);
        await Future<void>.delayed(Duration.zero);
        return sounds.length;
      }

      // Images were made before the stop: the run used to end as completed
      // and play the sound, and still does.
      expect(
        await run(
          ImageGenerationState(
            status: GenerationStatus.error,
            errorMessage: stopped,
            currentImages: [made],
          ),
        ),
        1,
      );
      // Stopped before any image, or failed for another reason: silent, as
      // every failed run.
      expect(
        await run(
          ImageGenerationState(
            status: GenerationStatus.error,
            errorMessage: stopped,
            currentImages: [
              GeneratedImage.create(
                Uint8List(0),
                width: 8,
                height: 8,
                kind: GeneratedImageKind.failedStreamSnapshot,
              ),
              GeneratedImage.create(
                Uint8List(0),
                width: 8,
                height: 8,
                isVariationOriginal: true,
              ),
            ],
          ),
        ),
        1,
      );
      expect(
        await run(
          ImageGenerationState(
            status: GenerationStatus.error,
            errorMessage: 'Exception: API_ERROR_402|Payment required',
            currentImages: [made],
          ),
        ),
        1,
      );
    });

    test('${platform.name}: a run stopped by 400, 401, 402, 403 or 404 chimes '
        'only once it made images', () async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final sounds = <String?>[];
      final generation = _Generation();
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(_Memory()),
          imageGenerationNotifierProvider.overrideWith(() => generation),
          completionWindowIsFocusedProvider.overrideWithValue(
            () async => false,
          ),
          notificationSoundPreviewProvider.overrideWithValue((path) async {
            sounds.add(path);
            return true;
          }),
        ],
      );
      addTearDown(container.dispose);
      container.read(generationCompletionWatcherProvider);
      final made = GeneratedImage.create(Uint8List(0), width: 8, height: 8);
      Future<int> run(ImageGenerationState end) async {
        generation.emit(GenerationStatus.generating);
        generation.finish(end);
        await Future<void>.delayed(Duration.zero);
        return sounds.length;
      }

      var played = 0;
      for (final reason in [
        'API_ERROR_400|Bad request',
        'API_ERROR_401|Unauthorized',
        'API_ERROR_402|Payment required',
        'API_ERROR_HTTP_403|Forbidden',
        'API_ERROR_HTTP_404|Not Found',
      ]) {
        final stopped = generationStatusStoppedError(
          GenerationStreamError(reason),
        );
        expect(
          await run(
            ImageGenerationState(
              status: GenerationStatus.error,
              errorMessage: stopped,
              currentImages: [made],
            ),
          ),
          ++played,
          reason: reason,
        );
        expect(
          await run(
            ImageGenerationState(
              status: GenerationStatus.error,
              errorMessage: stopped,
            ),
          ),
          played,
          reason: '$reason, before any image',
        );
      }
    });
  }

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
