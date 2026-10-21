import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_task_definitions.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/model_request_history_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_api_client.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_service.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/prompt_assistant_adapter.dart';

class _Dio extends Mock implements Dio {
  @override
  final Interceptors interceptors = Interceptors();
}

class _Local extends LocalStorageService {
  @override
  T? getSetting<T>(String key, {T? defaultValue}) => defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {}
}

class _Secrets extends SecureStorageService {
  @override
  Future<String?> getPromptAssistantApiKey(String id) async => 'secret-key';
  @override
  Future<String?> getPromptAssistantHeaders(String id) async => null;
}

class _PendingSecrets extends _Secrets {
  final key = Completer<String?>();
  @override
  Future<String?> getPromptAssistantApiKey(String id) => key.future;
}

class _CaptureApi extends PromptAssistantApiClient {
  _CaptureApi() : super(dio: Dio());
  final requests = <PromptAssistantRequest>[];
  @override
  Stream<StreamingChunk> complete({required PromptAssistantRequest request}) {
    requests.add(request);
    return Stream.value(
      const StreamingChunk(
        delta: '{"tag":"blue_eyes","name_zh":"青い目","wiki_zh":"本文"}',
      ),
    );
  }
}

const _model = ModelConfig(
  providerId: 'service',
  name: 'model',
  displayName: 'Model',
  temperature: 0.6,
  maxOutputTokens: 500,
);
const _provider = ProviderConfig(
  id: 'service',
  name: 'Service',
  baseUrl: 'https://example.test/v1',
);
Response<dynamic> _response({String text = 'OK', int status = 200}) =>
    Response<dynamic>(
      requestOptions: RequestOptions(path: '/test'),
      statusCode: status,
      data: {
        'choices': [
          {
            'message': {'content': text},
          },
        ],
      },
    );

void main() {
  test('empty services cannot dispatch a hidden preset model', () async {
    final api = _CaptureApi();
    final container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(_Local()),
        secureStorageServiceProvider.overrideWithValue(_Secrets()),
        promptAssistantServiceProvider.overrideWith(
          (ref) => PromptAssistantService(ref: ref, apiClient: api),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(promptAssistantConfigProvider.notifier);
    final provider = ProviderPreset.mistral.createConfig();
    await notifier.upsertProvider(provider);
    final service = container.read(promptAssistantServiceProvider);
    for (final models in [
      <ModelConfig>[],
      [
        ModelConfig(
          providerId: provider.id,
          name: 'default-model',
          displayName: 'Placeholder',
        ),
      ],
    ]) {
      await notifier.replaceProviderModels(provider.id, models);
      expect(service.translateRouteFingerprint(), isEmpty);
      expect(service.translateRouteLabel(), isEmpty);
      await expectLater(
        service.translateTags(['blue_eyes'], sessionId: 'empty'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('选中一个模型'),
          ),
        ),
      );
      expect(api.requests, isEmpty);
    }
    await notifier.replaceProviderModels(provider.id, [
      ModelConfig(
        providerId: provider.id,
        name: 'private-manual-model',
        displayName: 'Manual',
      ),
    ]);
    expect(service.translateRouteLabel(), contains('private-manual-model'));
    expect(api.requests, isEmpty);
  });
  test(
    'built-in rules remain canonical after injected configuration and cannot be saved, removed or imported',
    () async {
      final builtin = LauncherInterface.wikiTranslate.builtinPreset;
      final injected = TaskPresetConfig(
        id: builtin.id,
        name: 'Changed default',
        task: builtin.task,
        prompt: 'Discard source and links',
      );
      final config = PromptAssistantConfigState(
        providers: const [],
        models: const [],
        interfaces: {
          LauncherInterface.wikiTranslate: InterfaceSlotConfig(
            presetId: builtin.id,
          ),
        },
        providerHasApiKey: const {},
        presets: [injected],
      );
      expect(
        presetFor(config, LauncherInterface.wikiTranslate).prompt,
        builtin.prompt,
      );
      expect(
        PromptAssistantConfigState.decode(config.encode()).presets,
        isEmpty,
      );
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(_Local()),
          secureStorageServiceProvider.overrideWithValue(_Secrets()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(promptAssistantConfigProvider.notifier);
      await expectLater(notifier.savePreset(injected), throwsStateError);
      await expectLater(notifier.deletePreset(builtin.id), throwsStateError);
      await expectLater(
        notifier.importConfiguration(config.encode()),
        throwsFormatException,
      );
      await notifier.savePreset(
        TaskPresetConfig(
          id: 'custom-wiki',
          name: '我的百科',
          task: builtin.task,
          prompt: builtin.prompt,
        ),
      );
      expect(
        container.read(promptAssistantConfigProvider).presets.single.id,
        'custom-wiki',
      );
    },
  );
  setUpAll(() {
    registerFallbackValue(Options());
    registerFallbackValue(CancelToken());
  });
  test(
    'legacy routes inherit independently and unknown tasks cannot overwrite them',
    () {
      final config = PromptAssistantConfigState.decode(
        jsonEncode({
          'schemaVersion': 2,
          'providers': [_provider.toJson()],
          'models': [_model.toJson()],
          'interfaces': {
            'translate': {'providerId': 'service', 'model': 'model'},
            'tagTranslate': {'providerId': 'service', 'model': 'model'},
            'futureTask': {'providerId': 'wrong', 'model': 'wrong'},
          },
        }),
      );
      expect(
        config.interfaceFor(LauncherInterface.promptReverse).model,
        'model',
      );
      expect(
        config.interfaceFor(LauncherInterface.wikiTranslate).providerId,
        'service',
      );
      expect(config.interfaces.length, 2);
      expect(
        PromptAssistantConfigState.decode(
          config.encode(),
        ).interfaceFor(LauncherInterface.translate).model,
        'model',
      );
    },
  );
  test(
    'translation cache fingerprint ignores unrelated model edits but follows language',
    () async {
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(_Local()),
          secureStorageServiceProvider.overrideWithValue(_Secrets()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(promptAssistantConfigProvider.notifier);
      await notifier.upsertProvider(_provider);
      await notifier.replaceProviderModels('service', [_model]);
      await notifier.saveInterface(
        LauncherInterface.tagTranslate,
        const InterfaceSlotConfig(providerId: 'service', model: 'model'),
      );
      final service = container.read(promptAssistantServiceProvider);
      final before = service.translateRouteFingerprint();
      expect(before, isNotEmpty);
      // 加一个不相干的模型、改它的思考档位：已有译文不该失效。
      await notifier.replaceProviderModels('service', [
        _model,
        const ModelConfig(
          providerId: 'service',
          name: 'other',
          displayName: 'Other',
          reasoningEffort: 'high',
          maxOutputTokens: 900,
        ),
      ]);
      expect(service.translateRouteFingerprint(), before);
      await notifier.saveInterface(
        LauncherInterface.tagTranslate,
        const InterfaceSlotConfig(
          providerId: 'service',
          model: 'model',
          targetLanguage: 'ja',
        ),
      );
      expect(service.translateRouteFingerprint(), isNot(before));
    },
  );
  test(
    'draft Wiki uses model parameters and preserves language, link contract and saved configuration',
    () async {
      final api = _CaptureApi();
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(_Local()),
          secureStorageServiceProvider.overrideWithValue(_Secrets()),
          promptAssistantServiceProvider.overrideWith(
            (ref) => PromptAssistantService(ref: ref, apiClient: api),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(promptAssistantConfigProvider.notifier);
      await notifier.upsertProvider(_provider);
      await notifier.replaceProviderModels('service', [_model]);
      final before = container.read(promptAssistantConfigProvider).encode();
      const preset = TaskPresetConfig(
        id: 'custom-wiki',
        name: 'Wiki',
        task: LauncherInterface.wikiTranslate,
        prompt: 'Use short paragraphs.',
      );
      final service = container.read(promptAssistantServiceProvider);
      await service.testTaskDraft(
        LauncherInterface.wikiTranslate,
        const InterfaceSlotConfig(
          providerId: 'service',
          model: 'model',
          targetLanguage: 'ja',
        ),
        preset,
        sessionId: 'draft',
      );
      final request = api.requests.single;
      expect(request.modelConfig!.temperature, 0.6);
      expect(request.modelConfig!.maxOutputTokens, 500);
      expect(request.systemPrompt, contains('Use short paragraphs.'));
      expect(request.systemPrompt, contains('wof-tag:TAG'));
      expect(request.systemPrompt, contains('Return exactly one JSON object'));
      expect(
        jsonDecode(
          (request.userParts.single as PromptAssistantTextPart).text,
        )['target_language'],
        'ja',
      );
      expect(container.read(promptAssistantConfigProvider).encode(), before);
      final oldFingerprint = service.translateRouteFingerprint();
      await notifier.savePreset(preset);
      await notifier.saveInterface(
        LauncherInterface.wikiTranslate,
        const InterfaceSlotConfig(
          providerId: 'service',
          model: 'model',
          targetLanguage: 'ja',
          presetId: 'custom-wiki',
        ),
      );
      expect(service.translateRouteFingerprint(), isNot(oldFingerprint));
      await notifier.deletePreset(preset.id);
      expect(
        presetFor(
          container.read(promptAssistantConfigProvider),
          LauncherInterface.wikiTranslate,
        ).id,
        LauncherInterface.wikiTranslate.builtinId,
      );
      expect(
        container
            .read(promptAssistantConfigProvider)
            .interfaceFor(LauncherInterface.wikiTranslate)
            .model,
        'model',
      );
    },
  );
  for (final protocol in [
    ProviderProtocol.openaiChatCompletions,
    ProviderProtocol.openaiResponses,
    ProviderProtocol.geminiGenerateContent,
    ProviderProtocol.anthropicMessages,
  ]) {
    test(
      'stored sampling controls do not reach ${protocol.name} payload',
      () async {
        final dio = _Dio();
        Map<String, dynamic>? payload;
        when(
          () => dio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((invocation) async {
          payload = invocation.namedArguments[#data] as Map<String, dynamic>;
          return Response<dynamic>(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 200,
            data: {
              'choices': [
                {
                  'message': {'content': 'OK'},
                },
              ],
              'output_text': 'OK',
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
            },
          );
        });
        final parameters = _model.copyWith(topP: 0.8);
        await PromptAssistantApiClient(dio: dio)
            .complete(
              request: PromptAssistantRequest(
                sessionId: 'parameters',
                provider: _provider.copyWith(protocol: protocol),
                model: 'model',
                modelConfig: parameters,
                systemPrompt: 'Test',
                userParts: [PromptAssistantContentPart.text('test')],
                apiKey: 'secret-key',
              ),
            )
            .toList();
        final sampling = protocol == ProviderProtocol.geminiGenerateContent
            ? payload!['generationConfig'] as Map
            : payload!;
        expect(sampling, isNot(contains('temperature')));
        expect(sampling, isNot(contains('top_p')));
        expect(sampling, isNot(contains('topP')));
      },
    );
  }
  test(
    'queued cancellation cannot dispatch and releases the service gate',
    () async {
      final dio = _Dio();
      final pending = Completer<Response<dynamic>>();
      var calls = 0;
      when(
        () => dio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) {
        calls++;
        return pending.future;
      });
      final history = ModelRequestHistory();
      final client = PromptAssistantApiClient(dio: dio, history: history);
      PromptAssistantRequest request(String id) => PromptAssistantRequest(
        sessionId: id,
        provider: _provider.copyWith(maxConcurrentRequests: 1),
        model: 'model',
        systemPrompt: 'private-prompt',
        userParts: [PromptAssistantContentPart.text('private-body')],
        apiKey: 'secret-key',
      );
      final first = client.complete(request: request('first')).toList();
      await Future<void>.delayed(Duration.zero);
      final queued = client.complete(request: request('queued')).toList();
      final canceled = expectLater(queued, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      client.cancelCurrentRequest(sessionId: 'queued');
      await canceled;
      pending.complete(_response());
      await first;
      expect(calls, 1);
      expect(
        history.records.map((item) => item.status),
        containsAll([ModelRequestStatus.success, ModelRequestStatus.cancelled]),
      );
      expect(
        history.records.map((item) => item.parameters.toString()).join(),
        isNot(contains('secret-key')),
      );
      expect(
        history.records.map((item) => item.parameters.toString()).join(),
        isNot(contains('private-prompt')),
      );
      await client.complete(request: request('third')).toList();
      expect(calls, 2);
    },
  );
  test(
    'default transient retry preserves explicit parameters and records attempts',
    () async {
      final dio = _Dio();
      var calls = 0;
      when(
        () => dio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) async {
        calls++;
        expect((invocation.namedArguments[#data] as Map)['max_tokens'], 500);
        expect(
          invocation.namedArguments[#data] as Map,
          isNot(contains('temperature')),
        );
        if (calls == 1) {
          throw DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.badResponse,
            response: _response(status: 503),
          );
        }
        return _response();
      });
      final history = ModelRequestHistory();
      final client = PromptAssistantApiClient(dio: dio, history: history);
      await client
          .complete(
            request: PromptAssistantRequest(
              sessionId: 'retry',
              provider: _provider,
              model: 'model',
              modelConfig: _model,
              systemPrompt: 'Test',
              userParts: [PromptAssistantContentPart.text('test')],
              apiKey: null,
            ),
          )
          .toList();
      expect(calls, 2);
      expect(history.records.single.attempts, 2);
      expect(history.records.single.status, ModelRequestStatus.success);
    },
  );

  for (final spec in [
    (name: 'default transient failure', status: 503, retries: null, calls: 2),
    (name: 'explicitly disabled retry', status: 503, retries: 0, calls: 1),
    (name: 'authentication failure', status: 401, retries: null, calls: 1),
  ]) {
    test('${spec.name} respects the retry budget', () async {
      final dio = _Dio();
      var calls = 0;
      when(
        () => dio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async {
        calls++;
        throw DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: _response(status: spec.status),
        );
      });
      final history = ModelRequestHistory();
      final client = PromptAssistantApiClient(dio: dio, history: history);
      await expectLater(
        client
            .complete(
              request: PromptAssistantRequest(
                sessionId: 'retry-budget',
                provider: _provider.copyWith(retryAttempts: spec.retries),
                model: 'model',
                systemPrompt: 'Test',
                userParts: [PromptAssistantContentPart.text('test')],
                apiKey: null,
              ),
            )
            .toList(),
        throwsStateError,
      );
      expect(calls, spec.calls);
      expect(history.records.single.attempts, spec.calls);
      expect(history.records.single.status, ModelRequestStatus.failed);
    });
  }

  test(
    'closing a preset test during credential loading prevents Wiki dispatch',
    () async {
      final api = _CaptureApi();
      final secrets = _PendingSecrets();
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(_Local()),
          secureStorageServiceProvider.overrideWithValue(secrets),
          promptAssistantServiceProvider.overrideWith(
            (ref) => PromptAssistantService(ref: ref, apiClient: api),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(promptAssistantConfigProvider.notifier);
      await notifier.upsertProvider(_provider);
      await notifier.replaceProviderModels('service', [_model]);
      final service = container.read(promptAssistantServiceProvider);
      final pending = service.testTaskDraft(
        LauncherInterface.wikiTranslate,
        const InterfaceSlotConfig(providerId: 'service', model: 'model'),
        LauncherInterface.wikiTranslate.builtinPreset,
        sessionId: 'closed-draft',
      );
      final canceled = expectLater(pending, throwsStateError);
      await service.cancelCurrentTask(sessionId: 'closed-draft');
      secrets.key.complete(null);
      await canceled;
      expect(api.requests, isEmpty);
    },
  );
  test(
    'invalid imports cannot erase settings or create duplicate preset choices',
    () async {
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(_Local()),
          secureStorageServiceProvider.overrideWithValue(_Secrets()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(promptAssistantConfigProvider.notifier);
      await notifier.upsertProvider(_provider);
      final before = container.read(promptAssistantConfigProvider).encode();
      await expectLater(
        notifier.importConfiguration('{"foo":1}'),
        throwsFormatException,
      );
      const preset = TaskPresetConfig(
        id: 'same',
        name: 'Example',
        task: LauncherInterface.translate,
        prompt: 'Read carefully.',
      );
      final duplicate = jsonEncode({
        'providers': [_provider.toJson()],
        'models': [],
        'presets': [preset.toJson(), preset.toJson()],
      });
      await expectLater(
        notifier.importConfiguration(duplicate),
        throwsFormatException,
      );
      expect(container.read(promptAssistantConfigProvider).encode(), before);
    },
  );
}
