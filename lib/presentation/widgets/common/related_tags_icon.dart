import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

/// The selected branch motif, shared by all associated-tag actions.
class RelatedTagsIcon extends StatelessWidget {
  const RelatedTagsIcon({super.key, this.size = 18, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _RelatedTagsPainter(
        color ??
            IconTheme.of(context).color ??
            Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

class _RelatedTagsPainter extends CustomPainter {
  const _RelatedTagsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(3.7, 7.3)
        ..lineTo(8.5, 7.3)
        ..lineTo(13.2, 12)
        ..lineTo(8.5, 16.7)
        ..lineTo(3.7, 16.7)
        ..quadraticBezierTo(2.5, 16.7, 2.5, 15.5)
        ..lineTo(2.5, 8.5)
        ..quadraticBezierTo(2.5, 7.3, 3.7, 7.3)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(13.2, 12)
        ..lineTo(16.3, 12)
        ..moveTo(18.5, 6)
        ..lineTo(16.3, 6)
        ..lineTo(16.3, 18)
        ..lineTo(18.5, 18),
      paint,
    );
    canvas.drawCircle(const Offset(20, 6), 1.6, paint);
    canvas.drawCircle(const Offset(20, 18), 1.6, paint);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(5.5, 12), .85, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RelatedTagsPainter oldDelegate) =>
      oldDelegate.color != color;
}
