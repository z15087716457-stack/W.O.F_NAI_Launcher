import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/image/image_operation.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/services/canvas_pin_repository.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_models.dart';

void main() {
  test(
    'history provenance follows request snapshots and survives saved copies',
    () {
      final source = Uint8List.fromList([1, 2, 3]);
      final result = GeneratedImage.create(
        Uint8List(0),
        width: 64,
        height: 96,
        sourceParams: ImageParams(
          action: ImageGenerationAction.infill,
          sourceImage: source,
        ),
      );
      const nextDraft = ImageParams(
        enhanceWorkflow: true,
        action: ImageGenerationAction.img2img,
      );
      expect(ImageOperation.fromParams(nextDraft), ImageOperation.enhance);
      expect(result.operation, ImageOperation.inpaint);
      final saved = result
          .copyWith(generationRunId: 7, batchIndex: 2)
          .copyWithFilePath('result.png');
      expect(saved.operation, ImageOperation.inpaint);
      expect(saved.originalBytes, same(source));
      expect(saved.generationRunId, 7);
      final variation = GeneratedImage.create(
        Uint8List(0),
        width: 1,
        height: 1,
        sourceParams: nextDraft,
        operation: ImageOperation.variations,
      );
      expect(variation.operation, ImageOperation.variations);
    },
  );

  test('pin manifest retains tool identity and reads older manifests', () {
    final pin = CanvasPinRecord(
      imageId: 'tool-image',
      fileName: 'image.png',
      width: 64,
      height: 64,
      createdAt: DateTime(2026),
      operation: ImageOperation.pixelSnap,
    );
    final raw = pin.toJson();
    expect(CanvasPinRecord.tryParse(raw)?.operation, ImageOperation.pixelSnap);
    raw.remove('operation');
    expect(CanvasPinRecord.tryParse(raw)?.operation, isNull);
    raw['operation'] = 'future-tool';
    expect(CanvasPinRecord.tryParse(raw)?.imageId, 'tool-image');
  });
}
