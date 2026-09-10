import '../../../core/cache/thumbnail_cache_service.dart';
import '../../../data/services/gallery/gallery_view_mode.dart';
import 'gallery_grid.dart';

/// 相邻页缩略图预取的选档宽度（纯函数，可单测）。
///
/// 目标：预取请求的档位与各视图卡片实际请求的档位一致——卡片侧
/// （local_image_card_3d 的 _pickSizeForCurrentWidth）用布局真实宽度
/// `resolveThumbnailTier(widget.width, dpr, quality)`，预取侧必须用同一
/// 宽度口径，否则（路径, 档位）去重键对不上，预取全部白做。
///
/// 各视图的卡片宽来源（与布局代码同源，改布局时同步这里）：
/// - grid（固定方格）：`ResponsiveLayout.fixedCardWidth`（180，硬编码）；
/// - masonry（瀑布流）：实际列宽 = 可用宽/列数 ≈ `columnWidth`
///   （列数 = 可用宽/columnWidth 向下取整，实际列宽只会略大，边界档罕见）；
/// - justified（火车流）：卡片宽 = 行高 × 宽高比，行高锚 = columnWidth
///   （面积锚 t/√行内平均宽高比，与窗宽解耦；此处按 t×宽高比估算，
///   忽略 √平均比项的 ±20% 偏差，同宽高比聚行时个别卡片可能差一档）；
/// - 分组视图：分组网格用屏幕层 itemWidth（可用宽/列数 ≥ columnWidth），
///   provider 侧拿不到屏幕宽度，按 columnWidth 估算。
double galleryPreloadCardWidth({
  required GalleryViewMode viewMode,
  required double columnWidth,
  required bool isGroupedView,
  double? aspectRatio,
}) {
  if (isGroupedView) return columnWidth;

  switch (viewMode) {
    case GalleryViewMode.grid:
      return ResponsiveLayout.fixedCardWidth;
    case GalleryViewMode.masonry:
      return columnWidth;
    case GalleryViewMode.justified:
      final ratio = aspectRatio ?? 1.0;
      final safe = ratio.isFinite && ratio > 0 ? ratio : 1.0;
      return columnWidth * safe;
  }
}

/// 预取条目 → 缩略图档位（预取侧与卡片侧选档的汇聚点）。
ThumbnailSize galleryPreloadThumbnailSize({
  required GalleryViewMode viewMode,
  required double columnWidth,
  required double devicePixelRatio,
  required GalleryThumbnailQuality quality,
  required bool isGroupedView,
  double? aspectRatio,
}) {
  return resolveThumbnailTier(
    galleryPreloadCardWidth(
      viewMode: viewMode,
      columnWidth: columnWidth,
      isGroupedView: isGroupedView,
      aspectRatio: aspectRatio,
    ),
    devicePixelRatio,
    quality,
  );
}
