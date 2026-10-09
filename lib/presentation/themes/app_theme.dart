import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/font_provider.dart';
import 'studio_typography.dart';

// Legacy presets remain readable without reordering their stored indices.
import 'presets/bold_retro_theme.dart';
import 'presets/grunge_collage_theme.dart';
import 'presets/fluid_saturated_theme.dart';
import 'presets/material_you_theme.dart';
import 'presets/flat_design_theme.dart';
import 'presets/hand_drawn_theme.dart';
import 'presets/midnight_editorial_theme.dart';
import 'presets/zen_minimalist_theme.dart';
import 'presets/minimal_glass_theme.dart';
import 'presets/neo_dark_theme.dart';
import 'presets/pro_ai_theme.dart';
import 'presets/social_theme.dart';
import 'presets/retro_wave_theme.dart';
import 'presets/brutalist_theme.dart';
import 'presets/apple_light_theme.dart';
import 'presets/system_theme.dart';
import 'presets/geist_theme.dart';
import 'theme_extension.dart';

/// 历史风格索引与当前 Geist 主题。应用只暴露 Geist 深浅选择。
enum AppStyle {
  // 8 套新设计主题
  grungeCollage, // 拼贴朋克（历史默认）
  boldRetro, // 复古现代主义
  fluidSaturated, // 流体饱和
  materialYou, // Material You
  flatDesign, // 扁平设计
  handDrawn, // 手绘风格
  midnightEditorial, // 午夜编辑
  zenMinimalist, // 禅意极简
  // 8 套重构主题 (原 styles/ 目录)
  minimalGlass, // 原 herdingStyle - 金黄深青
  neoDark, // 原 linearStyle - Linear 风格
  proAi, // 原 invokeStyle - InvokeAI 风格
  social, // 原 discordStyle - Discord 风格
  retroWave, // 原 cassetteFuturism - 复古未来
  brutalist, // 原 motorolaFixBeeper - LCD 电子
  appleLight, // 原 pureLight - 纯净白
  system, // 跟随系统
  geist, // Studio 深浅主题。仅追加，保持历史存储索引稳定。
}

extension AppStyleExtension on AppStyle {
  /// 主题元数据映射
  static final _metadata = <AppStyle, _ThemeMetadata>{
    AppStyle.geist: const _ThemeMetadata('Geist', '中性黑白灰与品牌蓝', true),
    AppStyle.boldRetro: _ThemeMetadata(
      BoldRetroTheme.displayName,
      BoldRetroTheme.description,
      BoldRetroTheme.supportsDarkMode,
    ),
    AppStyle.grungeCollage: _ThemeMetadata(
      GrungeCollageTheme.displayName,
      GrungeCollageTheme.description,
      GrungeCollageTheme.supportsDarkMode,
    ),
    AppStyle.fluidSaturated: _ThemeMetadata(
      FluidSaturatedTheme.displayName,
      FluidSaturatedTheme.description,
      FluidSaturatedTheme.supportsDarkMode,
    ),
    AppStyle.materialYou: _ThemeMetadata(
      MaterialYouTheme.displayName,
      MaterialYouTheme.description,
      MaterialYouTheme.supportsDarkMode,
    ),
    AppStyle.flatDesign: _ThemeMetadata(
      FlatDesignTheme.displayName,
      FlatDesignTheme.description,
      FlatDesignTheme.supportsDarkMode,
    ),
    AppStyle.handDrawn: _ThemeMetadata(
      HandDrawnTheme.displayName,
      HandDrawnTheme.description,
      HandDrawnTheme.supportsDarkMode,
    ),
    AppStyle.midnightEditorial: _ThemeMetadata(
      MidnightEditorialTheme.displayName,
      MidnightEditorialTheme.description,
      MidnightEditorialTheme.supportsDarkMode,
    ),
    AppStyle.zenMinimalist: _ThemeMetadata(
      ZenMinimalistTheme.displayName,
      ZenMinimalistTheme.description,
      ZenMinimalistTheme.supportsDarkMode,
    ),
    AppStyle.minimalGlass: _ThemeMetadata(
      MinimalGlassTheme.displayName,
      MinimalGlassTheme.description,
      MinimalGlassTheme.supportsDarkMode,
    ),
    AppStyle.neoDark: _ThemeMetadata(
      NeoDarkTheme.displayName,
      NeoDarkTheme.description,
      NeoDarkTheme.supportsDarkMode,
    ),
    AppStyle.proAi: _ThemeMetadata(
      ProAiTheme.displayName,
      ProAiTheme.description,
      ProAiTheme.supportsDarkMode,
    ),
    AppStyle.social: _ThemeMetadata(
      SocialTheme.displayName,
      SocialTheme.description,
      SocialTheme.supportsDarkMode,
    ),
    AppStyle.retroWave: _ThemeMetadata(
      RetroWaveTheme.displayName,
      RetroWaveTheme.description,
      RetroWaveTheme.supportsDarkMode,
    ),
    AppStyle.brutalist: _ThemeMetadata(
      BrutalistTheme.displayName,
      BrutalistTheme.description,
      BrutalistTheme.supportsDarkMode,
    ),
    AppStyle.appleLight: _ThemeMetadata(
      AppleLightTheme.displayName,
      AppleLightTheme.description,
      AppleLightTheme.supportsDarkMode,
    ),
    AppStyle.system: _ThemeMetadata(
      SystemTheme.displayName,
      SystemTheme.description,
      SystemTheme.supportsDarkMode,
    ),
  };

  _ThemeMetadata get _meta => _metadata[this]!;

  String get displayName => _meta.displayName;
  String get description => _meta.description;
  bool get supportsDarkMode => _meta.supportsDarkMode;
}

/// 主题元数据
class _ThemeMetadata {
  final String displayName;
  final String description;
  final bool supportsDarkMode;

  const _ThemeMetadata(
    this.displayName,
    this.description,
    this.supportsDarkMode,
  );
}

/// 应用主题管理器
class AppTheme {
  AppTheme._();

  /// 主题构建器映射
  static final _themeBuilders = <AppStyle, _ThemeBuilder>{
    AppStyle.geist: _ThemeBuilder(GeistTheme.light, GeistTheme.dark),
    AppStyle.boldRetro: _ThemeBuilder(
      BoldRetroTheme.light,
      BoldRetroTheme.dark,
    ),
    AppStyle.grungeCollage: _ThemeBuilder(
      GrungeCollageTheme.light,
      GrungeCollageTheme.dark,
    ),
    AppStyle.fluidSaturated: _ThemeBuilder(
      FluidSaturatedTheme.light,
      FluidSaturatedTheme.dark,
    ),
    AppStyle.materialYou: _ThemeBuilder(
      MaterialYouTheme.light,
      MaterialYouTheme.dark,
    ),
    AppStyle.flatDesign: _ThemeBuilder(
      FlatDesignTheme.light,
      FlatDesignTheme.dark,
    ),
    AppStyle.handDrawn: _ThemeBuilder(
      HandDrawnTheme.light,
      HandDrawnTheme.dark,
    ),
    AppStyle.midnightEditorial: _ThemeBuilder(
      MidnightEditorialTheme.light,
      MidnightEditorialTheme.dark,
    ),
    AppStyle.zenMinimalist: _ThemeBuilder(
      ZenMinimalistTheme.light,
      ZenMinimalistTheme.dark,
    ),
    AppStyle.minimalGlass: _ThemeBuilder(
      MinimalGlassTheme.light,
      MinimalGlassTheme.dark,
    ),
    AppStyle.neoDark: _ThemeBuilder(NeoDarkTheme.light, NeoDarkTheme.dark),
    AppStyle.proAi: _ThemeBuilder(ProAiTheme.light, ProAiTheme.dark),
    AppStyle.social: _ThemeBuilder(SocialTheme.light, SocialTheme.dark),
    AppStyle.retroWave: _ThemeBuilder(
      RetroWaveTheme.light,
      RetroWaveTheme.dark,
    ),
    AppStyle.brutalist: _ThemeBuilder(
      BrutalistTheme.light,
      BrutalistTheme.dark,
    ),
    AppStyle.appleLight: _ThemeBuilder(
      AppleLightTheme.light,
      AppleLightTheme.dark,
    ),
    AppStyle.system: _ThemeBuilder(SystemTheme.light, SystemTheme.dark),
  };

  /// 获取指定风格的主题
  ///
  /// [fontConfig] 为 null 或系统默认时，保留主题原生字体；
  /// 有值时用用户选择覆盖主题字体。
  static ThemeData getTheme(
    AppStyle style,
    Brightness brightness, {
    FontConfig? fontConfig,
  }) {
    final builder = _themeBuilders[style]!;
    final baseTheme = brightness == Brightness.light
        ? builder.light
        : builder.dark;

    // 使用主题原生字体
    if (fontConfig == null || fontConfig.fontFamily.isEmpty) {
      return baseTheme.copyWith(
        tooltipTheme: _buildTooltipTheme(baseTheme, null),
      );
    }

    // 应用用户选择的字体
    return _applyFontConfig(baseTheme, fontConfig);
  }

  /// 应用字体配置到主题
  static ThemeData _applyFontConfig(
    ThemeData baseTheme,
    FontConfig fontConfig,
  ) {
    final result = switch (fontConfig.source) {
      FontSource.google => _buildGoogleFontTheme(
        baseTheme,
        fontConfig.fontFamily,
      ),
      FontSource.system || FontSource.bundled => (
        baseTheme.textTheme.apply(
          fontFamily: fontConfig.fontFamily,
          fontFamilyFallback: StudioTypography.fallback,
        ),
        baseTheme.primaryTextTheme.apply(
          fontFamily: fontConfig.fontFamily,
          fontFamilyFallback: StudioTypography.fallback,
        ),
        fontConfig.fontFamily,
      ),
    };

    if (result == null) {
      return baseTheme.copyWith(
        tooltipTheme: _buildTooltipTheme(baseTheme, null),
      );
    }

    final (textTheme, primaryTextTheme, tooltipFontFamily) = result;

    return StudioTypography.applyFamily(baseTheme, tooltipFontFamily!).copyWith(
      extensions: [
        ...baseTheme.extensions.values.where((e) => e is! StudioFontProfile),
        StudioFontProfile(
          usePrototypeFamilies: fontConfig == FontConfig.defaultFont,
        ),
      ],
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      tooltipTheme: _buildTooltipTheme(baseTheme, tooltipFontFamily),
      chipTheme: _applyFontToChipTheme(baseTheme.chipTheme, textTheme),
    );
  }

  /// 把用户字体同步到 Chip 的标签样式。
  ///
  /// Chip 对 `labelStyle` / `secondaryLabelStyle` 是"有则取之"而非合并：
  /// 主题一旦设了这两项，就不会再回退到 `textTheme.labelLarge`，
  /// 因此仅更新 textTheme 不足以让 Chip 跟随用户选择的字体。
  static ChipThemeData _applyFontToChipTheme(
    ChipThemeData chipTheme,
    TextTheme textTheme,
  ) {
    final fontFamily = textTheme.labelLarge?.fontFamily;
    if (fontFamily == null) return chipTheme;
    return chipTheme.copyWith(
      labelStyle: chipTheme.labelStyle?.copyWith(
        fontFamily: fontFamily,
        fontFamilyFallback: StudioTypography.fallback,
      ),
      secondaryLabelStyle: chipTheme.secondaryLabelStyle?.copyWith(
        fontFamily: fontFamily,
        fontFamilyFallback: StudioTypography.fallback,
      ),
    );
  }

  /// 构建 Google Font 主题，返回 null 如果字体无效
  static (TextTheme textTheme, TextTheme primaryTextTheme, String? fontFamily)?
  _buildGoogleFontTheme(ThemeData baseTheme, String fontName) {
    try {
      final fontFamily = GoogleFonts.getFont(fontName).fontFamily;
      return (
        _applyGoogleFont(baseTheme.textTheme, fontName),
        _applyGoogleFont(baseTheme.primaryTextTheme, fontName),
        fontFamily,
      );
    } catch (e) {
      return null;
    }
  }

  /// 使用 Google Font 应用到 TextTheme
  static TextTheme _applyGoogleFont(TextTheme base, String fontName) {
    final fontFamily = GoogleFonts.getFont(fontName).fontFamily;

    TextStyle? applyFont(TextStyle? style) => style?.copyWith(
      fontFamily: fontFamily,
      fontFamilyFallback: StudioTypography.fallback,
    );

    return base.copyWith(
      displayLarge: applyFont(base.displayLarge),
      displayMedium: applyFont(base.displayMedium),
      displaySmall: applyFont(base.displaySmall),
      headlineLarge: applyFont(base.headlineLarge),
      headlineMedium: applyFont(base.headlineMedium),
      headlineSmall: applyFont(base.headlineSmall),
      titleLarge: applyFont(base.titleLarge),
      titleMedium: applyFont(base.titleMedium),
      titleSmall: applyFont(base.titleSmall),
      bodyLarge: applyFont(base.bodyLarge),
      bodyMedium: applyFont(base.bodyMedium),
      bodySmall: applyFont(base.bodySmall),
      labelLarge: applyFont(base.labelLarge),
      labelMedium: applyFont(base.labelMedium),
      labelSmall: applyFont(base.labelSmall),
    );
  }

  /// 构建统一的 Tooltip 样式
  static TooltipThemeData _buildTooltipTheme(
    ThemeData baseTheme,
    String? fontFamily,
  ) {
    return TooltipThemeData(
      decoration: BoxDecoration(
        color: baseTheme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: baseTheme.dividerColor, width: 1),
      ),
      textStyle: StudioTypography.body.copyWith(
        color: baseTheme.colorScheme.onSurface.withValues(alpha: 0.8),
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        fontFamily: fontFamily ?? StudioTypography.cjk,
        fontFamilyFallback: StudioTypography.fallback,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      waitDuration: const Duration(milliseconds: 500),
    );
  }

  /// 主题扩展构建器映射
  static final _extensionBuilders =
      <AppStyle, _ThemeBuilder<AppThemeExtension>>{
        AppStyle.geist: _ThemeBuilder(
          GeistTheme.extension(Brightness.light),
          GeistTheme.extension(Brightness.dark),
        ),
        AppStyle.boldRetro: _ThemeBuilder(
          BoldRetroTheme.lightExtension,
          BoldRetroTheme.darkExtension,
        ),
        AppStyle.grungeCollage: _ThemeBuilder(
          GrungeCollageTheme.lightExtension,
          GrungeCollageTheme.darkExtension,
        ),
        AppStyle.fluidSaturated: _ThemeBuilder(
          FluidSaturatedTheme.lightExtension,
          FluidSaturatedTheme.darkExtension,
        ),
        AppStyle.materialYou: _ThemeBuilder(
          MaterialYouTheme.lightExtension,
          MaterialYouTheme.darkExtension,
        ),
        AppStyle.flatDesign: _ThemeBuilder(
          FlatDesignTheme.lightExtension,
          FlatDesignTheme.darkExtension,
        ),
        AppStyle.handDrawn: _ThemeBuilder(
          HandDrawnTheme.lightExtension,
          HandDrawnTheme.darkExtension,
        ),
        AppStyle.midnightEditorial: _ThemeBuilder(
          MidnightEditorialTheme.lightExtension,
          MidnightEditorialTheme.darkExtension,
        ),
        AppStyle.zenMinimalist: _ThemeBuilder(
          ZenMinimalistTheme.lightExtension,
          ZenMinimalistTheme.darkExtension,
        ),
        AppStyle.minimalGlass: _ThemeBuilder(
          MinimalGlassTheme.lightExtension,
          MinimalGlassTheme.darkExtension,
        ),
        AppStyle.neoDark: _ThemeBuilder(
          NeoDarkTheme.lightExtension,
          NeoDarkTheme.darkExtension,
        ),
        AppStyle.proAi: _ThemeBuilder(
          ProAiTheme.lightExtension,
          ProAiTheme.darkExtension,
        ),
        AppStyle.social: _ThemeBuilder(
          SocialTheme.lightExtension,
          SocialTheme.darkExtension,
        ),
        AppStyle.retroWave: _ThemeBuilder(
          RetroWaveTheme.lightExtension,
          RetroWaveTheme.darkExtension,
        ),
        AppStyle.brutalist: _ThemeBuilder(
          BrutalistTheme.lightExtension,
          BrutalistTheme.darkExtension,
        ),
        AppStyle.appleLight: _ThemeBuilder(
          AppleLightTheme.lightExtension,
          AppleLightTheme.darkExtension,
        ),
        AppStyle.system: _ThemeBuilder(
          SystemTheme.lightExtension,
          SystemTheme.darkExtension,
        ),
      };

  /// 获取指定风格的主题扩展
  static AppThemeExtension getExtension(AppStyle style, Brightness brightness) {
    final builder = _extensionBuilders[style]!;
    return brightness == Brightness.light ? builder.light : builder.dark;
  }
}

/// 主题构建器辅助类
class _ThemeBuilder<T> {
  final T light;
  final T dark;

  const _ThemeBuilder(this.light, this.dark);
}
