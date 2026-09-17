import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../../data/models/prompt_block/prompt_block_collection.dart';
import '../../../providers/prompt_block_library_provider.dart';

/// 块 ★ 收藏按钮菜单：收藏/取消收藏 + 各收藏集快捷成员切换。
///
/// 交互模型照抄本地画廊心形菜单（`gallery_favorite_menu.dart`）；
/// 差异点是成员关系直接从块库 state 派生（collection.blockIds），
/// 无需异步拉取。
///
/// [anchor] 为触发点在全局坐标系中的左上角（菜单默认出现在左侧）。
Future<void> showBlockFavoriteMenu(
  BuildContext context, {
  required WidgetRef ref,
  required PromptBlock block,
  required Offset anchor,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'favorite menu',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 100),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _BlockFavoriteMenuPanel(blockId: block.id, anchor: anchor);
    },
  );
}

class _BlockFavoriteMenuPanel extends ConsumerStatefulWidget {
  final String blockId;
  final Offset anchor;

  const _BlockFavoriteMenuPanel({required this.blockId, required this.anchor});

  @override
  ConsumerState<_BlockFavoriteMenuPanel> createState() =>
      _BlockFavoriteMenuPanelState();
}

class _BlockFavoriteMenuPanelState
    extends ConsumerState<_BlockFavoriteMenuPanel> {
  /// 菜单内折叠的收藏文件夹 ID。
  final Set<String> _collapsedFolderIds = {};
  bool _busy = false;

  /// 收藏切换的请求序号：连点时只让最后一次落库结果回写 UI，
  /// 避免先发请求的旧结果覆盖后发请求的新状态。
  int _favoriteRequestSeq = 0;

  /// 收藏开关：落库完成后 provider 重建 state，勾选/星标随之校准。
  /// 序号守卫用于丢弃连点中先发请求的过场态。
  Future<void> _toggleFavorite(PromptBlock block) async {
    final seq = ++_favoriteRequestSeq;
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .toggleFavorite(block.id);
      if (!mounted || seq != _favoriteRequestSeq) return;
      setState(() {});
    } catch (_) {
      // 失败保持原状，由外层 toast 处理兜底
    }
  }

  Future<void> _toggleCollection(String collectionId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .toggleBlockInCollection(collectionId, widget.blockId);
    } catch (_) {
      // 失败保持原状，由外层 toast 处理兜底
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final screenSize = MediaQuery.of(context).size;
    const panelWidth = 240.0;

    var left = widget.anchor.dx - panelWidth - 8;
    if (left < 8) left = widget.anchor.dx + 8;
    var top = widget.anchor.dy;
    if (top + 320 > screenSize.height) top = screenSize.height - 320;
    if (top < 8) top = 8;

    final state = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
    final block = state?.blockById(widget.blockId);
    final isFavorite = block?.isFavorite ?? false;
    final memberIds =
        state?.collectionIdsOfBlock(widget.blockId) ?? const <String>{};
    final collections = state?.collections ?? const <PromptBlockCollection>[];

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: panelWidth,
          child: Material(
            key: const Key('prompt-block-favorite-menu'),
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surfaceContainerHigh,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenSize.height - top - 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MenuRow(
                      icon: isFavorite ? Icons.star : Icons.star_border,
                      iconColor: isFavorite ? Colors.amber.shade700 : null,
                      label: isFavorite
                          ? l10n.common_unfavorite
                          : l10n.common_favorite,
                      checked: isFavorite,
                      onTap: block == null
                          ? null
                          : () => _toggleFavorite(block),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 12,
                      endIndent: 12,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    if (state == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else if (collections.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.collections_bookmark_outlined,
                              size: 16,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.promptBlockLibrary_favoriteMenuEmptyCollections,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._buildCollectionMenuRows(
                        collections,
                        null,
                        0,
                        memberIds,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 收藏集菜单行（树形：收藏文件夹可折叠，仅收藏集可勾选成员）。
  List<Widget> _buildCollectionMenuRows(
    List<PromptBlockCollection> collections,
    String? parentId,
    int depth,
    Set<String> memberIds,
  ) {
    final rows = <Widget>[];
    for (final node in collections.childrenOf(parentId)) {
      if (node.isFolder) {
        final expanded = !_collapsedFolderIds.contains(node.id);
        rows.add(
          _MenuRow(
            icon: expanded ? Icons.folder_open : Icons.folder,
            iconColor: Colors.amber.shade700,
            label: node.displayName,
            count: null,
            depth: depth,
            isExpanded: expanded,
            onTap: () => setState(() {
              if (expanded) {
                _collapsedFolderIds.add(node.id);
              } else {
                _collapsedFolderIds.remove(node.id);
              }
            }),
          ),
        );
        if (expanded) {
          rows.addAll(
            _buildCollectionMenuRows(
              collections,
              node.id,
              depth + 1,
              memberIds,
            ),
          );
        }
      } else {
        rows.add(
          _MenuRow(
            icon: Icons.collections_bookmark,
            iconColor: Colors.amber.shade700,
            label: node.displayName,
            count: node.blockIds.length,
            depth: depth,
            checked: memberIds.contains(node.id),
            onTap: _busy ? null : () => _toggleCollection(node.id),
          ),
        );
      }
    }
    return rows;
  }
}

/// 菜单行：图标 + 名称（+ 计数）+ 勾选态/文件夹展开箭头（+ 层级缩进）。
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final int? count;

  /// null = 文件夹行（不显示勾选框，改用展开箭头）。
  final bool? checked;
  final bool? isExpanded;
  final int depth;
  final VoidCallback? onTap;

  const _MenuRow({
    required this.icon,
    this.iconColor,
    required this.label,
    this.count,
    this.checked,
    this.isExpanded,
    this.depth = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12 + depth * 12.0,
          right: 12,
          top: 10,
          bottom: 10,
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: iconColor ?? theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            const SizedBox(width: 6),
            if (checked != null)
              Icon(
                checked! ? Icons.check : Icons.check_box_outline_blank,
                size: 16,
                color: checked!
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              )
            else if (isExpanded != null)
              Icon(
                isExpanded! ? Icons.expand_more : Icons.chevron_right,
                size: 16,
                color: theme.colorScheme.outline,
              ),
          ],
        ),
      ),
    );
  }
}
