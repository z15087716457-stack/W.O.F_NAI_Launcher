import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_inventory.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.root);
  final String root;
  @override
  Future<String?> getApplicationSupportPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('settings_storage_fix_');
    final original = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(temp.path);
    addTearDown(() => PathProviderPlatform.instance = original);
  });
  tearDown(() async => temp.delete(recursive: true));

  test(
    'production isolate completes, shares a pending read and can refresh',
    () async {
      await File(p.join(temp.path, 'a.png')).writeAsBytes([1, 2, 3]);
      await File(p.join(temp.path, 'ignored.txt')).writeAsString('ignored');
      await Directory(p.join(temp.path, '.thumbs')).create();
      await File(p.join(temp.path, '.thumbs', 'a.webp')).writeAsBytes([4, 5]);
      final worker = SettingsDirectoryMeasurements();
      final first = worker.measure(temp.path, gallery: true);
      expect(
        identical(first, worker.measure(p.join(temp.path, '.'), gallery: true)),
        isTrue,
      );
      expect(await first.timeout(const Duration(seconds: 5)), (
        bytes: 3,
        thumbs: 2,
        images: 1,
      ));
      await File(p.join(temp.path, 'b.jpg')).writeAsBytes([6]);
      expect(
        await worker
            .measure(temp.path, gallery: true)
            .timeout(const Duration(seconds: 5)),
        (bytes: 4, thumbs: 2, images: 2),
      );
    },
  );

  test(
    'queue stays serial and a failed traversal does not block later jobs',
    () async {
      final blocked = Completer<SettingsDirectoryMeasurement>();
      final started = <String>[];
      final worker = SettingsDirectoryMeasurements(
        measure: (path, gallery) async {
          started.add(p.basename(path));
          if (p.basename(path) == 'first') return blocked.future;
          return (bytes: 9, thumbs: 0, images: 0);
        },
      );
      final first = worker.measure(p.join(temp.path, 'first'));
      final failed = expectLater(first, throwsStateError);
      final next = worker.measure(p.join(temp.path, 'next'));
      await Future<void>.delayed(Duration.zero);
      expect(started, ['first']);
      blocked.completeError(StateError('fixture failure'));
      await failed;
      expect((await next.timeout(const Duration(seconds: 1))).bytes, 9);
      expect(started, ['first', 'next']);
      expect((await worker.measure(p.join(temp.path, 'next'))).bytes, 9);
      expect(started, ['first', 'next', 'next']);
    },
  );

  test(
    'source rows and limits resolve while measurement is still blocked',
    () async {
      final blocked = Completer<SettingsDirectoryMeasurement>();
      final container = ProviderContainer(
        overrides: [
          settingsFoldersProvider.overrideWith(
            (ref) async => {
              for (final folder in SettingsFolder.values)
                folder: p.join(temp.path, folder.name),
            },
          ),
          settingsGalleryExtraRootsProvider.overrideWith(
            (ref) async => [p.join(temp.path, 'extra')],
          ),
          ragDirectoryProvider.overrideWithValue(
            () async => Directory(p.join(temp.path, 'rag')),
          ),
          settingsDiskFreeProvider.overrideWithValue((_) async => 456),
          settingsMeasurementsProvider.overrideWithValue(
            SettingsDirectoryMeasurements(measure: (_, __) => blocked.future),
          ),
        ],
      );
      addTearDown(container.dispose);
      final pending = container.read(settingsStorageDataProvider.future);
      final locations = await container
          .read(settingsStorageLocationsProvider.future)
          .timeout(const Duration(seconds: 1));
      expect(locations.roots.map((r) => r.primary), [true, false]);
      expect(locations.roots.last.path, p.join(temp.path, 'extra'));
      expect(locations.thumbnailLimit, greaterThan(0));
      expect(locations.folderNames[SettingsFolder.images], 'images');
      expect(container.read(settingsStorageDataProvider).isLoading, isTrue);
      blocked.complete((bytes: 3, thumbs: 2, images: 1));
      final measured = await pending.timeout(const Duration(seconds: 2));
      expect(measured.roots, hasLength(2));
      expect(measured.imageCount, 2);
      expect(measured.diskFree, 456);
    },
  );

  test(
    'nested and duplicate sources do not count image or thumbnail bytes twice',
    () async {
      final images = Directory(p.join(temp.path, 'images'))..createSync();
      final nested = Directory(p.join(images.path, 'child'))..createSync();
      File(p.join(images.path, 'a.png')).writeAsBytesSync([1, 2, 3]);
      File(p.join(nested.path, 'b.jpg')).writeAsBytesSync([4, 5]);
      Directory(p.join(nested.path, '.thumbs')).createSync();
      File(p.join(nested.path, '.thumbs', 'b.webp')).writeAsBytesSync([6]);
      final container = ProviderContainer(
        overrides: [
          settingsFoldersProvider.overrideWith(
            (ref) async => {
              for (final folder in SettingsFolder.values)
                folder: p.join(temp.path, folder.name),
            },
          ),
          settingsGalleryExtraRootsProvider.overrideWith(
            (ref) async => [nested.path, images.path],
          ),
          ragDirectoryProvider.overrideWithValue(
            () async => Directory(p.join(temp.path, 'rag')),
          ),
          settingsDiskFreeProvider.overrideWithValue((_) async => null),
        ],
      );
      addTearDown(container.dispose);
      final result = await container
          .read(settingsStorageDataProvider.future)
          .timeout(const Duration(seconds: 5));
      expect(result.imageCount, 2);
      expect(
        result.slices
            .firstWhere((s) => s.kind == SettingsStorageKind.images)
            .bytes,
        5,
      );
      expect(result.thumbnailBytes, 1);
      expect(result.roots.map((r) => r.images), [2, 1, 2]);
    },
  );
}
