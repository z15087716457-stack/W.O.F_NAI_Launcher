import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'agent_test_harness.dart';

AgentViewData streamView(int revision, {bool idle = false, String draft = ''}) {
  final fixture = AgentFixture.view(AgentScene.run);
  return AgentViewData(
    now: fixture.now,
    workspace: fixture.workspace,
    chat: fixture.chat,
    workspaces: fixture.workspaces,
    chats: fixture.chats,
    composer: AgentComposerData(text: draft, canSend: idle && draft.isNotEmpty),
    thread: [
      for (var i = 0; i < 4; i++)
        AgentTurn(
          id: 'old$i',
          renderKey: 'old$i',
          user: AgentUserMessage(text: '历史请求 $i', at: fixture.now),
          reply: AgentReply(blocks: [AgentTextBlock('历史回复 $i，**保持稳定**。')]),
        ),
      AgentTurn(
        id: 'live',
        renderKey: (revision, idle),
        user: AgentUserMessage(text: '当前请求', at: fixture.now),
        reply: AgentReply(
          live: !idle,
          blocks: [
            AgentThinkingBlock(
              List.filled(20 + revision, '新增思考。').join(),
              live: !idle,
            ),
          ],
        ),
      ),
    ],
    shelf: fixture.shelf,
    usage: fixture.usage,
    models: fixture.models,
    thinking: fixture.thinking,
    permission: fixture.permission,
    mentions: fixture.mentions,
    skills: fixture.skills,
    status: idle ? AgentRunStatus.idle : AgentRunStatus.working,
    revision: revision,
  );
}

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets(
    'stream updates retain old replies, composer focus and editing selection',
    (t) async {
      await pumpAgent(t, data: streamView(0, draft: '本地草稿'));
      final field = find.byKey(const Key('agent-input'));
      await t.tap(field);
      await t.pump();
      final editing = t.widget<TextField>(field).controller!;
      editing.selection = const TextSelection(baseOffset: 1, extentOffset: 3);
      final counts = <String, int>{};
      debugOnRebuildDirtyWidget = (element, _) {
        final name = element.widget.runtimeType.toString();
        counts.update(name, (n) => n + 1, ifAbsent: () => 1);
      };
      for (var i = 1; i <= 12; i++) {
        await pumpAgent(t, data: streamView(i, draft: '本地草稿'));
      }
      debugOnRebuildDirtyWidget = null;
      expect(counts['AgentMarkdown'] ?? 0, 0);
      expect(counts['AgentComposer'] ?? 0, 0);
      expect(
        counts['_Turn'],
        12,
        reason: 'only the active turn should rebuild',
      );
      expect(editing.text, '本地草稿');
      expect(
        editing.selection,
        const TextSelection(baseOffset: 1, extentOffset: 3),
      );
      expect(t.widget<TextField>(field).focusNode!.hasFocus, isTrue);
      await pumpAgent(t, data: streamView(13, idle: true, draft: '本地草稿'));
      expect(find.byKey(const Key('agent-progress')), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
}
