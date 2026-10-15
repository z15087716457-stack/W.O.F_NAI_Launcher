import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/enums/precise_ref_type.dart';
import 'package:nai_launcher/core/services/anlas_calculator.dart';
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_action_providers.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';

import '../../helpers/app_logger_test_isolation.dart';

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams(
    width: 512,
    height: 512,
    steps: 8,
    nSamples: 2,
    model: ImageModels.animeDiffusionV4Curated,
  );

  void reference() => state = state.copyWith(
    preciseReferences: [
      PreciseReference(image: Uint8List(1), type: PreciseRefType.character),
    ],
  );
}

class _BatchSize extends ImagesPerRequest {
  @override
  int build() => 2;
}

class _Subscription extends SubscriptionNotifier {
  @override
  SubscriptionState build() =>
      const SubscriptionState.loaded(UserSubscription(tier: 1));

  void tier(int value) => state = SubscriptionState.loaded(
    UserSubscription(tier: value, active: true),
  );
}

class _Workflow extends ImageWorkflowController {
  @override
  ImageWorkflowState build() => const ImageWorkflowState(
    upscale: UpscaleWorkflowSettings(backend: UpscaleBackend.novelai),
  );
  void backend(UpscaleBackend backend) =>
      state = state.copyWith(upscale: state.upscale.copyWith(backend: backend));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);

  Future<Uint8List> sourcePng({
    int steps = 28,
  }) => ImageSaveUtils.buildPrebuiltMetadataBytes(
    imageBytes: Uint8List.fromList(
      img.encodePng(img.Image(width: 16, height: 16)),
    ),
    metadata: {
      'Software': 'NovelAI',
      'Source': 'NovelAI Diffusion V4.5 Full',
      'Comment':
          '{"prompt":"synthetic source","seed":12345,"width":1024,"height":1024,"steps":$steps}',
    },
  );

  ProviderContainer quoteContainer() => ProviderContainer(
    overrides: [
      generationParamsNotifierProvider.overrideWith(_Params.new),
      subscriptionNotifierProvider.overrideWith(_Subscription.new),
    ],
  );

  test(
    'scrolling back gives a synchronous quote after providers dispose',
    () async {
      final bytes = await sourcePng();
      final images = [
        for (final id in ['scroll-a', 'scroll-b'])
          GeneratedImage(id: id, bytes: bytes, width: 1024, height: 1024),
      ];
      final container = quoteContainer();
      addTearDown(container.dispose);
      for (final image in images) {
        final sub = container.listen(
          imageVariationCostProvider(image),
          (_, _) {},
        );
        await container.read(generatedImageMetadataProvider(image).future);
        await container.pump();
        expect(container.read(imageVariationCostProvider(image)), 48);
        sub.close();
        await container.pump();
        await container.pump();
        expect(
          container.exists(generatedImageMetadataProvider(image)),
          isFalse,
        );
        expect(container.exists(imageVariationCostProvider(image)), isFalse);
      }
      final prices = <int?>[];
      final sub = container.listen(
        imageVariationCostProvider(images.first),
        (_, value) => prices.add(value),
        fireImmediately: true,
      );
      addTearDown(sub.close);
      expect(prices, [48]);
      expect(
        container.read(generatedImageMetadataProvider(images.first)).isLoading,
        isFalse,
      );
      (container.read(generationParamsNotifierProvider.notifier) as _Params)
          .reference();
      expect(container.read(imageVariationCostProvider(images.first)), 63);
      // The retained data is metadata only: subscription changes still reprice.
      (container.read(subscriptionNotifierProvider.notifier) as _Subscription)
          .tier(3);
      expect(container.read(imageVariationCostProvider(images.first)), 47);
    },
  );

  test(
    'cached PNG remains authoritative and changed source bytes invalidate it',
    () async {
      const fallback = NaiImageMetadata(prompt: 'stale fallback', steps: 8);
      final bytes = await sourcePng();
      final first = GeneratedImage(
        id: 'same-source',
        bytes: bytes,
        width: 1024,
        height: 1024,
        metadata: fallback,
      );
      final container = quoteContainer();
      addTearDown(container.dispose);
      var sub = container.listen(imageVariationCostProvider(first), (_, _) {});
      await container.read(generatedImageMetadataProvider(first).future);
      await container.pump();
      expect(container.read(imageVariationCostProvider(first)), 48);
      sub.close();
      await container.pump();
      await container.pump();
      final saved = first.copyWithFilePath('synthetic.png');
      sub = container.listen(imageVariationCostProvider(saved), (_, _) {});
      expect(container.read(imageVariationCostProvider(saved)), 48);
      expect(
        container
            .read(generatedImageMetadataProvider(saved))
            .valueOrNull
            ?.steps,
        28,
      );
      sub.close();
      await container.pump();
      await container.pump();
      final replacement = GeneratedImage(
        id: first.id,
        bytes: await sourcePng(steps: 50),
        width: 1024,
        height: 1024,
        metadata: fallback,
      );
      sub = container.listen(
        imageVariationCostProvider(replacement),
        (_, _) {},
      );
      addTearDown(sub.close);
      expect(
        container.read(generatedImageMetadataProvider(replacement)).isLoading,
        isTrue,
      );
      expect(container.read(imageVariationCostProvider(replacement)), isNull);
      await container.read(generatedImageMetadataProvider(replacement).future);
      await container.pump();
      expect(
        container
            .read(generatedImageMetadataProvider(replacement))
            .valueOrNull
            ?.steps,
        50,
      );
      expect(
        container.read(imageVariationCostProvider(replacement)),
        greaterThan(48),
      );
    },
  );

  test(
    'recent metadata retention is bounded and least recently used',
    () async {
      final bytes = await sourcePng();
      final images = [
        for (var index = 0; index < 65; index++)
          GeneratedImage(
            id: 'bounded-$index',
            bytes: bytes,
            width: 1024,
            height: 1024,
          ),
      ];
      final container = quoteContainer();
      addTearDown(container.dispose);
      Future<void> visit(GeneratedImage image) async {
        final sub = container.listen(
          generatedImageMetadataProvider(image),
          (_, _) {},
        );
        await container.read(generatedImageMetadataProvider(image).future);
        sub.close();
        await container.pump();
        await container.pump();
      }

      for (final image in images.take(64)) {
        await visit(image);
      }
      await visit(images.first); // Refresh A: B is now the least recently used.
      await visit(images.last);
      expect(
        container.read(generatedImageMetadataProvider(images.first)).isLoading,
        isFalse,
      );
      expect(
        container.read(generatedImageMetadataProvider(images[1])).isLoading,
        isTrue,
      );
      expect(
        container.read(generatedImageMetadataProvider(images.last)).isLoading,
        isFalse,
      );
      await container.read(generatedImageMetadataProvider(images[1]).future);
    },
  );

  test(
    'upscale quote follows selected image and backend, never the draft size',
    () {
      final small = GeneratedImage(
        id: 'small',
        bytes: Uint8List(0),
        width: 512,
        height: 512,
      );
      final large = GeneratedImage(
        id: 'large',
        bytes: Uint8List(0),
        width: 832,
        height: 1216,
      );
      final invalid = GeneratedImage(
        id: 'too-large',
        bytes: Uint8List(0),
        width: 2048,
        height: 2048,
      );
      final container = ProviderContainer(
        overrides: [
          generationParamsNotifierProvider.overrideWith(_Params.new),
          imageWorkflowControllerProvider.overrideWith(_Workflow.new),
          subscriptionNotifierProvider.overrideWith(_Subscription.new),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        imageUpscaleCostProvider(large),
        (_, _) {},
      );
      addTearDown(subscription.close);
      expect(container.read(imageUpscaleCostProvider(small)), 1);
      expect(container.read(imageUpscaleCostProvider(large)), 1);
      expect(container.read(imageUpscaleCostProvider(invalid)), isNull);
      (container.read(imageWorkflowControllerProvider.notifier) as _Workflow)
          .backend(UpscaleBackend.comfyui);
      expect(container.read(imageUpscaleCostProvider(large)), 0);
      (container.read(imageWorkflowControllerProvider.notifier) as _Workflow)
          .backend(UpscaleBackend.local);
      expect(container.read(imageUpscaleCostProvider(large)), 0);
    },
  );

  test(
    'reads seed from PNG when generated image metadata field is empty',
    () async {
      final png = Uint8List.fromList(
        img.encodePng(img.Image(width: 16, height: 16)),
      );
      final bytes = await ImageSaveUtils.buildPrebuiltMetadataBytes(
        imageBytes: png,
        metadata: {
          'Software': 'NovelAI',
          'Source': 'NovelAI Diffusion V4',
          'Comment':
              '{"prompt":"test image","seed":12345,"width":16,"height":16}',
        },
      );
      final image = GeneratedImage.create(bytes, width: 16, height: 16);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final metadata = await container.read(
        generatedImageMetadataProvider(image).future,
      );
      expect(image.metadata, isNull);
      expect(metadata?.seed, 12345);
      expect(metadata?.prompt, 'test image');
    },
  );

  test(
    'variation quote uses selected metadata, independent of main upscale price',
    () async {
      const metadata = NaiImageMetadata(
        prompt: 'selected source',
        model: ImageModels.animeDiffusionV45Full,
        width: 1024,
        height: 1024,
        steps: 28,
        strength: 0.6,
      );
      final image = GeneratedImage(
        id: 'source',
        bytes: Uint8List(0),
        width: 1024,
        height: 1024,
        metadata: metadata,
      );
      final container = ProviderContainer(
        overrides: [
          generationParamsNotifierProvider.overrideWith(_Params.new),
          imagesPerRequestProvider.overrideWith(_BatchSize.new),
          subscriptionNotifierProvider.overrideWith(_Subscription.new),
          estimatedCostProvider.overrideWithValue(0),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        imageVariationCostProvider(image),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(generatedImageMetadataProvider(image).future);
      final quote = container.read(imageVariationCostProvider(image));
      expect(
        quote,
        AnlasCalculator.calculateRequestCost(
          width: 1024,
          height: 1024,
          steps: 28,
          batchCount: 1,
          batchSize: 3,
          model: ImageModels.animeDiffusionV45Full,
          strength: 0.8,
          subscriptionTier: 0,
          smea: false,
          smeaDyn: false,
        ),
      );
      expect(quote, greaterThan(0));
    },
  );

  test('unknown image parameters do not borrow an unrelated price', () async {
    final image = GeneratedImage(
      id: 'unknown',
      bytes: Uint8List.fromList(
        img.encodePng(img.Image(width: 16, height: 16)),
      ),
      width: 512,
      height: 512,
    );
    final container = ProviderContainer(
      overrides: [estimatedCostProvider.overrideWithValue(99)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      imageVariationCostProvider(image),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(generatedImageMetadataProvider(image).future);
    expect(container.read(imageVariationCostProvider(image)), isNull);
    subscription.close();
    await container.pump();
    await container.pump();
    expect(
      container.read(generatedImageMetadataProvider(image)).isLoading,
      isFalse,
    );
    expect(container.read(imageVariationCostProvider(image)), isNull);
  });
}
