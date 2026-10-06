import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/enums/quality_tag_preset.dart';
import 'package:nai_launcher/core/network/request_builders/nai_image_request_builder.dart';
import 'package:nai_launcher/core/services/anlas_calculator.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/presentation/utils/official_image_variations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'V5 source projection matches observed official request and 27 Anlas quote',
    () async {
      final image = Uint8List.fromList(
        img.encodePng(img.Image(width: 512, height: 768)),
      );
      const prompt = '1girl, solo, portrait';
      const metadata = NaiImageMetadata(
        model: ImageModels.animeDiffusionV5Full,
        width: 512,
        height: 768,
        steps: 23,
        scale: 7,
        sampler: 'k_euler_ancestral',
        prompt: '$prompt, very aesthetic, masterpiece, no text',
        qualityTagHint: 1,
        ucPresetTagHint: 2,
        noiseSchedule: 'karras',
        strength: .2,
        noise: .5,
      );
      final projection = OfficialImageVariations.project(
        current: const ImageParams(
          prompt: 'unrelated draft',
          nSamples: 8,
          enhanceWorkflow: true,
          upscaledEnhance: true,
        ),
        source: image,
        width: 512,
        height: 768,
        metadata: metadata,
      );
      expect(projection.prompt, prompt);
      expect(projection.effectiveQualityTagPreset, QualityTagPreset.standard);
      expect(projection.enhanceWorkflow, isFalse);
      expect(projection.upscaledEnhance, isFalse);
      final result = await NAIImageRequestBuilder(
        params: projection.copyWith(
          nSamples: 3,
          seed: 597282670,
          extraNoiseSeed: 597282669,
        ),
        encodeVibe:
            (image, {required model, informationExtracted = 1.0}) async => '',
      ).build(sampler: 'k_euler_ancestral', isStream: true);
      final params = result.requestParameters;
      expect(result.requestData['model'], 'nai-diffusion-5-full');
      expect(result.requestData['action'], 'img2img');
      expect(params['params_version'], 4);
      expect(params['n_samples'], 3);
      expect(params['strength'], .8);
      expect(params['noise'], .1);
      expect(params['seed'], 597282670);
      expect(params['extra_noise_seed'], 597282669);
      expect(params['color_correct'], isFalse);
      expect(params['tag_hint_qt'], 1);
      expect(params['tag_hint_uc_preset'], 2);
      expect(result.effectivePrompt, metadata.prompt);
      expect(
        AnlasCalculator.calculateRequestCost(
          width: 512,
          height: 768,
          steps: 23,
          batchCount: 1,
          batchSize: 3,
          strength: .8,
          model: projection.model,
          smea: false,
          smeaDyn: false,
          subscriptionTier: 0,
        ),
        27,
      );
    },
  );

  test('unknown presets and characters cannot leak from a different draft', () {
    final params = OfficialImageVariations.project(
      current: const ImageParams(
        prompt: 'draft',
        negativePrompt: 'draft uc',
        qualityTagPreset: QualityTagPreset.standard,
        ucPreset: 0,
        characters: [CharacterPrompt(prompt: 'draft character')],
        useCoords: true,
      ),
      source: Uint8List(0),
      width: 832,
      height: 1216,
      metadata: const NaiImageMetadata(
        prompt: 'recorded text',
        negativePrompt: 'recorded uc',
      ),
    );
    expect(params.prompt, 'recorded text');
    expect(params.negativePrompt, 'recorded uc');
    expect(params.effectiveQualityTagPreset, QualityTagPreset.none);
    expect(params.ucPreset, 3);
    expect(params.characters, isEmpty);
    expect(params.useCoords, isFalse);
  });
}
