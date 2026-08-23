import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/services/gallery/gallery_column_width_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GalleryColumnWidthStore', () {
    test('loads 260 by default when no record exists', () async {
      SharedPreferences.setMockInitialValues({});
      const store = GalleryColumnWidthStore();

      expect(await store.load(), 260.0);
    });

    test('persists and reloads the saved width', () async {
      SharedPreferences.setMockInitialValues({});
      const store = GalleryColumnWidthStore();

      await store.save(320);
      expect(await store.load(), 320.0);

      await store.save(140); // 最小值
      expect(await store.load(), 140.0);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble(StorageKeys.localGalleryColumnWidth), 140.0);
    });

    test('stored value wins over default', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.localGalleryColumnWidth: 420.0,
      });
      const store = GalleryColumnWidthStore();

      expect(await store.load(), 420.0);
    });

    test('clamps out-of-range values to the valid range', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.localGalleryColumnWidth: 500.0,
      });
      const store = GalleryColumnWidthStore();

      expect(await store.load(), 480.0);
    });

    test('clampColumnWidth snaps to the 20px step', () {
      expect(GalleryColumnWidthStore.clampColumnWidth(145), 140);
      expect(GalleryColumnWidthStore.clampColumnWidth(155), 160);
      expect(GalleryColumnWidthStore.clampColumnWidth(0), 140);
      expect(GalleryColumnWidthStore.clampColumnWidth(10000), 480);
      expect(GalleryColumnWidthStore.clampColumnWidth(260), 260);
    });
  });
}
