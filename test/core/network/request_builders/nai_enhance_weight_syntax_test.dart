import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/request_builders/nai_image_request_builder.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';

void main() {
  for (final entry in {
    'girl, blue dress': 'girl, blue dress, -2::upscaled, blurry::,',
    'girl, text:hello': 'girl, -2::upscaled, blurry::,text:hello',
    'girl, -2::upscaled, blurry::,': 'girl, -2::upscaled, blurry::,',
  }.entries) {
    test(
      'Enhance fixed weight has identical request bytes: ${entry.key}',
      () async {
        final result = await NAIImageRequestBuilder(
          params: ImageParams(
            model: 'nai-diffusion-4-5-full',
            prompt: entry.key,
            qualityToggle: false,
            ucPreset: 3,
            enhanceWorkflow: true,
            seed: 1,
          ),
          encodeVibe:
              (image, {required model, informationExtracted = 1.0}) async =>
                  throw StateError('No vibe expected'),
        ).build(sampler: 'k_euler');
        expect(result.requestData['input'], entry.value);
        expect(
          result.requestParameters['v4_prompt']['caption']['base_caption'],
          entry.value,
        );
      },
    );
  }
}
