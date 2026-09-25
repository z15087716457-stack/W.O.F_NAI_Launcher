import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/inpaint_mask_utils.dart';

void main() {
  test('binary mask compression uses canvas-compatible center sampling', () {
    final source = Uint8List.fromList([0, 1, 0, 1, 1, 0, 1, 0]);

    final resized = InpaintMaskUtils.resizeBinaryMask(
      source,
      sourceWidth: 4,
      sourceHeight: 2,
      targetWidth: 2,
      targetHeight: 1,
    );

    expect(resized, Uint8List.fromList([0, 0]));
  });
}
