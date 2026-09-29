import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/pill_document.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/blocks/prompt_block_appearance.dart';
import '../../../widgets/prompt/blocks/prompt_block_icons.dart';
import '../../../widgets/prompt/pills/translation_tag_span.dart';

enum _PromptBlockCardAction { favorite, copy, addTag, edit, delete }

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
    this.onAddTag,
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
  final ValueChanged<Offset>? onAddTag;

  /// ★ 收藏入口：回调收到按钮的全局锚点，宿主据此弹出收藏菜单。
  final ValueChanged<Offset>? onToggleFavorite;
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
    final previewContent = block.content.isEmpty
        ? block.negativeContent
        : block.content;
    final preview = previewContent.isEmpty
        ? context.l10n.detail_noContent
        : previewContent.replaceAll(RegExp(r'\s+'), ' ').trim();

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
          Builder(
            builder: (buttonContext) => IconButton(
              tooltip: block.isFavorite
                  ? context.l10n.common_unfavorite
                  : context.l10n.common_favorite,
              visualDensity: VisualDensity.compact,
              onPressed: () => onToggleFavorite?.call(_anchorOf(buttonContext)),
              icon: Icon(
                block.isFavorite ? Icons.star : Icons.star_border,
                size: 18,
                color: block.isFavorite
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (onAddTag != null)
          Builder(
            builder: (buttonContext) => IconButton(
              tooltip: '添加标签',
              visualDensity: VisualDensity.compact,
              onPressed: () => onAddTag?.call(_anchorOf(buttonContext)),
              icon: const Icon(Icons.sell_outlined, size: 18),
            ),
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

  /// 按钮自身在全局坐标系中的左上角，供收藏菜单锚定。
  static Offset _anchorOf(BuildContext buttonContext) {
    final box = buttonContext.findRenderObject();
    return box is RenderBox ? box.localToGlobal(Offset.zero) : Offset.zero;
  }

  Widget _buildActionMenu(BuildContext context) {
    return Builder(
      builder: (menuContext) => PopupMenuButton<_PromptBlockCardAction>(
        key: ValueKey('prompt-block-card-actions-${block.id}'),
        tooltip: context.l10n.common_edit,
        icon: const Icon(Icons.more_horiz, size: 20),
        onSelected: (action) {
          switch (action) {
            case _PromptBlockCardAction.favorite:
              onToggleFavorite?.call(_anchorOf(menuContext));
            case _PromptBlockCardAction.copy:
              _copyContent();
            case _PromptBlockCardAction.addTag:
              onAddTag?.call(_anchorOf(menuContext));
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
          if (onAddTag != null)
            const PopupMenuItem(
              value: _PromptBlockCardAction.addTag,
              child: Text('添加标签'),
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
      ),
    );
  }

  Future<void> _copyContent() async {
    await Clipboard.setData(
      ClipboardData(
        text: block.content.isNotEmpty ? block.content : block.negativeContent,
      ),
    );
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
    this.showThumbnail = true,
    this.paletteStyle = false,
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

  /// 有缩略图时以 22px 圆角头像替换前导图标；无图块仍显示图标。
  final bool showThumbnail;

  /// The floating palette shows full text at a smaller, prompt-like size.
  final bool paletteStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockColor = promptBlockColorFromString(block.color);
    final thumbnail = block.thumbnail;
    final titleStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: paletteStyle ? 12 : null,
      height: paletteStyle ? 1.25 : null,
      fontWeight: paletteStyle ? FontWeight.w500 : FontWeight.w600,
      color: PromptBlockAppearance.text(
        block.appearance,
        blockColor,
        theme.colorScheme.onSurface,
      ),
    );
    final marks =
        paletteStyle &&
            block.readingTranslationZh == displayTitle &&
            block.readingTranslationMarks?.isNotEmpty == true
        ? TranslationPill.fromJson({
            'zh': displayTitle,
            'marks': block.readingTranslationMarks,
          }).marks
        : const <TranslationTagMark>[];
    return GestureDetector(
      onSecondaryTapUp: onSecondaryTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Material(
          color: PromptBlockAppearance.fill(
            block.appearance,
            blockColor,
            dark: theme.brightness == Brightness.dark,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(paletteStyle ? 6 : 18),
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
            child: CustomPaint(
              painter: PromptBlockPatternPainter(
                appearance: block.appearance,
                color: blockColor,
              ),
              child: Padding(
                padding: paletteStyle
                    ? const EdgeInsets.fromLTRB(8, 5, 22, 5)
                    : const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showThumbnail &&
                        thumbnail != null &&
                        !(paletteStyle && block.readingTranslationZh != null))
                      ClipRRect(
                        key: ValueKey('prompt-block-pill-thumb-${block.id}'),
                        borderRadius: BorderRadius.circular(5),
                        child: Image.file(
                          File(thumbnail),
                          width: 22,
                          height: 22,
                          fit: BoxFit.cover,
                          alignment: Alignment(
                            block.thumbnailOffsetX.clamp(-1.0, 1.0),
                            block.thumbnailOffsetY.clamp(-1.0, 1.0),
                          ),
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, __, ___) => Icon(
                            paletteStyle && block.readingTranslationZh != null
                                ? Icons.translate_outlined
                                : promptBlockIconFromName(block.iconName),
                            size: paletteStyle ? 13 : 16,
                            color: PromptBlockAppearance.text(
                              block.appearance,
                              blockColor,
                              blockColor,
                            ),
                          ),
                        ),
                      )
                    else
                      Icon(
                        paletteStyle && block.readingTranslationZh != null
                            ? Icons.translate_outlined
                            : promptBlockIconFromName(block.iconName),
                        size: paletteStyle ? 13 : 16,
                        color: PromptBlockAppearance.text(
                          block.appearance,
                          blockColor,
                          blockColor,
                        ),
                      ),
                    SizedBox(width: paletteStyle ? 5 : 6),
                    Flexible(
                      child: marks.isEmpty
                          ? Text(
                              displayTitle,
                              maxLines: paletteStyle ? null : 1,
                              overflow: paletteStyle
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              softWrap: paletteStyle,
                              style: titleStyle,
                            )
                          : Text.rich(
                              TranslationTagSpan.annotate(
                                context,
                                TextSpan(
                                  children: [TextSpan(text: displayTitle)],
                                ),
                                displayTitle,
                                marks,
                              ),
                              softWrap: true,
                              style: titleStyle,
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
      ),
    );
  }
}
