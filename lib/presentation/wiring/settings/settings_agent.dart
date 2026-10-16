import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/nai_agent/tool_catalog.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/services/nai_agent/agent_workspace_store.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../screens/settings/sections/nai_agent_mcp_settings.dart';
import '../../ui/settings/settings_contract.dart';

final settingsAgentBackendProvider = Provider(SettingsAgentBackend.new);

class SettingsAgentInventory {
  const SettingsAgentInventory(this.workspaces, this.sessions);
  final int workspaces, sessions;
}

final settingsAgentInventoryProvider = FutureProvider.autoDispose((ref) async {
  final store = ref.watch(naiAgentWorkspaceStoreProvider);
  final workspaces = await store.listWorkspaces();
  var sessions = 0;
  for (final workspace in workspaces) {
    sessions += (await store.listChats(workspace.id)).length;
  }
  return SettingsAgentInventory(workspaces.length, sessions);
});

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
        return '${await store.effectiveSystemPrompt(workspace.id)}\n\n$naiAgentToolMap';
      }
    }
    final value = await store.readSettings();
    final workspaces = await store.listWorkspaces();
    final workspace = workspaces
        .where((w) => w.id == value.selectedWorkspaceId)
        .firstOrNull;
    if (workspace != null) {
      return '${await store.effectiveSystemPrompt(workspace.id)}\n\n$naiAgentToolMap';
    }
    return [
      value.systemPromptPrefix,
      value.systemPrompt,
      if (value.globalInstructions.isNotEmpty) value.globalInstructions,
      naiAgentToolMap,
    ].where((s) => s.isNotEmpty).join('\n\n');
  }
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

SettingsAgentData settingsAgentData(WidgetRef ref) {
  final settings = ref.watch(naiAgentUiPreferencesProvider).settings;
  final inventory = ref.watch(settingsAgentInventoryProvider).valueOrNull;
  return SettingsAgentData(
    globalInstructions: settings.globalInstructions,
    systemPrefix: settings.systemPromptPrefix,
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
    // External MCP status awaits a frontend "not checked" state; the old
    // Agent entry remains until that contract can represent offline configs.
    mcp: [
      SettingsMcpServer(
        id: 'nai_studio',
        name: 'NAI Studio',
        transport: 'stdio',
        state: SettingsMcpState.connected,
        mode: SettingsMcpMode.values.byName(settings.studioMcpExposure),
        enabled: settings.studioMcpEnabled,
        builtin: true,
        tools: naiAgentToolNames.length,
      ),
    ],
    tools: naiAgentDefaultToolNames,
    dataPath: ref.watch(naiAgentWorkspaceStoreProvider).root.path,
    workspaces: inventory?.workspaces ?? 0,
    sessions: inventory?.sessions ?? 0,
  );
}
