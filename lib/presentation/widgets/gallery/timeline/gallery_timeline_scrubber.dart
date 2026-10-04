import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/services/gallery/gallery_group_mode.dart';
import '../../../../data/services/gallery/unified_gallery_service.dart'
    show GalleryTimelineEntry;
import 'gallery_timeline_layout.dart';

/// 右侧时间轴：按比例标出月份/年份，拖动或点击快速定位。
///
/// 替代分页条与系统滚动条；不分组（或非时间排序）时只显示位置滑块。
class GalleryTimelineScrubber extends StatefulWidget {
  const GalleryTimelineScrubber({
    super.key,
    required this.layout,
    required this.entries,
    required this.groupMode,
    required this.scrollController,
  });

  final GalleryTimelineLayout layout;
  final List<GalleryTimelineEntry> entries;

  /// 用户选择的分组方式（非时间排序时布局里没有日期分组）
  final GalleryGroupMode groupMode;
  final ScrollController scrollController;

  @override
  State<GalleryTimelineScrubber> createState() =>
      _GalleryTimelineScrubberState();
}

class _ScrubberMark {
  const _ScrubberMark(this.offset, this.label, {required this.isYear});

  final double offset;
  final String label;
  final bool isYear;
}

class _GalleryTimelineScrubberState extends State<GalleryTimelineScrubber> {
  static const _trackInset = 14.0;
  static const _minLabelGap = 18.0;

  double? _hoverY;
  bool _dragging = false;
  List<_ScrubberMark>? _marks;
  Object? _marksKey;

  double get _maxScroll => widget.scrollController.hasClients
      ? widget.scrollController.position.maxScrollExtent
      : 0;

  List<_ScrubberMark> _buildMarks(String locale) {
    final key = (widget.layout, locale);
    if (key == _marksKey && _marks != null) return _marks!;
    _marksKey = key;
    final marks = <_ScrubberMark>[];
    int? lastYear;
    int? lastMonth;
    final monthFormat = DateFormat.MMM(locale);
    for (final section in widget.layout.sections) {
      final date = section.date;
      if (date == null) continue;
      if (date.year != lastYear) {
        marks.add(
          _ScrubberMark(section.headerTop, '${date.year}', isYear: true),
        );
      } else if (date.month != lastMonth) {
        marks.add(
          _ScrubberMark(
            section.headerTop,
            monthFormat.format(date),
            isYear: false,
          ),
        );
      }
      lastYear = date.year;
      lastMonth = date.month;
    }
    return _marks = marks;
  }

  /// 去重叠：年份优先，月份只填年份之间的空位。
  List<(double, _ScrubberMark)> _placeMarks(
    List<_ScrubberMark> marks,
    double trackHeight,
  ) {
    final maxScroll = _maxScroll;
    if (maxScroll <= 0 || marks.isEmpty) return const [];
    double toY(double offset) =>
        _trackInset + (offset / maxScroll).clamp(0.0, 1.0) * trackHeight;
    final placed = <(double, _ScrubberMark)>[];
    bool fits(double y) =>
        placed.every((item) => (item.$1 - y).abs() >= _minLabelGap);
    for (final mark in marks.where((m) => m.isYear)) {
      final y = toY(mark.offset);
      if (fits(y)) placed.add((y, mark));
    }
    for (final mark in marks.where((m) => !m.isYear)) {
      final y = toY(mark.offset);
      if (fits(y)) placed.add((y, mark));
    }
    return placed;
  }

  void _jumpTo(double localY, double trackHeight) {
    if (!widget.scrollController.hasClients || trackHeight <= 0) return;
    final fraction = ((localY - _trackInset) / trackHeight).clamp(0.0, 1.0);
    widget.scrollController.jumpTo(fraction * _maxScroll);
  }

  String? _labelAt(double localY, double trackHeight, String locale) {
    final maxScroll = _maxScroll;
    if (maxScroll <= 0 || widget.layout.sections.isEmpty) return null;
    final fraction = ((localY - _trackInset) / trackHeight).clamp(0.0, 1.0);
    final index = widget.layout.sectionIndexAt(fraction * maxScroll);
    if (index < 0) return null;
    final section = widget.layout.sections[index];
    final date =
        section.date ??
        (section.start < widget.entries.length
            ? widget.entries[section.start].modifiedAt
            : null);
    if (date == null || section.date == null) return null;
    return widget.groupMode == GalleryGroupMode.month
        ? DateFormat.yMMMM(locale).format(date)
        : DateFormat.yMMMd(locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackHeight = math.max(
          0.0,
          constraints.maxHeight - _trackInset * 2,
        );
        return AnimatedBuilder(
          animation: widget.scrollController,
          builder: (context, _) {
            final maxScroll = _maxScroll;
            if (maxScroll <= 0) return const SizedBox.shrink();
            final offset = widget.scrollController.offset;
            final thumbY =
                _trackInset +
                (offset / maxScroll).clamp(0.0, 1.0) * trackHeight;
            final placed = _placeMarks(_buildMarks(locale), trackHeight);
            final hoverY = _hoverY;
            final hoverLabel = hoverY == null
                ? null
                : _labelAt(hoverY, trackHeight, locale);
            final active = _dragging || hoverY != null;

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onHover: (event) =>
                  setState(() => _hoverY = event.localPosition.dy),
              onExit: (_) => setState(() => _hoverY = null),
              child: GestureDetector(
                key: const Key('gallery-timeline-scrubber'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) =>
                    _jumpTo(details.localPosition.dy, trackHeight),
                onVerticalDragStart: (details) {
                  setState(() => _dragging = true);
                  _jumpTo(details.localPosition.dy, trackHeight);
                },
                onVerticalDragUpdate: (details) {
                  setState(() => _hoverY = details.localPosition.dy);
                  _jumpTo(details.localPosition.dy, trackHeight);
                },
                onVerticalDragEnd: (_) => setState(() => _dragging = false),
                onVerticalDragCancel: () => setState(() => _dragging = false),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: 8,
                      top: _trackInset,
                      bottom: _trackInset,
                      width: 1,
                      child: ColoredBox(color: theme.dividerColor),
                    ),
                    for (final (y, mark) in placed) ...[
                      Positioned(
                        right: 6,
                        top: y - 2.5,
                        width: 5,
                        height: 5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.outline,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 15,
                        top: y - 8,
                        height: 16,
                        child: Center(
                          child: Text(
                            mark.label,
                            maxLines: 1,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10.5,
                              fontWeight: mark.isYear
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: mark.isYear
                                  ? colors.onSurface
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                    Positioned(
                      right: 3,
                      top: thumbY - (active ? 2 : 1.5),
                      width: active ? 13 : 11,
                      height: active ? 4 : 3,
                      child: DecoratedBox(
                        key: const Key('gallery-timeline-scrubber-thumb'),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (hoverY != null && hoverLabel != null)
                      Positioned(
                        right: constraints.maxWidth + 4,
                        top: (hoverY - 12).clamp(
                          0.0,
                          constraints.maxHeight - 24,
                        ),
                        child: IgnorePointer(
                          child: Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.inverseSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              hoverLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onInverseSurface,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
