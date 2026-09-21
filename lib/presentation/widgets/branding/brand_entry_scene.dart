import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_version.dart';
import '../../../core/utils/localization_extension.dart';
import '../../themes/brand_entry_theme.dart';
import '../../themes/studio_typography.dart';

/// The complete, original wordmark. The asset only removes empty source margins;
/// both the W.O.F block and the NAI STUDIO signature remain in their original ratio.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 360});
  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/wof_logo_full.png',
    width: width,
    height: width * 547 / 1111,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    semanticLabel: 'W.O.F NAI Studio',
  );
}

/// Shared architecture for sign-in and warmup: quiet technical marks at the
/// edges, a centered brand anchor and a small, readable control surface.
class BrandEntryScene extends ConsumerWidget {
  const BrandEntryScene({super.key, required this.child, this.loading = false});
  final Widget child;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(brandEntryBrightnessProvider);
    return Theme(
      data: BrandEntryTheme.forBrightness(brightness),
      child: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          final dark = brightness == Brightness.dark;
          return Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _EntryFramePainter(scheme.outline, dark),
                    ),
                  ),
                ),
                Positioned.fill(
                  top: 60,
                  bottom: 50,
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final logoWidth = math.min(
                          360.0,
                          constraints.maxWidth - 96,
                        );
                        return SingleChildScrollView(
                          key: const Key('brand_entry_scroll'),
                          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: math.max(
                                0,
                                constraints.maxHeight - 44,
                              ),
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 460,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    BrandLogo(width: logoWidth),
                                    const SizedBox(height: 22),
                                    Text(
                                      context.l10n.brand_entryTagline,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                            letterSpacing: 1.2,
                                          ),
                                    ),
                                    SizedBox(height: loading ? 52 : 32),
                                    child,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 22,
                  left: 28,
                  child: ExcludeSemantics(
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          color: BrandEntryTheme.blue,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          loading ? 'STUDIO / START' : 'STUDIO / ACCESS',
                          style: StudioTypography.data.copyWith(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 18,
                  child: IconButton(
                    key: const Key('brand_appearance_toggle'),
                    tooltip: dark
                        ? context.l10n.brand_switchToLight
                        : context.l10n.brand_switchToDark,
                    onPressed: () =>
                        ref.read(brandEntryBrightnessProvider.notifier).state =
                            dark ? Brightness.light : Brightness.dark,
                    icon: Icon(
                      dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 19,
                    ),
                  ),
                ),
                Positioned(
                  left: 28,
                  right: 28,
                  bottom: 20,
                  child: IgnorePointer(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.app_subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'v${AppVersion.versionName}',
                          style: StudioTypography.data.copyWith(
                            fontSize: 10,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EntryFramePainter extends CustomPainter {
  const _EntryFramePainter(this.color, this.dark);
  final Color color;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    // Keep artwork outside the form; wide screens get quiet framing rails.
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(28, size.height - 46),
      Offset(size.width - 28, size.height - 46),
      paint,
    );
    if (size.width < 780) return;
    final left = size.width / 2 - 300;
    final right = size.width / 2 + 300;
    for (final x in [left, right]) {
      canvas.drawLine(Offset(x, 76), Offset(x, size.height - 86), paint);
      for (final y in [76.0, size.height / 2, size.height - 86]) {
        canvas.drawLine(
          Offset(x - 4, y),
          Offset(x + 4, y),
          paint..color = color,
        );
        canvas.drawLine(Offset(x, y - 4), Offset(x, y + 4), paint);
        paint.color = color.withValues(alpha: 0.45);
      }
    }
    final squares = Paint()
      ..color = BrandEntryTheme.blue.withValues(alpha: dark ? 0.14 : 0.08);
    for (final point in [
      Offset(left - 48, 146),
      Offset(right + 38, size.height - 160),
    ]) {
      canvas.drawRect(Rect.fromLTWH(point.dx, point.dy, 5, 5), squares);
      canvas.drawRect(Rect.fromLTWH(point.dx + 9, point.dy + 9, 5, 5), squares);
      canvas.drawRect(Rect.fromLTWH(point.dx, point.dy + 18, 5, 5), squares);
    }
  }

  @override
  bool shouldRepaint(_EntryFramePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dark != dark;
}
