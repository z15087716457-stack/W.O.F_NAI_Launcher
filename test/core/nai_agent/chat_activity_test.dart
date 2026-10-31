import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';

void main() {
  late Directory root;
  late AgentWorkspaceStore store;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('chat-activity-');
    store = AgentWorkspaceStore(root);
  });
  tearDown(() => root.delete(recursive: true));

  test(
    'activity outranks creation, survives restart, and rename does not move a chat',
    () async {
      final w = await store.createWorkspace('workspace');
      final a = await store.createChat(w.id, 'old');
      final b = await store.createChat(w.id, 'new');
      final at = DateTime(2030);
      await store.updateChat(w.id, a.id, lastActivityAt: at);
      var chats = await AgentWorkspaceStore(root).listChats(w.id);
      expect(chats.first.id, a.id);
      expect(chats.first.lastActivityAt, at);
      await store.updateChat(w.id, b.id, title: 'renamed');
      chats = await store.listChats(w.id);
      expect(chats.first.id, a.id);
      expect(chats.last.activityAt, b.createdAt);
      expect(chats.first.createdAt, a.createdAt);
    },
  );

  test(
    'legacy history uses real messages, not metadata entries or file mtime',
    () async {
      final w = await store.createWorkspace('workspace');
      final a = await store.createChat(w.id, 'old');
      final session = File('${w.agentDirectory.path}/sessions/legacy.jsonl');
      await session.parent.create(recursive: true);
      await session.writeAsString(
        [
          jsonEncode({
            'type': 'message',
            'timestamp': '2030-01-01T00:00:00Z',
            'message': {'role': 'user', 'content': 'hi'},
          }),
          jsonEncode({
            'type': 'message',
            'timestamp': '2030-01-02T00:00:00Z',
            'message': {'role': 'assistant', 'content': 'hello'},
          }),
          jsonEncode({
            'type': 'session_info',
            'timestamp': '2040-01-01T00:00:00Z',
            'name': 'renamed',
          }),
          '{unfinished',
        ].join('\n'),
      );
      await store.updateChat(w.id, a.id, sessionFile: 'sessions/legacy.jsonl');
      var loaded = (await store.listChats(w.id)).single;
      expect(loaded.activityAt, DateTime.utc(2030, 1, 2));
      loaded = await store.updateChat(w.id, a.id, title: 'changed');
      expect(loaded.activityAt, DateTime.utc(2030, 1, 2));
      expect(
        (await AgentWorkspaceStore(root).listChats(w.id)).single.activityAt,
        DateTime.utc(2030, 1, 2),
      );
    },
  );
}
