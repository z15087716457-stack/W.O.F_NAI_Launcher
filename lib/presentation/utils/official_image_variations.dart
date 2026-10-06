import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../core/constants/api_constants.dart';
import '../../core/enums/quality_tag_preset.dart';
import '../../core/utils/nai_resolution_adapter.dart';
import '../../data/models/gallery/nai_image_metadata.dart';
import '../../data/models/image/image_params.dart';
import 'metadata_import_applier.dart';

/// Website generateVariations (2952/5285 bundles, verified 2026-10-06).
/// This is a request projection; it never imports anything into the editor.
class OfficialImageVariations {
  const OfficialImageVariations._();

  static const strength = 0.8;
  static const noise = 0.1;
  static const count = 3;

  static bool supportsSize(int width, int height) =>
      width > 0 &&
      height > 0 &&
      width * height <= NaiResolutionAdapter.officialMaxPixels &&
      _gridSize(width) * _gridSize(height) <=
          NaiResolutionAdapter.officialMaxPixels;

  // The website rounds each request edge to the nearest 64; ties round up.
  static int _gridSize(int value) => math.max(64, ((value + 32) ~/ 64) * 64);

  static ImageParams project({
    required ImageParams current,
    required Uint8List source,
    required int width,
    required int height,
    NaiImageMetadata? metadata,
  }) {
    var params = current;
    if (metadata != null && metadata.hasData) {
      final model =
          MetadataImportApplier.resolveImportableModel(metadata) ??
          current.model;
      final quality =
          MetadataImportApplier.recordedQualityPreset(metadata) ??
          QualityTagPreset.none;
      final uc = MetadataImportApplier.recordedUcPreset(metadata);
      final raw = _recordedParams(metadata);
      final characters = <CharacterPrompt>[];
      final characterCount = math.max(
        metadata.characterPrompts.length,
        metadata.characterInfos.length,
      );
      for (var index = 0; index < characterCount; index++) {
        final info = index < metadata.characterInfos.length
            ? metadata.characterInfos[index]
            : null;
        characters.add(
          CharacterPrompt(
            prompt: index < metadata.characterPrompts.length
                ? metadata.characterPrompts[index]
                : info?.prompt ?? '',
            negativePrompt:
                info?.negativePrompt ??
                (index < metadata.characterNegativePrompts.length
                    ? metadata.characterNegativePrompts[index]
                    : ''),
            positionX: info?.centerX,
            positionY: info?.centerY,
          ),
        );
      }
      params = current.copyWith(
        model: model,
        prompt: MetadataImportApplier.resolveImportedPrompt(
          metadata,
          importQualityPreset: true,
          currentModel: model,
        ),
        negativePrompt: MetadataImportApplier.resolveImportedNegativePrompt(
          metadata,
          importUcPreset: true,
          currentModel: model,
        ),
        steps: metadata.steps ?? current.steps,
        scale: metadata.scale ?? current.scale,
        sampler: metadata.sampler ?? current.sampler,
        smea: metadata.smea ?? false,
        smeaDyn: metadata.smeaDyn ?? false,
        smeaAuto: raw['autoSmea'] == true,
        cfgRescale: metadata.cfgRescale ?? 0,
        noiseSchedule:
            metadata.noiseSchedule ??
            (ImageModels.isV4Model(model) ? 'karras' : 'native'),
        varietyPlus: metadata.varietyPlus ?? false,
        decrisp: raw['dynamic_thresholding'] == true,
        transparentBackground: raw['tag_hint_transparent_background'] == true,
        furryMode: raw['modelMode'] == 'Furry',
        qualityToggle: quality != QualityTagPreset.none,
        qualityTagPreset: quality,
        ucPreset: uc == null
            ? UcPresets.noneApiValue
            : UcPresets.toApiValue(uc),
        characters: characters,
        useCoords:
            metadata.characterUseCoords ??
            characters.any((c) => c.positionX != null && c.positionY != null),
      );
    }
    return params.copyWith(
      width: _gridSize(width),
      height: _gridSize(height),
      nSamples: 1,
      seed: -1,
      extraNoiseSeed: null,
      action: ImageGenerationAction.img2img,
      sourceImage: source,
      strength: strength,
      noise: noise,
      maskImage: null,
      inpaintFocusRegion: null,
      isOutpaint: false,
      enhanceWorkflow: false,
      upscaledEnhance: false,
      addOriginalImage: true,
      smeaAuto: false,
      smea: false,
      smeaDyn: false,
    );
  }

  static Map<String, dynamic> _recordedParams(NaiImageMetadata metadata) {
    try {
      var value = jsonDecode(metadata.rawJson ?? '{}');
      if (value is! Map) return {};
      value = value['Comment'] ?? value['comment'] ?? value;
      if (value is String) value = jsonDecode(value);
      return value is Map ? Map<String, dynamic>.from(value) : {};
    } catch (_) {
      return {};
    }
  }
}
