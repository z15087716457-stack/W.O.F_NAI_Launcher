import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/services/anlas_calculator.dart';
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_action_providers.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams(
    width: 512,
    height: 512,
    steps: 8,
    nSamples: 2,
    model: ImageModels.animeDiffusionV4Curated,
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
          batchCount: 2,
          batchSize: 2,
          model: ImageModels.animeDiffusionV45Full,
          strength: 0.6,
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
      bytes: Uint8List(0),
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
  });
}
