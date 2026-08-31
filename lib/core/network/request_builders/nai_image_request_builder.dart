import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../../constants/api_constants.dart';
import '../../enums/precise_ref_type.dart';
import '../../utils/app_logger.dart';
import '../../utils/inpaint_mask_utils.dart';
import '../../utils/nai_resolution_adapter.dart';
import '../../utils/nai_api_utils.dart';
import '../../utils/prompt_semantics_utils.dart';
import '../../../data/models/character/character_prompt.dart'
    show CharacterPositionLayout;
import '../../../data/models/image/image_params.dart';

typedef EncodeVibeFn =
    Future<String> Function(
      Uint8List image, {
      required String model,
      double informationExtracted,
    });

class NAIImageRequestBuildResult {
  NAIImageRequestBuildResult({
    required this.seed,
    required this.effectivePrompt,
    required this.effectiveNegativePrompt,
    required this.requestParameters,
    required this.requestData,
    this.vibeEncodingMap = const {},
    this.normalizedSourceImageBytes,
    this.inpaintMaskArtifacts,
  });

  final int seed;
  final String effectivePrompt;
  final String effectiveNegativePrompt;
  final Map<String, dynamic> requestParameters;
  final Map<String, dynamic> requestData;
  final Map<int, String> vibeEncodingMap;
  final Uint8List? normalizedSourceImageBytes;
  final NovelAiInpaintMaskArtifacts? inpaintMaskArtifacts;
}

class NAIImageRequestBuilder {
  NAIImageRequestBuilder({
    required this.params,
    required this.encodeVibe,
    List<PreciseReference>? preciseReferences,
  }) : _preciseReferences =
           (preciseReferences ??
                   (params.isV45Model
                       ? params.preciseReferences
                       : <PreciseReference>[]))
               .where((reference) => reference.enabled)
               .toList(growable: false);

  final ImageParams params;
  final EncodeVibeFn encodeVibe;
  final List<PreciseReference> _preciseReferences;

  Map<String, dynamic> buildBaseParameters({
    required String sampler,
    required int seed,
    required String effectiveNegativePrompt,
    required bool isStream,
  }) {
    final requestParameters = <String, dynamic>{
      'params_version': params.paramsVersion,
      'width': params.width,
      'height': params.height,
      'scale': NAIApiUtils.toJsonNumber(params.scale),
      'sampler': sampler,
      'steps': params.steps,
      'n_samples': params.nSamples,
      'ucPreset': params.ucPreset,
      'qualityToggle': params.effectiveQualityToggle,
      'autoSmea': false,
      'dynamic_thresholding': params.isV3Model && params.decrisp,
      'controlnet_strength': 1,
      'legacy': false,
      'add_original_image': params.action == ImageGenerationAction.infill
          ? false
          : params.addOriginalImage,
      'cfg_rescale': NAIApiUtils.toJsonNumber(params.cfgRescale),
      'noise_schedule': params.isV4Model
          ? (params.noiseSchedule == 'native' ? 'karras' : params.noiseSchedule)
          : params.noiseSchedule,
      'normalize_reference_strength_multiple': true,
      'inpaintImg2ImgStrength': NAIApiUtils.toJsonNumber(
        params.inpaintStrength,
      ),
      'seed': seed,
      'negative_prompt': effectiveNegativePrompt,
      'deliberate_euler_ancestral_bug': false,
      'prefer_brownian': true,
      if (isStream) 'stream': 'msgpack',
    };

    // V5 不支持 Variety+：UI 隐藏后存储值可能是残留的 true，这里按能力表拦截
    final varietyPlus = params.varietyPlus && params.modelSpec.varietyPlus;
    requestParameters['skip_cfg_above_sigma'] = varietyPlus
        ? 58.0 * sqrt(4.0 * (params.width / 8) * (params.height / 8) / 63232)
        : null;

    // V5 透明背景：官方请求层参数（bundle 7416 K 函数）。
    // straight_alpha 是输出 alpha 编码模式（官方设置默认 straight=true），
    // tag_hint_* 为服务端标签提示（质量词 Standard/Light/None、UC 预设数字编码）。
    if (params.modelSpec.transparency) {
      requestParameters['tag_hint_transparent_background'] =
          params.transparentBackground;
      requestParameters['straight_alpha'] = true;
      requestParameters['tag_hint_qt'] = QualityTags.toTagHintValue(
        params.effectiveQualityTagPreset,
      );
      requestParameters['tag_hint_uc_preset'] = UcPresets.toTagHintValue(
        UcPresets.getPresetTypeFromInt(params.ucPreset),
      );
    }

    // V5 增强 Max✨：宽高保持源图，由服务端端到端放大。
    // 能力位门控：模型切走后残留的开启状态不再发出。
    if (params.upscaledEnhance && params.modelSpec.maxEnhance) {
      requestParameters['upscaled_enhance'] = true;
    }

    if (!params.isV4Model) {
      requestParameters['sm'] = params.effectiveSmea;
      requestParameters['sm_dyn'] = params.effectiveSmeaDyn;
      requestParameters['uc'] = effectiveNegativePrompt;
    }

    return requestParameters;
  }

  void buildV4Parameters(
    Map<String, dynamic> requestParameters, {
    required String effectivePrompt,
    required String effectiveNegativePrompt,
  }) {
    requestParameters['params_version'] = 3;
    requestParameters['use_coords'] = params.useCoords;
    requestParameters['legacy_v3_extend'] = false;
    requestParameters['legacy_uc'] = false;

    final charCaptions = <Map<String, dynamic>>[];
    final negativeCharCaptions = <Map<String, dynamic>>[];
    final characterPrompts = <Map<String, dynamic>>[];

    for (var index = 0; index < params.characters.length; index++) {
      final char = params.characters[index];
      // 连续坐标直传（0-1），与位置画布所见即所得
      final fallbackPosition = CharacterPositionLayout.positionForIndex(
        index,
        params.characters.length,
      );
      var x = fallbackPosition.column;
      var y = fallbackPosition.row;
      if (char.positionX != null && char.positionY != null) {
        x = char.positionX!.clamp(0.0, 1.0);
        y = char.positionY!.clamp(0.0, 1.0);
      }

      charCaptions.add({
        'centers': [
          {'x': x, 'y': y},
        ],
        'char_caption': char.prompt,
      });

      negativeCharCaptions.add({
        'centers': [
          {'x': x, 'y': y},
        ],
        'char_caption': char.negativePrompt,
      });

      characterPrompts.add({
        'center': {'x': x, 'y': y},
        'prompt': char.prompt,
        'uc': char.negativePrompt,
        'enabled': true,
      });
    }

    requestParameters['v4_prompt'] = {
      'caption': {
        'base_caption': effectivePrompt,
        'char_captions': charCaptions,
      },
      'use_coords': params.useCoords,
      'use_order': true,
    };

    requestParameters['v4_negative_prompt'] = {
      'caption': {
        'base_caption': effectiveNegativePrompt,
        'char_captions': negativeCharCaptions,
      },
      'legacy_uc': false,
    };

    requestParameters['characterPrompts'] = characterPrompts;
  }

  Future<Map<int, String>> buildVibeTransferParameters(
    Map<String, dynamic> requestParameters, {
    required bool isStream,
  }) async {
    final vibeEncodingMap = <int, String>{};
    if (_preciseReferences.isNotEmpty) {
      // NovelAI 官方说明 Precise Reference 与 Vibe Transfer 不兼容，
      // 因此两者同时存在时优先保留 Precise Reference，避免结果偏离网页端。
      return vibeEncodingMap;
    }
    if (params.action == ImageGenerationAction.infill) {
      // NovelAI 的 infill 请求会直接携带 image + mask，继续附带
      // Vibe Transfer payload 会触发服务端 500，因此局部重绘时跳过。
      return vibeEncodingMap;
    }
    if (!params.hasVibeReferencesV4) {
      return vibeEncodingMap;
    }

    requestParameters['normalize_reference_strength_multiple'] =
        params.normalizeVibeStrength;

    if (!isStream) {
      final allEncodings = <String>[];
      final allStrengths = <double>[];
      final allInfoExtracted = <double>[];

      for (int i = 0; i < params.vibeReferencesV4.length; i++) {
        final vibe = params.vibeReferencesV4[i];
        if (!vibe.enabled) {
          continue;
        }

        if (vibe.needsEncodingForModel(params.model)) {
          AppLogger.d(
            'V4 Vibe: Encoding rawImage at index $i (2 Anlas)...',
            'ImgGen',
          );
          try {
            final encoding = await encodeVibe(
              vibe.rawImageData!,
              model: params.model,
              informationExtracted: vibe.infoExtracted,
            );
            if (encoding.isNotEmpty) {
              allEncodings.add(encoding);
              allStrengths.add(vibe.strength);
              allInfoExtracted.add(vibe.infoExtracted);
              vibeEncodingMap[i] = encoding;
              AppLogger.d(
                'V4 Vibe: Encoded raw image at index $i successfully, hash length: ${encoding.length}',
                'ImgGen',
              );
            } else {
              AppLogger.w(
                'V4 Vibe: Failed to encode raw image at index $i (empty result)',
                'ImgGen',
              );
            }
          } catch (e) {
            AppLogger.e(
              'V4 Vibe: Failed to encode raw image at index $i: $e',
              'ImgGen',
            );
          }
        } else if (vibe.vibeEncoding.isNotEmpty) {
          allEncodings.add(vibe.vibeEncoding);
          allStrengths.add(vibe.strength);
          allInfoExtracted.add(vibe.infoExtracted);
          vibeEncodingMap[i] = vibe.vibeEncoding;
          AppLogger.d('V4 Vibe: Using pre-encoded vibe at index $i', 'ImgGen');
        }
      }

      if (allEncodings.isNotEmpty) {
        requestParameters['reference_image_multiple'] = allEncodings;
        requestParameters['reference_strength_multiple'] = allStrengths;
        requestParameters['reference_information_extracted_multiple'] =
            allInfoExtracted;

        AppLogger.d(
          'V4 Vibe Transfer: ${vibeEncodingMap.length} vibes with encodings',
          'ImgGen',
        );
      }

      return vibeEncodingMap;
    }

    final encodedVibes = params.vibeReferencesV4
        .asMap()
        .entries
        .where((entry) => entry.value.enabled)
        .where((entry) => !entry.value.needsEncodingForModel(params.model))
        .where((entry) => entry.value.vibeEncoding.isNotEmpty)
        .toList();
    final rawImageVibes = params.vibeReferencesV4
        .asMap()
        .entries
        .where((entry) => entry.value.enabled)
        .where((entry) => entry.value.needsEncodingForModel(params.model))
        .toList();

    final allEncodings = <String>[];
    final allStrengths = <double>[];
    final allInfoExtracted = <double>[];

    for (final entry in encodedVibes) {
      final vibe = entry.value;
      allEncodings.add(vibe.vibeEncoding);
      allStrengths.add(vibe.strength);
      allInfoExtracted.add(vibe.infoExtracted);
      vibeEncodingMap[entry.key] = vibe.vibeEncoding;
    }

    if (rawImageVibes.isNotEmpty) {
      AppLogger.d(
        'V4 Vibe (Stream): Encoding ${rawImageVibes.length} raw images (2 Anlas each)...',
        'ImgGen',
      );
      for (final entry in rawImageVibes) {
        final vibe = entry.value;
        try {
          final encoding = await encodeVibe(
            vibe.rawImageData!,
            model: params.model,
            informationExtracted: vibe.infoExtracted,
          );
          if (encoding.isNotEmpty) {
            allEncodings.add(encoding);
            allStrengths.add(vibe.strength);
            allInfoExtracted.add(vibe.infoExtracted);
            vibeEncodingMap[entry.key] = encoding;
            AppLogger.d(
              'V4 Vibe (Stream): Encoded raw image at index ${entry.key} successfully',
              'ImgGen',
            );
          } else {
            AppLogger.w(
              'V4 Vibe (Stream): Failed to encode raw image at index ${entry.key} (empty result)',
              'ImgGen',
            );
          }
        } catch (e) {
          AppLogger.e(
            'V4 Vibe (Stream): Failed to encode raw image at index ${entry.key}: $e',
            'ImgGen',
          );
        }
      }
    }

    if (allEncodings.isNotEmpty) {
      requestParameters['reference_image_multiple'] = allEncodings;
      requestParameters['reference_strength_multiple'] = allStrengths;
      requestParameters['reference_information_extracted_multiple'] =
          allInfoExtracted;

      AppLogger.d(
        'V4 Vibe Transfer (Stream): ${encodedVibes.length} encoded + ${rawImageVibes.length} raw = ${allEncodings.length} total vibes',
        'ImgGen',
      );
    }

    return vibeEncodingMap;
  }

  Future<void> buildPreciseReferenceParameters(
    Map<String, dynamic> requestParameters,
  ) async {
    if (_preciseReferences.isEmpty) {
      return;
    }

    final referenceImages = <String>[];
    for (final reference in _preciseReferences) {
      final imageBytes =
          NAIApiUtils.isKnownNormalizedPreciseReferencePng(reference.image)
          ? reference.image
          : await NAIApiUtils.ensurePngFormatAsync(reference.image);
      referenceImages.add(base64Encode(imageBytes));
    }

    requestParameters['normalize_reference_strength_multiple'] = true;
    requestParameters['director_reference_images'] = referenceImages;
    requestParameters['director_reference_descriptions'] = _preciseReferences
        .map(
          (r) => {
            'caption': {
              'base_caption': r.type.toApiString(),
              'char_captions': [],
            },
            'legacy_uc': false,
          },
        )
        .toList();
    requestParameters['director_reference_information_extracted'] =
        _preciseReferences.map((_) => 1).toList();
    requestParameters['director_reference_strength_values'] = _preciseReferences
        .map((r) => r.strength)
        .toList();
    requestParameters['director_reference_secondary_strength_values'] =
        _preciseReferences.map((r) => 1.0 - r.fidelity).toList();
  }

  Future<Uint8List> _normalizeRequestSourceImage(Uint8List sourceImage) async {
    return await NaiResolutionAdapter.normalizeImageForRequestAsync(
          sourceImage,
          targetWidth: params.width,
          targetHeight: params.height,
        ) ??
        sourceImage;
  }

  /// 非最大档增强（Enhance）时按官方 enhancePromptAdd 行为注入防糊负权重词。
  ///
  /// 官方（bundle 7416 generateEnhance）对 V4.5/V5 在提示词中插入
  /// `, -2::upscaled, blurry::,`——插在 `text:` 块之前，无则追加末尾；
  /// Max✨ 档不注入。已含该词或非增强工作流时原样返回。
  String _applyEnhancePromptAdditions(String prompt) {
    if (!params.enhanceWorkflow || params.upscaledEnhance) {
      return prompt;
    }
    // 官方 enhancePromptAdd 能力位：V4.5/V5 为 true，V4.0 及更早为 false。
    final spec = params.modelSpec;
    if (!(params.isV45Model || spec.isV5) ||
        prompt.contains('upscaled, blurry')) {
      return prompt;
    }
    const addition = ', -2::upscaled, blurry::,';
    final textBlock = RegExp(
      r'(?:^|\s|[,.:[\]{}、。])text:(?!:)',
      caseSensitive: false,
    ).firstMatch(prompt);
    if (textBlock == null) {
      return '$prompt$addition';
    }
    final insertAt = textBlock.end - 'text:'.length;
    return prompt.replaceRange(insertAt, insertAt, addition.substring(2));
  }

  Future<NAIImageRequestBuildResult> build({
    required String sampler,
    bool isStream = false,
  }) async {
    if (sampler.isEmpty) {
      throw ArgumentError.value(sampler, 'sampler', 'Sampler cannot be empty');
    }

    final seed = params.seed == -1 ? Random().nextInt(4294967295) : params.seed;

    final baseModel = ImageModels.resolveBaseModel(params.model);
    final requestModel = params.action == ImageGenerationAction.infill
        ? ImageModels.resolveInpaintingModel(baseModel)
        : params.model;
    final promptSemantics = buildPromptSemanticsSnapshot(
      prompt: params.prompt,
      negativePrompt: params.negativePrompt,
      model: baseModel,
      qualityToggle: params.qualityToggle,
      qualityTagPreset: params.effectiveQualityTagPreset,
      ucPreset: params.ucPreset,
      transparentBackground: params.transparentBackground,
    );
    final effectivePrompt = _applyEnhancePromptAdditions(
      promptSemantics.effectivePrompt,
    );
    final effectiveNegativePrompt = promptSemantics.effectiveNegativePrompt;

    final requestParameters = buildBaseParameters(
      sampler: sampler,
      seed: seed,
      effectiveNegativePrompt: effectiveNegativePrompt,
      isStream: isStream,
    );
    Uint8List? normalizedSourceImageBytes;
    NovelAiInpaintMaskArtifacts? inpaintMaskArtifacts;

    if (params.isV4Model) {
      buildV4Parameters(
        requestParameters,
        effectivePrompt: effectivePrompt,
        effectiveNegativePrompt: effectiveNegativePrompt,
      );
    }

    if (params.action == ImageGenerationAction.img2img &&
        params.sourceImage != null) {
      final normalizedSource = await _normalizeRequestSourceImage(
        params.sourceImage!,
      );
      normalizedSourceImageBytes = normalizedSource;
      requestParameters['image'] = base64Encode(normalizedSource);
      requestParameters['strength'] = params.strength;
      requestParameters['noise'] = params.noise;
    }

    if (params.action == ImageGenerationAction.infill &&
        params.sourceImage != null &&
        params.maskImage != null) {
      final maskArtifactsFuture =
          InpaintMaskUtils.prepareNovelAiInpaintMaskArtifactsAsync(
            params.maskImage!,
            targetWidth: params.width,
            targetHeight: params.height,
            closingIterations: params.inpaintMaskClosingIterations,
            expansionIterations: params.inpaintMaskExpansionIterations,
          );
      final normalizedSourceFuture = _normalizeRequestSourceImage(
        params.sourceImage!,
      );
      final normalizedSource = await normalizedSourceFuture;
      inpaintMaskArtifacts = await maskArtifactsFuture;
      normalizedSourceImageBytes = normalizedSource;
      requestParameters['image'] = base64Encode(normalizedSource);
      requestParameters['mask'] = base64Encode(
        inpaintMaskArtifacts.requestMaskBytes,
      );
      requestParameters['strength'] = NAIApiUtils.toJsonNumber(params.strength);
      requestParameters['noise'] = NAIApiUtils.toJsonNumber(params.noise);
      if (ImageModels.supportsImg2ImgInpainting(requestModel) &&
          params.inpaintStrength != 1.0) {
        requestParameters['img2img'] = {
          'strength': NAIApiUtils.toJsonNumber(params.inpaintStrength),
          'color_correct': true,
        };
      }
    }

    final vibeEncodingMap = await buildVibeTransferParameters(
      requestParameters,
      isStream: isStream,
    );

    await buildPreciseReferenceParameters(requestParameters);

    final requestData = <String, dynamic>{
      'input': effectivePrompt,
      'model': requestModel,
      'action': params.action.value,
      'parameters': requestParameters,
      'use_new_shared_trial': true,
    };

    return NAIImageRequestBuildResult(
      seed: seed,
      effectivePrompt: effectivePrompt,
      effectiveNegativePrompt: effectiveNegativePrompt,
      requestParameters: requestParameters,
      requestData: requestData,
      vibeEncodingMap: vibeEncodingMap,
      normalizedSourceImageBytes: normalizedSourceImageBytes,
      inpaintMaskArtifacts: inpaintMaskArtifacts,
    );
  }
}
