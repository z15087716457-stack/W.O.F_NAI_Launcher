import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/providers/settings_navigation_provider.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/presentation/providers/font_provider.dart';
import 'package:nai_launcher/presentation/providers/settings_font_scale_provider.dart';
import 'package:nai_launcher/presentation/widgets/settings/account_credentials_dialog.dart';
import 'package:nai_launcher/presentation/widgets/settings/account_subscription_summary.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_toggle.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nai_launcher/core/constants/app_version.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_providers.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/database/database_providers.dart';
import 'package:nai_launcher/core/cache/gallery_cache_manager.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/cache_statistics_tile.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/account_settings_section.dart';
import 'package:nai_launcher/presentation/providers/data_source_cache_provider.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import '../../../helpers/studio_capture_fonts.dart';

import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/model_compact_dropdown.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/theme_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/integrations_settings_section.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/prompt_assistant_settings_section.dart';
import 'package:nai_launcher/presentation/screens/settings/settings_screen.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/model_management_widgets.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/core/utils/app_language.dart';

import '../../../helpers/chinese_script_test_support.dart';

class _DesignShortcuts extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}

class _DesignSettingsScale extends SettingsFontScaleNotifier {
  _DesignSettingsScale(this.scale);
  final double scale;
  @override
  double build() => scale;
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

class _DesignTheme extends ThemeNotifier {
  _DesignTheme(this.brightness);
  final Brightness brightness;
  @override
  Brightness build() => brightness;
}

class _FakeAccountManagerNotifier extends AccountManagerNotifier {
  @override
  AccountManagerState build() => const AccountManagerState();
}

class _FakeSubscriptionNotifier extends SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionStateInitial();
}

class _DesignAccounts extends AccountManagerNotifier {
  @override
  AccountManagerState build() => AccountManagerState(
    accounts: [
      SavedAccount(
        id: 'pd',
        email: 'token_fixture',
        nickname: 'PD',
        isDefault: true,
        createdAt: DateTime(2026),
      ),
      SavedAccount(
        id: 'fish',
        email: 'fixture@example.test',
        nickname: '鲟鱼',
        createdAt: DateTime(2026),
        subscriptionExpiresAt:
            DateTime(2027, 1, 1).millisecondsSinceEpoch ~/ 1000,
      ),
    ],
  );
}

class _DesignAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    accountId: 'pd',
    displayName: 'PD',
  );
}

class _DesignSubscription extends SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionStateLoaded(
    UserSubscription(
      tier: 3,
      active: true,
      expiresAt: 1798761600,
      trainingStepsLeft: TrainingStepsInfo(fixedTrainingStepsLeft: 29600),
    ),
  );
}

class _DesignPaths extends PathProviderPlatform {
  _DesignPaths(this.path);
  final String path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

class _DesignCatalog extends TagCatalogRepository {
  @override
  Future<Map<String, String>> metadata() async => {
    'tag_count': '837204',
    'data_version': '2026-09',
  };
  @override
  Future<void> dispose() async {}
}

class _DesignTagsCache extends DanbooruTagsCacheNotifier {
  @override
  Future<DanbooruTagsCacheState> build() async =>
      const DanbooruTagsCacheState();
}

class _MemorySettingsStorage extends LocalStorageService {
  String? _config;

  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      key == StorageKeys.promptAssistantConfigJson
      ? _config as T?
      : defaultValue;

  @override
  Future<void> setSetting<T>(String key, T value) async {
    if (key == StorageKeys.promptAssistantConfigJson) {
      _config = value as String;
    }
  }
}

class _MemoryAssistantSecrets extends SecureStorageService {
  final Map<String, String> headers = {};
  @override
  Future<String?> getPromptAssistantHeaders(String providerId) async =>
      headers[providerId];
  @override
  Future<void> savePromptAssistantHeaders(
    String providerId,
    String value,
  ) async {
    headers[providerId] = value;
  }

  @override
  Future<void> deletePromptAssistantHeaders(String providerId) async {
    headers.remove(providerId);
  }

  @override
  Future<String?> getPromptAssistantApiKey(String providerId) async => null;
}

void main() {
  late Directory hiveDir;
  final settingsCaptureKey = GlobalKey();

  setUpAll(() async {
    // Real fonts keep the English and Japanese layout checks representative.
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    hiveDir = Directory.systemTemp.createTempSync('settings_screen_hive_');
    PathProviderPlatform.instance = _DesignPaths(hiveDir.path);
    Hive.init(hiveDir.path);
    await Hive.openBox(StorageKeys.settingsBox);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'W.O.F NAI Studio',
      packageName: 'wof.nai.studio',
      version: '2.0.0-preview',
      buildNumber: '6',
      buildSignature: '',
    );
    await AppVersion.initialize();
    await Hive.box(StorageKeys.settingsBox).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  Future<ProviderContainer> pumpPolish(
    WidgetTester tester, {
    double width = 1280,
    double scale = 1,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = _MemorySettingsStorage()
      .._config = const PromptAssistantConfigState(
        providers: [
          ProviderConfig(
            id: 'deepseek',
            name: 'DeepSeek',
            baseUrl: 'https://example.test/v1',
            preset: ProviderPreset.deepseek,
          ),
        ],
        models: [
          ModelConfig(
            providerId: 'deepseek',
            name: 'deepseek-chat',
            displayName: 'DeepSeek Chat',
          ),
        ],
        interfaces: {},
        providerHasApiKey: {},
      ).encode();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shortcutConfigNotifierProvider.overrideWith(_DesignShortcuts.new),
          settingsFontScaleProvider.overrideWith(
            () => _DesignSettingsScale(scale),
          ),
          themeNotifierProvider.overrideWith(() => _DesignTheme(brightness)),
          allFontsProvider.overrideWith(
            (ref) async => {
              '应用默认': [FontConfig.defaultFont],
              '内置字体': bundledPresets,
              'Google Fonts': GoogleFontPresets.all,
            },
          ),
          localStorageServiceProvider.overrideWithValue(storage),
          secureStorageServiceProvider.overrideWithValue(
            _MemoryAssistantSecrets(),
          ),
          authNotifierProvider.overrideWith(_DesignAuth.new),
          accountManagerNotifierProvider.overrideWith(_DesignAccounts.new),
          subscriptionNotifierProvider.overrideWith(_DesignSubscription.new),
        ],
        child: MaterialApp(
          theme: AppTheme.getTheme(AppStyle.geist, brightness),
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const IntegratedTitleBarShell(child: SettingsScreen()),
          builder: (context, child) => RepaintBoundary(
            key: settingsCaptureKey,
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1)),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
  }

  Future<void> capturePolish(WidgetTester tester, String name) async {
    if (Platform.environment['CAPTURE_SETTINGS_REDESIGN'] != '1') return;
    await tester.runAsync(() async {
      final image =
          await (settingsCaptureKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(
        '${Platform.environment['SETTINGS_CAPTURE_DIR'] ?? '.dart_tool/settings-redesign-captures'}/$name.png',
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'account menu request opens accounts from an existing settings section',
    (tester) async {
      final container = await pumpPolish(tester);
      await tester.tap(find.text('常规与外观'));
      await tester.pumpAndSettle();
      expect(find.text('外观样式'), findsOneWidget);
      container.read(settingsAccountOpenRequestProvider.notifier).state++;
      await tester.pumpAndSettle();
      expect(find.byType(AccountSubscriptionSummary), findsOneWidget);
      expect(find.byKey(const Key('settings-account-pd')), findsOneWidget);
      expect(find.text('风格'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'account menu navigation retains the unsaved model confirmation',
    (tester) async {
      final container = await pumpPolish(tester);
      await tester.tap(find.byKey(const ValueKey('settings-nav-models')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('service-edit-connection')),
      );
      await tester.tap(find.byKey(const Key('service-edit-connection')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.controller?.text == 'DeepSeek',
        ),
        '未保存的服务',
      );
      await tester.pumpAndSettle();
      container.read(settingsAccountOpenRequestProvider.notifier).state++;
      await tester.pumpAndSettle();
      expect(find.text('保留当前编辑？'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('未保存的服务'), findsNWidgets(2));
      expect(find.byType(AccountSettingsSection), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('search respects unsaved model connection edits', (tester) async {
    await pumpPolish(tester);
    await tester.tap(find.byKey(const ValueKey('settings-nav-models')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('service-edit-connection')),
    );
    await tester.tap(find.byKey(const Key('service-edit-connection')));
    await tester.pumpAndSettle();
    final name = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller?.text == 'DeepSeek',
    );
    await tester.enterText(name, '未保存的服务');
    await tester.tap(find.byKey(const Key('settings-open-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('settings-search-input')),
      '自动登录',
    );
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('保留当前编辑？'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('未保存的服务'), findsNWidgets(2));
    expect(find.byType(AccountSettingsSection), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'sidebar search stays below native captions and the blank header remains draggable',
    (tester) async {
      final windowCalls = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        (call) async {
          windowCalls.add(call.method);
          return call.method == 'isMaximized' || call.method == 'isFullScreen'
              ? false
              : null;
        },
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('com.nailauncher/titlebar'),
        (_) async => null,
      );
      addTearDown(() {
        messenger.setMockMethodCallHandler(
          const MethodChannel('window_manager'),
          null,
        );
        messenger.setMockMethodCallHandler(
          const MethodChannel('com.nailauncher/titlebar'),
          null,
        );
      });
      await pumpPolish(tester, width: 2400);
      final search = tester.getRect(
        find.byKey(const Key('settings-open-search')),
      );
      final captions = tester.getRect(
        find.byKey(const Key('window-caption-controls')),
      );
      final sidebar = tester.getRect(
        find.byKey(const Key('settings-sidebar-surface')),
      );
      expect(search.top, greaterThanOrEqualTo(captions.bottom));
      expect(search.left, greaterThan(sidebar.left));
      expect(search.right, lessThan(sidebar.right));
      expect(
        search.bottom,
        lessThan(
          tester
              .getRect(find.byKey(const ValueKey('settings-nav-appearance')))
              .top,
        ),
      );
      await capturePolish(tester, 'settings-header-aligned');
      final hover = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await hover.addPointer(location: search.center);
      await tester.pumpAndSettle();
      await capturePolish(tester, 'settings-header-hover');
      await hover.removePointer();
      final pane = tester.getRect(
        find.byKey(const Key('settings-content-pane')),
      );
      final content = tester.getRect(
        find.byKey(const Key('settings-main-content')),
      );
      expect(content.width, 850);
      expect(content.center.dx, closeTo(pane.center.dx, 1));
      final material = tester.widget<Material>(
        find.byKey(const Key('settings-sidebar-surface')),
      );
      expect(
        material.color,
        Theme.of(
          tester.element(find.byType(SettingsScreen)),
        ).colorScheme.surface,
      );
      await tester.dragFrom(const Offset(800, 22), const Offset(50, 20));
      await tester.pumpAndSettle();
      expect(windowCalls, contains('startDragging'));
      windowCalls.clear();
      await tester.tapAt(const Offset(800, 22));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tapAt(const Offset(800, 22));
      await tester.pumpAndSettle();
      expect(windowCalls, contains('maximize'));
      windowCalls.clear();
      await tester.tap(find.byKey(const Key('settings-open-search')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings-search-input')), findsOneWidget);
      expect(windowCalls, isNot(contains('startDragging')));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'search jumps to settings and model tasks with compact form typography',
    (tester) async {
      await pumpPolish(tester);
      await tester.tap(find.byKey(const Key('settings-open-search')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('settings-search-input')),
        '翻译功能',
      );
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('原文 → 阅读语言'), findsWidgets);
      await capturePolish(tester, 'model-task-form');
      final fields = find.byWidgetPredicate(
        (widget) => widget is ModelCompactDropdown<String>,
      );
      expect(fields, findsWidgets);
      final element = tester.element(fields.first);
      expect(Theme.of(element).textTheme.titleMedium?.fontSize, 13);
      expect(
        Theme.of(element).textTheme.titleMedium?.fontWeight,
        FontWeight.w400,
      );
      await tester.tap(fields.at(1));
      await tester.pumpAndSettle();
      await capturePolish(tester, 'model-task-dropdown');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('settings-search-input')),
        '自动登录',
      );
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(AccountSettingsSection), findsOneWidget);
      expect(find.text('启动时自动登录'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'account actions set an explicit default and auto-login without changing active account',
    (tester) async {
      final container = await pumpPolish(tester);
      await tester.tap(find.byKey(const ValueKey('settings-nav-account')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('settings-account-menu-fish')),
      );
      await tester.tap(
        find.byKey(const ValueKey('settings-account-menu-fish')),
      );
      await tester.pumpAndSettle();
      await capturePolish(tester, 'account-actions');
      await tester.tap(find.text('设为默认账号'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(accountManagerNotifierProvider.notifier)
            .defaultAccount
            ?.id,
        'fish',
      );
      expect(container.read(authNotifierProvider).accountId, 'pd');
      final automatic = find.widgetWithText(Row, '启动时自动登录');
      await tester.ensureVisible(find.text('启动时自动登录'));
      await tester.pumpAndSettle();
      final toggle = find.descendant(
        of: automatic,
        matching: find.byType(SettingsToggle),
      );
      await tester.tap(toggle.first);
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getBool(
          AuthNotifier.autoLoginPreferenceKey,
        ),
        false,
      );
      expect(container.read(authNotifierProvider).accountId, 'pd');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'redesigned settings pages remain usable at desktop and compact widths with enlarged type',
    (tester) async {
      final capture = GlobalKey();
      final shouldCapture =
          Platform.environment['CAPTURE_SETTINGS_REDESIGN'] == '1';
      final styles = shouldCapture ? Brightness.values : [Brightness.light];
      for (final brightness in styles) {
        for (final layout in [
          (1280.0, 1.0, const Locale('zh')),
          (2400.0, 1.0, const Locale('zh')),
          (740.0, 1.3, const Locale('zh')),
          (360.0, 1.3, const Locale('zh')),
          for (final locale in const [
            Locale('en'),
            Locale('ja'),
            Locale('zh', 'TW'),
            Locale('ko'),
          ]) ...[(1280.0, 1.0, locale), (360.0, 1.3, locale)],
        ]) {
          final width = layout.$1, scale = layout.$2, locale = layout.$3;
          final l10n = lookupAppLocalizations(locale);
          final chinese = locale == const Locale('zh');
          final traditional = AppLanguage.fromLocale(
            locale,
          ).isTraditionalChinese;
          final suffix = chinese ? '' : '-${locale.toLanguageTag()}';
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          await tester.binding.setSurfaceSize(Size(width, 900));
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                localUpscaleModelsProvider.overrideWith(
                  (ref) async => [
                    localUpscaleCatalog.first.withInstalled(true),
                    ...localUpscaleCatalog.skip(1),
                    ...advancedUpscaleCatalog,
                  ],
                ),
                bridgeDraftVersionProvider.overrideWith(
                  (ref) => 'fixture-draft',
                ),
                settingsFontScaleProvider.overrideWith(
                  () => _DesignSettingsScale(scale),
                ),
                themeNotifierProvider.overrideWith(
                  () => _DesignTheme(brightness),
                ),
                localStorageServiceProvider.overrideWithValue(
                  _MemorySettingsStorage()
                    .._config = const PromptAssistantConfigState(
                      providers: [
                        ProviderConfig(
                          id: 'deepseek',
                          name: 'DeepSeek',
                          baseUrl: 'https://example.test/v1',
                          preset: ProviderPreset.deepseek,
                        ),
                        ProviderConfig(
                          id: 'openai',
                          name: 'OpenAI',
                          baseUrl: 'https://example.test/v1',
                          preset: ProviderPreset.openaiChat,
                        ),
                        ProviderConfig(
                          id: 'claude',
                          name: 'Anthropic',
                          baseUrl: 'https://example.test',
                          preset: ProviderPreset.anthropic,
                        ),
                      ],
                      models: [
                        ModelConfig(
                          providerId: 'deepseek',
                          name: 'deepseek-chat',
                          displayName: 'DeepSeek Chat',
                        ),
                      ],
                      interfaces: {},
                      providerHasApiKey: {},
                    ).encode(),
                ),
                secureStorageServiceProvider.overrideWithValue(
                  _MemoryAssistantSecrets(),
                ),
                authNotifierProvider.overrideWith(_DesignAuth.new),
                accountManagerNotifierProvider.overrideWith(
                  _DesignAccounts.new,
                ),
                subscriptionNotifierProvider.overrideWith(
                  _DesignSubscription.new,
                ),
                tagCatalogRepositoryProvider.overrideWithValue(
                  _DesignCatalog(),
                ),
                databaseManagerProvider.overrideWith(
                  (ref) async =>
                      throw StateError('capture excludes database I/O'),
                ),
                danbooruTagsCacheNotifierProvider.overrideWith(
                  _DesignTagsCache.new,
                ),
                cacheStatisticsProvider.overrideWith(
                  (ref) async => CacheStatistics(
                    l1MemorySize: 0,
                    l1HitRate: 0,
                    l1MemoryBytes: 0,
                    l2HiveSize: 0,
                    l2HitRate: 0,
                    l2HiveBytes: 0,
                    l3DatabaseImageCount: 0,
                    l3DatabaseMetadataCount: 0,
                    totalHitRate: 0,
                    lastUpdated: DateTime(2026),
                  ),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.getTheme(AppStyle.geist, brightness),
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => RepaintBoundary(
                  key: capture,
                  child: MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(1)),
                    child: child!,
                  ),
                ),
                home: const SettingsScreen(),
              ),
            ),
          );
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump(const Duration(milliseconds: 250));
          await tester.pump();
          for (final destination in SettingsDestination.values) {
            debugPrint(
              "Render ${destination.name}/${width.toInt()}/$scale/${brightness.name}",
            );
            if (find
                .byType(DropdownButtonFormField<SettingsDestination>)
                .evaluate()
                .isNotEmpty) {
              await tester.tap(
                find.byWidgetPredicate(
                  (widget) =>
                      widget is DropdownButtonFormField<SettingsDestination>,
                ),
              );
              await tester.pump();
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 50)),
              );
              await tester.pump(const Duration(milliseconds: 250));
              await tester.pump();
              final label = switch (destination) {
                SettingsDestination.appearance =>
                  l10n.settings_generalAppearance,
                SettingsDestination.controls => l10n.settings_controlsShortcuts,
                SettingsDestination.generation =>
                  l10n.settings_generationPrompts,
                SettingsDestination.storage => l10n.settings_galleryFiles,
                SettingsDestination.data => l10n.settings_dictionariesCache,
                SettingsDestination.localUpscale => l10n.settings_localUpscale,
                SettingsDestination.account => l10n.settings_novelaiAccounts,
                SettingsDestination.agent => l10n.naiAgent_title,
                SettingsDestination.models => l10n.settings_modelsAndInterfaces,
                SettingsDestination.integrations =>
                  l10n.settings_connectionsIntegrations,
                SettingsDestination.privacy => l10n.settings_privacySharing2,
                SettingsDestination.about => l10n.settings_aboutDiagnostics,
              };
              await tester.ensureVisible(find.text(label).last);
              await tester.tap(find.text(label).last);
            } else {
              final nav = find.byKey(
                ValueKey('settings-nav-${destination.name}'),
              );
              await tester.ensureVisible(nav);
              await tester.tap(nav);
            }
            await tester.pump();
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 50)),
            );
            await tester.pump(const Duration(milliseconds: 250));
            await tester.pump();
            expect(
              tester.takeException(),
              isNull,
              reason:
                  '${destination.name}/${width.toInt()}/$scale/${brightness.name}$suffix',
            );
            if (const {'en', 'ko'}.contains(locale.languageCode)) {
              expect(
                _visibleHanText(tester),
                isEmpty,
                reason:
                    '${locale.languageCode} ${destination.name}/${width.toInt()}',
              );
            }
            if (traditional) {
              expect(
                simplifiedOnlyTexts(_visibleHanText(tester)),
                isEmpty,
                reason: 'Traditional ${destination.name}/${width.toInt()}',
              );
            }
            if (chinese && destination == SettingsDestination.storage) {
              final add = find.text('添加文件夹');
              await tester.ensureVisible(add);
              await tester.pump(const Duration(milliseconds: 250));
              final import = find.text('导入标签索引...');
              if (width >= 740 && import.evaluate().isNotEmpty) {
                expect(
                  (tester.getCenter(add).dy - tester.getCenter(import).dy)
                      .abs(),
                  lessThan(1),
                );
              }
            }
            if (destination == SettingsDestination.integrations) {
              expect(find.text('ComfyUI'), findsOneWidget);
              await tester.tap(
                find
                    .text(
                      AppLocalizations.of(
                        tester.element(find.byType(SettingsScreen)),
                      )!.bridge_title,
                    )
                    .first,
              );
              await tester.pump(const Duration(milliseconds: 250));
              expect(find.text('Krita Bridge'), findsNothing);
            }
            if (shouldCapture) {
              await tester.runAsync(() async {
                final image =
                    await (capture.currentContext!.findRenderObject()!
                            as RenderRepaintBoundary)
                        .toImage(pixelRatio: 1.5);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final file = File(
                  '${Platform.environment['SETTINGS_CAPTURE_DIR'] ?? '.dart_tool/settings-redesign-captures'}/${destination.name}-${brightness.name}-${width.toInt()}$suffix.png',
                );
                await file.parent.create(recursive: true);
                await file.writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('settings dialogs and account actions use the new design', (
    tester,
  ) async {
    Future<void> navigate(SettingsDestination destination, String label) async {
      if (find
          .byKey(ValueKey('settings-nav-${destination.name}'))
          .evaluate()
          .isNotEmpty) {
        final nav = find.byKey(ValueKey('settings-nav-${destination.name}'));
        await tester.ensureVisible(nav);
        await tester.tap(nav);
      } else {
        await tester.tap(
          find.byWidgetPredicate(
            (widget) => widget is DropdownButtonFormField<SettingsDestination>,
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(label).last);
        await tester.tap(find.text(label).last);
      }
      await tester.pumpAndSettle();
    }

    for (final brightness in Brightness.values) {
      for (final layout in [(1280.0, 1.0), (360.0, 1.3)]) {
        await pumpPolish(
          tester,
          width: layout.$1,
          scale: layout.$2,
          brightness: brightness,
        );

        await navigate(SettingsDestination.appearance, '常规与外观');
        await tester.ensureVisible(find.text('字体').last);
        await tester.tap(find.text('字体').last);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('settings-font-preview')), findsOneWidget);
        await capturePolish(
          tester,
          'dialog-font-${brightness.name}-${layout.$1.toInt()}',
        );
        await tester.enterText(
          find.byKey(const Key('settings-font-search')),
          'Geist',
        );
        await tester.pumpAndSettle();
        expect(find.text('Geist + HarmonyOS Sans'), findsOneWidget);
        await tester.tap(find.byTooltip('关闭').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('语言').last);
        await tester.tap(find.text('语言').last);
        await tester.pumpAndSettle();
        await capturePolish(
          tester,
          'dialog-language-${brightness.name}-${layout.$1.toInt()}',
        );
        await tester.tap(find.byTooltip('关闭').last);
        await tester.pumpAndSettle();
        await navigate(SettingsDestination.account, 'NovelAI 账号');
        expect(find.text('账号资料'), findsNothing);
        expect(find.byType(AccountSubscriptionSummary), findsOneWidget);
        expect(find.text('当前账号'), findsNothing);
        final menu = find.byKey(const Key('settings-account-menu-pd'));
        await tester.ensureVisible(menu);
        await tester.tap(menu);
        await tester.pumpAndSettle();
        await tester.tap(find.text('编辑资料'));
        await tester.pumpAndSettle();
        expect(find.text('账号详情'), findsOneWidget);
        expect(find.text('token_fixture'), findsNothing);
        await capturePolish(
          tester,
          'dialog-account-${brightness.name}-${layout.$1.toInt()}',
        );
        await tester.tap(find.byTooltip('关闭').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('更新凭据'));
        await tester.tap(find.text('更新凭据'));
        await tester.pumpAndSettle();
        expect(find.byType(AccountCredentialsDialog), findsOneWidget);
        await capturePolish(
          tester,
          'dialog-credentials-${brightness.name}-${layout.$1.toInt()}',
        );
        await tester.tap(find.byTooltip('关闭').last);
        await tester.pumpAndSettle();
        await navigate(SettingsDestination.controls, '操作与快捷键');
        await tester.ensureVisible(find.text('键盘快捷键').last);
        await tester.tap(find.text('键盘快捷键').last);
        await tester.pumpAndSettle();
        await capturePolish(
          tester,
          'dialog-shortcuts-${brightness.name}-${layout.$1.toInt()}',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });

  testWidgets('设置页按十个工作流分类，旧模型入口仍可使用', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final settings = _MemorySettingsStorage()
      .._config = const PromptAssistantConfigState(
        providers: [
          ProviderConfig(
            id: 'deepseek',
            name: 'DeepSeek',
            baseUrl: 'https://example.test/v1',
            preset: ProviderPreset.deepseek,
          ),
        ],
        models: [
          ModelConfig(
            providerId: 'deepseek',
            name: 'deepseek-chat',
            displayName: 'DeepSeek Chat',
          ),
        ],
        interfaces: {
          LauncherInterface.translate: InterfaceSlotConfig(
            providerId: 'deepseek',
            model: 'deepseek-chat',
          ),
        },
        providerHasApiKey: {},
      ).encode();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(settings),
          secureStorageServiceProvider.overrideWithValue(
            _MemoryAssistantSecrets(),
          ),
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          accountManagerNotifierProvider.overrideWith(
            _FakeAccountManagerNotifier.new,
          ),
          subscriptionNotifierProvider.overrideWith(
            _FakeSubscriptionNotifier.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.getTheme(
            AppStyle.geist,
            Platform.environment['STUDIO_APPEARANCE'] == 'dark'
                ? Brightness.dark
                : Brightness.light,
          ),
          builder: (context, child) => RepaintBoundary(
            key: settingsCaptureKey,
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.1)),
              child: child!,
            ),
          ),
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const IntegratedTitleBarShell(child: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final destination in SettingsDestination.values) {
      expect(
        find.byKey(ValueKey('settings-nav-${destination.name}')),
        findsOneWidget,
      );
    }
    for (final label in [
      '常规与外观',
      '操作与快捷键',
      '生成与提示词',
      '图库与文件',
      '词库与缓存',
      'NovelAI 账号',
      '模型与接口',
      '连接与集成',
      '隐私与分享',
      '关于与诊断',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.byType(NavigationRail), findsNothing);

    // 撤销的分类不再出现
    expect(find.text('队列'), findsNothing);
    expect(find.text('通知'), findsNothing);
    expect(find.text('数据源'), findsNothing);
    expect(find.text('ComfyUI'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('settings-nav-integrations')));
    await tester.pumpAndSettle();

    final integrations = find.byType(IntegrationsSettingsSection);
    expect(integrations, findsOneWidget);

    final tabsFinder = find.descendant(
      of: integrations,
      matching: find.byType(ManagementTabs),
    );
    expect(tabsFinder, findsOneWidget);
    final segmentLabels = tester.widget<ManagementTabs>(tabsFinder).labels;
    expect(find.byType(PromptAssistantSettingsSection), findsNothing);
    expect(segmentLabels, const ['ComfyUI', '本机桥接', '网络']);
    await tester.tap(find.byKey(const ValueKey('settings-nav-models')));
    await tester.pumpAndSettle();
    expect(find.text('服务商'), findsOneWidget);
    expect(find.text('功能接口'), findsOneWidget);
    if (Platform.environment['CAPTURE_MODEL_MANAGEMENT'] == '1') {
      await tester.runAsync(() async {
        final image =
            await (settingsCaptureKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
          '.dart_tool/model-management-captures/settings-${Platform.environment['STUDIO_APPEARANCE'] ?? 'light'}.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('第三方接口可手动添加模型 ID', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = _MemorySettingsStorage();
    final captureKey = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => storage),
          secureStorageServiceProvider.overrideWith(
            (ref) => _MemoryAssistantSecrets(),
          ),
        ],
        child: RepaintBoundary(
          key: captureKey,
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: PromptAssistantSettingsSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PromptAssistantSettingsSection)),
    );
    await container
        .read(promptAssistantConfigProvider.notifier)
        .upsertProvider(
          const ProviderConfig(
            id: 'custom',
            name: '中转服务',
            baseUrl: 'https://example.test/v1',
          ),
        );
    await tester.pumpAndSettle();

    await tester.tap(find.text('中转服务').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('AI_SERVICE_CAPTURE')) {
      await tester.runAsync(() async {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/qa/ai-service-editor.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
      });
    }
    await tester.ensureVisible(
      find.byKey(const Key('ai-service-manual-model-id')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('ai-service-manual-model-id')),
      'relay-model-v5',
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('service-add-custom-model')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('service-add-custom-model')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('service-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('service-save')));
    await tester.pumpAndSettle();
    await tester.pump();

    final models = container
        .read(promptAssistantConfigProvider)
        .modelsForProvider(providerId: 'custom');
    expect(models.map((model) => model.name), contains('relay-model-v5'));
    await container
        .read(promptAssistantConfigProvider.notifier)
        .setInterfaceProvider(LauncherInterface.translate, 'custom');
    expect(
      container
          .read(promptAssistantConfigProvider)
          .promptTranslationRoute
          ?.model
          .name,
      'relay-model-v5',
    );
  });

  testWidgets('服务高级设置保存超时并保留既有安全请求头', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = _MemorySettingsStorage();
    final secrets = _MemoryAssistantSecrets()
      ..headers['custom'] = '{"X-Project":"studio"}';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => storage),
          secureStorageServiceProvider.overrideWith((ref) => secrets),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: PromptAssistantSettingsSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PromptAssistantSettingsSection)),
    );
    await container
        .read(promptAssistantConfigProvider.notifier)
        .upsertProvider(
          const ProviderConfig(
            id: 'custom',
            name: '中转服务',
            baseUrl: 'https://example.test/v1',
          ),
        );
    await tester.pumpAndSettle();
    await tester.tap(find.text('中转服务').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('高级设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('高级设置'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('service-request-timeout')),
      '75',
    );
    expect(find.text('自定义请求头'), findsNothing);
    expect(find.text('允许图片输入'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('service-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('service-save')));
    await tester.pumpAndSettle();
    expect(
      container
          .read(promptAssistantConfigProvider)
          .providers
          .single
          .timeoutSeconds,
      75,
    );
    expect(jsonDecode(secrets.headers['custom']!), {'X-Project': 'studio'});
    expect(tester.takeException(), isNull);
  });
}

/// Language names stay in their own script and account nicknames are fixture
/// data; everything else on English pages should be free of Han characters.
const _allowedHanText = {'中文', '简体中文', '繁體中文', '日本語', '鲟', '鲟鱼'};

/// Visible text that still contains Han characters.
List<String> _visibleHanText(WidgetTester tester) {
  final han = RegExp(r'[\u4e00-\u9fff]');
  return [
    for (final element in find.byType(RichText).evaluate())
      if ((element.widget as RichText).text.toPlainText() case final text
          when han.hasMatch(text) && !_allowedHanText.contains(text))
        text,
  ];
}
