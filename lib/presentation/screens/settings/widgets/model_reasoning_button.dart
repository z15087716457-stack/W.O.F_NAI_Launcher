import 'package:flutter/material.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../prompt_assistant/models/prompt_task_definitions.dart';
import 'model_compact_dropdown.dart';
import 'settings_hover_line.dart';
import '../../../../core/utils/localization_extension.dart';

class ModelReasoningButton extends StatelessWidget {
  const ModelReasoningButton({
    super.key,
    required this.model,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final ModelConfig? model;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final choices = model?.availableReasoningEfforts ?? const <String>[];
    final unsupported = model?.reasoningEfforts?.isEmpty == true;
    final selected = choices.contains(value) ? value : null;
    final label = unsupported
        ? context.l10n.modelReasoning_unsupported
        : selected == null
        ? model?.reasoningEffort == null
              ? context.l10n.modelReasoning_followModel
              : context.l10n.modelReasoning_followModelLevel(
                  reasoningEffortLabel(context.l10n, model!.reasoningEffort),
                )
        : reasoningEffortLabel(context.l10n, selected);
    final canChoose = enabled && model != null && !unsupported;
    return SettingsHoverLine(
      enabled: canChoose,
      child: PopupMenuButton<String>(
        key: const Key('task-reasoning'),
        tooltip: unsupported
            ? context.l10n.modelReasoning_notAdjustable
            : context.l10n.modelReasoning_strength,
        shadowColor: colors.shadow.withValues(alpha: .14),
        elevation: 3,
        shape: modelMenuShape,
        color: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        menuPadding: const EdgeInsets.symmetric(vertical: 6),
        enabled: canChoose,
        position: PopupMenuPosition.under,
        onSelected: (v) => onChanged(v == 'inherit' ? null : v),
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            enabled: false,
            height: 30,
            child: Text(
              context.l10n.modelReasoning_strength,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          _item(
            context,
            'inherit',
            context.l10n.modelReasoning_followModel,
            selected == null,
            subtitle: context.l10n.modelReasoning_modelDefault(
              reasoningEffortLabel(context.l10n, model?.reasoningEffort),
            ),
          ),
          if (choices.isNotEmpty) const PopupMenuDivider(),
          for (final choice in choices)
            _item(
              context,
              choice,
              reasoningEffortLabel(context.l10n, choice),
              selected == choice,
            ),
          if (choices.isEmpty)
            PopupMenuItem<String>(
              enabled: false,
              child: Text(context.l10n.modelReasoning_levelsUnknown),
            ),
        ],
        child: Semantics(
          button: true,
          enabled: canChoose,
          label: context.l10n.modelReasoning_strengthValue(label),
          child: Container(
            constraints: const BoxConstraints(minHeight: 42),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: .7),
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    label,
                    key: const Key('task-reasoning-value'),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: canChoose
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.expand_more,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _item(
    BuildContext context,
    String value,
    String label,
    bool selected, {
    String? subtitle,
  }) {
    final colors = Theme.of(context).colorScheme;
    return PopupMenuItem<String>(
      key: ValueKey('task-reasoning-$value'),
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: .08) : null,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected ? colors.primary : colors.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 16,
              child: selected
                  ? Icon(Icons.check, size: 16, color: colors.primary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
