import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/gallery_path_utils.dart';
import 'package:nai_launcher/data/models/gallery/gallery_category.dart';

/// 外部图库源：folderPath 是绝对路径就是外部源（只读），按平台的路径规则判断。
void main() {
  tearDown(() => debugGalleryPathWindowsRulesOverride = null);

  GalleryCategory category(String folderPath) =>
      GalleryCategory.create(name: 'c', folderPath: folderPath);

  test('Windows：盘符、UNC 路径是外部源，相对路径是主源', () {
    debugGalleryPathWindowsRulesOverride = true;
    expect(category(r'E:\GalleryFixtures\01_图库').isExternal, isTrue);
    expect(category(r'\\nas\gallery\NAI 3').isExternal, isTrue);
    expect(category(r'NAI 3\sub').isExternal, isFalse);
  });

  test('macOS：/Users、/Volumes 下的文件夹是外部源，相对路径是主源', () {
    debugGalleryPathWindowsRulesOverride = false;
    expect(category('/Users/me/Pictures/图库').isExternal, isTrue);
    expect(category('/Volumes/外置盘/NAI 3').isExternal, isTrue);
    expect(category('NAI 3/sub').isExternal, isFalse);
  });
}
