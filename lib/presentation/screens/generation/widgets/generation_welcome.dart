import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../widgets/branding/brand_entry_scene.dart';

/// Calm canvas empty state. A tip is chosen once per visit, never on a timer.
class GenerationWelcome extends StatefulWidget {
  const GenerationWelcome({super.key});

  @override
  State<GenerationWelcome> createState() => _GenerationWelcomeState();
}

class _GenerationWelcomeState extends State<GenerationWelcome> {
  final _tipIndex = math.Random().nextInt(3);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final tips = [
      l10n.generation_tipReuseBlocks,
      l10n.generation_tipBlockModes,
      l10n.generation_tipLockBlocks,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(0.0, math.min(400.0, constraints.maxWidth - 48));
        return Align(
          alignment: const Alignment(0, -.08),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandLogo(width: math.min(240, width * .7)),
                    const SizedBox(height: 32),
                    Text(
                      'TIP',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: .32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tips[_tipIndex],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: scheme.onSurface.withValues(alpha: .48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
