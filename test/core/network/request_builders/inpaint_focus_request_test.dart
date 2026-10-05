import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/network/request_builders/nai_image_request_builder.dart';
import 'package:nai_launcher/core/services/anlas_calculator.dart';
import 'package:nai_launcher/core/utils/inpaint_focus_region.dart';
import 'package:nai_launcher/core/utils/inpaint_mask_utils.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'focused infill crops and resizes both protocols and bills the request crop',
    () async {
      const focus = InpaintFocusRegion(
        x: 128,
        y: 128,
        width: 256,
        height: 256,
        context: 32,
      );
      final source = _png(512, 512, img.ColorRgb8(20, 60, 120));
      final mask = Uint8List(512 * 512);
      focus.applyToBinaryMask(mask, 512, 512);
      final maskBytes = InpaintMaskUtils.encodeBinaryMask(mask, 512, 512);
      final params = ImageParams(
        model: 'nai-diffusion-4-5-full',
        width: 512,
        height: 512,
        action: ImageGenerationAction.infill,
        sourceImage: source,
        maskImage: maskBytes,
        inpaintFocusRegion: focus,
        seed: 123,
      );
      expect(params.effectiveInpaintRequestSize, (width: 1024, height: 1024));
      expect(
        AnlasCalculator.calculate(params),
        AnlasCalculator.calculate(
          params.copyWith(width: 1024, height: 1024, inpaintFocusRegion: null),
        ),
      );
      expect(params.toJson().containsKey('inpaintFocusRegion'), isFalse);
      for (final stream in [false, true]) {
        final result = await NAIImageRequestBuilder(
          params: params,
          encodeVibe: _noVibes,
        ).build(sampler: 'k_euler', isStream: stream);
        expect(result.requestData['action'], 'infill');
        expect(result.requestParameters['width'], 1024);
        expect(result.requestParameters['height'], 1024);
        expect(result.inpaintFocusRegion!.rect, focus.rect);
        final inputImage = img.decodePng(
          base64Decode(result.requestParameters['image'] as String),
        )!;
        final requestMask = img.decodePng(
          base64Decode(result.requestParameters['mask'] as String),
        )!;
        expect((inputImage.width, inputImage.height), (1024, 1024));
        expect((requestMask.width, requestMask.height), (1024, 1024));
        expect(requestMask.getPixel(512, 512).r.toInt(), 255);
        expect(requestMask.getPixel(0, 0).r.toInt(), 0);
        expect(img.decodePng(result.fullInpaintSourceImageBytes!)!.width, 512);
        final generated = _png(1024, 1024, img.ColorRgb8(230, 30, 10));
        final artifact = InpaintMaskUtils.composeGeneratedImageArtifact(
          normalizedSourceImage: result.fullInpaintSourceImageBytes!,
          compositeMaskImage: result.inpaintMaskArtifacts!.compositeMaskBytes,
          generatedImage: generated,
          focusRegion: result.inpaintFocusRegion,
        );
        final display = img.decodePng(artifact.displayImageBytes)!;
        final patch = img.decodePng(artifact.transparentPatchBytes!)!;
        expect((display.width, display.height), (512, 512));
        expect(display.getPixel(0, 0).r.toInt(), 20);
        expect(display.getPixel(511, 511).b.toInt(), 120);
        expect(display.getPixel(256, 256).r.toInt(), 230);
        expect(patch.getPixel(0, 0).a.toInt(), 0);
        expect(patch.getPixel(256, 256).a.toInt(), 255);
      }
      expect(params.width, 512);
      expect(params.sourceImage, same(source));
      expect(params.maskImage, same(maskBytes));
    },
  );

  test('focus resolution follows the website 1MP fit and 64-pixel floor', () {
    expect(
      const InpaintFocusRegion(x: 0, y: 0, width: 384, height: 256).requestSize,
      (width: 1216, height: 832),
    );
    expect(
      const InpaintFocusRegion(
        x: 0,
        y: 0,
        width: 1024,
        height: 1024,
      ).requestSize,
      (width: 1024, height: 1024),
    );
  });

  test('focus restricts drawn coverage and fills only an empty interior', () {
    const focus = InpaintFocusRegion(
      x: 8,
      y: 8,
      width: 48,
      height: 48,
      context: 8,
    );
    final mask = Uint8List(64 * 64)
      ..[32 * 64 + 32] = 1
      ..[0] = 1;
    focus.applyToBinaryMask(mask, 64, 64);
    expect(mask.where((v) => v == 1).length, 1);
    expect(mask[32 * 64 + 32], 1);
    mask.fillRange(0, mask.length, 0);
    focus.applyToBinaryMask(mask, 64, 64);
    expect(mask.where((v) => v == 1).length, 32 * 32);
    expect(mask[15 * 64 + 15], 0);
    const invalidInterior = InpaintFocusRegion(
      x: 0,
      y: 0,
      width: 64,
      height: 64,
      context: 96,
    );
    invalidInterior.applyToBinaryMask(mask, 64, 64);
    expect(mask.every((v) => v == 0), isTrue);
  });
}

Uint8List _png(int width, int height, img.Color color) => Uint8List.fromList(
  img.encodePng(
    img.fill(
      img.Image(width: width, height: height),
      color: color,
    ),
  ),
);
Future<String> _noVibes(
  Uint8List image, {
  required String model,
  double informationExtracted = 1,
}) async => throw StateError('No vibes expected');
