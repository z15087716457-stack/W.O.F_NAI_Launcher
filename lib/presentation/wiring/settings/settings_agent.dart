import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/nai_agent/tool_catalog.dart';
import '../../../core/nai_agent/mcp_config.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/services/nai_agent/agent_workspace_store.dart';
import '../../providers/nai_agent/nai_agent_skills_provider.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../screens/settings/sections/nai_agent_mcp_settings.dart';
import 'settings_dialogs.dart';
import '../../ui/settings/settings_contract.dart';

final settingsAgentBackendProvider = Provider(SettingsAgentBackend.new);

class SettingsAgentInventory {
  const SettingsAgentInventory(this.workspaces, this.sessions, this.selected);
  final int workspaces, sessions;
  final AgentWorkspace? selected;
}

final settingsAgentInventoryProvider = FutureProvider.autoDispose((ref) async {
  final store = ref.watch(naiAgentWorkspaceStoreProvider);
  final selected = ref.watch(
    naiAgentUiPreferencesProvider.select(
      (value) => value.settings.selectedWorkspaceId,
    ),
  );
  final workspaces = await store.listWorkspaces();
  var sessions = 0;
  for (final workspace in workspaces) {
    sessions += (await store.listChats(workspace.id)).length;
  }
  return SettingsAgentInventory(
    workspaces.length,
    sessions,
    workspaces.where((workspace) => workspace.id == selected).firstOrNull,
  );
});

/// Query only an existing idle host; rendering settings cannot start one.
final settingsMcpStatusProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  if (!ref.exists(naiAgentControllerProvider)) return '';
  final runtime = ref.watch(
    naiAgentControllerProvider.select(
      (value) => (
        value.selected?.client,
        value.selected?.running,
        value.selected?.starting,
        value.selected?.mcpStatus,
        value.selected?.extensionSignature == value.settings.extensionSignature,
      ),
    ),
  );
  final client = runtime.$1;
  if (!runtime.$5) return '';
  if (client == null ||
      client.isClosed ||
      runtime.$2 == true ||
      runtime.$3 == true) {
    return runtime.$4 ?? '';
  }
  try {
    final response = await client.mcpCommand('status');
    return response['mcpStatus'] as String? ?? '';
  } catch (_) {
    return '';
  }
});

SettingsMcpServer settingsMcpServer(AgentMcpServer server, String status) {
  final line =
      RegExp(
        '^${RegExp.escape(server.name)}: (.+)\$',
        multiLine: true,
      ).firstMatch(status)?.group(1) ??
      '';
  final state = !server.enabled
      ? SettingsMcpState.disabled
      : line.startsWith('needs sign-in')
      ? SettingsMcpState.needsLogin
      : line.startsWith('connected')
      ? SettingsMcpState.connected
      : line.startsWith('connecting') || line.startsWith('starting')
      ? SettingsMcpState.connecting
      : line.startsWith('error') || line.startsWith('failed')
      ? SettingsMcpState.error
      : SettingsMcpState.unchecked;
  return SettingsMcpServer(
    id: server.configId,
    name: server.name,
    transport: server.transport,
    state: state,
    mode: SettingsMcpMode.values.byName(server.exposure),
    enabled: server.enabled,
    tools:
        int.tryParse(
          RegExp(r', (\d+) tools?').firstMatch(line)?.group(1) ?? '',
        ) ??
        0,
  );
}

/// These settings can be read/edited without creating a workspace or Node child.
class SettingsAgentBackend {
  SettingsAgentBackend(this.ref);
  final Ref ref;
  AgentWorkspaceStore get store => ref.read(naiAgentWorkspaceStoreProvider);
  AgentSettings get settings =>
      ref.read(naiAgentUiPreferencesProvider).settings;

  Future<void> update(
    Map<String, dynamic> changes, {
    Map<String, dynamic>? expected,
  }) async {
    if (ref.exists(naiAgentControllerProvider)) {
      final controller = ref.read(naiAgentControllerProvider);
      await controller.ready;
      await controller.updateSettings(changes, expected: expected);
    } else {
      final result = expected == null
          ? await store.patchSettings(changes)
          : await store.patchSettingsChecked(changes, expected: expected);
      ref.read(naiAgentUiPreferencesProvider).replace(result);
    }
  }

  Future<void> saveInstructions({
    required String global,
    required String prefix,
    required String expectedGlobal,
    required String expectedPrefix,
  }) => update(
    {'globalInstructions': global, 'systemPromptPrefix': prefix},
    expected: {
      'globalInstructions': expectedGlobal,
      'systemPromptPrefix': expectedPrefix,
    },
  );

  Future<void> saveSystemPrompt({
    required SettingsPromptScope scope,
    required String? text,
    required String workspaceId,
    required String? expectedGlobal,
    required String? expectedWorkspace,
  }) async {
    if (scope == SettingsPromptScope.global) {
      await update(
        {'customSystemPrompt': text},
        expected: {'customSystemPrompt': expectedGlobal},
      );
      return;
    }
    if (workspaceId.isEmpty) throw StateError('No selected workspace');
    if (ref.exists(naiAgentControllerProvider)) {
      final controller = ref.read(naiAgentControllerProvider);
      await controller.ready;
      await controller.setWorkspacePrompt(
        text,
        expectedWorkspaceId: workspaceId,
        checkPrompt: true,
        expectedPrompt: expectedWorkspace,
      );
    } else {
      await store.updateWorkspace(
        workspaceId,
        customSystemPrompt: text,
        resetPrompt: text == null,
        checkPrompt: true,
        expectedPrompt: expectedWorkspace,
        requireSelected: true,
      );
    }
    ref.invalidate(settingsAgentInventoryProvider);
  }

  Future<void> extension(
    String path, {
    bool? enabled,
    bool remove = false,
  }) async {
    if (ref.exists(naiAgentControllerProvider)) {
      final controller = ref.read(naiAgentControllerProvider);
      await controller.ready;
      await controller.configureExtension(
        path,
        enabled: enabled,
        remove: remove,
      );
    } else {
      final result = await store.configureExtension(
        path,
        enabled: enabled,
        remove: remove,
      );
      ref.read(naiAgentUiPreferencesProvider).replace(result);
    }
  }

  Future<void> mcp(
    String id, {
    bool? enabled,
    SettingsMcpMode? mode,
    bool remove = false,
  }) async {
    final current = await store.readSettings();
    if (id == 'nai_studio') {
      if (remove) {
        throw ArgumentError('The built-in tool group cannot be deleted');
      }
      await update({
        if (enabled != null) 'studioMcpEnabled': enabled,
        if (mode != null) 'studioMcpExposure': mode.name,
      });
      return;
    }
    final server = current.mcpServers
        .where((s) => s.configId == id)
        .firstOrNull;
    if (server == null) throw ArgumentError.value(id, 'id');
    await update(
      {
        'mcpServers': [
          for (final item in current.mcpServers)
            if (item.configId != id)
              item.toJson()
            else if (!remove)
              {
                ...item.toJson(),
                if (enabled != null) 'enabled': enabled,
                if (mode != null) 'exposure': mode.name,
              },
        ],
      },
      expected: {
        'mcpServers': current.mcpServers.map((s) => s.toJson()).toList(),
      },
    );
    if (remove) {
      await ref.read(secureStorageServiceProvider).deleteAgentMcpConfig(id);
    }
  }

  Future<void> mcpLogin(String id) async {
    final current = settings.mcpServers.firstWhere((s) => s.configId == id);
    final controller = ref.read(naiAgentControllerProvider);
    await controller.ready;
    await controller.mcpCommand('login', name: current.name);
  }

  Future<String> finalPrompt() async {
    if (ref.exists(naiAgentControllerProvider)) {
      final controller = ref.read(naiAgentControllerProvider);
      await controller.ready;
      final client = controller.selected?.client;
      if (client != null && !client.isClosed) {
        return (await client.getSystemPrompt())['text'] as String;
      }
      final workspace = controller.selectedWorkspace;
      if (workspace != null) {
        return _pending(await store.effectiveSystemPrompt(workspace.id));
      }
    }
    final value = await store.readSettings();
    final workspaces = await store.listWorkspaces();
    final workspace = workspaces
        .where((w) => w.id == value.selectedWorkspaceId)
        .firstOrNull;
    if (workspace != null) {
      return _pending(await store.effectiveSystemPrompt(workspace.id));
    }
    return _pending(
      [
        value.systemPromptPrefix,
        value.systemPrompt,
        if (value.globalInstructions.isNotEmpty) value.globalInstructions,
      ].where((s) => s.isNotEmpty).join('\n\n'),
    );
  }

  /// No live host: show only what Studio assembles and say what Pi adds.
  static String _pending(String studio) =>
      '[${currentL10n.set_agFinalPending}]\n\n$studio';

  Future<void> skill(String id, {bool? enabled, bool? manual}) async {
    final mode = manual == null ? null : (manual ? 'manual' : 'auto');
    if (ref.exists(naiAgentControllerProvider)) {
      final controller = ref.read(naiAgentControllerProvider);
      await controller.ready;
      await controller.configureSkill(id, enabled: enabled, mode: mode);
    } else {
      final result = await store.configureSkill(
        id,
        enabled: enabled,
        mode: mode,
      );
      ref.read(naiAgentUiPreferencesProvider).replace(result);
    }
  }

  String? get _workspaceId {
    if (ref.exists(naiAgentControllerProvider)) {
      final id = ref.read(naiAgentControllerProvider).selectedWorkspace?.id;
      if (id != null) return id;
    }
    return ref.read(settingsAgentInventoryProvider).valueOrNull?.selected?.id;
  }

  Future<void> removeSkill(String id) async {
    final workspaceId = _workspaceId;
    if (ref.exists(naiAgentControllerProvider)) {
      final controller = ref.read(naiAgentControllerProvider);
      await controller.ready;
      await controller.removeSkill(id, workspaceId: workspaceId);
      controller.skillFilesChanged();
    } else {
      final result = await store.removeSkill(id, workspaceId: workspaceId);
      ref.read(naiAgentUiPreferencesProvider).replace(result);
    }
    skillFilesChanged();
  }

  Future<String> importSkill(String folder, {required bool workspace}) async {
    final name = await store.importSkill(
      folder,
      source: workspace ? 'workspace' : 'global',
      workspaceId: workspace ? _workspaceId : null,
    );
    skillFilesChanged();
    return name;
  }

  Future<String> createSkill(String name, {required bool workspace}) async {
    final created = await store.createSkill(
      name,
      source: workspace ? 'workspace' : 'global',
      workspaceId: workspace ? _workspaceId : null,
    );
    skillFilesChanged();
    return created;
  }

  Future<void> copyBuiltinSkill(String name) async {
    await store.copyBuiltinSkill(name);
    skillFilesChanged();
  }

  /// Files changed on disk: refresh the list and restart idle hosts on next send.
  void skillFilesChanged() {
    ref.read(naiAgentSkillRevisionProvider.notifier).state++;
    if (ref.exists(naiAgentControllerProvider)) {
      ref.read(naiAgentControllerProvider).skillFilesChanged();
    }
  }

  String? get _workspaceName {
    if (ref.exists(naiAgentControllerProvider)) {
      final name = ref.read(naiAgentControllerProvider).selectedWorkspace?.name;
      if (name != null) return name;
    }
    return ref.read(settingsAgentInventoryProvider).valueOrNull?.selected?.name;
  }

  Future<void> openPath(String path) async {
    await Directory(path).create(recursive: true);
    if (!await launchUrl(Uri.directory(path))) {
      throw StateError('Unable to open folder');
    }
  }

  String skillFolder(String id) =>
      store.skillFolder(id, workspaceId: _workspaceId).path;

  String skillRoot(SettingsSkillSource source) =>
      store.skillSourceDirectory(source.name, workspaceId: _workspaceId).path;
}

class SettingsAgentActions {
  SettingsAgentActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;
  SettingsAgentBackend get backend => ref.read(settingsAgentBackendProvider);
  Future<void> addExtension(bool directory) async {
    final path = directory
        ? await FilePicker.platform.getDirectoryPath()
        : (await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['ts', 'js', 'mjs', 'cjs'],
          ))?.files.single.path;
    if (path != null && context.mounted) await backend.extension(path);
  }

  Future<void> addSkill() async {
    final folder = await FilePicker.platform.getDirectoryPath();
    if (folder == null || !context.mounted) return;
    final l = context.l10n;
    final workspace = backend._workspaceName;
    var toWorkspace = false, manual = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, setState) => AlertDialog(
          title: Text(l.set_agSkillAddTitle),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(folder),
                const SizedBox(height: 14),
                Text(l.set_agSkillPlace),
                const SizedBox(height: 6),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(l.set_agSkillGlobal),
                    ),
                    if (workspace != null)
                      ButtonSegment(
                        value: true,
                        label: Text(l.set_agSkillPlaceWorkspace(workspace)),
                      ),
                  ],
                  selected: {toWorkspace},
                  onSelectionChanged: (v) =>
                      setState(() => toWorkspace = v.first),
                ),
                const SizedBox(height: 14),
                Text(l.set_agSkillMode),
                const SizedBox(height: 6),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, label: Text(l.set_agSkillAuto)),
                    ButtonSegment(
                      value: true,
                      label: Text(l.set_agSkillManual),
                    ),
                  ],
                  selected: {manual},
                  onSelectionChanged: (v) => setState(() => manual = v.first),
                ),
                const SizedBox(height: 14),
                Text('${l.set_agSkillCopyNote} ${l.set_agSkillTrust}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(l.common_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(l.common_confirm),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final String name;
    try {
      name = await backend.importSkill(folder, workspace: toWorkspace);
    } on AgentSkillExists catch (error) {
      if (context.mounted) {
        await settingsConfirm(
          context,
          l.set_agSkillAddTitle,
          l.set_agSkillExists(error.name),
        );
      }
      return;
    }
    if (manual) {
      await backend.skill(
        '${toWorkspace ? 'workspace' : 'global'}/$name',
        manual: true,
      );
    }
  }

  Future<void> newSkill() async {
    final l = context.l10n;
    final name = await settingsTextInput(context, title: l.set_agSkillNewName);
    if (name == null || name.isEmpty || !context.mounted) return;
    try {
      final created = await backend.createSkill(name, workspace: false);
      await backend.openPath(backend.skillFolder('global/$created'));
    } on AgentSkillExists catch (error) {
      if (context.mounted) {
        await settingsConfirm(
          context,
          l.set_agSkillNew,
          l.set_agSkillExists(error.name),
        );
      }
    } on FormatException {
      if (context.mounted) {
        await settingsConfirm(context, l.set_agSkillNew, l.set_agSkillErrName);
      }
    }
  }

  Future<void> removeSkill(String id) async {
    final l = context.l10n;
    final name = id.split('/').last;
    if (!await settingsConfirm(
      context,
      l.set_agSkillRemove,
      l.set_agSkillRemoveConfirm(name),
    )) {
      return;
    }
    await backend.removeSkill(id);
  }

  Future<void> viewSkill(String id) async {
    final l = context.l10n;
    final builtin = id.startsWith('builtin/');
    final file = File(p.join(backend.skillFolder(id), 'SKILL.md'));
    final text = await file.exists() ? await file.readAsString() : '';
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(id.split('/').last),
        content: SizedBox(
          width: 800,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(file.path),
              if (builtin) ...[
                const SizedBox(height: 6),
                Text(l.set_agSkillReadOnly),
              ],
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(child: SelectableText(text)),
              ),
            ],
          ),
        ),
        actions: [
          if (builtin)
            TextButton(
              onPressed: () async {
                Navigator.pop(dialog);
                try {
                  await backend.copyBuiltinSkill(id.split('/').last);
                } on AgentSkillExists catch (error) {
                  if (context.mounted) {
                    await settingsConfirm(
                      context,
                      l.set_agSkillCopy,
                      l.set_agSkillExists(error.name),
                    );
                  }
                }
              },
              child: Text(l.set_agSkillCopy),
            ),
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: text)),
            child: Text(l.common_copy),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text(l.common_close),
          ),
        ],
      ),
    );
  }

  Future<void> editMcp(String? id) async {
    final current = id == null
        ? null
        : backend.settings.mcpServers.firstWhere((s) => s.configId == id);
    await const NaiAgentMcpSettings().edit(context, ref, current);
  }

  Future<void> viewPrompt({bool builtin = false}) async {
    final text = builtin
        ? naiAgentDefaultSystemPrompt
        : await backend.finalPrompt();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(
          builtin ? context.l10n.set_agBuiltin : context.l10n.set_agFinal,
        ),
        content: SizedBox(
          width: 800,
          child: SingleChildScrollView(child: SelectableText(text)),
        ),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: text)),
            child: Text(context.l10n.common_copy),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }
}

SettingsAgentData settingsAgentData(WidgetRef ref, {bool inspect = false}) {
  final settings = ref.watch(naiAgentUiPreferencesProvider).settings;
  final inventory = ref.watch(settingsAgentInventoryProvider).valueOrNull;
  final controller = ref.exists(naiAgentControllerProvider)
      ? ref.watch(naiAgentControllerProvider)
      : null;
  final workspace = controller?.selectedWorkspace ?? inventory?.selected;
  final skills = ref.watch(naiAgentSkillsProvider(workspace?.id)).valueOrNull;
  final mcpStatus = inspect
      ? ref.watch(settingsMcpStatusProvider).valueOrNull ?? ''
      : '';
  return SettingsAgentData(
    globalInstructions: settings.globalInstructions,
    workspaceRulesPath: workspace == null
        ? null
        : p.join(workspace.directory.path, 'instructions.md'),
    systemPrefix: settings.systemPromptPrefix,
    systemPrompt: SettingsSystemPrompt(
      builtin: naiAgentDefaultSystemPrompt,
      global: settings.customSystemPrompt,
      workspaceId: workspace?.id ?? '',
      workspaceName: workspace?.name ?? '',
      workspace: workspace?.customSystemPrompt,
    ),
    skills: [
      for (final skill in skills?.skills ?? const <NaiAgentSkill>[])
        SettingsSkill(
          id: skill.key,
          name: skill.name,
          source: SettingsSkillSource.values.byName(skill.source),
          description: skill.displayDescription(currentL10n),
          path: skill.directory,
          enabled: skill.enabled,
          manual: skill.mode == 'manual',
          state: SettingsSkillState.values.byName(skill.state),
          error: skill.error == null
              ? null
              : SettingsSkillError.values.byName(skill.error!),
        ),
    ],
    skillFolders: [
      (
        SettingsSkillSource.global,
        ref.watch(naiAgentWorkspaceStoreProvider).globalSkillsDirectory.path,
      ),
      if (workspace != null)
        (SettingsSkillSource.workspace, workspace.skills.path),
    ],
    context: skills == null
        ? null
        : SettingsAgentContext(
            promptTokens: _tokens(settings.systemPrompt),
            skillTokens: _tokens(skills.catalogChars),
            skillCount: skills.skills
                .where((s) => s.state == 'active' && s.mode == 'auto')
                .length,
            toolTokens: _defaultToolTokens,
            toolCount: naiAgentDefaultToolNames.length,
          ),
    extensions: [
      const SettingsExtension(
        id: 'builtin',
        name: 'studio_context · ask_user',
        builtin: true,
      ),
      for (final extension in settings.extensions)
        SettingsExtension(
          id: extension.path,
          name: p.basename(extension.path),
          path: extension.path,
          enabled: extension.enabled,
        ),
    ],
    mcp: [
      SettingsMcpServer(
        id: 'nai_studio',
        name: 'NAI Studio',
        transport: 'stdio',
        state: settings.studioMcpEnabled
            ? SettingsMcpState.unchecked
            : SettingsMcpState.disabled,
        mode: SettingsMcpMode.values.byName(settings.studioMcpExposure),
        enabled: settings.studioMcpEnabled,
        builtin: true,
        tools: naiAgentToolNames.length,
      ),
      for (final server in settings.mcpServers)
        settingsMcpServer(server, mcpStatus),
    ],
    tools: naiAgentDefaultToolNames,
    dataPath: ref.watch(naiAgentWorkspaceStoreProvider).root.path,
    workspaces: inventory?.workspaces ?? 0,
    sessions: inventory?.sessions ?? 0,
  );
}

/// About four characters per token; display only.
int _tokens(Object value) =>
    ((value is int ? value : '$value'.length) / 4).ceil();

/// Measured from the Pi 1.3.0 request: 7 default tool schemas plus descriptions.
const _defaultToolTokens = 1300;
