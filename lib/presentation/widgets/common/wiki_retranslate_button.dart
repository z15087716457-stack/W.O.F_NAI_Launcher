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
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(0, 28),
          visualDensity: VisualDensity.compact,
          textStyle: Theme.of(context).textTheme.labelSmall,
        ),
        icon: busy
            ? const TranslationIcon(size: 14, busy: true)
            : const Icon(Icons.refresh, size: 14),
        label: Text(label),
      ),
    );
  }
}
