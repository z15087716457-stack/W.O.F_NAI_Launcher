import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/wiki/auto_tag_translation_controller.dart';
import 'translation_icon.dart';
import '../../../core/utils/localization_extension.dart';

String wikiTranslatingLabel(BuildContext context) =>
    context.l10n.wiki_translating;

String wikiBackLabel(BuildContext context) => context.l10n.wiki_back;

String wikiReadingStateLabel(BuildContext context, bool showTranslation) =>
    showTranslation
    ? context.l10n.wiki_readingTranslation
    : context.l10n.wiki_readingOriginal;

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
        message: showTranslation
            ? context.l10n.wiki_switchToOriginal
            : context.l10n.wiki_switchToTranslation,
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

class TagTranslationIndicator extends ConsumerWidget {
  const TagTranslationIndicator({
    super.key,
    required this.tag,
    required this.surface,
    this.wiki = false,
    this.size = 14,
  });

  static const extent = 22.0;
  final String tag, surface;
  final bool wiki;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(autoTagTranslationProvider);
    final activity = controller.activityFor(tag, wiki: wiki);
    final scheme = Theme.of(context).colorScheme;
    if (activity == null) return const SizedBox.square(dimension: extent);
    final failed = activity.phase == TagTranslationPhase.failed;
    final label = switch (activity.phase) {
      TagTranslationPhase.queued => context.l10n.wiki_translationQueued,
      TagTranslationPhase.translating => context.l10n.wiki_translating,
      TagTranslationPhase.failed => context.l10n.wiki_translationFailedRetry,
    };
    final message = failed && activity.error?.isNotEmpty == true
        ? '$label\n${activity.error}'
        : label;
    return SizedBox.square(
      dimension: extent,
      child: IconButton(
        key: ValueKey('tag-translation-${wiki ? 'wiki' : 'name'}-$tag'),
        tooltip: message,
        padding: EdgeInsets.zero,
        alignment: Alignment.center,
        iconSize: size,
        visualDensity: VisualDensity.standard,
        constraints: const BoxConstraints.tightFor(
          width: extent,
          height: extent,
        ),
        style: IconButton.styleFrom(
          alignment: Alignment.center,
          minimumSize: const Size.square(extent),
          maximumSize: const Size.square(extent),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: failed
            ? () => activity.wiki
                  ? controller.retranslateWiki(surface: surface, tag: tag)
                  : controller.retranslateName(surface: surface, tag: tag)
            : null,
        icon: Transform.translate(
          offset: Offset(0, MediaQuery.textScalerOf(context).scale(1.5)),
          child: TranslationIcon(
            size: size,
            busy: activity.phase == TagTranslationPhase.translating,
            color: failed
                ? scheme.error
                : activity.phase == TagTranslationPhase.queued
                ? scheme.onSurfaceVariant
                : scheme.primary,
          ),
        ),
      ),
    );
  }
}

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
        : context.l10n.wiki_retranslate;
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
