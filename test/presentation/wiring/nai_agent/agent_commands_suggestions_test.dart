import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_skills_provider.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart' as view;
import 'agent_wiring_harness.dart';

class _Controller extends AgentTestController {
  _Controller(super.store);
  @override
  Future<void> compact([String? instructions]) async {
    calls.add('compact:$instructions');
  }
}

void main() {
  late AgentWiringHarness h;
  late _Controller c;
  setUp(() async {
    h = AgentWiringHarness();
    await h.init(
      controller: (store) => c = _Controller(store),
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
  });
  tearDown(() async => h.dispose());

  testWidgets('/compact intercepts instructions and never sends a prompt', (
    tester,
  ) async {
    await c.updateSettings({'providerId': '', 'modelId': ''});
    await tester.runAsync(() => c.saveComposer('/compact 保留角色设定'));
    await h.pump(tester);
    expect(
      await tester.runAsync(() => h.panel(tester).actions.onSend(steer: false)),
      true,
    );
    expect(c.calls, ['compact:保留角色设定']);
    expect(c.selected!.composer.text, isEmpty);
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
