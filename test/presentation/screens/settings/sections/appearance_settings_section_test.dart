import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/history_click_behavior_provider.dart';
import 'package:nai_launcher/presentation/providers/locale_provider.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/appearance_settings_section.dart';

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = Directory.systemTemp.createTempSync('appearance_settings_hive_');
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

  testWidgets('历史点击行为默认经典并可从操作设置切换和持久化', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = _FakeStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: AppearanceSettingsSection(controlsOnly: true),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppearanceSettingsSection)),
    );

    expect(find.text('历史记录点击行为'), findsOneWidget);
    expect(find.text('经典'), findsOneWidget);
    expect(
      container.read(historyClickBehaviorNotifierProvider),
      HistoryClickBehavior.openDetail,
    );

    await tester.tap(find.text('历史记录点击行为'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('单击历史图片直接打开详情'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.textContaining('单击切换中央预览'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('官网式联动'));
    await tester.pumpAndSettle();

    expect(
      container.read(historyClickBehaviorNotifierProvider),
      HistoryClickBehavior.selectPreview,
    );
    expect(storage.behavior, 'select_preview');
  });

  testWidgets('语言选择列出简繁中文并切换到繁体', (tester) async {
    addTearDown(() => setCurrentL10nLocale(const Locale('zh')));
    await tester.binding.setSurfaceSize(const Size(1000, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = _FakeStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            locale: ref.watch(localeNotifierProvider),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: AppearanceSettingsSection()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('语言'));
    await tester.pumpAndSettle();
    final dialog = find.byType(Dialog);
    for (final name in ['简体中文', '繁體中文', 'English', '日本語', '한국어']) {
      expect(
        find.descendant(of: dialog, matching: find.text(name)),
        findsOneWidget,
      );
    }
    await tester.tap(find.descendant(of: dialog, matching: find.text('繁體中文')));
    await tester.pumpAndSettle();

    expect(storage.getLocaleCode(), 'zh_TW');
    expect(find.text('語言'), findsOneWidget);
    expect(find.text('繁體中文'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in const [
    Locale('zh'),
    Locale('zh', 'TW'),
    Locale('ja'),
    Locale('en'),
    Locale('ko'),
  ]) {
    testWidgets('字体大小预览在 $locale 界面显示多语言示例', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWith((ref) => _FakeStorage()),
          ],
          child: MaterialApp(
            locale: locale,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: AppearanceSettingsSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(AppearanceSettingsSection)),
      )!;
      await tester.tap(find.text(l10n.settings_fontScale));
      await tester.pumpAndSettle();

      expect(
        find.text(switch (locale) {
          Locale(countryCode: 'TW') => '光影落在畫布上。',
          Locale(languageCode: 'ko') => '빛과 그림자가 캔버스에 내려앉는다.',
          _ => '光影落在画布上。',
        }),
        findsOneWidget,
      );
      expect(find.text('色から物語が生まれる。'), findsOneWidget);
      expect(find.text('Let colors tell a story.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

class _FakeStorage extends LocalStorageService {
  String behavior = 'open_detail';
  String locale = 'zh';

  // Real Hive writes would not finish inside the widget test's fake async.
  @override
  String getLocaleCode() => locale;

  @override
  Future<void> setLocaleCode(String code) async => locale = code;

  @override
  String getHistoryClickBehavior() => behavior;

  @override
  Future<void> setHistoryClickBehavior(String value) async {
    behavior = value;
  }
}
