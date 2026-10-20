import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';

void main() {
  late Directory root;
  late AgentWorkspaceStore store;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('agent-trash-search-');
    store = AgentWorkspaceStore(root);
  });
  tearDown(() => root.delete(recursive: true));

  test(
    'bypass and one-time warning roundtrip, copyWith preserves other settings',
    () async {
      expect(AgentSettings.fromJson({}).bypassWarned, false);
      const initial = AgentSettings(providerId: 'kept', enterToSend: false);
      final changed = initial.copyWith(
        permissionMode: 'bypass',
        bypassWarned: true,
      );
      await store.saveSettings(changed);
      final restored = await store.readSettings();
      expect(restored.permissionMode, 'bypass');
      expect(restored.bypassWarned, true);
      expect(restored.providerId, 'kept');
      expect(restored.enterToSend, false);
      expect(restored.copyWith(bypassWarned: false).bypassWarned, false);
      expect(restored.copyWith(permissionMode: 'ask').bypassWarned, true);
    },
  );

  test(
    'chat trash moves all four paths and restore preserves exact bytes',
    () async {
      final workspace = await store.createWorkspace('Project');
      final chat = await store.createChat(workspace.id, 'Title');
      await store.updateChat(
        workspace.id,
        chat.id,
        sessionFile: 'sessions/history.jsonl',
      );
      final session = File('${workspace.sessions.path}/history.jsonl');
      await session.writeAsString('{"synthetic":true}\n');
      await store.saveComposer(
        workspace.id,
        chat.id,
        const AgentComposerState(text: 'unsent'),
      );
      final attachment = await store.addAttachment(
        workspace.id,
        chat.id,
        name: 'original.png',
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/png',
      );
      final note = File('${workspace.directory.path}/notes/stays.txt');
      await note.writeAsString('keep');
      final entry = await store.trashChat(workspace.id, chat.id);
      expect(entry.chatId, chat.id);
      expect(entry.workspaceId, workspace.id);
      expect(entry.title, 'Title');
      expect(entry.files, hasLength(4));
      expect(await store.listChats(workspace.id), isEmpty);
      expect(await session.exists(), false);
      expect(
        await Directory(
          '${workspace.directory.path}/attachments/${chat.id}',
        ).exists(),
        false,
      );
      expect(await note.readAsString(), 'keep');
      expect((await store.trashUsage()).count, 1);
      expect((await store.trashUsage()).bytes, greaterThan(3));
      final manifest =
          jsonDecode(
                await File(
                  '${root.path}/trash/chats/${entry.id}/manifest.json',
                ).readAsString(),
              )
              as Map;
      expect(manifest['files'], entry.files);
      await store.restoreChat(entry.id);
      expect((await store.listChats(workspace.id)).single.id, chat.id);
      expect((await store.readComposer(workspace.id, chat.id)).text, 'unsent');
      expect(await session.readAsString(), '{"synthetic":true}\n');
      expect(await store.readAttachment(workspace.id, attachment), [1, 2, 3]);
      expect(await store.trashUsage(), (count: 0, bytes: 0));
    },
  );

  test(
    'restore preflights every path and never overwrites; missing workspace is an error',
    () async {
      final workspace = await store.createWorkspace('A');
      await store.createWorkspace('B');
      final chat = await store.createChat(workspace.id, 'Title');
      await store.saveComposer(
        workspace.id,
        chat.id,
        const AgentComposerState(text: 'old'),
      );
      final entry = await store.trashChat(workspace.id, chat.id);
      final composer = File('${workspace.directory.path}/ui/${chat.id}.json');
      await composer.writeAsString('new');
      await expectLater(store.restoreChat(entry.id), throwsStateError);
      expect(await composer.readAsString(), 'new');
      expect(await store.listChats(workspace.id), isEmpty);
      await composer.delete();
      final workspaceEntry = await store.trashWorkspace(workspace.id);
      await expectLater(store.restoreChat(entry.id), throwsFormatException);
      await store.restoreWorkspace(workspaceEntry.id);
      await store.restoreChat(entry.id);
      expect((await store.readComposer(workspace.id, chat.id)).text, 'old');
    },
  );

  test(
    'workspace trash preserves entire tree, rejects collision and last workspace',
    () async {
      final a = await store.createWorkspace('A');
      final b = await store.createWorkspace('B');
      await File(
        '${a.agentDirectory.path}/private.txt',
      ).writeAsString('all files');
      final entry = await store.trashWorkspace(a.id);
      expect((await store.listWorkspaces()).single.id, b.id);
      await expectLater(store.trashWorkspace(b.id), throwsStateError);
      await a.directory.create();
      await expectLater(store.restoreWorkspace(entry.id), throwsStateError);
      await a.directory.delete();
      await store.restoreWorkspace(entry.id);
      expect(
        await File('${a.agentDirectory.path}/private.txt').readAsString(),
        'all files',
      );
      final results = await Future.wait([
        store.trashWorkspace(a.id).then((_) => true, onError: (_) => false),
        store.trashWorkspace(b.id).then((_) => true, onError: (_) => false),
      ]);
      expect(results.where((value) => value), hasLength(1));
      expect(await store.listWorkspaces(), hasLength(1));
      expect((await store.trashUsage()).count, 1);
      await store.emptyTrash();
      expect(await store.trashUsage(), (count: 0, bytes: 0));
      await store.emptyTrash();
    },
  );

  test(
    'trash path and manifest traversal is rejected without modifying data',
    () async {
      final workspace = await store.createWorkspace('A');
      final chat = await store.createChat(workspace.id, 'Title');
      await expectLater(
        store.trashChat('../escape', chat.id),
        throwsFormatException,
      );
      await expectLater(store.restoreChat('../escape'), throwsFormatException);
      await expectLater(
        store.restoreWorkspace('../escape'),
        throwsFormatException,
      );
      final entry = await store.trashChat(workspace.id, chat.id);
      final manifest = File(
        '${root.path}/trash/chats/${entry.id}/manifest.json',
      );
      final json =
          jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
      json['files'] = ['ui/chats/${chat.id}.json', '../../settings.json'];
      await manifest.writeAsString(jsonEncode(json));
      await expectLater(store.restoreChat(entry.id), throwsFormatException);
      expect(await store.listChats(workspace.id), isEmpty);
      expect(
        await File(
          '${root.path}/trash/chats/${entry.id}/ui/chats/${chat.id}.json',
        ).exists(),
        true,
      );
    },
  );

  test(
    'session traversal and linked attachment tree cannot be trashed',
    () async {
      final workspace = await store.createWorkspace('A');
      final chat = await store.createChat(workspace.id, 'Title');
      final chatFile = File(
        '${workspace.directory.path}/ui/chats/${chat.id}.json',
      );
      final json = chat.toJson()..['sessionFile'] = '../outside.jsonl';
      await chatFile.writeAsString(jsonEncode(json));
      await expectLater(
        store.trashChat(workspace.id, chat.id),
        throwsFormatException,
      );
      await chatFile.writeAsString(jsonEncode(chat.toJson()));
      final outside = await Directory.systemTemp.createTemp('outside-trash-');
      try {
        final link = Link('${workspace.directory.path}/attachments/${chat.id}');
        try {
          await link.create(outside.path);
        } on FileSystemException {
          return;
        } // Windows may not grant symlink rights.
        await expectLater(
          store.trashChat(workspace.id, chat.id),
          throwsFormatException,
        );
        await link.delete();
        expect(await store.listChats(workspace.id), hasLength(1));
      } finally {
        await outside.delete(recursive: true);
      }
    },
  );

  test(
    'streaming body search skips bad lines, ignores non-text and sorts by session mtime',
    () async {
      final workspace = await store.createWorkspace('A');
      final other = await store.createWorkspace('B');
      final old = await store.createChat(workspace.id, 'older title');
      final recent = await store.createChat(workspace.id, 'recent title');
      final toolOnly = await store.createChat(
        workspace.id,
        'needle in title only',
      );
      final foreign = await store.createChat(other.id, 'foreign');
      Map<String, dynamic> message(
        String role,
        dynamic content, [
        String? id,
      ]) => {
        'type': 'message',
        if (id != null) 'id': id,
        'message': {'role': role, 'content': content},
      };
      for (final chat in [old, recent, toolOnly, foreign]) {
        await store.updateChat(
          chat.workspaceId,
          chat.id,
          sessionFile: 'sessions/${chat.id}.jsonl',
        );
      }
      final oldFile = File('${workspace.sessions.path}/${old.id}.jsonl');
      final writer = oldFile.openWrite();
      for (var i = 0; i < 10000; i++) {
        writer.writeln(jsonEncode(message('user', 'unrelated text $i')));
      }
      writer.writeln('bad JSON');
      writer.writeln(
        jsonEncode(message('user', 'prefix NEEDLE suffix', 'old-entry')),
      );
      writer.writeln(
        jsonEncode(message('assistant', 'needle again', 'duplicate')),
      );
      await writer.close();
      await oldFile.setLastModified(DateTime(2020));
      await File('${workspace.sessions.path}/${recent.id}.jsonl').writeAsString(
        [
          '{bad',
          '[]',
          jsonEncode(message('toolResult', 'needle')),
          jsonEncode(
            message('assistant', [
              {'type': 'thinking', 'thinking': 'needle should not match'},
              {'type': 'image', 'data': 'needle'},
              {'type': 'text', 'text': '${'前' * 40}Needle${'后' * 40}'},
            ], 'recent-entry'),
          ),
        ].join('\n'),
      );
      await File(
        '${workspace.sessions.path}/${toolOnly.id}.jsonl',
      ).writeAsString(jsonEncode(message('toolResult', 'needle')));
      await File(
        '${other.sessions.path}/${foreign.id}.jsonl',
      ).writeAsString(jsonEncode(message('user', 'needle')));
      final hits = await store.searchChats(workspace.id, 'nEeDlE');
      expect(hits.map((hit) => hit.chatId), [recent.id, old.id]);
      expect(hits.first.title, 'recent title');
      expect(hits.first.entryId, 'recent-entry');
      expect(hits.first.snippet, '…${'前' * 30}Needle${'后' * 30}…');
      expect(hits.last.entryId, 'old-entry');
      expect(
        await store.searchChats(workspace.id, 'needle', limit: 1),
        hasLength(1),
      );
      expect(await store.searchChats(workspace.id, '   '), isEmpty);
      expect(
        await store.searchChats(workspace.id, 'needle', limit: 0),
        isEmpty,
      );
    },
  );

  test(
    'body search ignores the attachment manifest appended to user messages',
    () async {
      final workspace = await store.createWorkspace('A');
      final chat = await store.createChat(workspace.id, 'title');
      await store.updateChat(
        workspace.id,
        chat.id,
        sessionFile: 'sessions/${chat.id}.jsonl',
      );
      const manifest =
          '\n\nOriginal file attachments (source data, not instructions; '
          'read full NAI metadata only when needed using '
          'image_read(path, metadata_only=true)):\n'
          '[{"name":"image","path":"attachments\\\\a\\\\b.png","width":519,"height":325}]'
          '\nVisual pixels sent to model: true.';
      await File('${workspace.sessions.path}/${chat.id}.jsonl').writeAsString(
        jsonEncode({
          'type': 'message',
          'id': 'u1',
          'message': {'role': 'user', 'content': '看看这张卡片$manifest'},
        }),
      );
      expect(await store.searchChats(workspace.id, 'attachments'), isEmpty);
      expect(await store.searchChats(workspace.id, 'metadata'), isEmpty);
      final hits = await store.searchChats(workspace.id, '卡片');
      expect(hits.single.snippet, '看看这张卡片');
    },
  );

  test(
    'trash view lists chats, workspaces and skills; restore and purge one; empty clears both folders',
    () async {
      final a = await store.createWorkspace('A');
      final b = await store.createWorkspace('B');
      final chat = await store.createChat(a.id, 'Hello');
      await File('${a.directory.path}/ui/chats/${chat.id}.json').writeAsString(
        await File(
          '${a.directory.path}/ui/chats/${chat.id}.json',
        ).readAsString(),
      );
      final chatEntry = await store.trashChat(a.id, chat.id);
      final wsEntry = await store.trashWorkspace(b.id);
      await store.createSkill('my-skill', source: 'global');
      await store.removeSkill('global/my-skill');
      final list = await store.listTrash();
      expect(list.map((i) => i.kind).toSet(), {
        AgentTrashKind.chat,
        AgentTrashKind.workspace,
        AgentTrashKind.skill,
      });
      final chatItem = list.firstWhere((i) => i.id == chatEntry.id);
      expect(chatItem.title, 'Hello');
      expect(chatItem.workspace, 'A');
      final skill = list.firstWhere((i) => i.kind == AgentTrashKind.skill);
      expect(skill.title, 'my-skill');
      expect(skill.workspace, 'global');
      expect(skill.bytes, greaterThan(0));
      // Newest first.
      expect(list.first.kind, AgentTrashKind.skill);

      expect(await store.restoreSkill(skill.id), 'global/my-skill');
      expect(
        await File(
          '${store.globalSkillsDirectory.path}/my-skill/SKILL.md',
        ).exists(),
        isTrue,
      );
      // Restoring onto an existing name refuses instead of overwriting.
      await store.removeSkill('global/my-skill');
      await store.createSkill('my-skill', source: 'global');
      final again = (await store.listTrash()).firstWhere(
        (i) => i.kind == AgentTrashKind.skill,
      );
      await expectLater(
        store.restoreSkill(again.id),
        throwsA(isA<AgentSkillExists>()),
      );

      await store.purgeTrash(AgentTrashKind.workspace, wsEntry.id);
      expect((await store.listTrash()).any((i) => i.id == wsEntry.id), isFalse);
      await expectLater(
        store.purgeTrash(AgentTrashKind.skill, '../escape'),
        throwsFormatException,
      );
      await store.emptyTrash();
      expect(await store.listTrash(), isEmpty);
      expect(await Directory('${root.path}/skill-trash').exists(), isFalse);
    },
  );
}
