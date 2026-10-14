import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/utils/inpaint_mask_utils.dart';

void main() {
  test('OLD keeps black clear and shows only white mask at 30 percent', () {
    final mask = img.Image(width: 2, height: 1, numChannels: 4)
      ..setPixelRgba(0, 0, 0, 0, 0, 255)
      ..setPixelRgba(1, 0, 255, 255, 255, 255);
    final bytes = Uint8List.fromList(img.encodePng(mask));
    final before = Uint8List.fromList(bytes);
    final overlay = img.decodePng(
      InpaintMaskUtils.maskToComparisonOverlay(bytes)!,
    )!;
    expect(overlay.width, 2);
    expect(overlay.height, 1);
    expect(overlay.getPixel(0, 0).a, 0);
    expect(overlay.getPixel(1, 0).r, 255);
    expect(overlay.getPixel(1, 0).g, 255);
    expect(overlay.getPixel(1, 0).b, 255);
    expect(overlay.getPixel(1, 0).a, 77);
    expect(bytes, orderedEquals(before));
  });

  test(
    'transparent mask background stays clear and invalid bytes are omitted',
    () {
      final mask = img.Image(width: 2, height: 1, numChannels: 4)
        ..setPixelRgba(0, 0, 255, 255, 255, 0)
        ..setPixelRgba(1, 0, 96, 170, 255, 140);
      final overlay = img.decodePng(
        InpaintMaskUtils.maskToComparisonOverlay(
          Uint8List.fromList(img.encodePng(mask)),
        )!,
      )!;
      expect(overlay.getPixel(0, 0).a, 0);
      expect(overlay.getPixel(1, 0).a, 77);
      expect(
        InpaintMaskUtils.maskToComparisonOverlay(Uint8List.fromList([1, 2, 3])),
        isNull,
      );
    },
  );
}
