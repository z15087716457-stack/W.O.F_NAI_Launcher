import 'package:flutter/foundation.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../providers/tips_provider.dart' show isTipNight;

typedef _Copy = String Function(AppLocalizations l10n);
typedef _CountedCopy = String Function(AppLocalizations l10n, int count);

/// 生成按钮文案池（文案在 ARB，随界面语言切换；繁体由简体自动生成）
///
/// 文案由 [pick] 用确定性种子选取：数量变化或一次生成结束时
/// 外层推进种子，按钮即换上新文案；同一种子在 build 间结果稳定。
/// 约 75% 种子显示官方式 [normal]；约 25% 进彩蛋：其中 seed % 20 == 0
/// （约 5%）出稀有句，深夜再分出一部分夜间句，其余先看特殊数字再按张数分档。
class GenerateButtonCopy {
  GenerateButtonCopy._();

  /// 彩蛋命中步长：seed % 4 == 0 → 约 25%
  static const int _funnyModulo = 4;

  /// 稀有句命中步长：seed % 20 == 0 → 约 5%
  static const int _rareModulo = 20;

  /// 深夜时 seed % 8 == 0（且非稀有）出夜间句
  static const int _nightModulo = 8;

  /// 按种子与总张数挑选一条文案。
  ///
  /// [count] 是最终生成总张数（请求次数 × 每次张数）。
  static String pick({
    required AppLocalizations l10n,
    required int seed,
    required int count,
    DateTime? now,
  }) {
    if (seed % _funnyModulo != 0) return normal(l10n, count);
    final step = seed ~/ _funnyModulo;
    if (seed % _rareModulo == 0) return _rare[step % _rare.length](l10n);
    if (seed % _nightModulo == 0 && isTipNight(now ?? DateTime.now())) {
      return _night[step % _night.length](l10n);
    }
    final special = _special[count];
    if (special != null) return special(l10n, count);
    if (count <= 1) return _one[step % _one.length](l10n);
    final pool = _poolFor(count);
    return pool[step % pool.length](l10n, count);
  }

  /// 官方式默认文案（约 75% 显示）。
  static String normal(AppLocalizations l10n, int count) =>
      l10n.genButton_normal(count);

  /// 常规分档：1 张单独一池，2–4、5–9、10–49、50+ 各一池。
  static List<_CountedCopy> _poolFor(int count) => count <= 4
      ? _few
      : count <= 9
      ? _batch
      : count < 50
      ? _many
      : _huge;

  /// 供测试读取某个张数的常规分档池。
  @visibleForTesting
  static List<String> debugPoolFor(AppLocalizations l10n, int count) =>
      count <= 1
      ? [for (final copy in _one) copy(l10n)]
      : [for (final copy in _poolFor(count)) copy(l10n, count)];

  /// 供测试读取稀有池与夜间池。
  @visibleForTesting
  static List<String> debugRarePool(AppLocalizations l10n) => [
    for (final copy in _rare) copy(l10n),
  ];

  @visibleForTesting
  static List<String> debugNightPool(AppLocalizations l10n) => [
    for (final copy in _night) copy(l10n),
  ];

  static final List<_Copy> _one = [
    (l) => l.genButton_one_1,
    (l) => l.genButton_one_2,
    (l) => l.genButton_one_3,
    (l) => l.genButton_one_4,
    (l) => l.genButton_one_5,
    (l) => l.genButton_one_6,
    (l) => l.genButton_one_7,
    (l) => l.genButton_one_8,
    (l) => l.genButton_one_9,
    (l) => l.genButton_one_10,
    (l) => l.genButton_one_11,
    (l) => l.genButton_one_12,
  ];
  static final List<_CountedCopy> _few = [
    (l, n) => l.genButton_few_1(n),
    (l, n) => l.genButton_few_2(n),
    (l, n) => l.genButton_few_3(n),
    (l, n) => l.genButton_few_4(n),
    (l, n) => l.genButton_few_5(n),
    (l, n) => l.genButton_few_6(n),
    (l, n) => l.genButton_few_7(n),
    (l, n) => l.genButton_few_8(n),
  ];
  static final List<_CountedCopy> _batch = [
    (l, n) => l.genButton_batch_1(n),
    (l, n) => l.genButton_batch_2(n),
    (l, n) => l.genButton_batch_3(n),
    (l, n) => l.genButton_batch_4(n),
    (l, n) => l.genButton_batch_5(n),
    (l, n) => l.genButton_batch_6(n),
    (l, n) => l.genButton_batch_7(n),
    (l, n) => l.genButton_batch_8(n),
  ];
  static final List<_CountedCopy> _many = [
    (l, n) => l.genButton_many_1(n),
    (l, n) => l.genButton_many_2(n),
    (l, n) => l.genButton_many_3(n),
    (l, n) => l.genButton_many_4(n),
    (l, n) => l.genButton_many_5(n),
    (l, n) => l.genButton_many_6(n),
    (l, n) => l.genButton_many_7(n),
    (l, n) => l.genButton_many_8(n),
  ];
  static final List<_CountedCopy> _huge = [
    (l, n) => l.genButton_huge_1(n),
    (l, n) => l.genButton_huge_2(n),
    (l, n) => l.genButton_huge_3(n),
    (l, n) => l.genButton_huge_4(n),
    (l, n) => l.genButton_huge_5(n),
    (l, n) => l.genButton_huge_6(n),
    (l, n) => l.genButton_huge_7(n),
    (l, n) => l.genButton_huge_8(n),
  ];
  static final List<_Copy> _rare = [
    (l) => l.genButton_rare_1,
    (l) => l.genButton_rare_2,
    (l) => l.genButton_rare_3,
    (l) => l.genButton_rare_4,
    (l) => l.genButton_rare_5,
    (l) => l.genButton_rare_6,
    (l) => l.genButton_rare_7,
    (l) => l.genButton_rare_8,
    (l) => l.genButton_rare_9,
    (l) => l.genButton_rare_10,
  ];
  static final List<_Copy> _night = [
    (l) => l.genButton_night_1,
    (l) => l.genButton_night_2,
    (l) => l.genButton_night_3,
    (l) => l.genButton_night_4,
  ];

  static final Map<int, _CountedCopy> _special = {
    7: (l, n) => l.genButton_special_7(n),
    9: (l, n) => l.genButton_special_9(n),
    42: (l, n) => l.genButton_special_42(n),
    99: (l, n) => l.genButton_special_99(n),
    100: (l, n) => l.genButton_special_100(n),
  };
}
