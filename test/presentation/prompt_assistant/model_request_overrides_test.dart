import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/model_request_overrides.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/model_request_history_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_api_client.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/prompt_assistant_adapter.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/openai_chat_completions_adapter.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/openai_responses_adapter.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/anthropic_messages_adapter.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/gemini_generate_content_adapter.dart';
import '../screens/settings/model_management_section_test.dart' as harness;

class _FailingSettings extends harness.MemorySettings {
  bool fail = false;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    if (fail && key == StorageKeys.promptAssistantConfigJson) {
      throw StateError('simulated settings write failure');
    }
    await super.setSetting(key, value);
  }
}

const _options = ModelRequestOverrides(
  headers: {'x-client': 'studio-client', 'Authorization': 'custom-secret'},
  body: {
    'metadata': {'source': 'studio'},
    'enabled': true,
    'count': 3,
    'labels': ['a', 'b'],
    'optional': null,
  },
);
const _model = ModelConfig(
  providerId: 'deepseek',
  name: 'offline-model',
  displayName: '仅用于显示',
  contextWindow: 128000,
  maxOutputTokens: 8000,
  requestOverrides: _options,
);

PromptAssistantRequest _request(ProviderConfig provider, ModelConfig model) =>
    PromptAssistantRequest(
      sessionId: 'offline',
      provider: provider,
      model: model.name,
      modelConfig: model,
      systemPrompt: 'Test',
      userParts: const [PromptAssistantTextPart('Test')],
      apiKey: 'base-secret',
    );

Map<String, dynamic> get _response => {
  'choices': [
    {
      'message': {'content': 'OK'},
    },
  ],
  'content': [
    {'type': 'text', 'text': 'OK'},
  ],
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': 'OK'},
        ],
      },
    },
  ],
  'output_text': 'OK',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    ModelCatalogRepository.cached = ModelCatalogRepository.decode(
      File('assets/data/model_catalog.json').readAsStringSync(),
    );
  });

  test(
    'JSON types survive, nested patches retain unrelated parameters, and headers are validated',
    () {
      final roundtrip = ModelRequestOverrides.decode(_options.encode());
      expect(roundtrip.body, _options.body);
      expect(roundtrip.body['enabled'], isTrue);
      expect(roundtrip.body['count'], isA<int>());
      const patch = ModelRequestOverrides(
        body: {
          'reasoning': {'summary': 'auto'},
        },
      );
      expect(
        patch.applyBody({
          'reasoning': {'effort': 'high'},
        }),
        {
          'reasoning': {'effort': 'high', 'summary': 'auto'},
        },
      );
      expect(
        ModelRequestOverrides.headerError('Bad Header', 'value'),
        isNotNull,
      );
      expect(
        ModelRequestOverrides.headerError('X-Client', 'injected\r\nHeader'),
        isNotNull,
      );
      expect(ModelRequestOverrides.headerError('X-Client', ''), isNull);
      expect(
        const ModelRequestOverrides(
          body: {'model': 'wrong'},
        ).validate(_model.name),
        isNotNull,
      );
      expect(
        const ModelRequestOverrides(
          body: {'stream': true},
        ).validate(_model.name),
        isNotNull,
      );
    },
  );

  for (final entry
      in <(String, PromptAssistantProviderAdapter, ProviderPreset)>[
        (
          'chat',
          const OpenAiChatCompletionsAdapter(),
          ProviderPreset.openaiCompatibleChat,
        ),
        (
          'responses',
          const OpenAiResponsesAdapter(),
          ProviderPreset.openaiResponses,
        ),
        (
          'anthropic',
          const AnthropicMessagesAdapter(),
          ProviderPreset.anthropic,
        ),
        ('gemini', const GeminiGenerateContentAdapter(), ProviderPreset.gemini),
      ]) {
    test(
      '${entry.$1} sends model headers and JSON fields without changing routed model or content',
      () async {
        final dio = Dio();
        addTearDown(dio.close);
        RequestOptions? sent;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              sent = request;
              handler.resolve(
                Response(
                  requestOptions: request,
                  statusCode: 200,
                  data: _response,
                ),
              );
            },
          ),
        );
        final provider = entry.$3.createConfig().copyWith(
          requestHeaders: {'X-CLIENT': 'provider-client'},
        );
        await entry.$2.complete(
          dio: dio,
          request: _request(provider, _model),
          cancelToken: CancelToken(),
        );
        final headers = sent!.headers;
        final client = headers.entries
            .where((e) => e.key.toLowerCase() == 'x-client')
            .toList();
        expect(client, hasLength(1));
        expect(client.single.value, 'studio-client');
        expect(
          headers.entries
              .singleWhere((e) => e.key.toLowerCase() == 'authorization')
              .value,
          'custom-secret',
        );
        final body = sent!.data as Map;
        for (final e in _options.body.entries) {
          expect(body[e.key], e.value);
        }
        if (entry.$1 == 'gemini') {
          expect(sent!.path, contains(_model.name));
          expect(body['contents'], isNotEmpty);
          expect((body['generationConfig'] as Map)['maxOutputTokens'], 8000);
        } else {
          expect(body['model'], _model.name);
          expect(
            body[entry.$1 == 'responses' ? 'input' : 'messages'],
            isNotEmpty,
          );
        }
      },
    );
  }

  test(
    'saving and reload use secure storage, configuration serialization excludes values',
    () async {
      final local = harness.MemorySettings()
        ..values[StorageKeys.promptAssistantConfigJson] = harness.sampleConfig
            .encode();
      final secure = harness.MemorySecrets();
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(local),
          secureStorageServiceProvider.overrideWithValue(secure),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(promptAssistantConfigProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await notifier.saveServiceDraft(
        provider: harness.sampleConfig.providers.first,
        models: [_model],
        headers: const {},
      );
      final raw = local.values[StorageKeys.promptAssistantConfigJson] as String;
      expect(raw, isNot(contains('custom-secret')));
      expect(raw, isNot(contains('studio-client')));
      expect(raw, isNot(contains('metadata')));
      final restored = PromptAssistantConfigState.decode(
        raw,
      ).modelsForProvider(providerId: 'deepseek').single;
      expect(restored.hasRequestOverrides, isTrue);
      expect(restored.requestOverrides, isNull);
      final loaded = await notifier.loadModelRequestOverrides(restored);
      expect(loaded.requestOverrides!.body, _options.body);
      expect(loaded.requestOverrides!.headers, _options.headers);
      await notifier.saveServiceDraft(
        provider: harness.sampleConfig.providers.first,
        models: [
          loaded.copyWith(requestOverrides: ModelRequestOverrides.empty),
        ],
        headers: const {},
      );
      expect(
        container
            .read(promptAssistantConfigProvider)
            .modelsForProvider(providerId: 'deepseek')
            .single
            .hasRequestOverrides,
        isFalse,
      );
      expect(secure.headers.keys.where((k) => k.startsWith('model/')), isEmpty);
      await notifier.upsertModel(_model);
      await notifier.deleteModel(_model);
      expect(secure.headers.keys.where((k) => k.startsWith('model/')), isEmpty);
      await notifier.upsertModel(_model.copyWith(source: ModelSource.api));
      expect(await notifier.syncProviderModels('deepseek', ['replacement']), [
        _model.name,
      ]);
      expect(secure.headers.keys.where((k) => k.startsWith('model/')), isEmpty);
      await notifier.upsertModel(_model);
      await notifier.deleteProvider('deepseek');
      expect(secure.headers.keys.where((k) => k.startsWith('model/')), isEmpty);
    },
  );

  test(
    'failed service save restores secure values and never publishes the changed draft',
    () async {
      final local = _FailingSettings()
        ..values[StorageKeys.promptAssistantConfigJson] = harness.sampleConfig
            .encode();
      final secure = harness.MemorySecrets()
        ..keys['deepseek'] = 'previous-key'
        ..headers['deepseek'] = jsonEncode({'X-Client': 'previous-client'});
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(local),
          secureStorageServiceProvider.overrideWithValue(secure),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(promptAssistantConfigProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      final before = container.read(promptAssistantConfigProvider);
      local.fail = true;
      await expectLater(
        notifier.saveServiceDraft(
          provider: before.providers.first.copyWith(name: '未保存的名称'),
          models: [_model],
          headers: const {'X-Client': 'new-client'},
          apiKey: 'new-key',
        ),
        throwsStateError,
      );
      expect(
        identical(container.read(promptAssistantConfigProvider), before),
        isTrue,
      );
      expect(secure.keys['deepseek'], 'previous-key');
      expect(jsonDecode(secure.headers['deepseek']!), {
        'X-Client': 'previous-client',
      });
      expect(secure.headers.keys.where((k) => k.startsWith('model/')), isEmpty);
      expect(
        local.values[StorageKeys.promptAssistantConfigJson],
        harness.sampleConfig.encode(),
      );
      await expectLater(
        notifier.saveInterface(
          LauncherInterface.translate,
          before.interfaceFor(LauncherInterface.translate),
        ),
        throwsStateError,
      );
      expect(
        identical(container.read(promptAssistantConfigProvider), before),
        isTrue,
      );
      await expectLater(
        notifier.savePreset(
          const TaskPresetConfig(
            id: 'failed-preset',
            name: '未保存的预设',
            task: LauncherInterface.translate,
            prompt: '未保存的提示词',
          ),
          applyToInterface: true,
        ),
        throwsStateError,
      );
      expect(
        identical(container.read(promptAssistantConfigProvider), before),
        isTrue,
      );
    },
  );

  test(
    'complete diagnostics preserve custom JSON data while redacting model header and body credentials',
    () async {
      final dio = Dio(), history = ModelRequestHistory();
      addTearDown(dio.close);
      addTearDown(history.dispose);
      final client = PromptAssistantApiClient(dio: dio, history: history);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {
                  'choices': [
                    {
                      'message': {'content': 'custom-secret body-secret OK'},
                    },
                  ],
                },
              ),
            );
          },
        ),
      );
      final options = ModelRequestOverrides(
        headers: _options.headers,
        body: {
          ..._options.body,
          'credentials': {'token': 'body-secret'},
        },
      );
      await client
          .complete(
            request: _request(
              ProviderPreset.openaiCompatibleChat.createConfig(),
              _model.copyWith(requestOverrides: options),
            ),
          )
          .toList();
      final record = history.records.single;
      final json = jsonEncode([
        record.overview,
        record.exchanges.map((e) => e.request).toList(),
        record.output,
      ]);
      expect(json, isNot(contains('custom-secret')));
      expect(json, isNot(contains('body-secret')));
      expect((record.exchanges.single.requestBody as Map)['enabled'], true);
      expect(record.output, contains('[已脱敏]'));
    },
  );
}
