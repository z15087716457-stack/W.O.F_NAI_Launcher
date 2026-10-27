import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../data/services/gallery/gallery_group_mode.dart';
import '../../common/studio_icons.dart';
import 'gallery_timeline_layout.dart';

/// Shared date/count header; main-gallery selection is supplied by its adapter.
class GalleryTimelineGroupHeader extends StatefulWidget {
  const GalleryTimelineGroupHeader({
    super.key,
    required this.section,
    required this.groupMode,
    this.selectedCount = 0,
    this.onToggle,
    this.opaque = false,
    this.reducedMotion = false,
  });
  final GalleryTimelineSection section;
  final GalleryGroupMode groupMode;
  final int selectedCount;
  final VoidCallback? onToggle;
  final bool opaque, reducedMotion;
  @override
  State<GalleryTimelineGroupHeader> createState() =>
      _GalleryTimelineGroupHeaderState();
}

class _GalleryTimelineGroupHeaderState
    extends State<GalleryTimelineGroupHeader> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final section = widget.section;
    final date = section.date!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final groupMode = widget.groupMode;
    final selectedCount = widget.selectedCount;
    final allSelected = selectedCount > 0 && selectedCount == section.count;
    final showCheck =
        widget.onToggle != null && (_hovered || selectedCount > 0);
    final reducedMotion =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context);

    final count = NumberFormat.decimalPattern(locale).format(section.count);
    final countText = l10n.localGallery_groupImageCount(section.count, count);
    final (title, detail) = _labels(date, groupMode, locale, l10n);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        color: widget.opaque ? colors.surface : null,
        padding: const EdgeInsets.only(left: galleryTimelineLeftPadding),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            AnimatedContainer(
              duration: reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              width: showCheck ? 26 : 0,
              child: showCheck
                  ? Semantics(
                      button: true,
                      selected: allSelected,
                      label: l10n.localGallery_selectGroup,
                      child: GestureDetector(
                        key: const Key('gallery-group-select'),
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onToggle,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: allSelected ? colors.primary : null,
                              border: Border.all(
                                color: allSelected
                                    ? colors.primary
                                    : colors.outline,
                                width: 1.5,
                              ),
                            ),
                            child: allSelected
                                ? Icon(
                                    StudioIcons.galleryCheckBold,
                                    size: 13,
                                    color: colors.onPrimary,
                                  )
                                : selectedCount > 0
                                ? Center(
                                    child: Container(
                                      width: 8,
                                      height: 2,
                                      color: colors.primary,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                detail == null ? countText : '$detail · $countText',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, String?) _labels(
    DateTime date,
    GalleryGroupMode mode,
    String locale,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    if (mode == GalleryGroupMode.month) {
      return (
        date.year == now.year
            ? DateFormat.MMMM(locale).format(date)
            : DateFormat.yMMMM(locale).format(date),
        null,
      );
    }
    final today = DateTime(now.year, now.month, now.day);
    final weekday = DateFormat.E(locale).format(date);
    final dayText = date.year == now.year
        ? DateFormat.MMMd(locale).format(date)
        : DateFormat.yMMMd(locale).format(date);
    if (date == today) {
      return (l10n.localGallery_group_today, '$dayText $weekday');
    }
    if (date == today.subtract(const Duration(days: 1))) {
      return (l10n.localGallery_group_yesterday, '$dayText $weekday');
    }
    return (dayText, weekday);
  }
}

class GalleryTimelineStickyHeader extends StatelessWidget {
  const GalleryTimelineStickyHeader({
    super.key,
    required this.layout,
    required this.scrollController,
    required this.headerBuilder,
  });
  final GalleryTimelineLayout layout;
  final ScrollController scrollController;
  final Widget Function(GalleryTimelineSection section) headerBuilder;
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: scrollController,
        builder: (context, _) {
          final offset = scrollController.hasClients
              ? scrollController.offset
              : 0.0;
          if (offset <= 0) return const SizedBox.shrink();
          final index = layout.sectionIndexAt(offset);
          if (index < 0) return const SizedBox.shrink();
          final section = layout.sections[index];
          if (!section.hasHeader || section.headerTop >= offset) {
            return const SizedBox.shrink();
          }
          var shift = 0.0;
          if (index + 1 < layout.sections.length) {
            final nextTop = layout.sections[index + 1].headerTop - offset;
            if (nextTop < layout.headerHeight) {
              shift = nextTop - layout.headerHeight;
            }
          }
          return Transform.translate(
            offset: Offset(0, shift),
            child: headerBuilder(section),
          );
        },
      ),
    );
  }
}
