import 'package:flutter/material.dart';

/// A single flat caution label; only the right edge carries warning stripes.
class TranslationModifiedBadge extends StatelessWidget {
  const TranslationModifiedBadge({super.key});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: '原文已修改，中文待同步',
    child: Semantics(
      label: '被修改，原文已修改，中文待同步',
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
                    const Icon(
                      Icons.build_outlined,
                      size: 11,
                      color: Color(0xFF272922),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '被修改',
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
