import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'nai_agent_inventory_cache.dart';
import 'nai_agent_workspace_provider.dart';
import 'nai_agent_skills_provider.dart';

/// Uses the host's exact template resolver, even before the first model request.
///
/// 列一次要起 Node；结果经 [naiAgentInventoryCacheProvider] 留到提示词文件夹或刷新序号变了为止。
/// 正在列的那次由缓存共用，所以离开页面不再结束它：列完的结果留着给下次用（卡住的照旧 30 秒超时结束）。
final naiAgentCommandsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, workspaceId) async {
      final revision = ref.watch(naiAgentSkillRevisionProvider);
      final store = ref.read(naiAgentWorkspaceStoreProvider);
      final paths = ref.read(naiAgentRuntimePathsProvider);
      final start = ref.read(naiAgentListProcessStarterProvider);
      final cache = ref.read(naiAgentInventoryCacheProvider);
      final stat = ref.read(naiAgentFileStatProvider);
      final workspace = await store.getWorkspace(workspaceId);
      final script = p.join(p.dirname(paths.host), 'list-commands.mjs');
      if (!await File(paths.node).exists() || !await File(script).exists()) {
        return [];
      }
      final packages = store.packageConfig(
        workspace,
        ref.read(naiAgentUiPreferencesProvider).settings,
      );
      final input = <String, dynamic>{
        'cwd': workspace.directory.absolute.path,
        'agentDir': workspace.agentDirectory.absolute.path,
        'globalDirectory': store.globalPromptsDirectory.absolute.path,
        'workspaceDirectory': workspace.prompts.absolute.path,
        'packages': packages,
      };
      return cache.read(
        slot: jsonEncode(['commands', workspaceId]),
        request: jsonEncode([paths.node, script, revision, input]),
        folders: (takenAt) => naiAgentHasEnabledPackages(packages)
            ? Future.value(null)
            : naiAgentPromptFoldersStamp(
                [
                  workspace.prompts.absolute.path,
                  store.globalPromptsDirectory.absolute.path,
                ],
                takenAt,
                stat: stat,
              ),
        list: () => listNaiAgentCommands(
          node: paths.node,
          script: script,
          input: input,
          start: start,
        ),
      );
    });

/// Lists the prompt templates the host would offer; never starts a session.
Future<List<Map<String, dynamic>>> listNaiAgentCommands({
  required String node,
  required String script,
  required Map<String, dynamic> input,
  NaiAgentListProcessStarter start = startNaiAgentListProcess,
}) async {
  final process = await start(node, [
    script,
  ], workingDirectory: p.dirname(script));
  unawaited(process.stderr.drain<void>());
  process.stdin.writeln(jsonEncode(input));
  await process.stdin.close();
  final line = await process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .first
      .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          process.kill();
          throw TimeoutException('Template inventory timed out');
        },
      );
  await process.exitCode;
  final result = jsonDecode(line) as Map;
  if (result['error'] is String) {
    throw StateError(result['error'] as String);
  }
  return [
    for (final command in result['commands'] as List)
      Map<String, dynamic>.from(command as Map),
  ];
}
