import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../data/services/gallery/gallery_group_mode.dart';
import '../../../data/services/gallery/gallery_nai_only_store.dart';
import '../../providers/local_gallery_provider.dart';
import 'date_range_picker_dialog.dart';
import 'gallery_nai_versions.dart';
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
      _FilterChip(
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
      _VersionSegment(
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
        end: criteria.dateEnd,
        onPick: () async {
          final result = await showDateRangePickerDialog(
            context,
            initialStart: criteria.dateStart,
            initialEnd: criteria.dateEnd,
          );
          if (result == null) return;
          await notifier.setDateRange(result.start, result.end);
        },
        onClear: () => notifier.setDateRange(null, null),
      ),
      for (final tag in criteria.selectedTags)
        _FilterChip(
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.tooltip,
    required this.active,
    required this.onTap,
    this.icon,
    this.onClear,
  });

  final String label;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = active ? colors.primary : colors.onSurface;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: Material(
        color: active
            ? colors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: active
              ? BorderSide.none
              : BorderSide(color: theme.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 28,
            padding: EdgeInsets.only(left: 10, right: onClear == null ? 10 : 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: foreground),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foreground,
                    fontSize: 12.5,
                  ),
                ),
                if (onClear != null)
                  InkWell(
                    onTap: onClear,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        StudioIcons.galleryClose,
                        size: 13,
                        color: foreground,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 模型版本分段：全部 / V3 / V4 / V4.5 / V5；选中的 V4 起可切 Full / Curated。
class _VersionSegment extends StatelessWidget {
  const _VersionSegment({
    required this.active,
    required this.tooltip,
    required this.allLabel,
    required this.allVariantsLabel,
    required this.onSelectAll,
    required this.onSelectVersion,
  });

  final ({String version, String? variant})? active;
  final String tooltip;
  final String allLabel;
  final String allVariantsLabel;
  final VoidCallback onSelectAll;
  final void Function(String version, String? variant) onSelectVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final border = BorderSide(color: theme.dividerColor);

    Widget segment({
      required Key key,
      required String label,
      required bool selected,
      required VoidCallback onTap,
      Widget? trailing,
      bool first = false,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: selected ? colors.surfaceContainerHighest : null,
          border: first ? null : Border(left: border),
        ),
        child: InkWell(
          key: key,
          onTap: onTap,
          child: Container(
            height: 26,
            padding: EdgeInsets.only(
              left: 10,
              right: trailing == null ? 10 : 2,
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: colors.onSurface,
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      );
    }

    final current = active;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 700),
      child: Container(
        key: const Key('gallery-filter-versions'),
        decoration: BoxDecoration(
          border: Border.fromBorderSide(border),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            segment(
              key: const ValueKey('gallery-version-all'),
              label: allLabel,
              selected: current == null,
              onTap: onSelectAll,
              first: true,
            ),
            for (final version in GalleryNaiVersions.labels)
              segment(
                key: ValueKey('gallery-version-$version'),
                label: current?.version == version && current?.variant != null
                    ? 'V$version ${current!.variant}'
                    : 'V$version',
                selected: current?.version == version,
                onTap: () => current?.version == version
                    ? onSelectAll()
                    : onSelectVersion(version, null),
                trailing:
                    current?.version == version &&
                        GalleryNaiVersions.fullIds.containsKey(version)
                    ? _VariantMenu(
                        version: version,
                        active: current!.variant,
                        allLabel: allVariantsLabel,
                        onSelected: (variant) =>
                            onSelectVersion(version, variant),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _VariantMenu extends StatelessWidget {
  const _VariantMenu({
    required this.version,
    required this.active,
    required this.allLabel,
    required this.onSelected,
  });

  final String version;
  final String? active;
  final String allLabel;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      key: ValueKey('gallery-version-variant-$version'),
      tooltip: 'Full / Curated',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      padding: EdgeInsets.zero,
      onSelected: (value) => onSelected(value == 'all' ? null : value),
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: 'all',
          checked: active == null,
          child: Text(allLabel),
        ),
        CheckedPopupMenuItem(
          value: 'F',
          checked: active == 'F',
          child: const Text('Full'),
        ),
        CheckedPopupMenuItem(
          value: 'C',
          checked: active == 'C',
          child: const Text('Curated'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          StudioIcons.galleryChevronDown,
          size: 15,
          color: colors.onSurfaceVariant,
        ),
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
    return _FilterChip(
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
