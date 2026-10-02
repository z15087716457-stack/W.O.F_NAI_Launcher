import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../prompt_assistant/models/prompt_task_definitions.dart';
import '../../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../../prompt_assistant/services/prompt_assistant_service.dart';
import 'model_management_widgets.dart';

class ModelPresetEditor extends ConsumerStatefulWidget {
  const ModelPresetEditor({
    super.key,
    required this.preset,
    required this.onDirtyChanged,
    required this.onSaved,
    required this.onCreate,
  });
  final TaskPresetConfig preset;
  final ValueChanged<bool> onDirtyChanged;
  final ValueChanged<String> onSaved;
  final ValueChanged<LauncherInterface> onCreate;
  @override
  ConsumerState<ModelPresetEditor> createState() => _ModelPresetEditorState();
}

class _ModelPresetEditorState extends ConsumerState<ModelPresetEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _prompt;
  bool _busy = false;
  String? _message;
  Offset? _creationPosition;
  late bool _newPreset;
  late String? _observedPreset;
  late String? _observedInterfacePreset;
  int _tab = 0;
  bool get _builtin => widget.preset.id.startsWith('builtin:');
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.preset.name);
    _prompt = TextEditingController(text: widget.preset.prompt);
    _newPreset =
        !_builtin &&
        !ref
            .read(promptAssistantConfigProvider)
            .presets
            .any((item) => item.id == widget.preset.id);
    _observedPreset = _newPreset ? null : widget.preset.toJson().toString();
    _observedInterfacePreset = ref
        .read(promptAssistantConfigProvider)
        .interfaceFor(widget.preset.task)
        .presetId;
  }

  @override
  void dispose() {
    _name.dispose();
    _prompt.dispose();
    super.dispose();
  }

  TaskPresetConfig get _draft => TaskPresetConfig(
    id: widget.preset.id,
    name: _name.text.trim(),
    task: widget.preset.task,
    prompt: _prompt.text.trim(),
  );
  void _changed(String _) {
    setState(() {});
    widget.onDirtyChanged(
      !_builtin &&
          (_newPreset ||
              _name.text != widget.preset.name ||
              _prompt.text != widget.preset.prompt),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final latest = ref
          .read(promptAssistantConfigProvider)
          .presets
          .where((item) => item.id == widget.preset.id)
          .firstOrNull;
      if (latest?.toJson().toString() != _observedPreset) {
        throw StateError('预设已在别处修改，请重新打开后编辑。');
      }
      if (_newPreset &&
          ref
                  .read(promptAssistantConfigProvider)
                  .interfaceFor(widget.preset.task)
                  .presetId !=
              _observedInterfacePreset) {
        throw StateError('接口使用的预设已在别处修改，请重新打开后新建。');
      }
      await ref
          .read(promptAssistantConfigProvider.notifier)
          .savePreset(_draft, applyToInterface: _newPreset);
      if (mounted) {
        widget.onDirtyChanged(false);
        widget.onSaved(widget.preset.id);
      }
    } catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ManagementHeading(
            _builtin ? widget.preset.task.title : _name.text,
            description: _builtin ? '内置 · 只读' : '用户',
            actions: [
              GestureDetector(
                onTapDown: (details) =>
                    _creationPosition = details.globalPosition,
                child: FilledButton.icon(
                  key: const Key('preset-create'),
                  onPressed: _busy
                      ? null
                      : () async {
                          final task = await showInterfacePresetMenu(
                            context,
                            globalPosition: _creationPosition,
                          );
                          _creationPosition = null;
                          if (mounted && task != null) widget.onCreate(task);
                        },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('新建接口预设'),
                ),
              ),
            ],
          ),
          ManagementTabs(
            labels: const ['提示词', '输出约定'],
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
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_tab == 0) ...[
                    TextFormField(
                      key: const Key('preset-name'),
                      controller: _name,
                      readOnly: _builtin,
                      decoration: const InputDecoration(labelText: '预设名称'),
                      onChanged: _changed,
                      validator: (value) =>
                          value?.trim().isEmpty != false ? '请输入名称' : null,
                    ),
                    const SizedBox(height: 24),
                    Text('行为与翻译策略', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(
                      _builtin
                          ? '内置规则已锁定。新建接口预设后可编辑自己的翻译偏好。'
                          : '此处修改翻译偏好；返回格式由应用单独维护。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('preset-prompt'),
                      controller: _prompt,
                      readOnly: _builtin,
                      minLines: 12,
                      maxLines: 24,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.65),
                      decoration: const InputDecoration(
                        alignLabelWithHint: true,
                        hintText: '输入翻译策略',
                      ),
                      onChanged: _changed,
                      validator: (value) =>
                          value?.trim().isEmpty != false ? '提示词不能为空' : null,
                    ),
                    if (!_builtin)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            _prompt.text = widget.preset.task.builtinPrompt;
                            _changed('');
                          },
                          child: const Text('将策略恢复为内置内容'),
                        ),
                      ),
                  ],
                  if (_tab == 1) ...[
                    Text('应用输出约定', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(
                      '此部分保证翻译结果可以回填和显示，由应用维护。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SelectableText(
                      PromptAssistantService.outputContractFor(
                        widget.preset.task,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.65),
                    ),
                  ],
                  if (!_builtin) ...[
                    const SizedBox(height: 22),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        key: const Key('preset-save'),
                        onPressed: _busy ? null : _save,
                        child: const Text('保存预设'),
                      ),
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
