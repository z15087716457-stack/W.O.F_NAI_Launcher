import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/data/models/gallery/gallery_category.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/gallery_category_provider.dart';

/// 分类选择结果
///
/// 三态语义：
/// - 对话框取消 / 关闭：返回 null；
/// - 选中「未分类（图库根）」：返回 [CategoryPickResult(category: null)]；
/// - 选中具体分类：返回 [CategoryPickResult(category: category)]。
class CategoryPickResult {
  final GalleryCategory? category;

  const CategoryPickResult({this.category});
}

class _FlattenedCategoryItem {
  final GalleryCategory category;
  final int depth;

  const _FlattenedCategoryItem({required this.category, required this.depth});
}

/// 分类选择对话框
class CategoryPickerDialog extends ConsumerStatefulWidget {
  final String title;

  /// 会话级展开状态缓存（运行期间跨打开保持，重启启动器时重置）
  static final Set<String> _sessionExpandedIds = {};

  /// 测试用：清空会话展开缓存
  @visibleForTesting
  static void debugClearSessionExpandedIds() => _sessionExpandedIds.clear();

  const CategoryPickerDialog({super.key, required this.title});

  /// 弹出分类选择对话框
  static Future<CategoryPickResult?> show(
    BuildContext context, {
    required String title,
  }) {
    return showDialog<CategoryPickResult?>(
      context: context,
      builder: (context) => CategoryPickerDialog(title: title),
    );
  }

  @override
  ConsumerState<CategoryPickerDialog> createState() =>
      _CategoryPickerDialogState();
}

class _CategoryPickerDialogState extends ConsumerState<CategoryPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();
      if (_searchQuery != query) {
        setState(() => _searchQuery = query);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 展开状态挂在 [CategoryPickerDialog._sessionExpandedIds]（会话级记忆）

  /// 全量拍平（搜索模式用）
  List<_FlattenedCategoryItem> _flattenCategories(
    List<GalleryCategory> allCategories,
  ) {
    final items = <_FlattenedCategoryItem>[];

    void addBranch(List<GalleryCategory> nodes, int depth) {
      for (final node in nodes.sortedByOrder()) {
        items.add(_FlattenedCategoryItem(category: node, depth: depth));
        final children = allCategories.getChildren(node.id);
        if (children.isNotEmpty) {
          addBranch(children, depth + 1);
        }
      }
    }

    addBranch(allCategories.rootCategories, 0);
    return items;
  }

  /// 按折叠状态拍平（浏览模式用：未展开的子树不列出）
  List<_FlattenedCategoryItem> _flattenVisible(
    List<GalleryCategory> allCategories,
  ) {
    final items = <_FlattenedCategoryItem>[];

    void addBranch(List<GalleryCategory> nodes, int depth) {
      for (final node in nodes.sortedByOrder()) {
        items.add(_FlattenedCategoryItem(category: node, depth: depth));
        if (CategoryPickerDialog._sessionExpandedIds.contains(node.id)) {
          final children = allCategories.getChildren(node.id);
          if (children.isNotEmpty) {
            addBranch(children, depth + 1);
          }
        }
      }
    }

    addBranch(allCategories.rootCategories, 0);
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final categoryState = ref.watch(galleryCategoryNotifierProvider);
    final allCategories = categoryState.categories;

    final isSearching = _searchQuery.isNotEmpty;
    final visibleCategories = isSearching
        ? _flattenCategories(allCategories)
              .where(
                (item) => item.category.displayName.toLowerCase().contains(
                  _searchQuery,
                ),
              )
              .toList()
        : _flattenVisible(allCategories);

    final showRootItem =
        _searchQuery.isEmpty ||
        l10n.localGallery_uncategorizedRoot.toLowerCase().contains(
          _searchQuery,
        ) ||
        'root'.contains(_searchQuery);

    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      content: SizedBox(
        width: 560,
        height: 700,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.localGallery_categoryFilterHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  if (showRootItem) ...[
                    _buildRootTile(context, theme, l10n),
                    const Divider(height: 12),
                  ],
                  if (visibleCategories.isEmpty && !showRootItem)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          l10n.localGallery_noMatchingResults,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    )
                  else
                    ...visibleCategories.map(
                      (item) => _buildCategoryTile(
                        context,
                        theme,
                        l10n,
                        item,
                        showExpandControls: !isSearching,
                        hasChildren: allCategories
                            .getChildren(item.category.id)
                            .isNotEmpty,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.common_cancel),
        ),
      ],
    );
  }

  Widget _buildRootTile(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return InkWell(
      key: const ValueKey('category_picker_root_item'),
      borderRadius: BorderRadius.circular(8),
      onTap: () =>
          Navigator.of(context).pop(const CategoryPickResult(category: null)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.localGallery_uncategorizedRoot,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    _FlattenedCategoryItem item, {
    required bool showExpandControls,
    required bool hasChildren,
  }) {
    final category = item.category;
    final isExternal = category.isExternal;

    return InkWell(
      key: ValueKey('category_picker_item_${category.id}'),
      borderRadius: BorderRadius.circular(8),
      onTap: () =>
          Navigator.of(context).pop(CategoryPickResult(category: category)),
      child: Padding(
        padding: EdgeInsets.only(
          left: 12.0 + item.depth * 16.0,
          right: 12.0,
          top: 8.0,
          bottom: 8.0,
        ),
        child: Row(
          children: [
            if (showExpandControls && hasChildren)
              GestureDetector(
                key: ValueKey('category_picker_expand_${category.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    if (CategoryPickerDialog._sessionExpandedIds.contains(category.id)) {
                      CategoryPickerDialog._sessionExpandedIds.remove(category.id);
                    } else {
                      CategoryPickerDialog._sessionExpandedIds.add(category.id);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    CategoryPickerDialog._sessionExpandedIds.contains(category.id)
                        ? Icons.expand_more
                        : Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              const SizedBox(width: 22),
            Icon(
              isExternal ? Icons.folder_shared_outlined : Icons.folder_outlined,
              size: 20,
              color: isExternal
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.displayName,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isExternal) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.localGallery_externalSourceChip,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Text(
              '${category.imageCount}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
