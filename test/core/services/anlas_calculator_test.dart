import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/enums/precise_ref_type.dart';
import 'package:nai_launcher/core/services/anlas_calculator.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';

void main() {
  const model = 'nai-diffusion-4-5-full';

  group('AnlasCalculator base pricing', () {
    test('matches the web formula at non-default step counts', () {
      final cost = AnlasCalculator.calculateFromValues(
        width: 512,
        height: 768,
        steps: 10,
        nSamples: 1,
        smea: false,
        smeaDyn: false,
        model: model,
      );

      expect(cost, 4);
    });

    test('rounds the base price before applying SMEA multipliers', () {
      final smeaCost = AnlasCalculator.calculateFromValues(
        width: 512,
        height: 768,
        steps: 28,
        nSamples: 1,
        smea: true,
        smeaDyn: false,
        model: model,
      );
      final dynamicSmeaCost = AnlasCalculator.calculateFromValues(
        width: 512,
        height: 768,
        steps: 28,
        nSamples: 1,
        smea: true,
        smeaDyn: true,
        model: model,
      );

      expect(smeaCost, 10);
      expect(dynamicSmeaCost, 12);
    });

    test('uses inpaint strength instead of full-strength generation cost', () {
      final cost = AnlasCalculator.calculate(
        const ImageParams(
          model: model,
          action: ImageGenerationAction.infill,
          width: 1024,
          height: 1024,
          steps: 28,
          inpaintStrength: 0.5,
        ),
      );

      expect(cost, 10);
    });

    test('recognizes the current furry V3 model id', () {
      final cost = AnlasCalculator.calculateFromValues(
        width: 1024,
        height: 1024,
        steps: 28,
        nSamples: 1,
        smea: false,
        smeaDyn: false,
        model: 'nai-diffusion-furry-3',
      );

      expect(cost, 20);
    });

    test('uses the web model threshold for effective auto-SMEA', () {
      const belowThreshold = ImageParams(
        model: 'nai-diffusion-3',
        width: 1472,
        height: 1472,
        steps: 28,
        smeaAuto: true,
      );
      const aboveThreshold = ImageParams(
        model: 'nai-diffusion-3',
        width: 1536,
        height: 1536,
        steps: 28,
        smeaAuto: true,
      );
      const furryV3 = ImageParams(
        model: 'nai-diffusion-furry-3',
        width: 1024,
        height: 1088,
        steps: 28,
        smeaAuto: true,
      );
      const v4 = ImageParams(
        model: model,
        width: 1536,
        height: 1536,
        steps: 28,
        smeaAuto: true,
      );

      expect(belowThreshold.effectiveSmea, isFalse);
      expect(aboveThreshold.effectiveSmea, isTrue);
      expect(aboveThreshold.effectiveSmeaDyn, isFalse);
      expect(furryV3.effectiveSmea, isFalse);
      expect(v4.effectiveSmea, isFalse);
      expect(
        AnlasCalculator.calculate(aboveThreshold),
        AnlasCalculator.calculateFromValues(
          width: 1536,
          height: 1536,
          steps: 28,
          nSamples: 1,
          smea: true,
          smeaDyn: false,
          model: 'nai-diffusion-3',
        ),
      );
    });

    test('disables SMEA for img2img and applies redraw strength', () {
      final params = ImageParams(
        model: 'nai-diffusion-3',
        action: ImageGenerationAction.img2img,
        sourceImage: Uint8List.fromList([1, 2, 3]),
        width: 1536,
        height: 1536,
        steps: 28,
        strength: 0.5,
        smea: true,
        smeaDyn: true,
      );

      expect(params.effectiveSmea, isFalse);
      expect(params.effectiveSmeaDyn, isFalse);
      expect(
        AnlasCalculator.calculate(params),
        AnlasCalculator.calculateFromValues(
          width: 1536,
          height: 1536,
          steps: 28,
          nSamples: 1,
          smea: false,
          smeaDyn: false,
          model: 'nai-diffusion-3',
          strength: 0.5,
        ),
      );
    });

    test('returns the official invalid sentinel above the per-image cap', () {
      final cost = AnlasCalculator.calculateFromValues(
        width: 4096,
        height: 4096,
        steps: 50,
        nSamples: 1,
        smea: true,
        smeaDyn: true,
        model: model,
      );

      expect(cost, AnlasCalculator.invalidCost);
    });
  });

  group('AnlasCalculator request pricing', () {
    test('applies the Opus free image once per request', () {
      final cost = AnlasCalculator.calculateRequestCost(
        width: 1024,
        height: 1024,
        steps: 28,
        batchCount: 2,
        batchSize: 3,
        smea: false,
        smeaDyn: false,
        model: model,
        subscriptionTier: AnlasCalculator.opusTier,
      );

      expect(cost, 80);
    });

    test('applies the Opus free image to base-image requests (img2img free too)', () {
      // 官方 SDK 免费判定不含底图排除：img2img/infill 满足尺寸/步数同样免费。
      // strength 先作用于单价再免费：ceil(20×0.5)=10 → 免费 0。
      final cost = AnlasCalculator.calculateRequestCost(
        width: 1024,
        height: 1024,
        steps: 28,
        batchCount: 1,
        batchSize: 1,
        smea: false,
        smeaDyn: false,
        model: model,
        subscriptionTier: AnlasCalculator.opusTier,
        strength: 0.5,
      );

      expect(cost, 0);
    });

    test('applies the Opus free image even with character references', () {
      // 修正后的官方规则：PR 是独立附加费（+5/参考），不取消 Opus 免费资格。
      // 免费条件下基础为 0，只收 PR 附加费 5。
      final cost = AnlasCalculator.calculateRequestCost(
        width: 1024,
        height: 1024,
        steps: 28,
        batchCount: 1,
        batchSize: 1,
        smea: false,
        smeaDyn: false,
        model: model,
        subscriptionTier: AnlasCalculator.opusTier,
        extraPerSampleCost: 5,
      );

      expect(cost, 5);
    });

    test('keeps per-image, per-request, and one-time fees distinct', () {
      final cost = AnlasCalculator.calculateRequestCost(
        width: 1024,
        height: 1024,
        steps: 28,
        batchCount: 2,
        batchSize: 3,
        smea: false,
        smeaDyn: false,
        model: model,
        subscriptionTier: AnlasCalculator.opusTier,
        extraPerSampleCost: 5,
        extraPerRequestCost: 2,
        oneTimeCost: 4,
      );

      expect(cost, 118);
    });
  });

  group('AnlasCalculator upscale pricing', () {
    test(
      'uses the official input-area tiers instead of output generation cost',
      () {
        expect(
          AnlasCalculator.calculateNovelAiUpscaleCost(
            inputWidth: 512,
            inputHeight: 512,
            scale: 4,
          ),
          1,
        );
        expect(
          AnlasCalculator.calculateNovelAiUpscaleCost(
            inputWidth: 512,
            inputHeight: 768,
            scale: 4,
          ),
          2,
        );
        expect(
          AnlasCalculator.calculateNovelAiUpscaleCost(
            inputWidth: 1024,
            inputHeight: 1024,
            scale: 4,
          ),
          7,
        );
      },
    );

    test('applies the Opus threshold and reports unsupported input sizes', () {
      expect(
        AnlasCalculator.calculateNovelAiUpscaleCost(
          inputWidth: 640,
          inputHeight: 640,
          scale: 4,
          subscriptionTier: AnlasCalculator.opusTier,
        ),
        0,
      );
      expect(
        AnlasCalculator.calculateNovelAiUpscaleCost(
          inputWidth: 1025,
          inputHeight: 1024,
          scale: 4,
        ),
        AnlasCalculator.invalidCost,
      );
    });
  });

  group('AnlasCalculator Vibe pricing', () {
    test('charges encoding only for enabled uncached raw Vibes', () {
      final rawImage = Uint8List.fromList([1, 2, 3]);
      final params = ImageParams(
        model: model,
        vibeReferencesV4: [
          VibeReference(
            displayName: 'enabled',
            vibeEncoding: '',
            rawImageData: rawImage,
            sourceType: VibeSourceType.rawImage,
          ),
          VibeReference(
            displayName: 'disabled',
            vibeEncoding: '',
            rawImageData: rawImage,
            sourceType: VibeSourceType.rawImage,
            enabled: false,
          ),
        ],
      );

      expect(AnlasCalculator.resolveVibeEncodingCost(params), 2);
    });

    test('re-encodes raw-backed Vibes when their model changed', () {
      final rawImage = Uint8List.fromList([1, 2, 3]);
      final staleParams = ImageParams(
        model: model,
        vibeReferencesV4: [
          VibeReference(
            displayName: 'stale',
            vibeEncoding: 'encoded-for-v4',
            rawImageData: rawImage,
            encodingModel: 'nai-diffusion-4-full',
            sourceType: VibeSourceType.naiv4vibe,
          ),
        ],
      );
      final currentParams = staleParams.copyWith(
        vibeReferencesV4: [
          staleParams.vibeReferencesV4.single.copyWith(encodingModel: model),
        ],
      );

      expect(AnlasCalculator.resolveVibeEncodingCost(staleParams), 2);
      expect(AnlasCalculator.resolveVibeEncodingCost(currentParams), 0);
    });

    test('Precise Reference suppresses mutually exclusive Vibe fees', () {
      final rawImage = Uint8List.fromList([1, 2, 3]);
      final params = ImageParams(
        model: model,
        preciseReferences: [
          PreciseReference(image: rawImage, type: PreciseRefType.character),
        ],
        vibeReferencesV4: [
          VibeReference(
            displayName: 'raw-vibe',
            vibeEncoding: '',
            rawImageData: rawImage,
            sourceType: VibeSourceType.rawImage,
          ),
        ],
      );

      expect(AnlasCalculator.resolveVibeEncodingCost(params), 0);
      expect(AnlasCalculator.resolveVibeReferenceExtraCost(params), 0);
    });

    test('charges two Anlas for every Vibe after the fourth per request', () {
      final params = ImageParams(
        model: model,
        vibeReferencesV4: List.generate(
          6,
          (index) => VibeReference(
            displayName: 'vibe-$index',
            vibeEncoding: 'encoded-$index',
            sourceType: VibeSourceType.naiv4vibe,
          ),
        ),
      );

      expect(AnlasCalculator.resolveVibeReferenceExtraCost(params), 4);
    });

    test('does not charge Vibe extras for inpainting', () {
      final params = ImageParams(
        model: model,
        action: ImageGenerationAction.infill,
        vibeReferencesV4: List.generate(
          5,
          (index) => VibeReference(
            displayName: 'vibe-$index',
            vibeEncoding: 'encoded-$index',
            sourceType: VibeSourceType.naiv4vibe,
          ),
        ),
      );

      expect(AnlasCalculator.resolveVibeReferenceExtraCost(params), 0);
    });
  });

  group('Opus 免费与 PR 附加费（PR 不取消免费资格）', () {
    int prCost({
      int width = 832,
      int height = 1216,
      int steps = 28,
      int tier = AnlasCalculator.opusTier,
      double strength = 1.0,
      int prFee = 0,
    }) {
      return AnlasCalculator.calculateRequestCost(
        width: width,
        height: height,
        steps: steps,
        batchCount: 1,
        batchSize: 1,
        smea: false,
        smeaDyn: false,
        model: model,
        subscriptionTier: tier,
        strength: strength,
        extraPerSampleCost: prFee,
      );
    }

    test('Opus 默认尺寸无 PR：基础免费 = 0', () {
      expect(prCost(), 0);
    });

    test('Opus 默认尺寸 + 1PR：只收 5 点附加费（基础照免）', () {
      expect(prCost(prFee: 5), 5);
    });

    test('Opus 默认尺寸 + 2PR：10 点', () {
      expect(prCost(prFee: 10), 10);
    });

    test('非 Opus 默认尺寸 + 1PR：基础 20 + 5 = 25', () {
      expect(prCost(tier: 0, prFee: 5), 25);
    });

    test('Opus 大尺寸 + 1PR：基础照收 + 5', () {
      final base = prCost(width: 1536, height: 1536);
      expect(base, greaterThan(0));
      expect(prCost(width: 1536, height: 1536, prFee: 5), base + 5);
    });

    test('Opus 图生图 1216×832 str0.7：免费（实证 case：误显 14 → 实扣 0）', () {
      expect(prCost(width: 1216, height: 832, strength: 0.7), 0);
    });

    test('非 Opus 图生图 1216×832 str0.7：14 点', () {
      expect(prCost(width: 1216, height: 832, strength: 0.7, tier: 0), 14);
    });

    test('Opus 底图但超尺寸：不免费，PR 附加费照加', () {
      final base = prCost(width: 1536, height: 1536, strength: 0.7);
      expect(base, greaterThan(0));
      expect(prCost(width: 1536, height: 1536, strength: 0.7, prFee: 5), base + 5);
    });

    test('Opus 超 28 步：不免费', () {
      expect(prCost(steps: 40), greaterThan(0));
    });
  });
}
