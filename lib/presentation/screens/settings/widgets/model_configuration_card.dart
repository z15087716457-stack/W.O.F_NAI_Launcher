import 'package:flutter/material.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../prompt_assistant/models/model_catalog_entry.dart';
import 'model_parameter_fields.dart' show reasoningChoices;
import 'model_compact_dropdown.dart';
import 'model_request_overrides_editor.dart';
import '../../../prompt_assistant/models/model_request_overrides.dart';

class ModelConfigurationCard extends StatefulWidget {
  const ModelConfigurationCard({
    super.key,
    required this.value,
    required this.protocol,
    required this.onChanged,
    required this.onValidationChanged,
    this.enabled = true,
    this.requestDraft,
    this.onRequestDraftChanged,
    this.onRequestValidationChanged,
  });
  final ModelConfig value;
  final ProviderProtocol protocol;
  final ValueChanged<ModelConfig> onChanged;
  final ValueChanged<String?> onValidationChanged;
  final bool enabled;
  final ModelRequestDraft? requestDraft;
  final ValueChanged<ModelRequestDraft>? onRequestDraftChanged;
  final ValueChanged<String?>? onRequestValidationChanged;
  @override
  State<ModelConfigurationCard> createState() => _ModelConfigurationCardState();
}

class _ModelConfigurationCardState extends State<ModelConfigurationCard> {
  late ModelConfig _model;
  late final TextEditingController _alias, _context, _output;
  @override
  void initState() {
    super.initState();
    _model = widget.value;
    _alias = TextEditingController(
      text: _model.displayName == _model.name ? '' : _model.displayName,
    );
    _context = TextEditingController(
      text: _model.contextWindow?.toString() ?? '',
    );
    _output = TextEditingController(
      text: _model.maxOutputTokens?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant ModelConfigurationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value.contextWindow != oldWidget.value.contextWindow &&
        _context.text == (oldWidget.value.contextWindow?.toString() ?? '')) {
      _context.text = widget.value.contextWindow?.toString() ?? '';
    }
    if (widget.value.maxOutputTokens != oldWidget.value.maxOutputTokens &&
        _output.text == (oldWidget.value.maxOutputTokens?.toString() ?? '')) {
      _output.text = widget.value.maxOutputTokens?.toString() ?? '';
    }
    _model = widget.value;
  }

  @override
  void dispose() {
    _alias.dispose();
    _context.dispose();
    _output.dispose();
    super.dispose();
  }

  String? _capacityError(TextEditingController controller, int? limit) {
    if (controller.text.trim().isEmpty) return null;
    final value = int.tryParse(controller.text.trim());
    if (value == null || value <= 0) return '请输入正整数';
    if (limit != null && value > limit) return '目录上限 ${modelTokenLabel(limit)}';
    if (controller == _output &&
        _model.contextWindow != null &&
        value > _model.contextWindow!) {
      return '输出不能超过上下文窗口';
    }
    return null;
  }

  void _emit(ModelConfig next, String field) {
    next = next.copyWith(
      customFields: {
        ..._model.preservedFields,
        field,
        if (field == 'reasoningEfforts' &&
            next.reasoningEffort != _model.reasoningEffort)
          'reasoningEffort',
      },
    );
    setState(() => _model = next);
    widget.onValidationChanged(
      _capacityError(_context, next.catalogEntry?.contextLimit) ??
          _capacityError(_output, next.catalogEntry?.outputLimit) ??
          RequestParameters.fromModel(next).validateFor(widget.protocol),
    );
    widget.onChanged(next);
  }

  Widget _label(String text, [String? help]) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(text, style: Theme.of(context).textTheme.labelSmall),
      if (help != null) ...[
        const SizedBox(width: 4),
        Tooltip(
          message: help,
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(
            Icons.help_outline,
            size: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );
  InputDecoration _decoration({String? hint, String? error}) => InputDecoration(
    isDense: true,
    filled: true,
    fillColor: Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: .55),
    hintText: hint,
    errorText: error,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide.none,
    ),
  );
  Widget _segment(String label, bool selected, VoidCallback? action) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: TextButton(
          onPressed: widget.enabled ? action : null,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 27),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            foregroundColor: selected
                ? colors.surface
                : colors.onSurfaceVariant,
            backgroundColor: selected ? colors.onSurface : Colors.transparent,
            disabledForegroundColor: colors.onSurfaceVariant.withValues(
              alpha: .3,
            ),
            textStyle: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontSize: 10.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: Text(label, maxLines: 1),
        ),
      ),
    );
  }

  Widget _tokenField(bool contextWindow) {
    final controller = contextWindow ? _context : _output;
    final limit = contextWindow
        ? _model.catalogEntry?.contextLimit
        : _model.catalogEntry?.outputLimit;
    final presets = contextWindow
        ? [128000, 256000, 312000, 500000, 1000000]
        : [4000, 8000, 16000, 32000, 128000];
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
      contextWindow ? 'contextWindow' : 'maxOutputTokens',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(contextWindow ? '上下文窗口' : '最大输出'),
        const SizedBox(height: 4),
        TextField(
          key: contextWindow
              ? ValueKey('context-${_model.name}')
              : const Key('parameter-max-tokens'),
          controller: controller,
          enabled: widget.enabled,
          style: Theme.of(context).textTheme.bodySmall,
          keyboardType: TextInputType.number,
          decoration:
              _decoration(
                hint: '未标注',
                error: _capacityError(controller, limit),
              ).copyWith(
                suffixText: 'tokens',
                suffixStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          onChanged: (_) => update(),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final n in presets)
              _segment(
                modelTokenLabel(n),
                controller.text == '$n',
                limit != null && n > limit
                    ? null
                    : () {
                        controller.text = '$n';
                        update();
                      },
              ),
          ],
        ),
      ],
    );
  }

  Widget _thinkingHeader(List<String> choices) {
    final current = _model.reasoningEffort;
    final defaults = {if (current != null) current, ...choices}.toList();
    final protocol = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('思考协议'),
        const SizedBox(height: 4),
        ModelCompactDropdown<ModelReasoningProtocol>(
          key: ValueKey('reasoning-protocol-${_model.name}'),
          value: _model.reasoningProtocol,
          choices: [
            const ModelDropdownChoice(ModelReasoningProtocol.standard, '标准'),
            ModelDropdownChoice(
              ModelReasoningProtocol.adaptive,
              '自适应',
              enabled: widget.protocol == ProviderProtocol.anthropicMessages,
            ),
          ],
          onChanged: widget.enabled
              ? (value) => _emit(
                  _model.copyWith(reasoningProtocol: value),
                  'reasoningProtocol',
                )
              : null,
        ),
      ],
    );
    final effort = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('默认思考等级'),
        const SizedBox(height: 4),
        ModelCompactDropdown<String>(
          key: ValueKey('default-effort-${_model.name}-${choices.join('-')}'),
          value: current ?? '',
          choices: [
            const ModelDropdownChoice('', '默认'),
            for (final value in defaults)
              ModelDropdownChoice(value, value == 'none' ? 'off' : value),
          ],
          onChanged: widget.enabled
              ? (value) => _emit(
                  _model.copyWith(
                    reasoningEffort: value,
                    clearReasoningEffort: value == '',
                  ),
                  'reasoningEffort',
                )
              : null,
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 18),
        _label(
          '思考设置',
          _model.catalogEntry?.reasoningEfforts == null
              ? '目录未标注，可手动开启'
              : '已按本地目录勾选支持的等级；可按实际接口调整。',
        ),
        const SizedBox(height: 7),
        LayoutBuilder(
          builder: (context, bounds) =>
              bounds.maxWidth < 300 * MediaQuery.textScalerOf(context).scale(1)
              ? Column(children: [protocol, const SizedBox(height: 8), effort])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: protocol),
                    const SizedBox(width: 8),
                    Expanded(child: effort),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        _label('支持的等级'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final possible = reasoningChoices(widget.protocol);
    final choices = _model.reasoningEfforts ?? const <String>[];
    final colors = Theme.of(context).colorScheme;
    Widget capability(
      String label,
      bool? value,
      ValueChanged<bool> change, [
      String? help,
    ]) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 24,
          child: Checkbox(
            value: value == true,
            onChanged: widget.enabled ? (v) => change(v!) : null,
            activeColor: colors.onSurface,
            checkColor: colors.surface,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 4),
        _label(label, help),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('别名', '在显示模型名称的地方生效；请求仍使用模型 ID。'),
          const SizedBox(height: 4),
          TextField(
            key: ValueKey('alias-${_model.name}'),
            controller: _alias,
            enabled: widget.enabled,
            style: Theme.of(context).textTheme.bodySmall,
            decoration: _decoration(hint: '例如 fast'),
            onChanged: (value) => _emit(
              _model.copyWith(
                displayName: value.trim().isEmpty ? _model.name : value,
              ),
              'displayName',
            ),
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxWidth <
                    300 * MediaQuery.textScalerOf(context).scale(1)
                ? Column(
                    children: [
                      _tokenField(true),
                      const SizedBox(height: 8),
                      _tokenField(false),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _tokenField(true)),
                      const SizedBox(width: 8),
                      Expanded(child: _tokenField(false)),
                    ],
                  ),
          ),
          const SizedBox(height: 9),
          _thinkingHeader(choices),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: .35),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                for (final effort in [
                  'none',
                  'minimal',
                  'low',
                  'medium',
                  'high',
                  'xhigh',
                  'max',
                ])
                  _segment(
                    effort == 'none' ? 'off' : effort,
                    choices.contains(effort),
                    possible.contains(effort)
                        ? () {
                            final next = [...choices];
                            choices.contains(effort)
                                ? next.remove(effort)
                                : next.add(effort);
                            _emit(
                              _model.copyWith(
                                reasoningEfforts: next,
                                clearReasoningEffort:
                                    _model.reasoningEffort != null &&
                                    !next.contains(_model.reasoningEffort),
                              ),
                              'reasoningEfforts',
                            );
                          }
                        : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          const Divider(height: 12),
          ModelRequestOverridesEditor(
            modelId: _model.name,
            value: _model.requestOverrides ?? ModelRequestOverrides.empty,
            draft: widget.requestDraft,
            enabled: widget.enabled,
            onDraftChanged: widget.onRequestDraftChanged,
            onChanged: (value) => _emit(
              _model.copyWith(requestOverrides: value),
              'requestOverrides',
            ),
            onValidationChanged:
                widget.onRequestValidationChanged ?? widget.onValidationChanged,
            capabilities: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 5,
              children: [
                _label('能力'),
                capability(
                  '图片',
                  _model.supportsVision,
                  (v) => _emit(
                    _model.copyWith(supportsVision: v),
                    'supportsVision',
                  ),
                ),
                capability(
                  '原生网络搜索',
                  _model.supportsNativeSearch,
                  (v) => _emit(
                    _model.copyWith(supportsNativeSearch: v),
                    'supportsNativeSearch',
                  ),
                  '应用尚未适配此连接的原生搜索；不代表厂商网站或其他 API 不支持搜索。',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
