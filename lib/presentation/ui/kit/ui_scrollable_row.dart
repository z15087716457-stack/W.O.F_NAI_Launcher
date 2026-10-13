import 'package:flutter/widgets.dart';

/// Preserve row alignment when it fits; keep long localized controls reachable.
class UiScrollableRow extends StatelessWidget {
  const UiScrollableRow({
    super.key,
    required this.children,
    this.spacing = 0,
    this.shrinkWrap = false,
  });

  final List<Widget> children;
  final double spacing;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) => shrinkWrap
      ? SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: spacing,
            children: children,
          ),
        )
      : LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: box.maxWidth),
              child: IntrinsicWidth(
                child: Row(spacing: spacing, children: children),
              ),
            ),
          ),
        );
}
