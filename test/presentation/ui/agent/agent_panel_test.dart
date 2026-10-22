import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_glyphs.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_thread.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_fixture_image.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'agent_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  group('布局', () {
    for (final width in [320.0, 360.0, 420.0, 520.0]) {
      for (final scene in AgentScene.values) {
        testWidgets('${scene.name} @ $width 不溢出', (tester) async {
          await pumpAgent(
            tester,
            scene: scene,
            width: width,
            tab: switch (scene) {
              AgentScene.shelf => AgentTab.shelf,
              AgentScene.memory => AgentTab.memory,
              _ => AgentTab.chat,
            },
          );
          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('agent-panel')), findsOneWidget);
        });
      }
    }

    for (final locale in ['en', 'ja', 'ko', 'zh_TW']) {
      testWidgets('$locale 窄宽不溢出', (tester) async {
        for (final scene in [
          AgentScene.welcome,
          AgentScene.chat,
          AgentScene.ask,
          AgentScene.run,
        ]) {
          await pumpAgent(tester, scene: scene, width: 320, locale: locale);
          expect(tester.takeException(), isNull, reason: scene.name);
        }
      });
    }
  });

  group('交互', () {
    testWidgets('标签切换到产物和记忆', (tester) async {
      await pumpAgent(tester);
      await tester.tap(find.byKey(const Key('agent-tab-shelf')));
      await tester.pump();
      expect(find.byKey(const Key('agent-shelf')), findsOneWidget);
      await tester.tap(find.byKey(const Key('agent-tab-memory')));
      await tester.pump();
      expect(find.byKey(const Key('agent-memory')), findsOneWidget);
      await tester.tap(find.byKey(const Key('agent-tab-chat')));
      await tester.pump();
      expect(find.byKey(const Key('agent-thread')), findsOneWidget);
    });

    testWidgets('付费确认：确认 / 取消', (tester) async {
      final rec = await pumpAgent(tester);
      expect(find.byKey(const Key('agent-gate-g1')), findsOneWidget);
      expect(find.text('80'), findsOneWidget);
      await tester.tap(find.byKey(const Key('agent-gate-confirm')));
      expect(rec.last('gate'), ('g1', true));
      await tester.tap(find.byKey(const Key('agent-gate-cancel')));
      expect(rec.last('gate'), ('g1', false));
    });

    testWidgets('付费确认：未复核 / 已变化时不可确认', (tester) async {
      final base = AgentFixture.view(AgentScene.chat);
      final g = AgentFixture.gate();
      final changed = AgentGate(
        g.id,
        kind: g.kind,
        expiresAt: g.expiresAt,
        ready: true,
        changed: true,
        totalAnlas: 80,
      );
      final rec = await pumpAgent(tester, data: _withPending(base, [changed]));
      await tester.tap(find.byKey(const Key('agent-gate-confirm')));
      expect(rec.names, isNot(contains('gate')));
      expect(find.text('配置或报价已变化，请让 Agent 重新准备'), findsOneWidget);
    });

    testWidgets('提问：数字键选项、回答', (tester) async {
      final rec = await pumpAgent(tester, scene: AgentScene.ask);
      await tester.tap(find.byKey(const Key('agent-ask-option-keep-0')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-ask-submit')));
      final (id, answers) =
          rec.last('answer')! as (String, Map<String, String>);
      expect(id, 'q1');
      expect(answers, {'keep': '保留构图，只换画风'});
    });

    testWidgets('提问：自填答案', (tester) async {
      final rec = await pumpAgent(tester, scene: AgentScene.ask);
      await tester.enterText(
        find.byKey(const Key('agent-ask-custom-keep')),
        '只保留光影',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-ask-submit')));
      final (_, answers) = rec.last('answer')! as (String, Map<String, String>);
      expect(answers, {'keep': '只保留光影'});
    });

    testWidgets('审批：按选项原文回传', (tester) async {
      final rec = await pumpAgent(tester, scene: AgentScene.approval);
      await tester.tap(find.byKey(const Key('agent-approval-option-0')));
      expect(rec.last('approve'), ('a1', '允许一次'));
    });

    testWidgets('提示词改动可撤销', (tester) async {
      final rec = await pumpAgent(tester);
      await tester.tap(find.byKey(const Key('agent-diff-undo-d1')));
      await tester.pump();
      expect(rec.last('undoDiff'), 'd1');
    });

    testWidgets('步骤展开参数和结果', (tester) async {
      await pumpAgent(tester);
      expect(find.text('参数'), findsNothing);
      await tester.tap(find.byKey(const Key('agent-step-s1')));
      await tester.pump();
      expect(find.text('参数'), findsOneWidget);
      expect(find.text('结果'), findsOneWidget);
    });

    testWidgets('欢迎页任务块填入输入框', (tester) async {
      final rec = await pumpAgent(tester, scene: AgentScene.welcome);
      await tester.tap(find.byKey(const Key('agent-task-0')));
      await tester.pump();
      await tester.pump();
      expect(rec.names, contains('composer'));
      expect((rec.last('composer')! as String), contains('检查当前草稿'));
    });

    testWidgets('自定义快捷信息：直接发送、齿轮去设置、空列表隐藏', (tester) async {
      final base = AgentFixture.view(AgentScene.welcome);
      AgentViewData withQuick(List<AgentQuickItem> quick) => AgentViewData(
        now: base.now,
        workspace: base.workspace,
        chat: base.chat,
        workspaces: base.workspaces,
        chats: base.chats,
        composer: base.composer,
        thread: base.thread,
        shelf: base.shelf,
        memory: base.memory,
        usage: base.usage,
        models: base.models,
        thinking: base.thinking,
        permission: base.permission,
        mentions: base.mentions,
        skills: base.skills,
        draft: base.draft,
        status: base.status,
        revision: base.revision,
        quick: quick,
      );
      var rec = await pumpAgent(
        tester,
        data: withQuick(const [
          AgentQuickItem(
            id: 'q1',
            glyph: 'wand',
            title: '换成水彩',
            prompt: '把当前草稿改成水彩画风',
            send: true,
          ),
        ]),
      );
      expect(find.text('快捷信息'), findsOneWidget);
      expect(find.text('换成水彩'), findsOneWidget);
      expect(find.byKey(const Key('agent-task-1')), findsNothing);
      await tester.tap(find.byKey(const Key('agent-task-0')));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(rec.last('composer'), '把当前草稿改成水彩画风');
      expect(rec.names, contains('send'));
      await tester.tap(find.byKey(const Key('agent-quick-edit')));
      await tester.pump();
      expect(rec.last('editMemory'), AgentMemoryTarget.quick);
      rec = await pumpAgent(tester, data: withQuick(const []));
      expect(find.text('快捷信息'), findsNothing);
      expect(find.byKey(const Key('agent-task-0')), findsNothing);
    });

    testWidgets('输入 @ 弹出引用面板，回车插入', (tester) async {
      final rec = await pumpAgent(tester, scene: AgentScene.welcome);
      await tester.enterText(find.byKey(const Key('agent-input')), '参考 @角');
      await tester.pump();
      expect(find.byKey(const Key('agent-mention-panel')), findsOneWidget);
      expect(find.byKey(const Key('agent-mention-m-c1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('agent-mention-m-c1')));
      await tester.pump();
      expect(rec.last('composer'), '参考 @角色 1 ');
      expect(find.byKey(const Key('agent-mention-panel')), findsNothing);
    });

    testWidgets('@ 按钮再点一次撤掉刚插入的空 @，不叠加', (tester) async {
      final rec = await pumpAgent(tester, scene: AgentScene.welcome);
      final input = find.byKey(const Key('agent-input'));
      await tester.enterText(input, '参考');
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-mention')));
      await tester.pump();
      expect(rec.last('composer'), '参考 @');
      expect(find.byKey(const Key('agent-mention-panel')), findsOneWidget);
      await tester.tap(find.byKey(const Key('agent-mention')));
      await tester.pump();
      expect(rec.last('composer'), '参考');
      expect(find.byKey(const Key('agent-mention-panel')), findsNothing);
      // 已经输入了查询词的 @ 不动，按钮照常再插一个。
      await tester.enterText(input, '@角');
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-mention')));
      await tester.pump();
      expect(rec.last('composer'), '@角 @');
    });

    testWidgets('积木分类有搜索框：筛选后回车插入', (tester) async {
      final rec = await pumpAgent(tester, scene: AgentScene.welcome);
      await tester.enterText(find.byKey(const Key('agent-input')), '用 @');
      await tester.pump();
      expect(find.byKey(const Key('agent-block-search')), findsNothing);
      await tester.tap(
        find
            .descendant(
              of: find.byKey(const Key('agent-mention-panel')),
              matching: find.text('积木'),
            )
            .first,
      );
      await tester.pump();
      expect(find.byKey(const Key('agent-block-search')), findsOneWidget);
      expect(find.byKey(const Key('agent-mention-b400')), findsOneWidget);
      expect(find.byKey(const Key('agent-mention-b-water')), findsOneWidget);
      await tester.tap(find.byKey(const Key('agent-block-search')));
      await tester.enterText(find.byKey(const Key('agent-block-search')), '水彩');
      await tester.pump();
      expect(find.byKey(const Key('agent-mention-panel')), findsOneWidget);
      expect(find.byKey(const Key('agent-mention-b400')), findsNothing);
      expect(find.byKey(const Key('agent-mention-b-water')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(rec.last('composer'), '用 @水彩晕染 ');
      expect(find.byKey(const Key('agent-mention-panel')), findsNothing);
    });

    testWidgets('附件悬停信息卡：不贴整段元数据，可移入、卡内滚动', (tester) async {
      final long = List.filled(80, 'masterpiece').join(', ');
      await pumpAgent(
        tester,
        data: _withAttachments(AgentFixture.view(AgentScene.welcome), [
          AgentAttachment(
            id: 'a1',
            name: 'nai-001.png',
            image: UiFixtureImage.gradient('a1'),
            width: 832,
            height: 1216,
            metadata: AgentImageInfo(
              model: 'V4.5 Full',
              steps: 28,
              scale: 5,
              sampler: 'k_euler_ancestral',
              seed: 123456,
              prompt: long,
              negative: 'lowres',
              characterPrompts: const [
                AgentImageCharacter(prompt: 'girl, red hair'),
                AgentImageCharacter(prompt: 'boy', negative: 'hat'),
              ],
            ),
          ),
        ]),
      );
      expect(find.byKey(const Key('agent-attachment-info-a1')), findsNothing);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(
        tester.getCenter(find.byKey(const Key('agent-attachment-a1'))),
      );
      await tester.pump();
      await tester.pump();
      final card = find.byKey(const Key('agent-attachment-info-a1'));
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('V4.5 Full · 832×1216')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.text('28 步 · CFG 5 · k_euler_ancestral'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('种子 123456')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('2 个角色')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('角色 2 · 角色负面')),
        findsOneWidget,
      );
      // 卡宽 300 减内边距；高度封顶 360，长提示词在卡内滚动。
      expect(tester.getSize(card).width, lessThanOrEqualTo(300));
      expect(tester.getSize(card).height, lessThanOrEqualTo(360));
      final scroll = find.byKey(const Key('agent-attachment-info-scroll-a1'));
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          )
          .position;
      expect(position.maxScrollExtent, greaterThan(0));
      // 从缩略图移进卡片：中途短暂离开两者也不收起。
      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 50));
      await mouse.moveTo(tester.getCenter(card));
      await tester.pump(const Duration(milliseconds: 200));
      expect(card, findsOneWidget);
      await mouse.moveTo(tester.getCenter(card));
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(card),
          scrollDelta: const Offset(0, 120),
        ),
      );
      await tester.pump();
      expect(position.pixels, greaterThan(0));
      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 200));
      expect(card, findsNothing);
    });

    testWidgets('行首 / 弹出技能', (tester) async {
      final rec = await pumpAgent(tester, scene: AgentScene.welcome);
      await tester.enterText(find.byKey(const Key('agent-input')), '/nai-p');
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-skill-nai-prompt')));
      await tester.pump();
      expect(rec.last('composer'), '/skill:nai-prompt ');
    });

    testWidgets('运行中：停止、排队行转引导 / 撤回', (tester) async {
      final rec = await pumpAgent(tester, scene: AgentScene.run);
      await tester.tap(find.byKey(const Key('agent-stop')));
      await tester.pump();
      expect(rec.names, contains('stop'));
      await tester.tap(find.byKey(const Key('agent-queue-steer-q1')));
      await tester.pump();
      expect(rec.last('steerQueued'), 'q1');
      await tester.tap(find.byKey(const Key('agent-queue-withdraw-q1')));
      await tester.pump();
      expect(rec.last('withdrawQueued'), 'q1');
    });

    testWidgets('权限三档收成一个按钮，点开切换', (tester) async {
      for (final width in [460.0, 340.0]) {
        final rec = await pumpAgent(
          tester,
          scene: AgentScene.welcome,
          width: width,
        );
        // 只显示当前档位（自动），另外两档收在弹层里。
        expect(find.text('只读'), findsNothing);
        expect(find.text('询问'), findsNothing);
        await tester.tap(find.byKey(const Key('agent-permission')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('agent-permission-readonly')));
        await tester.pump();
        expect(rec.last('permission'), AgentPermissionMode.readonly);
        expect(find.byKey(const Key('agent-permission-popover')), findsNothing);
      }
    });

    testWidgets('模型弹层：换模型和思考档位', (tester) async {
      final rec = await pumpAgent(tester, scene: AgentScene.welcome);
      await tester.tap(find.byKey(const Key('agent-model')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-model-openai-gpt-5')));
      await tester.pump();
      expect(rec.last('selectModel'), ('openai', 'gpt-5'));
      await tester.tap(find.byKey(const Key('agent-model')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-thinking-high')));
      await tester.pump();
      expect(rec.last('thinking'), 'high');
    });

    testWidgets('聊天列表：切换聊天、搜索、工作区', (tester) async {
      final rec = await pumpAgent(tester);
      await tester.tap(find.byKey(const Key('agent-chats')));
      await tester.pump();
      expect(find.byKey(const Key('agent-chats-popover')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('agent-chats-search')), '厚涂');
      await tester.pump();
      expect(find.byKey(const Key('agent-chat-c1')), findsNothing);
      await tester.tap(find.byKey(const Key('agent-chat-c2')));
      await tester.pump();
      expect(rec.last('selectChat'), 'c2');
    });

    testWidgets('更多菜单：重命名聊天', (tester) async {
      final rec = await pumpAgent(tester);
      await tester.tap(find.byKey(const Key('agent-more')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-menu-rename')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('agent-name-input')),
        '水彩 v2',
      );
      await tester.tap(find.byKey(const Key('agent-name-save')));
      await tester.pump();
      expect(rec.last('renameChat'), ('c3', '水彩 v2'));
    });

    testWidgets('完全权限：首次切换先确认，勾不再提醒；取消不切', (tester) async {
      var rec = await pumpAgent(tester);
      await tester.tap(find.byKey(const Key('agent-permission')));
      await tester.pump();
      expect(find.text('完全权限'), findsOneWidget);
      // 从低到高：只读 → 询问 → 自动 → 完全权限。
      final ys = [
        for (final m in ['readonly', 'ask', 'auto', 'bypass'])
          tester.getTopLeft(find.byKey(Key('agent-permission-$m'))).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()));
      await tester.tap(find.byKey(const Key('agent-permission-bypass')));
      await tester.pump();
      expect(find.byKey(const Key('agent-confirm-dialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('agent-confirm-cancel')));
      await tester.pump();
      expect(find.byKey(const Key('agent-confirm-dialog')), findsNothing);
      expect(rec.names, isNot(contains('permission')));

      await tester.tap(find.byKey(const Key('agent-permission')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-permission-bypass')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-confirm-optout')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-confirm-ok')));
      await tester.pump();
      await tester.pump();
      expect(rec.names, containsAllInOrder(['silenceBypass', 'permission']));
      expect(rec.last('permission'), AgentPermissionMode.bypass);

      // 已勾过不再提醒：直接切；当前档是完全权限时按钮用警示色文字。
      final base = AgentFixture.view(AgentScene.chat);
      rec = await pumpAgent(
        tester,
        data: _copy(base, permission: AgentPermissionMode.ask, warned: true),
      );
      await tester.tap(find.byKey(const Key('agent-permission')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-permission-bypass')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('agent-confirm-dialog')), findsNothing);
      expect(rec.last('permission'), AgentPermissionMode.bypass);
      await pumpAgent(
        tester,
        data: _copy(base, permission: AgentPermissionMode.bypass),
      );
      final label = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('agent-permission')),
          matching: find.text('完全权限'),
        ),
      );
      final ctx = tester.element(find.byKey(const Key('agent-permission')));
      expect(label.style?.color, ctx.ui.error);
      // 只有一个下拉箭头（按钮组件自带的那个）。
      expect(
        find.descendant(
          of: find.byKey(const Key('agent-permission')),
          matching: find.byWidgetPredicate(
            (w) => w is AgentIcon && w.path == AgentGlyphs.chevron,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('删除对话：垃圾桶就地变成取消 / 删除，Esc 和点别处取消；删除后可撤销', (tester) async {
      final compose = AgentFixture.view(AgentScene.compose);
      final rec = await pumpAgent(
        tester,
        data: _copy(
          compose,
          chats: [
            for (final c in compose.chats)
              AgentChatInfo(id: c.id, title: c.title, createdAt: c.createdAt),
          ],
        ),
      );
      await tester.tap(find.byKey(const Key('agent-chats')));
      await tester.pump();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: tester.getCenter(find.byKey(const Key('agent-chat-c2'))),
      );
      addTearDown(mouse.removePointer);
      await tester.pump();
      expect(find.byKey(const Key('agent-chat-delete-c2')), findsOneWidget);

      Future<void> arm() async {
        await mouse.moveTo(
          tester.getCenter(find.byKey(const Key('agent-chat-c2'))),
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('agent-chat-delete-c2')));
        await tester.pump();
      }

      // 点垃圾桶：列表不关、不弹窗，这一行出现取消 / 删除。
      await arm();
      expect(find.byKey(const Key('agent-chats-popover')), findsOneWidget);
      expect(find.byKey(const Key('agent-confirm-dialog')), findsNothing);
      expect(find.byKey(const Key('agent-chat-delete-ok-c2')), findsOneWidget);
      expect(find.textContaining('厚涂对比三种光源'), findsWidgets);
      // 鼠标移开不会自动取消。
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      expect(find.byKey(const Key('agent-chat-delete-ok-c2')), findsOneWidget);

      // 取消按钮。
      await tester.tap(find.byKey(const Key('agent-chat-delete-cancel-c2')));
      await tester.pump();
      expect(find.byKey(const Key('agent-chat-delete-ok-c2')), findsNothing);
      expect(rec.names, isNot(contains('deleteChat')));

      // Esc 先取消确认，列表还在。
      await arm();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byKey(const Key('agent-chat-delete-ok-c2')), findsNothing);
      expect(find.byKey(const Key('agent-chats-popover')), findsOneWidget);

      // 点别的行只取消，不切换。
      await arm();
      await tester.tap(find.byKey(const Key('agent-chat-c1')));
      await tester.pump();
      expect(find.byKey(const Key('agent-chat-delete-ok-c2')), findsNothing);
      expect(rec.names, isNot(contains('selectChat')));

      // 确认删除 → 撤销提示。
      await arm();
      await tester.tap(find.byKey(const Key('agent-chat-delete-ok-c2')));
      await tester.pump();
      await tester.pump();
      expect(rec.last('deleteChat'), 'c2');
      expect(find.byKey(const Key('agent-undo-toast')), findsOneWidget);
      await tester.tap(find.byKey(const Key('agent-undo-toast-undo')));
      await tester.pump();
      await tester.pump();
      expect(rec.last('undoDelete'), 'trash-c2');
      expect(find.byKey(const Key('agent-undo-toast')), findsNothing);
    });

    testWidgets('菜单删对话两步确认、移开作废；删工作区弹侧栏内确认框', (tester) async {
      final compose = AgentFixture.view(AgentScene.compose);
      final rec = await pumpAgent(
        tester,
        data: _copy(
          compose,
          chats: [
            for (final c in compose.chats)
              AgentChatInfo(id: c.id, title: c.title, createdAt: c.createdAt),
          ],
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.tap(find.byKey(const Key('agent-more')));
      await tester.pump();
      final item = find.byKey(const Key('agent-menu-delete-chat'));
      await mouse.moveTo(tester.getCenter(item));
      await tester.pump();
      await tester.tap(item);
      await tester.pump();
      expect(find.text('再点一次删除'), findsOneWidget);
      expect(find.byKey(const Key('agent-confirm-dialog')), findsNothing);
      expect(rec.names, isNot(contains('deleteChat')));
      // 移开作废。
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      expect(find.text('再点一次删除'), findsNothing);
      expect(find.text('删除对话'), findsOneWidget);
      // 两次连点才删。
      await mouse.moveTo(tester.getCenter(item));
      await tester.pump();
      await tester.tap(item);
      await tester.pump();
      await tester.tap(item);
      await tester.pump();
      await tester.pump();
      expect(rec.names, contains('deleteChat'));
      expect(find.byKey(const Key('agent-undo-toast')), findsOneWidget);

      // 工作区影响整组聊天：仍弹确认框，但只盖侧栏。
      await tester.tap(find.byKey(const Key('agent-more')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-menu-delete-workspace')));
      await tester.pump();
      final panel = tester.getRect(find.byKey(const Key('agent-panel')));
      final dialog = tester.getRect(
        find.byKey(const Key('agent-confirm-dialog')),
      );
      expect(panel.contains(dialog.center), isTrue);
      expect(rec.names, isNot(contains('deleteWorkspace')));
      await tester.tap(find.byKey(const Key('agent-confirm-ok')));
      await tester.pump();
      await tester.pump();
      expect(rec.names, contains('deleteWorkspace'));

      // 等待用户时两个删除菜单都禁用。
      await pumpAgent(tester);
      await tester.tap(find.byKey(const Key('agent-more')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-menu-delete-chat')));
      await tester.pump();
      expect(find.text('再点一次删除'), findsNothing);
      await tester.pump(const Duration(seconds: 7));
    });

    testWidgets('确认弹窗只盖侧栏，居中在侧栏里', (tester) async {
      await pumpAgent(tester, width: 360);
      await tester.tap(find.byKey(const Key('agent-permission')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-permission-bypass')));
      await tester.pump();
      await tester.pump();
      final panel = tester.getRect(find.byKey(const Key('agent-panel')));
      final dialog = tester.getRect(
        find.byKey(const Key('agent-confirm-dialog')),
      );
      expect(panel.contains(dialog.topLeft), isTrue);
      expect(panel.contains(dialog.bottomRight - const Offset(1, 1)), isTrue);
      expect((dialog.center.dx - panel.center.dx).abs(), lessThan(1));
    });

    testWidgets('看图步骤：行下直接显示缩略图，不用展开参数；点开看大图', (tester) async {
      final base = AgentFixture.view(AgentScene.compose);
      await pumpAgent(
        tester,
        data: _copy(
          base,
          thread: [
            AgentTurn(
              id: 't-read',
              user: AgentUserMessage(text: '看看这张', at: DateTime(2026, 10, 20)),
              reply: AgentReply(
                blocks: [
                  AgentStepsBlock([
                    AgentStep(
                      id: 's-read',
                      tool: 'image_read',
                      status: AgentStepStatus.done,
                      subject: 'selected',
                      arguments: '{"image_id": "selected"}',
                      images: [
                        AgentFixture.img('r1', source: AgentImageSource.tool),
                      ],
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      );
      final thumbs = find.byKey(const Key('agent-step-images-s-read'));
      expect(thumbs, findsOneWidget);
      expect(find.text('参数'), findsNothing);
      await tester.tap(
        find.descendant(of: thumbs, matching: find.byType(AgentThumb)),
      );
      await tester.pump();
      expect(find.byKey(const Key('agent-zoom')), findsOneWidget);
      // 展开参数时不重复显示缩略图。
      await tester.tap(find.byKey(const Key('agent-step-s-read')));
      await tester.pump();
    });

    testWidgets('聊天列表：输入两个字以上同时搜正文，命中点开切过去', (tester) async {
      final rec = await pumpAgent(tester);
      await tester.tap(find.byKey(const Key('agent-chats')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('agent-chats-search')), '发');
      await tester.pump(const Duration(milliseconds: 400));
      expect(rec.names, isNot(contains('searchChats')));
      await tester.enterText(find.byKey(const Key('agent-chats-search')), '发型');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(rec.last('searchChats'), '发型');
      expect(find.text('内容匹配'), findsOneWidget);
      expect(find.byKey(const Key('agent-chat-hit-c0')), findsOneWidget);
      await tester.tap(find.byKey(const Key('agent-chat-hit-c0')));
      await tester.pump();
      expect(rec.last('selectChat'), 'c0');
    });

    testWidgets('出错时给重试（重新回答最后一轮）', (tester) async {
      final rec = await pumpAgent(
        tester,
        data: _copy(AgentFixture.view(AgentScene.compose), error: '连接断了'),
      );
      await tester.ensureVisible(find.byKey(const Key('agent-error-retry')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-error-retry')));
      await tester.pump();
      expect(rec.names, contains('regenerate'));
    });

    group('过程折叠与工作中提示', () {
      DateTime at(int s) => DateTime(2026, 10, 20, 15, 0, s);
      AgentStep step(
        String id,
        String tool, {
        AgentStepStatus status = AgentStepStatus.done,
        int s = 0,
        List<AgentImage> images = const [],
      }) => AgentStep(
        id: id,
        tool: tool,
        status: status,
        at: at(s),
        duration: status == AgentStepStatus.done
            ? const Duration(milliseconds: 130)
            : null,
        arguments: '{}',
        images: images,
      );
      AgentThinkingBlock think(int s, {bool live = false}) =>
          AgentThinkingBlock('想一想', at: at(s), live: live);
      AgentViewData withReply(
        List<AgentBlock> blocks, {
        bool live = false,
        AgentRunStatus? status,
        int? limit,
      }) {
        final b = _copy(
          AgentFixture.view(AgentScene.compose),
          thread: [
            AgentTurn(
              id: 't',
              user: AgentUserMessage(text: 'Q', at: at(0)),
              reply: AgentReply(blocks: blocks, live: live),
            ),
          ],
        );
        return AgentViewData(
          now: b.now,
          workspace: b.workspace,
          chat: b.chat,
          workspaces: b.workspaces,
          chats: b.chats,
          composer: b.composer,
          thread: b.thread,
          shelf: b.shelf,
          memory: b.memory,
          usage: b.usage,
          models: b.models,
          thinking: b.thinking,
          permission: b.permission,
          mentions: b.mentions,
          skills: b.skills,
          status: status ?? b.status,
          runLimit: limit,
        );
      }

      testWidgets('出现结果后前面的过程收成一行，点开再收回；用时按消息时间', (tester) async {
        await pumpAgent(
          tester,
          data: withReply([
            think(1),
            AgentStepsBlock([step('a', 'bash', s: 3), step('b', 'bash', s: 5)]),
            think(8),
            AgentTextBlock('中间回复', at: at(12)),
            think(13),
            AgentStepsBlock([step('c', 'studio_context', s: 14)]),
            AgentTextBlock('结论', at: at(16)),
          ]),
        );
        final fold = find.byKey(const Key('agent-fold-0'));
        expect(fold, findsOneWidget);
        expect(find.byKey(const Key('agent-step-a')), findsNothing);
        expect(
          find.descendant(
            of: fold,
            matching: find.textContaining('运行命令 2 次', findRichText: true),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: fold, matching: find.text('11.0s')),
          findsOneWidget,
        );
        // 两条以内不折叠。
        expect(find.byKey(const Key('agent-fold-2')), findsNothing);
        expect(find.byKey(const Key('agent-step-c')), findsOneWidget);
        await tester.tap(fold);
        await tester.pump();
        expect(find.byKey(const Key('agent-step-a')), findsOneWidget);
        await tester.tap(fold);
        await tester.pump();
        expect(find.byKey(const Key('agent-step-a')), findsNothing);
      });

      testWidgets('运行中最后一段展开；等你处理、出错的段不收', (tester) async {
        await pumpAgent(
          tester,
          data: withReply(
            [
              think(1),
              AgentStepsBlock([
                step('w1', 'bash', s: 2),
                step('w2', 'ask_user', status: AgentStepStatus.waitingUser),
              ]),
              AgentTextBlock('问你一下', at: at(4)),
              think(5),
              AgentStepsBlock([
                step('f1', 'bash', s: 6),
                step('f2', 'krita__push', status: AgentStepStatus.failed, s: 7),
              ]),
              AgentTextBlock('推送失败了', at: at(8)),
              think(9),
              AgentStepsBlock([
                step('r1', 'bash', s: 10),
                step('r2', 'image_generate', status: AgentStepStatus.running),
              ]),
            ],
            live: true,
            status: AgentRunStatus.working,
          ),
        );
        expect(find.byKey(const Key('agent-step-w2')), findsOneWidget);
        expect(find.byKey(const Key('agent-step-f2')), findsOneWidget);
        expect(find.byKey(const Key('agent-step-r2')), findsOneWidget);
        expect(find.byKey(const Key('agent-fold-0')), findsNothing);
        // 运行中的图标和失败图标。
        expect(
          find.byKey(const ValueKey('agent-activity-gen-running')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('agent-activity-external-failed')),
          findsOneWidget,
        );
        // 工作中提示行：标语 + 用时，不再写“正在思考”。
        expect(find.byKey(const Key('agent-live-slogan')), findsOneWidget);
        expect(find.text('正在思考'), findsNothing);
      });

      testWidgets('看图步骤留在外面，前面的过程照样收起', (tester) async {
        await pumpAgent(
          tester,
          data: withReply([
            think(1),
            AgentStepsBlock([
              step('x1', 'studio_context', s: 2),
              step('x2', 'bash', s: 3),
              step(
                'x3',
                'image_read',
                s: 4,
                images: [AgentFixture.img('r1', source: AgentImageSource.tool)],
              ),
            ]),
            AgentTextBlock('看完了', at: at(6)),
          ]),
        );
        expect(find.byKey(const Key('agent-fold-0')), findsOneWidget);
        expect(find.byKey(const Key('agent-step-images-x3')), findsOneWidget);
      });

      testWidgets('一轮结束后最后一串过程也收起，结束态是灰色类型图标', (tester) async {
        await pumpAgent(
          tester,
          data: withReply([
            AgentTextBlock('先说一句', at: at(1)),
            think(2),
            AgentStepsBlock([
              step('y1', 'bash', s: 3),
              step('y2', 'bash', s: 4),
            ]),
          ]),
        );
        final fold = find.byKey(const Key('agent-fold-1'));
        expect(fold, findsOneWidget);
        await tester.tap(fold);
        await tester.pump();
        expect(
          find.byKey(const ValueKey('agent-activity-run-done')),
          findsNWidgets(2),
        );
        expect(
          find.byKey(const ValueKey('agent-activity-think-done')),
          findsOneWidget,
        );
      });

      testWidgets('步数上限：灰卡，继续发新消息，调整上限去设置', (tester) async {
        final rec = await pumpAgent(
          tester,
          data: withReply([AgentTextBlock('做到一半', at: at(1))], limit: 32),
        );
        expect(find.byKey(const Key('agent-limit')), findsOneWidget);
        expect(find.byKey(const Key('agent-error')), findsNothing);
        expect(find.text('已达到单次任务步数上限（32 步）'), findsOneWidget);
        await tester.tap(find.byKey(const Key('agent-limit-continue')));
        await tester.pump();
        expect(rec.names, contains('continue'));
        expect(rec.names, isNot(contains('regenerate')));
        await tester.tap(find.byKey(const Key('agent-limit-adjust')));
        await tester.pump();
        expect(rec.names, contains('adjustLimit'));
      });
    });

    testWidgets('用量弹层显示本聊天生图花费估算', (tester) async {
      final base = AgentFixture.view(AgentScene.chat);
      await pumpAgent(tester, data: _copy(base, anlas: 48));
      await tester.tap(find.byKey(const Key('agent-usage')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('agent-usage-anlas')), findsOneWidget);
      expect(find.text('≈ 48 Anlas'), findsOneWidget);
    });

    testWidgets('操作失败显示提示', (tester) async {
      final base = AgentFixture.actions();
      final failing = AgentActions(
        onClose: base.onClose,
        onNewChat: () async => false,
        onSelectChat: base.onSelectChat,
        onRenameChat: base.onRenameChat,
        onSelectWorkspace: base.onSelectWorkspace,
        onCreateWorkspace: base.onCreateWorkspace,
        onRenameWorkspace: base.onRenameWorkspace,
        onOpenWorkspaceFolder: base.onOpenWorkspaceFolder,
        onCompact: base.onCompact,
        onExport: base.onExport,
        onOpenSettings: base.onOpenSettings,
        onComposerChanged: base.onComposerChanged,
        onSend: base.onSend,
        onStop: base.onStop,
        onPickImages: base.onPickImages,
        onAttachCanvas: base.onAttachCanvas,
        onAttachImage: base.onAttachImage,
        onPaste: base.onPaste,
        onRemoveAttachment: base.onRemoveAttachment,
        onEditQueued: base.onEditQueued,
        onSteerQueued: base.onSteerQueued,
        onWithdrawQueued: base.onWithdrawQueued,
        onRestoreQueued: base.onRestoreQueued,
        onResendFrom: base.onResendFrom,
        onRegenerate: base.onRegenerate,
        onAnswer: base.onAnswer,
        onCancelAsk: base.onCancelAsk,
        onApprove: base.onApprove,
        onCancelApproval: base.onCancelApproval,
        onDecideGate: base.onDecideGate,
        onUndoDiff: base.onUndoDiff,
        onUndoDiffs: base.onUndoDiffs,
        onRevealImage: base.onRevealImage,
        onOpenFile: base.onOpenFile,
        onOpenLink: base.onOpenLink,
        onSelectModel: base.onSelectModel,
        onOpenModelSettings: base.onOpenModelSettings,
        onThinking: base.onThinking,
        onPermission: base.onPermission,
        onRefreshUsage: base.onRefreshUsage,
        onDismissNotices: base.onDismissNotices,
        onRetryInit: base.onRetryInit,
        onEditMemory: base.onEditMemory,
        onDeleteChat: base.onDeleteChat,
        onDeleteWorkspace: base.onDeleteWorkspace,
        onUndoDelete: base.onUndoDelete,
        onSearchChats: base.onSearchChats,
        onImageAction: base.onImageAction,
        onSilenceBypass: base.onSilenceBypass,
        onContinue: base.onContinue,
        onAdjustLimit: base.onAdjustLimit,
        onOpenSettingAt: base.onOpenSettingAt,
      );
      await pumpAgent(tester, actions: failing);
      await tester.tap(find.byKey(const Key('agent-new-chat')));
      await tester.pump();
      expect(find.byKey(const Key('agent-toast')), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });
  });

  // 默认对每个场景做深浅色／两种宽度的实绘冒烟；需要导出 PNG 时：
  // CAPTURE_AGENT=1 flutter test test/presentation/ui/agent/agent_panel_test.dart --plain-name capture
  group('capture', () {
    final out =
        Platform.environment['CAPTURE_AGENT_OUT'] ??
        '.dart_tool/agent-redesign-20261018/new';
    final on = Platform.environment['CAPTURE_AGENT'] == '1';
    for (final dark in [false, true]) {
      for (final width in [360.0, 460.0]) {
        for (final scene in AgentScene.values) {
          testWidgets('capture ${scene.name}${dark ? '-dark' : ''}-$width', (
            tester,
          ) async {
            await pumpAgent(
              tester,
              scene: scene,
              width: width,
              height: 1000,
              dark: dark,
              tab: switch (scene) {
                AgentScene.shelf => AgentTab.shelf,
                AgentScene.memory => AgentTab.memory,
                _ => AgentTab.chat,
              },
            );
            if (scene == AgentScene.compose) {
              await tester.showKeyboard(find.byKey(const Key('agent-input')));
              await tester.enterText(
                find.byKey(const Key('agent-input')),
                '把 @角色 1 的发色换成浅金，再参考 @',
              );
              await tester.pump();
            }
            await tester.runAsync(() async {
              for (final e in find.byType(Image).evaluate()) {
                final img = e.widget as Image;
                await precacheImage(img.image, e);
              }
            });
            await tester.pump();
            expect(tester.takeException(), isNull);
            if (!on) return;
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const Key('agent-capture')),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 1);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final f = File(
                '$out/${scene.name}${dark ? '-dark' : ''}-${width.toInt()}.png',
              );
              f.parent.createSync(recursive: true);
              f.writeAsBytesSync(bytes!.buffer.asUint8List());
            });
          });
        }
      }
    }
  });
}

AgentViewData _withPending(AgentViewData d, List<AgentPending> pending) =>
    AgentViewData(
      now: d.now,
      workspace: d.workspace,
      chat: d.chat,
      workspaces: d.workspaces,
      chats: d.chats,
      composer: AgentComposerData(text: d.composer.text, pending: pending),
      thread: d.thread,
      shelf: d.shelf,
      memory: d.memory,
      usage: d.usage,
      models: d.models,
      thinking: d.thinking,
      permission: d.permission,
      mentions: d.mentions,
      skills: d.skills,
      draft: d.draft,
      status: d.status,
      revision: d.revision,
    );

AgentViewData _withAttachments(
  AgentViewData d,
  List<AgentAttachment> attachments,
) => AgentViewData(
  now: d.now,
  workspace: d.workspace,
  chat: d.chat,
  workspaces: d.workspaces,
  chats: d.chats,
  composer: AgentComposerData(text: d.composer.text, attachments: attachments),
  thread: d.thread,
  shelf: d.shelf,
  memory: d.memory,
  usage: d.usage,
  models: d.models,
  thinking: d.thinking,
  permission: d.permission,
  mentions: d.mentions,
  skills: d.skills,
  draft: d.draft,
  status: d.status,
  revision: d.revision,
);

AgentViewData _copy(
  AgentViewData b, {
  AgentPermissionMode? permission,
  bool? warned,
  String? error,
  int? anlas,
  List<AgentChatInfo>? chats,
  List<AgentTurn>? thread,
}) => AgentViewData(
  now: b.now,
  workspace: b.workspace,
  chat: b.chat,
  workspaces: b.workspaces,
  chats: chats ?? b.chats,
  composer: b.composer,
  thread: thread ?? b.thread,
  shelf: b.shelf,
  memory: b.memory,
  usage: anlas == null
      ? b.usage
      : AgentUsageData(
          tokens: b.usage.tokens,
          window: b.usage.window,
          input: b.usage.input,
          output: b.usage.output,
          total: b.usage.total,
          userMessages: b.usage.userMessages,
          assistantMessages: b.usage.assistantMessages,
          toolCalls: b.usage.toolCalls,
          anlas: anlas,
        ),
  models: b.models,
  thinking: b.thinking,
  permission: permission ?? b.permission,
  mentions: b.mentions,
  skills: b.skills,
  draft: b.draft,
  status: b.status,
  error: error ?? b.error,
  notices: b.notices,
  revision: b.revision,
  quick: b.quick,
  bypassWarned: warned ?? b.bypassWarned,
);
