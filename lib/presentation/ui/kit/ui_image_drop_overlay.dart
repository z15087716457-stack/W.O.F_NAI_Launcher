import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import 'ui_card.dart';
import 'ui_colors.dart';
import 'ui_controls.dart';
import 'ui_glyph.dart';
import 'ui_text.dart';

/// 全窗口拖入与读取提示；读取期间保留输入屏障。
class UiImageDropOverlay extends StatelessWidget {
  const UiImageDropOverlay({super.key, required this.processing});

  final bool processing;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: processing,
        child: IgnorePointer(
          child: ColoredBox(
            key: const Key('image-drop-backdrop'),
            color: Colors.black.withValues(alpha: .4),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: 400,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 180),
                    child: Semantics(
                      liveRegion: true,
                      child: UiCard(
                        key: const Key('image-drop-notice'),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              key: const Key('image-drop-icon'),
                              width: 40,
                              height: 40,
                              child: Center(
                                child: processing
                                    ? const UiSpinner(size: 32)
                                    : UiGlyph(
                                        UiGlyphs.image,
                                        size: 40,
                                        color: c.accent,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Size both labels so switching phase cannot move
                            // the card when localized text wraps.
                            IndexedStack(
                              index: processing ? 1 : 0,
                              alignment: Alignment.center,
                              children: [
                                _DropMessage(
                                  title: l.drop_hint,
                                  subtitle: l.drop_hintSubtitle,
                                ),
                                _DropMessage(
                                  title: l.drop_processing,
                                  subtitle: l.drop_processingSubtitle,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropMessage extends StatelessWidget {
  const _DropMessage({required this.title, required this.subtitle});

  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: UiText.sans(
            18,
            weight: FontWeight.w600,
            color: c.ink,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: UiText.sans(13, color: c.muted, height: 1.5),
        ),
      ],
    );
  }
}
