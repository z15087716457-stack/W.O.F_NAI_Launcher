import 'dart:math' as math;

/// 火车流（justified 等高行）布局算法。
///
/// V3 引擎：面积均衡 DP 断行（V2 混排引擎迁移）+ 行高重锚定三级填充。
/// V1 DP 引擎（顶格优先 + 行高钳带 [0.8t, 1.8t]）与 V3a 的
/// 「exact 行 h=W/Σa 精确填满」均已退役——后者把行高绑回窗宽，
/// 双横图行被顶到 ~2t、多图行压成纸条；本引擎恢复 V2 验收性质的
/// 面积锚：**行高 h0 = t/√(行内平均宽高比)，钳 [t×0.5, t×3.5]，
/// 与窗宽解耦（拖窗图大小稳定），填满靠 cover 微裁吸收，不靠行高缩放**。
///
/// 断行 DP（非贪心，O(n²)）：f[0]=0，f[j+1] = min over i（f[i]+cost(i..j)），
/// 成本结构沿用 V2：
/// 1. 行内 ln(a) 方差 × [justifiedVarianceWeight]（软偏好：同宽高比聚行
///    → 行内面积更均衡）；另有硬约束：行内 max ln(a) − min ln(a) >
///    [justifiedAspectSpreadCap]（默认 1.2 ≈ 2.7 倍）的行不可行
///    （同高下行内图面积差 = e^落差，防混行自由度带回极端大小病）；
/// 2. 填充偏离罚（目标 = 锚定内容宽 h0·Σa 贴近 W；按方向不对称：
///    缩小侧 [justifiedDownscaleWeight] = 2×放大侧 [justifiedUpscaleWeight]，
///    「同幅度偏差缩小恒贵于放大」「cap 内放大恒优于欠填」结构成立——
///    推导见两常数上方注释）：
///    justify 行按方向吃 (1±r)² 微调罚；crop 行 (1−r)²×w_down；
///    upscale 行 (r−1)²×w_up（超线性：小空洞放大优于欠填留空，
///    大放大率罚分陡增 → DP 自动偏好「多拉一张细分 + 小放大」
///    而非「少图硬放大」）；
///    欠填行 ((W−contentW)/W)²×[justifiedUnderfillWeight]
///    + 基础罚 [justifiedUnderfillBasePenalty]；
/// 3. 单图行罚 [justifiedSingleImagePenalty]（防一行一张碎裂）。
///
/// cap 维持 1.4 的预期管理：静已知案例 C 差 7% 撞 cap、接受
/// 「混行+放大」兜底；复验若想让 3 横行硬放大，可抬 1.45~1.5——
/// 届时 [justifiedUpscaleWeight] 的临界推导（注释在其上方）需同步
/// 重推导（w_up 临界随 cap 上移而下降）。
///
/// 每行分派（r = 图片可用宽 Wa / (h0·Σa)，Wa = W − spacing×(k−1)）：
/// - r ∈ [1−tol, 1+tol]（tol = [justifiedJustifyTolerance] = 0.08）
///   → justify 行：h = Wa/Σa，零裁剪精确填满（渲染 Expanded 分格，
///   格宽 = Wa×a_i/Σa 与图比精确一致）；
/// - r ∈ (1+tol, [justifiedUpscaleCap]]（默认 1.4）→ upscale 行（新增）：
///   h = r·h0 整行等比放大、自然宽 contain、零裁剪精确填满
///   （r·h0 ≡ Wa/Σa，与 justify 行同构）；放大不丢内容，r>1 侧的原
///   crop 层由此退役。若 r·h0 超高带上限 3.5t，放大率钳到 3.5t/h0，
///   钳后保持带顶高度左对齐（= 带顶欠填，不裁）；
/// - r ∈ [1−cap, 1−tol)（cap = [justifiedCropCap] = 0.12，仅 r<1 过满侧）
///   → crop 行：行高钉 h0，Expanded 分格 + 卡片 BoxFit.cover 微裁填满
///   （锚点居中；隐含裁量 = 1−r ≤ cap）；
/// - 其余 → 欠填行：h0 左对齐不裁（V2 现状，竖图行高自动 ~1.2t）。
///   无挤压守卫：欠填自然内容宽 h0·Σa+spacing×(k−1) > W×(1+tol) 的
///   多图行不可行——多图横排纸条行结构性不可能；
/// - 单图行独立分派（hFull = Wa/a = 单图填满整行宽所需高度，≡ r·h0；
///   静拍板原则：放大优先于缩小、填满优先于留空、不丢内容优先）：
///   hFull ≤ 3.5t → 满宽零裁剪（exact，height = hFull，fillCost = 0
///   与旧 contain 一致）——收编旧 contain 分支（hFull < h0 的超宽全景，
///   渲染同为满宽条带）与中宽长图（h0 < hFull，原 r≫cap 只能欠填、
///   右侧留大空洞）；hFull > 3.5t 且 3.5t/hFull ≥ 1−cap → 满宽 cover
///   裁上下（crop，height 钉 3.5t，裁量 ≤ cap 与 crop 行同预算、同
///   双倍缩小罚——单图中横图放大到满宽只超高一点时宁裁不留空）；
///   其余（方图/竖图落单行，满宽裁量超预算）维持欠填 h0 左对齐。
///
/// 调参口清单：权重 [justifiedVarianceWeight] / [justifiedUnderfillWeight]
/// / 裁量上限 [justifiedCropCap]（兼作单图满宽 cover 的裁量预算）
/// / 放大上限 [justifiedUpscaleCap]
/// （兼为同名可选参数的默认值）；[justifiedUpscaleWeight] /
/// [justifiedDownscaleWeight] / [justifiedUnderfillBasePenalty] /
/// [justifiedSingleImagePenalty] / 落差硬上限 [justifiedAspectSpreadCap] /
/// 高带系数 [justifiedMinHeightFactor] / [justifiedMaxHeightFactor] /
/// 顶格容差 [justifiedJustifyTolerance] 为顶层常量。
///
/// 不变量：所有行 imageCount 之和 == 图数、索引连续不重叠；空列表返回空；
/// 非法宽高比（0/负/NaN）占位 1.0 不抛异常；欠填行渲染宽 ≤ W×1.08
/// （渲染层无 shrink 压扁）；单图满宽行高 = Wa/a 可低于高带下限 0.5t
/// （超宽全景条带，旧 contain 同此）。无末行特殊逻辑。

/// 行内比方差罚权重（软偏好：同宽高比聚行 → 行内面积更均衡）。
/// 2.0 → 1.0：混行的阻拦职责移交硬上限 [justifiedAspectSpreadCap]，
/// 方差罚降为软偏好（空洞填 charge 不再被它压过）
const double justifiedVarianceWeight = 1.0;

/// 填充偏离罚权重（欠填行距平方罚 / 裁剪行裁量平方罚共用）
const double justifiedUnderfillWeight = 1.5;

/// 欠填固定基础罚：任何欠填行都付，偏好填满但不强求
const double justifiedUnderfillBasePenalty = 0.05;

/// 单图行罚：防一行一张碎裂
const double justifiedSingleImagePenalty = 0.3;

/// 单格裁量上限：r 低于 1 超过它则退回欠填不裁剪
/// （crop 带 = [1−cap, 1−tol)，仅 r<1 过满侧）
const double justifiedCropCap = 0.12;

/// 放大上限：r 超过它则不再放大填满（退回欠填）。
/// 1.25 → 1.4（静拍板：稀疏区 cap 内硬放大填满）。
/// 放大率 cap 与放大罚超线性共同约束：cap 内硬放大优于留空，
/// 超 cap 说明图太稀疏，左对齐留空更自然
const double justifiedUpscaleCap = 1.4;

/// 放大罚权重（(r−1)² 的系数）：1.5 → 0.9。
/// 「cap 内放大恒优于欠填」的结构性临界推导：需
/// (r−1)²·w_up < gap²·w_fill + 基础罚，其中 gap≈(Wa/W)(1−1/r)；
/// 取最不利端 r=1.4、Wa/W≈0.97（w_fill=1.5、基础罚 0.05）：
/// w_up < 0.05/0.16 + 1.5×0.97²/1.96 ≈ 1.03 → 取 0.9 留 ~13% 裕度，
/// cap 内（含 1.4）放大结构性恒优于欠填重新成立
const double justifiedUpscaleWeight = 0.9;

/// 缩小罚权重（(1−r)² 的系数，r<1 侧：crop 行与 justify 带内微调缩小行）。
/// = 2×[justifiedUpscaleWeight]——填充罚分不对称化（静的设计法则：
/// 「放大是优先策略，画幅大了页面滚乱要多滚一点也可以接受，但是小了
/// 就很麻烦」，与 V1「竖图行宁可欠填也不压薄」一脉相承）。
/// 结构性不等式（平方项天然区分带内小幅与带外大幅，带内 r≥0.92 时
/// 该项 ≤ (0.08)²×1.8 ≈ 0.0115，常用 justify 行成本不爆炸）：
/// 1. 同幅度偏差缩小恒贵于放大（w_down = 2×w_up，构造保证）；
/// 2. cap 内放大恒优于欠填（见 [justifiedUpscaleWeight] 推导，不动）；
/// 3. 致密重排（多拉图压小行高，r<1 侧）罚分双倍于放大 → DP 偏好
///    放大本行；缩小（crop）永远是最后手段。
const double justifiedDownscaleWeight = 1.8;

/// 行内宽高比落差硬上限：max ln(a) − min ln(a) 超过它的行不可行。
/// 同高下行内图面积差 = e^落差：1.2 ≈ 2.7 倍——混行自由度放开后
/// （方差罚下调）由它挡住「同行极端大小」病
const double justifiedAspectSpreadCap = 1.2;

/// 顶格容差：r ∈ [1±tol] 判定 justify 行；兼作欠填溢出守卫
/// （欠填自然内容宽 > W×(1+tol) 的多图行不可行）
const double justifiedJustifyTolerance = 0.08;

/// 防呆高带系数：行高锚 h0 钳 [t×min, t×max]
const double justifiedMinHeightFactor = 0.5;
const double justifiedMaxHeightFactor = 3.5;

/// 行填充模式
enum JustifiedFill {
  /// justify 行：h = Wa/Σa，零裁剪精确填满；
  /// 单图满宽行（hFull = Wa/a ≤ 3.5t，含原 contain 全景）同归此
  exact,

  /// crop 行（仅 r<1 过满侧）：行高钉 h0，Expanded 分格 + 卡片 cover 微裁；
  /// 单图 hFull 略超 3.5t 时行高钉 3.5t、满宽 cover 裁上下（同 cap 预算）
  crop,

  /// upscale 行：h = r·h0 整行等比放大，自然宽 contain、零裁剪精确填满
  ///（r·h0 ≡ Wa/Σa，渲染与 justify 行同构走 Expanded，无需 cover 路径）
  upscale,

  /// 欠填左对齐不裁剪（height = 面积锚 h0 或放大钳制后的带顶，自然宽留空）
  underfilled,

  /// 单图全景 contain（height = Wa/a，不裁不填满）——已退役：单图满宽
  /// 分派收编后不再产出（渲染效果同为满宽条带），枚举值保留不动
  /// [JustifiedRow.isUnderfilled] 的归并结构
  contain,
}

/// 火车流等高行（面积均衡 DP 断行结果，索引为绝对索引）
class JustifiedRow {
  /// 起始图索引（含）
  final int startIndex;

  /// 结束图索引（含）
  final int endIndex;

  /// 渲染行高：exact = Wa/Σa（单图满宽 = Wa/a）；crop = 面积锚 h0
  /// （单图满宽 cover = 3.5t）；underfilled = h0 或放大钳制后的带顶
  final double height;

  /// 填充模式（渲染分支判定用）
  final JustifiedFill fill;

  const JustifiedRow({
    required this.startIndex,
    required this.endIndex,
    required this.height,
    required this.fill,
  });

  /// 渲染层欠填分支判定：欠填（及已退役的全景 contain）走自然宽左对齐，
  /// justify/crop/upscale 走 Expanded 顶格（crop 的裁剪由卡片内部 cover 完成）
  bool get isUnderfilled =>
      fill == JustifiedFill.underfilled || fill == JustifiedFill.contain;
}

/// 火车流断行：把图串切成等高行序列（面积均衡 DP + 行高重锚定三级填充）。
///
/// [targetHeight] 目标边长 t（= 逻辑列宽 columnWidth），语义 = 目标面积
/// t² 的边长（行高锚）；[availableWidth] 为内容区可用宽（已扣 padding）。
List<JustifiedRow> computeJustifiedRows({
  required List<double> aspectRatios,
  required double availableWidth,
  required double targetHeight,
  required double spacing,

  /// 行内比方差罚权重覆盖；null = [justifiedVarianceWeight]
  double? varianceWeight,

  /// 填充偏离罚权重覆盖；null = [justifiedUnderfillWeight]
  double? underfillWeight,

  /// 单格裁量上限覆盖；null = [justifiedCropCap]
  double? cropCap,

  /// 放大上限覆盖；null = [justifiedUpscaleCap]
  double? upscaleCap,
}) {
  final n = aspectRatios.length;
  if (n == 0) return const [];
  final varWeight = varianceWeight ?? justifiedVarianceWeight;
  final fillWeight = underfillWeight ?? justifiedUnderfillWeight;
  final cap = cropCap ?? justifiedCropCap;
  const upscaleWeight = justifiedUpscaleWeight;
  const downWeight = justifiedDownscaleWeight;
  final upCap = upscaleCap ?? justifiedUpscaleCap;

  final t = targetHeight;
  final minH = t * justifiedMinHeightFactor;
  final maxH = t * justifiedMaxHeightFactor;

  // 非法宽高比占位为 1（与 V1/V2 占位策略一致），保证不抛异常
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

  /// 候选行 (i..j) 评估：返回 (行高, 填充模式, 成本)；不可行返回 null
  (double, JustifiedFill, double)? evaluateRow(int i, int j) {
    final count = j - i + 1;
    final rowSumA = sumA[j + 1] - sumA[i];
    final meanA = rowSumA / count;
    // 行高锚 h0 = t/√mean_a（钳带内，与窗宽解耦）
    final h0 = (t / math.sqrt(meanA)).clamp(minH, maxH);
    final imageW = availableWidth - spacing * (count - 1);
    if (imageW <= 0) return null; // 极端窄行：多图不可行
    // r = 图片可用宽 / 锚定行内容宽（r=1 即锚高精确填满）
    final r = imageW / (h0 * rowSumA);

    // 欠填形态统一结算：返回 (height, fill, fillCost)，超守卫不可行返回 null
    (double, JustifiedFill, double)? asUnderfilled(double h) {
      final contentW = h * rowSumA + spacing * (count - 1);
      // 无挤压守卫：自然内容宽超 W×(1+tol) 的多图行不可行
      // （多图横排纸条行结构性不可能）
      if (count > 1 &&
          contentW > availableWidth * (1 + justifiedJustifyTolerance)) {
        return null;
      }
      final gap = (availableWidth - contentW) / availableWidth;
      return (
        h,
        JustifiedFill.underfilled,
        gap * gap * fillWeight + justifiedUnderfillBasePenalty,
      );
    }

    final JustifiedFill fill;
    final double height;
    final double fillCost;
    if (count == 1) {
      // 单图行独立分派（放大优先于缩小、填满优先于留空、不丢内容优先）。
      // hFull = 单图填满整行宽所需高度（≡ r·h0）；单图行的 r 常态 ≫
      // upscaleCap（长图锚高下行宽只有窗宽三四成），通用带分派对它失灵，
      // 故绕开 r 带直接按 hFull 三派
      final hFull = imageW / aspects[i];
      if (hFull <= maxH) {
        // 满宽零裁剪：收编旧 contain（hFull < h0 的超宽全景，渲染同为
        // 满宽条带）与中宽长图（h0 < hFull 的放大满宽）。fill 取 exact
        // 走 Expanded 顶格（underfilled/contain 才会自然宽左对齐）；
        // fillCost = 0 与旧 contain 一致，单图行罚照旧叠加
        fill = JustifiedFill.exact;
        height = hFull;
        fillCost = 0;
      } else if (maxH / hFull >= 1 - cap) {
        // 满宽 cover 裁上下：hFull 略超 3.5t（单图中横图放大到满宽只
        // 超高一点）→ 行高钉 3.5t，裁量 1−3.5t/hFull ≤ cap，与 crop 行
        // 同预算、同双倍缩小罚（缩小永远是最后手段的结构不变）
        final coverR = maxH / hFull;
        fill = JustifiedFill.crop;
        height = maxH;
        fillCost = (1 - coverR) * (1 - coverR) * downWeight;
      } else {
        // 其余单图（方图/竖图落单行，满宽裁量超预算）：维持欠填
        final settled = asUnderfilled(h0);
        if (settled == null) return null;
        fill = settled.$2;
        height = settled.$1;
        fillCost = settled.$3;
      }
    } else if (r >= 1 - justifiedJustifyTolerance &&
        r <= 1 + justifiedJustifyTolerance) {
      // justify 行：h = Wa/Σa，零裁剪精确填满。
      // 带内微调也吃方向不对称罚（平方项量级 ≤0.01，常用行成本不爆炸）：
      // r<1 微调缩小吃 w_down，r>1 微调放大吃 w_up——DP 偏好把行做大
      fill = JustifiedFill.exact;
      height = imageW / rowSumA;
      fillCost = r < 1
          ? (1 - r) * (1 - r) * downWeight
          : (r - 1) * (r - 1) * upscaleWeight;
    } else if (r >= 1 - cap && r < 1 - justifiedJustifyTolerance) {
      // crop 行（仅 r<1 过满侧）：行高钉 h0，Expanded 分格 +
      // 卡片 cover 微裁。r>1 侧原 crop 层已退役——放大不丢内容严格更好。
      // 缩小罚双倍于放大（缩小永远是最后手段）
      fill = JustifiedFill.crop;
      height = h0;
      fillCost = (1 - r) * (1 - r) * downWeight;
    } else if (r > 1 + justifiedJustifyTolerance && r <= upCap) {
      // upscale 行（新增）：h = r·h0，整行等比放大、自然宽 contain、
      // 零裁剪精确填满（r·h0 ≡ Wa/Σa，与 justify 行同构）
      final upscaledH = r * h0;
      if (upscaledH <= maxH) {
        fill = JustifiedFill.upscale;
        height = upscaledH;
        // 放大罚超线性：(r−1)²——小空洞放大优于欠填留空，
        // 大放大率受罚陡增，DP 自动偏好重排细分
        fillCost = (r - 1) * (r - 1) * upscaleWeight;
      } else {
        // 放大率钳 3.5t/h0：钳后带顶欠填（保持放大后宽度左对齐）；
        // 带顶内容宽仍超守卫 → 退普通 h0 欠填
        final clamped = asUnderfilled(maxH);
        final settled = clamped ?? asUnderfilled(h0);
        if (settled == null) return null;
        fill = settled.$2;
        height = settled.$1;
        fillCost = settled.$3;
      }
    } else {
      // 欠填行：h0 左对齐不裁（r < 1−cap 或 r > upscaleCap）
      final settled = asUnderfilled(h0);
      if (settled == null) return null;
      fill = settled.$2;
      height = settled.$1;
      fillCost = settled.$3;
    }

    // 成本 1：行内 ln(a) 方差罚（E[x²]−E[x]²，浮点噪声钳 0）
    final rowSumLog = sumLog[j + 1] - sumLog[i];
    final rowSumLog2 = sumLog2[j + 1] - sumLog2[i];
    final meanLog = rowSumLog / count;
    final variance = math.max(rowSumLog2 / count - meanLog * meanLog, 0.0);
    var cost = variance * varWeight + fillCost;
    // 成本 3：单图行罚
    if (count == 1) cost += justifiedSingleImagePenalty;
    return (height, fill, cost);
  }

  // DP 断行：f[j+1] = 前 j+1 张最小总成本，prev[j+1] 记最优路径
  // 最后一段的起点（回溯用）
  final f = List<double>.filled(n + 1, double.infinity);
  final prev = List<int>.filled(n + 1, -1);
  f[0] = 0;
  for (var i = 0; i < n; i++) {
    if (f[i] == double.infinity) continue;
    // 行内宽高比落差硬上限：随 j 扩展 ln(a) 的 min/max 单调扩张，
    // 超 [justifiedAspectSpreadCap] 即可 break（更长的 j 只会更超）
    var minLog = double.infinity;
    var maxLog = double.negativeInfinity;
    for (var j = i; j < n; j++) {
      final logA = math.log(aspects[j]);
      if (logA < minLog) minLog = logA;
      if (logA > maxLog) maxLog = logA;
      if (maxLog - minLog > justifiedAspectSpreadCap) break;
      final candidate = evaluateRow(i, j);
      if (candidate == null) continue;
      final total = f[i] + candidate.$3;
      if (total < f[j + 1]) {
        f[j + 1] = total;
        prev[j + 1] = i;
      }
    }
  }

  // 从 n 反向回溯（单图行恒可行，prev 必有路；
  // 防御：缺失时退化为单图行，不死循环不丢图）
  final rows = <JustifiedRow>[];
  var end = n;
  while (end > 0) {
    final start = prev[end] >= 0 && prev[end] < end ? prev[end] : end - 1;
    final candidate = evaluateRow(start, end - 1);
    rows.insert(
      0,
      JustifiedRow(
        startIndex: start,
        endIndex: end - 1,
        height: candidate?.$1 ?? t,
        fill: candidate?.$2 ?? JustifiedFill.underfilled,
      ),
    );
    end = start;
  }
  return rows;
}
