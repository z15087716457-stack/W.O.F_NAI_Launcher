import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/utils/vibe_library_path_helper.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/services/vibe_file_storage_service.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/app_logger_test_isolation.dart';

class _BrokenListing implements Directory {
  _BrokenListing(this.real, this.partial);
  final Directory real;
  final bool partial;
  @override
  String get path => real.path;
  @override
  Future<bool> exists() => real.exists();
  @override
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) async* {
    if (partial) {
      yield* real.list(recursive: recursive, followLinks: followLinks);
    }
    throw FileSystemException('injected directory enumeration failure', path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ListingFailure extends IOOverrides {
  _ListingFailure(this.path, this.partial);
  final String path;
  final bool partial;
  @override
  Directory createDirectory(String value) {
    final real = super.createDirectory(value);
    return p.equals(value, path) ? _BrokenListing(real, partial) : real;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory temp;
  late Directory directory;
  late VibeLibraryStorageService storage;
  late VibeLibraryEntry entry;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('vibe_sync_failure_');
    Hive.init(p.join(temp.path, 'hive'));
    SharedPreferences.setMockInitialValues({});
    await Hive.openBox(StorageKeys.settingsBox);
    directory = await Directory(p.join(temp.path, 'vibes')).create();
    await VibeLibraryPathHelper.instance.setPath(directory.path);
    final files = VibeFileStorageService();
    storage = VibeLibraryStorageService(fileStorage: files);
    const vibe = VibeReference(
      displayName: 'fixture',
      vibeEncoding: 'Zml4dHVyZQ==',
      sourceType: VibeSourceType.naiv4vibe,
    );
    final path = await files.saveVibeToFile(vibe);
    entry = VibeLibraryEntry.fromVibeReference(
      name: 'fixture',
      vibeData: vibe,
      filePath: path,
      isFavorite: true,
    ).copyWith(categoryId: 'category', tags: ['personal tag'], usedCount: 7);
    await storage.saveEntry(entry);
  });
  tearDown(() async {
    await storage.close();
    await VibeLibraryPathHelper.instance.resetToDefault();
    await Hive.close();
    await temp.delete(recursive: true);
  });
  Future<void> expectPreserved() async {
    final saved = (await storage.getAllEntries()).single;
    expect(saved.id, entry.id);
    expect(saved.isFavorite, isTrue);
    expect(saved.categoryId, 'category');
    expect(saved.tags, ['personal tag']);
    expect(saved.usedCount, 7);
  }

  for (final partial in [false, true]) {
    test(
      'enumeration failure is reported without deleting entries, partial=$partial',
      () async {
        final result = await IOOverrides.runWithIOOverrides(
          () => storage.syncWithFileSystem(),
          _ListingFailure(directory.path, partial),
        );
        expect(result.failedCount, 1);
        expect(result.errors, isNotEmpty);
        expect(result.deletedCount, 0);
        expect(result.upsertedCount, 0);
        await expectPreserved();
        final recovered = await storage.syncWithFileSystem();
        expect(recovered.failedCount, 0);
        await expectPreserved();
      },
    );
  }
  test(
    'temporarily missing root is not recreated and treated as an empty library',
    () async {
      await directory.rename(p.join(temp.path, 'offline'));
      final result = await storage.syncWithFileSystem();
      expect(result.failedCount, 1);
      expect(result.deletedCount, 0);
      expect(await Directory(directory.path).exists(), isFalse);
      await expectPreserved();
    },
  );
  test(
    'switching roots does not delete entries outside the enumerated root',
    () async {
      final other = await Directory(p.join(temp.path, 'other')).create();
      await VibeLibraryPathHelper.instance.setPath(other.path);
      final result = await storage.syncWithFileSystem();
      expect(result.failedCount, 0);
      expect(result.deletedCount, 0);
      await expectPreserved();
    },
  );
  test(
    'complete empty enumeration removes genuinely missing entries in its root',
    () async {
      await File(entry.filePath!).delete();
      final result = await storage.syncWithFileSystem();
      expect(result.failedCount, 0);
      expect(result.deletedCount, 1);
      expect(await storage.getAllEntries(), isEmpty);
      expect(await storage.getDisplayEntries(), isEmpty);
    },
  );
  test('file parse failure keeps existing user attributes', () async {
    await File(entry.filePath!).writeAsString('broken fixture');
    final result = await storage.syncWithFileSystem();
    expect(result.failedCount, 1);
    expect(result.deletedCount, 0);
    await expectPreserved();
  });
}
