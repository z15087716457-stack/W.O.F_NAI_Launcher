import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../data/models/prompt_block/prompt_block.dart';
import '../../providers/prompt_block_library_provider.dart';
import '../../providers/tips_provider.dart';
import 'thumbnail_display.dart';

/// 块库条目选择对话框
///
/// 用于从全局 Prompt 块库中选择一个块，返回选中的 [PromptBlock]。
/// 旧本地词库的选择场景（预设自定义词、角色导入等）统一改走这里。
class PromptBlockPickerDialog extends ConsumerStatefulWidget {
  /// 对话框标题
  final String? title;

  const PromptBlockPickerDialog({super.key, this.title});

  /// 显示块选择对话框，返回用户选中的块（取消返回 null）。
  static Future<PromptBlock?> show(BuildContext context, {String? title}) {
    return showDialog<PromptBlock>(
      context: context,
      builder: (context) => PromptBlockPickerDialog(title: title),
    );
  }

  @override
  ConsumerState<PromptBlockPickerDialog> createState() =>
      _PromptBlockPickerDialogState();
}

class _PromptBlockPickerDialogState
    extends ConsumerState<PromptBlockPickerDialog> {
  String _searchQuery = '';
  String? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    final savedFolderId = ref
        .read(localStorageServiceProvider)
        .getSetting<String>(StorageKeys.promptBlockPickerFolderId);
    if (savedFolderId != null && savedFolderId.isNotEmpty) {
      _selectedFolderId = savedFolderId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncState = ref.watch(promptBlockLibraryNotifierProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            _buildHeader(theme),
            const SizedBox(height: 16),

            // 搜索和筛选栏
            asyncState.when(
              data: (state) => _buildFilterBar(theme, state),
              loading: () => const SizedBox(height: 48),
              error: (_, _) => const SizedBox(height: 48),
            ),
            const SizedBox(height: 16),

            // 块网格
            Expanded(
              child: asyncState.when(
                data: (state) => _buildBlockGrid(theme, state),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    '$error',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 底部按钮
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.library_books_outlined,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          widget.title ?? context.l10n.promptBlockPicker_title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: context.l10n.common_close,
        ),
      ],
    );
  }

  Widget _buildFilterBar(ThemeData theme, PromptBlockLibraryState state) {
    final selectedFolderId = _effectiveSelectedFolderId(state);
    // 文件夹下拉按 DFS 树序展开，显示根→当前路径名以区分同名子文件夹。
    final treeOrder = state.folderTreeOrder();
    final orderedFolders = state.folders.toList()
      ..sort(
        (a, b) =>
            (treeOrder[a.id] ?? 1 << 30).compareTo(treeOrder[b.id] ?? 1 << 30),
      );
    return Row(
      children: [
        // 搜索框
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: tipHint(
                context.l10n,
                TipModule.blockLibrary,
                epoch: watchTipEpoch(ref),
              ),
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),
        const SizedBox(width: 12),

        // 文件夹筛选
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String?>(
            initialValue: selectedFolderId,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              isDense: true,
            ),
            hint: Text(context.l10n.promptBlockLibrary_allBlocks),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(context.l10n.promptBlockLibrary_allBlocks),
              ),
              ...orderedFolders.map(
                (folder) => DropdownMenuItem<String?>(
                  value: folder.id,
                  child: Text(
                    state.folderPath(folder.id),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: _setSelectedFolder,
          ),
        ),
      ],
    );
  }

  Widget _buildBlockGrid(ThemeData theme, PromptBlockLibraryState state) {
    // 按文件夹子树过滤
    final selectedFolderId = _effectiveSelectedFolderId(state);
    var blocks = selectedFolderId == null
        ? state.blocks.toList()
        : state.blocksInFolderTree(selectedFolderId);

    // 搜索过滤（标题 + 内容）
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      blocks = blocks
          .where(
            (block) =>
                block.title.toLowerCase().contains(lowerQuery) ||
                block.content.toLowerCase().contains(lowerQuery),
          )
          .toList();
    }
    blocks = _sortFavoritesFirst(blocks);

    if (blocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? context.l10n.promptBlockLibrary_noSearchResults
                  : context.l10n.promptBlockLibrary_empty,
              style: TextStyle(color: theme.colorScheme.outline, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        final block = blocks[index];
        return _BlockSelectCard(
          block: block,
          onTap: () => Navigator.of(context).pop(block),
        );
      },
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.common_cancel),
        ),
      ],
    );
  }

  String? _effectiveSelectedFolderId(PromptBlockLibraryState state) {
    final selected = _selectedFolderId;
    if (selected == null) return null;
    return state.folders.any((folder) => folder.id == selected)
        ? selected
        : null;
  }

  void _setSelectedFolder(String? value) {
    setState(() => _selectedFolderId = value);
    final storage = ref.read(localStorageServiceProvider);
    if (value == null) {
      unawaited(storage.deleteSetting(StorageKeys.promptBlockPickerFolderId));
    } else {
      unawaited(
        storage.setSetting(StorageKeys.promptBlockPickerFolderId, value),
      );
    }
  }

  List<PromptBlock> _sortFavoritesFirst(List<PromptBlock> blocks) {
    if (!blocks.any((block) => block.isFavorite)) {
      return blocks;
    }
    final favorites = <PromptBlock>[];
    final others = <PromptBlock>[];
    for (final block in blocks) {
      if (block.isFavorite) {
        favorites.add(block);
      } else {
        others.add(block);
      }
    }
    return [...favorites, ...others];
  }
}

/// 块选择卡片
class _BlockSelectCard extends StatefulWidget {
  final PromptBlock block;
  final VoidCallback onTap;

  const _BlockSelectCard({required this.block, required this.onTap});

  @override
  State<_BlockSelectCard> createState() => _BlockSelectCardState();
}

class _BlockSelectCardState extends State<_BlockSelectCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = widget.block;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovering
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: _isHovering
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 预览图区域
              Expanded(flex: 3, child: _buildThumbnail(theme, block)),

              // 信息区域
              Expanded(flex: 2, child: _buildInfo(theme, block)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ThemeData theme, PromptBlock block) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (block.hasThumbnail && block.thumbnail != null)
          LayoutBuilder(
            builder: (context, constraints) {
              return ThumbnailDisplay(
                imagePath: block.thumbnail!,
                offsetX: block.thumbnailOffsetX,
                offsetY: block.thumbnailOffsetY,
                scale: block.thumbnailScale,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
              );
            },
          )
        else
          _buildPlaceholder(theme),

        // 悬停遮罩
        if (_isHovering)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
              child: Container(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.common_select,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // 收藏标识
        if (block.isFavorite)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.favorite, size: 12, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildInfo(ThemeData theme, PromptBlock block) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            block.displayTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // 内容预览
          Expanded(
            child: Text(
              block.contentPreview,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
