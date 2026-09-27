import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../providers/pill_workspace_provider.dart';
import '../providers/prompt_block_library_provider.dart';

/// 在当前光标处插入块。双面块的另一侧放入配对提示词框末尾。
/// 返回当前框光标应前进的字符数；一次用户操作只计一次使用次数。
int insertPromptBlockBundle(
  WidgetRef ref, {
  required String scope,
  required int offset,
  required String blockId,
}) {
  final block = ref
      .read(promptBlockLibraryNotifierProvider)
      .valueOrNull
      ?.blockById(blockId);
  final negative = block?.negativeContent.isNotEmpty == true;
  if (!negative) {
    ref
        .read(pillWorkspaceProvider(scope).notifier)
        .insertBlockAt(offset: offset, blockId: blockId);
    return 1;
  }

  String? positiveScope;
  String? negativeScope;
  if (scope == PillScopes.main || scope == PillScopes.negative) {
    positiveScope = PillScopes.main;
    negativeScope = PillScopes.negative;
  } else {
    final match = RegExp(r'^char:(.+):(pos|neg)$').firstMatch(scope);
    if (match != null) {
      final characterId = match.group(1)!;
      positiveScope = PillScopes.charPos(characterId);
      negativeScope = PillScopes.charNeg(characterId);
    }
  }
  if (positiveScope == null || negativeScope == null) {
    ref
        .read(pillWorkspaceProvider(scope).notifier)
        .insertBlockAt(offset: offset, blockId: blockId);
    return 1;
  }

  final hasPositive = block!.content.isNotEmpty;
  final bundleId = const Uuid().v4();
  final rollScopeMask = hasPositive ? 1 : 2;
  final activePositive = scope == positiveScope;
  var counted = false;
  if (hasPositive) {
    final lane = pillWorkspaceProvider(positiveScope);
    final document = ref.read(lane).document;
    ref
        .read(lane.notifier)
        .insertBlockAt(
          offset: activePositive ? offset : document.text.length,
          blockId: blockId,
          bundleId: bundleId,
          rollScopeMask: rollScopeMask,
        );
    counted = true;
  }
  final lane = pillWorkspaceProvider(negativeScope);
  final document = ref.read(lane).document;
  ref
      .read(lane.notifier)
      .insertBlockAt(
        offset: activePositive ? document.text.length : offset,
        blockId: blockId,
        useNegativeContent: true,
        countUse: !counted,
        bundleId: bundleId,
        rollScopeMask: rollScopeMask,
      );
  return activePositive ? (hasPositive ? 1 : 0) : 1;
}
