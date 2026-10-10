import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../providers/cost_estimate_provider.dart';
import '../../../providers/tips_provider.dart';
import '../../../widgets/common/collapsible_image_panel.dart';
import '../../../themes/studio_typography.dart';
import '../../generation/widgets/generation_controls/generation_controls.dart';
import '../../generation/widgets/generation_params_menu_host.dart';
import '../../generation/widgets/header_capsules.dart';
import '../../generation/widgets/img2img_panel.dart';
import '../../generation/widgets/precise_reference_panel.dart';
import '../../generation/widgets/prompt_input.dart';
import '../../generation/widgets/size_selector.dart';
import '../../generation/widgets/unified_reference_panel.dart';
import 'explore_characters.dart';
import 'explore_draw_count.dart';
import 'explore_controls.dart';
import 'explore_icon.dart';
import 'explore_random_variables_module.dart';
import 'explore_text.dart';

class ExploreEditor extends ConsumerWidget {
  const ExploreEditor({
    super.key,
    required this.controller,
    required this.onBatchEvent,
  });
  final GenerationControlsController controller;
  final GenerationBatchCallback onBatchEvent;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(generationParamsNotifierProvider),
        c = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: c.outlineVariant)),
      ),
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 37),
            padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.outlineVariant)),
            ),
            child: const SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 2,
                children: [ModelModeCapsule(), QuotaChipsCapsule()],
              ),
            ),
          ),
          Expanded(
            child: GenerationParamsMenuHost(
              summaryMinWidth: 352,
              summaryBuilder: (context, toggle, arrow) =>
                  ExploreParamsSummary(onToggle: toggle, arrow: arrow),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PromptInputWidget(
                      prototypeExplore: true,
                      autoGrow: true,
                      allowEvolutionToggle: true,
                      tipSurface: TipSurface.explorePrompt,
                    ),
                    const SizedBox(height: 12),
                    const ExploreRandomVariablesModule(),
                    if (ImageModels.isV4Model(params.model)) ...[
                      const SizedBox(height: 12),
                      const ExploreCharacters(),
                    ],
                    const SizedBox(height: 12),
                    ExploreSection(
                      title: context.l10n.generation_sectionReferenceImages,
                      child: const ReferenceModuleScope(
                        prototypeExplore: true,
                        child: Column(
                          children: [
                            Img2ImgPanel(),
                            UnifiedReferencePanel(),
                            PreciseReferencePanel(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ExploreSection(
                      title: context.l10n.generation_moduleImage,
                      child: Column(
                        children: [
                          SizeSelector(
                            width: params.width,
                            height: params.height,
                            layout: SizeSelectorLayout.explorePrototype,
                            onChanged: (width, height) => ref
                                .read(generationParamsNotifierProvider.notifier)
                                .updateSize(width, height),
                          ),
                          ExploreDrawCount(
                            value: params.nSamples,
                            onChanged: (n) => ref
                                .read(generationParamsNotifierProvider.notifier)
                                .updateNSamples(n),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.outlineVariant)),
            ),
            child: GenerationControls(
              controller: controller,
              compact: true,
              exploreMode: true,
              showBalanceChips: false,
              showAutoSaveChip: false,
              onBatchEvent: onBatchEvent,
              presentationBuilder: (context, state) =>
                  ExploreGenerateButton(state: state),
            ),
          ),
        ],
      ),
    );
  }
}

class ExploreGenerateButton extends ConsumerWidget {
  const ExploreGenerateButton({super.key, required this.state});
  final GenerationControlsViewState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).colorScheme, l = context.l10n;
    final cost = state.cost ?? ref.watch(estimatedCostProvider) ?? 0;
    final balance = ref.watch(anlasBalanceProvider),
        insufficient = balance != null && balance < cost;
    final label = state.canCancel
        ? l.styleExplore_stopRun
        : state.busy
        ? l.generation_generating
        : state.cooldown > 0
        ? l.generation_cooldownRemaining(state.cooldown)
        : l.styleExplore_onboardingDraw(state.count);
    return Material(
      key: const Key('explore-generate-button'),
      color: state.canCancel
          ? c.surfaceContainerHighest
          : const Color(0xff005dff),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: state.canCancel
            ? state.onCancel
            : state.busy || state.cooldown > 0
            ? null
            : state.onGenerate,
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 9, 0),
            child: Row(
              children: [
                ExploreIcon(
                  state.canCancel ? 'stop' : 'play',
                  size: 14,
                  filled: true,
                  color: state.canCancel ? c.onSurface : Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ExploreText(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: state.canCancel ? c.onSurface : Colors.white,
                    ),
                  ),
                ),
                if (state.canCancel && state.generation.totalImages > 1)
                  ExploreText(
                    '${state.generation.currentImage} / ${state.generation.totalImages}',
                    style: StudioTypography.data.copyWith(
                      fontSize: 12,
                      color: c.onSurfaceVariant,
                    ),
                  ),
                if (!state.busy)
                  Container(
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: insufficient ? c.error : Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExploreText(
                          '$cost',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: insufficient
                                ? c.onError
                                : const Color(0xff111111),
                          ),
                        ),
                        const SizedBox(width: 3),
                        SvgPicture.asset(
                          'assets/icons/nai-icon-anlas.svg',
                          width: 10,
                          height: 10,
                          colorFilter: ColorFilter.mode(
                            insufficient ? c.onError : const Color(0xff111111),
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExploreParamsSummary extends ConsumerWidget {
  const ExploreParamsSummary({
    super.key,
    required this.onToggle,
    required this.arrow,
  });
  final VoidCallback onToggle;
  final Widget arrow;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(generationParamsNotifierProvider),
        c = Theme.of(context).colorScheme,
        l = context.l10n;
    Widget cell(String label, Widget value, {VoidCallback? onTap}) => InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExploreText(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: c.onSurfaceVariant,
              ),
            ),
            DefaultTextStyle(
              style: StudioTypography.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: c.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: value,
            ),
          ],
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.outlineVariant)),
      ),
      child: Row(
        children: [
          cell(l.generation_stepsLabel, ExploreText('${p.steps}')),
          cell(l.generation_guidance, ExploreText(p.scale.toStringAsFixed(1))),
          cell(
            l.generation_seed,
            p.seed == -1
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExploreIcon('dice', size: 12, color: c.onSurface),
                      const SizedBox(width: 4),
                      ExploreText(l.generation_seedRandom),
                    ],
                  )
                : ExploreText('${p.seed}'),
            onTap: () {
              final n = ref.read(generationParamsNotifierProvider.notifier);
              if (p.seed == -1) {
                n.pinRandomSeed();
              } else {
                n.randomizeSeed();
              }
            },
          ),
          Expanded(
            child: PopupMenuButton<String>(
              tooltip: l.generation_sampler,
              onSelected: (value) => ref
                  .read(generationParamsNotifierProvider.notifier)
                  .updateSampler(value),
              itemBuilder: (_) => [
                for (final value in Samplers.samplersForModel(p.model))
                  PopupMenuItem(
                    value: value,
                    child: ExploreText(
                      Samplers.samplerDisplayNames[value] ?? value,
                    ),
                  ),
              ],
              child: cell(
                l.generation_sampler,
                ExploreText(
                  Samplers.samplerDisplayNames[p.sampler] ?? p.sampler,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: InkWell(
              key: const Key('params-drawer-toggle'),
              onTap: onToggle,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(color: c.outlineVariant),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: arrow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
