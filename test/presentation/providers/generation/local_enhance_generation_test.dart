import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/data/datasources/remote/nai_image_generation_api_service.dart';
import 'package:nai_launcher/data/models/image/image_operation.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/image/image_stream_chunk.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/data/services/image_metadata_service.dart';
import 'package:nai_launcher/data/services/local_upscale_service.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/image_save_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';

class _Api extends Mock implements NAIImageGenerationApiService {}

class _Upscale extends Mock implements LocalUpscaleService {}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams(
    prompt: 'user draft',
    seed: 789,
    width: 832,
    height: 1216,
  );
}

class _Save extends ImageSaveSettingsNotifier {
  @override
  ImageSaveSettings build() => const ImageSaveSettings(autoSave: false);
}

class _Subscription extends SubscriptionNotifier {
  @override
  SubscriptionState build() =>
      const SubscriptionState.loaded(UserSubscription(tier: 3));
  @override
  void schedulePostBillingRefresh({Duration delay = Duration.zero}) {}
}

Uint8List _png(int w, int h) =>
    Uint8List.fromList(img.encodePng(img.Image(width: w, height: h)));

Future<void> _until(bool Function() ready) async {
  for (var i = 0; i < 500; i++) {
    if (ready()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Generation did not reach native post-processing');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUpAll(() async {
    registerFallbackValue(const ImageParams());
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(LocalUpscaleCancellation());
    temp = await Directory.systemTemp.createTemp('studio_local_enhance_test_');
    Hive.init(temp.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
    await Hive.openBox(StorageKeys.statisticsCacheBox);
  });
  setUp(() async => Hive.box(StorageKeys.settingsBox).clear());
  tearDownAll(() async {
    await Hive.close();
    await temp.delete(recursive: true);
  });

  for (final scenario in [
    'stream',
    'empty-stream',
    'stream-denied',
    'batch',
    'multiple-samples',
    'failure',
    'cancel',
    'cancel-multiple',
    'cancel-after-first',
    'frozen-settings',
    'missing-model',
    'closed',
    'variations',
    'explore',
  ]) {
    test('automatic local enhancement: $scenario', () async {
      final cancelScenario = scenario.startsWith('cancel');
      final api = _Api();
      final service = _Upscale();
      final raw = _png(48, 32);
      final pending = Completer<LocalUpscaleResult>();
      final requests = <ImageParams>[];
      final inferred = <(String, double)>[];
      LocalUpscaleCancellation? activeCancellation;
      when(() => api.cancelGeneration()).thenReturn(null);
      when(() => api.generateImageStream(any())).thenAnswer((call) {
        final params = call.positionalArguments.single as ImageParams;
        requests.add(params);
        if (scenario == 'empty-stream') return const Stream.empty();
        if (scenario == 'stream-denied') {
          return Stream.fromIterable([
            ImageStreamChunk.error('Streaming not allowed'),
          ]);
        }
        return Stream.fromIterable([
          for (var i = 0; i < params.nSamples; i++)
            ImageStreamChunk.complete(raw, sampleIndex: i),
        ]);
      });
      when(
        () => api.generateImage(any(), onProgress: any(named: 'onProgress')),
      ).thenAnswer((_) async => ([raw], <int, String>{}));
      when(
        () => service.upscale(
          any(),
          modelId: any(named: 'modelId'),
          scale: any(named: 'scale'),
          cancellation: any(named: 'cancellation'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((call) async {
        inferred.add((
          call.namedArguments[#modelId] as String,
          call.namedArguments[#scale] as double,
        ));
        activeCancellation =
            call.namedArguments[#cancellation] as LocalUpscaleCancellation;
        if ((cancelScenario &&
                (scenario != 'cancel-after-first' || inferred.length == 2)) ||
            scenario == 'frozen-settings') {
          return pending.future;
        }
        if (scenario == 'failure') {
          throw const LocalUpscaleException(LocalUpscaleError.processFailed);
        }
        final bytes = await ImageSaveUtils.inheritSourceMetadata(
          imageBytes: _png(72, 48),
          sourceBytes: call.positionalArguments.single as Uint8List,
          width: 72,
          height: 48,
        );
        return LocalUpscaleResult(bytes, 72, 48);
      });
      final container = ProviderContainer(
        overrides: [
          generationParamsNotifierProvider.overrideWith(_Params.new),
          imageSaveSettingsNotifierProvider.overrideWith(_Save.new),
          subscriptionNotifierProvider.overrideWith(_Subscription.new),
          naiImageGenerationApiServiceProvider.overrideWithValue(api),
          localUpscaleServiceProvider.overrideWithValue(service),
          localUpscaleModelsProvider.overrideWith(
            (ref) async => [
              localUpscaleCatalog.first.withInstalled(
                scenario != 'missing-model',
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);
      final draft = container.read(generationParamsNotifierProvider);
      final workflow = container.read(imageWorkflowControllerProvider.notifier);
      workflow.openTemporaryTool(_png(1248, 1824), ImageWorkflowMode.enhance);
      workflow.setEnhanceLocalUpscale();
      if (scenario == 'closed') workflow.closeTemporaryTool();
      final params = container
          .read(generationRequestParamsProvider)
          .copyWith(nSamples: scenario == 'batch' ? 2 : 1);
      expect(params.sourceImage, isNull);
      expect(params.width, draft.width);
      expect(params.height, draft.height);
      expect(params.enhanceWorkflow, isFalse);
      expect(params.upscaledEnhance, isFalse);
      final notifier = container.read(imageGenerationNotifierProvider.notifier);
      final work = scenario == 'explore'
          ? notifier.generateForExplore(params).then<void>((_) {})
          : notifier.generate(
              params,
              imagesPerRequestOverride:
                  [
                    'multiple-samples',
                    'cancel-multiple',
                    'cancel-after-first',
                  ].contains(scenario)
                  ? 2
                  : 1,
              operation: scenario == 'variations'
                  ? ImageOperation.variations
                  : null,
            );
      if (cancelScenario || scenario == 'frozen-settings') {
        await _until(
          () =>
              container.read(localUpscaleTaskProvider).running &&
              (scenario != 'cancel-after-first' || inferred.length == 2),
        );
        expect(
          container.read(imageGenerationNotifierProvider).isGenerating,
          isTrue,
        );
        expect(
          container.read(imageGenerationNotifierProvider).history,
          hasLength(scenario == 'cancel-after-first' ? 1 : 0),
        );
        expect(
          container.read(imageGenerationNotifierProvider).currentImages,
          hasLength(scenario == 'cancel-after-first' ? 1 : 0),
        );
        if (cancelScenario) {
          notifier.cancel();
          expect(activeCancellation!.isCancelled, isTrue);
        } else {
          workflow.updateLocalUpscaleScale(3);
          workflow.updateLocalUpscaleModel('rtx');
        }
        pending.complete(LocalUpscaleResult(_png(72, 48), 72, 48));
      }
      await work;
      final state = container.read(imageGenerationNotifierProvider);
      if (scenario == 'missing-model') {
        expect(requests, isEmpty);
        expect(inferred, isEmpty);
        expect(state.status, GenerationStatus.error);
      } else if (cancelScenario) {
        expect(state.status, GenerationStatus.cancelled);
        expect(state.history, hasLength(scenario == 'cancel' ? 1 : 2));
        expect(
          state.history.where((image) => image.width == 48),
          hasLength(scenario == 'cancel-multiple' ? 2 : 1),
        );
        expect(
          state.history.where((image) => image.width == 72),
          hasLength(scenario == 'cancel-after-first' ? 1 : 0),
        );
      } else {
        expect(state.status, GenerationStatus.completed);
        final excluded = ['closed', 'variations', 'explore'].contains(scenario);
        final count = scenario == 'batch' || scenario == 'multiple-samples'
            ? 2
            : 1;
        expect(inferred.length, excluded ? 0 : count);
        expect(state.currentImages, hasLength(count));
        final success = !excluded && scenario != 'failure';
        expect(state.currentImages.first.width, success ? 72 : 48);
        expect(state.currentImages.first.height, success ? 48 : 32);
        if (success) {
          expect(
            state.currentImages.every(
              (image) => image.operation == ImageOperation.upscale,
            ),
            isTrue,
          );
          expect(
            state.currentImages.every((image) => image.originalBytes == null),
            isTrue,
          );
          expect(state.history, hasLength(count));
          expect(state.history.where((image) => image.width == 48), isEmpty);
          expect(
            state.history.map((image) => image.id).toSet(),
            state.currentImages.map((image) => image.id).toSet(),
          );
          expect(
            state.currentImages.map((image) => image.batchIndex).toList(),
            List.generate(count, (i) => i),
          );
          if (scenario != 'frozen-settings') {
            final metadata = await ImageMetadataService().getMetadataFromBytes(
              state.currentImages.first.bytes,
            );
            expect(metadata!.prompt, contains('user draft'));
          }
        }
        if (scenario == 'failure') {
          expect(requests, hasLength(1));
          expect(state.history, hasLength(1));
          expect(
            container.read(localUpscaleTaskProvider).error,
            LocalUpscaleError.processFailed,
          );
        }
        if (scenario == 'frozen-settings') {
          expect(inferred.single, ('anime', 1.5));
        }
      }
      expect(container.read(generationParamsNotifierProvider), same(draft));
      if (requests.isNotEmpty) {
        expect(
          requests.every(
            (request) =>
                request.width == draft.width && request.height == draft.height,
          ),
          isTrue,
        );
      }
    });
  }
}
