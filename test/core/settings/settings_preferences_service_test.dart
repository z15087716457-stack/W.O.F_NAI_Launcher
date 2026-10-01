import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/settings/settings_preferences_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';

class MemoryStorage extends LocalStorageService {
  final values = <String, Object?>{};
  String? failKey;
  void Function(String key)? beforeWrite;
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      (values[key] ?? defaultValue) as T?;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    beforeWrite?.call(key);
    if (key == failKey) {
      failKey = null;
      throw StateError('simulated failure');
    }
    values[key] = value;
  }

  @override
  Future<void> deleteSetting(String key) async {
    values.remove(key);
  }
}

void main() {
  late MemoryStorage storage;
  late Directory dir;
  late SettingsPreferencesService service;
  setUp(() {
    storage = MemoryStorage();
    dir = Directory.systemTemp.createTempSync('studio_preference_test_');
    service = SettingsPreferencesService(storage, backupDirectory: dir);
  });
  tearDown(() async => dir.delete(recursive: true));
  test(
    'round trip includes tag expansion preferences and excludes accounts, model bindings and paths',
    () {
      storage.values.addAll({
        StorageKeys.tagExpansionResultLimit: CompletionResultLimits.all,
        StorageKeys.fontScale: 1.3,
        'token': 'fake_secret',
        StorageKeys.promptAssistantConfigJson: 'fake_model_config',
        StorageKeys.imageSavePath: 'fake_path',
      });
      final values = service.decode(service.encode(service.capture()));
      expect(values[StorageKeys.tagExpansionResultLimit], 300000);
      expect(values[StorageKeys.fontScale], 1.3);
      expect(values.keys, isNot(contains('token')));
      expect(values.keys, isNot(contains(StorageKeys.imageSavePath)));
      expect(
        values.keys,
        isNot(contains(StorageKeys.promptAssistantConfigJson)),
      );
    },
  );
  test(
    'invalid schema, secret keys and invalid values reject before any mutation',
    () async {
      for (final raw in [
        jsonEncode({
          'schema': 'other',
          'version': 1,
          'preferences': {StorageKeys.fontScale: 1},
        }),
        service.encode({'api_key': 'fake'}),
        service.encode({StorageKeys.fontScale: 10}),
        service.encode({StorageKeys.tagExpansionResultLimit: 0}),
        service.encode({StorageKeys.enableCooccurrenceRecommendation: 'true'}),
      ]) {
        expect(() => service.decode(raw), throwsFormatException);
      }
      expect(storage.values, isEmpty);
      expect(await dir.list().toList(), isEmpty);
    },
  );
  test(
    'reset only selected scope and backup can restore pre-reset state',
    () async {
      storage.values.addAll({
        StorageKeys.studioThemeMode: 'light',
        StorageKeys.enableCooccurrenceRecommendation: false,
        'token': 'fake_secret',
      });
      final before = service.capture();
      final file = await service.apply(
        service.defaults({PreferenceGroup.appearance}),
        expected: before,
      );
      expect(storage.values[StorageKeys.studioThemeMode], isNull);
      expect(
        storage.values[StorageKeys.enableCooccurrenceRecommendation],
        false,
      );
      expect(storage.values['token'], 'fake_secret');
      expect(service.decode(await file.readAsString()), before);
      await service.apply(
        service.decode(await file.readAsString()),
        expected: service.capture(),
      );
      expect(storage.values[StorageKeys.studioThemeMode], 'light');
    },
  );
  test(
    'write failure rolls back previous touched preferences and keeps backup',
    () async {
      storage.values[StorageKeys.studioThemeMode] = 'light';
      storage.failKey = StorageKeys.enableCooccurrenceRecommendation;
      final before = service.capture();
      await expectLater(
        service.apply({
          StorageKeys.studioThemeMode: 'dark',
          StorageKeys.enableCooccurrenceRecommendation: false,
        }, expected: before),
        throwsStateError,
      );
      expect(service.capture(), before);
      expect(await service.latestBackup(), isNotNull);
    },
  );
  test('stale confirmation does not write or create backup', () async {
    final before = service.capture();
    storage.values[StorageKeys.fontScale] = 1.3;
    await expectLater(
      service.apply({StorageKeys.fontScale: 1.0}, expected: before),
      throwsStateError,
    );
    expect(storage.values[StorageKeys.fontScale], 1.3);
    expect(await dir.list().toList(), isEmpty);
  });
  test('rollback preserves another later write during failed import', () async {
    storage.values[StorageKeys.studioThemeMode] = 'light';
    storage.failKey = StorageKeys.enableCooccurrenceRecommendation;
    storage.beforeWrite = (key) {
      if (key == StorageKeys.enableCooccurrenceRecommendation)
        storage.values[StorageKeys.studioThemeMode] = 'light';
    };
    await expectLater(
      service.apply({
        StorageKeys.studioThemeMode: 'dark',
        StorageKeys.enableCooccurrenceRecommendation: false,
      }, expected: service.capture()),
      throwsStateError,
    );
    expect(storage.values[StorageKeys.studioThemeMode], 'light');
  });
}
