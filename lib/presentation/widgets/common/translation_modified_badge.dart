import 'package:flutter/material.dart';

/// Three Chinese pixel glyphs, sampled from bundled HarmonyOS Sans SC Bold.
/// Keeping the glyph grid local avoids Latin-only pixel font fallback.
class TranslationModifiedBadge extends StatelessWidget {
  const TranslationModifiedBadge({super.key});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: '原文已修改，中文待同步',
    child: Semantics(
      label: '被修改，原文已修改，中文待同步',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF7CF54),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF25231B).withValues(alpha: .2),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.build_outlined, size: 11, color: Color(0xFF25231B)),
            SizedBox(width: 4),
            CustomPaint(size: Size(44, 14), painter: _ModifiedPixelPainter()),
          ],
        ),
      ),
    ),
  );
}

class _ModifiedPixelPainter extends CustomPainter {
  const _ModifiedPixelPainter();
  static const _glyphs = [
    [
      2072,
      3096,
      8190,
      8190,
      1946,
      3580,
      8190,
      16358,
      16380,
      4028,
      3516,
      4094,
      4038,
      0,
    ],
    [
      0,
      1120,
      3198,
      4078,
      7164,
      6780,
      15343,
      15288,
      2812,
      2588,
      2806,
      2780,
      2296,
      2496,
    ],
    [
      48,
      7984,
      8062,
      895,
      998,
      8164,
      8044,
      6204,
      6200,
      6968,
      8060,
      7662,
      4290,
      0,
    ],
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF25231B)
      ..isAntiAlias = false;
    for (var glyph = 0; glyph < _glyphs.length; glyph++) {
      for (var y = 0; y < 14; y++) {
        for (var x = 0; x < 14; x++) {
          if (_glyphs[glyph][y] & (1 << (13 - x)) != 0) {
            canvas.drawRect(
              Rect.fromLTWH((glyph * 15 + x).toDouble(), y.toDouble(), 1, 1),
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ModifiedPixelPainter oldDelegate) => false;
}
