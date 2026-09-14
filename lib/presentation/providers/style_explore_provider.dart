import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pill_workspace_provider.dart';

/// 载入快照/导入元数据前是否需要覆盖确认：
/// 主/负 lane 任一非空（内容未备份，覆盖即丢）→ 确认。
final styleExploreNeedsOverwriteConfirmProvider = Provider<bool>((ref) {
  final positive = ref.watch(pillWorkspaceProvider(PillScopes.main));
  final negative = ref.watch(pillWorkspaceProvider(PillScopes.negative));
  return positive.document.text.isNotEmpty ||
      positive.document.instances.isNotEmpty ||
      negative.document.text.isNotEmpty ||
      negative.document.instances.isNotEmpty;
});
