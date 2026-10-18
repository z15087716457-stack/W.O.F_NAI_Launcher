import 'package:flutter/painting.dart';

import 'channel_contract.dart';
import 'channel_geometry.dart';

/// 每个主题的配色（原型 THEMES）：底色、线稿色、点缀色，各分浅色 / 深色；[swatch] 是设置卡片、
/// 刻度条、全局地图上的色块。底色只是很淡地染在画布底上，按段权重混进去。
class ChannelPalette {
  const ChannelPalette({
    required this.swatch,
    required this.bg,
    this.bg2,
    required this.ink,
    required this.accent,
    required this.code,
  });

  final Color swatch;
  final (Color, Color) bg;

  /// 段尾的底色（深海：越往下越深），null = 整段同一底色。
  final (Color, Color)? bg2;
  final (Color, Color) ink;
  final (Color, Color) accent;

  /// 装饰用的英文代号（像素字，不翻译）。
  final String code;

  Color bgOf(bool dark) => dark ? bg.$2 : bg.$1;
  Color inkOf(bool dark) => dark ? ink.$2 : ink.$1;
  Color accentOf(bool dark) => dark ? accent.$2 : accent.$1;

  static ChannelPalette of(ChannelTheme t) => switch (t) {
    ChannelTheme.circuit => const ChannelPalette(
      swatch: Color(0xFF3B82F6),
      bg: (Color(0xFFF7F9FC), Color(0xFF0D1217)),
      ink: (Color(0xFF3A506C), Color(0xFF8AAACE)),
      accent: (Color(0xFF0064E2), Color(0xFF50A8FF)),
      code: 'CIRCUIT',
    ),
    ChannelTheme.stars => const ChannelPalette(
      swatch: Color(0xFF6D5DFC),
      bg: (Color(0xFFF7F7FB), Color(0xFF0A0C15)),
      ink: (Color(0xFF2C345C), Color(0xFFC0CAF2)),
      accent: (Color(0xFFC47828), Color(0xFFFFD496)),
      code: 'ATLAS',
    ),
    ChannelTheme.herb => const ChannelPalette(
      swatch: Color(0xFF6B8A3A),
      bg: (Color(0xFFFBFAF3), Color(0xFF10110D)),
      ink: (Color(0xFF54603A), Color(0xFFACBE92)),
      accent: (Color(0xFFB25C4A), Color(0xFFE49882)),
      code: 'HERBARIUM',
    ),
    ChannelTheme.arcade => const ChannelPalette(
      swatch: Color(0xFFB07048),
      bg: (Color(0xFFF9F7F3), Color(0xFF0D1219)),
      ink: (Color(0xFF504A44), Color(0xFF96B4DA)),
      accent: (Color(0xFFBA5838), Color(0xFFF09870)),
      code: 'ARCADE',
    ),
    ChannelTheme.abyss => const ChannelPalette(
      swatch: Color(0xFF0E7490),
      bg: (Color(0xFFF3F8FA), Color(0xFF09131A)),
      bg2: (Color(0xFFE3EDF2), Color(0xFF03080C)),
      ink: (Color(0xFF225874), Color(0xFF6CBAD6)),
      accent: (Color(0xFF008AA0), Color(0xFF5AE6DC)),
      code: 'ABYSS',
    ),
    ChannelTheme.wave => const ChannelPalette(
      swatch: Color(0xFFD6452F),
      bg: (Color(0xFFF7F9FA), Color(0xFF0B0F13)),
      ink: (Color(0xFF244874), Color(0xFF80A6D0)),
      accent: (Color(0xFFD44632), Color(0xFFE8624C)),
      code: 'SEIGAIHA',
    ),
    ChannelTheme.caliber => const ChannelPalette(
      swatch: Color(0xFF57534E),
      bg: (Color(0xFFF8F7F5), Color(0xFF0F0F10)),
      ink: (Color(0xFF484644), Color(0xFFACA8A2)),
      accent: (Color(0xFFC81E46), Color(0xFFFF6080)),
      code: 'CALIBER',
    ),
    ChannelTheme.strata => const ChannelPalette(
      swatch: Color(0xFFCA8A04),
      bg: (Color(0xFFFBF8F1), Color(0xFF12100C)),
      bg2: (Color(0xFFEFE4CF), Color(0xFF090705)),
      ink: (Color(0xFF6E5432), Color(0xFFCCB288)),
      accent: (Color(0xFFC4601C), Color(0xFFF8A85C)),
      code: 'STRATA',
    ),
    ChannelTheme.metro => const ChannelPalette(
      swatch: Color(0xFF10B981),
      bg: (Color(0xFFF7FAF9), Color(0xFF0B100F)),
      ink: (Color(0xFF3C464C), Color(0xFF9CACB2)),
      accent: (Color(0xFF009C68), Color(0xFF34DEA0)),
      code: 'METRO',
    ),
    ChannelTheme.score => const ChannelPalette(
      swatch: Color(0xFFC026D3),
      bg: (Color(0xFFFBF9F5), Color(0xFF100E12)),
      ink: (Color(0xFF383040), Color(0xFFC4BAD0)),
      accent: (Color(0xFFA828BE), Color(0xFFE28CFF)),
      code: 'SCORE',
    ),
    ChannelTheme.luna => const ChannelPalette(
      swatch: Color(0xFF94A3B8),
      bg: (Color(0xFFF6F7FA), Color(0xFF0A0D14)),
      ink: (Color(0xFF3C4660), Color(0xFFB0BCD6)),
      accent: (Color(0xFFB28A28), Color(0xFFFAE296)),
      code: 'LUNA',
    ),
  };

  /// 画布底色：段内按权重从“无主题”混到主题底色（[base] = 生图页画布原本的底色）。
  static Color tint(
    ChannelEnv env,
    double y,
    Color base,
    bool dark,
    double level,
  ) {
    if (env.off) return base;
    final k = ChannelGeo.zoneOf(y);
    final p = of(env.themeOf(k));
    var c = p.bgOf(dark);
    if (p.bg2 case final b2?) {
      final f = ((y - ChannelGeo.zoneStart(k)) / ChannelGeo.zone).clamp(
        0.0,
        1.0,
      );
      c = lerpColor(c, dark ? b2.$2 : b2.$1, f);
    }
    return lerpColor(base, c, env.weight(k, y) * level.clamp(0.0, 1.0));
  }
}
