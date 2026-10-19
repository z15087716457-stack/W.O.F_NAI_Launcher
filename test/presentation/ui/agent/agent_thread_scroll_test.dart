import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_panel.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_parts.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

AgentTurn _turn(int i, {int lines = 1}) => AgentTurn(
  id: 't$i',
  user: AgentUserMessage(text: 'Q$i', at: DateTime(2026, 10, 19, 12)),
  reply: AgentReply(
    blocks: [AgentTextBlock(List.filled(lines, 'answer $i').join('\n\n'))],
  ),
);

AgentViewData _view(List<AgentTurn> thread, int revision) {
  final d = AgentFixture.view(AgentScene.chat);
  return AgentViewData(
    now: d.now,
    workspace: d.workspace,
    chat: d.chat,
    workspaces: d.workspaces,
    chats: d.chats,
    composer: const AgentComposerData(text: '', pending: []),
    thread: thread,
    shelf: d.shelf,
    memory: d.memory,
    usage: d.usage,
    models: d.models,
    thinking: d.thinking,
    permission: d.permission,
    mentions: d.mentions,
    skills: d.skills,
    revision: revision,
  );
}

Future<void> _pump(WidgetTester tester, AgentViewData data) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(420, 700);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: GeistTheme.light,
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: WindowChromeScope(
          child: AgentPanel(
            data: data,
            actions: AgentFixture.actions(),
            initialTab: AgentTab.chat,
          ),
        ),
      ),
    ),
  );
  // A lazy list learns its full extent over a few frames.
  for (var i = 0; i < 6; i++) {
    await tester.pump();
  }
}

ScrollPosition _position(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byKey(const Key('agent-thread')),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

void main() {
  testWidgets('first message sits at the top, not the bottom', (tester) async {
    await _pump(tester, _view([_turn(1)], 1));
    final list = tester.getRect(find.byKey(const Key('agent-thread')));
    final q = tester.getRect(find.text('Q1'));
    expect(q.top - list.top, lessThan(60));
    expect(find.byKey(const Key('agent-jump-latest')), findsNothing);
  });

  testWidgets('follows new content at bottom; scrolling up stops following '
      'and shows the jump button, which returns and resumes following', (
    tester,
  ) async {
    final turns = [for (var i = 0; i < 6; i++) _turn(i, lines: 6)];
    await _pump(tester, _view(turns, 1));
    var pos = _position(tester);
    expect(pos.maxScrollExtent, greaterThan(0));
    expect(pos.pixels, pos.maxScrollExtent, reason: 'opens at the latest');

    await _pump(tester, _view([...turns, _turn(6, lines: 6)], 2));
    pos = _position(tester);
    expect(pos.pixels, pos.maxScrollExtent, reason: 'follows while at bottom');

    await tester.drag(
      find.byKey(const Key('agent-thread')),
      const Offset(0, 400),
    );
    await tester.pump();
    expect(find.byKey(const Key('agent-jump-latest')), findsOneWidget);
    final held = _position(tester).pixels;

    await _pump(tester, _view([...turns, _turn(6, lines: 6), _turn(7)], 3));
    pos = _position(tester);
    expect(pos.pixels, held, reason: 'no auto-follow after scrolling up');
    expect(pos.pixels, lessThan(pos.maxScrollExtent));

    await tester.tap(find.byKey(const Key('agent-jump-latest')));
    await tester.pumpAndSettle();
    pos = _position(tester);
    expect(pos.pixels, pos.maxScrollExtent);
    expect(find.byKey(const Key('agent-jump-latest')), findsNothing);

    await _pump(
      tester,
      _view([...turns, _turn(6, lines: 6), _turn(7), _turn(8, lines: 8)], 4),
    );
    pos = _position(tester);
    expect(pos.pixels, pos.maxScrollExtent, reason: 'following resumed');
  });

  testWidgets('thinking block collapses to one line and expands', (
    tester,
  ) async {
    const thinking = AgentThinkingBlock('先读当前草稿，再对照规则。');
    await _pump(
      tester,
      _view([
        AgentTurn(
          id: 't',
          user: AgentUserMessage(text: 'Q', at: DateTime(2026, 10, 19)),
          reply: const AgentReply(blocks: [thinking, AgentTextBlock('answer')]),
        ),
      ], 1),
    );
    expect(find.textContaining('已思考', findRichText: true), findsOneWidget);
    expect(find.textContaining('13 字', findRichText: true), findsOneWidget);
    expect(find.byKey(const Key('agent-thinking-text')), findsNothing);
    await tester.tap(find.byKey(const Key('agent-thinking')));
    await tester.pump();
    expect(find.byKey(const Key('agent-thinking-text')), findsOneWidget);
    expect(find.text(thinking.text), findsOneWidget);
  });

  test('step durations under a second show milliseconds', () {
    expect(agentDuration(const Duration(milliseconds: 8)), '8ms');
    expect(agentDuration(const Duration(milliseconds: 508)), '508ms');
    expect(agentDuration(const Duration(milliseconds: 6172)), '6.2s');
    expect(agentDuration(const Duration(seconds: 64)), '1m 04s');
  });

  for (final state in AgentDiffState.values) {
    testWidgets('diff header status sits at the right edge ($state)', (
      tester,
    ) async {
      await _pump(
        tester,
        _view([
          AgentTurn(
            id: 't',
            user: AgentUserMessage(text: 'Q', at: DateTime(2026, 10, 19)),
            reply: AgentReply(
              blocks: [
                AgentDiffBlock(
                  AgentPromptDiff(
                    id: 'd',
                    field: AgentPromptField.prompt,
                    segments: const [AgentDiffSegment('a, b')],
                    state: state,
                  ),
                ),
              ],
            ),
          ),
        ], 1),
      );
      final diff = tester.getRect(find.byKey(const Key('agent-diff-d')));
      final trailing = state == AgentDiffState.applied
          ? find.byKey(const Key('agent-diff-undo-d'))
          : find.text(state == AgentDiffState.undone ? '已撤销' : '已写入');
      expect(tester.getRect(trailing).right, closeTo(diff.right, 1));
    });
  }

  testWidgets('position card draws a mini board with moves and legend', (
    tester,
  ) async {
    await _pump(
      tester,
      _view([
        AgentTurn(
          id: 't',
          user: AgentUserMessage(text: 'Q', at: DateTime(2026, 10, 19)),
          reply: const AgentReply(
            blocks: [
              AgentPositionBlock(
                id: 'p',
                customBefore: false,
                customAfter: true,
                aspect: 832 / 1216,
                marks: [
                  AgentPositionMark(
                    index: 0,
                    name: 'Alice',
                    before: Offset(.3, .5),
                    after: Offset(.7, .5),
                  ),
                  AgentPositionMark(
                    index: 1,
                    name: 'Bob',
                    after: Offset(.1, .9),
                  ),
                  AgentPositionMark(
                    index: 2,
                    name: 'Cat',
                    before: Offset(.5, .1),
                    after: Offset(.5, .1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ], 1),
    );
    final card = find.byKey(const Key('agent-position-p'));
    expect(card, findsOneWidget);
    final board = tester.getRect(
      find.byKey(const Key('agent-position-board-p')),
    );
    expect(board.height, closeTo(150, .5));
    expect(board.width, closeTo(150 * 832 / 1216, .5));
    // 圆点按坐标落在板子上。
    final alice = tester.getCenter(
      find.byKey(const Key('agent-position-dot-0')),
    );
    expect(alice.dx, closeTo(board.left + board.width * .7, 1));
    expect(alice.dy, closeTo(board.top + board.height * .5, 1));
    for (final t in [
      '角色位置',
      'AI 选择 → 自定义',
      '已调整',
      'Alice',
      'B3',
      'D3',
      'Bob',
      '未定位',
      'A5',
      'Cat',
      'C1',
    ]) {
      expect(
        find.descendant(of: card, matching: find.text(t)),
        findsOneWidget,
        reason: t,
      );
    }
    expect(
      tester.getRect(find.text('已调整')).right,
      closeTo(tester.getRect(card).right, 1),
    );
  });

  testWidgets('position card under AI choice dims the board and explains', (
    tester,
  ) async {
    await _pump(
      tester,
      _view([
        AgentTurn(
          id: 't',
          user: AgentUserMessage(text: 'Q', at: DateTime(2026, 10, 19)),
          reply: const AgentReply(
            blocks: [
              AgentPositionBlock(
                id: 'p',
                customBefore: true,
                customAfter: false,
                marks: [
                  AgentPositionMark(
                    index: 0,
                    name: 'Alice',
                    before: Offset(.5, .5),
                    after: Offset(.5, .5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ], 1),
    );
    expect(find.text('自定义 → AI 选择'), findsOneWidget);
    expect(find.text('当前为 AI 选择，坐标暂不生效。'), findsOneWidget);
  });
}
