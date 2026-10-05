import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../prompt_assistant/models/prompt_task_definitions.dart';
import '../../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../../prompt_assistant/providers/model_request_history_provider.dart';
import '../../../prompt_assistant/providers/provider_connection_health_provider.dart';
import '../widgets/ai_service_editor.dart';
import '../widgets/model_management_widgets.dart';
import '../widgets/model_task_editor.dart';
import '../widgets/model_compact_dropdown.dart';
import '../widgets/model_preset_editor.dart';
import '../widgets/model_request_details_dialog.dart';
import '../widgets/provider_logo.dart';
import '../widgets/provider_picker.dart';
import '../widgets/provider_connection_status_dot.dart';
import '../widgets/model_draft_save_controller.dart';
import '../../../../core/utils/localization_extension.dart';

enum _LeaveAction { discard, save }

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
  bool _leaving = false, _choosingProvider = false;
  final _draftSave = ModelDraftSaveController();
  Future<bool> _leave() async {
    if (!_dirty) return true;
    if (_leaving) return false;
    _leaving = true;
    try {
      final action = await showDialog<_LeaveAction>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.modelSettings_keepEditsTitle),
          content: Text(context.l10n.modelSettings_keepEditsBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, _LeaveAction.discard),
              child: Text(context.l10n.modelSettings_discard),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, _LeaveAction.save),
              child: Text(context.l10n.modelSettings_saveAndSwitch),
            ),
          ],
        ),
      );
      if (!mounted) return false;
      if (action == _LeaveAction.discard) return true;
      if (action == _LeaveAction.save) return await _draftSave.save();
      return false;
    } finally {
      _leaving = false;
    }
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

  Future<void> _add([ProviderPreset? template]) async {
    if (_choosingProvider) return;
    _choosingProvider = true;
    try {
      final selected = template ?? await showProviderPicker(context);
      if (!mounted || selected == null) return;
      await _switch(() {
        _tab = 0;
        _addingService = true;
        _providerId = null;
        _serviceTemplate = selected;
      });
    } finally {
      _choosingProvider = false;
    }
  }

  Widget _addServiceButton() {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      key: const Key('service-add'),
      tooltip: context.l10n.modelSettings_addProvider,
      onPressed: _add,
      style: IconButton.styleFrom(
        foregroundColor: colors.onSurface,
        backgroundColor: colors.onSurface.withValues(alpha: .075),
        minimumSize: const Size(32, 32),
        padding: const EdgeInsets.all(6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: const Icon(Icons.add, size: 18),
    );
  }

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
  Future<void> _createPreset(LauncherInterface task) async {
    if (!await _leave() || !mounted) return;
    final count = ref
        .read(promptAssistantConfigProvider)
        .presets
        .where((p) => p.task == task)
        .length;
    final preset = TaskPresetConfig(
      id: 'preset-${DateTime.now().microsecondsSinceEpoch}',
      name: count == 0
          ? task.titleIn(context.l10n)
          : context.l10n.modelSettings_presetCopyName(
              task.titleIn(context.l10n),
              count + 1,
            ),
      task: task,
      prompt: task.builtinPrompt,
    );
    setState(() {
      _newPreset = preset;
      _presetId = preset.id;
      _dirty = true;
      _editorRevision++;
    });
  }

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
        title: Text(
          context.l10n.modelSettings_deleteProviderTitle(provider.name),
        ),
        content: Text(
          used == 0
              ? context.l10n.modelSettings_deleteProviderBody
              : '${context.l10n.modelSettings_deleteProviderBody}${context.l10n.modelSettings_deleteProviderBindings(used)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.common_delete),
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

  Future<void> _deletePreset(TaskPresetConfig preset) async {
    if (!await _leave() || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.modelSettings_deletePresetTitle(preset.name)),
        content: Text(context.l10n.modelSettings_deletePresetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.common_delete),
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
    if (!mounted) return;
    _message(context.l10n.modelSettings_configCopied);
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
          title: Text(context.l10n.modelSettings_importConfig),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.modelSettings_importConfigHint),
                  const SizedBox(height: 16),
                  TextField(
                    controller: input,
                    minLines: 7,
                    maxLines: 12,
                    decoration: InputDecoration(
                      hintText: context.l10n.modelSettings_configJson,
                    ),
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
                        context.l10n.modelSettings_importPreview(
                          preview!.providers.length,
                          preview!.models.length,
                          preview!.presets.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.common_cancel),
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
                    throw FormatException(
                      context.l10n.modelSettings_importMissingProviders,
                    );
                  }
                  update(
                    () =>
                        preview = PromptAssistantConfigState.decode(input.text),
                  );
                } catch (exception) {
                  update(() => error = '$exception');
                }
              },
              child: Text(
                preview == null
                    ? context.l10n.modelSettings_checkConfig
                    : context.l10n.modelSettings_importAndReplace,
              ),
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
      if (mounted) _message(context.l10n.modelSettings_configImported);
    } catch (exception) {
      _message('$exception');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(promptAssistantConfigProvider);
    final connectionHealth = ref.watch(providerConnectionHealthProvider);
    final history = ref.watch(modelRequestHistoryProvider);
    final theme = Theme.of(context);
    final provider = _addingService
        ? null
        : config.providers
                  .where((item) => item.id == _providerId)
                  .firstOrNull ??
              config.providers.firstOrNull;
    final presets = [
      for (final task in LauncherInterface.values) ...[
        task.builtinPreset,
        ...config.presets.where((p) => p.task == task),
        if (_newPreset?.task == task) _newPreset!,
      ],
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
                  context.l10n.settings_modelsAndInterfaces,
                  description: context.l10n.modelSettings_description,
                  actions: [
                    PopupMenuButton<String>(
                      shape: modelMenuShape,
                      elevation: 3,
                      clipBehavior: Clip.antiAlias,
                      tooltip: context.l10n.modelSettings_configMenu,
                      icon: const Icon(Icons.more_horiz),
                      onSelected: (value) =>
                          value == 'export' ? _export() : _import(),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'export',
                          child: Text(context.l10n.modelSettings_copyConfig),
                        ),
                        PopupMenuItem(
                          value: 'import',
                          child: Text(context.l10n.modelSettings_importConfig),
                        ),
                      ],
                    ),
                  ],
                ),
                ManagementTabs(
                  key: const Key('model-management-tabs'),
                  labels: [
                    context.l10n.modelSettings_tabProviders,
                    context.l10n.modelSettings_tabInterfaces,
                    context.l10n.modelSettings_tabPresets,
                    context.l10n.modelSettings_tabRequests,
                  ],
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
                                  borderRadius: modelMenuRadius,
                                  elevation: 3,
                                  dropdownColor:
                                      theme.colorScheme.surfaceContainerLow,
                                  key: ValueKey(
                                    'provider-picker-${provider?.id}',
                                  ),
                                  initialValue: provider?.id,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText:
                                        context.l10n.modelSettings_tabProviders,
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
                                            if (item.enabled)
                                              ProviderConnectionStatusDot(
                                                key: ValueKey(
                                                  'provider-health-compact-${item.id}',
                                                ),
                                                providerName: item.name,
                                                result: connectionHealth
                                                    .resultFor(item.id),
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
                              _addServiceButton(),
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
                                        context.l10n
                                            .modelSettings_providersCount(
                                              config.providers.length,
                                            ),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                    _addServiceButton(),
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
                                            '${context.l10n.modelSettings_providerModelCount(config.modelsForProvider(providerId: item.id).where((m) => !m.isPlaceholder).length)}${item.enabled ? '' : context.l10n.modelSettings_providerDisabledSuffix}',
                                        selected: provider?.id == item.id,
                                        icon: _ProviderMonogram(
                                          item,
                                          selected: provider?.id == item.id,
                                        ),
                                        onTap: () => _switch(() {
                                          _providerId = item.id;
                                          _addingService = false;
                                        }),
                                        trailing: item.enabled
                                            ? ProviderConnectionStatusDot(
                                                key: ValueKey(
                                                  'provider-health-${item.id}',
                                                ),
                                                providerName: item.name,
                                                result: connectionHealth
                                                    .resultFor(item.id),
                                              )
                                            : null,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          detail: provider != null || _addingService
                              ? AiServiceEditor(
                                  key: ValueKey(
                                    'service-editor-$_editorRevision',
                                  ),
                                  provider: provider,
                                  initialPreset: _serviceTemplate,
                                  onDelete: provider == null
                                      ? null
                                      : () => _deleteProvider(provider),
                                  saveController: _draftSave,
                                  onDirtyChanged: _dirtyChanged,
                                  onTaskSelected: _openTask,
                                  onSaved: (id) => setState(() {
                                    _providerId = id;
                                    _addingService = false;
                                    _dirty = false;
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
                                          context.l10n.modelSettings_emptyTitle,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          context.l10n.modelSettings_emptyBody,
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
                                              onPressed: () => _add(
                                                ProviderPreset
                                                    .openaiCompatibleChat,
                                              ),
                                              child: Text(
                                                context
                                                    .l10n
                                                    .modelSettings_customService,
                                              ),
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
                                borderRadius: modelMenuRadius,
                                elevation: 3,
                                dropdownColor:
                                    theme.colorScheme.surfaceContainerLow,
                                initialValue: _task,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText:
                                      context.l10n.modelSettings_tabInterfaces,
                                ),
                                items: [
                                  for (final task in LauncherInterface.values)
                                    DropdownMenuItem(
                                      value: task,
                                      child: Text(task.titleIn(context.l10n)),
                                    ),
                                ],
                                onChanged: (value) => _openTask(value!),
                              ),
                          list: ListView(
                            padding: const EdgeInsets.only(top: 14),
                            children: [
                              for (final task in LauncherInterface.values)
                                ManagementListItem(
                                  title: task.titleIn(context.l10n),
                                  subtitle:
                                      config.interfaceFor(task).model.isEmpty
                                      ? context.l10n.modelSettings_notConfigured
                                      : config.interfaceFor(task).model,
                                  selected: task == _task,
                                  icon: Icon(interfaceIcon(task)),
                                  onTap: () => _openTask(task),
                                ),
                            ],
                          ),
                          detail: ModelTaskEditor(
                            key: ValueKey(
                              'task-editor-${_task.name}-$_editorRevision',
                            ),
                            task: _task,
                            saveController: _draftSave,
                            onDirtyChanged: _dirtyChanged,
                            onEditPreset: _openPreset,
                          ),
                        )
                      : _tab == 2
                      ? ManagementSplit(
                          compactPicker: DropdownButtonFormField<String>(
                            borderRadius: modelMenuRadius,
                            elevation: 3,
                            dropdownColor:
                                theme.colorScheme.surfaceContainerLow,
                            key: ValueKey('preset-picker-${preset.id}'),
                            initialValue: preset.id,
                            isExpanded: true,
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: context.l10n.modelSettings_preset,
                            ),
                            items: [
                              for (final item in presets)
                                DropdownMenuItem(
                                  value: item.id,
                                  child: Text(
                                    item.displayNameIn(context.l10n),
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
                                  title: item.displayNameIn(context.l10n),
                                  subtitle: item.id.startsWith('builtin:')
                                      ? context.l10n.modelSettings_presetBuiltin
                                      : context.l10n.modelSettings_presetUser,
                                  selected: item.id == preset.id,
                                  icon: Icon(interfaceIcon(item.task)),
                                  onTap: () => _openPreset(item.id),
                                  trailing:
                                      item.id.startsWith('builtin:') ||
                                          item == _newPreset
                                      ? null
                                      : IconButton(
                                          tooltip: context
                                              .l10n
                                              .modelSettings_deletePreset,
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
                            saveController: _draftSave,
                            onDirtyChanged: _dirtyChanged,
                            onSaved: (id) => setState(() {
                              _presetId = id;
                              _newPreset = null;
                              _dirty = false;
                              _editorRevision++;
                            }),
                            onCreate: _createPreset,
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
          context.l10n.modelSettings_recentRequests,
          description: context.l10n.modelSettings_recentRequestsHint,
          actions: [
            TextButton.icon(
              onPressed: history.records.isEmpty ? null : history.clear,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: Text(context.l10n.modelSettings_clearRequests),
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: history.records.isEmpty
              ? Center(
                  child: Text(
                    context.l10n.modelSettings_requestsEmpty,
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
                        record.status == ModelRequestStatus.success
                            ? Icons.check_circle_outline
                            : record.status == ModelRequestStatus.failed
                            ? Icons.error_outline
                            : Icons.schedule,
                        size: 18,
                        color: record.status == ModelRequestStatus.failed
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
                            record.status.labelIn(context.l10n),
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
                        builder: (_) =>
                            ModelRequestDetailsDialog(recordId: record.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
