import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/prompt_set_tools.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_resources.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_thread_mapper.dart';
import '../../../core/nai_agent/prompt_set_tools_test.dart' show promptSetInput;

void main() {
  late Directory root;
  late AgentChatRuntime runtime;
  late AgentResources resources;
  late AgentThreadMapper mapper;
  late NaiAgentPromptSets sets;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('prompt-set-mapper-');
    final store = AgentWorkspaceStore(root),
        workspace = await AgentWorkspaceStore(root).createWorkspace('sets');
    runtime = AgentChatRuntime(
      workspace,
      await store.createChat(workspace.id, 'sets'),
      const AgentComposerState(),
    );
    resources = AgentResources(() {});
    mapper = AgentThreadMapper(resources);
    sets = NaiAgentPromptSets(workspace.agentDirectory);
  });
  tearDown(() async {
    await resources.settle();
    resources.dispose();
    await root.delete(recursive: true);
  });
  List<AgentPromptSetBlock> cards() => [
    for (final turn in mapper.map(runtime).turns)
      ...?turn.reply?.blocks.whereType<AgentPromptSetBlock>(),
  ];
  for (final nested in [false, true]) {
    test(
      'latest only across whole chat, direct/nested=$nested, read omitted and restart loads',
      () async {
        final first =
            (await sets.execute(
                  promptSetInput(),
                  NaiAgentCancellation(),
                ))['details']
                as Map<String, dynamic>;
        final update = promptSetInput()
          ..addAll({
            'action': 'update',
            'set_id': first['set_id'],
            'expected_revision': 1,
          });
        update['items'][1]['note'] = 'Changed';
        final second =
            (await sets.execute(update, NaiAgentCancellation()))['details']
                as Map<String, dynamic>;
        runtime.messages = [];
        for (final (i, value) in [first, second].indexed) {
          final id = 'call$i';
          runtime.messages.addAll([
            {'role': 'user', 'content': 'revision $i'},
            {
              'role': 'assistant',
              'content': [
                {
                  'type': 'toolCall',
                  'id': id,
                  'name': nested ? 'codemode' : 'prompt_set',
                  'arguments': {'action': i == 0 ? 'create' : 'update'},
                },
              ],
            },
            {
              'role': 'toolResult',
              'toolCallId': id,
              'details': nested
                  ? {
                      'calls': [
                        {
                          'id': 'nested$i',
                          'name': 'mcp__nai_studio__prompt_set',
                          'status': 'ok',
                        },
                      ],
                      'studio_results': [
                        {
                          'tool': 'mcp__nai_studio__prompt_set',
                          'tool_call_id': 'nested$i',
                          ...value,
                        },
                      ],
                    }
                  : value,
            },
          ]);
        }
        expect(cards(), hasLength(1));
        expect(cards().single.revision, 2);
        expect(cards().single.changedItems, [1]);
        await resources.settle();
        final card = cards().single;
        expect(card.data!.title, 'Rain');
        expect(card.data!.items[1].note, 'Changed');
        resources.dispose();
        resources = AgentResources(() {});
        mapper = AgentThreadMapper(resources);
        cards();
        await resources.settle();
        expect(cards().single.data!.revision, 2);
        if (nested) {
          // A later failure in the same script must not hide a successful set write.
          runtime.messages.last['isError'] = true;
          expect(cards(), hasLength(1));
          expect(cards().single.revision, 2);
        }
      },
    );
  }
  test(
    'missing file yields a small missing-data block, never throws',
    () async {
      runtime.messages = [
        {
          'role': 'assistant',
          'content': [
            {
              'type': 'toolCall',
              'id': 'missing',
              'name': 'prompt_set',
              'arguments': {'action': 'create'},
            },
          ],
        },
        {
          'role': 'toolResult',
          'toolCallId': 'missing',
          'details': {
            'ok': true,
            'set_id': '012345abcdef',
            'revision': 1,
            'count': 2,
          },
        },
      ];
      expect(cards().single.data, isNull);
      await resources.settle();
      expect(cards().single.data, isNull);
    },
  );
  test('resource cache invalidates on atomic file updates', () async {
    final first =
        (await sets.execute(
              promptSetInput(),
              NaiAgentCancellation(),
            ))['details']
            as Map;
    final id = first['set_id'] as String;
    expect(resources.promptSet(runtime.workspace, id), isNull);
    await resources.settle();
    expect(resources.promptSet(runtime.workspace, id)!['revision'], 1);
    final update = promptSetInput()
      ..addAll({
        'action': 'update',
        'set_id': id,
        'expected_revision': 1,
        'title': 'Changed on disk',
      });
    await sets.execute(update, NaiAgentCancellation());
    Map<String, dynamic>? latest;
    for (var i = 0; i < 50; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      resources.promptSet(runtime.workspace, id);
      await resources.settle();
      latest = resources.promptSet(runtime.workspace, id);
      if (latest?['revision'] == 2) break;
    }
    expect(latest?['title'], 'Changed on disk');
  });
  test('read result never emits a card', () {
    runtime.messages = [
      {
        'role': 'assistant',
        'content': [
          {
            'type': 'toolCall',
            'id': 'read',
            'name': 'prompt_set',
            'arguments': {'action': 'read'},
          },
        ],
      },
      {
        'role': 'toolResult',
        'toolCallId': 'read',
        'details': {
          'ok': true,
          'set_id': '012345abcdef',
          'revision': 1,
          'count': 2,
        },
      },
    ];
    expect(cards(), isEmpty);
  });
}
