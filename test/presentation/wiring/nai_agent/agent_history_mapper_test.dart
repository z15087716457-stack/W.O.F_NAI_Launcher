import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_history_mapper.dart';

void main() {
  setUp(() => setCurrentL10nLocale(const Locale('zh')));
  final start = DateTime(2026, 10, 24, 10);
  AgentTurn turn(int i, List<AgentBlock> blocks) => AgentTurn(
    id: 't$i',
    user: AgentUserMessage(
      text: 'Message $i',
      at: start.add(Duration(minutes: i)),
    ),
    reply: AgentReply(blocks: blocks),
  );
  const qa = AgentAnsweredQuestionsBlock(
    questions: [
      AgentAnsweredQuestion(
        question: 'Choose an outfit?',
        answer: 'Blue coat',
        kind: AgentAnswerKind.option,
      ),
      AgentAnsweredQuestion(
        question: 'Any notes?',
        answer: 'No hat',
        kind: AgentAnswerKind.free,
      ),
    ],
  );
  test(
    'alternates users, model cards and answered questions in source order',
    () {
      final entries = agentHistoryEntries([
        turn(1, [
          const AgentTextBlock('not a card'),
          const AgentPromptSetBlock(setId: 's', revision: 1),
          qa,
        ]),
        turn(2, [const AgentImagesBlock(images: [])]),
      ]);
      expect(entries.map((e) => e.kind), [
        AgentHistoryKind.user,
        AgentHistoryKind.card,
        AgentHistoryKind.questions,
        AgentHistoryKind.user,
        AgentHistoryKind.card,
      ]);
      expect(
        entries
            .where((e) => e.kind == AgentHistoryKind.user)
            .map((e) => e.number),
        [1, 2],
      );
      expect(entries[2].title, contains('Choose an outfit?'));
      expect(entries[2].subtitle, contains('No hat'));
      expect(entries[2].blockIndex, 2);
      expect(entries.every((e) => !e.beforeCompaction), true);
    },
  );
  test(
    'compacted archive keeps original chronology and targets the retained summary',
    () {
      final compact = AgentCompactionBlock(
        summary: 'Summary text',
        tokensBefore: 131000,
        at: start.add(const Duration(minutes: 3)),
        auto: true,
      );
      final archived = [
        turn(1, [qa]),
        turn(2, [compact]),
        turn(4, [const AgentPromptSetBlock(setId: 's', revision: 2)]),
      ];
      final current = [
        turn(4, [compact, const AgentPromptSetBlock(setId: 's', revision: 2)]),
      ];
      final entries = agentHistoryEntries(current, archive: archived);
      expect(entries.map((e) => e.kind), [
        AgentHistoryKind.user,
        AgentHistoryKind.questions,
        AgentHistoryKind.user,
        AgentHistoryKind.compaction,
        AgentHistoryKind.user,
        AgentHistoryKind.card,
      ]);
      expect(
        entries
            .take(3)
            .every(
              (e) =>
                  e.beforeCompaction && e.turnId == 't4' && e.blockIndex == 0,
            ),
        true,
      );
      final marker = entries.singleWhere(
        (e) => e.kind == AgentHistoryKind.compaction,
      );
      expect(marker.auto, true);
      expect(marker.tokensBefore, 131000);
      expect(entries.last.blockIndex, 1);
      expect(entries.last.beforeCompaction, false);
      expect(
        filterAgentHistory(entries, kind: AgentHistoryKind.user),
        hasLength(3),
      );
      expect(
        filterAgentHistory(
          entries,
          kind: AgentHistoryKind.questions,
          query: 'BLUE',
        ),
        hasLength(1),
      );
      expect(filterAgentHistory(entries, query: 'summary'), [marker]);
      expect(filterAgentHistory(entries, query: 'missing'), isEmpty);
    },
  );
}
