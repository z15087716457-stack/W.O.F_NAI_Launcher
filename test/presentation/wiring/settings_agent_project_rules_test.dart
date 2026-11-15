import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_agent.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'workspace prefix settings share prompt persistence without starting Agent',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'nai-settings-prefix-',
      );
      addTearDown(() => root.delete(recursive: true));
      final store = AgentWorkspaceStore(root);
      final a = await store.createWorkspace('A');
      final b = await store.createWorkspace('B');
      await store.patchSettings({'systemPromptPrefix': 'GLOBAL'});
      final container = ProviderContainer(
        overrides: [naiAgentWorkspaceStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final backend = container.read(settingsAgentBackendProvider);
      await backend.selectWorkspace(a.id);
      Future<void> save(String? text, String? expected) =>
          backend.saveSystemPrompt(
            prefix: true,
            scope: SettingsPromptScope.workspace,
            text: text,
            workspaceId: a.id,
            expectedGlobal: null,
            expectedWorkspace: expected,
          );
      await save('OWN', null);
      expect((await store.getWorkspace(a.id)).customSystemPromptPrefix, 'OWN');
      expect((await store.readSettings()).systemPromptPrefix, 'GLOBAL');
      await expectLater(save('STALE', null), throwsStateError);
      await save('', 'OWN');
      expect((await store.getWorkspace(a.id)).customSystemPromptPrefix, isNull);
      expect(await store.effectiveSystemPrompt(a.id), startsWith('GLOBAL'));
      await save(null, null);
      expect((await store.getWorkspace(a.id)).customSystemPromptPrefix, isNull);
      await backend.selectWorkspace(b.id);
      await expectLater(save('WRONG_WORKSPACE', null), throwsStateError);
      expect((await store.getWorkspace(a.id)).customSystemPromptPrefix, isNull);
      expect((await store.getWorkspace(b.id)).customSystemPromptPrefix, isNull);
      expect(container.exists(naiAgentControllerProvider), false);
    },
  );

  test(
    'settings select workspaces and read AGENTS without starting Agent or creating files',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'nai-settings-project-rules-',
      );
      addTearDown(() => root.delete(recursive: true));
      final store = AgentWorkspaceStore(root);
      final a = await store.createWorkspace('A');
      final b = await store.createWorkspace('B');
      await store.patchSettings({
        'globalInstructions': 'SHARED',
        'systemPromptPrefix': 'PREFIX',
      });
      final bFile = File(p.join(b.directory.path, 'AGENTS.md'));
      await bFile.writeAsString('B_RULES');
      final container = ProviderContainer(
        overrides: [naiAgentWorkspaceStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final backend = container.read(settingsAgentBackendProvider);
      expect(await backend.selectWorkspace(a.id), true);
      expect(
        await container.read(settingsAgentProjectRulesProvider(a.id).future),
        null,
      );
      expect(await File(p.join(a.directory.path, 'AGENTS.md')).exists(), false);
      expect(await backend.selectWorkspace(b.id), true);
      expect(
        await container.read(settingsAgentProjectRulesProvider(b.id).future),
        'B_RULES',
      );
      expect((await store.readSettings()).selectedWorkspaceId, b.id);
      expect((await store.readSettings()).globalInstructions, 'SHARED');
      expect((await store.readSettings()).systemPromptPrefix, 'PREFIX');
      expect(container.exists(naiAgentControllerProvider), false);
      await bFile.writeAsString('B_UPDATED');
      expect(await backend.selectWorkspace(b.id), true);
      expect(
        await container.read(settingsAgentProjectRulesProvider(b.id).future),
        'B_UPDATED',
      );
      expect(container.exists(naiAgentControllerProvider), false);
    },
  );
}
