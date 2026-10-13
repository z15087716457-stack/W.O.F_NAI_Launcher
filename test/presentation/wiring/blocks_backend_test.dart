import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/wiring/blocks_library_backend.dart';
import 'package:nai_launcher/presentation/wiring/blocks_platform.dart';

class DelayedThumbnail extends BlocksPlatform {
  final started = Completer<void>();
  final release = Completer<String>();
  @override
  Future<String> saveThumbnail(String token) {
    started.complete();
    return release.future;
  }
}

void main() {
  late Directory directory;
  late PromptBlockStorage storage;
  late ProviderContainer container;
  late BlocksLibraryBackend backend;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('blocks_backend_');
    Hive.init(directory.path);
    storage = PromptBlockStorage();
    await storage.init();
    container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    backend = container.read(blocksLibraryBackendProvider);
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'plain text preserves whitespace and explicit atoms preserve inner commas',
    () async {
      final plain = await backend.save(
        const BlockDraft(title: 'Plain', atoms: null, text: 'a,  b\n c'),
      );
      expect(plain.content, 'a,  b\n c');
      expect(plain.atoms, isNull);
      final atom = await backend.save(
        const BlockDraft(
          title: 'Atoms',
          atoms: ['a, b', 'c'],
          negativeAtoms: ['d, e'],
        ),
      );
      expect(atom.atoms, ['a, b', 'c']);
      expect(atom.content, 'a, b, c');
      expect(atom.negativeContent, 'd, e');
    },
  );

  test(
    'patch only changes supplied fields and explicitly clears icon and folder',
    () async {
      final folder = await backend.notifier.createFolder(name: 'Folder');
      final b = await backend.save(
        BlockDraft(
          title: 'Original',
          atoms: const ['a'],
          folderId: folder.id,
          icon: 'star',
        ),
      );
      await backend.patch(b.id, const BlockPatch(title: 'New'));
      expect(backend.requireBlock(b.id).folderId, folder.id);
      await backend.patch(
        b.id,
        const BlockPatch(clearIcon: true, toRoot: true),
      );
      expect(backend.requireBlock(b.id).iconName, isNull);
      expect(backend.requireBlock(b.id).folderId, isNull);
      expect(backend.requireBlock(b.id).content, 'a');
    },
  );

  test(
    'unchanged derived atoms do not normalize existing plain text',
    () async {
      final b = await backend.save(
        const BlockDraft(title: 'Plain', atoms: null, text: 'a,  b\n c'),
      );
      final saved = await backend.save(
        BlockDraft(title: 'Renamed', atoms: b.atomsOrSplit),
        id: b.id,
      );
      expect(saved.content, b.content);
      expect(saved.atoms, isNull);
    },
  );

  test('queued rename and recolor use the state at execution time', () async {
    final b = await backend.save(
      const BlockDraft(
        title: 'Tagged',
        atoms: ['a'],
        tags: [BlockTag('old', Colors.red)],
      ),
    );
    await Future.wait([
      backend.changeTag('old', newName: 'new'),
      backend.changeTag('new', color: '#FF0000FF'),
    ]);
    expect(backend.requireBlock(b.id).tags.single.name, 'new');
    expect(backend.requireBlock(b.id).tags.single.color, '#FF0000FF');
  });

  test(
    'adding to a collection only stores references and moving never clones the block',
    () async {
      final b = await backend.save(
        const BlockDraft(title: 'Member', atoms: ['a']),
      );
      final first = await backend.notifier.createCollection(name: 'First');
      final second = await backend.notifier.createCollection(name: 'Second');
      await backend.addToCollection([b.id, b.id], first.id);
      await backend.addToCollection([b.id], first.id);
      await backend.addToCollection(
        [b.id],
        second.id,
        sourceCollectionId: first.id,
      );
      expect(backend.library.blocks, hasLength(1));
      expect(backend.library.collectionById(first.id)!.blockIds, isEmpty);
      expect(backend.library.collectionById(second.id)!.blockIds, [b.id]);
    },
  );

  test('save refuses a stale edit baseline', () async {
    final b = await backend.save(
      const BlockDraft(title: 'Original', atoms: ['a']),
    );
    await backend.patch(b.id, const BlockPatch(title: 'User edit'));
    await expectLater(
      backend.save(
        const BlockDraft(title: 'Old', atoms: ['b']),
        id: b.id,
        expected: b,
      ),
      throwsStateError,
    );
    expect(backend.requireBlock(b.id).title, 'User edit');
  });

  test(
    'duplicate retains lineage and settings but has new identity and no import origin',
    () async {
      final b = await backend.save(
        const BlockDraft(
          title: 'Original',
          atoms: ['a'],
          params: BlockParams(steps: 12),
          negativeAtoms: ['bad'],
        ),
      );
      await backend.notifier.updateBlock(
        b.copyWith(useCount: 3, sourcePath: 'import.txt'),
      );
      final clone = await backend.duplicate(b.id);
      expect(clone.id, isNot(b.id));
      expect(clone.lineageKey, b.lineageKey);
      expect(clone.useCount, 0);
      expect(clone.sourcePath, isNull);
      expect(clone.generationSettings?.steps, 12);
      expect(clone.negativeAtoms, ['bad']);
      expect(backend.library.blocksInFolder(null).map((b) => b.id), [
        b.id,
        clone.id,
      ]);
    },
  );

  test(
    'rename tag merges collisions and deletion removes all occurrences',
    () async {
      final b = await backend.save(
        const BlockDraft(
          title: 'Tags',
          atoms: ['a'],
          tags: [BlockTag('one', Colors.red), BlockTag('two', Colors.blue)],
        ),
      );
      await backend.changeTag('one', newName: 'two');
      expect(backend.requireBlock(b.id).tags.map((t) => t.name), ['two']);
      await backend.changeTag('two', delete: true);
      expect(backend.requireBlock(b.id).tags, isEmpty);
    },
  );

  test(
    'collection removal is idempotent and never toggles absent members on',
    () async {
      final b = await backend.save(
        const BlockDraft(title: 'Member', atoms: ['a']),
      );
      final c = await backend.notifier.createCollection(name: 'Collection');
      await backend.notifier.toggleBlockInCollection(c.id, b.id);
      await backend.removeFromCollection([b.id, b.id], c.id);
      await backend.removeFromCollection([b.id], c.id);
      expect(backend.library.collectionById(c.id)!.blockIds, isEmpty);
      expect(backend.requireBlock(b.id).isFavorite, isTrue);
    },
  );

  test(
    'custom reorder preserves siblings and rejects cross-folder targets',
    () async {
      final a = await backend.save(const BlockDraft(title: 'A', atoms: ['a']));
      final b = await backend.save(const BlockDraft(title: 'B', atoms: ['b']));
      await backend.reorder(b.id, a.id);
      expect(backend.library.blocksInFolder(null).map((b) => b.id), [
        b.id,
        a.id,
      ]);
      await backend.reorder(b.id, 'missing');
      expect(backend.library.blocksInFolder(null).map((b) => b.id), [
        b.id,
        a.id,
      ]);
    },
  );

  test(
    'undo restores only its deletion, memberships and palette; cannot undo twice',
    () async {
      final a = await backend.save(const BlockDraft(title: 'A', atoms: ['a']));
      final b = await backend.save(const BlockDraft(title: 'B', atoms: ['b']));
      final c = await backend.notifier.createCollection(name: 'Collection');
      await backend.notifier.toggleBlockInCollection(c.id, a.id);
      await storage.putPaletteBlockIds([a.id, b.id]);
      final deleted = await backend.delete([a.id]);
      await backend.patch(
        b.id,
        const BlockPatch(title: 'Edited after deletion'),
      );
      await backend.undo(deleted);
      expect(backend.requireBlock(a.id).content, 'a');
      expect(backend.requireBlock(b.id).title, 'Edited after deletion');
      expect(backend.library.collectionById(c.id)!.blockIds, contains(a.id));
      expect(await storage.getPaletteBlockIds(), containsAll([a.id, b.id]));
      await backend.patch(a.id, const BlockPatch(title: 'Later edit'));
      await backend.undo(deleted);
      expect(backend.requireBlock(a.id).title, 'Later edit');
    },
  );

  test('queued failed operations do not poison later writes', () async {
    final b = await backend.save(const BlockDraft(title: 'A', atoms: ['a']));
    await expectLater(
      backend.patch('missing', const BlockPatch(title: 'No')),
      throwsStateError,
    );
    await backend.patch(b.id, const BlockPatch(title: 'Yes'));
    expect(backend.requireBlock(b.id).title, 'Yes');
  });

  test(
    'thumbnail loading cannot overwrite a concurrent library edit',
    () async {
      final delayed = DelayedThumbnail();
      final other = ProviderContainer(
        overrides: [
          promptBlockStorageProvider.overrideWithValue(storage),
          blocksPlatformProvider.overrideWithValue(delayed),
        ],
      );
      addTearDown(other.dispose);
      await other.read(promptBlockLibraryNotifierProvider.future);
      final service = other.read(blocksLibraryBackendProvider);
      final b = await service.save(
        const BlockDraft(title: 'Before', atoms: ['a']),
      );
      final saving = service.save(
        const BlockDraft(title: 'Old save', atoms: ['a'], thumbToken: 'picked'),
        id: b.id,
      );
      final expectation = expectLater(saving, throwsStateError);
      await delayed.started.future;
      await service.notifier.updateBlock(b.copyWith(title: 'Concurrent edit'));
      delayed.release.complete('${directory.path}/new.png');
      await expectation;
      expect(service.requireBlock(b.id).title, 'Concurrent edit');
    },
  );
}
