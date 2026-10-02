import 'package:flutter/material.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';

List<String> reasoningChoices(ProviderProtocol protocol) => switch (protocol) {
  ProviderProtocol.openaiChatCompletions || ProviderProtocol.openaiResponses =>
    ['none', 'minimal', 'low', 'medium', 'high', 'xhigh', 'max'],
  ProviderProtocol.anthropicMessages => [
    'none',
    'low',
    'medium',
    'high',
    'xhigh',
    'max',
  ],
  ProviderProtocol.geminiGenerateContent => [
    'none',
    'minimal',
    'low',
    'medium',
    'high',
  ],
  ProviderProtocol.ollamaChatCompletions => [],
};

class ModelParameterFields extends StatefulWidget {
  const ModelParameterFields({
    super.key,
    required this.value,
    required this.onChanged,
    this.protocol = ProviderProtocol.openaiChatCompletions,
    this.readOnly = false,
    this.onValidationChanged,
    this.samplingOnly = false,
  });
  final RequestParameters value;
  final ValueChanged<RequestParameters> onChanged;
  final ProviderProtocol protocol;
  final bool readOnly;
  final bool samplingOnly;
  final ValueChanged<String?>? onValidationChanged;
  @override
  State<ModelParameterFields> createState() => _ModelParameterFieldsState();
}

class _ModelParameterFieldsState extends State<ModelParameterFields> {
  late final TextEditingController _temperature, _topP, _tokens;
  String? _reasoning;
  @override
  void initState() {
    super.initState();
    _temperature = TextEditingController(
      text: widget.value.temperature?.toString() ?? '',
    );
    _topP = TextEditingController(text: widget.value.topP?.toString() ?? '');
    _tokens = TextEditingController(
      text: widget.value.maxOutputTokens?.toString() ?? '',
    );
    _reasoning = widget.value.reasoningEffort;
  }

  @override
  void dispose() {
    _temperature.dispose();
    _topP.dispose();
    _tokens.dispose();
    super.dispose();
  }

  void _changed(String _) {
    final parameters = RequestParameters(
      temperature: double.tryParse(_temperature.text),
      topP: double.tryParse(_topP.text),
      maxOutputTokens: int.tryParse(_tokens.text),
      reasoningEffort: _reasoning,
    );
    final malformed =
        (_temperature.text.trim().isNotEmpty &&
            parameters.temperature == null) ||
        (_topP.text.trim().isNotEmpty && parameters.topP == null) ||
        (_tokens.text.trim().isNotEmpty && parameters.maxOutputTokens == null);
    widget.onValidationChanged?.call(
      malformed
          ? '参数包含无效数字，请回到参数页修正。'
          : parameters.validateFor(widget.protocol),
    );
    widget.onChanged(parameters);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth > 430
          ? (constraints.maxWidth - 16) / 2
          : constraints.maxWidth;
      final choices = reasoningChoices(widget.protocol);
      return Wrap(
        spacing: 16,
        runSpacing: 18,
        children: [
          SizedBox(
            width: width,
            child: TextFormField(
              key: const Key('parameter-temperature'),
              controller: _temperature,
              readOnly: widget.readOnly,
              decoration: InputDecoration(
                labelText: 'Temperature',
                helperText:
                    widget.protocol == ProviderProtocol.anthropicMessages
                    ? '0–1；与 Top P 选一项'
                    : '0–2；留空继承',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: _changed,
              validator: (value) {
                if (value?.trim().isEmpty != false) return null;
                final number = double.tryParse(value!);
                final max =
                    widget.protocol == ProviderProtocol.anthropicMessages
                    ? 1
                    : 2;
                return number == null ||
                        !number.isFinite ||
                        number < 0 ||
                        number > max
                    ? '请输入 0–$max 之间的数字'
                    : null;
              },
            ),
          ),
          SizedBox(
            width: width,
            child: TextFormField(
              key: const Key('parameter-top-p'),
              controller: _topP,
              readOnly: widget.readOnly,
              decoration: const InputDecoration(
                labelText: 'Top P',
                helperText: '大于 0、不超过 1；留空继承',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: _changed,
              validator: (value) {
                if (value?.trim().isEmpty != false) return null;
                final number = double.tryParse(value!);
                return number == null ||
                        !number.isFinite ||
                        number <= 0 ||
                        number > 1
                    ? '请输入大于 0、不超过 1 的数字'
                    : null;
              },
            ),
          ),
          if (!widget.samplingOnly)
            SizedBox(
              width: width,
              child: TextFormField(
                key: const Key('parameter-max-tokens'),
                controller: _tokens,
                readOnly: widget.readOnly,
                decoration: const InputDecoration(
                  labelText: '最大输出 token',
                  helperText: '留空继承模型默认',
                ),
                keyboardType: TextInputType.number,
                onChanged: _changed,
                validator: (value) =>
                    value?.trim().isEmpty != false ||
                        ((int.tryParse(value!) ?? 0) > 0)
                    ? null
                    : '请输入大于 0 的整数',
              ),
            ),
          if (!widget.samplingOnly && choices.isNotEmpty)
            SizedBox(
              width: width,
              child: DropdownButtonFormField<String>(
                key: const Key('parameter-reasoning'),
                initialValue: _reasoning ?? '',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '推理强度',
                  helperText: '仅适用于支持推理参数的模型',
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('继承模型默认')),
                  for (final value in {
                    ...choices,
                    if (_reasoning != null) _reasoning!,
                  })
                    DropdownMenuItem(value: value, child: Text(value)),
                ],
                onChanged: widget.readOnly
                    ? null
                    : (value) {
                        setState(() => _reasoning = value == '' ? null : value);
                        _changed('');
                      },
              ),
            ),
        ],
      );
    },
  );
}
