import 'package:flutter/material.dart';

/// Flat paired settings groups, stacked when reading space becomes too narrow.
class SettingsColumns extends StatelessWidget {
  const SettingsColumns({
    super.key,
    required this.left,
    required this.right,
    this.leftFraction = .5,
  });

  final Widget left, right;
  final double leftFraction;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      if (constraints.maxWidth < 740 * scale) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [left, const SizedBox(height: 20), right],
        );
      }
      const gap = 49.0;
      final leftWidth = (constraints.maxWidth - gap) * leftFraction;
      final rtl = Directionality.of(context) == TextDirection.rtl;
      return Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: leftWidth, child: left),
              const SizedBox(width: gap),
              Expanded(child: right),
            ],
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: rtl ? null : leftWidth + gap / 2,
            right: rtl ? leftWidth + gap / 2 : null,
            width: 1,
            child: ColoredBox(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: .5),
            ),
          ),
        ],
      );
    },
  );
}
