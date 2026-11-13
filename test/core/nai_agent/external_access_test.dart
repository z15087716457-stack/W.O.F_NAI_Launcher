import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/external_access.dart';
import 'package:nai_launcher/core/nai_agent/external_session.dart';
import 'package:nai_launcher/core/nai_agent/tool_catalog.dart';
import '../../helpers/agent_test_node.dart';

void main() {
  test('transient notices and unread flags are not replayed from history', () {
    final session = ExternalAgentSession(summary: 'Task')
      ..unread = true
      ..unreadAt = 42
      ..notice = ExternalAgentNotice(
        id: 'new',
        at: DateTime.now(),
        isError: false,
        title: 'Rain',
      );
    final saved = session.toJson();
    expect(saved.keys, unorderedEquals(['schema', 'summary', 'calls']));
    final restored = ExternalAgentSession.fromJson(saved);
    expect(restored.unread, isFalse);
    expect(restored.notice, isNull);
  });
  test(
    'external business permissions match the actual internal Pi hook',
    () async {
      final rows = [
        for (final name in naiAgentToolNames.where(
          (n) => !{'read', 'write', 'edit', 'bash'}.contains(n),
        ))
          for (final action in [
            null,
            'read',
            'list',
            'create',
            'prepare',
            'run',
            'delete',
            'remove',
            'move_file',
            'update',
            'cancel',
          ])
            {
              'name': name,
              'args': {if (action != null) 'action': action},
            },
      ];
      final process = await Process.start(agentTestNode, [
        'tool/nai_agent/test/fixture-external-permissions.mjs',
      ]);
      process.stdin.write(jsonEncode(rows));
      await process.stdin.close();
      final output = process.stdout.transform(utf8.decoder).join();
      final errors = process.stderr.transform(utf8.decoder).join();
      expect(await process.exitCode, 0, reason: await errors);
      expect(jsonDecode(await output), [
        for (final row in rows)
          externalToolAccess(
            row['name'] as String,
            Map<String, dynamic>.from(row['args'] as Map),
          ).name,
      ]);
    },
  );
  test(
    'recovering an interrupted external call never replays it or reports success',
    () {
      final session = ExternalAgentSession.fromJson({
        'summary': 'Task',
        'calls': [
          ExternalAgentCall(
            id: 'a',
            name: 'prompt_set',
            arguments: {},
            startedAt: 100,
          ).toJson(),
        ],
      });
      expect(session.connected, isFalse);
      expect(session.calls.single.result!['isError'], isTrue);
      expect(session.calls.single.result!['details']['error'], 'interrupted');
      expect(session.displayTools['a']!['isError'], isTrue);
      expect(
        session.displayMessages(DateTime(2026)).last['role'],
        'toolResult',
      );
    },
  );
  test(
    'skill symlinks cannot turn a resource read into arbitrary file access',
    () async {
      final root = await Directory.systemTemp.createTemp('external-skill-');
      try {
        final skill = Directory('${root.path}/skill')..createSync();
        File('${root.path}/outside.md').writeAsStringSync('Outside');
        await Link('${skill.path}/escape.md').create('${root.path}/outside.md');
        await expectLater(
          readExternalSkill(skill.path, 'escape.md'),
          throwsA(
            isA<NaiAgentToolError>().having(
              (e) => e.code,
              'code',
              'invalid_path',
            ),
          ),
        );
        await expectLater(
          readExternalSkill(skill.path, '${root.path}/outside.md'),
          throwsA(isA<NaiAgentToolError>()),
        );
      } finally {
        await root.delete(recursive: true);
      }
    },
  );
}
