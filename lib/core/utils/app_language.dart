import 'dart:ui';

import '../../l10n/zh_tw_labels.dart';

/// Interface languages. Simplified and Traditional Chinese share the language
/// code `zh`, so code that must tell them apart uses this instead of
/// [Locale.languageCode].
enum AppLanguage {
  simplifiedChinese('zh', Locale('zh'), '简体中文'),
  traditionalChinese('zh_TW', Locale('zh', 'TW'), '繁體中文'),
  english('en', Locale('en'), 'English'),
  japanese('ja', Locale('ja'), '日本語'),
  korean('ko', Locale('ko'), '한국어');

  const AppLanguage(this.storageCode, this.locale, this.nativeName);

  /// Value saved under StorageKeys.locale. Existing settings keep `zh`.
  final String storageCode;
  final Locale locale;

  /// Shown in the language picker in the language itself.
  final String nativeName;

  bool get isChinese => this == simplifiedChinese || this == traditionalChinese;
  bool get isTraditionalChinese => this == traditionalChinese;

  /// Locale tag for Chinese tag readings: Traditional for the Traditional
  /// interface, otherwise the dictionary's Simplified text.
  String get chineseReadingLocale => isTraditionalChinese ? 'zh-TW' : 'zh-CN';

  /// Curated Simplified labels kept in code (Wiki directory, tag group and
  /// category names, button copy) in this language's script. Traditional
  /// forms are generated at build time; see tool/l10n.
  String chineseLabel(String simplified) =>
      isTraditionalChinese ? zhTwLabels[simplified] ?? simplified : simplified;

  static bool isStorageCode(Object? value) =>
      values.any((language) => language.storageCode == value);

  static AppLanguage fromStorage(String? code) {
    if (code == null) return simplifiedChinese;
    for (final language in values) {
      if (language.storageCode == code) return language;
    }
    final parts = code.split(RegExp('[-_]'));
    return fromLocale(
      Locale.fromSubtags(
        languageCode: parts.first,
        scriptCode:
            parts.length > 2 || (parts.length == 2 && parts[1].length == 4)
            ? parts[1]
            : null,
        countryCode: parts.length > 1 && parts.last.length == 2
            ? parts.last
            : null,
      ),
    );
  }

  static AppLanguage fromLocale(Locale locale) {
    switch (locale.languageCode.toLowerCase()) {
      case 'zh':
        final traditional =
            locale.scriptCode?.toLowerCase() == 'hant' ||
            const {
              'TW',
              'HK',
              'MO',
            }.contains(locale.countryCode?.toUpperCase());
        return traditional ? traditionalChinese : simplifiedChinese;
      case 'ja':
        return japanese;
      case 'ko':
        return korean;
      default:
        return english;
    }
  }

  /// Accepts BCP 47 tags such as `zh-TW`, `zh-Hant` or `zh-CN`.
  static AppLanguage fromLanguageTag(String tag) => fromStorage(tag);
}
