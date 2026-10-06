import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/services/image_workflow_launcher.dart';

class _Generation extends ImageGenerationNotifier {
  _Generation(this.busy);
  final bool busy;
  @override
  ImageGenerationState build() => ImageGenerationState(
    status: busy ? GenerationStatus.generating : GenerationStatus.idle,
    generationRunId: 12,
  );
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams(prompt: 'user draft', seed: 42);
}

class _CaptureGeneration extends ImageGenerationNotifier {
  ImageParams? submitted;
  GeneratedImage? original;
  @override
  ImageGenerationState build() => const ImageGenerationState();
  @override
  Future<void> generateOfficialVariations(
    ImageParams params, {
    required GeneratedImage original,
  }) async {
    submitted = params;
    this.original = original;
  }
}

class _MemoryStorage extends LocalStorageService {
  final values = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      (values[key] ?? defaultValue) as T?;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }
}

class _Bridge extends KritaBridgeNotifier {
  _Bridge(bool busy) {
    state = KritaBridgeState(activeRequestId: busy ? 'request' : null);
  }
}

class _Cooldown extends GenerationCooldownNotifier {
  _Cooldown(this.active);
  final bool active;
  @override
  GenerationCooldownState build() =>
      GenerationCooldownState(remainingSeconds: active ? 5 : 0);
}

void main() {
  late Directory isolatedHive;
  setUpAll(() async {
    isolatedHive = await Directory.systemTemp.createTemp(
      'nai_variation_audit_',
    );
    Hive.init(isolatedHive.path);
    await Hive.openBox(StorageKeys.settingsBox);
  });
  tearDownAll(() async {
    await Hive.close();
    await isolatedHive.delete(recursive: true);
  });
  testWidgets(
    'variations submit the selected PNG prompts rather than the previous draft',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => _MemoryStorage()),
          imageGenerationNotifierProvider.overrideWith(_CaptureGeneration.new),
          generationParamsNotifierProvider.overrideWith(_Params.new),
          kritaBridgeNotifierProvider.overrideWith((ref) => _Bridge(false)),
          generationCooldownProvider.overrideWith(() => _Cooldown(false)),
        ],
      );
      addTearDown(container.dispose);
      final beforeParams = container.read(generationParamsNotifierProvider);
      final beforeWorkflow = container.read(imageWorkflowControllerProvider);
      final beforeCharacters = container.read(characterPromptNotifierProvider);
      final image = await ImageSaveUtils.buildPrebuiltMetadataBytes(
        imageBytes: Uint8List.fromList(
          img.encodePng(img.Image(width: 512, height: 768)),
        ),
        metadata: {
          'Software': 'NovelAI',
          'Source': 'NovelAI Diffusion V4.5',
          'Comment': jsonEncode({
            'prompt': 'selected image prompt',
            'uc': 'selected image negative',
            'model': 'nai-diffusion-4-5-full',
            'width': 512,
            'height': 768,
            'steps': 28,
            'seed': 123,
            'v4_prompt': {
              'caption': {
                'base_caption': 'selected image prompt',
                'char_captions': [
                  {
                    'char_caption': '1girl, blue hair',
                    'centers': [
                      {'x': 0.2, 'y': 0.4},
                    ],
                  },
                ],
              },
              'use_coords': true,
            },
            'v4_negative_prompt': {
              'caption': {
                'base_caption': 'selected image negative',
                'char_captions': [
                  {
                    'char_caption': 'red hair',
                    'centers': [
                      {'x': 0.2, 'y': 0.4},
                    ],
                  },
                ],
              },
            },
          }),
        },
      );
      late Future<void> Function() invoke;
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
                  invoke = () => ImageWorkflowLauncher.generateVariations(
                    context,
                    ref,
                    image,
                  );
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await container.read(promptBlockLibraryNotifierProvider.future);
        await invoke();
      });
      final generated =
          container.read(imageGenerationNotifierProvider.notifier)
              as _CaptureGeneration;
      expect(generated.submitted?.prompt, 'selected image prompt');
      expect(generated.submitted?.negativePrompt, 'selected image negative');
      expect(generated.submitted?.sourceImage, same(image));
      expect(generated.submitted?.strength, .8);
      expect(generated.submitted?.noise, .1);
      expect(generated.submitted?.nSamples, 1);
      expect(generated.original?.isVariationOriginal, isTrue);
      expect(generated.submitted?.characters.single.prompt, '1girl, blue hair');
      expect(generated.submitted?.characters.single.negativePrompt, 'red hair');
      expect(
        container.read(generationParamsNotifierProvider),
        same(beforeParams),
      );
      expect(
        container.read(imageWorkflowControllerProvider),
        same(beforeWorkflow),
      );
      expect(
        container.read(characterPromptNotifierProvider),
        same(beforeCharacters),
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final gate in ['generation', 'bridge', 'cooldown']) {
    testWidgets(
      '$gate blocks variations before changing any draft or workflow',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            imageGenerationNotifierProvider.overrideWith(
              () => _Generation(gate == 'generation'),
            ),
            generationParamsNotifierProvider.overrideWith(_Params.new),
            kritaBridgeNotifierProvider.overrideWith(
              (ref) => _Bridge(gate == 'bridge'),
            ),
            generationCooldownProvider.overrideWith(
              () => _Cooldown(gate == 'cooldown'),
            ),
          ],
        );
        addTearDown(container.dispose);
        final params = container.read(generationParamsNotifierProvider);
        final workflow = container.read(imageWorkflowControllerProvider);
        final generation = container.read(imageGenerationNotifierProvider);
        late Future<void> Function() invoke;
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
                    invoke = () => ImageWorkflowLauncher.generateVariations(
                      context,
                      ref,
                      Uint8List(0),
                    );
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        );
        await invoke();
        await invoke();
        expect(container.read(generationParamsNotifierProvider), same(params));
        expect(container.read(imageWorkflowControllerProvider), same(workflow));
        expect(
          container.read(imageGenerationNotifierProvider),
          same(generation),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      },
    );
  }
}
