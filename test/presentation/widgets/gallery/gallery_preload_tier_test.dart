import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_view_mode.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_grid.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_preload_tier.dart';

void main() {
  group('galleryPreloadCardWidth（预取选档宽度与卡片布局同源）', () {
    test('grid = 固定方格卡片宽（180）', () {
      expect(
        galleryPreloadCardWidth(
          viewMode: GalleryViewMode.grid,
          columnWidth: 260,
          isGroupedView: false,
        ),
        ResponsiveLayout.fixedCardWidth,
      );
    });

    test('masonry = 逻辑列宽', () {
      expect(
        galleryPreloadCardWidth(
          viewMode: GalleryViewMode.masonry,
          columnWidth: 320,
          isGroupedView: false,
        ),
        320,
      );
    });

    test('justified = 列宽 × 宽高比（行高锚≈列宽）', () {
      expect(
        galleryPreloadCardWidth(
          viewMode: GalleryViewMode.justified,
          columnWidth: 260,
          isGroupedView: false,
          aspectRatio: 832 / 1216,
        ),
        closeTo(260 * 832 / 1216, 0.001),
      );
      expect(
        galleryPreloadCardWidth(
          viewMode: GalleryViewMode.justified,
          columnWidth: 260,
          isGroupedView: false,
          aspectRatio: 1.0,
        ),
        260,
      );
    });

    test('justified 无尺寸/非法宽高比按 1.0 处理', () {
      for (final bad in <double?>[null, 0, -1.5, double.nan, double.infinity]) {
        expect(
          galleryPreloadCardWidth(
            viewMode: GalleryViewMode.justified,
            columnWidth: 260,
            isGroupedView: false,
            aspectRatio: bad,
          ),
          260,
          reason: 'aspectRatio=$bad 应按 1.0 处理',
        );
      }
    });

    test('分组视图优先于视图模式（分组网格按列宽估）', () {
      expect(
        galleryPreloadCardWidth(
          viewMode: GalleryViewMode.grid,
          columnWidth: 300,
          isGroupedView: true,
        ),
        300,
      );
    });
  });

  group('galleryPreloadThumbnailSize（预取档位 == 卡片请求档位）', () {
    // 卡片侧：resolveThumbnailTier(布局宽度, dpr, quality)
    // 预取侧：galleryPreloadThumbnailSize(同参数) —— 两者必须给出同档，
    // 否则 (路径, 档位) 去重键对不上，预取全部白做。
    for (final dpr in [1.0, 1.25, 1.5, 2.0]) {
      test('DPR $dpr 下各视图档位与卡片请求一致', () {
        const columnWidth = 260.0;

        // grid：卡片宽 180（ResponsiveLayout.fixedCardWidth）
        expect(
          galleryPreloadThumbnailSize(
            viewMode: GalleryViewMode.grid,
            columnWidth: columnWidth,
            devicePixelRatio: dpr,
            quality: GalleryThumbnailQuality.hd,
            isGroupedView: false,
          ),
          resolveThumbnailTier(
            ResponsiveLayout.fixedCardWidth,
            dpr,
            GalleryThumbnailQuality.hd,
          ),
        );

        // masonry：卡片宽 = 列宽
        expect(
          galleryPreloadThumbnailSize(
            viewMode: GalleryViewMode.masonry,
            columnWidth: columnWidth,
            devicePixelRatio: dpr,
            quality: GalleryThumbnailQuality.hd,
            isGroupedView: false,
          ),
          resolveThumbnailTier(columnWidth, dpr, GalleryThumbnailQuality.hd),
        );

        // justified：卡片宽 = 列宽 × 宽高比（典型 NAI 画幅）
        for (final dims in [
          (832, 1216), // 竖图
          (1024, 1024), // 方图
          (1216, 832), // 横图
        ]) {
          final aspect = dims.$1 / dims.$2;
          expect(
            galleryPreloadThumbnailSize(
              viewMode: GalleryViewMode.justified,
              columnWidth: columnWidth,
              devicePixelRatio: dpr,
              quality: GalleryThumbnailQuality.hd,
              isGroupedView: false,
              aspectRatio: aspect,
            ),
            resolveThumbnailTier(
              columnWidth * aspect,
              dpr,
              GalleryThumbnailQuality.hd,
            ),
            reason: 'dims=$dims',
          );
        }

        // sd 质量恒 small（两路径共用 resolveThumbnailTier 语义）
        expect(
          galleryPreloadThumbnailSize(
            viewMode: GalleryViewMode.justified,
            columnWidth: columnWidth,
            devicePixelRatio: dpr,
            quality: GalleryThumbnailQuality.sd,
            isGroupedView: false,
            aspectRatio: 2.0,
          ),
          ThumbnailSize.small,
        );
      });
    }

    test('回归锚：DPR 1.0 + 列宽 260 下，旧实现（恒用列宽）在网格与火车流错档', () {
      // 网格：卡片要 small(180×1.0≤180)，旧预取按 260 → medium
      expect(
        resolveThumbnailTier(180, 1.0, GalleryThumbnailQuality.hd),
        ThumbnailSize.small,
      );
      expect(
        resolveThumbnailTier(260, 1.0, GalleryThumbnailQuality.hd),
        ThumbnailSize.medium,
      );

      // 火车流横图 1216×832：卡片要 large(260×1.462>360)，旧预取 medium
      expect(
        resolveThumbnailTier(260 * 1216 / 832, 1.0, GalleryThumbnailQuality.hd),
        ThumbnailSize.large,
      );
    });
  });
}
