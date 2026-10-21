import 'dart:convert';
import 'dart:io';

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/image_save_utils.dart';
import '../../../../data/models/gallery/nai_image_metadata.dart';
import '../../../../data/repositories/gallery_folder_repository.dart';
import '../../../../data/services/image_metadata_service.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/local_gallery_provider.dart';
import '../../../utils/image_viewer_opener.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/image_detail/file_image_detail_data.dart';
import '../../../widgets/common/image_detail/image_detail_data.dart';
import '../../../utils/image_viewer_callbacks.dart';

/// 图像保存服务类
///
/// 负责处理图像保存、全屏预览等功能
/// 从生成页桌面布局中提取，减少文件职责
class GenerationSaveService {
  GenerationSaveService._();

  /// 显示全屏预览
  ///
  /// 简化逻辑：统一使用 FileImageDetailData 从 PNG 文件解析元数据
  /// - 如果图像已保存（有 filePath），直接使用
  /// - 如果图像未保存，先保存到磁盘再使用
  /// - 元数据异步加载，详情页先显示，解析中显示转圈
  static void showFullscreenPreview(
    BuildContext context,
    WidgetRef ref,
    List<GeneratedImage> images,
  ) {
    // 立即构建基础数据（使用 FileImageDetailData 从文件解析）
    final allImages = images.map((img) {
      // 如果图像已保存，直接使用 filePath
      // 如果未保存，使用临时字节（这种情况在 auto-save 开启时应该很少）
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
      // 这种情况只应在 auto-save 关闭且用户未手动保存时发生
      return GeneratedImageDetailData(
        imageBytes: img.bytes,
        metadata: img.metadata,
        id: img.id,
        showSaveButton: img.canSave,
        showCopyButton: img.canSave,
      );
    }).toList();

    // 使用 ImageDetailOpener 打开详情页（带防重复点击）
    // 使用 'generation_desktop' key 避免与本地图库的 'default' key 冲突
    ImageViewerOpener.showMultipleImmediate(
      context,
      images: allImages,
      initialIndex: 0,
      showMetadataPanel: true,
      showThumbnails: allImages.length > 1,
      callbacks: ImageViewerCallbacks(
        onSave: (image) async {
          if (!image.showSaveButton) return;
          await saveImageFromDetail(context, ref, image);
        },
      ),
    );
  }

  /// 从详情页保存图像
  ///
  /// 使用 [ImageSaveUtils] 确保元数据完整嵌入
  static Future<void> saveImageFromDetail(
    BuildContext context,
    WidgetRef ref,
    ImageDetailData image,
  ) async {
    if (!image.showSaveButton) return;
    final pending = _pendingSaves[image.identifier];
    if (pending != null) return pending;
    final task = _saveImageFromDetail(context, ref, image);
    _pendingSaves[image.identifier] = task;
    try {
      await task;
    } finally {
      _pendingSaves.remove(image.identifier);
    }
  }

  static final _pendingSaves = <String, Future<void>>{};

  static Future<void> _saveImageFromDetail(
    BuildContext context,
    WidgetRef ref,
    ImageDetailData image,
  ) async {
    try {
      final current = ref
          .read(imageGenerationNotifierProvider)
          .mergedPanelImages;
      final knownPath =
          current
              .where((candidate) => candidate.id == image.identifier)
              .firstOrNull
              ?.filePath ??
          image.fileInfo?.path;
      if (knownPath != null && await File(knownPath).exists()) {
        if (context.mounted) {
          ref
              .read(imageGenerationNotifierProvider.notifier)
              .updateImageFilePath(image.identifier, knownPath);
          AppToast.success(context, context.l10n.image_imageSaved(knownPath));
        }
        return;
      }
      final saveDirPath = await GalleryFolderRepository.instance.getRootPath();
      if (saveDirPath == null) return;
      final path = await saveToDirectory(image, rootPath: saveDirPath);

      if (context.mounted) {
        ref
            .read(imageGenerationNotifierProvider.notifier)
            .updateImageFilePath(image.identifier, path);
        ref.read(localGalleryNotifierProvider.notifier).refresh();
        AppToast.success(context, context.l10n.image_imageSaved(saveDirPath));
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, context.l10n.image_saveFailed(e.toString()));
      }
    }
  }

  static final _pendingWrites = <String, Future<String>>{};

  /// Shared file operation, also used with a temporary root by offline tests.
  static Future<String> saveToDirectory(
    ImageDetailData image, {
    required String rootPath,
  }) async {
    final key = '$rootPath:${image.identifier}';
    final pending = _pendingWrites[key];
    if (pending != null) return pending;
    final task = _writeToDirectory(image, rootPath);
    _pendingWrites[key] = task;
    try {
      return await task;
    } finally {
      _pendingWrites.remove(key);
    }
  }

  static Future<String> _writeToDirectory(
    ImageDetailData image,
    String rootPath,
  ) async {
    final imageBytes = await image.getImageBytes();

    // 获取已有元数据（如果图像已包含）
    final existingMetadata =
        await ImageMetadataService().getMetadataFromBytes(imageBytes) ??
        image.metadata;
    // 构建最终字节：已嵌入 NAI 元数据则原样保留；
    // 否则用已有元数据重新嵌入；两者都没有则原样保存
    final finalBytes = ImageSaveUtils.hasEmbeddedNovelAiMetadata(imageBytes)
        ? imageBytes
        : existingMetadata != null
        ? await ImageSaveUtils.buildPrebuiltMetadataBytes(
            imageBytes: imageBytes,
            metadata: {
              'Description': existingMetadata.prompt,
              'Software': 'NovelAI',
              'Source':
                  existingMetadata.source ??
                  existingMetadata.model ??
                  'NovelAI Diffusion',
              'Comment': jsonEncode(
                buildCommentJsonFromMetadata(existingMetadata),
              ),
            },
          )
        : imageBytes;

    final seed = await ImageSaveUtils.resolveSeed(
      metadata: existingMetadata,
      bytes: imageBytes,
    );
    final identicalPath = await ImageSaveUtils.findIdenticalGalleryFile(
      rootPath: rootPath,
      bytes: finalBytes,
      seed: seed,
      matchWithoutSeed: true,
    );
    final path =
        identicalPath ??
        await ImageSaveUtils.saveBytesToGalleryPath(
          rootPath: rootPath,
          bytes: finalBytes,
          seed: seed,
        );

    return path;
  }

  /// 从元数据构建 Comment JSON
  static Map<String, dynamic> buildCommentJsonFromMetadata(
    NaiImageMetadata metadata,
  ) {
    // Preserve complete V4/V5 characters and reference fields when available.
    final raw = metadata.rawJson;
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final nested = decoded['Comment'] ?? decoded['comment'];
          final comment = nested is String
              ? jsonDecode(nested)
              : nested ?? decoded;
          if (comment is Map &&
              (comment.containsKey('prompt') ||
                  comment.containsKey('v4_prompt'))) {
            return Map<String, dynamic>.from(comment);
          }
        }
      } on FormatException {
        // Fall back to known fields; never substitute the current editor draft.
      }
    }
    final commentJson = <String, dynamic>{
      'prompt': metadata.prompt,
      'uc': metadata.negativePrompt,
      if (metadata.seed != null) 'seed': metadata.seed,
      if (metadata.steps != null) 'steps': metadata.steps,
      if (metadata.width != null) 'width': metadata.width,
      if (metadata.height != null) 'height': metadata.height,
      if (metadata.scale != null) 'scale': metadata.scale,
      if (metadata.model != null) 'model': metadata.model,
      if (metadata.cfgRescale != null) 'cfg_rescale': metadata.cfgRescale,
      if (metadata.noiseSchedule != null)
        'noise_schedule': metadata.noiseSchedule,
      if (metadata.sampler != null) 'sampler': metadata.sampler,
      if (metadata.smea != null) 'sm': metadata.smea,
      if (metadata.smeaDyn != null) 'sm_dyn': metadata.smeaDyn,
      if (metadata.strength != null) 'strength': metadata.strength,
      if (metadata.noise != null) 'noise': metadata.noise,
      if (metadata.qualityToggle != null)
        'quality_toggle': metadata.qualityToggle,
      if (metadata.ucPreset != null) 'uc_preset': metadata.ucPreset,
      if (metadata.varietyPlus != null) 'variety_plus': metadata.varietyPlus,
    };

    final characters = metadata.characterInfos.isNotEmpty
        ? metadata.characterInfos
        : [
            for (var i = 0; i < metadata.characterPrompts.length; i++)
              CharacterPromptInfo(
                prompt: metadata.characterPrompts[i],
                negativePrompt: i < metadata.characterNegativePrompts.length
                    ? metadata.characterNegativePrompts[i]
                    : null,
              ),
          ];
    Map<String, dynamic> caption(CharacterPromptInfo info, bool negative) => {
      'char_caption': negative ? info.negativePrompt ?? '' : info.prompt,
      if (info.centerX != null && info.centerY != null)
        'centers': [
          {'x': info.centerX, 'y': info.centerY},
        ],
    };
    if (characters.isNotEmpty) {
      commentJson['v4_prompt'] = {
        if (metadata.characterUseCoords != null)
          'use_coords': metadata.characterUseCoords,
        'caption': {
          'base_caption': metadata.prompt,
          'char_captions': [
            for (final info in characters) caption(info, false),
          ],
        },
      };
      commentJson['v4_negative_prompt'] = {
        'caption': {
          'base_caption': metadata.negativePrompt,
          'char_captions': [for (final info in characters) caption(info, true)],
        },
      };
    }

    if (metadata.preciseReferenceImages.isNotEmpty) {
      commentJson.addAll({
        'director_reference_images': metadata.preciseReferenceImages,
        'director_reference_descriptions': [
          for (final type in metadata.preciseReferenceTypes)
            {
              'caption': {'base_caption': type, 'char_captions': []},
            },
        ],
        'director_reference_strength_values':
            metadata.preciseReferenceStrengths,
        'director_reference_secondary_strength_values': metadata
            .preciseReferenceFidelities
            .map((value) => 1.0 - value)
            .toList(),
      });
    }
    // 添加 Vibe 数据
    if (metadata.vibeReferences.isNotEmpty) {
      final references = metadata.vibeReferences
          .where((v) => v.vibeEncoding.isNotEmpty)
          .toList();
      commentJson['reference_image_multiple'] = references
          .map((v) => v.vibeEncoding)
          .toList();
      commentJson['reference_strength_multiple'] = references
          .map((v) => v.strength)
          .toList();
      commentJson['reference_information_extracted_multiple'] = references
          .map((v) => v.infoExtracted)
          .toList();
    }

    return commentJson;
  }
}
