/// 火车流（等高行）布局：Google 相册 / Flickr 式的贪心断行。
///
/// 每行按目标行高 t 从左到右放图。放下一张会超出可用宽时，比较两种收尾：
/// 把它放进本行（行高压低到刚好填满），或本行到此为止（行高抬高到刚好
/// 填满），按比例取更接近 t 的一种。满行精确填满可用宽，图片保持原始
/// 宽高比，不裁剪也不放大到别的行高档位。
///
/// 每段（每个日期分组）的最后一行不足一行时保持 t、靠左排列，不会被拉满；
/// 只差一点（拉满所需行高 ≤ t × [justifiedLastRowMaxStretch]）时才顺手拉满，
/// 避免右侧只剩一条窄缝。比整行还宽的单张全景图独占一行、按可用宽缩小。
///
/// 复杂度 O(n)，整库四五万张一次排完。
library;

/// 末行允许拉满的最大放大比例：再大就保持目标行高、靠左排列。
const double justifiedLastRowMaxStretch = 1.15;

/// 一行的断行结果。
class JustifiedRow {
  const JustifiedRow({
    required this.start,
    required this.end,
    required this.height,
    required this.filled,
  });

  /// 起始图索引（含）
  final int start;

  /// 结束图索引（不含）
  final int end;

  /// 行高；行内每张图宽 = 行高 × 宽高比
  final double height;

  /// 是否精确填满可用宽（满行，或差一点被拉满的末行）
  final bool filled;

  int get count => end - start;
}

/// 把一串宽高比切成等高行。
///
/// [aspectRatios] 为宽/高；非法值（0、负数、NaN、无穷）按 1 处理。
/// [availableWidth] 为内容区可用宽，[targetHeight] 为目标行高，
/// [spacing] 为图间距。
List<JustifiedRow> computeJustifiedRows({
  required List<double> aspectRatios,
  required double availableWidth,
  required double targetHeight,
  required double spacing,
  double lastRowMaxStretch = justifiedLastRowMaxStretch,
}) {
  final n = aspectRatios.length;
  if (n == 0 || availableWidth <= 0 || targetHeight <= 0) return const [];
  final width = availableWidth;
  final target = targetHeight;
  double aspectAt(int i) {
    final a = aspectRatios[i];
    return a.isFinite && a > 0 ? a : 1.0;
  }

  /// count 张、宽高比之和为 sum 时刚好填满可用宽的行高
  double fillHeight(int count, double sum) =>
      ((width - spacing * (count - 1)) / sum).clamp(1.0, double.infinity);

  final rows = <JustifiedRow>[];
  var start = 0;
  var sum = 0.0;
  for (var i = 0; i < n; i++) {
    final a = aspectAt(i);
    final count = i - start + 1;
    final next = sum + a;
    if (next * target + spacing * (count - 1) < width) {
      sum = next;
      continue;
    }
    // 放进这张就满了：比较「放进本行」和「本行到此为止」谁更接近目标行高
    final withIt = fillHeight(count, next);
    if (count > 1) {
      final without = fillHeight(count - 1, sum);
      if (without / target < target / withIt) {
        rows.add(
          JustifiedRow(start: start, end: i, height: without, filled: true),
        );
        start = i;
        sum = a;
        // 新行只有这一张：本身就比整行宽（全景图）时立即独占一行
        if (a * target >= width) {
          rows.add(
            JustifiedRow(
              start: i,
              end: i + 1,
              height: fillHeight(1, a),
              filled: true,
            ),
          );
          start = i + 1;
          sum = 0;
        }
        continue;
      }
    }
    rows.add(
      JustifiedRow(start: start, end: i + 1, height: withIt, filled: true),
    );
    start = i + 1;
    sum = 0;
  }

  if (start < n) {
    final count = n - start;
    final stretched = fillHeight(count, sum);
    rows.add(
      stretched <= target * lastRowMaxStretch
          ? JustifiedRow(start: start, end: n, height: stretched, filled: true)
          : JustifiedRow(start: start, end: n, height: target, filled: false),
    );
  }
  return rows;
}
