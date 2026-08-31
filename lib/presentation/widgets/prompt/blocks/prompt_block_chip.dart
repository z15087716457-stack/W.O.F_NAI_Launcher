import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/prompt_block_segment.dart';
import 'prompt_block_colors.dart';

/// 编辑器中的块快照芯片。
///
/// 芯片只展示快照标题和状态，不把正文摘要混入编辑器视觉层。
class PromptBlockChip extends StatelessWidget {
  const PromptBlockChip({
    super.key,
    required this.segment,
    this.onToggleEnabled,
    this.onDelete,
    this.onExpand,
  });

  final BlockSegment segment;
  final VoidCallback? onToggleEnabled;
  final VoidCallback? onDelete;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = promptBlockColorFromString(segment.colorSnapshot);
    final foreground = segment.enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.48);
    final title = segment.titleSnapshot.trim().isEmpty
        ? context.l10n.promptBlockLibrary_unnamedBlock
        : segment.titleSnapshot;

    return Semantics(
      container: true,
      label: title,
      enabled: segment.enabled,
      child: Container(
        key: ValueKey('prompt-block-chip-${segment.id}'),
        constraints: const BoxConstraints(minHeight: 42),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: segment.enabled ? 0.7 : 0.35,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: segment.enabled ? 0.75 : 0.3),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 5,
              height: 42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: segment.enabled ? 1 : 0.45),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              segment.enabled
                  ? Icons.view_module_outlined
                  : Icons.visibility_off_outlined,
              size: 17,
              color: color.withValues(alpha: segment.enabled ? 1 : 0.6),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  decoration: segment.enabled
                      ? null
                      : TextDecoration.lineThrough,
                ),
              ),
            ),
            PopupMenuButton<_PromptBlockChipAction>(
              key: const Key('prompt-block-chip-menu'),
              tooltip: context.l10n.promptBlockEditor_more,
              padding: EdgeInsets.zero,
              onSelected: (action) => _handleAction(context, action),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _PromptBlockChipAction.preview,
                  child: Text(context.l10n.promptBlockEditor_preview),
                ),
                if (onToggleEnabled != null)
                  PopupMenuItem(
                    value: _PromptBlockChipAction.toggle,
                    child: Text(
                      segment.enabled
                          ? context.l10n.promptBlockEditor_disable
                          : context.l10n.promptBlockEditor_enable,
                    ),
                  ),
                if (onExpand != null)
                  PopupMenuItem(
                    value: _PromptBlockChipAction.expand,
                    child: Text(context.l10n.common_expand),
                  ),
                if (onDelete != null)
                  PopupMenuItem(
                    value: _PromptBlockChipAction.delete,
                    child: Text(context.l10n.common_delete),
                  ),
              ],
              icon: Icon(Icons.more_vert, size: 19, color: foreground),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, _PromptBlockChipAction action) {
    switch (action) {
      case _PromptBlockChipAction.preview:
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              segment.titleSnapshot.trim().isEmpty
                  ? context.l10n.promptBlockLibrary_unnamedBlock
                  : segment.titleSnapshot,
            ),
            content: SingleChildScrollView(
              child: SelectableText(segment.contentSnapshot),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(context.l10n.common_close),
              ),
            ],
          ),
        );
      case _PromptBlockChipAction.toggle:
        onToggleEnabled?.call();
      case _PromptBlockChipAction.delete:
        onDelete?.call();
      case _PromptBlockChipAction.expand:
        onExpand?.call();
    }
  }
}

enum _PromptBlockChipAction { preview, toggle, delete, expand }
