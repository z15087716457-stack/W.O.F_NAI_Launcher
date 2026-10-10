import 'dart:math' as math;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/layout_state_provider.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/pills/prompt_pill.dart';
import 'explore_controls.dart';
import 'explore_icon.dart';
import 'explore_style.dart';
import 'explore_text.dart';
import 'explore_variables_view.dart' show exploreUiRandomInstances;

class ExploreOnboarding extends ConsumerWidget {
  const ExploreOnboarding({super.key, this.onGenerate, this.onOpenPrevious});
  final Future<void> Function()? onGenerate;
  final VoidCallback? onOpenPrevious;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
    final blocks = [
      for (final lane in [PillScopes.main, PillScopes.negative])
        for (final e in exploreUiRandomInstances(
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
          onOpenPrevious != null ||
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
    final theme = Theme.of(context), c = theme.colorScheme, l = context.l10n;
    final steps = [
      _Step(
        number: 1,
        title: l.styleExplore_onboardingRandomTitle,
        description: l.styleExplore_onboardingRandomDescription,
        illustration: blocks.isEmpty
            ? ExploreButton(
                key: const Key('explore-onboarding-library'),
                label: l.styleExplore_openBlockLibrary,
                color: c.primary,
                onPressed: onOpenLibrary,
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final b in blocks.take(2)) ...[
                      PromptPill(
                        title: b.title,
                        color: promptBlockColorFromString(b.color),
                        appearance: b.appearance,
                        leading: ExploreIcon(
                          'dice',
                          size: 12,
                          color: promptBlockColorFromString(b.color),
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExploreIcon(
                          'check',
                          size: 13,
                          strokeWidth: 2.6,
                          color: ExploreStyle.ok(theme),
                        ),
                        const SizedBox(width: 5),
                        ExploreText(
                          l.styleExplore_onboardingDetected(blocks.length),
                          style: TextStyle(
                            fontSize: 12,
                            color: ExploreStyle.ok(theme),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
      _Step(
        number: 2,
        title: l.styleExplore_onboardingDrawTitle,
        description: l.styleExplore_onboardingDrawDescription(count),
        illustration: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final entry in [('c01', -6.0), ('c04', 2.0), ('c12', 7.0)])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Transform.rotate(
                    angle: entry.$2 * math.pi / 180,
                    child: Container(
                      width: 62,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: theme.brightness == Brightness.dark
                                  ? .4
                                  : .14,
                            ),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/images/explore-example-${entry.$1}.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      _Step(
        number: 3,
        title: l.styleExplore_onboardingReviewTitle,
        description: l.styleExplore_onboardingReviewDescription,
        illustration: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExploreIcon(
              'heart',
              size: 28,
              filled: true,
              color: ExploreStyle.heart(theme),
            ),
            const SizedBox(width: 8),
            ExploreIcon('arrR', size: 18, color: ExploreStyle.faint(theme)),
            const SizedBox(width: 8),
            ExploreIcon('evo', size: 30, color: ExploreStyle.evolution(theme)),
            const SizedBox(width: 8),
            ExploreIcon('arrR', size: 18, color: ExploreStyle.faint(theme)),
            const SizedBox(width: 8),
            ExploreIcon('box', size: 28, color: c.onSurfaceVariant),
          ],
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 40,
              horizontal: constraints.maxWidth >= 700 ? 70 : 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: theme.brightness == Brightness.dark ? .85 : .9,
                  child: SvgPicture.asset(
                    'assets/images/wof_nai_lab.svg',
                    width: 230,
                    semanticsLabel: 'W.O.F NAI LAB',
                    colorFilter: theme.brightness == Brightness.dark
                        ? const ColorFilter.matrix([
                            -1,
                            0,
                            0,
                            0,
                            255,
                            0,
                            -1,
                            0,
                            0,
                            255,
                            0,
                            0,
                            -1,
                            0,
                            255,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ])
                        : null,
                  ),
                ),
                const SizedBox(height: 26),
                ExploreText(
                  l.styleExplore_onboardingTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                ExploreText(
                  l.styleExplore_onboardingSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: c.onSurfaceVariant),
                ),
                const SizedBox(height: 26),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: constraints.maxWidth >= 700
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < steps.length; i++) ...[
                                if (i > 0) const SizedBox(width: 14),
                                Expanded(child: steps[i]),
                              ],
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < steps.length; i++) ...[
                              if (i > 0) const SizedBox(height: 14),
                              steps[i],
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 26),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton(
                      key: const Key('explore-onboarding-generate'),
                      onPressed: generating || onGenerate == null
                          ? null
                          : onGenerate,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.standard,
                        backgroundColor: const Color(0xff005dff),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ExploreIcon(
                            'play',
                            size: 13,
                            filled: true,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          ExploreText(l.styleExplore_onboardingDraw(count)),
                        ],
                      ),
                    ),
                    if (hasPrevious)
                      ExploreButton(
                        key: const Key('explore-onboarding-previous'),
                        label: l.styleExplore_onboardingOpenPrevious,
                        height: 36,
                        radius: 8,
                        fontSize: 13.5,
                        horizontal: 14,
                        trailing: ExploreIcon(
                          'chevD',
                          size: 14,
                          color: c.onSurface,
                        ),
                        onPressed: onOpenPrevious,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.description,
    required this.illustration,
  });
  final int number;
  final String title, description;
  final Widget illustration;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      key: Key('explore-onboarding-step-$number'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ExploreStyle.raised(Theme.of(context)),
        border: Border.all(color: c.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.onSurface,
                ),
                child: ExploreText(
                  '$number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.surface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ExploreText(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: ExploreText(
              description,
              style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 150,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: ExploreStyle.panel(Theme.of(context)),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: illustration,
          ),
        ],
      ),
    );
  }
}
