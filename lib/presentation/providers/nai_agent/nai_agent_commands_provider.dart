import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'nai_agent_inventory.dart';
import 'nai_agent_skills_provider.dart';
import 'nai_agent_workspace_provider.dart';

final _commandsCacheProvider = Provider((ref) {
  ref.watch(naiAgentSkillRevisionProvider);
  ref.watch(naiAgentRuntimePathsProvider);
  return NaiAgentInventoryCache<List<Map<String, dynamic>>>();
});

/// Uses the host's exact template resolver, even before the first model request.
final naiAgentCommandsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, workspaceId) async {
      final cache = ref.watch(_commandsCacheProvider);
      final settings = watchNaiAgentInventorySettings(ref, workspaceId);
      final store = ref.watch(naiAgentWorkspaceStoreProvider);
      final paths = ref.watch(naiAgentRuntimePathsProvider);
      final workspace = await store.getWorkspace(workspaceId);
      final script = p.join(p.dirname(paths.host), 'list-commands.mjs');
      if (!await File(paths.node).exists() || !await File(script).exists()) {
        return [];
      }
      final config = <String, dynamic>{
        'cwd': workspace.directory.absolute.path,
        'agentDir': workspace.agentDirectory.absolute.path,
        'globalDirectory': store.globalPromptsDirectory.absolute.path,
        'workspaceDirectory': workspace.prompts.absolute.path,
        'packages': store.packageConfig(workspace, settings),
      };
      return cache.read(workspaceId, config, () async {
        final result = await readNaiAgentInventory(
          node: paths.node,
          script: script,
          config: config,
          timeout: const Duration(seconds: 30),
        );
        return [
          for (final command in result['commands'] as List)
            Map<String, dynamic>.from(command as Map),
        ];
      });
    });
