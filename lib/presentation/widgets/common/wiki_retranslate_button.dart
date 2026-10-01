import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/wiki/auto_tag_translation_controller.dart';
import 'translation_icon.dart';

String wikiTranslatingLabel(BuildContext context) =>
    switch (Localizations.localeOf(context).languageCode) {
      'zh' => '正在翻译中',
      'ja' => '翻訳中',
      'ko' => '번역 중',
      _ => 'Translating',
    };

String wikiBackLabel(BuildContext context) =>
    switch (Localizations.localeOf(context).languageCode) {
      'zh' => '返回上一次',
      'ja' => '前に戻る',
      'ko' => '이전으로',
      _ => 'Back',
    };

String wikiReadingStateLabel(BuildContext context, bool showTranslation) =>
    switch (Localizations.localeOf(context).languageCode) {
      'zh' => showTranslation ? '译文' : '原文',
      'ja' => showTranslation ? '訳文' : '原文',
      'ko' => showTranslation ? '번역문' : '원문',
      _ => showTranslation ? 'Translation' : 'Original',
    };

/// Both actions share a quiet, right-aligned footer. The reading label describes
/// the body currently on screen, while the tooltip describes the next action.
class WikiArticleActions extends StatelessWidget {
  const WikiArticleActions({
    super.key,
    required this.tag,
    required this.surface,
    required this.showTranslation,
    required this.onToggle,
  });

  final String tag, surface;
  final bool showTranslation;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 4,
    children: [
      Tooltip(
        message: switch (Localizations.localeOf(context).languageCode) {
          'zh' => showTranslation ? '切换到原文' : '切换到译文',
          'ja' => showTranslation ? '原文に切り替え' : '訳文に切り替え',
          'ko' => showTranslation ? '원문으로 전환' : '번역문으로 전환',
          _ => showTranslation ? 'Show original' : 'Show translation',
        },
        child: TextButton.icon(
          key: ValueKey('wiki-reading-toggle-$tag'),
          onPressed: onToggle,
          style: _wikiActionStyle(context),
          icon: showTranslation
              ? const TranslationIcon(size: 14)
              : const Icon(Icons.subject, size: 14),
          label: Text(wikiReadingStateLabel(context, showTranslation)),
        ),
      ),
      WikiRetranslateButton(tag: tag, surface: surface),
    ],
  );
}

ButtonStyle _wikiActionStyle(BuildContext context) => TextButton.styleFrom(
  foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  minimumSize: const Size(0, 28),
  visualDensity: VisualDensity.compact,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  textStyle: Theme.of(context).textTheme.labelSmall,
);

class WikiRetranslateButton extends ConsumerWidget {
  const WikiRetranslateButton({
    super.key,
    required this.tag,
    required this.surface,
  });
  final String tag;
  final String surface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translation = ref.watch(autoTagTranslationProvider);
    final busy = translation.isWikiTranslating(tag);
    final label = busy
        ? wikiTranslatingLabel(context)
        : switch (Localizations.localeOf(context).languageCode) {
            'zh' => '重新翻译',
            'ja' => '再翻訳',
            'ko' => '다시 번역',
            _ => 'Retranslate',
          };
    return Tooltip(
      message: translation.wikiErrorFor(tag) ?? label,
      child: TextButton.icon(
        key: ValueKey('wiki-retranslate-$tag'),
        onPressed: busy
            ? null
            : () => translation.retranslateWiki(surface: surface, tag: tag),
        style: _wikiActionStyle(context),
        icon: busy
            ? const TranslationIcon(size: 14, busy: true)
            : const Icon(Icons.refresh, size: 14),
        label: Text(label),
      ),
    );
  }
}
