import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';

class _DelayedStore extends AgentWorkspaceStore {
  _DelayedStore() : super(Directory.systemTemp);
  final result = Completer<AgentSettings>();
  @override
  Future<AgentSettings> readSettings() => result.future;
}

void main() {
  test(
    'same settings skip UI notifications but still supersede a pending load',
    () async {
      final preferences = NaiAgentUiPreferences();
      final store = _DelayedStore();
      var notices = 0;
      preferences.addListener(() => notices++);
      final pending = preferences.load(store);
      for (var i = 0; i < 300; i++) {
        preferences.replace(preferences.settings);
      }
      expect(notices, 0);
      store.result.complete(const AgentSettings(panelExpanded: true));
      await pending;
      expect(preferences.settings.panelExpanded, false);
      preferences.replace(const AgentSettings(panelExpanded: true));
      expect(notices, 1);
      preferences.dispose();
    },
  );

  test(
    'real host coalesces thinking notifications and publishes final content immediately',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'agent-stream-notification-',
      );
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        await utf8.decoder.bind(request).join();
        request.response.headers.set(
          'content-type',
          'text/event-stream; charset=utf-8',
        );
        for (var i = 0; i < 120; i++) {
          request.response.write(
            'data: ${jsonEncode({
              'id': 'test',
              'object': 'chat.completion.chunk',
              'model': 'test',
              'choices': [
                {
                  'index': 0,
                  'delta': {'reasoning_content': '合成思考$i。'},
                  'finish_reason': null,
                },
              ],
            })}\n\n',
          );
          await request.response.flush();
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        request.response.write(
          'data: ${jsonEncode({
            'id': 'test',
            'object': 'chat.completion.chunk',
            'model': 'test',
            'choices': [
              {
                'index': 0,
                'delta': {'content': '完成'},
                'finish_reason': 'stop',
              },
            ],
          })}\n\ndata: [DONE]\n\n',
        );
        await request.response.close();
      });
      final controller = NaiAgentWorkspaceController(
        store: AgentWorkspaceStore(root),
        initialWorkspaceName: 'Synthetic workspace',
        initialChatName: 'Synthetic chat',
        startClient: (workspace, chat, settings, prompt, resume) =>
            PiHostClient.start(
              nodeExecutable: 'E:/node/node.exe',
              hostScript: File('tool/nai_agent/host.mjs').absolute.path,
              workspaceId: workspace.id,
              workspaceDirectory: workspace.directory,
              agentDirectory: workspace.agentDirectory,
              sessionDirectory: workspace.sessions,
              sessionFile: resume,
              sessionName: chat.title,
              systemPrompt: prompt,
              privateModelConfig: {
                'providerId': 'synthetic',
                'modelId': 'test',
                'protocol': 'openaiChatCompletions',
                'baseUrl': 'http://127.0.0.1:${server.port}',
                'tools': true,
                'reasoning': true,
                'nextSuggestion': false,
                'cacheWarming': 'off',
              },
              executeTool: (_, _, _) async => {'content': []},
            ),
      );
      addTearDown(() async {
        await controller.close();
        controller.dispose();
        await server.close(force: true);
        await root.delete(recursive: true);
      });
      await controller.initialize();
      var notifications = 0;
      controller.addListener(() => notifications++);
      await controller.sendText('Synthetic stream only');
      final runtime = controller.selected!;
      final thinking = runtime.messages
          .expand(
            (message) => message['content'] is List
                ? message['content'] as List
                : const [],
          )
          .whereType<Map>()
          .where((part) => part['type'] == 'thinking')
          .single['thinking'];
      expect(thinking, List.generate(120, (i) => '合成思考$i。').join());
      expect(runtime.running, false);
      expect(
        notifications,
        lessThan(70),
        reason: '120 deltas must not each notify the UI',
      );
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}
