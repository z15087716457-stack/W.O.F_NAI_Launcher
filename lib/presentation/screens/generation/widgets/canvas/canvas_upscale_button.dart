import 'dart:async';
import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/services/anlas_calculator.dart';
import '../../../../../core/utils/localization_extension.dart';
import '../../../../providers/generation/cloud_upscale_provider.dart';
import '../../../../providers/generation/image_workflow_controller.dart';
import '../../../../providers/generation/local_upscale_provider.dart';
import '../../../../providers/image_generation_provider.dart';
import '../../../../widgets/common/app_toast.dart';
import '../../../../widgets/common/hinted_scroll_view.dart';
import '../generation_sidebar_style.dart';
import '../local_upscale_panel.dart';
import '../../../settings/sections/local_upscale_settings_section.dart';

/// Execute the remembered scheme with the main action; the arrow only edits
/// settings. Neither action replaces the user's img2img source.
class CanvasUpscaleButton extends ConsumerWidget {
  const CanvasUpscaleButton({super.key, required this.image});
  final GeneratedImage image;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final workflow = ref.watch(imageWorkflowControllerProvider);
    final local = ref.watch(localUpscaleTaskProvider);
    final cloud = ref.watch(cloudUpscaleTaskProvider);
    final generating = ref.watch(
      imageGenerationNotifierProvider.select((s) => s.isGenerating),
    );
    final isCloud = workflow.upscale.backend == UpscaleBackend.novelai;
    final cost = isCloud
        ? AnlasCalculator.calculateNovelAiUpscaleCost(
            inputWidth: image.width,
            inputHeight: image.height,
          )
        : 0;
    final running = local.running || cloud.running;
    final models = isCloud
        ? null
        : ref.watch(localUpscaleModelsProvider).valueOrNull;
    final supported = isCloud
        ? cost >= 0
        : Platform.isWindows &&
              (models?.any(
                    (model) =>
                        model.installed &&
                        model.id == workflow.upscale.localModel,
                  ) ??
                  false);
    final locked =
        generating || ref.watch(advancedUpscaleInstallProvider).running;
    final enabled =
        !locked &&
        image.canUseAsGenerationInput &&
        (running || (!workflow.isToolRunning && supported));
    final color = theme.colorScheme.onSurface.withValues(
      alpha: enabled ? 1 : .35,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: running ? l.common_cancel : l.image_upscale,
          child: InkWell(
            key: const Key('canvas-upscale-execute'),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(6),
            ),
            onTap: !enabled
                ? null
                : () {
                    if (local.running) {
                      ref.read(localUpscaleTaskProvider.notifier).cancel();
                      return;
                    }
                    if (cloud.running) {
                      ref.read(cloudUpscaleTaskProvider.notifier).cancel();
                      return;
                    }
                    unawaited(_run(context, ref));
                  },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(7, 7, 4, 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (running)
                    Icon(Icons.stop, size: 16, color: color)
                  else
                    SvgPicture.asset(
                      'assets/icons/nai-icon-upscale.svg',
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                    ),
                  const SizedBox(width: 4),
                  Ink(
                    key: ValueKey(
                      cost >= 0
                          ? 'canvas-cost-nai-icon-upscale.svg'
                          : 'canvas-upscale-inset',
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: .6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cost >= 0 ? '$cost' : '—',
                          key: isCloud
                              ? null
                              : const Key('canvas-upscale-local-cost'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: color,
                          ),
                        ),
                        if (cost >= 0) ...[
                          const SizedBox(width: 3),
                          SvgPicture.asset(
                            'assets/icons/nai-icon-anlas.svg',
                            width: 12,
                            height: 12,
                            colorFilter: ColorFilter.mode(
                              color,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: 1,
          height: 16,
          color: theme.dividerColor.withValues(alpha: .5),
        ),
        MenuAnchor(
          consumeOutsideTap: true,
          alignmentOffset: const Offset(0, 6),
          style: MenuStyle(
            alignment: AlignmentDirectional.bottomEnd,
            backgroundColor: WidgetStatePropertyAll(
              GenSidebarStyle.panelSurface(theme),
            ),
            padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: GenSidebarStyle.border(theme)),
              ),
            ),
          ),
          builder: (context, menu, child) => Tooltip(
            message: l.upscale_settings,
            child: InkWell(
              key: const Key('canvas-upscale-settings'),
              onTap: locked || workflow.isToolRunning
                  ? null
                  : () => menu.isOpen ? menu.close() : menu.open(),
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(6),
              ),
              child: SizedBox(
                width: 18,
                height: 36,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(
                    alpha: locked ? .35 : 1,
                  ),
                ),
              ),
            ),
          ),
          menuChildren: [
            SizedBox(
              key: const Key('canvas-upscale-popover'),
              width: math.min(320, MediaQuery.sizeOf(context).width - 48),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: math.max(
                    160,
                    math.min(520, MediaQuery.sizeOf(context).height - 140),
                  ),
                ),
                child: HintedScrollView(
                  child: LocalUpscalePanel(
                    onCloudStart: () {},
                    cloudRunning: cloud.running,
                    framed: false,
                    configurationOnly: true,
                    sourceWidth: image.width,
                    sourceHeight: image.height,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref) async {
    final backend = ref.read(imageWorkflowControllerProvider).upscale.backend;
    if (backend == UpscaleBackend.novelai) {
      await ref.read(cloudUpscaleTaskProvider.notifier).start(image: image);
      if (!context.mounted) return;
      final error = ref.read(cloudUpscaleTaskProvider).error;
      if (error != null) AppToast.error(context, error);
    } else {
      await ref.read(localUpscaleTaskProvider.notifier).start(image: image);
      if (!context.mounted) return;
      final error = ref.read(localUpscaleTaskProvider).error;
      if (error != null) {
        AppToast.error(context, localUpscaleErrorText(context, error));
      }
    }
  }
}
