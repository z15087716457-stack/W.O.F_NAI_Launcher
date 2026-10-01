import 'dart:io';
import 'dart:ui' as ui;
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
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/model_management_section.dart';
import '../../../helpers/studio_capture_fonts.dart';

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
Future<void> capture(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_MODEL_MANAGEMENT'] != '1') return;
  debugDisableShadows = false;
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
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final storage = MemorySettings()
    ..values[StorageKeys.promptAssistantConfigJson] = sampleConfig.encode();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storage),
        secureStorageServiceProvider.overrideWithValue(MemorySecrets()),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.getTheme(
          AppStyle.geist,
          Platform.environment['STUDIO_APPEARANCE'] == 'dark'
              ? Brightness.dark
              : Brightness.light,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
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
    if (Platform.environment['CAPTURE_MODEL_MANAGEMENT'] != '1') return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets(
    'management pages are usable without model calls and preserve unsaved service edits',
    (tester) async {
      final container = await pumpManagement(tester);
      expect(find.text('DeepSeek'), findsWidgets);
      await capture(tester, 'provider');
      await tester.tap(find.text('模型').first);
      await tester.pumpAndSettle();
      await capture(tester, 'models');
      await tester.tap(find.text('DeepSeek Chat').first);
      await tester.pumpAndSettle();
      await capture(tester, 'model-parameters');
      await tester.enterText(
        find.byKey(const Key('parameter-temperature')),
        '0.4',
      );
      await tester.tap(find.text('保存').first);
      await tester.pumpAndSettle();
      expect(
        container
            .read(promptAssistantConfigProvider)
            .models
            .firstWhere((model) => model.name == 'deepseek-chat')
            .temperature,
        0.4,
      );
      await tester.tap(find.text('高级设置').first);
      await tester.pumpAndSettle();
      await capture(tester, 'advanced');
      await tester.tap(find.text('连接').first);
      await tester.pumpAndSettle();
      final name = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.controller?.text == 'DeepSeek',
      );
      await tester.enterText(name, '我的服务');
      await tester.pumpAndSettle();
      await tester.tap(find.text('功能接口').first);
      await tester.pumpAndSettle();
      expect(find.text('保留当前编辑？'), findsOneWidget);
      await tester.tap(find.text('继续编辑'));
      await tester.pumpAndSettle();
      expect(
        container.read(promptAssistantConfigProvider).providers.first.name,
        'DeepSeek',
      );
      await tester.tap(find.text('保存').first);
      await tester.pumpAndSettle();
      expect(
        container.read(promptAssistantConfigProvider).providers.first.name,
        '我的服务',
      );
      await tester.tap(find.text('功能接口').first);
      await tester.pumpAndSettle();
      await capture(tester, 'task');
      await tester.tap(find.text('参数').first);
      await tester.pumpAndSettle();
      await capture(tester, 'task-parameters');
      await tester.enterText(
        find.byKey(const Key('parameter-temperature')),
        'invalid',
      );
      await tester.tap(find.text('模型与预设').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('task-save')));
      await tester.pumpAndSettle();
      expect(find.textContaining('无效数字'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('parameter-temperature')),
        '0.2',
      );
      await tester.tap(find.byKey(const Key('task-save')));
      await tester.pumpAndSettle();
      expect(
        container
            .read(promptAssistantConfigProvider)
            .interfaceFor(LauncherInterface.translate)
            .parameters
            .temperature,
        0.2,
      );
      await tester.tap(find.text('预设与提示词').first);
      await tester.pumpAndSettle();
      await capture(tester, 'preset');
      await tester.tap(find.byKey(const Key('preset-clone')));
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
  testWidgets('short windows keep model editing scrollable', (tester) async {
    await pumpManagement(tester, size: const Size(1000, 500));
    await tester.tap(find.text('模型').first);
    await tester.pumpAndSettle();
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
    final name = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller?.text == 'DeepSeek',
    );
    await tester.enterText(name, '旧草稿');
    await tester.pumpAndSettle();
    await container
        .read(promptAssistantConfigProvider.notifier)
        .upsertProvider(sampleConfig.providers.first.copyWith(name: '新的已保存名称'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存').first);
    await tester.pumpAndSettle();
    expect(
      container.read(promptAssistantConfigProvider).providers.first.name,
      '新的已保存名称',
    );
    expect(find.textContaining('别处修改'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
