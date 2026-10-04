import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/gallery/gallery_group_mode.dart';
import 'package:nai_launcher/data/services/gallery/gallery_view_mode.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/presentation/widgets/gallery/timeline/gallery_timeline_layout.dart';

List<GalleryTimelineEntry> _entries(int count, {int perDay = 7}) {
  const sizes = [(832, 1216), (1216, 832), (1024, 1024), (1472, 640)];
  final start = DateTime(2026, 10, 4, 20);
  return [
    for (var i = 0; i < count; i++)
      GalleryTimelineEntry(
        path: 'C:/gallery/$i.png',
        modifiedAt: start.subtract(Duration(days: i ~/ perDay, minutes: i)),
        width: sizes[i % sizes.length].$1,
        height: sizes[i % sizes.length].$2,
      ),
  ];
}

void main() {
  const width = 1000.0;
  const left = 16.0;
  const right = 48.0;

  GalleryTimelineLayout layout(
    List<GalleryTimelineEntry> entries, {
    GalleryViewMode mode = GalleryViewMode.justified,
    GalleryGroupMode group = GalleryGroupMode.day,
  }) => computeGalleryTimelineLayout(
    entries: entries,
    viewMode: mode,
    groupMode: group,
    width: width,
    tileSize: 220,
    leftPadding: left,
    rightPadding: right,
  );

  test('groups consecutive entries by day with a header per section', () {
    final entries = _entries(30);
    final result = layout(entries);

    expect(result.sections, hasLength(5));
    expect(result.sections.first.date, DateTime(2026, 10, 4));
    expect(result.sections.map((s) => s.count).reduce((a, b) => a + b), 30);
    for (final section in result.sections) {
      final firstTile = result.tiles[section.start];
      expect(firstTile.top, section.headerTop + result.headerHeight);
      expect(result.sectionIndexOf(section.start), isNonNegative);
    }
    expect(result.sectionIndexAt(result.sections[2].headerTop + 1), 2);
  });

  test('month grouping merges days and no grouping has no headers', () {
    final entries = _entries(90, perDay: 2);
    final byMonth = layout(entries, group: GalleryGroupMode.month);
    expect(byMonth.sections.map((s) => s.date), [
      DateTime(2026, 10),
      DateTime(2026, 9),
      DateTime(2026, 8),
    ]);

    final flat = layout(entries, group: GalleryGroupMode.none);
    expect(flat.sections, hasLength(1));
    expect(flat.sections.single.hasHeader, isFalse);
    expect(flat.headerHeight, 0);
  });

  for (final mode in GalleryViewMode.values) {
    test('${mode.name}: tiles stay inside the content box without overlap', () {
      final entries = _entries(60);
      final result = layout(entries, mode: mode);
      for (var i = 0; i < result.tiles.length; i++) {
        final rect = result.tiles[i];
        expect(rect.left, greaterThanOrEqualTo(left - 0.01));
        expect(rect.right, lessThanOrEqualTo(width - right + 0.01));
        expect(rect.width, greaterThan(0));
        expect(rect.height, greaterThan(0));
        for (var j = i + 1; j < result.tiles.length; j++) {
          final overlap = rect.intersect(result.tiles[j]);
          expect(
            overlap.width <= 0.01 || overlap.height <= 0.01,
            isTrue,
            reason: 'tiles $i and $j overlap',
          );
        }
      }
      expect(result.extent, greaterThan(result.tiles.last.bottom));
    });

    test('${mode.name}: visible-range query matches a brute-force scan', () {
      final entries = _entries(200);
      final result = layout(entries, mode: mode);
      for (final top in [0.0, 333.0, 1800.0, result.extent - 500]) {
        final bottom = top + 700;
        final expected = {
          for (var i = 0; i < result.tiles.length; i++)
            if (result.tiles[i].bottom > top && result.tiles[i].top < bottom) i,
        };
        expect(result.indicesIn(top, bottom).toSet(), expected);
      }
      final probe = result.tiles[37];
      expect(result.indexAt(probe.center), 37);
      expect(result.indexAt(Offset(left / 2, probe.center.dy)), isNull);
    });
  }

  test('justified rows keep each image ratio; only the last row is short', () {
    final entries = _entries(40);
    final result = layout(entries, group: GalleryGroupMode.none);
    final rows = <double, List<int>>{};
    for (var i = 0; i < result.tiles.length; i++) {
      rows.putIfAbsent(result.tiles[i].top, () => []).add(i);
    }
    final ordered = rows.values.toList();
    for (final row in ordered) {
      final first = result.tiles[row.first];
      final last = result.tiles[row.last];
      expect(first.left, closeTo(left, 0.01));
      for (final i in row) {
        final rect = result.tiles[i];
        expect(rect.height, first.height, reason: 'one height per row');
        expect(
          rect.width / rect.height,
          closeTo(entries[i].aspectRatio!, 0.01),
          reason: 'tile $i is cropped or stretched',
        );
      }
      if (row != ordered.last) {
        expect(last.right, closeTo(width - right, 0.01));
      }
    }
    expect(result.tiles.last.height, lessThanOrEqualTo(220 * 1.15 + 0.01));
  });

  test('justified: a lone image in a day is not blown up to full width', () {
    final entries = [
      GalleryTimelineEntry(
        path: 'C:/gallery/wide.png',
        modifiedAt: DateTime(2026, 9, 22, 12),
        width: 1920,
        height: 1088,
      ),
      ..._entries(8).map(
        (e) => GalleryTimelineEntry(
          path: e.path,
          modifiedAt: DateTime(2026, 9, 21, 12),
          width: e.width,
          height: e.height,
        ),
      ),
    ];
    final result = layout(entries);
    expect(result.sections.first.count, 1);
    final lone = result.tiles.first;
    expect(lone.height, 220);
    expect(lone.width, closeTo(220 * 1920 / 1088, 0.01));
    expect(lone.right, lessThan(width - right));
  });

  test('lays out a 45k-image library without quadratic blowup', () {
    final entries = _entries(45000, perDay: 400);
    final watch = Stopwatch()..start();
    final grouped = layout(entries);
    final flat = layout(entries, group: GalleryGroupMode.none);
    watch.stop();
    expect(grouped.tiles, hasLength(45000));
    expect(flat.tiles, hasLength(45000));
    expect(watch.elapsedMilliseconds, lessThan(4000));
  });
}
