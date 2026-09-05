import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/blocks/prompt_block_icons.dart';

enum _PromptBlockCardAction { favorite, copy, export, edit, delete }

class PromptBlockCard extends StatelessWidget {
  const PromptBlockCard({
    super.key,
    required this.block,
    required this.displayTitle,
    required this.width,
    required this.onTap,
    required this.onEdit,
    required this.onCopy,
    required this.onDelete,
    this.onExport,
    this.onToggleFavorite,
    this.selected = false,
    this.multiSelected = false,
    this.onSecondaryTap,
  });

  final PromptBlock block;
  final String displayTitle;
  final double width;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback? onExport;
  final VoidCallback? onToggleFavorite;
  final bool selected;

  /// 多选模式下属于选中集合（叠加勾选角标；描边复用 [selected]）。
  final bool multiSelected;

  /// 右键菜单入口（secondary tap）。
  final void Function(TapUpDetails details)? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockColor = promptBlockColorFromString(block.color);
    final compact = width <= 160;
    final preview = block.content.isEmpty
        ? context.l10n.detail_noContent
        : block.content.replaceAll(RegExp(r'\s+'), ' ').trim();

    return GestureDetector(
      onSecondaryTapUp: onSecondaryTap,
      child: Stack(
        children: [
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            elevation: selected ? 2 : 0,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selected
                    ? theme.colorScheme.primary
                    : blockColor.withValues(alpha: 0.55),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Material(
                    color: compact
                        ? blockColor.withValues(alpha: 0.15)
                        : theme.colorScheme.surface,
                    child: InkWell(
                      key: ValueKey('prompt-block-card-body-${block.id}'),
                      onTap: onTap,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 10 : 12,
                          compact ? 10 : 12,
                          compact ? 10 : 12,
                          8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: compact ? 30 : 34,
                                  height: compact ? 30 : 34,
                                  decoration: BoxDecoration(
                                    color: blockColor.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(
                                    promptBlockIconFromName(block.iconName),
                                    size: compact ? 18 : 20,
                                    color: blockColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    displayTitle,
                                    maxLines: compact ? 2 : 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (block.isFavorite && !compact)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.star,
                                      size: 17,
                                      color: blockColor,
                                    ),
                                  ),
                              ],
                            ),
                            if (!compact) ...[
                              const SizedBox(height: 10),
                              Expanded(
                                child: Text(
                                  preview,
                                  maxLines: width < 240 ? 2 : 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildActions(context, theme),
              ],
            ),
          ),
          if (multiSelected)
            Positioned(
              top: 6,
              right: 6,
              child: Icon(
                Icons.check_circle,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    if (width < 210) {
      return SizedBox(
        height: 38,
        child: Align(
          alignment: Alignment.centerRight,
          child: _buildActionMenu(context),
        ),
      );
    }

    final buttons = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onToggleFavorite != null)
          IconButton(
            tooltip: block.isFavorite
                ? context.l10n.common_unfavorite
                : context.l10n.common_favorite,
            visualDensity: VisualDensity.compact,
            onPressed: onToggleFavorite,
            icon: Icon(
              block.isFavorite ? Icons.star : Icons.star_border,
              size: 18,
              color: block.isFavorite
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (onExport != null)
          IconButton(
            tooltip: context.l10n.promptBlockLibrary_exportBlockAsTxt,
            visualDensity: VisualDensity.compact,
            onPressed: onExport,
            icon: const Icon(Icons.file_upload_outlined, size: 18),
          ),
        IconButton(
          tooltip: context.l10n.common_copy,
          visualDensity: VisualDensity.compact,
          onPressed: _copyContent,
          icon: const Icon(Icons.copy_outlined, size: 18),
        ),
        IconButton(
          tooltip: context.l10n.common_edit,
          visualDensity: VisualDensity.compact,
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
        ),
        IconButton(
          tooltip: context.l10n.common_delete,
          visualDensity: VisualDensity.compact,
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline,
            size: 18,
            color: theme.colorScheme.error,
          ),
        ),
      ],
    );

    return SizedBox(
      height: 38,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: buttons,
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return PopupMenuButton<_PromptBlockCardAction>(
      key: ValueKey('prompt-block-card-actions-${block.id}'),
      tooltip: context.l10n.common_edit,
      icon: const Icon(Icons.more_horiz, size: 20),
      onSelected: (action) {
        switch (action) {
          case _PromptBlockCardAction.favorite:
            onToggleFavorite?.call();
          case _PromptBlockCardAction.copy:
            _copyContent();
          case _PromptBlockCardAction.export:
            onExport?.call();
          case _PromptBlockCardAction.edit:
            onEdit();
          case _PromptBlockCardAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) => [
        if (onToggleFavorite != null)
          PopupMenuItem(
            value: _PromptBlockCardAction.favorite,
            child: Text(
              block.isFavorite
                  ? context.l10n.common_unfavorite
                  : context.l10n.common_favorite,
            ),
          ),
        PopupMenuItem(
          value: _PromptBlockCardAction.copy,
          child: Text(context.l10n.common_copy),
        ),
        if (onExport != null)
          PopupMenuItem(
            value: _PromptBlockCardAction.export,
            child: Text(context.l10n.promptBlockLibrary_exportBlockAsTxt),
          ),
        PopupMenuItem(
          value: _PromptBlockCardAction.edit,
          child: Text(context.l10n.common_edit),
        ),
        PopupMenuItem(
          value: _PromptBlockCardAction.delete,
          child: Text(context.l10n.common_delete),
        ),
      ],
    );
  }

  Future<void> _copyContent() async {
    await Clipboard.setData(ClipboardData(text: block.content));
    onCopy();
  }
}

class PromptBlockPill extends StatelessWidget {
  const PromptBlockPill({
    super.key,
    required this.block,
    required this.displayTitle,
    required this.maxWidth,
    required this.onTap,
    this.selected = false,
    this.multiSelected = false,
    this.onSecondaryTap,
  });

  final PromptBlock block;
  final String displayTitle;
  final double maxWidth;
  final VoidCallback onTap;
  final bool selected;

  /// 多选模式下属于选中集合（叠加勾选角标；描边复用 [selected]）。
  final bool multiSelected;

  /// 右键菜单入口（secondary tap）。
  final void Function(TapUpDetails details)? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockColor = promptBlockColorFromString(block.color);
    return GestureDetector(
      onSecondaryTapUp: onSecondaryTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Material(
          color: blockColor.withValues(alpha: 0.16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: selected
                  ? theme.colorScheme.primary
                  : blockColor.withValues(alpha: 0.65),
              width: selected ? 1.4 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('prompt-block-pill-body-${block.id}'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    promptBlockIconFromName(block.iconName),
                    size: 16,
                    color: blockColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (multiSelected) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.check_circle,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
