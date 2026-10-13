import 'dart:typed_data';

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../core/utils/inpaint_mask_utils.dart';
import '../../core/utils/localization_extension.dart';
import '../../core/utils/nai_resolution_adapter.dart';
import '../../data/services/image_metadata_service.dart';
import '../providers/generation/image_workflow_controller.dart';
import '../providers/image_generation_provider.dart';
import '../providers/krita/krita_bridge_notifier.dart';
import '../wiring/tools_director_wiring.dart';
import '../wiring/generation_backend.dart';
import '../utils/asset_protection_guard.dart';
import '../utils/official_image_variations.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/image_editor/image_editor_screen.dart';

class ImageWorkflowLauncher {
  const ImageWorkflowLauncher._();

  /// 「生成变体」同动作占位：元数据解析是异步的，解析完成前
  /// `state.isGenerating` 仍为 false，仅靠它挡不住双击；
  /// 占位期间的重复调用直接丢弃，不发生第二次解析/批改。
  static bool _variationsLaunching = false;

  static void openImageToImage(WidgetRef ref, Uint8List imageBytes) {
    final workflowNotifier = ref.read(imageWorkflowControllerProvider.notifier);
    workflowNotifier.replaceSourceImage(imageBytes);
    workflowNotifier.enterBaseMode(clearMask: true);
    workflowNotifier.setPanelExpanded(true);
  }

  static Future<void> openEditor(
    BuildContext context,
    WidgetRef ref,
    Uint8List imageBytes, {
    required ImageEditorMode mode,
    Future<void> Function(void Function())? writeDraft,
  }) async {
    Future<void> apply(void Function() write) async {
      if (writeDraft == null) {
        write();
      } else {
        await writeDraft(write);
      }
    }

    final workflowNotifier = ref.read(imageWorkflowControllerProvider.notifier);

    final params = ref.read(generationParamsNotifierProvider);
    final editingCurrentSource = identical(params.sourceImage, imageBytes);
    final result = await ImageEditorScreen.show(
      context,
      initialImage: imageBytes,
      existingMask: mode == ImageEditorMode.inpaint && editingCurrentSource
          ? params.maskImage
          : null,
      showMaskExport: mode == ImageEditorMode.inpaint,
      mode: mode,
      existingFocusRegion: editingCurrentSource
          ? params.inpaintFocusRegion
          : null,
      title: mode == ImageEditorMode.edit
          ? context.l10n.img2img_editImage
          : context.l10n.img2img_inpaint,
    );

    if (result == null || !context.mounted) {
      return;
    }

    final current = ref.read(generationParamsNotifierProvider);
    if (!identical(current.sourceImage, params.sourceImage) ||
        (editingCurrentSource &&
            (!identical(current.maskImage, params.maskImage) ||
                !identical(
                  current.inpaintFocusRegion,
                  params.inpaintFocusRegion,
                ))) ||
        current.width != params.width ||
        current.height != params.height) {
      AppToast.warning(context, context.l10n.editor_sourceChanged);
      return;
    }

    AppLogger.d(
      'Editor returned: mode=$mode, hasImageChanges=${result.hasImageChanges}, '
          'hasMaskChanges=${result.hasMaskChanges}, '
          'modifiedBytes=${result.modifiedImage?.length ?? 0}, '
          'maskBytes=${result.maskImage?.length ?? 0}, '
          'hasOutpaintChanges=${result.hasOutpaintChanges}, '
          'outpaintSourceBytes=${result.outpaintSourceImage?.length ?? 0}, '
          'outpaintSourceWidth=${result.outpaintSourceWidth}, '
          'outpaintSourceHeight=${result.outpaintSourceHeight}, '
          'inpaintSourceBytes=${result.inpaintSourceImage?.length ?? 0}, '
          'inpaintSourceWidth=${result.inpaintSourceWidth}, '
          'inpaintSourceHeight=${result.inpaintSourceHeight}, '
          'sourceWasNormalized=${result.sourceWasNormalized}, '
          'outputWidth=${result.outputWidth}, '
          'outputHeight=${result.outputHeight}, '
          'compressionApplied=${result.compressionApplied}',
      'ImageWorkflow',
    );

    if (mode == ImageEditorMode.edit) {
      if (result.hasImageChanges && result.modifiedImage != null) {
        await apply(() {
          workflowNotifier.closeTemporaryTool();
          workflowNotifier.enterBaseMode(clearMask: true);
          workflowNotifier.replaceSourceImage(
            result.modifiedImage!,
            sourceWidth: result.outputWidth,
            sourceHeight: result.outputHeight,
            autoAdapt: !result.compressionApplied,
          );
          workflowNotifier.setPanelExpanded(true);
        });
        if (context.mounted) {
          AppToast.success(context, context.l10n.img2img_editApplied);
        }
      }
      return;
    }

    final effectiveMask =
        result.maskImage != null &&
            InpaintMaskUtils.hasMaskedPixels(result.maskImage!)
        ? result.maskImage
        : null;
    await apply(() {
      workflowNotifier.closeTemporaryTool();
      if (!identical(
        ref.read(generationParamsNotifierProvider).sourceImage,
        imageBytes,
      )) {
        workflowNotifier.replaceSourceImage(imageBytes);
      }
      workflowNotifier.applyInpaintEditorResult(
        sourceImage: result.hasOutpaintChanges
            ? result.outpaintSourceImage
            : result.inpaintSourceImage,
        sourceWidth: result.hasOutpaintChanges
            ? result.outpaintSourceWidth
            : result.inpaintSourceWidth,
        sourceHeight: result.hasOutpaintChanges
            ? result.outpaintSourceHeight
            : result.inpaintSourceHeight,
        maskImage: effectiveMask,
        focusRegion: result.inpaintFocusRegion,
        sourceIsOutpaint: result.hasOutpaintChanges,
        useExactSourceDimensions: result.compressionApplied,
      );
      if (result.inpaintStrength != null) {
        ref
            .read(generationParamsNotifierProvider.notifier)
            .updateInpaintStrength(result.inpaintStrength!);
      }
    });
    if (!context.mounted) return;
    if (result.generateAfterApply) {
      await ref
          .read(generationBackendProvider)
          .generate(
            confirm: (cost) => AssetProtectionGuard.confirmHighAnlasCost(
              context: context,
              ref: ref,
              cost: cost,
            ),
            alive: () => context.mounted,
          );
      if (!context.mounted) return;
    }
    if (effectiveMask != null) {
      AppToast.success(context, context.l10n.img2img_inpaintMaskReady);
    } else if (result.maskImage != null) {
      AppToast.warning(context, context.l10n.toast_noValidMaskIgnored);
    }
  }

  static void openEnhance(WidgetRef ref, Uint8List imageBytes) {
    final workflowNotifier = ref.read(imageWorkflowControllerProvider.notifier);
    workflowNotifier.openTemporaryTool(
      imageBytes,
      ImageWorkflowMode.enhance,
      enhanceUsesGenerationSize: true,
    );
  }

  static Future<void> openInpaint(
    BuildContext context,
    WidgetRef ref,
    Uint8List imageBytes,
  ) async {
    await openEditor(context, ref, imageBytes, mode: ImageEditorMode.inpaint);
  }

  /// 打开图生图「超分」子面板（内嵌，非弹窗）
  static void openUpscale(WidgetRef ref, Uint8List imageBytes) {
    final workflowNotifier = ref.read(imageWorkflowControllerProvider.notifier);
    workflowNotifier.openTemporaryTool(imageBytes, ImageWorkflowMode.upscale);
  }

  static Future<void> openDirectorTools(
    BuildContext context,
    WidgetRef ref,
    Uint8List imageBytes, {
    Future<void> Function(void Function())? writeDraft,
  }) async {
    final result = await ToolsDirectorWiring.show(
      context,
      sourceImage: imageBytes,
      writeDraft: writeDraft,
    );
    if (result != null && context.mounted) {
      final workflowNotifier = ref.read(
        imageWorkflowControllerProvider.notifier,
      );
      void apply() {
        workflowNotifier.replaceSourceImage(result);
        workflowNotifier.setPanelExpanded(true);
      }

      if (writeDraft == null) {
        apply();
      } else {
        await writeDraft(apply);
      }
      if (context.mounted) {
        AppToast.success(context, context.l10n.img2img_directorApplied);
      }
    }
  }

  static Future<void> generateVariations(
    BuildContext context,
    WidgetRef ref,
    Uint8List imageBytes, {
    GeneratedImage? sourceImage,
    Future<void> Function()? beforeSubmit,
  }) async {
    if (_variationsLaunching || !context.mounted) {
      return;
    }
    _variationsLaunching = true;
    try {
      // 所有闸门必须先于任何工作流/参数改动：
      // 被拦截的动作不得修改用户当前草稿与画布状态。
      if (_isVariationLaunchBlocked(context, ref)) {
        return;
      }

      // 先解析元数据再动笔；解析期间闸门状态可能翻转，await 后必须复核。
      final metadata =
          await ImageMetadataService().getMetadataFromBytes(imageBytes) ??
          sourceImage?.metadata;
      if (!context.mounted || _isVariationLaunchBlocked(context, ref)) {
        return;
      }

      final size = NaiResolutionAdapter.readImageSize(imageBytes);
      final current = ref.read(generationParamsNotifierProvider);
      final width =
          size?.$1 ?? sourceImage?.width ?? metadata?.width ?? current.width;
      final height =
          size?.$2 ?? sourceImage?.height ?? metadata?.height ?? current.height;
      if (!OfficialImageVariations.supportsSize(width, height)) {
        AppToast.warning(
          context,
          context.l10n.generation_variationSizeUnsupported,
        );
        return;
      }
      final generation = ref.read(imageGenerationNotifierProvider.notifier);
      final params = OfficialImageVariations.project(
        current: metadata?.hasData == true
            ? current
            : generation.preparePromptParams(current),
        source: imageBytes,
        width: width,
        height: height,
        metadata: metadata,
      );
      await beforeSubmit?.call();
      if (!context.mounted || _isVariationLaunchBlocked(context, ref)) return;
      final original = GeneratedImage.create(
        imageBytes,
        width: width,
        height: height,
        metadata: metadata,
        isVariationOriginal: true,
      );
      AppToast.info(context, context.l10n.img2img_variationsStarted);
      await generation.generateOfficialVariations(params, original: original);
    } catch (error) {
      AppLogger.w('Variation preparation failed: $error', 'ImageWorkflow');
      if (context.mounted) {
        AppToast.error(
          context,
          context.l10n.toast_processImageFailed(error.toString()),
        );
      }
    } finally {
      _variationsLaunching = false;
    }
  }

  /// 变体生成的统一闸门：启动器在途生成、Krita 桥接占用、冷却期
  /// 任一命中即拦截并提示。返回 true 表示本次动作被拒绝。
  static bool _isVariationLaunchBlocked(BuildContext context, WidgetRef ref) {
    if (ref.read(imageGenerationNotifierProvider).isGenerating) {
      AppToast.info(context, context.l10n.generation_generating);
      return true;
    }
    if (ref.read(kritaBridgeNotifierProvider).isBridgeGenerating) {
      AppToast.warning(context, context.l10n.toast_kritaBusy);
      return true;
    }
    final cooldownState = ref.read(generationCooldownProvider);
    if (cooldownState.isActive) {
      AppToast.info(
        context,
        context.l10n.generation_cooldownRemaining(
          cooldownState.remainingSeconds,
        ),
      );
      return true;
    }
    return false;
  }
}
