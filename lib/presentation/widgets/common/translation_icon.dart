import 'dart:math' as math;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../themes/studio_typography.dart';

enum TranslationIconStyle { prototype, pill }

/// The selected solid language glyph, with the retained language-cycle artwork
/// during actual requests. Every state keeps the same layout and text offsets.
class TranslationIcon extends StatefulWidget {
  const TranslationIcon({
    super.key,
    this.size,
    this.color,
    this.busy = false,
    this.style = TranslationIconStyle.prototype,
  });

  final double? size;
  final Color? color;
  final bool busy;
  final TranslationIconStyle style;

  @override
  State<TranslationIcon> createState() => _TranslationIconState();
}

class _TranslationIconState extends State<TranslationIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  void _syncPulse() {
    final run =
        widget.busy &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (run) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      _motion
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(TranslationIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.busy != widget.busy) _syncPulse();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final dimension = widget.size ?? theme.size ?? 24;
    final baseInk =
        widget.color ?? theme.color ?? Theme.of(context).colorScheme.onSurface;
    final ink = baseInk.withValues(alpha: baseInk.a * (theme.opacity ?? 1));
    final Widget glyph = widget.style == TranslationIconStyle.pill
        // The HTML slot is as wide as the 10px glyph, not a square icon box.
        ? SizedBox(
            height: dimension,
            child: Center(
              widthFactor: 1,
              child: RichText(
                textScaler: TextScaler.noScaling,
                text: TextSpan(
                  // The prototype uses this glyph as artwork, not a label.
                  text: '译',
                  style: TextStyle(
                    fontFamily: StudioTypography.cjk,
                    fontSize: dimension * 10 / 12,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: ink,
                  ),
                ),
              ),
            ),
          )
        : SizedBox.square(
            dimension: dimension,
            child: Center(
              child: Icon(Icons.translate, size: dimension, color: baseInk),
            ),
          );
    return ExcludeSemantics(
      child: widget.busy
          ? SizedBox(
              width: widget.style == TranslationIconStyle.pill
                  ? dimension * 10 / 12
                  : dimension,
              height: dimension,
              child: FittedBox(
                child: SizedBox.square(
                  dimension: dimension,
                  child: CustomPaint(
                    painter: TranslationIconPainter(ink, _motion),
                  ),
                ),
              ),
            )
          : glyph,
    );
  }
}

/// Retained vector animation: the arrows orbit an upright A.
class TranslationIconPainter extends CustomPainter {
  TranslationIconPainter(this.color, this.motion) : super(repaint: motion);
  final Color color;
  final Animation<double> motion;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final ring = Path()
      ..moveTo(4.4, 8)
      ..arcToPoint(const Offset(19.2, 6.2), radius: const Radius.circular(8.2))
      ..moveTo(19.2, 3.4)
      ..lineTo(19.2, 6.2)
      ..lineTo(16.4, 6.2)
      ..moveTo(19.6, 16)
      ..arcToPoint(const Offset(4.8, 17.8), radius: const Radius.circular(8.2))
      ..moveTo(4.8, 20.6)
      ..lineTo(4.8, 17.8)
      ..lineTo(7.6, 17.8);
    canvas.save();
    canvas.translate(12, 12);
    canvas.rotate(motion.value * math.pi * 2);
    canvas.translate(-12, -12);
    canvas.drawPath(ring, paint);
    canvas.restore();
    canvas.drawPath(
      Path()
        ..moveTo(8.8, 15.4)
        ..lineTo(12, 8.1)
        ..lineTo(15.2, 15.4)
        ..moveTo(10, 12.8)
        ..lineTo(14, 12.8),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(TranslationIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.motion != motion;
}
