import '../../../helpers/fetch_test_server.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_questions.dart';

void main() {
  test(
    'question cancellation and invalid input do not silently select an option',
    () async {
      final broker = NaiAgentQuestions();
      addTearDown(broker.dispose);
      final token = NaiAgentCancellation();
      final pending = broker.ask('workspace', 'chat', {
        'questions': [
          {
            'id': 'direction',
            'question': '方向？',
            'options': ['A', 'B'],
          },
        ],
      }, token);
      final error = expectLater(pending, throwsA(isA<NaiAgentToolError>()));
      token.cancel();
      await error;
      expect(broker.forChat('chat'), isEmpty);
      await expectLater(
        broker.ask('workspace', 'chat', {
          'questions': [],
        }, NaiAgentCancellation()),
        throwsA(isA<NaiAgentToolError>()),
      );
      final second = broker.ask('workspace', 'chat', {
        'questions': [
          {'id': 'direction', 'question': '方向？'},
        ],
      }, NaiAgentCancellation());
      broker.cancel(broker.forChat('chat').single.id);
      expect((await second)['details'], {'status': 'cancelled', 'answers': []});
    },
  );
  test(
    'official Pi asks Flutter, waits for an explicit answer, then sends it to the next model request',
    () async {
      final root = await Directory.systemTemp.createTemp('nai-question-host-');
      final broker = NaiAgentQuestions();
      final server = await bindFetchTestServer();
      final requests = <Map>[];
      final asked = Completer<void>();
      broker.addListener(() {
        if (broker.forChat('chat').isNotEmpty && !asked.isCompleted) {
          asked.complete();
        }
      });
      final serving = server.listen((request) async {
        requests.add(
          jsonDecode(await utf8.decoder.bind(request).join()) as Map,
        );
        final question = requests.length == 1;
        request.response.headers.set(
          'content-type',
          'text/event-stream; charset=utf-8',
        );
        request.response.write(
          'data: ${jsonEncode({
            'id': 'test',
            'object': 'chat.completion.chunk',
            'model': 'test',
            'choices': [
              {
                'index': 0,
                'delta': question ? {
                        'role': 'assistant',
                        'tool_calls': [
                          {
                            'index': 0,
                            'id': 'ask-1',
                            'type': 'function',
                            'function': {
                              'name': 'ask_user',
                              'arguments': jsonEncode({
                                'questions': [
                                  {
                                    'id': 'direction',
                                    'question': '先整理什么？',
                                    'options': ['画师标签', '角色标签'],
                                  },
                                ],
                              }),
                            },
                          },
                        ],
                      } : {'role': 'assistant', 'content': '收到回答，继续整理。'},
                'finish_reason': question ? 'tool_calls' : 'stop',
              },
            ],
          })}\n\ndata: [DONE]\n\n',
        );
        await request.response.close();
      });
      PiHostClient? host;
      try {
        host = await PiHostClient.start(
          nodeExecutable: 'E:/node/node.exe',
          hostScript: File('tool/nai_agent/host.mjs').absolute.path,
          workspaceId: 'workspace',
          workspaceDirectory: root,
          agentDirectory: Directory('${root.path}/.agent'),
          systemPrompt: 'NAI Agent.',
          extraToolNames: const ['ask_user'],
          privateModelConfig: {
            'providerId': 'question-test',
            'modelId': 'test',
            'protocol': 'openaiChatCompletions',
            'baseUrl': 'http://127.0.0.1:${server.port}',
            'tools': true,
          },
          executeTool: (name, params, token) =>
              broker.ask('workspace', 'chat', params, token),
        );
        final prompt = host.prompt('帮我整理标签');
        await asked.future.timeout(const Duration(seconds: 10));
        expect(requests, hasLength(1));
        expect(jsonEncode(requests.first['tools']), contains('ask_user'));
        final card = broker.forChat('chat').single;
        broker.answer(card.id, {'direction': '画师标签'});
        final result = await prompt.timeout(const Duration(seconds: 10));
        expect(requests, hasLength(2));
        final response = (requests.last['messages'] as List)
            .where((m) => m['role'] == 'tool')
            .single;
        expect(jsonEncode(response), contains('画师标签'));
        expect(
          (result['messages'] as List).last['content'][0]['text'],
          '收到回答，继续整理。',
        );
        expect(broker.forChat('chat'), isEmpty);
        expect(
          (await host.getSystemPrompt())['text'],
          contains(
            'Missing input/preferences: ask_user (direct tool, not from codemode).',
          ),
        );
      } finally {
        await host?.close();
        broker.dispose();
        await serving.cancel();
        await server.close(force: true);
        await root.delete(recursive: true);
      }
    },
  );
}
