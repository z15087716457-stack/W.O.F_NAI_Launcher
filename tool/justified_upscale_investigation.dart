// 火车流「超 upscaleCap 欠填洞」一次性调查演算脚本（不进正式测试套件）。
// 用法：dart run tool/justified_upscale_investigation.dart
//
// 结构：SchemedRow/Scheme + computeRowsX 为 lib 引擎（V3 + 单图行满宽分派）
// 的镜像拷贝，仅放大带分派按方案开关改写；baseline 方案与 lib 引擎逐格
// 对拍（sanity），保证镜像无偏。所有场景为用户反馈的典型组合网格。
import 'dart:math' as math;

import 'package:nai_launcher/core/utils/justified_layout.dart';
import 'package:nai_launcher/core/utils/justified_layout.dart' as lib;

const double spacing = 12.0;
const double tol = justifiedJustifyTolerance; // 0.08
const double wFill = justifiedUnderfillWeight; // 1.5
const double basePenalty = justifiedUnderfillBasePenalty; // 0.05
const double wDown = justifiedDownscaleWeight; // 1.8
const double singlePenalty = justifiedSingleImagePenalty; // 0.3
const double cropCap = justifiedCropCap; // 0.12

/// 候选方案开关
class Scheme {
  final String name;

  /// 二次罚放大带右端（baseline = 1.4）
  final double cap;

  /// 二次罚权重 w_up
  final double wUp;

  /// 超 cap 放大的高度门控（×t）；null = 纯 cap 模式（超 cap 不可行）
  final double? gateT;

  /// 超 cap 放大的绝对 r 上限（兼面积天花：放大后单图面积 = r²·t²）
  final double maxRatio;

  /// 超 cap 线性尾斜率（cap 点连续：(cap−1)²·wUp + (r−cap)·slope）
  final double tailSlope;

  /// 高度门控不够时，允许 cover 竖裁兜底（裁量 ≤ cropCap，行高钉门控）
  final bool hybridCrop;

  const Scheme(
    this.name, {
    required this.cap,
    required this.wUp,
    this.gateT,
    this.maxRatio = double.infinity,
    this.tailSlope = 0,
    this.hybridCrop = false,
  });
}

/// 镜像引擎：与 lib.computeJustifiedRows 同结构，仅 r>1 侧放大带按方案改写
List<lib.JustifiedRow> computeRowsX(
  List<double> aspectRatios,
  double width,
  double t,
  Scheme s,
) {
  final n = aspectRatios.length;
  if (n == 0) return const [];
  final minH = t * justifiedMinHeightFactor;
  final maxH = t * justifiedMaxHeightFactor;
  final aspects = List<double>.generate(n, (i) {
    final a = aspectRatios[i];
    return (a.isFinite && a > 0) ? a : 1.0;
  });
  final sumA = List<double>.filled(n + 1, 0);
  final sumLog = List<double>.filled(n + 1, 0);
  final sumLog2 = List<double>.filled(n + 1, 0);
  for (var i = 0; i < n; i++) {
    final logA = math.log(aspects[i]);
    sumA[i + 1] = sumA[i] + aspects[i];
    sumLog[i + 1] = sumLog[i] + logA;
    sumLog2[i + 1] = sumLog2[i] + logA * logA;
  }

  double upscaleCost(double r) {
    if (r <= s.cap) return (r - 1) * (r - 1) * s.wUp;
    return (s.cap - 1) * (s.cap - 1) * s.wUp + (r - s.cap) * s.tailSlope;
  }

  // 超 cap 区（r > cap）是否允许放大：高度门控 + 绝对 r 上限
  bool gatedAllowed(double r, double h0) {
    if (s.gateT == null) return false;
    return r <= s.maxRatio && r * h0 <= s.gateT! * t && r * h0 <= maxH;
  }

  (double, lib.JustifiedFill, double)? evaluateRow(int i, int j) {
    final count = j - i + 1;
    final rowSumA = sumA[j + 1] - sumA[i];
    final meanA = rowSumA / count;
    final h0 = (t / math.sqrt(meanA)).clamp(minH, maxH);
    final imageW = width - spacing * (count - 1);
    if (imageW <= 0) return null;
    final r = imageW / (h0 * rowSumA);

    (double, lib.JustifiedFill, double)? asUnderfilled(double h) {
      final contentW = h * rowSumA + spacing * (count - 1);
      if (count > 1 && contentW > width * (1 + tol)) return null;
      final gap = (width - contentW) / width;
      return (
        h,
        lib.JustifiedFill.underfilled,
        gap * gap * wFill + basePenalty,
      );
    }

    final lib.JustifiedFill fill;
    final double height;
    final double fillCost;
    if (count == 1) {
      // 单图行独立分派（已入库的修复，镜像保持一致）
      final hFull = imageW / aspects[i];
      if (hFull <= maxH) {
        fill = lib.JustifiedFill.exact;
        height = hFull;
        fillCost = 0;
      } else if (maxH / hFull >= 1 - cropCap) {
        final coverR = maxH / hFull;
        fill = lib.JustifiedFill.crop;
        height = maxH;
        fillCost = (1 - coverR) * (1 - coverR) * wDown;
      } else {
        final settled = asUnderfilled(h0);
        if (settled == null) return null;
        fill = settled.$2;
        height = settled.$1;
        fillCost = settled.$3;
      }
    } else if (r >= 1 - tol && r <= 1 + tol) {
      fill = lib.JustifiedFill.exact;
      height = imageW / rowSumA;
      fillCost = r < 1 ? (1 - r) * (1 - r) * wDown : (r - 1) * (r - 1) * s.wUp;
    } else if (r >= 1 - cropCap && r < 1 - tol) {
      fill = lib.JustifiedFill.crop;
      height = h0;
      fillCost = (1 - r) * (1 - r) * wDown;
    } else if (r > 1 + tol && (r <= s.cap || gatedAllowed(r, h0))) {
      // 放大带：cap 内二次罚；超 cap 走门控 + 线性尾
      final upscaledH = r * h0;
      if (upscaledH <= maxH) {
        fill = lib.JustifiedFill.upscale;
        height = upscaledH;
        fillCost = upscaleCost(r);
      } else {
        final clamped = asUnderfilled(maxH);
        final settled = clamped ?? asUnderfilled(h0);
        if (settled == null) return null;
        fill = settled.$2;
        height = settled.$1;
        fillCost = settled.$3;
      }
    } else if (s.hybridCrop &&
        s.gateT != null &&
        r > s.maxRatio &&
        r <= s.maxRatio / (1 - cropCap)) {
      // 竖裁兜底：双门控放不下但差一点（r ∈ (2.0, 2.27]），行高钉门控，cover 裁上下 ≤ cropCap
      final gateH = math.min(s.gateT! * t, maxH);
      final cropFrac = 1 - gateH / (r * h0);
      if (cropFrac >= 0 && cropFrac <= cropCap) {
        fill = lib.JustifiedFill.crop;
        height = gateH;
        fillCost = upscaleCost(gateH / h0) + cropFrac * cropFrac * wDown;
      } else {
        final settled = asUnderfilled(h0);
        if (settled == null) return null;
        fill = settled.$2;
        height = settled.$1;
        fillCost = settled.$3;
      }
    } else {
      final settled = asUnderfilled(h0);
      if (settled == null) return null;
      fill = settled.$2;
      height = settled.$1;
      fillCost = settled.$3;
    }

    final rowSumLog = sumLog[j + 1] - sumLog[i];
    final rowSumLog2 = sumLog2[j + 1] - sumLog2[i];
    final meanLog = rowSumLog / count;
    final variance = math.max(rowSumLog2 / count - meanLog * meanLog, 0.0);
    var cost = variance * justifiedVarianceWeight + fillCost;
    if (count == 1) cost += singlePenalty;
    return (height, fill, cost);
  }

  final f = List<double>.filled(n + 1, double.infinity);
  final prev = List<int>.filled(n + 1, -1);
  f[0] = 0;
  for (var i = 0; i < n; i++) {
    if (f[i] == double.infinity) continue;
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
  final rows = <lib.JustifiedRow>[];
  var end = n;
  while (end > 0) {
    final start = prev[end] >= 0 && prev[end] < end ? prev[end] : end - 1;
    final candidate = evaluateRow(start, end - 1);
    rows.insert(
      0,
      lib.JustifiedRow(
        startIndex: start,
        endIndex: end - 1,
        height: candidate?.$1 ?? t,
        fill: candidate?.$2 ?? lib.JustifiedFill.underfilled,
      ),
    );
    end = start;
  }
  return rows;
}

/// 行观测指标
class RowStat {
  final int count;
  final lib.JustifiedFill fill;
  final double height;
  final double r; // 锚定填满比 imageW/(h0·Σa)
  final double holePct; // 欠填空洞率（填满行 = 0）
  final double areaMult; // 单图显示面积 / t²（取行内均值）
  const RowStat(
    this.count,
    this.fill,
    this.height,
    this.r,
    this.holePct,
    this.areaMult,
  );
}

RowStat statOf(
  lib.JustifiedRow row,
  List<double> aspects,
  double width,
  double t,
) {
  var sumA = 0.0;
  for (var k = row.startIndex; k <= row.endIndex; k++) {
    sumA += aspects[k];
  }
  final count = row.endIndex - row.startIndex + 1;
  final meanA = sumA / count;
  final h0 = (t / math.sqrt(meanA)).clamp(
    t * justifiedMinHeightFactor,
    t * justifiedMaxHeightFactor,
  );
  final imageW = width - spacing * (count - 1);
  final r = imageW / (h0 * sumA);
  final isCrop = row.fill == lib.JustifiedFill.crop;
  // crop 行卡片宽 = imageW×a/Σa（Expanded 分格），其余 = height×a
  final shownW = isCrop ? imageW * meanA / sumA : row.height * meanA;
  final area = row.height * shownW / (t * t);
  final hole = row.isUnderfilled
      ? 1 - (row.height * sumA + spacing * (count - 1)) / width
      : 0.0;
  return RowStat(count, row.fill, row.height, r, hole, area);
}

String fillTag(lib.JustifiedFill f) {
  switch (f) {
    case lib.JustifiedFill.exact:
      return 'justify';
    case lib.JustifiedFill.upscale:
      return '放大';
    case lib.JustifiedFill.crop:
      return '裁剪';
    case lib.JustifiedFill.underfilled:
      return '欠填';
    case lib.JustifiedFill.contain:
      return 'contain';
  }
}

String cellOf(List<lib.JustifiedRow> rows, List<double> a, double w, double t) {
  final parts = <String>[];
  for (final row in rows) {
    final st = statOf(row, a, w, t);
    final ht = st.height / t;
    if (st.fill == lib.JustifiedFill.underfilled) {
      parts.add(
        '${st.count}张欠填 洞${(st.holePct * 100).toStringAsFixed(0)}% '
        'h${ht.toStringAsFixed(2)}t',
      );
    } else {
      parts.add(
        '${st.count}张${fillTag(st.fill)} h${ht.toStringAsFixed(2)}t '
        '面${st.areaMult.toStringAsFixed(1)}x',
      );
    }
  }
  return parts.join('+');
}

void main() {
  const t = 283.0; // 用户当前列宽
  final windows = [1200.0, 1600.0, 1920.0];

  final scenarios = <String, List<double>>{
    'S1 2×横长(a=2)': [2, 2],
    'S2 3×横长(a=2)': [2, 2, 2],
    'S3 2×横长(a=2.5)': [2.5, 2.5],
    'S4 4×竖图(a=0.6)': [0.6, 0.6, 0.6, 0.6],
    'S5 5×竖图(a=0.6)': [0.6, 0.6, 0.6, 0.6, 0.6],
    'S6 4×方图(a=1)': [1, 1, 1, 1],
    'S7 3×横图(a=1.55)': [1.55, 1.55, 1.55],
    'S8 4×竖图(a=0.75)': [0.75, 0.75, 0.75, 0.75],
    'S9 3×方图(a=1)': [1, 1, 1],
    'S10 2×方图(a=1)': [1, 1],
    'S11 3×竖长(a=0.5)': [0.5, 0.5, 0.5],
  };

  final schemes = <Scheme>[
    const Scheme('baseline(cap1.4,w.9)', cap: 1.4, wUp: 0.9),
    const Scheme('A15(cap1.5,w.75)', cap: 1.5, wUp: 0.75),
    const Scheme('A16(cap1.6,w.62)', cap: 1.6, wUp: 0.62),
    const Scheme('A18(cap1.8,w.46)', cap: 1.8, wUp: 0.46),
    const Scheme(
      'B(门控2t,rMax2,尾.3)',
      cap: 1.4,
      wUp: 0.9,
      gateT: 2.0,
      maxRatio: 2.0,
      tailSlope: 0.3,
    ),
    const Scheme(
      'B-r2.5(门控2t,rMax2.5,尾.3)',
      cap: 1.4,
      wUp: 0.9,
      gateT: 2.0,
      maxRatio: 2.5,
      tailSlope: 0.3,
    ),
    const Scheme(
      'B-1.5t(门控1.5t,rMax2,尾.3)',
      cap: 1.4,
      wUp: 0.9,
      gateT: 1.5,
      maxRatio: 2.0,
      tailSlope: 0.3,
    ),
    const Scheme(
      'B+C(门控2t,rMax2,尾.3,竖裁)',
      cap: 1.4,
      wUp: 0.9,
      gateT: 2.0,
      maxRatio: 2.0,
      tailSlope: 0.3,
      hybridCrop: true,
    ),
  ];

  // ── 0. sanity：B+C 定案镜像 vs lib 引擎逐格对拍 ──
  var mismatch = 0;
  var cells = 0;
  final bcScheme = schemes.firstWhere((s) => s.name.startsWith('B+C'));
  for (final a in scenarios.values) {
    for (final w in windows) {
      cells++;
      final ref = lib.computeJustifiedRows(
        aspectRatios: a,
        availableWidth: w,
        targetHeight: t,
        spacing: spacing,
      );
      final got = computeRowsX(a, w, t, bcScheme);
      if (ref.length != got.length) {
        mismatch++;
        continue;
      }
      for (var k = 0; k < ref.length; k++) {
        if (ref[k].fill != got[k].fill ||
            (ref[k].height - got[k].height).abs() > 1e-6 ||
            ref[k].startIndex != got[k].startIndex) {
          mismatch++;
          break;
        }
      }
    }
  }
  print('== sanity: B+C 镜像 vs lib 引擎  $cells 格, mismatch=$mismatch ==');
  print('');

  // ── 1. w_up 临界推导（cap → w_up < base/(cap−1)² + wFill·(0.97/cap)²）──
  print('== w_up 临界随 cap 上移（Wa/W≈0.97, wFill=1.5, base=0.05）==');
  for (final cap in [1.4, 1.5, 1.6, 1.8, 2.0]) {
    final crit =
        basePenalty / math.pow(cap - 1, 2) + wFill * math.pow(0.97 / cap, 2);
    print('  cap=$cap  w_up临界=${crit.toStringAsFixed(3)}');
  }
  print('');

  // ── 2. 各方案「放大 vs 欠填」交叉点（cost 相等时的 r，超出则欠填更便宜）──
  print('== 放大罚与欠填罚交叉点 r*（r<r* 时放大结构性更优；gap≈0.97(1−1/r)）==');
  for (final s in schemes) {
    var cross = double.nan;
    for (var r = 1.09; r <= 4.0; r += 0.001) {
      final up = r <= s.cap
          ? (r - 1) * (r - 1) * s.wUp
          : (s.gateT == null
                ? double.infinity
                : (s.cap - 1) * (s.cap - 1) * s.wUp +
                      (r - s.cap) * s.tailSlope);
      final gap = 0.97 * (1 - 1 / r);
      final under = gap * gap * wFill + basePenalty;
      if (up > under) {
        cross = r;
        break;
      }
    }
    print(
      '  ${s.name.padRight(30)} r*='
      '${cross.isNaN ? ">4.0" : cross.toStringAsFixed(2)}',
    );
  }
  print('');

  // ── 3. 场景网格（t=283；每格 = DP 断行结果）──
  for (final s in schemes) {
    print('== 方案 ${s.name}  (t=283) ==');
    final header = StringBuffer('场景'.padRight(20));
    for (final w in windows) {
      header.write('W=${w.toInt()}'.padRight(34));
    }
    print(header);
    var holesBase = 0, holesNow = 0;
    var maxArea = 0.0, maxHt = 0.0;
    for (final e in scenarios.entries) {
      final line = StringBuffer(e.key.padRight(20));
      for (final w in windows) {
        final rows = computeRowsX(e.value, w, t, s);
        final cell = cellOf(rows, e.value, w, t);
        line.write(cell.padRight(34));
        final base = computeRowsX(e.value, w, t, schemes[0]);
        final baseHole = base.any((r) => r.isUnderfilled);
        final nowHole = rows.any((r) => r.isUnderfilled);
        if (baseHole) holesBase++;
        if (nowHole) holesNow++;
        for (final row in rows) {
          final st = statOf(row, e.value, w, t);
          if (!row.isUnderfilled) {
            if (st.areaMult > maxArea) maxArea = st.areaMult;
            if (st.height / t > maxHt) maxHt = st.height / t;
          }
        }
      }
      print(line);
    }
    final totalCells = scenarios.length * windows.length;
    print(
      '  小计：基线欠填格 $holesBase/$totalCells → 本方案 $holesNow/$totalCells；'
      '填满行最大面积 ${maxArea.toStringAsFixed(1)}x t²，'
      '最高行 ${maxHt.toStringAsFixed(2)}t',
    );
    print('');
  }

  // ── 4. 关键格成本审计（baseline 下 DP 为什么选欠填）──
  print('== 关键格成本审计（baseline 权重）：欠填 vs 若允许放大的罚 ==');
  for (final (name, a, w) in [
    ('S1 2×a2', [2.0, 2.0], 1200.0),
    ('S1 2×a2', [2.0, 2.0], 1600.0),
    ('S4 4×a0.6', [0.6, 0.6, 0.6, 0.6], 1600.0),
    ('S7 3×a1.55', [1.55, 1.55, 1.55], 1600.0),
  ]) {
    final sumA = a.fold<double>(0, (x, y) => x + y);
    final count = a.length;
    final h0 = (t / math.sqrt(sumA / count)).clamp(
      t * justifiedMinHeightFactor,
      t * justifiedMaxHeightFactor,
    );
    final imageW = w - spacing * (count - 1);
    final r = imageW / (h0 * sumA);
    final contentW = h0 * sumA + spacing * (count - 1);
    final gap = (w - contentW) / w;
    final underCost = gap * gap * wFill + basePenalty;
    final upCost = (r - 1) * (r - 1) * 0.9;
    final singlesCost = count * singlePenalty;
    print(
      '  $name @W=${w.toInt()}: r=${r.toStringAsFixed(2)}, '
      '欠填罚=${underCost.toStringAsFixed(3)}(洞${(gap * 100).toStringAsFixed(0)}%), '
      '若放大罚=${upCost.toStringAsFixed(3)}(h=${(r * h0 / t).toStringAsFixed(2)}t), '
      '全拆单图=${singlesCost.toStringAsFixed(2)}',
    );
  }
  print('');

  // ── 5. 推荐方案的 t=200 稳健性抽查 ──
  final rec = schemes[4];
  print('== 稳健性：方案 ${rec.name} 在 t=200 下抽查 ==');
  for (final e in scenarios.entries) {
    final line = StringBuffer(e.key.padRight(20));
    for (final w in windows) {
      line.write(
        cellOf(
          computeRowsX(e.value, w, 200, rec),
          e.value,
          w,
          200,
        ).padRight(34),
      );
    }
    print(line);
  }
}
