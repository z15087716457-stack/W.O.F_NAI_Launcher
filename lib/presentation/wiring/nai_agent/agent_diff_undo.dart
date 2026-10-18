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

class AgentDiffUndo {
  AgentDiffUndo(this.ref);
  final Ref ref;

  Future<bool> restore(AgentDiffRestore diff, Directory directory) async {
    final fields = agentMap(diff.backup['fields']);
    final docs = agentMap(diff.backup['documents']);
    final patch = <String, dynamic>{};
    String? scope;
    Map<String, dynamic>? document;
    if (diff.characterId == null) {
      if (diff.field != 'prompt' && diff.field != 'negative_prompt') {
        return false;
      }
      if (fields[diff.field] is! String) return false;
      patch[diff.field] = fields[diff.field];
      scope = diff.field == 'prompt' ? PillScopes.main : PillScopes.negative;
      document = agentMap(docs[diff.field]);
    } else {
      final current = agentMaps(readBridgeDraft(ref).fields['characters']);
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
      patch['characters'] = current;
      scope = key == 'prompt'
          ? PillScopes.charPos(diff.characterId!)
          : PillScopes.charNeg(diff.characterId!);
      final lane = agentMap(
        agentMap(agentMap(docs['characters'])['lanes'])[diff.characterId],
      );
      document = agentMap(lane[key == 'prompt' ? 'positive' : 'negative']);
    }
    // Parse before backup/check so malformed history cannot partially write.
    final restored = document.isEmpty ? null : PillDocument.fromJson(document);
    return guardedAgentUndo(
      expected: diff.version,
      version: () => ref.read(bridgeDraftVersionProvider),
      backup: () async {
        await backupBridgeDraft(directory, readBridgeDraft(ref));
      },
      apply: () {
        ref.read(bridgeDraftWriterProvider)(patch);
        if (restored != null) {
          ref
              .read(pillWorkspaceProvider(scope!).notifier)
              .restoreDocument(restored);
        }
      },
    );
  }
}
