import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';
import 'settings_tile.dart';
import 'settings_ui_theme.dart';

/// A readable path with explicit actions; narrow settings put Change below it.
class SettingsPathTile extends StatelessWidget {
  const SettingsPathTile({
    super.key,
    required this.title,
    required this.path,
    required this.onOpen,
    required this.onChange,
    this.onReset,
    this.defaultLabel,
  });

  final String title, path;
  final VoidCallback onOpen, onChange;
  final VoidCallback? onReset;
  final String? defaultLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final field = Container(
      key: const Key('settings-path-field'),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 5, 5, 5),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              path,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
          if (defaultLabel != null) ...[
            const SizedBox(width: 8),
            Text(
              defaultLabel!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(width: 5),
          IconButton(
            key: const Key('settings-path-open'),
            tooltip: context.l10n.settings_openFolder,
            onPressed: onOpen,
            icon: const Icon(Icons.folder_open_outlined, size: 18),
          ),
          if (onReset != null)
            IconButton(
              key: const Key('settings-path-reset'),
              tooltip: context.l10n.common_reset,
              onPressed: onReset,
              icon: const Icon(Icons.close, size: 18),
            ),
        ],
      ),
    );
    final change = OutlinedButton(
      key: const Key('settings-path-change'),
      onPressed: onChange,
      child: Text(settingsText(context, '更改', 'Change', '変更')),
    );
    return SettingsTile(
      title: Text(title),
      onTap: onChange,
      subtitle: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560 * scale) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                field,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: change),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: field),
              const SizedBox(width: 10),
              change,
            ],
          );
        },
      ),
      showNavigationArrow: false,
    );
  }
}
