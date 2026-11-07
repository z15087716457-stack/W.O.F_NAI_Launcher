import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/prompt_block/pill_document.dart';
import '../providers/pill_workspace_provider.dart';
import '../providers/prompt_block_library_provider.dart';

/// 在当前光标处插入块。双面块的另一侧放入配对提示词框末尾。
/// 返回当前框光标应前进的字符数；一次用户操作只计一次使用次数。
int insertPromptBlockBundle(
  WidgetRef ref, {
  required String scope,
  required int offset,
  required String blockId,
  PillTempContent? temp,
}) => insertPromptBlockBundleWithReader(
  ref.read,
  scope: scope,
  offset: offset,
  blockId: blockId,
  temp: temp,
);

/// Shared insertion semantics for both widgets and the Agent provider binding.
int insertPromptBlockBundleWithReader(
  T Function<T>(ProviderListenable<T>) read, {
  required String scope,
  required int offset,
  required String blockId,
  PillTempContent? temp,
}) {
  final block = read(
    promptBlockLibraryNotifierProvider,
  ).valueOrNull?.blockById(blockId);
  final negative = temp != null
      ? temp.negativeContent?.isNotEmpty == true
      : block?.negativeContent.isNotEmpty == true;
  if (!negative) {
    read(
      pillWorkspaceProvider(scope).notifier,
    ).insertBlockAt(offset: offset, blockId: blockId, temp: temp);
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
    read(
      pillWorkspaceProvider(scope).notifier,
    ).insertBlockAt(offset: offset, blockId: blockId, temp: temp);
    return 1;
  }

  final hasPositive = (temp?.content ?? block!.content).isNotEmpty;
  final bundleId = const Uuid().v4();
  final rollScopeMask = hasPositive ? 1 : 2;
  final activePositive = scope == positiveScope;
  var counted = false;
  if (hasPositive) {
    final lane = pillWorkspaceProvider(positiveScope);
    final document = read(lane).document;
    read(lane.notifier).insertBlockAt(
      offset: activePositive ? offset : document.text.length,
      blockId: blockId,
      temp: temp,
      bundleId: bundleId,
      rollScopeMask: rollScopeMask,
    );
    counted = true;
  }
  final lane = pillWorkspaceProvider(negativeScope);
  final document = read(lane).document;
  read(lane.notifier).insertBlockAt(
    offset: activePositive ? document.text.length : offset,
    blockId: blockId,
    temp: temp,
    useNegativeContent: true,
    countUse: !counted,
    bundleId: bundleId,
    rollScopeMask: rollScopeMask,
  );
  return activePositive ? (hasPositive ? 1 : 0) : 1;
}
