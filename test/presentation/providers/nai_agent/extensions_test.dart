import '../../../helpers/fetch_test_server.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_questions.dart';

void main() {
  late Directory root;
  setUp(
    () async => root = await Directory.systemTemp.createTemp('nai-extensions-'),
  );
  tearDown(() => root.delete(recursive: true));

  test(
    'selected extension state persists, merges concurrent settings, and removal keeps source files',
    () async {
      final store = AgentWorkspaceStore(root);
      final a = await File(
        '${root.path}/a.ts',
      ).writeAsString('export default () => {};');
      final b = await File(
        '${root.path}/b.js',
      ).writeAsString('export default () => {};');
      await Future.wait([
        store.configureExtension(a.path),
        store.configureExtension(b.path),
        store.patchSettings({'enterToSend': false}),
      ]);
      final saved = await store.readSettings();
      expect(saved.enabledExtensionPaths, [
        p.normalize(a.path),
        p.normalize(b.path),
      ]);
      expect(saved.enterToSend, false);
      await store.configureExtension(a.path, enabled: false);
      final reopened = await AgentWorkspaceStore(root).readSettings();
      expect(reopened.enabledExtensionPaths, [p.normalize(b.path)]);
      expect(reopened.extensionSignature, isNot(saved.extensionSignature));
      await a.delete();
      await store.configureExtension(a.path, remove: true);
      await store.configureExtension(b.path, remove: true);
      expect(await b.exists(), true);
      expect((await store.readSettings()).extensions, isEmpty);
      expect(AgentSettings.fromJson({}).extensions, isEmpty);
    },
  );

  test(
    'only explicit extension files or directories can be added, and duplicate imports keep state',
    () async {
      final store = AgentWorkspaceStore(root);
      await expectLater(
        store.configureExtension('relative.ts'),
        throwsFormatException,
      );
      final wrong = await File(
        '${root.path}/image.png',
      ).writeAsString('not code');
      await expectLater(
        store.configureExtension(wrong.path),
        throwsFormatException,
      );
      await expectLater(
        store.configureExtension('${root.path}/missing.ts'),
        throwsFormatException,
      );
      final package = await Directory('${root.path}/package').create();
      await store.configureExtension(package.path, enabled: false);
      await store.configureExtension(package.path);
      expect((await store.readSettings()).extensions, hasLength(1));
      expect((await store.readSettings()).enabledExtensionPaths, isEmpty);
    },
  );

  test(
    'standard select accepts only actual options; editor preserves prefill and whitespace',
    () async {
      final broker = NaiAgentQuestions();
      addTearDown(broker.dispose);
      final pending = broker.askExtensionUi('w', 'a', {
        'method': 'select',
        'title': 'Choose',
        'options': List.generate(16, (i) => 'Option $i'),
      }, NaiAgentCancellation());
      final request = broker.forChat('a').single;
      expect(broker.forChat('b'), isEmpty);
      broker.answer(request.id, {'value': 'invented'});
      expect(broker.forChat('a'), hasLength(1));
      broker.answer(request.id, {'value': 'Option 15'});
      expect((await pending)['details'], {
        'status': 'answered',
        'value': 'Option 15',
      });
      final editing = broker.askExtensionUi('w', 'a', {
        'method': 'editor',
        'title': 'Edit',
        'prefill': '  original\n',
      }, NaiAgentCancellation());
      final editor = broker.forChat('a').single;
      expect(editor.questions.single.prefill, '  original\n');
      expect(editor.questions.single.multiline, true);
      broker.answer(editor.id, {'value': '\n  changed\n'});
      expect((await editing)['details'], {
        'status': 'answered',
        'value': '\n  changed\n',
      });
      broker.answer(editor.id, {'value': 'late'});
      expect(broker.forChat('a'), isEmpty);
    },
  );

  test(
    'standard confirm, empty input and dialog cancellation have distinct replies',
    () async {
      final broker = NaiAgentQuestions();
      addTearDown(broker.dispose);
      final confirm = broker.askExtensionUi('w', 'c', {
        'method': 'confirm',
        'title': 'Confirm',
        'message': 'Continue?',
      }, NaiAgentCancellation());
      final card = broker.forChat('c').single;
      expect(card.questions.single.allowCustom, false);
      broker.answer(card.id, {'value': card.questions.single.options.first});
      expect((await confirm)['details'], {'status': 'answered', 'value': true});
      final input = broker.askExtensionUi('w', 'c', {
        'method': 'input',
        'title': 'Text',
      }, NaiAgentCancellation());
      broker.answer(broker.forChat('c').single.id, {'value': ''});
      expect((await input)['details'], {'status': 'answered', 'value': ''});
      final cancelled = broker.askExtensionUi('w', 'c', {
        'method': 'input',
        'title': 'Text',
      }, NaiAgentCancellation());
      broker.cancel(broker.forChat('c').single.id);
      expect((await cancelled)['details'], {'status': 'cancelled'});
    },
  );

  test(
    'real host startup dialog does not delay ready; Stop retires pending prompt before any model request',
    () async {
      final broker = NaiAgentQuestions();
      final server = await bindFetchTestServer();
      var requests = 0;
      final serving = server.listen((request) async {
        await utf8.decoder.bind(request).join();
        requests++;
        request.response.headers.set('content-type', 'text/event-stream');
        request.response.write(
          'data: ${jsonEncode({
            'id': 'test',
            'object': 'chat.completion.chunk',
            'model': 'test',
            'choices': [
              {
                'index': 0,
                'delta': {'role': 'assistant', 'content': 'done'},
                'finish_reason': 'stop',
              },
            ],
          })}\n\ndata: [DONE]\n\n',
        );
        await request.response.close();
      });
      final extension = await File('${root.path}/startup.ts').writeAsString('''
      export default pi => pi.on('session_start', async (_event,ctx) => {
        console.log('extension diagnostic'); ctx.ui.notify('startup notice');
        await ctx.ui.input('Startup question');
      });
    ''');
      final asked = Completer<void>();
      PiHostClient? client;
      try {
        client =
            await PiHostClient.start(
              nodeExecutable: 'E:/node/node.exe',
              hostScript: File('tool/nai_agent/host.mjs').absolute.path,
              workspaceId: 'w',
              workspaceDirectory: root,
              agentDirectory: Directory('${root.path}/.agent'),
              systemPrompt: 'NAI.',
              extensionPaths: [extension.path],
              privateModelConfig: {
                'providerId': 'extension-test',
                'modelId': 'test',
                'protocol': 'openaiChatCompletions',
                'baseUrl': 'http://127.0.0.1:${server.port}',
                'tools': true,
              },
              executeTool: (name, params, token) {
                expect(name, '_nai_extension_ui');
                if (!asked.isCompleted) asked.complete();
                return broker.askExtensionUi('w', 'c', params, token);
              },
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () =>
                  throw TimeoutException('host startup did not become ready'),
            );
        final notification = client.events.firstWhere(
          (event) => event['type'] == 'extension_ui',
        );
        await asked.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () =>
              throw TimeoutException('startup question not delivered'),
        );
        expect(
          (await notification.timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('startup notification not delivered'),
          ))['message'],
          'startup notice',
        );
        expect(broker.forChat('c'), hasLength(1));
        final pending = client.prompt('must not start');
        final stopped = expectLater(pending, throwsA(isA<NaiAgentToolError>()));
        await client.abort();
        await stopped;
        expect(broker.forChat('c'), isEmpty);
        expect(requests, 0);
        await client
            .prompt('continue')
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () =>
                  throw TimeoutException('continued prompt did not finish'),
            );
        expect(requests, 1);
      } finally {
        await client?.close();
        broker.dispose();
        await serving.cancel();
        await server.close(force: true);
      }
    },
  );
}
