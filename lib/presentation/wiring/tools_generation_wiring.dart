import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/anlas_calculator.dart';

import '../../core/constants/model_display.dart';
import '../../core/utils/localization_extension.dart';
import '../../core/utils/max_enhance_utils.dart';
import '../../data/models/upscale/local_upscale_models.dart';
import '../providers/cost_estimate_provider.dart';
import '../providers/generation/cloud_upscale_provider.dart';
import '../providers/generation/image_workflow_controller.dart';
import '../providers/generation/local_upscale_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/subscription_provider.dart';
import '../ui/gen/gen_contract.dart';
import '../ui/tools/tools_contract.dart';
import '../ui/tools/tools_sheets.dart';
import 'generation_operations.dart';

class ToolsSheetSession {
  const ToolsSheetSession(this.sheet, this.image);
  final GenToolSheet sheet;
  final GeneratedImage image;
}

final toolsSheetProvider = StateProvider<ToolsSheetSession?>((ref) => null);
final toolsWindowsProvider = Provider<bool>((ref) => Platform.isWindows);

String toolsUpscaleStatus(LocalUpscaleProgress? progress) {
  final l = currentL10n;
  return switch (progress?.phase) {
    LocalUpscalePhase.preparing => l.localUpscale_preparing,
    LocalUpscalePhase.encoding => l.localUpscale_encoding,
    LocalUpscalePhase.inference => l.localUpscale_inference,
    LocalUpscalePhase.decoding => l.localUpscale_decoding,
    LocalUpscalePhase.resizing => l.localUpscale_resizing,
    LocalUpscalePhase.complete => l.localUpscale_complete,
    null => '',
  };
}

ToolsEnhanceData toolsEnhanceView(Ref ref, GeneratedImage image) {
  final workflow = ref.watch(imageWorkflowControllerProvider);
  final controller = ref.read(imageWorkflowControllerProvider.notifier);
  final draft = ref.watch(generationParamsNotifierProvider);
  final request = ref.watch(generationRequestParamsProvider);
  final settings = workflow.enhance;
  final models = ref.watch(localUpscaleModelsProvider).valueOrNull ?? [];
  final model = models
      .where((m) => m.id == workflow.upscale.localModel)
      .firstOrNull;
  return ToolsEnhanceData(
    sourceWidth: image.width,
    sourceHeight: image.height,
    scales: [
      for (final factor in controller.availableEnhanceFactors)
        ToolsEnhanceScale.factor(factor),
      if (controller.isEnhanceMaxUpscaleEligible) ToolsEnhanceScale.max,
      ToolsEnhanceScale.local,
    ],
    scale: settings.localUpscale
        ? ToolsEnhanceScale.local
        : settings.maxUpscale && controller.isEnhanceMaxUpscaleEligible
        ? ToolsEnhanceScale.max
        : ToolsEnhanceScale.factor(settings.upscaleFactor),
    outWidth: settings.localUpscale
        ? null
        : request.upscaledEnhance
        ? MaxEnhanceMath.targetSize(request.width, request.height).width
        : request.width,
    outHeight: settings.localUpscale
        ? null
        : request.upscaledEnhance
        ? MaxEnhanceMath.targetSize(request.width, request.height).height
        : request.height,
    magnitude: (settings.magnitude * 4).round() + 1,
    strength: request.strength,
    noise: request.noise,
    custom: settings.showIndividualSettings,
    local: ToolsLocalUpscale(
      label: model?.name ?? workflow.upscale.localModel,
      factor: workflow.upscale.localScale,
      ready: ref.watch(toolsWindowsProvider) && model?.installed == true,
    ),
    model: ModelDisplay.shortNameOf(draft.model),
    steps: draft.steps,
    cost: ref.watch(toolsEnhanceCostProvider(image)),
    insufficient: ref.watch(isBalanceInsufficientProvider),
    busy:
        ref.watch(imageGenerationNotifierProvider).isGenerating ||
        workflow.isToolRunning,
  );
}

ToolsUpscaleData toolsUpscaleView(Ref ref, GeneratedImage image) {
  final l = currentL10n;
  final workflow = ref.watch(imageWorkflowControllerProvider);
  final settings = workflow.upscale;
  final models = ref.watch(localUpscaleModelsProvider).valueOrNull ?? [];
  final model = models.where((m) => m.id == settings.localModel).firstOrNull;
  final method = model?.method ?? LocalUpscaleMethod.standard;
  final cloud = settings.backend == UpscaleBackend.novelai;
  final windows = ref.watch(toolsWindowsProvider);
  final install = ref.watch(advancedUpscaleInstallProvider);
  final localTask = ref.watch(localUpscaleTaskProvider);
  final cloudTask = ref.watch(cloudUpscaleTaskProvider);
  final running = localTask.running || cloudTask.running;
  final cloudCost = imageUpscaleCost(ref, image);
  final blocked = install.running
      ? l.localUpscale_busy
      : cloud
      ? cloudCost < 0
            ? l.localUpscale_sizeLimit
            : null
      : !windows
      ? l.localUpscale_unsupportedPlatform
      : model?.installed != true
      ? l.localUpscale_modelMissing
      : null;
  final options = settings.selectedSeedvr2Options;
  ToolsUpscaleField number(
    String id,
    String label,
    double value,
    double max, {
    double min = 0,
    int decimals = 0,
  }) => ToolsUpscaleField(
    id: id,
    label: label,
    kind: ToolsFieldKind.number,
    value: value,
    min: min,
    max: max,
    decimals: decimals,
  );
  return ToolsUpscaleData(
    backends: [
      ToolsUpscaleBackend(
        id: 'local',
        title: l.localUpscale_local,
        detail: l.localUpscale_description,
        enabled: windows,
      ),
      ToolsUpscaleBackend(
        id: 'novelai',
        title: l.img2img_novelAiCloudUpscale,
        detail: l.img2img_novelAiCloudUpscale,
        cost: cloudCost < 0 ? null : cloudCost,
      ),
    ],
    backend: cloud ? 'novelai' : 'local',
    sourceWidth: image.width,
    sourceHeight: image.height,
    methods: cloud
        ? []
        : [
            const ToolsOption(id: 'standard', label: 'NCNN'),
            const ToolsOption(id: 'seedvr2', label: 'SeedVR2'),
            const ToolsOption(id: 'rtx', label: 'RTX Video'),
          ],
    method: cloud ? null : method.name,
    models: cloud || method == LocalUpscaleMethod.rtx
        ? []
        : [
            for (final item in models.where((m) => m.method == method))
              ToolsUpscaleModel(
                id: item.id,
                label: item.name,
                state: install.id == item.id
                    ? ToolsModelState.downloading
                    : item.installed
                    ? ToolsModelState.ready
                    : ToolsModelState.missing,
              ),
          ],
    model: cloud ? null : settings.localModel,
    scale: cloud ? null : settings.localScale,
    minScale: 1,
    maxScale: 4,
    outWidth: (image.width * (cloud ? 2 : settings.localScale)).round(),
    outHeight: (image.height * (cloud ? 2 : settings.localScale)).round(),
    advanced: cloud || method != LocalUpscaleMethod.seedvr2
        ? []
        : [
            ToolsUpscaleField(
              id: 'colorCorrection',
              label: l.localUpscale_seedvr2Color,
              kind: ToolsFieldKind.choice,
              value: options.colorCorrection,
              options: [
                for (final color in Seedvr2Options.colors)
                  ToolsOption(
                    id: color,
                    label: color == 'none' ? l.localUpscale_colorNone : color,
                  ),
              ],
            ),
            number(
              'seed',
              l.localUpscale_seedvr2Seed,
              options.seed.toDouble(),
              4294967295,
            ),
            number(
              'blocksToSwap',
              l.localUpscale_seedvr2Memory,
              options.blocksToSwap.toDouble(),
              Seedvr2Options.maxBlocks(settings.localModel).toDouble(),
            ),
            ToolsUpscaleField(
              id: 'vaeTiled',
              label: l.localUpscale_vaeTiled,
              kind: ToolsFieldKind.toggle,
              value: options.vaeTiled,
            ),
            number(
              'vaeTileSize',
              l.localUpscale_vaeTileSize,
              options.vaeTileSize.toDouble(),
              4096,
              min: 128,
            ),
            number(
              'vaeTileOverlap',
              l.localUpscale_vaeOverlap,
              options.vaeTileOverlap.toDouble(),
              4032,
            ),
            number(
              'inputNoise',
              l.localUpscale_inputNoise,
              options.inputNoise,
              1,
              decimals: 2,
            ),
            number(
              'latentNoise',
              l.localUpscale_latentNoise,
              options.latentNoise,
              1,
              decimals: 2,
            ),
          ],
    cost: cloud && cloudCost >= 0 ? cloudCost : null,
    running: running,
    blocked: blocked,
  );
}

int imageUpscaleCost(Ref ref, GeneratedImage image) =>
    AnlasCalculator.calculateNovelAiUpscaleCost(
      inputWidth: image.width,
      inputHeight: image.height,
    );

class ToolsGenerationSheetWiring extends ConsumerWidget {
  const ToolsGenerationSheetWiring({super.key});

  static Future<void> open(
    WidgetRef ref,
    GenerationOperations operations,
    String id,
    GenToolSheet sheet,
  ) async {
    final image = operations.input(id);
    final previous = ref.read(toolsSheetProvider);
    if (previous?.image.id == id && previous?.sheet == sheet) {
      await close(ref, operations, previous!);
      return;
    }
    await operations.backend.mutate(() {
      operations.workflow.closeTemporaryTool();
      if (sheet == GenToolSheet.enhance) {
        operations.workflow.openTemporaryTool(
          image.bytes,
          ImageWorkflowMode.enhance,
        );
      }
      ref.read(toolsSheetProvider.notifier).state = ToolsSheetSession(
        sheet,
        image,
      );
    }, alive: () => operations.mounted);
  }

  static Future<void> close(
    WidgetRef ref,
    GenerationOperations operations,
    ToolsSheetSession session,
  ) => operations.backend.mutate(() {
    if (!identical(ref.read(toolsSheetProvider), session)) return;
    operations.workflow.closeTemporaryTool();
    ref.read(toolsSheetProvider.notifier).state = null;
  }, alive: () => operations.mounted);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(toolsSheetProvider);
    if (session == null) return const SizedBox.shrink();
    final operations = GenerationOperations(
      ref,
      context,
      () => context.mounted,
    );
    final controller = ref.read(imageWorkflowControllerProvider.notifier);
    bool valid() =>
        context.mounted && identical(ref.read(toolsSheetProvider), session);
    void mutate(void Function() write) =>
        operations.run(() => operations.backend.mutate(write, alive: valid));
    void run() => operations.run(() async {
      if (!valid()) return;
      if (session.sheet == GenToolSheet.enhance) {
        await operations.backend.generate(
          confirm: operations.confirm,
          alive: valid,
          onStarted: () => ref.read(toolsSheetProvider.notifier).state = null,
        );
      } else {
        final data = toolsUpscaleViewForAction(ref, session.image);
        if (data.blocked != null && !data.running) {
          throw StateError(data.blocked!);
        }
        await operations.upscale(
          session.image.id,
          onStarted: () {
            if (valid()) ref.read(toolsSheetProvider.notifier).state = null;
          },
        );
        if (valid()) ref.read(toolsSheetProvider.notifier).state = null;
      }
    });
    if (session.sheet == GenToolSheet.enhance) {
      return ToolsEnhanceSheet(
        data: ref.watch(toolsEnhanceDataProvider(session.image)),
        actions: ToolsEnhanceActions(
          onScale: (value) => mutate(() {
            if (value == ToolsEnhanceScale.local) {
              controller.setEnhanceLocalUpscale();
            } else if (value == ToolsEnhanceScale.max) {
              if (controller.isEnhanceMaxUpscaleEligible) {
                controller.setEnhanceMaxUpscale(true);
              }
            } else {
              final factor = double.tryParse(value);
              if (factor != null) controller.updateEnhanceUpscaleFactor(factor);
            }
          }),
          onMagnitude: (value) => mutate(
            () =>
                controller.updateEnhanceMagnitude((value.clamp(1, 5) - 1) / 4),
          ),
          onCustom: (value) =>
              mutate(() => controller.toggleEnhanceIndividualSettings(value)),
          onStrength: (value) => mutate(
            () => controller.updateEnhanceIndividualSettings(
              strength: value.clamp(0, 1),
            ),
          ),
          onNoise: (value) => mutate(
            () => controller.updateEnhanceIndividualSettings(
              noise: value.clamp(0, 1),
            ),
          ),
          onOpenUpscaleSettings: () => operations.run(
            () => open(ref, operations, session.image.id, GenToolSheet.upscale),
          ),
          onRun: run,
          onClose: () => operations.run(() => close(ref, operations, session)),
        ),
      );
    }
    return ToolsUpscaleSheet(
      data: ref.watch(toolsUpscaleDataProvider(session.image)),
      actions: ToolsUpscaleActions(
        onBackend: (value) => mutate(
          () => controller.updateUpscaleBackend(
            value == 'novelai' ? UpscaleBackend.novelai : UpscaleBackend.local,
          ),
        ),
        onMethod: (value) => mutate(() {
          final method = LocalUpscaleMethod.values
              .where((m) => m.name == value)
              .firstOrNull;
          final models = ref.read(localUpscaleModelsProvider).valueOrNull ?? [];
          final model =
              models
                  .where((m) => m.method == method && m.installed)
                  .firstOrNull ??
              models.where((m) => m.method == method).firstOrNull;
          if (model != null) controller.updateLocalUpscaleModel(model.id);
        }),
        onModel: (value) => mutate(() {
          if (ref
                  .read(localUpscaleModelsProvider)
                  .valueOrNull
                  ?.any((m) => m.id == value) ==
              true) {
            controller.updateLocalUpscaleModel(value);
          }
        }),
        onManageModels: () => context.go('/settings?section=localUpscale'),
        onScale: (value) =>
            mutate(() => controller.updateLocalUpscaleScale(value.clamp(1, 4))),
        onAdvanced: (id, value) => mutate(() {
          final current = ref.read(imageWorkflowControllerProvider).upscale;
          final options = current.selectedSeedvr2Options.toJson();
          if (!options.containsKey(id)) return;
          options[id] = value;
          controller.updateLocalSeedvr2Options(
            Seedvr2Options.fromJson(options, modelId: current.localModel),
          );
        }),
        onRun: run,
        onClose: () => operations.run(() => close(ref, operations, session)),
      ),
    );
  }
}

final toolsEnhanceDataProvider = Provider.autoDispose
    .family<ToolsEnhanceData, GeneratedImage>(toolsEnhanceView);
final toolsEnhanceCostProvider = Provider.autoDispose
    .family<int, GeneratedImage>((ref, image) {
      final workflow = ref.watch(imageWorkflowControllerProvider);
      final draft = ref.watch(generationParamsNotifierProvider);
      final request = workflow.enhance.localUpscale
          ? ref.watch(generationRequestParamsProvider)
          : canvasEnhanceRequest(
              draft,
              workflow.enhance,
              image.bytes,
              image.width,
              image.height,
            );
      return generationRequestCost(
        request,
        workflow.copyWith(mode: ImageWorkflowMode.enhance),
        ref.watch(subscriptionNotifierProvider).subscription,
        ref.watch(imagesPerRequestProvider),
      );
    });
final toolsUpscaleDataProvider = Provider.autoDispose
    .family<ToolsUpscaleData, GeneratedImage>(toolsUpscaleView);

ToolsUpscaleData toolsUpscaleViewForAction(
  WidgetRef ref,
  GeneratedImage image,
) => ref.read(toolsUpscaleDataProvider(image));
