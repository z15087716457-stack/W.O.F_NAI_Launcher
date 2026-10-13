import 'dart:typed_data';

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../../core/utils/app_logger.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/prompt_block_thumbnails.dart';
import '../../../data/models/gallery/nai_image_metadata.dart';
import '../../../data/services/image_metadata_service.dart';
import '../../providers/prompt_block_library_provider.dart';
import '../../wiring/blocks_edit_wiring.dart';
import '../common/app_toast.dart';
import '../common/prompt_block_picker_dialog.dart';
import 'prompt_block_drop_menu.dart';

/// Prompt 块库拖拽处理器
///
/// 处理拖入块库页面的图片文件，支持创建新块或更新现有块预览图
class PromptBlockDropHandler {
  /// 处理拖入块库的图片
  ///
  /// [context] BuildContext 用于显示对话框
  /// [ref] WidgetRef 用于访问 Provider
  /// [fileName] 拖入的文件名
  /// [bytes] 图片字节数据
  static Future<void> handle({
    required BuildContext context,
    required WidgetRef ref,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final l10n = context.l10n;
    try {
      // 解析图片元数据（此步骤不涉及 context）
      final metadata = await ImageMetadataService().getMetadataFromBytes(bytes);
      final prompt = metadata?.prompt ?? '';

      // 显示操作选择菜单
      final action = await PromptBlockDropMenu.show(
        // ignore: use_build_context_synchronously
        context,
        fileName: fileName,
        prompt: prompt,
      );

      if (action == null) return;

      switch (action) {
        case PromptBlockDropAction.create:
          await _handleCreateBlock(
            // ignore: use_build_context_synchronously
            context: context,
            ref: ref,
            fileName: fileName,
            bytes: bytes,
            metadata: metadata,
          );
          break;
        case PromptBlockDropAction.updateThumbnail:
          await _handleUpdateThumbnail(
            // ignore: use_build_context_synchronously
            context: context,
            ref: ref,
            bytes: bytes,
          );
          break;
        case PromptBlockDropAction.cancel:
          break;
      }
    } catch (e, stack) {
      AppLogger.e('处理块库拖拽失败', e, stack, 'PromptBlockDropHandler');
      if (context.mounted) {
        AppToast.error(context, l10n.toast_processImageFailed(e.toString()));
      }
    }
  }

  /// 处理创建新块
  static Future<void> _handleCreateBlock({
    required BuildContext context,
    required WidgetRef ref,
    required String fileName,
    required Uint8List bytes,
    required NaiImageMetadata? metadata,
  }) async {
    // 提取文件名作为默认块标题（去掉扩展名）
    final defaultName = path.basenameWithoutExtension(fileName);
    final initialContent = metadata?.prompt ?? '';

    if (!context.mounted) return;

    await BlocksEditWiring.createWithDialog(
      context,
      ref,
      initialTitle: defaultName,
      initialContent: initialContent.isNotEmpty ? initialContent : null,
      initialImageBytes: bytes,
    );
  }

  /// 处理更新现有块预览图
  static Future<void> _handleUpdateThumbnail({
    required BuildContext context,
    required WidgetRef ref,
    required Uint8List bytes,
  }) async {
    // 显示块选择对话框
    final selectedBlock = await PromptBlockPickerDialog.show(context);

    if (selectedBlock == null || !context.mounted) return;

    // 归一化并保存图片到块预览图目录
    final String thumbnailPath;
    try {
      thumbnailPath = await savePromptBlockThumbnail(bytes);
    } catch (e, stack) {
      AppLogger.e('保存缩略图失败', e, stack, 'PromptBlockDropHandler');
      // ignore: use_build_context_synchronously
      AppToast.error(context, context.l10n.toast_savePreviewFailed);
      return;
    }

    // 删除旧预览图（如果存在且在块预览图目录内）
    await deletePromptBlockThumbnail(selectedBlock.thumbnail);

    // 更新块
    await ref
        .read(promptBlockLibraryNotifierProvider.notifier)
        .updateBlock(selectedBlock.copyWith(thumbnail: thumbnailPath));

    if (context.mounted) {
      AppToast.success(context, context.l10n.toast_previewUpdated);
    }
  }
}
