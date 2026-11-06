import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_skills_provider.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart' as view;
import 'agent_wiring_harness.dart';

class _Client extends Mock implements PiHostClient {}

void main() {
  late AgentWiringHarness h;
  late AgentTestController c;
  setUp(() async {
    h = AgentWiringHarness();
    await h.init(
      skills: const NaiAgentSkillInventory(
        [
          NaiAgentSkill(
            key: 'global/test',
            name: 'test',
            source: 'global',
            state: 'active',
            description: 'Test skill',
          ),
        ],
        0,
        {},
      ),
    );
    c = h.c;
  });
  tearDown(() async => h.dispose());

  testWidgets('/compact clears the input and shows its own busy state', (
    tester,
  ) async {
    const instructions = '保留角色设定';
    final client = _Client();
    late Completer<void> started;
    late Completer<Map<String, dynamic>> result;
    await tester.runAsync(() async {
      await c.updateSettings({'panelExpanded': true});
      started = Completer<void>();
      result = Completer<Map<String, dynamic>>();
      when(() => client.isClosed).thenReturn(false);
      when(() => client.initialState).thenReturn({});
      when(client.cancelSuggestion).thenAnswer((_) async => {});
      when(client.close).thenAnswer((_) async {});
      when(() => client.compact(instructions)).thenAnswer((_) {
        started.complete();
        return result.future;
      });
      c.selected!
        ..client = client
        ..providerId = c.settings.providerId
        ..modelId = c.settings.modelId
        ..reasoningEffort = c.settings.reasoningEffort
        ..modelRevision = c.readModelRevision()
        ..maxRequestsPerRun = c.settings.maxRequestsPerRun
        ..extensionSignature = c.settings.extensionSignature
        ..messages = [
          {'role': 'user', 'content': '之前的问题', 'timestamp': 1000},
          {'role': 'assistant', 'content': '已经完成的回复', 'timestamp': 1100},
        ];
      await c.saveComposer('/compact $instructions');
    });
    await h.pump(tester, width: 320);

    await tester.tap(find.byKey(const Key('agent-send')));
    await tester.runAsync(
      () => started.future.timeout(const Duration(seconds: 3)),
    );
    await tester.pump();
    final input = find.byKey(const Key('agent-input'));
    expect(tester.widget<TextField>(input).controller!.text, isEmpty);
    expect(h.panel(tester).data.status, view.AgentRunStatus.compacting);
    expect(h.panel(tester).data.thread.last.reply!.live, isFalse);
    expect(find.text('压缩中…'), findsOneWidget);
    expect(find.byKey(const Key('agent-stop')), findsNothing);
    expect(find.byKey(const Key('agent-send-queue')), findsNothing);
    expect(c.calls, isEmpty, reason: 'a builtin is never sent as a prompt');

    await tester.enterText(input, '下一条消息');
    await tester.pump();
    expect(h.panel(tester).data.composer.canSend, isFalse);
    expect(tester.takeException(), isNull);

    await tester.runAsync(() async {
      result.complete({'messages': c.selected!.messages});
      await result.future;
    });
    await tester.pumpAndSettle();
    expect(h.panel(tester).data.status, view.AgentRunStatus.idle);
    expect(find.text('压缩中…'), findsNothing);
    expect(tester.widget<TextField>(input).controller!.text, '下一条消息');
    expect(find.byKey(const Key('agent-send')), findsOneWidget);
    verify(() => client.compact(instructions)).called(1);
  });

  testWidgets(
    '/new creates a draft and clears only the original command draft',
    (tester) async {
      // Persist one chat so the existing createChat operation must make another.
      final runtime = c.selected!;
      runtime.chat = (await tester.runAsync(
        () => c.store.saveDraftChat(runtime.chat),
      ))!;
      c.chats = [runtime.chat];
      await tester.runAsync(() => c.saveComposer('/new'));
      await h.pump(tester);
      expect(
        await tester.runAsync(
          () => h.panel(tester).actions.onSend(steer: false),
        ),
        true,
      );
      expect(c.selected!.chat.id, isNot(runtime.chat.id));
      expect(c.selected!.chat.isDraft, true);
      expect(runtime.composer.text, isEmpty);
      expect(c.calls, isEmpty);
    },
  );

  testWidgets(
    'slash contracts cover three groups, selection inserts or executes; panels get a minimal hook',
    (tester) async {
      c.selected!.client = null;
      await h.pump(tester);
      var panel = h.panel(tester);
      final skill = panel.data.slashCommands.firstWhere(
        (s) => s.kind == view.AgentSlashCommandKind.skill,
      );
      expect(skill.insertion, '/skill:test ');
      await tester.runAsync(() => panel.actions.onSelectSlashCommand!(skill));
      expect(c.selected!.composer.text, '/skill:test ');
      const template = view.AgentSlashCommand(
        kind: view.AgentSlashCommandKind.template,
        name: 'review',
        description: 'Review',
        argumentHint: '[focus]',
      );
      expect(template.executesOnSelect, false);
      await tester.runAsync(
        () => panel.actions.onSelectSlashCommand!(template),
      );
      expect(c.selected!.composer.text, '/review ');
      final compact = panel.data.slashCommands.firstWhere(
        (s) => s.name == 'compact',
      );
      await tester.runAsync(() => panel.actions.onSelectSlashCommand!(compact));
      expect(c.selected!.composer.text, '/compact ');
      final model = panel.data.slashCommands.firstWhere(
        (s) => s.name == 'model',
      );
      expect(
        await tester.runAsync(() => panel.actions.onSelectSlashCommand!(model)),
        true,
      );
      await tester.pumpAndSettle();
      panel = h.panel(tester);
      expect(panel.data.localAction, view.AgentLocalAction.model);
      expect(panel.data.localActionRevision, 1);
      expect(c.selected!.composer.text, isEmpty);
      expect(c.calls, isEmpty);
      expect(await c.executeSlashCommand('ordinary /new'), isNull);
      expect(await c.executeSlashCommand('/skill:test'), isNull);
      expect(await c.executeSlashCommand('/new invalid'), false);
    },
  );

  testWidgets(
    'suggestion projection is empty-input only; acceptance fills and editing clears',
    (tester) async {
      c.selected!.suggestion = '请继续';
      await h.pump(tester);
      expect(h.panel(tester).data.composer.suggestion, '请继续');
      await tester.runAsync(
        () => h.panel(tester).actions.onAcceptSuggestion!(),
      );
      await tester.pumpAndSettle();
      expect(c.selected!.composer.text, '请继续');
      expect(c.selected!.suggestion, isNull);
      expect(h.panel(tester).data.composer.suggestion, isNull);
      c.selected!.suggestion = 'stale';
      await tester.runAsync(() => c.saveComposer('user typing'));
      expect(c.selected!.suggestion, isNull);
      c.selected!.suggestion = 'disabled';
      await tester.runAsync(() => c.updateSettings({'nextSuggestion': false}));
      expect(c.selected!.suggestion, isNull);
    },
  );

  testWidgets(
    'cache warming status maps decision and time without inventing economics',
    (tester) async {
      c.selected!.cacheWarming = {
        'mode': 'idle',
        'state': 'scheduled',
        'nextWarmAt': 1000,
        'lastWarmAt': 700,
        'warmCount': 3,
        'ttlSeconds': 300,
        'decision': {'expectedSavings': 0.1, 'action': 'warm'},
      };
      await h.pump(tester);
      final data = h.panel(tester).data.usage.cacheWarming!;
      expect(data.mode, 'idle');
      expect(data.state, 'scheduled');
      expect(data.expectedSavings, .1);
      expect(data.action, 'warm');
      expect(data.nextWarmAt!.millisecondsSinceEpoch, 1000);
      expect(data.lastWarmAt!.millisecondsSinceEpoch, 700);
      expect(data.warmCount, 3);
      expect(data.ttlSeconds, 300);
      final defaults = view.AgentCacheWarmingData.fromJson(const {});
      expect(defaults.lastWarmAt, isNull);
      expect(defaults.warmCount, 0);
      expect(defaults.ttlSeconds, isNull);
      expect(
        view.AgentCacheWarmingData.fromJson(const {}).expectedSavings,
        isNull,
      );
    },
  );
}
