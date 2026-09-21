import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'studio_icon_registry.dart';

/// Geist artwork with the same IconData, layout and accessibility contract as Icon.
/// Unmapped specialist icons keep their existing artwork until a suitable asset
/// exists. Keeping the original IconData also preserves stored category choices.
class StudioIcon extends Icon {
  const StudioIcon(
    super.icon, {
    super.key,
    super.size,
    super.fill,
    super.weight,
    super.grade,
    super.opticalSize,
    super.color,
    super.shadows,
    super.semanticLabel,
    super.textDirection,
    super.applyTextScaling,
    super.blendMode,
    super.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final asset = StudioIconRegistry.assetFor(icon);
    final theme = IconTheme.of(context);
    // Preserve the original renderer for callers needing font-specific effects.
    if (asset == null ||
        blendMode != null ||
        (shadows ?? theme.shadows)?.isNotEmpty == true) {
      return super.build(context);
    }
    final direction = textDirection ?? Directionality.of(context);
    final baseSize = size ?? theme.size ?? 24;
    final scaledSize = (applyTextScaling ?? theme.applyTextScaling ?? false)
        ? MediaQuery.textScalerOf(context).scale(baseSize)
        : baseSize;
    final baseColor = color ?? theme.color ?? Colors.black;
    final resolvedColor = baseColor.withValues(
      alpha: baseColor.a * (theme.opacity ?? 1),
    );
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: scaledSize,
          // A caption button or InputDecorator can force the outer box to be
          // larger than size. Like Flutter's Icon, loosen those constraints
          // for the artwork without shrinking the button's layout/hit region.
          child: Center(
            child: SvgPicture.asset(
              asset,
              width: scaledSize,
              height: scaledSize,
              colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
              matchTextDirection: icon!.matchTextDirection,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    ).withDirection(direction);
  }
}

extension on Widget {
  Widget withDirection(TextDirection direction) =>
      Directionality(textDirection: direction, child: this);
}
