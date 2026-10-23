import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';

void main() {
  group('resolveThumbnailTier', () {
    ThumbnailSize cover(double w, double h, double aspect, {double dpr = 1}) =>
        resolveThumbnailTier(
          w,
          dpr,
          GalleryThumbnailQuality.hd,
          cardHeight: h,
          imageAspect: aspect,
        );
    test(
      'cover uses actual fitted pixels for grid, masonry, landscape and train',
      () {
        const portrait = 832 / 1216;
        expect(cover(250, 250, portrait), ThumbnailSize.large);
        expect(cover(330, 330 / portrait, portrait), ThumbnailSize.large);
        expect(cover(200, 200, 1.5), ThumbnailSize.large);
        expect(cover(300, 200, 1.5), ThumbnailSize.large);
        // Train was already sharp at these sizes, and stays on the same tier.
        expect(cover(200, 200 / 1.5, 1.5), pickThumbnailSize(200, 1));
        expect(cover(400, 400 / portrait, portrait), ThumbnailSize.large);
        expect(cover(50, 50, portrait, dpr: 2), ThumbnailSize.small);
        expect(cover(1000, 1000, portrait, dpr: 4), ThumbnailSize.large);
        expect(
          resolveThumbnailTier(
            330,
            4,
            GalleryThumbnailQuality.sd,
            cardHeight: 330,
            imageAspect: portrait,
          ),
          ThumbnailSize.small,
        );
      },
    );
    test(
      'decode size keeps one axis and covers instead of stretching square crops',
      () {
        final portrait = thumbnailCoverDecodeSize(
          cardWidth: 250,
          cardHeight: 250,
          imageAspect: 832 / 1216,
          devicePixelRatio: 1,
          quality: GalleryThumbnailQuality.hd,
          tier: ThumbnailSize.large,
        );
        expect(portrait, (width: 375, height: null));
        final landscape = thumbnailCoverDecodeSize(
          cardWidth: 250,
          cardHeight: 250,
          imageAspect: 1.5,
          devicePixelRatio: 1,
          quality: GalleryThumbnailQuality.hd,
          tier: ThumbnailSize.large,
        );
        expect(landscape, (width: null, height: 375));
        final capped = thumbnailCoverDecodeSize(
          cardWidth: 1000,
          cardHeight: 1000,
          imageAspect: 832 / 1216,
          devicePixelRatio: 4,
          quality: GalleryThumbnailQuality.hd,
          tier: ThumbnailSize.large,
        );
        expect(capped, (width: 602, height: null));
      },
    );
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
