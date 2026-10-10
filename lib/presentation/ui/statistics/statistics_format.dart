import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';

/// 统计页的数字和日期写法。数字统一千分位（各语言一致），日期跟随界面语言。
abstract final class StatsFormat {
  static final _int = NumberFormat('#,##0', 'en_US');

  static String count(num n) => _int.format(n.round());

  /// 百分比；分母为 0 时 0%。
  static String percent(num a, num b, [int digits = 0]) =>
      b == 0 ? '0%' : '${(a / b * 100).toStringAsFixed(digits)}%';

  /// 字节 → (数字, 单位)。≥ 1 GB 用 GB 一位小数，否则 MB 取整。
  static (String, String) bytes(int b) {
    const gb = 1024 * 1024 * 1024, mb = 1024 * 1024;
    if (b >= gb) return ((b / gb).toStringAsFixed(1), 'GB');
    return ((b / mb).toStringAsFixed(b < 10 * mb && b > 0 ? 1 : 0), 'MB');
  }

  static String bytesText(int b) {
    final (v, u) = bytes(b);
    return '$v $u';
  }

  /// 平均文件大小，MB 一位小数。
  static String averageMb(int bytes, int files) =>
      '${(files == 0 ? 0 : bytes / files / 1048576).toStringAsFixed(1)} MB';

  /// 去掉多余小数：5.0 → 5，5.50 → 5.5。
  static String trim(num v) {
    final s = v.toStringAsFixed(2);
    return s.contains('.')
        ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
        : s;
  }

  /// 纵轴刻度：≥ 1000 写成 k。
  static String axis(num v) => v >= 1000 ? '${trim(v / 1000)}k' : trim(v);

  static String sampler(String id) => Samplers.samplerDisplayNames[id] ?? id;

  static String _locale(BuildContext context) =>
      Localizations.localeOf(context).toString();

  /// 周几，短名（周五 / Fri / 金 / 금）。
  static String weekday(BuildContext context, int weekday) =>
      DateFormat.E(_locale(context)).format(DateTime(2024, 1, weekday));

  /// 周几，单字（一 / M / 月 / 월），用于日历和点阵左侧。
  static String weekdayNarrow(BuildContext context, int weekday) =>
      DateFormat.EEEEE(_locale(context)).format(DateTime(2024, 1, weekday));

  static String month(BuildContext context, DateTime d) =>
      DateFormat.MMM(_locale(context)).format(d);

  static String monthDay(BuildContext context, DateTime d) =>
      DateFormat.Md(_locale(context)).format(d);

  static String yearMonth(BuildContext context, DateTime d) =>
      DateFormat.yMMM(_locale(context)).format(d);

  static String fullDate(BuildContext context, DateTime d) =>
      DateFormat.yMMMEd(_locale(context)).format(d);

  static String longDate(BuildContext context, DateTime d) =>
      DateFormat.yMd(_locale(context)).format(d);

  static String time(DateTime d) => DateFormat('HH:mm').format(d);
}

/// 把带一个占位的整句拆成三段，中间那段加粗。
/// 例：`richParts((v) => l10n.stats_imagesCount(v), '2,345')` → `['', '2,345', ' 张']`。
List<String> richParts(
  String Function(String placeholder) template,
  String value,
) {
  const mark = '\u0000';
  final parts = template(mark).split(mark);
  return [
    parts.first,
    value,
    parts.length > 1 ? parts.sublist(1).join(value) : '',
  ];
}
