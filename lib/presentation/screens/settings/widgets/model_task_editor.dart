import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../prompt_assistant/models/prompt_task_definitions.dart';
import '../../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../../prompt_assistant/services/prompt_assistant_service.dart';
import 'model_management_widgets.dart';
import 'model_parameter_fields.dart';

class ModelTaskEditor extends ConsumerStatefulWidget {
  const ModelTaskEditor({
    super.key,
    required this.task,
    required this.onDirtyChanged,
    required this.onEditPreset,
  });
  final LauncherInterface task;
  final ValueChanged<bool> onDirtyChanged;
  final ValueChanged<String> onEditPreset;
  @override
  ConsumerState<ModelTaskEditor> createState() => _ModelTaskEditorState();
}

class _ModelTaskEditorState extends ConsumerState<ModelTaskEditor> {
  final _form = GlobalKey<FormState>();
  late InterfaceSlotConfig _slot;
  late String _initial;
  late String _observedSlot;
  int _tab = 0;
  bool _busy = false;
  String? _message, _testResult;
  String? _parameterError, _testSession;
  late final PromptAssistantService _service;
  @override
  void initState() {
    super.initState();
    _service = ref.read(promptAssistantServiceProvider);
    final config = ref.read(promptAssistantConfigProvider);
    _observedSlot = jsonEncode(config.interfaceFor(widget.task).toJson());
    _slot = config
        .interfaceFor(widget.task)
        .copyWith(presetId: presetFor(config, widget.task).id);
    _initial = jsonEncode(_slot.toJson());
  }

  @override
  void dispose() {
    final session = _testSession;
    if (session != null) _service.cancelCurrentTask(sessionId: session);
    super.dispose();
  }

  bool _validate() {
    if (_parameterError != null) {
      setState(() {
        _message = _parameterError;
        _tab = 1;
      });
      return false;
    }
    return _form.currentState!.validate();
  }

  void _edit(InterfaceSlotConfig value) {
    setState(() {
      _slot = value;
      _message = null;
    });
    widget.onDirtyChanged(
      _parameterError != null || jsonEncode(_slot.toJson()) != _initial,
    );
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _busy = true);
    try {
      if (jsonEncode(
            ref
                .read(promptAssistantConfigProvider)
                .interfaceFor(widget.task)
                .toJson(),
          ) !=
          _observedSlot) {
        throw StateError('功能配置已在别处修改，请重新打开后编辑。');
      }
      await ref
          .read(promptAssistantConfigProvider.notifier)
          .saveInterface(widget.task, _slot);
      if (!mounted) return;
      _initial = jsonEncode(_slot.toJson());
      _observedSlot = _initial;
      widget.onDirtyChanged(false);
      setState(() => _message = '配置已保存');
    } catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test(TaskPresetConfig preset) async {
    if (!_validate()) return;
    setState(() {
      _busy = true;
      _testResult = null;
      _message = null;
    });
    try {
      _testSession = 'profile-test-${DateTime.now().microsecondsSinceEpoch}';
      final result = await _service.testTaskDraft(
        widget.task,
        _slot,
        preset,
        sessionId: _testSession!,
      );
      if (mounted) setState(() => _testResult = result);
    } catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      _testSession = null;
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(promptAssistantConfigProvider);
    final theme = Theme.of(context);
    final choices = [
      for (final provider in config.providers.where((item) => item.enabled))
        for (final model in config.modelsForProvider(providerId: provider.id))
          if (!model.isPlaceholder) (provider: provider, model: model),
    ];
    final selected = choices
        .where(
          (item) =>
              item.provider.id == _slot.providerId &&
              item.model.name == _slot.model,
        )
        .firstOrNull;
    final presets = [
      widget.task.builtinPreset,
      ...config.presets.where((item) => item.task == widget.task),
    ];
    final preset =
        presets.where((item) => item.id == _slot.presetId).firstOrNull ??
        widget.task.builtinPreset;
    final protocol =
        selected?.provider.protocol ?? ProviderProtocol.openaiChatCompletions;
    final effective = selected == null
        ? null
        : _slot.parameters.applyTo(preset.parameters.applyTo(selected.model));
    final changed = jsonEncode(_slot.toJson()) != _initial;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ManagementHeading(
            widget.task.title,
            description: changed ? '有未保存的修改' : widget.task.description,
            actions: [
              TextButton.icon(
                key: const Key('task-test'),
                onPressed: _busy || selected == null
                    ? null
                    : () => _test(preset),
                icon: const Icon(Icons.science_outlined, size: 16),
                label: const Text('测试预设'),
              ),
              FilledButton(
                key: const Key('task-save'),
                onPressed: _busy ? null : _save,
                child: const Text('保存'),
              ),
            ],
          ),
          ManagementTabs(
            labels: const ['模型与预设', '参数', '提示词与输出'],
            selected: _tab,
            onSelected: (value) => setState(() => _tab = value),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_message != null) ...[
                    Text(
                      _message!,
                      key: const Key('task-message'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _message == '配置已保存'
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_tab == 0) ...[
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        'task-route-${widget.task.name}-${selected?.model.name}',
                      ),
                      initialValue: selected == null
                          ? null
                          : jsonEncode([
                              selected.provider.id,
                              selected.model.name,
                            ]),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '服务商与模型',
                        helperText: '仅列出启用服务中的已选模型',
                      ),
                      items: [
                        for (final item in choices)
                          DropdownMenuItem(
                            value: jsonEncode([
                              item.provider.id,
                              item.model.name,
                            ]),
                            child: Text(
                              '${item.provider.name} · ${item.model.displayName}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) {
                              final route = (jsonDecode(value!) as List)
                                  .cast<String>();
                              _edit(
                                _slot.copyWith(
                                  providerId: route[0],
                                  model: route[1],
                                ),
                              );
                            },
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      key: ValueKey('task-preset-${preset.id}'),
                      initialValue: preset.id,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: '使用预设'),
                      items: [
                        for (final item in presets)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              item.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) => _edit(_slot.copyWith(presetId: value)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => widget.onEditPreset(preset.id),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('查看与编辑预设'),
                        ),
                        if (!preset.id.startsWith('builtin:'))
                          TextButton(
                            onPressed: () => _edit(
                              _slot.copyWith(presetId: widget.task.builtinId),
                            ),
                            child: const Text('恢复内置预设'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (widget.task != LauncherInterface.promptReverse)
                      DropdownButtonFormField<String>(
                        key: const Key('task-language'),
                        initialValue: _slot.targetLanguage,
                        decoration: const InputDecoration(labelText: '目标语言'),
                        items: const [
                          DropdownMenuItem(
                            value: 'auto',
                            child: Text('跟随界面语言'),
                          ),
                          DropdownMenuItem(value: 'zh', child: Text('简体中文')),
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'ja', child: Text('日本語')),
                          DropdownMenuItem(value: 'ko', child: Text('한국어')),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) =>
                                  _edit(_slot.copyWith(targetLanguage: value)),
                      ),
                    if (widget.task == LauncherInterface.promptReverse)
                      Text(
                        '结合原文落实修改，输出英文生成提示词。',
                        style: theme.textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 28),
                    Text('当前生效', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(
                      selected == null
                          ? '尚未选择可用模型'
                          : '${selected.provider.name} · ${selected.model.name}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preset.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (_tab == 1) ...[
                    Text('本功能参数', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Text(
                      '留空继承预设与模型默认值。只发送明确设置的参数。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ModelParameterFields(
                      key: ValueKey(
                        'task-parameters-${widget.task.name}-${protocol.name}',
                      ),
                      value: _slot.parameters,
                      protocol: protocol,
                      onValidationChanged: (error) => _parameterError = error,
                      onChanged: (value) =>
                          _edit(_slot.copyWith(parameters: value)),
                    ),
                    const SizedBox(height: 28),
                    Text('生效参数', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 10),
                    SelectableText(
                      const JsonEncoder.withIndent('  ').convert({
                        'Temperature': effective?.temperature ?? '服务默认',
                        'Top P': effective?.topP ?? '服务默认',
                        '最大输出 token': effective?.maxOutputTokens ?? '服务默认',
                        '推理强度': effective?.reasoningEffort ?? '服务默认',
                      }),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (_tab == 2) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '翻译策略',
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onEditPreset(preset.id),
                          child: const Text('编辑预设'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      preset.prompt,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.65),
                    ),
                    const SizedBox(height: 24),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('应用输出约定'),
                      subtitle: const Text('返回字段与校验规则由应用维护'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SelectableText(
                            PromptAssistantService.outputContractFor(
                              widget.task,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_testResult != null) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text('测试结果', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SelectableText(
                      _testResult!,
                      key: const Key('task-test-result'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
