import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_task_definitions.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/model_request_history_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/prompt_assistant_adapter.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/model_management_widgets.dart';
import 'model_management_section_test.dart' as harness;
import '../../../helpers/studio_capture_fonts.dart';

PromptAssistantConfigState get _config => harness.sampleConfig.copyWith(
  models: [
    const ModelConfig(
      providerId: 'deepseek',
      name: 'deepseek-chat',
      displayName: 'DeepSeek Chat',
      contextWindow: 128000,
      maxOutputTokens: 8192,
      reasoningEfforts: ['none', 'low', 'high'],
      reasoningEffort: 'high',
    ),
    const ModelConfig(
      providerId: 'deepseek',
      name: 'deepseek-reasoner',
      displayName: 'DeepSeek Reasoner',
      contextWindow: 256000,
      maxOutputTokens: 16384,
    ),
    for (var i = 0; i < 20; i++)
      ModelConfig(
        providerId: 'deepseek',
        name: 'catalog-model-${i.toString().padLeft(2, '0')}',
        displayName: '离线目录示例 ${i + 1}',
        contextWindow: 128000,
        maxOutputTokens: 8192,
      ),
  ],
);

void main() {
  setUpAll(() async {
    await ModelCatalogRepository.load();
    if (Platform.environment['CAPTURE_MODEL_MANAGEMENT'] != '1') return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets(
    'dense model catalog has one header, aligned metadata, and filtered selection',
    (tester) async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': [
                    for (final model in _config.models) {'id': model.name},
                  ],
                },
              ),
            ),
          ),
        );
      addTearDown(dio.close);
      await harness.pumpManagement(tester, config: _config, dio: dio);
      expect(find.byKey(const Key('service-catalog-list')), findsNothing);
      await harness.tapVisible(
        tester,
        find.byKey(const Key('service-fetch-catalog')),
      );
      expect(find.text('该服务的模型'), findsOneWidget);
      expect(find.text('获取列表'), findsOneWidget);
      expect(
        find.byKey(const Key('service-catalog-select-all')),
        findsOneWidget,
      );
      final row = find.byKey(const Key('catalog-model-deepseek-chat'));
      final firstRowHeight = tester.getSize(row).height;
      expect(firstRowHeight, lessThanOrEqualTo(36));
      expect(find.text('128K · 8.2K'), findsWidgets);
      await harness.capture(tester, 'refinement-catalog');
      await tester.enterText(
        find.byKey(const Key('service-catalog-search')),
        'deepseek-chat',
      );
      await tester.pumpAndSettle();
      expect(row, findsOneWidget);
      expect(
        find.byKey(const Key('catalog-model-deepseek-reasoner')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('service-catalog-select-all')));
      await tester.pumpAndSettle();
      final checkbox = find.descendant(
        of: row,
        matching: find.byType(Checkbox),
      );
      expect(tester.widget<Checkbox>(checkbox).value, isFalse);
      await tester.tap(find.byKey(const Key('service-catalog-select-all')));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(checkbox).value, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'thinking pill only offers declared levels and persists an explicit off',
    (tester) async {
      final container = await harness.pumpManagement(tester, config: _config);
      await harness.tapVisible(tester, find.text('功能接口').first);
      await harness.tapVisible(tester, find.byKey(const Key('task-reasoning')));
      expect(find.byKey(const Key('task-reasoning-none')), findsOneWidget);
      expect(find.byKey(const Key('task-reasoning-low')), findsOneWidget);
      expect(find.byKey(const Key('task-reasoning-max')), findsNothing);
      await harness.capture(tester, 'refinement-thinking-menu');
      await tester.tap(find.byKey(const Key('task-reasoning-none')));
      await tester.pumpAndSettle();
      expect(find.text('思考 · 关闭'), findsOneWidget);
      await harness.tapVisible(tester, find.byKey(const Key('task-save')));
      expect(
        container
            .read(promptAssistantConfigProvider)
            .interfaceFor(LauncherInterface.translate)
            .reasoningEffort,
        'none',
      );
      await harness.tapVisible(tester, find.byKey(const Key('task-reasoning')));
      await tester.tap(find.byKey(const Key('task-reasoning-inherit')));
      await tester.pumpAndSettle();
      await harness.tapVisible(tester, find.byKey(const Key('task-save')));
      expect(
        container
            .read(promptAssistantConfigProvider)
            .interfaceFor(LauncherInterface.translate)
            .reasoningEffort,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('provider picker is a wide flat searchable grid', (tester) async {
    await harness.pumpManagement(tester);
    await harness.tapVisible(
      tester,
      find.byKey(const Key('service-edit-connection')),
    );
    expect(
      find.byKey(const Key('service-protocol-openaiChatCompletions')),
      findsOneWidget,
    );
    await harness.tapVisible(
      tester,
      find.byKey(const Key('service-provider-picker')),
    );
    expect(tester.getSize(find.byType(Dialog)).width, greaterThan(800));
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('国内厂商'), findsNothing);
    expect(find.text('国际厂商'), findsNothing);
    expect(find.text('聚合平台'), findsNothing);
    await harness.capture(tester, 'refinement-provider-picker');
    await tester.enterText(
      find.byKey(const Key('provider-search')),
      'DeepSeek',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('choose-provider-deepseek')), findsOneWidget);
    expect(
      find.byKey(const Key('choose-provider-openaiResponses')),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('choose-provider-deepseek')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'presets use task icons and create an associated user entry from the click menu',
    (tester) async {
      final container = await harness.pumpManagement(tester);
      await harness.tapVisible(tester, find.text('预设与提示词').first);
      expect(find.text('对照默认'), findsNothing);
      expect(find.text('复制并编辑'), findsNothing);
      final builtin = find.widgetWithText(ManagementListItem, '百科正文翻译');
      expect(
        find.descendant(
          of: builtin,
          matching: find.byIcon(Icons.menu_book_outlined),
        ),
        findsOneWidget,
      );
      expect(find.text('Studio 默认 · 百科正文翻译'), findsNothing);
      await harness.capture(tester, 'refinement-presets');
      await harness.tapVisible(tester, find.byKey(const Key('preset-create')));
      expect(find.byType(PopupMenuItem<LauncherInterface>), findsNWidgets(4));
      await harness.capture(tester, 'refinement-preset-menu');
      final wiki = find.widgetWithText(
        PopupMenuItem<LauncherInterface>,
        '百科正文翻译',
      );
      await tester.tap(wiki);
      await tester.pumpAndSettle();
      expect(find.text('用户'), findsWidgets);
      await harness.tapVisible(tester, find.byKey(const Key('preset-save')));
      final saved = container.read(promptAssistantConfigProvider);
      expect(saved.presets.single.task, LauncherInterface.wikiTranslate);
      expect(
        saved.interfaceFor(LauncherInterface.wikiTranslate).presetId,
        saved.presets.single.id,
      );
      expect(
        saved.presets.single.prompt,
        LauncherInterface.wikiTranslate.builtinPreset.prompt,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('full request details stay scrollable with a fixed copy action', (
    tester,
  ) async {
    final container = await harness.pumpManagement(tester);
    final history = container.read(modelRequestHistoryProvider);
    final id = history.begin(
      const PromptAssistantRequest(
        sessionId: 'offline',
        provider: ProviderConfig(
          id: 'test',
          name: '测试服务',
          baseUrl: 'https://example.test/v1',
        ),
        model: 'test-model',
        systemPrompt: '完整规则',
        userParts: [],
        apiKey: null,
        taskName: '原文 → 阅读语言',
      ),
    );
    history.sent(
      id,
      ModelRequestExchange(
        time: DateTime(2026, 10, 2),
        method: 'POST',
        url: 'https://example.test/v1/chat/completions',
        requestHeaders: const {
          'Authorization': '[已脱敏]',
          'Content-Type': 'application/json',
        },
        requestBody: {
          'messages': [
            for (var i = 0; i < 80; i++)
              {'role': 'user', 'content': '完整请求第 $i 行'},
          ],
        },
        responseHeaders: const {'x-request-id': 'offline-id'},
        statusCode: 200,
        responseBody: const {
          'choices': [
            {
              'message': {'content': '完整响应'},
            },
          ],
        },
      ),
    );
    history.update(id, '成功', output: '完整响应');
    await harness.tapVisible(tester, find.text('请求记录').first);
    await harness.tapVisible(tester, find.text('原文 → 阅读语言 · test-model'));
    expect(tester.getSize(find.byType(Dialog)).width, greaterThan(900));
    await tester.tap(find.text('请求').last);
    await tester.pumpAndSettle();
    final text = tester
        .widget<SelectableText>(
          find.byKey(const Key('request-details-content')),
        )
        .data!;
    expect(text, contains('完整请求第 79 行'));
    await harness.capture(tester, 'refinement-request-details');
    await tester.drag(
      find.byKey(const Key('request-details-scroll-1')),
      const Offset(0, -550),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('request-details-copy')).hitTestable(),
      findsOneWidget,
    );
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.tap(find.byKey(const Key('request-details-copy')));
    await tester.pumpAndSettle();
    expect(copied, text);
    await tester.tap(find.text('响应').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const Key('request-details-content')),
          )
          .data,
      contains('完整响应'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('advanced controls and picker handle a short enlarged layout', (
    tester,
  ) async {
    await harness.pumpManagement(
      tester,
      size: const Size(820, 510),
      scale: 1.5,
    );
    await harness.tapVisible(
      tester,
      find.byKey(const Key('service-advanced-toggle')),
    );
    expect(find.byKey(const Key('service-request-timeout')), findsOneWidget);
    expect(find.byKey(const Key('service-max-concurrency')), findsOneWidget);
    expect(find.byKey(const Key('service-retry-attempts')), findsOneWidget);
    expect(find.text('允许图片输入'), findsNothing);
    expect(find.text('自定义请求头'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('service-retry-attempts')));
    await tester.pumpAndSettle();
    await harness.capture(tester, 'refinement-advanced-compact');
    await harness.tapVisible(
      tester,
      find.byKey(const Key('service-edit-connection')),
    );
    await harness.tapVisible(
      tester,
      find.byKey(const Key('service-provider-picker')),
    );
    await harness.capture(tester, 'refinement-provider-picker-compact');
    await tester.enterText(find.byKey(const Key('provider-search')), 'Ollama');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('choose-provider-ollama')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
