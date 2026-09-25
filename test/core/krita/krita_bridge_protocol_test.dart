import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/enums/quality_tag_preset.dart';
import 'package:nai_launcher/core/krita/krita_bridge_models.dart';
import 'package:nai_launcher/core/krita/krita_bridge_protocol.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';

void main() {
  group('KritaBridgeProtocol', () {
    test('parses authenticated ping with matching secret', () {
      final result = KritaBridgeProtocol.decodeIncoming(
        jsonEncode({'type': 'ping', 'version': 1, 'secret': 'session-secret'}),
        sessionSecret: 'session-secret',
        authenticated: false,
      );

      expect(result.error, isNull);
      expect(result.message, isA<KritaPingMessage>());
      expect((result.message! as KritaPingMessage).version, 1);
    });

    test('rejects ping when secret is missing or wrong', () {
      final missing = KritaBridgeProtocol.decodeIncoming(
        jsonEncode({'type': 'ping', 'version': 1}),
        sessionSecret: 'session-secret',
        authenticated: false,
      );
      final wrong = KritaBridgeProtocol.decodeIncoming(
        jsonEncode({'type': 'ping', 'version': 1, 'secret': 'wrong-secret'}),
        sessionSecret: 'session-secret',
        authenticated: false,
      );

      expect(missing.error?.code, KritaBridgeErrorCode.authFailed);
      expect(wrong.error?.code, KritaBridgeErrorCode.authFailed);
    });

    test('rejects non-ping messages before authentication', () {
      final result = KritaBridgeProtocol.decodeIncoming(
        jsonEncode({'type': 'get_params', 'id': 'req-1'}),
        sessionSecret: 'session-secret',
        authenticated: false,
      );

      expect(result.message, isNull);
      expect(result.error?.code, KritaBridgeErrorCode.unauthorizedBridgeClient);
      expect(result.error?.id, 'req-1');
    });

    test('rejects oversized text frames before JSON decoding', () {
      final result = KritaBridgeProtocol.decodeIncoming(
        '{"type":"ping"}',
        sessionSecret: 'session-secret',
        authenticated: false,
        maxTextFrameBytes: 8,
      );

      expect(result.message, isNull);
      expect(result.error?.code, KritaBridgeErrorCode.payloadTooLarge);
    });

    test('rejects decoded image bytes above the configured limit', () {
      final result = KritaBridgeProtocol.decodeIncoming(
        jsonEncode({
          'type': 'img2img',
          'id': 'req-large-image',
          'image': base64Encode([1, 2, 3]),
        }),
        sessionSecret: 'session-secret',
        authenticated: true,
        maxDecodedImageBytes: 2,
      );

      expect(result.message, isNull);
      expect(result.error?.id, 'req-large-image');
      expect(result.error?.code, KritaBridgeErrorCode.payloadTooLarge);
    });

    test('rejects img2img payloads that are not PNG images', () {
      final result = KritaBridgeProtocol.decodeIncoming(
        jsonEncode({
          'type': 'img2img',
          'id': 'req-not-png',
          'image': base64Encode([1, 2, 3]),
        }),
        sessionSecret: 'session-secret',
        authenticated: true,
      );

      expect(result.message, isNull);
      expect(result.error?.id, 'req-not-png');
      expect(result.error?.code, KritaBridgeErrorCode.invalidRequest);
    });

    test('rejects malformed PNG headers without throwing raw exceptions', () {
      final bytes = _pngWithDimensions(128, 128);
      bytes[12] = 0xff;
      bytes[13] = 0xff;
      bytes[14] = 0xff;
      bytes[15] = 0xff;

      final result = KritaBridgeProtocol.decodeIncoming(
        jsonEncode({
          'type': 'img2img',
          'id': 'req-bad-png-header',
          'image': base64Encode(bytes),
        }),
        sessionSecret: 'session-secret',
        authenticated: true,
      );

      expect(result.message, isNull);
      expect(result.error?.id, 'req-bad-png-header');
      expect(result.error?.code, KritaBridgeErrorCode.invalidRequest);
    });

    test('rejects img2img PNGs larger than bridge V1 canvas bounds', () {
      final result = KritaBridgeProtocol.decodeIncoming(
        jsonEncode({
          'type': 'img2img',
          'id': 'req-large-canvas',
          'image': base64Encode(_pngWithDimensions(4097, 4096)),
        }),
        sessionSecret: 'session-secret',
        authenticated: true,
      );

      expect(result.message, isNull);
      expect(result.error?.id, 'req-large-canvas');
      expect(result.error?.code, KritaBridgeErrorCode.invalidRequest);
    });

    test('rejects V1 scaled payload metadata instead of ignoring it', () {
      final result = KritaBridgeProtocol.decodeIncoming(
        jsonEncode({
          'type': 'img2img',
          'id': 'req-scaled-payload',
          'image': base64Encode(_pngWithDimensions(128, 128)),
          'image_scale': {
            'original_width': 6000,
            'original_height': 4000,
            'sent_width': 4096,
            'sent_height': 2731,
            'scale_x': 0.6826667,
            'scale_y': 0.68275,
          },
        }),
        sessionSecret: 'session-secret',
        authenticated: true,
      );

      expect(result.message, isNull);
      expect(result.error?.id, 'req-scaled-payload');
      expect(result.error?.code, KritaBridgeErrorCode.invalidRequest);
    });

    test('rejects inpaint when image and mask PNG dimensions differ', () {
      final result = KritaBridgeProtocol.decodeIncoming(
        jsonEncode({
          'type': 'inpaint',
          'id': 'req-mismatched-mask',
          'image': base64Encode(_pngWithDimensions(128, 128)),
          'mask': base64Encode(_pngWithDimensions(64, 128)),
        }),
        sessionSecret: 'session-secret',
        authenticated: true,
      );

      expect(result.message, isNull);
      expect(result.error?.id, 'req-mismatched-mask');
      expect(result.error?.code, KritaBridgeErrorCode.invalidRequest);
    });

    test('rejects inpaint PNGs smaller than bridge V1 canvas bounds', () {
      final result = KritaBridgeProtocol.decodeIncoming(
        jsonEncode({
          'type': 'inpaint',
          'id': 'req-small-canvas',
          'image': base64Encode(_pngWithDimensions(63, 128)),
          'mask': base64Encode(_pngWithDimensions(63, 128)),
        }),
        sessionSecret: 'session-secret',
        authenticated: true,
      );

      expect(result.message, isNull);
      expect(result.error?.id, 'req-small-canvas');
      expect(result.error?.code, KritaBridgeErrorCode.invalidRequest);
    });

    test('returns unsupported_message for unknown authenticated type', () {
      final result = KritaBridgeProtocol.decodeIncoming(
        jsonEncode({'type': 'mystery', 'id': 'req-2'}),
        sessionSecret: 'session-secret',
        authenticated: true,
      );

      expect(result.message, isNull);
      expect(result.error?.code, KritaBridgeErrorCode.unsupportedMessage);
      expect(result.error?.id, 'req-2');
    });

    test('accepts payload envelope and ignores unknown fields', () {
      final result = KritaBridgeProtocol.decodeIncoming(
        jsonEncode({
          'type': 'img2img',
          'id': 'req-3',
          'version': 1,
          'payload': {
            'image': base64Encode(_pngWithDimensions(128, 128)),
            'prompt': '1girl',
            'negative_prompt': 'lowres',
            'strength': 0.45,
            'noise': 0.1,
            'future_field': true,
          },
        }),
        sessionSecret: 'session-secret',
        authenticated: true,
      );

      final message = result.message as KritaImg2ImgMessage;
      expect(message.id, 'req-3');
      expect(message.image, _pngWithDimensions(128, 128));
      expect(message.prompt, '1girl');
      expect(message.negativePrompt, 'lowres');
      expect(message.strength, 0.45);
      expect(message.noise, 0.1);
    });
  });

  group('KritaBridge request mapping', () {
    test('quality_preset overrides legacy quality_toggle for generate', () {
      const base = ImageParams(
        qualityToggle: true,
        qualityTagPreset: QualityTagPreset.standard,
      );

      final light = applyKritaParamsOverlay(base, {
        'quality_preset': 'light',
        'quality_toggle': false,
      });
      final legacyOff = applyKritaParamsOverlay(base, {
        'quality_toggle': false,
      });

      expect(light.qualityToggle, isTrue);
      expect(light.qualityTagPreset, QualityTagPreset.light);
      expect(legacyOff.qualityToggle, isFalse);
      expect(legacyOff.qualityTagPreset, QualityTagPreset.none);
    });

    test('maps inpaint fields onto ImageParams', () {
      final result = KritaBridgeProtocol.decodeIncoming(
        jsonEncode({
          'type': 'inpaint',
          'id': 'req-inpaint',
          'image': base64Encode(_pngWithDimensions(1024, 768)),
          'mask': base64Encode(_pngWithDimensions(1024, 768)),
          'prompt': 'paint stars',
          'negative_prompt': 'blurry',
          'strength': 0.7,
          'noise': 0.05,
          'inpaint_strength': 0.9,
          'mask_closing_iterations': 2,
          'mask_expansion_iterations': 3,
        }),
        sessionSecret: 'session-secret',
        authenticated: true,
      );

      final mapping = (result.message! as KritaInpaintMessage).toImageParams(
        const ImageParams(model: 'nai-diffusion-4-5-full-inpainting'),
      );

      expect(mapping.params.action, ImageGenerationAction.infill);
      expect(mapping.params.model, 'nai-diffusion-4-5-full-inpainting');
      expect(mapping.params.sourceImage, _pngWithDimensions(1024, 768));
      expect(mapping.params.maskImage, _pngWithDimensions(1024, 768));
      expect(mapping.params.prompt, 'paint stars');
      expect(mapping.params.negativePrompt, 'blurry');
      expect(mapping.params.strength, 0.7);
      expect(mapping.params.noise, 0.05);
      expect(mapping.params.inpaintStrength, 0.9);
      expect(mapping.params.inpaintMaskClosingIterations, 2);
      expect(mapping.params.inpaintMaskExpansionIterations, 3);
    });

    test('maps non-inpainting base models to matching inpainting models', () {
      final result = KritaBridgeProtocol.decodeIncoming(
        jsonEncode({
          'type': 'inpaint',
          'id': 'req-inpaint-model',
          'image': base64Encode(_pngWithDimensions(832, 1216)),
          'mask': base64Encode(_pngWithDimensions(832, 1216)),
        }),
        sessionSecret: 'session-secret',
        authenticated: true,
      );

      final mapping = (result.message! as KritaInpaintMessage).toImageParams(
        const ImageParams(model: 'nai-diffusion-4-5-full'),
      );

      expect(mapping.params.action, ImageGenerationAction.infill);
      expect(mapping.params.model, 'nai-diffusion-4-5-full-inpainting');
    });

    test(
      'maps img2img request onto ImageParams without touching base settings',
      () {
        final result = KritaBridgeProtocol.decodeIncoming(
          jsonEncode({
            'type': 'img2img',
            'id': 'req-img2img',
            'image': base64Encode(_pngWithDimensions(512, 512)),
            'prompt': 'sketch',
            'negative_prompt': 'bad anatomy',
            'strength': 0.35,
            'noise': 0.2,
          }),
          sessionSecret: 'session-secret',
          authenticated: true,
        );

        final mapping = (result.message! as KritaImg2ImgMessage).toImageParams(
          const ImageParams(model: 'nai-diffusion-4-full', width: 1024),
        );

        expect(mapping.params.action, ImageGenerationAction.img2img);
        expect(mapping.params.sourceImage, _pngWithDimensions(512, 512));
        expect(mapping.params.prompt, 'sketch');
        expect(mapping.params.negativePrompt, 'bad anatomy');
        expect(mapping.params.strength, 0.35);
        expect(mapping.params.noise, 0.2);
        expect(mapping.params.model, 'nai-diffusion-4-full');
        expect(mapping.params.width, 1024);
      },
    );
  });
}

Uint8List _pngWithDimensions(int width, int height) {
  final bytes = Uint8List(33);
  bytes.setAll(0, const [137, 80, 78, 71, 13, 10, 26, 10]);
  final data = ByteData.view(bytes.buffer);
  data.setUint32(8, 13);
  bytes.setAll(12, ascii.encode('IHDR'));
  data.setUint32(16, width);
  data.setUint32(20, height);
  bytes[24] = 8;
  bytes[25] = 6;
  return bytes;
}
