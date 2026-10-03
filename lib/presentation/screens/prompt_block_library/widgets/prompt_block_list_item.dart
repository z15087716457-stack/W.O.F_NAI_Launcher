import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';

class PromptBlockListItem extends StatelessWidget {
  const PromptBlockListItem({
    super.key,
    required this.block,
    required this.displayTitle,
    required this.onEdit,
    required this.onCopy,
    required this.onDelete,
    this.onTap,
    this.selected = false,
    this.multiSelected = false,
    this.onSecondaryTap,
    this.onAddTag,
    this.onToggleFavorite,
    this.reorderIndex,
    this.compact = false,
  });

  final PromptBlock block;
  final String displayTitle;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool selected;

  /// 多选模式下属于选中集合（叠加勾选角标；描边复用 [selected]）。
  final bool multiSelected;

  /// 右键菜单入口（secondary tap）。
  final void Function(TapUpDetails details)? onSecondaryTap;

  final ValueChanged<Offset>? onAddTag;

  /// ★ 收藏入口：回调收到按钮的全局锚点，宿主据此弹出收藏菜单。
  final ValueChanged<Offset>? onToggleFavorite;
  final int? reorderIndex;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockColor = promptBlockColorFromString(block.color);
    final previewContent = block.content.isEmpty
        ? block.negativeContent
        : block.content;
    final preview = previewContent.isEmpty
        ? context.l10n.detail_noContent
        : previewContent.replaceAll(RegExp(r'\s+'), ' ').trim();

    return GestureDetector(
      onSecondaryTapUp: onSecondaryTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            width: selected ? 1.3 : 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              SizedBox(width: 6, child: ColoredBox(color: blockColor)),
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      14,
                      compact ? 7 : 11,
                      8,
                      compact ? 7 : 11,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (multiSelected) ...[
                              Icon(
                                Icons.check_circle,
                                size: 17,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                displayTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 2 : 5),
                        Text(
                          preview,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (reorderIndex != null)
                ReorderableDragStartListener(
                  index: reorderIndex!,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.drag_handle,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (onToggleFavorite != null)
                Builder(
                  builder: (buttonContext) => IconButton(
                    tooltip: block.isFavorite
                        ? context.l10n.common_unfavorite
                        : context.l10n.common_favorite,
                    onPressed: () {
                      final box = buttonContext.findRenderObject();
                      final anchor = box is RenderBox
                          ? box.localToGlobal(Offset.zero)
                          : Offset.zero;
                      onToggleFavorite?.call(anchor);
                    },
                    icon: Icon(
                      block.isFavorite ? Icons.star : Icons.star_border,
                      size: 19,
                      color: block.isFavorite
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (onAddTag != null)
                Builder(
                  builder: (buttonContext) => IconButton(
                    tooltip: context.l10n.promptBlockLibrary_addTag,
                    onPressed: () {
                      final box = buttonContext.findRenderObject();
                      onAddTag?.call(
                        box is RenderBox
                            ? box.localToGlobal(Offset.zero)
                            : Offset.zero,
                      );
                    },
                    icon: const Icon(Icons.sell_outlined, size: 19),
                  ),
                ),
              IconButton(
                tooltip: context.l10n.common_copy,
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text: block.content.isNotEmpty
                          ? block.content
                          : block.negativeContent,
                    ),
                  );
                  onCopy();
                },
                icon: const Icon(Icons.copy_outlined, size: 19),
              ),
              IconButton(
                tooltip: context.l10n.common_edit,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
              IconButton(
                tooltip: context.l10n.common_delete,
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  size: 19,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
