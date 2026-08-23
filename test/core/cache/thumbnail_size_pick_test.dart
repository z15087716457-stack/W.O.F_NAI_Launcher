import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';

/// 缩略图档位挑选纯函数测试：物理需求 = 逻辑宽 × DPR
void main() {
  group('pickThumbnailSize', () {
    test('DPR 1.0 窄卡片走 small（≤180）', () {
      expect(pickThumbnailSize(120, 1.0), ThumbnailSize.small);
      expect(pickThumbnailSize(180, 1.0), ThumbnailSize.small);
    });

    test('DPR 1.0 中卡片走 medium（≤360）', () {
      expect(pickThumbnailSize(181, 1.0), ThumbnailSize.medium);
      expect(pickThumbnailSize(260, 1.0), ThumbnailSize.medium);
      expect(pickThumbnailSize(360, 1.0), ThumbnailSize.medium);
    });

    test('DPR 1.0 大卡片走 large', () {
      expect(pickThumbnailSize(361, 1.0), ThumbnailSize.large);
      expect(pickThumbnailSize(480, 1.0), ThumbnailSize.large);
    });

    test('高 DPR 放大物理需求，自动升档', () {
      // 180 逻辑宽 × 1.25 = 225 物理像素 → medium
      expect(pickThumbnailSize(180, 1.25), ThumbnailSize.medium);
      // 260 逻辑宽 × 2.0 = 520 物理像素 → large
      expect(pickThumbnailSize(260, 2.0), ThumbnailSize.large);
      // 260 逻辑宽 × 1.25 = 325 物理像素 → medium（provider 预取默认口径）
      expect(pickThumbnailSize(260, 1.25), ThumbnailSize.medium);
    });

    test('边界值取包含侧（≤ 即同档）', () {
      expect(pickThumbnailSize(180, 1.0), ThumbnailSize.small);
      expect(pickThumbnailSize(360, 1.0), ThumbnailSize.medium);
      expect(pickThumbnailSize(180.01, 1.0), ThumbnailSize.medium);
      expect(pickThumbnailSize(360.01, 1.0), ThumbnailSize.large);
    });
  });
}
