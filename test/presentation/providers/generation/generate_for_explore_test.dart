import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    var streamError = false;

    setUp(() async {
      capturedParams = null;
      streamError = false;
      mockApiService = MockNAIImageGenerationApiService();

      when(
        () => mockApiService.generateImage(
          any(),
          onProgress: any(named: 'onProgress'),
          focusedInpaintEnabled: any(named: 'focusedInpaintEnabled'),
          minimumContextMegaPixels: any(named: 'minimumContextMegaPixels'),
          focusedSelectionRect: any(named: 'focusedSelectionRect'),
        ),
      ).thenAnswer((_) async => fail('non-stream fallback was not expected'));
      when(
        () => mockApiService.generateImageStream(
          any(),
          focusedInpaintEnabled: any(named: 'focusedInpaintEnabled'),
          minimumContextMegaPixels: any(named: 'minimumContextMegaPixels'),
          focusedSelectionRect: any(named: 'focusedSelectionRect'),
        ),
      ).thenAnswer((invocation) {
        capturedParams = invocation.positionalArguments.first as ImageParams;
        if (streamError) {
          return Stream<ImageStreamChunk>.fromIterable([
            ImageStreamChunk.error('boom'),
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
