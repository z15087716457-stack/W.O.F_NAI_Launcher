import '../../helpers/fetch_test_server.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/core/nai_agent/model_request_gate.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';

void main() {
  late Directory root;
  late HttpServer server;
  late StreamSubscription<HttpRequest> serving;
  final clients = <PiHostClient>[];
  final bodies = <Map>[];
  Future<void> Function(int, HttpRequest)? beforeReply;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('nai-lifecycle-');
    server = await bindFetchTestServer();
    bodies.clear();
    beforeReply = null;
    serving = server.listen((request) async {
      bodies.add(jsonDecode(await utf8.decoder.bind(request).join()) as Map);
      await beforeReply?.call(bodies.length, request);
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
              'delta': {'role': 'assistant', 'content': '完成'},
              'finish_reason': 'stop',
            },
          ],
        })}\n\ndata: [DONE]\n\n',
      );
      await request.response.close();
    });
  });
  tearDown(() async {
    for (final client in clients) {
      await client.close();
    }
    clients.clear();
    await serving.cancel();
    await server.close(force: true);
    await root.delete(recursive: true);
  });
  Future<PiHostClient> start(
    String id, {
    File? resume,
    String provider = 'lifecycle-test',
    bool translation = false,
  }) async {
    final workspace = Directory('${root.path}/$id');
    final client = await PiHostClient.start(
      nodeExecutable:
          Platform.environment['NAI_AGENT_NODE'] ?? 'E:/node/node.exe',
      hostScript: File('tool/nai_agent/host.mjs').absolute.path,
      workspaceId: id,
      workspaceDirectory: workspace,
      agentDirectory: Directory('${workspace.path}/.agent'),
      sessionDirectory: Directory('${workspace.path}/sessions'),
      sessionFile: resume,
      systemPrompt: 'NAI Agent.',
      sessionKind: translation ? 'translation' : null,
      seedSystemPrompt: translation ? 'Original system' : null,
      seedMessages: translation
          ? [
              {'role': 'user', 'content': 'original request'},
              {'role': 'assistant', 'content': 'original response'},
            ]
          : const [],
      privateModelConfig: {
        'providerId': provider,
        'modelId': 'test',
        'protocol': 'openaiChatCompletions',
        'baseUrl': 'http://127.0.0.1:${server.port}',
        'apiKey': 'synthetic',
        'tools': true,
        'vision': true,
        'maxConcurrentRequests': 1,
        // Request counts here cover the main loop only (D06 has own tests).
        'nextSuggestion': false,
      },
      executeTool: (_, __, ___) async => {'content': []},
    );
    clients.add(client);
    return client;
  }

  test(
    'Dart client starts isolated translation with exact seed prefix and closes',
    () async {
      final client = await start('translation', translation: true);
      expect(client.initialState['sessionFile'], isNull);
      expect(bodies, isEmpty);
      await client.prompt('adjust blocks');
      final messages = bodies.single['messages'] as List;
      expect(messages[0]['content'], 'Original system');
      expect(messages[1]['content'], 'original request');
      expect(messages[2]['content'], 'original response');
      final tools = bodies.single['tools'] as List;
      expect(tools.map((tool) => tool['function']['name']).toSet(), {
        'mcp__nai_studio__translation_blocks_read',
        'mcp__nai_studio__translation_blocks_edit',
      });
      await client.close();
      expect(client.isClosed, isTrue);
      await client.whenClosed;
    },
  );

  test(
    'child resume reads official history without a model request or tool replay',
    () async {
      final first = await start('one');
      await first.prompt('原问题');
      final state = await first.state();
      final file = File(state['sessionFile'] as String);
      final history = await file.readAsBytes();
      final id = first.sessionId;
      await first.close();
      final second = await start('one', resume: file);
      expect(second.sessionId, id);
      expect(bodies, hasLength(1));
      expect(await file.readAsBytes(), history);
      expect(
        (second.initialState['messages'] as List).where(
          (m) => m['role'] == 'user',
        ),
        hasLength(1),
      );
      expect((await second.sessions())['sessions'], hasLength(1));
      await second.setSystemPrompt('改后的内置提示词');
      await second.prompt('后续问题');
      expect(jsonEncode(bodies.last), contains('改后的内置提示词'));
    },
  );

  test(
    'Studio gate prevents a Pi request from bypassing another caller; queued abort dispatches nothing',
    () async {
      final cancellation = NaiAgentCancellation();
      final gate = ModelRequestGates.shared.forProvider('cross-caller');
      final release = await gate.acquire(
        limit: 1,
        cancellation: cancellation.whenCancelled,
        isCancelled: () => cancellation.isCancelled,
      );
      final client = await start('one', provider: 'cross-caller');
      final waiting = Completer<void>();
      final subscription = client.events.listen((message) {
        if (message['type'] == 'request_permit' && !waiting.isCompleted) {
          waiting.complete();
        }
      });
      final prompt = client.prompt('等一个请求位置');
      await waiting.future.timeout(const Duration(seconds: 10));
      expect(bodies, isEmpty);
      await client.abort();
      await prompt;
      expect(bodies, isEmpty);
      expect(gate.active, 1);
      release();
      await client.prompt('继续');
      expect(bodies, hasLength(1));
      expect(gate.active, 0);
      await subscription.cancel();
    },
  );

  test(
    'queue can edit, withdraw and steer; attachment bytes survive rebuilding Pi queues',
    () async {
      final entered = Completer<void>(), release = Completer<void>();
      beforeReply = (number, _) async {
        if (number == 1) {
          entered.complete();
          await release.future;
        }
      };
      final client = await start('one');
      final running = client.prompt('先做第一步');
      await entered.future.timeout(const Duration(seconds: 10));
      await client.prompt('不要发', queueId: 'remove');
      await client.prompt(
        '附图',
        queueId: 'image',
        images: [
          {
            'type': 'image',
            'mimeType': 'image/png',
            'data': base64Encode([137, 80, 78, 71, 1, 2]),
          },
        ],
      );
      await client.editQueue('remove', remove: true);
      final edited = await client.editQueue(
        'image',
        text: '改为附图引导',
        steer: true,
      );
      expect((edited['queue'] as List).single['behavior'], 'steer');
      expect((edited['queue'] as List).single['imageCount'], 1);
      release.complete();
      await running;
      expect(bodies, hasLength(2));
      expect(jsonEncode(bodies.last), contains('改为附图引导'));
      expect(
        jsonEncode(bodies.last),
        contains(base64Encode([137, 80, 78, 71, 1, 2])),
      );
      expect(jsonEncode(bodies.last), isNot(contains('不要发')));
      expect((await client.state())['queue'], isEmpty);
    },
  );
}
