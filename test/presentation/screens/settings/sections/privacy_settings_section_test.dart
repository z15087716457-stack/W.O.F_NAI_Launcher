import 'package:nai_launcher/presentation/screens/settings/widgets/settings_tile.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/services/danbooru_tags_lazy_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/privacy_settings_section.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_card.dart';
import 'package:nai_launcher/presentation/widgets/online_gallery/blacklist_settings_panel.dart';

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = Directory.systemTemp.createTempSync('privacy_settings_hive_');
    Hive.init(hiveDir.path);
    await Hive.openBox(StorageKeys.settingsBox);
  });

  setUp(() async {
    await Hive.box(StorageKeys.settingsBox).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    bool generationOnly = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          danbooruTagsLazyServiceProvider.overrideWith(
            (ref) => Completer<DanbooruTagsLazyService>().future,
          ),
        ],
        child: MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PrivacySettingsSection(generationOnly: generationOnly),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('独立保护功能与在线画廊黑名单', (tester) async {
    await pumpSection(tester);

    expect(find.text('保护模式'), findsNothing);
    expect(find.text('保护功能'), findsOneWidget);
    expect(find.text('复制/拖拽时移除全部元数据'), findsOneWidget);
    expect(find.text('限制生图频率'), findsNothing);
    expect(find.text('生图间隔'), findsNothing);
    expect(find.text('间隔随机抖动'), findsNothing);
    expect(find.byType(OnlineGalleryBlacklistSettingsPanel), findsOneWidget);
  });

  testWidgets('子开关直接可用，附属参数跟随自己的开关', (tester) async {
    await pumpSection(tester);

    final stripTile = tester.widget<SettingsSwitchTile>(
      find.ancestor(
        of: find.text('复制/拖拽时移除全部元数据'),
        matching: find.byType(SettingsSwitchTile),
      ),
    );
    expect(stripTile.onChanged, isNotNull);

    await pumpSection(tester, generationOnly: true);
    final intervalSwitch = tester.widget<SettingsSwitchTile>(
      find.ancestor(
        of: find.text('限制生图频率'),
        matching: find.byType(SettingsSwitchTile),
      ),
    );
    expect(intervalSwitch.onChanged, isNotNull);

    final intervalTile = tester.widget<SettingsTile>(
      find.ancestor(of: find.text('生图间隔'), matching: find.byType(SettingsTile)),
    );
    expect(intervalTile.onTap, isNull);

    final jitterTile = tester.widget<SettingsTile>(
      find.ancestor(
        of: find.text('间隔随机抖动'),
        matching: find.byType(SettingsTile),
      ),
    );
    expect(jitterTile.onTap, isNull);
  });

  testWidgets('复制/拖拽移除元数据默认关闭（空存储走默认值）', (tester) async {
    await pumpSection(tester);

    final stripTile = tester.widget<SettingsSwitchTile>(
      find.ancestor(
        of: find.text('复制/拖拽时移除全部元数据'),
        matching: find.byType(SettingsSwitchTile),
      ),
    );
    expect(stripTile.value, isFalse);
  });

  testWidgets('在线画廊黑名单与主设置卡片宽度一致', (tester) async {
    await pumpSection(tester);

    final primaryCard = find.byType(SettingsCard).first;
    final blacklistCard = find.byType(OnlineGalleryBlacklistSettingsPanel);
    expect(
      find.descendant(of: blacklistCard, matching: find.byType(Card)),
      findsNothing,
    );

    final primaryRect = tester.getRect(primaryCard);
    final blacklistRect = tester.getRect(blacklistCard);

    expect(blacklistRect.left, primaryRect.left);
    expect(blacklistRect.right, primaryRect.right);
    expect(blacklistRect.width, primaryRect.width);
  });
}
