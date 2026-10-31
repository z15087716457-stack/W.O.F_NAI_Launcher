import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

AgentViewData _view(List<AgentTurn> thread, int revision, {String text = ''}) {
  final d = AgentFixture.view(AgentScene.chat);
  return AgentViewData(
    now: d.now,
    workspace: d.workspace,
    chat: d.chat,
    workspaces: d.workspaces,
    chats: d.chats,
    composer: AgentComposerData(
      text: text,
      canSend: text.isNotEmpty,
      pending: const [],
    ),
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

  testWidgets(
    'typing keeps the reading position; sending returns to latest and resumes following',
    (tester) async {
      final turns = [for (var i = 0; i < 6; i++) _turn(i, lines: 6)];
      await _pump(tester, _view(turns, 1, text: 'message'));
      final thread = find.byKey(const Key('agent-thread'));
      final input = find.byKey(const Key('agent-input'));
      await tester.drag(thread, const Offset(0, 400));
      await tester.pumpAndSettle();
      final held = _position(tester).pixels;
      expect(held, lessThan(_position(tester).maxScrollExtent));

      await tester.tap(input);
      await tester.pump();
      expect(
        _position(tester).pixels,
        held,
        reason: 'focus alone keeps the reading position',
      );
      const composing = TextEditingValue(
        text: 'ni',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      );
      tester.testTextInput.updateEditingValue(composing);
      await tester.pumpAndSettle();
      expect(
        _position(tester).pixels,
        held,
        reason: 'typing keeps the reading position',
      );
      expect(tester.widget<TextField>(input).controller!.value, composing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        _position(tester).pixels,
        held,
        reason: 'IME candidate confirmation is not a send',
      );
      tester.testTextInput.updateEditingValue(
        composing.copyWith(composing: TextRange.empty),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(_position(tester).pixels, held, reason: 'a newline is not a send');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_position(tester).pixels, _position(tester).maxScrollExtent);
      expect(find.byKey(const Key('agent-jump-latest')), findsNothing);

      await _pump(tester, _view([...turns, _turn(6, lines: 8)], 2, text: 'ni'));
      expect(
        _position(tester).pixels,
        _position(tester).maxScrollExtent,
        reason: 'new content follows after sending',
      );

      await tester.drag(thread, const Offset(0, 400));
      await tester.pumpAndSettle();
      final reading = _position(tester).pixels;
      tester.testTextInput.updateEditingValue(
        composing.copyWith(selection: const TextSelection.collapsed(offset: 1)),
      );
      await tester.pumpAndSettle();
      expect(
        _position(tester).pixels,
        reading,
        reason: 'selection alone does not jump',
      );

      await tester.enterText(input, 'pasted text\nsecond line');
      await tester.pumpAndSettle();
      expect(
        _position(tester).pixels,
        reading,
        reason: 'pasting does not jump either',
      );
      await tester.tap(find.byKey(const Key('agent-send')));
      await tester.pumpAndSettle();
      expect(_position(tester).pixels, _position(tester).maxScrollExtent);

      await tester.drag(thread, const Offset(0, 400));
      await tester.pumpAndSettle();
      final beforeEmptySend = _position(tester).pixels;
      await _pump(tester, _view([...turns, _turn(6, lines: 8)], 2));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        _position(tester).pixels,
        beforeEmptySend,
        reason: 'an empty composer cannot send or jump',
      );
      expect(tester.takeException(), isNull);
    },
  );

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

  testWidgets('params card and change summary: rows, undo, undo all', (
    tester,
  ) async {
    final calls = <(String, Object?)>[];
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
              data: _view([
                AgentTurn(
                  id: 't',
                  user: AgentUserMessage(text: 'Q', at: DateTime(2026, 10, 20)),
                  reply: const AgentReply(
                    blocks: [
                      AgentChangeSummaryBlock(
                        id: 'all',
                        ids: ['d', 'p'],
                        added: 3,
                        removed: 1,
                      ),
                      AgentDiffBlock(
                        AgentPromptDiff(
                          id: 'd',
                          field: AgentPromptField.prompt,
                          segments: [
                            AgentDiffSegment('a', AgentDiffKind.added),
                          ],
                        ),
                      ),
                      AgentParamBlock(
                        id: 'p',
                        changes: [
                          AgentParamChange(
                            AgentParam.steps,
                            AgentParamValue.text('28'),
                            AgentParamValue.text('32'),
                          ),
                          AgentParamChange(
                            AgentParam.seed,
                            AgentParamValue.word(AgentParamWord.random),
                            AgentParamValue.text('1814808702'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ], 1),
              actions: AgentFixture.actions(
                record: (name, [arg]) => calls.add((name, arg)),
              ),
              initialTab: AgentTab.chat,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('本次改动 · 2 处'), findsOneWidget);
    expect(find.text('生图参数'), findsOneWidget);
    expect(find.text('2 项'), findsOneWidget);
    final steps = find.byKey(const Key('agent-param-p-steps'));
    expect(
      find.descendant(of: steps, matching: find.text('步数')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('agent-param-p-seed')),
        matching: find.textContaining('随机'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('agent-diff-undo-p')));
    await tester.pump();
    expect(calls.last, ('undoDiff', 'p'));
    await tester.tap(find.byKey(const Key('agent-diff-undo-all')));
    await tester.pump();
    expect(calls.last.$1, 'undoDiffs');
    expect(calls.last.$2, ['d', 'p']);
    expect(find.text('全部撤销'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('unnamed character diffs are titled 角色 N', (tester) async {
    AgentDiffBlock block(String id, AgentPromptField field, int index) =>
        AgentDiffBlock(
          AgentPromptDiff(
            id: id,
            field: field,
            label: '',
            characterIndex: index,
            segments: const [AgentDiffSegment('girl', AgentDiffKind.added)],
          ),
        );
    await _pump(
      tester,
      _view([
        AgentTurn(
          id: 't',
          user: AgentUserMessage(text: 'Q', at: DateTime(2026, 10, 20)),
          reply: AgentReply(
            blocks: [
              block('c0', AgentPromptField.character, 0),
              block('n1', AgentPromptField.characterNegative, 1),
            ],
          ),
        ),
      ], 1),
    );
    expect(find.text('角色 1'), findsOneWidget);
    expect(find.text('角色 2 · 角色负面'), findsOneWidget);
  });

  testWidgets('position card: free-coordinate board, legend lists only moves', (
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
                    before: Offset(.1, .1),
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
                  AgentPositionMark(
                    index: 3,
                    name: 'Dan',
                    before: Offset(.4, .4),
                    after: Offset(.45, .42),
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
    // 圆点按坐标落在板子上（不再吸附到格子）。
    final alice = tester.getCenter(
      find.byKey(const Key('agent-position-dot-0')),
    );
    expect(alice.dx, closeTo(board.left + board.width * .7, 1));
    expect(alice.dy, closeTo(board.top + board.height * .5, 1));
    // 没动的角色也画在板上，但图例只列动过的，其余合成一行。
    expect(find.byKey(const Key('agent-position-dot-2')), findsOneWidget);
    expect(find.byKey(const Key('agent-position-legend-2')), findsNothing);
    for (final t in [
      '角色位置',
      'AI 选择 → 自定义',
      '已调整',
      'Alice',
      '左上',
      '右中',
      'Bob',
      '未定位',
      '左下',
      'Dan',
      '正中 · 微调', // 同一方位里小幅移动
      '其余 1 人位置未变',
    ]) {
      expect(
        find.descendant(of: card, matching: find.text(t)),
        findsOneWidget,
        reason: t,
      );
    }
    for (final t in ['B3', 'D3', 'A5', 'C1']) {
      expect(find.text(t), findsNothing, reason: '不再显示 5×5 格名');
    }
    expect(
      tester.getRect(find.text('已调整')).right,
      closeTo(tester.getRect(card).right, 1),
    );
  });

  testWidgets('position card with 22 characters keeps every dot readable', (
    tester,
  ) async {
    await _pump(
      tester,
      _view([
        AgentTurn(
          id: 't',
          user: AgentUserMessage(text: 'Q', at: DateTime(2026, 10, 20)),
          reply: AgentReply(
            blocks: [
              AgentPositionBlock(
                id: 'p',
                customBefore: true,
                customAfter: true,
                aspect: 1,
                marks: [
                  for (var i = 0; i < 22; i++)
                    () {
                      // 前两个挤在同一点，其余按行排开；只有 0 号移动过。
                      final at = i < 2
                          ? const Offset(.5, .5)
                          : Offset((i % 5 + .5) / 5, (i ~/ 5 + .5) / 5);
                      return AgentPositionMark(
                        index: i,
                        before: i == 0 ? const Offset(.9, .9) : at,
                        after: at,
                      );
                    }(),
                ],
              ),
            ],
          ),
        ),
      ], 1),
    );
    final board = tester.getRect(
      find.byKey(const Key('agent-position-board-p')),
    );
    expect(board.width, closeTo(180, .5), reason: '人多时板子放大');
    final dots = [
      for (var i = 0; i < 22; i++)
        tester.getRect(find.byKey(Key('agent-position-dot-$i'))),
    ];
    expect(dots.first.width, 13, reason: '人多时圆点缩小');
    for (final d in dots) {
      expect(board.inflate(.5).contains(d.topLeft), isTrue);
      expect(board.inflate(.5).contains(d.bottomRight), isTrue);
    }
    // 重合的两个圆点被推开，编号不叠在一起。
    expect(
      (dots[0].center - dots[1].center).distance,
      greaterThanOrEqualTo(13),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('agent-position-board-p')),
        matching: find.text('22'),
      ),
      findsOneWidget,
    );
    // 图例只有一行变化 + 一行汇总，不会拉成 22 行。
    expect(find.byKey(const Key('agent-position-legend-0')), findsOneWidget);
    expect(find.byKey(const Key('agent-position-legend-5')), findsNothing);
    expect(find.text('其余 21 人位置未变'), findsOneWidget);
  });

  testWidgets('position card under AI choice skips the board', (tester) async {
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
    expect(find.text('当前为 AI 选择，坐标不生效，由模型自行安排位置。'), findsOneWidget);
    expect(find.byKey(const Key('agent-position-board-p')), findsNothing);
  });
}
