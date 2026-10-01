import '../../../../core/utils/prompt_translation_language.dart';

/// Small editor labels share the UI locale; content language belongs to a block.
class TranslationEditorLabels {
  TranslationEditorLabels(String languageCode)
    : language = PromptTranslationLanguage.fromCode(languageCode);

  final PromptTranslationLanguage language;

  String _text(String zh, String en, String ja, String ko) =>
      switch (language) {
        PromptTranslationLanguage.chinese => zh,
        PromptTranslationLanguage.english => en,
        PromptTranslationLanguage.japanese => ja,
        PromptTranslationLanguage.korean => ko,
      };

  String get title => _text('翻译块', 'Translation block', '翻訳ブロック', '번역 블록');
  String get source => _text('原文', 'Original', '原文', '원문');
  String get sourcePrefix => _text('原', 'Src', '原', '원');
  String get generation => _text('生图使用', 'Generation', '画像生成用', '이미지 생성용');
  String get editable => _text('可改写', 'Editable', '編集可能', '편집 가능');
  String get modified => _text('被修改', 'Modified', '変更済み', '수정됨');
  String get edited => _text('已编辑', 'Edited', '編集済み', '편집됨');
  String get close => _text('关闭', 'Close', '閉じる', '닫기');
  String get save => _text('保存', 'Save', '保存', '저장');
  String get delete => _text('删除整块', 'Delete block', 'ブロックを削除', '블록 삭제');
  String get restore =>
      _text('还原为原文文本', 'Restore original text', '原文テキストに戻す', '원문 텍스트로 복원');
  String get configure =>
      _text('配置翻译模型', 'Configure translation model', '翻訳モデルを設定', '번역 모델 설정');
  String reading(PromptTranslationLanguage value) =>
      value.labelFor(language.code);
  String readingFieldTitle(PromptTranslationLanguage value) => _text(
    '${reading(value)}阅读文本',
    '${reading(value)} reading text',
    '${reading(value)}の表示テキスト',
    '${reading(value)} 읽기 텍스트',
  );
  String sourceWarning(PromptTranslationLanguage value) => _text(
    '原文已修改，${reading(value)}待同步',
    'Original modified; ${reading(value)} needs syncing',
    '原文が変更されました。${reading(value)}との同期が必要です',
    '원문이 수정되었습니다. ${reading(value)} 동기화가 필요합니다',
  );
  String get editHint => _text(
    '译文已手工编辑；这是编辑记录，不触发原文修改提醒',
    'Translation edited manually; original review status is unchanged',
    '訳文の手動編集履歴です。原文の確認状態は変わりません',
    '번역을 직접 편집했습니다. 원문 검토 상태는 유지됩니다',
  );
}
