import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';

part 'tip_catalog.dart';

/// 小贴士类型：决定标签（提示 / 过来人说 / 狼说）。
enum TipKind {
  /// 正经教程：一句话讲清一个真实功能。
  guide,

  /// 幽默教学：功能是真的，包装是梗。
  trick,

  /// 狼的闲聊：不教东西，品牌角色 W.O.F（WolF）在说话。
  wolf,
}

/// 小贴士出现的位置；每个位置只从自己的池里抽。
enum TipSurface {
  /// 生成页空画布欢迎页（STUDIO），长段落。
  studio,

  /// 画风探索空候选区欢迎页（LAB），长段落。
  lab,

  /// 生成页主提示词框。
  prompt,

  /// 画风探索页提示词框。
  explorePrompt,

  /// 角色框正面输入区（≤ 3 行）。
  character,

  /// 本地画廊搜索框（短句）；挂载首轮固定出使用说明。
  gallerySearch(leadsWithGuide: true),

  /// 在线画廊标签搜索框（短句）；挂载首轮固定出使用说明。
  onlineSearch(leadsWithGuide: true),

  /// 块库搜索框（短句）。
  blockSearch,

  /// 生成中占位卡（一行，不带标签）。
  generating,

  /// 启动载入页进度条下方。
  splash;

  const TipSurface({this.leadsWithGuide = false});

  final bool leadsWithGuide;
}

class Tip {
  const Tip(this.kind, this._text, {this.short = false, this.night = false});

  const Tip.guide(String Function(AppLocalizations) text, {bool short = false})
    : this(TipKind.guide, text, short: short);

  const Tip.trick(String Function(AppLocalizations) text, {bool short = false})
    : this(TipKind.trick, text, short: short);

  const Tip.wolf(
    String Function(AppLocalizations) text, {
    bool short = false,
    bool night = false,
  }) : this(TipKind.wolf, text, short: short, night: night);

  final TipKind kind;
  final String Function(AppLocalizations) _text;

  /// 窄屏紧凑提示词框（72px）只抽短句。
  final bool short;

  /// 只在深夜出现。
  final bool night;

  String text(AppLocalizations l10n) => _text(l10n);

  String label(AppLocalizations l10n) => tipKindLabel(l10n, kind);

  /// 输入框占位用：带类型标签的一行。
  String hint(AppLocalizations l10n) => l10n.tips_hint(label(l10n), text(l10n));
}

/// 某个位置的全部小贴士（按登记顺序）。
List<Tip> tipsFor(TipSurface surface) => _tipCatalog[surface]!;

String tipKindLabel(AppLocalizations l10n, TipKind kind) => switch (kind) {
  TipKind.guide => l10n.tips_kind_guide,
  TipKind.trick => l10n.tips_kind_trick,
  TipKind.wolf => l10n.tips_kind_wolf,
};

/// 深夜：本地时间 01:00–04:59。
bool isTipNight(DateTime time) => time.hour >= 1 && time.hour < 5;

/// 洗牌牌组：每个位置在本次运行内有一个固定的随机顺序，
/// 按序号依次往下走，一轮放完才会重复。
class TipDeck {
  TipDeck({int? seed}) : seed = seed ?? Random().nextInt(1 << 30);

  final int seed;
  final Map<TipSurface, List<int>> _orders = {};
  final Map<TipSurface, int> _drawn = {};

  List<int> _order(TipSurface surface) => _orders.putIfAbsent(
    surface,
    () =>
        List<int>.generate(tipsFor(surface).length, (i) => i)
          ..shuffle(Random(seed + surface.index * 7919)),
  );

  /// 第 [index] 条可用小贴士；同一序号结果稳定。
  ///
  /// 白天跳过深夜条；[shortOnly] 只取短句；[kind] 只取某一类。
  Tip tipAt(
    TipSurface surface,
    int index, {
    DateTime? now,
    bool shortOnly = false,
    TipKind? kind,
  }) {
    final tips = tipsFor(surface);
    final night = isTipNight(now ?? DateTime.now());
    final eligible = [
      for (final i in _order(surface))
        if ((night || !tips[i].night) &&
            (!shortOnly || tips[i].short) &&
            (kind == null || tips[i].kind == kind))
          tips[i],
    ];
    final pool = eligible.isEmpty ? tips : eligible;
    return pool[index % pool.length];
  }

  /// 一次性位置（欢迎页、占位卡、启动页）每次露面取下一条。
  Tip draw(TipSurface surface, {DateTime? now}) {
    final index = _drawn[surface] ?? 0;
    _drawn[surface] = index + 1;
    return tipAt(surface, index, now: now);
  }
}

final tipDeckProvider = Provider<TipDeck>((ref) => TipDeck());

/// 启动页本次运行固定的一条。
final splashTipProvider = Provider<Tip>(
  (ref) => ref.read(tipDeckProvider).draw(TipSurface.splash),
);

/// 5 分钟轮播周期。
const Duration tipRotationInterval = Duration(minutes: 5);

/// 当前轮次：以 Unix 毫秒对轮播周期取整。
int currentTipEpoch([DateTime? now]) =>
    (now ?? DateTime.now()).millisecondsSinceEpoch ~/
    tipRotationInterval.inMilliseconds;

/// 全局 tip 轮次 provider：首次监听即产当前轮次，
/// 之后每 5 分钟 +1 驱动所有绑定框换下一条。
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

/// 便捷读取当前轮次（供绑定框 watch 用）：
/// provider 尚未产出时回落到按系统时间计算的轮次。
int watchTipEpoch(WidgetRef ref) =>
    ref.watch(tipEpochProvider).valueOrNull ?? currentTipEpoch();

/// 输入框轮播的那一条：同一轮次稳定，到点换下一条。
///
/// [slot] 让同屏的同类框（如多个角色框）错开；[firstEpoch] 为框挂载时的
/// 轮次，首轮固定出使用说明（[TipSurface.leadsWithGuide]）。
Tip rotatingTip(
  TipDeck deck,
  TipSurface surface, {
  required int epoch,
  int slot = 0,
  int? firstEpoch,
  bool shortOnly = false,
  DateTime? now,
}) {
  final leadGuide = surface.leadsWithGuide && epoch == firstEpoch;
  return deck.tipAt(
    surface,
    leadGuide ? slot : epoch + slot,
    now: now,
    shortOnly: shortOnly,
    kind: leadGuide ? TipKind.guide : null,
  );
}

/// 绑定框取占位文字（带类型标签）。
String watchTipHint(
  WidgetRef ref,
  AppLocalizations l10n,
  TipSurface surface, {
  int slot = 0,
  int? firstEpoch,
  bool shortOnly = false,
}) => rotatingTip(
  ref.watch(tipDeckProvider),
  surface,
  epoch: watchTipEpoch(ref),
  slot: slot,
  firstEpoch: firstEpoch,
  shortOnly: shortOnly,
).hint(l10n);
