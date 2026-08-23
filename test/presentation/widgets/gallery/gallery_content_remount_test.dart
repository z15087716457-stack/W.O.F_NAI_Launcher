import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/presentation/widgets/gallery/gallery_content_view.dart';

/// galleryNeedsRemount 纯函数测试：同页/同过滤下条目数变化=需要重挂。
void main() {
  group('galleryNeedsRemount', () {
    test('同页同过滤条目减少（删除）→ 重挂', () {
      expect(
        galleryNeedsRemount(
          oldLength: 50,
          newLength: 49,
          samePage: true,
          sameFilters: true,
        ),
        isTrue,
      );
    });

    test('同页同过滤条目增加（恢复）→ 重挂', () {
      expect(
        galleryNeedsRemount(
          oldLength: 49,
          newLength: 50,
          samePage: true,
          sameFilters: true,
        ),
        isTrue,
      );
    });

    test('翻页（页码变化）→ 不重挂（新数据集，保持滚动行为）', () {
      expect(
        galleryNeedsRemount(
          oldLength: 50,
          newLength: 50,
          samePage: false,
          sameFilters: true,
        ),
        isFalse,
      );
    });

    test('切换过滤条件 → 不重挂', () {
      expect(
        galleryNeedsRemount(
          oldLength: 50,
          newLength: 30,
          samePage: true,
          sameFilters: false,
        ),
        isFalse,
      );
    });

    test('同页同过滤条目数不变（仅元数据刷新）→ 不重挂', () {
      expect(
        galleryNeedsRemount(
          oldLength: 50,
          newLength: 50,
          samePage: true,
          sameFilters: true,
        ),
        isFalse,
      );
    });
  });
}
