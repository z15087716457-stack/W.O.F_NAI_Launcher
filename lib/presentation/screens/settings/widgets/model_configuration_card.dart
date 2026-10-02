import 'package:flutter/material.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import 'model_parameter_fields.dart';

/// All request controls belong to this model. Empty values use server defaults.
class ModelConfigurationCard extends StatefulWidget {
  const ModelConfigurationCard({
    super.key,
    required this.value,
    required this.protocol,
    required this.onChanged,
    required this.onValidationChanged,
    this.enabled = true,
  });
  final ModelConfig value;
  final ProviderProtocol protocol;
  final ValueChanged<ModelConfig> onChanged;
  final ValueChanged<String?> onValidationChanged;
  final bool enabled;
  @override
  State<ModelConfigurationCard> createState() => _ModelConfigurationCardState();
}

class _ModelConfigurationCardState extends State<ModelConfigurationCard> {
  late ModelConfig _model;
  late final TextEditingController _context, _output;
  bool _advanced = false;
  String? _samplingError;
  @override
  void initState() {
    super.initState();
    _model = widget.value;
    _context = TextEditingController(
      text: _model.contextWindow?.toString() ?? '',
    );
    _output = TextEditingController(
      text: _model.maxOutputTokens?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _context.dispose();
    _output.dispose();
    super.dispose();
  }

  String? _numberError(TextEditingController controller) =>
      controller.text.trim().isEmpty ||
          (int.tryParse(controller.text.trim()) ?? 0) > 0
      ? null
      : '请输入正整数';
  void _emit(ModelConfig next) {
    setState(() => _model = next);
    widget.onValidationChanged(
      _numberError(_context) ??
          _numberError(_output) ??
          _samplingError ??
          RequestParameters.fromModel(next).validateFor(widget.protocol),
    );
    widget.onChanged(next);
  }

  Widget _tokenField(
    String label,
    TextEditingController controller,
    List<int> presets,
    bool contextWindow,
  ) {
    void update() => _emit(
      contextWindow
          ? _model.copyWith(
              contextWindow: int.tryParse(controller.text.trim()),
              clearContextWindow: controller.text.trim().isEmpty,
            )
          : _model.copyWith(
              maxOutputTokens: int.tryParse(controller.text.trim()),
              clearMaxOutputTokens: controller.text.trim().isEmpty,
            ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 7),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final n in [0, ...presets])
              ChoiceChip(
                label: Text(n == 0 ? '默认' : '${n ~/ 1000}K'),
                selected: controller.text == (n == 0 ? '' : '$n'),
                visualDensity: VisualDensity.compact,
                showCheckmark: false,
                color: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: .09)
                      : Theme.of(context).colorScheme.surface,
                ),
                labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: controller.text == (n == 0 ? '' : '$n')
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                onSelected: widget.enabled
                    ? (_) {
                        controller.text = n == 0 ? '' : '$n';
                        update();
                      }
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 7),
        TextField(
          key: contextWindow
              ? ValueKey('context-${_model.name}')
              : const Key('parameter-max-tokens'),
          controller: controller,
          enabled: widget.enabled,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '使用服务默认值',
            errorText: _numberError(controller),
          ),
          onChanged: (_) => update(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final choices = reasoningChoices(widget.protocol);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 18),
          TextFormField(
            key: ValueKey('alias-${_model.name}'),
            initialValue: _model.displayName,
            enabled: widget.enabled,
            decoration: const InputDecoration(labelText: '显示名称 / 别名'),
            onChanged: (value) => _emit(_model.copyWith(displayName: value)),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final fields = [
                _tokenField('上下文窗口 · 参考', _context, [128000, 256000], true),
                _tokenField('最大输出 · token', _output, [8000, 16000], false),
              ];
              return constraints.maxWidth <
                      310 * MediaQuery.textScalerOf(context).scale(1)
                  ? Column(
                      children: [
                        fields[0],
                        const SizedBox(height: 14),
                        fields[1],
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: fields[0]),
                        const SizedBox(width: 12),
                        Expanded(child: fields[1]),
                      ],
                    );
            },
          ),
          const SizedBox(height: 14),
          if (choices.isNotEmpty)
            DropdownButtonFormField<String>(
              key: const Key('parameter-reasoning'),
              initialValue: _model.reasoningEffort ?? '',
              isExpanded: true,
              decoration: const InputDecoration(labelText: '推理强度'),
              items: [
                const DropdownMenuItem(value: '', child: Text('使用服务默认值')),
                for (final value in {
                  ...choices,
                  if (_model.reasoningEffort != null) _model.reasoningEffort!,
                })
                  DropdownMenuItem(value: value, child: Text(value)),
              ],
              onChanged: widget.enabled
                  ? (value) => _emit(
                      _model.copyWith(
                        reasoningEffort: value,
                        clearReasoningEffort: value == '',
                      ),
                    )
                  : null,
            ),
          const SizedBox(height: 10),
          Text(
            '快捷数值可编辑；请按模型实际限制设置。上下文用于记录容量，留空参数由服务决定。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            key: const Key('model-advanced-toggle'),
            onPressed: () => setState(() => _advanced = !_advanced),
            icon: Icon(
              _advanced ? Icons.expand_less : Icons.expand_more,
              size: 16,
            ),
            label: const Text('采样与能力'),
          ),
          if (_advanced) ...[
            const SizedBox(height: 8),
            ModelParameterFields(
              value: RequestParameters.fromModel(_model),
              protocol: widget.protocol,
              samplingOnly: true,
              readOnly: !widget.enabled,
              onValidationChanged: (error) => _samplingError = error,
              onChanged: (value) => _emit(
                _model.copyWith(
                  temperature: value.temperature,
                  topP: value.topP,
                  clearTemperature: value.temperature == null,
                  clearTopP: value.topP == null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('模型能力', style: theme.textTheme.labelMedium),
            const SizedBox(height: 5),
            Text('按实际模型手动标注，未标注不会视为已支持。', style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _capability(
                  '图片输入',
                  _model.supportsVision,
                  (value) => _model.copyWith(
                    supportsVision: value,
                    clearSupportsVision: value == null,
                  ),
                ),
                _capability(
                  '工具调用',
                  _model.supportsTools,
                  (value) => _model.copyWith(
                    supportsTools: value,
                    clearSupportsTools: value == null,
                  ),
                ),
                _capability(
                  '结构化输出',
                  _model.supportsStructuredOutput,
                  (value) => _model.copyWith(
                    supportsStructuredOutput: value,
                    clearSupportsStructuredOutput: value == null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _capability(
    String label,
    bool? value,
    ModelConfig Function(bool?) update,
  ) => SizedBox(
    width: 145,
    child: DropdownButtonFormField<int>(
      initialValue: value == null
          ? 0
          : value
          ? 1
          : 2,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: const [
        DropdownMenuItem(value: 0, child: Text('未标注')),
        DropdownMenuItem(value: 1, child: Text('支持')),
        DropdownMenuItem(value: 2, child: Text('不支持')),
      ],
      onChanged: widget.enabled
          ? (value) => _emit(update(value == 0 ? null : value == 1))
          : null,
    ),
  );
}
