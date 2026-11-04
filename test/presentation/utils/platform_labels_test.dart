import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/utils/platform_labels.dart';
import 'package:nai_launcher/presentation/utils/shortcut_labels.dart';

void main() {
  final zh = lookupAppLocalizations(const Locale('zh'));
  final en = lookupAppLocalizations(const Locale('en'));

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('macOS 上叫访达、菜单栏', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(showInFileManagerLabel(zh, zh.localGallery_showInFolder), '在访达中显示');
    expect(showInFileManagerLabel(zh, zh.gen_reveal), '在访达中显示');
    expect(showInFileManagerLabel(en, en.refs_showInFolder), 'Show in Finder');
    expect(minimizeToTrayLabel(zh), '隐藏到菜单栏');
    expect(minimizeToTrayLabel(en), 'Hide to Menu Bar');
    expect(imageMissingHintLabel(zh), '可能已经在访达里被移动、改名或删除');
    expect(followSystemAppearanceLabel(zh), '按 macOS 设置自动切换');
    // 盘符在 Mac 上只是「/」，剩余空间不带它
    expect(diskFreeLabel(zh, '/', '120 GB'), '剩余 120 GB');
    expect(diskFreeLabel(en, '/', '120 GB'), '120 GB free');
    expect(
      settingsShortcutLabel(zh, 'shortcut_action_minimize_to_tray'),
      '隐藏到菜单栏',
    );
  });

  test('其他平台用原来的叫法', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(showInFileManagerLabel(zh, zh.localGallery_showInFolder), '在文件夹中显示');
    expect(showInFileManagerLabel(zh, zh.gen_reveal), '在资源管理器中显示');
    expect(showInFileManagerLabel(en, en.refs_showInFolder), 'Show in folder');
    expect(minimizeToTrayLabel(zh), '最小化到托盘');
    expect(imageMissingHintLabel(zh), '可能已经在资源管理器里被移动、改名或删除');
    expect(followSystemAppearanceLabel(zh), '按 Windows 设置自动切换');
    expect(diskFreeLabel(zh, 'E:', '120 GB'), 'E: 盘剩余 120 GB');
    expect(
      settingsShortcutLabel(zh, 'shortcut_action_minimize_to_tray'),
      '最小化到托盘',
    );
  });
}
