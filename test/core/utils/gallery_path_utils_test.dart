import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/gallery_path_utils.dart';

/// 画廊路径工具（P1-17）：尾随分隔符归一 + 前缀匹配语义
void main() {
  group('galleryPathIsWithin', () {
    test('root 以分隔符结尾时同样匹配子路径', () {
      expect(
        galleryPathIsWithin(r'E:\A.I\NovelAI\01_图库\', r'E:\A.I\NovelAI\01_图库\NAI 3\a.png'),
        isTrue,
      );
      expect(
        galleryPathIsWithin(r'E:\A.I\NovelAI\01_图库\', r'E:\A.I\NovelAI\01_图库\NAI 3\'),
        isTrue,
      );
    });

    test('root 无尾随分隔符时匹配子路径（回归）', () {
      expect(
        galleryPathIsWithin(r'E:\A.I\NovelAI\01_图库', r'E:\A.I\NovelAI\01_图库\NAI 3\a.png'),
        isTrue,
      );
    });

    test('路径相等（root 带/不带尾随分隔符）视为包含', () {
      expect(
        galleryPathIsWithin(r'E:\a\b\', r'E:\a\b'),
        isTrue,
      );
      expect(
        galleryPathIsWithin(r'E:\a\b', r'E:\a\b\'),
        isTrue,
      );
    });

    test('前缀相似但不是同目录时不算包含', () {
      expect(
        galleryPathIsWithin(r'E:\a\test_batch', r'E:\a\test_batch_2\x.png'),
        isFalse,
      );
      expect(
        galleryPathIsWithin(r'E:\a\b', r'E:\a\bc\x.png'),
        isFalse,
      );
    });

    test('正斜杠 root 也归一', () {
      expect(
        galleryPathIsWithin('E:/A.I/NovelAI/01_图库/', 'E:/A.I/NovelAI/01_图库/NAI 3/a.png'),
        isTrue,
      );
    });
  });
}
