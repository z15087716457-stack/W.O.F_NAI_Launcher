import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/krita/bridge_draft_guard.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/models/image/image_params.dart';
import '../../providers/krita/bridge_draft_snapshot.dart';
import '../../providers/pill_workspace_provider.dart';
import '../../providers/prompt_block_library_provider.dart';
import '../../ui/agent/agent_contract.dart';
import 'agent_thread_mapper.dart';

final agentDraftProvider = Provider<BridgeDraftSnapshot>((ref) {
  ref.watch(bridgeDraftVersionProvider);
  ref.watch(pillWorkspaceRevisionProvider);
  return readBridgeDraft(ref, reactive: true);
});

List<AgentMention> agentDraftMentions(
  BridgeDraftSnapshot draft,
  AppLocalizations l,
) {
  final fields = draft.fields;
  String count(Object? text) => l.imageViewer_tagCount(
    (text?.toString() ?? '')
        .split(',')
        .where((t) => t.trim().isNotEmpty)
        .length,
  );
  return [
    AgentMention(
      id: 'draft/prompt',
      kind: AgentMentionKind.prompt,
      label: l.ag_field_prompt,
      detail: count(fields['prompt']),
    ),
    AgentMention(
      id: 'draft/negative',
      kind: AgentMentionKind.negative,
      label: l.ag_field_negative,
      detail: count(fields['negative_prompt']),
    ),
    for (final (i, c) in agentMaps(fields['characters']).indexed)
      AgentMention(
        id: 'draft/character/${c['id']}',
        kind: AgentMentionKind.character,
        label: (c['name'] as String? ?? '').isEmpty
            ? l.gen_characterN(i + 1)
            : c['name'] as String,
        detail: count(c['prompt']),
      ),
  ];
}

AgentDraftSummary agentDraftSummary(
  BridgeDraftSnapshot draft,
  ImageParams params,
  ImageProvider? image,
) {
  var blocks = 0;
  void count(Object? value) {
    if (value is Map) {
      if (value['instances'] is Map) {
        blocks += (value['instances'] as Map).length;
      }
      for (final entry in value.entries) {
        if (entry.key != 'instances') count(entry.value);
      }
    }
  }

  count(draft.documents);
  return AgentDraftSummary(
    model: draft.fields['model'].toString(),
    prompt: draft.fields['prompt'] as String? ?? '',
    width: agentInt(draft.fields['width']),
    height: agentInt(draft.fields['height']),
    characters: agentMaps(draft.fields['characters']).length,
    blocks: blocks,
    references:
        params.enabledVibeReferencesV4.length +
        params.enabledPreciseReferences.length,
    image: image,
  );
}

List<AgentMention> agentBlockMentions(PromptBlockLibraryState? library) => [
  for (final block in library?.blocks ?? [])
    AgentMention(
      id: 'block/${block.id}',
      kind: AgentMentionKind.block,
      label: block.name,
    ),
];
