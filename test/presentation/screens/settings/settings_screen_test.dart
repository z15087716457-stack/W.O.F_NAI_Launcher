import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import '../../../helpers/studio_capture_fonts.dart';

import 'package:flutter/material.dart';
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
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/integrations_settings_section.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/prompt_assistant_settings_section.dart';
import 'package:nai_launcher/presentation/screens/settings/settings_screen.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

class _FakeAccountManagerNotifier extends AccountManagerNotifier {
  @override
  AccountManagerState build() => const AccountManagerState();
}

class _FakeSubscriptionNotifier extends SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionStateInitial();
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
    if (Platform.environment['CAPTURE_MODEL_MANAGEMENT'] == '1') {
      await loadStudioCaptureFonts();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
    hiveDir = Directory.systemTemp.createTempSync('settings_screen_hive_');
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

  testWidgets('设置页导航为 10 个分类', (tester) async {
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
          builder: (context, child) =>
              RepaintBoundary(key: settingsCaptureKey, child: child!),
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const IntegratedTitleBarShell(child: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations.length, 10);

    final labels = rail.destinations
        .map((destination) => (destination.label as Text).data)
        .toList();
    expect(labels, const [
      '账户',
      '外观',
      '生成',
      '数据与存储',
      '安全与分享',
      '网络',
      '快捷键',
      '模型与接口',
      '集成',
      '关于',
    ]);

    final icons = rail.destinations
        .map((destination) => (destination.icon as Icon).icon)
        .toList();
    expect(icons, const [
      Icons.person_outline,
      Icons.palette_outlined,
      Icons.tune_outlined,
      Icons.storage_outlined,
      Icons.shield_outlined,
      Icons.network_check_outlined,
      Icons.keyboard_outlined,
      Icons.hub_outlined,
      Icons.extension_outlined,
      Icons.info_outlined,
    ]);

    final selectedIcons = rail.destinations
        .map((destination) => (destination.selectedIcon as Icon).icon)
        .toList();
    expect(selectedIcons, const [
      Icons.person,
      Icons.palette,
      Icons.tune,
      Icons.storage,
      Icons.shield,
      Icons.network_check,
      Icons.keyboard,
      Icons.hub,
      Icons.extension,
      Icons.info,
    ]);

    // 撤销的分类不再出现
    expect(find.text('队列'), findsNothing);
    expect(find.text('通知'), findsNothing);
    expect(find.text('数据源'), findsNothing);
    expect(find.text('ComfyUI'), findsNothing);

    await tester.tap(find.byIcon(Icons.extension_outlined));
    await tester.pumpAndSettle();

    final integrations = find.byType(IntegrationsSettingsSection);
    expect(integrations, findsOneWidget);

    final segmentedButton = find.descendant(
      of: integrations,
      matching: find.byType(SegmentedButton<int>),
    );
    expect(segmentedButton, findsOneWidget);

    final segments = tester
        .widget<SegmentedButton<int>>(segmentedButton)
        .segments;
    final segmentLabels = segments
        .map((segment) => (segment.label as Text).data)
        .toList();

    expect(find.byType(PromptAssistantSettingsSection), findsNothing);
    expect(segmentLabels, const ['ComfyUI', 'Krita']);
    await tester.tap(find.byIcon(Icons.hub_outlined));
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
    await tester.tap(find.text('模型').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('ai-service-manual-model-id')),
      'relay-model-v5',
    );
    await tester.pump();
    await tester.ensureVisible(find.byTooltip('添加自定义模型'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('添加自定义模型'));
    await tester.pump();
    await tester.ensureVisible(find.text('保存').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存').first);
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

  testWidgets('服务高级设置保存超时和安全请求头', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = _MemorySettingsStorage();
    final secrets = _MemoryAssistantSecrets();
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
    await tester.tap(find.text('高级设置'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '请求超时（秒）'), '75');
    await tester.ensureVisible(find.text('自定义请求头').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('自定义请求头').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加请求头'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('ai-header-name-0')),
      'X-Project',
    );
    await tester.enterText(
      find.byKey(const Key('ai-header-value-0')),
      'studio',
    );
    await tester.tap(find.text('应用'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('保存').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存').first);
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
