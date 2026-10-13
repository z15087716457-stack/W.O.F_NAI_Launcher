import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/enums/precise_ref_type.dart';
import 'package:nai_launcher/core/nai_agent/generation_snapshot.dart';
import 'package:nai_launcher/core/utils/inpaint_focus_region.dart';
import 'package:nai_launcher/core/utils/nai_api_utils.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';

void main() {
  final pixels = Uint8List.fromList(
    img.encodePng(img.Image(width: 4, height: 3)),
  );
  test(
    'complete JSON round trip retains all nonserialized generation fields',
    () {
      final precise = NAIApiUtils.markNormalizedPreciseReferencePng(
        Uint8List.fromList(pixels),
      );
      final original = ImageParams(
        prompt: 'raw',
        negativePrompt: 'negative',
        sourceImage: pixels,
        maskImage: pixels,
        action: ImageGenerationAction.infill,
        extraNoiseSeed: 123,
        enhanceWorkflow: true,
        isOutpaint: true,
        inpaintFocusRegion: const InpaintFocusRegion(
          x: 8,
          y: 16,
          width: 64,
          height: 128,
          context: 24,
        ),
        inpaintMaskClosingIterations: 2,
        inpaintMaskExpansionIterations: 3,
        vibeReferencesV4: [
          VibeReference(
            displayName: 'reference',
            vibeEncoding: 'encoded',
            rawImageData: pixels,
            thumbnail: pixels,
            encodingModel: 'nai-diffusion-4-full',
            sourceType: VibeSourceType.naiv4vibe,
            strength: 0.83,
            infoExtracted: 0.45,
            enabled: false,
            bundleSource: 'bundle',
          ),
        ],
        preciseReferences: [
          PreciseReference(
            image: precise,
            type: PreciseRefType.style,
            strength: 0.73,
            fidelity: 0.51,
            enabled: false,
          ),
        ],
        characters: const [
          CharacterPrompt(
            prompt: 'character',
            negativePrompt: 'uc',
            positionX: 0.2,
            positionY: 0.7,
            position: 'B3',
          ),
        ],
      );
      final saved =
          jsonDecode(jsonEncode(encodeAgentImageParams(original)))
              as Map<String, dynamic>;
      final actual = decodeAgentImageParams(saved);
      expect(actual.toJson(), original.toJson());
      expect(encodeAgentImageParams(actual), saved);
      expect(actual.sourceImage, pixels);
      expect(actual.maskImage, pixels);
      expect(actual.extraNoiseSeed, 123);
      expect(actual.enhanceWorkflow, isTrue);
      expect(actual.inpaintFocusRegion!.context, 24);
      expect(actual.vibeReferencesV4.single.rawImageData, pixels);
      expect(actual.vibeReferencesV4.single.thumbnail, pixels);
      expect(actual.preciseReferences.single.image, pixels);
      expect(
        NAIApiUtils.isKnownNormalizedPreciseReferencePng(
          actual.preciseReferences.single.image,
        ),
        isTrue,
      );
      expect(actual.characters.single.position, 'B3');
    },
  );
  test(
    'null references remain null rather than acquiring an image tool mode',
    () {
      final actual = decodeAgentImageParams(
        encodeAgentImageParams(const ImageParams()),
      );
      expect(actual.sourceImage, isNull);
      expect(actual.maskImage, isNull);
      expect(actual.inpaintFocusRegion, isNull);
      expect(actual.vibeReferencesV4, isEmpty);
    },
  );
  test(
    'malformed image encoding and reference type fail before application',
    () {
      final saved = encodeAgentImageParams(const ImageParams());
      saved['extra']['sourceImage'] = 'bad base64 !';
      expect(() => decodeAgentImageParams(saved), throwsFormatException);
      final type = encodeAgentImageParams(
        ImageParams(
          preciseReferences: [
            PreciseReference(image: pixels, type: PreciseRefType.character),
          ],
        ),
      );
      type['extra']['precise'][0]['type'] = 'unknown';
      expect(() => decodeAgentImageParams(type), throwsFormatException);
    },
  );
}
