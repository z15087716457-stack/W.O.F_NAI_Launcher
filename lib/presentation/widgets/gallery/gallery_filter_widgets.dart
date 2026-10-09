import 'package:flutter/material.dart';
import '../common/studio_icons.dart';
import 'gallery_nai_versions.dart';

class GalleryFilterChip extends StatelessWidget {
  const GalleryFilterChip({
    super.key,
    required this.label,
    required this.tooltip,
    required this.active,
    required this.onTap,
    this.icon,
    this.onClear,
    this.count,
    this.iconWidget,
    this.trailing,
    this.activeColor,
    this.activeForeground,
  });

  final String label;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;
  final VoidCallback? onClear;
  final int? count;
  final Widget? iconWidget, trailing;
  final Color? activeColor, activeForeground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = active
        ? activeForeground ?? colors.primary
        : colors.onSurface;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: Material(
        color: active
            ? activeColor ?? colors.primary.withValues(alpha: 0.12)
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
                if (icon != null || iconWidget != null) ...[
                  IconTheme(
                    data: IconThemeData(color: foreground, size: 14),
                    child: iconWidget ?? Icon(icon),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foreground,
                    fontSize: 12.5,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: 'Geist Mono',
                      fontSize: 11,
                      color: foreground.withValues(alpha: .7),
                    ),
                  ),
                ],
                if (trailing != null) ...[const SizedBox(width: 5), trailing!],
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
class GalleryVersionSegment extends StatelessWidget {
  const GalleryVersionSegment({
    super.key,
    required this.active,
    required this.tooltip,
    required this.allLabel,
    required this.allVariantsLabel,
    required this.onSelectAll,
    required this.onSelectVersion,
    this.showVariantMenu = true,
  });

  final ({String version, String? variant})? active;
  final String tooltip;
  final String allLabel;
  final String allVariantsLabel;
  final bool showVariantMenu;
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
                    showVariantMenu &&
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
