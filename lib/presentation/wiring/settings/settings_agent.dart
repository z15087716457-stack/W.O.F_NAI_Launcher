import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
import 'settings_agent_quick.dart';
import 'settings_dialogs.dart';
import '../../ui/kit/ui_glyph.dart';
import '../../ui/settings/settings_agent_dialogs.dart';
import '../../ui/settings/settings_dialog_kit.dart';
import '../../ui/settings/settings_kit.dart';
import '../../widgets/common/app_toast.dart';
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

/// Archived chats, workspaces and skills (the Agent "trash").
final settingsAgentTrashProvider =
    FutureProvider.autoDispose<List<AgentTrashItem>>(
      (ref) => ref.watch(naiAgentWorkspaceStoreProvider).listTrash(),
    );

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
        value.selected?.extensionSignature == value.settings.extensionSignature,
      ),
    ),
  );
  final client = runtime.$1;
  if (!runtime.$4) return '';
  if (client == null ||
      client.isClosed ||
      runtime.$2 == true ||
      runtime.$3 == true) {
    // Read the cached fallback without subscribing to our query's output.
    return ref.read(naiAgentControllerProvider).selected?.mcpStatus ?? '';
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

  /// Opens a text file in the system editor, creating it empty if missing.
  Future<void> openFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      await file.parent.create(recursive: true);
      await file.writeAsString('', flush: true);
    }
    if (!await launchUrl(Uri.file(path))) {
      throw StateError('Unable to open file');
    }
  }

  Future<List<AgentTrashItem>> trash() => store.listTrash();

  /// Restore one archived item. Chats whose workspace is also archived fail
  /// with `StateError('workspace_trashed')` so the UI can explain it.
  Future<void> restoreTrash(AgentTrashItem item) async {
    if (item.kind == AgentTrashKind.skill) {
      await store.restoreSkill(item.id, workspaceId: _workspaceId);
      skillFilesChanged();
    } else {
      if (item.kind == AgentTrashKind.chat && item.workspace == null) {
        throw StateError('workspace_trashed');
      }
      if (ref.exists(naiAgentControllerProvider)) {
        final controller = ref.read(naiAgentControllerProvider);
        await controller.ready;
        await controller.restoreTrashed(item.kind, item.id);
      } else if (item.kind == AgentTrashKind.chat) {
        await store.restoreChat(item.id);
      } else {
        await store.restoreWorkspace(item.id);
      }
    }
    ref.invalidate(settingsAgentInventoryProvider);
    ref.invalidate(settingsAgentTrashProvider);
  }

  Future<void> purgeTrash(AgentTrashItem item) async {
    await store.purgeTrash(item.kind, item.id);
    ref.invalidate(settingsAgentTrashProvider);
  }

  Future<void> emptyTrash() async {
    await store.emptyTrash();
    ref.invalidate(settingsAgentTrashProvider);
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
    final choice = await showSettingsDialog<(bool, bool)>(
      context,
      (_) => SettingsSkillImportDialog(
        folder: folder,
        workspace: backend._workspaceName,
      ),
    );
    if (choice == null) return;
    final (toWorkspace, manual) = choice;
    final String name;
    try {
      name = await backend.importSkill(folder, workspace: toWorkspace);
    } on AgentSkillExists catch (error) {
      if (context.mounted) {
        await settingsNotice(
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
    final name = await settingsTextInput(
      context,
      title: l.set_agSkillNew,
      label: l.set_agSkillName,
      hint: 'watercolor-style',
      help: l.set_agSkillNewHelp,
      mono: true,
      confirm: l.set_agSkillCreate,
      validate: (v) => naiAgentSkillName.hasMatch(v) && v.length <= 64
          ? null
          : l.set_agSkillErrName,
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    try {
      final created = await backend.createSkill(name, workspace: false);
      await backend.openPath(backend.skillFolder('global/$created'));
    } on AgentSkillExists catch (error) {
      if (context.mounted) {
        await settingsNotice(
          context,
          l.set_agSkillNew,
          l.set_agSkillExists(error.name),
        );
      }
    }
  }

  Future<void> removeSkill(String id) async {
    final l = context.l10n;
    final name = id.split('/').last;
    if (!await settingsConfirm(
      context,
      l.set_agSkillRemove,
      l.set_agSkillRemoveBody(name),
      confirm: l.set_delete,
      danger: true,
    )) {
      return;
    }
    await backend.removeSkill(id);
    ref.invalidate(settingsAgentTrashProvider);
  }

  Future<void> viewSkill(String id) async {
    final l = context.l10n;
    final builtin = id.startsWith('builtin/');
    final file = File(p.join(backend.skillFolder(id), 'SKILL.md'));
    final text = await file.exists() ? await file.readAsString() : '';
    if (!context.mounted) return;
    await showSettingsDialog<void>(
      context,
      (dialog) => SettingsTextViewer(
        glyph: SettingsGlyphs.spark,
        title: id.split('/').last,
        path: file.path,
        notice: builtin ? l.set_agSkillReadOnly : null,
        text: text,
        extraActions: [
          if (builtin)
            SettingsBtn(
              label: l.set_agSkillCopy,
              onTap: () async {
                Navigator.pop(dialog);
                try {
                  await backend.copyBuiltinSkill(id.split('/').last);
                } on AgentSkillExists catch (error) {
                  if (context.mounted) {
                    await settingsNotice(
                      context,
                      l.set_agSkillCopy,
                      l.set_agSkillExists(error.name),
                    );
                  }
                }
              },
            )
          else
            SettingsBtn(
              label: l.set_agSkillOpenFolder,
              glyph: SettingsGlyphs.folder,
              onTap: () => backend.openPath(backend.skillFolder(id)),
            ),
        ],
      ),
    );
  }

  Future<void> openTrash() async {
    final l = context.l10n;
    String kindOf(AgentTrashItem item) => switch (item.kind) {
      AgentTrashKind.chat => item.workspace ?? l.set_agTrashGoneWorkspace,
      AgentTrashKind.workspace => '',
      AgentTrashKind.skill =>
        item.workspace == 'workspace'
            ? l.set_agSkillWorkspace
            : l.set_agSkillGlobal,
    };
    final items = <String, AgentTrashItem>{};
    await showSettingsDialog<void>(
      context,
      (dialog) => SettingsTrashDialog(
        load: () async {
          final list = await backend.trash();
          items
            ..clear()
            ..addEntries(list.map((item) => MapEntry(item.id, item)));
          return [
            for (final item in list)
              SettingsTrashRow(
                id: item.id,
                kind: SettingsTrashKind.values.byName(item.kind.name),
                title: item.title,
                at: item.trashedAt,
                bytes: item.bytes,
                detail: kindOf(item).isEmpty ? null : kindOf(item),
                blocked:
                    item.kind == AgentTrashKind.chat && item.workspace == null
                    ? l.set_agTrashNeedWorkspace
                    : null,
              ),
          ];
        },
        onRestore: (row) async {
          try {
            await backend.restoreTrash(items[row.id]!);
            if (dialog.mounted) {
              AppToast.success(dialog, l.set_agTrashRestored(row.title));
            }
            return null;
          } on AgentSkillExists {
            return l.set_agTrashRestoreFailed;
          } on StateError catch (error) {
            return error.message == 'workspace_trashed'
                ? l.set_agTrashNeedWorkspace
                : l.set_agTrashRestoreFailed;
          } catch (_) {
            return l.set_agTrashRestoreFailed;
          }
        },
        onPurge: (row) async {
          if (!await settingsConfirm(
            dialog,
            l.set_agTrashPurgeTitle,
            l.set_agTrashPurgeBody(row.title),
            confirm: l.set_agTrashPurge,
            danger: true,
          )) {
            return false;
          }
          await backend.purgeTrash(items[row.id]!);
          if (dialog.mounted) {
            AppToast.success(dialog, l.set_agTrashPurged(row.title));
          }
          return true;
        },
        onEmpty: (count) async {
          if (!await settingsConfirm(
            dialog,
            l.set_agTrashPurgeAll,
            l.set_agTrashPurgeAllBody(count),
            confirm: l.set_agTrashPurgeAll,
            danger: true,
          )) {
            return false;
          }
          await backend.emptyTrash();
          return true;
        },
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
    final l = context.l10n;
    final raw = builtin
        ? naiAgentDefaultSystemPrompt
        : await backend.finalPrompt();
    if (!context.mounted) return;
    // finalPrompt() prefixes "[pending notice]" when no live host exists;
    // show that as a hint above the text instead of inside it.
    final marker = '[${l.set_agFinalPending}]\n\n';
    final pending = !builtin && raw.startsWith(marker);
    final text = pending ? raw.substring(marker.length) : raw;
    await showSettingsDialog<void>(
      context,
      (_) => SettingsTextViewer(
        glyph: builtin ? SettingsGlyphs.lock : UiGlyphs.file,
        title: builtin ? l.set_agBuiltin : l.set_agFinal,
        subtitle: builtin
            ? l.set_agBuiltinSub
            : (pending ? null : l.set_agFinalLive),
        notice: pending ? l.set_agFinalPending : null,
        text: text,
      ),
    );
  }
}

SettingsAgentData settingsAgentData(
  WidgetRef ref,
  BuildContext context, {
  bool inspect = false,
}) {
  final quick = settingsQuickData(ref, context);
  final settings = ref.watch(naiAgentUiPreferencesProvider).settings;
  final inventory = ref.watch(settingsAgentInventoryProvider).valueOrNull;
  final trash = ref.watch(settingsAgentTrashProvider).valueOrNull;
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
    trashCount: trash?.length ?? 0,
    trashBytes: trash?.fold<int>(0, (sum, item) => sum + item.bytes) ?? 0,
    quick: quick.$1,
    quickDefault: quick.$2,
  );
}

/// About four characters per token; display only.
int _tokens(Object value) =>
    ((value is int ? value : '$value'.length) / 4).ceil();

/// Measured from the Pi 1.3.0 request: 7 default tool schemas plus descriptions.
const _defaultToolTokens = 1300;
