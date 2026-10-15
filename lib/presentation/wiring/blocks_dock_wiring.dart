import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/localization_extension.dart';
import '../../data/models/prompt_block/prompt_block_folder.dart';
import '../providers/layout_state_provider.dart';
import '../providers/pill_workspace_provider.dart';
import '../providers/prompt_block_library_provider.dart';
import '../providers/prompt_block_palette_provider.dart';
import '../ui/blocks/blocks_contract.dart';
import '../ui/blocks/blocks_dock.dart';
import '../widgets/prompt/blocks/prompt_block_drag_data.dart';
import 'blocks_actions.dart';
import 'blocks_library_backend.dart';
import 'blocks_mapping.dart';
import 'blocks_preferences.dart';
import '../../core/rag/rag_settings.dart';
import '../../core/rag/rag_text_search.dart';
import '../providers/rag_provider.dart';
import 'blocks_rag_wiring.dart';

class BlocksDockWiring extends ConsumerStatefulWidget {
  const BlocksDockWiring({
    super.key,
    this.fallbackScope = PillScopes.main,
    this.allowPopOut = true,
    this.onClose,
  });
  final String fallbackScope;
  final bool allowPopOut;
  final VoidCallback? onClose;
  @override
  ConsumerState<BlocksDockWiring> createState() => _BlocksDockWiringState();
}

class _BlocksDockWiringState extends ConsumerState<BlocksDockWiring> {
  String _query = '';
  BlocksDockFilter _filter = const BlocksDockFilter.all();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(promptBlockLibraryNotifierProvider);
    final prefs =
        ref.watch(blocksPreferencesProvider).valueOrNull ??
        const BlocksPreferences();
    final library =
        state.valueOrNull ??
        PromptBlockLibraryState(blocks: const [], folders: const []);
    final filter =
        _filter.folderId != null &&
            library.folderById(_filter.folderId!) == null
        ? const BlocksDockFilter.all()
        : _filter;
    final scope = filter.favorites
        ? const BlocksScope.favorites()
        : filter.folderId == null
        ? const BlocksScope.all()
        : BlocksScope.folder(filter.folderId!);
    final semantic = _query.trim().isEmpty
        ? const <RagSearchHit>[]
        : ref
                  .watch(
                    ragTextSearchProvider(
                      RagTextQuery(
                        source: RagSource.blocks,
                        query: _query.trim(),
                        allowed: mapBlocksLibrary(
                          library,
                          preferences: prefs.copyWith(scope: scope),
                        ).blocks.map((b) => b.id),
                      ),
                    ),
                  )
                  .asData
                  ?.value ??
              const <RagSearchHit>[];
    final data = mapBlocksLibrary(
      library,
      preferences: prefs.copyWith(scope: scope),
      query: _query,
      semanticIds: semantic.map((hit) => hit.id).toList(),
    );
    final host = BlocksActions(ref, context, () => mounted && context.mounted);
    final backend = ref.read(blocksLibraryBackendProvider);
    final folders = library.foldersIn(null);
    final groups = <BlocksDockGroup>[];
    if (!filter.favorites) {
      final groupFolders = filter.folderId == null
          ? library.folders
          : library.folders.where(
              (f) =>
                  f.id == filter.folderId ||
                  library.folders
                      .getDescendantIds(filter.folderId!)
                      .contains(f.id),
            );
      for (final folder in groupFolders) {
        final blocks = library.blocksInFolder(folder.id);
        if (blocks.isEmpty) continue;
        groups.add(
          BlocksDockGroup(
            id: folder.id,
            name: library.folderPath(folder.id),
            count: blocks.length,
            expanded: !prefs.collapsed.contains(folder.id),
            blocks: blocks.map((b) => blockDataOf(b, library)).toList(),
          ),
        );
      }
      if (filter.isAll && library.blocksInFolder(null).isNotEmpty) {
        final blocks = library.blocksInFolder(null);
        groups.insert(
          0,
          BlocksDockGroup(
            id: '',
            name: context.l10n.blocks_uncategorized,
            count: blocks.length,
            expanded: !prefs.collapsed.contains(''),
            blocks: blocks.map((b) => blockDataOf(b, library)).toList(),
          ),
        );
      }
    }
    return Material(
      type: MaterialType.transparency,
      child: BlocksDock(
        data: BlocksDockViewData(
          total: library.blocks.length,
          loading: state.isLoading,
          query: _query,
          filter: filter,
          chips: [
            for (final f in folders)
              BlocksDockChip(
                id: f.id,
                name: f.name,
                count: library.blocksInFolderTree(f.id).length,
              ),
          ],
          favorites: library.favoriteBlocks
              .map((b) => blockDataOf(b, library))
              .toList(),
          recent: recentBlocks(
            library,
            prefs.recentIds,
          ).take(8).map((b) => blockDataOf(b, library)).toList(),
          groups: groups,
          results: data.blocks,
          rag: blocksRagStatus(ref, context),
        ),
        actions: BlocksDockActions(
          onQueryChanged: (value) => setState(() => _query = value),
          onFilterChanged: (value) => setState(() {
            _filter = value;
            _query = '';
          }),
          onInsert: (id) =>
              host.insert([id], fallbackScope: widget.fallbackScope),
          dragDataOf: (id) => PromptBlockDragData(blockId: id),
          onCreate: () => host.edit(folderId: filter.folderId),
          onEdit: (id) => host.edit(id: id),
          onOpenLibrary: () => host.showInLibrary(null),
          onShowInLibrary: host.showInLibrary,
          onClose:
              widget.onClose ??
              () => ref
                  .read(layoutStateNotifierProvider.notifier)
                  .setBlockLibraryPanelExpanded(false),
          onToggleGroup: (id, expanded) => host.preference(
            (p) => p.copyWith(
              collapsed: expanded
                  ? (Set.of(p.collapsed)..remove(id))
                  : {...p.collapsed, id},
            ),
          ),
          onSetFavorite: (id, value) => host.run(
            () => backend.serialize(
              () => backend.notifier.setFavorite([id], value),
            ),
          ),
          onAddToPalette: (id) => host.run(
            () => ref
                .read(promptBlockPaletteNotifierProvider.notifier)
                .addBlock(id),
          ),
          onPopOut: !widget.allowPopOut
              ? null
              : () => showDialog<void>(
                  context: context,
                  builder: (ctx) => Dialog(
                    child: SizedBox(
                      width: 300,
                      height: 600,
                      child: BlocksDockWiring(
                        fallbackScope: widget.fallbackScope,
                        allowPopOut: false,
                        onClose: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
