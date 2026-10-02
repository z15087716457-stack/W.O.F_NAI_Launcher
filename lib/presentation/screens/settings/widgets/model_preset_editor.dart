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
    required this.onClone,
  });
  final TaskPresetConfig preset;
  final ValueChanged<bool> onDirtyChanged;
  final ValueChanged<String> onSaved;
  final ValueChanged<TaskPresetConfig> onClone;
  @override
  ConsumerState<ModelPresetEditor> createState() => _ModelPresetEditorState();
}

class _ModelPresetEditorState extends ConsumerState<ModelPresetEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _prompt;
  bool _busy = false;
  String? _message;
  late bool _newPreset;
  late String? _observedPreset;
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
  void _changed(String _) => widget.onDirtyChanged(
    !_builtin &&
        (_newPreset ||
            _name.text != widget.preset.name ||
            _prompt.text != widget.preset.prompt),
  );
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
      await ref.read(promptAssistantConfigProvider.notifier).savePreset(_draft);
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

  Future<void> _compare() => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: SizedBox(
        width: 900,
        height: MediaQuery.sizeOf(context).height * .75,
        child: Column(
          children: [
            ManagementHeading(
              '与内置方案对照',
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  Widget text(String title, String body) =>
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 12),
                            SelectableText(
                              body,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(height: 1.65),
                            ),
                          ],
                        ),
                      );
                  return constraints.maxWidth > 600
                      ? Row(
                          children: [
                            Expanded(
                              child: text(
                                'Studio 默认',
                                widget.preset.task.builtinPrompt,
                              ),
                            ),
                            const VerticalDivider(width: 1),
                            Expanded(child: text('当前编辑', _prompt.text)),
                          ],
                        )
                      : DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              const TabBar(
                                tabs: [
                                  Tab(text: 'Studio 默认'),
                                  Tab(text: '当前编辑'),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    text(
                                      'Studio 默认',
                                      widget.preset.task.builtinPrompt,
                                    ),
                                    text('当前编辑', _prompt.text),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ManagementHeading(
            _builtin ? 'Studio 内置方案 · 只读' : '自定义预设',
            description: widget.preset.task.title,
            actions: [
              TextButton.icon(
                onPressed: _compare,
                icon: Icon(
                  _builtin ? Icons.lock_outline : Icons.compare_arrows,
                  size: 16,
                ),
                label: const Text('对照默认'),
              ),
              if (_builtin)
                FilledButton.icon(
                  key: const Key('preset-clone'),
                  onPressed: () => widget.onClone(
                    TaskPresetConfig(
                      id: 'preset-${DateTime.now().microsecondsSinceEpoch}',
                      name: '${widget.preset.task.title} · 自定义',
                      task: widget.preset.task,
                      prompt: widget.preset.prompt,
                    ),
                  ),
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: const Text('复制并编辑'),
                )
              else
                FilledButton(
                  key: const Key('preset-save'),
                  onPressed: _busy ? null : _save,
                  child: const Text('保存'),
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
                          ? '内置规则已锁定，始终保留默认内容。复制为自定义后可编辑。'
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
