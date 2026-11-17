import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/autocomplete/completion_models.dart';
import '../../../core/database/dictionary_revision.dart';
import '../../../core/tag_expansion/tag_semantics_repository.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../core/wiki/auto_tag_translation_controller.dart';
import '../../ui/kit/ui_colors.dart';
import '../../ui/kit/ui_text.dart';
import 'tag_category_visuals.dart';

/// A selected tag reads the same local reference as search. The existing
/// visible-tag queue may fill it later; observing its status starts no request.
final tagMeaningProfileProvider = FutureProvider.autoDispose
    .family<TagSemanticProfile?, String>((ref, tag) {
      ref.watch(dictionaryRevisionProvider);
      ref.watch(
        autoTagTranslationProvider.select(
          (queue) => (queue.definitionFor(tag), queue.activityFor(tag)?.phase),
        ),
      );
      return ref.watch(tagSemanticsRepositoryProvider).find(tag);
    });

/// Shared reference text: a sidebar has category and labels; the compact Wiki
/// introduction contains only the summary and synonym text.
class TagMeaning extends ConsumerWidget {
  const TagMeaning({super.key, required this.candidate, this.compact = false});

  final CompletionCandidate candidate;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(tagMeaningProfileProvider(candidate.canonicalTag));
    final profile = result.asData?.value;
    final summary = profile?.summaryZh ?? '';
    final synonyms = profile?.synonymsZh ?? const <String>[];
    if (compact && summary.isEmpty && synonyms.isEmpty) {
      return const SizedBox.shrink();
    }
    final c = context.ui;
    return Padding(
      padding: compact
          ? const EdgeInsets.fromLTRB(12, 0, 12, 10)
          : const EdgeInsets.fromLTRB(14, 13, 14, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: compact ? 5 : 12,
        children: [
          if (!compact)
            Row(
              spacing: 6,
              children: [
                Icon(
                  TagCategoryVisuals.icon(candidate.category),
                  size: 13,
                  color: TagCategoryVisuals.color(context, candidate.category),
                ),
                Flexible(
                  child: Text(
                    TagCategoryVisuals.label(context, candidate.category),
                    style: UiText.sans(11.5, color: c.muted),
                  ),
                ),
              ],
            ),
          if (summary.isNotEmpty || !compact)
            Text(
              summary.isNotEmpty
                  ? summary
                  : result.isLoading
                  ? context.l10n.common_loading
                  : context.l10n.wiki_withoutArticle,
              style: UiText.sans(12, color: c.ink, height: 1.65),
            ),
          if (synonyms.isNotEmpty)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [
                if (!compact)
                  Text(
                    context.l10n.tagMeaning_synonyms,
                    style: UiText.sans(11, color: c.faint),
                  ),
                Text(
                  synonyms.join('、'),
                  style: UiText.sans(11.5, color: c.muted, height: 1.6),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
