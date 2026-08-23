import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_content_view.dart';

/// 画廊内容空态判定纯逻辑（P0-4）：空态检查必须走在 masonry/grid 分支之前，
/// 且无过滤时不能拿 filteredFiles（适配器语义下恒为空）当判据。
void main() {
  group('galleryContentEmptyKind', () {
    test('有过滤 + 结果为空 → noResults', () {
      expect(
        galleryContentEmptyKind(
          hasFilters: true,
          filteredFilesEmpty: true,
          currentImagesEmpty: true,
          isPageLoading: false,
        ),
        GalleryContentEmptyKind.noResults,
      );
    });

    test('有过滤 + 有结果 → 非空态（瀑布流应正常渲染）', () {
      expect(
        galleryContentEmptyKind(
          hasFilters: true,
          filteredFilesEmpty: false,
          currentImagesEmpty: false,
          isPageLoading: false,
        ),
        isNull,
      );
    });

    test('无过滤 + 当前页为空 + 不在加载 → emptyLibrary', () {
      expect(
        galleryContentEmptyKind(
          hasFilters: false,
          // 适配器语义：无过滤时 filteredFiles 恒为空，不能作数
          filteredFilesEmpty: true,
          currentImagesEmpty: true,
          isPageLoading: false,
        ),
        GalleryContentEmptyKind.emptyLibrary,
      );
    });

    test('无过滤 + 页面加载中 → 非空态（保留骨架屏）', () {
      expect(
        galleryContentEmptyKind(
          hasFilters: false,
          filteredFilesEmpty: true,
          currentImagesEmpty: true,
          isPageLoading: true,
        ),
        isNull,
      );
    });

    test('无过滤 + 当前页有图 → 非空态', () {
      expect(
        galleryContentEmptyKind(
          hasFilters: false,
          filteredFilesEmpty: true,
          currentImagesEmpty: false,
          isPageLoading: false,
        ),
        isNull,
      );
    });

    test('有过滤 + 空结果 + 加载中 → noResults（与历史行为一致）', () {
      expect(
        galleryContentEmptyKind(
          hasFilters: true,
          filteredFilesEmpty: true,
          currentImagesEmpty: true,
          isPageLoading: true,
        ),
        GalleryContentEmptyKind.noResults,
      );
    });
  });
}
