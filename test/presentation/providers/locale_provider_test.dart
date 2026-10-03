import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/utils/app_language.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/presentation/providers/locale_provider.dart';

import '../../helpers/light_theme_contrast.dart';

void main() {
  late InMemoryLocalStorageService storage;
  late ProviderContainer container;

  setUp(() {
    storage = InMemoryLocalStorageService();
    container = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    );
  });

  tearDown(() {
    container.dispose();
    setCurrentL10nLocale(const Locale('zh'));
  });

  test('legacy zh setting stays Simplified Chinese', () {
    storage.setSetting(StorageKeys.locale, 'zh');

    expect(container.read(localeNotifierProvider), const Locale('zh'));
    expect(currentAppLanguage, AppLanguage.simplifiedChinese);
    expect(currentL10n.localeName, 'zh');
  });

  test('Traditional Chinese is stored as zh_TW', () async {
    container.read(localeNotifierProvider);

    await container.read(localeNotifierProvider.notifier).setLocale('zh_TW');

    expect(container.read(localeNotifierProvider), const Locale('zh', 'TW'));
    expect(storage.getLocaleCode(), 'zh_TW');
    expect(currentAppLanguage, AppLanguage.traditionalChinese);
    expect(currentL10n.localeName, 'zh_TW');
  });

  test('toggle cycles through every interface language', () async {
    storage.setSetting(StorageKeys.locale, 'zh');
    final notifier = container.read(localeNotifierProvider.notifier);
    final visited = <String>[];
    for (var index = 0; index < AppLanguage.values.length; index++) {
      await notifier.toggleLocale();
      visited.add(storage.getLocaleCode());
    }

    expect(visited, ['zh_TW', 'en', 'ja', 'ko', 'zh']);
  });
}
