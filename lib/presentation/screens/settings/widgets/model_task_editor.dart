import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../prompt_assistant/models/prompt_task_definitions.dart';
import '../../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../../prompt_assistant/services/prompt_assistant_service.dart';
import 'model_management_widgets.dart';
import 'model_reasoning_button.dart';
import 'model_draft_save_controller.dart';
import 'model_compact_dropdown.dart';

typedef _ModelRoute = ({ProviderConfig provider, ModelConfig model});

class ModelTaskEditor extends ConsumerStatefulWidget {
  const ModelTaskEditor({
    super.key,
    required this.task,
    required this.onDirtyChanged,
    required this.onEditPreset,
    this.saveController,
  });
  final LauncherInterface task;
  final ValueChanged<bool> onDirtyChanged;
  final ValueChanged<String> onEditPreset;
  final ModelDraftSaveController? saveController;
  @override
  ConsumerState<ModelTaskEditor> createState() => _ModelTaskEditorState();
}

class _ModelTaskEditorState extends ConsumerState<ModelTaskEditor> {
  final _reasoningHelpKey = GlobalKey<TooltipState>();
  final _form = GlobalKey<FormState>();
  late InterfaceSlotConfig _slot;
  late String _initial;
  late String _observedSlot;
  int _tab = 0;
  bool _busy = false;
  String? _message, _testResult;
  String? _testSession;
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
    widget.saveController?.attach(this, _save);
  }

  @override
  void dispose() {
    widget.saveController?.detach(this);
    final session = _testSession;
    if (session != null) _service.cancelCurrentTask(sessionId: session);
    super.dispose();
  }

  bool _validate() => _form.currentState!.validate();

  void _edit(InterfaceSlotConfig value) {
    setState(() {
      _slot = value;
      _message = null;
    });
    widget.onDirtyChanged(jsonEncode(_slot.toJson()) != _initial);
  }

  Future<bool> _save() async {
    if (_busy || !_validate()) return false;
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
      if (!mounted) return false;
      _initial = jsonEncode(_slot.toJson());
      _observedSlot = _initial;
      widget.onDirtyChanged(false);
      setState(() => _message = '配置已保存');
      return true;
    } catch (error) {
      if (mounted) setState(() => _message = '$error');
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test(TaskPresetConfig preset) async {
    if (_busy || !_validate()) return;
    setState(() {
      _busy = true;
      _testSession = 'profile-test-${DateTime.now().microsecondsSinceEpoch}';
      _testResult = null;
      _message = null;
    });
    try {
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

  Widget _property({
    required String label,
    required Widget control,
    List<Widget> actions = const [],
    String? help,
    Widget? labelHelp,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 24 * MediaQuery.textScalerOf(context).scale(1),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (labelHelp != null) ...[
                    const SizedBox(width: 5),
                    labelHelp,
                  ],
                ],
              ),
              ...actions,
            ],
          ),
        ),
        const SizedBox(height: 4),
        control,
        if (help != null) ...[
          const SizedBox(height: 6),
          Text(
            help,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _propertyRow({
    required Key key,
    required Widget first,
    required Widget second,
    int firstFlex = 1,
  }) => LayoutBuilder(
    key: key,
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      if (constraints.maxWidth < 620 * scale) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, const SizedBox(height: 22), second],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: firstFlex, child: first),
          const SizedBox(width: 28),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 28),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: .5),
                  ),
                ),
              ),
              child: second,
            ),
          ),
        ],
      );
    },
  );

  Widget _properties({
    required PromptAssistantConfigState config,
    required List<_ModelRoute> choices,
    required _ModelRoute? selected,
    required List<TaskPresetConfig> presets,
    required TaskPresetConfig preset,
    required bool usesInterfaceReasoning,
  }) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final border = UnderlineInputBorder(
      borderSide: BorderSide(
        color: colors.outlineVariant.withValues(alpha: .7),
      ),
    );
    final decoration = InputDecoration(
      isDense: true,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      constraints: const BoxConstraints(minHeight: 42),
      border: border,
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colors.primary),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colors.error),
      ),
    );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: colors.onSurface,
    );
    final presetActions = [
      TextButton(
        key: const Key('task-preset-details'),
        onPressed: () => widget.onEditPreset(preset.id),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          minimumSize: const Size(0, 24),
        ),
        child: Text(preset.id.startsWith('builtin:') ? '查看内置规则' : '查看与编辑预设'),
      ),
      if (!preset.id.startsWith('builtin:'))
        TextButton(
          onPressed: _busy
              ? null
              : () => _edit(_slot.copyWith(presetId: widget.task.builtinId)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            minimumSize: const Size(0, 24),
          ),
          child: const Text('恢复内置预设'),
        ),
    ];
    const languages = {
      'auto': '跟随界面语言',
      'zh': '简体中文',
      'en': 'English',
      'ja': '日本語',
      'ko': '한국어',
    };
    final effectiveModel = selected == null
        ? null
        : effectiveTaskModel(
            config.copyWith(
              interfaces: {...config.interfaces, widget.task: _slot},
            ),
            widget.task,
            selected.model,
          );
    return Column(
      key: const Key('task-properties'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _propertyRow(
          key: const Key('task-model-properties'),
          firstFlex: 2,
          first: _property(
            label: '服务商与模型',
            help: '仅列出启用服务中的已选模型',
            control: ModelCompactDropdown<String>(
              key: ValueKey(
                'task-route-${widget.task.name}-${selected?.model.name}',
              ),
              value: selected == null
                  ? null
                  : jsonEncode([selected.provider.id, selected.model.name]),
              decoration: decoration,
              textStyle: valueStyle,
              hint: '选择服务商与模型',
              choices: [
                for (final item in choices)
                  ModelDropdownChoice(
                    jsonEncode([item.provider.id, item.model.name]),
                    '${item.provider.name} · ${item.model.displayName}',
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (value) {
                      final route = (jsonDecode(value) as List).cast<String>();
                      _edit(
                        _slot.copyWith(
                          providerId: route[0],
                          model: route[1],
                          clearReasoningEffort: true,
                        ),
                      );
                    },
            ),
          ),
          second: _property(
            label: '思考',
            labelHelp: Tooltip(
              key: _reasoningHelpKey,
              message: '纯翻译通常无需开启思考；为兼顾打标、语义分类等处理，建议开启该模型支持的最低思考档位。',
              waitDuration: const Duration(milliseconds: 450),
              child: IconButton(
                key: const Key('task-reasoning-help'),
                onPressed: () =>
                    _reasoningHelpKey.currentState?.ensureTooltipVisible(),
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(24),
                  padding: const EdgeInsets.all(4),
                  backgroundColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                icon: const Icon(
                  Icons.help_outline,
                  size: 13,
                  semanticLabel: '思考档位建议',
                ),
              ),
            ),
            control: ModelReasoningButton(
              model: selected?.model,
              value: _slot.reasoningEffort,
              enabled: !_busy,
              onChanged: (value) => _edit(
                _slot.copyWith(
                  reasoningEffort: value,
                  clearReasoningEffort: value == null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        const Divider(),
        const SizedBox(height: 24),
        _propertyRow(
          key: const Key('task-output-properties'),
          first: _property(
            label: '使用预设',
            actions: presetActions,
            control: ModelCompactDropdown<String>(
              key: ValueKey('task-preset-${preset.id}'),
              value: preset.id,
              decoration: decoration,
              textStyle: valueStyle,
              choices: [
                for (final item in presets)
                  ModelDropdownChoice(item.id, item.name),
              ],
              onChanged: _busy
                  ? null
                  : (value) => _edit(_slot.copyWith(presetId: value)),
            ),
          ),
          second: widget.task == LauncherInterface.promptReverse
              ? _property(
                  label: '输出语言',
                  control: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text('英文生成提示词', style: valueStyle),
                  ),
                  help: '结合原文落实修改，输出英文生成提示词。',
                )
              : _property(
                  label: '目标语言',
                  control: ModelCompactDropdown<String>(
                    key: const Key('task-language'),
                    value: _slot.targetLanguage,
                    decoration: decoration,
                    textStyle: valueStyle,
                    choices: [
                      for (final entry in languages.entries)
                        ModelDropdownChoice(entry.key, entry.value),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) =>
                              _edit(_slot.copyWith(targetLanguage: value)),
                  ),
                ),
        ),
        const SizedBox(height: 26),
        const Divider(),
        const SizedBox(height: 14),
        DefaultTextStyle(
          style: theme.textTheme.bodySmall!.copyWith(
            color: colors.onSurfaceVariant,
          ),
          child: _effectiveFooter(
            Wrap(
              key: const Key('task-effective-summary'),
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '当前生效',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  selected == null
                      ? '尚未选择可用模型'
                      : '${selected.provider.name} · ${selected.model.name}',
                ),
                if (effectiveModel != null)
                  Text(
                    '思考：${reasoningEffortLabel(effectiveModel.reasoningEffort)}${usesInterfaceReasoning ? '（本接口）' : '（跟随模型）'}',
                  ),
                Text(preset.name),
                Text(
                  widget.task == LauncherInterface.promptReverse
                      ? '英文生成提示词'
                      : languages[_slot.targetLanguage] ?? '跟随界面语言',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _effectiveFooter(Widget summary) {
    final promptTask =
        widget.task == LauncherInterface.translate ||
        widget.task == LauncherInterface.promptReverse;
    final hint = Text(
      promptTask ? '无需翻译时，也可将提示词拆分为模块，通过积木功能自由拼装。' : '无需翻译时，也可整理排版并为相关标签添加链接。',
      key: const Key('task-format-hint'),
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w400,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <
            760 * MediaQuery.textScalerOf(context).scale(1)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [summary, const SizedBox(height: 12), hint],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: summary),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: hint),
          ],
        );
      },
    );
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
    final changed = jsonEncode(_slot.toJson()) != _initial;
    final usesInterfaceReasoning =
        selected != null &&
        _slot.reasoningEffort != null &&
        selected.model.availableReasoningEfforts.contains(
          _slot.reasoningEffort,
        );
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
            labels: const ['模型与预设', '提示词与输出'],
            selected: _tab,
            inProgress: _testSession != null,
            onSelected: (value) => setState(() => _tab = value),
          ),
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
                  if (_tab == 0)
                    _properties(
                      config: config,
                      choices: choices,
                      selected: selected,
                      presets: presets,
                      preset: preset,
                      usesInterfaceReasoning: usesInterfaceReasoning,
                    ),
                  if (_tab == 1) ...[
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
