import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../../core/enums/precise_ref_type.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../../../../core/utils/file_explorer_utils.dart';
import '../../../../../core/utils/image_save_utils.dart';
import '../../../../../core/utils/localization_extension.dart';
import '../../../../../core/utils/nai_resolution_adapter.dart';
import '../../../../../core/utils/prompt_preset_resolution.dart';
import '../../../../../core/utils/vibe_file_parser.dart';
import '../../../../../data/repositories/gallery_folder_repository.dart';
import '../../../../../data/services/alias_resolver_service.dart';
import '../../../../../data/services/image_metadata_service.dart';
import '../../../../providers/generation/preview_selection_provider.dart';
import '../../../../providers/history_click_behavior_provider.dart';
import '../../../../providers/character_prompt_provider.dart';
import '../../../../providers/image_generation_provider.dart';
import '../../../../providers/local_gallery_provider.dart';
import '../../../../providers/quality_preset_provider.dart';
import '../../../../providers/uc_preset_provider.dart';
import '../../../../services/image_workflow_launcher.dart';
import '../../../../widgets/common/app_toast.dart';
import '../../../../widgets/common/image_detail/file_image_detail_data.dart';
import '../../../../widgets/common/image_detail/image_detail_data.dart';
import '../../../../widgets/common/image_detail/image_detail_viewer.dart';
import '../../../../utils/image_detail_opener.dart';
import '../../../prompt_block_library/widgets/prompt_block_edit_dialog.dart';

/// 生成图的可复用操作集合。
///
/// 历史预览卡片与 G11 画布 tile 共用同一套操作：详情页、保存、
/// 发送到图生图/Vibe/精准参考、在资源管理器定位、存入词库等。
/// 全部方法依赖 [WidgetRef] 读取最新状态，不持有 widget 状态。
class GeneratedImageActions {
  const GeneratedImageActions(this.ref);

  final WidgetRef ref;

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

      final seed = await ImageSaveUtils.resolveSeed(
        metadata: image.metadata,
        bytes: image.bytes,
      );

      // 兜底去重：同一 seed 且字节一致的文件今日已存在则直接定位，
      // 不再另存副本（覆盖 filePath 未回写、跨会话等一切缺路径场景）。
      final identicalPath = await ImageSaveUtils.findIdenticalDatedFile(
        rootPath: saveDirPath,
        bytes: image.bytes,
        seed: seed,
      );
      if (identicalPath != null) {
        ref
            .read(imageGenerationNotifierProvider.notifier)
            .updateImageFilePath(image.id, identicalPath);
        await FileExplorerUtils.revealFile(identicalPath);
        return;
      }

      // 原子保存：日期分类路径 + 独占防冲突 + 失败清理，全在工具内完成。
      final filePath = await ImageSaveUtils.saveBytesToDatedPath(
        rootPath: saveDirPath,
        bytes: image.bytes,
        seed: seed,
      );

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
    final params = ref.read(generationParamsNotifierProvider);
    final characterConfig = ref.read(characterPromptNotifierProvider);

    // 使用竖线格式合并正面提示词和角色提示词
    final positivePrompt = params.prompt;
    final enabledCharacters = characterConfig.characters
        .where((c) => c.enabled && c.prompt.isNotEmpty)
        .toList();

    final String combinedPrompt;
    if (enabledCharacters.isEmpty) {
      combinedPrompt = positivePrompt;
    } else {
      // 使用竖线格式：主提示词 | 角色1 | 角色2
      final buffer = StringBuffer(positivePrompt);
      for (final char in enabledCharacters) {
        buffer.write('\n| ${char.prompt}');
      }
      combinedPrompt = buffer.toString();
    }

    // 解析别名引用，保存实际内容到块库
    final aliasResolver = ref.read(aliasResolverServiceProvider.notifier);
    final resolvedPrompt = aliasResolver.resolveAliases(combinedPrompt);

    if (!context.mounted) return;

    await PromptBlockEditDialog.createWithDialog(
      context,
      ref,
      initialContent: resolvedPrompt,
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
    final sequence = linkedSelection
        ? state.detailSequenceFor(selectedImage)
        : state.displayImages;
    if (sequence.isEmpty) return;
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

  /// 获取保存目录
  Future<Directory?> _getSaveDirectory() async {
    final dirPath = await GalleryFolderRepository.instance.getRootPath();
    if (dirPath == null) return null;
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 保存图像（详情页保存回调使用，入参为 ImageDetailData）
  Future<void> saveImage(BuildContext context, ImageDetailData image) async {
    try {
      final imageBytes = await image.getImageBytes();
      final saveDir = await _getSaveDirectory();
      if (saveDir == null) return;

      // 统一解析真实 seed：文件名与元数据嵌入共用同一结果
      final resolvedSeed = await ImageSaveUtils.resolveSeed(
        metadata: image.metadata,
        bytes: imageBytes,
      );
      final params = ref.read(generationParamsNotifierProvider);
      // 最终 seed：解析结果优先，回退当前参数，仍未知道则随机。
      // 在生成文件名之前确定，保证文件名与嵌入元数据完全一致。
      final finalSeed = resolvedSeed ?? params.seed;
      final actualSeed = finalSeed < 0
          ? Random().nextInt(4294967295)
          : finalSeed;

      // 构建最终字节：已有 NAI 元数据则原样保留，否则按当前参数重建
      final Uint8List finalBytes;
      if (ImageSaveUtils.hasEmbeddedNovelAiMetadata(imageBytes)) {
        finalBytes = imageBytes;
      } else {
        final characterConfig = ref.read(characterPromptNotifierProvider);

        // 解析别名
        final aliasResolver = ref.read(aliasResolverServiceProvider.notifier);
        final resolvedPrompt = aliasResolver.resolveAliases(params.prompt);
        final resolvedNegative = aliasResolver.resolveAliases(
          params.negativePrompt,
        );
        final qualityState = ref.read(qualityPresetNotifierProvider);
        final qualityContent = ref
            .read(qualityPresetNotifierProvider.notifier)
            .getEffectiveContent(params.model);
        final ucState = ref.read(ucPresetNotifierProvider);
        final ucPresetContent = ref
            .read(ucPresetNotifierProvider.notifier)
            .getEffectiveContent(params.model);
        final presetResolution = resolvePromptPresetSettings(
          prompt: resolvedPrompt,
          negativePrompt: resolvedNegative,
          qualityMode: qualityState.mode,
          qualityContent: qualityContent,
          ucPresetType: ucState.presetType,
          ucPresetContent: ucPresetContent,
          useCustomUcPreset: ucState.isCustom,
        );

        // 构建 V4 多角色提示词结构（解析别名）
        final charCaptions = <Map<String, dynamic>>[];
        final charNegCaptions = <Map<String, dynamic>>[];

        for (final char in characterConfig.characters.where(
          (c) => c.enabled && c.prompt.isNotEmpty,
        )) {
          charCaptions.add({
            'char_caption': aliasResolver.resolveAliases(char.prompt),
            'centers': [
              {'x': 0.5, 'y': 0.5},
            ],
          });
          charNegCaptions.add({
            'char_caption': aliasResolver.resolveAliases(char.negativePrompt),
            'centers': [
              {'x': 0.5, 'y': 0.5},
            ],
          });
        }

        final encodedSize = NaiResolutionAdapter.readImageSize(imageBytes);
        final paramsForSave = params.copyWith(
          prompt: presetResolution.prompt,
          negativePrompt: presetResolution.negativePrompt,
          qualityToggle: presetResolution.qualityToggle,
          qualityTagPreset: presetResolution.qualityTagPreset,
          ucPreset: presetResolution.ucPreset,
          width: encodedSize?.$1 ?? params.width,
          height: encodedSize?.$2 ?? params.height,
        );
        finalBytes = await ImageSaveUtils.rebuildImageBytesWithMetadata(
          imageBytes: imageBytes,
          params: paramsForSave,
          actualSeed: actualSeed,
          charCaptions: charCaptions,
          charNegCaptions: charNegCaptions,
          useCoords: !characterConfig.globalAiChoice,
        );
      }

      // 原子保存：日期分类路径 + 独占防冲突 + 失败清理，全在工具内完成
      final filePath = await ImageSaveUtils.saveBytesToDatedPath(
        rootPath: saveDir.path,
        bytes: finalBytes,
        seed: actualSeed,
      );

      // 立即解析并缓存刚保存图像的元数据
      unawaited(
        ImageMetadataService()
            .getMetadata(filePath)
            .then((metadata) {
              AppLogger.d(
                '生成图像元数据已缓存: ${metadata?.prompt.substring(0, metadata.prompt.length > 30 ? 30 : metadata.prompt.length)}...',
                'ImagePreview',
              );
            })
            .catchError((e) {
              AppLogger.w('生成图像元数据缓存失败: $e', 'ImagePreview');
            }),
      );

      // 更新保存图像的文件路径到状态
      final currentState = ref.read(imageGenerationNotifierProvider);
      final updatedImages = currentState.displayImages.map((img) {
        if (img.id == image.identifier) {
          return img.copyWithFilePath(filePath);
        }
        return img;
      }).toList();

      if (updatedImages.isNotEmpty) {
        ref
            .read(imageGenerationNotifierProvider.notifier)
            .updateDisplayImages(updatedImages);
      }

      ref.read(localGalleryNotifierProvider.notifier).refresh();

      if (context.mounted) {
        AppToast.success(context, context.l10n.image_imageSaved(saveDir.path));
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, context.l10n.image_saveFailed(e.toString()));
      }
    }
  }
}
