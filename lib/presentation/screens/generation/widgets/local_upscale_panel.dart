import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/anlas_calculator.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/upscale/local_upscale_models.dart';
import '../../../../data/services/local_upscale_service.dart';
import '../../../providers/generation/image_workflow_controller.dart';
import '../../../providers/generation/local_upscale_provider.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../widgets/common/editable_double_field.dart';
import '../../settings/sections/local_upscale_settings_section.dart';

class LocalUpscalePanel extends ConsumerWidget {
  const LocalUpscalePanel({
    super.key,
    required this.onCloudStart,
    required this.cloudRunning,
    this.framed = true,
    this.configurationOnly = false,
    this.localOnly = false,
    this.sourceWidth,
    this.sourceHeight,
    this.forGeneration = false,
  });
  final VoidCallback onCloudStart;
  final bool cloudRunning;
  final bool framed;
  final bool configurationOnly;
  final bool localOnly;
  final bool forGeneration;
  final int? sourceWidth;
  final int? sourceHeight;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final workflow = ref.watch(imageWorkflowControllerProvider);
    final controller = ref.read(imageWorkflowControllerProvider.notifier);
    final task = ref.watch(localUpscaleTaskProvider);
    final installing = ref.watch(advancedUpscaleInstallProvider).running;
    final cloud =
        !localOnly && workflow.upscale.backend == UpscaleBackend.novelai;
    final busy =
        workflow.isToolRunning ||
        task.running ||
        cloudRunning ||
        installing ||
        ref.watch(
          imageGenerationNotifierProvider.select((s) => s.isGenerating),
        );
    final hasSource =
        sourceWidth != null ||
        forGeneration ||
        ref.watch(
          generationParamsNotifierProvider.select((p) => p.sourceImage != null),
        );
    final generating = ref.watch(
      imageGenerationNotifierProvider.select(
        (s) => s.status == GenerationStatus.generating,
      ),
    );
    final models = cloud
        ? const AsyncData<List<LocalUpscaleModel>>([])
        : ref.watch(localUpscaleModelsProvider);
    final installed = (models.valueOrNull ?? [])
        .where((m) => m.installed)
        .toList();
    final selected = installed
        .where((m) => m.id == workflow.upscale.localModel)
        .firstOrNull;
    final method =
        advancedUpscaleCatalog
            .where((m) => m.id == workflow.upscale.localModel)
            .firstOrNull
            ?.method ??
        LocalUpscaleMethod.standard;
    final methodModels = installed.where((m) => m.method == method).toList();
    final params = forGeneration
        ? ref.watch(generationParamsNotifierProvider)
        : null;
    final width =
        sourceWidth ??
        params?.width ??
        workflow.sourceImageWidth ??
        workflow.sourceWidth ??
        0;
    final height =
        sourceHeight ??
        params?.height ??
        workflow.sourceImageHeight ??
        workflow.sourceHeight ??
        0;
    final scale = workflow.upscale.localScale;
    final cloudSupported =
        width > 0 &&
        height > 0 &&
        width * height <= ApiConstants.upscaleMaxInputPixels;
    final localSupported =
        width > 0 &&
        height > 0 &&
        selected != null &&
        width *
                height *
                selected.inferenceScale(scale) *
                selected.inferenceScale(scale) <=
            LocalUpscaleService.maxNativeOutputPixels;
    final canStart =
        hasSource &&
        !busy &&
        !generating &&
        (cloud ? cloudSupported : Platform.isWindows && localSupported);
    final progress = task.progress;
    final status = task.cancelling
        ? l.localUpscale_cancelling
        : switch (progress?.phase) {
            LocalUpscalePhase.preparing => l.localUpscale_preparing,
            LocalUpscalePhase.encoding => l.localUpscale_encoding,
            LocalUpscalePhase.inference => l.localUpscale_inference,
            LocalUpscalePhase.decoding => l.localUpscale_decoding,
            LocalUpscalePhase.resizing => l.localUpscale_resizing,
            LocalUpscalePhase.complete => l.localUpscale_complete,
            null => '',
          };
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (framed) ...[
          Text(
            l.image_upscale,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (!localOnly) ...[
          SegmentedButton<UpscaleBackend>(
            segments: [
              ButtonSegment(
                value: UpscaleBackend.local,
                label: Text(l.localUpscale_local),
                icon: const Icon(Icons.computer_outlined, size: 16),
              ),
              const ButtonSegment(
                value: UpscaleBackend.novelai,
                label: Text('NovelAI'),
                icon: Icon(Icons.cloud_outlined, size: 16),
              ),
            ],
            selected: {cloud ? UpscaleBackend.novelai : UpscaleBackend.local},
            showSelectedIcon: false,
            onSelectionChanged: busy
                ? null
                : (value) => controller.updateUpscaleBackend(value.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (cloud) ...[
          Text(
            l.img2img_novelAiCloudUpscale,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (cloudSupported)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.upscale_cloudCost(
                  AnlasCalculator.calculateNovelAiUpscaleCost(
                    inputWidth: width,
                    inputHeight: height,
                  ),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (hasSource && !cloudSupported)
            Text(
              l.img2img_cloudUpscaleSizeLimit,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          if (cloudRunning)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
        ] else ...[
          SegmentedButton<LocalUpscaleMethod>(
            segments: [
              ButtonSegment(
                value: LocalUpscaleMethod.standard,
                label: Text(l.img2img_upscaleRegularModel),
              ),
              const ButtonSegment(
                value: LocalUpscaleMethod.seedvr2,
                label: Text('SeedVR2'),
              ),
              const ButtonSegment(
                value: LocalUpscaleMethod.rtx,
                label: Text('RTX'),
              ),
            ],
            selected: {method},
            showSelectedIcon: false,
            onSelectionChanged: busy
                ? null
                : (values) {
                    final next = values.first;
                    controller.updateLocalUpscaleModel(
                      next == LocalUpscaleMethod.standard
                          ? localUpscaleDefaultModel
                          : advancedUpscaleCatalog
                                .firstWhere((m) => m.method == next)
                                .id,
                    );
                  },
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.img2img_upscaleModel,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => context.go('/settings?section=local-upscale'),
                child: Text(l.localUpscale_manage),
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            key: ValueKey('local-upscale-model-${selected?.id}'),
            initialValue: selected?.id,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            hint: Text(
              method == LocalUpscaleMethod.standard
                  ? l.localUpscale_modelMissing
                  : l.localUpscale_notInstalled,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            items: methodModels
                .map(
                  (model) => DropdownMenuItem(
                    value: model.id,
                    child: Text(
                      localUpscaleModelName(context, model),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: busy
                ? null
                : (id) {
                    if (id != null) controller.updateLocalUpscaleModel(id);
                  },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(l.upscale_scale)),
              EditableDoubleField(
                value: scale,
                min: 1,
                max: 4,
                decimals: 2,
                width: 66,
                enabled: !busy,
                onChanged: controller.updateLocalUpscaleScale,
              ),
              const Text(' ×'),
            ],
          ),
          Slider(
            value: scale,
            min: 1,
            max: 4,
            onChanged: busy ? null : controller.updateLocalUpscaleScale,
          ),
          if (width > 0 && height > 0)
            Text(
              '$width × $height  →  ${(width * scale).round()} × ${(height * scale).round()}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            switch (method) {
              LocalUpscaleMethod.standard => l.localUpscale_description,
              LocalUpscaleMethod.seedvr2 => l.localUpscale_seedvr2Help,
              LocalUpscaleMethod.rtx => l.localUpscale_rtxHelp,
            },
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!Platform.isWindows)
            Text(
              l.localUpscale_unsupportedPlatform,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          if (hasSource && selected != null && !localSupported)
            Text(
              l.localUpscale_sizeLimit,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          if (models.hasError)
            Text(
              localUpscaleErrorText(
                context,
                models.error is LocalUpscaleException
                    ? (models.error as LocalUpscaleException).code
                    : LocalUpscaleError.processFailed,
              ),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          if (task.running) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: task.cancelling ? null : progress?.fraction,
            ),
            const SizedBox(height: 6),
            Text(
              '$status${progress?.fraction != null && progress?.phase == LocalUpscalePhase.inference ? ' ${(progress!.fraction! * 100).floor()}%' : ''}',
              style: theme.textTheme.labelMedium,
            ),
          ],
          if (task.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                localUpscaleErrorText(context, task.error!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: task.error == LocalUpscaleError.cancelled
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.error,
                ),
              ),
            ),
          if (task.completed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.localUpscale_complete,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
        if (!configurationOnly) ...[
          const SizedBox(height: 12),
          if (!cloud && task.running)
            OutlinedButton.icon(
              onPressed: task.cancelling
                  ? null
                  : ref.read(localUpscaleTaskProvider.notifier).cancel,
              icon: const Icon(Icons.stop, size: 20),
              label: Text(
                task.cancelling ? l.localUpscale_cancelling : l.common_cancel,
              ),
            )
          else
            FilledButton.icon(
              onPressed: canStart
                  ? (cloud
                        ? onCloudStart
                        : () => ref
                              .read(localUpscaleTaskProvider.notifier)
                              .start())
                  : null,
              icon: const Icon(Icons.play_arrow, size: 20),
              label: Text(l.img2img_startUpscale),
            ),
        ],
      ],
    );
    if (!framed) return content;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: .4),
        ),
      ),
      child: content,
    );
  }
}
