import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/storage/local_storage_service.dart';

final workspaceFontScaleProvider =
    NotifierProvider<WorkspaceFontScaleNotifier, double>(
      WorkspaceFontScaleNotifier.new,
    );

class WorkspaceFontScaleNotifier extends Notifier<double> {
  @override
  double build() {
    final value = ref
        .read(localStorageServiceProvider)
        .getSetting(StorageKeys.workspaceFontScale);
    return value is num && value.isFinite ? value.toDouble().clamp(.8, 1.5) : 1;
  }

  Future<void> setFontScale(double scale) async {
    if (!scale.isFinite) throw ArgumentError.value(scale, 'scale');
    final value = (.8 + ((scale.clamp(.8, 1.5) - .8) / .1).round() * .1).clamp(
      .8,
      1.5,
    );
    await ref
        .read(localStorageServiceProvider)
        .setSetting(StorageKeys.workspaceFontScale, value);
    state = value;
  }

  Future<void> reset() => setFontScale(1);
}

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
      false;

  Future<void> setEnabled(bool enabled) async {
    await ref
        .read(localStorageServiceProvider)
        .setSetting(StorageKeys.promptAutocompleteEnabled, enabled);
    state = enabled;
  }
}
