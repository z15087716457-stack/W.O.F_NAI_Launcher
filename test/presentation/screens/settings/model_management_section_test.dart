import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_task_definitions.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_service.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/model_management_section.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/compact_service_connection.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_ui_theme.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_typography_scope.dart';

class MemorySettings extends LocalStorageService {
  final values = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values[key] as T? ?? defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }

  @override
  String getLocaleCode() => 'zh';
}

class MemorySecrets extends SecureStorageService {
  final keys = <String, String>{}, headers = <String, String>{};
  @override
  Future<String?> getPromptAssistantApiKey(String providerId) async =>
      keys[providerId];
  @override
  Future<void> savePromptAssistantApiKey(String providerId, String key) async {
    keys[providerId] = key;
  }

  @override
  Future<void> deletePromptAssistantApiKey(String providerId) async {
    keys.remove(providerId);
  }

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
}

const sampleConfig = PromptAssistantConfigState(
  providers: [
    ProviderConfig(
      id: 'deepseek',
      name: 'DeepSeek',
      baseUrl: 'https://api.example.test/v1',
      preset: ProviderPreset.deepseek,
    ),
    ProviderConfig(
      id: 'local',
      name: '本地模型',
      baseUrl: 'http://localhost:1234/v1',
      preset: ProviderPreset.lmStudioChat,
      enabled: false,
    ),
  ],
  models: [
    ModelConfig(
      providerId: 'deepseek',
      name: 'deepseek-chat',
      displayName: 'DeepSeek Chat',
      contextWindow: 128000,
    ),
    ModelConfig(
      providerId: 'deepseek',
      name: 'deepseek-reasoner',
      displayName: 'DeepSeek Reasoner',
      reasoningEffort: 'high',
    ),
    ModelConfig(providerId: 'local', name: 'local-model', displayName: '本地模型'),
  ],
  interfaces: {
    LauncherInterface.translate: InterfaceSlotConfig(
      providerId: 'deepseek',
      model: 'deepseek-chat',
    ),
    LauncherInterface.tagTranslate: InterfaceSlotConfig(
      providerId: 'deepseek',
      model: 'deepseek-chat',
    ),
  },
  providerHasApiKey: {},
);

final captureKey = GlobalKey();
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_MODEL_MANAGEMENT'] != '1') return;
  debugDisableShadows = false;
  void repaint(RenderObject render) {
    render.markNeedsPaint();
    render.visitChildren(repaint);
  }

  repaint(captureKey.currentContext!.findRenderObject()!);
  await tester.pump();
  await tester.runAsync(() async {
    final image =
        await (captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('.dart_tool/model-management-captures')
      ..createSync(recursive: true);
    File(
      '${folder.path}/$name-${Platform.environment['STUDIO_APPEARANCE'] ?? 'light'}.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
  debugDisableShadows = true;
}

Future<ProviderContainer> pumpManagement(
  WidgetTester tester, {
  Size size = const Size(1200, 820),
  double scale = 1,
  MemorySecrets? secrets,
  Dio? dio,
  MemorySettings? settings,
  PromptAssistantConfigState config = sampleConfig,
  Locale locale = const Locale('zh'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final storage = settings ?? MemorySettings();
  storage.values.putIfAbsent(
    StorageKeys.promptAssistantConfigJson,
    config.encode,
  );
  storage.values[StorageKeys.settingsFontScale] = scale;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (dio != null) promptAssistantDioProvider.overrideWithValue(dio),
        localStorageServiceProvider.overrideWithValue(storage),
        secureStorageServiceProvider.overrideWithValue(
          secrets ?? MemorySecrets(),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: settingsUiTheme(
          AppTheme.getTheme(
            AppStyle.geist,
            Platform.environment['STUDIO_APPEARANCE'] == 'dark'
                ? Brightness.dark
                : Brightness.light,
          ),
        ),
        builder: (context, child) => SettingsTypographyScope(
          child: RepaintBoundary(key: captureKey, child: child!),
        ),
        home: const Scaffold(body: ModelManagementSection()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(ModelManagementSection)),
  );
}

void main() {
  setUpAll(() async {
    await ModelCatalogRepository.load();
    if (Platform.environment['CAPTURE_MODEL_MANAGEMENT'] != '1') return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final spec in [
    (const Size(1200, 820), 1.0, 'wide'),
    (const Size(360, 920), 1.3, 'compact'),
  ]) {
    testWidgets(
      '${spec.$3} blank key preserves the saved key and typed key replaces it on save',
      (tester) async {
        final secrets = MemorySecrets()..keys['deepseek'] = 'old-test-key';
        await pumpManagement(
          tester,
          secrets: secrets,
          size: spec.$1,
          scale: spec.$2,
        );
        await tapVisible(
          tester,
          find.byKey(const Key('service-edit-connection')),
        );
        final connection = tester.widget<CompactServiceConnection>(
          find.byType(CompactServiceConnection),
        );
        final keyField = find.byWidgetPredicate(
          (w) => w is TextField && identical(w.controller, connection.apiKey),
        );
        expect(connection.apiKey.text, isEmpty);
        expect(tester.widget<TextField>(keyField).enabled, isTrue);
        expect(find.text('清除密钥'), findsNothing);
        expect(
          find.descendant(
            of: find.byType(CompactServiceConnection),
            matching: find.byType(Checkbox),
          ),
          findsNothing,
        );
        await Scrollable.ensureVisible(
          tester.element(find.text(connection.preset.connectionHint)),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
        await tester.pumpAndSettle();
        await capture(tester, 'key-cleanup-${spec.$3}');
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.byKey(const Key('service-save')));
        expect(secrets.keys['deepseek'], 'old-test-key');
        await tapVisible(
          tester,
          find.byKey(const Key('service-edit-connection')),
        );
        final updated = tester.widget<CompactServiceConnection>(
          find.byType(CompactServiceConnection),
        );
        final replacement = find.byWidgetPredicate(
          (w) => w is TextField && identical(w.controller, updated.apiKey),
        );
        await tester.ensureVisible(replacement);
        await tester.pumpAndSettle();
        await tester.enterText(replacement, 'new-test-key');
        expect(secrets.keys['deepseek'], 'old-test-key');
        await tapVisible(tester, find.byKey(const Key('service-save')));
        expect(secrets.keys['deepseek'], 'new-test-key');
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'changing vendors preserves stored credentials until save and requires the new key',
    (tester) async {
      final secrets = MemorySecrets()
        ..keys['deepseek'] = 'old-test-key'
        ..headers['deepseek'] = '{"X-Project":"old"}';
      final container = await pumpManagement(tester, secrets: secrets);
      await tapVisible(
        tester,
        find.byKey(const Key('service-edit-connection')),
      );
      await tapVisible(
        tester,
        find.byKey(const Key('service-provider-picker')),
      );
      await tester.enterText(
        find.byKey(const Key('provider-search')),
        'OpenAI',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('choose-provider-openaiResponses')),
      );
      await tester.pumpAndSettle();
      expect(secrets.keys['deepseek'], 'old-test-key');
      expect(
        container.read(promptAssistantConfigProvider).providers.first.preset,
        ProviderPreset.deepseek,
      );
      final keyField = find.byWidgetPredicate(
        (w) => w is TextField && w.obscureText,
      );
      await tester.ensureVisible(keyField);
      await tester.pumpAndSettle();
      await tester.enterText(keyField, 'new-test-key');
      await tapVisible(tester, find.byKey(const Key('service-save')));
      final saved = container
          .read(promptAssistantConfigProvider)
          .providers
          .firstWhere((p) => p.id == 'deepseek');
      expect(saved.protocol, ProviderProtocol.openaiResponses);
      expect(saved.baseUrl, 'https://api.openai.com/v1');
      expect(secrets.keys['deepseek'], 'new-test-key');
      expect(
        await secrets.getPromptAssistantHeaders('deepseek'),
        anyOf(isNull, '{}'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'offline additions retain manual provenance without filling the API list',
    (tester) async {
      final container = await pumpManagement(tester);
      expect(find.byKey(const Key('service-catalog-list')), findsNothing);
      await tester.ensureVisible(
        find.byKey(const Key('ai-service-manual-model-id')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('ai-service-manual-model-id')),
        'deepseek-flash',
      );
      await tapVisible(
        tester,
        find.byKey(const Key('service-add-custom-model')),
      );
      expect(find.byKey(const Key('service-catalog-list')), findsNothing);
      await tapVisible(tester, find.byKey(const Key('service-save')));
      final selected = container
          .read(promptAssistantConfigProvider)
          .models
          .firstWhere((m) => m.name == 'deepseek-flash');
      expect(selected.source, ModelSource.manual);
      expect(
        container
            .read(promptAssistantConfigProvider)
            .models
            .any((m) => m.name == 'deepseek-chat'),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'management pages are usable without model calls and preserve unsaved service edits',
    (tester) async {
      final container = await pumpManagement(tester);
      expect(find.text('DeepSeek'), findsWidgets);
      expect(find.byType(TextField), findsNWidgets(3));
      await capture(tester, 'provider');
      await capture(tester, 'models');
      await tapVisible(
        tester,
        find.byKey(const Key('service-model-parameters-deepseek-chat')),
      );
      await capture(tester, 'model-parameters');
      expect(find.text('采样与能力'), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('parameter-max-tokens')));
      await tester.enterText(
        find.byKey(const Key('parameter-max-tokens')),
        '8000',
      );
      await tapVisible(tester, find.byKey(const Key('service-save')));
      expect(
        container
            .read(promptAssistantConfigProvider)
            .models
            .firstWhere((model) => model.name == 'deepseek-chat')
            .maxOutputTokens,
        8000,
      );
      await tapVisible(
        tester,
        find.byKey(const Key('service-advanced-toggle')),
      );
      await capture(tester, 'advanced');
      await tapVisible(
        tester,
        find.byKey(const Key('service-edit-connection')),
      );
      await capture(tester, 'connection-edit');
      final name = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.controller?.text == 'DeepSeek',
      );
      await tester.enterText(name, '我的服务');
      await tester.pumpAndSettle();
      await tester.tap(find.text('功能接口').first);
      await tester.pumpAndSettle();
      expect(find.text('保留当前编辑？'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        container.read(promptAssistantConfigProvider).providers.first.name,
        'DeepSeek',
      );
      await tapVisible(tester, find.byKey(const Key('service-save')));
      expect(
        container.read(promptAssistantConfigProvider).providers.first.name,
        '我的服务',
      );
      await tester.tap(find.text('功能接口').first);
      await tester.pumpAndSettle();
      await capture(tester, 'task');
      expect(find.text('参数'), findsNothing);
      expect(find.byKey(const Key('parameter-temperature')), findsNothing);
      await tester.tap(find.byKey(const Key('task-save')));
      await tester.pumpAndSettle();
      expect(
        container
            .read(promptAssistantConfigProvider)
            .models
            .firstWhere((m) => m.name == 'deepseek-chat')
            .maxOutputTokens,
        8000,
      );
      await tester.tap(find.text('预设与提示词').first);
      await tester.pumpAndSettle();
      await capture(tester, 'preset');
      await tester.tap(find.byKey(const Key('preset-create')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          PopupMenuItem<LauncherInterface>,
          LauncherInterface.translate.title,
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('preset-name')), '我的翻译规则');
      await tester.tap(find.byKey(const Key('preset-save')));
      await tester.pumpAndSettle();
      expect(
        container.read(promptAssistantConfigProvider).presets.single.name,
        '我的翻译规则',
      );
      await tester.tap(find.text('请求记录').first);
      await tester.pumpAndSettle();
      await capture(tester, 'history');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('compact management layout supports enlarged text', (
    tester,
  ) async {
    await pumpManagement(tester, size: const Size(600, 760), scale: 1.3);
    await capture(tester, 'compact-provider');
    await tester.tap(find.text('功能接口').first);
    await tester.pumpAndSettle();
    await capture(tester, 'compact-task');
    await tester.tap(find.text('预设与提示词').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'collapsing a connection preserves its draft and guards linked navigation',
    (tester) async {
      final container = await pumpManagement(tester);
      await tapVisible(
        tester,
        find.byKey(const Key('service-edit-connection')),
      );
      final name = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.controller?.text == 'DeepSeek',
      );
      await tester.enterText(name, '未保存的名称');
      await tapVisible(
        tester,
        find.byKey(const Key('service-edit-connection')),
      );
      expect(find.byType(TextField), findsNWidgets(3));
      expect(
        container.read(promptAssistantConfigProvider).providers.first.name,
        'DeepSeek',
      );
      await tapVisible(tester, find.text(LauncherInterface.translate.title));
      expect(find.text('保留当前编辑？'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byKey(const Key('service-edit-connection')),
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.controller?.text == '未保存的名称',
        ),
        findsOneWidget,
      );
      await tapVisible(tester, find.byKey(const Key('service-save')));
      expect(
        container.read(promptAssistantConfigProvider).providers.first.name,
        '未保存的名称',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('short windows keep model editing scrollable', (tester) async {
    await pumpManagement(tester, size: const Size(1000, 500));
    await tester.ensureVisible(
      find.byKey(const Key('ai-service-manual-model-id')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('a stale service draft cannot overwrite a newer saved edit', (
    tester,
  ) async {
    final container = await pumpManagement(tester);
    await tapVisible(tester, find.byKey(const Key('service-edit-connection')));
    final name = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller?.text == 'DeepSeek',
    );
    await tester.enterText(name, '旧草稿');
    await tester.pumpAndSettle();
    await container
        .read(promptAssistantConfigProvider.notifier)
        .upsertProvider(sampleConfig.providers.first.copyWith(name: '新的已保存名称'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('service-save')));
    expect(
      container.read(promptAssistantConfigProvider).providers.first.name,
      '新的已保存名称',
    );
    expect(find.textContaining('别处修改'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
