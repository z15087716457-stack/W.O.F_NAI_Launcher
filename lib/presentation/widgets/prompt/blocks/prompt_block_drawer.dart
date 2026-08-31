import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../../data/models/prompt_block/prompt_block_folder.dart';
import '../../../providers/prompt_block_library_provider.dart';
import 'prompt_block_colors.dart';
import 'prompt_block_drag_data.dart';

/// 生成页右侧的 Prompt 块库侧签。
///
/// 宽屏直接作为无 barrier 的侧栏使用；窄屏由编辑器放入 modal dialog，
/// 因此拖拽不是窄屏的必要交互。
class PromptBlockDrawer extends ConsumerStatefulWidget {
  const PromptBlockDrawer({
    super.key,
    required this.onInsertBlock,
    this.initialFolderId,
    this.compact = false,
    this.onClose,
  });

  final ValueChanged<PromptBlock> onInsertBlock;
  final String? initialFolderId;
  final bool compact;
  final VoidCallback? onClose;

  @override
  ConsumerState<PromptBlockDrawer> createState() => _PromptBlockDrawerState();
}

class _PromptBlockDrawerState extends ConsumerState<PromptBlockDrawer> {
  late final TextEditingController _searchController;
  String? _folderId;

  @override
  void initState() {
    super.initState();
    _folderId = widget.initialFolderId;
    _searchController = TextEditingController()..addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(PromptBlockDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFolderId != widget.initialFolderId &&
        _searchController.text.isEmpty) {
      _folderId = widget.initialFolderId;
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(promptBlockLibraryNotifierProvider);
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: _buildSearchField(context),
            ),
            Expanded(child: _buildBody(context, library)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final library = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
    final folder = library == null || _folderId == null
        ? null
        : library.folderById(_folderId!);
    final title = folder?.displayName ?? context.l10n.promptBlockEditor_library;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
      child: Row(
        children: [
          if (_folderId != null)
            IconButton(
              key: const Key('prompt-block-drawer-back'),
              tooltip: context.l10n.promptBlockEditor_back,
              onPressed: () => _goToParent(library),
              icon: const Icon(Icons.arrow_back, size: 19),
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (widget.onClose != null)
            IconButton(
              key: const Key('prompt-block-drawer-close'),
              tooltip: context.l10n.common_close,
              onPressed: widget.onClose,
              icon: const Icon(Icons.close, size: 19),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      key: const Key('prompt-block-drawer-search'),
      controller: _searchController,
      decoration: InputDecoration(
        hintText: context.l10n.promptBlockLibrary_searchHint,
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: context.l10n.common_clear,
                onPressed: _searchController.clear,
                icon: const Icon(Icons.close, size: 16),
              ),
        isDense: true,
        filled: true,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<PromptBlockLibraryState> library,
  ) {
    return library.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildError(context, error),
      data: (state) {
        if (_folderId != null && state.folderById(_folderId!) == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _folderId = null);
          });
        }
        final query = _searchController.text.trim().toLowerCase();
        final blocks =
            query.isEmpty
                  ? state.blocksInFolder(_folderId)
                  : state.blocks
                        .where(
                          (block) =>
                              block.title.toLowerCase().contains(query) ||
                              block.content.toLowerCase().contains(query),
                        )
                        .toList()
              ..sort((a, b) => a.title.compareTo(b.title));
        final folders = query.isEmpty ? state.foldersIn(_folderId) : const [];

        if (blocks.isEmpty && folders.isEmpty) {
          return _buildEmpty(context, query.isNotEmpty);
        }

        return ListView(
          key: const Key('prompt-block-drawer-list'),
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
          children: [
            for (final folder in folders) _buildFolderTile(context, folder),
            for (final block in blocks) _buildBlockTile(context, block),
          ],
        );
      },
    );
  }

  Widget _buildFolderTile(BuildContext context, PromptBlockFolder folder) {
    return Card(
      key: ValueKey('prompt-block-folder-${folder.id}'),
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.folder_outlined),
        title: Text(
          folder.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right, size: 19),
        onTap: () => setState(() => _folderId = folder.id),
      ),
    );
  }

  Widget _buildBlockTile(BuildContext context, PromptBlock block) {
    final tile = InkWell(
      key: ValueKey('prompt-block-drawer-block-${block.id}'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => widget.onInsertBlock(block),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 30,
              decoration: BoxDecoration(
                color: promptBlockColorFromString(block.color),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                _blockTitle(context, block),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.add_circle_outline, size: 18),
          ],
        ),
      ),
    );

    final child = Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: tile,
    );
    if (widget.compact) return child;

    return Draggable<PromptBlockDragData>(
      key: ValueKey('prompt-block-draggable-${block.id}'),
      data: PromptBlockDragData(blockId: block.id),
      feedback: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 220,
          child: ListTile(
            dense: true,
            leading: Icon(
              Icons.view_module_outlined,
              color: promptBlockColorFromString(block.color),
            ),
            title: Text(
              _blockTitle(context, block),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: child),
      child: child,
    );
  }

  Widget _buildEmpty(BuildContext context, bool searching) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          searching
              ? context.l10n.promptBlockLibrary_noSearchResults
              : context.l10n.promptBlockLibrary_emptyFolder,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.promptBlockLibrary_loadFailed('$error'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref
                  .read(promptBlockLibraryNotifierProvider.notifier)
                  .refresh(),
              child: Text(context.l10n.common_retry),
            ),
          ],
        ),
      ),
    );
  }

  String _blockTitle(BuildContext context, PromptBlock block) {
    final title = block.title.trim();
    return title.isEmpty
        ? context.l10n.promptBlockLibrary_unnamedBlock
        : block.title;
  }

  void _goToParent(PromptBlockLibraryState? state) {
    if (state == null || _folderId == null) {
      setState(() => _folderId = null);
      return;
    }
    setState(() => _folderId = state.folderById(_folderId!)?.parentId);
  }

  void _onSearchChanged() => setState(() {});
}
