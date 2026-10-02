import 'package:flutter/material.dart';
import 'settings_ui_theme.dart';

class SettingsDialogFrame extends StatelessWidget {
  const SettingsDialogFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.width = 440,
    this.height,
  });
  final String title;
  final Widget child;
  final List<Widget> actions;
  final double width;
  final double? height;
  @override
  Widget build(BuildContext context) => Theme(
    data: settingsUiTheme(Theme.of(context)),
    child: Builder(
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width,
            maxHeight: MediaQuery.sizeOf(context).height - 64,
          ),
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(child: child),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: actions,
                    ),
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

class SettingsChoice<T> {
  const SettingsChoice(this.value, this.label, {this.description, this.icon});
  final T value;
  final String label;
  final String? description;
  final IconData? icon;
}

class SettingsChoiceRow extends StatelessWidget {
  const SettingsChoiceRow({
    super.key,
    required this.label,
    this.description,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected
              ? colors.primary.withValues(alpha: .08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: colors.onSurfaceVariant),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: selected ? colors.primary : colors.onSurface,
                          ),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 18,
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: colors.primary,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showSettingsChoice<T>({
  required BuildContext context,
  required String title,
  required T value,
  required List<SettingsChoice<T>> choices,
}) => showDialog<T>(
  context: context,
  builder: (context) => SettingsDialogFrame(
    title: title,
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in choices)
            SettingsChoiceRow(
              label: option.label,
              description: option.description,
              icon: option.icon,
              selected: value == option.value,
              onTap: () => Navigator.pop(context, option.value),
            ),
        ],
      ),
    ),
  ),
);
