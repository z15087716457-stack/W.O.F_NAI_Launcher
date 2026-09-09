import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/services/gallery/gallery_view_mode.dart';
import 'package:nai_launcher/data/services/gallery/gallery_view_mode_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GalleryViewModeStore', () {
    test('无记录时默认火车流', () async {
      SharedPreferences.setMockInitialValues({});
      const store = GalleryViewModeStore();

      expect(await store.load(), GalleryViewMode.justified);
    });

    test('枚举往返：保存后读回，且只写在新键', () async {
      SharedPreferences.setMockInitialValues({});
      const store = GalleryViewModeStore();

      await store.save(GalleryViewMode.justified); // 火车流
      expect(await store.load(), GalleryViewMode.justified);

      await store.save(GalleryViewMode.grid); // 网格
      expect(await store.load(), GalleryViewMode.grid);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.localGalleryViewModeV2), 'grid');
      // 旧布尔键不再写入
      expect(prefs.getBool(StorageKeys.localGalleryViewMode), isNull);
    });

    test('旧布尔 true 迁移为瀑布流并回写新键', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.localGalleryViewMode: true,
      });
      const store = GalleryViewModeStore();

      expect(await store.load(), GalleryViewMode.masonry);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.localGalleryViewModeV2), 'masonry');
    });

    test('旧布尔 false 迁移为网格并回写新键', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.localGalleryViewMode: false,
      });
      const store = GalleryViewModeStore();

      expect(await store.load(), GalleryViewMode.grid);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.localGalleryViewModeV2), 'grid');
    });

    test('新键优先于旧布尔键', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.localGalleryViewModeV2: 'justified',
        StorageKeys.localGalleryViewMode: false,
      });
      const store = GalleryViewModeStore();

      expect(await store.load(), GalleryViewMode.justified);
    });

    test('新键为未知字符串时落默认火车流', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.localGalleryViewModeV2: 'not_a_mode',
      });
      const store = GalleryViewModeStore();

      expect(await store.load(), GalleryViewMode.justified);
    });

    test('遗留 mosaic 字符串静默迁移为火车流', () async {
      // V2 曾持久化 'mosaic'；V3 删除该视图后枚举反序列化不到，
      // 落默认 justified，不崩不丢档
      SharedPreferences.setMockInitialValues({
        StorageKeys.localGalleryViewModeV2: 'mosaic',
      });
      const store = GalleryViewModeStore();

      expect(await store.load(), GalleryViewMode.justified);
    });
  });
}
