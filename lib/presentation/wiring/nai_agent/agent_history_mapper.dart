import '../../../core/utils/localization_extension.dart';
import '../../ui/agent/agent_contract.dart';

/// The thread already includes the full current branch and its compaction markers.
List<AgentHistoryEntry> agentHistoryEntries(List<AgentTurn> turns) {
  final l = currentL10n;
  final entries = <AgentHistoryEntry>[];
  var number = 0;
  for (final t in turns) {
    void add(
      AgentHistoryKind kind,
      String title,
      String subtitle, {
      int? index,
      DateTime? at,
      AgentCompactionBlock? compact,
    }) {
      entries.add(
        AgentHistoryEntry(
          id: '${t.id}/history/${index ?? 'user'}',
          turnId: t.id,
          kind: kind,
          title: title,
          subtitle: subtitle,
          at: at ?? t.user.at,
          number: kind == AgentHistoryKind.user ? ++number : null,
          blockIndex: index,
          auto: compact?.auto ?? false,
          tokensBefore: compact?.tokensBefore,
        ),
      );
    }

    final blocks = t.reply?.blocks ?? <AgentBlock>[];
    // Pi places a retained leading summary in the first post-compaction turn.
    for (final (i, b) in blocks.indexed) {
      if (b is AgentCompactionBlock &&
          (b.at == null || !b.at!.isAfter(t.user.at))) {
        entries.add(
          AgentHistoryEntry(
            id: '${t.id}/compact/$i',
            turnId: t.id,
            kind: AgentHistoryKind.compaction,
            title: b.summary,
            at: b.at,
            blockIndex: i,
            auto: b.auto,
            tokensBefore: b.tokensBefore,
          ),
        );
      }
    }
    if (t.user.text.isNotEmpty || t.user.images.isNotEmpty) {
      add(
        AgentHistoryKind.user,
        t.user.text.isEmpty ? l.ag_historyImageMessage : t.user.text,
        '',
      );
    }
    for (final (index, b) in blocks.indexed) {
      switch (b) {
        case AgentAnsweredQuestionsBlock():
          add(
            AgentHistoryKind.questions,
            b.questions.map((q) => q.question).join(' · '),
            b.questions.map((q) => l.ag_historyAnswer(q.answer)).join(' · '),
            index: index,
            at: b.at,
          );
        case AgentPromptSetBlock():
          add(
            AgentHistoryKind.card,
            b.data?.title ?? l.ag_historyPromptSet,
            b.data == null
                ? l.ag_historyPromptSet
                : '${b.data!.items.length} ${b.data!.unit}',
            index: index,
          );
        case AgentImagesBlock():
          add(
            AgentHistoryKind.card,
            l.ag_historyImages(b.images.length),
            '',
            index: index,
          );
        case AgentDiffBlock() ||
            AgentParamBlock() ||
            AgentPositionBlock() ||
            AgentSettingsBlock() ||
            AgentGalleryBlock() ||
            AgentChangeSummaryBlock():
          add(
            AgentHistoryKind.card,
            switch (b) {
              AgentDiffBlock() => l.ag_historyPromptChange,
              AgentParamBlock() => l.ag_historyParams,
              AgentPositionBlock() => l.ag_historyPositions,
              AgentSettingsBlock() => l.ag_historySettings,
              AgentGalleryBlock() => l.ag_historyGallery,
              _ => l.ag_historyChanges,
            },
            '',
            index: index,
          );
        case AgentCompactionBlock():
          if (b.at != null && b.at!.isAfter(t.user.at)) {
            add(
              AgentHistoryKind.compaction,
              b.summary,
              '',
              index: index,
              at: b.at,
              compact: b,
            );
          }
        default:
          break;
      }
    }
  }
  return entries;
}
