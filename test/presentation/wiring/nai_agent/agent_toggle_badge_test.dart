import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_generation_approvals.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_image_approvals.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_questions.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_glyphs.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_toggle_badge.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_toggle_wiring.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_wiring.dart';

import '../../providers/nai_agent/generation_approvals_test.dart'
    show approvalQuote;
import 'agent_wiring_harness.dart';

void main() {
  test('waiting > running > done in both expanded and collapsed views', () {
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
    expect(sample(expanded: true), AgentToggleBadge.done);
    expect(sample(), AgentToggleBadge.none);
    expect(sample(running: {'a'}, expanded: true), AgentToggleBadge.running);
    expect(sample(waiting: {'a'}, expanded: true), AgentToggleBadge.waiting);
    expect(sample(expanded: true), AgentToggleBadge.done);
    ledger.clearDone();
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

  testWidgets('toolbar and header share held-chat status and completion timing', (
    tester,
  ) async {
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
      child: const Row(
        children: [
          AgentToggleWiring(),
          AgentToggleWiring(),
          Expanded(child: AgentWiring()),
        ],
      ),
      width: 560,
    );
    void expectStatus(AgentToggleBadge status) {
      final buttons = find.byType(AgentToggleButton);
      expect(buttons, findsNWidgets(2));
      expect(
        tester.widgetList<AgentToggleButton>(buttons).map((w) => w.badge),
        everyElement(status),
      );
      expect(
        tester.widget<AgentStatusMark>(find.byType(AgentStatusMark)).badge,
        status,
      );
    }

    expectStatus(AgentToggleBadge.none);
    final runtime = h.c.selected!;
    runtime.starting = true;
    // Switch away: the first runtime is still held in a different workspace.
    await tester.runAsync(() => h.c.createWorkspace('other'));
    expect(h.c.selected!.chat.id, isNot(runtime.chat.id));
    await h.c.renameChat(h.c.selected!.chat.id, 'starting');
    await tester.pump();
    expectStatus(AgentToggleBadge.running);
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
    expectStatus(AgentToggleBadge.waiting);
    questions.answer(questions.forChat(runtime.chat.id).single.id, {
      'q': 'yes',
    });
    await answer;
    await tester.pump();
    expectStatus(AgentToggleBadge.running);
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
    expectStatus(AgentToggleBadge.waiting);
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
    expectStatus(AgentToggleBadge.waiting);
    images.decide(images.forChat(runtime.chat.id).single.id, run: false);
    expect(await imageDecision, false);
    runtime.running = false;
    await h.c.renameChat(h.c.selected!.chat.id, 'done');
    await tester.pump();
    expectStatus(AgentToggleBadge.done);
    final prefs = h.container.read(naiAgentUiPreferencesProvider);
    prefs.replace(h.c.settings.copyWith());
    prefs.replace(h.c.settings.copyWith());
    // A preference notification with panelExpanded unchanged must not erase done.
    await tester.pump();
    expectStatus(AgentToggleBadge.done);
    prefs.replace(
      AgentSettings.fromJson({...h.c.settings.toJson(), 'panelExpanded': true}),
    );
    await tester.pump();
    expectStatus(AgentToggleBadge.done);
    await tester.pump(const Duration(seconds: 2));
    expectStatus(AgentToggleBadge.none);
    runtime.running = true;
    final selectedChat = h.c.selected!.chat.id;
    await h.c.renameChat(selectedChat, 'expanded run');
    await tester.pump();
    expectStatus(AgentToggleBadge.running);
    runtime.running = false;
    await h.c.renameChat(selectedChat, 'expanded done');
    await tester.pump();
    expectStatus(AgentToggleBadge.done);
    prefs.replace(h.c.settings);
    await tester.pump();
    expectStatus(AgentToggleBadge.none);
    // Two notifications before a frame still register completion.
    runtime.running = true;
    await h.c.renameChat(h.c.selected!.chat.id, 'short run');
    runtime.running = false;
    await h.c.renameChat(h.c.selected!.chat.id, 'short done');
    await tester.pump();
    expectStatus(AgentToggleBadge.done);
    expect(tester.takeException(), isNull);
  });
}
