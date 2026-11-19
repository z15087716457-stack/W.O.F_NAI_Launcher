import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_inventory.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_storage_measurement.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_storage_snapshot.dart';

class _CachedStorage extends SettingsStorageSnapshotStore {
  _CachedStorage(this.data);
  SettingsStorageData data;
  @override
  SettingsStorageData? read(String signature) => data;
  @override
  Future<void> save(String signature, SettingsStorageData data) async =>
      this.data = data;
}

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
    'unused managed folders are empty but a missing custom library is unavailable',
    () async {
      final images = await Directory(p.join(temp.path, 'images')).create();
      final saved = _CachedStorage(const SettingsStorageData());
      var vibePath = p.join(temp.path, 'vibes');
      final container = ProviderContainer(
        overrides: [
          settingsFoldersProvider.overrideWith(
            (_) async => {
              for (final folder in SettingsFolder.values)
                folder: switch (folder) {
                  SettingsFolder.images => images.path,
                  SettingsFolder.vibes => vibePath,
                  SettingsFolder.preciseRefs => p.join(
                    temp.path,
                    'precise_refs',
                  ),
                  _ => p.join(temp.path, folder.name),
                },
            },
          ),
          settingsGallerySourcesProvider.overrideWith(
            (_) async => [images.path],
          ),
          ragDirectoryProvider.overrideWithValue(
            () async => Directory(p.join(temp.path, 'rag')),
          ),
          settingsDiskFreeProvider.overrideWithValue((_) async => null),
          settingsStorageSnapshotStoreProvider.overrideWithValue(saved),
        ],
      );
      addTearDown(container.dispose);
      final fresh = await container.read(settingsStorageDataProvider.future);
      expect(fresh.incomplete, isFalse);
      expect(saved.data.measuredAt, isNotNull);
      expect(fresh.totalBytes, 0);
      vibePath = p.join(temp.path, 'detached-library');
      container.invalidate(settingsFoldersProvider);
      final offline = await container.read(settingsStorageDataProvider.future);
      expect(
        offline.slices
            .firstWhere((s) => s.kind == SettingsStorageKind.vibes)
            .incomplete,
        isTrue,
      );
      expect(offline.incomplete, isTrue);
    },
  );

  test('PR originals inside a gallery root count once as PR assets', () async {
    final images = await Directory(p.join(temp.path, 'pictures')).create();
    final precise = await Directory(p.join(images.path, 'pr')).create();
    final media = await Directory(
      p.join(temp.path, 'draft-backups', 'media'),
    ).create(recursive: true);
    await File(p.join(media.path, 'digest')).writeAsBytes([1, 2, 3]);
    await File(p.join(media.parent.path, 'snapshot.json')).writeAsBytes([4, 5]);
    await File(p.join(images.path, 'generated.png')).writeAsBytes([1, 2, 3]);
    await File(
      p.join(precise.path, 'reference.png'),
    ).writeAsBytes([4, 5, 6, 7]);
    await File(p.join(precise.path, 'readme.txt')).writeAsBytes([8, 9]);
    final container = ProviderContainer(
      overrides: [
        settingsFoldersProvider.overrideWith(
          (ref) async => {
            for (final folder in SettingsFolder.values)
              folder: folder == SettingsFolder.images
                  ? images.path
                  : folder == SettingsFolder.preciseRefs
                  ? precise.path
                  : p.join(temp.path, folder.name),
          },
        ),
        settingsGallerySourcesProvider.overrideWith(
          (ref) async => [images.path],
        ),
        ragDirectoryProvider.overrideWithValue(
          () async => Directory(p.join(temp.path, 'rag')),
        ),
        settingsDiskFreeProvider.overrideWithValue((_) async => null),
      ],
    );
    addTearDown(container.dispose);
    final result = await container.read(settingsStorageDataProvider.future);
    int bytes(SettingsStorageKind kind) =>
        result.slices.firstWhere((s) => s.kind == kind).bytes;
    expect(bytes(SettingsStorageKind.preciseRefs), 4);
    expect(bytes(SettingsStorageKind.images), 3);
    expect(bytes(SettingsStorageKind.other), 2);
    expect(bytes(SettingsStorageKind.draftBackups), 5);
    expect(result.totalBytes, 14);
  });

  test(
    'cached totals resolve before traversal and survive a failed silent refresh',
    () async {
      final blocked = Completer<SettingsDirectoryMeasurement>();
      final started = Completer<void>();
      final cached = _CachedStorage(
        SettingsStorageData(
          measuredAt: DateTime(2026, 10, 29),
          slices: const [
            SettingsStorageSlice(SettingsStorageKind.images, 500),
            SettingsStorageSlice(SettingsStorageKind.thumbnails, 30),
          ],
          thumbnailBytes: 30,
          thumbnailCount: 3,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          settingsFoldersProvider.overrideWith(
            (ref) async => {
              for (final folder in SettingsFolder.values)
                folder: p.join(temp.path, folder.name),
            },
          ),
          settingsGallerySourcesProvider.overrideWith((ref) async => []),
          ragDirectoryProvider.overrideWithValue(
            () async => Directory(p.join(temp.path, 'rag')),
          ),
          settingsStorageSnapshotStoreProvider.overrideWithValue(cached),
          settingsMeasurementsProvider.overrideWithValue(
            SettingsDirectoryMeasurements(
              measure: (_, __) {
                if (!started.isCompleted) started.complete();
                return blocked.future;
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final pending = container.read(settingsStorageDataProvider.future);
      final old = await container
          .read(settingsStorageCachedProvider.future)
          .timeout(const Duration(seconds: 1));
      expect(old!.totalBytes, 530);
      expect(old.thumbnailBytes, 30);
      expect(container.read(settingsStorageDataProvider).isLoading, isTrue);
      expect(container.read(settingsStorageManualRefreshProvider), isFalse);
      await started.future;
      final failed = expectLater(pending, throwsStateError);
      blocked.completeError(StateError('fixture read failure'));
      await failed;
      expect(
        container.read(settingsStorageCachedProvider).requireValue!.totalBytes,
        530,
      );
      expect(cached.data.thumbnailBytes, 30);
    },
  );

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
      final measured = await first.timeout(const Duration(seconds: 5));
      expect(measured.bytes, 3);
      expect(measured.thumbs, 2);
      expect(measured.images, 1);
      expect(measured.other, 7);
      expect(measured.incomplete, isFalse);
      await File(p.join(temp.path, 'b.jpg')).writeAsBytes([6]);
      final refreshed = await worker
          .measure(temp.path, gallery: true)
          .timeout(const Duration(seconds: 5));
      expect(refreshed.bytes, 4);
      expect(refreshed.thumbs, 2);
      expect(refreshed.images, 2);
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
          return const SettingsDirectoryMeasurement(bytes: 9);
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
          settingsGallerySourcesProvider.overrideWith(
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
      expect(locations.roots.map((r) => r.path), [p.join(temp.path, 'extra')]);
      expect(locations.roots.last.path, p.join(temp.path, 'extra'));
      expect(locations.thumbnailLimit, 20 * 1024 * 1024 * 1024);
      expect(locations.folderNames[SettingsFolder.images], 'images');
      expect(container.read(settingsStorageDataProvider).isLoading, isTrue);
      blocked.complete(
        const SettingsDirectoryMeasurement(bytes: 3, thumbs: 2, images: 1),
      );
      final measured = await pending.timeout(const Duration(seconds: 2));
      expect(measured.roots.map((r) => r.path), [p.join(temp.path, 'extra')]);
      expect(measured.imageCount, 0);
      expect(measured.diskFree, 456);
    },
  );

  test(
    'Vibe is shallow, unrelated files are separate and overlaps are counted once',
    () async {
      final images = Directory(p.join(temp.path, 'images'))..createSync();
      final vibes = Directory(p.join(images.path, 'vibes'))..createSync();
      final child = Directory(p.join(vibes.path, 'child'))..createSync();
      File(p.join(images.path, 'a.png')).writeAsBytesSync(List.filled(3, 1));
      File(
        p.join(images.path, 'notes.txt'),
      ).writeAsBytesSync(List.filled(11, 1));
      File(
        p.join(vibes.path, 'a.naiv4vibe'),
      ).writeAsBytesSync(List.filled(7, 1));
      File(
        p.join(vibes.path, 'b.NAIV4VIBEBUNDLE'),
      ).writeAsBytesSync(List.filled(13, 1));
      File(
        p.join(vibes.path, 'unrelated.bin'),
      ).writeAsBytesSync(List.filled(1000, 1));
      File(
        p.join(child.path, 'nested.naiv4vibe'),
      ).writeAsBytesSync(List.filled(17, 1));
      File(
        p.join(vibes.path, 'preview.jpg'),
      ).writeAsBytesSync(List.filled(5, 1));
      final container = ProviderContainer(
        overrides: [
          settingsFoldersProvider.overrideWith(
            (ref) async => {
              for (final folder in SettingsFolder.values)
                folder: folder == SettingsFolder.vibes
                    ? vibes.path
                    : p.join(temp.path, folder.name),
            },
          ),
          settingsGallerySourcesProvider.overrideWith(
            (ref) async => [vibes.path, images.path],
          ),
          ragDirectoryProvider.overrideWithValue(
            () async => Directory(p.join(temp.path, 'rag')),
          ),
          settingsDiskFreeProvider.overrideWithValue((_) async => null),
        ],
      );
      addTearDown(container.dispose);
      final result = await container.read(settingsStorageDataProvider.future);
      int bytes(SettingsStorageKind kind) =>
          result.slices.firstWhere((s) => s.kind == kind).bytes;
      expect(bytes(SettingsStorageKind.vibes), 20);
      expect(bytes(SettingsStorageKind.images), 3);
      expect(bytes(SettingsStorageKind.other), 1033);
      expect(result.totalBytes, 1056);
      expect(
        result.slices
            .firstWhere((s) => s.kind == SettingsStorageKind.other)
            .paths,
        containsAll([images.path, vibes.path]),
      );
    },
  );

  test(
    'missing or non-directory traversal marks incomplete rather than successful zero',
    () async {
      final missing = settingsMeasureDirectory(p.join(temp.path, 'missing'));
      expect(missing.bytes, 0);
      expect(missing.incomplete, isTrue);
      final file = File(p.join(temp.path, 'not-a-directory'))
        ..writeAsStringSync('x');
      expect(settingsMeasureDirectory(file.path).incomplete, isTrue);
    },
  );

  test(
    'same directory image/Vibe/Agent roots and failed reads retain unique totals',
    () async {
      File(p.join(temp.path, 'image.jpg')).writeAsBytesSync(List.filled(3, 1));
      File(
        p.join(temp.path, 'asset.naiv4vibe'),
      ).writeAsBytesSync(List.filled(5, 1));
      File(p.join(temp.path, 'notes.txt')).writeAsBytesSync(List.filled(7, 1));
      final worker = SettingsDirectoryMeasurements();
      final gallery = await worker.measure(temp.path, gallery: true);
      final plain = await worker.measure(temp.path);
      final failedPath = p.join(temp.path, 'absent');
      final failed = await worker.measure(failedPath);
      final slices = settingsClassifyStorage(
        galleries: {temp.path: gallery},
        categories: {
          SettingsStorageKind.vibes: {temp.path: plain, failedPath: failed},
          SettingsStorageKind.agent: {temp.path: plain},
        },
      );
      expect(slices.fold<int>(0, (sum, s) => sum + s.bytes), 15);
      expect(
        slices.firstWhere((s) => s.kind == SettingsStorageKind.vibes).bytes,
        5,
      );
      expect(
        slices.firstWhere((s) => s.kind == SettingsStorageKind.images).bytes,
        0,
      );
      expect(
        slices.firstWhere((s) => s.kind == SettingsStorageKind.agent).bytes,
        0,
      );
      expect(
        slices
            .firstWhere((s) => s.kind == SettingsStorageKind.vibes)
            .incomplete,
        isTrue,
      );
      expect(
        slices
            .firstWhere((s) => s.kind == SettingsStorageKind.other)
            .incomplete,
        isTrue,
      );
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
          settingsGallerySourcesProvider.overrideWith(
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
      expect(result.roots.map((r) => r.images), [1, 2]);
    },
  );
}
