import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../data/models/gallery/image_collection.dart';
import '../../../data/models/gallery/local_image_record.dart';
import '../../providers/collection_provider.dart';
import '../../providers/local_gallery_provider.dart';

/// 心形收藏按钮菜单：收藏/取消收藏 + 各收藏集快捷成员切换
///
/// [anchor] 为卡片在全局坐标系中的左上角（菜单默认出现在卡片左侧）。
Future<void> showGalleryFavoriteMenu(
  BuildContext context, {
  required WidgetRef ref,
  required LocalImageRecord record,
  required Offset anchor,
}) async {
  final state = ref.read(collectionNotifierProvider);
  if (state.collections.isEmpty && !state.isLoading) {
    // 集合列表首次使用前确保已加载
    await ref.read(collectionNotifierProvider.notifier).initialize();
  }
  if (!context.mounted) return;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'favorite menu',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 100),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _FavoriteMenuPanel(record: record, anchor: anchor);
    },
  );
}

class _FavoriteMenuPanel extends ConsumerStatefulWidget {
  final LocalImageRecord record;
  final Offset anchor;

  const _FavoriteMenuPanel({required this.record, required this.anchor});

  @override
  ConsumerState<_FavoriteMenuPanel> createState() => _FavoriteMenuPanelState();
}

class _FavoriteMenuPanelState extends ConsumerState<_FavoriteMenuPanel> {
  /// 该图所在收藏集 ID 集合；null 表示正在异步拉取或拉取失败
  Set<String>? _memberCollectionIds;

  /// 菜单内折叠的收藏文件夹 ID
  final Set<String> _collapsedFolderIds = {};
  late bool _isFavorite;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.record.isFavorite;
    _loadMembership();
  }

  Future<void> _loadMembership() async {
    Set<String>? ids;
    try {
      ids = await ref
          .read(collectionNotifierProvider.notifier)
          .getCollectionIdsForImage(widget.record.path);
    } catch (_) {
      ids = null; // 失败降级：只显示收藏 toggle
    }
    if (!mounted) return;
    setState(() => _memberCollectionIds = ids ?? const {});
  }

  Future<void> _toggleFavorite() async {
    if (_busy) return;
    setState(() => _busy = true);
    final nowFavorite = await ref
        .read(localGalleryNotifierProvider.notifier)
        .toggleFavorite(widget.record.path);
    if (!mounted) return;
    setState(() {
      _isFavorite = nowFavorite;
      _busy = false;
    });
  }

  Future<void> _toggleCollection(String collectionId) async {
    if (_busy) return;
    setState(() => _busy = true);
    final nowMember = await ref
        .read(collectionNotifierProvider.notifier)
        .toggleImageInCollection(collectionId, widget.record.path);
    // 入子集即入根：同步当前页记录，缩略图/预览图红心即时点亮
    final syncedIsFav = await ref
        .read(localGalleryNotifierProvider.notifier)
        .syncFavoriteStatus(widget.record.path);
    if (!mounted) return;
    setState(() {
      _busy = false;
      // null=查询失败，保持原状态
      if (syncedIsFav != null) _isFavorite = syncedIsFav;
      if (_memberCollectionIds != null) {
        if (nowMember) {
          _memberCollectionIds!.add(collectionId);
        } else {
          _memberCollectionIds!.remove(collectionId);
        }
      }
    });
    // 若画廊正按该收藏集过滤，重放当前页让图片即时增减
    final criteria = ref.read(localGalleryNotifierProvider).filterCriteria;
    if (criteria.collectionId == collectionId) {
      await ref
          .read(localGalleryNotifierProvider.notifier)
          .refresh(scan: false);
    }
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

    final collections = ref.watch(collectionNotifierProvider).collections;

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: panelWidth,
          child: Material(
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
                      icon: _isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      iconColor: _isFavorite ? Colors.red.shade400 : null,
                      label: _isFavorite
                          ? l10n.localGallery_unfavorite
                          : l10n.common_favorite,
                      checked: _isFavorite,
                      onTap: _busy ? null : _toggleFavorite,
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
                    if (_memberCollectionIds == null)
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
                                l10n.localGallery_favoriteMenuEmptyCollections,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._buildCollectionMenuRows(collections, null, 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 收藏集菜单行（树形：文件夹分组可折叠，仅收藏集可勾选成员）
  List<Widget> _buildCollectionMenuRows(
    List<ImageCollection> collections,
    String? parentId,
    int depth,
  ) {
    final rows = <Widget>[];
    for (final node in collections.where((c) => c.parentId == parentId)) {
      if (node.isFolder) {
        final expanded = !_collapsedFolderIds.contains(node.id);
        rows.add(
          _MenuRow(
            icon: expanded ? Icons.folder_open : Icons.folder,
            iconColor: Colors.amber.shade700,
            label: node.name,
            count: node.imageCount,
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
            _buildCollectionMenuRows(collections, node.id, depth + 1),
          );
        }
      } else {
        rows.add(
          _MenuRow(
            icon: Icons.collections_bookmark,
            iconColor: Colors.amber.shade700,
            label: node.name,
            count: node.imageCount,
            depth: depth,
            checked: _memberCollectionIds!.contains(node.id),
            onTap: _busy ? null : () => _toggleCollection(node.id),
          ),
        );
      }
    }
    return rows;
  }
}

/// 菜单行：图标 + 名称（+ 计数）+ 勾选态/文件夹展开箭头（+ 层级缩进）
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final int? count;

  /// null = 文件夹行（不显示勾选框，改用展开箭头）
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
