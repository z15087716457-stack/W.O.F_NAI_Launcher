import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/presentation/screens/generation/widgets/img2img_preview_cache.dart';

void main() {
  group('resolveSourcePreviewDimensions', () {
    test('uses known source dimensions without reading image bytes', () {
      var imageSizeReadCount = 0;

      final dimensions = resolveSourcePreviewDimensions(
        sourceBytes: Uint8List.fromList([1, 2, 3]),
        sourceWidth: 8000,
        sourceHeight: 6000,
        fallbackWidth: 1216,
        fallbackHeight: 896,
        imageSizeReader: (_) {
          imageSizeReadCount += 1;
          return (1, 1);
        },
      );

      expect(dimensions, equals((8000, 6000)));
      expect(imageSizeReadCount, isZero);
    });

    test(
      'reads encoded source dimensions instead of request bucket dimensions',
      () {
        final sourceBytes = Uint8List.fromList(
          img.encodePng(img.Image(width: 1500, height: 900)),
        );

        final dimensions = resolveSourcePreviewDimensions(
          sourceBytes: sourceBytes,
          fallbackWidth: 1472,
          fallbackHeight: 896,
        );

        expect(dimensions.$1, equals(1500));
        expect(dimensions.$2, equals(900));
      },
    );

    test(
      'uses fallback request dimensions when encoded size is unreadable',
      () {
        final dimensions = resolveSourcePreviewDimensions(
          sourceBytes: Uint8List.fromList([1, 2, 3]),
          fallbackWidth: 1472,
          fallbackHeight: 896,
        );

        expect(dimensions.$1, equals(1472));
        expect(dimensions.$2, equals(896));
      },
    );
  });

  group('Img2ImgPreviewCache', () {
    test('should reuse mask overlay results when inputs stay unchanged', () {
      var maskOverlayCalls = 0;
      final cache = Img2ImgPreviewCache(
        maskOverlayBuilder: (maskImage) {
          maskOverlayCalls += 1;
          return Uint8List.fromList([maskOverlayCalls]);
        },
      );
      final maskImage = Uint8List.fromList([4, 5, 6]);

      final first = cache.resolve(maskImage: maskImage);
      final second = cache.resolve(maskImage: maskImage);

      expect(maskOverlayCalls, equals(1));
      expect(
        identical(second.maskOverlayBytes, first.maskOverlayBytes),
        isTrue,
      );
    });

    test('should recompute mask overlay only when mask input changes', () {
      var maskOverlayCalls = 0;
      final cache = Img2ImgPreviewCache(
        maskOverlayBuilder: (maskImage) {
          maskOverlayCalls += 1;
          return maskImage;
        },
      );
      final maskImage = Uint8List.fromList([4, 5, 6]);

      final cleared = cache.resolve(maskImage: null);
      final first = cache.resolve(maskImage: maskImage);
      final second = cache.resolve(maskImage: maskImage);
      final third = cache.resolve(maskImage: Uint8List.fromList([7, 8, 9]));

      expect(cleared.maskOverlayBytes, isNull);
      expect(first.maskOverlayBytes, isNotNull);
      expect(
        identical(second.maskOverlayBytes, first.maskOverlayBytes),
        isTrue,
      );
      expect(
        identical(third.maskOverlayBytes, first.maskOverlayBytes),
        isFalse,
      );
      expect(maskOverlayCalls, equals(2));
    });
  });
}
