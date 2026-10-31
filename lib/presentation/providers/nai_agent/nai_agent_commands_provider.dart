import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'nai_agent_workspace_provider.dart';
import 'nai_agent_skills_provider.dart';

/// Uses the host's exact template resolver, even before the first model request.
final naiAgentCommandsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, workspaceId) async {
      ref.watch(naiAgentSkillRevisionProvider);
      final store = ref.read(naiAgentWorkspaceStoreProvider);
      final workspace = await store.getWorkspace(workspaceId);
      final paths = ref.read(naiAgentRuntimePathsProvider);
      final script = p.join(p.dirname(paths.host), 'list-commands.mjs');
      if (!await File(paths.node).exists() || !await File(script).exists()) {
        return [];
      }
      final process = await Process.start(paths.node, [
        script,
      ], workingDirectory: p.dirname(script));
      ref.onDispose(() => process.kill());
      unawaited(process.stderr.drain<void>());
      process.stdin.writeln(
        jsonEncode({
          'cwd': workspace.directory.absolute.path,
          'agentDir': workspace.agentDirectory.absolute.path,
          'globalDirectory': store.globalPromptsDirectory.absolute.path,
          'workspaceDirectory': workspace.prompts.absolute.path,
          'packages': store.packageConfig(
            workspace,
            ref.read(naiAgentUiPreferencesProvider).settings,
          ),
        }),
      );
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
    });
