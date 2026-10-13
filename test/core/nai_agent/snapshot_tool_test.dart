import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/snapshot_tool.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_snapshot_files.dart';

void main() {
  late Directory root;
  late AgentSnapshotFiles files;
  late NaiAgentSnapshotTool tool;
  late String version;
  late bool busy, alive, applied;
  late Map<String, dynamic> draft;
  Future<void> Function()? duringPrepare;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('nai-agent-snapshot-');
    files = AgentSnapshotFiles(root);
    version = 'latest';
    busy = false;
    alive = true;
    applied = false;
    draft = {
      'draft': {
        'fields': {'prompt': 'before'},
      },
      'image': {
        'params': {'width': 832},
        'extra': {
          'sourceImage': 'pixel-bytes-never-sent',
          'vibes': [],
          'precise': [],
        },
      },
      'blocks': [],
    };
    duringPrepare = null;
    tool = NaiAgentSnapshotTool(
      files: files,
      capture: () => draft,
      readVersion: () => version,
      isBusy: () => busy,
      isAlive: () => alive,
      prepare: (saved, check) async {
        await duringPrepare?.call();
        check();
        return saved;
      },
      apply: (saved) {
        applied = true;
        draft = saved as Map<String, dynamic>;
        version = 'restored';
      },
      readBack: () => draft,
    );
  });
  tearDown(() async => root.delete(recursive: true));
  Future<String> save() async =>
      (await tool.execute({
            'action': 'save',
            'name': '测试配置',
          }, NaiAgentCancellation()))['details']['saved']['id']
          as String;
  Matcher failure(String code) =>
      throwsA(isA<NaiAgentToolError>().having((e) => e.code, 'code', code));
  test(
    'save/read/list are workspace files and read never leaks binary images',
    () async {
      final id = await save();
      final result = await tool.execute({
        'action': 'read',
        'id': id,
      }, NaiAgentCancellation());
      expect(result['details']['has_source_image'], isTrue);
      expect(jsonEncode(result), isNot(contains('pixel-bytes-never-sent')));
      expect(
        (await files.read(id))['generation']['image']['extra']['sourceImage'],
        'pixel-bytes-never-sent',
      );
      expect((await files.list()).single['id'], id);
      expect(applied, isFalse);
    },
  );
  test(
    'explicit load creates complete backup then reports actual restored state',
    () async {
      final id = await save();
      draft = {
        'draft': {
          'fields': {'prompt': 'user newer'},
        },
      };
      final result = await tool.execute({
        'action': 'load',
        'id': id,
        'expected_version': version,
      }, NaiAgentCancellation());
      expect(applied, isTrue);
      expect(result['details']['draft_version'], 'restored');
      final backup = jsonDecode(
        await File(result['details']['backup_path']).readAsString(),
      );
      expect(backup['generation']['draft']['fields']['prompt'], 'user newer');
      expect((await files.list()), hasLength(1));
    },
  );
  for (final condition in ['stale', 'busy', 'cancel', 'close']) {
    test(
      'refuses $condition before application even if it occurs during asynchronous prepare',
      () async {
        final id = await save();
        final cancellation = NaiAgentCancellation();
        duringPrepare = () async {
          switch (condition) {
            case 'stale':
              version = 'user-edited';
            case 'busy':
              busy = true;
            case 'cancel':
              cancellation.cancel();
            case 'close':
              alive = false;
          }
        };
        await expectLater(
          tool.execute({
            'action': 'load',
            'id': id,
            'expected_version': version,
          }, cancellation),
          failure(
            {
              'stale': 'draft_conflict',
              'busy': 'busy',
              'cancel': 'cancelled',
              'close': 'closed',
            }[condition]!,
          ),
        );
        expect(applied, isFalse);
      },
    );
  }
  test(
    'missing or old expected version refuses before making a backup',
    () async {
      final id = await save();
      await expectLater(
        tool.execute({'action': 'load', 'id': id}, NaiAgentCancellation()),
        failure('draft_conflict'),
      );
      expect(
        await Directory(
          p.join(root.path, '.agent', 'snapshot-backups'),
        ).exists(),
        isFalse,
      );
    },
  );
  test('maximum valid display name also permits a restore backup', () async {
    final saved = await files.save('x' * 200, draft);
    final result = await tool.execute({
      'action': 'load',
      'id': saved['id'],
      'expected_version': version,
    }, NaiAgentCancellation());
    expect(await File(result['details']['backup_path']).exists(), isTrue);
  });
  test(
    'damaged metadata is skipped and traversal IDs never open a file',
    () async {
      await save();
      await File(
        p.join(root.path, 'snapshots', 'bad.meta.json'),
      ).writeAsString('{"schema":2,"id":20}');
      await File(
        p.join(root.path, 'snapshots', 'wrong.meta.json'),
      ).writeAsString('[]');
      expect(await files.list(), hasLength(1));
      await expectLater(files.read('../../outside'), throwsFormatException);
    },
  );
}
