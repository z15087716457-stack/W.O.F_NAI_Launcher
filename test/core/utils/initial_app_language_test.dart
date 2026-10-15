import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/utils/app_language.dart';
import 'package:nai_launcher/core/utils/initial_app_language.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/presentation/providers/locale_provider.dart';

import '../../helpers/light_theme_contrast.dart';

void main() {
  tearDown(() => setCurrentL10nLocale(const Locale('zh')));

  for (final entry in const [
    (Locale('zh', 'CN'), AppLanguage.simplifiedChinese),
    (Locale('zh', 'SG'), AppLanguage.simplifiedChinese),
    (Locale('zh', 'TW'), AppLanguage.traditionalChinese),
    (Locale('zh', 'HK'), AppLanguage.traditionalChinese),
    (Locale('zh', 'MO'), AppLanguage.traditionalChinese),
    (
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      AppLanguage.traditionalChinese,
    ),
    (
      Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: 'HK',
      ),
      AppLanguage.simplifiedChinese,
    ),
    (Locale('en', 'GB'), AppLanguage.english),
    (Locale('ja', 'JP'), AppLanguage.japanese),
    (Locale('ko', 'KR'), AppLanguage.korean),
  ]) {
    test('fresh setup uses ${entry.$1} before the first app frame', () async {
      final storage = InMemoryLocalStorageService();
      final language = await initializeAppLanguage(
        storage: storage,
        systemLocales: [entry.$1],
      );
      expect(language, entry.$2);
      expect(storage.getLocaleCode(), entry.$2.storageCode);
      expect(currentAppLanguage, entry.$2);
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      expect(container.read(localeNotifierProvider), entry.$2.locale);
    });
  }

  test('system preference order skips unsupported languages', () {
    expect(
      AppLanguage.fromSystemLocales(const [
        Locale('fr'),
        Locale('ja'),
        Locale('ko'),
      ]),
      AppLanguage.japanese,
    );
    expect(
      AppLanguage.fromSystemLocales(const [Locale('ko'), Locale('en')]),
      AppLanguage.korean,
    );
    expect(
      AppLanguage.fromSystemLocales(const [Locale('de')]),
      AppLanguage.english,
    );
    expect(AppLanguage.fromSystemLocales(const []), AppLanguage.english);
  });

  for (final stored in ['zh', 'zh_TW', 'en', 'ja', 'ko', 'zh-Hant-TW']) {
    test('existing choice $stored is not replaced or normalized', () async {
      final storage = InMemoryLocalStorageService();
      await storage.setLocaleCode(stored);
      await initializeAppLanguage(
        storage: storage,
        systemLocales: const [Locale('ko')],
      );
      expect(storage.getLocaleCode(), stored);
      expect(currentAppLanguage, AppLanguage.fromStorage(stored));
    });
  }

  test('detected default survives a later OS language change', () async {
    final storage = InMemoryLocalStorageService();
    await initializeAppLanguage(
      storage: storage,
      systemLocales: const [Locale('ja')],
    );
    await initializeAppLanguage(
      storage: storage,
      systemLocales: const [Locale('ko')],
    );
    expect(storage.getLocaleCode(), 'ja');
    expect(currentAppLanguage, AppLanguage.japanese);
  });

  test(
    'manual choice persists across real storage close and startup',
    () async {
      await setUpTemporaryHive();
      await Hive.openBox(StorageKeys.settingsBox);
      final storage = LocalStorageService();
      await initializeAppLanguage(
        storage: storage,
        systemLocales: const [Locale('ja')],
      );
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      );
      expect(container.read(localeNotifierProvider), const Locale('ja'));
      await container.read(localeNotifierProvider.notifier).setLocale('zh_TW');
      container.dispose();
      await Hive.box(StorageKeys.settingsBox).close();
      await Hive.openBox(StorageKeys.settingsBox);
      await initializeAppLanguage(
        storage: storage,
        systemLocales: const [Locale('en')],
      );
      final restarted = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      );
      addTearDown(restarted.dispose);
      expect(restarted.read(localeNotifierProvider), const Locale('zh', 'TW'));
      expect(currentAppLanguage, AppLanguage.traditionalChinese);
      expect(currentL10n.localeName, 'zh_TW');
    },
  );
}
