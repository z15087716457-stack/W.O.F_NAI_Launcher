import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/canvas_settings_provider.dart';

/// A display-only layer beneath image pixels; never composited into saved bytes.
class CanvasImageBackground extends ConsumerWidget {
  const CanvasImageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CanvasImageBackdrop(
    value: ref.watch(canvasImageBackgroundNotifierProvider),
    child: child,
  );
}

class CanvasImageBackdrop extends StatelessWidget {
  const CanvasImageBackdrop({super.key, required this.value, this.child});

  final String value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _BackdropPainter(
        value,
        colors.surface,
        colors.surfaceContainerHighest,
      ),
      isComplex: value.startsWith('checker'),
      child: child,
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter(this.value, this.surface, this.checker);

  final String value;
  final Color surface;
  final Color checker;

  @override
  void paint(Canvas canvas, Size size) {
    final (base, alternate) = switch (value) {
      'checker' => (surface, checker),
      'checkerLight' => (const Color(0xFFFFFFFF), const Color(0xFFCCCCCC)),
      'checkerDark' => (const Color(0xFF2A2A2A), const Color(0xFF494949)),
      'black' => (Colors.black, null),
      'white' => (Colors.white, null),
      'gray' => (const Color(0xFF808080), null),
      'red' => (const Color(0xFFFF0000), null),
      'green' => (const Color(0xFF00FF00), null),
      'blue' => (const Color(0xFF0000FF), null),
      _ => (
        value.startsWith('#') && CanvasImageBackgroundNotifier.isValid(value)
            ? Color(0xFF000000 | int.parse(value.substring(1), radix: 16))
            : Colors.transparent,
        null,
      ),
    };
    if (base == Colors.transparent) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    if (alternate != null) {
      final paint = Paint()..color = alternate;
      const cell = 6.0;
      for (var row = 0; row * cell < size.height; row++) {
        for (var x = (row % 2) * cell; x < size.width; x += cell * 2) {
          canvas.drawRect(Rect.fromLTWH(x, row * cell, cell, cell), paint);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      value != old.value || surface != old.surface || checker != old.checker;
}
