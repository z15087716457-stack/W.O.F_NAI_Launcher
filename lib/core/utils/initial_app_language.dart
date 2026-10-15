import 'dart:ui';

import '../constants/storage_keys.dart';
import '../storage/local_storage_service.dart';
import 'app_language.dart';
import 'localization_extension.dart';

/// Runs after settings migration, before either bootstrap or login is built.
/// A detected default is saved once, while existing choices stay untouched.
Future<AppLanguage> initializeAppLanguage({
  required LocalStorageService storage,
  required Iterable<Locale> systemLocales,
}) async {
  final stored = storage.getSetting<String>(StorageKeys.locale);
  final language = stored == null
      ? AppLanguage.fromSystemLocales(systemLocales)
      : AppLanguage.fromStorage(stored);
  if (stored == null) {
    await storage.setLocaleCode(language.storageCode);
  }
  setCurrentL10nLocale(language.locale);
  return language;
}
