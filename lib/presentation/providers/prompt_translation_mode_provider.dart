import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_storage_service.dart';
import '../../data/models/prompt_reading.dart';

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
