import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_settings.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/settings_font_scale_provider.dart';
import 'package:nai_launcher/presentation/providers/workspace_text_settings_provider.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_edits.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_values.dart';
import '../../core/settings/settings_preferences_service_test.dart'
    show MemoryStorage;

void main() {
  test(
    'settings read projection follows both independent preferences reactively',
    () async {
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(MemoryStorage()),
        ],
      );
      addTearDown(container.dispose);
      final updates = <Map<SettingKey, Object>>[];
      container.listen(
        workspaceTextSettingValuesProvider,
        (_, next) => updates.add(next),
        fireImmediately: true,
      );
      expect(container.read(workspaceTextSettingValuesProvider), {
        SettingKey.workspaceFontScale: 1.0,
        SettingKey.promptAutocomplete: false,
      });
      await container
          .read(settingsValueStoreProvider)
          .write(SettingKey.workspaceFontScale, 1.5);
      expect(
        container.read(
          workspaceTextSettingValuesProvider,
        )[SettingKey.workspaceFontScale],
        1.5,
      );
      await container
          .read(settingsValueStoreProvider)
          .write(SettingKey.promptAutocomplete, true);
      expect(
        container.read(
          workspaceTextSettingValuesProvider,
        )[SettingKey.promptAutocomplete],
        true,
      );
      expect(updates, hasLength(3));
    },
  );

  test(
    'creative scale persists/reloads/resets independently with settings wiring',
    () async {
      final storage = MemoryStorage()
        ..values[StorageKeys.settingsFontScale] = 1.2;
      ProviderContainer create() => ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      );
      final container = create();
      expect(container.read(workspaceFontScaleProvider), 1);
      expect(container.read(settingsFontScaleProvider), 1.2);
      await container
          .read(settingsValueStoreProvider)
          .write(SettingKey.workspaceFontScale, 1.34);
      expect(container.read(workspaceFontScaleProvider), closeTo(1.3, .0001));
      expect(
        storage.values[StorageKeys.workspaceFontScale],
        closeTo(1.3, .0001),
      );
      expect(container.read(settingsFontScaleProvider), 1.2);
      container.dispose();
      final reloaded = create();
      addTearDown(reloaded.dispose);
      expect(reloaded.read(workspaceFontScaleProvider), closeTo(1.3, .0001));
      final notifier = reloaded.read(workspaceFontScaleProvider.notifier);
      await expectLater(notifier.setFontScale(double.nan), throwsArgumentError);
      await expectLater(
        notifier.setFontScale(double.infinity),
        throwsArgumentError,
      );
      expect(reloaded.read(workspaceFontScaleProvider), closeTo(1.3, .0001));
      await notifier.setFontScale(9);
      expect(reloaded.read(workspaceFontScaleProvider), 1.5);
      await notifier.setFontScale(-1);
      expect(reloaded.read(workspaceFontScaleProvider), .8);
      await notifier.reset();
      expect(reloaded.read(workspaceFontScaleProvider), 1);
      expect(storage.values[StorageKeys.settingsFontScale], 1.2);
      final spec = SettingSpec.of(SettingKey.workspaceFontScale);
      expect(
        (spec.min, spec.max, spec.step, spec.defaultValue),
        (.8, 1.5, .1, 1.0),
      );
    },
  );

  test('stored scale clamps and invalid stored values use the default', () {
    final storage = MemoryStorage();
    final container = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    for (final (stored, expected) in [
      (0, .8),
      (10, 1.5),
      (double.nan, 1),
      ('bad', 1),
      (1.2, 1.2),
    ]) {
      storage.values[StorageKeys.workspaceFontScale] = stored;
      container.invalidate(workspaceFontScaleProvider);
      expect(container.read(workspaceFontScaleProvider), expected);
    }
  });

  test(
    'typed autocomplete defaults off and never rewrites explicit picker settings',
    () async {
      final storage = MemoryStorage();
      ProviderContainer create() => ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      );
      final container = create();
      expect(container.read(promptAutocompleteEnabledProvider), false);
      expect(container.read(autocompleteSettingsProvider).enabled, true);
      await container
          .read(settingsValueStoreProvider)
          .write(SettingKey.promptAutocomplete, true);
      expect(container.read(promptAutocompleteEnabledProvider), true);
      expect(storage.values[StorageKeys.promptAutocompleteEnabled], true);
      expect(container.read(autocompleteSettingsProvider).enabled, true);
      container.dispose();
      final reloaded = create();
      addTearDown(reloaded.dispose);
      expect(reloaded.read(promptAutocompleteEnabledProvider), true);
      await reloaded
          .read(settingsValueStoreProvider)
          .write(SettingKey.promptAutocomplete, false);
      expect(reloaded.read(promptAutocompleteEnabledProvider), false);
      expect(SettingSpec.of(SettingKey.promptAutocomplete).defaultValue, false);
    },
  );
}
