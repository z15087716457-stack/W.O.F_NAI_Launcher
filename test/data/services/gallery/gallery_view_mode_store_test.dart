import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/services/gallery/gallery_view_mode_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GalleryViewModeStore', () {
    test('loads true (waterfall) by default when no record exists', () async {
      SharedPreferences.setMockInitialValues({});
      const store = GalleryViewModeStore();

      expect(await store.load(), isTrue);
    });

    test('persists and reloads the saved view mode', () async {
      SharedPreferences.setMockInitialValues({});
      const store = GalleryViewModeStore();

      await store.save(false); // 网格
      expect(await store.load(), isFalse);

      await store.save(true); // 瀑布流
      expect(await store.load(), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool(StorageKeys.localGalleryViewMode),
        isTrue,
      );
    });

    test('stored value wins over default', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.localGalleryViewMode: false,
      });
      const store = GalleryViewModeStore();

      expect(await store.load(), isFalse);
    });
  });
}
