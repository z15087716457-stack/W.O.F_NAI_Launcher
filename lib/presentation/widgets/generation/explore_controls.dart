import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../themes/studio_typography.dart';
import 'explore_icon.dart';
import 'explore_text.dart';
import 'explore_style.dart';

/// Primitive controls use the A prototype's boxes, with no Material minimums.
class ExploreButton extends StatelessWidget {
  const ExploreButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
    this.background,
    this.border,
    this.height = 30,
    this.radius = 7,
    this.horizontal = 11,
    this.fontSize = 12.5,
    this.fontWeight = FontWeight.w500,
    this.ghost = false,
    this.trailing,
    this.expand = false,
    this.fullWidthCenter = false,
  });
  final String label;
  final Widget? icon, trailing;
  final VoidCallback? onPressed;
  final Color? color, background, border;
  final double height, radius, horizontal, fontSize;
  final FontWeight fontWeight;
  final bool ghost, expand, fullWidthCenter;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = color ?? colors.onSurface;
    return Opacity(
      opacity: onPressed == null ? .45 : 1,
      child: Material(
        color:
            background ??
            (ghost
                ? Colors.transparent
                : ExploreStyle.raised(Theme.of(context))),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: ghost
              ? BorderSide.none
              : BorderSide(color: border ?? colors.outlineVariant),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            width: fullWidthCenter ? double.infinity : null,
            height: height,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              child: IconTheme(
                data: IconThemeData(color: foreground, size: 15),
                child: Row(
                  mainAxisAlignment: fullWidthCenter
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 6)],
                    if (expand)
                      Expanded(
                        child: ExploreText(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: StudioTypography.body.copyWith(
                            color: foreground,
                            fontSize: fontSize,
                            fontWeight: fontWeight,
                          ),
                        ),
                      )
                    else if (fullWidthCenter)
                      ExploreText(
                        label,
                        maxLines: 1,
                        style: StudioTypography.body.copyWith(
                          color: foreground,
                          fontSize: fontSize,
                          fontWeight: fontWeight,
                        ),
                      )
                    else
                      Flexible(
                        fit: FlexFit.loose,
                        child: ExploreText(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StudioTypography.body.copyWith(
                            color: foreground,
                            fontSize: fontSize,
                            fontWeight: fontWeight,
                          ),
                        ),
                      ),
                    if (trailing != null) ...[
                      const SizedBox(width: 6),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ExploreIconButton extends StatelessWidget {
  const ExploreIconButton(
    this.icon, {
    super.key,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.background,
    this.size = 16,
    this.width = 28,
    this.height = 28,
    this.radius = 6,
    this.filled = false,
  });
  final String icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color, background;
  final double size, width, height, radius;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget button = Material(
      color: background ?? Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: width,
          height: height,
          child: Center(
            child: ExploreIcon(
              icon,
              size: size,
              filled: filled,
              color: color ?? colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}

class ExploreSection extends StatelessWidget {
  const ExploreSection({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.count,
    this.actions = const [],
  });
  final String title;
  final Widget child;
  final Widget? leading;
  final int? count;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 38,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 6)],
                  ExploreText(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    ExploreCount(count!),
                  ],
                  const Spacer(),
                  ...actions,
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class ExploreCount extends StatelessWidget {
  const ExploreCount(this.count, {super.key});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    height: 18,
    constraints: const BoxConstraints(minWidth: 18),
    padding: const EdgeInsets.symmetric(horizontal: 5),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(9),
    ),
    child: ExploreText(
      '$count',
      style: StudioTypography.data.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class ExploreKeyCap extends StatelessWidget {
  const ExploreKeyCap(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 18,
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          top: BorderSide(color: colors.outlineVariant),
          left: BorderSide(color: colors.outlineVariant),
          right: BorderSide(color: colors.outlineVariant),
          bottom: BorderSide(color: colors.outlineVariant, width: 2),
        ),
      ),
      child: ExploreText(
        label,
        style: StudioTypography.data.copyWith(
          fontSize: 10.5,
          height: 1,
          fontWeight: FontWeight.w500,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
