import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';

/// 占位符 TIPS 系统（FEAT-60）：空输入框 hint 轮播小贴士。
///
/// 池按模块双带（teach 教学 / fun 主题杂谈）+ 通用兜底（gen/fun），
/// 绑定「废话型」占位符的输入框按模块取词，全局 5 分钟统一切换。
enum TipModule {
  /// 生图页主提示词框（探索页以外的 PromptInputWidget 宿主）。
  gen(teachRatio: 0.5, moduleFunRatio: 0.5),

  /// 画风探索页提示词框：重输入区，教学压到 25%，
  /// 省出的配额给模块专属「遗传」主题杂谈。
  explore(teachRatio: 0.25, moduleFunRatio: 0.25),

  /// 画廊系搜索框（本地画廊 + 在线画廊标签搜索）。
  gallerySearch(teachRatio: 0.5, moduleFunRatio: 0.5),

  /// 块库搜索框（生图页面板 + 管理页 + 选择弹窗共用）。
  blockLibrary(teachRatio: 0.5, moduleFunRatio: 0.5);

  const TipModule({required this.teachRatio, required this.moduleFunRatio});

  /// 教学池抽取权重。
  final double teachRatio;

  /// 模块专属杂谈池抽取权重；该池为空时权重让渡给通用池。
  final double moduleFunRatio;
}

/// 5 分钟轮播周期。
const Duration tipRotationInterval = Duration(minutes: 5);

/// 当前轮次：以 Unix 毫秒对轮播周期取整。
int currentTipEpoch([DateTime? now]) =>
    (now ?? DateTime.now()).millisecondsSinceEpoch ~/
    tipRotationInterval.inMilliseconds;

/// 全局 tip 轮次 provider：首次监听即产当前轮次，
/// 之后每 5 分钟 +1 驱动所有绑定框重抽。
final tipEpochProvider = StreamProvider<int>((ref) {
  return Stream.multi((controller) {
    controller.add(currentTipEpoch());
    final timer = Timer.periodic(
      tipRotationInterval,
      (_) => controller.add(currentTipEpoch()),
    );
    controller.onCancel = timer.cancel;
  });
});

class _ModulePools {
  const _ModulePools({
    required this.teach,
    required this.fun,
    this.start,
  });

  final List<String> Function(AppLocalizations) teach;
  final List<String> Function(AppLocalizations) fun;

  /// 首次打开启动池：非空时第一轮固定从这里抽
  /// （静定：画廊搜索首条永远是使用说明）。
  final List<String> Function(AppLocalizations)? start;
}

final Map<TipModule, _ModulePools> _modulePools = {
  TipModule.gen: _ModulePools(
    teach: (l10n) => [
      l10n.tips_gen_teach_1,
      l10n.tips_gen_teach_2,
      l10n.tips_gen_teach_3,
      l10n.tips_gen_teach_4,
      l10n.tips_gen_teach_5,
    ],
    fun: (l10n) => [
      l10n.tips_gen_fun_1,
      l10n.tips_gen_fun_2,
      l10n.tips_gen_fun_3,
      l10n.tips_gen_fun_4,
      l10n.tips_gen_fun_5,
    ],
  ),
  TipModule.explore: _ModulePools(
    teach: (l10n) => [
      l10n.tips_explore_teach_1,
      l10n.tips_explore_teach_2,
      l10n.tips_explore_teach_3,
      l10n.tips_explore_teach_4,
      l10n.tips_explore_teach_5,
    ],
    fun: (l10n) => [
      l10n.tips_explore_fun_1,
      l10n.tips_explore_fun_2,
      l10n.tips_explore_fun_3,
      l10n.tips_explore_fun_4,
      l10n.tips_explore_fun_5,
    ],
  ),
  TipModule.gallerySearch: _ModulePools(
    start: (l10n) => [
      l10n.tips_gallerySearch_start_1,
      l10n.tips_gallerySearch_start_2,
      l10n.tips_gallerySearch_start_3,
      l10n.tips_gallerySearch_start_4,
      l10n.tips_gallerySearch_start_5,
      l10n.tips_gallerySearch_start_6,
      l10n.tips_gallerySearch_start_7,
      l10n.tips_gallerySearch_start_8,
      l10n.tips_gallerySearch_start_9,
      l10n.tips_gallerySearch_start_10,
    ],
    teach: (l10n) => [
      l10n.tips_gallerySearch_teach_1,
      l10n.tips_gallerySearch_teach_2,
      l10n.tips_gallerySearch_teach_3,
      l10n.tips_gallerySearch_teach_4,
      l10n.tips_gallerySearch_teach_5,
    ],
    fun: (l10n) => [
      l10n.tips_gallerySearch_fun_1,
      l10n.tips_gallerySearch_fun_2,
      l10n.tips_gallerySearch_fun_3,
      l10n.tips_gallerySearch_fun_4,
      l10n.tips_gallerySearch_fun_5,
    ],
  ),
  TipModule.blockLibrary: _ModulePools(
    teach: (l10n) => [
      l10n.tips_blocklib_teach_1,
      l10n.tips_blocklib_teach_2,
      l10n.tips_blocklib_teach_3,
      l10n.tips_blocklib_teach_4,
      l10n.tips_blocklib_teach_5,
    ],
    fun: (l10n) => [
      l10n.tips_blocklib_fun_1,
      l10n.tips_blocklib_fun_2,
      l10n.tips_blocklib_fun_3,
      l10n.tips_blocklib_fun_4,
      l10n.tips_blocklib_fun_5,
    ],
  ),
};

List<String> _genericPool(AppLocalizations l10n) => [
      l10n.tips_gen_1,
      l10n.tips_gen_2,
      l10n.tips_gen_3,
      l10n.tips_gen_4,
      l10n.tips_gen_5,
      l10n.tips_fun_1,
      l10n.tips_fun_2,
      l10n.tips_fun_3,
      l10n.tips_fun_4,
      l10n.tips_fun_5,
    ];

/// 按模块配比抽取一条 tip 正文（不含 `Tip: ` 前缀）。
///
/// [epoch] 传入轮次号使同轮内结果稳定；同一 epoch 内
/// 不同模块通过 [module] 掺入种子错开抽取。
/// [firstEpoch] 传入绑定框的挂载轮次：`epoch == firstEpoch` 且模块
/// 有启动池时固定抽使用说明句（静定：首句永远是用法）。
String pickTip(
  AppLocalizations l10n,
  TipModule module, {
  int? epoch,
  int? firstEpoch,
  Random? random,
}) {
  final pools = _modulePools[module]!;
  final resolvedEpoch = epoch ?? currentTipEpoch();

  final rng = random ?? Random(resolvedEpoch * 31 + module.index * 7919);

  // 挂载首轮：有启动池的模块固定从使用说明句抽（静定）。
  if (firstEpoch != null &&
      resolvedEpoch == firstEpoch &&
      pools.start != null) {
    final start = pools.start!(l10n).where((e) => e.isNotEmpty).toList();
    if (start.isNotEmpty) return start[rng.nextInt(start.length)];
  }

  final teach = pools.teach(l10n).where((e) => e.isNotEmpty).toList();
  final fun = pools.fun(l10n).where((e) => e.isNotEmpty).toList();
  final generic = _genericPool(l10n).where((e) => e.isNotEmpty).toList();

  final candidates = <List<String>, double>{};
  if (teach.isNotEmpty) candidates[teach] = module.teachRatio;
  if (fun.isNotEmpty) candidates[fun] = module.moduleFunRatio;
  if (generic.isNotEmpty) {
    candidates[generic] = 1 - candidates.values.fold(0.0, (a, b) => a + b);
  }
  if (candidates.isEmpty) return '';

  var roll = rng.nextDouble();
  var selected = candidates.keys.last;
  for (final entry in candidates.entries) {
    roll -= entry.value;
    if (roll < 0) {
      selected = entry.key;
      break;
    }
  }
  return selected[rng.nextInt(selected.length)];
}

/// 绑定框取 hint：统一 `Tip: ` 前缀。
String tipHint(
  AppLocalizations l10n,
  TipModule module, {
  int? epoch,
  int? firstEpoch,
  Random? random,
}) {
  final tip = pickTip(
    l10n,
    module,
    epoch: epoch,
    firstEpoch: firstEpoch,
    random: random,
  );
  return tip.isEmpty ? tip : 'Tip: $tip';
}

/// 便捷读取当前轮次（供绑定框 watch 用）：
/// provider 尚未产出时回落到按系统时间计算的轮次。
int watchTipEpoch(WidgetRef ref) =>
    ref.watch(tipEpochProvider).valueOrNull ?? currentTipEpoch();
