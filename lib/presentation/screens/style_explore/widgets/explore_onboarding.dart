import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/layout_state_provider.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../providers/style_explore/explore_roll_capture.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/pills/prompt_pill.dart';
import 'explore_dialog_frame.dart';
import 'explore_icon.dart';

class ExploreOnboarding extends ConsumerWidget {
  const ExploreOnboarding({super.key, this.onGenerate, this.onOpenPrevious});
  final Future<void> Function()? onGenerate;
  final VoidCallback? onOpenPrevious;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
    final blocks = [
      for (final lane in [PillScopes.main, PillScopes.negative])
        for (final e in exploreGeneticInstances(
          ref.watch(pillWorkspaceProvider(lane)).document,
        ))
          if (library?.blockById(e.value.blockId) case final block?) block,
    ];
    return ExploreOnboardingView(
      blocks: blocks,
      count: ref.watch(generationParamsNotifierProvider).nSamples,
      generating:
          ref.watch(imageGenerationNotifierProvider).isGenerating ||
          ref.watch(exploreRunRunnerProvider).isRunning,
      hasPrevious:
          ref
              .watch(exploreRunListNotifierProvider)
              .valueOrNull
              ?.runs
              .isNotEmpty ==
          true,
      onGenerate: onGenerate,
      onOpenPrevious: onOpenPrevious,
      onOpenLibrary: () => ref
          .read(layoutStateNotifierProvider.notifier)
          .setBlockLibraryPanelExpanded(true),
    );
  }
}

class ExploreOnboardingView extends StatelessWidget {
  const ExploreOnboardingView({
    super.key,
    required this.blocks,
    required this.count,
    required this.generating,
    required this.hasPrevious,
    required this.onOpenLibrary,
    this.onGenerate,
    this.onOpenPrevious,
  });
  final List<PromptBlock> blocks;
  final int count;
  final bool generating, hasPrevious;
  final VoidCallback onOpenLibrary;
  final Future<void> Function()? onGenerate;
  final VoidCallback? onOpenPrevious;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme, l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/images/wof_nai_lab.svg',
                  width: 64,
                  semanticsLabel: 'W.O.F NAI LAB',
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.styleExplore_onboardingTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                _step(
                  context,
                  1,
                  l10n.styleExplore_onboardingRandomTitle,
                  l10n.styleExplore_onboardingRandomHint,
                  blocks.isEmpty
                      ? OutlinedButton(
                          key: const Key('explore-onboarding-library'),
                          onPressed: onOpenLibrary,
                          style: ExploreDialogFrame.buttonStyle(context),
                          child: Text(l10n.styleExplore_openBlockLibrary),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final b in blocks)
                              PromptPill(
                                title: b.title,
                                color: promptBlockColorFromString(b.color),
                                appearance: b.appearance,
                                leading: ExploreIcon(
                                  'dice',
                                  size: 12,
                                  color: promptBlockColorFromString(b.color),
                                ),
                              ),
                          ],
                        ),
                  done: blocks.isNotEmpty,
                ),
                const SizedBox(height: 14),
                _step(
                  context,
                  2,
                  l10n.styleExplore_onboardingDrawTitle,
                  l10n.styleExplore_onboardingDrawHint,
                  FilledButton.icon(
                    key: const Key('explore-onboarding-generate'),
                    onPressed: generating || onGenerate == null
                        ? null
                        : onGenerate,
                    style: ExploreDialogFrame.buttonStyle(context).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.disabled)
                            ? colors.surfaceContainerHighest
                            : colors.primary,
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.disabled)
                            ? colors.onSurfaceVariant
                            : colors.onPrimary,
                      ),
                    ),
                    icon: ExploreIcon(
                      'play',
                      size: 13,
                      filled: true,
                      color: generating
                          ? colors.onSurfaceVariant
                          : colors.onPrimary,
                    ),
                    label: Text(l10n.styleExplore_onboardingDraw(count)),
                  ),
                ),
                const SizedBox(height: 14),
                _step(
                  context,
                  3,
                  l10n.styleExplore_onboardingReviewTitle,
                  l10n.styleExplore_onboardingReviewHint,
                  null,
                ),
                if (hasPrevious) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    key: const Key('explore-onboarding-previous'),
                    onPressed: onOpenPrevious,
                    style: ExploreDialogFrame.buttonStyle(context),
                    icon: ExploreIcon(
                      'chevD',
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    label: Text(l10n.styleExplore_onboardingOpenPrevious),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _step(
    BuildContext context,
    int number,
    String title,
    String hint,
    Widget? action, {
    bool done = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: Key('explore-onboarding-step-$number'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? colors.primary : colors.surfaceContainerHighest,
            ),
            child: done
                ? ExploreIcon(
                    'check',
                    size: 15,
                    strokeWidth: 2.6,
                    color: colors.onPrimary,
                  )
                : Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (action != null) ...[const SizedBox(height: 10), action],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
