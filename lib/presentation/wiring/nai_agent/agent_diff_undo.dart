import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/prompt_block/pill_document.dart';
import '../../providers/krita/bridge_draft_snapshot.dart';
import '../../providers/krita/bridge_draft_writer.dart';
import '../../providers/pill_workspace_provider.dart';
import 'agent_thread_mapper.dart';

/// Checks both sides of the asynchronous backup; no await is allowed between
/// the second check and the synchronous writer.
Future<bool> guardedAgentUndo({
  required String expected,
  required String Function() version,
  required Future<void> Function() backup,
  required void Function() apply,
}) async {
  if (expected.isEmpty || version() != expected) return false;
  await backup();
  if (version() != expected) return false;
  apply();
  return true;
}

final agentDiffUndoProvider = Provider((ref) => AgentDiffUndo(ref));

/// One restore folded into a patch plus the pill documents it brings back.
class _Plan {
  final patch = <String, dynamic>{};
  final documents = <String, PillDocument>{};
}

class AgentDiffUndo {
  AgentDiffUndo(this.ref);
  final Ref ref;

  Future<bool> restore(AgentDiffRestore diff, Directory directory) =>
      restoreAll([diff], directory);

  /// Restores several cards of the same change in a single guarded write.
  /// Every card must still match the current draft version; otherwise nothing
  /// is written.
  Future<bool> restoreAll(
    List<AgentDiffRestore> diffs,
    Directory directory,
  ) async {
    if (diffs.isEmpty) return false;
    final version = diffs.first.version;
    if (version.isEmpty ||
        diffs.any((d) => d.version != version) ||
        ref.read(bridgeDraftVersionProvider) != version) {
      return false;
    }
    final plan = _Plan();
    // Character edits build on one working copy so several lanes combine.
    List<Map<String, dynamic>>? characters;
    for (final diff in diffs) {
      final fields = agentMap(diff.backup['fields']);
      final docs = agentMap(diff.backup['documents']);
      if (diff.field == 'params') {
        if (diff.params.isEmpty) return false;
        for (final key in diff.params) {
          if (!fields.containsKey(key)) return false;
          plan.patch[key] = fields[key];
        }
        continue;
      }
      if (diff.characterId == null) {
        if (diff.field != 'prompt' && diff.field != 'negative_prompt') {
          return false;
        }
        if (fields[diff.field] is! String) return false;
        plan.patch[diff.field] = fields[diff.field];
        final document = agentMap(docs[diff.field]);
        // Parse before backup/check so malformed history cannot partially write.
        if (document.isNotEmpty) {
          plan.documents[diff.field == 'prompt'
              ? PillScopes.main
              : PillScopes.negative] = PillDocument.fromJson(
            document,
          );
        }
        continue;
      }
      characters ??= agentMaps(readBridgeDraft(ref).fields['characters']);
      final current = characters;
      final old = agentMaps(
        fields['characters'],
      ).where((c) => c['id'] == diff.characterId).firstOrNull;
      final key = diff.field.split('/').last;
      final index = current.indexWhere((c) => c['id'] == diff.characterId);
      if (index < 0) {
        if (old == null) return false;
        current.insert(
          (diff.characterIndex ?? current.length).clamp(0, current.length),
          Map.of(old),
        );
      } else {
        current[index] = {...current[index], key: old?[key] ?? ''};
      }
      plan.patch['characters'] = current;
      final lane = agentMap(
        agentMap(agentMap(docs['characters'])['lanes'])[diff.characterId],
      );
      final document = agentMap(
        lane[key == 'prompt' ? 'positive' : 'negative'],
      );
      if (document.isNotEmpty) {
        plan.documents[key == 'prompt'
            ? PillScopes.charPos(diff.characterId!)
            : PillScopes.charNeg(diff.characterId!)] = PillDocument.fromJson(
          document,
        );
      }
    }
    return guardedAgentUndo(
      expected: version,
      version: () => ref.read(bridgeDraftVersionProvider),
      backup: () async {
        await backupBridgeDraft(directory, readBridgeDraft(ref));
      },
      apply: () {
        ref.read(bridgeDraftWriterProvider)(plan.patch);
        for (final MapEntry(:key, :value) in plan.documents.entries) {
          ref.read(pillWorkspaceProvider(key).notifier).restoreDocument(value);
        }
      },
    );
  }
}
