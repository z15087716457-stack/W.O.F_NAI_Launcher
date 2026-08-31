import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'character_prompt_provider.dart';
import 'generation/generation_params_notifier.dart';
import 'pill_workspace_provider.dart';

/// 块实例随机的全局 roll 协调器（P2.5，roll 时机 4 = 每次生成入队后）。
///
/// 重 roll 所有活跃 lane 的随机实例，并把变化 lane 的新投影**主动推送**
/// 到外部汇点（生成参数/角色配置）——编辑器被 tab 切换卸载后 onChanged
/// 链断开，不推的话下一张生成会用陈旧提示词。推送目标内部
/// `syncFromPlainText(投影)` 与投影等价，天然无回环。
class PillRollCoordinator {
  const PillRollCoordinator(this._ref);

  final Ref _ref;

  /// 全部活跃 lane roll + 同步；没有任何随机实例时秒退（零开销）。
  ///
  /// 返回「本次 roll 出新投影」的 scope→投影表：生成批次循环直接取用，
  /// 绕开 updatePrompt 的 microtask 延迟（读完即重建参数，等不到下一拍）。
  Map<String, String> rollAllLanesAndSync() {
    final rolled = <String, String>{};
    // 快照一份再遍历：推送过程可能触发 forgetScope 改动注册表
    final scopes = PillWorkspaceNotifier.activeScopes.toList();
    for (final scope in scopes) {
      // 探索页 lane 与主生成无关：runner 自控 roll 节奏，这里无谓 roll
      // 只会打乱用户正在编辑的随机实例。
      if (scope.startsWith('explore:')) continue;
      final provider = pillWorkspaceProvider(scope);
      if (!_ref.exists(provider)) continue;
      final changed = _ref.read(provider.notifier).rollAllRandom();
      if (!changed) continue;
      final projection = _ref.read(provider).projection;
      rolled[scope] = projection;
      _syncLane(scope, projection);
    }
    return rolled;
  }

  void _syncLane(String scope, String projection) {
    if (scope == PillScopes.main) {
      _ref
          .read(generationParamsNotifierProvider.notifier)
          .updatePrompt(projection);
      return;
    }
    if (scope == PillScopes.negative) {
      _ref
          .read(generationParamsNotifierProvider.notifier)
          .updateNegativePrompt(projection);
      return;
    }
    final charMatch = RegExp(r'^char:(.+):(pos|neg)$').firstMatch(scope);
    if (charMatch == null) return;
    final id = charMatch.group(1)!;
    final isPositive = charMatch.group(2) == 'pos';
    final config = _ref.read(characterPromptNotifierProvider);
    for (final character in config.characters) {
      if (character.id != id) continue;
      final updated = isPositive
          ? character.copyWith(prompt: projection)
          : character.copyWith(negativePrompt: projection);
      _ref
          .read(characterPromptNotifierProvider.notifier)
          .updateCharacter(updated);
      return;
    }
    // 角色已删：lane 是残留（forgetScope 之外的路径），静默跳过
  }
}

final pillRollCoordinatorProvider = Provider<PillRollCoordinator>(
  (ref) => PillRollCoordinator(ref),
);
