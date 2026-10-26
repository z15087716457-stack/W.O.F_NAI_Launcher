import '../../../core/utils/localization_extension.dart';
import '../../ui/agent/agent_contract.dart';

String _blockKey(AgentBlock b) => switch (b) {
  AgentPromptSetBlock() => 'set/${b.setId}/${b.revision}',
  AgentCompactionBlock() => 'compact/${b.summary}',
  AgentAnsweredQuestionsBlock() =>
    'qa/${b.questions.map((q) => '${q.question}/${q.answer}').join('|')}',
  _ => b.runtimeType.toString(),
};

/// Both inputs are projections of the current branch; the archive is local Pi
/// history before compaction, never the all-branches fork menu.
List<AgentHistoryEntry> agentHistoryEntries(
  List<AgentTurn> current, {
  List<AgentTurn> archive = const [],
}) {
  final l = currentL10n;
  final source = archive.isEmpty ? current : archive;
  final compactions = <(AgentTurn, int, AgentCompactionBlock)>[
    for (final t in current)
      for (final (i, b) in (t.reply?.blocks ?? <AgentBlock>[]).indexed)
        if (b is AgentCompactionBlock) (t, i, b),
  ];
  final entries = <AgentHistoryEntry>[];
  var number = 0;
  for (final t in source) {
    final target = current.where((c) => c.user.at == t.user.at).firstOrNull;
    final fallback =
        compactions
            .where((c) => c.$3.at == null || !c.$3.at!.isBefore(t.user.at))
            .firstOrNull ??
        compactions.lastOrNull;
    final turnId = target?.id ?? fallback?.$1.id ?? t.id;
    final before = target == null && fallback != null;
    void add(
      AgentHistoryKind kind,
      String title,
      String subtitle, {
      int? index,
      DateTime? at,
      AgentCompactionBlock? compact,
      bool compacted = false,
    }) {
      entries.add(
        AgentHistoryEntry(
          id: '${t.id}/history/${index ?? 'user'}',
          turnId: compacted ? fallback?.$1.id ?? turnId : turnId,
          kind: kind,
          title: title,
          subtitle: subtitle,
          at: at ?? t.user.at,
          number: kind == AgentHistoryKind.user ? ++number : null,
          blockIndex: before || compacted ? fallback?.$2 : index,
          beforeCompaction: before || compacted,
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
        final ci = compactions
            .where((c) => c.$3.summary == b.summary)
            .firstOrNull;
        entries.add(
          AgentHistoryEntry(
            id: '${t.id}/compact/$i',
            turnId: ci?.$1.id ?? turnId,
            kind: AgentHistoryKind.compaction,
            title: b.summary,
            at: b.at,
            blockIndex: ci?.$2 ?? fallback?.$2 ?? i,
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
    final occurrences = <String, int>{};
    for (final (i, b) in blocks.indexed) {
      final key = _blockKey(b),
          occurrence = occurrences.update(
            _blockKey(b),
            (n) => n + 1,
            ifAbsent: () => 0,
          );
      final matches = (target?.reply?.blocks ?? <AgentBlock>[]).indexed
          .where((e) => _blockKey(e.$2) == key)
          .toList();
      final match = matches.elementAtOrNull(occurrence);
      final index = match?.$1 ?? i;
      final compacted = archive.isNotEmpty && match == null && fallback != null;
      switch (b) {
        case AgentAnsweredQuestionsBlock():
          add(
            AgentHistoryKind.questions,
            b.questions.map((q) => q.question).join(' · '),
            b.questions.map((q) => l.ag_historyAnswer(q.answer)).join(' · '),
            index: index,
            compacted: compacted,
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
            compacted: compacted,
          );
        case AgentImagesBlock():
          add(
            AgentHistoryKind.card,
            l.ag_historyImages(b.images.length),
            '',
            index: index,
            compacted: compacted,
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
            compacted: compacted,
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
              compacted: compacted,
            );
          }
        default:
          break;
      }
    }
  }
  return entries;
}

List<AgentHistoryEntry> filterAgentHistory(
  List<AgentHistoryEntry> entries, {
  AgentHistoryKind? kind,
  String query = '',
}) {
  final text = query.trim().toLowerCase();
  return entries
      .where(
        (e) =>
            (kind == null || e.kind == kind) &&
            (text.isEmpty ||
                '${e.title}\n${e.subtitle}'.toLowerCase().contains(text)),
      )
      .toList();
}
