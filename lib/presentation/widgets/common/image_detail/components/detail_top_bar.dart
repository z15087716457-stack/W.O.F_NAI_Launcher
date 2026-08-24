import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/localization_extension.dart';
import '../../../../../data/models/gallery/local_image_record.dart';
import '../../../../providers/local_gallery_provider.dart';
import '../../animated_favorite_button.dart';
import '../image_detail_data.dart';

/// 顶部控制栏
///
/// 显示关闭按钮、图片索引信息和操作按钮
class DetailTopBar extends StatelessWidget {
  final int currentIndex;
  final int totalImages;
  final ImageDetailData currentImage;
  final VoidCallback onClose;
  final VoidCallback? onReuseMetadata;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onSave;
  final VoidCallback? onCopyImage;
  final VoidCallback? onSendToImg2Img;
  final VoidCallback? onSendToReversePrompt;

  /// 删除当前图片（仅支持删除的调用方传入，如本地画廊）
  final VoidCallback? onDelete;

  const DetailTopBar({
    super.key,
    required this.currentIndex,
    required this.totalImages,
    required this.currentImage,
    required this.onClose,
    this.onReuseMetadata,
    this.onFavoriteToggle,
    this.onSave,
    this.onCopyImage,
    this.onSendToImg2Img,
    this.onSendToReversePrompt,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metadata = currentImage.metadata;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // 关闭按钮
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onClose,
            tooltip: l10n.common_close,
          ),

          const SizedBox(width: 16),

          // 图片信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${currentIndex + 1} / $totalImages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (metadata?.model != null)
                  Text(
                    metadata!.model!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          // 保存按钮（仅生成图像显示）
          if (currentImage.showSaveButton && onSave != null)
            IconButton(
              icon: const Icon(Icons.save_alt, color: Colors.white),
              onPressed: onSave,
              tooltip: l10n.common_save,
            ),

          // 复用参数按钮
          if (metadata != null && onReuseMetadata != null)
            IconButton(
              icon: const Icon(Icons.input, color: Colors.white),
              onPressed: onReuseMetadata,
              tooltip: l10n.shortcut_action_reuse_params,
            ),

          // 发送到图生图
          if (onSendToImg2Img != null)
            IconButton(
              icon: const Icon(Icons.image_search, color: Colors.white),
              onPressed: onSendToImg2Img,
              tooltip: l10n.detail_sendToImg2Img,
            ),

          // 发送到反推模块
          if (onSendToReversePrompt != null)
            IconButton(
              icon: const Icon(Icons.auto_fix_high, color: Colors.white),
              onPressed: onSendToReversePrompt,
              tooltip: l10n.detail_sendToReversePrompt,
            ),

          // 复制图像按钮
          if (onCopyImage != null)
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white),
              onPressed: onCopyImage,
              tooltip: l10n.shortcut_action_copy_image,
            ),

          // 收藏按钮（仅本地图库显示）
          if (currentImage.showFavoriteButton && onFavoriteToggle != null)
            Consumer(
              builder: (context, ref, child) {
                // 如果是本地图库图片，实时监听收藏状态
                final isLocalImage = currentImage.identifier.isNotEmpty &&
                    currentImage is LocalImageDetailData;

                bool isFavorite = currentImage.isFavorite;

                if (isLocalImage) {
                  final galleryState = ref.watch(localGalleryNotifierProvider);
                  final record = galleryState.currentImages
                      .cast<LocalImageRecord?>()
                      .firstWhere(
                        (img) => img?.path == currentImage.identifier,
                        orElse: () => null,
                      );
                  if (record != null) {
                    isFavorite = record.isFavorite;
                  }
                }

                return AnimatedFavoriteButton(
                  isFavorite: isFavorite,
                  size: 24,
                  inactiveColor: Colors.white,
                  showBackground: true,
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  onToggle: onFavoriteToggle,
                );
              },
            ),

          // 删除按钮（仅支持删除的调用方显示）
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
              onPressed: onDelete,
              tooltip: l10n.common_delete,
            ),
        ],
      ),
    );
  }
}
