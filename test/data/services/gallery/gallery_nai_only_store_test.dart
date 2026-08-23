import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/services/gallery/gallery_nai_only_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GalleryNaiOnlyStore', () {
    test('loads true (NAI-only) by default when no record exists', () async {
      SharedPreferences.setMockInitialValues({});
      const store = GalleryNaiOnlyStore();

      expect(await store.load(), isTrue);
    });

    test('persists and reloads the saved preference', () async {
      SharedPreferences.setMockInitialValues({});
      const store = GalleryNaiOnlyStore();

      await store.save(false); // 显示全部（含非 NAI 图）
      expect(await store.load(), isFalse);

      await store.save(true);
      expect(await store.load(), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(StorageKeys.localGalleryNaiOnly), isTrue);
    });

    test('stored value wins over default', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.localGalleryNaiOnly: false,
      });
      const store = GalleryNaiOnlyStore();

      expect(await store.load(), isFalse);
    });
  });
}
