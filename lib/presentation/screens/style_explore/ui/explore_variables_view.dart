import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/pill_document.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../providers/style_explore/explore_roll_capture.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/pills/prompt_pill.dart';
import 'explore_controls.dart';
import 'explore_icon.dart';
import 'explore_style.dart';
import 'explore_text.dart';

/// The editor lists every enabled random/sequential block; the evolution target
/// is a separate marker and does not determine list visibility.
Iterable<MapEntry<String, PillInstance>> exploreUiRandomInstances(
  PillDocument doc,
) => doc.instances.entries.where(
  (e) => e.value.enabled && e.value.settings.hasRoll,
);

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
    final t = Theme.of(context), c = t.colorScheme, l = context.l10n;
    final target = resolveExploreOverrideMarkerInDocument(positive);
    final variables = [
      for (final lane in [(positive, false), (negative, true)])
        for (final entry in exploreUiRandomInstances(lane.$1))
          (marker: entry.key, instance: entry.value, negative: lane.$2),
    ];
    return ExploreSection(
      key: const Key('explore-random-variables'),
      title: l.styleExplore_variablesTitle,
      count: variables.length,
      leading: ExploreIcon('dice', size: 15, color: ExploreStyle.pink(t)),
      actions: [
        ExploreText(
          l.styleExplore_variablesHint,
          style: TextStyle(fontSize: 12, color: ExploreStyle.faint(t)),
        ),
        Tooltip(
          message: l.styleExplore_variablesExplanation,
          triggerMode: TooltipTriggerMode.tap,
          child: SizedBox.square(
            dimension: 28,
            child: Center(
              child: ExploreIcon('info', size: 15, color: c.onSurfaceVariant),
            ),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (variables.isEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.outlineVariant)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExploreIcon('warn', size: 15, color: c.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ExploreText(
                          l.styleExplore_variablesEmpty,
                          style: TextStyle(
                            fontSize: 12,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ExploreButton(
                    label: l.styleExplore_openBlockLibrary,
                    height: 28,
                    ghost: true,
                    horizontal: 0,
                    fontSize: 12,
                    color: c.primary,
                    onPressed: onOpenLibrary,
                  ),
                ],
              ),
            ),
          for (final variable in variables)
            Builder(
              builder: (context) {
                final block = library?.blockById(variable.instance.blockId);
                final color = block == null
                    ? c.error
                    : promptBlockColorFromString(block.color);
                return Container(
                  key: ValueKey(
                    'explore-variable-${variable.negative ? 'neg' : 'pos'}-${variable.marker}',
                  ),
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.outlineVariant)),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: PromptPill(
                            title: block?.title ?? l.promptBlockPill_missing,
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
                      ExploreText(
                        l.styleExplore_variablePoolSize(
                          block?.atomsOrSplit.length ?? 0,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                      if (variable.negative || variable.marker == target) ...[
                        const SizedBox(width: 6),
                        ExploreText(
                          '· ${variable.negative ? l.styleExplore_variableNegative : l.styleExplore_variableEvolutionTarget}',
                          style: TextStyle(
                            fontSize: 12,
                            color: ExploreStyle.faint(t),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
