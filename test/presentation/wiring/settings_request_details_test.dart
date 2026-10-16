import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_task_definitions.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/model_request_history_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/prompt_assistant_adapter.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/model_request_details_dialog.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_page.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_models.dart';

import '../../helpers/studio_capture_fonts.dart';
import '../../helpers/uiux_frontend_capture.dart';
import '../screens/settings/model_management_section_test.dart'
    show MemorySettings, MemorySecrets;

void main() {
  setUpAll(loadStudioCaptureFonts);
  late ProviderContainer container;
  late ModelRequestHistory history;
  late ModelCatalogRepository? previousCatalog;
  late SettingsModelsData view;
  late SettingsModelActions actions;

  String seed(String body, {LauncherInterface? task}) {
    final id = history.begin(
      PromptAssistantRequest(
        sessionId: 'fixture',
        apiKey: null,
        provider: const ProviderConfig(
          id: 'fixture',
          name: 'Fixture',
          baseUrl: 'https://example.invalid/v1',
        ),
        model: 'fixture-model',
        systemPrompt: 'Fixture system',
        userParts: const [PromptAssistantTextPart('fixture input')],
        taskName: task?.titleIn(lookupAppLocalizations(const Locale('zh'))),
      ),
    );
    final exchange = history.sent(
      id,
      ModelRequestExchange(
        time: DateTime(2026, 10, 16),
        method: 'POST',
        url: 'https://example.invalid/v1/chat/completions',
        requestHeaders: const {'Authorization': '[redacted]', 'X-Test': 'keep'},
        requestBody: {'messages': body},
      ),
    );
    history.received(
      id,
      exchange,
      headers: const {'content-type': 'application/json'},
      body: {
        'error': {'message': 'fixture failure'},
      },
      statusCode: 400,
      error: 'fixture bad request',
    );
    history.update(
      id,
      ModelRequestStatus.failed,
      error: 'HTTP 400',
      attempts: 1,
    );
    return id;
  }

  setUp(() {
    previousCatalog = ModelCatalogRepository.cached;
    ModelCatalogRepository.cached = ModelCatalogRepository.empty;
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemorySettings()),
        secureStorageServiceProvider.overrideWithValue(MemorySecrets()),
      ],
    );
    history = container.read(modelRequestHistoryProvider);
  });
  tearDown(() {
    container.dispose();
    ModelCatalogRepository.cached = previousCatalog;
  });

  Future<void> mount(WidgetTester t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1500, 1000);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: const Key('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('zh'),
            theme: GeistTheme.light,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  actions = SettingsModelActions(context, ref);
                  view = settingsModelsData(context, ref);
                  return SettingsPage(
                    data: SettingsFixture.view(
                      page: SettingsPageId.models,
                    ).copyWith(models: view),
                    actions: SettingsActions(
                      onRequestDetails: (id) => actions.requestDetails(id),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets(
    'new settings opens the exact transcript and copies its full body',
    (t) async {
      final old = seed('older request', task: LauncherInterface.tagTranslate);
      final fullBody = 'full body ${'long content ' * 1000}';
      final id = seed(fullBody, task: LauncherInterface.tagTranslate);
      seed('connection probe');
      await mount(t);
      expect(view.requests.map((r) => r.id), [id, old]);
      expect(view.requestTotal, 2);
      await t.tap(find.byKey(const Key('models-tab-requests')));
      await t.pumpAndSettle();
      final button = find.byKey(Key('request-details-$id'));
      final mouse = await t.createGesture(kind: ui.PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(t.getCenter(button));
      await t.pumpAndSettle();
      await t.tap(button);
      await t.pumpAndSettle();
      expect(
        t
            .widget<ModelRequestDetailsDialog>(
              find.byType(ModelRequestDetailsDialog),
            )
            .recordId,
        id,
      );
      String content() => t
          .widget<SelectableText>(
            find.byKey(const Key('request-details-content')),
          )
          .data!;
      expect(content(), contains('HTTP 400'));
      await t.tap(find.text('请求').last);
      await t.pumpAndSettle();
      expect(
        content(),
        contains('https://example.invalid/v1/chat/completions'),
      );
      expect(content(), contains('Authorization'));
      expect(content(), contains('[redacted]'));
      expect(content(), contains('full body'));
      expect(content(), isNot(contains('older request')));
      String? copied;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await t.tap(find.byKey(const Key('request-details-copy')));
      await t.pumpAndSettle();
      final body = ((jsonDecode(copied!) as Map)['请求'] as List).single as Map;
      expect(body['正文'], {'messages': fullBody});
      expect(copied, content());
      expect(copied!.length, greaterThan(12000));
      seed('new arriving request', task: LauncherInterface.promptReverse);
      await t.pumpAndSettle();
      expect(content(), contains('full body'));
      await t.tap(find.text('响应').last);
      await t.pumpAndSettle();
      expect(content(), contains('400'));
      expect(content(), contains('content-type'));
      expect(content(), contains('fixture failure'));
      final capture = find.byKey(const Key('capture'));
      await captureUiuxRegion(
        t,
        capture,
        'details-response',
        t.getRect(capture),
      );
      history.clear();
      await t.pumpAndSettle();
      expect(find.text('此记录已清空或已超出最近 100 条。'), findsOneWidget);
      expect(
        t
            .widget<TextButton>(find.byKey(const Key('request-details-copy')))
            .onPressed,
        isNull,
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('an expired id opens the missing-record state', (t) async {
    await mount(t);
    final dialog = actions.requestDetails('already-evicted');
    await t.pumpAndSettle();
    expect(find.text('此记录已清空或已超出最近 100 条。'), findsOneWidget);
    await t.tap(find.text('关闭'));
    await t.pumpAndSettle();
    await dialog;
  });
}
