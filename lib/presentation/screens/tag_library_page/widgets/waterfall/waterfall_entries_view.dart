import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../../../core/utils/localization_extension.dart';
import '../../../../../data/models/tag_library/tag_library_entry.dart';
import '../../../../providers/tag_library_page_provider.dart';
import '../../../../providers/tag_library_selection_provider.dart';
import '../grouped_view/category_header.dart';
import '../grouped_view/grouped_entries_view.dart';
import 'waterfall_entry_card.dart';

/// 瀑布流视图 - 按分类分组，条目图片按原始宽高比排列
class WaterfallEntriesView extends ConsumerWidget {
  final void Function(TagLibraryEntry) onEdit;
  final void Function(TagLibraryEntry) onDelete;
  final void Function(TagLibraryEntry) onSend;

  const WaterfallEntriesView({
    super.key,
    required this.onEdit,
    required this.onDelete,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tagLibraryPageNotifierProvider);
    final selectionState = ref.watch(tagLibrarySelectionNotifierProvider);

    // 按分类分组（与分组视图同一套逻辑）
    final grouped = groupEntriesByCategory(
      state.filteredEntries,
      state.categories,
      context.l10n.tagLibrary_uncategorized,
    );

    final nonEmptyGroups = grouped.where((g) => g.entries.isNotEmpty).toList();

    if (nonEmptyGroups.isEmpty) {
      return _buildEmptyState(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = (constraints.maxWidth / 220).floor().clamp(2, 8);
        final itemWidth =
            (constraints.maxWidth - 32 - (columnCount - 1) * 12) / columnCount;

        return CustomScrollView(
          slivers: [
            for (final group in nonEmptyGroups) ...[
              // 吸顶分类标题
              SliverPersistentHeader(
                pinned: true,
                delegate: CategoryHeaderDelegate(
                  title: group.category.displayName,
                  count: group.entries.length,
                ),
              ),
              // 该分类的条目瀑布流
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: columnCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemBuilder: (context, index) => _buildEntryCard(
                    context,
                    ref,
                    group.entries[index],
                    selectionState,
                    state,
                    itemWidth,
                  ),
                  childCount: group.entries.length,
                ),
              ),
            ],
            // 底部留白
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );
  }

  /// 构建条目卡片
  Widget _buildEntryCard(
    BuildContext context,
    WidgetRef ref,
    TagLibraryEntry entry,
    SelectionModeState selectionState,
    TagLibraryPageState state,
    double itemWidth,
  ) {
    final isSelected = selectionState.isSelected(entry.id);
    final allIds = state.filteredEntries.map((e) => e.id).toList();

    return WaterfallEntryCard(
      key: ValueKey(entry.id),
      entry: entry,
      width: itemWidth,
      enableDrag: !selectionState.isActive,
      isSelectionMode: selectionState.isActive,
      isSelected: isSelected,
      onToggleSelection: () {
        final notifier = ref.read(tagLibrarySelectionNotifierProvider.notifier);
        if (HardwareKeyboard.instance.isShiftPressed) {
          notifier.selectRange(entry.id, allIds);
        } else if (!selectionState.isActive) {
          notifier.enterAndSelect(entry.id);
        } else {
          notifier.toggle(entry.id);
        }
      },
      onTap: () => onEdit(entry),
      onDelete: () => onDelete(entry),
      onEdit: () => onEdit(entry),
      onSend: () => onSend(entry),
      onToggleFavorite: () => ref
          .read(tagLibraryPageNotifierProvider.notifier)
          .toggleFavorite(entry.id),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.tagLibrary_empty,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
