import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../themes/studio_typography.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../actions/explore_display_data.dart';

export '../actions/explore_display_data.dart' show explorePromptMatches;

/// Selection and block highlights are separate from compensated glyph paints.
class ExploreHighlightedPrompt extends ConsumerWidget {
  const ExploreHighlightedPrompt({super.key, required this.snapshot});
  final ExploreRollSnapshot snapshot;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocks = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
    final parts = <InlineSpan>[];
    var cursor = 0;
    for (final match in explorePromptMatches(snapshot)) {
      parts.add(
        TextSpan(text: snapshot.positive.substring(cursor, match.start)),
      );
      final block = blocks?.blockById(match.blockId);
      final ink = block == null
          ? Theme.of(context).colorScheme.primary
          : promptBlockColorFromString(block.color);
      parts.add(
        TextSpan(
          text: snapshot.positive.substring(match.start, match.end),
          style: TextStyle(
            color: ink,
            backgroundColor: ink.withValues(alpha: .18),
          ),
        ),
      );
      cursor = match.end;
    }
    parts.add(TextSpan(text: snapshot.positive.substring(cursor)));
    return SelectableText.rich(
      TextSpan(children: parts),
      style: StudioTypography.body.copyWith(fontSize: 12, height: 1.6),
    );
  }
}
