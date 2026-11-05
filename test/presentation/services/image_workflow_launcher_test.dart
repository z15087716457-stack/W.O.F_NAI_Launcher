import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_action_providers.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/services/image_workflow_launcher.dart';
import 'package:nai_launcher/presentation/utils/official_image_variations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, accountId: 'A');

  void switchTo(String id) {
    state = AuthState(status: AuthStatus.authenticated, accountId: id);
  }
}

class _Subscription extends SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionState.loaded(
    UserSubscription(
      tier: 1,
      active: true,
      trainingStepsLeft: TrainingStepsInfo(fixedTrainingStepsLeft: 1000),
    ),
  );

  void useOpus() =>
      state = SubscriptionState.loaded(state.subscription!.copyWith(tier: 3));
}

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
  testWidgets(
    'place on canvas preserves source and draft, reuses tile and requests focus each time',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => _MemoryStorage()),
          imageGenerationNotifierProvider.overrideWith(
            () => _Generation(false),
          ),
          generationParamsNotifierProvider.overrideWith(_Params.new),
        ],
      );
      addTearDown(container.dispose);
      final params = container.read(generationParamsNotifierProvider);
      final workflow = container.read(imageWorkflowControllerProvider);
      final bytes = await ImageSaveUtils.buildPrebuiltMetadataBytes(
        imageBytes: Uint8List.fromList(
          img.encodePng(img.Image(width: 8, height: 12)),
        ),
        metadata: {
          'Software': 'NovelAI',
          'Comment': '{"prompt":"original","seed":321}',
        },
      );
      late WidgetRef widgetRef;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, child) {
              widgetRef = ref;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(ImageWorkflowLauncher.placeOnCanvas(widgetRef, bytes), isTrue);
      final first = container
          .read(imageGenerationNotifierProvider)
          .currentImages
          .single;
      final focus = container.read(canvasHistoryFocusRequestProvider)!;
      expect(first.bytes, bytes);
      expect((first.width, first.height), (8, 12));
      expect(first.filePath, isNull);
      expect(container.read(generationPreviewSelectionProvider), first.id);
      expect(focus.imageId, first.id);
      expect(
        ImageWorkflowLauncher.placeOnCanvas(
          widgetRef,
          Uint8List.fromList(bytes),
        ),
        isTrue,
      );
      expect(
        container.read(imageGenerationNotifierProvider).currentImages.single.id,
        first.id,
      );
      expect(
        container.read(canvasHistoryFocusRequestProvider)!.revision,
        focus.revision + 1,
      );
      expect(container.read(generationParamsNotifierProvider), same(params));
      expect(container.read(imageWorkflowControllerProvider), same(workflow));
      expect(
        ImageWorkflowLauncher.placeOnCanvas(widgetRef, Uint8List(0)),
        isFalse,
      );
      expect(
        container.read(canvasHistoryFocusRequestProvider)!.revision,
        focus.revision + 1,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    },
  );

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
          authNotifierProvider.overrideWith(_Auth.new),
          subscriptionNotifierProvider.overrideWith(_Subscription.new),
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
  for (final change in ['none', 'account-restored', 'quote']) {
    testWidgets(
      'variation quote matches the three submitted images ($change)',
      (tester) async {
        const metadata = NaiImageMetadata(
          model: ImageModels.animeDiffusionV45Full,
          prompt: 'source prompt',
          steps: 28,
        );
        final source = GeneratedImage.create(
          Uint8List.fromList(img.encodePng(img.Image(width: 512, height: 768))),
          width: 1024,
          height: 1024,
          metadata: metadata,
        );
        final container = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWithValue(
              _MemoryStorage()
                ..values[StorageKeys.protectionWarnHighAnlasCost] = true
                ..values[StorageKeys.protectionHighAnlasCostThreshold] = 1,
            ),
            imageGenerationNotifierProvider.overrideWith(
              _CaptureGeneration.new,
            ),
            generationParamsNotifierProvider.overrideWith(_Params.new),
            authNotifierProvider.overrideWith(_Auth.new),
            subscriptionNotifierProvider.overrideWith(_Subscription.new),
            kritaBridgeNotifierProvider.overrideWith((ref) => _Bridge(false)),
            generationCooldownProvider.overrideWith(() => _Cooldown(false)),
            generatedImageMetadataProvider(
              source,
            ).overrideWith((ref) => metadata),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container
            .read(subscriptionNotifierProvider)
            .subscription;
        final projected = OfficialImageVariations.project(
          current: container.read(generationParamsNotifierProvider),
          source: source.bytes,
          width: 512,
          height: 768,
          metadata: metadata,
        );
        final total = variationRequestCost(projected, subscription);
        var backups = 0;
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
                      source.bytes,
                      sourceImage: source,
                      beforeSubmit: () async => backups++,
                    );
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        );
        final operation = invoke();
        await tester.pumpAndSettle();
        expect(find.text('$total Anlas'), findsOneWidget);
        expect(container.read(imageVariationCostProvider(source)), total);
        if (change == 'account-restored') {
          final auth = container.read(authNotifierProvider.notifier) as _Auth;
          auth.switchTo('B');
          auth.switchTo('A');
        } else if (change == 'quote') {
          (container.read(subscriptionNotifierProvider.notifier)
                  as _Subscription)
              .useOpus();
          expect(
            variationRequestCost(
              projected,
              container.read(subscriptionNotifierProvider).subscription,
            ),
            isNot(total),
          );
        }
        await tester.tap(find.text('Continue Generation'));
        await tester.pumpAndSettle();
        await operation;
        final generation =
            container.read(imageGenerationNotifierProvider.notifier)
                as _CaptureGeneration;
        if (change == 'none') {
          expect(generation.submitted?.prompt, projected.prompt);
          expect(
            variationRequestCost(generation.submitted!, subscription),
            total,
          );
          expect(backups, 1);
        } else {
          expect(generation.submitted, isNull);
          expect(backups, 0);
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

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
