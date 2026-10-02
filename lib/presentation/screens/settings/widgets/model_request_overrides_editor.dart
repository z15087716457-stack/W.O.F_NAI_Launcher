import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../prompt_assistant/models/model_request_overrides.dart';
import '../../../themes/studio_typography.dart';

class ModelRequestDraft {
  const ModelRequestDraft(this.headers, this.body, {this.openBody});
  final List<(String, String)> headers, body;
  final bool? openBody;
  Object get fingerprint => [
    headers.map((r) => [r.$1, r.$2]).toList(),
    body.map((r) => [r.$1, r.$2]).toList(),
  ];
}

class _RequestField {
  _RequestField(String key, String value)
    : key = TextEditingController(text: key),
      value = TextEditingController(text: value);
  final TextEditingController key, value;
  String? error;
  void dispose() {
    key.dispose();
    value.dispose();
  }
}

class ModelRequestOverridesEditor extends StatefulWidget {
  const ModelRequestOverridesEditor({
    super.key,
    required this.modelId,
    required this.value,
    required this.capabilities,
    required this.onChanged,
    required this.onValidationChanged,
    this.draft,
    this.onDraftChanged,
    this.enabled = true,
  });
  final String modelId;
  final ModelRequestOverrides value;
  final ModelRequestDraft? draft;
  final Widget capabilities;
  final ValueChanged<ModelRequestOverrides> onChanged;
  final ValueChanged<String?> onValidationChanged;
  final ValueChanged<ModelRequestDraft>? onDraftChanged;
  final bool enabled;
  @override
  State<ModelRequestOverridesEditor> createState() =>
      _ModelRequestOverridesEditorState();
}

class _ModelRequestOverridesEditorState
    extends State<ModelRequestOverridesEditor> {
  late final List<_RequestField> _headers, _body;
  bool? _openBody;
  @override
  void initState() {
    super.initState();
    _openBody = widget.draft?.openBody;
    _headers = [
      if (widget.draft case final draft?)
        for (final r in draft.headers) _RequestField(r.$1, r.$2)
      else
        for (final e in widget.value.headers.entries)
          _RequestField(e.key, e.value),
    ];
    _body = [
      if (widget.draft case final draft?)
        for (final r in draft.body) _RequestField(r.$1, r.$2)
      else
        for (final e in widget.value.body.entries)
          _RequestField(
            e.key,
            const JsonEncoder.withIndent('  ').convert(e.value),
          ),
    ];
    _read();
  }

  @override
  void dispose() {
    for (final row in [..._headers, ..._body]) {
      row.dispose();
    }
    super.dispose();
  }

  ({ModelRequestOverrides value, String? error}) _read() {
    final headers = <String, String>{}, names = <String>{};
    final body = <String, dynamic>{};
    String? error;
    for (final row in _headers) {
      row.error = null;
      final key = row.key.text.trim(), value = row.value.text;
      if (key.isEmpty && value.isEmpty) continue;
      row.error = ModelRequestOverrides.headerError(key, value);
      if (!names.add(key.toLowerCase())) row.error = '请求头名称重复';
      error ??= row.error;
      if (row.error == null) headers[key] = value;
    }
    for (final row in _body) {
      row.error = null;
      final key = row.key.text.trim(), value = row.value.text.trim();
      if (key.isEmpty && value.isEmpty) continue;
      if (key.isEmpty) {
        row.error = '请输入字段名';
      } else if (body.containsKey(key)) {
        row.error = '字段名重复';
      } else {
        try {
          body[key] = jsonDecode(value);
          if (key == 'model' && body[key] != widget.modelId) {
            row.error = '模型 ID 请通过模型列表设置';
          } else if (key == 'stream' && body[key] != false) {
            row.error = '当前接口使用非流式请求，stream 应为 false';
          }
        } on FormatException {
          row.error = '请输入有效的 JSON 值';
        }
      }
      error ??= row.error;
    }
    final next = ModelRequestOverrides(
      headers: Map.unmodifiable(headers),
      body: Map.unmodifiable(body),
    );
    error ??= next.validate(widget.modelId);
    return (value: next, error: error);
  }

  void _changed() {
    final parsed = _read();
    widget.onDraftChanged?.call(
      ModelRequestDraft(
        [for (final r in _headers) (r.key.text, r.value.text)],
        [for (final r in _body) (r.key.text, r.value.text)],
        openBody: _openBody,
      ),
    );
    widget.onChanged(parsed.value);
    widget.onValidationChanged(parsed.error);
    setState(() {});
  }

  Widget _button(bool body) {
    final active = _openBody == body;
    final colors = Theme.of(context).colorScheme;
    return TextButton(
      key: Key(body ? 'model-custom-body' : 'model-custom-headers'),
      onPressed: widget.enabled
          ? () => setState(() => _openBody = active ? null : body)
          : null,
      style: TextButton.styleFrom(
        foregroundColor: colors.onSurfaceVariant,
        backgroundColor: colors.onSurface.withValues(alpha: active ? .1 : .045),
        minimumSize: const Size(0, 29),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: Theme.of(context).textTheme.labelSmall,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(body ? '自定义请求体' : '自定义请求头'),
          const SizedBox(width: 3),
          Icon(active ? Icons.expand_less : Icons.expand_more, size: 13),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint, [String? error]) => InputDecoration(
    hintText: hint,
    errorText: error,
    isDense: true,
    filled: true,
    fillColor: Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: .25),
    contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  );

  Widget _entry(_RequestField row, int index, bool body) {
    final style = Theme.of(context).textTheme.bodySmall;
    final keyField = TextField(
      key: ValueKey('${body ? 'body' : 'header'}-key-$index'),
      controller: row.key,
      enabled: widget.enabled,
      style: style,
      decoration: _decoration(body ? '字段名' : '请求头名称'),
      onChanged: (_) => _changed(),
    );
    final valueField = TextField(
      key: ValueKey('${body ? 'body' : 'header'}-value-$index'),
      controller: row.value,
      enabled: widget.enabled,
      style: body
          ? style?.copyWith(fontFamily: StudioTypography.mono, fontSize: 11)
          : style,
      decoration: _decoration(body ? '值（JSON）' : '值', row.error),
      minLines: body ? 2 : 1,
      maxLines: body ? 4 : 1,
      keyboardType: body ? TextInputType.multiline : TextInputType.text,
      onChanged: (_) => _changed(),
    );
    final remove = IconButton(
      key: ValueKey('${body ? 'body' : 'header'}-remove-$index'),
      tooltip: '删除此项',
      onPressed: widget.enabled
          ? () {
              (body ? _body : _headers).remove(row);
              row.dispose();
              _changed();
            }
          : null,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 27, minHeight: 30),
      icon: const Icon(Icons.delete_outline, size: 16),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: LayoutBuilder(
        builder: (context, bounds) =>
            bounds.maxWidth < 270 * MediaQuery.textScalerOf(context).scale(1)
            ? Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: keyField),
                      remove,
                    ],
                  ),
                  const SizedBox(height: 6),
                  valueField,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: body ? 2 : 1, child: keyField),
                  const SizedBox(width: 8),
                  Expanded(flex: body ? 3 : 1, child: valueField),
                  const SizedBox(width: 4),
                  remove,
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final buttons = Wrap(
      spacing: 6,
      runSpacing: 5,
      alignment: WrapAlignment.end,
      children: [_button(false), _button(true)],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, bounds) =>
              bounds.maxWidth >= 430 * MediaQuery.textScalerOf(context).scale(1)
              ? Row(
                  children: [
                    Expanded(child: widget.capabilities),
                    const SizedBox(width: 8),
                    buttons,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    widget.capabilities,
                    const SizedBox(height: 5),
                    Align(alignment: Alignment.centerRight, child: buttons),
                  ],
                ),
        ),
        if (_openBody case final body?) ...[
          const SizedBox(height: 8),
          Container(
            key: Key(body ? 'model-body-editor' : 'model-headers-editor'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: .45),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: .35),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      body ? '请求体' : '请求头',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${(body ? _body : _headers).length} 项',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                for (var i = 0; i < (body ? _body : _headers).length; i++)
                  _entry((body ? _body : _headers)[i], i, body),
                if (body) ...[
                  const SizedBox(height: 6),
                  Text(
                    '支持字符串、数字、布尔值、数组和对象',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: Key(
                      body ? 'model-add-body-field' : 'model-add-header',
                    ),
                    onPressed: widget.enabled
                        ? () {
                            (body ? _body : _headers).add(
                              _RequestField('', ''),
                            );
                            _changed();
                          }
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onSurfaceVariant,
                      minimumSize: const Size(0, 29),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: Theme.of(context).textTheme.labelSmall,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 15),
                    label: Text(body ? '添加请求体字段' : '添加请求头'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
