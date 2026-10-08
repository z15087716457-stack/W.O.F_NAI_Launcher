import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../themes/studio_typography.dart';
import '../../common/dashed_rounded_border.dart';
import '../../common/studio_icons.dart';
import '../../common/translation_icon.dart';
import '../../common/uiux_prototype_icon.dart';
import '../blocks/prompt_block_appearance.dart';
import 'dna_icon.dart';

enum PromptPillSize {
  regular,
  large;

  double get height => this == regular ? 20 : 24;
  double get fontSize => this == regular ? 12 : 13;
  double get iconSize => this == regular ? 12 : 13;
  double get radius => this == regular ? 5 : 6;
  double get gap => this == regular ? 3 : 4;
  EdgeInsets get padding => this == regular
      ? const EdgeInsets.only(left: 4, right: 6)
      : const EdgeInsets.only(left: 6, right: 8);
}

/// The same compact visual in editors, the library and the floating palette.
/// Interaction remains with the host; multiline labels are reserved for the
/// palette's existing translated reading, never for inline block instances.
class PromptPill extends StatelessWidget {
  const PromptPill({
    super.key,
    required this.title,
    required this.color,
    this.appearance = PromptBlockAppearance.classic,
    this.enabled = true,
    this.icon,
    this.locked = false,
    this.showRollBadge = false,
    this.rollBadgeIcon = Icons.casino_outlined,
    this.evolutionEnabled = false,
    this.allowEvolutionToggle = false,
    this.isAttachedUc = false,
    this.variant = PromptPillVariant.normal,
    this.size = PromptPillSize.regular,
    this.active = false,
    this.focused = false,
    this.leading,
    this.label,
    this.trailing,
    this.multiline = false,
  });

  final String title;
  final Color color;
  final String appearance;
  final bool enabled;
  final IconData? icon;
  final bool locked;
  final bool showRollBadge;
  final IconData rollBadgeIcon;
  final bool evolutionEnabled;
  final bool allowEvolutionToggle;
  final bool isAttachedUc;
  final PromptPillVariant variant;
  final PromptPillSize size;
  final bool active;
  final bool focused;
  final Widget? leading;
  final Widget? label;
  final Widget? trailing;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final normal = variant == PromptPillVariant.normal;
    final dark = theme.brightness == Brightness.dark;
    final translation = appearance == PromptBlockAppearance.translation;
    final solid = appearance == PromptBlockAppearance.solid;
    final dashed = !normal || !enabled;
    final (border, fill, ink, glyph) = switch (variant) {
      PromptPillVariant.missing => (
        colors.error.withValues(alpha: .7),
        colors.error.withValues(alpha: .12),
        colors.error,
        Icons.error_outline,
      ),
      PromptPillVariant.unknown => (
        colors.outline.withValues(alpha: .6),
        Colors.transparent,
        colors.onSurfaceVariant,
        Icons.help_outline,
      ),
      PromptPillVariant.normal when !enabled => (
        colors.onSurfaceVariant.withValues(alpha: .7),
        Colors.transparent,
        colors.onSurfaceVariant,
        icon ?? StudioIcons.promptBlocks,
      ),
      PromptPillVariant.normal => (
        translation
            ? colors.outlineVariant
            : solid
            ? color
            : color.withValues(alpha: .45),
        active && appearance == PromptBlockAppearance.classic
            ? color.withValues(alpha: .16)
            : PromptBlockAppearance.fill(
                appearance,
                color,
                dark: dark,
                translationSurface: colors.surfaceContainerHighest,
              ),
        PromptBlockAppearance.text(
          appearance,
          color,
          colors.onSurface,
          dark: dark,
        ),
        icon ?? StudioIcons.promptBlocks,
      ),
    };
    final iconColor = translation && normal && enabled
        ? colors.onSurfaceVariant
        : !normal || !enabled || solid
        ? ink
        : color;
    final textStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(
          fontFamily: StudioTypography.cjk,
          fontFamilyFallback: const [
            StudioTypography.sans,
            StudioTypography.korean,
          ],
          fontSize: size.fontSize,
          fontWeight: translation ? FontWeight.w500 : FontWeight.w600,
          height: multiline ? 1.25 : 1,
          color: ink,
          decoration: normal && !enabled
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        );
    final content = Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size.radius),
        side: dashed ? BorderSide.none : BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: normal && enabled
            ? PromptBlockPatternPainter(appearance: appearance, color: color)
            : null,
        foregroundPainter: dashed
            ? DashedRoundedBorderPainter(
                color: border,
                dashedColor: border,
                radius: Radius.circular(size.radius),
                topRounded: true,
                bottomRounded: true,
                solidLeft: false,
                solidRight: false,
                dashedAll: true,
              )
            : null,
        child: Padding(
          padding: multiline
              ? size.padding.add(
                  const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
                )
              : size.padding.add(const EdgeInsets.all(1)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(color: iconColor, size: size.iconSize),
                child: !normal
                    ? UiuxPrototypeIcon(
                        glyph,
                        size: size.iconSize,
                        color: iconColor,
                        strokeWidth: 2,
                      )
                    : leading ??
                          (translation
                              ? TranslationIcon(
                                  size: size.iconSize,
                                  color: iconColor,
                                  style: TranslationIconStyle.pill,
                                )
                              : UiuxPrototypeIcon(
                                  glyph,
                                  size: size.iconSize,
                                  color: iconColor,
                                  strokeWidth: 2,
                                )),
              ),
              SizedBox(width: size.gap),
              Flexible(
                child: DefaultTextStyle(
                  style: textStyle,
                  child:
                      label ??
                      Text(
                        title,
                        style: textStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                ),
              ),
              if (normal && isAttachedUc) ...[
                SizedBox(width: size.gap + 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'UC',
                    style: textStyle.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
              if (normal && evolutionEnabled && allowEvolutionToggle) ...[
                SizedBox(width: size.gap + 1),
                DnaIcon(
                  size: 11,
                  color:
                      (enabled ? DnaIcon.prototypeColor(theme.brightness) : ink)
                          .withValues(alpha: .8),
                ),
              ] else if (normal && locked) ...[
                SizedBox(width: size.gap + 1),
                UiuxPrototypeIcon(
                  Icons.lock_outline,
                  size: 11,
                  color: ink.withValues(alpha: .8),
                  strokeWidth: 2.2,
                ),
              ] else if (normal && showRollBadge) ...[
                SizedBox(width: size.gap + 1),
                UiuxPrototypeIcon(
                  rollBadgeIcon,
                  size: 11,
                  color: ink.withValues(alpha: .8),
                  strokeWidth: 2.2,
                ),
              ],
              if (trailing != null) ...[SizedBox(width: size.gap), trailing!],
            ],
          ),
        ),
      ),
    );
    final frame = multiline
        ? ConstrainedBox(
            constraints: BoxConstraints(minHeight: size.height),
            child: content,
          )
        : SizedBox(height: size.height, child: content);
    return CustomPaint(
      painter: active && normal && enabled
          ? PromptPillShadowPainter(
              color: color.withValues(alpha: .3),
              radius: size.radius,
              spreadRadius: 2,
            )
          : null,
      foregroundPainter: focused
          ? _PillFocusPainter(colors.primary, size.radius)
          : null,
      child: frame,
    );
  }
}

class _PillFocusPainter extends CustomPainter {
  const _PillFocusPainter(this.color, this.radius);
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(2),
      Radius.circular(radius + 2),
    ),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );

  @override
  bool shouldRepaint(_PillFocusPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Visual feedback without changing the drag data, anchor or target geometry.
class PromptPillDragFeedback extends StatelessWidget {
  const PromptPillDragFeedback({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -math.pi / 90,
    child: CustomPaint(
      painter: PromptPillShadowPainter(
        // HTML --shadow: rgba(0,0,0,.14) light / .45 dark.
        color: Colors.black.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? .45 : .14,
        ),
        radius: PromptPillSize.regular.radius,
        offset: const Offset(0, 6),
        blurRadius: 16,
      ),
      child: child,
    ),
  );
}

/// CSS `box-shadow` semantics: painted only outside the pill outline, so the
/// translucent block fill is not darkened by the shadow beneath it.
class PromptPillShadowPainter extends CustomPainter {
  const PromptPillShadowPainter({
    required this.color,
    required this.radius,
    this.offset = Offset.zero,
    this.blurRadius = 0,
    this.spreadRadius = 0,
  });

  final Color color;
  final double radius;
  final Offset offset;
  final double blurRadius;
  final double spreadRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final reach = blurRadius * 2 + spreadRadius + offset.distance + 2;
    canvas
      ..save()
      ..clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect((Offset.zero & size).inflate(reach)),
          Path()..addRRect(outline),
        ),
      );
    final paint = Paint()..color = color;
    if (blurRadius > 0) {
      // Chromium maps a CSS blur length to a Skia radius of half that length.
      paint.maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        Shadow.convertRadiusToSigma(blurRadius / 2),
      );
    }
    canvas
      ..drawRRect(outline.shift(offset).inflate(spreadRadius), paint)
      ..restore();
  }

  @override
  bool shouldRepaint(PromptPillShadowPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.offset != offset ||
      oldDelegate.blurRadius != blurRadius ||
      oldDelegate.spreadRadius != spreadRadius;
}

enum PromptPillVariant { normal, missing, unknown }
