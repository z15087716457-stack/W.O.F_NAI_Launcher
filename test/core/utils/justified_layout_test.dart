import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/justified_layout.dart';

void main() {
  // 通用参数：1000px 可用宽、目标行高 200、容忍区间 [160, 360]、间距 12
  const width = 1000.0;
  const target = 200.0;
  const minH = 160.0;
  const maxH = 360.0;
  const spacing = 12.0;

  List<JustifiedRow> layout(
    List<double> aspects, {
    double availableWidth = width,
  }) {
    return computeJustifiedRows(
      aspectRatios: aspects,
      availableWidth: availableWidth,
      targetHeight: target,
      minHeight: minH,
      maxHeight: maxH,
      spacing: spacing,
    );
  }

  /// 顶格行拟合成本：Σ(h − target)²（欠填行不计）
  double fitCost(List<JustifiedRow> rows) {
    var cost = 0.0;
    for (final row in rows) {
      if (row.isUnderfilled) continue;
      final d = row.height - target;
      cost += d * d;
    }
    return cost;
  }

  /// 贪心基线：从行首起取第一个落入区间的断点（取满即断）
  List<JustifiedRow> greedy(List<double> aspects) {
    final n = aspects.length;
    final rows = <JustifiedRow>[];
    final prefix = List<double>.filled(n + 1, 0);
    for (var i = 0; i < n; i++) {
      prefix[i + 1] = prefix[i] + aspects[i];
    }

    double h(int i, int j) =>
        (width - spacing * (j - i)) / (prefix[j + 1] - prefix[i]);

    double clampH(double v) => v.clamp(minH, maxH);

    var i = 0;
    while (i < n) {
      int? pick;
      int? underfillEnd;
      for (var j = i; j < n; j++) {
        final hj = h(i, j);
        if (hj > maxH) {
          underfillEnd = j;
          continue;
        }
        if (hj < minH) break;
        pick = j;
        break;
      }
      if (pick == null) {
        final j = underfillEnd ?? i;
        rows.add(
          JustifiedRow(
            startIndex: i,
            endIndex: j,
            height: clampH(h(i, j)),
            isUnderfilled: true,
          ),
        );
        i = j + 1;
      } else {
        rows.add(
          JustifiedRow(
            startIndex: i,
            endIndex: pick,
            height: clampH(h(i, pick)),
            isUnderfilled: false,
          ),
        );
        i = pick + 1;
      }
    }
    if (rows.isNotEmpty) {
      final last = rows.last;
      rows[rows.length - 1] = JustifiedRow(
        startIndex: last.startIndex,
        endIndex: last.endIndex,
        height: last.height,
        isUnderfilled: true,
      );
    }
    return rows;
  }

  group('computeJustifiedRows 常规混合宽高比', () {
    const aspects = [1.5, 0.7, 2.0, 1.0, 0.8, 1.3, 1.9, 0.6, 1.1, 1.4];

    test('行高全部落在容忍区间', () {
      final rows = layout(aspects);
      expect(rows, isNotEmpty);
      for (final row in rows) {
        expect(row.height, inInclusiveRange(minH, maxH));
      }
    });

    test('行索引连续且完整覆盖全部图片', () {
      final rows = layout(aspects);
      expect(rows.first.startIndex, 0);
      expect(rows.last.endIndex, aspects.length - 1);
      for (var k = 0; k + 1 < rows.length; k++) {
        expect(rows[k + 1].startIndex, rows[k].endIndex + 1);
      }
    });

    test('顶格行宽度正好撑满可用宽', () {
      final rows = layout(aspects);
      for (final row in rows) {
        if (row.isUnderfilled) continue;
        final imageWidths = <double>[
          for (var i = row.startIndex; i <= row.endIndex; i++)
            row.height * aspects[i],
        ];
        final total =
            imageWidths.fold<double>(0, (a, b) => a + b) +
            spacing * (row.endIndex - row.startIndex);
        expect(total, closeTo(width, 1.0));
      }
    });
  });

  group('DP 断行优于贪心', () {
    test('混合宽高比：DP 拟合总成本严格低于贪心', () {
      const aspects = [1.5, 0.7, 2.0, 1.0, 0.8, 1.3, 1.9, 0.6, 1.1, 1.4];
      final dp = layout(aspects);
      final greedyRows = greedy(aspects);
      // 贪心取满后产生偏离 target 的恶劣行（h≈315），DP 行高更贴近 target
      expect(fitCost(dp), lessThan(fitCost(greedyRows)));
    });

    test('均匀宽高比：DP 行高更接近 target', () {
      final aspects = List<double>.filled(10, 1.0);
      final dp = layout(aspects);
      // 贪心逐行取满得到 h≈325（偏离 125），DP 应压到 target 附近
      for (final row in dp) {
        expect((row.height - target).abs(), lessThan(50));
      }
    });
  });

  group('欠填容忍', () {
    test('连续竖图且后续无图可借：欠填行 height=maxHeight 不压成纸条', () {
      final rows = layout([0.6, 0.6, 0.6]);
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.isUnderfilled, isTrue);
      expect(row.height, maxH);
      expect(row.startIndex, 0);
      expect(row.endIndex, 2);
    });

    test('h 跳过区间的跳档输入不抛异常，行高 clamp 进区间', () {
      // 0.5 竖图 h=2000 远超上限，加一张 8.0 全景又直接跌穿下限
      final rows = layout([0.5, 8.0]);
      expect(rows, hasLength(2));
      expect(rows.every((r) => r.isUnderfilled), isTrue);
      expect(rows[0].height, maxH);
      expect(rows[1].height, minH);
    });
  });

  group('末行规则', () {
    test('末行恒 isUnderfilled 且高度 clamp', () {
      // 单张普通横图：自然行高 1000/1.5≈667 超上限 → clamp 到 maxHeight
      final rows = layout([1.5]);
      expect(rows.single.isUnderfilled, isTrue);
      expect(rows.single.height, maxH);

      // 末行自然行高在区间内时保持自然高度（不拉伸）
      final tail = layout([1.5, 0.7, 2.0, 1.0]);
      expect(tail.last.isUnderfilled, isTrue);
      expect(tail.last.height, inInclusiveRange(minH, maxH));
    });
  });

  group('极端边界不抛异常', () {
    test('空列表返回空', () {
      expect(layout(const []), isEmpty);
    });

    test('单张图', () {
      expect(layout([1.0]), hasLength(1));
    });

    test('极端全景 aspect=8', () {
      final rows = layout([8.0]);
      expect(rows.single.height, minH);
      expect(rows.single.isUnderfilled, isTrue);
    });

    test('占位宽高比 1.0（缺元数据场景）正常断行', () {
      final rows = layout(List<double>.filled(6, 1.0));
      expect(rows, isNotEmpty);
      expect(rows.last.endIndex, 5);
    });

    test('非法宽高比（0 / 负值）不抛异常', () {
      final rows = layout([0.0, -1.0, 1.0]);
      expect(rows, isNotEmpty);
      for (final row in rows) {
        expect(row.height.isFinite, isTrue);
      }
    });
  });
}
