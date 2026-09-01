import 'dart:math' as math;

import '../../data/models/prompt_block/pill_document.dart';
import '../../data/models/style_explore/explore_run.dart';
import 'pill_roll_engine.dart';

/// 深度迭代变异配置（阶段 D）。默认值偏向保守扰动：
/// 权重扰动区间 = 父权重 ± [weightAmplitude]（截断到 weightMin/Max）。
class ExploreMutationConfig {
  const ExploreMutationConfig({
    this.weightPerturbProbability = 0.7,
    this.weightAmplitude = 0.4,
    this.assignWeightProbability = 0.3,
    this.assignWeightMode = 0.8,
    this.deleteProbability = 0.08,
    this.injectionRatio = 0.1,
    this.crossoverProbability = 0.65,
    this.weightMin = 0.1,
    this.weightMax = 2.0,
    this.dispersion = 0.5,
    this.maxAttempts = 240,
  });

  /// 每个带 `N::...::` 权重的原子被重采样的概率。
  final double weightPerturbProbability;

  /// 权重扰动区间半宽（Split-Beta 众数 = 父权重）。
  final double weightAmplitude;

  /// 无权重原子被赋予随机权重的概率。
  final double assignWeightProbability;

  /// 赋权时的采样众数。
  final double assignWeightMode;

  /// 每个原子被删除的概率（子代至少保留一个原子）。
  final double deleteProbability;

  /// 随机注入名额占比（同 PromptCard：round(count × 比)、至少 1）。
  final double injectionRatio;

  /// 保底+注入之外的剩余名额里，两父本交叉的概率（父本 ≥2 时生效）。
  final double crossoverProbability;

  /// 权重取值范围（扰动/赋权都截断到此区间并 0.1 离散化）。
  final double weightMin;
  final double weightMax;

  /// Split-Beta 左右离散度（0~1，越大越偏离众数）。
  final double dispersion;

  /// 每个名额的去重尝试上限（耗尽则放弃该名额，不静默重复）。
  final int maxAttempts;
}

/// 变异引擎输入父本。
class ExploreMutationParent {
  const ExploreMutationParent({
    required this.id,
    required this.text,
    this.preference = 1.0,
    this.sourceCandidateId,
  });

  /// 父本条 id（ExploreParent.id）。
  final String id;

  /// 父本串（roll 快照串或自定义串）。
  final String text;

  /// 偏好值：加权选父时的票权（两两排序产出）。
  final double preference;

  /// 来源候选 id（子代 lineage.parentCandidateIds 用；自定义串为 null）。
  final String? sourceCandidateId;
}

/// 一个子代产物：变异串 + 实际操作 + 实际使用的父本。
class ExploreMutatedCandidate {
  const ExploreMutatedCandidate({
    required this.text,
    required this.operation,
    required this.parents,
  });

  final String text;

  /// mutation / crossover / injection（按实际操作登记）。
  final ExploreLineageOperation operation;
  final List<ExploreMutationParent> parents;
}

/// 深度迭代变异引擎：纯函数、零 Flutter 依赖，seeded [math.Random] 可复现。
///
/// 语义对齐 PromptCard `generate_deep_candidates`：
/// - **公平性保底**：每个父本至少产出一个局部变异子代（即使偏好最低）。
/// - **随机注入名额**：占 round(count × [ExploreMutationConfig.injectionRatio])、
///   至少 1，从注入池无放回抽新原子。
/// - 剩余名额：父本 ≥2 时按 [ExploreMutationConfig.crossoverProbability]
///   两父本交叉，否则按偏好加权选父做局部变异。
/// - **去重**：产出串集合内互不重复，也不与任何父本串完全重复；
///   单名额尝试上限后放弃该名额（明确提前收尾，不静默重复）。
///
/// 与 PromptCard 的两处有意偏差（因我们的子代串只替换目标实例的 roll
/// 结果而非整段提示词）：
/// - 注入子代 = 父本原子 + 池中新原子（保留家族特征），非纯池抽取。
/// - 局部变异 = 权重扰动（Split-Beta 以父权重为众数重采样）+ 小概率删除 +
///   按概率给无权重原子赋权，不做 PromptCard 的 ID 替换（文本原子无池映射）。
abstract final class ExploreMutationEngine {
  /// 带权重原子的解析：`N::内容::`（splitTopLevelAtoms 保证权重段完整）。
  static final RegExp _weightedAtom = RegExp(r'^([-+]?\d+(?:\.\d+)?)::(.*)::$');

  /// 生成一轮深度子代串。要求 [count] ≥ 父本数（保底约束），
  /// 否则抛 [ArgumentError]；返回数量可能少于 [count]（去重空间耗尽）。
  static List<ExploreMutatedCandidate> generateDeepCandidates({
    required List<ExploreMutationParent> parents,
    required int count,
    List<String> injectionPool = const [],
    ExploreMutationConfig config = const ExploreMutationConfig(),
    required math.Random rng,
  }) {
    if (parents.isEmpty) {
      throw ArgumentError.value(parents, 'parents', '深度迭代至少需要一个父本');
    }
    if (count < parents.length) {
      throw ArgumentError.value(count, 'count', '子代数需不小于父本数（每父本保底一个变异子代）');
    }

    final parentAtoms = {
      for (final parent in parents)
        parent.id: PillRollEngine.splitTopLevelAtoms(parent.text),
    };
    // 注入池规范化：去空、去重（保序）。
    final pool = <String>[];
    final poolSeen = <String>{};
    for (final raw in injectionPool) {
      final atom = raw.trim();
      if (atom.isEmpty) continue;
      if (poolSeen.add(atom)) pool.add(atom);
    }

    final parentTexts = {for (final parent in parents) parent.text};
    final seen = <String>{};
    final results = <ExploreMutatedCandidate>[];

    bool appendUnique(ExploreMutatedCandidate Function() factory) {
      for (var attempt = 0; attempt < config.maxAttempts; attempt++) {
        final candidate = factory();
        final text = candidate.text;
        if (text.isEmpty) continue;
        if (parentTexts.contains(text) || !seen.add(text)) continue;
        results.add(candidate);
        return true;
      }
      return false;
    }

    // 保底：每个父本至少一个局部变异子代。
    for (final parent in parents) {
      appendUnique(() => _mutate(parent, parentAtoms[parent.id]!, config, rng));
    }

    // 随机注入名额（池为空则整体跳过）。
    if (pool.isNotEmpty) {
      final injectionCount = math.min(
        count - results.length,
        math.max(1, (count * config.injectionRatio).round()),
      );
      for (var i = 0; i < injectionCount; i++) {
        appendUnique(
          () => _inject(_weightedParent(parents, rng), parentAtoms, pool, rng),
        );
      }
    }

    // 剩余名额：交叉或加权变异；去重空间耗尽即提前收尾。
    while (results.length < count) {
      final filled =
          parents.length > 1 && rng.nextDouble() < config.crossoverProbability
          ? appendUnique(() => _crossover(parents, parentAtoms, rng))
          : appendUnique(() {
              final parent = _weightedParent(parents, rng);
              return _mutate(parent, parentAtoms[parent.id]!, config, rng);
            });
      if (!filled) break;
    }
    return results;
  }

  /// 按偏好加权随机选父；[excludeId] 用于交叉时选出两个不同父本。
  static ExploreMutationParent _weightedParent(
    List<ExploreMutationParent> parents,
    math.Random rng, [
    String? excludeId,
  ]) {
    final eligible = [
      for (final parent in parents)
        if (parent.id != excludeId) parent,
    ];
    final total = eligible.fold<double>(
      0,
      (sum, parent) => sum + math.max(0, parent.preference),
    );
    if (total <= 0) return eligible[rng.nextInt(eligible.length)];
    var ticket = rng.nextDouble() * total;
    for (final parent in eligible) {
      ticket -= math.max(0, parent.preference);
      if (ticket <= 0) return parent;
    }
    return eligible.last;
  }

  /// 局部变异：原子删除（小概率）+ 权重扰动/赋权，至少保留一个原子。
  static ExploreMutatedCandidate _mutate(
    ExploreMutationParent parent,
    List<String> atoms,
    ExploreMutationConfig config,
    math.Random rng,
  ) {
    final kept = <String>[];
    for (final atom in atoms) {
      if (atoms.length > 1 && rng.nextDouble() < config.deleteProbability) {
        continue;
      }
      kept.add(_perturbAtom(atom, config, rng));
    }
    if (kept.isEmpty && atoms.isNotEmpty) {
      kept.add(_perturbAtom(atoms[rng.nextInt(atoms.length)], config, rng));
    }
    var text = kept.join(', ');
    // 与父本完全一致时强制改一处：有权重原子强制扰动，否则随机赋权。
    if (text == parent.text && kept.isNotEmpty) {
      final weightedIndexes = [
        for (var i = 0; i < kept.length; i++)
          if (_weightedAtom.hasMatch(kept[i])) i,
      ];
      if (weightedIndexes.isNotEmpty) {
        final index = weightedIndexes[rng.nextInt(weightedIndexes.length)];
        kept[index] = _perturbWeightedAtom(
          _weightedAtom.firstMatch(kept[index])!,
          config,
          rng,
        );
      } else {
        final index = rng.nextInt(kept.length);
        kept[index] = _assignWeight(kept[index], config, rng);
      }
      text = kept.join(', ');
    }
    return ExploreMutatedCandidate(
      text: text,
      operation: ExploreLineageOperation.mutation,
      parents: [parent],
    );
  }

  /// 单原子扰动：带权重的按概率重采样，无权重的按概率赋权。
  static String _perturbAtom(
    String atom,
    ExploreMutationConfig config,
    math.Random rng,
  ) {
    final match = _weightedAtom.firstMatch(atom);
    if (match != null) {
      if (rng.nextDouble() >= config.weightPerturbProbability) return atom;
      return _perturbWeightedAtom(match, config, rng);
    }
    if (rng.nextDouble() < config.assignWeightProbability) {
      return _assignWeight(atom, config, rng);
    }
    return atom;
  }

  /// 权重扰动：以父权重为众数 Split-Beta 重采样，区间 = 父权重 ± 幅度
  /// （截断到 weightMin/Max），0.1 离散化；原子内容原样保留。
  static String _perturbWeightedAtom(
    Match match,
    ExploreMutationConfig config,
    math.Random rng,
  ) {
    final parentWeight = double.parse(match.group(1)!);
    final content = match.group(2)!;
    final lo = math.max(
      config.weightMin,
      parentWeight - config.weightAmplitude,
    );
    final hi = math.min(
      config.weightMax,
      parentWeight + config.weightAmplitude,
    );
    final sampled = PillRollEngine.sampleSplitBetaWeight(
      PillInstanceSettings(
        weightEnabled: true,
        weightMin: lo,
        weightMax: hi,
        weightAverage: parentWeight.clamp(lo, hi).toDouble(),
        leftDispersion: config.dispersion,
        rightDispersion: config.dispersion,
      ),
      rng,
    );
    final w = PillRollEngine.discretizeWeight(sampled, lo, hi);
    return '${w.toStringAsFixed(1)}::$content::';
  }

  /// 给无权重原子赋随机权重（众数 = assignWeightMode）。
  static String _assignWeight(
    String atom,
    ExploreMutationConfig config,
    math.Random rng,
  ) {
    final sampled = PillRollEngine.sampleSplitBetaWeight(
      PillInstanceSettings(
        weightEnabled: true,
        weightMin: config.weightMin,
        weightMax: config.weightMax,
        weightAverage: config.assignWeightMode
            .clamp(config.weightMin, config.weightMax)
            .toDouble(),
        leftDispersion: config.dispersion,
        rightDispersion: config.dispersion,
      ),
      rng,
    );
    final w = PillRollEngine.discretizeWeight(
      sampled,
      config.weightMin,
      config.weightMax,
    );
    return '${w.toStringAsFixed(1)}::$atom::';
  }

  /// 两父本交叉：随机切点原子段互换（头A+尾B 或 头B+尾A，方向随机）；
  /// 单原子父本退化为合并洗牌。子代内相同原子去重（保序）。
  static ExploreMutatedCandidate _crossover(
    List<ExploreMutationParent> parents,
    Map<String, List<String>> parentAtoms,
    math.Random rng,
  ) {
    final first = _weightedParent(parents, rng);
    final second = _weightedParent(parents, rng, first.id);
    final atomsA = parentAtoms[first.id]!;
    final atomsB = parentAtoms[second.id]!;

    final List<String> child;
    if (atomsA.length >= 2 && atomsB.length >= 2) {
      final cutA = 1 + rng.nextInt(atomsA.length - 1);
      final cutB = 1 + rng.nextInt(atomsB.length - 1);
      child = rng.nextBool()
          ? [...atomsA.take(cutA), ...atomsB.skip(cutB)]
          : [...atomsB.take(cutB), ...atomsA.skip(cutA)];
    } else {
      child = [...atomsA, ...atomsB];
      for (var i = child.length - 1; i > 0; i--) {
        final j = rng.nextInt(i + 1);
        final tmp = child[i];
        child[i] = child[j];
        child[j] = tmp;
      }
    }

    final deduped = <String>[];
    final seenAtoms = <String>{};
    for (final atom in child) {
      if (seenAtoms.add(atom)) deduped.add(atom);
    }
    return ExploreMutatedCandidate(
      text: deduped.join(', '),
      operation: ExploreLineageOperation.crossover,
      parents: [first, second],
    );
  }

  /// 随机注入：父本原子 + 池中无放回抽 1~2 个新原子，随机位置插入。
  /// 池已被该父本覆盖时返回原文（去重层拒绝并重试）。
  static ExploreMutatedCandidate _inject(
    ExploreMutationParent parent,
    Map<String, List<String>> parentAtoms,
    List<String> pool,
    math.Random rng,
  ) {
    final atoms = List<String>.of(parentAtoms[parent.id]!);
    final available = [
      for (final atom in pool)
        if (!atoms.contains(atom)) atom,
    ];
    if (available.isEmpty) {
      return ExploreMutatedCandidate(
        text: parent.text,
        operation: ExploreLineageOperation.injection,
        parents: [parent],
      );
    }
    final drawCount = math.min(available.length, 1 + rng.nextInt(2));
    for (var i = 0; i < drawCount; i++) {
      final j = i + rng.nextInt(available.length - i);
      final tmp = available[i];
      available[i] = available[j];
      available[j] = tmp;
      atoms.insert(rng.nextInt(atoms.length + 1), available[i]);
    }
    return ExploreMutatedCandidate(
      text: atoms.join(', '),
      operation: ExploreLineageOperation.injection,
      parents: [parent],
    );
  }
}
