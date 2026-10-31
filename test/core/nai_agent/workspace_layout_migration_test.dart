import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_files.dart';

void main() {
  late Directory root;
  late AgentWorkspaceStore store;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('wof-layout-');
    store = AgentWorkspaceStore(root);
  });
  tearDown(() => root.delete(recursive: true));

  Future<Directory> legacy() async {
    final dir = store.workspaceDirectory('legacy');
    for (final child in [
      'sessions',
      'attachments/chat',
      'outputs',
      'notes',
      'skills',
      'snapshots',
      'ui/chats',
      '.agent/draft-backups',
      '.pi/prompts',
    ]) {
      await Directory(p.join(dir.path, child)).create(recursive: true);
    }
    final now = DateTime(2026, 10, 31).toIso8601String();
    await File(p.join(dir.path, 'workspace.json')).writeAsString(
      jsonEncode({
        'schema': 1,
        'id': 'legacy',
        'name': 'Project',
        'createdAt': now,
      }),
    );
    await File(
      p.join(dir.path, 'instructions.md'),
    ).writeAsString('STUDIO_RULE');
    await File(p.join(dir.path, 'AGENTS.md')).writeAsString('PROJECT_RULE');
    await File(p.join(dir.path, 'app.py')).writeAsString('print("project")');
    await File(
      p.join(dir.path, 'outputs', 'report.md'),
    ).writeAsString('Original report');
    await File(
      p.join(dir.path, '.agent', 'draft-backups', 'draft.json'),
    ).writeAsString('{"draft":"original"}');
    await File(
      p.join(dir.path, '.pi', 'prompts', 'review.md'),
    ).writeAsString('Review prompt');
    final history =
        '${jsonEncode({'type': 'session', 'id': 'native', 'version': 3, 'timestamp': now, 'cwd': dir.path})}\n'
        '${jsonEncode({
          'type': 'message',
          'id': 'u1',
          'timestamp': now,
          'message': {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'Read outputs/report.md and attachments/chat/image.png'},
            ],
          },
        })}\n';
    await File(
      p.join(dir.path, 'sessions', 'history.jsonl'),
    ).writeAsString(history);
    await File(p.join(dir.path, 'ui', 'chats', 'chat.json')).writeAsString(
      jsonEncode({
        'schema': 1,
        'id': 'chat',
        'workspaceId': 'legacy',
        'title': 'History',
        'createdAt': now,
        'sessionFile': 'sessions/history.jsonl',
      }),
    );
    final bytes = [1, 2, 3];
    await File(
      p.join(dir.path, 'attachments', 'chat', 'image.png'),
    ).writeAsBytes(bytes);
    await File(p.join(dir.path, 'ui', 'chat.json')).writeAsString(
      jsonEncode({
        'text': 'Unsent draft',
        'attachments': [
          {
            'id': 'image',
            'name': 'image.png',
            'path': 'attachments/chat/image.png',
            'mimeType': 'image/png',
            'bytes': 3,
            'sha256': sha256.convert(bytes).toString(),
          },
        ],
      }),
    );
    return dir;
  }

  test(
    'new workspace keeps every launcher file under .W.O.F and loads root rules once',
    () async {
      final workspace = await store.createWorkspace('Project');
      expect(
        (await workspace.directory.list().toList()).map(
          (item) => p.basename(item.path),
        ),
        ['.W.O.F'],
      );
      expect(
        p.relative(workspace.sessions.path, from: workspace.directory.path),
        p.join('.W.O.F', 'sessions'),
      );
      final rules = File(p.join(workspace.directory.path, 'AGENTS.md'));
      await rules.writeAsString('PROJECT_UNIQUE');
      await File(
        p.join(workspace.agentDirectory.path, 'instructions.md'),
      ).writeAsString('STUDIO_UNIQUE');
      final prompt = await store.effectiveSystemPrompt(workspace.id);
      expect('PROJECT_UNIQUE'.allMatches(prompt), hasLength(1));
      expect('STUDIO_UNIQUE'.allMatches(prompt), hasLength(1));
      await rules.writeAsString('PROJECT_UPDATED');
      expect(
        await store.effectiveSystemPrompt(workspace.id),
        contains('PROJECT_UPDATED'),
      );
      expect(
        await store.effectiveSystemPrompt(workspace.id),
        isNot(contains('PROJECT_UNIQUE')),
      );
      final project = File(p.join(workspace.directory.path, 'main.py'));
      await project.writeAsString('custom');
      expect(await project.readAsString(), 'custom');
    },
  );

  test(
    'legacy migration backs up all state, preserves Pi bytes and restores chats',
    () async {
      final dir = await legacy();
      final history = await File(
        p.join(dir.path, 'sessions', 'history.jsonl'),
      ).readAsBytes();
      final workspaces = await Future.wait([
        store.getWorkspace('legacy'),
        store.getWorkspace('legacy'),
      ]);
      final workspace = workspaces.first;
      expect(
        workspaces.every((item) => item.directory.path == dir.path),
        isTrue,
      );
      expect(
        (await dir.list().toList())
            .map((item) => p.basename(item.path))
            .toSet(),
        {'.W.O.F', 'AGENTS.md', 'app.py'},
      );
      expect(
        await File(
          p.join(workspace.sessions.path, 'history.jsonl'),
        ).readAsBytes(),
        history,
      );
      expect(
        await File(
          p.join(
            workspace.agentDirectory.path,
            'migration-backup',
            'sessions',
            'history.jsonl',
          ),
        ).readAsBytes(),
        history,
      );
      expect(
        await File(
          p.join(workspace.agentDirectory.path, 'draft-backups', 'draft.json'),
        ).readAsString(),
        '{"draft":"original"}',
      );
      expect(
        await File(p.join(workspace.prompts.path, 'review.md')).readAsString(),
        'Review prompt',
      );
      final composer = await store.readComposer('legacy', 'chat');
      expect(composer.text, 'Unsent draft');
      expect(
        composer.attachments.single.relativePath,
        p.join('.W.O.F', 'attachments', 'chat', 'image.png'),
      );
      expect(
        await store.readAttachment('legacy', composer.attachments.single),
        [1, 2, 3],
      );
      expect(
        (await store.listChats('legacy')).single.sessionFile,
        'sessions/history.jsonl',
      );
      expect(
        utf8.decode(await AgentWorkspaceFiles(dir).read('outputs/report.md')),
        'Original report',
      );
      await File(p.join(dir.path, 'outputs', 'report.md')).parent.create();
      await File(
        p.join(dir.path, 'outputs', 'report.md'),
      ).writeAsString('Custom project output');
      expect(
        utf8.decode(await AgentWorkspaceFiles(dir).read('outputs/report.md')),
        'Custom project output',
      );
      await AgentWorkspaceStore(root).getWorkspace('legacy');
      expect(
        await File(p.join(dir.path, 'app.py')).readAsString(),
        'print("project")',
      );
      final trash = await store.trashChat('legacy', 'chat');
      await store.restoreChat(trash.id);
      expect((await store.listChats('legacy')).single.title, 'History');
      expect(
        await File(
          p.join(workspace.sessions.path, 'history.jsonl'),
        ).readAsBytes(),
        history,
      );
    },
  );

  test(
    'migration refuses conflicting launcher destinations before touching originals',
    () async {
      final dir = await legacy();
      final conflicting = File(
        p.join(dir.path, '.W.O.F', 'outputs', 'report.md'),
      );
      await conflicting.parent.create(recursive: true);
      await conflicting.writeAsString('Keep existing');
      await expectLater(store.getWorkspace('legacy'), throwsStateError);
      expect(await File(p.join(dir.path, 'workspace.json')).exists(), isTrue);
      expect(
        await File(p.join(dir.path, 'outputs', 'report.md')).readAsString(),
        'Original report',
      );
      expect(await conflicting.readAsString(), 'Keep existing');
    },
  );

  test(
    'interrupted migration restores its partial transfer before retrying',
    () async {
      final dir = await legacy();
      final data = Directory(p.join(dir.path, '.W.O.F'));
      final backup = Directory(p.join(data.path, 'migration-backup'));
      final names = [
        'attachments',
        'outputs',
        'notes',
        'skills',
        'sessions',
        'snapshots',
        'ui',
        'instructions.md',
        '.agent/draft-backups',
        '.pi/prompts',
        'workspace.json',
      ];
      for (final name in names) {
        final source = p.join(dir.path, name);
        final target = p.join(backup.path, name);
        if (await FileSystemEntity.type(source) ==
            FileSystemEntityType.directory) {
          await Directory(target).create(recursive: true);
          await for (final entry in Directory(
            source,
          ).list(recursive: true, followLinks: false)) {
            final copy = p.join(target, p.relative(entry.path, from: source));
            if (entry is Directory) {
              await Directory(copy).create(recursive: true);
            } else if (entry is File) {
              await File(copy).parent.create(recursive: true);
              await entry.copy(copy);
            }
          }
        } else {
          await File(target).parent.create(recursive: true);
          await File(source).copy(target);
        }
      }
      await File(p.join(backup.path, 'manifest.json')).writeAsString(
        jsonEncode({
          'schema': 1,
          'workspaceId': 'legacy',
          'complete': false,
          'moves': [
            for (final name in names) {'from': p.normalize(name)},
          ],
        }),
      );
      final from = Directory(p.join(dir.path, 'outputs'));
      final to = p.join(data.path, 'outputs');
      expect(p.isWithin(dir.absolute.path, p.absolute(to)), isTrue);
      await from.rename(to);
      final workspace = await store.getWorkspace('legacy');
      expect(
        await File(
          p.join(workspace.agentDirectory.path, 'outputs', 'report.md'),
        ).readAsString(),
        'Original report',
      );
      expect(
        await File(p.join(backup.path, 'outputs', 'report.md')).readAsString(),
        'Original report',
      );
      expect(await File(p.join(dir.path, 'workspace.json')).exists(), isFalse);
      expect(
        jsonDecode(
          await File(p.join(backup.path, 'manifest.json')).readAsString(),
        )['complete'],
        isTrue,
      );
    },
  );

  test(
    'legacy attachment objects remain readable and exports use the management directory',
    () async {
      final workspace = await store.createWorkspace('Project');
      final attachment = await store.addAttachment(
        workspace.id,
        'chat',
        name: 'image.png',
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/png',
      );
      expect(attachment.relativePath, startsWith('.W.O.F'));
      final exported = await AgentWorkspaceFiles(
        workspace.directory,
      ).export('result.txt', Uint8List.fromList([65]), () {});
      expect(exported, startsWith(p.join('.W.O.F', 'outputs')));
      expect(
        await Directory(p.join(workspace.directory.path, 'outputs')).exists(),
        isFalse,
      );
    },
  );
}
