import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../core/wiki/wiki_bookmark_store.dart';
import '../../../core/wiki/wiki_directory.dart';
import '../../../core/wiki/wiki_directory_labels.dart';
import '../../widgets/common/themed_input_dialog.dart';
import '../../widgets/common/themed_confirm_dialog.dart';
import '../../widgets/common/studio_animated_icon.dart';
import '../../widgets/common/studio_icons.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../../providers/canvas_settings_provider.dart';

enum WikiScopeKind { all, bookmarks, collection, directory }

class WikiScope {
  const WikiScope(this.kind, this.id, this.label, {this.node});

  final WikiScopeKind kind;
  final String? id;
  final String label;
  final WikiDirectoryNode? node;

  bool matches(WikiScope other) => kind == other.kind && id == other.id;
}

// Keep source indices for selection and expansion IDs while grouping folders.
// The relative order within each group remains the official directory order.
Iterable<(int, WikiDirectoryNode)> _foldersFirst(
  List<WikiDirectoryNode> nodes,
) sync* {
  yield* nodes.indexed.where((entry) => entry.$2.children.isNotEmpty);
  yield* nodes.indexed.where((entry) => entry.$2.children.isEmpty);
}

class WikiSidebar extends StatelessWidget {
  const WikiSidebar({
    super.key,
    required this.directory,
    required this.bookmarks,
    required this.selection,
    required this.onSelect,
    this.width = 216,
    this.headerHeight = 62,
    this.navigationHeight,
    this.allowWindowDrag = false,
  });

  final WikiDirectory directory;
  final WikiBookmarkStore bookmarks;
  final WikiScope selection;
  final ValueChanged<WikiScope> onSelect;
  final double width;
  final double headerHeight;
  final bool allowWindowDrag;
  // The first two rows share the results toolbar's height; collections below
  // them can still expand the directory naturally.
  final double? navigationHeight;

  Future<void> _create(BuildContext context, {String? parentId}) async {
    final name = await ThemedInputDialog.show(
      context: context,
      title: parentId == null
          ? context.l10n.wiki_newCollection
          : context.l10n.wiki_newChildCollection,
      hintText: context.l10n.wiki_collectionNameHint,
      validator: (value) => value.trim().isEmpty ? ' ' : null,
    );
    if (name == null || !context.mounted) return;
    final created = await bookmarks.createCollection(name, parentId: parentId);
    onSelect(WikiScope(WikiScopeKind.collection, created.id, created.name));
  }

  Future<void> _rename(
    BuildContext context,
    WikiBookmarkCollection collection,
  ) async {
    final name = await ThemedInputDialog.show(
      context: context,
      title: context.l10n.wiki_renameCollection,
      initialValue: collection.name,
      validator: (value) => value.trim().isEmpty ? ' ' : null,
    );
    if (name == null) return;
    await bookmarks.renameCollection(collection.id, name);
    if (selection.id == collection.id) {
      onSelect(WikiScope(WikiScopeKind.collection, collection.id, name));
    }
  }

  Future<void> _delete(
    BuildContext context,
    WikiBookmarkCollection collection,
  ) async {
    final confirmed = await ThemedConfirmDialog.show(
      context: context,
      title: context.l10n.wiki_deleteCollection,
      content: collection.name,
      confirmText: context.l10n.wiki_deleteCollection,
      type: ThemedConfirmDialogType.danger,
    );
    if (!confirmed) return;
    await bookmarks.deleteCollection(collection.id);
    if (selection.id == collection.id && context.mounted) {
      onSelect(
        WikiScope(WikiScopeKind.bookmarks, null, context.l10n.wiki_bookmarks),
      );
    }
  }

  Widget _collection(
    BuildContext context,
    WikiBookmarkCollection item,
    int depth,
  ) {
    final children = bookmarks.childrenOf(item.id);
    final selected =
        selection.kind == WikiScopeKind.collection && selection.id == item.id;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(left: (depth * 13).toDouble()),
          child: _row(
            context,
            icon: Icons.bookmarks_outlined,
            label: item.name,
            count: bookmarks.tagsIn(item.id).length,
            selected: selected,
            onTap: () => onSelect(
              WikiScope(WikiScopeKind.collection, item.id, item.name),
            ),
            trailing: PopupMenuButton<String>(
              tooltip: item.name,
              icon: const Icon(Icons.more_horiz, size: 17),
              onSelected: (value) {
                if (value == 'child') _create(context, parentId: item.id);
                if (value == 'rename') _rename(context, item);
                if (value == 'delete') _delete(context, item);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'child',
                  child: Text(context.l10n.wiki_newChildCollection),
                ),
                PopupMenuItem(
                  value: 'rename',
                  child: Text(context.l10n.wiki_renameCollection),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(context.l10n.wiki_deleteCollection),
                ),
              ],
            ),
          ),
        ),
        for (final child in children) _collection(context, child, depth + 1),
      ],
    );
  }

  Widget _directoryNode(
    BuildContext context,
    WikiDirectoryNode node,
    String path,
    int depth,
  ) {
    final id = node.group ?? path;
    final label = WikiDirectoryLabels.display(node.label, context.appLanguage);
    final selected =
        selection.kind == WikiScopeKind.directory && selection.id == id;
    if (node.children.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(left: (depth * 13).toDouble()),
        child: _row(
          context,
          icon: Icons.sell_outlined,
          label: label,
          selected: selected,
          onTap: () => onSelect(
            WikiScope(WikiScopeKind.directory, id, label, node: node),
          ),
        ),
      );
    }
    return ExpansionTile(
      key: PageStorageKey('wiki-directory-$id'),
      shape: const Border(),
      collapsedShape: const Border(),
      dense: true,
      tilePadding: EdgeInsets.only(left: 12 + depth * 12, right: 4),
      childrenPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.folder_outlined,
        size: 17,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: InkWell(
        onTap: () =>
            onSelect(WikiScope(WikiScopeKind.directory, id, label, node: node)),
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
      children: [
        for (final (index, child) in _foldersFirst(node.children))
          _directoryNode(context, child, '$id/$index', depth + 1),
      ],
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
    int? count,
    Widget? trailing,
    double height = 36,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      child: Material(
        color: selected
            ? scheme.onSurface.withValues(alpha: .065)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(
                  icon,
                  size: 17,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                if (trailing != null)
                  SizedBox(width: 30, height: 32, child: trailing),
                if (trailing == null) const SizedBox(width: 11),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: theme.dividerColor)),
        ),
        child: Column(
          children: [
            SizedBox(
              key: const ValueKey('wiki-directory-header'),
              height: headerHeight,
              child: WindowHeaderDragSurface(
                enabled: allowWindowDrag,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const _WikiTitleMark(),
                        const SizedBox(width: 10),
                        Expanded(
                          child: IgnorePointer(
                            child: Text(
                              context.l10n.wiki_title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                leadingDistribution:
                                    TextLeadingDistribution.even,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.wiki_newCollection,
                          visualDensity: VisualDensity.standard,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(
                            Icons.create_new_folder_outlined,
                            size: 19,
                          ),
                          onPressed: () => _create(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  SizedBox(height: navigationHeight == null ? 9 : 5),
                  // Reserve 5px above, 4px around rows and 10px to the divider.
                  _row(
                    context,
                    height: navigationHeight == null
                        ? 36
                        : (navigationHeight! - 19) / 2,
                    icon: Icons.library_books_outlined,
                    label: context.l10n.wiki_allTags,
                    selected: selection.kind == WikiScopeKind.all,
                    onTap: () => onSelect(
                      WikiScope(
                        WikiScopeKind.all,
                        null,
                        context.l10n.wiki_allTags,
                      ),
                    ),
                  ),
                  _row(
                    context,
                    height: navigationHeight == null
                        ? 36
                        : (navigationHeight! - 19) / 2,
                    icon: Icons.bookmark_outline,
                    label: context.l10n.wiki_bookmarks,
                    count: bookmarks.bookmarkCount,
                    selected: selection.kind == WikiScopeKind.bookmarks,
                    onTap: () => onSelect(
                      WikiScope(
                        WikiScopeKind.bookmarks,
                        null,
                        context.l10n.wiki_bookmarks,
                      ),
                    ),
                  ),
                  for (final item in bookmarks.childrenOf(null))
                    _collection(context, item, 1),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                    child: Divider(
                      key: ValueKey('wiki-official-directory-divider'),
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(17, 0, 8, 7),
                    child: Text(
                      context.l10n.wiki_officialDirectory,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final (index, node) in _foldersFirst(directory.roots))
                    _directoryNode(context, node, 'root-$index', 0),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WikiTitleMark extends ConsumerStatefulWidget {
  const _WikiTitleMark();

  @override
  ConsumerState<_WikiTitleMark> createState() => _WikiTitleMarkState();
}

class _WikiTitleMarkState extends ConsumerState<_WikiTitleMark> {
  int _trigger = 0;

  @override
  Widget build(BuildContext context) => MouseRegion(
    key: const ValueKey('wiki-brand-mark'),
    onEnter: (_) => setState(() => _trigger++),
    child: StudioAnimatedIcon(
      icon: StudioIcons.tagWiki,
      trigger: _trigger,
      size: 28,
      color: Theme.of(context).colorScheme.primary,
      reducedMotion: ref.watch(canvasReducedMotionNotifierProvider),
    ),
  );
}
