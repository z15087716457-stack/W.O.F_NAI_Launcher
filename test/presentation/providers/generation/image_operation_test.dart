import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/image/image_operation.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/services/canvas_pin_repository.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_models.dart';

void main() {
  test('OLD freezes the source and mask and preserves both through copies', () {
    final source = Uint8List.fromList([1, 2, 3]);
    final mask = Uint8List.fromList([4, 5, 6]);
    final result = GeneratedImage.create(
      Uint8List.fromList([7, 8]),
      width: 64,
      height: 96,
      sourceParams: ImageParams(
        action: ImageGenerationAction.infill,
        sourceImage: source,
        maskImage: mask,
      ),
    );
    source[0] = 99;
    mask[0] = 99;
    final saved = result
        .copyWith(generationRunId: 8, batchIndex: 1)
        .copyWithFilePath('saved.png');
    expect(saved.canCompareOriginal, isTrue);
    expect(saved.originalBytes, orderedEquals([1, 2, 3]));
    expect(saved.inpaintMaskBytes, orderedEquals([4, 5, 6]));
    expect(saved.bytes, same(result.bytes));
    expect(saved.id, result.id);
    expect(saved.inpaintMaskBytes, same(result.inpaintMaskBytes));
  });

  test(
    'OLD needs a completed non-variation source and only infill retains a mask',
    () {
      for (final action in ImageGenerationAction.values) {
        final image = GeneratedImage.create(
          Uint8List(0),
          width: 1,
          height: 1,
          sourceParams: ImageParams(
            action: action,
            sourceImage: Uint8List(1),
            maskImage: Uint8List(1),
          ),
        );
        expect(
          image.inpaintMaskBytes != null,
          action == ImageGenerationAction.infill,
        );
      }
      for (final kind in GeneratedImageKind.values) {
        final image = GeneratedImage(
          id: 'image',
          bytes: Uint8List(0),
          width: 1,
          height: 1,
          kind: kind,
          originalBytes: Uint8List(1),
        );
        expect(image.canCompareOriginal, kind == GeneratedImageKind.completed);
      }
      expect(
        GeneratedImage.create(
          Uint8List(0),
          width: 1,
          height: 1,
          originalBytes: Uint8List(1),
          isVariationOriginal: true,
        ).canCompareOriginal,
        isFalse,
      );
      expect(
        GeneratedImage.create(
          Uint8List(0),
          width: 1,
          height: 1,
        ).canCompareOriginal,
        isFalse,
      );
      expect(
        GeneratedImage.create(
          Uint8List(0),
          width: 1,
          height: 1,
          originalBytes: Uint8List(0),
        ).canCompareOriginal,
        isFalse,
      );
    },
  );
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
      expect(saved.originalBytes, orderedEquals(source));
      expect(saved.originalBytes, isNot(same(source)));
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
