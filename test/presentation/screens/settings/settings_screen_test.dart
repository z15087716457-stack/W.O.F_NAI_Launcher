import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
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

void main() {
  late Directory hiveDir;

  setUpAll(() async {
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

  testWidgets('设置页导航为 9 个分类', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          accountManagerNotifierProvider.overrideWith(
            _FakeAccountManagerNotifier.new,
          ),
          subscriptionNotifierProvider.overrideWith(
            _FakeSubscriptionNotifier.new,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: IntegratedTitleBarShell(child: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations.length, 9);

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

    final promptAssistantSection = find.byType(PromptAssistantSettingsSection);
    expect(promptAssistantSection, findsOneWidget);
    expect(
      find.descendant(of: promptAssistantSection, matching: find.text('模型与接口')),
      findsOneWidget,
    );
    expect(segmentLabels, const ['模型与接口', 'ComfyUI', 'Krita']);
  });

  testWidgets('第三方接口可手动添加模型 ID', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = _MemorySettingsStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PromptAssistantSettingsSection(),
            ),
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

    await tester.tap(find.text('手动添加模型'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'relay-model-v5');
    await tester.pump();
    await tester.tap(find.text('保存'));
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
}
