import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/external_session.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_questions.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_window_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_canvas_notice.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_glyphs.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_canvas_notice_wiring.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_toggle_badge.dart';
import 'agent_wiring_harness.dart';

void main() {
  Future<AgentWiringHarness> setup(WidgetTester tester) async {
    final h = AgentWiringHarness();
    await tester.runAsync(
      () => h.init(
        overrides: [naiAgentWindowHostProvider.overrideWithValue(null)],
      ),
    );
    return h;
  }

  Future<AgentChatRuntime> session(
    WidgetTester tester,
    AgentWiringHarness h,
    String client,
  ) async => (await tester.runAsync(
    () => h.c.openExternal(
      workspaceId: h.c.selectedWorkspace!.id,
      client: client,
      summary: 'Storyboard',
    ),
  ))!;
  void result(
    AgentWiringHarness h,
    AgentChatRuntime r,
    String id,
    int at, {
    bool failed = false,
  }) {
    final call =
        ExternalAgentCall(
            id: id,
            name: 'prompt_set',
            arguments: {},
            startedAt: at,
          )
          ..finishedAt = at
          ..result = {
            ...naiAgentTextResult({'title': 'Rain'}),
            if (failed) 'isError': true,
          };
    r.external!.calls.add(call);
    h.c.externalResult(r, call);
    h.c.externalChanged(r);
  }

  testWidgets('closed canvas notices do not create the controller', (
    tester,
  ) async {
    final h = await setup(tester);
    await h.pump(tester, child: const AgentCanvasNoticeWiring());
    expect(h.container.exists(naiAgentControllerProvider), isFalse);
    expect(find.byType(AgentCanvasNotice), findsNothing);
  });
  testWidgets(
    'View chooses the latest result, preserves input and keeps the badge after fading',
    (tester) async {
      final h = await setup(tester);
      h.container.read(naiAgentControllerProvider);
      final previous = h.c.selected!;
      previous.composer = const AgentComposerState(
        text: 'Do not lose my draft',
      );
      final a = await session(tester, h, 'First'),
          b = await session(tester, h, 'Second');
      final now = DateTime.now().millisecondsSinceEpoch;
      result(h, a, 'a', now - 100);
      result(h, b, 'b', now);
      await h.pump(tester, child: const AgentCanvasNoticeWiring());
      expect(
        tester.widget<AgentCanvasNotice>(find.byType(AgentCanvasNotice)).client,
        'Second',
      );
      expect(h.c.latestUnreadExternal, same(b));
      await tester.pump(const Duration(milliseconds: 5400));
      expect(b.external!.unread, isTrue);
      expect(
        h.container.read(agentToggleBadgeProvider),
        isNot(AgentToggleBadge.none),
      );
      result(h, b, 'b-new', DateTime.now().millisecondsSinceEpoch);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('agent-canvas-notice-view')));
      for (var i = 0; i < 100 && !h.c.settings.panelExpanded; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
      }
      await tester.pump();
      expect(h.c.selected, same(b));
      expect(h.c.settings.panelExpanded, isTrue);
      expect(b.external!.unread, isFalse);
      expect(b.external!.notice, isNull);
      expect(find.byType(AgentCanvasNotice), findsNothing);
      expect(previous.composer.text, 'Do not lose my draft');
      expect(previous.chat.isDraft, isFalse);
    },
  );
  testWidgets('a failed operation is never presented as a successful update', (
    tester,
  ) async {
    final h = await setup(tester);
    h.container.read(naiAgentControllerProvider);
    final r = await session(tester, h, 'External');
    result(h, r, 'failed', DateTime.now().millisecondsSinceEpoch, failed: true);
    await h.pump(tester, child: const AgentCanvasNoticeWiring());
    expect(
      tester.widget<AgentCanvasNotice>(find.byType(AgentCanvasNotice)).kind,
      AgentCanvasNoticeKind.failed,
    );
  });
  testWidgets(
    'actual pending questions notify without repeatedly restarting their five seconds',
    (tester) async {
      final h = await setup(tester);
      h.container.read(naiAgentControllerProvider);
      final r = await session(tester, h, 'External');
      r.external!.unread = true;
      h.c.externalChanged(r);
      await h.pump(tester, child: const AgentCanvasNoticeWiring());
      final token = NaiAgentCancellation();
      final pending = h.container.read(naiAgentQuestionsProvider).ask(
        r.workspace.id,
        r.chat.id,
        {
          'questions': [
            {'id': 'one', 'question': 'Choose a style'},
          ],
        },
        token,
      );
      final cancelled = expectLater(pending, throwsA(isA<NaiAgentToolError>()));
      await tester.pump();
      final first = tester.widget<AgentCanvasNotice>(
        find.byType(AgentCanvasNotice),
      );
      expect(first.kind, AgentCanvasNoticeKind.attention);
      await tester.pump(const Duration(seconds: 3));
      h.c.externalChanged(r);
      await tester.pump();
      final rebuilt = tester.widget<AgentCanvasNotice>(
        find.byType(AgentCanvasNotice),
      );
      expect(rebuilt.at, first.at);
      await tester.pump(const Duration(milliseconds: 2400));
      final fade = find.ancestor(
        of: find.byKey(const Key('agent-canvas-notice')),
        matching: find.byType(AnimatedOpacity),
      );
      expect(tester.widget<AnimatedOpacity>(fade).opacity, 0);
      expect(
        h.container.read(naiAgentQuestionsProvider).forChat(r.chat.id),
        hasLength(1),
      );
      final other = await session(tester, h, 'Second');
      result(
        h,
        other,
        'new-result',
        first.at.add(const Duration(milliseconds: 10)).millisecondsSinceEpoch,
      );
      await tester.pump();
      expect(
        tester.widget<AgentCanvasNotice>(find.byType(AgentCanvasNotice)).kind,
        AgentCanvasNoticeKind.updated,
      );
      expect(
        tester.widget<AgentCanvasNotice>(find.byType(AgentCanvasNotice)).client,
        'Second',
      );
      token.cancel();
      await tester.pump();
      await cancelled;
      expect(
        tester.widget<AgentCanvasNotice>(find.byType(AgentCanvasNotice)).client,
        'Second',
      );
    },
  );
}
