import 'dart:math';

import '../../data/models/prompt_block/pill_document.dart';
import 'nai_weight_syntax.dart';

/// 块实例随机引擎（P2.5）：纯函数、零 Flutter 依赖，seeded [Random] 可复现。
///
/// 权重采样对齐 PromptCard 的 Split-Beta（证据：
/// `PromptCard-Studio backend/app/style_explore_algorithm.py`
/// `dispersion_to_beta_shape` / `_sample_side` / `sample_split_beta_weight` /
/// `soft_balance_weights` / `discretize_weight`）：
/// 左右区间长度加权选侧 → 距离分布 Beta(1, 12-11·离散) → 软平衡整串均值
/// 向「平均权重」回拉 → 0.1 四舍五入离散化。
abstract final class PillRollEngine {
  /// 权重段起始：`N::`（含负数/小数，允许前导空白）。
  static final RegExp _weightPrefix = RegExp(r'^\s*[-+]?\d+(?:\.\d+)?::');

  /// 按顶层逗号切分块内容为原子列表。
  ///
  /// `N::...::` 权重段内部的逗号不切断（如 `0.5::artist:a, 1girl::` 整体
  /// 是一个原子）。各原子 trim，空原子丢弃。
  static List<String> splitTopLevelAtoms(String content) {
    final raw = <String>[];
    final buffer = StringBuffer();
    var i = 0;
    var atAtomStart = true; // 起始或刚越过顶层逗号（允许先导空白）
    while (i < content.length) {
      if (atAtomStart) {
        final match = _weightPrefix.firstMatch(content.substring(i));
        if (match != null) {
          // 权重段：整体消费到闭合 ::；无闭合则剩余全算普通文本
          final close = content.indexOf('::', i + match.end);
          final end = close < 0 ? content.length : close + 2;
          buffer.write(content.substring(i, end));
          i = end;
          atAtomStart = false;
          continue;
        }
      }
      final ch = content[i];
      if (ch == ',') {
        raw.add(buffer.toString());
        buffer.clear();
        atAtomStart = true;
      } else {
        buffer.write(ch);
        if (ch.trim().isNotEmpty) atAtomStart = false;
      }
      i++;
    }
    raw.add(buffer.toString());
    return [
      for (final atom in raw)
        if (atom.trim().isNotEmpty) atom.trim(),
    ];
  }

  /// 原子是否自带顶层权重前缀（`N::` 开头）；带则不重复包装随机权重。
  static bool hasTopLevelWeightPrefix(String atom) =>
      _weightPrefix.hasMatch(atom);

  /// 执行一次 roll，返回物化提示词串（可为空串：触发概率未中/数量 0/池空）。
  static String rollInstance({
    required PillInstanceSettings settings,
    required List<String> atoms,
    required Random rng,
  }) {
    if (settings.triggerProbability < 1.0 &&
        rng.nextDouble() >= settings.triggerProbability) {
      return '';
    }
    if (atoms.isEmpty) return '';

    // 数量：min~max 均匀含两端，池不足截断；min>max 防御性交换
    final lo = settings.countMin.clamp(0, atoms.length);
    final hi = settings.countMax.clamp(0, atoms.length);
    final lower = lo <= hi ? lo : hi;
    final upper = lo <= hi ? hi : lo;
    if (upper <= 0) return '';
    final count = lower + rng.nextInt(upper - lower + 1);
    if (count <= 0) return '';

    // 均匀无放回：部分 Fisher-Yates 取前 count 个下标
    final indices = List<int>.generate(atoms.length, (i) => i);
    for (var i = 0; i < count; i++) {
      final j = i + rng.nextInt(indices.length - i);
      final tmp = indices[i];
      indices[i] = indices[j];
      indices[j] = tmp;
    }
    final drawn = indices.sublist(0, count);
    if (settings.order == PillRollOrder.original) drawn.sort();
    final selected = [for (final index in drawn) atoms[index]];

    return _composeSelected(selected, settings, rng);
  }

  /// 顺序模式 roll（QoL-L2）：从 [cursor] 起取 N 个原子（N = min~max
  /// 区间随机、截断到池长），池尾绕回，单次内不重复；按游标序输出。
  ///
  /// 返回 `(物化串, 下一游标)`。游标只在触发概率通过、实例实际出场时
  /// 推进（推进量 = 实际抽取数，已按池长取模）；触发未中/数量 0/池空
  /// 原样返回入参游标——序列 = 实际看到的内容流。权重段与随机模式共用
  /// 同一配重管线（选择机制与权重正交）。[cursor] 越界（池内容编辑后
  /// 原子数变化）按 `cursor % 池长` 收敛，不写回由调用方决定。
  static (String, int) rollInstanceSequential({
    required PillInstanceSettings settings,
    required List<String> atoms,
    required int cursor,
    required Random rng,
  }) {
    if (settings.triggerProbability < 1.0 &&
        rng.nextDouble() >= settings.triggerProbability) {
      return ('', cursor);
    }
    if (atoms.isEmpty) return ('', cursor);

    final lo = settings.countMin.clamp(0, atoms.length);
    final hi = settings.countMax.clamp(0, atoms.length);
    final lower = lo <= hi ? lo : hi;
    final upper = lo <= hi ? hi : lo;
    if (upper <= 0) return ('', cursor);
    final count = lower + rng.nextInt(upper - lower + 1);
    if (count <= 0) return ('', cursor);

    final start = cursor % atoms.length;
    final selected = [
      for (var k = 0; k < count; k++) atoms[(start + k) % atoms.length],
    ];
    final text = _composeSelected(selected, settings, rng);
    return (text, (start + count) % atoms.length);
  }

  /// 选中原子 → 输出串：权重段关闭直拼；开启则 Split-Beta 配重
  /// （自带顶层权重前缀的原子尊重作者显式权重，不套第二层）。
  static String _composeSelected(
    List<String> selected,
    PillInstanceSettings settings,
    Random rng,
  ) {
    if (!settings.weightEnabled) {
      return NaiWeightSyntax.guardClosures(selected.join(', '));
    }

    final weights = [
      for (var k = 0; k < selected.length; k++)
        sampleSplitBetaWeight(settings, rng),
    ];
    final balanced = settings.softBalance
        ? softBalanceWeights(weights, settings)
        : weights;
    final parts = <String>[];
    for (var k = 0; k < selected.length; k++) {
      final atom = selected[k];
      if (hasTopLevelWeightPrefix(atom)) {
        parts.add(atom);
        continue;
      }
      final w = discretizeWeight(
        balanced[k],
        settings.weightMin,
        settings.weightMax,
      );
      parts.add(NaiWeightSyntax.wrap(w.toStringAsFixed(1), atom));
    }
    return NaiWeightSyntax.guardClosures(parts.join(', '));
  }

  /// Split-Beta 连续采样（未软平衡/离散化）。防御性修正 min>max 与
  /// 平均越界（正常路径由 L2 弹窗与 fromJson 保证有序）。
  static double sampleSplitBetaWeight(PillInstanceSettings s, Random rng) {
    var lower = s.weightMin, upper = s.weightMax;
    if (lower > upper) {
      final tmp = lower;
      lower = upper;
      upper = tmp;
    }
    final mode = s.weightAverage.clamp(lower, upper);
    const eps = 1e-9;
    final leftLen = mode - lower;
    final rightLen = upper - mode;
    if (leftLen <= eps && rightLen <= eps) return mode;
    if (leftLen <= eps) {
      return _sampleSide(mode, rightLen, s.rightDispersion, 1, rng);
    }
    if (rightLen <= eps) {
      return _sampleSide(mode, leftLen, s.leftDispersion, -1, rng);
    }
    // 区间越长落入该侧机会越大，避免短侧被「各 50%」过度放大
    final chooseLeft = rng.nextDouble() < leftLen / (leftLen + rightLen);
    return chooseLeft
        ? _sampleSide(mode, leftLen, s.leftDispersion, -1, rng)
        : _sampleSide(mode, rightLen, s.rightDispersion, 1, rng);
  }

  /// 距离 ~ Beta(1, 12-11·离散)（逆 CDF：1-(1-u)^(1/β)），离散 1 退化均匀。
  static double _sampleSide(
    double mode,
    double length,
    double dispersion,
    int direction,
    Random rng,
  ) {
    final beta = 12.0 - 11.0 * dispersion.clamp(0.0, 1.0);
    final distance = (1 - pow(1 - rng.nextDouble(), 1 / beta)) * length;
    return mode + direction * distance;
  }

  /// 软平衡：整串同向平移 `(平均 - 串均值) * strength` 并 clamp 回范围，
  /// 只减弱共同偏高/偏低，不改变成员间相对差距。
  static List<double> softBalanceWeights(
    List<double> weights,
    PillInstanceSettings s,
  ) {
    if (weights.isEmpty || s.softBalanceStrength <= 0) {
      return List<double>.of(weights);
    }
    final mean = weights.reduce((a, b) => a + b) / weights.length;
    final shift = (s.weightAverage - mean) * s.softBalanceStrength;
    return [
      for (final w in weights)
        (w + shift).clamp(s.weightMin, s.weightMax).toDouble(),
    ];
  }

  /// 截断到 [lower, upper] 并四舍五入到 0.1 网格。
  static double discretizeWeight(double value, double lower, double upper) {
    final clipped = value.clamp(lower, upper).toDouble();
    final rounded = (clipped * 10).roundToDouble() / 10;
    return rounded.clamp(lower, upper).toDouble();
  }
}
