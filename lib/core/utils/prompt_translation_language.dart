/// Reading language is stored on each block, independently of the UI locale.
enum PromptTranslationLanguage {
  chinese('zh', 'Simplified Chinese'),
  english('en', 'English'),
  japanese('ja', 'Japanese'),
  korean('ko', 'Korean');

  const PromptTranslationLanguage(this.code, this.promptName);

  final String code;
  final String promptName;

  static PromptTranslationLanguage fromCode(String code) {
    final language = code.toLowerCase().split(RegExp('[-_]')).first;
    return values.firstWhere(
      (value) => value.code == language,
      orElse: () => chinese,
    );
  }

  String get badgePrefix => switch (this) {
    chinese => '中',
    english => 'EN',
    japanese => '日',
    korean => '한',
  };

  String labelFor(String uiLanguageCode) => switch (fromCode(uiLanguageCode)) {
    chinese => switch (this) {
      chinese => '中文',
      english => '英语',
      japanese => '日语',
      korean => '韩语',
    },
    english => switch (this) {
      chinese => 'Chinese',
      english => 'English',
      japanese => 'Japanese',
      korean => 'Korean',
    },
    japanese => switch (this) {
      chinese => '中国語',
      english => '英語',
      japanese => '日本語',
      korean => '韓国語',
    },
    korean => switch (this) {
      chinese => '중국어',
      english => '영어',
      japanese => '일본어',
      korean => '한국어',
    },
  };
}
