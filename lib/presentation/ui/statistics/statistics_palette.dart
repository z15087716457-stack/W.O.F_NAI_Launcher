import 'package:flutter/material.dart';

import '../kit/ui_colors.dart';
import 'statistics_contract.dart';
import 'statistics_derive.dart';

/// 统计页图表色。表面和强调色跟主题；模型系列等原型专用色按 HTML 原型取值。
class StatsPalette {
  StatsPalette._(this.c);
  factory StatsPalette.of(BuildContext context) => StatsPalette._(context.ui);

  final UiColors c;

  Color family(StatsFamily f) => switch (f) {
    StatsFamily.nai45 => c.accent,
    StatsFamily.nai5 =>
      c.dark ? const Color(0xFFB58BE0) : const Color(0xFF8E4EC6),
    StatsFamily.nai4 =>
      c.dark ? const Color(0xFF2FC4AD) : const Color(0xFF12A594),
    StatsFamily.nai3 =>
      c.dark ? const Color(0xFFF1A10D) : const Color(0xFFD48A00),
    StatsFamily.other =>
      c.dark ? const Color(0xFF6B6B6B) : const Color(0xFFA8A8A8),
    StatsFamily.noMetadata =>
      c.dark ? const Color(0xFF2C2C2C) : const Color(0xFFE3E3E3),
  };

  /// 日历 5 档：空、强调色 22% / 45% / 72% 混卡片底、强调色。
  List<Color> get heat => [
    c.dark ? const Color(0xFF1F1F1F) : const Color(0xFFEFEFEF),
    c.onCard(c.accent, .22),
    c.onCard(c.accent, .45),
    c.onCard(c.accent, .72),
    c.accent,
  ];

  /// 文件大小 5 档。
  List<Color> get sizeBuckets => [
    c.onCard(c.accent, .25),
    c.onCard(c.accent, .5),
    c.accent,
    family(StatsFamily.nai5),
    c.error,
  ];

  Color orientation(StatsOrientation o) => switch (o) {
    StatsOrientation.portrait => c.accent,
    StatsOrientation.landscape => c.onCard(c.accent, .5),
    StatsOrientation.square => c.strong,
  };
}
