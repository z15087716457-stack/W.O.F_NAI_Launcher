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
    this.compact = true,
  });

  final String tag, surface;
  final bool showTranslation;
  final VoidCallback onToggle;
  final bool compact;

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
          style: _wikiActionStyle(context, compact: compact),
          icon: showTranslation
              ? Icon(Icons.translate, size: compact ? 14 : 17)
              : Icon(Icons.subject, size: compact ? 14 : 17),
          label: Text(wikiReadingStateLabel(context, showTranslation)),
        ),
      ),
      WikiRetranslateButton(tag: tag, surface: surface, compact: compact),
    ],
  );
}

ButtonStyle _wikiActionStyle(BuildContext context, {bool compact = true}) =>
    TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: compact ? 4 : 6),
      minimumSize: Size(0, compact ? 28 : 32),
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: compact
          ? Theme.of(context).textTheme.labelSmall
          : Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 14),
    );

class WikiRetranslateButton extends ConsumerWidget {
  const WikiRetranslateButton({
    super.key,
    required this.tag,
    required this.surface,
    this.compact = true,
  });
  final String tag;
  final String surface;
  final bool compact;

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
        style: _wikiActionStyle(context, compact: compact),
        icon: busy
            ? TranslationIcon(size: compact ? 14 : 17, busy: true)
            : Icon(Icons.refresh, size: compact ? 14 : 17),
        label: Text(label),
      ),
    );
  }
}
