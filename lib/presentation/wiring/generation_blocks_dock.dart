import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/localization_extension.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../providers/layout_state_provider.dart';
import '../providers/pill_workspace_provider.dart';
import '../providers/pill_roll_coordinator.dart';
import '../providers/prompt_block_library_provider.dart';
import '../providers/prompt_block_palette_provider.dart';
import '../router/app_router.dart';
import 'blocks_actions.dart';
import '../ui/blocks/blocks_contract.dart';
import '../ui/blocks/blocks_dock.dart';
import '../utils/prompt_block_bundle_insertion.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/prompt/blocks/prompt_block_colors.dart';
import '../widgets/prompt/blocks/prompt_block_drag_data.dart';
import 'generation_backend.dart';

BlockData generationBlockData(
  PromptBlock block,
  PromptBlockLibraryState library,
) => BlockData(
  id: block.id,
  title: block.displayTitle,
  color: promptBlockColorFromString(block.color),
  icon: block.iconName,
  look:
      BlockAppearance.values.asNameMap()[block.appearance] ??
      BlockAppearance.classic,
  atoms: block.atomsOrSplit,
  negativeAtoms: block.negativeAtomsOrSplit,
  params: block.generationSettings == null
      ? null
      : BlockParams(
          model: block.generationSettings!.model,
          steps: block.generationSettings!.steps,
          scale: block.generationSettings!.scale,
          cfgRescale: block.generationSettings!.cfgRescale,
          sampler: block.generationSettings!.sampler,
          noiseSchedule: block.generationSettings!.noiseSchedule,
          width: block.generationSettings!.width,
          height: block.generationSettings!.height,
        ),
  tags: [
    for (final tag in block.tags)
      BlockTag(tag.name, promptBlockColorFromString(tag.color)),
  ],
  folderId: block.folderId,
  folderName: block.folderId == null
      ? null
      : library.folderById(block.folderId!)?.name,
  thumb: block.hasThumbnail
      ? BlockThumb(
          FileImage(File(block.thumbnail!)),
          offsetX: block.thumbnailOffsetX,
          offsetY: block.thumbnailOffsetY,
          scale: block.thumbnailScale,
        )
      : null,
  useCount: block.useCount,
  favorite: block.isFavorite,
  createdAt: block.createdAt.toLocal(),
  updatedAt: block.updatedAt.toLocal(),
  sourcePath: block.sourcePath,
  importedAt: block.importedAt?.toLocal(),
  reading: block.readingTranslationZh,
  readingNeedsReview: block.readingTranslationNeedsReview,
);

class BlocksDockWiring extends ConsumerStatefulWidget {
  const BlocksDockWiring({
    super.key,
    this.fallbackScope = PillScopes.main,
    this.onInsert,
  });
  final String fallbackScope;

  /// 换掉默认的插入写入（画风探索用自己的草稿保护）。
  final Future<void> Function(String id)? onInsert;
  @override
  ConsumerState<BlocksDockWiring> createState() => _BlocksDockWiringState();
}

class _BlocksDockWiringState extends ConsumerState<BlocksDockWiring> {
  String query = '';
  BlocksDockFilter filter = const BlocksDockFilter.all();
  final collapsed = <String>{};
  void run(Future<void> Function() job) async {
    try {
      await job();
    } catch (error) {
      if (mounted) AppToast.error(context, error.toString());
    }
  }

  Future<void> insert(String id) async {
    final target = ref.read(pillActiveEditorTargetProvider);
    final scope = target?.scope ?? widget.fallbackScope;
    final write = ref
        .read(generationBackendProvider)
        .captureDraft(
          alive: () =>
              mounted && ref.read(pillActiveEditorTargetProvider) == target,
        );
    await write(() {
      final lane = pillWorkspaceProvider(scope);
      final offset = (target?.caret ?? ref.read(lane).document.text.length)
          .clamp(0, ref.read(lane).document.text.length);
      insertPromptBlockBundle(ref, scope: scope, offset: offset, blockId: id);
      ref
          .read(pillRollCoordinatorProvider)
          .syncLaneProjection(scope, ref.read(lane).projection);
      if (scope == PillScopes.main || scope == PillScopes.negative) {
        final paired = pillWorkspaceProvider(
          scope == PillScopes.main ? PillScopes.negative : PillScopes.main,
        );
        ref
            .read(pillRollCoordinatorProvider)
            .syncLaneProjection(
              scope == PillScopes.main ? PillScopes.negative : PillScopes.main,
              ref.read(paired).projection,
            );
      }
    });
  }

  Future<void> edit(String? id) async {
    await ref.read(promptBlockLibraryNotifierProvider.future);
    if (!mounted) return;
    await BlocksActions(
      ref,
      context,
      () => mounted,
    ).edit(id: id, folderId: filter.folderId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(promptBlockLibraryNotifierProvider);
    final library =
        state.valueOrNull ??
        PromptBlockLibraryState(blocks: const [], folders: const []);
    BlockData map(PromptBlock block) => generationBlockData(block, library);
    final filtered = library.blocks
        .where(
          (block) =>
              (!filter.favorites || block.isFavorite) &&
              (filter.folderId == null ||
                  library
                      .blocksInFolderTree(filter.folderId!)
                      .any((item) => item.id == block.id)) &&
              (query.trim().isEmpty ||
                  '${block.displayTitle} ${block.content} ${block.tags.map((tag) => tag.name).join(' ')}'
                      .toLowerCase()
                      .contains(query.toLowerCase())),
        )
        .toList();
    final folders = filter.folderId == null
        ? library.folders
        : library.folders.where(
            (folder) => library
                .blocksInFolderTree(filter.folderId!)
                .any((block) => block.folderId == folder.id),
          );
    return BlocksDock(
      data: BlocksDockViewData(
        total: library.blocks.length,
        loading: state.isLoading,
        query: query,
        filter: filter,
        chips: [
          for (final folder in library.foldersIn(null))
            BlocksDockChip(
              id: folder.id,
              name: folder.name,
              count: library.blocksInFolderTree(folder.id).length,
            ),
        ],
        favorites: library.favoriteBlocks.map(map).toList(),
        recent:
            (library.blocks.toList()
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)))
                .where((block) => block.useCount > 0)
                .take(8)
                .map(map)
                .toList(),
        groups: [
          if (filter.isAll && library.blocksInFolder(null).isNotEmpty)
            BlocksDockGroup(
              id: '',
              name: context.l10n.blocks_uncategorized,
              count: library.blocksInFolder(null).length,
              blocks: library.blocksInFolder(null).map(map).toList(),
              expanded: !collapsed.contains(''),
            ),
          if (!filter.favorites)
            for (final folder in folders)
              BlocksDockGroup(
                id: folder.id,
                name: library.folderPath(folder.id),
                count: library.blocksInFolder(folder.id).length,
                blocks: library.blocksInFolder(folder.id).map(map).toList(),
                expanded: !collapsed.contains(folder.id),
              ),
        ],
        results: filtered.map(map).toList(),
      ),
      actions: BlocksDockActions(
        onQueryChanged: (value) => setState(() => query = value),
        onFilterChanged: (value) => setState(() {
          filter = value;
          query = '';
        }),
        onInsert: (id) => run(() => (widget.onInsert ?? insert)(id)),
        dragDataOf: (id) => PromptBlockDragData(blockId: id),
        onCreate: () => run(() => edit(null)),
        onEdit: (id) => run(() => edit(id)),
        onOpenLibrary: () => context.go(AppRoutes.promptBlockLibrary),
        onShowInLibrary: (id) =>
            context.go('${AppRoutes.promptBlockLibrary}?block=$id'),
        onClose: () => run(
          () => ref
              .read(layoutStateNotifierProvider.notifier)
              .setBlockLibraryPanelExpanded(false),
        ),
        onToggleGroup: (id, expanded) => setState(() {
          if (expanded) {
            collapsed.remove(id);
          } else {
            collapsed.add(id);
          }
        }),
        onSetFavorite: (id, value) => run(
          () => ref
              .read(promptBlockLibraryNotifierProvider.notifier)
              .setFavorite([id], value),
        ),
        onAddToPalette: (id) => run(
          () => ref
              .read(promptBlockPaletteNotifierProvider.notifier)
              .addBlock(id),
        ),
      ),
    );
  }
}
