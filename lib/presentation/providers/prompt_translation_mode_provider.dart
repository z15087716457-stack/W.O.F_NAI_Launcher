import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_storage_service.dart';
import '../../data/models/prompt_reading.dart';

final promptAutoTranslationEnabledProvider =
    NotifierProvider<PromptAutoTranslationEnabled, bool>(
      PromptAutoTranslationEnabled.new,
    );

class PromptAutoTranslationEnabled extends Notifier<bool> {
  static const storageKey = 'prompt_auto_translation_enabled';

  @override
  bool build() =>
      ref.watch(localStorageServiceProvider).getSetting<bool>(storageKey) ??
      false;

  Future<void> setEnabled(bool enabled) async {
    await ref.read(localStorageServiceProvider).setSetting(storageKey, enabled);
    state = enabled;
  }
}

final promptTranslationModeProvider =
    NotifierProvider<PromptTranslationModeController, PromptTranslationMode?>(
      PromptTranslationModeController.new,
    );

/// An unset preference lets existing block documents retain their mode.
class PromptTranslationModeController extends Notifier<PromptTranslationMode?> {
  static const storageKey = 'prompt_translation_mode';
  @override
  PromptTranslationMode? build() =>
      PromptTranslationMode.values.asNameMap()[ref
          .watch(localStorageServiceProvider)
          .getSetting<String>(storageKey)];

  Future<void> select(PromptTranslationMode mode) async {
    await ref
        .read(localStorageServiceProvider)
        .setSetting(storageKey, mode.name);
    state = mode;
  }
}
