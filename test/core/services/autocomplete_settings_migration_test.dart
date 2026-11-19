import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/services/data_migration_service.dart';
import 'package:nai_launcher/presentation/providers/workspace_text_settings_provider.dart';

void main() {
  late Box settings;
  final migrate = DataMigrationService.instance.migrateAutocompleteSettings;

  setUp(() async {
    final directory = await Directory.systemTemp.createTemp(
      'autocomplete_migration_',
    );
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    Hive.init(directory.path);
    settings = await Hive.openBox(StorageKeys.settingsBox);
  });

  test(
    'an upgrade enables saved-off completion once across restarts',
    () async {
      await settings.putAll({
        StorageKeys.autocompleteMigrationVersion: 1,
        StorageKeys.promptAutocompleteEnabled: false,
        StorageKeys.enableCooccurrenceRecommendation: false,
      });
      await migrate();
      final first = ProviderContainer();
      addTearDown(first.dispose);
      expect(first.read(promptAutocompleteEnabledProvider), isTrue);
      expect(settings.get(StorageKeys.autocompleteMigrationVersion), 2);
      expect(
        settings.get(StorageKeys.enableCooccurrenceRecommendation),
        isFalse,
      );

      await first
          .read(promptAutocompleteEnabledProvider.notifier)
          .setEnabled(false);
      await settings.close();
      await Hive.openBox(StorageKeys.settingsBox);
      await migrate();
      final restarted = ProviderContainer();
      addTearDown(restarted.dispose);
      expect(restarted.read(promptAutocompleteEnabledProvider), isFalse);
    },
  );

  test('a new profile starts enabled and records the migration', () async {
    await migrate();
    expect(settings.get(StorageKeys.promptAutocompleteEnabled), isTrue);
    expect(settings.get(StorageKeys.autocompleteMigrationVersion), 2);
  });

  test('a pre-v1 profile also completes legacy settings cleanup', () async {
    await settings.putAll({
      StorageKeys.promptAutocompleteEnabled: false,
      StorageKeys.danbooruTagsHotPreset: 'old',
    });
    await migrate();
    expect(settings.containsKey(StorageKeys.danbooruTagsHotPreset), isFalse);
    expect(settings.get(StorageKeys.promptAutocompleteEnabled), isTrue);
    expect(settings.get(StorageKeys.autocompleteMigrationVersion), 2);
  });

  test('a newer migration version preserves the saved choice', () async {
    await settings.putAll({
      StorageKeys.autocompleteMigrationVersion: 3,
      StorageKeys.promptAutocompleteEnabled: false,
    });
    await migrate();
    expect(settings.get(StorageKeys.promptAutocompleteEnabled), isFalse);
    expect(settings.get(StorageKeys.autocompleteMigrationVersion), 3);
  });
}
