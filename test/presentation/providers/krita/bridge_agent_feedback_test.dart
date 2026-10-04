import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/krita/bridge_session.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_agent_feedback.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';

const agent = BridgeClient(
  id: 'one',
  kind: BridgeClientKind.agent,
  name: 'Codex',
);

BridgeActivity activity(
  String key,
  DateTime now, {
  BridgeActivityStatus status = BridgeActivityStatus.running,
  String? version,
}) => BridgeActivity(
  key: key,
  client: agent,
  operation: 'get_params',
  at: now,
  status: status,
  confirmedDraftVersion: version,
  finishedAt: status == BridgeActivityStatus.running ? null : now,
);

KritaBridgeState session(
  List<BridgeActivity> activities, {
  BridgeActivity? outcome,
  bool connected = false,
  String secret = 'secret',
}) => KritaBridgeState(
  enabled: true,
  secret: secret,
  session: BridgeSession(
    clients: connected ? [agent] : [],
    activities: activities,
    latestAgentOutcome: outcome,
  ),
);

void main() {
  testWidgets('快速请求至少反馈600ms；成功一直绿，普通断连和时间流逝不清除', (tester) async {
    final clock = tester.binding.clock.now;
    final controller = BridgeAgentFeedbackController(
      session([]),
      'v1',
      clock: clock,
    );
    addTearDown(controller.dispose);
    final done = activity(
      'read',
      clock(),
      status: BridgeActivityStatus.completed,
      version: 'v1',
    );
    controller.updateBridge(session([done], outcome: done, connected: true));
    expect(controller.state.phase, BridgeAgentPhase.working);
    await tester.pump(const Duration(milliseconds: 599));
    expect(controller.state.phase, BridgeAgentPhase.working);
    await tester.pump(const Duration(milliseconds: 1));
    expect(controller.state.phase, BridgeAgentPhase.synced);
    controller.updateBridge(session([done], outcome: done));
    await tester.pump(const Duration(minutes: 30));
    expect(controller.state.phase, BridgeAgentPhase.synced);
  });

  testWidgets('改动立即变灰；撤销和旧事件不能重新变绿，只有新确认可以', (tester) async {
    final clock = tester.binding.clock.now;
    final done = activity(
      'read',
      clock().subtract(const Duration(seconds: 2)),
      status: BridgeActivityStatus.completed,
      version: 'v1',
    );
    final controller = BridgeAgentFeedbackController(
      session([done], outcome: done),
      'v1',
      clock: clock,
    );
    addTearDown(controller.dispose);
    expect(controller.state.phase, BridgeAgentPhase.synced);
    controller.updateDraft('v2');
    expect(controller.state.phase, BridgeAgentPhase.changed);
    controller.updateDraft('v1');
    controller.updateBridge(session([done], outcome: done, connected: true));
    expect(controller.state.phase, BridgeAgentPhase.changed);
    final fresh = activity(
      'new read',
      clock(),
      status: BridgeActivityStatus.completed,
      version: 'v1',
    );
    controller.updateBridge(session([fresh, done], outcome: fresh));
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.state.phase, BridgeAgentPhase.synced);
  });

  testWidgets('晚到完成不得确认新内容；可见反馈等待中改动会立即取消', (tester) async {
    final clock = tester.binding.clock.now;
    final controller = BridgeAgentFeedbackController(
      session([]),
      'v1',
      clock: clock,
    );
    addTearDown(controller.dispose);
    final active = activity('read', clock());
    controller.updateBridge(session([active]));
    controller.updateDraft('v2');
    expect(controller.state.phase, BridgeAgentPhase.working);
    final done = active
        .confirm('v1')
        .finish(BridgeActivityStatus.completed, finishedAt: clock());
    controller.updateBridge(session([done], outcome: done));
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.state.phase, BridgeAgentPhase.changed);
    final fresh = activity(
      'fresh',
      clock(),
      status: BridgeActivityStatus.completed,
      version: 'v2',
    );
    controller.updateBridge(session([fresh], outcome: fresh));
    controller.updateDraft('v3');
    expect(controller.state.phase, BridgeAgentPhase.changed);
    await tester.pump(const Duration(seconds: 2));
    expect(controller.state.phase, BridgeAgentPhase.changed);
  });

  testWidgets('并行任务按完成顺序呈现；失败橙色，重启清空；Krita不触发', (tester) async {
    final clock = tester.binding.clock.now;
    final controller = BridgeAgentFeedbackController(
      session([]),
      'v1',
      clock: clock,
    );
    addTearDown(controller.dispose);
    final older = activity('long task', clock());
    final later = activity(
      'later read',
      clock(),
      status: BridgeActivityStatus.completed,
      version: 'v1',
    );
    controller.updateBridge(session([later, older], outcome: later));
    expect(controller.state.phase, BridgeAgentPhase.working);
    final failure = older.finish(
      BridgeActivityStatus.disconnected,
      finishedAt: clock(),
    );
    controller.updateBridge(session([later, failure], outcome: failure));
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.state.phase, BridgeAgentPhase.failed);
    controller.updateBridge(session([], secret: 'new secret'));
    expect(controller.state.phase, BridgeAgentPhase.waiting);
    final krita = BridgeActivity(
      key: 'krita',
      client: const BridgeClient(
        id: 'krita',
        kind: BridgeClientKind.krita,
        name: 'Krita',
      ),
      operation: 'get_params',
      at: clock(),
    );
    controller.updateBridge(session([krita], secret: 'new secret'));
    expect(controller.state.phase, BridgeAgentPhase.waiting);
  });
}
