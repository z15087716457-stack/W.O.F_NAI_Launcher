import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../../core/enums/precise_ref_type.dart';
import '../../../../../core/utils/file_explorer_utils.dart';
import '../../../../../core/utils/localization_extension.dart';
import '../../../../../core/utils/vibe_file_parser.dart';
import '../../../../../data/repositories/gallery_folder_repository.dart';
import '../../../../../data/services/image_metadata_service.dart';
import '../../../../providers/generation/preview_selection_provider.dart';
import '../../../../providers/canvas_settings_provider.dart';
import '../../../../providers/history_click_behavior_provider.dart';
import '../../../../providers/image_generation_provider.dart';
import '../../../../providers/local_gallery_provider.dart';
import '../../../../services/image_workflow_launcher.dart';
import '../../../../widgets/common/app_toast.dart';
import '../../../../widgets/common/themed_confirm_dialog.dart';
import '../../../../widgets/common/image_detail/file_image_detail_data.dart';
import '../../../../widgets/common/image_detail/image_detail_data.dart';
import '../../../../widgets/common/image_detail/image_detail_viewer.dart';
import '../../../../utils/image_detail_opener.dart';
import '../../../prompt_block_library/widgets/prompt_block_edit_dialog.dart';
import '../../services/generation_save_service.dart';

/// 生成图的可复用操作集合。
///
/// 历史预览卡片与 G11 画布 tile 共用同一套操作：详情页、保存、
/// 发送到图生图/Vibe/精准参考、在资源管理器定位、存入词库等。
/// 全部方法依赖 [WidgetRef] 读取最新状态，不持有 widget 状态。
class GeneratedImageActions {
  const GeneratedImageActions(this.ref);

  final WidgetRef ref;

  /// Remove the clicked image from the generation workspace, keeping saved
  /// gallery files. Pin membership is removed too, so a pinned copy cannot
  /// make the deleted image reappear on the canvas.
  Future<void> deleteImage(
    BuildContext context,
    GeneratedImage image, {
    bool confirm = true,
  }) async {
    if (confirm) {
      final confirmed = await ThemedConfirmDialog.show(
        context: context,
        title: context.l10n.common_delete,
        content: context.l10n.generation_deleteSelectedImagesConfirm(1),
        confirmText: context.l10n.common_delete,
        cancelText: context.l10n.common_cancel,
        type: ThemedConfirmDialogType.danger,
        icon: Icons.delete_outline,
      );
      if (!confirmed || !context.mounted) return;
    }
    if (!context.mounted) return;
    try {
      await ref.read(canvasPinnedNotifierProvider.notifier).remove(image.id);
      if (!context.mounted) return;
      ref.read(imageGenerationNotifierProvider.notifier).removeImages({
        image.id,
      });
      if (ref.read(generationPreviewSelectionProvider) == image.id) {
        ref.read(generationPreviewSelectionProvider.notifier).clear();
      }
    } catch (error) {
      if (context.mounted) {
        AppToast.error(
          context,
          context.l10n.bulkProgress_errorDeleteFailed(error.toString()),
        );
      }
    }
  }

  /// 生成图文件名：优先已保存路径的原文件名，否则回退 id 命名。
  String previewImageFileName(GeneratedImage image) {
    final filePath = image.filePath;
    if (filePath != null && filePath.isNotEmpty) {
      return p.basename(filePath);
    }
    return 'generation_${image.id}.png';
  }

  void sendToImageToImage(BuildContext context, GeneratedImage image) {
    ImageWorkflowLauncher.openImageToImage(ref, image.bytes);
    AppToast.success(context, context.l10n.drop_addedToImg2Img);
  }

  Future<void> sendToVibeTransfer(
    BuildContext context,
    GeneratedImage image,
  ) async {
    final l10n = context.l10n;

    try {
      final currentState = ref.read(generationParamsNotifierProvider);
      final currentCount = currentState.vibeReferencesV4.length;
      const maxCount = 16;
      final vibes = await VibeFileParser.parseFile(
        previewImageFileName(image),
        image.bytes,
      );

      if (!context.mounted) return;
      if (currentCount + vibes.length > maxCount) {
        AppToast.warning(context, l10n.toast_styleReferenceLimit(maxCount));
        return;
      }

      ref
          .read(generationParamsNotifierProvider.notifier)
          .addVibeReferences(vibes);

      final message = currentCount > 0
          ? l10n.toast_appendedStyleReferences(vibes.length)
          : vibes.length == 1
          ? l10n.drop_addedToVibe
          : l10n.drop_addedMultipleToVibe(vibes.length);
      AppToast.success(context, message);
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, '${l10n.vibeParseFailed}: $e');
      }
    }
  }

  Future<void> sendToPreciseReference(
    BuildContext context,
    GeneratedImage image,
  ) async {
    final l10n = context.l10n;

    try {
      await ref
          .read(generationParamsNotifierProvider.notifier)
          .addPreciseReferenceFromImage(
            image.bytes,
            type: PreciseRefType.character,
            strength: 1.0,
            fidelity: 1.0,
          );

      if (!context.mounted) return;
      AppToast.success(context, l10n.drop_addedToCharacterRef);
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, l10n.gallery_sendFailed(e.toString()));
      }
    }
  }

  /// 回读状态层中同 id 且已带 filePath 的最新图像对象；没有则返回原对象。
  /// 构建期捕获的 image 可能早于自动保存的 filePath 回写，点击时应以状态为准。
  GeneratedImage freshImageWithPath(GeneratedImage image) {
    final s = ref.read(imageGenerationNotifierProvider);
    for (final list in [s.currentImages, s.history, s.displayImages]) {
      for (final candidate in list) {
        if (candidate.id == image.id &&
            candidate.filePath != null &&
            candidate.filePath!.isNotEmpty) {
          return candidate;
        }
      }
    }
    return image;
  }

  /// 在文件资源管理器中定位图像。已保存的图直接定位原文件，未保存时先保存再定位。
  Future<void> openImageInExplorer(
    BuildContext context,
    GeneratedImage image,
  ) async {
    try {
      final existingPath = freshImageWithPath(image).filePath;
      if (existingPath != null &&
          existingPath.isNotEmpty &&
          await File(existingPath).exists()) {
        await FileExplorerUtils.revealFile(existingPath);
        return;
      }

      final saveDirPath = await GalleryFolderRepository.instance.getRootPath();
      if (saveDirPath == null) return;

      final filePath = await GenerationSaveService.saveToDirectory(
        GeneratedImageDetailData(
          id: image.id,
          imageBytes: image.bytes,
          metadata: image.metadata,
        ),
        rootPath: saveDirPath,
      );
      if (!context.mounted) return;

      // 回写保存路径，后续「打开文件夹」「保存图像」直接复用原文件
      ref
          .read(imageGenerationNotifierProvider.notifier)
          .updateImageFilePath(image.id, filePath);

      ref.read(localGalleryNotifierProvider.notifier).refresh();
      await FileExplorerUtils.revealFile(filePath);

      if (context.mounted) {
        AppToast.success(context, context.l10n.image_imageSaved(saveDirPath));
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, context.l10n.image_saveFailed(e.toString()));
      }
    }
  }

  /// 显示保存到词库对话框
  Future<void> showSaveToLibraryDialog(
    BuildContext context,
    Uint8List bytes,
  ) async {
    final metadata = await ImageMetadataService().getMetadataFromBytes(bytes);
    // Save the clicked image's prompt; a missing PNG prompt stays empty.
    final combinedPrompt = [
      if (metadata?.prompt.isNotEmpty == true) metadata!.prompt,
      for (final prompt in metadata?.characterPrompts ?? const <String>[])
        if (prompt.isNotEmpty) '| $prompt',
    ].join('\n');

    if (!context.mounted) return;

    await PromptBlockEditDialog.createWithDialog(
      context,
      ref,
      initialContent: combinedPrompt,
      initialImageBytes: bytes,
    );
  }

  /// 打开生成图详情页。
  ///
  /// - 历史点击行为为 selectPreview 且当前选中的正是此图时，
  ///   详情序列走 [ImageGenerationState.detailSequenceFor] 联动视图；
  /// - 否则以整个 displayImages 为浏览序列。
  Future<void> showFullscreenImage(
    BuildContext context,
    GeneratedImage selectedImage,
  ) async {
    final state = ref.read(imageGenerationNotifierProvider);
    final linkedSelection =
        ref.read(historyClickBehaviorNotifierProvider) ==
            HistoryClickBehavior.selectPreview &&
        ref.read(generationPreviewSelectionProvider) == selectedImage.id;
    final candidates = linkedSelection
        ? state.detailSequenceFor(selectedImage)
        : state.displayImages;
    final sequence = candidates.any((image) => image.id == selectedImage.id)
        ? candidates
        : [selectedImage, ...candidates];
    final selectedIndex = sequence.indexWhere(
      (image) => image.id == selectedImage.id,
    );
    final initialIndex = selectedIndex < 0 ? 0 : selectedIndex;

    // 简化逻辑：统一使用 FileImageDetailData 从 PNG 文件解析
    // - 已保存的图像直接使用 filePath
    // - 未保存的图像使用 GeneratedImageDetailData 作为 fallback
    final allImages = sequence.map((img) {
      if (img.filePath != null && img.filePath!.isNotEmpty) {
        // 加入预加载队列（如果尚未解析）
        ImageMetadataService().enqueuePreload(
          taskId: img.id,
          filePath: img.filePath,
        );
        return FileImageDetailData(
          filePath: img.filePath!,
          cachedBytes: img.bytes,
          id: img.id,
          initialMetadata: img.metadata,
          showCopyButton: img.canSave,
        );
      }

      // 未保存的图像：使用 GeneratedImageDetailData 作为 fallback
      return GeneratedImageDetailData(
        imageBytes: img.bytes,
        metadata: img.metadata,
        id: img.id,
        showSaveButton: img.canSave,
        showCopyButton: img.canSave,
      );
    }).toList();

    // 使用 ImageDetailOpener 打开详情页
    ImageDetailOpener.showMultipleImmediate(
      context,
      images: allImages,
      initialIndex: initialIndex,
      showMetadataPanel: true,
      showThumbnails: allImages.length > 1,
      callbacks: ImageDetailCallbacks(
        onSave: (image) async {
          if (!image.showSaveButton) return;
          await saveImage(context, image);
        },
      ),
    );
  }

  /// All generation surfaces share metadata-preserving, idempotent saving.
  Future<void> saveImage(BuildContext context, ImageDetailData image) =>
      GenerationSaveService.saveImageFromDetail(context, ref, image);
}
