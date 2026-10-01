import 'package:flutter/material.dart';

/// Compact caution label with normal application typography.
class TranslationModifiedBadge extends StatelessWidget {
  const TranslationModifiedBadge({super.key});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: '原文已修改，中文待同步',
    child: Semantics(
      label: '被修改，原文已修改，中文待同步',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: CustomPaint(
          painter: const _CautionStripes(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFF7CF54),
                borderRadius: BorderRadius.circular(1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.build_outlined,
                    size: 11,
                    color: Color(0xFF25231B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '被修改',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF25231B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CautionStripes extends CustomPainter {
  const _CautionStripes();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF7CF54),
    );
    final paint = Paint()..color = const Color(0xFF25231B);
    for (double x = -size.height; x < size.width; x += 9) {
      canvas.drawPath(
        Path()
          ..moveTo(x, size.height)
          ..lineTo(x + size.height, 0)
          ..lineTo(x + size.height + 4, 0)
          ..lineTo(x + 4, size.height)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CautionStripes oldDelegate) => false;
}
