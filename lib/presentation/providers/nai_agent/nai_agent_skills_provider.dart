import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../data/services/nai_agent/agent_workspace_store.dart';
import '../../../l10n/app_localizations.dart';
import 'nai_agent_inventory_cache.dart';
import 'nai_agent_workspace_provider.dart';

/// One skill copy as resolved by the host (`tool/nai_agent/lib/skills.mjs`).
class NaiAgentSkill {
  const NaiAgentSkill({
    required this.key,
    required this.name,
    required this.source,
    required this.state,
    this.description = '',
    this.directory = '',
    this.file = '',
    this.enabled = true,
    this.mode = 'auto',
    this.error,
    this.shadowedBy,
    this.packageSource,
  });

  factory NaiAgentSkill.fromJson(Map<String, dynamic> value) => NaiAgentSkill(
    key: value['key'] as String,
    name: value['name'] as String,
    source: value['source'] as String,
    state: value['state'] as String,
    description: value['description'] as String? ?? '',
    directory: value['directory'] as String? ?? '',
    file: value['file'] as String? ?? '',
    enabled: value['enabled'] != false,
    mode: value['mode'] == 'manual' ? 'manual' : 'auto',
    error: value['error'] as String?,
    shadowedBy: value['shadowedBy'] as String?,
    packageSource: value['packageSource'] as String?,
  );

  final String key, name, source, state, description, directory, file, mode;
  final bool enabled;

  /// `description` | `name` | `missing` | `parse`.
  final String? error;
  final String? shadowedBy;
  final String? packageSource;
  bool get builtin => source == 'builtin';

  /// Settings / composer text. Built-ins ship an English SKILL.md for the
  /// model; the UI shows the localized summary. Other skills show their own.
  String displayDescription(AppLocalizations l) {
    if (!builtin) return description;
    return switch (name) {
      'nai-prompt' => l.set_agSkillDescNaiPrompt,
      'nai-studio' => l.set_agSkillDescNaiStudio,
      _ => description,
    };
  }
}

class NaiAgentSkillInventory {
  const NaiAgentSkillInventory(this.skills, this.catalogChars, this.config);
  final List<NaiAgentSkill> skills;
  final int catalogChars;
  final Map<String, dynamic> config;
}

/// Lists skills with the same resolver a session uses; never starts a session.
Future<NaiAgentSkillInventory> listNaiAgentSkills({
  required String node,
  required String script,
  required Map<String, dynamic> config,
  NaiAgentListProcessStarter start = startNaiAgentListProcess,
}) async {
  final process = await start(node, [
    script,
  ], workingDirectory: p.dirname(script));
  final stderr = process.stderr.transform(utf8.decoder).join();
  process.stdin.writeln(jsonEncode(config));
  await process.stdin.close();
  final line = await process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .first
      .timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          process.kill();
          throw TimeoutException('Skill inventory timed out');
        },
      );
  unawaited(stderr);
  await process.exitCode;
  final value = jsonDecode(line) as Map<String, dynamic>;
  if (value['error'] != null) throw StateError(value['error'] as String);
  return NaiAgentSkillInventory(
    [
      for (final row in value['skills'] as List)
        NaiAgentSkill.fromJson(Map<String, dynamic>.from(row as Map)),
    ],
    (value['catalogChars'] as num?)?.toInt() ?? 0,
    config,
  );
}

/// Bumped after any skill change so settings and the Agent panel re-read the
/// folders, also when nothing on disk looks different.
final naiAgentSkillRevisionProvider = StateProvider<int>((ref) => 0);

/// 列一次要起 Node；结果经 [naiAgentInventoryCacheProvider] 留到技能文件夹、开关或刷新序号变了为止。
final naiAgentSkillsProvider = FutureProvider.autoDispose
    .family<NaiAgentSkillInventory, String?>((ref, workspaceId) async {
      final revision = ref.watch(naiAgentSkillRevisionProvider);
      final settings = ref.watch(
        naiAgentUiPreferencesProvider.select(
          (value) => (
            value.settings.disabledSkills,
            value.settings.skillModes,
            value.settings.packages,
          ),
        ),
      );
      final store = ref.read(naiAgentWorkspaceStoreProvider);
      final paths = ref.read(naiAgentRuntimePathsProvider);
      final start = ref.read(naiAgentListProcessStarterProvider);
      final cache = ref.read(naiAgentInventoryCacheProvider);
      final stat = ref.read(naiAgentFileStatProvider);
      final script = p.join(p.dirname(paths.host), 'list-skills.mjs');
      final workspace = workspaceId == null
          ? null
          : await store.getWorkspace(workspaceId);
      final packages = store.packageConfig(
        workspace,
        ref.read(naiAgentUiPreferencesProvider).settings,
      );
      final config = <String, dynamic>{
        'builtinDirectory': store.builtinSkillsDirectory.absolute.path,
        'globalDirectory': store.globalSkillsDirectory.absolute.path,
        if (workspaceId != null)
          'workspaceDirectory': store
              .skillSourceDirectory('workspace', workspaceId: workspaceId)
              .absolute
              .path,
        'disabled': settings.$1,
        'modes': settings.$2,
        'cwd': (workspace?.directory ?? store.root).absolute.path,
        'agentDir': (workspace?.agentDirectory ?? store.root).absolute.path,
        'packages': packages,
      };
      if (!await File(paths.node).exists() || !await File(script).exists()) {
        return NaiAgentSkillInventory(const [], 0, config);
      }
      return cache.read(
        slot: jsonEncode(['skills', workspaceId]),
        request: jsonEncode([paths.node, script, revision, config]),
        folders: (takenAt) => naiAgentHasEnabledPackages(packages)
            ? Future.value(null)
            : naiAgentSkillFoldersStamp(
                [
                  for (final key in const [
                    'builtinDirectory',
                    'globalDirectory',
                    'workspaceDirectory',
                  ])
                    if (config[key] case final String directory) directory,
                ],
                takenAt,
                stat: stat,
              ),
        list: () => listNaiAgentSkills(
          node: paths.node,
          script: script,
          config: config,
          start: start,
        ),
      );
    });

extension NaiAgentSkillStore on AgentWorkspaceStore {
  Directory skillFolder(String key, {String? workspaceId}) {
    final parts = key.split('/');
    return Directory(
      p.join(
        skillSourceDirectory(parts[0], workspaceId: workspaceId).path,
        parts[1],
      ),
    );
  }
}
