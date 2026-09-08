import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/mosaic_layout.dart';

void main() {
  // 通用参数：1000px 可用宽、目标边长 200（目标面积 t²）、间距 12
  const width = 1000.0;
  const target = 200.0;
  const spacing = 12.0;

  List<MosaicRow> layout(
    List<double> aspects, {
    double w = width,
    double t = target,
  }) {
    return computeMosaicRows(
      aspectRatios: aspects,
      availableWidth: w,
      targetHeight: t,
      spacing: spacing,
    );
  }

  /// 基准行高 t/sqrt(mean_a)（含防呆钳带 [0.5t, 3.5t]）
  double h0Of(List<double> aspects, int start, int end, double t) {
    var sum = 0.0;
    for (var k = start; k <= end; k++) {
      sum += aspects[k];
    }
    final raw = t / math.sqrt(sum / (end - start + 1));
    return raw.clamp(t * mosaicMinHeightFactor, t * mosaicMaxHeightFactor);
  }

  /// 行渲染内容宽（height×Σa + spacing×(k−1)）
  double rowContentWidth(MosaicRow row, List<double> aspects) {
    var sumA = 0.0;
    for (var k = row.startIndex; k <= row.endIndex; k++) {
      sumA += aspects[k];
    }
    return row.height * sumA + spacing * (row.endIndex - row.startIndex);
  }

  /// 行内图片是否全部同一宽高比（方差罚的同质性断言用）
  bool isHomogeneous(MosaicRow row, List<double> aspects) {
    final first = aspects[row.startIndex];
    for (var k = row.startIndex + 1; k <= row.endIndex; k++) {
      if (aspects[k] != first) return false;
    }
    return true;
  }

  group('大小锚定（核心回归：图大小与窗宽无关）', () {
    // 竖 0.7 / 方 1.0 / 横 1.8 各 6 张，t=260
    final seq = [
      ...List<double>.filled(6, 0.7),
      ...List<double>.filled(6, 1.0),
      ...List<double>.filled(6, 1.8),
    ];

    test('纯竖图行行高跨窗宽偏差 ≤15%，且 ≈ t/sqrt(0.7)', () {
      final rowsNarrow = layout(seq, w: 1000, t: 260);
      final rowsWide = layout(seq, w: 1400, t: 260);
      // 纯竖图行 = 行内索引全落竖图段 [0, 5]
      final hNarrow = rowsNarrow.firstWhere((r) => r.endIndex <= 5).height;
      final hWide = rowsWide.firstWhere((r) => r.endIndex <= 5).height;
      final expected = 260 / math.sqrt(0.7); // ≈310.7

      // 锚定效应：两窗宽间行高几乎一致（实测偏差 ≈2.5%）
      final drift = (hWide - hNarrow).abs() / hNarrow;
      // ignore: avoid_print
      print(
        'mosaic stability: w=1000 h=$hNarrow, w=1400 h=$hWide, '
        'drift=${(drift * 100).toStringAsFixed(2)}%',
      );
      expect(drift, lessThanOrEqualTo(0.15));
      expect(hNarrow, closeTo(expected, expected * 0.05));
      expect(hWide, closeTo(expected, expected * 0.05));
    });

    test('竖图行自动高、横图行自动矮（面积均衡推论）', () {
      final rows = layout(seq, w: 1000, t: 260);
      final hPortrait = rows.firstWhere((r) => r.endIndex <= 5).height;
      final hSquare = rows
          .firstWhere((r) => r.startIndex >= 6 && r.endIndex <= 11)
          .height;
      final hLandscape = rows.firstWhere((r) => r.startIndex >= 12).height;
      // 0.7→h≈1.2t、1.8→h≈0.75t：竖图行显著高于横图行
      expect(hPortrait, greaterThan(hSquare));
      expect(hSquare, greaterThan(hLandscape));
      expect(hPortrait, closeTo(260 / math.sqrt(0.7), 260 * 0.05));
      expect(hLandscape, closeTo(260 / math.sqrt(1.8), 260 * 0.05));
    });
  });

  group('面积均衡', () {
    test('纯竖连排行内每图面积 ≈ t²（±5%）', () {
      // 5 张 0.7 竖图：欠填行 height=h0，面积 = h0²×a = t² 严格相等
      final rows = layout(List<double>.filled(5, 0.7));
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.isJustified, isFalse); // 欠填行 height=h0
      final area = row.height * row.height * 0.7;
      expect(area, closeTo(target * target, target * target * 0.05));
    });

    test('方差罚生效：强对比序列断行不混行', () {
      // [0.7×6, 1.8×6]：纯竖行可行（顶格成本 0），混入横图的行内方差
      // 罚远高于省下的欠填罚 → 断行保持同宽高比聚行
      final aspects = [
        ...List<double>.filled(6, 0.7),
        ...List<double>.filled(6, 1.8),
      ];
      final rows = layout(aspects);
      expect(rows, isNotEmpty);
      for (final row in rows) {
        expect(
          isHomogeneous(row, aspects),
          isTrue,
          reason: '行 ${row.startIndex}-${row.endIndex} 混入了不同宽高比',
        );
      }
    });
  });

  group('可行性与无挤压', () {
    test('任意行渲染内容宽 ≤ W×1.08+1（无挤压 → 无压扁）', () {
      var seed = 42;
      double rnd() {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        return seed / 0x7fffffff;
      }

      final aspects = [for (var k = 0; k < 50; k++) 0.4 + rnd() * 2.2];
      for (final row in layout(aspects)) {
        expect(
          rowContentWidth(row, aspects),
          lessThanOrEqualTo(width * 1.08 + 1),
          reason: '行 ${row.startIndex}-${row.endIndex} 超宽',
        );
      }
    });

    test('欠填行 height = h0 不被抬升', () {
      var seed = 7;
      double rnd() {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        return seed / 0x7fffffff;
      }

      final aspects = [for (var k = 0; k < 30; k++) 0.4 + rnd() * 2.2];
      for (final row in layout(aspects)) {
        if (row.isJustified) continue;
        // 单图全景 contain 行（height=W/a）另行断言，跳过
        final h0 = h0Of(aspects, row.startIndex, row.endIndex, target);
        if (row.height < h0 - 0.01) continue; // contain 行 height=W/a < h0
        expect(row.height, closeTo(h0, 0.01));
      }
    });

    test('顶格行 height = h0×W/contentW（微调顶格）', () {
      // 5 张方图：contentW = 200×5+48 = 1048 ∈ [920, 1080] → 顶格
      final rows = layout(List<double>.filled(5, 1.0));
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.isJustified, isTrue);
      const h0 = 200.0;
      const contentW = h0 * 5 + spacing * 4;
      expect(row.height, closeTo(h0 * width / contentW, 1.0));
    });
  });

  group('单图行与极端边界', () {
    test('单图全景（a=16）：height=W/a contain 不裁、欠填标记', () {
      // h0 钳下限 0.5t=100，h0×a=1600 > W×1.08 → contain
      final rows = layout([16.0]);
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.isJustified, isFalse);
      expect(row.height, closeTo(width / 16, 0.01));
    });

    test('空列表返回空', () {
      expect(layout(const []), isEmpty);
    });

    test('单张图不抛异常', () {
      final rows = layout([1.0]);
      expect(rows, hasLength(1));
      expect(rows.single.startIndex, 0);
      expect(rows.single.endIndex, 0);
    });

    test('非法宽高比（0 / 负 / NaN）占位 1.0 不抛异常', () {
      final rows = layout([0.0, -1.0, double.nan, 1.0]);
      final total = rows.fold<int>(
        0,
        (sum, r) => sum + r.endIndex - r.startIndex + 1,
      );
      expect(total, 4);
      for (final row in rows) {
        expect(row.height.isFinite, isTrue);
      }
    });

    test('极端全景与极端竖图混合不抛异常且守恒', () {
      final rows = layout([8.0, 0.05, 1.5]);
      expect(
        rows.fold<int>(0, (sum, r) => sum + r.endIndex - r.startIndex + 1),
        3,
      );
      for (final row in rows) {
        expect(row.height.isFinite, isTrue);
        expect(row.height, greaterThan(0));
      }
    });
  });

  group('图数守恒与索引连续', () {
    List<double> randomAspects(int seed, int count) {
      var s = seed;
      double rnd() {
        s = (s * 1103515245 + 12345) & 0x7fffffff;
        return s / 0x7fffffff;
      }

      return [for (var k = 0; k < count; k++) 0.4 + rnd() * 2.2];
    }

    test('多组固定种子随机序列', () {
      for (final seed in [1, 42, 777, 20240908]) {
        for (final count in [1, 2, 3, 5, 17, 50]) {
          final aspects = randomAspects(seed, count);
          final rows = layout(aspects);
          // 图数守恒
          final total = rows.fold<int>(
            0,
            (sum, r) => sum + r.endIndex - r.startIndex + 1,
          );
          expect(total, aspects.length, reason: 'seed=$seed count=$count');
          if (rows.isEmpty) continue;
          // 索引连续不重叠
          expect(rows.first.startIndex, 0);
          expect(rows.last.endIndex, aspects.length - 1);
          for (var k = 1; k < rows.length; k++) {
            expect(rows[k].startIndex, rows[k - 1].endIndex + 1);
          }
        }
      }
    });
  });
}
