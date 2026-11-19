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
    },
  );
  test(
    'same-time turns and identical summaries jump to their own positions',
    () {
      final marker = AgentCompactionBlock(summary: 'Summary', at: start);
      final entries = agentHistoryEntries([
        AgentTurn(
          id: 'first',
          user: AgentUserMessage(text: 'first', at: start),
          reply: AgentReply(blocks: [marker]),
        ),
        AgentTurn(
          id: 'second',
          user: AgentUserMessage(text: 'second', at: start),
          reply: AgentReply(
            blocks: [const AgentTextBlock('reply'), marker, qa],
          ),
        ),
      ]);
      expect(entries.map((e) => (e.turnId, e.blockIndex)), [
        ('first', 0),
        ('first', null),
        ('second', 1),
        ('second', null),
        ('second', 2),
      ]);
    },
  );
  test(
    'full branch keeps pre-compaction cards reachable at their actual turns',
    () {
      final compact = AgentCompactionBlock(
        summary: 'Summary text',
        tokensBefore: 131000,
        at: start.add(const Duration(minutes: 3)),
        auto: true,
      );
      final entries = agentHistoryEntries([
        turn(1, [qa]),
        turn(2, [compact]),
        turn(4, [const AgentPromptSetBlock(setId: 's', revision: 2)]),
      ]);
      expect(entries.map((e) => (e.kind, e.turnId, e.blockIndex)), [
        (AgentHistoryKind.user, 't1', null),
        (AgentHistoryKind.questions, 't1', 0),
        (AgentHistoryKind.user, 't2', null),
        (AgentHistoryKind.compaction, 't2', 0),
        (AgentHistoryKind.user, 't4', null),
        (AgentHistoryKind.card, 't4', 0),
      ]);
      expect(entries[3].auto, true);
      expect(entries[3].tokensBefore, 131000);
    },
  );
}
