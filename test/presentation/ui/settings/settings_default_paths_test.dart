// 设置 → 存储里没改过的 Vibe 目录、应用数据（Hive）目录显示默认位置：macOS 上用 / 分隔，
// Hive 在「应用支持」目录下；其他平台照旧。
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/app_bundle_paths.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';
import 'package:path/path.dart' as p;

import 'settings_test_harness.dart';

String _shownPath(WidgetTester t, SettingKey key) => t
    .widget<SettingsTailText>(
      find.descendant(
        of: find.byKey(Key('path-${key.name}')),
        matching: find.byType(SettingsTailText),
      ),
    )
    .text;

void main() {
  testWidgets('macOS：Vibe 目录用 / 分隔，Hive 在应用支持目录下', (t) async {
    await pumpSettings(t, page: SettingsPageId.storage);
    expect(_shownPath(t, SettingKey.vibePath), 'Documents/NAI_Launcher/vibes');
    expect(
      _shownPath(t, SettingKey.appDataPath),
      p.join(AppBundlePaths.applicationSupport, 'hive'),
    );
    await t.pump(const Duration(seconds: 5));
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('Windows：照旧', (t) async {
    await pumpSettings(t, page: SettingsPageId.storage);
    expect(_shownPath(t, SettingKey.vibePath), r'Documents\NAI_Launcher\vibes');
    expect(_shownPath(t, SettingKey.appDataPath), './user-data/hive');
    await t.pump(const Duration(seconds: 5));
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
