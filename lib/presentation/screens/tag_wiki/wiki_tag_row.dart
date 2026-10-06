import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/autocomplete/completion_models.dart';
import '../../../core/utils/tag_normalizer.dart';
import '../../widgets/autocomplete/tag_category_visuals.dart';

/// Two readable lines with a stable action slot, including when it is hidden.
class WikiTagRow extends StatefulWidget {
  const WikiTagRow({
    super.key,
    required this.candidate,
    required this.subtitle,
    required this.countLabel,
    required this.selected,
    required this.bookmarked,
    required this.bookmarkLabel,
    required this.onSelect,
    required this.onBookmark,
    this.noArticleLabel,
    this.translationIndicator,
  });

  final CompletionCandidate candidate;
  final String subtitle, countLabel, bookmarkLabel;
  final bool selected, bookmarked;
  final VoidCallback onSelect, onBookmark;
  final Widget? translationIndicator;

  /// Small outlined badge left of the post count; null keeps the slot empty.
  final String? noArticleLabel;

  static double extentOf(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return math.max(60, scaler.scale(14) * 1.35 + scaler.scale(12) * 1.3 + 24);
  }

  @override
  State<WikiTagRow> createState() => _WikiTagRowState();
}

class _WikiTagRowState extends State<WikiTagRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tag = widget.candidate.canonicalTag;
    final showBookmark =
        widget.selected || widget.bookmarked || _hovered || _focused;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: widget.selected
              ? scheme.primary.withValues(alpha: .08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: widget.onSelect,
            onFocusChange: (focused) => setState(() => _focused = focused),
            borderRadius: BorderRadius.circular(4),
            hoverColor: scheme.onSurface.withValues(alpha: .035),
            child: SizedBox(
              height: WikiTagRow.extentOf(context),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.selected
                          ? scheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Icon(
                    TagCategoryVisuals.icon(widget.candidate.category),
                    key: ValueKey(
                      'wiki-category-${widget.candidate.category.name}-$tag',
                    ),
                    size: 16,
                    color: TagCategoryVisuals.color(
                      context,
                      widget.candidate.category,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Tooltip(
                      message:
                          '${TagNormalizer.toDisplay(tag)}\n${widget.subtitle}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  TagNormalizer.toDisplay(tag),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (widget.translationIndicator != null)
                                widget.translationIndicator!,
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            key: ValueKey('wiki-row-subtitle-$tag'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (widget.noArticleLabel != null) ...[
                    Container(
                      key: ValueKey('wiki-row-no-article-$tag'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        widget.noArticleLabel!,
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.countLabel,
                    key: ValueKey('wiki-row-count-$tag'),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 32,
                    height: 36,
                    child: showBookmark
                        ? IconButton(
                            key: ValueKey('wiki-row-bookmark-$tag'),
                            tooltip: widget.bookmarkLabel,
                            padding: EdgeInsets.zero,
                            iconSize: 18,
                            onPressed: widget.onBookmark,
                            icon: Icon(
                              widget.bookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
