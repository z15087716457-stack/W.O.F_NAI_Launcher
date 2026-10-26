import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_panel.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_answered_questions.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_history_mapper.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'agent_test_harness.dart';

final _at = DateTime(2026, 10, 24, 11, 4);
final _qa = AgentAnsweredQuestionsBlock(
  at: _at,
  questions: const [
    AgentAnsweredQuestion(
      question: '现在就办的话，走哪条？',
      answer: '拆块 + 建服装柜块（推荐）',
      kind: AgentAnswerKind.option,
    ),
    AgentAnsweredQuestion(
      question: '临时块要不要带上原块的随机项？',
      answer: '不用，临时块只保留当前这一项，随机的以后再说。',
      kind: AgentAnswerKind.free,
    ),
  ],
);
AgentViewData _data(List<AgentTurn> turns, {List<AgentHistoryEntry>? history}) {
  final d = AgentFixture.view(AgentScene.chat);
  return AgentViewData(
    now: d.now,
    workspace: d.workspace,
    chat: d.chat,
    workspaces: d.workspaces,
    chats: d.chats,
    composer: const AgentComposerData(text: '', pending: []),
    thread: turns,
    shelf: d.shelf,
    usage: d.usage,
    models: d.models,
    thinking: d.thinking,
    permission: d.permission,
    mentions: d.mentions,
    skills: d.skills,
    memory: d.memory,
    history: history ?? agentHistoryEntries(turns),
  );
}

AgentTurn _turn(int i, {List<AgentBlock>? blocks}) => AgentTurn(
  id: 't$i',
  user: AgentUserMessage(
    text: 'Message $i',
    at: _at.add(Duration(minutes: i)),
  ),
  reply: AgentReply(
    blocks:
        blocks ??
        [AgentTextBlock(List.filled(i % 3 + 1, 'Answer $i').join('\n\n'))],
  ),
);
Future<void> _frames(WidgetTester t, [int n = 80]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 20));
  }
}

Future<void> _capture(WidgetTester t, String name) async {
  if (Platform.environment['CAPTURE_AGENT'] != '1') return;
  final boundary = t.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('agent-capture')),
  );
  await t.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory(
      'E:/A.I/NovelAI/.devin/runs/fix-batch-1024/agent-capture',
    );
    await dir.create(recursive: true);
    await File(
      '${dir.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets(
    'history opens without a modal barrier, searches, jumps through lazy turns, and Esc closes',
    (t) async {
      final turns = List.generate(45, (i) => _turn(i));
      await pumpAgent(t, data: _data(turns), height: 700);
      await _frames(t, 8);
      final barriers = find.byType(ModalBarrier).evaluate().length;
      await t.tap(find.byKey(const Key('agent-history-toggle')));
      await t.pump();
      expect(find.byKey(const Key('agent-history')), findsOneWidget);
      expect(find.byType(ModalBarrier).evaluate().length, barriers);
      await t.enterText(
        find.byKey(const Key('agent-history-search')),
        'Message 1',
      );
      await t.pump();
      await t.tap(find.byKey(const Key('agent-history-entry-t1/history/user')));
      await _frames(t);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pump();
      expect(find.byKey(const Key('agent-history')), findsNothing);
      final viewport = t.getRect(find.byKey(const Key('agent-thread')));
      expect(viewport.overlaps(t.getRect(find.text('Message 1'))), true);
      // Keyboard selection and Enter jump forward to an unmounted target.
      await t.tap(find.byKey(const Key('agent-history-toggle')));
      await t.pump();
      await t.enterText(
        find.byKey(const Key('agent-history-search')),
        'Message 4',
      );
      await t.pump();
      // 初始无选中：第一次 ↓ 选中第一条（Message 4），第二次到 Message 40。
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await _frames(t);
      await t.tap(find.byKey(const Key('agent-history-close')));
      await t.pump();
      expect(viewport.overlaps(t.getRect(find.text('Message 40'))), true);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'card jump targets its block and compacted messages target summary without branching',
    (t) async {
      final compact = AgentCompactionBlock(
        summary: 'Earlier conversation summary',
        at: _at,
        tokensBefore: 42000,
      );
      final turns = [
        _turn(
          0,
          blocks: [
            compact,
            AgentTextBlock(
              List.filled(35, 'Long intermediate answer').join('\n\n'),
            ),
            _qa,
          ],
        ),
      ];
      final history = [
        const AgentHistoryEntry(
          id: 'old',
          turnId: 't0',
          kind: AgentHistoryKind.user,
          title: 'Old question',
          blockIndex: 0,
          beforeCompaction: true,
        ),
        ...agentHistoryEntries(turns),
      ];
      await pumpAgent(t, data: _data(turns, history: history), height: 700);
      await _frames(t, 8);
      await t.tap(find.byKey(const Key('agent-history-toggle')));
      await t.pump();
      await t.enterText(
        find.byKey(const Key('agent-history-search')),
        'Old question',
      );
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await _frames(t);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pump();
      expect(
        t
            .getRect(find.byKey(const Key('agent-thread')))
            .overlaps(t.getRect(find.byKey(const Key('agent-compaction')))),
        true,
      );
      expect(find.text('这段在压缩之前，点看摘要'), findsOneWidget);
      await t.tap(find.byKey(const Key('agent-compaction')));
      await t.pump();
      expect(find.text('Earlier conversation summary'), findsOneWidget);
      await t.tap(find.byKey(const Key('agent-history-toggle')));
      await t.pump();
      await t.enterText(find.byKey(const Key('agent-history-search')), '现在就办');
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await _frames(t);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pump();
      expect(
        t
            .getRect(find.byKey(const Key('agent-thread')))
            .overlaps(t.getRect(find.byType(AgentAnsweredQuestionsView))),
        true,
      );
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('left dock opens outwards and closing panel removes overlay', (
    t,
  ) async {
    await pumpAgent(t, data: _data([_turn(0)]), width: 920);
    final panel = t.widget<AgentPanel>(find.byType(AgentPanel));
    final app = t.widget<MaterialApp>(find.byType(MaterialApp));
    var pageTaps = 0;
    await t.pumpWidget(
      MaterialApp(
        theme: app.theme,
        locale: app.locale,
        supportedLocales: app.supportedLocales,
        localizationsDelegates: app.localizationsDelegates,
        home: Scaffold(
          body: Row(
            children: [
              SizedBox(width: 420, child: panel),
              Expanded(
                child: GestureDetector(
                  onTap: () => pageTaps++,
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await t.pump();
    await t.tap(find.byKey(const Key('agent-history-toggle')));
    await t.pump();
    expect(t.getRect(find.byKey(const Key('agent-history'))).left, 420);
    await t.tapAt(const Offset(850, 400));
    await t.pump();
    expect(pageTaps, 1);
    expect(find.byKey(const Key('agent-history')), findsOneWidget);
    await t.tap(find.byKey(const Key('agent-close')));
    await t.pump();
    expect(find.byKey(const Key('agent-history')), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets('answered card stays directly visible outside tools', (t) async {
    await pumpAgent(
      t,
      data: _data([
        _turn(
          0,
          blocks: [
            const AgentStepsBlock([
              AgentStep(
                id: 's',
                tool: 'studio_context',
                status: AgentStepStatus.done,
              ),
            ]),
            _qa,
          ],
        ),
      ]),
    );
    expect(find.byType(AgentAnsweredQuestionsView), findsOneWidget);
    expect(find.text('向你提问 · 已回答'), findsOneWidget);
    expect(find.text(_qa.questions.last.answer), findsOneWidget);
    expect(find.text(_qa.questions.first.answer), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  for (final dark in [false, true]) {
    testWidgets('capture answered and history ${dark ? 'dark' : 'light'}', (
      t,
    ) async {
      final compact = AgentCompactionBlock(
        summary: '之前已确认只修改当前实例，块库保持不变。',
        tokensBefore: 131000,
        at: _at,
        auto: true,
      );
      final turns = [
        _turn(
          0,
          blocks: [
            compact,
            const AgentTextBlock('会先把那个块标成临时块：它和块库断开，只改这一处。'),
            _qa,
          ],
        ),
        _turn(
          1,
          blocks: [
            AgentPromptSetBlock(
              setId: 'fedcba543210',
              revision: 1,
              data: AgentFixture.promptSet(ordered: false),
            ),
          ],
        ),
        _turn(2),
      ];
      await pumpAgent(
        t,
        data: _data(turns),
        width: 920,
        height: 850,
        dark: dark,
      );
      // Dock the actual panel on the right to exercise the external flyout.
      final panel = t.widget<AgentPanel>(find.byType(AgentPanel));
      final app = t.widget<MaterialApp>(find.byType(MaterialApp));
      await t.pumpWidget(
        RepaintBoundary(
          key: const Key('agent-capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: app.theme,
            locale: app.locale,
            supportedLocales: app.supportedLocales,
            localizationsDelegates: app.localizationsDelegates,
            home: Scaffold(
              body: Row(
                children: [
                  const Expanded(child: Center(child: Text('Studio'))),
                  SizedBox(width: 520, child: panel),
                ],
              ),
            ),
          ),
        ),
      );
      await _frames(t, 12);
      final list = t.widget<ListView>(find.byKey(const Key('agent-thread')));
      list.controller!.jumpTo(0);
      await _frames(t, 12);
      await _capture(t, 'answered-${dark ? 'dark' : 'light'}');
      await t.tap(find.byKey(const Key('agent-history-toggle')));
      await t.pump();
      await _frames(t, 12);
      expect(
        t.getRect(find.byKey(const Key('agent-history'))).right,
        t.getRect(find.byKey(const Key('agent-panel'))).left,
      );
      await _capture(t, 'history-${dark ? 'dark' : 'light'}');
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pump();
      expect(t.takeException(), isNull);
    });
  }
}
