import 'package:flutter/material.dart';

import 'lab_logo_path.dart';

/// Draws the pixel LAB mark with a binary edge, like a hard pixel brush.
class LabLogoMark extends StatelessWidget {
  const LabLogoMark({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'W.O.F NAI LAB',
    child: SizedBox(
      width: width,
      height: width * 657 / 1514,
      child: const CustomPaint(painter: _LabLogoPainter()),
    ),
  );
}

class _LabLogoPainter extends CustomPainter {
  const _LabLogoPainter();

  static const _blue = Color(0xFF005DFF);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1514, size.height / 657);
    canvas.translate(-130, -96);
    canvas.drawPath(
      labLogoPath,
      Paint()
        ..color = _blue
        ..isAntiAlias = false,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LabLogoPainter oldDelegate) => false;
}
