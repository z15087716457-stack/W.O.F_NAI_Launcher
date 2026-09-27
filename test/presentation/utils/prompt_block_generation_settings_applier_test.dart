import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/presentation/utils/prompt_block_generation_settings_applier.dart';

void main() {
  test(
    'model capability check rejects unsupported values before application',
    () {
      const settings = PromptBlockGenerationSettings(
        sampler: Samplers.kDpmppSde,
        noiseSchedule: NoiseSchedules.karras,
        cfgRescale: .2,
      );
      expect(
        () => validatePromptBlockGenerationSettings(
          settings,
          ImageModels.animeDiffusionV5Full,
        ),
        throwsStateError,
      );
      expect(
        () => validatePromptBlockGenerationSettings(
          settings,
          ImageModels.animeDiffusionV4Full,
        ),
        returnsNormally,
      );
    },
  );

  test('legacy dimensions do not count as reusable settings', () {
    const settings = PromptBlockGenerationSettings(width: 1216, height: 832);
    expect(settings.isEmpty, isTrue);
    expect(
      () => validatePromptBlockGenerationSettings(
        settings,
        ImageModels.animeDiffusionV5Full,
      ),
      returnsNormally,
    );
  });
}
