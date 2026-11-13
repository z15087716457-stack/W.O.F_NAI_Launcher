import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/krita/bridge_draft_guard.dart';
import 'package:nai_launcher/core/krita/krita_bridge_server.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/prompt_set_tools.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';
import 'package:nai_launcher/core/nai_agent/vision_access.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_external_bridge.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_questions.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_skills_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_window_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_resources.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_thread_mapper.dart';
import '../../../core/nai_agent/prompt_set_tools_test.dart' show promptSetInput;
import '../../../helpers/agent_test_node.dart';

extension _Next<T> on StreamIterator<T> {
  Future<T> get next async {
    if (!await moveNext()) throw StateError('Connection closed');
    return current;
  }
}

void main() {
  late Directory root;
  late AgentWorkspaceStore store;
  late NaiAgentWorkspaceController controller;
  late ProviderContainer container;
  late KritaBridgeServer server;
  late NaiAgentExternalBridge gateway;
  late WebSocket socket;
  late StreamIterator<dynamic> responses;
  late StreamSubscription requests, disconnects;
  late String sessionId;
  var sequence = 0, opens = 0, executed = 0;
  var containerDisposed = false;
  Future<Map<String, dynamic>> Function(
    Map<String, dynamic>,
    NaiAgentCancellation,
  )?
  slow;
  Future<Map<String, dynamic>> request(
    String operation, [
    Map<String, dynamic> args = const {},
  ]) async {
    final id = 'request-${sequence++}';
    socket.add(
      jsonEncode({
        'type': 'agent_request',
        'id': id,
        'payload': {
          'operation': operation,
          if (operation != 'session') 'session_id': sessionId,
          ...args,
        },
      }),
    );
    final value =
        jsonDecode(
              await responses.next.timeout(const Duration(seconds: 15))
                  as String,
            )
            as Map<String, dynamic>;
    expect(value['id'], id);
    return value;
  }

  AgentChatRuntime getRuntime() =>
      controller.heldRuntimes.firstWhere((r) => r.chat.id == sessionId);
  Future<void> until(bool Function() condition) async {
    for (var i = 0; i < 400 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(condition(), isTrue);
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('external-studio-');
    containerDisposed = false;
    store = AgentWorkspaceStore(Directory('${root.path}/data'));
    opens = executed = 0;
    sequence = 0;
    slow = null;
    controller = NaiAgentWorkspaceController(
      store: store,
      initialWorkspaceName: 'Test',
      initialChatName: 'Chat',
      startClient: (a, b, c, d, e) async =>
          throw StateError('External sessions must never start Pi'),
    );
    controller.ready = controller.initialize(restoreHistory: false);
    await controller.ready;
    final skill = Directory('${root.path}/skill')..createSync();
    File('${skill.path}/SKILL.md').writeAsStringSync('Enabled skill');
    File('${skill.path}/reference.md').writeAsStringSync('Reference text');
    server = KritaBridgeServer(
      discoveryDirectory: Directory('${root.path}/bridge'),
    )..agentToolsEnabled = true;
    await server.start(preferredPort: 0);
    container = ProviderContainer(
      overrides: [
        naiAgentControllerProvider.overrideWith((ref) => controller),
        naiAgentWindowControllerProvider.overrideWith(
          (ref) => NaiAgentWindowController(
            host: null,
            readSettings: store.readSettings,
            saveExpanded: (expanded) async {
              opens += expanded ? 1 : 0;
              controller.settings = await store.patchSettings({
                'panelExpanded': expanded,
              });
            },
          ),
        ),
        naiAgentSkillsProvider.overrideWith(
          (ref, id) async => NaiAgentSkillInventory(
            [
              NaiAgentSkill(
                key: 'builtin/test',
                name: 'test',
                source: 'builtin',
                state: 'active',
                directory: skill.path,
                file: '${skill.path}/SKILL.md',
              ),
              NaiAgentSkill(
                key: 'global/off',
                name: 'off',
                source: 'global',
                state: 'disabled',
                enabled: false,
                directory: skill.path,
              ),
            ],
            0,
            {},
          ),
        ),
        naiAgentStudioFactoryProvider.overrideWithValue(
          (
            workspace,
            data,
            allowsImages, {
            visionAccess = const NaiAgentVisionAccess(),
            owner,
          }) => NaiAgentStudioTools(
            workspaceDirectory: workspace,
            allowsImages: allowsImages,
            readDraft: () =>
                BridgeDraftSnapshot(fields: {'prompt': 'original'}),
            readSummary: (_) => {'native': true},
            isGenerating: () => false,
            backupDraft: (_) async => 'backup',
            writeDraft: (_) => [],
            readImage: (_) => null,
            domainTools: {
              'prompt_set': (args, token) {
                executed++;
                return NaiAgentPromptSets(
                  data,
                  chatId: owner?.chatId,
                ).execute(args, token);
              },
              'settings_update': (args, token) async {
                executed++;
                return slow == null
                    ? naiAgentTextResult({'ok': true})
                    : slow!(args, token);
              },
              'generation_run': (args, token) async {
                executed++;
                return naiAgentTextResult({
                  'owner': owner?.chatId,
                  'requires_native_confirmation': true,
                });
              },
            },
          ),
        ),
      ],
    );
    final provider = Provider((ref) => NaiAgentExternalBridge(ref, server));
    gateway = container.read(provider);
    requests = server.requests.listen(
      (r) => unawaited(server.inClientScope(r, () => gateway.handle(r))),
    );
    disconnects = server.disconnections.listen(gateway.disconnected);
    socket = await WebSocket.connect('ws://127.0.0.1:${server.port}/krita');
    responses = StreamIterator(socket);
    socket.add(
      jsonEncode({
        'type': 'ping',
        'version': 1,
        'secret': server.secret,
        'client': {'kind': 'agent', 'name': 'Codex'},
      }),
    );
    final pong = jsonDecode(await responses.next as String) as Map;
    expect(pong['capabilities'], contains('agent_tools_v1'));
    final opened = await request('session', {'summary': 'Create a storyboard'});
    sessionId = (opened['result'] as Map)['session_id'] as String;
  });
  tearDown(() async {
    gateway.close();
    await socket.close();
    await responses.cancel();
    await requests.cancel();
    await disconnects.cancel();
    await server.dispose();
    await controller.close();
    if (!containerDisposed) container.dispose();
    await root.delete(recursive: true);
  });
  test(
    'external cold start does not launch a configured internal MCP host',
    () async {
      await store.patchSettings({
        'providerId': 'test',
        'modelId': 'test',
        'mcpServers': [
          {
            'name': 'synthetic',
            'configId': 'synthetic',
            'transport': 'stdio',
            'enabled': true,
          },
        ],
      });
      var starts = 0;
      final cold = NaiAgentWorkspaceController(
        store: store,
        initialWorkspaceName: 'Test',
        initialChatName: 'Chat',
        startClient: (a, b, c, d, e) async {
          starts++;
          throw StateError('Unexpected host');
        },
      );
      cold.ready = cold.initialize(restoreHistory: false, connectMcp: false);
      await cold.ready;
      expect(starts, 0);
      expect(cold.selected!.error, isNull);
      await cold.close();
      cold.dispose();
    },
  );
  test(
    'closing an attached bridge after Provider disposal uses its existing owner',
    () async {
      container.dispose();
      containerDisposed = true;
      expect(gateway.close, returnsNormally);
    },
  );
  test(
    'reads are quiet; sessions never start a model or replace the internal draft',
    () async {
      final previous = controller.selected!;
      previous.composer = const AgentComposerState(text: 'User draft');
      final response = await request('call', {
        'name': 'studio_context',
        'arguments': {},
      });
      expect(response['result']['details']['native'], isTrue);
      expect(controller.selected, same(previous));
      expect(previous.composer.text, 'User draft');
      expect(opens, 0);
      expect(getRuntime().client, isNull);
    },
  );
  test(
    'native prompt-set cards persist, map and reveal once; manual close stays closed',
    () async {
      final response = await request('call', {
        'name': 'prompt_set',
        'arguments': promptSetInput(),
      });
      expect(response['result']['isError'], isNot(true));
      expect(executed, 1);
      final runtime = getRuntime();
      expect(controller.selected, same(runtime));
      expect(opens, 1);
      final resources = AgentResources(() {});
      final mapped = AgentThreadMapper(resources).map(runtime);
      expect(
        mapped.turns.single.reply!.blocks.whereType<AgentPromptSetBlock>(),
        hasLength(1),
      );
      expect(mapped.turns.single.user.entryId, isNull);
      await resources.settle();
      resources.dispose();
      await container.read(naiAgentWindowControllerProvider).close();
      await request('call', {
        'name': 'prompt_set',
        'arguments': promptSetInput(),
      });
      expect(opens, 1);
      expect(runtime.external!.unread, isTrue);
      expect(runtime.external!.notice!.title, 'Rain');
      final notice = runtime.external!.notice;
      await request('call', {'name': 'studio_context', 'arguments': {}});
      expect(runtime.external!.notice, same(notice));
      final saved = await store.readExternalChat(
        runtime.workspace.id,
        runtime.chat.id,
      );
      expect(saved['calls'], hasLength(3));
      expect(
        (await store.listChats(
          runtime.workspace.id,
        )).firstWhere((c) => c.id == sessionId).externalClient,
        'Codex',
      );
    },
  );
  test(
    'a meaningful write keeps a typed internal draft selected and marks external unread',
    () async {
      final previous = controller.selected!;
      previous.composer = const AgentComposerState(text: 'Keep this');
      await request('call', {
        'name': 'prompt_set',
        'arguments': promptSetInput(),
      });
      expect(controller.selected, same(previous));
      expect(opens, 0);
      expect(getRuntime().external!.unread, isTrue);
      expect(previous.composer.text, 'Keep this');
      await controller.showExternal(getRuntime());
      await controller.selectChat(previous.chat.id);
      expect(controller.selected!.composer.text, 'Keep this');
      expect(controller.selected!.chat.isDraft, isFalse);
    },
  );
  test(
    'readonly blocks writes and paid run before the business executor',
    () async {
      await store.patchSettings({'permissionMode': 'readonly'});
      for (final name in ['prompt_set', 'generation_run']) {
        final value = await request('call', {
          'name': name,
          'arguments': promptSetInput(),
        });
        expect(value['result']['isError'], isTrue);
        expect(value['result']['details']['code'], 'readonly');
      }
      expect(executed, 0);
      expect(opens, 0);
    },
  );
  test(
    'ask mode uses the native question gate, denial never executes',
    () async {
      await store.patchSettings({'permissionMode': 'ask'});
      final result = request('call', {
        'name': 'settings_update',
        'arguments': {
          'changes': {'x': 1},
        },
      });
      final questions = container.read(naiAgentQuestionsProvider);
      await until(() => questions.forChat(sessionId).isNotEmpty);
      final gate = questions.forChat(sessionId).single;
      expect(gate.kind, 'tool_approval');
      questions.answer(gate.id, {
        'approve': gate.questions.single.options.last,
      });
      expect((await result)['result']['isError'], isTrue);
      expect(executed, 0);
    },
  );
  test(
    'permission changes during a native approval invalidate the pending write',
    () async {
      await store.patchSettings({'permissionMode': 'ask'});
      final result = request('call', {
        'name': 'settings_update',
        'arguments': {},
      });
      final questions = container.read(naiAgentQuestionsProvider);
      await until(() => questions.forChat(sessionId).isNotEmpty);
      final gate = questions.forChat(sessionId).single;
      await store.patchSettings({'permissionMode': 'readonly'});
      questions.answer(gate.id, {
        'approve': gate.questions.single.options.first,
      });
      expect(
        (await result)['result']['details']['code'],
        'permissions_changed',
      );
      expect(executed, 0);
    },
  );
  test(
    'only active enabled skills and their relative references are exposed',
    () async {
      final skills = await request('skills');
      expect(skills['result']['skills'], hasLength(1));
      final read = await request('skill_read', {
        'key': 'builtin/test',
        'path': 'reference.md',
      });
      expect(read['result']['text'], 'Reference text');
      final disabled = await request('skill_read', {'key': 'global/off'});
      expect(disabled['code'], 'skill_missing');
      File('${root.path}/private.txt').writeAsStringSync('Private');
      final outside = await request('skill_read', {
        'key': 'builtin/test',
        'path': '../private.txt',
      });
      expect(outside['code'], 'invalid_path');
    },
  );
  test(
    'end cancels pending calls, records failure and preserves the artifact log',
    () async {
      slow = (args, token) async {
        await token.whenCancelled;
        token.check();
        return {};
      };
      final result = request('call', {
        'name': 'settings_update',
        'arguments': {},
      });
      await until(() => executed == 1);
      await controller.stop();
      final response = await result;
      expect(response['result']['details']['code'], 'cancelled');
      await request('end');
      expect(getRuntime().external!.connected, isFalse);
      expect(getRuntime().external!.calls.single.result, isNotNull);
      expect(
        (await request('call', {
          'name': 'studio_context',
          'arguments': {},
        }))['code'],
        'session_missing',
      );
    },
  );
  test(
    'disconnect cancels work and retains the selected external history',
    () async {
      slow = (args, token) async {
        await token.whenCancelled;
        token.check();
        return {};
      };
      final result = request('call', {
        'name': 'settings_update',
        'arguments': {},
      });
      await until(() => executed == 1);
      final disconnected = expectLater(result, throwsA(anything));
      await socket.close();
      await until(
        () => !getRuntime().external!.connected && !getRuntime().running,
      );
      await disconnected;
      expect(
        getRuntime().external!.calls.single.result!['details']['code'],
        'cancelled',
      );
    },
  );
  test(
    'disabled business group rejects calls but still allows session end',
    () async {
      await store.patchSettings({'studioMcpEnabled': false});
      expect(
        (await request('call', {
          'name': 'studio_context',
          'arguments': {},
        }))['code'],
        'disabled',
      );
      expect((await request('end'))['result']['connected'], isFalse);
    },
  );
  test(
    'external clients cannot use host shell tools or internal conversations',
    () async {
      expect(
        (await request('call', {
          'name': 'bash',
          'arguments': {'command': 'noop'},
        }))['code'],
        'unknown_tool',
      );
      final internal = await store.createChat(
        controller.selectedWorkspace!.id,
        'Internal',
      );
      final value = await request('session', {'session_id': internal.id});
      expect(value['code'], 'session_missing');
    },
  );
  test(
    'records restore into the same external conversation after reopening the controller',
    () async {
      await request('call', {
        'name': 'prompt_set',
        'arguments': promptSetInput(),
      });
      await request('end');
      final workspace = controller.selectedWorkspace!;
      final restored = NaiAgentWorkspaceController(
        store: store,
        initialWorkspaceName: 'Test',
        initialChatName: 'Chat',
        startClient: (a, b, c, d, e) async =>
            throw StateError('No Pi for external history'),
      );
      restored.ready = restored.initialize(restoreHistory: false);
      await restored.ready;
      try {
        final runtime = await restored.openExternal(
          workspaceId: workspace.id,
          client: 'Codex',
          sessionId: sessionId,
        );
        expect(runtime.external!.calls.single.result!['isError'], isNot(true));
        await restored.showExternal(runtime);
        await restored.loadHistory();
        expect(restored.selected!.displayMessages, hasLength(3));
        expect(restored.selected!.client, isNull);
        final trash = await restored.deleteChat(sessionId);
        expect(
          (await store.listChats(workspace.id)).any((c) => c.id == sessionId),
          isFalse,
        );
        await restored.undoDeleteChat(trash);
        expect(
          (await store.readExternalChat(workspace.id, sessionId))['calls'],
          hasLength(1),
        );
      } finally {
        await restored.close();
        restored.dispose();
      }
    },
  );
  test(
    'CLI tools reuse the persisted logical session without credentials',
    () async {
      final sessionFile = File('${root.path}/cli-session.json');
      final arguments = File('${root.path}/arguments.json')
        ..writeAsStringSync(jsonEncode(promptSetInput()));
      String? previous;
      for (final name in ['studio_context', 'prompt_set']) {
        final result = await Process.run(agentTestNode, [
          File('tool/nai_agent/external-mcp.mjs').absolute.path,
          '--client',
          'CLI tools',
          '--discovery',
          server.discoveryFile.path,
          '--session-file',
          sessionFile.path,
          '--summary',
          'CLI task',
          '--call',
          name,
          if (name == 'prompt_set') ...['--args', arguments.path],
        ]);
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stderr, isEmpty);
        expect(
          (jsonDecode(result.stdout as String) as Map)['isError'],
          isNot(true),
        );
        final session = jsonDecode(sessionFile.readAsStringSync()) as Map;
        expect(
          session.keys,
          unorderedEquals(['session_id', 'workspace_id', 'client']),
        );
        expect(sessionFile.readAsStringSync(), isNot(contains(server.secret)));
        if (previous != null) expect(session['session_id'], previous);
        previous = session['session_id'] as String;
      }
      final runtime = controller.heldRuntimes.firstWhere(
        (r) => r.chat.id == previous,
      );
      expect(runtime.external!.calls, hasLength(2));
      expect(runtime.client, isNull);
    },
  );
  test(
    'closing during execution reports the completed result without reopening',
    () async {
      final complete = Completer<void>();
      slow = (args, token) async {
        await complete.future;
        token.check();
        return naiAgentTextResult({'ok': true});
      };
      final response = request('call', {
        'name': 'settings_update',
        'arguments': {},
      });
      await until(() => executed == 1);
      final runtime = getRuntime();
      expect(runtime.external!.unread, isFalse);
      await container.read(naiAgentWindowControllerProvider).close();
      complete.complete();
      await response;
      expect(opens, 1);
      expect(controller.settings.panelExpanded, isFalse);
      expect(runtime.external!.unread, isTrue);
      expect(runtime.external!.notice!.isError, isFalse);
      expect(runtime.external!.notice!.title, isNull);
    },
  );
  test(
    'permission failures notify with an error and cancelled work does not claim an update',
    () async {
      await store.patchSettings({'permissionMode': 'readonly'});
      await request('call', {'name': 'settings_update', 'arguments': {}});
      final runtime = getRuntime();
      expect(runtime.external!.notice!.isError, isTrue);
      await controller.showExternal(runtime);
      await store.patchSettings({'permissionMode': 'auto'});
      slow = (args, token) async {
        await token.whenCancelled;
        token.check();
        return {};
      };
      final response = request('call', {
        'name': 'settings_update',
        'arguments': {},
      });
      await until(() => executed == 1);
      await controller.stop();
      await response;
      expect(runtime.external!.notice, isNull);
    },
  );
  test(
    'native paid cancellation and partial failures keep their actual outcome',
    () async {
      controller.selected!.composer = const AgentComposerState(
        text: 'Keep input',
      );
      for (final details in [
        {'status': 'cancelled'},
        {'ok': false, 'cancelled': true},
        {
          'ok': false,
          'error': 'native_gallery_failed',
          'applied_fields': ['favorite'],
        },
      ]) {
        slow = (args, token) async => naiAgentTextResult(details);
        final response = await request('call', {
          'name': 'settings_update',
          'arguments': {},
        });
        expect(response['result']['isError'], isNot(true));
        if (details['error'] != null) {
          expect(getRuntime().external!.notice!.isError, isTrue);
        } else {
          expect(getRuntime().external!.notice, isNull);
          expect(getRuntime().external!.unread, isFalse);
        }
      }
    },
  );
  test(
    'real stdio MCP reaches authenticated native card persistence without Pi',
    () async {
      final process = await Process.start(agentTestNode, [
        File('tool/nai_agent/external-mcp.mjs').absolute.path,
        '--client',
        'CLI test',
        '--discovery',
        server.discoveryFile.path,
      ]);
      final lines = StreamIterator(
        process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
      );
      final errors = process.stderr.transform(utf8.decoder).join();
      Future<Map> rpc(int id, String method, [Map args = const {}]) async {
        process.stdin.writeln(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': id,
            'method': method,
            'params': args,
          }),
        );
        return jsonDecode(await lines.next.timeout(const Duration(seconds: 20)))
            as Map;
      }

      try {
        final init = await rpc(1, 'initialize');
        expect(init['result']['capabilities']['tools'], isNotNull);
        final list = await rpc(2, 'tools/list');
        expect(list['result']['tools'], hasLength(26));
        final card = await rpc(3, 'tools/call', {
          'name': 'prompt_set',
          'arguments': promptSetInput(),
        });
        expect(card['result']['isError'], isNot(true));
        expect(card['result']['details']['set_id'], isNotEmpty);
        final external = controller.heldRuntimes.firstWhere(
          (r) => r.chat.externalClient == 'CLI test',
        );
        expect(external.client, isNull);
        expect(external.external!.calls, hasLength(1));
        final inventory = await rpc(4, 'resources/list');
        expect(inventory['result']['resources'], hasLength(1));
        final skill = await rpc(5, 'resources/read', {
          'uri': 'nai-skill:///builtin%2Ftest?path=reference.md',
        });
        expect(skill['result']['contents'][0]['text'], 'Reference text');
        slow = (args, token) async {
          await token.whenCancelled;
          token.check();
          return {};
        };
        process.stdin.writeln(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': 6,
            'method': 'tools/call',
            'params': {'name': 'settings_update', 'arguments': {}},
          }),
        );
        await until(() => executed == 2);
        process.stdin.writeln(
          jsonEncode({
            'jsonrpc': '2.0',
            'method': 'notifications/cancelled',
            'params': {'requestId': 6},
          }),
        );
        final cancelled =
            jsonDecode(await lines.next.timeout(const Duration(seconds: 10)))
                as Map;
        expect(cancelled['id'], 6);
        expect(cancelled['result']['isError'], isTrue);
        expect(cancelled['result']['details']['code'], 'cancelled');
      } finally {
        await process.stdin.close();
        await process.exitCode.timeout(const Duration(seconds: 10));
        await lines.cancel();
        expect(await errors, isEmpty);
      }
    },
  );
}
