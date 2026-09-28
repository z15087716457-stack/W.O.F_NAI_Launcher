import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';
import 'lab_logo_mark.dart';

/// LAB branding is reserved for the empty exploration gallery.
class ExploreGalleryWelcome extends StatelessWidget {
  const ExploreGalleryWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                    LabLogoMark(
                      // Pixel trails add width beyond the letter bodies.
                      // 340px matches the optical height of the 300px STUDIO mark.
                      width: math.min(340, width * .9),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'TIP',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: .32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.styleExplore_labTip,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
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
