import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../providers/generation/image_workflow_controller.dart';
import '../../../providers/image_generation_provider.dart';
import 'img2img_panel.dart';
import 'generation_sidebar_style.dart';
import 'local_upscale_panel.dart';

/// Screen-space tool controls leave the image and camera free to move.
class GenerationToolPanel extends ConsumerWidget {
  const GenerationToolPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSource = ref.watch(
      generationParamsNotifierProvider.select((p) => p.sourceImage != null),
    );
    final workflow = ref.watch(imageWorkflowControllerProvider);
    if (!hasSource && workflow.temporaryEnhanceSource == null) {
      return const SizedBox.shrink();
    }
    if (!workflow.isEnhance && !workflow.isUpscale) {
      return const SizedBox.shrink();
    }
    final controller = ref.read(imageWorkflowControllerProvider.notifier);
    final busy =
        workflow.isToolRunning ||
        ref.watch(
          imageGenerationNotifierProvider.select((s) => s.isGenerating),
        );
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              60,
              12,
              constraints.maxHeight > 360 ? 60 : 8,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: workflow.isEnhance ? 520 : 540,
                maxHeight: (constraints.maxHeight - 128).clamp(120, 640),
              ),
              child: Material(
                key: const Key('generation-tool-surface'),
                color: GenSidebarStyle.panelSurface(theme),
                elevation: 8,
                shadowColor: Colors.black45,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: GenSidebarStyle.border(theme)),
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  primary: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              workflow.isEnhance
                                  ? Icons.auto_awesome
                                  : Icons.photo_size_select_large,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                workflow.isEnhance
                                    ? context.l10n.img2img_enhance
                                    : context.l10n.image_upscale,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: context.l10n.common_close,
                              onPressed: busy
                                  ? null
                                  : controller.closeTemporaryTool,
                              constraints: const BoxConstraints.tightFor(
                                width: 28,
                                height: 28,
                              ),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close, size: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (workflow.isEnhance)
                          AbsorbPointer(
                            absorbing: busy,
                            child: _enhance(context, controller, workflow),
                          )
                        else
                          AbsorbPointer(
                            absorbing: busy,
                            child: const Img2ImgPanel(toolOnly: true),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _enhance(
    BuildContext context,
    ImageWorkflowController controller,
    ImageWorkflowState state,
  ) {
    final settings = state.enhance;
    final magnitude = (settings.magnitude * 4).round() + 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleOptions = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.img2img_enhanceUpscaleAmount,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: GenSidebarStyle.border(Theme.of(context)),
                ),
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final factor in controller.availableEnhanceFactors)
                    _option(
                      context,
                      '${factor == factor.roundToDouble() ? factor.toInt() : factor}x',
                      !settings.localUpscale &&
                          !settings.maxUpscale &&
                          settings.upscaleFactor == factor,
                      () => controller.updateEnhanceUpscaleFactor(factor),
                    ),
                  if (controller.isEnhanceMaxUpscaleEligible)
                    _option(
                      context,
                      context.l10n.img2img_enhanceMax,
                      settings.maxUpscale && !settings.localUpscale,
                      () => controller.setEnhanceMaxUpscale(true),
                    ),
                  _option(
                    context,
                    context.l10n.localUpscale_local,
                    settings.localUpscale,
                    controller.setEnhanceLocalUpscale,
                  ),
                ],
              ),
            ),
          ],
        );
        final parameters = settings.localUpscale
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.enhance_localAfterGeneration,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  LocalUpscalePanel(
                    onCloudStart: () {},
                    cloudRunning: false,
                    framed: false,
                    configurationOnly: true,
                    localOnly: true,
                    forGeneration: true,
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (settings.showIndividualSettings) ...[
                    _slider(
                      context,
                      context.l10n.img2img_strength,
                      settings.strength.clamp(.01, .99),
                      (v) => controller.updateEnhanceIndividualSettings(
                        strength: v,
                      ),
                      min: .01,
                      max: .99,
                      divisions: 98,
                    ),
                    _slider(
                      context,
                      context.l10n.img2img_noise,
                      settings.noise.clamp(0, .99),
                      (v) =>
                          controller.updateEnhanceIndividualSettings(noise: v),
                      max: .99,
                      divisions: 99,
                    ),
                  ] else
                    _slider(
                      context,
                      context.l10n.img2img_enhanceMagnitude,
                      magnitude.toDouble(),
                      (v) => controller.updateEnhanceMagnitude((v - 1) / 4),
                      min: 1,
                      max: 5,
                      divisions: 4,
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () =>
                          controller.toggleEnhanceIndividualSettings(
                            !settings.showIndividualSettings,
                          ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 24),
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant,
                        textStyle: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(fontSize: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        settings.showIndividualSettings
                            ? context.l10n.img2img_hideAdvanced
                            : context.l10n.img2img_showAdvanced,
                      ),
                    ),
                  ),
                ],
              );
        if (constraints.maxWidth < (settings.localUpscale ? 480 : 350)) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [scaleOptions, const SizedBox(height: 12), parameters],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: constraints.maxWidth * .34, child: scaleOptions),
            const SizedBox(width: 20),
            Expanded(child: parameters),
          ],
        );
      },
    );
  }

  Widget _option(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback action,
  ) => Material(
    color: selected
        ? GenSidebarStyle.selectedSurface(Theme.of(context))
        : Colors.transparent,
    borderRadius: BorderRadius.circular(3),
    child: InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );

  Widget _slider(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> change, {
    double min = 0,
    double max = 1,
    int divisions = 100,
  }) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            max > 1 ? value.toInt().toString() : value.toStringAsFixed(2),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      SizedBox(
        height: 26,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: change,
          ),
        ),
      ),
    ],
  );
}
