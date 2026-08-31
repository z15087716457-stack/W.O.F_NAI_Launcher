import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/data/models/prompt/prompt_preset_mode.dart';
import 'package:nai_launcher/presentation/widgets/prompt/quality_tags_selector.dart';

void main() {
  test('V5 quality menu exposes Standard, Light, and None', () {
    expect(qualityNativeModesForModel(ImageModels.animeDiffusionV5Full), const [
      PromptPresetMode.naiDefault,
      PromptPresetMode.naiLight,
      PromptPresetMode.none,
    ]);
  });

  test('non-V5 quality menu keeps NAI Default and None only', () {
    expect(
      qualityNativeModesForModel(ImageModels.animeDiffusionV45Full),
      const [PromptPresetMode.naiDefault, PromptPresetMode.none],
    );
    expect(
      qualityVisibleModeForModel(
        ImageModels.animeDiffusionV45Full,
        PromptPresetMode.naiLight,
      ),
      PromptPresetMode.naiDefault,
    );
  });
}
