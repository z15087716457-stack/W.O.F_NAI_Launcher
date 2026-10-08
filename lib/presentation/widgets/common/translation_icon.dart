import 'package:flutter/material.dart';

import 'uiux_prototype_icon.dart';

enum TranslationIconStyle { prototype, pill }

/// Translation artwork from the selected prototypes. The host owns activity
/// status and tooltips; the old animated artwork is no longer retained.
class TranslationIcon extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final dimension = size ?? theme.size ?? 24;
    final ink = color ?? theme.color ?? Theme.of(context).colorScheme.onSurface;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: dimension,
        child: Center(
          child: style == TranslationIconStyle.pill
              ? RichText(
                  textScaler: TextScaler.noScaling,
                  text: TextSpan(
                    // The prototype uses this glyph as artwork, not a label.
                    text: '译',
                    style: TextStyle(
                      fontFamily: 'HarmonyOS Sans SC',
                      fontSize: dimension * 10 / 12,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: ink.withValues(
                        alpha: ink.a * (theme.opacity ?? 1),
                      ),
                    ),
                  ),
                )
              : UiuxPrototypeIcon(
                  Icons.translate,
                  size: dimension,
                  color: color,
                ),
        ),
      ),
    );
  }
}
