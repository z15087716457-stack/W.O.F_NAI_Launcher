import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/localization_extension.dart';
import '../../providers/local_gallery_provider.dart';
import '../../providers/selection_mode_provider.dart';

/// 多选时浮在内容底部中央的操作条（不替换顶栏，筛选与搜索保持可见）。
class GalleryFloatingBulkBar extends ConsumerWidget {
  const GalleryFloatingBulkBar({
    super.key,
    required this.onSelectAllResults,
    required this.onMove,
    required this.onCopy,
    required this.onPack,
    required this.onEditMetadata,
    required this.onAddToCollection,
    required this.onDelete,
    this.onRemoveFromCollection,
  });

  final Future<void> Function() onSelectAllResults;
  final VoidCallback onMove;
  final VoidCallback onCopy;
  final VoidCallback onPack;
  final VoidCallback onEditMetadata;
  final VoidCallback onAddToCollection;
  final VoidCallback onDelete;

  /// 仅在按收藏集浏览时提供
  final VoidCallback? onRemoveFromCollection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(localGallerySelectionNotifierProvider);
    if (!selection.isActive) return const SizedBox.shrink();
    final resultCount = ref.watch(
      localGalleryNotifierProvider.select((s) => s.resultCount),
    );
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final count = selection.selectedIds.length;
    final allSelected = resultCount > 0 && count >= resultCount;
    final notifier = ref.read(localGallerySelectionNotifierProvider.notifier);
    final hasSelection = count > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;
        Widget action(
          IconData icon,
          String label,
          VoidCallback? onPressed, {
          bool danger = false,
          Key? key,
        }) {
          final color = danger ? colors.error : colors.onSurface;
          final button = compact
              ? IconButton(
                  key: key,
                  onPressed: onPressed,
                  tooltip: label,
                  icon: Icon(icon, size: 18),
                  color: color,
                )
              : TextButton.icon(
                  key: key,
                  onPressed: onPressed,
                  icon: Icon(
                    icon,
                    size: 17,
                    color: danger ? colors.error : colors.onSurfaceVariant,
                  ),
                  label: Text(label),
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 34),
                    textStyle: theme.textTheme.bodyMedium,
                  ),
                );
          return button;
        }

        Widget divider() => Container(
          width: 1,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          color: theme.dividerColor,
        );

        return Material(
          key: const Key('gallery-floating-bulk-bar'),
          color: colors.surfaceContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.dividerColor),
          ),
          shadowColor: Colors.black,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.45 : 0.12,
                  ),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: const Key('gallery-bulk-exit'),
                      onPressed: notifier.exit,
                      tooltip: l10n.common_exit,
                      icon: const Icon(Icons.close, size: 18),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 2, right: 8),
                      child: Text(
                        l10n.localGallery_selectedImages(
                          NumberFormat.decimalPattern(locale).format(count),
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('gallery-bulk-select-all'),
                      onPressed: allSelected
                          ? notifier.clearSelection
                          : () => onSelectAllResults(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 30),
                        textStyle: theme.textTheme.bodySmall,
                      ),
                      child: Text(
                        allSelected
                            ? l10n.localGallery_deselectAllResults
                            : l10n.localGallery_selectAllResults,
                      ),
                    ),
                    divider(),
                    action(
                      Icons.drive_file_move_outline,
                      l10n.localGallery_moveSelected,
                      hasSelection ? onMove : null,
                    ),
                    action(
                      Icons.file_copy_outlined,
                      l10n.localGallery_copyTo,
                      hasSelection ? onCopy : null,
                    ),
                    action(
                      Icons.archive_outlined,
                      l10n.localGallery_packSelected,
                      hasSelection ? onPack : null,
                    ),
                    action(
                      Icons.edit_outlined,
                      l10n.localGallery_editMetadata,
                      hasSelection ? onEditMetadata : null,
                    ),
                    action(
                      Icons.bookmark_add_outlined,
                      l10n.localGallery_addToCollection,
                      hasSelection ? onAddToCollection : null,
                    ),
                    if (onRemoveFromCollection != null)
                      action(
                        Icons.bookmark_remove_outlined,
                        l10n.localGallery_removeFromCollection,
                        hasSelection ? onRemoveFromCollection : null,
                      ),
                    divider(),
                    action(
                      Icons.delete_outline,
                      l10n.common_delete,
                      hasSelection ? onDelete : null,
                      danger: true,
                      key: const Key('gallery-bulk-delete'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
