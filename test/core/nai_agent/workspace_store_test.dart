import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';

void main() {
  late Directory root;
  late AgentWorkspaceStore store;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('nai-workspaces-');
    store = AgentWorkspaceStore(root);
  });
  tearDown(() => root.delete(recursive: true));

  test(
    'approval mode and per-model thinking preferences survive concurrent saves',
    () async {
      final a = jsonEncode(['local', 'a']), b = jsonEncode(['local', 'b']);
      await Future.wait([
        store.patchSettings({
          'reasoningEfforts': {a: 'high'},
        }),
        store.patchSettings({
          'reasoningEfforts': {b: 'low'},
        }),
        store.patchSettings({
          'permissionMode': 'readonly',
          'providerId': 'local',
          'modelId': 'a',
        }),
      ]);
      final settings = await AgentWorkspaceStore(root).readSettings();
      expect(settings.permissionMode, 'readonly');
      expect(settings.reasoningEffort, 'high');
      expect(settings.reasoningEfforts[b], 'low');
      await store.patchSettings({
        'reasoningEfforts': {a: null},
      });
      expect((await store.readSettings()).reasoningEfforts, {b: 'low'});
      expect(
        AgentSettings.fromJson({'permissionMode': 'invalid'}).permissionMode,
        'ask',
      );
      expect(AgentSettings.fromJson({}).panelWidth, 520);
    },
  );
  test(
    'workspace names cannot become paths; rename preserves files and isolation',
    () async {
      final a = await store.createWorkspace('画风 / ../研究');
      final b = await store.createWorkspace('画风 / ../研究');
      expect(a.id, isNot(b.id));
      final notes = File('${a.directory.path}/notes/private.txt');
      await notes.writeAsString('甲');
      await store.updateWorkspace(a.id, name: '新的名字');
      expect((await store.getWorkspace(a.id)).directory.path, a.directory.path);
      expect(await notes.readAsString(), '甲');
      expect(
        await File('${b.directory.path}/notes/private.txt').exists(),
        false,
      );
      expect(await store.listWorkspaces(), hasLength(2));
      expect(
        () => store.workspaceDirectory('../outside'),
        throwsFormatException,
      );
    },
  );

  test(
    'global instructions and prefix persist separately and apply around workspace base prompts',
    () async {
      final a = await store.createWorkspace('A'),
          b = await store.createWorkspace('B');
      await store.patchSettings({
        'customSystemPrompt': 'GLOBAL_BASE',
        'globalInstructions': 'SHARED_RULE',
        'systemPromptPrefix': 'PREFIX_IDENTITY',
      });
      await store.updateWorkspace(b.id, customSystemPrompt: 'PROJECT_BASE');
      await File(
        '${b.directory.path}/instructions.md',
      ).writeAsString('LOCAL_RULE');
      final reopened = AgentWorkspaceStore(root);
      final settings = await reopened.readSettings();
      expect(settings.systemPrompt, 'GLOBAL_BASE');
      expect(settings.globalInstructions, 'SHARED_RULE');
      expect(settings.systemPromptPrefix, 'PREFIX_IDENTITY');
      for (final workspace in [a, b]) {
        final prompt = await reopened.effectiveSystemPrompt(workspace.id);
        final base = workspace.id == a.id ? 'GLOBAL_BASE' : 'PROJECT_BASE';
        expect(prompt, startsWith('PREFIX_IDENTITY'));
        expect(prompt.indexOf(base), lessThan(prompt.indexOf('SHARED_RULE')));
        expect(prompt, contains('SHARED_RULE'));
      }
      final project = await reopened.effectiveSystemPrompt(b.id);
      expect(project, isNot(contains('GLOBAL_BASE')));
      expect(
        project.indexOf('SHARED_RULE'),
        lessThan(project.indexOf('LOCAL_RULE')),
      );
      await reopened.patchSettings({'globalInstructions': ''});
      expect(
        await reopened.effectiveSystemPrompt(b.id),
        isNot(contains('SHARED_RULE')),
      );
      expect(
        await reopened.effectiveSystemPrompt(b.id),
        startsWith('PREFIX_IDENTITY'),
      );
      await reopened.patchSettings({'systemPromptPrefix': ''});
      expect(
        await reopened.effectiveSystemPrompt(b.id),
        startsWith('PROJECT_BASE'),
      );
      expect(AgentSettings.fromJson({}).globalInstructions, isEmpty);
      expect(AgentSettings.fromJson({}).systemPromptPrefix, isEmpty);
    },
  );

  test(
    'independent instruction saves merge settings and retain previous instruction text',
    () async {
      await store.saveSettings(
        const AgentSettings(
          customSystemPrompt: 'BASE',
          globalInstructions: 'OLD_GLOBAL',
          systemPromptPrefix: 'OLD_PREFIX',
          providerId: 'configured',
          enterToSend: false,
        ),
      );
      await Future.wait([
        store.patchSettings({'globalInstructions': 'NEW_GLOBAL'}),
        store.patchSettings({'systemPromptPrefix': 'NEW_PREFIX'}),
      ]);
      final settings = await store.readSettings();
      expect(settings.globalInstructions, 'NEW_GLOBAL');
      expect(settings.systemPromptPrefix, 'NEW_PREFIX');
      expect(settings.systemPrompt, 'BASE');
      expect(settings.providerId, 'configured');
      expect(settings.enterToSend, false);
      final files = await Directory(
        '${root.path}/prompt-history',
      ).list().toList();
      expect(files, hasLength(2));
      final text = (await Future.wait(
        files.cast<File>().map((file) => file.readAsString()),
      )).join('\n');
      expect(text, contains('OLD_GLOBAL'));
      expect(text, contains('OLD_PREFIX'));
    },
  );

  test(
    'global and workspace prompt overrides restore and retain previous versions',
    () async {
      final workspace = await store.createWorkspace('项目');
      await store.saveSettings(const AgentSettings(customSystemPrompt: '全局一'));
      await store.saveSettings(const AgentSettings(customSystemPrompt: '全局二'));
      expect(await store.effectiveSystemPrompt(workspace.id), contains('全局二'));
      await store.updateWorkspace(workspace.id, customSystemPrompt: '工作区');
      await File(
        '${workspace.directory.path}/instructions.md',
      ).writeAsString('项目规则');
      expect(await store.effectiveSystemPrompt(workspace.id), contains('工作区'));
      expect(await store.effectiveSystemPrompt(workspace.id), contains('项目规则'));
      await store.updateWorkspace(workspace.id, resetPrompt: true);
      expect(await store.effectiveSystemPrompt(workspace.id), contains('全局二'));
      final previous = await Directory(
        '${root.path}/prompt-history',
      ).list().toList();
      expect(previous, hasLength(1));
      expect(await (previous.single as File).readAsString(), contains('全局一'));
      await store.saveSettings(const AgentSettings());
      expect(
        await store.effectiveSystemPrompt(workspace.id),
        contains('你是 NAI Agent'),
      );
    },
  );

  test(
    'empty chats keep separate drafts and interrupted queues never replay',
    () async {
      final workspace = await store.createWorkspace('项目');
      final a = await store.createChat(workspace.id, '未发送');
      final b = await store.createChat(workspace.id, '另一个');
      expect(a.sessionFile, isNull);
      await store.saveComposer(
        workspace.id,
        a.id,
        const AgentComposerState(
          text: '待写',
          wasRunning: true,
          pending: [
            {'text': '排队'},
          ],
        ),
      );
      final recovered = await AgentWorkspaceStore(
        root,
      ).readComposer(workspace.id, a.id);
      expect(recovered.text, '待写');
      expect(recovered.interrupted, true);
      expect(recovered.wasRunning, false);
      expect(recovered.pending.single['text'], '排队');
      expect((await store.readComposer(workspace.id, b.id)).text, '');
      expect((await store.listChats(workspace.id)), hasLength(2));
      await store.updateChat(
        workspace.id,
        a.id,
        title: '新标题',
        sessionFile: 'sessions/a.jsonl',
      );
      expect(
        (await store.listChats(
          workspace.id,
        )).firstWhere((c) => c.id == a.id).sessionFile,
        'sessions/a.jsonl',
      );
      await expectLater(
        store.updateChat(workspace.id, a.id, sessionFile: '../a.jsonl'),
        throwsFormatException,
      );
      expect(
        await workspace.sessions.list().isEmpty,
        true,
      ); // Only Pi creates history.
    },
  );

  test(
    'attachments preserve original bytes and reject changed or escaped files',
    () async {
      final workspace = await store.createWorkspace('项目');
      final chat = await store.createChat(workspace.id, '聊天');
      final bytes = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);
      final attachment = await store.addAttachment(
        workspace.id,
        chat.id,
        name: '原图.png',
        bytes: bytes,
        mimeType: 'image/png',
      );
      expect(await store.readAttachment(workspace.id, attachment), bytes);
      await store.saveComposer(
        workspace.id,
        chat.id,
        AgentComposerState(attachments: [attachment]),
      );
      expect(
        (await store.readComposer(
          workspace.id,
          chat.id,
        )).attachments.single.sha256Hex,
        attachment.sha256Hex,
      );
      await File(
        '${workspace.directory.path}/${attachment.relativePath}',
      ).writeAsBytes([1]);
      await expectLater(
        store.readAttachment(workspace.id, attachment),
        throwsFormatException,
      );
      final escaped = AgentAttachment.fromJson({
        ...attachment.toJson(),
        'path': '../outside.png',
      });
      await File(
        '${workspace.directory.parent.path}/outside.png',
      ).writeAsBytes(bytes);
      await expectLater(
        store.readAttachment(workspace.id, escaped),
        throwsFormatException,
      );
    },
  );

  test(
    'snapshots persist raw fields without installing or modifying any draft',
    () async {
      final workspace = await store.createWorkspace('项目');
      final file = await store.saveSnapshot(workspace.id, '配置', {
        'prompt': '原始',
        'steps': 28,
      });
      expect((jsonDecode(await file.readAsString()) as Map)['draft'], {
        'prompt': '原始',
        'steps': 28,
      });
      expect(await store.snapshots(workspace.id), hasLength(1));
    },
  );
}
