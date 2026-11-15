import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/storage/local_storage_service.dart';

/// Independent of the explicit Ctrl tag picker and its existing settings.
final promptAutocompleteEnabledProvider =
    NotifierProvider<PromptAutocompleteEnabledNotifier, bool>(
      PromptAutocompleteEnabledNotifier.new,
    );

class PromptAutocompleteEnabledNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref
          .read(localStorageServiceProvider)
          .getSetting<bool>(StorageKeys.promptAutocompleteEnabled) ??
      true;

  Future<void> setEnabled(bool enabled) async {
    await ref
        .read(localStorageServiceProvider)
        .setSetting(StorageKeys.promptAutocompleteEnabled, enabled);
    state = enabled;
  }
}
