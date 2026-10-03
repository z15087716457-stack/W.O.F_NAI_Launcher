import 'package:flutter/material.dart';

/// Side-labelled settings on wide screens, stacked labels on narrow screens.
class SettingsLabeledGroup extends StatelessWidget {
  const SettingsLabeledGroup({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    this.showDivider = true,
  });

  final String title, description;
  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final line = theme.colorScheme.outlineVariant.withValues(alpha: .5);
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            height: 1.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    return Padding(
      padding: EdgeInsets.only(bottom: showDivider ? 26 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 740 * scale) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [label, const SizedBox(height: 12), child],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 168 * scale,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: label,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsetsDirectional.only(start: 26 * scale),
                      decoration: BoxDecoration(
                        border: BorderDirectional(
                          start: BorderSide(color: line),
                        ),
                      ),
                      child: child,
                    ),
                  ),
                ],
              );
            },
          ),
          if (showDivider) ...[
            const SizedBox(height: 24),
            Divider(height: 1, color: line),
          ],
        ],
      ),
    );
  }
}
