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
}
