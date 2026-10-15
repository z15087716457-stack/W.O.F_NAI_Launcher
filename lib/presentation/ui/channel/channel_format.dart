import 'package:flutter/widgets.dart';

import '../../../core/utils/localization_extension.dart';
import 'channel_contract.dart';

abstract final class ChannelFormat {
  static String name(BuildContext context, ChannelTheme t) {
    final l = context.l10n;
    return switch (t) {
      ChannelTheme.circuit => l.channel_themeCircuit,
      ChannelTheme.stars => l.channel_themeStars,
      ChannelTheme.herb => l.channel_themeHerb,
      ChannelTheme.arcade => l.channel_themeArcade,
      ChannelTheme.abyss => l.channel_themeAbyss,
      ChannelTheme.wave => l.channel_themeWave,
    };
  }

  static Map<ChannelTheme, String> names(BuildContext context) => {
    for (final t in ChannelTheme.values) t: name(context, t),
  };

  /// “固定一个”时卡片下面的一句介绍。
  static String description(BuildContext context, ChannelTheme t) {
    final l = context.l10n;
    return switch (t) {
      ChannelTheme.circuit => l.channel_descCircuit,
      ChannelTheme.stars => l.channel_descStars,
      ChannelTheme.herb => l.channel_descHerb,
      ChannelTheme.arcade => l.channel_descArcade,
      ChannelTheme.abyss => l.channel_descAbyss,
      ChannelTheme.wave => l.channel_descWave,
    };
  }

  static String level(BuildContext context, ChannelLevel v) {
    final l = context.l10n;
    return switch (v) {
      ChannelLevel.soft => l.channel_levelSoft,
      ChannelLevel.standard => l.channel_levelStandard,
      ChannelLevel.strong => l.channel_levelStrong,
    };
  }

  static String mode(BuildContext context, ChannelMode v) {
    final l = context.l10n;
    return switch (v) {
      ChannelMode.off => l.channel_modeOff,
      ChannelMode.fixed => l.channel_modeFixed,
      ChannelMode.random => l.channel_modeRandom,
    };
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String clock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  static bool sameDay(DateTime a, DateTime b) => _day(a) == _day(b);

  /// 换日分隔线上的日期：“今天 · 10月14日 周二”“昨天 · …”“10月12日 周日”。
  static String day(BuildContext context, DateTime t, DateTime now) {
    final l = context.l10n;
    final weekday = switch (t.weekday) {
      DateTime.monday => l.channel_weekday1,
      DateTime.tuesday => l.channel_weekday2,
      DateTime.wednesday => l.channel_weekday3,
      DateTime.thursday => l.channel_weekday4,
      DateTime.friday => l.channel_weekday5,
      DateTime.saturday => l.channel_weekday6,
      _ => l.channel_weekday7,
    };
    final date = l.channel_monthDayWeek(t.month, t.day, weekday);
    final diff = _day(now).difference(_day(t)).inDays;
    return switch (diff) {
      0 => l.channel_dayToday(date),
      1 => l.channel_dayYesterday(date),
      _ => date,
    };
  }

  /// 每批左上角：“23:10 · 1 张”，最新一批加“· 最新”，生成中写“生成中 · 4 张”。
  static String? batch(
    BuildContext context,
    ChannelBatch b, {
    required bool newest,
  }) {
    final l = context.l10n;
    if (b.pending) return l.channel_batchPending(b.count);
    final t = b.time;
    if (t == null) return null;
    return newest
        ? l.channel_batchNewest(clock(t), b.count)
        : l.channel_batch(clock(t), b.count);
  }
}
