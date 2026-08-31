import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GallerySortStore', () {
    test('returns null by default when no record exists', () async {
      SharedPreferences.setMockInitialValues({});
      const store = GallerySortStore();

      expect(await store.load(), isNull);
    });

    test('persists and reloads field + direction', () async {
      SharedPreferences.setMockInitialValues({});
      const store = GallerySortStore();

      await store.save(
        const GallerySort(
          field: GallerySortField.imageDimensions,
          direction: GallerySortDirection.ascending,
        ),
      );

      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!.field, GallerySortField.imageDimensions);
      expect(loaded.direction, GallerySortDirection.ascending);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(StorageKeys.localGallerySortField),
        'imageDimensions',
      );
      expect(
        prefs.getString(StorageKeys.localGallerySortDirection),
        'ascending',
      );
    });

    test('stored values win over default', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.localGallerySortField: 'fileSize',
        StorageKeys.localGallerySortDirection: 'descending',
      });
      const store = GallerySortStore();

      final loaded = await store.load();
      expect(loaded!.field, GallerySortField.fileSize);
      expect(loaded.direction, GallerySortDirection.descending);
    });

    test(
      'invalid enum names fall back to null (caller uses default)',
      () async {
        SharedPreferences.setMockInitialValues({
          StorageKeys.localGallerySortField: 'not_a_field',
          StorageKeys.localGallerySortDirection: 'descending',
        });
        const store = GallerySortStore();

        expect(await store.load(), isNull);
      },
    );

    test('missing direction falls back to null', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.localGallerySortField: 'fileName',
      });
      const store = GallerySortStore();

      expect(await store.load(), isNull);
    });
  });
}
