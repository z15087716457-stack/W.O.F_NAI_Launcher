import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';

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
      final (id, answers) = rec.last('answer')! as (String, Map<String, String>);
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

    testWidgets('权限三档；窄宽收成下拉', (tester) async {
      var rec = await pumpAgent(tester, scene: AgentScene.welcome, width: 460);
      await tester.tap(find.text('只读'));
      await tester.pump();
      expect(rec.last('permission'), AgentPermissionMode.readonly);

      rec = await pumpAgent(tester, scene: AgentScene.welcome, width: 340);
      expect(find.text('只读'), findsNothing);
      await tester.tap(find.byKey(const Key('agent-permission')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-permission-ask')));
      await tester.pump();
      expect(rec.last('permission'), AgentPermissionMode.ask);
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
        onEditMessage: base.onEditMessage,
        onRegenerate: base.onRegenerate,
        onAnswer: base.onAnswer,
        onCancelAsk: base.onCancelAsk,
        onApprove: base.onApprove,
        onCancelApproval: base.onCancelApproval,
        onDecideGate: base.onDecideGate,
        onUndoDiff: base.onUndoDiff,
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
      );
      await pumpAgent(tester, actions: failing);
      await tester.tap(find.byKey(const Key('agent-new-chat')));
      await tester.pump();
      expect(find.byKey(const Key('agent-toast')), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });
  });

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
          }, skip: !on);
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
