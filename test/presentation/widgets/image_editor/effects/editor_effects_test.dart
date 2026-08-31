import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/presentation/widgets/image_editor/effects/editor_effects.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('editor local effects', () {
    test(
      'every effect produces a valid changed image through compute',
      () async {
        final source = _buildSourceImage();
        final sourceBytes = Uint8List.fromList(img.encodePng(source));
        final sourceSignature = _imageSignature(source);

        for (final type in EditorEffectType.values) {
          final cropRect = type == EditorEffectType.cropToSelection
              ? const EditorEffectCropRect(x: 3, y: 2, width: 7, height: 5)
              : null;
          final job = EditorEffectJob(
            imageBytes: sourceBytes,
            effectType: type,
            intensity: editorEffectDefaultIntensity(type),
            cropRect: cropRect,
          );

          final result = EditorEffectResult.fromMessage(
            await compute(
              runEditorEffectJobMessage,
              job.toMessage(),
              debugLabel: 'editor_effect_test_${type.name}',
            ),
          );
          final decoded = img.decodePng(result.bytes);

          expect(decoded, isNotNull, reason: '${type.name} did not decode');
          expect(result.width, decoded!.width, reason: type.name);
          expect(result.height, decoded.height, reason: type.name);

          if (type == EditorEffectType.rotateLeft ||
              type == EditorEffectType.rotateRight) {
            expect(decoded.width, source.height, reason: type.name);
            expect(decoded.height, source.width, reason: type.name);
          } else if (type == EditorEffectType.cropToSelection) {
            expect(decoded.width, cropRect!.width, reason: type.name);
            expect(decoded.height, cropRect.height, reason: type.name);
          } else {
            expect(decoded.width, source.width, reason: type.name);
            expect(decoded.height, source.height, reason: type.name);
          }

          expect(
            _imageSignature(decoded),
            isNot(sourceSignature),
            reason: '${type.name} did not change the test image',
          );
        }
      },
    );

    test('crop effect requires a selection rectangle', () {
      final source = _buildSourceImage();
      final sourceBytes = Uint8List.fromList(img.encodePng(source));

      expect(
        () => runEditorEffectJob(
          EditorEffectJob(
            imageBytes: sourceBytes,
            effectType: EditorEffectType.cropToSelection,
            intensity: 1.0,
          ),
        ),
        throwsStateError,
      );
    });
  });
}

img.Image _buildSourceImage() {
  final image = img.Image(width: 17, height: 11);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final checker = (x + y).isEven ? 220 : 32;
      image.setPixelRgba(
        x,
        y,
        (x * 17 + y * 11 + checker).clamp(0, 255),
        (x * 7 + y * 23 + 48).clamp(0, 255),
        (x * 31 + y * 5 + (255 - checker)).clamp(0, 255),
        255,
      );
    }
  }
  return image;
}

String _imageSignature(img.Image image) {
  final buffer = StringBuffer('${image.width}x${image.height}:');
  for (final pixel in image) {
    buffer
      ..write(pixel.r.toInt())
      ..write(',')
      ..write(pixel.g.toInt())
      ..write(',')
      ..write(pixel.b.toInt())
      ..write(';');
  }
  return buffer.toString();
}
