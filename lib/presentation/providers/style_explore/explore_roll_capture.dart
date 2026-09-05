import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/pill_roll_engine.dart';
import '../../../data/models/prompt_block/pill_document.dart';
import '../../../data/models/style_explore/explore_run.dart';
import '../pill_workspace_provider.dart';
import '../prompt_block_library_provider.dart';

/// 解析深度轮 override 的目标遗传实例 marker（纯函数）：
/// 优先文档中与 [blockId] 相同的启用随机遗传实例（父本来源实例），
/// 找不到回退第一个启用随机遗传实例；都没有 → null（不允许深度轮）。
String? resolveExploreOverrideMarkerInDocument(
  PillDocument document, {
  String? blockId,
}) {
  String? first;
  for (final entry in document.instances.entries) {
    final instance = entry.value;
    if (!instance.enabled ||
        !instance.settings.isRandom ||
        !instance.evolutionEnabled) {
      continue;
    }
    first ??= entry.key;
    if (blockId != null && instance.blockId == blockId) return entry.key;
  }
  return first;
}

/// Ref 版 [resolveExploreOverrideMarkerInDocument]：读 main lane 当前文档。
String? resolveExploreOverrideMarker(Ref ref, {String? blockId}) {
  return resolveExploreOverrideMarkerInDocument(
    ref.read(pillWorkspaceProvider(PillScopes.main)).document,
    blockId: blockId,
  );
}

/// 提取候选的父本串（建家族/建分支用）：
/// 按快照中的实例顺序合并全部遗传随机实例的 rolledText；无有效串回退正向全文。
String exploreParentStringFor(ExploreCandidate candidate) {
  final snapshot = candidate.rollSnapshot;
  if (snapshot == null) return '';

  final atoms = <String>[];
  for (final instanceRoll in snapshot.instanceRolls) {
    final rolledText = instanceRoll.rolledText.trim();
    if (rolledText.isEmpty) continue;
    atoms.addAll(PillRollEngine.splitTopLevelAtoms(rolledText));
  }
  return atoms.isEmpty ? snapshot.positive : atoms.join(', ');
}

/// 解析父本集深度轮 override 的目标块 id：
/// 第一个带来源候选的父本，其 roll 快照第一个遗传实例的 blockId。
String? exploreTargetBlockIdForParentSet(
  ExploreRun run,
  ExploreParentSet parentSet,
) {
  for (final parent in parentSet.parents) {
    final sourceId = parent.sourceCandidateId;
    if (sourceId == null) continue;
    final rolls = run.candidateById(sourceId)?.rollSnapshot?.instanceRolls;
    if (rolls != null && rolls.isNotEmpty) return rolls.first.blockId;
  }
  return null;
}

/// 组装深度轮注入池：run 快照正向文档中遗传随机实例的块内容原子
/// （块内容按当前块库解析；池 = 顶层逗号切分后的原子集合，去重保序）。
List<String> buildExploreInjectionPool(Ref ref, ExploreRun run) {
  final library = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
  final pool = <String>[];
  final seen = <String>{};
  for (final instance in run.recipeSnapshot.positive.instances.values) {
    if (!instance.enabled ||
        !instance.settings.isRandom ||
        !instance.evolutionEnabled) {
      continue;
    }
    final content = library?.blockById(instance.blockId)?.content;
    if (content == null) continue;
    for (final atom in PillRollEngine.splitTopLevelAtoms(content)) {
      if (seen.add(atom)) pool.add(atom);
    }
  }
  return pool;
}

/// 抓 main/negative 双 lane 当前投影 + 启用随机遗传实例的 roll 明细。
///
/// lane 合并后探索变量就是主 lane 的随机遗传实例：runner 批量生成与
/// 探索页手动单张登记共用同一份抓取逻辑。投影是同步现值（roll 后
/// 立即可读，不经 generationParams 的 microtask 回写——红线）。
ExploreRollSnapshot captureExploreRollSnapshot(Ref ref) {
  final library = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
  final positive = ref.read(pillWorkspaceProvider(PillScopes.main));
  final negative = ref.read(pillWorkspaceProvider(PillScopes.negative));
  return ExploreRollSnapshot(
    positive: positive.projection,
    negative: negative.projection,
    instanceRolls: [
      ..._laneInstanceRolls(
        'pos',
        positive,
        ref.read(pillWorkspaceProvider(PillScopes.main).notifier),
        library,
      ),
      ..._laneInstanceRolls(
        'neg',
        negative,
        ref.read(pillWorkspaceProvider(PillScopes.negative).notifier),
        library,
      ),
    ],
  );
}

List<ExploreInstanceRoll> _laneInstanceRolls(
  String lane,
  PillWorkspaceState workspace,
  PillWorkspaceNotifier notifier,
  PromptBlockLibraryState? library,
) {
  return [
    for (final entry in workspace.document.instances.entries)
      if (entry.value.enabled &&
          entry.value.settings.isRandom &&
          entry.value.evolutionEnabled)
        ExploreInstanceRoll(
          lane: lane,
          marker: entry.key,
          blockId: entry.value.blockId,
          blockTitle: library?.blockById(entry.value.blockId)?.title ?? '',
          rolledText: notifier.effectiveRollFor(entry.key) ?? '',
        ),
  ];
}
