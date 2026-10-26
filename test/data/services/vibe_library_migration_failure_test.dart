import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
// Fault injection stays in the test; production uses the public Hive API.
// ignore: implementation_imports
import 'package:hive/src/backend/vm/storage_backend_vm.dart';
// ignore: implementation_imports
import 'package:hive/src/box/box_base_impl.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/utils/hive_storage_helper.dart';
import 'package:nai_launcher/core/utils/vibe_library_path_helper.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/services/vibe_library_migration_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../helpers/app_logger_test_isolation.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.root);
  final String root;
  @override
  Future<String?> getApplicationSupportPath() async => p.join(root, 'support');
  @override
  Future<String?> getApplicationDocumentsPath() async => p.join(root, 'docs');
}

class _FailingAdapter extends VibeLibraryEntryAdapter {
  @override
  void write(BinaryWriter writer, VibeLibraryEntry obj) =>
      throw StateError('injected entry serialization failure');
}

class _FailOnceWrite implements RandomAccessFile {
  _FailOnceWrite(this.real);
  final RandomAccessFile real;
  var failed = false;
  @override
  Future<RandomAccessFile> writeFrom(
    List<int> buffer, [
    int start = 0,
    int? end,
  ]) async {
    if (!failed) {
      failed = true;
      throw FileSystemException(
        'injected settings completion write failure',
        real.path,
      );
    }
    return real.writeFrom(buffer, start, end);
  }

  @override
  Future<RandomAccessFile> setPosition(int position) =>
      real.setPosition(position);
  @override
  Future<void> close() => real.close();
  @override
  Future<RandomAccessFile> flush() => real.flush();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory temp;
  late Directory vibes;
  late PathProviderPlatform previousPaths;
  late Box<dynamic> settings;
  const boxName = 'vibe_library_entries';
  const versionKey = 'vibe_library_schema_version';
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('vibe_migration_failure_');
    previousPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(temp.path);
    HiveStorageHelper.instance.clearCache();
    final hivePath = await HiveStorageHelper.instance.getPath();
    await Directory(hivePath).create(recursive: true);
    Hive.init(hivePath);
    settings = await Hive.openBox(StorageKeys.settingsBox);
    await settings.put(versionKey, 20);
    vibes = await Directory(p.join(temp.path, 'vibes')).create();
    await VibeLibraryPathHelper.instance.setPath(vibes.path);
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(LegacyVibeLibraryEntryV20Adapter());
    }
    Hive.registerAdapter(VibeLibraryEntryAdapter(), override: true);
    final legacy = await Hive.openBox<LegacyVibeLibraryEntryV20>(boxName);
    await legacy.put(
      'fixture',
      LegacyVibeLibraryEntryV20(
        id: 'fixture',
        name: 'fixture',
        vibeDisplayName: 'fixture',
        vibeEncoding: 'Zml4dHVyZQ==',
        vibeThumbnail: null,
        rawImageData: null,
        strength: 0.6,
        infoExtracted: 0.7,
        sourceTypeIndex: VibeSourceType.naiv4vibe.index,
        categoryId: 'personal category',
        tags: ['personal tag'],
        isFavorite: true,
        usedCount: 7,
        lastUsedAt: null,
        createdAt: DateTime(2026, 1, 1),
        thumbnail: null,
      ),
    );
    await legacy.close();
  });
  tearDown(() async {
    await VibeLibraryPathHelper.instance.resetToDefault();
    await Hive.close();
    Hive.registerAdapter(VibeLibraryEntryAdapter(), override: true);
    HiveStorageHelper.instance.clearCache();
    PathProviderPlatform.instance = previousPaths;
    await temp.delete(recursive: true);
  });
  Future<void> expectLegacyRestored() async {
    expect(Hive.isBoxOpen(boxName), isFalse);
    final restored = await Hive.openBox<LegacyVibeLibraryEntryV20>(boxName);
    try {
      expect(restored.length, 1);
      final value = restored.get('fixture')!;
      expect(value.isFavorite, isTrue);
      expect(value.tags, ['personal tag']);
      expect(value.categoryId, 'personal category');
      expect(value.usedCount, 7);
    } finally {
      await restored.close();
    }
    expect(settings.get(versionKey), 20);
  }

  Future<void> expectRetrySucceeds() async {
    Hive.registerAdapter(VibeLibraryEntryAdapter(), override: true);
    final result = await VibeLibraryMigrationService().migrateIfNeeded();
    expect(result.success, isTrue);
    expect(result.exportedCount, 1);
    expect(settings.get(versionKey), 23);
    final migrated = await Hive.openBox<VibeLibraryEntry>(boxName);
    try {
      final value = migrated.get('fixture')!;
      expect(value.isFavorite, isTrue);
      expect(value.usedCount, 7);
      expect(await File(value.filePath!).exists(), isTrue);
    } finally {
      await migrated.close();
    }
  }

  test(
    'serialization failure retains old data, releases typed box and supports retry',
    () async {
      Hive.registerAdapter(_FailingAdapter(), override: true);
      final result = await VibeLibraryMigrationService().migrateIfNeeded();
      expect(result.success, isFalse);
      expect(result.error, contains('injected entry serialization failure'));
      expect(result.backupPath, isNotNull);
      await expectLegacyRestored();
      expect(await vibes.list().length, 0);
      await expectRetrySucceeds();
    },
  );
  for (final stage in ['backup', 'export', 'rebuild', 'verify']) {
    test(
      'callback failure after $stage rolls back before a later launch',
      () async {
        final result = await VibeLibraryMigrationService().migrateIfNeeded(
          onProgress: (progress) {
            if (progress.stage == stage && progress.current == progress.total) {
              throw StateError('injected $stage callback failure');
            }
          },
        );
        expect(result.success, isFalse);
        expect(result.error, contains('injected $stage callback failure'));
        expect(result.backupPath, isNotNull);
        await expectLegacyRestored();
        expect(await vibes.list().length, 0);
        await expectRetrySucceeds();
      },
    );
  }
  test(
    'completion-marker disk failure restores the source and permits retry',
    () async {
      // The test replaces only the real settings writer at the commit boundary.
      // ignore: invalid_use_of_protected_member
      final backend = (settings as BoxBaseImpl).backend as StorageBackendVm;
      final result = await VibeLibraryMigrationService().migrateIfNeeded(
        onProgress: (progress) {
          if (progress.stage == 'verify') {
            backend.writeRaf = _FailOnceWrite(backend.writeRaf);
          }
        },
      );
      expect(result.success, isFalse);
      expect(
        result.error,
        contains('injected settings completion write failure'),
      );
      await expectLegacyRestored();
      expect(await vibes.list().length, 0);
      await expectRetrySucceeds();
    },
  );
  test(
    'incomplete backup cannot delete exported files or mark migration complete',
    () async {
      final result = await VibeLibraryMigrationService().migrateIfNeeded(
        onProgress: (progress) {
          if (progress.stage == 'rebuild' && progress.current == 1) {
            final backup =
                settings.get('vibe_library_migration_backup_dir') as String;
            File(p.join(backup, '$boxName.hive')).deleteSync();
            throw StateError('injected missing rollback backup');
          }
        },
      );
      expect(result.success, isFalse);
      expect(result.error, contains('injected missing rollback backup'));
      expect(result.error, contains('rollback'));
      expect(result.backupPath, isNotNull);
      expect(settings.get(versionKey), 20);
      expect(await vibes.list().length, 1);
      final retained = await Hive.openBox<VibeLibraryEntry>(boxName);
      try {
        expect(await File(retained.get('fixture')!.filePath!).exists(), isTrue);
      } finally {
        await retained.close();
      }
      final retry = await VibeLibraryMigrationService().migrateIfNeeded();
      expect(retry.success, isFalse);
      expect(settings.get(versionKey), 20);
      expect(await vibes.list().length, 1);
    },
  );
}
