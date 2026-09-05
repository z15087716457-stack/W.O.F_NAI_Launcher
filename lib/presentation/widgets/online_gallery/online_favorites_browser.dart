import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/cache/danbooru_image_cache_manager.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/online_gallery/gallery_item.dart';
import '../../../data/models/online_gallery/gallery_source.dart';
import '../../../data/repositories/online_favorites_repository.dart';
import '../../providers/online_favorites_provider.dart';
import '../common/app_toast.dart';

/// AItag 本地收藏浏览器：子集 chips + 收藏作者卡 + 收藏网格
///
/// 作者头像取该作者第一张收藏封面圆形裁切；点击作者卡过滤其全部收藏作品。
class OnlineFavoritesBrowser extends ConsumerStatefulWidget {
  const OnlineFavoritesBrowser({
    super.key,
    required this.columnWidth,
    required this.onOpenItem,
  });

  /// 每列目标宽度（px），与画廊列宽偏好共用
  final double columnWidth;

  /// 点击卡片打开详情（复用在线画廊详情通路）
  final void Function(GalleryItem item) onOpenItem;

  @override
  ConsumerState<OnlineFavoritesBrowser> createState() =>
      _OnlineFavoritesBrowserState();
}

class _OnlineFavoritesBrowserState
    extends ConsumerState<OnlineFavoritesBrowser> {
  /// null → 根收藏；否则为子集 id（仅 !_viewingAll 时生效）
  String? _selectedFilter;
  bool _viewingAll = true;
  int? _authorFilter;
  List<OnlineFavoriteEntry> _entries = const [];
  Map<int, (String name, int count)> _authorCounts = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    const source = GallerySourceId.aiTag;
    final repo = ref.read(onlineFavoritesRepositoryProvider);
    final notifier = ref.read(onlineFavoritesNotifierProvider.notifier);
    try {
      await notifier.bindSource(source);
      final entries = await repo.listFavorites(
        source,
        collectionId: _selectedFilter,
        includeAll: _viewingAll,
        authorId: _authorFilter,
      );
      final counts = await repo.authorCounts(source);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _authorCounts = counts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _removeAuthor(OnlineFavoriteAuthor author) async {
    final removed = await ref
        .read(onlineFavoritesNotifierProvider.notifier)
        .removeAuthor(author.authorId);
    if (!removed || !mounted) return;
    if (_authorFilter == author.authorId) {
      setState(() => _authorFilter = null);
    }
    await _reload();
    if (mounted) {
      AppToast.success(context, context.l10n.onlineFav_authorUnfavorited);
    }
  }

  Future<void> _createCollection() async {
    final name = await _promptText(context.l10n.onlineFav_newCollection);
    if (name == null || name.trim().isEmpty) return;
    await ref
        .read(onlineFavoritesNotifierProvider.notifier)
        .createCollection(name.trim());
    await _reload();
  }

  Future<void> _renameCollection(String id, String current) async {
    final name = await _promptText(
      context.l10n.onlineFav_renameCollection,
      initial: current,
    );
    if (name == null || name.trim().isEmpty || name == current) return;
    await ref
        .read(onlineFavoritesNotifierProvider.notifier)
        .renameCollection(id, name.trim());
    await _reload();
  }

  Future<String?> _promptText(String title, {String? initial}) async {
    final controller = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(context.l10n.common_confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favState = ref.watch(onlineFavoritesNotifierProvider);

    return Column(
      children: [
        _buildCollectionChips(theme, favState.collections),
        if (favState.authors.isNotEmpty) _buildAuthorStrip(theme),
        Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildGrid(theme),
        ),
      ],
    );
  }

  Widget _buildCollectionChips(
    ThemeData theme,
    List<OnlineCollectionInfo> collections,
  ) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _filterChip(
            label: context.l10n.onlineFav_all,
            selected: _viewingAll && _authorFilter == null,
            onTap: () {
              setState(() {
                _viewingAll = true;
                _selectedFilter = null;
                _authorFilter = null;
              });
              _reload();
            },
          ),
          _filterChip(
            label: context.l10n.onlineFav_rootCollection,
            selected: !_viewingAll && _selectedFilter == null,
            onTap: () {
              setState(() {
                _viewingAll = false;
                _selectedFilter = null;
                _authorFilter = null;
              });
              _reload();
            },
          ),
          for (final collection in collections)
            _filterChip(
              label: '${collection.name} (${collection.itemCount})',
              selected: !_viewingAll && _selectedFilter == collection.id,
              onTap: () {
                setState(() {
                  _viewingAll = false;
                  _selectedFilter = collection.id;
                  _authorFilter = null;
                });
                _reload();
              },
              onMenu: () => _showCollectionMenu(collection),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(context.l10n.onlineFav_newCollection),
              onPressed: _createCollection,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    VoidCallback? onMenu,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        onDeleted: onMenu,
        deleteIcon: onMenu == null
            ? const SizedBox.shrink()
            : const Icon(Icons.more_vert, size: 16),
        deleteButtonTooltipMessage: onMenu == null ? '' : null,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Future<void> _showCollectionMenu(OnlineCollectionInfo collection) async {
    final theme = Theme.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(context.l10n.onlineFav_renameCollection),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(context.l10n.onlineFav_deleteCollection),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'rename') {
      await _renameCollection(collection.id, collection.name);
    } else if (action == 'delete') {
      await ref
          .read(onlineFavoritesNotifierProvider.notifier)
          .deleteCollection(collection.id);
      if (_selectedFilter == collection.id) {
        setState(() {
          _viewingAll = true;
          _selectedFilter = null;
        });
      }
      await _reload();
    }
  }

  /// 作者区：横向卡片（头像 = 该作者收藏封面，右侧 4 张示例小图）
  Widget _buildAuthorStrip(ThemeData theme) {
    final favState = ref.watch(onlineFavoritesNotifierProvider);
    final authors = favState.authors;

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: authors.length,
        itemBuilder: (context, index) {
          final author = authors[index];
          final selected = _authorFilter == author.authorId;
          final count = _authorCounts[author.authorId]?.$2 ?? 0;
          final samples = _entries
              .where((entry) => entry.item.uploaderId == author.authorId)
              .take(4)
              .toList();
          return _AuthorCard(
            authorId: author.authorId,
            authorName: author.authorName,
            workCount: count,
            sampleUrls: [
              for (final entry in samples)
                entry.item.cover.previewUrl.isNotEmpty
                    ? entry.item.cover.previewUrl
                    : entry.item.cover.displayUrl,
            ],
            fallbackAvatarSeed: author.authorId,
            selected: selected,
            onTap: () {
              setState(() => _authorFilter = selected ? null : author.authorId);
              _reload();
            },
            onRemove: () => _removeAuthor(author),
          );
        },
      ),
    );
  }

  Widget _buildGrid(ThemeData theme) {
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.onlineFav_empty,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width - 60;
    final columnCount = (screenWidth / widget.columnWidth)
        .floor()
        .clamp(2, 8)
        .clamp(1, _entries.length);
    return MasonryGridView.count(
      padding: const EdgeInsets.all(12),
      crossAxisCount: columnCount,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      itemCount: _entries.length,
      itemBuilder: (context, index) =>
          _buildFavoriteCard(theme, _entries[index]),
    );
  }

  Widget _buildFavoriteCard(ThemeData theme, OnlineFavoriteEntry entry) {
    final item = entry.item;
    final cover = item.cover;
    final url = cover.previewUrl.isNotEmpty
        ? cover.previewUrl
        : cover.displayUrl;
    final aspect = cover.width > 0 && cover.height > 0
        ? cover.width / cover.height
        : 1.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => widget.onOpenItem(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (url.isNotEmpty)
              AspectRatio(
                aspectRatio: aspect.clamp(0.4, 3.0),
                child: CachedNetworkImage(
                  imageUrl: url,
                  httpHeaders: onlineGalleryImageHeadersForUrl(url),
                  cacheKey: onlineGalleryImageCacheKeyForUrl(url),
                  cacheManager: DanbooruImageCacheManager.instance,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.title?.isNotEmpty == true)
                          Text(
                            item.title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        if (item.author?.isNotEmpty == true)
                          Text(
                            item.author!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _FavoriteCardMenu(entry: entry, onChanged: _reload),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 收藏卡片右侧操作菜单：移入子集 / 移除收藏
class _FavoriteCardMenu extends ConsumerWidget {
  const _FavoriteCardMenu({required this.entry, required this.onChanged});

  final OnlineFavoriteEntry entry;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.outline),
      onPressed: () async {
        final notifier = ref.read(onlineFavoritesNotifierProvider.notifier);
        final collections = ref
            .read(onlineFavoritesNotifierProvider)
            .collections;
        final action = await showModalBottomSheet<String>(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(context.l10n.onlineFav_rootCollection),
                  subtitle: Text(context.l10n.onlineFav_moveHere),
                  onTap: () => Navigator.pop(context, 'root'),
                ),
                for (final collection in collections)
                  ListTile(
                    leading: const Icon(Icons.collections_bookmark_outlined),
                    title: Text(collection.name),
                    onTap: () => Navigator.pop(context, collection.id),
                  ),
                ListTile(
                  leading: Icon(
                    Icons.favorite_border,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(context.l10n.onlineFav_removeFavorite),
                  onTap: () => Navigator.pop(context, 'remove'),
                ),
              ],
            ),
          ),
        );
        if (action == null) return;
        if (action == 'remove') {
          await notifier.removeFavorite(entry.item);
        } else {
          await notifier.moveToCollection(
            entry.item.id,
            action == 'root' ? null : action,
          );
        }
        await onChanged();
      },
    );
  }
}

/// Pixiv 式作者卡：圆形头像 + 名字/张数 + 示例小图
class _AuthorCard extends StatelessWidget {
  const _AuthorCard({
    required this.authorId,
    required this.authorName,
    required this.workCount,
    required this.sampleUrls,
    required this.fallbackAvatarSeed,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  final int authorId;
  final String authorName;
  final int workCount;
  final List<String> sampleUrls;
  final int fallbackAvatarSeed;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = sampleUrls.isNotEmpty ? sampleUrls.first : '';
    final avatarColors = [
      Colors.blue.shade300,
      Colors.purple.shade300,
      Colors.teal.shade300,
      Colors.orange.shade300,
      Colors.pink.shade300,
    ];

    return SizedBox(
      width: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 30, 8),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        avatarColors[fallbackAvatarSeed % avatarColors.length],
                    foregroundImage: avatarUrl.isEmpty
                        ? null
                        : CachedNetworkImageProvider(
                            avatarUrl,
                            cacheManager: DanbooruImageCacheManager.instance,
                            cacheKey: onlineGalleryImageCacheKeyForUrl(
                              avatarUrl,
                            ),
                            headers: onlineGalleryImageHeadersForUrl(avatarUrl),
                          ),
                    child: avatarUrl.isEmpty
                        ? Text(
                            authorName.isNotEmpty
                                ? authorName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          authorName.isEmpty ? '???' : authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          context.l10n.onlineFav_authorWorkCount(workCount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 56,
                    height: 40,
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var i = 0; i < 4; i++)
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(3),
                              image: i < sampleUrls.length
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        sampleUrls[i],
                                        cacheManager:
                                            DanbooruImageCacheManager.instance,
                                        cacheKey:
                                            onlineGalleryImageCacheKeyForUrl(
                                              sampleUrls[i],
                                            ),
                                        headers:
                                            onlineGalleryImageHeadersForUrl(
                                              sampleUrls[i],
                                            ),
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton(
              key: ValueKey('online-favorite-author-remove-$authorId'),
              tooltip: context.l10n.onlineFav_unfavoriteAuthor,
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              visualDensity: VisualDensity.compact,
              iconSize: 17,
              color: theme.colorScheme.error.withValues(alpha: 0.72),
              icon: const Icon(Icons.person_remove_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
