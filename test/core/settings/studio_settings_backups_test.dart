import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/settings/settings_preferences_service.dart';
import 'package:nai_launcher/core/settings/studio_settings_backups.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';

import 'settings_preferences_service_test.dart' show MemoryStorage;

void main() {
  late Directory root;
  late MemoryStorage storage;
  late ShortcutConfig shortcuts;
  late StudioSettingsBackups backups;
  bool failShortcuts = false;
  setUp(() {
    root = Directory.systemTemp.createTempSync('studio-settings-backups-');
    storage = MemoryStorage();
    shortcuts = ShortcutConfig.createDefault();
    failShortcuts = false;
    backups = StudioSettingsBackups(
      preferences: SettingsPreferencesService(storage),
      directory: Directory('${root.path}/v2'),
      readShortcuts: () => shortcuts,
      writeShortcuts: (value) async {
        if (failShortcuts) {
          failShortcuts = false;
          throw StateError('shortcut failure');
        }
        shortcuts = value;
      },
    );
  });
  tearDown(() async => root.delete(recursive: true));
  StudioSettingsSnapshot change(String mode, [ShortcutConfig? shortcut]) =>
      StudioSettingsSnapshot({StorageKeys.studioThemeMode: mode}, shortcut);

  test(
    'failed undo metadata persistence rolls back the imported settings',
    () async {
      storage.values[StorageKeys.studioThemeMode] = 'dark';
      storage.failKey = 'settings_last_import_v2';
      await expectLater(
        backups.apply(change('light'), expected: backups.capture()),
        throwsStateError,
      );
      expect(storage.values[StorageKeys.studioThemeMode], 'dark');
      expect(await backups.lastImportAt(), isNull);
      expect(await backups.list(), hasLength(1));
    },
  );

  test('v2 round trip and v1 import preserve the public allowlist', () {
    storage.values.addAll({
      'api_key': 'synthetic-secret',
      StorageKeys.imageSavePath: 'private-path',
    });
    final raw = backups.encode(backups.capture());
    expect(raw, isNot(contains('synthetic-secret')));
    expect(raw, isNot(contains('private-path')));
    expect(backups.decode(raw).shortcuts!.toJson(), shortcuts.toJson());
    final v1 = backups.preferences.encode({
      StorageKeys.studioThemeMode: 'system',
    });
    expect(
      backups.decode(v1).preferences[StorageKeys.studioThemeMode],
      'system',
    );
    expect(backups.decode(v1).shortcuts, isNull);
  });
  test(
    'import backs up before writes and undo preserves unrelated later changes',
    () async {
      storage.values[StorageKeys.studioThemeMode] = 'dark';
      final next = shortcuts.copyWith(showInMenus: true);
      await backups.apply(change('light', next), expected: backups.capture());
      expect(storage.values[StorageKeys.studioThemeMode], 'light');
      expect(shortcuts.showInMenus, isTrue);
      final records = await backups.list();
      expect(records.single.reason, 'import');
      expect(
        (await backups.read(
          records.single.id,
        )).preferences[StorageKeys.studioThemeMode],
        'dark',
      );
      expect(await backups.lastImportAt(), isNotNull);
      storage.values[StorageKeys.notificationSoundEnabled] = false;
      await backups.undoImport();
      expect(storage.values[StorageKeys.studioThemeMode], 'dark');
      expect(storage.values[StorageKeys.notificationSoundEnabled], isFalse);
      expect(shortcuts.showInMenus, isFalse);
      expect(await backups.lastImportAt(), isNull);
      await expectLater(backups.undoImport(), throwsStateError);
    },
  );
  test(
    'automatic retention keeps five validated v2 snapshots and legacy files',
    () async {
      final legacy = File('${root.path}/preferences-legacy.json');
      legacy.writeAsStringSync('keep');
      await backups.directory.create();
      final unrelated = File('${backups.directory.path}/manual.json')
        ..writeAsStringSync('keep');
      for (var i = 0; i < 7; i++) {
        await backups.apply(
          change(i.isEven ? 'light' : 'dark'),
          expected: backups.capture(),
          reason: 'reset',
        );
      }
      expect((await backups.list()).length, 5);
      expect(legacy.readAsStringSync(), 'keep');
      expect(unrelated.readAsStringSync(), 'keep');
    },
  );
  test('stale confirmation rejects before a write or snapshot', () async {
    final before = backups.capture();
    storage.values[StorageKeys.studioThemeMode] = 'system';
    expect(await backups.lastImportAt(), isNull);
    await expectLater(
      backups.apply(change('light'), expected: before),
      throwsStateError,
    );
    expect(storage.values[StorageKeys.studioThemeMode], 'system');
    expect(await backups.list(), isEmpty);
  });
  test('stale import undo cannot overwrite a newer edit', () async {
    await backups.apply(change('light'), expected: backups.capture());
    storage.values[StorageKeys.studioThemeMode] = 'system';
    await expectLater(backups.undoImport(), throwsStateError);
    expect(storage.values[StorageKeys.studioThemeMode], 'system');
  });
  test('unknown keys and traversal IDs are refused', () async {
    const bad = StudioSettingsSnapshot({'api_key': 'synthetic'}, null);
    await expectLater(
      backups.apply(bad, expected: backups.capture()),
      throwsFormatException,
    );
    await expectLater(backups.read('../preferences.json'), throwsArgumentError);
    expect(await backups.list(), isEmpty);
  });
  test(
    'public preference failure rolls back and keeps its recovery snapshot',
    () async {
      storage.values[StorageKeys.studioThemeMode] = 'dark';
      storage.failKey = StorageKeys.notificationSoundEnabled;
      await expectLater(
        backups.apply(
          const StudioSettingsSnapshot({
            StorageKeys.studioThemeMode: 'light',
            StorageKeys.notificationSoundEnabled: false,
          }, null),
          expected: backups.capture(),
        ),
        throwsStateError,
      );
      expect(storage.values[StorageKeys.studioThemeMode], 'dark');
      expect(await backups.list(), hasLength(1));
    },
  );
  test(
    'shortcut write failure restores preceding public preference writes',
    () async {
      storage.values[StorageKeys.studioThemeMode] = 'dark';
      failShortcuts = true;
      await expectLater(
        backups.apply(
          change('light', shortcuts.copyWith(showInMenus: true)),
          expected: backups.capture(),
        ),
        throwsStateError,
      );
      expect(storage.values[StorageKeys.studioThemeMode], 'dark');
      expect(shortcuts.showInMenus, isFalse);
      expect(await backups.lastImportAt(), isNull);
    },
  );
  test(
    'restore makes a fresh snapshot before applying the chosen backup',
    () async {
      storage.values[StorageKeys.studioThemeMode] = 'dark';
      await backups.apply(change('light'), expected: backups.capture());
      final first = (await backups.list()).single;
      await backups.apply(
        await backups.read(first.id),
        expected: backups.capture(),
        reason: 'reset',
      );
      expect(storage.values[StorageKeys.studioThemeMode], 'dark');
      expect((await backups.list()).first.reason, 'reset');
    },
  );
}
