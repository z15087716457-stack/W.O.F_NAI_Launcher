import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../prompt_assistant/models/prompt_task_definitions.dart';
import '../../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../../prompt_assistant/services/prompt_assistant_service.dart';
import 'model_management_widgets.dart';
import 'model_draft_save_controller.dart';
import '../../../../core/utils/localization_extension.dart';

class ModelPresetEditor extends ConsumerStatefulWidget {
  const ModelPresetEditor({
    super.key,
    required this.preset,
    required this.onDirtyChanged,
    required this.onSaved,
    required this.onCreate,
    this.saveController,
  });
  final TaskPresetConfig preset;
  final ValueChanged<bool> onDirtyChanged;
  final ValueChanged<String> onSaved;
  final ValueChanged<LauncherInterface> onCreate;
  final ModelDraftSaveController? saveController;
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
    // Built-in presets keep a stable stored name; show it in the UI language.
    _name = TextEditingController(
      text: _builtin ? widget.preset.task.title : widget.preset.name,
    );
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
    widget.saveController?.attach(this, _save);
  }

  @override
  void dispose() {
    widget.saveController?.detach(this);
    _name.dispose();
    _prompt.dispose();
    super.dispose();
  }

  TaskPresetConfig get _draft => TaskPresetConfig(
    id: widget.preset.id,
    name: _builtin ? widget.preset.name : _name.text.trim(),
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

  Future<bool> _save() async {
    if (_busy || _builtin || !_form.currentState!.validate()) return false;
    setState(() => _busy = true);
    try {
      final latest = ref
          .read(promptAssistantConfigProvider)
          .presets
          .where((item) => item.id == widget.preset.id)
          .firstOrNull;
      if (latest?.toJson().toString() != _observedPreset) {
        throw StateError(context.l10n.modelPreset_changedElsewhere);
      }
      if (_newPreset &&
          ref
                  .read(promptAssistantConfigProvider)
                  .interfaceFor(widget.preset.task)
                  .presetId !=
              _observedInterfacePreset) {
        throw StateError(context.l10n.modelPreset_interfacePresetChanged);
      }
      await ref
          .read(promptAssistantConfigProvider.notifier)
          .savePreset(_draft, applyToInterface: _newPreset);
      if (mounted) {
        widget.onDirtyChanged(false);
        widget.onSaved(widget.preset.id);
      }
      return true;
    } catch (error) {
      if (mounted) setState(() => _message = '$error');
      return false;
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
            _builtin ? widget.preset.task.titleIn(context.l10n) : _name.text,
            description: _builtin
                ? context.l10n.modelPreset_builtinReadOnly
                : context.l10n.modelSettings_presetUser,
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
                  label: Text(context.l10n.modelPreset_newInterfacePreset),
                ),
              ),
            ],
          ),
          ManagementTabs(
            labels: [
              context.l10n.modelPreset_tabPrompt,
              context.l10n.modelPreset_tabOutputContract,
            ],
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
                      decoration: InputDecoration(
                        labelText: context.l10n.modelPreset_name,
                      ),
                      onChanged: _changed,
                      validator: (value) => value?.trim().isEmpty != false
                          ? context.l10n.modelPreset_nameRequired
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.l10n.modelPreset_behavior,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _builtin
                          ? context.l10n.modelPreset_builtinLocked
                          : context.l10n.modelPreset_editHint,
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
                      decoration: InputDecoration(
                        alignLabelWithHint: true,
                        hintText: context.l10n.modelPreset_strategyHint,
                      ),
                      onChanged: _changed,
                      validator: (value) => value?.trim().isEmpty != false
                          ? context.l10n.modelPreset_promptRequired
                          : null,
                    ),
                    if (!_builtin)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            _prompt.text = widget.preset.task.builtinPrompt;
                            _changed('');
                          },
                          child: Text(context.l10n.modelPreset_restoreStrategy),
                        ),
                      ),
                  ],
                  if (_tab == 1) ...[
                    Text(
                      context.l10n.modelSettings_outputContract,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.modelPreset_outputContractNote,
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
                        child: Text(context.l10n.modelPreset_save),
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
