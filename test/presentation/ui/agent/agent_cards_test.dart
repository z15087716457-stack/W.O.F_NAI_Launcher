import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_activity.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_parts.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_thread.dart';

import 'agent_test_harness.dart';

final _at = DateTime(2026, 10, 20, 15);

AgentViewData _view(
  List<AgentBlock> blocks, {
  AgentTurnSummary? summary,
  bool live = false,
  bool regenerate = true,
}) {
  final b = AgentFixture.view(AgentScene.compose);
  return AgentViewData(
    now: b.now,
    workspace: b.workspace,
    chat: b.chat,
    workspaces: b.workspaces,
    chats: b.chats,
    composer: b.composer,
    thread: [
      AgentTurn(
        id: 't1',
        user: AgentUserMessage(
          text: 'Q',
          at: _at,
          entryId: 'e1',
          images: [
            AgentFixture.img('t1/user/1', source: AgentImageSource.attachment),
            AgentFixture.img('t1/user/2', source: AgentImageSource.attachment),
          ],
        ),
        reply: AgentReply(
          blocks: blocks,
          live: live,
          canRegenerate: regenerate && !live,
          summary: summary,
        ),
      ),
    ],
    shelf: b.shelf,
    memory: b.memory,
    usage: b.usage,
    models: b.models,
    thinking: b.thinking,
    permission: b.permission,
    mentions: b.mentions,
    skills: b.skills,
    status: live ? AgentRunStatus.working : AgentRunStatus.idle,
  );
}

AgentStep _read(String id, {AgentStepStatus status = AgentStepStatus.done}) =>
    AgentStep(
      id: id,
      tool: 'image_read',
      status: status,
      subject: id,
      duration: const Duration(milliseconds: 50),
      at: _at,
      arguments: '{"image_id": "$id"}',
      images: [AgentFixture.img('img-$id', source: AgentImageSource.tool)],
    );

String _plain(List<AgentDiffSegment?> w) => w.map((s) => s?.text ?? '…').join();

void main() {
  setUp(AgentAppear.reset);

  group('提示词改动窗口', () {
    List<AgentDiffSegment> prompt(int n, Map<int, AgentDiffKind> marks) => [
      for (var i = 0; i < n; i++)
        AgentDiffSegment(
          't$i${i == n - 1 ? '' : ', '}',
          marks[i] ?? AgentDiffKind.same,
        ),
    ];

    test('改动在后半段：前面省略、前后各留 3 个', () {
      final w = agentDiffWindow(prompt(30, {20: AgentDiffKind.removed}));
      expect(w.first, isNull);
      final text = _plain(w);
      expect(text, contains('t17'));
      expect(text, contains('t23'));
      expect(text, isNot(contains('t16,')));
      expect(text, isNot(contains('t24')));
      expect(
        w.whereType<AgentDiffSegment>().any(
          (s) => s.kind == AgentDiffKind.removed,
        ),
        isTrue,
      );
    });

    test('开头和结尾都改：中间长段省略，两处都看得到', () {
      final w = agentDiffWindow(
        prompt(40, {1: AgentDiffKind.added, 37: AgentDiffKind.added}),
      );
      expect(w.where((s) => s == null), hasLength(1));
      final text = _plain(w);
      expect(text, startsWith('t0'));
      expect(text, endsWith('t39'));
    });

    test('只隔一个没改的 tag 不省略；全都没改原样返回', () {
      final w = agentDiffWindow(
        prompt(9, {1: AgentDiffKind.added, 8: AgentDiffKind.added}),
      );
      expect(w, isNot(contains(null)));
      final same = prompt(5, {});
      expect(agentDiffWindow(same), same);
    });
  });

  testWidgets('改动卡默认只显示改动附近，点「展开全部」看全文', (t) async {
    final segs = [
      for (var i = 0; i < 40; i++)
        AgentDiffSegment(
          'tag$i, ',
          i == 30 ? AgentDiffKind.removed : AgentDiffKind.same,
        ),
    ];
    await pumpAgent(
      t,
      data: _view([
        AgentDiffBlock(
          AgentPromptDiff(
            id: 'd',
            field: AgentPromptField.prompt,
            segments: segs,
          ),
        ),
      ]),
    );
    String text() => t
        .widget<RichText>(
          find.descendant(
            of: find.byKey(const Key('agent-diff-text-d')),
            matching: find.byType(RichText),
          ),
        )
        .text
        .toPlainText();
    expect(text(), contains('tag30'));
    expect(text(), isNot(contains('tag5,')));
    await t.tap(find.byKey(const Key('agent-diff-more-d')));
    await t.pump();
    expect(text(), contains('tag5,'));
    expect(text(), contains('tag30'));
  });

  testWidgets('连续看图合成一组，缩略图排一起，点开组内左右切换', (t) async {
    await pumpAgent(
      t,
      data: _view([
        AgentStepsBlock([_read('a'), _read('b'), _read('c'), _read('d')]),
        const AgentTextBlock('ok'),
      ]),
    );
    expect(find.byKey(const Key('agent-read-group-a')), findsOneWidget);
    expect(find.text('查看图片 · 4 张'), findsOneWidget);
    expect(find.text('200ms'), findsOneWidget);
    final strip = find.byKey(const Key('agent-step-images-a'));
    expect(
      find.descendant(of: strip, matching: find.byType(AgentThumb)),
      findsNWidgets(4),
    );
    // 一行排开（不是每张一整行）。
    final ys = {
      for (final e
          in find
              .descendant(of: strip, matching: find.byType(AgentThumb))
              .evaluate())
        t.getTopLeft(find.byWidget(e.widget)).dy,
    };
    expect(ys, hasLength(1));
    await t.tap(find.byKey(const Key('agent-image-img-b')));
    await t.pump();
    expect(find.byKey(const Key('agent-zoom')), findsOneWidget);
    expect(find.text('2 / 4'), findsOneWidget);
    await t.tap(find.byKey(const Key('agent-zoom-next')));
    await t.pump();
    expect(find.text('3 / 4'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await t.pump();
    expect(find.text('2 / 4'), findsOneWidget);
  });

  testWidgets('只看一张时和普通步骤一样；失败的单独显示不并入', (t) async {
    await pumpAgent(
      t,
      data: _view([
        AgentStepsBlock([
          _read('a'),
          _read('x', status: AgentStepStatus.failed),
          _read('b'),
        ]),
      ]),
    );
    expect(find.byKey(const Key('agent-step-a')), findsOneWidget);
    expect(find.byKey(const Key('agent-step-x')), findsOneWidget);
    expect(find.byKey(const Key('agent-step-b')), findsOneWidget);
    expect(find.textContaining('查看图片 ·'), findsNothing);
  });

  testWidgets('查询步骤下面一排标签：点一下复制，太多时折叠', (t) async {
    final copied = <String>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpAgent(
      t,
      data: _view([
        AgentStepsBlock([
          AgentStep(
            id: 'q',
            tool: 'tag_query',
            status: AgentStepStatus.done,
            at: _at,
            tags: [
              const AgentTagHit(
                tag: 'yd_(orange_maru)',
                category: AgentTagCategory.artist,
                count: 2311,
              ),
              for (var i = 0; i < 20; i++)
                AgentTagHit(tag: 'tag$i', count: 100 - i),
            ],
          ),
        ]),
      ]),
    );
    expect(find.byKey(const Key('agent-step-tags-q')), findsOneWidget);
    expect(find.byKey(const Key('agent-tags-more-q')), findsOneWidget);
    expect(find.byKey(const Key('agent-tag-q-tag19')), findsNothing);
    await t.tap(find.byKey(const Key('agent-tag-q-yd_(orange_maru)')));
    await t.pump();
    expect(copied, ['yd_(orange_maru)']);
    await t.tap(find.byKey(const Key('agent-tags-more-q')));
    await t.pump();
    expect(find.byKey(const Key('agent-tag-q-tag19')), findsOneWidget);
  });

  testWidgets('设置改动卡：旧→新、撤销、去设置；设置页没有的项不给跳转', (t) async {
    final rec = await pumpAgent(
      t,
      data: _view([
        const AgentSettingsBlock(
          id: 's',
          changes: [
            AgentSettingChange(
              key: 'font_family',
              label: '字体',
              before: '系统默认',
              after: 'Noto Sans SC',
              anchor: (section: 'appearance', anchor: 'fontFamily'),
            ),
            AgentSettingChange(
              key: 'tag_expansion_result_limit',
              label: 'tag_expansion_result_limit',
              before: '20',
              after: '40',
            ),
          ],
        ),
      ]),
    );
    expect(find.text('应用设置'), findsOneWidget);
    expect(find.text('2 项'), findsOneWidget);
    await t.tap(find.byKey(const Key('agent-setting-go-s-font_family')));
    await t.pump();
    expect(rec.last('openSettingAt'), 'appearance#fontFamily');
    expect(
      find.byKey(const Key('agent-setting-go-s-tag_expansion_result_limit')),
      findsNothing,
    );
    await t.tap(find.byKey(const Key('agent-diff-undo-s')));
    await t.pump();
    expect(rec.last('undoDiff'), 's');
  });

  testWidgets('画廊卡：一句话 + 缩略图，最多 8 张其余「+N」；不能撤销的不给按钮', (t) async {
    await pumpAgent(
      t,
      data: _view([
        AgentGalleryBlock(
          id: 'g',
          action: AgentGalleryAction.favorite,
          count: 11,
          undoable: true,
          images: [for (var i = 0; i < 9; i++) AgentFixture.img('g$i')],
        ),
        AgentGalleryBlock(
          id: 'c',
          action: AgentGalleryAction.copy,
          count: 1,
          target: '风景',
          images: [AgentFixture.img('c0')],
        ),
      ]),
    );
    expect(find.text('已收藏 11 张'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
    expect(find.byKey(const Key('agent-image-g8')), findsNothing);
    expect(find.byKey(const Key('agent-diff-undo-g')), findsOneWidget);
    expect(find.text('已复制 1 张到「风景」'), findsOneWidget);
    expect(find.byKey(const Key('agent-diff-undo-c')), findsNothing);
  });

  testWidgets('压缩分隔线：点开看摘要和原 token 数', (t) async {
    await pumpAgent(
      t,
      data: _view([
        const AgentTextBlock('前面'),
        AgentCompactionBlock(
          summary: '用户在整理画廊',
          tokensBefore: 182345,
          at: _at,
          auto: true,
        ),
        const AgentTextBlock('后面'),
      ]),
    );
    expect(find.text('上下文快满了，之前的对话已自动压缩'), findsOneWidget);
    expect(find.byKey(const Key('agent-compaction-summary')), findsNothing);
    await t.tap(find.text('上下文快满了，之前的对话已自动压缩'));
    await t.pump();
    expect(find.byKey(const Key('agent-compaction-summary')), findsOneWidget);
    expect(find.text('用户在整理画廊'), findsOneWidget);
    expect(find.text('原 182k token'), findsOneWidget);
  });

  testWidgets('一轮小结：一行淡字，没有的项不写；进行中不显示', (t) async {
    await pumpAgent(
      t,
      data: _view(
        [const AgentTextBlock('好了')],
        summary: const AgentTurnSummary(
          took: Duration(seconds: 72),
          changes: 3,
          toolCalls: 5,
        ),
      ),
    );
    final line = find.byKey(const Key('agent-turn-summary-t1'));
    expect(line, findsOneWidget);
    expect(
      find.descendant(of: line, matching: find.text('用时 1m 12s · 改动 3 处')),
      findsOneWidget,
    );
    final tip = t.widget<Tooltip>(
      find.descendant(of: line, matching: find.byType(Tooltip)),
    );
    expect(tip.message, contains('工具 5 次'));
    await pumpAgent(
      t,
      data: _view(
        [const AgentTextBlock('好了')],
        live: true,
        summary: const AgentTurnSummary(changes: 3),
      ),
    );
    expect(find.byKey(const Key('agent-turn-summary-t1')), findsNothing);
  });

  testWidgets('原地编辑历史消息：改字、去图，发送后从这句重来；取消什么都不动', (t) async {
    final rec = await pumpAgent(t, data: _view([const AgentTextBlock('答')]));
    final line = find.byKey(const Key('agent-user-e1'));
    // 悬停出现铅笔。
    final g = await t.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: t.getCenter(line));
    await t.pump();
    await t.tap(find.byKey(const Key('agent-edit-e1')));
    await t.pump();
    final box = find.byKey(const Key('agent-edit-text-e1'));
    expect(box, findsOneWidget);
    expect(find.text('发送后，这条之后的对话会被替换'), findsOneWidget);
    // 取消：不调任何操作。
    await t.tap(find.byKey(const Key('agent-edit-cancel-e1')));
    await t.pump();
    expect(box, findsNothing);
    expect(rec.names, isNot(contains('resendFrom')));
    // 双击进入编辑，Esc 也能取消。
    await t.tap(find.text('Q'));
    await t.pump(const Duration(milliseconds: 50));
    await t.tap(find.text('Q'));
    await t.pump();
    expect(box, findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pump();
    expect(box, findsNothing);
    // 改字 + 去掉一张图，Ctrl+Enter 发送。
    await t.tap(find.byKey(const Key('agent-edit-e1')));
    await t.pump();
    await t.enterText(box, '  改过的问题  ');
    await t.tap(find.byKey(const Key('agent-edit-remove-t1/user/1')));
    await t.pump();
    await t.tap(find.byKey(const Key('agent-edit-send-e1')));
    await t.pump();
    final sent = rec.last('resendFrom')! as (String, String, List<String>);
    expect(sent.$1, 'e1');
    expect(sent.$2, '改过的问题');
    expect(sent.$3, ['t1/user/2']);
    expect(box, findsNothing);
    await g.removePointer();
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('运行中不给编辑', (t) async {
    await pumpAgent(t, data: _view([const AgentTextBlock('答')], live: true));
    final g = await t.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(
      location: t.getCenter(find.byKey(const Key('agent-user-e1'))),
    );
    await t.pump();
    expect(find.byKey(const Key('agent-edit-e1')), findsNothing);
    await g.removePointer();
  });

  testWidgets('省略文字：截断时才有悬停全文', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                width: 80,
                child: AgentOverflowText(
                  'a very long label that will not fit',
                  key: Key('long'),
                ),
              ),
              SizedBox(
                width: 400,
                child: AgentOverflowText('short', key: Key('short')),
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('long')),
        matching: find.byType(Tooltip),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('short')),
        matching: find.byType(Tooltip),
      ),
      findsNothing,
    );
  });

  testWidgets('新内容进场：最后一轮新出现的一节先透明再显示；打开时已有的不动', (t) async {
    // 打开聊天：已有内容直接显示。
    final first = [const AgentTextBlock('一')];
    await pumpAgentAnimated(t, _view(first, live: true));
    Opacity? fade(String text) => t
        .widgetList<Opacity>(
          find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
        )
        .firstOrNull;
    expect(fade('一')?.opacity ?? 1, 1);
    // 之后新出现一节：开始是半透明，动画结束变实。
    await pumpAgentAnimated(
      t,
      _view([...first, const AgentTextBlock('二')], live: true),
      settle: false,
    );
    await t.pump(const Duration(milliseconds: 60));
    expect(fade('二')!.opacity, lessThan(1));
    await t.pump(const Duration(milliseconds: 400));
    expect(fade('二')?.opacity ?? 1, 1);
    await t.pumpWidget(const SizedBox());
  });
}
