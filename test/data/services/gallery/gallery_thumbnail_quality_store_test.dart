import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/services/gallery/gallery_thumbnail_quality_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GalleryThumbnailQualityStore', () {
    test('defaults to hd when no value exists', () async {
      SharedPreferences.setMockInitialValues({});
      const store = GalleryThumbnailQualityStore();

      expect(await store.load(), GalleryThumbnailQuality.hd);
    });

    test('persists enum names and reloads them', () async {
      SharedPreferences.setMockInitialValues({});
      const store = GalleryThumbnailQualityStore();

      await store.save(GalleryThumbnailQuality.sd);

      expect(await store.load(), GalleryThumbnailQuality.sd);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.localGalleryThumbnailQuality), 'sd');
    });

    test('falls back to hd for an invalid value', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.localGalleryThumbnailQuality: 'invalid',
      });
      const store = GalleryThumbnailQualityStore();

      expect(await store.load(), GalleryThumbnailQuality.hd);
    });
  });
}
