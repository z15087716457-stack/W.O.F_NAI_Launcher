import 'dart:math' as math;

/// 混排（面积均衡等高行）布局算法。
///
/// 设计语义（第四轮架构，旧「模板拼块墙」已整体退役）：混排 = 把图串
/// 切成若干等高行，行高以「目标面积 t²」为锚——行 i..j 的基准行高
/// `h0 = t / sqrt(mean_a)`（mean_a = 行内平均宽高比），同方向连排时每图
/// 面积 = h0²×a ≈ t² 严格相等：竖图行自动高（0.7 → h≈1.2t）、横图行
/// 自动矮（1.8 → h≈0.75t），横竖图大小差距由此收敛。**行高与
/// availableWidth 无关**——W 只影响断行位置，拖窗时图大小基本不变
/// （旧架构图大小 = f(窗宽×模板匹配) 无锚点，拖窗大小巨变）。
///
/// 与火车流（justified_layout）的定位差异：火车流顶格优先、行高钳带，
/// 行高随窗宽与断行浮动；混排面积锚定优先，行高由内容方向决定、
/// 窗宽只改变每行图数。两算法独立，参数互不影响。
///
/// 断行规则：
/// - 防呆高带：h0 钳 [t×0.5, t×3.5]。
/// - 候选行内容宽 contentW = h0×Σa + spacing×(j−i)；contentW > W×1.08
///   → 不可行（不许挤压）；∈ [W×0.92, W×1.08] → 顶格行（isJustified，
///   height = h0×W/contentW，微调顶格）；< W×0.92 → 欠填行（height=h0，
///   自然宽左对齐留空）。
/// - 单图行恒可行：h0×a 超宽（全景）时 height=W/a（contain 不裁）、
///   欠填标记——DP 必有路。
/// - 无末行特殊逻辑：不存在 clamp 抬高路径，压扁病根结构性免疫。
///
/// DP 断行（非贪心，O(n²)）：f[0]=0，f[j+1] = min over i（f[i]+cost(i..j)）。
/// 成本三项：
/// 1. 行内比方差罚 = 行内 ln(a) 方差 × [mosaicVarianceWeight]
///    （偏好同宽高比聚一行 → 行内面积更均衡）；
/// 2. 欠填罚 = ((W−contentW)/W)² × [mosaicUnderfillWeight]
///    + 基础罚 [mosaicUnderfillBasePenalty]（偏好顶格但不强求；
///    单图全景 contain 行撑满整宽不罚）；
/// 3. 单图行罚 [mosaicSingleImagePenalty]（防一行一张碎裂）。
///
/// 调参口清单：权重 [mosaicVarianceWeight] / [mosaicUnderfillWeight]
/// （兼为同名可选参数的默认值，验收可调）；容忍带 [mosaicJustifyTolerance]、
/// 基础罚 [mosaicUnderfillBasePenalty]、单图罚 [mosaicSingleImagePenalty]、
/// 高带系数 [mosaicMinHeightFactor] / [mosaicMaxHeightFactor] 为顶层常量。
///
/// 不变量：所有行 imageCount 之和 == 图数、索引连续不重叠；空列表返回空；
/// 非法宽高比（0/负/NaN）占位 1.0 不抛异常。

/// 行内比方差罚权重（调大 → 更偏好同宽高比聚行）
const double mosaicVarianceWeight = 2.0;

/// 欠填罚权重（调大 → 更偏好顶格行）
const double mosaicUnderfillWeight = 1.5;

/// 欠填固定基础罚：任何欠填行都付，偏好顶格但不强求
const double mosaicUnderfillBasePenalty = 0.05;

/// 单图行罚：防一行一张碎裂
const double mosaicSingleImagePenalty = 0.3;

/// 顶格容忍带：contentW 落 [W×(1−tol), W×(1+tol)] 内允许微调顶格
const double mosaicJustifyTolerance = 0.08;

/// 防呆高带系数：基准行高 h0 钳 [t×min, t×max]
const double mosaicMinHeightFactor = 0.5;
const double mosaicMaxHeightFactor = 3.5;

/// 混排等高行（面积均衡 DP 断行结果，索引为绝对索引）
class MosaicRow {
  /// 起始图索引（含）
  final int startIndex;

  /// 结束图索引（含）
  final int endIndex;

  /// 渲染行高：顶格行 = h0×W/contentW（微调顶格后的真实行高）；
  /// 欠填行 = h0；单图全景 contain 行 = W/a
  final double height;

  /// true=顶格行（Expanded flex 分宽撑满整行）；
  /// false=欠填行（自然宽左对齐留空；含单图全景 contain 行）
  final bool isJustified;

  const MosaicRow({
    required this.startIndex,
    required this.endIndex,
    required this.height,
    required this.isJustified,
  });
}

/// 混排断行：把图串切成面积均衡的等高行序列。
///
/// [targetHeight] 目标边长 t（= 逻辑列宽 columnWidth），语义 = 目标面积
/// t² 的边长；[availableWidth] 为内容区可用宽（已扣 padding）。
List<MosaicRow> computeMosaicRows({
  required List<double> aspectRatios,
  required double availableWidth,
  required double targetHeight,
  required double spacing,

  /// 行内比方差罚权重覆盖；null = [mosaicVarianceWeight]
  double? varianceWeight,

  /// 欠填罚权重覆盖；null = [mosaicUnderfillWeight]
  double? underfillWeight,
}) {
  final n = aspectRatios.length;
  if (n == 0) return const [];
  final varWeight = varianceWeight ?? mosaicVarianceWeight;
  final fillWeight = underfillWeight ?? mosaicUnderfillWeight;

  final t = targetHeight;
  final minH = t * mosaicMinHeightFactor;
  final maxH = t * mosaicMaxHeightFactor;
  final justifyMin = availableWidth * (1 - mosaicJustifyTolerance);
  final justifyMax = availableWidth * (1 + mosaicJustifyTolerance);

  // 非法宽高比占位为 1（与 V1 占位策略一致），保证不抛异常
  final aspects = List<double>.generate(n, (i) {
    final a = aspectRatios[i];
    return (a.isFinite && a > 0) ? a : 1.0;
  });
  // 前缀和：Σa / Σln(a) / Σln(a)²（断行与行内方差用）
  final sumA = List<double>.filled(n + 1, 0);
  final sumLog = List<double>.filled(n + 1, 0);
  final sumLog2 = List<double>.filled(n + 1, 0);
  for (var i = 0; i < n; i++) {
    final logA = math.log(aspects[i]);
    sumA[i + 1] = sumA[i] + aspects[i];
    sumLog[i + 1] = sumLog[i] + logA;
    sumLog2[i + 1] = sumLog2[i] + logA * logA;
  }

  /// 候选行 (i..j) 评估：返回 (行高, 是否顶格, 成本)；不可行返回 null
  (double, bool, double)? evaluateRow(int i, int j) {
    final count = j - i + 1;
    final rowSumA = sumA[j + 1] - sumA[i];
    final meanA = rowSumA / count;
    final h0 = (t / math.sqrt(meanA)).clamp(minH, maxH);
    final contentW = h0 * rowSumA + spacing * (count - 1);

    final bool isJustified;
    final double height;
    final bool isContainSingle;
    if (contentW > justifyMax) {
      if (count > 1) return null; // 多图行不许挤压，不可行
      // 单图全景 contain：height=W/a 不裁，欠填标记（DP 必有路的兜底）
      isJustified = false;
      height = availableWidth / aspects[i];
      isContainSingle = true;
    } else if (contentW >= justifyMin) {
      // 顶格行：微调顶格后的真实行高
      isJustified = true;
      height = h0 * availableWidth / contentW;
      isContainSingle = false;
    } else {
      // 欠填行：height=h0 不被抬升，自然宽左对齐
      isJustified = false;
      height = h0;
      isContainSingle = false;
    }

    // 成本 1：行内 ln(a) 方差罚（E[x²]−E[x]²，浮点噪声钳 0）
    final rowSumLog = sumLog[j + 1] - sumLog[i];
    final rowSumLog2 = sumLog2[j + 1] - sumLog2[i];
    final meanLog = rowSumLog / count;
    final variance = math.max(rowSumLog2 / count - meanLog * meanLog, 0.0);
    var cost = variance * varWeight;
    // 成本 2：欠填罚（contain 单图行撑满整宽不罚）
    if (!isJustified && !isContainSingle) {
      final gap = (availableWidth - contentW) / availableWidth;
      cost += gap * gap * fillWeight + mosaicUnderfillBasePenalty;
    }
    // 成本 3：单图行罚
    if (count == 1) cost += mosaicSingleImagePenalty;
    return (height, isJustified, cost);
  }

  // DP 断行：f[j+1] = 前 j+1 张最小总成本，prev[j+1] 记最优路径
  // 最后一段的起点（回溯用）
  final f = List<double>.filled(n + 1, double.infinity);
  final prev = List<int>.filled(n + 1, -1);
  f[0] = 0;
  for (var i = 0; i < n; i++) {
    if (f[i] == double.infinity) continue;
    for (var j = i; j < n; j++) {
      final candidate = evaluateRow(i, j);
      if (candidate == null) continue;
      final total = f[i] + candidate.$3;
      if (total < f[j + 1]) {
        f[j + 1] = total;
        prev[j + 1] = i;
      }
    }
  }

  // 从 n 反向回溯（单图 contain 恒可行，prev 必有路；
  // 防御：缺失时退化为单图行，不死循环不丢图）
  final rows = <MosaicRow>[];
  var end = n;
  while (end > 0) {
    final start = prev[end] >= 0 && prev[end] < end ? prev[end] : end - 1;
    final candidate = evaluateRow(start, end - 1);
    rows.insert(
      0,
      MosaicRow(
        startIndex: start,
        endIndex: end - 1,
        height: candidate?.$1 ?? t,
        isJustified: candidate?.$2 ?? false,
      ),
    );
    end = start;
  }
  return rows;
}
