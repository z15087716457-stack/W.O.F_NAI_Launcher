import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/autocomplete/completion_models.dart';
import '../../../core/utils/tag_normalizer.dart';
import '../../widgets/autocomplete/tag_candidate_title.dart';

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
  });

  final CompletionCandidate candidate;
  final String subtitle, countLabel, bookmarkLabel;
  final bool selected, bookmarked;
  final VoidCallback onSelect, onBookmark;

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
    final scheme = Theme.of(context).colorScheme;
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
              ? scheme.onSurface.withValues(alpha: .065)
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
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.selected
                          ? scheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Tooltip(
                      message:
                          '${TagNormalizer.toDisplay(tag)}\n${widget.subtitle}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TagCandidateTitle(
                            title: TagNormalizer.toDisplay(tag),
                            category: widget.candidate.category,
                            iconKey: ValueKey(
                              'wiki-category-${widget.candidate.category.name}-$tag',
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
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
                  Text(
                    widget.countLabel,
                    key: ValueKey('wiki-row-count-$tag'),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
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
