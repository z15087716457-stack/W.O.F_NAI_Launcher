import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_roll_coordinator.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';

import '../../../helpers/prompt_normalization_fixture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';

import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/datasources/remote/nai_image_generation_api_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/image/image_stream_chunk.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/image_save_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/notification_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';

class MockNAIImageGenerationApiService extends Mock
    implements NAIImageGenerationApiService {}

class _MockPillRollCoordinator extends Mock implements PillRollCoordinator {}

class TestSubscriptionNotifier extends SubscriptionNotifier {
  int refreshBalanceCallCount = 0;

  @override
  SubscriptionState build() {
    ref.keepAlive();
    return const SubscriptionState.loaded(
      UserSubscription(
        tier: 3,
        active: true,
        trainingStepsLeft: TrainingStepsInfo(fixedTrainingStepsLeft: 10000),
      ),
    );
  }

  @override
  void schedulePostBillingRefresh({
    Duration delay = SubscriptionNotifier.postBillingRefreshDelay,
  }) {
    refreshBalanceCallCount += 1;
  }
}

void main() {
  late Directory hiveTempDir;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    registerFallbackValue(const ImageParams());
    hiveTempDir = await Directory.systemTemp.createTemp(
      'generate_for_explore_test_',
    );
    Hive.init(hiveTempDir.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
    await Hive.openBox(StorageKeys.statisticsCacheBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveTempDir.exists()) {
      await hiveTempDir.delete(recursive: true);
    }
  });

  group('generateForExplore', () {
    late ProviderContainer container;
    late MockNAIImageGenerationApiService mockApiService;
    late TestSubscriptionNotifier subscriptionNotifier;

    ImageParams? capturedParams;
    final capturedRequests = <ImageParams>[];
    ImageParams? fallbackParams;
    var streamError = false;
    var streamUnsupported = false;
    var rollCalls = 0;
    Map<String, String> Function()? onRoll;
    void Function()? onStream;

    setUp(() async {
      capturedParams = null;
      capturedRequests.clear();
      fallbackParams = null;
      streamError = false;
      streamUnsupported = false;
      rollCalls = 0;
      onRoll = null;
      onStream = null;
      mockApiService = MockNAIImageGenerationApiService();
      final rollCoordinator = _MockPillRollCoordinator();
      when(rollCoordinator.rollAllLanesAndSync).thenAnswer((_) {
        rollCalls++;
        return onRoll?.call() ?? {};
      });

      when(
        () => mockApiService.generateImage(
          any(),
          onProgress: any(named: 'onProgress'),
          focusedInpaintEnabled: any(named: 'focusedInpaintEnabled'),
          minimumContextMegaPixels: any(named: 'minimumContextMegaPixels'),
          focusedSelectionRect: any(named: 'focusedSelectionRect'),
        ),
      ).thenAnswer((invocation) async {
        if (!streamUnsupported) fail('non-stream fallback was not expected');
        fallbackParams = invocation.positionalArguments.first as ImageParams;
        return ([_validImageBytes(width: 512, height: 768)], <int, String>{});
      });
      when(
        () => mockApiService.generateImageStream(
          any(),
          focusedInpaintEnabled: any(named: 'focusedInpaintEnabled'),
          minimumContextMegaPixels: any(named: 'minimumContextMegaPixels'),
          focusedSelectionRect: any(named: 'focusedSelectionRect'),
        ),
      ).thenAnswer((invocation) {
        capturedParams = invocation.positionalArguments.first as ImageParams;
        capturedRequests.add(capturedParams!);
        onStream?.call();
        if (streamError || streamUnsupported) {
          return Stream<ImageStreamChunk>.fromIterable([
            ImageStreamChunk.error(
              streamUnsupported ? 'streaming is not allowed' : 'boom',
            ),
          ]);
        }
        return Stream<ImageStreamChunk>.fromIterable([
          ImageStreamChunk.complete(
            _validImageBytes(width: 512, height: 768),
            sampleIndex: 0,
          ),
        ]);
      });

      container = ProviderContainer(
        overrides: [
          naiImageGenerationApiServiceProvider.overrideWithValue(
            mockApiService,
          ),
          subscriptionNotifierProvider.overrideWith(
            TestSubscriptionNotifier.new,
          ),
          pillRollCoordinatorProvider.overrideWithValue(rollCoordinator),
        ],
      );
      await container
          .read(notificationSettingsNotifierProvider.notifier)
          .setSoundEnabled(false);
      await container
          .read(imageSaveSettingsNotifierProvider.notifier)
          .setAutoSave(false);
      container.read(subscriptionNotifierProvider);
      subscriptionNotifier =
          container.read(subscriptionNotifierProvider.notifier)
              as TestSubscriptionNotifier;
    });

    tearDown(() async {
      container.dispose();
      await Hive.box(StorageKeys.settingsBox).clear();
    });

    for (final autoFormat in [false, true]) {
      for (final sdAutoConvert in [false, true]) {
        for (final entry in ['explore', 'single', 'batch']) {
          test(
            '$entry freezes gated prompts: format=$autoFormat SD=$sdAutoConvert',
            () async {
              final params = await configurePromptNormalization(
                container,
                autoFormat: autoFormat,
                sdAutoConvert: sdAutoConvert,
              );
              final charactersBefore = container.read(
                characterPromptNotifierProvider,
              );
              final lane = container.read(
                pillWorkspaceProvider(PillScopes.main).notifier,
              );
              lane.syncFromPlainText(params.prompt);
              final documentBefore = container
                  .read(pillWorkspaceProvider(PillScopes.main))
                  .document;
              final notifier = container.read(
                imageGenerationNotifierProvider.notifier,
              );
              if (entry == 'explore') {
                expect(await notifier.generateForExplore(params), isNotNull);
              } else {
                await notifier.generate(
                  params.copyWith(nSamples: entry == 'batch' ? 3 : 1),
                  imagesPerRequestOverride: 1,
                );
              }
              expect(capturedRequests, hasLength(entry == 'batch' ? 3 : 1));
              for (final request in capturedRequests) {
                expectNormalizedPromptParams(
                  request,
                  autoFormat: autoFormat,
                  sdAutoConvert: sdAutoConvert,
                );
              }
              expect(
                container.read(generationParamsNotifierProvider).prompt,
                normalizationPrompt,
              );
              expect(
                container.read(generationParamsNotifierProvider).negativePrompt,
                normalizationNegative,
              );
              expect(
                container.read(characterPromptNotifierProvider),
                charactersBefore,
              );
              expect(
                container.read(pillWorkspaceProvider(PillScopes.main)).document,
                documentBefore,
              );
              expect(
                rollCalls,
                entry == 'explore'
                    ? 0
                    : entry == 'batch'
                    ? 2
                    : 1,
              );
              expect(
                container.read(imageGenerationNotifierProvider).status,
                GenerationStatus.completed,
              );
            },
          );
        }
      }
    }

    for (final entry in ['explore', 'single', 'batch']) {
      test(
        '$entry preserves alias, fixed-tag and custom-preset composition',
        () async {
          final params = await configurePromptComposition(container);
          final notifier = container.read(
            imageGenerationNotifierProvider.notifier,
          );
          if (entry == 'explore') {
            expect(await notifier.generateForExplore(params), isNotNull);
          } else {
            await notifier.generate(
              params.copyWith(nSamples: entry == 'batch' ? 2 : 1),
              imagesPerRequestOverride: 1,
            );
          }
          expect(capturedRequests, hasLength(entry == 'batch' ? 2 : 1));
          for (final request in capturedRequests) {
            expectComposedPromptParams(request);
          }
          expect(
            container.read(generationParamsNotifierProvider).prompt,
            '<lighting>，blue eyes',
          );
        },
      );
    }

    test(
      'batch normalizes each new roll and keeps slot-to-request pairing',
      () async {
        final params = await configurePromptNormalization(
          container,
          autoFormat: true,
          sdAutoConvert: true,
        );
        final events = <GenerationBatchEvent>[];
        onRoll = () {
          final next = 'roll $rollCalls，(cinematic lighting:1.3)';
          final chars = container.read(characterPromptNotifierProvider);
          container
              .read(characterPromptNotifierProvider.notifier)
              .updateCharacter(
                chars.characters.first.copyWith(
                  prompt: '(artist$rollCalls:1.4)',
                ),
              );
          return {
            PillScopes.main: next,
            PillScopes.negative: '(bad hands:1.2)，roll $rollCalls',
          };
        };
        await container
            .read(imageGenerationNotifierProvider.notifier)
            .generate(
              params.copyWith(nSamples: 3),
              imagesPerRequestOverride: 1,
              onBatchEvent: events.add,
            );
        expect(capturedRequests.map((p) => p.prompt), [
          'girl, blue dress',
          'roll 1, 1.3::cinematic lighting::',
          'roll 2, 1.3::cinematic lighting::',
        ]);
        expect(capturedRequests.map((p) => p.characters.first.prompt), [
          '1.4::ralada747372 ::',
          '1.4::artist1 ::',
          '1.4::artist2 ::',
        ]);
        expect(capturedRequests.skip(1).map((p) => p.negativePrompt), [
          '1.2::bad hands::, roll 1',
          '1.2::bad hands::, roll 2',
        ]);
        expect(rollCalls, 2);
        expect(
          events
              .where((e) => e.kind == GenerationBatchEventKind.start)
              .map((e) => e.slotStart),
          [1, 2, 3],
        );
        expect(
          events
              .where((e) => e.kind == GenerationBatchEventKind.complete)
              .map((e) => e.slotStart),
          [1, 2, 3],
        );
      },
    );

    test(
      'stream fallback reuses frozen prompts after UI and settings change',
      () async {
        final params = await configurePromptNormalization(
          container,
          autoFormat: true,
          sdAutoConvert: true,
        );
        streamUnsupported = true;
        onStream = () {
          container.read(autoFormatPromptSettingsProvider.notifier).set(false);
          container
              .read(sdSyntaxAutoConvertSettingsProvider.notifier)
              .set(false);
          container
              .read(generationParamsNotifierProvider.notifier)
              .updatePrompt('later，draft');
          final chars = container.read(characterPromptNotifierProvider);
          container
              .read(characterPromptNotifierProvider.notifier)
              .updateCharacter(
                chars.characters.first.copyWith(prompt: 'later character'),
              );
        };
        final result = await container
            .read(imageGenerationNotifierProvider.notifier)
            .generateForExplore(params);
        expect(result, isNotNull);
        expect(fallbackParams, same(capturedRequests.single));
        expectNormalizedPromptParams(
          fallbackParams!,
          autoFormat: true,
          sdAutoConvert: true,
        );
        expect(rollCalls, 0);
      },
    );

    test(
      'returns materialized seed and image, bypasses batch branch',
      () async {
        // 即使 imagesPerRequest>1，探索入口也必须走单张路径。
        container.read(imagesPerRequestProvider.notifier).set(3);
        final params = container
            .read(generationParamsNotifierProvider)
            .copyWith(prompt: '1girl', width: 512, height: 768, nSamples: 5);

        final result = await container
            .read(imageGenerationNotifierProvider.notifier)
            .generateForExplore(params);

        expect(result, isNotNull);
        // nSamples 强制 1（批次分支会共享提示词，探索不能走）。
        expect(capturedParams!.nSamples, 1);
        // 随机种子已实体化：结果 seed = 实际请求 seed，且非 -1。
        expect(capturedParams!.seed, isNot(-1));
        expect(result!.seed, capturedParams!.seed);
        expect(result.imageBytes, isNotEmpty);
        expect(result.imageWidth, 512);
        expect(result.imageHeight, 768);
        expect(result.elapsedMs, greaterThanOrEqualTo(0));
        // 自动保存关闭时 filePath 为 null（runner 用字节直写兜底）。
        expect(result.filePath, isNull);

        final state = container.read(imageGenerationNotifierProvider);
        expect(state.status, GenerationStatus.completed);
        expect(state.currentImages, hasLength(1));
        expect(subscriptionNotifier.refreshBalanceCallCount, 1);
      },
    );

    test('failure returns null and leaves error in state', () async {
      streamError = true;
      final params = container
          .read(generationParamsNotifierProvider)
          .copyWith(prompt: 'fail me');

      final result = await container
          .read(imageGenerationNotifierProvider.notifier)
          .generateForExplore(params);

      expect(result, isNull);
      final state = container.read(imageGenerationNotifierProvider);
      expect(state.status, GenerationStatus.error);
      expect(state.errorMessage, contains('boom'));
      // 失败不记账但照常计划余额刷新。
      expect(subscriptionNotifier.refreshBalanceCallCount, 1);
    });
  });
}

Uint8List _validImageBytes({required int width, required int height}) {
  return Uint8List.fromList(
    img.encodePng(img.Image(width: width, height: height)),
  );
}
