import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/enums/quality_tag_preset.dart';
import 'package:nai_launcher/core/utils/prompt_semantics_utils.dart';

void main() {
  group('NSFW atom filtering', () {
    final cases = <String, String>{
      '1.5::nsfw::, lowres': 'lowres',
      '.5::NSFW::': '',
      '-1.2::nsfw, lowres::, blurry': '-1.2::lowres::, blurry',
      '2::lowres, nsfw::': '2::lowres::',
      '1.5::nsfw': '',
      '{{nsfw}}, [nsfw], lowres': 'lowres',
      '{lowres, [nsfw]}, blurry': '{lowres}, blurry',
      '1.5::{{nsfw}}::, lowres': 'lowres',
      '{1.5::nsfw::}, lowres': 'lowres',
      'lowres，nsfw，blurry': 'lowres, blurry',
      '  lowres,  blurry  ': '  lowres,  blurry  ',
      'nsfw_artist, sfw, nsfw content': 'nsfw_artist, sfw, nsfw content',
      'artist:nsfw, xnsfw, nsfworks': 'artist:nsfw, xnsfw, nsfworks',
      '"nsfw", <alias:nsfw>, ||nsfw|sfw||':
          '"nsfw", <alias:nsfw>, ||nsfw|sfw||',
      r'\nsfw, lowres': r'\nsfw, lowres',
      '<prompt>nsfw, lowres</prompt>': '<prompt>nsfw, lowres</prompt>',
    };
    for (final entry in cases.entries) {
      test('removes complete atoms from ${entry.key}', () {
        expect(UcPresets.removeNsfwTag(entry.key), entry.value);
      });
    }

    for (final prompt in ['nsfw', '1.5::nsfw::', '{lowres, nsfw}']) {
      test('recognizes positive atom $prompt', () {
        expect(UcPresets.containsNsfwTag(prompt), isTrue);
      });
    }
    for (final prompt in [
      'nsfw_artist',
      'nsfw content',
      '"nsfw"',
      'artist:nsfw',
    ]) {
      test('does not match a substring or literal in $prompt', () {
        expect(UcPresets.containsNsfwTag(prompt), isFalse);
      });
    }

    test('effective projection preserves the draft and remaining weights', () {
      const negative = '1.5::nsfw::, {lowres, 2::blurry::}';
      final snapshot = buildPromptSemanticsSnapshot(
        prompt: '1girl, nsfw',
        negativePrompt: negative,
        model: ImageModels.animeDiffusionV45Full,
        qualityToggle: false,
        ucPreset: UcPresets.toApiValue(UcPresetType.none),
      );
      expect(snapshot.baseNegativePrompt, negative);
      expect(snapshot.effectiveNegativePrompt, '{lowres, 2::blurry::}');
    });
  });

  group('buildPromptSemanticsSnapshot', () {
    test('should preserve base prompts while computing effective prompts', () {
      final snapshot = buildPromptSemanticsSnapshot(
        prompt: '1girl, sunset',
        negativePrompt: 'bad hands',
        model: ImageModels.animeDiffusionV45Full,
        qualityToggle: true,
        ucPreset: UcPresets.toApiValue(UcPresetType.heavy),
      );

      expect(snapshot.basePrompt, equals('1girl, sunset'));
      expect(snapshot.baseNegativePrompt, equals('bad hands'));
      expect(
        snapshot.effectivePrompt,
        equals('1girl, sunset, location, very aesthetic, masterpiece, no text'),
      );
      expect(
        snapshot.effectiveNegativePrompt,
        startsWith('lowres, artistic error'),
      );
      expect(snapshot.effectiveNegativePrompt, isNot(contains('nsfw')));
      expect(snapshot.effectiveNegativePrompt, endsWith('bad hands'));
    });

    test('should place V5 transparency before Light quality tags', () {
      final snapshot = buildPromptSemanticsSnapshot(
        prompt: '1girl',
        negativePrompt: '',
        model: ImageModels.animeDiffusionV5Full,
        qualityToggle: true,
        qualityTagPreset: QualityTagPreset.light,
        ucPreset: UcPresets.toApiValue(UcPresetType.none),
        transparentBackground: true,
      );

      expect(
        snapshot.effectivePrompt,
        '1girl, transparent background, very aesthetic, amazing quality, no text',
      );
    });

    test(
      'should keep prompt unchanged when quality and uc presets are disabled',
      () {
        final snapshot = buildPromptSemanticsSnapshot(
          prompt: '1girl',
          negativePrompt: 'blurry',
          model: ImageModels.animeDiffusionV45Full,
          qualityToggle: false,
          ucPreset: UcPresets.toApiValue(UcPresetType.none),
        );

        expect(snapshot.basePrompt, equals('1girl'));
        expect(snapshot.baseNegativePrompt, equals('blurry'));
        expect(snapshot.effectivePrompt, equals('1girl'));
        expect(snapshot.effectiveNegativePrompt, equals('blurry'));
      },
    );
  });
}
