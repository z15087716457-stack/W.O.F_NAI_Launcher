// D05/D06/D07（10-25）：斜杠三组、无参命令直接执行、/model /history 打开现有面板、
// 下一句建议 Tab 采纳、上下文弹窗里的缓存预热状态。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';

import 'agent_test_harness.dart';

void main() {
  testWidgets('/ 弹出三组：Skill / 提示词模板 / Studio 命令', (t) async {
    await pumpAgent(t, scene: AgentScene.welcome);
    await t.enterText(find.byKey(const Key('agent-input')), '/');
    await t.pump();
    expect(find.text('Skill'), findsOneWidget);
    expect(find.text('提示词模板'), findsOneWidget);
    expect(find.text('Studio 命令'), findsOneWidget);
    expect(find.byKey(const Key('agent-skill-nai-prompt')), findsOneWidget);
    expect(
      find.byKey(const Key('agent-slash-template-review-draft')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('agent-slash-builtin-new')), findsOneWidget);
    expect(find.textContaining('[重点]'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('过滤：/com 只剩 compact；模板/有参命令插入文本', (t) async {
    final rec = await pumpAgent(t, scene: AgentScene.welcome);
    await t.enterText(find.byKey(const Key('agent-input')), '/com');
    await t.pump();
    expect(
      find.byKey(const Key('agent-slash-builtin-compact')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('agent-slash-builtin-new')), findsNothing);
    await t.tap(find.byKey(const Key('agent-slash-builtin-compact')));
    await t.pump();
    expect(rec.last('composer'), '/compact ');
    expect(rec.names, isNot(contains('slash')));
    await t.enterText(find.byKey(const Key('agent-input')), '/rev');
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(rec.last('composer'), '/review-draft ');
  });

  testWidgets('无参 Studio 命令选中即执行，并清掉 /查询', (t) async {
    final rec = await pumpAgent(t, scene: AgentScene.welcome);
    await t.enterText(find.byKey(const Key('agent-input')), '/ne');
    await t.pump();
    await t.tap(find.byKey(const Key('agent-slash-builtin-new')));
    await t.pump();
    expect(rec.last('slash'), 'new');
    expect(rec.last('composer'), '');
    expect(find.byKey(const Key('agent-mention-panel')), findsNothing);
  });

  testWidgets('localAction：/model 打开模型弹层，/history 打开历史', (t) async {
    final base = AgentFixture.view(AgentScene.welcome);
    AgentViewData at(AgentLocalAction? a, int rev) => AgentViewData(
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
      slashCommands: base.slashCommands,
      draft: base.draft,
      status: base.status,
      revision: base.revision + rev,
      localAction: a,
      localActionRevision: rev,
    );
    await pumpAgent(t, data: at(null, 0));
    expect(find.byKey(const Key('agent-model-popover')), findsNothing);
    await pumpAgent(t, data: at(AgentLocalAction.model, 1));
    await t.pump();
    expect(find.byKey(const Key('agent-model-popover')), findsOneWidget);
    // 同一 revision 再刷新不重复触发。
    await t.tapAt(const Offset(5, 5));
    await t.pump();
    await pumpAgent(t, data: at(AgentLocalAction.model, 1));
    await t.pump();
    expect(find.byKey(const Key('agent-model-popover')), findsNothing);
    await pumpAgent(t, data: at(AgentLocalAction.history, 2));
    await t.pump();
    expect(find.byKey(const Key('agent-history')), findsOneWidget);
  });

  testWidgets('下一句建议：空输入时显示，点或 Tab 采纳；输入后消失', (t) async {
    final rec = await pumpAgent(t, scene: AgentScene.shelf);
    expect(find.byKey(const Key('agent-suggestion')), findsOneWidget);
    expect(find.text('再出 4 张，把背景换成黄昏'), findsOneWidget);
    await t.tap(find.byKey(const Key('agent-input')));
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    expect(rec.names, contains('acceptSuggestion'));
    await t.enterText(find.byKey(const Key('agent-input')), 'x');
    await t.pump();
    expect(find.byKey(const Key('agent-suggestion')), findsNothing);
  });

  testWidgets('上下文弹窗：缓存预热一节显示模式与状态', (t) async {
    await pumpAgent(t, scene: AgentScene.chat);
    await t.tap(find.byKey(const Key('agent-usage')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('agent-usage-cache-warming')), findsOneWidget);
    expect(find.text('缓存预热'), findsOneWidget);
    expect(find.text('只在 Agent 运行时'), findsOneWidget);
    expect(find.text('待机，下次运行时开始'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
