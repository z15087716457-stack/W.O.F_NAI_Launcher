import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/justified_layout.dart';

void main() {
  const width = 1000.0;
  const target = 200.0;

  List<JustifiedRow> layout(
    List<double> aspects, {
    double spacing = 0,
    double w = width,
  }) => computeJustifiedRows(
    aspectRatios: aspects,
    availableWidth: w,
    targetHeight: target,
    spacing: spacing,
  );

  double rowWidth(List<double> aspects, JustifiedRow row, double spacing) {
    var sum = 0.0;
    for (var i = row.start; i < row.end; i++) {
      sum += aspects[i];
    }
    return row.height * sum + spacing * (row.count - 1);
  }

  test('empty input or zero width gives no rows', () {
    expect(layout(const []), isEmpty);
    expect(layout(const [1, 1], w: 0), isEmpty);
  });

  test('a lone image keeps the target height instead of filling the row', () {
    final rows = layout(const [1920 / 1088]);
    expect(rows, hasLength(1));
    expect(rows.single.height, target);
    expect(rows.single.filled, isFalse);
  });

  test('a short trailing row stays at the target height, left aligned', () {
    final rows = layout(const [1, 1, 1, 1, 1, 0.7, 0.7]);
    expect(rows, hasLength(2));
    expect(rows.first.filled, isTrue);
    expect(rows.last.height, target);
    expect(rows.last.filled, isFalse);
  });

  test('a nearly full trailing row is stretched a little to close the gap', () {
    final rows = layout(const [1, 1, 1, 1.5]);
    expect(rows.single.filled, isTrue);
    expect(rows.single.height, closeTo(1000 / 4.5, 1e-9));
    expect(
      rows.single.height,
      lessThanOrEqualTo(target * justifiedLastRowMaxStretch),
    );
  });

  test('includes the overflowing image when that stays closer to target', () {
    // 4 squares = 800px; a 1.5 image makes 1100px. Including it gives
    // 1000/5.5 ≈ 182 (×1.1), ending before it gives 250 (×1.25).
    final rows = layout(const [1, 1, 1, 1, 1.5, 1]);
    expect(rows.first.end, 5);
    expect(rows.first.height, closeTo(1000 / 5.5, 1e-9));
  });

  test('ends the row early when squeezing the next image would be worse', () {
    // A 3:1 image would squeeze the row to ≈143 (×1.4); ending at 4 squares
    // gives 250 (×1.25).
    final rows = layout(const [1, 1, 1, 1, 3]);
    expect(rows, hasLength(2));
    expect(rows.first.end, 4);
    expect(rows.first.height, 250);
    expect(rows.last.start, 4);
    expect(rows.last.height, target);
    expect(rows.last.filled, isFalse);
  });

  test('a panorama wider than the row takes a full-width row of its own', () {
    final rows = layout(const [1, 1, 1, 1, 8, 1]);
    expect(rows.map((r) => (r.start, r.end)), [(0, 4), (4, 5), (5, 6)]);
    expect(rows[1].height, closeTo(125, 1e-9));
    expect(rows[1].filled, isTrue);
  });

  test('invalid aspect ratios are treated as squares', () {
    final rows = layout([double.nan, 0, -2, double.infinity]);
    expect(rows.single.count, 4);
    expect(rows.single.height, target);
  });

  test('rows are contiguous; filled rows exactly span the width', () {
    const sizes = <double>[1216 / 832, 832 / 1216, 1, 1920 / 1088, 1088 / 1920];
    final random = math.Random(7);
    final aspects = [
      for (var i = 0; i < 2000; i++) sizes[random.nextInt(sizes.length)],
    ];
    const spacing = 4.0;
    final rows = layout(aspects, spacing: spacing);
    var expectedStart = 0;
    for (final row in rows) {
      expect(row.start, expectedStart);
      expect(row.count, greaterThan(0));
      expectedStart = row.end;
      final w = rowWidth(aspects, row, spacing);
      if (row.filled) {
        expect(w, closeTo(width, 1e-6));
        // Typical NAI sizes: the closer-of-two rule keeps rows near target.
        expect(row.height, inInclusiveRange(target / 1.3, target * 1.3));
      } else {
        expect(row, same(rows.last));
        expect(w, lessThan(width));
      }
    }
    expect(expectedStart, aspects.length);
  });
}
