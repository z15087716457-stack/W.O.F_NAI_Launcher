import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/krita/bridge_draft_guard.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/block_tools.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_collection.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';

class _InterleavingStorage extends PromptBlockStorage {
  Future<void> Function()? onBlockRead;
  Future<void> Function()? onCollectionTransform;
  @override
  Future<PromptBlock?> getBlock(String id) async {
    final value = await super.getBlock(id);
    final hook = onBlockRead;
    onBlockRead = null;
    await hook?.call();
    return value;
  }

  @override
  Future<PromptBlockCollection?> transformCollection(
    String id,
    PromptBlockCollection? Function(PromptBlockCollection?) transform,
  ) async {
    final hook = onCollectionTransform;
    onCollectionTransform = null;
    await hook?.call();
    return super.transformCollection(id, transform);
  }
}

void main() {
  late Directory root;
  late _InterleavingStorage storage;
  late PromptBlockRepository repository;
  late BridgeDraftSnapshot current;
  late bool busy, alive;
  Future<void> Function()? duringBackup;
  late NaiAgentBlockTools tools;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('nai-agent-block-guards-');
    Hive.init(root.path);
    storage = _InterleavingStorage();
    await storage.init();
    repository = PromptBlockRepository(storage);
    current = BridgeDraftSnapshot(fields: {'prompt': 'original'});
    busy = false;
    alive = true;
    duringBackup = null;
    tools = NaiAgentBlockTools(
      readLibrary: repository.load,
      repository: repository,
      refresh: () async {},
      readDraft: () => current,
      backup: (_, __, ___) async {
        await duringBackup?.call();
        return 'synthetic-backup';
      },
      isBusy: () => busy,
      isAlive: () => alive,
      validateInstance: (_, __, ___) {},
      editInstance: (_, __) => {},
    );
  });
  tearDown(() async {
    await Hive.close();
    await root.delete(recursive: true);
  });
  Matcher error(String code) =>
      isA<NaiAgentToolError>().having((e) => e.code, 'code', code);
  Future<void> edit(
    PromptBlock block, {
    NaiAgentCancellation? token,
    String action = 'update',
  }) async {
    await tools.manage({
      'action': action,
      'id': block.id,
      'expected_version': naiAgentBlockVersion(block),
      'changes': {'content': 'model edit'},
    }, token ?? NaiAgentCancellation());
  }

  test(
    'Agent create and update accept preset settings and reject invalid values',
    () async {
      final created =
          (await tools.manage({
                'action': 'create',
                'changes': {
                  'title': 'preset',
                  'content': '',
                  'generationSettings': {
                    'qualityPreset': 'light',
                    'ucPreset': 7,
                  },
                },
              }, NaiAgentCancellation()))['details']
              as Map;
      final saved = (await repository.load()).blocks.single;
      expect(created['block'], isNotNull);
      await tools.manage({
        'action': 'update',
        'id': saved.id,
        'expected_version': naiAgentBlockVersion(saved),
        'changes': {
          'generationSettings': {'qualityPreset': 'none', 'ucPreset': 9},
        },
      }, NaiAgentCancellation());
      expect(
        (await repository.getBlock(saved.id))!.generationSettings!.ucPreset,
        9,
      );
      for (final settings in [
        {'qualityPreset': 'wrong'},
        {'ucPreset': 4},
        {'ucPreset': 1.5},
        {'qualityCustomBlockId': 5},
      ]) {
        expect(
          () => validateNaiAgentBlockChanges({'generationSettings': settings}),
          throwsA(error('invalid_changes')),
        );
      }
    },
  );

  test(
    'final Hive comparison detects an edit after the repository has read its old row',
    () async {
      final original = await repository.createBlock(
        title: 'one',
        content: 'original',
      );
      storage.onBlockRead = () =>
          storage.putBlock(original.copyWith(content: 'newer user edit'));
      await expectLater(edit(original), throwsA(error('block_conflict')));
      expect(
        (await repository.getBlock(original.id))!.content,
        'newer user edit',
      );
    },
  );
  test(
    'final Hive comparison detects a deletion after the repository has read its old row',
    () async {
      final original = await repository.createBlock(
        title: 'one',
        content: 'original',
      );
      storage.onBlockRead = () => storage.deleteBlock(original.id);
      await expectLater(edit(original), throwsA(error('block_conflict')));
      expect(await repository.getBlock(original.id), null);
    },
  );
  test(
    'a concurrent usage increment does not conflict or get lost in a guarded definition edit',
    () async {
      final original = await repository.createBlock(
        title: 'one',
        content: 'original',
      );
      storage.onBlockRead = () async {
        await repository.incrementUseCount(original.id);
      };
      await edit(original);
      final actual = (await repository.getBlock(original.id))!;
      expect(actual.content, 'model edit');
      expect(actual.useCount, 1);
    },
  );
  test(
    'the native usage counter changes only usage and preserves the current definition',
    () async {
      final original = await repository.createBlock(
        title: 'one',
        content: 'original',
      );
      await repository.updateBlock(
        original.copyWith(content: 'new user content', isFavorite: true),
      );
      await repository.incrementUseCount(original.id);
      final actual = (await repository.getBlock(original.id))!;
      expect(actual.content, 'new user content');
      expect(actual.isFavorite, true);
      expect(actual.useCount, 1);
    },
  );
  test(
    'collection cleanup preserves a name and new member changed during deletion',
    () async {
      final first = await repository.createBlock(title: 'one', content: 'one');
      final other = await repository.createBlock(title: 'two', content: 'two');
      final c = await repository.createCollection(name: 'old name');
      await storage.putCollection(c.copyWith(blockIds: [first.id]));
      storage.onCollectionTransform = () => storage.putCollection(
        c.copyWith(name: 'new user name', blockIds: [first.id, other.id]),
      );
      await edit(first, action: 'delete');
      final actual = (await repository.load()).collections.single;
      expect(actual.name, 'new user name');
      expect(actual.blockIds, [other.id]);
    },
  );
  test('a draft change during backup prevents the library write', () async {
    final original = await repository.createBlock(
      title: 'one',
      content: 'original',
    );
    duringBackup = () async {
      current = BridgeDraftSnapshot(fields: {'prompt': 'new user prompt'});
    };
    await expectLater(edit(original), throwsA(error('draft_conflict')));
    expect((await repository.getBlock(original.id))!.content, 'original');
  });
  test(
    'generation beginning during backup prevents the library write',
    () async {
      final original = await repository.createBlock(
        title: 'one',
        content: 'original',
      );
      duringBackup = () async {
        busy = true;
      };
      await expectLater(edit(original), throwsA(error('busy')));
      expect((await repository.getBlock(original.id))!.content, 'original');
    },
  );
  test('cancellation during backup prevents the library write', () async {
    final original = await repository.createBlock(
      title: 'one',
      content: 'original',
    );
    final token = NaiAgentCancellation();
    duringBackup = () async {
      token.cancel();
    };
    await expectLater(
      edit(original, token: token),
      throwsA(error('cancelled')),
    );
    expect((await repository.getBlock(original.id))!.content, 'original');
  });
  test('binding disposal during backup prevents the library write', () async {
    final original = await repository.createBlock(
      title: 'one',
      content: 'original',
    );
    duringBackup = () async {
      alive = false;
    };
    await expectLater(edit(original), throwsA(error('closed')));
    expect((await repository.getBlock(original.id))!.content, 'original');
  });
  test('backup failure prevents both deletion and creation', () async {
    final original = await repository.createBlock(
      title: 'one',
      content: 'original',
    );
    duringBackup = () async {
      throw const FileSystemException('synthetic write failure');
    };
    await expectLater(
      edit(original, action: 'delete'),
      throwsA(isA<FileSystemException>()),
    );
    await expectLater(
      tools.manage({
        'action': 'create',
        'changes': {'title': 'new', 'content': 'new'},
      }, NaiAgentCancellation()),
      throwsA(isA<FileSystemException>()),
    );
    expect((await repository.load()).blocks.single.id, original.id);
  });
}
