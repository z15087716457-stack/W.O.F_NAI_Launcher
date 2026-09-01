import 'package:flutter/foundation.dart';
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
///
/// **抑制**：探索 run 批量生成期间 runner 独占 roll 时机（每张 roll 时机
/// 与快照/发送严格对齐），主生成/桥接等外部路径的入队 roll 全部挂起，
/// 防止药丸显示的 currentRoll 被刷成与本张快照无关的值。计数式挂起/
/// 恢复配对使用。
class PillRollCoordinator {
  const PillRollCoordinator(this._ref);

  final Ref _ref;

  /// 抑制计数（>0 时 rollAllLanesAndSync 秒退）。
  static int _suppressCount = 0;

  /// 当前是否处于抑制期（测试与调试可读）。
  static bool get isRollSuppressed => _suppressCount > 0;

  /// 挂起全局 roll（与 [releaseRollSuppression] 配对）。
  static void suppressRoll() => _suppressCount++;

  /// 恢复全局 roll；计数有下限保护，重复调用安全。
  static void releaseRollSuppression() {
    if (_suppressCount > 0) _suppressCount--;
  }

  /// 测试专用：强制清零抑制计数（用例间隔离）。
  @visibleForTesting
  static void resetRollSuppression() => _suppressCount = 0;

  /// 全部活跃 lane roll + 同步；没有任何随机实例时秒退（零开销）。
  /// 抑制期（探索 run 批量生成中）整体秒退：roll 时机归探索 runner 独占。
  ///
  /// 返回「本次 roll 出新投影」的 scope→投影表：生成批次循环直接取用，
  /// 绕开 updatePrompt 的 microtask 延迟（读完即重建参数，等不到下一拍）。
  Map<String, String> rollAllLanesAndSync() {
    if (isRollSuppressed) return const {};
    final rolled = <String, String>{};
    // 快照一份再遍历：推送过程可能触发 forgetScope 改动注册表
    final scopes = PillWorkspaceNotifier.activeScopes.toList();
    for (final scope in scopes) {
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
