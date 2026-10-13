import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/krita/bridge_draft_guard.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';

void main() {
  test(
    'host abort cancels a pending Studio backup; late completion never commits',
    () async {
      final root = await Directory.systemTemp.createTemp('nai-host-cancel-');
      final draft = BridgeDraftSnapshot(fields: {'prompt': 'before'});
      final entered = Completer<void>(), release = Completer<void>();
      var wrote = false;
      final studio = NaiAgentStudioTools(
        workspaceDirectory: root,
        allowsImages: false,
        readDraft: () => draft,
        readSummary: () => {},
        isGenerating: () => false,
        backupDraft: (_) async {
          entered.complete();
          await release.future;
          return 'test-backup';
        },
        writeDraft: (_) {
          wrote = true;
          return ['prompt'];
        },
        readImage: (_) => null,
      );
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var requests = 0;
      final serving = server.listen((request) async {
        await utf8.decoder.bind(request).join();
        requests++;
        request.response.headers.set(
          'content-type',
          'text/event-stream; charset=utf-8',
        );
        final delta = {
          'role': 'assistant',
          'tool_calls': [
            {
              'index': 0,
              'id': 'pending-write',
              'type': 'function',
              'function': {
                'name': 'codemode',
                'arguments': jsonEncode({
                  'code':
                      'text(await tools.mcp__nai_studio__prompt_update(${jsonEncode({
                        "changes": {"prompt": "after"},
                        "expected": draft.fieldVersions,
                      })}));',
                }),
              },
            },
          ],
        };
        request.response.write(
          'data: ${jsonEncode({
            'id': 'local',
            'model': 'test',
            'object': 'chat.completion.chunk',
            'choices': [
              {'index': 0, 'delta': delta, 'finish_reason': 'tool_calls'},
            ],
          })}\n\ndata: [DONE]\n\n',
        );
        await request.response.close();
      });
      PiHostClient? client;
      StreamSubscription<Map<String, dynamic>>? eventsSubscription;
      final events = <Map>[];
      try {
        client = await PiHostClient.start(
          nodeExecutable:
              Platform.environment['NAI_AGENT_NODE'] ?? 'E:/node/node.exe',
          hostScript: File('tool/nai_agent/host.mjs').absolute.path,
          workspaceId: 'cancel-test',
          workspaceDirectory: root,
          agentDirectory: Directory('${root.path}/agent'),
          systemPrompt: 'NAI Agent.',
          privateModelConfig: {
            'providerId': 'test',
            'modelId': 'test',
            'protocol': 'openaiChatCompletions',
            'baseUrl': 'http://127.0.0.1:${server.port}',
            'apiKey': 'synthetic',
            'tools': true,
            'vision': false,
          },
          executeTool: studio.execute,
        );
        eventsSubscription = client.events.listen((envelope) {
          final event = envelope['event'];
          if (event is Map) events.add(event);
        });
        final prompt = client.prompt('write synthetic draft');
        await Future.any<void>([
          entered.future,
          prompt.then((state) {
            throw StateError(
              'Synthetic run ended before backup started: ${jsonEncode({'requests': requests, 'state': state})}',
            );
          }),
        ]).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException(
            'Synthetic backup did not start: ${jsonEncode(events.where((event) => event['type'] == 'message_end').toList())}',
          ),
        );
        await client.abort().timeout(const Duration(seconds: 5));
        release.complete();
        await prompt.timeout(const Duration(seconds: 5));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(wrote, isFalse);
        expect(requests, 1);
        expect(draft.fields['prompt'], 'before');
        expect(
          events.singleWhere(
            (event) => event['type'] == 'agent_settled',
          )['aborted'],
          isTrue,
        );
      } finally {
        await eventsSubscription?.cancel();
        if (!release.isCompleted) release.complete();
        await client?.close();
        await serving.cancel();
        await server.close(force: true);
        await root.delete(recursive: true);
      }
    },
  );
}
