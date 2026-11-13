import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';

import '../../../helpers/agent_test_node.dart';
import '../../../helpers/fetch_test_server.dart';

void main() {
  for (final scenario in ['buffered', 'empty', 'stop']) {
    test('real host exposes $scenario correctly and can send again', () async {
      final root = await Directory.systemTemp.createTemp('agent-failure-');
      final server = await bindFetchTestServer();
      final entered = Completer<void>();
      var requests = 0;
      server.listen((request) async {
        await utf8.decoder.bind(request).join();
        requests++;
        request.response.headers.set('content-type', 'text/event-stream');
        if (requests == 1 && scenario == 'stop') {
          await request.response.flush();
          entered.complete();
          return;
        }
        if (requests == 1 && scenario == 'buffered') {
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }
        request.response.write(
          'data: ${jsonEncode({
            'choices': [
              {
                'delta': {'content': requests == 1 && scenario == 'empty' ? '' : 'Recovered'},
                'finish_reason': 'stop',
              },
            ],
          })}\n\ndata: [DONE]\n\n',
        );
        await request.response.close();
      });
      final controller = NaiAgentWorkspaceController(
        store: AgentWorkspaceStore(root),
        initialWorkspaceName: 'Synthetic',
        initialChatName: 'Synthetic',
        startClient: (workspace, chat, settings, prompt, resume) =>
            PiHostClient.start(
              nodeExecutable: agentTestNode,
              hostScript: File('tool/nai_agent/host.mjs').absolute.path,
              workspaceId: workspace.id,
              workspaceDirectory: workspace.directory,
              agentDirectory: workspace.agentDirectory,
              sessionDirectory: workspace.sessions,
              sessionFile: resume,
              systemPrompt: prompt,
              privateModelConfig: {
                'providerId': 'synthetic',
                'modelId': 'test',
                'protocol': 'openaiChatCompletions',
                'baseUrl': 'http://127.0.0.1:${server.port}',
                'tools': true,
                'timeoutSeconds': .1,
                'cacheWarming': 'off',
                'nextSuggestion': false,
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
      final run = controller.sendText('Synthetic test');
      if (scenario == 'stop') {
        await entered.future.timeout(const Duration(seconds: 10));
        await controller.stop();
      }
      await run;
      final runtime = controller.selected!;
      expect(runtime.running, false);
      if (scenario == 'stop') {
        expect(runtime.error, isNull);
        expect(runtime.messages.last['stopReason'], 'aborted');
      } else if (scenario == 'empty') {
        expect(runtime.error, currentL10n.naiAgent_emptyResponse);
        expect(runtime.messages.last['stopReason'], 'error');
      } else {
        expect(runtime.error, isNull);
        expect(runtime.messages.last['stopReason'], 'stop');
      }
      await controller.sendText('Retry');
      expect(controller.selected!.error, isNull);
      expect(controller.selected!.messages.last['stopReason'], 'stop');
      expect(requests, 2);
    }, timeout: const Timeout(Duration(seconds: 30)));
  }
}
