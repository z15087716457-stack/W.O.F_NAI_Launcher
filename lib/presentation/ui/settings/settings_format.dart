import 'package:flutter/widgets.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../kit/ui_glyph.dart';
import 'settings_contract.dart';
import 'settings_kit.dart';

/// 目录图标：StudioIcons 字形或线性 SVG 路径（二选一）。
typedef SettingsPageIcon = ({IconData? icon, String? glyph});

abstract final class SettingsFormat {
  static String group(BuildContext context, SettingsGroup g) {
    final l = context.l10n;
    return switch (g) {
      SettingsGroup.none => '',
      SettingsGroup.personal => l.set_groupPersonal,
      SettingsGroup.create => l.set_groupCreate,
      SettingsGroup.intelligence => l.set_groupIntelligence,
      SettingsGroup.connect => l.set_groupConnect,
      SettingsGroup.system => l.set_groupSystem,
    };
  }

  static String page(BuildContext context, SettingsPageId p) {
    final l = context.l10n;
    return switch (p) {
      SettingsPageId.overview => l.set_pageOverview,
      SettingsPageId.account => l.set_pageAccount,
      SettingsPageId.appearance => l.set_pageAppearance,
      SettingsPageId.canvas => l.set_pageCanvas,
      SettingsPageId.shortcuts => l.set_pageShortcuts,
      SettingsPageId.generation => l.set_pageGeneration,
      SettingsPageId.storage => l.set_pageStorage,
      SettingsPageId.dictionaries => l.set_pageDictionaries,
      SettingsPageId.models => l.set_pageModels,
      SettingsPageId.agent => l.set_pageAgent,
      SettingsPageId.rag => l.set_pageRag,
      SettingsPageId.upscale => l.set_pageUpscale,
      SettingsPageId.bridges => l.set_pageBridges,
      SettingsPageId.network => l.set_pageNetwork,
      SettingsPageId.privacy => l.set_pagePrivacy,
      SettingsPageId.backup => l.set_pageBackup,
      SettingsPageId.about => l.set_pageAbout,
    };
  }

  /// 页头上方的英文小字（不翻译，和原型一致）。
  static String eyebrow(SettingsPageId p) => switch (p) {
    SettingsPageId.overview => 'Settings / Overview',
    SettingsPageId.account => 'Personal / Account',
    SettingsPageId.appearance => 'Personal / Appearance',
    SettingsPageId.canvas => 'Personal / Canvas',
    SettingsPageId.shortcuts => 'Personal / Shortcuts',
    SettingsPageId.generation => 'Create / Generation',
    SettingsPageId.storage => 'Create / Storage',
    SettingsPageId.dictionaries => 'Create / Dictionaries',
    SettingsPageId.models => 'Intelligence / Models',
    SettingsPageId.agent => 'Intelligence / Agent',
    SettingsPageId.rag => 'Intelligence / Semantic Search',
    SettingsPageId.upscale => 'Intelligence / Upscale',
    SettingsPageId.bridges => 'Connect / Bridges',
    SettingsPageId.network => 'Connect / Network',
    SettingsPageId.privacy => 'System / Privacy',
    SettingsPageId.backup => 'System / Backup',
    SettingsPageId.about => 'System / About',
  };

  static SettingsPageIcon icon(SettingsPageId p) => switch (p) {
    SettingsPageId.overview => (icon: null, glyph: UiGlyphs.grid),
    SettingsPageId.account => (icon: StudioIcons.settingsAccount, glyph: null),
    SettingsPageId.appearance => (
      icon: StudioIcons.settingsAppearance,
      glyph: null,
    ),
    SettingsPageId.canvas => (icon: null, glyph: SettingsGlyphs.canvas),
    SettingsPageId.shortcuts => (
      icon: StudioIcons.settingsControls,
      glyph: null,
    ),
    SettingsPageId.generation => (
      icon: StudioIcons.settingsGeneration,
      glyph: null,
    ),
    SettingsPageId.storage => (icon: StudioIcons.settingsStorage, glyph: null),
    SettingsPageId.dictionaries => (
      icon: StudioIcons.settingsData,
      glyph: null,
    ),
    SettingsPageId.models => (icon: StudioIcons.settingsModels, glyph: null),
    SettingsPageId.agent => (icon: null, glyph: SettingsGlyphs.spark),
    SettingsPageId.rag => (icon: null, glyph: SettingsGlyphs.hub),
    SettingsPageId.upscale => (icon: StudioIcons.galleryUpscale, glyph: null),
    SettingsPageId.bridges => (
      icon: StudioIcons.settingsIntegrations,
      glyph: null,
    ),
    SettingsPageId.network => (icon: null, glyph: SettingsGlyphs.globe),
    SettingsPageId.privacy => (icon: StudioIcons.settingsPrivacy, glyph: null),
    SettingsPageId.backup => (icon: null, glyph: SettingsGlyphs.backup),
    SettingsPageId.about => (icon: StudioIcons.settingsAbout, glyph: null),
  };

  /// 千分位整数。
  static String count(num n) {
    final s = n.round().abs().toString();
    final b = StringBuffer(n < 0 ? '−' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  /// 字节：≥ 1 GB 一位小数 GB，否则整数 MB / KB。
  static String bytes(int b) {
    const k = 1024.0;
    if (b >= k * k * k) {
      final g = b / (k * k * k);
      return '${g >= 100 ? g.round() : g.toStringAsFixed(1)} GB';
    }
    if (b >= k * k) return '${(b / (k * k)).round()} MB';
    if (b >= k) return '${(b / k).round()} KB';
    return '$b B';
  }

  /// GB 数字（不带单位，一位小数）。
  static String gb(int b) => (b / (1024 * 1024 * 1024)).toStringAsFixed(1);

  static String two(int n) => n.toString().padLeft(2, '0');
  static String time(DateTime t) => '${two(t.hour)}:${two(t.minute)}';
  static String monthDay(DateTime t) => '${two(t.month)}-${two(t.day)}';
  static String date(DateTime t) => '${t.year}-${two(t.month)}-${two(t.day)}';

  /// 相对时间：刚刚 / N 秒前 / N 分钟前 / 今天 HH:mm / 昨天 / MM-DD。
  static String ago(
    BuildContext context,
    DateTime at,
    DateTime now, {
    bool seconds = false,
  }) {
    final l = context.l10n;
    final d = now.difference(at);
    if (d.inSeconds < 10) return l.set_justNow;
    if (seconds && d.inSeconds < 60) return l.set_secondsAgo('${d.inSeconds}');
    if (d.inMinutes < 1) return l.set_justNow;
    if (d.inMinutes < 60) return l.set_minutesAgo('${d.inMinutes}');
    final today = DateTime(now.year, now.month, now.day);
    if (!at.isBefore(today)) return l.set_todayAt(time(at));
    if (!at.isBefore(today.subtract(const Duration(days: 1)))) {
      return l.set_yesterday;
    }
    return monthDay(at);
  }

  static String ms(int ms) =>
      ms >= 1000 ? '${(ms / 1000).toStringAsFixed(1)} s' : '$ms ms';

  static String tier(SettingsTier t) => switch (t) {
    SettingsTier.none => '',
    SettingsTier.tablet => 'Tablet',
    SettingsTier.scroll => 'Scroll',
    SettingsTier.opus => 'Opus',
  };

  static String task(BuildContext context, SettingsModelTask t) {
    final l = context.l10n;
    return switch (t) {
      SettingsModelTask.promptTranslate => l.set_mdTaskPrompt,
      SettingsModelTask.promptReverse => l.set_mdTaskReverse,
      SettingsModelTask.tagTranslate => l.set_mdTaskTag,
      SettingsModelTask.wikiTranslate => l.set_mdTaskWiki,
    };
  }

  static String ragSource(BuildContext context, SettingsRagSourceKind k) {
    final l = context.l10n;
    return switch (k) {
      SettingsRagSourceKind.tags => l.set_rgTags,
      SettingsRagSourceKind.wiki => l.set_rgWiki,
      SettingsRagSourceKind.blocks => l.set_rgBlocks,
      SettingsRagSourceKind.gallery => l.set_rgGallery,
    };
  }

  static String ragShort(BuildContext context, SettingsRagSourceKind k) {
    final l = context.l10n;
    return switch (k) {
      SettingsRagSourceKind.tags => l.set_rgShortTags,
      SettingsRagSourceKind.wiki => l.set_rgShortWiki,
      SettingsRagSourceKind.blocks => l.set_rgShortBlocks,
      SettingsRagSourceKind.gallery => l.set_rgShortGallery,
    };
  }

  static String upscaleName(BuildContext context, String id) {
    final l = context.l10n;
    return switch (id) {
      'animeQuality' => l.set_upAnimeQuality,
      'animeFast' => l.set_upAnimeFast,
      'general' => l.set_upGeneral,
      'seed3b' => l.set_upSeed3b,
      'seed7b' => l.set_upSeed7b,
      'seed7bSharp' => l.set_upSeed7bSharp,
      'seedvr2-3b-int8' => l.set_upSeed3bInt8,
      'seedvr2-7b-int8' => l.set_upSeed7bInt8,
      'seedvr2-7b-sharp-int8' => l.set_upSeed7bSharpInt8,
      'rtxVideo' => l.set_upRtx,
      _ => id,
    };
  }

  static String simpleViewerGroupDescription(BuildContext context) =>
      context.l10n.set_cvGroupBatchesSub;

  static String percent(double v) => '${(v * 100).round()}%';

  /// 文案里的 `{keys}` 占位换成 `\u0000`，配合 [SettingsKeyText] 画键帽。
  static String keyed(String Function(String) build) => build('\u0000');

  /// 标量设置的固定选项文字。
  static String choice(BuildContext context, SettingKey key, String value) {
    final l = context.l10n;
    return switch ((key, value)) {
      (SettingKey.themeMode, 'light') => l.set_apLight,
      (SettingKey.themeMode, 'dark') => l.set_apDark,
      (SettingKey.themeMode, 'system') => l.set_apSystem,
      (SettingKey.language, 'zh') => '简体中文',
      (SettingKey.language, 'zh_TW') => '繁體中文',
      (SettingKey.language, 'en') => 'English',
      (SettingKey.language, 'ja') => '日本語',
      (SettingKey.language, 'ko') => '한국어',
      (SettingKey.historyClick, 'openDetail') => l.set_cvOpenDetail,
      (SettingKey.historyClick, 'linkedPreview') => l.set_cvLinked,
      (SettingKey.outputViewer, 'canvas') => l.set_cvCanvas,
      (SettingKey.outputViewer, 'simple') => l.set_cvSimple,
      (SettingKey.wheelModifier, 'alt') => 'Alt',
      (SettingKey.wheelModifier, 'ctrl') => 'Ctrl',
      (SettingKey.wheelModifier, 'shift') => 'Shift',
      (SettingKey.wheelModifier, 'none') => l.set_gnNoKey,
      (SettingKey.galleryQuality, 'high') => l.set_stHigh,
      (SettingKey.galleryQuality, 'standard') => l.set_stStandard,
      (SettingKey.ragContext, 'beforeCursor') => l.set_rgBefore,
      (SettingKey.ragContext, 'around') => l.set_rgAround,
      (SettingKey.ragDevice, 'auto') => l.set_rgAuto,
      (SettingKey.ragDevice, 'cuda') => 'CUDA',
      (SettingKey.ragDevice, 'cpu') => 'CPU',
      (SettingKey.seedVramMode, 'recommended') => l.set_upRecommended,
      (SettingKey.seedVramMode, 'low') => l.set_upLowVram,
      (SettingKey.proxyMode, 'system') => l.set_nwSystem,
      (SettingKey.proxyMode, 'manual') => l.set_nwManual,
      _ => value,
    };
  }
}
