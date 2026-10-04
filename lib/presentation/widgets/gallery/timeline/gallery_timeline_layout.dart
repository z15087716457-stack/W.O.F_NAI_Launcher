import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../../../../core/utils/justified_layout.dart';
import '../../../../data/services/gallery/gallery_group_mode.dart';
import '../../../../data/services/gallery/gallery_view_mode.dart';
import '../../../../data/services/gallery/unified_gallery_service.dart'
    show GalleryTimelineEntry;

/// 连续画廊中的一个分组（按天/月；不分组时只有一个无日期分组）。
class GalleryTimelineSection {
  const GalleryTimelineSection({
    required this.start,
    required this.end,
    required this.date,
    required this.headerTop,
    required this.bottom,
  });

  /// 起始条目索引（含）
  final int start;

  /// 结束条目索引（不含）
  final int end;

  /// 分组日期（按天为当天零点，按月为当月 1 日）；不分组为 null
  final DateTime? date;

  /// 分组标题顶部（内容坐标）
  final double headerTop;

  /// 分组内容底部（内容坐标，不含分组间距）
  final double bottom;

  int get count => end - start;
  bool get hasHeader => date != null;
  bool contains(int index) => index >= start && index < end;
}

/// 整个数据集的排版结果：每个条目的矩形、分组与总高度。
///
/// 坐标以滚动内容左上角为原点（已含左右内边距）。查询可见区域走
/// 按顶边排序的索引二分，整库四五万张也只遍历可见附近的条目。
class GalleryTimelineLayout {
  GalleryTimelineLayout._({
    required this.tiles,
    required this.sections,
    required this.extent,
    required this.headerHeight,
    required Int32List byTop,
    required double maxTileHeight,
  }) : _byTop = byTop,
       _maxTileHeight = maxTileHeight;

  static final empty = GalleryTimelineLayout._(
    tiles: const [],
    sections: const [],
    extent: 0,
    headerHeight: 0,
    byTop: Int32List(0),
    maxTileHeight: 0,
  );

  final List<Rect> tiles;
  final List<GalleryTimelineSection> sections;
  final double extent;
  final double headerHeight;
  final Int32List _byTop;
  final double _maxTileHeight;

  bool get isEmpty => tiles.isEmpty;

  /// 与 [top, bottom) 相交的条目索引（按顶边升序）。
  List<int> indicesIn(double top, double bottom) {
    if (tiles.isEmpty || bottom <= top) return const [];
    final from = top - _maxTileHeight;
    var low = 0;
    var high = _byTop.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (tiles[_byTop[mid]].top < from) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    final result = <int>[];
    for (var i = low; i < _byTop.length; i++) {
      final rect = tiles[_byTop[i]];
      if (rect.top >= bottom) break;
      if (rect.bottom > top) result.add(_byTop[i]);
    }
    return result;
  }

  /// 指定纵坐标所在分组（标题区也算该分组）；空布局返回 -1。
  int sectionIndexAt(double y) {
    if (sections.isEmpty) return -1;
    var low = 0;
    var high = sections.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (sections[mid].headerTop <= y) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  /// 条目所在分组索引；越界返回 -1。
  int sectionIndexOf(int index) {
    if (index < 0 || index >= tiles.length) return -1;
    var low = 0;
    var high = sections.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final section = sections[mid];
      if (index < section.start) {
        high = mid - 1;
      } else if (index >= section.end) {
        low = mid + 1;
      } else {
        return mid;
      }
    }
    return -1;
  }

  /// 命中测试：内容坐标下的条目索引（落在间隙或标题上返回 null）。
  int? indexAt(Offset position) {
    for (final index in indicesIn(position.dy, position.dy + 1)) {
      if (tiles[index].contains(position)) return index;
    }
    return null;
  }
}

/// 分组键：按天取当天零点，按月取当月 1 日。
DateTime galleryGroupDate(DateTime time, GalleryGroupMode mode) =>
    switch (mode) {
      GalleryGroupMode.month => DateTime(time.year, time.month),
      _ => DateTime(time.year, time.month, time.day),
    };

/// 计算整个数据集的排版。
///
/// - justified：每个分组独立做等高行断行（[computeJustifiedRows]），
///   [tileSize] 为目标行高，分组末行不拉满；
/// - grid：方格，列数由 [tileSize] 推导；
/// - masonry：瀑布流，列宽由 [tileSize] 推导，按最短列放置。
GalleryTimelineLayout computeGalleryTimelineLayout({
  required List<GalleryTimelineEntry> entries,
  required GalleryViewMode viewMode,
  required GalleryGroupMode groupMode,
  required double width,
  required double tileSize,
  double gap = 4,
  double leftPadding = 16,
  double rightPadding = 16,
  double headerHeight = 44,
  double sectionSpacing = 12,
  double topPadding = 4,
  double bottomPadding = 32,
}) {
  final contentWidth = width - leftPadding - rightPadding;
  if (entries.isEmpty || contentWidth <= 0) return GalleryTimelineLayout.empty;

  final tiles = List<Rect>.filled(entries.length, Rect.zero);
  final sections = <GalleryTimelineSection>[];
  final grouped = groupMode != GalleryGroupMode.none;
  var y = grouped ? 0.0 : topPadding;
  var maxTileHeight = 0.0;
  var monotonic = true;

  final aspects = Float64List(entries.length);
  for (var i = 0; i < entries.length; i++) {
    final ratio = entries[i].aspectRatio ?? 1.0;
    aspects[i] = ratio.clamp(0.2, 5.0).toDouble();
  }

  void place(int index, double left, double top, double w, double h) {
    tiles[index] = Rect.fromLTWH(leftPadding + left, top, w, h);
    if (h > maxTileHeight) maxTileHeight = h;
  }

  /// 排一个分组，返回分组内容底部
  double layoutSection(int start, int end, double top) {
    switch (viewMode) {
      case GalleryViewMode.justified:
        final rows = computeJustifiedRows(
          aspectRatios: Float64List.sublistView(aspects, start, end),
          availableWidth: contentWidth,
          targetHeight: tileSize,
          spacing: gap,
        );
        var rowTop = top;
        for (final row in rows) {
          var x = 0.0;
          for (var k = row.start; k < row.end; k++) {
            final index = start + k;
            // 满行最后一张吸收舍入误差，右缘与内容区精确对齐
            final w = row.filled && k == row.end - 1
                ? contentWidth - x
                : row.height * aspects[index];
            place(index, x, rowTop, w, row.height);
            x += w + gap;
          }
          rowTop += row.height + gap;
        }
        return rowTop - gap;
      case GalleryViewMode.grid:
        final columns = math.max(
          1,
          ((contentWidth + gap) / (tileSize + gap)).floor(),
        );
        final cell = (contentWidth - gap * (columns - 1)) / columns;
        var bottom = top;
        for (var i = start; i < end; i++) {
          final local = i - start;
          final row = local ~/ columns;
          final column = local % columns;
          final cellTop = top + row * (cell + gap);
          place(i, column * (cell + gap), cellTop, cell, cell);
          bottom = cellTop + cell;
        }
        return bottom;
      case GalleryViewMode.masonry:
        monotonic = false;
        final columns = math.max(
          1,
          ((contentWidth + gap) / (tileSize + gap)).floor(),
        );
        final columnWidth = (contentWidth - gap * (columns - 1)) / columns;
        final heights = List<double>.filled(columns, top);
        for (var i = start; i < end; i++) {
          var shortest = 0;
          for (var c = 1; c < columns; c++) {
            if (heights[c] < heights[shortest]) shortest = c;
          }
          final h = columnWidth / aspects[i];
          place(
            i,
            shortest * (columnWidth + gap),
            heights[shortest],
            columnWidth,
            h,
          );
          heights[shortest] += h + gap;
        }
        return heights.reduce(math.max) - gap;
    }
  }

  var start = 0;
  while (start < entries.length) {
    var end = entries.length;
    DateTime? date;
    if (grouped) {
      date = galleryGroupDate(entries[start].modifiedAt, groupMode);
      end = start + 1;
      while (end < entries.length &&
          galleryGroupDate(entries[end].modifiedAt, groupMode) == date) {
        end++;
      }
    }
    final headerTop = y;
    final contentTop = grouped ? y + headerHeight : y;
    final bottom = layoutSection(start, end, contentTop);
    sections.add(
      GalleryTimelineSection(
        start: start,
        end: end,
        date: date,
        headerTop: headerTop,
        bottom: bottom,
      ),
    );
    y = bottom + sectionSpacing;
    start = end;
  }

  final byTop = Int32List.fromList(List<int>.generate(tiles.length, (i) => i));
  if (!monotonic) {
    final sorted = byTop.toList()
      ..sort((a, b) {
        final cmp = tiles[a].top.compareTo(tiles[b].top);
        return cmp != 0 ? cmp : a.compareTo(b);
      });
    byTop.setAll(0, sorted);
  }

  return GalleryTimelineLayout._(
    tiles: tiles,
    sections: sections,
    extent: y - sectionSpacing + bottomPadding,
    headerHeight: grouped ? headerHeight : 0,
    byTop: byTop,
    maxTileHeight: maxTileHeight,
  );
}
