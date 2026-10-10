import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/prompt_translation_language.dart';
import '../../../../l10n/app_localizations.dart';

/// Small editor labels share the UI locale; content language belongs to a block.
class TranslationEditorLabels {
  TranslationEditorLabels(BuildContext context)
    : _l10n = context.l10n,
      language = PromptTranslationLanguage.forLocale(
        Localizations.localeOf(context),
      );

  final AppLocalizations _l10n;
  final PromptTranslationLanguage language;

  String get title => _l10n.translationEditor_title;
  String get source => _l10n.translationEditor_source;
  String get sourcePrefix => _l10n.translationEditor_sourcePrefix;
  String get generation => _l10n.translationEditor_generation;
  String get editable => _l10n.translationEditor_editable;
  String get modified => _l10n.translationEditor_modified;
  String get edited => _l10n.translationEditor_edited;
  String get close => _l10n.translationEditor_close;
  String get save => _l10n.translationEditor_save;
  String get delete => _l10n.translationEditor_delete;
  String get restore => _l10n.translationEditor_restore;
  String get configure => _l10n.translationEditor_configure;
  String reading(PromptTranslationLanguage value) => switch (value) {
    PromptTranslationLanguage.chinese => _l10n.translationLanguage_chinese,
    PromptTranslationLanguage.traditionalChinese =>
      _l10n.translationLanguage_traditionalChinese,
    PromptTranslationLanguage.english => _l10n.translationLanguage_english,
    PromptTranslationLanguage.japanese => _l10n.translationLanguage_japanese,
    PromptTranslationLanguage.korean => _l10n.translationLanguage_korean,
  };
  String readingFieldTitle(PromptTranslationLanguage value) =>
      _l10n.translationEditor_readingFieldTitle(reading(value));
  String sourceWarning(PromptTranslationLanguage value) =>
      _l10n.translationEditor_sourceWarning(reading(value));
  String get editHint => _l10n.translationEditor_editHint;
}
