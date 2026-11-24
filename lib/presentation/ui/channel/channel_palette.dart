import 'package:flutter/painting.dart';

import 'channel_contract.dart';
import 'channel_geometry.dart';

/// 每个字符艺术主题的配色基调（浅色 / 深色）：
/// 底色用于段间渐变过渡与图片光台融合，[swatch] 是设置卡片、全局地图上的色块。
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

  /// 段尾/深处的第二底色，null = 整段同一底色。
  final (Color, Color)? bg2;
  final (Color, Color) ink;
  final (Color, Color) accent;

  /// 装饰用的英文代号（像素字，不翻译）。
  final String code;

  Color bgOf(bool dark) => dark ? bg.$2 : bg.$1;
  Color inkOf(bool dark) => dark ? ink.$2 : ink.$1;
  Color accentOf(bool dark) => dark ? accent.$2 : accent.$1;

  static ChannelPalette of(ChannelTheme t) => switch (t) {
    ChannelTheme.pelagic => const ChannelPalette(
      swatch: Color(0xFF38BDF8),
      bg: (Color(0xFFF3F8FD), Color(0xFF06101C)),
      bg2: (Color(0xFFE5EFF8), Color(0xFF03070F)),
      ink: (Color(0xFF1A527A), Color(0xFF72D6F4)),
      accent: (Color(0xFF0E7490), Color(0xFF67E8F9)),
      code: 'PELAGIC',
    ),
    ChannelTheme.nimbus => const ChannelPalette(
      swatch: Color(0xFFF472B6),
      bg: (Color(0xFFF4EFF8), Color(0xFF0F132A)),
      bg2: (Color(0xFFFCEFE8), Color(0xFF2B1B3B)),
      ink: (Color(0xFF6B3F7A), Color(0xFFF5B8CC)),
      accent: (Color(0xFFD97757), Color(0xFFFDE68A)),
      code: 'NIMBUS',
    ),
    ChannelTheme.cumulus => const ChannelPalette(
      swatch: Color(0xFF2563EB),
      bg: (Color(0xFF2A6BE4), Color(0xFF123482)),
      bg2: (Color(0xFF8EC0FB), Color(0xFF2A62C8)),
      ink: (Color(0xFFFFFFFF), Color(0xFFEAF4FF)),
      accent: (Color(0xFF1D4ED8), Color(0xFF93C5FD)),
      code: 'CUMULUS',
    ),
    ChannelTheme.aurora => const ChannelPalette(
      swatch: Color(0xFF34D399),
      bg: (Color(0xFFDCECF9), Color(0xFF061322)),
      bg2: (Color(0xFFC7E0F6), Color(0xFF0C2036)),
      ink: (Color(0xFF0F5E6B), Color(0xFF7AFAD0)),
      accent: (Color(0xFF6D28D9), Color(0xFFB484FF)),
      code: 'AURORA',
    ),
    ChannelTheme.strata => const ChannelPalette(
      swatch: Color(0xFF2DD4BF),
      bg: (Color(0xFFF4F6F1), Color(0xFF040D11)),
      bg2: (Color(0xFFE7ECE2), Color(0xFF03070A)),
      ink: (Color(0xFF145C56), Color(0xFF5EEAD4)),
      accent: (Color(0xFFC2410C), Color(0xFFFEF08A)),
      code: 'STRATA',
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
