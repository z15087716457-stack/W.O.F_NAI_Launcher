import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/app_language.dart';
import 'package:nai_launcher/core/utils/prompt_translation_language.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';

void main() {
  test('stored codes keep legacy zh as Simplified Chinese', () {
    expect(AppLanguage.fromStorage(null), AppLanguage.simplifiedChinese);
    expect(AppLanguage.fromStorage('zh'), AppLanguage.simplifiedChinese);
    expect(AppLanguage.fromStorage('zh_TW'), AppLanguage.traditionalChinese);
    expect(AppLanguage.fromStorage('zh-Hant'), AppLanguage.traditionalChinese);
    expect(
      AppLanguage.fromStorage('zh-Hant-TW'),
      AppLanguage.traditionalChinese,
    );
    expect(AppLanguage.fromStorage('zh-CN'), AppLanguage.simplifiedChinese);
    expect(AppLanguage.fromStorage('en'), AppLanguage.english);
    expect(AppLanguage.fromStorage('ja'), AppLanguage.japanese);
    expect(AppLanguage.fromStorage('ko'), AppLanguage.korean);
    expect(AppLanguage.fromStorage('ko-KR'), AppLanguage.korean);
    expect(AppLanguage.fromStorage('xx'), AppLanguage.english);
  });

  test('locales tell Traditional and Simplified Chinese apart', () {
    expect(
      AppLanguage.fromLocale(const Locale('zh')),
      AppLanguage.simplifiedChinese,
    );
    for (final locale in const [
      Locale('zh', 'TW'),
      Locale('zh', 'HK'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    ]) {
      expect(AppLanguage.fromLocale(locale), AppLanguage.traditionalChinese);
    }
  });

  test('every language is generated and round-trips through storage', () {
    for (final language in AppLanguage.values) {
      expect(AppLocalizations.supportedLocales, contains(language.locale));
      expect(AppLanguage.fromStorage(language.storageCode), language);
      expect(AppLanguage.isStorageCode(language.storageCode), isTrue);
    }
    expect(AppLanguage.isStorageCode('zh-Hant'), isFalse);
    expect(AppLanguage.traditionalChinese.locale.toString(), 'zh_TW');
    expect(AppLanguage.traditionalChinese.nativeName, '繁體中文');
    expect(AppLanguage.korean.nativeName, '한국어');
  });

  test('curated labels use the generated Traditional table', () {
    expect(AppLanguage.traditionalChinese.chineseLabel('视觉特征'), '視覺特徵');
    expect(AppLanguage.traditionalChinese.chineseLabel('发型'), '髮型');
    expect(AppLanguage.traditionalChinese.chineseLabel('unknown'), 'unknown');
    for (final language in [
      AppLanguage.simplifiedChinese,
      AppLanguage.english,
      AppLanguage.japanese,
      AppLanguage.korean,
    ]) {
      expect(language.chineseLabel('发型'), '发型');
    }
  });

  test('reading languages add Traditional Chinese as zh-TW', () {
    const traditional = PromptTranslationLanguage.traditionalChinese;
    expect(traditional.code, 'zh-TW');
    expect(traditional.badgePrefix, '繁');
    expect(traditional.isChinese, isTrue);
    for (final code in ['zh-TW', 'zh_TW', 'zh-Hant', 'zh-HK']) {
      expect(PromptTranslationLanguage.fromCode(code), traditional);
    }
    expect(
      PromptTranslationLanguage.fromCode('zh'),
      PromptTranslationLanguage.chinese,
    );
    expect(
      PromptTranslationLanguage.fromCode('zh-CN'),
      PromptTranslationLanguage.chinese,
    );
    expect(
      PromptTranslationLanguage.forInterface(AppLanguage.traditionalChinese),
      traditional,
    );
    expect(
      PromptTranslationLanguage.forLocale(const Locale('ko')),
      PromptTranslationLanguage.korean,
    );
    expect(
      PromptTranslationLanguage.forInterface(AppLanguage.korean),
      PromptTranslationLanguage.korean,
    );
    expect(PromptTranslationLanguage.isCode('zh-TW'), isTrue);
    expect(PromptTranslationLanguage.isCode('zh_TW'), isFalse);
  });
}
