import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/storage/local_storage_service.dart';
import '../../core/utils/app_language.dart';
import '../../core/utils/localization_extension.dart';

part 'locale_provider.g.dart';

/// 语言设置 Notifier
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    // 从本地存储加载语言设置
    final storage = ref.read(localStorageServiceProvider);
    final locale = AppLanguage.fromStorage(storage.getLocaleCode()).locale;
    setCurrentL10nLocale(locale);
    return locale;
  }

  /// 设置语言，[code] 为 [AppLanguage.storageCode]
  Future<void> setLocale(String code) async {
    final language = AppLanguage.fromStorage(code);
    setCurrentL10nLocale(language.locale);
    state = language.locale;

    // 保存到本地存储
    final storage = ref.read(localStorageServiceProvider);
    await storage.setLocaleCode(language.storageCode);
  }

  /// 切换语言
  Future<void> toggleLocale() async {
    const languages = AppLanguage.values;
    final current = languages.indexOf(AppLanguage.fromLocale(state));
    await setLocale(languages[(current + 1) % languages.length].storageCode);
  }
}
