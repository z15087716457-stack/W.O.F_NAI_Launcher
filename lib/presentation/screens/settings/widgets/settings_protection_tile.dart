import 'package:flutter/material.dart';

import 'settings_hover_line.dart';
import 'settings_toggle.dart';

/// A protection control that can share the height of its matrix row.
class SettingsProtectionTile extends StatelessWidget {
  const SettingsProtectionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SettingsHoverLine(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          child: Container(
            constraints: BoxConstraints(
              minHeight: 108 * MediaQuery.textScalerOf(context).scale(1),
            ),
            padding: const EdgeInsets.symmetric(vertical: 22),
            alignment: Alignment.topLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 12),
                  child: Icon(
                    icon,
                    size: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          height: 1.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SettingsToggle(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
