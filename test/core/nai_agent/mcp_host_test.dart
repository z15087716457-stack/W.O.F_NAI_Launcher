import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/krita/bridge_draft_guard.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';

void main() {
  test(
    'official CodeMode reaches actual Dart backup and version guards through the private host',
    () async {
      final root = await Directory.systemTemp.createTemp('nai-mcp-host-');
      var draft = BridgeDraftSnapshot(fields: {'prompt': 'before'});
      var backups = 0;
      final studio = NaiAgentStudioTools(
        workspaceDirectory: root,
        allowsImages: false,
        readDraft: () => draft,
        readSummary: () => {},
        isGenerating: () => false,
        readImage: (_) => null,
        backupDraft: (before) async {
          final file = File('${root.path}/backup-${++backups}.json');
          await file.writeAsString(jsonEncode(before.toJson()));
          return file.path;
        },
        writeDraft: (changes) {
          draft = BridgeDraftSnapshot(fields: {...draft.fields, ...changes});
          return changes.keys.toList();
        },
      );
      final requests = <Map<String, dynamic>>[];
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final serving = server.listen((request) async {
        requests.add(
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>,
        );
        request.response.headers.set('content-type', 'text/event-stream');
        final delta = requests.length == 1
            ? {
                'role': 'assistant',
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'script',
                    'type': 'function',
                    'function': {
                      'name': 'codemode',
                      'arguments': jsonEncode({
                        'code': '''
            const state=JSON.parse(await tools.studio_context({scope:"draft"}));
            const result=await tools.mcp__nai_studio__prompt_update({changes:{prompt:"after"},expected:state.draft.field_versions});
            text(result.structuredContent);
            const stale=await tools.mcp__nai_studio__prompt_update({changes:{prompt:"stale"},expected:state.draft.field_versions});
            text({stale:stale.isError});
          ''',
                      }),
                    },
                  },
                ],
              }
            : {'content': 'Completed.'};
        request.response.write(
          'data: ${jsonEncode({
            'id': 'synthetic',
            'object': 'chat.completion.chunk',
            'choices': [
              {'index': 0, 'delta': delta, 'finish_reason': requests.length == 1 ? 'tool_calls' : 'stop'},
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
          workspaceId: 'mcp-test',
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
          },
          executeTool: studio.execute,
        );
        eventsSubscription = client.events.listen((envelope) {
          final event = envelope['event'];
          if (event is Map) events.add(event);
        });
        final status = await client.mcpCommand('status');
        expect(status['mcpStatus'], contains('nai_studio'));
        expect(requests, isEmpty);
        final completedState = await client
            .prompt('perform synthetic test')
            .timeout(const Duration(seconds: 20));
        expect(
          requests,
          hasLength(2),
          reason: jsonEncode({
            'state': completedState,
            'events': events
                .where((event) => event['type'] == 'message_end')
                .toList(),
          }),
        );
        expect(draft.fields['prompt'], 'after');
        expect(backups, 1);
        final backup = jsonDecode(
          await File('${root.path}/backup-1.json').readAsString(),
        );
        expect(backup['fields']['prompt'], 'before');
        final declared = (requests.first['tools'] as List)
            .map((tool) => tool['function']['name'])
            .toSet();
        expect(declared, {
          'read',
          'write',
          'edit',
          'bash',
          'studio_context',
          'codemode',
        });
        expect(jsonEncode(requests.last), contains('stale'));
        expect(jsonEncode(requests.last), contains('true'));
        expect(
          events.singleWhere(
            (event) => event['type'] == 'agent_settled',
          )['aborted'],
          isFalse,
        );
        final completed = events.firstWhere(
          (event) =>
              event['type'] == 'tool_execution_end' &&
              event['toolName'] == 'codemode',
        );
        expect(completed['durationMs'], isNonNegative);
      } finally {
        await eventsSubscription?.cancel();
        await client?.close();
        await serving.cancel();
        await server.close(force: true);
        await root.delete(recursive: true);
      }
    },
  );
}
