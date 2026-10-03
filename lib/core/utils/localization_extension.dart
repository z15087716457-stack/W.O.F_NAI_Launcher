import 'package:flutter/widgets.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';

import 'app_language.dart';

/// BuildContext 扩展，简化多语言调用
///
/// 使用示例：
/// ```dart
/// Text(context.l10n.settings)
/// ```
extension LocalizationExtension on BuildContext {
  /// 获取当前语言环境的 AppLocalizations 实例
  AppLocalizations get l10n => AppLocalizations.of(this) ?? currentL10n;

  /// Interface language, telling Simplified and Traditional Chinese apart.
  AppLanguage get appLanguage {
    final locale = Localizations.maybeLocaleOf(this);
    return locale == null ? currentAppLanguage : AppLanguage.fromLocale(locale);
  }

  /// 获取 timeago 使用的本地化代码
  String get timeagoLocaleCode => switch (appLanguage) {
    AppLanguage.simplifiedChinese => 'zh',
    AppLanguage.traditionalChinese => 'zh_TW',
    AppLanguage.japanese => 'ja',
    AppLanguage.korean => 'ko',
    AppLanguage.english => 'en',
  };

  /// 获取 Vibe 来源类型的本地化展示名称
  String vibeSourceTypeLabel(VibeSourceType sourceType) {
    switch (sourceType) {
      case VibeSourceType.png:
        return l10n.vibe_sourceType_png;
      case VibeSourceType.naiv4vibe:
        return l10n.vibe_sourceType_v4vibe;
      case VibeSourceType.naiv4vibebundle:
        return l10n.vibe_sourceType_bundle;
      case VibeSourceType.rawImage:
        return l10n.vibe_sourceType_image;
    }
  }
}

AppLocalizations? _currentL10n;
AppLanguage _currentAppLanguage = AppLanguage.simplifiedChinese;

/// Localizations for code that has no BuildContext, such as models, services
/// and errors raised below the UI. It follows [setCurrentL10nLocale], which the
/// locale provider calls; before that it uses the app's default language.
AppLocalizations get currentL10n =>
    _currentL10n ??= lookupAppLocalizations(_currentAppLanguage.locale);

/// Interface language for code without a BuildContext; see [currentL10n].
AppLanguage get currentAppLanguage => _currentAppLanguage;

void setCurrentL10nLocale(Locale locale) {
  _currentAppLanguage = AppLanguage.fromLocale(locale);
  _currentL10n = lookupAppLocalizations(_currentAppLanguage.locale);
}
