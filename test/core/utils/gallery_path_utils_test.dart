import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/gallery_path_utils.dart';

/// 画廊路径工具（P1-17）：尾随分隔符归一 + 前缀匹配语义
void main() {
  tearDown(() => debugGalleryPathWindowsRulesOverride = null);

  group('galleryPathIsWithin', () {
    // 下面这组用的是 Windows 路径，按 Windows 规则判断，不看跑测试的机器
    setUp(() => debugGalleryPathWindowsRulesOverride = true);

    test('root 以分隔符结尾时同样匹配子路径', () {
      expect(
        galleryPathIsWithin(
          r'E:\A.I\NovelAI\01_图库\',
          r'E:\A.I\NovelAI\01_图库\NAI 3\a.png',
        ),
        isTrue,
      );
      expect(
        galleryPathIsWithin(
          r'E:\A.I\NovelAI\01_图库\',
          r'E:\A.I\NovelAI\01_图库\NAI 3\',
        ),
        isTrue,
      );
    });

    test('root 无尾随分隔符时匹配子路径（回归）', () {
      expect(
        galleryPathIsWithin(
          r'E:\A.I\NovelAI\01_图库',
          r'E:\A.I\NovelAI\01_图库\NAI 3\a.png',
        ),
        isTrue,
      );
    });

    test('路径相等（root 带/不带尾随分隔符）视为包含', () {
      expect(galleryPathIsWithin(r'E:\a\b\', r'E:\a\b'), isTrue);
      expect(galleryPathIsWithin(r'E:\a\b', r'E:\a\b\'), isTrue);
    });

    test('前缀相似但不是同目录时不算包含', () {
      expect(
        galleryPathIsWithin(r'E:\a\test_batch', r'E:\a\test_batch_2\x.png'),
        isFalse,
      );
      expect(galleryPathIsWithin(r'E:\a\b', r'E:\a\bc\x.png'), isFalse);
    });

    test('正斜杠 root 也归一', () {
      expect(
        galleryPathIsWithin(
          'E:/A.I/NovelAI/01_图库/',
          'E:/A.I/NovelAI/01_图库/NAI 3/a.png',
        ),
        isTrue,
      );
    });
  });

  group('galleryPathIsWithin（macOS 路径）', () {
    setUp(() => debugGalleryPathWindowsRulesOverride = false);

    test('子路径、尾随分隔符、相等都算包含', () {
      expect(
        galleryPathIsWithin('/Users/me/图库', '/Users/me/图库/NAI 3/a.png'),
        isTrue,
      );
      expect(
        galleryPathIsWithin('/Users/me/图库/', '/Users/me/图库/NAI 3/a.png'),
        isTrue,
      );
      expect(galleryPathIsWithin('/Users/me/图库/', '/Users/me/图库'), isTrue);
    });

    test('前缀相似但不是同目录时不算包含', () {
      expect(
        galleryPathIsWithin('/Users/me/图库', '/Users/me/图库_2/a.png'),
        isFalse,
      );
    });
  });

  group('isAbsoluteGalleryPath', () {
    test('Windows：盘符和 UNC 是绝对路径', () {
      debugGalleryPathWindowsRulesOverride = true;
      expect(isAbsoluteGalleryPath(r'E:\GalleryFixtures\01_图库'), isTrue);
      expect(isAbsoluteGalleryPath('E:/GalleryFixtures/01_图库'), isTrue);
      expect(isAbsoluteGalleryPath(r'\\nas\gallery'), isTrue);
      expect(isAbsoluteGalleryPath(r'\\?\E:\GalleryFixtures'), isTrue);
      expect(isAbsoluteGalleryPath(r'NAI 3\sub'), isFalse);
      expect(isAbsoluteGalleryPath('Uncategorized'), isFalse);
    });

    test('macOS：以 / 开头的是绝对路径（外部图库源）', () {
      debugGalleryPathWindowsRulesOverride = false;
      expect(isAbsoluteGalleryPath('/Users/me/Pictures/NAI'), isTrue);
      expect(isAbsoluteGalleryPath('/Volumes/外置盘/图库/'), isTrue);
      expect(isAbsoluteGalleryPath('NAI 3/sub'), isFalse);
      expect(isAbsoluteGalleryPath('Uncategorized'), isFalse);
      // 盘符写法照旧算绝对路径
      expect(isAbsoluteGalleryPath(r'D:\External\Photos'), isTrue);
    });

    test('Windows：以 / 开头的不算（Windows 行为不变）', () {
      debugGalleryPathWindowsRulesOverride = true;
      expect(isAbsoluteGalleryPath('/Users/me/Pictures/NAI'), isFalse);
    });
  });
}
