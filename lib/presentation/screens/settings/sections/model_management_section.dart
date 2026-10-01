import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../prompt_assistant/models/prompt_task_definitions.dart';
import '../../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../../prompt_assistant/providers/model_request_history_provider.dart';
import '../widgets/ai_service_editor_dialog.dart';
import '../widgets/model_management_widgets.dart';
import '../widgets/model_task_editor.dart';
import '../widgets/model_preset_editor.dart';
import '../widgets/provider_logo.dart';

class _ProviderMonogram extends StatelessWidget {
  const _ProviderMonogram(this.provider, {required this.selected});
  final ProviderConfig provider;
  final bool selected;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 29,
    height: 29,
    child: Center(child: ProviderLogo(provider.preset, size: 24)),
  );
}

class ModelManagementSection extends ConsumerStatefulWidget {
  const ModelManagementSection({super.key});
  @override
  ConsumerState<ModelManagementSection> createState() =>
      ModelManagementSectionState();
}

class ModelManagementSectionState
    extends ConsumerState<ModelManagementSection> {
  Future<bool> confirmLeave() => _leave();
  Future<void> openSearchTab(String tab) =>
      _switch(() => _tab = tab == 'presets' ? 2 : 1);
  int _tab = 0, _editorRevision = 0;
  String? _providerId;
  LauncherInterface _task = LauncherInterface.translate;
  String _presetId = LauncherInterface.translate.builtinId;
  TaskPresetConfig? _newPreset;
  ProviderPreset? _serviceTemplate;
  bool _addingService = false, _dirty = false;
  Future<bool> _leave() async {
    if (!_dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('保留当前编辑？'),
            content: const Text('当前修改尚未保存。可以继续编辑，或放弃修改后切换。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('继续编辑'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('放弃并切换'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _switch(VoidCallback action) async {
    if (!await _leave() || !mounted) return;
    setState(() {
      _dirty = false;
      _newPreset = null;
      _editorRevision++;
      action();
    });
  }

  Future<void> _add([ProviderPreset? template]) => _switch(() {
    _tab = 0;
    _addingService = true;
    _providerId = null;
    _serviceTemplate = template;
  });
  void _dirtyChanged(bool value) {
    if (mounted && _dirty != value) setState(() => _dirty = value);
  }

  void _openTask(LauncherInterface task) => _switch(() {
    _tab = 1;
    _task = task;
  });
  void _openPreset(String id) => _switch(() {
    _tab = 2;
    _presetId = id;
    _newPreset = null;
  });
  Future<void> _deleteProvider(ProviderConfig provider) async {
    if (!await _leave() || !mounted) return;
    final used = LauncherInterface.values
        .where(
          (task) =>
              ref
                  .read(promptAssistantConfigProvider)
                  .interfaceFor(task)
                  .providerId ==
              provider.id,
        )
        .length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除 ${provider.name}？'),
        content: Text(
          '此服务的连接、密钥和已选模型将被删除。${used == 0 ? '' : '$used 个功能的模型绑定会被清除，预设保留。'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(promptAssistantConfigProvider.notifier)
          .deleteProvider(provider.id);
      if (mounted) {
        setState(() {
          _providerId = null;
          _dirty = false;
          _editorRevision++;
        });
      }
    } catch (error) {
      _message('$error');
    }
  }

  Future<void> _cloneProvider(ProviderConfig provider) async {
    if (!await _leave() || !mounted) return;
    final config = ref.read(promptAssistantConfigProvider);
    final id = 'service-${DateTime.now().microsecondsSinceEpoch}';
    final notifier = ref.read(promptAssistantConfigProvider.notifier);
    try {
      await notifier.upsertProvider(
        provider.copyWith(
          id: id,
          name: '${provider.name} · 副本',
          enabled: false,
        ),
      );
      await notifier.replaceProviderModels(id, [
        for (final model in config.modelsForProvider(providerId: provider.id))
          model.copyWith(providerId: id),
      ]);
      if (mounted) {
        setState(() {
          _providerId = id;
          _addingService = false;
          _dirty = false;
          _editorRevision++;
        });
      }
      _message('已复制连接与模型配置，请为副本设置密钥。');
    } catch (error) {
      _message('$error');
    }
  }

  Future<void> _deletePreset(TaskPresetConfig preset) async {
    if (!await _leave() || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除“${preset.name}”？'),
        content: const Text('使用此预设的功能将恢复内置方案。模型绑定保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(promptAssistantConfigProvider.notifier)
          .deletePreset(preset.id);
      if (mounted) {
        setState(() {
          _presetId = preset.task.builtinId;
          _newPreset = null;
          _dirty = false;
          _editorRevision++;
        });
      }
    } catch (error) {
      _message('$error');
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _export() async {
    await Clipboard.setData(
      ClipboardData(
        text: const JsonEncoder.withIndent(
          '  ',
        ).convert(ref.read(promptAssistantConfigProvider).toJson()),
      ),
    );
    _message('配置已复制，不包含密钥或自定义请求头。');
  }

  Future<void> _import() async {
    if (!await _leave() || !mounted) return;
    final input = TextEditingController();
    String? error;
    PromptAssistantConfigState? preview;
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('导入配置'),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('粘贴导出的配置。导入前会备份当前配置；密钥继续独立保存。'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: input,
                    minLines: 7,
                    maxLines: 12,
                    decoration: const InputDecoration(hintText: '配置 JSON'),
                    onChanged: (_) => update(() {
                      preview = null;
                      error = null;
                    }),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (preview != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        '将导入 ${preview!.providers.length} 个服务商、${preview!.models.length} 个模型和 ${preview!.presets.length} 个自定义预设。',
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (preview != null) {
                  Navigator.pop(context, input.text);
                  return;
                }
                try {
                  final decoded = jsonDecode(input.text);
                  if (decoded is! Map ||
                      decoded['providers'] is! List ||
                      decoded['models'] is! List) {
                    throw const FormatException('缺少服务商或模型配置。');
                  }
                  update(
                    () =>
                        preview = PromptAssistantConfigState.decode(input.text),
                  );
                } catch (exception) {
                  update(() => error = '$exception');
                }
              },
              child: Text(preview == null ? '检查配置' : '导入并替换'),
            ),
          ],
        ),
      ),
    );
    // Wait for the dialog transition before disposing its text controller.
    await Future<void>.delayed(const Duration(milliseconds: 220));
    input.dispose();
    if (raw == null || !mounted) return;
    try {
      await ref
          .read(promptAssistantConfigProvider.notifier)
          .importConfiguration(raw);
      if (mounted) {
        setState(() {
          _dirty = false;
          _addingService = false;
          _newPreset = null;
          _editorRevision++;
        });
      }
      _message('配置已导入');
    } catch (exception) {
      _message('$exception');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(promptAssistantConfigProvider);
    final history = ref.watch(modelRequestHistoryProvider);
    final theme = Theme.of(context);
    final provider = _addingService
        ? null
        : config.providers
                  .where((item) => item.id == _providerId)
                  .firstOrNull ??
              config.providers.firstOrNull;
    final presets = [
      for (final task in LauncherInterface.values) task.builtinPreset,
      ...config.presets,
      if (_newPreset != null) _newPreset!,
    ];
    final preset =
        presets.where((item) => item.id == _presetId).firstOrNull ??
        LauncherInterface.translate.builtinPreset;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _leave() && context.mounted) {
          setState(() => _dirty = false);
          if (context.mounted) Navigator.maybePop(context);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = math.max(
            660.0,
            constraints.hasBoundedHeight
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height - 200,
          );
          final body = SizedBox(
            height: height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ManagementHeading(
                  '模型与接口',
                  description: '管理服务连接与翻译偏好。',
                  actions: [
                    PopupMenuButton<String>(
                      tooltip: '配置管理',
                      icon: const Icon(Icons.more_horiz),
                      onSelected: (value) =>
                          value == 'export' ? _export() : _import(),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'export', child: Text('复制配置')),
                        PopupMenuItem(value: 'import', child: Text('导入配置')),
                      ],
                    ),
                  ],
                ),
                ManagementTabs(
                  key: const Key('model-management-tabs'),
                  labels: const ['服务商', '功能接口', '预设与提示词', '请求记录'],
                  selected: _tab,
                  onSelected: (value) => _switch(() => _tab = value),
                ),
                Expanded(
                  child: _tab == 0
                      ? ManagementSplit(
                          compactPicker: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  key: ValueKey(
                                    'provider-picker-${provider?.id}',
                                  ),
                                  initialValue: provider?.id,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: '服务商',
                                    isDense: true,
                                  ),
                                  items: [
                                    for (final item in config.providers)
                                      DropdownMenuItem(
                                        value: item.id,
                                        child: Row(
                                          children: [
                                            ProviderLogo(item.preset, size: 20),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                item.name,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                  onChanged: (value) => _switch(() {
                                    _providerId = value;
                                    _addingService = false;
                                  }),
                                ),
                              ),
                              IconButton(
                                tooltip: '添加服务商',
                                onPressed: _add,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                          list: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  18,
                                  8,
                                  10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '服务商 · ${config.providers.length}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                    IconButton(
                                      key: const Key('service-add'),
                                      tooltip: '添加服务商',
                                      onPressed: _add,
                                      icon: const Icon(Icons.add, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView(
                                  children: [
                                    for (final item in config.providers)
                                      ManagementListItem(
                                        title: item.name,
                                        subtitle:
                                            '${config.modelsForProvider(providerId: item.id).where((m) => !m.isPlaceholder).length} 个模型${item.enabled ? '' : ' · 未启用'}',
                                        selected: provider?.id == item.id,
                                        icon: _ProviderMonogram(
                                          item,
                                          selected: provider?.id == item.id,
                                        ),
                                        onTap: () => _switch(() {
                                          _providerId = item.id;
                                          _addingService = false;
                                        }),
                                        trailing: SizedBox(
                                          width: 26,
                                          height: 32,
                                          child: PopupMenuButton<String>(
                                            tooltip: '管理 ${item.name}',
                                            padding: EdgeInsets.zero,
                                            iconSize: 16,
                                            onSelected: (value) =>
                                                value == 'clone'
                                                ? _cloneProvider(item)
                                                : _deleteProvider(item),
                                            itemBuilder: (_) => const [
                                              PopupMenuItem(
                                                value: 'clone',
                                                child: Text('复制服务配置'),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Text('删除服务'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          detail: provider != null || _addingService
                              ? AiServiceEditorDialog(
                                  key: ValueKey(
                                    'service-editor-${provider?.id ?? _serviceTemplate?.name ?? 'new'}-$_editorRevision',
                                  ),
                                  provider: provider,
                                  initialPreset: _serviceTemplate,
                                  embedded: true,
                                  onDirtyChanged: _dirtyChanged,
                                  onTaskSelected: _openTask,
                                  onSaved: (id) => setState(() {
                                    _providerId = id;
                                    _addingService = false;
                                    _dirty = false;
                                    _editorRevision++;
                                  }),
                                )
                              : Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.cloud_outlined,
                                          size: 34,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          '添加你的第一个模型服务',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '选择常用服务，或连接自定义接口。',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 24),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          alignment: WrapAlignment.center,
                                          children: [
                                            OutlinedButton(
                                              onPressed: () =>
                                                  _add(ProviderPreset.deepseek),
                                              child: const Text('DeepSeek'),
                                            ),
                                            OutlinedButton(
                                              onPressed: () => _add(
                                                ProviderPreset.openaiChat,
                                              ),
                                              child: const Text('OpenAI'),
                                            ),
                                            FilledButton(
                                              onPressed: _add,
                                              child: const Text('自定义服务'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        )
                      : _tab == 1
                      ? ManagementSplit(
                          compactPicker:
                              DropdownButtonFormField<LauncherInterface>(
                                initialValue: _task,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  labelText: '功能接口',
                                ),
                                items: [
                                  for (final task in LauncherInterface.values)
                                    DropdownMenuItem(
                                      value: task,
                                      child: Text(task.title),
                                    ),
                                ],
                                onChanged: (value) => _openTask(value!),
                              ),
                          list: ListView(
                            padding: const EdgeInsets.only(top: 14),
                            children: [
                              for (final task in LauncherInterface.values)
                                ManagementListItem(
                                  title: task.title,
                                  subtitle:
                                      config.interfaceFor(task).model.isEmpty
                                      ? '待配置'
                                      : config.interfaceFor(task).model,
                                  selected: task == _task,
                                  icon: Icon(switch (task) {
                                    LauncherInterface.translate => Icons.south,
                                    LauncherInterface.promptReverse =>
                                      Icons.north,
                                    LauncherInterface.tagTranslate =>
                                      Icons.label_outline,
                                    LauncherInterface.wikiTranslate =>
                                      Icons.menu_book_outlined,
                                  }),
                                  onTap: () => _openTask(task),
                                ),
                            ],
                          ),
                          detail: ModelTaskEditor(
                            key: ValueKey(
                              'task-editor-${_task.name}-$_editorRevision',
                            ),
                            task: _task,
                            onDirtyChanged: _dirtyChanged,
                            onEditPreset: _openPreset,
                          ),
                        )
                      : _tab == 2
                      ? ManagementSplit(
                          compactPicker: DropdownButtonFormField<String>(
                            key: ValueKey('preset-picker-${preset.id}'),
                            initialValue: preset.id,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: '预设',
                            ),
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
                            onChanged: (value) => _openPreset(value!),
                          ),
                          list: ListView(
                            padding: const EdgeInsets.only(top: 14),
                            children: [
                              for (final item in presets)
                                ManagementListItem(
                                  title: item.name,
                                  subtitle: item.id.startsWith('builtin:')
                                      ? '内置 · ${item.task.title}'
                                      : '自定义 · ${item.task.title}',
                                  selected: item.id == preset.id,
                                  icon: Icon(
                                    item.id.startsWith('builtin:')
                                        ? Icons.description_outlined
                                        : Icons.edit_note,
                                  ),
                                  onTap: () => _openPreset(item.id),
                                  trailing:
                                      item.id.startsWith('builtin:') ||
                                          item == _newPreset
                                      ? null
                                      : IconButton(
                                          tooltip: '删除预设',
                                          icon: const Icon(
                                            Icons.more_horiz,
                                            size: 16,
                                          ),
                                          onPressed: () => _deletePreset(item),
                                        ),
                                ),
                            ],
                          ),
                          detail: ModelPresetEditor(
                            key: ValueKey(
                              'preset-editor-${preset.id}-$_editorRevision',
                            ),
                            preset: preset,
                            onDirtyChanged: _dirtyChanged,
                            onSaved: (id) => setState(() {
                              _presetId = id;
                              _newPreset = null;
                              _dirty = false;
                              _editorRevision++;
                            }),
                            onClone: (copy) => setState(() {
                              _newPreset = copy;
                              _presetId = copy.id;
                              _dirty = true;
                              _editorRevision++;
                            }),
                          ),
                        )
                      : _requestRecords(history),
                ),
              ],
            ),
          );
          return constraints.hasBoundedHeight && constraints.maxHeight < 660
              ? SingleChildScrollView(child: body)
              : body;
        },
      ),
    );
  }

  Widget _requestRecords(ModelRequestHistory history) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ManagementHeading(
          '最近请求',
          description: '本次会话最近 100 条 · 不记录密钥、请求头或正文',
          actions: [
            TextButton.icon(
              onPressed: history.records.isEmpty ? null : history.clear,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('清空'),
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: history.records.isEmpty
              ? Center(
                  child: Text(
                    '翻译或测试模型后，请求记录会出现在这里。',
                    style: theme.textTheme.bodySmall,
                  ),
                )
              : ListView.separated(
                  itemCount: history.records.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final record = history.records[index];
                    final time = record.time.toLocal();
                    String two(int value) => value.toString().padLeft(2, '0');
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      leading: Icon(
                        record.status == '成功'
                            ? Icons.check_circle_outline
                            : record.status == '失败'
                            ? Icons.error_outline
                            : Icons.schedule,
                        size: 18,
                        color: record.status == '失败'
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        '${record.task} · ${record.model}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge,
                      ),
                      subtitle: Text(
                        '${record.provider} · ${two(time.hour)}:${two(time.minute)}:${two(time.second)}',
                        style: theme.textTheme.labelSmall,
                      ),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            record.status,
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${(record.elapsedMs / 1000).toStringAsFixed(1)}s',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(record.task),
                          content: SizedBox(
                            width: 560,
                            child: SingleChildScrollView(
                              child: SelectableText(
                                const JsonEncoder.withIndent('  ').convert({
                                  '服务商': record.provider,
                                  '模型': record.model,
                                  '协议': record.protocol,
                                  '状态': record.status,
                                  '耗时（毫秒）': record.elapsedMs,
                                  '请求次数': record.attempts,
                                  if (record.error != null) '错误': record.error,
                                  '生效参数': record.parameters,
                                }),
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('关闭'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
