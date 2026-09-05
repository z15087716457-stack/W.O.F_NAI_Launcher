import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/enums/quality_tag_preset.dart';
import 'package:nai_launcher/data/models/fixed_tag/fixed_tag_entry.dart';
import 'package:nai_launcher/data/models/fixed_tag/fixed_tag_prompt_type.dart';
import 'package:nai_launcher/presentation/providers/fixed_tags_provider.dart';
import 'package:nai_launcher/presentation/providers/quality_preset_provider.dart';
import 'package:nai_launcher/presentation/providers/uc_preset_provider.dart';
import 'package:nai_launcher/presentation/providers/tag_library_page_provider.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart' as ui;
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';

const normalizationPrompt = 'girl，blue dress';
const normalizationNegative = '(cinematic lighting:1.3), blue eyes';
const normalizationCharacters = [
  ui.CharacterPrompt(
    id: 'first',
    name: 'First',
    prompt: '(ralada747372:1.4)',
    negativePrompt: 'bad hands，low quality',
  ),
  ui.CharacterPrompt(
    id: 'disabled',
    name: 'Disabled',
    prompt: '(never send:1.5)',
    enabled: false,
  ),
  ui.CharacterPrompt(
    id: 'second',
    name: 'Second',
    prompt: 'blue hair，red dress',
    negativePrompt: '(bad anatomy:1.2)',
  ),
];

Future<ImageParams> configurePromptNormalization(
  ProviderContainer container, {
  required bool autoFormat,
  required bool sdAutoConvert,
}) async {
  container.read(autoFormatPromptSettingsProvider.notifier).set(autoFormat);
  container
      .read(sdSyntaxAutoConvertSettingsProvider.notifier)
      .set(sdAutoConvert);
  final characters = container.read(characterPromptNotifierProvider.notifier);
  characters.replaceAll(normalizationCharacters);
  characters.setGlobalAiChoice(false);
  final params = container.read(generationParamsNotifierProvider.notifier);
  params.updatePrompt(normalizationPrompt);
  params.updateNegativePrompt(normalizationNegative);
  await Future<void>.delayed(Duration.zero);
  return container.read(generationParamsNotifierProvider);
}

void expectNormalizedPromptParams(
  ImageParams params, {
  required bool autoFormat,
  required bool sdAutoConvert,
}) {
  expect(params.prompt, autoFormat ? 'girl, blue dress' : normalizationPrompt);
  expect(
    params.negativePrompt,
    sdAutoConvert
        ? '1.3::cinematic lighting::, blue eyes'
        : normalizationNegative,
  );
  expect(params.characters, hasLength(2));
  expect(
    params.characters.first.prompt,
    sdAutoConvert ? '1.4::ralada747372 ::' : '(ralada747372:1.4)',
  );
  expect(
    params.characters.first.negativePrompt,
    autoFormat ? 'bad hands, low quality' : 'bad hands，low quality',
  );
  expect(
    params.characters.last.prompt,
    autoFormat ? 'blue hair, red dress' : 'blue hair，red dress',
  );
  expect(
    params.characters.last.negativePrompt,
    sdAutoConvert ? '1.2::bad anatomy::' : '(bad anatomy:1.2)',
  );
  expect(params.useCoords, isTrue);
  expect(params.characters.first.positionX, 0.25);
  expect(params.characters.last.positionX, 0.75);
  expect(params.nSamples, 1);
}

Future<ImageParams> configurePromptComposition(
  ProviderContainer container,
) async {
  await configurePromptNormalization(
    container,
    autoFormat: true,
    sdAutoConvert: true,
  );
  final library = container.read(tagLibraryPageNotifierProvider.notifier);
  await library.addEntry(name: 'lighting', content: '(cinematic lighting:1.3)');
  await library.addEntry(name: 'negative', content: '(bad anatomy:1.1)');
  final quality = await library.addEntry(
    name: 'quality',
    content: '(soft light:1.2)',
  );
  final uc = await library.addEntry(
    name: 'uc',
    content: 'custom negative，low quality',
  );
  container
      .read(qualityPresetNotifierProvider.notifier)
      .setCustomEntry(quality.id);
  container.read(ucPresetNotifierProvider.notifier).setCustomEntry(uc.id);
  final fixed = container.read(fixedTagsNotifierProvider.notifier);
  await fixed.addEntry(name: 'prefix', content: '(ralada747372:1.4)');
  await fixed.addEntry(
    name: 'suffix',
    content: 'red dress，blue hair',
    position: FixedTagPosition.suffix,
  );
  await fixed.addEntry(
    name: 'negative',
    content: '(bad hands:1.3)',
    promptType: FixedTagPromptType.negative,
  );
  final params = container.read(generationParamsNotifierProvider.notifier);
  params.updatePrompt('<lighting>，blue eyes');
  params.updateNegativePrompt('<negative>，lowres');
  final characters = container.read(characterPromptNotifierProvider);
  container
      .read(characterPromptNotifierProvider.notifier)
      .updateCharacter(
        characters.characters.first.copyWith(
          prompt: '<lighting>, blue eyes',
          negativePrompt: '<negative>',
        ),
      );
  await Future<void>.delayed(Duration.zero);
  return container.read(generationParamsNotifierProvider);
}

void expectComposedPromptParams(ImageParams params) {
  expect(
    params.prompt,
    '1.4::ralada747372 ::, 1.3::cinematic lighting::, blue eyes, red dress, blue hair, 1.2::soft light::',
  );
  expect(
    params.negativePrompt,
    'custom negative, low quality, 1.3::bad hands::, 1.1::bad anatomy::, lowres',
  );
  expect(params.qualityToggle, isFalse);
  expect(params.qualityTagPreset, QualityTagPreset.none);
  expect(params.ucPreset, UcPresets.noneApiValue);
  expect(params.characters, hasLength(2));
  expect(
    params.characters.first.prompt,
    '1.3::cinematic lighting::, blue eyes',
  );
  expect(params.characters.first.negativePrompt, '1.1::bad anatomy::');
  expect(params.characters.last.prompt, 'blue hair, red dress');
}
