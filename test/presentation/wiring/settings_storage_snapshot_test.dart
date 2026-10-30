import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_storage_snapshot.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('storage-snapshot-');
    Hive.init(root.path);
    await Hive.openBox(StorageKeys.settingsBox);
  });
  tearDown(() async {
    await Hive.close();
    await root.delete(recursive: true);
  });

  test(
    'successful summary is restored across restart only for matching directories',
    () async {
      final at = DateTime(2026, 10, 30, 8);
      final data = SettingsStorageData(
        measuredAt: at,
        imageCount: 20,
        thumbnailBytes: 100,
        thumbnailCount: 15,
        slices: const [
          SettingsStorageSlice(
            SettingsStorageKind.images,
            2000,
            paths: ['E:/images'],
          ),
          SettingsStorageSlice(SettingsStorageKind.thumbnails, 100),
        ],
        roots: const [
          SettingsGalleryRoot(
            id: 'E:/images',
            path: 'E:/images',
            images: 20,
            primary: true,
          ),
        ],
      );
      await SettingsStorageSnapshotStore().save('original', data);
      await Hive.close();
      await Hive.openBox(StorageKeys.settingsBox);
      final restored = SettingsStorageSnapshotStore().read('original')!;
      expect(restored.totalBytes, 2100);
      expect(restored.thumbnailBytes, 100);
      expect(restored.thumbnailCount, 15);
      expect(restored.roots.single.images, 20);
      expect(restored.measuredAt, at);
      expect(restored.configurationKey, 'original');
      expect(SettingsStorageSnapshotStore().read('changed-roots'), isNull);
    },
  );
  test('damaged snapshot is ignored without clearing settings', () async {
    final box = Hive.box(StorageKeys.settingsBox);
    await box.put(SettingsStorageSnapshotStore.key, '{broken');
    expect(SettingsStorageSnapshotStore().read('original'), isNull);
    await box.put(
      SettingsStorageSnapshotStore.key,
      '{"signature":"original","slices":42}',
    );
    expect(SettingsStorageSnapshotStore().read('original'), isNull);
    expect(box.containsKey(SettingsStorageSnapshotStore.key), isTrue);
  });
}
