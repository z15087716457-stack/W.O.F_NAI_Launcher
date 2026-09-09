import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_category_tree_view.dart';

void main() {
  group('GalleryCategoryTreeView drag data', () {
    test('reads original gallery path from internal drag localData', () {
      expect(
        galleryInternalDragPathFromLocalData({
          'source': 'gallery_internal',
          'path': r'C:\gallery\image.png',
          'externalPayload': 'gallery_sanitized',
        }),
        r'C:\gallery\image.png',
      );
    });

    test('ignores non-gallery localData', () {
      expect(
        galleryInternalDragPathFromLocalData({
          'source': 'history_internal',
          'path': r'C:\gallery\image.png',
        }),
        isNull,
      );
    });

    test(
      'galleryInternalDragPathsFromLocalData prioritizes paths over path',
      () {
        expect(
          galleryInternalDragPathsFromLocalData({
            'source': 'gallery_internal',
            'path': r'C:\gallery\single.png',
            'paths': [r'C:\gallery\1.png', r'C:\gallery\2.png'],
          }),
          [r'C:\gallery\1.png', r'C:\gallery\2.png'],
        );
      },
    );

    test('galleryInternalDragPathsFromLocalData falls back to single path', () {
      expect(
        galleryInternalDragPathsFromLocalData({
          'source': 'gallery_internal',
          'path': r'C:\gallery\single.png',
        }),
        [r'C:\gallery\single.png'],
      );
    });

    test(
      'galleryInternalDragPathsFromLocalData returns null for non-gallery or invalid data',
      () {
        expect(
          galleryInternalDragPathsFromLocalData({
            'source': 'other_source',
            'paths': [r'C:\gallery\1.png'],
          }),
          isNull,
        );
        expect(galleryInternalDragPathsFromLocalData(null), isNull);
        expect(galleryInternalDragPathsFromLocalData('invalid'), isNull);
        expect(
          galleryInternalDragPathsFromLocalData({'source': 'gallery_internal'}),
          isNull,
        );
        expect(
          galleryInternalDragPathsFromLocalData({
            'source': 'gallery_internal',
            'paths': <String>[],
          }),
          isNull,
        );
      },
    );
  });
}
