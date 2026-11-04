// 小贴士正文里的快捷键按平台写：macOS 上 Ctrl → ⌘、Alt → ⌥、F1 / F5 / F11 → Mac 上的默认键；Windows 原样。
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';

const _locales = [
  Locale('zh'),
  Locale('zh', 'TW'),
  Locale('en'),
  Locale('ja'),
  Locale('ko'),
];

List<String> _allTips(Locale locale) {
  final l10n = lookupAppLocalizations(locale);
  return [
    for (final surface in TipSurface.values)
      for (final tip in tipsFor(surface)) tip.text(l10n),
  ];
}

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('macOS：没有 Ctrl、Alt、F1 / F5 / F11，写成 Mac 的键', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final windowsStyle = RegExp(r'Ctrl|\bAlt\b|\bF(?:1|5|11)\b');
    for (final locale in _locales) {
      final tips = _allTips(locale);
      expect(tips.where(windowsStyle.hasMatch), isEmpty, reason: '$locale');
      expect(tips.where((t) => t.contains('⌘')), isNotEmpty, reason: '$locale');
    }
  });

  test('翻译块切换那条：macOS 写 ⌘+点击，Windows 照旧写鼠标中键', () {
    for (final locale in _locales) {
      final l10n = lookupAppLocalizations(locale);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final mac = _allTips(locale);
      expect(mac, contains(l10n.tips_studio_trick_6_mac), reason: '$locale');
      expect(mac, isNot(contains(l10n.tips_studio_trick_6)), reason: '$locale');
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final windows = _allTips(locale);
      expect(windows, contains(l10n.tips_studio_trick_6), reason: '$locale');
      expect(
        windows,
        isNot(contains(l10n.tips_studio_trick_6_mac)),
        reason: '$locale',
      );
    }
  });

  test('Windows：照旧写 Ctrl、F1', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final tips = _allTips(const Locale('zh'));
    expect(tips.where((t) => t.contains('Ctrl')), isNotEmpty);
    expect(tips.where((t) => t.contains('F1')), isNotEmpty);
    expect(tips.where((t) => t.contains('⌘')), isEmpty);
  });
}
