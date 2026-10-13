import 'dart:async';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../core/nai_agent/tool_catalog.dart';
import '../../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../../widgets/nai_agent/nai_agent_shared.dart';
import 'nai_agent_extensions_settings.dart';
import 'nai_agent_mcp_settings.dart';

enum _LeavePrompt { discard, save }

class NaiAgentSettingsSection extends ConsumerStatefulWidget {
  const NaiAgentSettingsSection({super.key});
  @override
  ConsumerState<NaiAgentSettingsSection> createState() =>
      NaiAgentSettingsSectionState();
}

class NaiAgentSettingsSectionState
    extends ConsumerState<NaiAgentSettingsSection> {
  final _prompt = TextEditingController();
  final _instructions = {
    'globalInstructions': TextEditingController(),
    'systemPromptPrefix': TextEditingController(),
  };
  final _instructionDirty = <String>{};
  bool _instructionsLoaded = false;
  bool _workspace = false, _dirty = false, _saving = false, _loaded = false;
  String? _workspaceId;
  bool _useGlobal = false;
  @override
  void dispose() {
    _prompt.dispose();
    for (final editor in _instructions.values) {
      editor.dispose();
    }
    super.dispose();
  }

  void _load() {
    final c = ref.read(naiAgentControllerProvider);
    if (!c.initialized) return;
    _workspaceId = c.selectedWorkspace!.id;
    _useGlobal = _workspace && c.selectedWorkspace!.customSystemPrompt == null;
    _prompt.text = _workspace
        ? c.selectedWorkspace!.customSystemPrompt ?? c.settings.systemPrompt
        : c.settings.systemPrompt;
    _loaded = true;
    _dirty = false;
    if (!_instructionsLoaded) _loadInstructions();
  }

  void _loadInstructions() {
    final settings = ref.read(naiAgentControllerProvider).settings;
    _instructions['globalInstructions']!.text = settings.globalInstructions;
    _instructions['systemPromptPrefix']!.text = settings.systemPromptPrefix;
    _instructionDirty.clear();
    _instructionsLoaded = true;
  }

  Future<bool> confirmLeave() async {
    if (_saving) return false;
    if (!_dirty && _instructionDirty.isEmpty) return true;
    final result = await showDialog<_LeavePrompt>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.modelSettings_keepEditsTitle),
        content: Text(context.l10n.modelSettings_keepEditsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _LeavePrompt.discard),
            child: Text(context.l10n.modelSettings_discard),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _LeavePrompt.save),
            child: Text(context.l10n.modelSettings_saveAndSwitch),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    if (result == _LeavePrompt.discard) {
      setState(() {
        _load();
        _loadInstructions();
      });
      return true;
    }
    if (result == _LeavePrompt.save) {
      for (final key in _instructionDirty.toList()) {
        if (!await _saveInstruction(key)) return false;
      }
      return !_dirty || await _save();
    }
    return false;
  }

  Future<bool> _saveInstruction(String key) async {
    if (_saving) return false;
    final text = _instructions[key]!.text;
    setState(() => _saving = true);
    try {
      await ref.read(naiAgentControllerProvider).updateSettings({key: text});
      if (mounted) {
        setState(() {
          if (_instructions[key]!.text == text) _instructionDirty.remove(key);
        });
      }
      return true;
    } catch (_) {
      if (mounted) {
        await agentUiAction(
          context,
          () => Future.error(StateError('Instruction save failed')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _instructionEditor(String key, String title, String hint) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          key: ValueKey('nai-agent-$key'),
          controller: _instructions[key],
          minLines: 3,
          maxLines: 8,
          style: const TextStyle(fontSize: 13, height: 1.55),
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onChanged: (_) => setState(() => _instructionDirty.add(key)),
        ),
        const SizedBox(height: 8),
        Text(
          hint,
          style: TextStyle(
            fontSize: 12,
            height: 1.6,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            key: ValueKey('nai-agent-save-$key'),
            onPressed: _instructionDirty.contains(key) && !_saving
                ? () => _saveInstruction(key)
                : null,
            child: Text(context.l10n.naiAgent_saveInstructions),
          ),
        ),
      ],
    ),
  );

  Future<bool> _save() async {
    if (_saving) return false;
    setState(() => _saving = true);
    try {
      final c = ref.read(naiAgentControllerProvider);
      if (_workspace) {
        if (c.selectedWorkspace?.id != _workspaceId) return false;
        await c.setWorkspacePrompt(_useGlobal ? null : _prompt.text);
      } else {
        await c.updateSettings({'customSystemPrompt': _prompt.text});
      }
      if (mounted) setState(() => _dirty = false);
      return true;
    } catch (_) {
      if (mounted) {
        await agentUiAction(
          context,
          () => Future.error(StateError('Prompt save failed')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _effective() async {
    final c = ref.read(naiAgentControllerProvider),
        workspace = c.selectedWorkspace!;
    final client = c.selected?.client;
    final prompt = client != null && !client.isClosed
        ? (await client.getSystemPrompt())['text'] as String
        : '${await c.store.effectiveSystemPrompt(workspace.id)}\n\n$_toolMap';
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 680),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.naiAgent_showEffective,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      prompt,
                      style: const TextStyle(fontSize: 13, height: 1.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Checked against the official host tool map; live sessions expose Pi's final prompt.
  static const _toolMap = naiAgentToolMap;

  Widget _section(String title, Widget child, {String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        child,
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final c = ref.watch(naiAgentControllerProvider), l = context.l10n;
    if (!_loaded && c.initialized) _load();
    if (!c.initialized) return const Center(child: CircularProgressIndicator());
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _section(
              l.naiAgent_chooseModel,
              const Align(
                alignment: Alignment.centerLeft,
                child: NaiAgentModelPicker(),
              ),
            ),
            _section(
              l.naiAgent_instructions,
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _instructionEditor(
                    'globalInstructions',
                    l.naiAgent_globalInstructions,
                    l.naiAgent_globalInstructionsHelp,
                  ),
                  _instructionEditor(
                    'systemPromptPrefix',
                    l.naiAgent_systemPromptPrefix,
                    l.naiAgent_systemPromptPrefixHelp,
                  ),
                  ExpansionTile(
                    key: const Key('nai-agent-base-prompt'),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    title: Text(
                      l.naiAgent_systemPrompt,
                      style: const TextStyle(fontSize: 13),
                    ),
                    children: [
                      Text(
                        l.naiAgent_promptHelp,
                        style: const TextStyle(fontSize: 12, height: 1.6),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              ChoiceChip(
                                label: Text(l.naiAgent_globalScope),
                                selected: !_workspace,
                                onSelected: (_) async {
                                  if (await confirmLeave() && mounted) {
                                    setState(() {
                                      _workspace = false;
                                      _load();
                                    });
                                  }
                                },
                              ),
                              ChoiceChip(
                                label: Text(
                                  '${l.naiAgent_workspaceScope} · ${c.selectedWorkspace!.name}',
                                ),
                                selected: _workspace,
                                onSelected: (_) async {
                                  if (await confirmLeave() && mounted) {
                                    setState(() {
                                      _workspace = true;
                                      _load();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          if (_workspace)
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(l.naiAgent_useGlobal),
                              value: _useGlobal,
                              onChanged: (value) => setState(() {
                                _useGlobal = value;
                                _dirty = true;
                              }),
                            ),
                          const SizedBox(height: 10),
                          TextField(
                            key: const Key('nai-agent-custom-prompt'),
                            controller: _prompt,
                            minLines: 8,
                            maxLines: 18,
                            enabled: !_workspace || !_useGlobal,
                            style: const TextStyle(fontSize: 13, height: 1.55),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() => _dirty = true),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton(
                                key: const Key('nai-agent-save-base-prompt'),
                                onPressed: _dirty && !_saving ? _save : null,
                                child: Text(l.naiAgent_save),
                              ),
                              TextButton(
                                onPressed: () =>
                                    agentUiAction(context, () async {
                                      if (_workspace) {
                                        await c.setWorkspacePrompt(null);
                                      } else {
                                        await c.updateSettings({
                                          'customSystemPrompt': null,
                                        });
                                      }
                                      if (mounted) setState(_load);
                                    }),
                                child: Text(l.naiAgent_restoreDefault),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: () => agentUiAction(context, _effective),
                      child: Text(l.naiAgent_showEffective),
                    ),
                  ),
                ],
              ),
              hint: l.naiAgent_instructionOrder,
            ),
            _section(
              l.naiAgent_settings,
              Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.naiAgent_enterSends),
                    value: c.settings.enterToSend,
                    onChanged: (value) => agentUiAction(
                      context,
                      () => c.updateSettings({'enterToSend': value}),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(child: Text(l.naiAgent_runLimit)),
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          key: ValueKey(c.settings.maxRequestsPerRun),
                          initialValue: '${c.settings.maxRequestsPerRun}',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true),
                          onFieldSubmitted: (text) {
                            final value = int.tryParse(text);
                            if (value != null && value >= 1 && value <= 200) {
                              unawaited(
                                agentUiAction(
                                  context,
                                  () => c.updateSettings({
                                    'maxRequestsPerRun': value,
                                  }),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _section(l.naiAgent_extensions, const NaiAgentExtensionsSettings()),
            _section('MCP', const NaiAgentMcpSettings()),
            _section(
              l.naiAgent_toolsManuals,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final name in naiAgentDefaultToolNames)
                        Chip(
                          label: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Geist Mono',
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.naiAgent_toolsHint,
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
            _section(
              l.naiAgent_dataFolder,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    c.store.root.path,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Geist Mono',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.folder_open, size: 16),
                    label: Text(l.naiAgent_openFolder),
                    onPressed: () => agentUiAction(context, () async {
                      await launchUrl(Uri.directory(c.store.root.path));
                    }),
                  ),
                ],
              ),
            ),
            _section(
              l.naiAgent_usage,
              Text(
                l.naiAgent_unknownCost,
                style: const TextStyle(fontSize: 13, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
