import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/settings/settings_preferences_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/ui_scale_provider.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_edits.dart';

import '../../core/settings/settings_preferences_service_test.dart'
    show MemoryStorage;

void main() {
  test(
    'migrates the two current preferences without rewriting their stored values',
    () async {
      for (final (old, expected) in <(Map<String, Object?>, double)>[
        ({}, 1),
        (
          {
            StorageKeys.settingsFontScale: 1.2,
            StorageKeys.workspaceFontScale: 1.5,
          },
          1.2,
        ),
        (
          {
            StorageKeys.settingsFontScale: 1,
            StorageKeys.workspaceFontScale: 1.3,
          },
          1.3,
        ),
        ({StorageKeys.settingsFontScale: 1, StorageKeys.fontScale: 1.5}, 1),
        ({StorageKeys.fontScale: 1.4}, 1.4),
        ({StorageKeys.uiScale: 1, StorageKeys.workspaceFontScale: 1.5}, 1),
        (
          {
            StorageKeys.settingsFontScale: 'bad',
            StorageKeys.workspaceFontScale: 1.2,
          },
          1.2,
        ),
      ]) {
        final storage = MemoryStorage()..values.addAll(old);
        final container = ProviderContainer(
          overrides: [localStorageServiceProvider.overrideWithValue(storage)],
        );
        expect(container.read(uiScaleProvider), expected);
        expect(storage.values, old);
        await container.read(uiScaleProvider.notifier).reset();
        expect(storage.values[StorageKeys.uiScale], 1);
        container.invalidate(uiScaleProvider);
        expect(container.read(uiScaleProvider), 1);
        container.dispose();
      }
    },
  );

  test(
    'one setting persists, reloads and owns the settings contract',
    () async {
      final storage = MemoryStorage();
      ProviderContainer create() => ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      );
      var container = create();
      await container
          .read(settingsValueStoreProvider)
          .write(SettingKey.uiScale, 1.34);
      expect(container.read(uiScaleProvider), 1.3);
      expect(storage.values[StorageKeys.uiScale], 1.3);
      container.dispose();
      container = create();
      addTearDown(container.dispose);
      expect(container.read(uiScaleProvider), 1.3);
      expect(SettingSpec.of(SettingKey.uiScale).defaultValue, 1.0);
      expect(SettingsPreferencesService.keys, contains(StorageKeys.uiScale));
      expect(
        SettingsPreferencesService.keys,
        isNot(contains(StorageKeys.settingsFontScale)),
      );
      expect(
        SettingsPreferencesService.keys,
        isNot(contains(StorageKeys.workspaceFontScale)),
      );
    },
  );

  test(
    'old backups converge to one value; resetting cannot revive a legacy value',
    () async {
      final storage = MemoryStorage()
        ..values[StorageKeys.workspaceFontScale] = 1.5;
      final service = SettingsPreferencesService(storage);
      final imported = service.decode(
        service.encode({
          StorageKeys.settingsFontScale: 1.2,
          StorageKeys.workspaceFontScale: 1.5,
          StorageKeys.fontScale: 1.4,
        }),
      );
      expect(imported, {StorageKeys.uiScale: 1.2});
      expect(service.capture()[StorageKeys.uiScale], 1.5);
      expect(service.decode(service.encode({StorageKeys.uiScale: null})), {
        StorageKeys.uiScale: 1.0,
      });
    },
  );
}
