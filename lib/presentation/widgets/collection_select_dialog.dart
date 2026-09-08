import 'package:flutter/material.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/gallery/image_collection.dart';
import '../providers/collection_provider.dart';
import 'common/inset_shadow_container.dart';
import 'package:nai_launcher/presentation/widgets/common/themed_input.dart';

/// 集合选择结果
class CollectionSelectResult {
  final String collectionId;
  final String collectionName;

  /// 是否为「收藏」根（批量取消心形收藏，而非从某个收藏集移除）
  final bool isFavoriteRoot;

  const CollectionSelectResult({
    required this.collectionId,
    required this.collectionName,
    this.isFavoriteRoot = false,
  });
}

/// 集合选择对话框
///
/// 用于选择一个集合以添加/移除图片
class CollectionSelectDialog extends ConsumerStatefulWidget {
  final ThemeData theme;

  /// 移除模式：标题按「从集合移除」呈现，列表项标注选中图片的成员数
  final bool isRemoveMode;

  /// 当前多选的图片路径；移除模式下用于标注各集合包含几张选中图片
  final List<String> selectedImagePaths;

  /// 选中图片中是心形收藏（「收藏」根成员）的张数；移除模式根条目标注用
  final int favoriteCountInSelection;

  const CollectionSelectDialog({
    super.key,
    required this.theme,
    this.isRemoveMode = false,
    this.selectedImagePaths = const [],
    this.favoriteCountInSelection = 0,
  });

  /// 显示集合选择对话框
  ///
  /// 返回选中的集合ID，如果取消则返回null
  static Future<CollectionSelectResult?> show(
    BuildContext context, {
    required ThemeData theme,
    bool isRemoveMode = false,
    List<String> selectedImagePaths = const [],
    int favoriteCountInSelection = 0,
  }) {
    return showDialog<CollectionSelectResult>(
      context: context,
      builder: (context) => CollectionSelectDialog(
        theme: theme,
        isRemoveMode: isRemoveMode,
        selectedImagePaths: selectedImagePaths,
        favoriteCountInSelection: favoriteCountInSelection,
      ),
    );
  }

  @override
  ConsumerState<CollectionSelectDialog> createState() =>
      _CollectionSelectDialogState();
}

class _CollectionSelectDialogState
    extends ConsumerState<CollectionSelectDialog> {
  // 搜索过滤控制器
  final _filterController = TextEditingController();
  String _filterQuery = '';

  /// 各集合包含的选中图片张数；null=尚未加载完成（不标注）
  Map<String, int>? _memberCounts;

  /// 对话框内折叠的收藏文件夹 ID
  final Set<String> _collapsedFolderIds = {};

  @override
  void initState() {
    super.initState();
    // 初始化加载集合
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(collectionNotifierProvider.notifier).initialize();
    });
    if (widget.isRemoveMode && widget.selectedImagePaths.isNotEmpty) {
      _loadMemberCounts();
    }
    _filterController.addListener(_onFilterChanged);
  }

  Future<void> _loadMemberCounts() async {
    final counts = await ref
        .read(collectionNotifierProvider.notifier)
        .countMembershipByPaths(widget.selectedImagePaths);
    if (!mounted) return;
    setState(() => _memberCounts = counts);
  }

  void _onFilterChanged() {
    setState(() {
      _filterQuery = _filterController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _filterController.removeListener(_onFilterChanged);
    _filterController.dispose();
    super.dispose();
  }

  void _selectCollection(ImageCollection collection) {
    Navigator.of(context).pop(
      CollectionSelectResult(
        collectionId: collection.id,
        collectionName: collection.name,
      ),
    );
  }

  /// 计算搜索过滤的保留 ID 集（匹配节点 + 其祖先文件夹链；null=不过滤）
  Set<String>? _computeRetainedIds(List<ImageCollection> collections) {
    if (_filterQuery.isEmpty) return null;

    final byId = {for (final c in collections) c.id: c};
    bool matches(ImageCollection c) {
      final nameMatch = c.name.toLowerCase().contains(_filterQuery);
      final descMatch =
          c.description?.toLowerCase().contains(_filterQuery) ?? false;
      return nameMatch || descMatch;
    }

    final retain = {
      for (final c in collections)
        if (matches(c)) c.id,
    };
    for (final id in retain.toList()) {
      var parent = byId[id]?.parentId;
      while (parent != null) {
        retain.add(parent);
        parent = byId[parent]?.parentId;
      }
    }
    return retain;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final l10n = context.l10n;

    // 监听集合状态
    final collectionState = ref.watch(collectionNotifierProvider);
    final collections = collectionState.collections;
    final isLoading = collectionState.isLoading;

    return AlertDialog(
      title: Text(
        widget.isRemoveMode
            ? l10n.collectionSelect_removeTitle
            : l10n.collectionSelect_dialogTitle,
      ),
      content: SizedBox(
        width: 450,
        height: 500,
        child: Column(
          children: [
            // 搜索框
            InsetShadowContainer(
              borderRadius: 8,
              child: ThemedInput(
                controller: _filterController,
                decoration: InputDecoration(
                  hintText: l10n.collectionSelect_filterHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _filterQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _filterController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 集合列表
            Expanded(
              child: _buildCollectionList(theme, l10n, collections, isLoading),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
      ],
    );
  }

  /// 「收藏」根条目是否按当前搜索过滤匹配
  bool _rootMatchesFilter(AppLocalizations l10n) {
    if (_filterQuery.isEmpty) return true;
    return l10n.common_favorite.toLowerCase().contains(_filterQuery);
  }

  /// 构建集合列表
  Widget _buildCollectionList(
    ThemeData theme,
    AppLocalizations l10n,
    List<ImageCollection> collections,
    bool isLoading,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final retainedIds = _computeRetainedIds(collections);
    // 移除模式：顶部始终提供「收藏」根条目（根=总收藏，子集=根的细分）
    final rootVisible = widget.isRemoveMode && _rootMatchesFilter(l10n);
    final treeRows = _buildCollectionTreeRows(
      theme,
      l10n,
      collections,
      retainedIds,
      null,
      0,
    );
    final hasAnyEntry = treeRows.isNotEmpty || rootVisible;

    if (!hasAnyEntry && collections.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.collectionSelect_noCollections,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.collectionSelect_createCollectionHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!hasAnyEntry) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.collectionSelect_noFilterResults,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (rootVisible) _buildFavoriteRootTile(theme, l10n),
        ...treeRows,
      ],
    );
  }

  /// 收藏区树行（文件夹分组可折叠、仅收藏集可选；搜索时保留祖先链）
  List<Widget> _buildCollectionTreeRows(
    ThemeData theme,
    AppLocalizations l10n,
    List<ImageCollection> collections,
    Set<String>? retainedIds,
    String? parentId,
    int depth,
  ) {
    final rows = <Widget>[];
    for (final node in collections.where((c) => c.parentId == parentId)) {
      if (retainedIds != null && !retainedIds.contains(node.id)) continue;
      if (node.isFolder) {
        final expanded = !_collapsedFolderIds.contains(node.id);
        rows.add(_buildFolderTile(theme, node, depth, expanded));
        if (expanded) {
          rows.addAll(
            _buildCollectionTreeRows(
              theme,
              l10n,
              collections,
              retainedIds,
              node.id,
              depth + 1,
            ),
          );
        }
      } else {
        rows.add(_buildCollectionTile(theme, l10n, node, depth));
      }
    }
    return rows;
  }

  /// 文件夹分组行（不可选为目标，点击仅展开/收起）
  Widget _buildFolderTile(
    ThemeData theme,
    ImageCollection folder,
    int depth,
    bool expanded,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.only(
        left: 16 + depth * 20.0,
        right: 16,
      ),
      dense: true,
      leading: Icon(
        expanded ? Icons.folder_open : Icons.folder,
        color: Colors.amber.shade700,
      ),
      title: Text(
        folder.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        context.l10n.collectionSelect_imageCount(folder.imageCount),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      trailing: Icon(
        expanded ? Icons.expand_less : Icons.chevron_right,
        color: theme.colorScheme.outline,
      ),
      onTap: () => setState(() {
        if (expanded) {
          _collapsedFolderIds.add(folder.id);
        } else {
          _collapsedFolderIds.remove(folder.id);
        }
      }),
    );
  }

  /// 「收藏」根条目：移除模式下从根移除 = 取消心形收藏并移出所有集合
  Widget _buildFavoriteRootTile(ThemeData theme, AppLocalizations l10n) {
    final memberCount = widget.favoriteCountInSelection;
    final hasNone = memberCount == 0;

    return Opacity(
      opacity: hasNone ? 0.45 : 1.0,
      child: ListTile(
        leading: Icon(Icons.favorite, color: Colors.red.shade400),
        title: Text(
          l10n.common_favorite,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          memberCount > 0
              ? l10n.collectionSelect_memberCountInFavorites(memberCount)
              : l10n.collectionSelect_noSelectedInCollection,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        onTap: () => Navigator.of(context).pop(
          CollectionSelectResult(
            collectionId: 'favorites',
            collectionName: l10n.common_favorite,
            isFavoriteRoot: true,
          ),
        ),
      ),
    );
  }

  /// 构建集合列表项
  Widget _buildCollectionTile(
    ThemeData theme,
    AppLocalizations l10n,
    ImageCollection collection,
    int depth,
  ) {
    // 移除模式：标注该集合包含几张选中图片，无交集的集合淡化
    final isRemove = widget.isRemoveMode;
    final memberCount = _memberCounts?[collection.id];
    final hasNone = isRemove && memberCount == 0;

    return Opacity(
      opacity: hasNone ? 0.45 : 1.0,
      child: ListTile(
        contentPadding: EdgeInsets.only(
          left: 16 + depth * 20.0,
          right: 16,
        ),
        leading: Icon(Icons.folder_outlined, color: theme.colorScheme.primary),
        title: Text(
          collection.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (collection.description != null)
              Text(
                collection.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              isRemove && memberCount != null
                  ? (memberCount > 0
                        ? l10n.collectionSelect_memberCount(memberCount)
                        : l10n.collectionSelect_noSelectedInCollection)
                  : l10n.collectionSelect_imageCount(collection.imageCount),
              style: theme.textTheme.bodySmall?.copyWith(
                color: !isRemove || (memberCount ?? 0) > 0
                    ? theme.colorScheme.outline
                    : theme.colorScheme.outlineVariant,
              ),
            ),
          ],
        ),
        trailing: isRemove
            ? null
            : Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
        onTap: () => _selectCollection(collection),
      ),
    );
  }
}
