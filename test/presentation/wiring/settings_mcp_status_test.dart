import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/core/nai_agent/mcp_config.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_agent.dart';

class _Client extends Mock implements PiHostClient {}

void main() {
  test(
    'opening configured MCP settings starts one session and reuses its connection',
    () async {
      final root = await Directory.systemTemp.createTemp('settings-mcp-auto-');
      const server = AgentMcpServer(
        name: 'exa',
        configId: 'synthetic',
        transport: 'http',
        displayName: 'EXA免费联网搜索',
      );
      final store = AgentWorkspaceStore(root);
      await store.saveSettings(
        const AgentSettings(
          providerId: 'local',
          modelId: 'test',
          mcpServers: [server],
        ),
      );
      final client = _Client();
      when(() => client.isClosed).thenReturn(false);
      when(() => client.initialState).thenReturn({});
      when(() => client.events).thenAnswer((_) => const Stream.empty());
      when(() => client.close()).thenAnswer((_) async {});
      final status = Completer<Map<String, dynamic>>();
      when(() => client.mcpCommand('status')).thenAnswer((_) => status.future);
      var starts = 0;
      final controller = NaiAgentWorkspaceController(
        store: store,
        initialWorkspaceName: 'Test',
        initialChatName: 'Test',
        startClient: (_, __, ___, ____, _____) async {
          starts++;
          return client;
        },
      );
      final preferences = NaiAgentUiPreferences();
      await preferences.load(store);
      controller.addListener(() => preferences.replace(controller.settings));
      final container = ProviderContainer(
        overrides: [
          naiAgentUiPreferencesProvider.overrideWith((_) => preferences),
          naiAgentControllerProvider.overrideWith((_) {
            controller.ready = controller.initialize(restoreHistory: false);
            return controller;
          }),
        ],
      );
      final subscription = container.listen(
        settingsMcpStatusProvider,
        (_, __) {},
      );
      addTearDown(() async {
        subscription.close();
        await controller.close();
        container.dispose();
        await root.delete(recursive: true);
      });
      await controller.ready;
      final pending = container.read(settingsMcpStatusProvider.future);
      expect(container.read(settingsMcpStatusProvider).isLoading, true);
      expect(
        settingsMcpServer(server, '', connecting: true).state,
        SettingsMcpState.connecting,
      );
      status.complete({'mcpStatus': 'exa: connected, 2 tools (codemode)'});
      final result = await pending;
      expect(result, contains('exa: connected'));
      final row = settingsMcpServer(server, result);
      expect(row.name, 'EXA免费联网搜索');
      expect(row.state, SettingsMcpState.connected);
      expect(row.tools, 2);
      container.invalidate(settingsMcpStatusProvider);
      expect(await container.read(settingsMcpStatusProvider.future), result);
      expect(starts, 1);
      verify(() => client.mcpCommand('status')).called(2);
      verifyNever(() => client.mcpCommand('reconnect', name: 'exa'));
    },
  );

  test(
    'status reconnects to the lifecycle when Settings opens before Agent',
    () async {
      final root = await Directory.systemTemp.createTemp('settings-mcp-late-');
      final client = _Client();
      when(() => client.isClosed).thenReturn(false);
      when(() => client.close()).thenAnswer((_) async {});
      when(() => client.mcpCommand('status')).thenAnswer(
        (_) async => {'mcpStatus': 'exa: connected, 2 tools (codemode)'},
      );
      final controller = NaiAgentWorkspaceController(
        store: AgentWorkspaceStore(root),
        startClient: (_, __, ___, ____, _____) async => client,
        initialWorkspaceName: 'Test',
        initialChatName: 'Test',
      );
      final preferences = NaiAgentUiPreferences();
      final container = ProviderContainer(
        overrides: [
          naiAgentUiPreferencesProvider.overrideWith((_) => preferences),
          naiAgentControllerProvider.overrideWith((_) => controller),
        ],
      );
      final subscription = container.listen(
        settingsMcpStatusProvider,
        (_, __) {},
      );
      addTearDown(() async {
        subscription.close();
        await controller.close();
        container.dispose();
        await root.delete(recursive: true);
      });
      expect(await container.read(settingsMcpStatusProvider.future), isEmpty);
      expect(container.exists(naiAgentControllerProvider), isFalse);
      await controller.initialize();
      controller.selected!.client = client;
      controller.selected!.extensionSignature =
          controller.settings.extensionSignature;
      container.read(naiAgentControllerProvider);
      preferences.replace(controller.settings);
      expect(
        await container.read(settingsMcpStatusProvider.future),
        contains('exa: connected'),
      );
      verify(() => client.mcpCommand('status')).called(1);
    },
  );

  test(
    'status updates do not invalidate their own query; busy hosts use cached status',
    () async {
      final root = await Directory.systemTemp.createTemp('settings-mcp-');
      final client = _Client();
      final controller = NaiAgentWorkspaceController(
        store: AgentWorkspaceStore(root),
        startClient: (_, __, ___, ____, _____) async => client,
        initialWorkspaceName: 'fixture',
        initialChatName: 'fixture',
      );
      final container = ProviderContainer(
        overrides: [
          naiAgentUiPreferencesProvider.overrideWith(
            (_) => NaiAgentUiPreferences(),
          ),
          naiAgentControllerProvider.overrideWith((ref) => controller),
        ],
      );
      when(() => client.isClosed).thenReturn(false);
      when(() => client.close()).thenAnswer((_) async {});
      final pending = Completer<Map<String, dynamic>>();
      const status = 'nai_studio: connected, 19 tools (codemode)';
      when(() => client.mcpCommand('status')).thenAnswer((_) async {
        await Future<void>.delayed(Duration.zero);
        // The live controller can learn this status before the query completes.
        controller.selected!.mcpStatus = status;
        controller.dismissExtensionNotices(controller.selected!);
        return pending.future;
      });
      addTearDown(() async {
        await controller.close();
        container.dispose();
        await root.delete(recursive: true);
      });
      await controller.initialize();
      final runtime = controller.selected!;
      runtime.client = client;
      runtime.extensionSignature = controller.settings.extensionSignature;
      container.read(naiAgentControllerProvider);
      final subscription = container.listen(
        settingsMcpStatusProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);
      final result = container.read(settingsMcpStatusProvider.future);
      await Future<void>.delayed(Duration.zero);
      pending.complete({'mcpStatus': status});
      expect(await result, status);
      await Future<void>.delayed(Duration.zero);
      expect(await container.read(settingsMcpStatusProvider.future), status);
      verify(() => client.mcpCommand('status')).called(1);

      runtime.running = true;
      controller.dismissExtensionNotices(runtime);
      expect(await container.read(settingsMcpStatusProvider.future), status);
      verifyNever(() => client.mcpCommand('status'));
      runtime.extensionSignature = null;
      controller.dismissExtensionNotices(runtime);
      expect(await container.read(settingsMcpStatusProvider.future), isEmpty);
    },
  );
}
