import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_generation_approvals.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_image_approvals.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_questions.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_glyphs.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_toggle_badge.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_toggle_wiring.dart';

import '../../providers/nai_agent/generation_approvals_test.dart'
    show approvalQuote;
import 'agent_wiring_harness.dart';

void main() {
  test('waiting > running > done; opening clears done for every toolbar', () {
    final ledger = AgentToggleBadgeLedger();
    AgentToggleBadge sample({
      bool expanded = false,
      Set<String> waiting = const {},
      Set<String> running = const {},
      Set<String> chats = const {'a', 'b'},
    }) => ledger.update(
      expanded: expanded,
      waiting: waiting,
      running: running,
      chats: chats,
    );
    expect(sample(), AgentToggleBadge.none);
    expect(sample(running: {'a'}), AgentToggleBadge.running);
    expect(sample(running: {'a'}, waiting: {'a'}), AgentToggleBadge.waiting);
    expect(sample(waiting: {'a'}), AgentToggleBadge.waiting);
    expect(sample(running: {'b'}), AgentToggleBadge.running);
    expect(sample(), AgentToggleBadge.done);
    expect(sample(), AgentToggleBadge.done);
    expect(sample(expanded: true), AgentToggleBadge.none);
    expect(sample(), AgentToggleBadge.none);
    sample(running: {'a'}, expanded: true);
    expect(sample(expanded: true), AgentToggleBadge.none);
    expect(sample(), AgentToggleBadge.none);
    sample(running: {'a'});
    expect(sample(chats: {'b'}), AgentToggleBadge.none);
    sample(running: {'a'});
    expect(sample(waiting: {'a'}), AgentToggleBadge.waiting);
    expect(sample(waiting: {'a'}), AgentToggleBadge.waiting);
    expect(sample(), AgentToggleBadge.done);
    sample(expanded: true);
    expect(sample(waiting: {'a'}), AgentToggleBadge.waiting);
    expect(sample(), AgentToggleBadge.none);
  });

  testWidgets(
    'toggle watches all held chats, questions and expansion; short runs retained',
    (tester) async {
      final h = AgentWiringHarness();
      await tester.runAsync(h.init);
      addTearDown(h.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // 角标只在 Agent 已经启动过后才看：开关本身不创建控制器。
      await h.pump(tester, child: const AgentToggleWiring());
      expect(h.container.exists(naiAgentControllerProvider), isFalse);
      h.container.read(naiAgentControllerProvider);
      await h.pump(
        tester,
        child: const Row(children: [AgentToggleWiring(), AgentToggleWiring()]),
      );
      AgentToggleBadge badge() => tester
          .widgetList<AgentToggleButton>(find.byType(AgentToggleButton))
          .first
          .badge;
      expect(badge(), AgentToggleBadge.none);
      final runtime = h.c.selected!;
      runtime.starting = true;
      // Switch away: the first runtime is still held in a different workspace.
      await tester.runAsync(() => h.c.createWorkspace('other'));
      expect(h.c.selected!.chat.id, isNot(runtime.chat.id));
      await h.c.renameChat(h.c.selected!.chat.id, 'starting');
      await tester.pump();
      expect(badge(), AgentToggleBadge.running);
      runtime.starting = false;
      runtime.running = true;
      await h.c.renameChat(h.c.selected!.chat.id, 'running');
      final questions = h.container.read(naiAgentQuestionsProvider);
      final answer = questions.ask(runtime.workspace.id, runtime.chat.id, {
        'questions': [
          {
            'id': 'q',
            'question': 'Continue?',
            'options': ['yes'],
          },
        ],
      }, NaiAgentCancellation());
      await tester.pump();
      expect(badge(), AgentToggleBadge.waiting);
      questions.answer(questions.forChat(runtime.chat.id).single.id, {
        'q': 'yes',
      });
      await answer;
      await tester.pump();
      expect(badge(), AgentToggleBadge.running);
      final owner = NaiAgentConversationOwner(
        runtime.workspace.id,
        runtime.chat.id,
      );
      final generations = h.container.read(naiAgentGenerationApprovalsProvider);
      final generationDecision = generations.request(
        owner,
        approvalQuote(),
        NaiAgentCancellation(),
        () {},
      );
      await tester.pump();
      expect(badge(), AgentToggleBadge.waiting);
      generations.decide(
        generations.forChat(runtime.chat.id).single.id,
        generate: false,
      );
      expect(await generationDecision, false);
      final images = h.container.read(naiAgentImageApprovalsProvider);
      final imageDecision = images.request(
        owner,
        {},
        DateTime.now().add(const Duration(minutes: 1)),
        NaiAgentCancellation(),
        () {},
      );
      await tester.pump();
      expect(badge(), AgentToggleBadge.waiting);
      images.decide(images.forChat(runtime.chat.id).single.id, run: false);
      expect(await imageDecision, false);
      runtime.running = false;
      await h.c.renameChat(h.c.selected!.chat.id, 'done');
      await tester.pump();
      expect(
        tester
            .widgetList<AgentToggleButton>(find.byType(AgentToggleButton))
            .map((w) => w.badge),
        everyElement(AgentToggleBadge.done),
      );
      final prefs = h.container.read(naiAgentUiPreferencesProvider);
      prefs.replace(h.c.settings.copyWith());
      prefs.replace(h.c.settings.copyWith());
      // A preference notification with panelExpanded unchanged must not erase done.
      await tester.pump();
      expect(badge(), AgentToggleBadge.done);
      await tester.runAsync(() => h.c.updateSettings({'panelExpanded': true}));
      prefs.replace(h.c.settings);
      await tester.pump();
      expect(badge(), AgentToggleBadge.none);
      await tester.runAsync(() => h.c.updateSettings({'panelExpanded': false}));
      prefs.replace(h.c.settings);
      await tester.pump();
      expect(badge(), AgentToggleBadge.none);
      // Two notifications before a frame still register completion.
      runtime.running = true;
      await h.c.renameChat(h.c.selected!.chat.id, 'short run');
      runtime.running = false;
      await h.c.renameChat(h.c.selected!.chat.id, 'short done');
      await tester.pump();
      expect(badge(), AgentToggleBadge.done);
      expect(tester.takeException(), isNull);
    },
  );
}
