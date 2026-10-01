import 'package:flutter/material.dart';

import '../../../core/autocomplete/completion_models.dart';
import 'tag_category_visuals.dart';

/// Reserve the category cue outside the text so ellipsis cannot hide it.
class TagCandidateTitle extends StatelessWidget {
  const TagCandidateTitle({
    super.key,
    required this.title,
    required this.category,
    this.style,
    this.maxLines = 1,
    this.showCategory = true,
    this.iconSize = 12,
    this.iconKey,
  });

  final String title;
  final TagCategory category;
  final TextStyle? style;
  final int? maxLines;
  final bool showCategory;
  final double iconSize;
  final Key? iconKey;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: maxLines == 1
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start,
    children: [
      Flexible(
        child: Text(
          title,
          maxLines: maxLines,
          softWrap: maxLines != 1,
          overflow: maxLines == null
              ? TextOverflow.clip
              : TextOverflow.ellipsis,
          style: style,
        ),
      ),
      if (showCategory && category != TagCategory.general) ...[
        const SizedBox(width: 3),
        Tooltip(
          message: TagCategoryVisuals.label(context, category),
          child: Icon(
            TagCategoryVisuals.icon(category),
            key: iconKey,
            size: iconSize,
            color: TagCategoryVisuals.color(context, category),
          ),
        ),
      ],
    ],
  );
}
