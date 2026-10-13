import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../../core/utils/localization_extension.dart';
import '../../core/utils/prompt_block_thumbnails.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../../data/models/prompt_block/prompt_block_collection.dart';
import '../providers/prompt_block_library_provider.dart';
import '../ui/blocks/blocks_contract.dart';
import 'blocks_mapping.dart';
import 'blocks_platform.dart';

final blocksLibraryBackendProvider = Provider<BlocksLibraryBackend>(
  (ref) => BlocksLibraryBackend(ref),
);

class BlocksDeletion {
  BlocksDeletion(
    this.blocks,
    this.collections,
    this.thumbnails,
    this.paletteIds,
  );
  final List<PromptBlock> blocks;
  final List<PromptBlockCollection> collections;
  final Map<String, Uint8List> thumbnails;
  final List<String> paletteIds;
  bool restored = false;
}

class BlocksLibraryBackend {
  BlocksLibraryBackend(this.ref);
  final Ref ref;
  Future<void> _pending = Future.value();
  PromptBlockLibraryState get library =>
      ref.read(promptBlockLibraryNotifierProvider).requireValue;
  PromptBlockLibraryNotifier get notifier =>
      ref.read(promptBlockLibraryNotifierProvider.notifier);

  Future<T> serialize<T>(Future<T> Function() operation) {
    final next = _pending.then((_) => operation());
    _pending = next.then((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  PromptBlock requireBlock(String id) =>
      library.blockById(id) ??
      (throw StateError(currentL10n.promptBlockPill_missing));

  List<PromptBlockTag> tagsOf(List<BlockTag> tags) {
    final byName = <String, PromptBlockTag>{};
    for (final tag in tags) {
      final name = tag.name.trim();
      if (name.isNotEmpty) {
        byName.putIfAbsent(
          name,
          () => PromptBlockTag(name: name, color: blockColorString(tag.color)),
        );
      }
    }
    return byName.values.toList();
  }

  Future<void> discardUnusedThumbnail(String path) async {
    try {
      final blocks = await ref.read(promptBlockStorageProvider).getBlocks();
      if (!blocks.any((b) => b.thumbnail == path)) {
        await deletePromptBlockThumbnail(path);
      }
    } catch (_) {}
  }

  Future<PromptBlock> save(
    BlockDraft draft, {
    String? id,
    PromptBlock? expected,
  }) => serialize(() async {
    final before = id == null ? null : requireBlock(id);
    if (expected != null && before != expected) {
      throw StateError(currentL10n.bridge_conflict);
    }
    String? thumbnail = draft.clearThumb ? null : before?.thumbnail;
    String? createdThumbnail;
    if (draft.thumbToken case final token?) {
      createdThumbnail = await ref
          .read(blocksPlatformProvider)
          .saveThumbnail(token);
      thumbnail = createdThumbnail;
    }
    try {
      if (id != null && requireBlock(id) != before) {
        throw StateError(currentL10n.bridge_conflict);
      }
      final keepPlain =
          before != null &&
          before.atoms == null &&
          draft.atoms != null &&
          const ListEquality<String>().equals(draft.atoms, before.atomsOrSplit);
      final atoms = keepPlain ? null : draft.atoms;
      final content = keepPlain
          ? before.content
          : atoms?.join(', ') ?? draft.text ?? '';
      final keepNegative =
          before != null &&
          before.negativeAtoms == null &&
          const ListEquality<String>().equals(
            draft.negativeAtoms,
            before.negativeAtomsOrSplit,
          );
      final negativeAtoms = keepNegative ? null : draft.negativeAtoms;
      final negative = keepNegative
          ? before.negativeContent
          : draft.negativeAtoms.join(', ');
      final tags = tagsOf(draft.tags);
      final params = storedBlockParams(draft.params);
      final thumb = draft.thumb;
      final result = before == null
          ? await notifier.createBlock(
              title: draft.title,
              content: content,
              atoms: atoms,
              negativeContent: negative,
              negativeAtoms: negativeAtoms,
              folderId: draft.folderId,
              color: blockColorString(draft.color),
              appearance: draft.look.name,
              iconName: draft.icon,
              tags: tags,
              generationSettings: params,
              thumbnail: thumbnail,
              thumbnailOffsetX: thumb?.offsetX ?? 0,
              thumbnailOffsetY: thumb?.offsetY ?? 0,
              thumbnailScale: thumb?.scale ?? 1,
            )
          : await notifier.updateBlock(
              before.copyWith(
                title: draft.title.trim(),
                content: content,
                atoms: atoms,
                negativeContent: negative,
                negativeAtoms: negativeAtoms,
                folderId: draft.folderId,
                color: blockColorString(draft.color),
                appearance: draft.look.name,
                iconName: draft.icon,
                tags: tags,
                generationSettings: params,
                thumbnail: thumbnail,
                thumbnailOffsetX: thumb?.offsetX ?? 0,
                thumbnailOffsetY: thumb?.offsetY ?? 0,
                thumbnailScale: thumb?.scale ?? 1,
                readingTranslationNeedsReview:
                    before.readingTranslationNeedsReview ||
                    (before.readingTranslationZh != null &&
                        content != before.content),
              ),
            );
      if (before?.thumbnail != thumbnail && before?.thumbnail != null) {
        await discardUnusedThumbnail(before!.thumbnail!);
      }
      return result;
    } catch (_) {
      if (createdThumbnail != null) {
        await discardUnusedThumbnail(createdThumbnail);
      }
      rethrow;
    }
  });

  Future<void> patch(String id, BlockPatch patch) => serialize(() async {
    final b = requireBlock(id);
    await notifier.updateBlock(
      b.copyWith(
        title: patch.title?.trim() ?? b.title,
        color: patch.color == null ? b.color : blockColorString(patch.color!),
        iconName: patch.clearIcon ? null : patch.icon ?? b.iconName,
        appearance: patch.look?.name ?? b.appearance,
        folderId: patch.toRoot ? null : patch.folderId ?? b.folderId,
        tags: patch.tags == null ? b.tags : tagsOf(patch.tags!),
      ),
    );
  });

  Future<void> mapBlocks(
    List<String> ids,
    PromptBlock Function(PromptBlock) change,
  ) => serialize(() async {
    for (final id in ids.toSet()) {
      final b = library.blockById(id);
      if (b != null) await notifier.updateBlock(change(b));
    }
  });

  Future<PromptBlock> duplicate(String id) => serialize(() async {
    final b = requireBlock(id);
    final storage = ref.read(promptBlockStorageProvider);
    final siblings = library.blocksInFolder(b.folderId);
    final clone = PromptBlock.create(
      title: '${b.displayTitle} ${currentL10n.blocks_duplicate}',
      content: b.content,
      lineageId: b.lineageKey,
      atoms: b.atoms,
      negativeContent: b.negativeContent,
      negativeAtoms: b.negativeAtoms,
      generationSettings: b.generationSettings,
      tags: b.tags,
      folderId: b.folderId,
      color: b.color,
      appearance: b.appearance,
      iconName: b.iconName,
      isFavorite: b.isFavorite,
      readingTranslationZh: b.readingTranslationZh,
      readingTranslationMarks: b.readingTranslationMarks,
      readingTranslationNeedsReview: b.readingTranslationNeedsReview,
      readingTranslationLanguageCode: b.readingTranslationLanguageCode,
      readingTranslationEdited: b.readingTranslationEdited,
      thumbnail: b.hasThumbnail
          ? await savePromptBlockThumbnail(
              await File(b.thumbnail!).readAsBytes(),
            )
          : null,
      thumbnailOffsetX: b.thumbnailOffsetX,
      thumbnailOffsetY: b.thumbnailOffsetY,
      thumbnailScale: b.thumbnailScale,
    );
    if (await storage.getBlock(id) != b || requireBlock(id) != b) {
      if (clone.thumbnail != null) {
        await discardUnusedThumbnail(clone.thumbnail!);
      }
      throw StateError(currentL10n.bridge_conflict);
    }
    await storage.putBlock(clone);
    final ids = siblings.map((b) => b.id).toList();
    ids.insert(ids.indexOf(id) + 1, clone.id);
    await notifier.reorderBlocks(b.folderId, ids);
    return library.blockById(clone.id)!;
  });

  Future<void> reorder(String id, String? beforeId) => serialize(() async {
    final b = requireBlock(id);
    final siblings = library
        .blocksInFolder(b.folderId)
        .map((b) => b.id)
        .toList();
    if (id == beforeId || (beforeId != null && !siblings.contains(beforeId))) {
      return;
    }
    siblings.remove(id);
    siblings.insert(
      beforeId == null ? siblings.length : siblings.indexOf(beforeId),
      id,
    );
    await notifier.reorderBlocks(b.folderId, siblings);
  });

  Future<void> addToCollection(
    List<String> ids,
    String collectionId, {
    String? sourceCollectionId,
  }) => serialize(() async {
    final target = library.collectionById(collectionId);
    if (target == null || target.isFolder) {
      throw StateError(currentL10n.blockLibrary_collectionMissing);
    }
    for (final id in ids.toSet()) {
      requireBlock(id);
      if (library.collectionById(collectionId)?.blockIds.contains(id) != true) {
        await notifier.toggleBlockInCollection(collectionId, id);
      }
      if (sourceCollectionId == null || sourceCollectionId == collectionId) {
        continue;
      }
      final source = library.collectionById(sourceCollectionId);
      final sources = source?.isFolder == true
          ? library.collections.getDescendantIds(sourceCollectionId)
          : {sourceCollectionId};
      for (final sourceId in sources) {
        if (sourceId != collectionId &&
            library.collectionById(sourceId)?.blockIds.contains(id) == true) {
          await notifier.toggleBlockInCollection(sourceId, id);
        }
      }
    }
  });

  Future<void> removeFromCollection(List<String> ids, String collectionId) =>
      serialize(() async {
        for (final id in ids.toSet()) {
          if (library.collectionById(collectionId)?.blockIds.contains(id) ==
              true) {
            await notifier.toggleBlockInCollection(collectionId, id);
          }
        }
      });

  Future<void> changeTag(
    String name, {
    String? newName,
    String? color,
    bool delete = false,
  }) => serialize(() async {
    final ids = library.blocks
        .where((b) => b.tags.any((t) => t.name == name))
        .map((b) => b.id)
        .toList();
    for (final id in ids) {
      final b = requireBlock(id);
      final tags = <String, PromptBlockTag>{};
      for (final t in b.tags) {
        if (t.name == name && delete) continue;
        final next = t.name == name
            ? t.copyWith(
                name: newName?.trim() ?? t.name,
                color: color ?? t.color,
              )
            : t;
        if (next.name.isNotEmpty) {
          tags.putIfAbsent(next.name, () => next);
        }
      }
      await notifier.updateBlock(b.copyWith(tags: tags.values.toList()));
    }
  });

  Future<BlocksDeletion> delete(List<String> ids) => serialize(() async {
    final blocks = [
      for (final id in ids.toSet())
        if (library.blockById(id) case final b?) b,
    ];
    final thumbnails = <String, Uint8List>{};
    for (final b in blocks) {
      if (b.hasThumbnail && await File(b.thumbnail!).exists()) {
        thumbnails[b.id] = await File(b.thumbnail!).readAsBytes();
      }
    }
    final snapshot = BlocksDeletion(
      blocks,
      library.collections,
      thumbnails,
      await ref.read(promptBlockStorageProvider).getPaletteBlockIds(),
    );
    for (final b in blocks) {
      if (library.blockById(b.id) != b) {
        throw StateError(currentL10n.bridge_conflict);
      }
    }
    await notifier.deleteBlocks(blocks.map((b) => b.id).toList());
    return snapshot;
  });

  Future<void> undo(BlocksDeletion deletion) => serialize(() async {
    if (deletion.restored) return;
    final storage = ref.read(promptBlockStorageProvider);
    for (final b in deletion.blocks) {
      if (await storage.getBlock(b.id) != null) {
        throw StateError(currentL10n.bridge_conflict);
      }
    }
    for (final b in deletion.blocks) {
      final bytes = deletion.thumbnails[b.id];
      await storage.putBlock(
        b.copyWith(
          folderId:
              b.folderId == null || library.folderById(b.folderId!) != null
              ? b.folderId
              : null,
          thumbnail: bytes == null
              ? null
              : await savePromptBlockThumbnail(bytes),
        ),
      );
    }
    final restoredIds = deletion.blocks.map((b) => b.id).toSet();
    for (final old in deletion.collections) {
      final current = await storage.getCollection(old.id);
      if (current == null) continue;
      await storage.putCollection(
        current.copyWith(
          blockIds: {
            ...current.blockIds,
            ...old.blockIds.where(restoredIds.contains),
          }.toList(),
        ),
      );
    }
    final palette = await storage.getPaletteBlockIds();
    await storage.putPaletteBlockIds(
      {...palette, ...deletion.paletteIds.where(restoredIds.contains)}.toList(),
    );
    deletion.restored = true;
    await notifier.refresh();
  });
}
