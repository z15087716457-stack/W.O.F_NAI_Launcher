import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/nai_agent/mcp_config.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_agent.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_wiring.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late AgentWorkspaceStore store;
  late ProviderContainer container;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('settings-activation-');
    store = AgentWorkspaceStore(temp);
    container = ProviderContainer(
      overrides: [naiAgentWorkspaceStoreProvider.overrideWithValue(store)],
    );
    await container.read(naiAgentUiPreferencesProvider).load(store);
  });
  tearDown(() async {
    container.dispose();
    await temp.delete(recursive: true);
  });

  test('settings deep links preserve aliases and default to overview', () {
    for (final entry in {
      '': SettingsPageId.overview,
      '?section=local-upscale': SettingsPageId.upscale,
      '?section=localUpscale': SettingsPageId.upscale,
      '?section=promptAssistant': SettingsPageId.models,
      '?section=models': SettingsPageId.models,
      '?section=integrations&bridge=1': SettingsPageId.bridges,
      '?section=account': SettingsPageId.account,
      '?section=agent': SettingsPageId.agent,
      '?section=rag': SettingsPageId.rag,
    }.entries) {
      expect(
        settingsPageFromUri(Uri.parse('/settings${entry.key}')),
        entry.value,
      );
    }
  });

  test('MCP projection uses only observed exact server status', () {
    const server = AgentMcpServer(
      name: 'my-server',
      configId: 'mcp-fixture',
      transport: 'stdio',
    );
    for (final entry in {
      '': SettingsMcpState.unchecked,
      'my-server-extra: connected, 11 tools (codemode)':
          SettingsMcpState.unchecked,
      'my-server: connected, 4 tools (codemode)': SettingsMcpState.connected,
      'my-server: needs sign-in, run /mcp login my-server (codemode)':
          SettingsMcpState.needsLogin,
      'my-server: connecting (codemode)': SettingsMcpState.connecting,
      'my-server: error (codemode)': SettingsMcpState.error,
      'my-server: disconnected, reconnects on next call (codemode)':
          SettingsMcpState.unchecked,
    }.entries) {
      expect(settingsMcpServer(server, entry.key).state, entry.value);
    }
    expect(
      settingsMcpServer(
        server,
        'my-server: connected, 4 tools (codemode)',
      ).tools,
      4,
    );
  });

  test(
    'read-only Agent inventory and MCP status never start a host or create a workspace',
    () async {
      final subscription = container.listen(
        settingsAgentInventoryProvider,
        (_, __) {},
      );
      final inventory = await container.read(
        settingsAgentInventoryProvider.future,
      );
      expect(inventory.workspaces, 0);
      expect(inventory.selected, isNull);
      expect(await container.read(settingsMcpStatusProvider.future), isEmpty);
      expect(container.exists(naiAgentControllerProvider), isFalse);
      expect(await store.listWorkspaces(), isEmpty);
      subscription.close();
    },
  );

  test(
    'global base prompt writes and restores without starting Agent or creating workspace',
    () async {
      final backend = container.read(settingsAgentBackendProvider);
      await backend.saveSystemPrompt(
        scope: SettingsPromptScope.global,
        text: 'GLOBAL_FIXTURE',
        workspaceId: '',
        expectedGlobal: null,
        expectedWorkspace: null,
      );
      expect((await store.readSettings()).customSystemPrompt, 'GLOBAL_FIXTURE');
      await backend.saveSystemPrompt(
        scope: SettingsPromptScope.global,
        text: null,
        workspaceId: '',
        expectedGlobal: 'GLOBAL_FIXTURE',
        expectedWorkspace: null,
      );
      expect((await store.readSettings()).customSystemPrompt, isNull);
      expect(await store.listWorkspaces(), isEmpty);
      expect(container.exists(naiAgentControllerProvider), isFalse);
    },
  );

  test(
    'real instruction write rejects original draft after preferences refresh',
    () async {
      await store.patchSettings({'globalInstructions': 'NEWER_FIXTURE'});
      container
          .read(naiAgentUiPreferencesProvider)
          .replace(await store.readSettings());
      final backend = container.read(settingsAgentBackendProvider);
      await expectLater(
        backend.saveInstructions(
          global: 'DRAFT_FIXTURE',
          prefix: '',
          expectedGlobal: '',
          expectedPrefix: '',
        ),
        throwsStateError,
      );
      expect((await store.readSettings()).globalInstructions, 'NEWER_FIXTURE');
      expect(container.exists(naiAgentControllerProvider), isFalse);
    },
  );

  test(
    'workspace prompt writes independently, inherits global and keeps history',
    () async {
      final workspace = await store.createWorkspace('fixture');
      await store.patchSettings({
        'selectedWorkspaceId': workspace.id,
        'customSystemPrompt': 'GLOBAL_FIXTURE',
      });
      final backend = container.read(settingsAgentBackendProvider);
      await backend.saveSystemPrompt(
        scope: SettingsPromptScope.workspace,
        text: 'WORKSPACE_FIXTURE',
        workspaceId: workspace.id,
        expectedGlobal: 'GLOBAL_FIXTURE',
        expectedWorkspace: null,
      );
      expect(
        (await store.getWorkspace(workspace.id)).customSystemPrompt,
        'WORKSPACE_FIXTURE',
      );
      expect((await store.readSettings()).customSystemPrompt, 'GLOBAL_FIXTURE');
      await backend.saveSystemPrompt(
        scope: SettingsPromptScope.workspace,
        text: null,
        workspaceId: workspace.id,
        expectedGlobal: 'GLOBAL_FIXTURE',
        expectedWorkspace: 'WORKSPACE_FIXTURE',
      );
      expect(
        (await store.getWorkspace(workspace.id)).customSystemPrompt,
        isNull,
      );
      final history = Directory(
        '${workspace.directory.path}/.agent/prompt-history',
      );
      expect(await history.list().where((file) => file is File).length, 2);
      expect(container.exists(naiAgentControllerProvider), isFalse);
    },
  );

  test(
    'workspace prompt checks selected identity and original text inside the write lock',
    () async {
      final a = await store.createWorkspace('A');
      final b = await store.createWorkspace('B');
      await store.patchSettings({'selectedWorkspaceId': b.id});
      final backend = container.read(settingsAgentBackendProvider);
      await expectLater(
        backend.saveSystemPrompt(
          scope: SettingsPromptScope.workspace,
          text: 'WRONG_TARGET',
          workspaceId: a.id,
          expectedGlobal: null,
          expectedWorkspace: null,
        ),
        throwsStateError,
      );
      await store.updateWorkspace(b.id, customSystemPrompt: 'NEWER_WORKSPACE');
      await expectLater(
        backend.saveSystemPrompt(
          scope: SettingsPromptScope.workspace,
          text: 'STALE',
          workspaceId: b.id,
          expectedGlobal: null,
          expectedWorkspace: null,
        ),
        throwsStateError,
      );
      expect((await store.getWorkspace(a.id)).customSystemPrompt, isNull);
      expect(
        (await store.getWorkspace(b.id)).customSystemPrompt,
        'NEWER_WORKSPACE',
      );
      expect(container.exists(naiAgentControllerProvider), isFalse);
    },
  );
}
