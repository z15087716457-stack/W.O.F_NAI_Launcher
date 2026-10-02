import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/compact_service_connection.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' as harness;

Finder get _catalog => find.byKey(const Key('service-catalog-list'));
Finder _row(String id) => find.byKey(ValueKey('catalog-model-$id'));
CompactServiceConnection _connection(WidgetTester tester) =>
    tester.widget(find.byType(CompactServiceConnection));
Future<void> _type(
  WidgetTester tester,
  TextEditingController controller,
  String text,
) async {
  final field = find.byWidgetPredicate(
    (w) => w is TextField && identical(w.controller, controller),
  );
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

Future<void> _fetch(WidgetTester tester) =>
    harness.tapVisible(tester, find.widgetWithText(TextButton, '获取列表'));

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
    (const Size(600, 760), 1.3, 'compact'),
  ]) {
    testWidgets(
      '${spec.$3} new provider stays empty until explicit authenticated discovery',
      (tester) async {
        final requests = <RequestOptions>[];
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                requests.add(options);
                if (options.headers['Authorization'] != 'Bearer offline-key') {
                  handler.reject(
                    DioException(
                      requestOptions: options,
                      type: DioExceptionType.badResponse,
                      response: Response(
                        requestOptions: options,
                        statusCode: 401,
                        data: {'error': 'missing key'},
                      ),
                    ),
                  );
                } else {
                  handler.resolve(
                    Response(
                      requestOptions: options,
                      statusCode: 200,
                      data: {
                        'data': [
                          {'id': 'mistral-small-latest'},
                          {'id': 'private-model'},
                        ],
                      },
                    ),
                  );
                }
              },
            ),
          );
        addTearDown(dio.close);
        final container = await harness.pumpManagement(
          tester,
          dio: dio,
          size: spec.$1,
          scale: spec.$2,
        );
        final before = container.read(promptAssistantConfigProvider).encode();
        await harness.tapVisible(tester, find.byKey(const Key('service-add')));
        await harness.tapVisible(
          tester,
          find.byKey(const ValueKey('choose-provider-mistral')),
        );
        expect(requests, isEmpty);
        expect(_catalog, findsNothing);
        expect(
          find.byKey(const ValueKey('selected-model-mistral-small-latest')),
          findsNothing,
        );
        expect(_connection(tester).apiKey.text, isEmpty);
        await harness.capture(tester, 'catalog-discovery-${spec.$3}-unfetched');
        await _fetch(tester);
        expect(requests, hasLength(1));
        expect(_catalog, findsNothing);
        expect(container.read(promptAssistantConfigProvider).encode(), before);
        await _type(tester, _connection(tester).apiKey, 'offline-key');
        await _fetch(tester);
        expect(requests, hasLength(2));
        expect(
          requests.last.uri.toString(),
          'https://api.mistral.ai/v1/models',
        );
        expect(_row('mistral-small-latest'), findsOneWidget);
        expect(_row('private-model'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('selected-model-mistral-small-latest')),
          findsNothing,
        );
        await harness.capture(tester, 'catalog-discovery-${spec.$3}-fetched');
        await harness.tapVisible(tester, _row('mistral-small-latest'));
        await harness.tapVisible(tester, find.byKey(const Key('service-save')));
        final after = container.read(promptAssistantConfigProvider);
        final model = after
            .modelsForProvider(providerId: after.providers.last.id)
            .single;
        final facts = ModelCatalogRepository.cached!.lookup(
          ProviderPreset.mistral,
          model.name,
        )!;
        expect(model.name, 'mistral-small-latest');
        expect(model.source, ModelSource.api);
        expect(model.contextWindow, facts.contextLimit);
        expect(model.maxOutputTokens, facts.outputLimit);
        expect(_catalog, findsNothing);
        expect(
          find.byKey(const ValueKey('selected-model-mistral-small-latest')),
          findsOneWidget,
        );
        expect(requests, hasLength(2));
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'manual models use offline facts while the empty API result remains empty',
    (tester) async {
      var calls = 0;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              calls++;
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'data': []},
                ),
              );
            },
          ),
        );
      addTearDown(dio.close);
      final container = await harness.pumpManagement(tester, dio: dio);
      expect(_catalog, findsNothing);
      expect(
        find.byKey(const ValueKey('selected-model-deepseek-chat')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const Key('ai-service-manual-model-id')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('ai-service-manual-model-id')),
        'deepseek-flash',
      );
      await harness.tapVisible(
        tester,
        find.byKey(const Key('service-add-custom-model')),
      );
      expect(_catalog, findsNothing);
      expect(calls, 0);
      await _fetch(tester);
      expect(calls, 1);
      expect(_catalog, findsNothing);
      expect(
        find.byKey(const ValueKey('selected-model-deepseek-flash')),
        findsOneWidget,
      );
      await harness.tapVisible(tester, find.byKey(const Key('service-save')));
      final saved = container
          .read(promptAssistantConfigProvider)
          .models
          .firstWhere((m) => m.name == 'deepseek-flash');
      expect(saved.source, ModelSource.manual);
      expect(
        saved.contextWindow,
        ModelCatalogRepository.cached!
            .lookup(ProviderPreset.deepseek, 'deepseek-flash')!
            .contextLimit,
      );
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'editing the connection discards fetched IDs but preserves selected models',
    (tester) async {
      var calls = 0;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              calls++;
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'data': [
                      {'id': 'remote-only'},
                    ],
                  },
                ),
              );
            },
          ),
        );
      addTearDown(dio.close);
      final container = await harness.pumpManagement(tester, dio: dio);
      final before = container.read(promptAssistantConfigProvider).encode();
      await _fetch(tester);
      expect(_row('remote-only'), findsOneWidget);
      await harness.tapVisible(
        tester,
        find.byKey(const Key('service-edit-connection')),
      );
      await _type(tester, _connection(tester).apiKey, 'new-draft-key');
      expect(_catalog, findsNothing);
      expect(
        find.byKey(const ValueKey('selected-model-deepseek-chat')),
        findsOneWidget,
      );
      await _fetch(tester);
      expect(_row('remote-only'), findsOneWidget);
      await _type(
        tester,
        _connection(tester).url,
        'https://other.example.test/v1',
      );
      expect(_catalog, findsNothing);
      await _fetch(tester);
      expect(_row('remote-only'), findsOneWidget);
      _connection(tester).onProtocolChanged(ProviderProtocol.openaiResponses);
      await tester.pumpAndSettle();
      expect(_catalog, findsNothing);
      expect(calls, 3);
      expect(container.read(promptAssistantConfigProvider).encode(), before);
      expect(tester.takeException(), isNull);
    },
  );
}
