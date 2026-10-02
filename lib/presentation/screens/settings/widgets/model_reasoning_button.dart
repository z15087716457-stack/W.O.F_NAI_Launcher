import 'package:flutter/material.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../prompt_assistant/models/prompt_task_definitions.dart';

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
    final colors = Theme.of(context).colorScheme;
    final choices = model?.availableReasoningEfforts ?? const <String>[];
    final unsupported = model?.reasoningEfforts?.isEmpty == true;
    final selected = choices.contains(value) ? value : null;
    final label = unsupported
        ? '不支持'
        : selected == null
        ? '跟随模型'
        : reasoningEffortLabel(selected);
    return PopupMenuButton<String>(
      key: const Key('task-reasoning'),
      tooltip: unsupported ? '此模型不支持思考调节' : '思考强度',
      shadowColor: colors.shadow.withValues(alpha: .14),
      enabled: enabled && model != null && !unsupported,
      position: PopupMenuPosition.under,
      onSelected: (v) => onChanged(v == 'inherit' ? null : v),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          height: 30,
          child: Text('思考强度', style: Theme.of(context).textTheme.labelSmall),
        ),
        _item(
          context,
          'inherit',
          '跟随模型',
          selected == null,
          subtitle: '模型默认：${reasoningEffortLabel(model?.reasoningEffort)}',
        ),
        if (choices.isNotEmpty) const PopupMenuDivider(),
        for (final choice in choices)
          _item(
            context,
            choice,
            reasoningEffortLabel(choice),
            selected == choice,
          ),
        if (choices.isEmpty)
          const PopupMenuItem<String>(
            enabled: false,
            child: Text('可调档位尚未确认\n可在服务商的模型配置中设置'),
          ),
      ],
      child: Semantics(
        button: true,
        enabled: enabled && model != null && !unsupported,
        label: '思考强度：$label',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: unsupported
                ? colors.surfaceContainerLow
                : colors.primary.withValues(alpha: .07),
            border: Border.all(
              color: unsupported
                  ? colors.outlineVariant
                  : colors.primary.withValues(alpha: .23),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 17,
                color: unsupported ? colors.onSurfaceVariant : colors.primary,
              ),
              const SizedBox(width: 7),
              Text(
                '思考 · $label',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: unsupported ? colors.onSurfaceVariant : colors.primary,
                ),
              ),
              if (!unsupported) ...[
                const SizedBox(width: 7),
                Icon(Icons.expand_more, size: 15, color: colors.primary),
              ],
            ],
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
