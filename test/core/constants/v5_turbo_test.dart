import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/model_spec.dart';
import 'package:nai_launcher/core/network/request_builders/nai_image_request_builder.dart';
import 'package:nai_launcher/core/services/anlas_calculator.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/presentation/utils/metadata_import_applier.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_nai_versions.dart';

void main() {
  const turbo = ImageModels.animeDiffusionV5FullMedium;
  const infill = ImageModels.animeDiffusionV5FullMediumInpainting;
  test('Turbo is a registered V5 Full mode, including its infill identity', () {
    expect(
      ImageModels.turboModelForModel(ImageModels.animeDiffusionV5Full),
      turbo,
    );
    expect(
      ImageModels.baseModelForTurboModel(turbo),
      ImageModels.animeDiffusionV5Full,
    );
    expect(
      ImageModels.turboModelForModel(ImageModels.animeDiffusionV5Curated),
      isNull,
    );
    expect(ImageModels.resolveInpaintingModel(turbo), infill);
    expect(ImageModels.resolveBaseModel(infill), turbo);
    for (final id in [turbo, infill]) {
      final spec = ModelSpecs.of(id);
      expect(spec.isV5, isTrue);
      expect(spec.isTurbo, isTrue);
      expect(spec.customNegativePrompt, isFalse);
      expect(spec.maxCharacters, 32);
      expect(spec.transparency, isTrue);
      expect(spec.maxEnhance, isTrue);
      expect(spec.vibetransfer, isFalse);
      expect(spec.characterReferences, isFalse);
      expect(spec.cfgRescale, isFalse);
      expect(spec.fixedSteps, 14);
      expect(spec.fixedSampler, Samplers.kEulerAncestral);
      expect(spec.fixedUcPreset, 0);
      expect(Samplers.samplersForModel(id), [Samplers.kEulerAncestral]);
      expect(GalleryNaiVersions.labelForModel(id), 'V5');
      expect(GalleryNaiVersions.fullIds['5'], contains(id));
      expect(ImageModels.supportsImg2ImgInpainting(id), isTrue);
    }
  });

  for (final action in ImageGenerationAction.values) {
    for (final stream in [false, true]) {
      test(
        'request constraints survive stale settings: $action / stream=$stream',
        () async {
          final image = img.Image(width: 64, height: 64);
          img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));
          final bytes = Uint8List.fromList(img.encodePng(image));
          final raw = ImageParams(
            model: turbo,
            prompt: 'girl',
            negativePrompt: 'OLD_NEGATIVE_DO_NOT_SEND',
            steps: 50,
            sampler: Samplers.kDpmpp2m,
            cfgRescale: .7,
            ucPreset: 3,
            action: action,
            width: 64,
            height: 64,
            strength: .35,
            inpaintStrength: .6,
            sourceImage: action == ImageGenerationAction.generate
                ? null
                : bytes,
            maskImage: action == ImageGenerationAction.infill ? bytes : null,
            characters: const [
              CharacterPrompt(
                prompt: 'red hair',
                negativePrompt: 'OLD_CHARACTER_UC',
              ),
            ],
          );
          final result = await NAIImageRequestBuilder(
            params: raw,
            encodeVibe: (_, {required model, informationExtracted = 1}) async =>
                throw StateError('Unexpected encoding'),
          ).build(sampler: Samplers.kDpmpp2m, isStream: stream);
          final wire = result.requestParameters;
          expect(
            result.requestData['model'],
            action == ImageGenerationAction.infill ? infill : turbo,
          );
          expect(wire['steps'], 14);
          expect(wire['sampler'], Samplers.kEulerAncestral);
          expect(wire['cfg_rescale'], 0);
          expect(wire['params_version'], 4);
          expect(wire['ucPreset'], 0);
          expect(
            result.effectiveNegativePrompt,
            UcPresets.v5Presets[UcPresetType.heavy],
          );
          expect(
            jsonEncode(result.requestData),
            isNot(contains('OLD_NEGATIVE_DO_NOT_SEND')),
          );
          expect(
            jsonEncode(result.requestData),
            isNot(contains('OLD_CHARACTER_UC')),
          );
          expect(raw.steps, 50);
          expect(raw.sampler, Samplers.kDpmpp2m);
          expect(raw.cfgRescale, .7);
          expect(raw.negativePrompt, 'OLD_NEGATIVE_DO_NOT_SEND');
          expect(raw.characters.single.negativePrompt, 'OLD_CHARACTER_UC');
          if (action == ImageGenerationAction.img2img) {
            expect(wire['strength'], .35);
          }
          if (action == ImageGenerationAction.infill) {
            expect(wire['inpaintImg2ImgStrength'], .6);
          }
        },
      );
    }
  }

  test('prices match the exact isolated official function for 72 fixtures', () {
    final fixture =
        jsonDecode(
              File('test/fixtures/v5_turbo_prices.json').readAsStringSync(),
            )
            as Map;
    final cases = fixture['cases'] as List;
    expect(cases, hasLength(72));
    for (final row in cases.cast<Map>()) {
      final actual = AnlasCalculator.calculateFromValues(
        width: row['width'] as int,
        height: row['height'] as int,
        // A stale Full value must never raise the fixed-step Turbo price.
        steps: ImageModels.isTurboModel(row['model'] as String)
            ? 50
            : row['steps'] as int,
        nSamples: row['count'] as int,
        smea: false,
        smeaDyn: false,
        model: row['model'] as String,
        strength: (row['strength'] as num).toDouble(),
      );
      expect(actual, row['expected'], reason: '$row');
    }
  });

  for (final key in ['model', 'version', 'model_name']) {
    test('explicit Turbo $key survives generic V5 metadata and imports', () {
      final meta = NaiImageMetadata.fromNaiComment({
        'Source': 'NovelAI Diffusion V5',
        'Comment': jsonEncode({
          'prompt': 'girl',
          'model_name': 'DiffusionModelMetaName.NAIv5',
          key: turbo,
        }),
      });
      expect(meta.model, turbo);
      expect(meta.effectiveModel, turbo);
      expect(MetadataImportApplier.resolveImportableModel(meta), turbo);
      expect(meta.upgradeFromRawJsonIfNeeded().effectiveModel, turbo);
    });
  }
  test('fourteen Full steps do not imply Turbo', () {
    expect(
      NaiImageMetadata.fromNaiComment({
        'prompt': 'girl',
        'steps': 14,
        'version': ImageModels.animeDiffusionV5Full,
      }).model,
      ImageModels.animeDiffusionV5Full,
    );
  });
  test(
    'Turbo params do not override a different-family Source fingerprint',
    () {
      final meta = NaiImageMetadata.fromNaiComment({
        'Source': 'NovelAI Diffusion V4.5 Full',
        'Comment': jsonEncode({'model': turbo, 'prompt': 'girl'}),
      });
      expect(meta.effectiveModel, ImageModels.animeDiffusionV45Full);
    },
  );
}
