import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/prompt_block/pill_document.dart';
import '../../../data/models/style_explore/explore_run.dart';
import '../pill_workspace_provider.dart';
import '../prompt_block_library_provider.dart';

/// 抓 main/negative 双 lane 当前投影 + 启用随机实例的 roll 明细。
///
/// lane 合并后探索变量就是主 lane 的随机块实例：runner 批量生成与
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
      ..._laneInstanceRolls('pos', positive.document, library),
      ..._laneInstanceRolls('neg', negative.document, library),
    ],
  );
}

List<ExploreInstanceRoll> _laneInstanceRolls(
  String lane,
  PillDocument document,
  PromptBlockLibraryState? library,
) {
  return [
    for (final entry in document.instances.entries)
      if (entry.value.enabled && entry.value.settings.isRandom)
        ExploreInstanceRoll(
          lane: lane,
          marker: entry.key,
          blockId: entry.value.blockId,
          blockTitle: library?.blockById(entry.value.blockId)?.title ?? '',
          rolledText: entry.value.currentRoll ?? '',
        ),
  ];
}
