import 'package:flutter/material.dart';

/// A single flat caution label; only the right edge carries warning stripes.
class TranslationModifiedBadge extends StatelessWidget {
  const TranslationModifiedBadge({
    super.key,
    this.prefix = '原',
    this.label = '被修改',
    this.tooltip = '原文已修改，中文待同步',
  });

  final String prefix;
  final String label;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      label: '$prefix，$label，$tooltip',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: ColoredBox(
          color: const Color(0xFFF2CE59),
          child: CustomPaint(
            foregroundPainter: const _RightCautionStripes(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 3, 13, 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BadgePrefix(
                      prefix: prefix,
                      color: const Color(0xFF272922),
                    ),
                    const Icon(
                      Icons.build_outlined,
                      size: 11,
                      color: Color(0xFF272922),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF272922),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Translation polish is recorded quietly, without a wrench or warning color.
class TranslationEditedBadge extends StatelessWidget {
  const TranslationEditedBadge({
    super.key,
    required this.prefix,
    required this.label,
    required this.tooltip,
  });

  final String prefix;
  final String label;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: '$prefix，$label，$tooltip',
        child: Container(
          constraints: const BoxConstraints(minHeight: 20),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BadgePrefix(prefix: prefix, color: scheme.onSurfaceVariant),
              Icon(
                Icons.edit_outlined,
                size: 11,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgePrefix extends StatelessWidget {
  const _BadgePrefix({required this.prefix, required this.color});
  final String prefix;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        prefix,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 11,
          height: 1.2,
          color: color,
        ),
      ),
      Container(
        width: 1,
        height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        color: color.withValues(alpha: .3),
      ),
    ],
  );
}

class _RightCautionStripes extends CustomPainter {
  const _RightCautionStripes();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(size.width - 5, 0, 5, size.height));
    final paint = Paint()..color = const Color(0xFF272922);
    for (double x = size.width - 5 - size.height; x < size.width; x += 5) {
      canvas.drawPath(
        Path()
          ..moveTo(x, size.height)
          ..lineTo(x + size.height, 0)
          ..lineTo(x + size.height + 2.5, 0)
          ..lineTo(x + 2.5, size.height)
          ..close(),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RightCautionStripes oldDelegate) => false;
}
