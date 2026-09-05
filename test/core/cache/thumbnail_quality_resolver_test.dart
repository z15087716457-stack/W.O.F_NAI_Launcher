import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';

void main() {
  group('resolveThumbnailTier', () {
    test('sd always resolves to the small tier', () {
      expect(
        resolveThumbnailTier(1000, 4, GalleryThumbnailQuality.sd),
        ThumbnailSize.small,
      );
    });

    test('hd delegates to the existing physical-width resolver', () {
      expect(
        resolveThumbnailTier(100, 1, GalleryThumbnailQuality.hd),
        ThumbnailSize.small,
      );
      expect(
        resolveThumbnailTier(200, 1, GalleryThumbnailQuality.hd),
        ThumbnailSize.medium,
      );
      expect(
        resolveThumbnailTier(400, 1, GalleryThumbnailQuality.hd),
        ThumbnailSize.large,
      );
    });
  });
}
