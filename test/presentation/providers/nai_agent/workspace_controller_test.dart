import '../../../helpers/fetch_test_server.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/core/nai_agent/vision_access.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';

void main() {
  late Directory root;
  late HttpServer server;
  late StreamSubscription<HttpRequest> serving;
  final controllers = <NaiAgentWorkspaceController>[];
  var calls = 0;
  final requests = <Map<String, dynamic>>[];
  Future<void> Function()? waitForResponse;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('nai-controller-');
    server = await bindFetchTestServer();
    calls = 0;
    requests.clear();
    waitForResponse = null;
    serving = server.listen((request) async {
      requests.add(
        Map<String, dynamic>.from(
          jsonDecode(await utf8.decoder.bind(request).join()) as Map,
        ),
      );
      calls++;
      await waitForResponse?.call();
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
    for (final controller in controllers) {
      await controller.close();
      controller.dispose();
    }
    controllers.clear();
    await serving.cancel();
    await server.close(force: true);
    await root.delete(recursive: true);
  });
  NaiAgentWorkspaceController controller({
    bool vision = false,
    bool Function()? readVision,
    int Function()? readModelRevision,
    NaiAgentVisionAccess visionAccess = const NaiAgentVisionAccess(),
  }) {
    final value = NaiAgentWorkspaceController(
      store: AgentWorkspaceStore(root),
      initialWorkspaceName: '工作区',
      initialChatName: '新聊天',
      readModelRevision: readModelRevision,
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
            visionAccess: visionAccess,
            extensionPaths: settings.enabledExtensionPaths,
            mcp: {
              'builtinEnabled': settings.studioMcpEnabled,
              'builtinExposure': settings.studioMcpExposure,
            },
            privateModelConfig: {
              'providerId': 'controller-local',
              'modelId': 'test',
              'protocol': 'openaiChatCompletions',
              'baseUrl': 'http://127.0.0.1:${server.port}',
              'tools': true,
              'vision': readVision?.call() ?? vision,
              'maxConcurrentRequests': 1,
              'maxRequestsPerRun': 32,
              'permissionMode': settings.permissionMode,
            },
            executeTool: (_, __, ___) async => {'content': []},
          ),
    );
    controllers.add(value);
    return value;
  }

  test(
    'new chats are one in-memory draft, first send persists and auto-titles',
    () async {
      final c = controller();
      await c.initialize();
      final workspace = c.selectedWorkspace!, draftId = c.selected!.chat.id;
      expect(c.selected!.chat.isDraft, true);
      expect(await c.store.listChats(workspace.id), isEmpty);
      expect((await c.store.getWorkspace(workspace.id)).lastSessionId, isNull);
      await Future.wait([c.createChat(), c.createChat(), c.createChat()]);
      expect(c.chats, hasLength(1));
      expect(c.selected!.chat.id, draftId);
      await c.saveComposer('尚未发送');
      expect(
        await File('${workspace.directory.path}/ui/$draftId.json').exists(),
        false,
      );
      await c.close();
      expect(await c.store.listChats(workspace.id), isEmpty);
      final reopened = controller();
      await reopened.initialize();
      expect(reopened.selected!.composer.text, '');
      await reopened.saveComposer('  ${'标' * 40}  ');
      await reopened.send();
      expect(reopened.selected!.error, isNull);
      expect(reopened.selected!.chat.isDraft, false);
      expect(reopened.selected!.chat.title, '标' * 32);
      expect(reopened.chats, hasLength(1));
      expect(
        (await reopened.store.listChats(workspace.id)).single.id,
        reopened.selected!.chat.id,
      );
      expect(
        (await reopened.store.getWorkspace(workspace.id)).lastSessionId,
        reopened.selected!.chat.id,
      );
      expect(calls, 1);
    },
  );

  test(
    'switching away discards draft composer and staged attachments',
    () async {
      final c = controller();
      await c.initialize();
      await c.saveComposer('saved');
      await c.send();
      final saved = c.selected!.chat.id;
      await c.createChat();
      final draft = c.selected!;
      await c.saveComposer('never sent');
      await c.attach(
        'staged.png',
        img.encodePng(img.Image(width: 1, height: 1)),
        'image/png',
      );
      expect(c.chats.first.id, draft.chat.id);
      expect(
        (await c.store.getWorkspace(draft.workspace.id)).lastSessionId,
        saved,
      );
      final attachmentDirectory = Directory(
        '${draft.workspace.directory.path}/attachments/${draft.chat.id}',
      );
      expect(await attachmentDirectory.exists(), true);
      await c.selectChat(saved);
      expect(await attachmentDirectory.exists(), false);
      expect(
        c.heldRuntimes.any((runtime) => runtime.chat.id == draft.chat.id),
        false,
      );
      expect(c.chats.map((chat) => chat.id), [saved]);
      expect(await c.store.listChats(draft.workspace.id), hasLength(1));
      await c.createChat();
      final newDraftId = c.selected!.chat.id;
      await c.createWorkspace('other');
      expect(
        await File(
          '${draft.workspace.directory.path}/ui/chats/$newDraftId.json',
        ).exists(),
        false,
      );
      expect(c.selected!.chat.isDraft, true);
      expect(await c.store.listChats(c.selectedWorkspace!.id), isEmpty);
    },
  );

  test(
    'explicitly deleted draft is undoable but stays off disk until first send',
    () async {
      final c = controller();
      await c.initialize();
      await c.saveComposer('draft to undo');
      await c.attach(
        'staged.png',
        img.encodePng(img.Image(width: 1, height: 1)),
        'image/png',
      );
      final draft = c.selected!;
      final trash = await c.deleteChat(draft.chat.id);
      expect(await c.store.listChats(draft.workspace.id), isEmpty);
      expect(c.selected!.chat.id, isNot(draft.chat.id));
      await c.undoDeleteChat(trash);
      expect(c.selected!.chat.id, draft.chat.id);
      expect(c.selected!.chat.isDraft, true);
      expect(c.selected!.composer.text, 'draft to undo');
      expect(c.selected!.composer.attachments, hasLength(1));
      expect(await c.store.listChats(draft.workspace.id), isEmpty);
      expect(
        (await c.store.getWorkspace(draft.workspace.id)).lastSessionId,
        isNull,
      );
      await c.send();
      expect(c.selected!.error, isNull);
      expect(c.selected!.chat.title, 'draft to undo');
      expect(await c.store.listChats(draft.workspace.id), hasLength(1));
    },
  );

  test(
    'delete cannot race the first draft send while metadata is being saved',
    () async {
      final c = controller();
      await c.initialize();
      await c.saveComposer('first send');
      final chat = c.selected!;
      final sending = c.send();
      await expectLater(c.deleteChat(chat.chat.id), throwsStateError);
      await expectLater(c.deleteWorkspace(chat.workspace.id), throwsStateError);
      await sending;
      expect(chat.error, isNull);
      expect(await c.store.listChats(chat.workspace.id), hasLength(1));
    },
  );

  test(
    'chat deletion closes runtime, selects adjacent, undo restores history and selection',
    () async {
      final c = controller();
      var notifications = 0;
      c.addListener(() => notifications++);
      await c.initialize();
      await c.saveComposer('first searchable body');
      await c.send();
      final first = c.selected!;
      await c.createChat();
      await c.saveComposer('second');
      await c.send();
      final second = c.selected!, client = c.selected!.client!;
      final hits = await c.searchChats('SEARCHABLE');
      expect(hits.single.chatId, first.chat.id);
      final trash = await c.deleteChat(second.chat.id);
      expect(client.isClosed, true);
      expect(c.heldRuntimes.contains(second), false);
      expect(c.selected!.chat.id, first.chat.id);
      expect(
        (await c.store.getWorkspace(first.workspace.id)).lastSessionId,
        first.chat.id,
      );
      await c.undoDeleteChat(trash);
      expect(c.selected!.chat.id, second.chat.id);
      expect(
        c.selected!.messages.where((message) => message['role'] == 'user'),
        hasLength(1),
      );
      expect(
        (await c.store.getWorkspace(first.workspace.id)).lastSessionId,
        second.chat.id,
      );
      await c.deleteChat(first.chat.id);
      final lastTrash = await c.deleteChat(second.chat.id);
      expect(c.selected!.chat.isDraft, true);
      expect(await c.store.listChats(first.workspace.id), isEmpty);
      expect(
        (await c.store.getWorkspace(first.workspace.id)).lastSessionId,
        isNull,
      );
      await c.undoDeleteChat(lastTrash);
      expect(c.chats, hasLength(1));
      expect(c.selected!.chat.id, second.chat.id);
      expect(calls, 2);
      expect(notifications, greaterThan(10));
    },
  );

  test(
    'deletion rejects all busy states including background workspace chats',
    () async {
      final c = controller();
      await c.initialize();
      final first = c.selected!;
      for (final state in ['running', 'starting', 'waiting']) {
        first.running = state == 'running';
        first.starting = state == 'starting';
        first.waitingForSlot = state == 'waiting';
        final runningError = throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'running',
          ),
        );
        await expectLater(c.deleteChat(first.chat.id), runningError);
        await expectLater(c.deleteWorkspace(first.workspace.id), runningError);
      }
      first.running = first.starting = first.waitingForSlot = false;
      first.chat = await c.store.saveDraftChat(first.chat);
      await c.createWorkspace('other');
      first.waitingForSlot = true;
      await expectLater(
        c.deleteWorkspace(first.workspace.id),
        throwsStateError,
      );
      first.waitingForSlot = false;
      final trash = await c.deleteWorkspace(first.workspace.id);
      expect(c.selectedWorkspace!.id, isNot(first.workspace.id));
      expect(c.heldRuntimes.contains(first), false);
      await c.undoDeleteWorkspace(trash);
      expect(c.selectedWorkspace!.id, first.workspace.id);
      expect(c.settings.selectedWorkspaceId, first.workspace.id);
    },
  );

  test(
    'workspace deletion switches selection and undo, at least one remains',
    () async {
      final c = controller();
      await c.initialize();
      final firstWorkspace = c.selectedWorkspace!.id;
      await expectLater(c.deleteWorkspace(firstWorkspace), throwsStateError);
      await c.saveComposer('persisted');
      await c.send();
      final firstChat = c.selected!.chat.id;
      await c.createWorkspace('other');
      final otherWorkspace = c.selectedWorkspace!.id;
      await c.selectWorkspace(firstWorkspace);
      final client = c.selected!.client!;
      final trash = await c.deleteWorkspace(firstWorkspace);
      expect(client.isClosed, true);
      expect(c.selectedWorkspace!.id, otherWorkspace);
      expect(
        (await c.store.readSettings()).selectedWorkspaceId,
        otherWorkspace,
      );
      expect(c.workspaces, hasLength(1));
      await c.undoDeleteWorkspace(trash);
      expect(c.workspaces, hasLength(2));
      expect(c.selectedWorkspace!.id, firstWorkspace);
      expect(c.selected!.chat.id, firstChat);
      expect(
        (await c.store.readSettings()).selectedWorkspaceId,
        firstWorkspace,
      );
      expect(calls, 1);
    },
  );

  test('nonvision sends only compact NAI summary and original paths', () async {
    final c = controller();
    await c.initialize();
    final runtime = c.selected!;
    final png = img.encodePng(
      img.Image(
        width: 2,
        height: 2,
        textData: {
          'Software': 'NovelAI',
          'Description': 'large private prompt',
          'Comment': jsonEncode({
            'prompt': 'large private prompt',
            'seed': 6789,
            'steps': 28,
          }),
        },
      ),
    );
    final ordinary = img.encodePng(
      img.Image(
        width: 2,
        height: 2,
        textData: {'Software': 'Photoshop', 'Description': 'private EXIF'},
      ),
    );
    await c.attach('NAI.png', png, 'image/png');
    await c.attach('ordinary.png', ordinary, 'image/png');
    final originals = runtime.composer.attachments;
    await c.saveComposer('read original metadata when needed');
    await c.send();
    expect(runtime.error, isNull);
    expect(calls, 1);
    final sent = jsonEncode(requests.single['messages']);
    expect(sent, contains('6789'));
    expect(sent, contains('metadata_only=true'));
    expect(sent, contains('ordinary.png'));
    expect(sent, isNot(contains('large private prompt')));
    expect(sent, isNot(contains('private EXIF')));
    expect(sent, isNot(contains('image_url')));
    expect(runtime.visionNotice, contains('2'));
    expect(runtime.visionNotice, contains('文字仍照常发送'));
    expect(runtime.visionNotice, contains('请求 → 图片输入'));
    expect(
      await c.store.readAttachment(runtime.workspace.id, originals.first),
      png,
    );
    expect(
      await c.store.readAttachment(runtime.workspace.id, originals.last),
      ordinary,
    );
  });
  test(
    'provider-blocked attachments warn without pixels and clear on the next successful send',
    () async {
      var vision = false, revision = 0;
      const access = NaiAgentVisionAccess(
        blockedByProvider: true,
        providerName: 'Synthetic Provider',
      );
      final c = controller(
        readVision: () => vision,
        readModelRevision: () => revision,
        visionAccess: access,
      );
      await c.initialize();
      final runtime = c.selected!;
      final pixels = img.encodePng(img.Image(width: 3, height: 2));
      await c.attach('retained.png', pixels, 'image/png');
      final original = runtime.composer.attachments.single;
      await c.saveComposer('text still reaches the model');
      await c.send();
      expect(runtime.error, isNull);
      expect(calls, 1);
      expect(
        jsonEncode(requests.single['messages']),
        contains('text still reaches the model'),
      );
      expect(
        jsonEncode(requests.single['messages']),
        isNot(contains('image_url')),
      );
      final user = runtime.messages.singleWhere((m) => m['role'] == 'user');
      expect(
        (user['content'] as List).where((p) => p['type'] == 'image'),
        isEmpty,
      );
      expect(runtime.visionNotice, access.skippedAttachmentsNotice(1));
      expect(runtime.visionNotice, contains('Synthetic Provider → 请求 → 图片输入'));
      expect(
        await c.store.readAttachment(runtime.workspace.id, original),
        pixels,
      );

      await c.saveComposer('text only');
      await c.send();
      expect(runtime.error, isNull);
      expect(runtime.visionNotice, isNull);

      await c.attach('blocked-again.png', pixels, 'image/png');
      await c.send();
      expect(runtime.visionNotice, isNotNull);
      vision = true;
      revision++;
      await c.attach('now-visible.png', pixels, 'image/png');
      await c.saveComposer('now send the pixels');
      await c.send();
      expect(runtime.error, isNull);
      expect(runtime.visionNotice, isNull);
      expect(calls, 4);
      expect(
        jsonEncode(requests.last['messages']),
        contains('data:image/png;base64,'),
      );
      expect(
        await c.store.readAttachment(runtime.workspace.id, original),
        pixels,
      );
    },
  );

  test(
    'model-blocked attachments warn and changing the model clears the notice',
    () async {
      const access = NaiAgentVisionAccess(
        blockedByProvider: false,
        providerName: 'Text Provider',
      );
      final c = controller(visionAccess: access);
      await c.initialize();
      await c.attach(
        'text-model.png',
        img.encodePng(img.Image(width: 2, height: 2)),
        'image/png',
      );
      await c.send();
      expect(calls, 1);
      expect(c.selected!.error, isNull);
      expect(c.selected!.visionNotice, access.skippedAttachmentsNotice(1));
      expect(c.selected!.visionNotice, contains('模型 → 能力 → 图片输入'));
      await c.updateSettings({'providerId': 'other', 'modelId': 'other-model'});
      expect(c.selected!.visionNotice, isNull);
    },
  );

  test(
    'a queued successful send is not overwritten by an older attachment warning',
    () async {
      final c = controller(
        visionAccess: const NaiAgentVisionAccess(
          blockedByProvider: true,
          providerName: 'Queue Provider',
        ),
      );
      await c.initialize();
      final entered = Completer<void>(), release = Completer<void>();
      waitForResponse = () async {
        if (!entered.isCompleted) entered.complete();
        await release.future;
      };
      await c.attach(
        'queued.png',
        img.encodePng(img.Image(width: 2, height: 2)),
        'image/png',
      );
      await c.saveComposer('first attachment run');
      final run = c.send();
      await entered.future.timeout(const Duration(seconds: 10));
      try {
        expect(c.selected!.visionNotice, isNotNull);
        await c.saveComposer('text-only follow-up');
        await c.send();
        expect(c.selected!.visionNotice, isNull);
      } finally {
        release.complete();
        await run;
      }
      expect(c.selected!.visionNotice, isNull);
      expect(c.selected!.error, isNull);
      expect(calls, 2);
    },
  );

  for (final code in ['vision_disabled', 'vision_unavailable']) {
    test(
      '$code maps to the localized two-gate fallback without raw English',
      () async {
        final c = NaiAgentWorkspaceController(
          store: AgentWorkspaceStore(root),
          initialWorkspaceName: 'Workspace',
          initialChatName: 'Chat',
          startClient: (_, __, ___, ____, _____) =>
              Future.error(NaiAgentToolError(code, 'old English image error')),
        );
        controllers.add(c);
        await c.initialize();
        await c.saveComposer('send');
        await c.send();
        expect(c.selected!.error, currentL10n.naiAgent_visionDisabled);
        expect(c.selected!.error, isNot(contains('old English')));
        expect(calls, 0);
      },
    );
  }

  test('vision sends BMP as a PNG copy and retains the original BMP', () async {
    final c = controller(vision: true);
    await c.initialize();
    final runtime = c.selected!;
    final bmp = img.encodeBmp(img.Image(width: 3, height: 2));
    await c.attach('original.bmp', bmp, 'image/bmp');
    final original = runtime.composer.attachments.single;
    await c.send();
    expect(runtime.error, isNull);
    expect(calls, 1);
    expect(
      jsonEncode(requests.single['messages']),
      contains('data:image/png;base64,'),
    );
    expect(await c.store.readAttachment(runtime.workspace.id, original), bmp);
  });
  test(
    'live approval mode updates the owned Pi host without a model request',
    () async {
      final c = controller();
      await c.initialize();
      await c.saveComposer('first');
      await c.send();
      final client = c.selected!.client!;
      await c.updateSettings({'permissionMode': 'ask'});
      expect(c.selected!.client, same(client));
      expect((await client.state())['permissionMode'], 'ask');
      await c.updateSettings({
        'permissionMode': 'bypass',
        'bypassWarned': true,
      });
      expect((await client.state())['permissionMode'], 'bypass');
      expect(c.settings.bypassWarned, true);
      await c.updateSettings({'permissionMode': 'ask'});
      expect((await client.state())['permissionMode'], 'ask');
      expect(c.selected!.client, same(client));
      expect(calls, 1);
    },
  );
  test(
    'readonly stops background Agent work and recovers its queue without touching another draft',
    () async {
      final c = controller();
      await c.initialize();
      final first = c.selected!;
      final entered = Completer<void>(), release = Completer<void>();
      waitForResponse = () async {
        if (!entered.isCompleted) entered.complete();
        await release.future;
      };
      await c.saveComposer('running');
      final running = c.send();
      await entered.future.timeout(const Duration(seconds: 10));
      try {
        await c.saveComposer('queued');
        await c.send();
        await c.createWorkspace('second');
        await c.saveComposer('第二个项目的最新草稿');
        await c
            .updateSettings({'permissionMode': 'readonly'})
            .timeout(const Duration(seconds: 10));
        await running.timeout(const Duration(seconds: 10));
        expect(first.running, false);
        expect(first.composer.pending.single['recovered'], true);
        expect(c.selected!.composer.text, '第二个项目的最新草稿');
        expect((await first.client!.state())['permissionMode'], 'readonly');
        expect(calls, 1);
      } finally {
        if (!release.isCompleted) release.complete();
      }
    },
  );
  test(
    'instruction changes refresh live and restored Pi sessions while retaining each base prompt',
    () async {
      final c = controller();
      await c.initialize();
      final first = c.selected!, firstWorkspace = c.selectedWorkspace!.id;
      await c.saveComposer('first');
      await c.send();
      await c.createWorkspace('second');
      await c.setWorkspacePrompt('PROJECT_BASE');
      final second = c.selected!;
      await c.saveComposer('second');
      await c.send();
      expect(calls, 2);
      await c.updateSettings({
        'globalInstructions': 'SHARED_RULE',
        'systemPromptPrefix': 'PREFIX_IDENTITY',
      });
      expect(calls, 2);
      final live = (await second.client!.getSystemPrompt())['text'] as String;
      expect(
        live.indexOf('PREFIX_IDENTITY'),
        lessThan(live.indexOf('PROJECT_BASE')),
      );
      expect(
        live.indexOf('PROJECT_BASE'),
        lessThan(live.indexOf('SHARED_RULE')),
      );
      await c.saveComposer('second again');
      await c.send();
      await c.selectWorkspace(firstWorkspace);
      final restored =
          (await first.client!.getSystemPrompt())['text'] as String;
      expect(
        restored.indexOf('PREFIX_IDENTITY'),
        lessThan(restored.indexOf('你是 NAI Agent')),
      );
      expect(restored, contains('SHARED_RULE'));
      await c.saveComposer('first again');
      await c.send();
      for (final request in requests.skip(2)) {
        final messages = request['messages'] as List;
        final prompt =
            messages.firstWhere(
                  (message) => message['role'] == 'system',
                )['content']
                as String;
        expect(prompt, contains('PREFIX_IDENTITY'));
        expect(prompt, contains('SHARED_RULE'));
      }
      expect(first.messages.where((m) => m['role'] == 'user'), hasLength(2));
      await c.updateSettings({'globalInstructions': ''});
      final cleared = (await first.client!.getSystemPrompt())['text'] as String;
      expect(cleared, isNot(contains('SHARED_RULE')));
      expect(cleared, contains('PREFIX_IDENTITY'));
      await c.selectWorkspace(second.workspace.id);
      final reopened =
          (await second.client!.getSystemPrompt())['text'] as String;
      expect(reopened, isNot(contains('SHARED_RULE')));
      expect(reopened, contains('PREFIX_IDENTITY'));
      expect(reopened, contains('PROJECT_BASE'));
      expect(second.messages.where((m) => m['role'] == 'user'), hasLength(2));
      expect(calls, 4);
    },
  );

  test(
    'extension changes wait for next send and reload the same session in its workspace',
    () async {
      final c = controller();
      await c.initialize();
      final first = c.selected!, chatId = c.selected!.chat.id;
      final file = await File('${root.path}/workspace-extension.ts').writeAsString(
        "import { writeFile } from 'node:fs/promises'; import { join } from 'node:path'; "
        "export default pi => pi.on('session_start', async (_event, ctx) => { "
        "await writeFile(join(ctx.cwd, 'extension-started.txt'), 'started'); });",
      );
      final entered = Completer<void>(), release = Completer<void>();
      waitForResponse = () async {
        if (!entered.isCompleted) entered.complete();
        await release.future;
      };
      await c.saveComposer('first');
      final running = c.send();
      await entered.future.timeout(const Duration(seconds: 10));
      final before = first.client!, sessionFile = first.chat.sessionFile;
      final marker = File(
        '${first.workspace.directory.path}/extension-started.txt',
      );
      await c.configureExtension(file.path);
      expect(first.client, same(before));
      expect(before.isClosed, false);
      expect(await marker.exists(), false);
      release.complete();
      await running;
      expect(await marker.exists(), false);
      await c.saveComposer('next');
      await c.send();
      expect(first.error, isNull);
      expect(first.client, isNot(same(before)));
      expect(before.isClosed, true);
      expect(first.chat.id, chatId);
      expect(first.chat.sessionFile, sessionFile);
      expect(await marker.readAsString(), 'started');
      expect(first.messages.where((m) => m['role'] == 'user'), hasLength(2));
      await c.createWorkspace('another');
      final other = c.selected!;
      final otherMarker = File(
        '${other.workspace.directory.path}/extension-started.txt',
      );
      expect(await otherMarker.exists(), false);
      await c.saveComposer('other');
      await c.send();
      expect(other.error, isNull);
      expect(await otherMarker.readAsString(), 'started');
      expect(other.messages.where((m) => m['role'] == 'user'), hasLength(1));
      expect(calls, 3);
    },
  );

  test(
    'background task remains in original chat while switching workspaces preserves input',
    () async {
      final c = controller();
      await c.initialize();
      expect(calls, 0);
      final first = c.selected!, firstWorkspace = c.selectedWorkspace!.id;
      await c.saveComposer('先完成这个任务');
      final entered = Completer<void>(), release = Completer<void>();
      waitForResponse = () async {
        if (!entered.isCompleted) entered.complete();
        await release.future;
      };
      final running = c.send();
      await entered.future.timeout(const Duration(seconds: 10));
      await c.createWorkspace('另一个项目');
      final secondWorkspace = c.selectedWorkspace!.id;
      // Test composer persistence on a saved chat, not a disposable new draft.
      c.selected!.chat = await c.store.saveDraftChat(c.selected!.chat);
      await c.saveComposer('第二个项目的草稿');
      expect(c.runningChats.single.chat.id, first.chat.id);
      expect(c.selected!.messages, isEmpty);
      release.complete();
      await running;
      expect(c.selected!.composer.text, '第二个项目的草稿');
      expect(
        first.messages.where((m) => m['role'] == 'assistant'),
        hasLength(1),
      );
      await c.selectWorkspace(firstWorkspace);
      expect(c.selected!.chat.title, '先完成这个任务');
      expect(calls, 1);
      await c.selectWorkspace(secondWorkspace);
      expect(c.selected!.composer.text, '第二个项目的草稿');
    },
  );
  test(
    'MCP changes preserve the Pi session and apply on the next idle send',
    () async {
      final c = controller();
      await c.initialize();
      await c.saveComposer('first');
      await c.send();
      final runtime = c.selected!, before = c.selected!.client!;
      final sessionFile = runtime.chat.sessionFile;
      await c.updateSettings({'studioMcpEnabled': false});
      expect(runtime.client, same(before));
      expect(before.isClosed, false);
      await c.saveComposer('next');
      await c.send();
      expect(before.isClosed, true);
      expect(runtime.client, isNot(same(before)));
      expect(runtime.chat.sessionFile, sessionFile);
      expect(runtime.messages.where((m) => m['role'] == 'user'), hasLength(2));
      expect(runtime.error, isNull);
      final status = await runtime.client!.mcpCommand('status');
      expect(status['mcpStatus'], contains('disabled'));
      expect(calls, 2);
    },
  );

  test(
    'controller restart recovers Pi history, pending input and interrupted status without replay',
    () async {
      final c = controller();
      await c.initialize();
      await c.saveComposer('第一次');
      await c.send();
      expect(c.selected!.error, isNull);
      final workspaceId = c.selectedWorkspace!.id, chatId = c.selected!.chat.id;
      await c.saveComposer('尚未发送');
      await c.close();
      await c.store.saveComposer(
        workspaceId,
        chatId,
        const AgentComposerState(
          text: '尚未发送',
          wasRunning: true,
          pending: [
            {'queueId': 'recovered', 'text': '排队文字'},
          ],
        ),
      );
      final reopened = controller();
      await reopened.initialize();
      expect(calls, 1);
      expect(
        reopened.selected!.messages.where((m) => m['role'] == 'user'),
        hasLength(1),
      );
      expect(reopened.selected!.composer.text, '尚未发送');
      expect(reopened.selected!.composer.interrupted, true);
      expect(reopened.selected!.composer.pending.single['text'], '排队文字');
      await expectLater(
        reopened.restorePending('recovered'),
        throwsA(anything),
      );
      expect(reopened.selected!.composer.text, '尚未发送');
      await reopened.saveComposer('');
      await reopened.restorePending('recovered');
      expect(reopened.selected!.composer.text, '排队文字');
      expect(
        calls,
        1,
      ); // Restoration is editing a draft, never automatic sending.
    },
  );

  test(
    'stopping preserves only unsent queue messages for explicit restoration',
    () async {
      final c = controller();
      await c.initialize();
      await c.saveComposer('正在处理的消息');
      final entered = Completer<void>(), release = Completer<void>();
      waitForResponse = () async {
        if (!entered.isCompleted) entered.complete();
        await release.future;
      };
      final run = c.send();
      await entered.future.timeout(const Duration(seconds: 10));
      expect(c.selected!.composer.pending, isEmpty);
      await c.saveComposer('还未处理的消息');
      await c.send();
      expect(c.selected!.composer.pending, hasLength(1));
      await c.stop();
      await run;
      release.complete();
      expect(c.selected!.composer.pending, hasLength(1));
      expect(c.selected!.composer.pending.single['recovered'], true);
      expect(c.selected!.composer.pending.single['text'], '还未处理的消息');
      await c.restorePending(
        c.selected!.composer.pending.single['queueId'] as String,
      );
      expect(c.selected!.composer.text, '还未处理的消息');
      expect(c.selected!.composer.pending, isEmpty);
    },
  );
  test(
    'export keeps official Pi JSONL intact and makes no model call',
    () async {
      final c = controller();
      await c.initialize();
      await c.saveComposer('保存这一轮');
      await c.send();
      final runtime = c.selected!, callsBefore = calls;
      final exported = await c.exportSession(runtime);
      final original = await File(
        '${runtime.workspace.directory.path}/${runtime.chat.sessionFile}',
      ).readAsBytes();
      expect(exported, original);
      final rows = utf8
          .decode(exported)
          .trim()
          .split('\n')
          .map(jsonDecode)
          .toList();
      expect(rows.first['type'], 'session');
      expect(
        rows
            .where((e) => e['type'] == 'message')
            .map((e) => e['message']['role']),
        containsAll(['user', 'assistant']),
      );
      expect(calls, callsBefore);
    },
  );
  test(
    'an attachment prepared for one chat stays there after workspace switching',
    () async {
      final c = controller();
      await c.initialize();
      final original = c.selected!;
      original.chat = await c.store.saveDraftChat(original.chat);
      await c.createWorkspace('第二个工作区');
      await c.saveComposer('保留第二个项目的草稿');
      final selected = c.selected!;
      final pixels = img.encodePng(img.Image(width: 1, height: 1));
      await c.attach('reference.png', pixels, 'image/png', target: original);
      expect(selected.composer.attachments, isEmpty);
      expect(selected.composer.text, '保留第二个项目的草稿');
      expect(original.composer.attachments, hasLength(1));
      expect(
        await c.store.readAttachment(
          original.workspace.id,
          original.composer.attachments.single,
        ),
        pixels,
      );
      expect(calls, 0);
    },
  );
}
