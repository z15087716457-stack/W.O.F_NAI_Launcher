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
  const priority = [
    AgentToggleBadge.question,
    AgentToggleBadge.approval,
    AgentToggleBadge.runLimit,
    AgentToggleBadge.error,
    AgentToggleBadge.generating,
    AgentToggleBadge.compacting,
    AgentToggleBadge.tool,
    AgentToggleBadge.writing,
    AgentToggleBadge.thinking,
    AgentToggleBadge.starting,
    AgentToggleBadge.done,
    AgentToggleBadge.none,
  ];
  for (var i = 0; i < priority.length; i++) {
    for (var j = i; j < priority.length; j++) {
      final high = priority[i], low = priority[j];
      test('ledger priority ${high.name} > ${low.name}', () {
        final ledger = AgentToggleBadgeLedger();
        final states = {'a': high, 'b': low};
        final results = {
          for (final e in states.entries)
            if (!e.value.isRunning &&
                !{
                  AgentToggleBadge.question,
                  AgentToggleBadge.approval,
                  AgentToggleBadge.none,
                }.contains(e.value))
              e.key: e.value,
        };
        ledger.update(
          expanded: false,
          chats: states.keys.toSet(),
          running: {
            for (final id in results.keys) id: AgentToggleBadge.thinking,
          },
          waiting: {},
        );
        expect(
          ledger.update(
            expanded: false,
            chats: states.keys.toSet(),
            running: {
              for (final e in states.entries)
                if (e.value.isRunning) e.key: e.value,
            },
            waiting: {
              for (final e in states.entries)
                if (e.value == AgentToggleBadge.question ||
                    e.value == AgentToggleBadge.approval)
                  e.key: e.value,
            },
            results: results,
          ),
          high,
        );
      });
    }
  }

  for (final result in [
    AgentToggleBadge.done,
    AgentToggleBadge.error,
    AgentToggleBadge.runLimit,
  ]) {
    test('record and clear ${result.name} only after an observed run', () {
      final ledger = AgentToggleBadgeLedger();
      AgentToggleBadge sample({
        bool running = false,
        bool expanded = false,
        Set<String> chats = const {'a'},
        bool waiting = false,
      }) => ledger.update(
        expanded: expanded,
        chats: chats,
        running: {if (running) 'a': AgentToggleBadge.thinking},
        waiting: {if (waiting) 'a': AgentToggleBadge.approval},
        results: {'a': result},
      );
      expect(sample(), AgentToggleBadge.none);
      sample(running: true);
      expect(sample(waiting: true), AgentToggleBadge.approval);
      expect(sample(), result);
      expect(sample(), result);
      expect(sample(expanded: true), result);
      expect(sample(), AgentToggleBadge.none);
      sample(running: true);
      expect(sample(), result);
      ledger.clearDone();
      expect(sample(), AgentToggleBadge.none);
      sample(running: true);
      sample();
      expect(sample(running: true), AgentToggleBadge.thinking);
      expect(sample(), result);
      expect(sample(chats: {}), AgentToggleBadge.none);
    });

    testWidgets('${result.name} clears after two observed expanded seconds', (
      tester,
    ) async {
      final h = AgentWiringHarness();
      await tester.runAsync(h.init);
      addTearDown(h.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      h.container.read(naiAgentControllerProvider);
      await h.pump(tester, child: const AgentToggleWiring());
      final runtime = h.c.selected!;
      runtime.running = true;
      await h.c.renameChat(runtime.chat.id, 'running');
      runtime.running = false;
      runtime.error = result == AgentToggleBadge.error
          ? 'synthetic error'
          : null;
      runtime.runLimitHit = result == AgentToggleBadge.runLimit ? 3 : null;
      await h.c.renameChat(runtime.chat.id, 'finished');
      await tester.pump();
      expect(h.container.read(agentToggleBadgeProvider), result);
      await tester.pump(const Duration(seconds: 3));
      expect(h.container.read(agentToggleBadgeProvider), result);
      h.container
          .read(naiAgentUiPreferencesProvider)
          .replace(
            AgentSettings.fromJson({
              ...h.c.settings.toJson(),
              'panelExpanded': true,
            }),
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1999));
      expect(h.container.read(agentToggleBadgeProvider), result);
      await tester.pump(const Duration(milliseconds: 1));
      expect(h.container.read(agentToggleBadgeProvider), AgentToggleBadge.none);
    });
  }

  test(
    'runtime streaming, overlapping tools and new requests reset activity',
    () async {
      final h = AgentWiringHarness();
      await h.init();
      addTearDown(h.dispose);
      final r = h.c.selected!;
      void event(Map<String, dynamic> value) =>
          r.recordActivityEvent({'event': value});
      void delta(String type) => event({
        'type': 'message_update',
        'assistantMessageEvent': {'type': type},
      });
      r.running = true;
      expect(agentRuntimeBadge(r), AgentToggleBadge.thinking);
      delta('text_delta');
      expect(agentRuntimeBadge(r), AgentToggleBadge.writing);
      event({'type': 'tool_execution_update', 'toolCallId': 'orphan'});
      expect(agentRuntimeBadge(r), AgentToggleBadge.writing);
      event({
        'type': 'tool_execution_start',
        'toolCallId': 'read',
        'toolName': 'read',
      });
      expect(agentRuntimeBadge(r), AgentToggleBadge.tool);
      event({
        'type': 'tool_execution_start',
        'toolCallId': 'gen',
        'toolName': 'mcp__nai_studio__generation_run',
      });
      expect(agentRuntimeBadge(r), AgentToggleBadge.generating);
      event({'type': 'tool_execution_end', 'toolCallId': 'gen'});
      expect(agentRuntimeBadge(r), AgentToggleBadge.tool);
      event({'type': 'tool_execution_end', 'toolCallId': 'read'});
      expect(agentRuntimeBadge(r), AgentToggleBadge.thinking);
      for (final name in [
        'image_generate',
        'mcp__nai_studio__image_generate',
      ]) {
        for (final action in ['prepare', 'run', 'status', 'cancel']) {
          event({
            'type': 'tool_execution_start',
            'toolCallId': 'image',
            'toolName': name,
            'args': {'action': action},
          });
          expect(
            agentRuntimeBadge(r),
            action == 'run'
                ? AgentToggleBadge.generating
                : AgentToggleBadge.tool,
          );
          event({'type': 'tool_execution_end', 'toolCallId': 'image'});
        }
      }
      for (final type in ['thinking_delta', 'toolcall_delta']) {
        delta('text_delta');
        delta(type);
        expect(agentRuntimeBadge(r), AgentToggleBadge.thinking);
      }
      delta('text_delta');
      r.recordActivityEvent({'type': 'request_started'});
      expect(agentRuntimeBadge(r), AgentToggleBadge.thinking);
      delta('text_delta');
      r.running = false;
      r.running = true;
      expect(agentRuntimeBadge(r), AgentToggleBadge.thinking);
      r.waitingForSlot = true;
      expect(agentRuntimeBadge(r), AgentToggleBadge.starting);
      r.compacting = true;
      expect(agentRuntimeBadge(r), AgentToggleBadge.compacting);
    },
  );

  test('question > thinking > done in both expanded and collapsed views', () {
    final ledger = AgentToggleBadgeLedger();
    AgentToggleBadge sample({
      bool expanded = false,
      Set<String> waiting = const {},
      Set<String> running = const {},
      Set<String> chats = const {'a', 'b'},
    }) => ledger.update(
      expanded: expanded,
      waiting: {for (final id in waiting) id: AgentToggleBadge.question},
      running: {for (final id in running) id: AgentToggleBadge.thinking},
      chats: chats,
    );
    expect(sample(), AgentToggleBadge.none);
    expect(sample(running: {'a'}), AgentToggleBadge.thinking);
    expect(sample(running: {'a'}, waiting: {'a'}), AgentToggleBadge.question);
    expect(sample(waiting: {'a'}), AgentToggleBadge.question);
    expect(sample(running: {'b'}), AgentToggleBadge.thinking);
    expect(sample(), AgentToggleBadge.done);
    expect(sample(), AgentToggleBadge.done);
    expect(sample(expanded: true), AgentToggleBadge.done);
    expect(sample(), AgentToggleBadge.none);
    expect(sample(running: {'a'}, expanded: true), AgentToggleBadge.thinking);
    expect(sample(waiting: {'a'}, expanded: true), AgentToggleBadge.question);
    expect(sample(expanded: true), AgentToggleBadge.done);
    ledger.clearDone();
    expect(sample(expanded: true), AgentToggleBadge.none);
    expect(sample(), AgentToggleBadge.none);
    sample(running: {'a'});
    expect(sample(chats: {'b'}), AgentToggleBadge.none);
    sample(running: {'a'});
    expect(sample(waiting: {'a'}), AgentToggleBadge.question);
    expect(sample(waiting: {'a'}), AgentToggleBadge.question);
    expect(sample(), AgentToggleBadge.done);
    sample(expanded: true);
    expect(sample(waiting: {'a'}), AgentToggleBadge.question);
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
    expectStatus(AgentToggleBadge.starting);
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
    expectStatus(AgentToggleBadge.question);
    questions.answer(questions.forChat(runtime.chat.id).single.id, {
      'q': 'yes',
    });
    await answer;
    await tester.pump();
    expectStatus(AgentToggleBadge.thinking);
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
    expectStatus(AgentToggleBadge.approval);
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
    expectStatus(AgentToggleBadge.approval);
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
    expectStatus(AgentToggleBadge.thinking);
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
