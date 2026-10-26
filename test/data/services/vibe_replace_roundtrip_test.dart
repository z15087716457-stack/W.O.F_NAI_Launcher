import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/utils/vibe_library_path_helper.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/services/vibe_import_service.dart';
import 'package:nai_launcher/data/services/vibe_library_import_repository_impl.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/app_logger_test_isolation.dart';

class _FailingAdapter extends VibeLibraryEntryAdapter {
  @override
  void write(BinaryWriter writer, VibeLibraryEntry obj) =>
      throw StateError('injected replacement index write failure');
}

class _WriteFailureFile implements File {
  _WriteFailureFile(this.path);
  @override
  final String path;
  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async => throw FileSystemException(
    'injected replacement file write failure',
    path,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _WriteFailure extends IOOverrides {
  @override
  File createFile(String path) =>
      path.contains('.vibe-replace-') && p.basename(path) == 'replacement.tmp'
      ? _WriteFailureFile(path)
      : super.createFile(path);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory temp;
  late Directory directory;
  late VibeLibraryStorageService storage;
  late VibeImportService importer;
  const oldVibe = VibeReference(
    displayName: 'fixture',
    vibeEncoding: 'b2xk',
    sourceType: VibeSourceType.naiv4vibe,
  );
  const newVibe = VibeReference(
    displayName: 'fixture',
    vibeEncoding: 'bmV3',
    sourceType: VibeSourceType.naiv4vibe,
  );
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('vibe_replace_');
    Hive.init(p.join(temp.path, 'hive'));
    SharedPreferences.setMockInitialValues({});
    await Hive.openBox(StorageKeys.settingsBox);
    directory = await Directory(p.join(temp.path, 'vibes')).create();
    await VibeLibraryPathHelper.instance.setPath(directory.path);
    storage = VibeLibraryStorageService();
    importer = VibeImportService(
      repository: VibeLibraryStorageImportRepository(storage),
    );
  });
  tearDown(() async {
    await storage.close();
    Hive.registerAdapter(VibeLibraryEntryAdapter(), override: true);
    await VibeLibraryPathHelper.instance.resetToDefault();
    await Hive.close();
    await temp.delete(recursive: true);
  });
  Future<VibeLibraryEntry> seed(bool bundle) async {
    final entry = bundle
        ? await storage.saveBundleEntry([
            oldVibe,
            oldVibe.copyWith(displayName: 'old child'),
          ], name: 'fixture')
        : await storage.saveEntry(
            VibeLibraryEntry.fromVibeReference(
              name: 'fixture',
              vibeData: oldVibe,
            ),
          );
    final marked = entry.copyWith(isFavorite: true, usedCount: 7);
    await storage.saveEntry(marked);
    return marked;
  }

  Future<VibeImportResult> replace(bool bundle) => importer.importPrepared(
    name: 'fixture',
    references: [
      newVibe,
      if (bundle) newVibe.copyWith(displayName: 'new child'),
    ],
    bundle: bundle,
    conflictResolution: ConflictResolution.replace,
  );
  for (final oldBundle in [false, true]) {
    for (final newBundle in [false, true]) {
      test(
        'replacement survives rescan: bundle=$oldBundle to bundle=$newBundle',
        () async {
          final old = await seed(oldBundle);
          final result = await replace(newBundle);
          expect(result.successCount, 1);
          final saved = result.importedEntries.single;
          expect(saved.id, old.id);
          expect(saved.name, 'fixture');
          expect(saved.isBundle, newBundle);
          expect(saved.isFavorite, isTrue);
          expect(saved.usedCount, 7);
          expect(p.basenameWithoutExtension(saved.filePath!), 'fixture');
          expect(
            p.extension(saved.filePath!),
            newBundle ? '.naiv4vibebundle' : '.naiv4vibe',
          );
          final sync = await storage.syncWithFileSystem();
          expect(sync.failedCount, 0);
          final current = (await storage.getAllEntries()).single;
          expect(current.id, old.id);
          expect(current.name, 'fixture');
          expect(current.vibeEncoding, 'bmV3');
          expect(current.isBundle, newBundle);
          if (newBundle) {
            expect(current.bundledVibeNames, ['fixture', 'new child']);
          }
          expect(await directory.list().length, 1);
        },
      );
    }
  }
  for (final newBundle in [false, true]) {
    test(
      'index failure restores old file and record, newBundle=$newBundle',
      () async {
        final old = await seed(false);
        final bytes = await File(old.filePath!).readAsBytes();
        Hive.registerAdapter(_FailingAdapter(), override: true);
        final result = await replace(newBundle);
        expect(result.successCount, 0);
        expect(result.failCount, 1);
        Hive.registerAdapter(VibeLibraryEntryAdapter(), override: true);
        expect(await File(old.filePath!).readAsBytes(), bytes);
        expect(await directory.list().length, 1);
        final current = (await storage.getAllEntries()).single;
        expect(current.id, old.id);
        expect(current.vibeEncoding, 'b2xk');
        expect(current.isFavorite, isTrue);
      },
    );
  }
  test('type conversion does not overwrite an unrelated target file', () async {
    final old = await seed(false);
    final target = File(p.setExtension(old.filePath!, '.naiv4vibebundle'));
    await target.writeAsString('unrelated fixture');
    final result = await replace(true);
    expect(result.failCount, 1);
    expect(await target.readAsString(), 'unrelated fixture');
    expect((await storage.getEntryRecord(old.id))!.vibeEncoding, 'b2xk');
    expect(await File(old.filePath!).exists(), isTrue);
  });
  test(
    'file-write failure leaves the current native file and record intact',
    () async {
      final old = await seed(false);
      final bytes = await File(old.filePath!).readAsBytes();
      final result = await IOOverrides.runWithIOOverrides(
        () => replace(false),
        _WriteFailure(),
      );
      expect(result.failCount, 1);
      expect(await File(old.filePath!).readAsBytes(), bytes);
      expect((await storage.getEntryRecord(old.id))!.vibeEncoding, 'b2xk');
      expect(await directory.list().length, 1);
    },
  );
  for (final bundle in [false, true]) {
    test(
      'replacement recreates a missing native file, bundle=$bundle',
      () async {
        final old = await seed(false);
        await File(old.filePath!).delete();
        expect((await replace(bundle)).successCount, 1);
        expect((await storage.syncWithFileSystem()).failedCount, 0);
        final current = (await storage.getAllEntries()).single;
        expect(current.id, old.id);
        expect(current.vibeEncoding, 'bmV3');
        expect(current.isBundle, bundle);
        expect(await directory.list().length, 1);
      },
    );
  }
}
