import 'dart:io';
import 'dart:convert';

import 'package:flutter/painting.dart';

import '../../data/models/prompt_block/pill_document.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../../data/models/prompt_block/prompt_block_sort.dart';
import '../providers/prompt_block_library_provider.dart';
import '../ui/blocks/blocks_contract.dart';
import '../widgets/prompt/blocks/prompt_block_colors.dart';
import 'blocks_preferences.dart';

BlockAppearance blockLook(String value) =>
    BlockAppearance.values.asNameMap()[value] ?? BlockAppearance.classic;
String blockColorString(Color value) =>
    '#${value.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

BlockParams? blockParamsOf(
  PromptBlockGenerationSettings? value, {
  String? incompatible,
}) => value == null
    ? null
    : BlockParams(
        model: value.model,
        steps: value.steps,
        scale: value.scale,
        cfgRescale: value.cfgRescale,
        sampler: value.sampler,
        noiseSchedule: value.noiseSchedule,
        width: value.width,
        height: value.height,
        incompatible: incompatible,
      );
PromptBlockGenerationSettings? storedBlockParams(BlockParams? value) =>
    value == null
    ? null
    : PromptBlockGenerationSettings(
        model: value.model,
        steps: value.steps,
        scale: value.scale,
        cfgRescale: value.cfgRescale,
        sampler: value.sampler,
        noiseSchedule: value.noiseSchedule,
        width: value.width,
        height: value.height,
      );

Map<String, dynamic> blockDraftSnapshot(BlockDraft draft) {
  final image = draft.thumb?.image;
  return {
    'title': draft.title,
    'atoms': draft.atoms,
    'text': draft.text,
    'negativeAtoms': draft.negativeAtoms,
    'color': draft.color.toARGB32(),
    'icon': draft.icon,
    'look': draft.look.name,
    'folderId': draft.folderId,
    'tags': [
      for (final t in draft.tags) {'name': t.name, 'color': t.color.toARGB32()},
    ],
    'params': storedBlockParams(draft.params)?.toJson(),
    'thumb': draft.thumb == null
        ? null
        : {
            if (image is FileImage) 'path': image.file.path,
            if (image is MemoryImage) 'bytes': base64Encode(image.bytes),
            'x': draft.thumb!.offsetX,
            'y': draft.thumb!.offsetY,
            'scale': draft.thumb!.scale,
          },
    'thumbToken': draft.thumbToken,
    'clearThumb': draft.clearThumb,
  };
}

BlockData blockDataOf(
  PromptBlock b,
  PromptBlockLibraryState library, {
  BlockSourceState sourceState = BlockSourceState.none,
  String? incompatible,
}) => BlockData(
  id: b.id,
  title: b.displayTitle,
  color: promptBlockColorFromString(b.color),
  icon: b.iconName,
  look: blockLook(b.appearance),
  atoms: b.atomsOrSplit,
  negativeAtoms: b.negativeAtomsOrSplit,
  params: blockParamsOf(b.generationSettings, incompatible: incompatible),
  tags: [
    for (final t in b.tags)
      BlockTag(t.name, promptBlockColorFromString(t.color)),
  ],
  folderId: b.folderId,
  folderName: b.folderId == null ? null : library.folderById(b.folderId!)?.name,
  thumb: b.hasThumbnail
      ? BlockThumb(
          FileImage(File(b.thumbnail!)),
          offsetX: b.thumbnailOffsetX,
          offsetY: b.thumbnailOffsetY,
          scale: b.thumbnailScale,
        )
      : null,
  useCount: b.useCount,
  favorite: b.isFavorite,
  createdAt: b.createdAt.toLocal(),
  updatedAt: b.updatedAt.toLocal(),
  sourcePath: b.sourcePath,
  importedAt: b.importedAt?.toLocal(),
  sourceState: sourceState,
  reading: b.readingTranslationZh,
  readingNeedsReview: b.readingTranslationNeedsReview,
);

List<BlocksFolder> blockFoldersOf(
  PromptBlockLibraryState library,
  Set<String> expanded,
) {
  final result = <BlocksFolder>[];
  final visited = <String>{};
  void visit(String? parent, int depth) {
    for (final f in library.foldersIn(parent)) {
      if (!visited.add(f.id)) continue;
      result.add(
        BlocksFolder(
          id: f.id,
          name: f.name,
          parentId: f.parentId,
          depth: depth,
          count: library.blocksInFolderTree(f.id).length,
          hasChildren: library.foldersIn(f.id).isNotEmpty,
          expanded: expanded.contains(f.id),
        ),
      );
      visit(f.id, depth + 1);
    }
  }

  visit(null, 0);
  return result;
}

BlocksScope validBlocksScope(
  PromptBlockLibraryState library,
  BlocksScope scope,
) => switch (scope.kind) {
  BlocksScopeKind.folder when library.folderById(scope.id ?? '') == null =>
    const BlocksScope.all(),
  BlocksScopeKind.collection
      when library.collectionById(scope.id ?? '') == null =>
    const BlocksScope.favorites(),
  BlocksScopeKind.tag
      when !library.blocks.any((b) => b.tags.any((t) => t.name == scope.id)) =>
    const BlocksScope.all(),
  _ => scope,
};

List<PromptBlock> recentBlocks(
  PromptBlockLibraryState library,
  List<String> ids,
) {
  final live = {for (final b in library.blocks) b.id: b};
  return [
    for (final id in ids.toSet())
      if (live[id] case final b?) b,
  ];
}

bool blockMatches(PromptBlock block, String query) {
  String normalize(String value) => value.toLowerCase().replaceAll('_', ' ');
  final haystack = normalize(
    '${block.title} ${block.content} ${block.negativeContent} ${block.tags.map((t) => t.name).join(' ')}',
  );
  return normalize(query).trim().split(RegExp(r'\s+')).every(haystack.contains);
}

BlocksLibraryViewData mapBlocksLibrary(
  PromptBlockLibraryState library, {
  BlocksPreferences preferences = const BlocksPreferences(),
  String query = '',
  List<String> semanticIds = const [],
  BlocksRagStatus rag = const BlocksRagStatus(),
  Set<BlocksQuick> quick = const {},
  String? selectedId,
  bool loading = false,
  BlockParamCatalog catalog = const BlockParamCatalog(),
  Set<String> paletteIds = const {},
  Map<String, BlockSourceState> sourceStates = const {},
  String? Function(PromptBlock)? incompatibility,
}) {
  final scope = validBlocksScope(library, preferences.scope);
  final recent = recentBlocks(library, preferences.recentIds);
  final scoped = switch (scope.kind) {
    BlocksScopeKind.all => library.blocks,
    BlocksScopeKind.recent => recent,
    BlocksScopeKind.favorites => library.favoriteBlocks,
    BlocksScopeKind.uncategorized => library.blocksInFolder(null),
    BlocksScopeKind.folder => library.blocksInFolderTree(scope.id),
    BlocksScopeKind.collection => library.blocksInCollectionTree(scope.id!),
    BlocksScopeKind.tag =>
      library.blocks
          .where((b) => b.tags.any((t) => t.name == scope.id))
          .toList(),
  };
  var filtered = scoped
      .where(
        (b) =>
            (blockMatches(b, query) ||
                (query.trim().isNotEmpty && semanticIds.contains(b.id))) &&
            (!quick.contains(BlocksQuick.image) || b.hasThumbnail) &&
            (!quick.contains(BlocksQuick.negative) ||
                b.negativeContent.isNotEmpty) &&
            (!quick.contains(BlocksQuick.params) ||
                b.generationSettings?.isEmpty == false),
      )
      .toList();
  if (scope.kind != BlocksScopeKind.recent) {
    if (preferences.sort == BlocksSort.custom &&
        scope.kind != BlocksScopeKind.collection) {
      final order = library.folderTreeOrder();
      filtered.sort((a, b) {
        final folders = (order[a.folderId] ?? 0).compareTo(
          order[b.folderId] ?? 0,
        );
        final sort = a.sortOrder.compareTo(b.sortOrder);
        return folders != 0
            ? folders
            : sort != 0
            ? sort
            : a.id.compareTo(b.id);
      });
    } else {
      filtered = sortPromptBlocks(
        filtered,
        PromptBlockSortField.values.byName(preferences.sort.name),
        descending: preferences.descending,
        folderOrder: library.folderTreeOrder(),
      );
    }
  }
  if (query.trim().isNotEmpty && semanticIds.isNotEmpty) {
    final original = {
      for (var i = 0; i < filtered.length; i++) filtered[i].id: i,
    };
    final semantic = {
      for (var i = 0; i < semanticIds.length; i++) semanticIds[i]: i,
    };
    String normalize(String value) =>
        value.toLowerCase().replaceAll('_', ' ').trim();
    int group(PromptBlock b) => normalize(b.title) == normalize(query)
        ? 0
        : blockMatches(b, query)
        ? 1
        : 2;
    filtered.sort((a, b) {
      final order = group(a).compareTo(group(b));
      if (order != 0) return order;
      return group(a) < 2
          ? original[a.id]!.compareTo(original[b.id]!)
          : semantic[a.id]!.compareTo(semantic[b.id]!);
    });
  }
  final tags = <String, (BlockTag, int)>{};
  for (final b in library.blocks) {
    final seen = <String>{};
    for (final t in b.tags) {
      if (!seen.add(t.name)) continue;
      final old = tags[t.name];
      tags[t.name] = (
        old?.$1 ?? BlockTag(t.name, promptBlockColorFromString(t.color)),
        (old?.$2 ?? 0) + 1,
      );
    }
  }
  final tagInfos = [for (final t in tags.values) BlocksTagInfo(t.$1, t.$2)]
    ..sort(
      (a, b) => a.count == b.count
          ? a.tag.name.compareTo(b.tag.name)
          : b.count.compareTo(a.count),
    );
  final collections = <BlocksCollection>[];
  final visited = <String>{};
  void visitCollections(String? parent, int depth) {
    for (final c in library.collectionsIn(parent)) {
      if (!visited.add(c.id)) continue;
      collections.add(
        BlocksCollection(
          id: c.id,
          name: c.name,
          parentId: c.parentId,
          depth: depth,
          isFolder: c.isFolder,
          count: library.collectionTreeBlockCount(c.id),
        ),
      );
      visitCollections(c.id, depth + 1);
    }
  }

  visitCollections(null, 0);
  return BlocksLibraryViewData(
    now: DateTime.now(),
    loading: loading,
    blocks: [
      for (final b in filtered)
        blockDataOf(
          b,
          library,
          sourceState: sourceStates[b.id] ?? BlockSourceState.none,
          incompatible: incompatibility?.call(b),
        ),
    ],
    counts: BlocksCounts(
      all: library.blocks.length,
      favorites: library.favoriteBlocks.length,
      recent: recent.length,
      uncategorized: library.blocksInFolder(null).length,
    ),
    folders: blockFoldersOf(library, preferences.expanded),
    collections: collections,
    tags: tagInfos,
    scope: scope,
    query: query,
    sort: preferences.sort,
    descending: preferences.descending,
    view: preferences.view,
    quick: quick,
    cardSize: preferences.cardSize,
    sidebarOpen: preferences.sidebarOpen,
    inspectorOpen: preferences.inspectorOpen,
    selectedId: filtered.any((b) => b.id == selectedId) ? selectedId : null,
    catalog: catalog,
    paletteIds: paletteIds,
    rag: rag,
  );
}

BlockRollSettings toBlockRollSettings(PillInstanceSettings s) =>
    BlockRollSettings(
      mode: BlockMode.values.byName(s.mode.name),
      countMin: s.countMin,
      countMax: s.countMax,
      order: BlockOrder.values.byName(s.order.name),
      weightEnabled: s.weightEnabled,
      weightMin: s.weightMin,
      weightMax: s.weightMax,
      weightAverage: s.weightAverage,
      leftDispersion: s.leftDispersion,
      rightDispersion: s.rightDispersion,
      softBalance: s.softBalance,
      softBalanceStrength: s.softBalanceStrength,
      probability: s.triggerProbability,
    );
PillInstanceSettings toPillSettings(BlockRollSettings s) =>
    PillInstanceSettings(
      mode: PillRollMode.values.byName(s.mode.name),
      countMin: s.countMin,
      countMax: s.countMax,
      order: PillRollOrder.values.byName(s.order.name),
      weightEnabled: s.weightEnabled,
      weightMin: s.weightMin,
      weightMax: s.weightMax,
      weightAverage: s.weightAverage,
      leftDispersion: s.leftDispersion,
      rightDispersion: s.rightDispersion,
      softBalance: s.softBalance,
      softBalanceStrength: s.softBalanceStrength,
      triggerProbability: s.probability,
    );
