import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_chatgpt_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:path/path.dart' as p;

import '../../../helpers/agent_test_node.dart';

class _SecureStorage extends SecureStorageService {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  test(
    'ChatGPT connection restores, renews and signs out through private IPC',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'studio-chatgpt-test-',
      );
      addTearDown(() => root.delete(recursive: true));
      final log = File(p.join(root.path, 'actions.jsonl'));
      await File(p.join(root.path, 'manage-resources.mjs')).writeAsString(r'''
import { appendFile } from 'node:fs/promises';
import { createInterface } from 'node:readline';
for await (const line of createInterface({ input: process.stdin })) {
  const { resource, action, deviceId, credential, accessToken } = JSON.parse(line);
  if (resource !== 'chatgpt') throw Error('Wrong resource');
  await appendFile('actions.jsonl', JSON.stringify({ action, deviceId }) + '\n');
  const initial = { type: 'oauth', access: 'initial', refresh: 'refresh',
    expires: Date.now() + 60000 };
  const renewed = { ...initial, access: 'renewed' };
  let result;
  if (action === 'login') result = initial;
  if (action === 'refresh' && credential?.refresh === 'refresh') result = renewed;
  if (action === 'models' && ['initial', 'renewed'].includes(accessToken)) {
    result = { models: [{ id: 'gpt-6.1-sol', name: 'GPT-6.1 Sol', vision: true,
      contextWindow: 100000, maxTokens: 10000, efforts: ['off', 'high'] }] };
  }
  console.log(JSON.stringify({ result }));
}
''');
      final storage = _SecureStorage();
      final paths = NaiAgentRuntimePaths(
        node: agentTestNode,
        host: p.join(root.path, 'host.mjs'),
      );
      final account = NaiAgentChatGpt(storage, paths);
      addTearDown(account.dispose);
      await account.ready;
      expect(account.connected, isFalse);
      await account.signIn();
      expect(account.failed, isFalse);
      expect(account.models.single.id, 'gpt-6.1-sol');
      expect(await account.accessToken(), 'initial');
      expect(await account.claimPlanNotice(), isTrue);

      // Expire the persisted session, then simulate a restart and two chats.
      final credential = storage.values.entries.singleWhere(
        (entry) => entry.value.startsWith('{'),
      );
      storage.values[credential.key] = jsonEncode({
        ...jsonDecode(credential.value) as Map<String, dynamic>,
        'expires': 0,
      });
      final restored = NaiAgentChatGpt(storage, paths);
      addTearDown(restored.dispose);
      expect(
        await Future.wait([restored.accessToken(), restored.accessToken()]),
        ['renewed', 'renewed'],
      );
      expect(restored.models.single.name, 'GPT-6.1 Sol');
      expect(await restored.claimPlanNotice(), isFalse);
      expect(storage.values[credential.key], contains('renewed'));

      await restored.signOut();
      expect(storage.values.containsKey(credential.key), isFalse);
      expect(restored.models, isEmpty);
      await expectLater(restored.accessToken(), throwsStateError);
      await restored.signIn();
      final actions = (await log.readAsLines()).map(
        (line) => jsonDecode(line) as Map<String, dynamic>,
      );
      expect(actions.where((a) => a['action'] == 'refresh'), hasLength(1));
      final deviceIds = actions
          .where((a) => a['action'] == 'login')
          .map((a) => a['deviceId'])
          .toSet();
      expect(deviceIds.single, isA<String>());
    },
  );
}
