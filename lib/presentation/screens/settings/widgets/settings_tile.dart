import 'package:flutter/material.dart';
import 'settings_toggle.dart';
import 'settings_hover_line.dart';
export 'settings_toggle.dart';

/// A setting row: readable labels on the left, its value or action on the right.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.selected = false,
    this.dense = false,
    this.contentPadding,
    this.isThreeLine = false,
    this.controlWrapWidth = 520,
    this.hoverFeedback,
  });
  final Widget title;
  final Widget? subtitle, leading, trailing;
  final VoidCallback? onTap;
  final bool enabled, selected, dense, isThreeLine;
  final EdgeInsetsGeometry? contentPadding;
  final double controlWrapWidth;

  /// Informational or temporarily unavailable controls can suppress feedback.
  final bool? hoverFeedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labels = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultTextStyle(
          style: theme.textTheme.bodyMedium!.copyWith(
            fontSize: 13,
            color: enabled
                ? scheme.onSurface
                : scheme.onSurfaceVariant.withValues(alpha: .55),
          ),
          child: title,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          DefaultTextStyle(
            style: theme.textTheme.bodySmall!.copyWith(
              fontSize: 11,
              height: 1.5,
              color: scheme.onSurfaceVariant.withValues(
                alpha: enabled ? .8 : .5,
              ),
            ),
            child: subtitle!,
          ),
        ],
      ],
    );
    final control =
        trailing ??
        (onTap == null
            ? null
            : Icon(
                Icons.chevron_right,
                size: 17,
                color: scheme.onSurfaceVariant,
              ));
    return SettingsHoverLine(
      enabled:
          enabled && (hoverFeedback ?? (onTap != null || trailing != null)),
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: .06)
            : Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            padding:
                contentPadding ??
                EdgeInsets.symmetric(vertical: dense ? 10 : 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: .5),
                ),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < controlWrapWidth &&
                    control != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      labels,
                      const SizedBox(height: 10),
                      Align(alignment: Alignment.centerRight, child: control),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: labels),
                    if (control != null) ...[
                      const SizedBox(width: 24),
                      control,
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    this.secondary,
    required this.value,
    required this.onChanged,
    this.contentPadding,
    this.dense = false,
  });
  final Widget title;
  final Widget? subtitle, secondary;
  final bool value, dense;
  final ValueChanged<bool>? onChanged;
  final EdgeInsetsGeometry? contentPadding;
  @override
  Widget build(BuildContext context) => SettingsTile(
    title: title,
    subtitle: subtitle,
    enabled: onChanged != null,
    dense: dense,
    contentPadding: contentPadding,
    onTap: onChanged == null ? null : () => onChanged!(!value),
    trailing: SettingsToggle(value: value, onChanged: onChanged),
    controlWrapWidth: 0,
  );
}
