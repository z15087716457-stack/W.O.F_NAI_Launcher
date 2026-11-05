import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../data/services/nai_agent/agent_workspace_store.dart';
import '../../../l10n/app_localizations.dart';
import 'nai_agent_inventory.dart';
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
}) async {
  final value = await readNaiAgentInventory(
    node: node,
    script: script,
    config: config,
    timeout: const Duration(seconds: 20),
  );
  return NaiAgentSkillInventory(
    [
      for (final row in value['skills'] as List)
        NaiAgentSkill.fromJson(Map<String, dynamic>.from(row as Map)),
    ],
    (value['catalogChars'] as num?)?.toInt() ?? 0,
    config,
  );
}

/// Bumped after any skill change so settings re-read the folders.
final naiAgentSkillRevisionProvider = StateProvider<int>((ref) => 0);

final _skillsCacheProvider = Provider((ref) {
  ref.watch(naiAgentSkillRevisionProvider);
  ref.watch(naiAgentRuntimePathsProvider);
  return NaiAgentInventoryCache<NaiAgentSkillInventory>();
});

final naiAgentSkillsProvider = FutureProvider.autoDispose
    .family<NaiAgentSkillInventory, String?>((ref, workspaceId) async {
      final cache = ref.watch(_skillsCacheProvider);
      final settings = watchNaiAgentInventorySettings(
        ref,
        workspaceId,
        includeSkills: true,
      );
      final store = ref.watch(naiAgentWorkspaceStoreProvider);
      final paths = ref.watch(naiAgentRuntimePathsProvider);
      final script = p.join(p.dirname(paths.host), 'list-skills.mjs');
      final workspace = workspaceId == null
          ? null
          : await store.getWorkspace(workspaceId);
      final config = <String, dynamic>{
        'builtinDirectory': store.builtinSkillsDirectory.absolute.path,
        'globalDirectory': store.globalSkillsDirectory.absolute.path,
        if (workspaceId != null)
          'workspaceDirectory': store
              .skillSourceDirectory('workspace', workspaceId: workspaceId)
              .absolute
              .path,
        'disabled': settings.disabledSkills,
        'modes': settings.skillModes,
        'cwd': (workspace?.directory ?? store.root).absolute.path,
        'agentDir': (workspace?.agentDirectory ?? store.root).absolute.path,
        'packages': store.packageConfig(workspace, settings),
      };
      if (!await File(paths.node).exists() || !await File(script).exists()) {
        return NaiAgentSkillInventory(const [], 0, config);
      }
      return cache.read(
        workspaceId,
        config,
        () => listNaiAgentSkills(
          node: paths.node,
          script: script,
          config: config,
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
