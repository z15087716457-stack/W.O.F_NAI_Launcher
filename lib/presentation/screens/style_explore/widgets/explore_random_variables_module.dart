import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/pill_document.dart';
import '../../../providers/layout_state_provider.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../providers/style_explore/explore_roll_capture.dart';
import '../../../widgets/library/library_status_colors.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/pills/prompt_pill.dart';
import '../../generation/widgets/generation_module_card.dart';
import 'explore_icon.dart';

class ExploreRandomVariablesModule extends ConsumerWidget {
  const ExploreRandomVariablesModule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ExploreRandomVariablesView(
        positive: ref.watch(pillWorkspaceProvider(PillScopes.main)).document,
        negative: ref
            .watch(pillWorkspaceProvider(PillScopes.negative))
            .document,
        library: ref.watch(promptBlockLibraryNotifierProvider).valueOrNull,
        onOpenLibrary: () => ref
            .read(layoutStateNotifierProvider.notifier)
            .toggleBlockLibraryPanel(),
      );
}

/// Reads precisely the same lanes and instance predicate as the roll snapshot.
/// This view never edits a pill, its settings, or the editor document.
class ExploreRandomVariablesView extends StatelessWidget {
  const ExploreRandomVariablesView({
    super.key,
    required this.positive,
    required this.negative,
    required this.library,
    required this.onOpenLibrary,
  });

  final PillDocument positive, negative;
  final PromptBlockLibraryState? library;
  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final target = resolveExploreOverrideMarkerInDocument(positive);
    final variables = [
      for (final lane in [(positive, false), (negative, true)])
        for (final entry in exploreGeneticInstances(lane.$1))
          (marker: entry.key, instance: entry.value, negative: lane.$2),
    ];
    return GenerationModuleCard(
      key: const Key('explore-random-variables'),
      title: l10n.styleExplore_variablesTitle,
      count: variables.length,
      showZeroCount: true,
      headerLeading: ExploreIcon(
        'dice',
        size: 15,
        color: colors.onSurfaceVariant,
      ),
      actions: [
        Text(
          l10n.styleExplore_variablesHint,
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariant.withValues(alpha: .7),
          ),
        ),
        Tooltip(
          message: l10n.styleExplore_variablesExplanation,
          triggerMode: TooltipTriggerMode.tap,
          child: SizedBox.square(
            dimension: 28,
            child: Center(
              child: ExploreIcon(
                'info',
                size: 15,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
      children: variables.isEmpty
          ? [
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.outlineVariant)),
                ),
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExploreIcon(
                          'warn',
                          size: 15,
                          color: LibraryStatusColors(Theme.of(context)).warn,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.styleExplore_variablesEmpty,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: onOpenLibrary,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.styleExplore_openBlockLibrary,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ]
          : [
              for (final variable in variables)
                Builder(
                  builder: (context) {
                    final block = library?.blockById(variable.instance.blockId);
                    final color = block == null
                        ? colors.error
                        : promptBlockColorFromString(block.color);
                    return Container(
                      key: ValueKey(
                        'explore-variable-${variable.negative ? 'neg' : 'pos'}-${variable.marker}',
                      ),
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: colors.outlineVariant),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 1, 8, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: PromptPill(
                                title:
                                    block?.title ??
                                    l10n.promptBlockPill_missing,
                                color: color,
                                appearance: block?.appearance ?? 'classic',
                                variant: block == null
                                    ? PromptPillVariant.missing
                                    : PromptPillVariant.normal,
                                leading: ExploreIcon(
                                  block == null ? 'warn' : 'dice',
                                  size: 12,
                                  color: color,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.styleExplore_variablePoolSize(
                              block?.atomsOrSplit.length ?? 0,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          if (variable.negative ||
                              variable.marker == target) ...[
                            const SizedBox(width: 6),
                            Text(
                              '· ${variable.negative ? l10n.styleExplore_variableNegative : l10n.styleExplore_variableEvolutionTarget}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant.withValues(
                                  alpha: .7,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
            ],
    );
  }
}
