import 'dart:async';

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../data/services/gallery/gallery_group_mode.dart';
import '../../../data/services/gallery/gallery_nai_only_store.dart';
import '../../providers/local_gallery_provider.dart';
import 'date_range_picker_dialog.dart';
import 'gallery_nai_versions.dart';
import 'gallery_filter_widgets.dart';
import '../common/studio_icons.dart';

/// 筛选条高度
const double localGalleryFilterBarHeight = 46;

/// 顶栏下方的快捷筛选：仅 NAI、模型版本、日期范围、标签与分组方式。
class LocalGalleryFilterBar extends ConsumerWidget {
  const LocalGalleryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(localGalleryChromeStateProvider);
    final criteria = state.filterCriteria;
    final notifier = ref.read(localGalleryNotifierProvider.notifier);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final match = GalleryNaiVersions.match(criteria.filterModels);

    void selectModels(List<String> ids) {
      notifier.setFilterModels(ids);
      if (ids.isNotEmpty && !criteria.naiOnly) {
        notifier.setNaiOnly(true);
        unawaited(const GalleryNaiOnlyStore().save(true));
      }
    }

    final chips = <Widget>[
      GalleryFilterChip(
        key: const Key('gallery-filter-nai'),
        label: l10n.localGallery_naiOnlyChip,
        tooltip: l10n.localGallery_naiOnlyTooltip,
        active: criteria.naiOnly,
        icon: criteria.naiOnly ? StudioIcons.galleryCheck : null,
        onTap: () {
          final next = !criteria.naiOnly;
          notifier.setNaiOnly(next);
          unawaited(const GalleryNaiOnlyStore().save(next));
          if (!next && criteria.filterModels.isNotEmpty) {
            notifier.setFilterModels(const <String>[]);
          }
        },
      ),
      Padding(
        padding: const EdgeInsets.only(left: 4, right: 2),
        child: Text(
          l10n.localGallery_modelLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
      GalleryVersionSegment(
        active: match,
        tooltip: l10n.localGallery_naiVersionFilterTooltip,
        allLabel: l10n.localGallery_allVersions,
        allVariantsLabel: l10n.localGallery_allVariants,
        onSelectAll: () => notifier.setFilterModels(const <String>[]),
        onSelectVersion: (version, variant) {
          final ids = switch (variant) {
            'F' => GalleryNaiVersions.fullIds[version]!,
            'C' => GalleryNaiVersions.curatedIds[version]!,
            _ => GalleryNaiVersions.modelIds[version]!,
          };
          selectModels(ids);
        },
      ),
      _DateRangeChip(
        start: criteria.dateStart,
        end: criteria.displayDateEnd,
        onPick: () async {
          final result = await showDateRangePickerDialog(
            context,
            initialStart: criteria.dateStart,
            initialEnd: criteria.displayDateEnd,
          );
          if (result == null) return;
          await notifier.setDateRange(result.start, result.end);
        },
        onClear: () => notifier.setDateRange(null, null),
      ),
      for (final tag in criteria.selectedTags)
        GalleryFilterChip(
          key: ValueKey('gallery-filter-tag-$tag'),
          label: tag,
          tooltip: l10n.localGallery_tagIntersection,
          active: true,
          icon: StudioIcons.galleryTag,
          onTap: () => notifier.removeSelectedTag(tag),
          onClear: () => notifier.removeSelectedTag(tag),
        ),
      if (state.hasSessionFilters)
        TextButton(
          key: const Key('gallery-filter-clear'),
          onPressed: notifier.clearAllFilters,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 28),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: theme.textTheme.bodySmall,
          ),
          child: Text(l10n.localGallery_clearFilters),
        ),
    ];

    return SizedBox(
      height: localGalleryFilterBarHeight,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                children: [
                  for (var i = 0; i < chips.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    chips[i],
                  ],
                ],
              ),
            ),
          ),
          if (state.isTimeSorted)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _GroupModeButton(
                value: state.groupMode,
                onChanged: (mode) {
                  notifier.setGroupMode(mode);
                  unawaited(const GalleryGroupModeStore().save(mode));
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DateRangeChip extends StatelessWidget {
  const _DateRangeChip({
    required this.start,
    required this.end,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? start;
  final DateTime? end;
  final Future<void> Function() onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final active = start != null || end != null;
    final format = DateFormat.MMMd(locale);
    String label;
    if (!active) {
      label = l10n.localGallery_dateRangeChip;
    } else if (start != null && end != null) {
      label = start == end
          ? format.format(start!)
          : '${format.format(start!)} – ${format.format(end!)}';
    } else if (start != null) {
      label = '${format.format(start!)} –';
    } else {
      label = '– ${format.format(end!)}';
    }
    return GalleryFilterChip(
      key: const Key('gallery-filter-date'),
      label: label,
      tooltip: l10n.localGallery_dateRangeChip,
      active: active,
      icon: StudioIcons.galleryCalendar,
      onTap: () => unawaited(onPick()),
      onClear: active ? onClear : null,
    );
  }
}

class _GroupModeButton extends StatelessWidget {
  const _GroupModeButton({required this.value, required this.onChanged});

  final GalleryGroupMode value;
  final ValueChanged<GalleryGroupMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    String label(GalleryGroupMode mode) => switch (mode) {
      GalleryGroupMode.day => l10n.localGallery_groupByDay,
      GalleryGroupMode.month => l10n.localGallery_groupByMonth,
      GalleryGroupMode.none => l10n.localGallery_groupNone,
    };
    return PopupMenuButton<GalleryGroupMode>(
      key: const Key('gallery-filter-group-mode'),
      tooltip: l10n.localGallery_groupModeTooltip,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final mode in GalleryGroupMode.values)
          CheckedPopupMenuItem(
            value: mode,
            checked: mode == value,
            child: Text(label(mode)),
          ),
      ],
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label(value),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              StudioIcons.galleryChevronDown,
              size: 15,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
