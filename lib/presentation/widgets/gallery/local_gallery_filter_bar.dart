import 'dart:async';

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../data/services/gallery/gallery_group_mode.dart';
import '../../../data/services/gallery/gallery_filter_service.dart';
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
    return GalleryFilterBar(
      criteria: criteria,
      showClearFilters: state.hasSessionFilters,
      groupMode:
          state.isTimeSorted && state.browseScope != GalleryBrowseScope.recent
          ? state.groupMode
          : null,
      onNaiOnly: (value) {
        notifier.setNaiOnly(value);
        unawaited(const GalleryNaiOnlyStore().save(value));
        if (!value && criteria.filterModels.isNotEmpty) {
          notifier.setFilterModels(const []);
        }
      },
      onModels: (ids) {
        notifier.setFilterModels(ids);
        if (ids.isNotEmpty && !criteria.naiOnly) {
          notifier.setNaiOnly(true);
          unawaited(const GalleryNaiOnlyStore().save(true));
        }
      },
      onDateRange: notifier.setDateRange,
      onRemoveTag: notifier.removeSelectedTag,
      onClear: notifier.clearAllFilters,
      onGroupMode: (mode) {
        notifier.setGroupMode(mode);
        unawaited(const GalleryGroupModeStore().save(mode));
      },
    );
  }
}

/// Shared gallery controls. Data and persistence belong to each window's owner.
class GalleryFilterBar extends StatelessWidget {
  const GalleryFilterBar({
    super.key,
    required this.criteria,
    required this.onNaiOnly,
    required this.onModels,
    required this.onDateRange,
    required this.onRemoveTag,
    required this.onClear,
    required this.onGroupMode,
    this.showClearFilters = false,
    this.groupMode,
  });
  final FilterCriteria criteria;
  final ValueChanged<bool> onNaiOnly;
  final ValueChanged<List<String>> onModels;
  final void Function(DateTime?, DateTime?) onDateRange;
  final ValueChanged<String> onRemoveTag;
  final VoidCallback onClear;
  final ValueChanged<GalleryGroupMode> onGroupMode;
  final bool showClearFilters;
  final GalleryGroupMode? groupMode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final match = GalleryNaiVersions.match(criteria.filterModels);
    final chips = <Widget>[
      GalleryFilterChip(
        key: const Key('gallery-filter-nai'),
        label: l10n.localGallery_naiOnlyChip,
        tooltip: l10n.localGallery_naiOnlyTooltip,
        active: criteria.naiOnly,
        icon: criteria.naiOnly ? StudioIcons.galleryCheck : null,
        onTap: () => onNaiOnly(!criteria.naiOnly),
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
        onSelectAll: () => onModels(const <String>[]),
        onSelectVersion: (version, variant) {
          final ids = switch (variant) {
            'F' => GalleryNaiVersions.fullIds[version]!,
            'C' => GalleryNaiVersions.curatedIds[version]!,
            _ => GalleryNaiVersions.modelIds[version]!,
          };
          onModels(ids);
        },
      ),
      _DateRangeChip(
        start: criteria.dateStart,
        end: criteria.displayDateEnd,
        onPick: (result) => onDateRange(result.start, result.end),
        onClear: () => onDateRange(null, null),
      ),
      for (final tag in criteria.selectedTags)
        GalleryFilterChip(
          key: ValueKey('gallery-filter-tag-$tag'),
          label: tag,
          tooltip: l10n.localGallery_tagIntersection,
          active: true,
          icon: StudioIcons.galleryTag,
          onTap: () => onRemoveTag(tag),
          onClear: () => onRemoveTag(tag),
        ),
      if (showClearFilters)
        TextButton(
          key: const Key('gallery-filter-clear'),
          onPressed: onClear,
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
          if (groupMode != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GalleryGroupModeButton(
                value: groupMode!,
                onChanged: onGroupMode,
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
  final ValueChanged<DateRangeSelectionState> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final active = start != null || end != null;
    final format = DateFormat.MMMd(locale);
    final controller = MenuController();
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
    return MenuAnchor(
      controller: controller,
      alignmentOffset: const Offset(0, 6),
      useRootOverlay: true,
      style: const MenuStyle(padding: WidgetStatePropertyAll(EdgeInsets.zero)),
      builder: (context, controller, child) => GalleryFilterChip(
        key: const Key('gallery-filter-date'),
        label: label,
        tooltip: l10n.localGallery_dateRangeChip,
        active: active,
        icon: StudioIcons.galleryCalendar,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        onClear: active ? onClear : null,
      ),
      menuChildren: [
        CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): controller.close,
          },
          child: Focus(
            autofocus: true,
            child: GalleryDateRangePicker(
              initialStart: start,
              initialEnd: end,
              onSelected: (result) {
                controller.close();
                if (result != null) onPick(result);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class GalleryGroupModeButton extends StatelessWidget {
  const GalleryGroupModeButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

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
      constraints: const BoxConstraints(minWidth: 112, maxWidth: 240),
      menuPadding: const EdgeInsets.symmetric(vertical: 4),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final mode in GalleryGroupMode.values)
          GalleryChoiceMenuItem(
            value: mode,
            selected: mode == value,
            label: label(mode),
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
