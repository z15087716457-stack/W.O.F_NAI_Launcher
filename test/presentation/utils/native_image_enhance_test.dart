import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/utils/native_image_enhance.dart';

void main() {
  final source = Uint8List.fromList([1, 2, 3]);

  // Website build f928585: generateEnhance then the request's 64px alignment.
  for (final model in [
    ImageModels.animeDiffusionV45Full,
    ImageModels.animeDiffusionV5Full,
    ImageModels.animeDiffusionV5Curated,
    ImageModels.animeDiffusionV5FullMedium,
  ]) {
    for (final (width, height, targetWidth, targetHeight) in [
      (1216, 832, 1856, 1280),
      (832, 1216, 1280, 1856),
    ]) {
      test('$model $width x $height 1.5x uses website request dimensions', () {
        final draft = ImageParams(model: model, prompt: 'source prompt');
        final native = NativeImageEnhance.project(
          current: draft,
          source: source,
          width: width,
          height: height,
          factor: 1.5,
          strength: .2,
          noise: 0,
          max: false,
        );
        final canvas = canvasEnhanceRequest(
          draft,
          const EnhanceWorkflowSettings(magnitude: 0, upscaleFactor: 1.5),
          source,
          width,
          height,
        );
        for (final request in [native, canvas]) {
          expect((request.width, request.height), (targetWidth, targetHeight));
          expect(request.sourceImage, same(source));
          expect(request.action, ImageGenerationAction.img2img);
          expect(request.enhanceWorkflow, isTrue);
          expect(request.upscaledEnhance, isFalse);
          expect((request.strength, request.noise), (.2, 0));
        }
        expect((draft.width, draft.height), (832, 1216));
        expect(draft.sourceImage, isNull);
      });
    }
  }

  test(
    'V5 ordinary scales use the website 64px grid; retain preset exception',
    () {
      for (final model in [
        ImageModels.animeDiffusionV5Full,
        ImageModels.animeDiffusionV5Curated,
        ImageModels.animeDiffusionV5FullMedium,
      ]) {
        expect(NativeImageEnhance.factors(model, 704, 1024), [1.0, 2.0]);
        expect(canvasEnhanceFactors(model, 704, 1024), [1.0, 2.0]);
        expect(NativeImageEnhance.factors(model, 1216, 832), [1.0, 1.5]);
        expect(canvasEnhanceFactors(model, 832, 1216), [1.0, 1.5]);
      }
    },
  );

  test('1x, already aligned 1.5x, and Max keep their previous dimensions', () {
    for (final (width, height, factor, max, targetWidth, targetHeight) in [
      (1216, 832, 1.0, false, 1216, 832),
      (768, 1024, 1.5, false, 1152, 1536),
      (1216, 832, 1.5, true, 1216, 832),
    ]) {
      final request = NativeImageEnhance.project(
        current: const ImageParams(model: ImageModels.animeDiffusionV5Full),
        source: source,
        width: width,
        height: height,
        factor: factor,
        strength: .2,
        noise: 0,
        max: max,
      );
      expect((request.width, request.height), (targetWidth, targetHeight));
      expect(request.upscaledEnhance, max);
    }
  });
}
