import 'dart:math' as math;

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
    this.trailing,
    this.trailingExtent = 22,
    this.availableWidth,
  });

  final String title;
  final TagCategory category;
  final TextStyle? style;
  final int? maxLines;
  final bool showCategory;
  final double iconSize;
  final Key? iconKey;
  final Widget? trailing;
  final double trailingExtent;
  final double? availableWidth;
  bool get _hasCategory => showCategory && category != TagCategory.general;
  TextStyle get _textStyle => (style ?? const TextStyle()).copyWith(
    leadingDistribution: TextLeadingDistribution.even,
  );

  @override
  Widget build(BuildContext context) {
    if (maxLines == 1 || trailing == null) return _row(context);
    if (availableWidth != null) return _measured(context, availableWidth!);
    return LayoutBuilder(
      builder: (context, constraints) =>
          _measured(context, constraints.maxWidth),
    );
  }

  Widget _measured(BuildContext context, double width) {
    final reserved = trailingExtent + (_hasCategory ? iconSize + 3 : 0);
    final painter = TextPainter(
      text: TextSpan(
        text: title,
        style: DefaultTextStyle.of(context).style.merge(_textStyle),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '…',
    )..layout(maxWidth: math.max(1, width - reserved));
    final height = painter.height;
    painter.dispose();
    return SizedBox(
      height: math.max(height, trailingExtent),
      child: Align(
        alignment: Alignment.topLeft,
        child: _row(context, height: height),
      ),
    );
  }

  Widget _aligned(Widget child, double extent, double? height) => height == null
      ? child
      : SizedBox(
          width: extent,
          height: math.max(height, extent),
          child: Align(
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: Offset(0, (height - extent) / 2),
              child: child,
            ),
          ),
        );

  Widget _row(BuildContext context, {double? height}) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: height == null
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
          style: _textStyle,
        ),
      ),
      if (_hasCategory) ...[
        const SizedBox(width: 3),
        _aligned(
          Tooltip(
            message: TagCategoryVisuals.label(context, category),
            child: Icon(
              TagCategoryVisuals.icon(category),
              key: iconKey,
              size: iconSize,
              color: TagCategoryVisuals.color(context, category),
            ),
          ),
          iconSize,
          height,
        ),
      ],
      if (trailing != null) _aligned(trailing!, trailingExtent, height),
    ],
  );
}
