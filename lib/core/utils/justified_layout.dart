import 'dart:math' as math;

/// 火车流（justified 等高行）断行结果。
class JustifiedRow {
  /// 起始图索引（含）
  final int startIndex;

  /// 结束图索引（含）
  final int endIndex;

  /// 行高（px）
  final double height;

  /// true=欠填行：图按 height×aspect 取自然宽、左对齐、右侧留空，不顶格拉伸
  final bool isUnderfilled;

  const JustifiedRow({
    required this.startIndex,
    required this.endIndex,
    required this.height,
    required this.isUnderfilled,
  });
}

/// 火车流断行：把一串图切成若干等高行。
///
/// 候选行 i..j 的自然行高
/// `h(i..j) = (availableWidth − spacing×(j−i)) / Σaspect[i..j]`，
/// j 增大时 h 单调递减。h 落在 [minHeight, maxHeight] 内的行为「顶格行」，
/// 渲染时图按行高×aspect 正好撑满整行。
///
/// 断行用 DP（非贪心）：f[i] = 前 i 张的最小总成本，顶格行成本
/// `(h − targetHeight)²`（行内仅 1 张图时叠轻度罚分），O(n²)。
///
/// 欠填容忍：从 i 出发没有任何 j 使 h 落区间（典型 = 连续竖图，h 全高于
/// maxHeight）时允许欠填行——取 h 最接近 maxHeight 的 j，行高 clamp 进
/// 区间、isUnderfilled=true；成本是显著大于任何纯顶格路径的大罚分，
/// 保证 DP 只在无路可走时才选欠填。空列表返回空，极端输入只 clamp 不抛异常。
///
/// 末行规则：末行恒按欠填处理（左对齐、高度 clamp 自然行高、不顶格拉伸）。
/// 防压扁拆分：末行自然 h < minHeight 且图数 ≥2 时，从末行尾部逐张吐出
/// 图片组成新末行——每吐一张旧末行 Σaspect 减小、h 升高，直到旧末行
/// h ≥ minHeight 或仅剩 1 张；旧末行按常规行定 height 与 isUnderfilled
/// （h 落区间=顶格，否则欠填 clamp），新末行恒欠填 height=clamp(自然h)；
/// 新末行若仍 h < minHeight 且图数 ≥2 则递归同样处理。若不拆分，欠填行
/// height 被 clamp 抬高到 minHeight 时行内图总宽会超出行宽，渲染层只能
/// 缩宽防溢出，竖图被横向压扁。总图数守恒、索引连续。
List<JustifiedRow> computeJustifiedRows({
  required List<double> aspectRatios,
  required double availableWidth,
  required double targetHeight,
  required double minHeight,
  required double maxHeight,
  required double spacing,
}) {
  final n = aspectRatios.length;
  if (n == 0) return const [];

  // 非法宽高比占位为 1（与渲染层占位策略一致），保证不抛异常
  final aspects = List<double>.generate(n, (i) {
    final a = aspectRatios[i];
    return (a.isFinite && a > 0) ? a : 1.0;
  });

  // 宽高比前缀和：Σaspect[i..j] = prefix[j+1] − prefix[i]
  final prefix = List<double>.filled(n + 1, 0);
  for (var i = 0; i < n; i++) {
    prefix[i + 1] = prefix[i] + aspects[i];
  }

  double naturalHeight(int i, int j) =>
      (availableWidth - spacing * (j - i)) / (prefix[j + 1] - prefix[i]);

  double clampHeight(double h) => h.clamp(minHeight, maxHeight);

  // 单行顶格成本上限 × 行数上界 + 1 = 欠填罚分：任何纯顶格路径的总成本
  // 都低于它，欠填只在无路可走时被选中
  final maxFitDeviation = math.max(
    (maxHeight - targetHeight).abs(),
    (minHeight - targetHeight).abs(),
  );
  final singleImagePenalty = (0.1 * targetHeight) * (0.1 * targetHeight);
  final underfillPenalty =
      n * (maxFitDeviation * maxFitDeviation + singleImagePenalty) + 1;

  final cost = List<double>.filled(n + 1, double.infinity);
  final choiceEnd = List<int>.filled(n, -1);
  final choiceUnderfilled = List<bool>.filled(n, false);
  cost[0] = 0;

  for (var i = 0; i < n; i++) {
    if (cost[i] == double.infinity) continue;
    var foundFit = false;
    int? underfillEnd;
    for (var j = i; j < n; j++) {
      final h = naturalHeight(i, j);
      if (h > maxHeight) {
        // h 单调递减：最后一个仍高于上限的 j 离上限最近（欠填断点候选）
        underfillEnd = j;
        continue;
      }
      if (h < minHeight) break; // 更长的 j 只会更矮
      foundFit = true;
      final deviation = h - targetHeight;
      final rowCost = deviation * deviation + (j == i ? singleImagePenalty : 0);
      final total = cost[i] + rowCost;
      if (total < cost[j + 1]) {
        cost[j + 1] = total;
        choiceEnd[i] = j;
        choiceUnderfilled[i] = false;
      }
    }
    if (!foundFit) {
      // 欠填兜底：无落区间的断点；j 取 h 最接近 maxHeight 者，
      // 全低于下限时退化为 j = i（如单张全景）
      final j = underfillEnd ?? i;
      final total = cost[i] + underfillPenalty;
      if (total < cost[j + 1]) {
        cost[j + 1] = total;
        choiceEnd[i] = j;
        choiceUnderfilled[i] = true;
      }
    }
  }

  final rows = <JustifiedRow>[];
  var i = 0;
  while (i < n) {
    final j = choiceEnd[i];
    // 防御：DP 必有路（欠填兜底），异常时单片欠填也不会死循环
    final end = j >= i ? j : i;
    rows.add(
      JustifiedRow(
        startIndex: i,
        endIndex: end,
        height: clampHeight(naturalHeight(i, end)),
        isUnderfilled: j >= i && choiceUnderfilled[i],
      ),
    );
    i = end + 1;
  }

  // 末行处理：恒欠填（左对齐、高度 clamp 自然行高、不顶格拉伸）+
  // 防压扁拆分（自然 h 低于下限且图数 ≥2 时尾部逐张吐出新末行，可递归）
  while (rows.isNotEmpty) {
    final last = rows.last;
    // 逐张吐出：每吐一张旧末行 Σaspect 减小、h 升高，
    // 直到旧末行 h ≥ minHeight 或仅剩 1 张
    var headEnd = last.endIndex;
    while (headEnd > last.startIndex &&
        naturalHeight(last.startIndex, headEnd) < minHeight) {
      headEnd--;
    }
    if (headEnd == last.endIndex) {
      // 无需拆分：末行恒欠填 clamp
      rows[rows.length - 1] = JustifiedRow(
        startIndex: last.startIndex,
        endIndex: last.endIndex,
        height: clampHeight(naturalHeight(last.startIndex, last.endIndex)),
        isUnderfilled: true,
      );
      break;
    }
    // 旧末行按常规行处理：h 落区间 = 顶格，否则欠填 clamp
    final headNatural = naturalHeight(last.startIndex, headEnd);
    final headFit = headNatural >= minHeight && headNatural <= maxHeight;
    rows[rows.length - 1] = JustifiedRow(
      startIndex: last.startIndex,
      endIndex: headEnd,
      height: headFit ? headNatural : clampHeight(headNatural),
      isUnderfilled: !headFit,
    );
    // 吐出段成为新末行，下轮循环同样检查拆分
    rows.add(
      JustifiedRow(
        startIndex: headEnd + 1,
        endIndex: last.endIndex,
        height: clampHeight(naturalHeight(headEnd + 1, last.endIndex)),
        isUnderfilled: true,
      ),
    );
  }
  return rows;
}
