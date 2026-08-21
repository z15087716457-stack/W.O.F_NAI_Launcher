import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/model_spec.dart';

/// 能力表回归测试。
///
/// 期望值逐条对齐 NovelAI 网页端 bundle 里的模型能力开关表
/// （`_app-*.js` 的 `switch (model)` 分支），改动前先核对官网实现。
void main() {
  /// 需要显式注册能力的模型（V4 及更高版本，含 inpainting 变体）。
  const registeredBaseModels = [
    ImageModels.animeDiffusionV5Full,
    ImageModels.animeDiffusionV5Curated,
    ImageModels.animeDiffusionV45Full,
    ImageModels.animeDiffusionV45Curated,
    ImageModels.animeDiffusionV4Full,
    ImageModels.animeDiffusionV4Curated,
  ];

  group('ModelSpecs registry', () {
    test('covers every V4+ model exposed in the model picker', () {
      for (final id in registeredBaseModels) {
        expect(
          ModelSpecs.registeredIds,
          contains(id),
          reason: '$id 缺少能力描述，会退化到 legacy 回退值',
        );
        expect(ImageModels.allModels, contains(id));
      }
    });

    test('falls back to legacy capabilities for pre-V4 models', () {
      for (final id in const [
        ImageModels.animeDiffusionV3,
        ImageModels.furryDiffusionV3,
        ImageModels.furryDiffusion,
      ]) {
        final spec = ModelSpecs.of(id);

        expect(spec.v4Prompts, isFalse, reason: id);
        expect(spec.isV4OrLater, isFalse, reason: id);
        expect(spec.isV5, isFalse, reason: id);
        expect(spec.billingVersion, 3, reason: id);
      }
    });

    test('falls back instead of throwing on an unknown id', () {
      final spec = ModelSpecs.of('nai-diffusion-99-full');

      expect(spec.id, 'nai-diffusion-99-full');
      expect(spec.isV4OrLater, isFalse);
      expect(spec.billingVersion, 3);
    });

    test('keeps inpainting variants aligned with their base model', () {
      for (final base in registeredBaseModels) {
        final inpainting = ImageModels.resolveInpaintingModel(base);
        expect(inpainting, isNot(base), reason: base);

        final baseSpec = ModelSpecs.of(base);
        final inpaintingSpec = ModelSpecs.of(inpainting);

        expect(inpaintingSpec.isInpainting, isTrue, reason: inpainting);
        expect(inpaintingSpec.family, baseSpec.family, reason: inpainting);
        expect(
          inpaintingSpec.maxCharacters,
          baseSpec.maxCharacters,
          reason: inpainting,
        );
        expect(
          inpaintingSpec.opusUsageLimit,
          baseSpec.opusUsageLimit,
          reason: inpainting,
        );
        expect(ImageModels.resolveBaseModel(inpainting), base);
      }
    });
  });

  group('V5 capabilities', () {
    final spec = ModelSpecs.of(ImageModels.animeDiffusionV5Full);

    test('reuses the V4 prompt structure', () {
      expect(spec.v4Prompts, isTrue);
      expect(spec.characterPrompts, isTrue);
      expect(spec.isV4OrLater, isTrue);
      expect(spec.isV5, isTrue);
      expect(spec.billingVersion, 4);
    });

    test('drops vibe transfer, precise reference and noise schedule', () {
      expect(spec.vibetransfer, isFalse);
      expect(spec.encodedVibes, isFalse);
      expect(spec.characterReferences, isFalse);
      expect(spec.noiseSchedule, isFalse);
      expect(spec.varietyPlus, isFalse);
    });

    test('raises the character cap and enables the usage quota', () {
      expect(spec.maxCharacters, 32);
      expect(spec.opusUsageLimit, isTrue);
      expect(spec.freeformCharacterPosition, isTrue);
    });

    test('is recognised by the ImageModels helpers', () {
      expect(ImageModels.isV5Model(ImageModels.animeDiffusionV5Full), isTrue);
      expect(ImageModels.isV4Model(ImageModels.animeDiffusionV5Full), isTrue);
      expect(ImageModels.isV45Model(ImageModels.animeDiffusionV5Full), isFalse);
    });
  });

  group('V4 family capabilities', () {
    test('V4.5 keeps precise reference while V4.0 does not', () {
      expect(
        ModelSpecs.of(ImageModels.animeDiffusionV45Full).characterReferences,
        isTrue,
      );
      expect(
        ModelSpecs.of(ImageModels.animeDiffusionV4Full).characterReferences,
        isFalse,
      );
    });

    test('V4 family keeps vibe transfer and noise schedule, caps at 6', () {
      for (final id in const [
        ImageModels.animeDiffusionV4Full,
        ImageModels.animeDiffusionV45Full,
      ]) {
        final spec = ModelSpecs.of(id);
        expect(spec.vibetransfer, isTrue, reason: id);
        expect(spec.noiseSchedule, isTrue, reason: id);
        expect(spec.varietyPlus, isTrue, reason: id);
        expect(spec.maxCharacters, 6, reason: id);
        expect(spec.opusUsageLimit, isFalse, reason: id);
        expect(spec.isV5, isFalse, reason: id);
      }
    });

    test('no V4+ model advertises SMEA', () {
      for (final id in ImageModels.allModels) {
        final spec = ModelSpecs.of(id);
        if (!spec.isV4OrLater) continue;
        expect(spec.smea, isFalse, reason: id);
        expect(spec.smeaDyn, isFalse, reason: id);
        expect(spec.autoSmea, isFalse, reason: id);
      }
    });
  });
}
