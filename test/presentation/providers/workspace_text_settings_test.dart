import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_settings.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/workspace_text_settings_provider.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_edits.dart';
import '../../core/settings/settings_preferences_service_test.dart'
    show MemoryStorage;

void main() {
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
