import 'dart:ui';

import 'app_language.dart';

/// Reading language is stored on each block, independently of the UI locale.
enum PromptTranslationLanguage {
  chinese('zh', 'Simplified Chinese'),
  traditionalChinese('zh-TW', 'Traditional Chinese (Taiwan)'),
  english('en', 'English'),
  japanese('ja', 'Japanese'),
  korean('ko', 'Korean');

  const PromptTranslationLanguage(this.code, this.promptName);

  final String code;
  final String promptName;

  static bool isCode(Object? value) =>
      values.any((language) => language.code == value);

  static PromptTranslationLanguage fromCode(String code) {
    final parts = code.toLowerCase().split(RegExp('[-_]'));
    if (parts.first == 'zh') {
      return parts.skip(1).any(const {'tw', 'hant', 'hk', 'mo'}.contains)
          ? traditionalChinese
          : chinese;
    }
    return values.firstWhere(
      (value) => value.code == parts.first,
      orElse: () => chinese,
    );
  }

  /// The reading language that "follow interface language" resolves to.
  static PromptTranslationLanguage forLocale(Locale locale) =>
      fromCode(locale.toLanguageTag());

  static PromptTranslationLanguage forInterface(AppLanguage language) =>
      forLocale(language.locale);

  bool get isChinese => this == chinese || this == traditionalChinese;

  String get badgePrefix => switch (this) {
    chinese => '中',
    traditionalChinese => '繁',
    english => 'EN',
    japanese => '日',
    korean => '한',
  };
}
