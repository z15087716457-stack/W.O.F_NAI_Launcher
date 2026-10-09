import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';

List<({int start, int end, String blockId})> explorePromptMatches(
  ExploreRollSnapshot snapshot,
) {
  final matches = <({int start, int end, String blockId})>[];
  for (final roll in snapshot.instanceRolls.where(
    (r) => r.lane == 'pos' && r.rolledText.isNotEmpty,
  )) {
    var from = 0;
    while (from < snapshot.positive.length) {
      final start = snapshot.positive.indexOf(roll.rolledText, from);
      if (start < 0) break;
      matches.add((
        start: start,
        end: start + roll.rolledText.length,
        blockId: roll.blockId,
      ));
      from = start + roll.rolledText.length;
    }
  }
  matches.sort((a, b) => a.start.compareTo(b.start));
  final kept = <({int start, int end, String blockId})>[];
  for (final match in matches) {
    if (kept.isEmpty || match.start >= kept.last.end) kept.add(match);
  }
  return kept;
}

class ExploreHighlightedPrompt extends ConsumerWidget {
  const ExploreHighlightedPrompt({super.key, required this.snapshot});
  final ExploreRollSnapshot snapshot;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
    final spans = <TextSpan>[];
    var from = 0;
    for (final match in explorePromptMatches(snapshot)) {
      if (match.start > from) {
        spans.add(
          TextSpan(text: snapshot.positive.substring(from, match.start)),
        );
      }
      final block = library?.blockById(match.blockId);
      final color = block == null
          ? Theme.of(context).colorScheme.primary
          : promptBlockColorFromString(block.color);
      spans.add(
        TextSpan(
          text: snapshot.positive.substring(match.start, match.end),
          style: TextStyle(
            color: color,
            backgroundColor: color.withValues(alpha: .18),
          ),
        ),
      );
      from = match.end;
    }
    if (from < snapshot.positive.length) {
      spans.add(TextSpan(text: snapshot.positive.substring(from)));
    }
    return SelectableText.rich(
      TextSpan(children: spans),
      style: const TextStyle(fontSize: 12),
    );
  }
}
