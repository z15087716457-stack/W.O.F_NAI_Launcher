import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_task_definitions.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/model_request_history_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_api_client.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_service.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/prompt_assistant_adapter.dart';

class _Memory extends LocalStorageService {
  final values = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values[key] as T? ?? defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async => values[key] = value;
}

class _Secrets extends SecureStorageService {
  @override
  Future<String?> getPromptAssistantApiKey(String id) async => 'synthetic-key';
  @override
  Future<String?> getPromptAssistantHeaders(String id) async => null;
}

class _OfflineAdapter implements HttpClientAdapter {
  _OfflineAdapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions, int) respond;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options, requests.length);
  }

  @override
  void close({bool force = false}) {}
}

class _CaptureApi extends PromptAssistantApiClient {
  _CaptureApi({this.output = '{"tag":"blue_eyes","name_zh":"蓝眼睛"}'})
    : super(dio: Dio());
  final String output;
  final requests = <PromptAssistantRequest>[];
  @override
  Stream<StreamingChunk> complete({required PromptAssistantRequest request}) {
    requests.add(request);
    return Stream.value(StreamingChunk(delta: output));
  }
}

const _provider = ProviderConfig(
  id: 'test',
  name: '离线服务',
  baseUrl: 'https://example.test/v1',
);
const _model = ModelConfig(
  providerId: 'test',
  name: 'test-model',
  displayName: '离线模型',
  temperature: 0.3,
  topP: 0.7,
  maxOutputTokens: 1024,
  contextWindow: 128000,
  reasoningEffort: 'high',
  reasoningEfforts: ['none', 'low', 'high'],
);
const _slot = InterfaceSlotConfig(providerId: 'test', model: 'test-model');

PromptAssistantConfigState _config({InterfaceSlotConfig slot = _slot}) =>
    PromptAssistantConfigState(
      providers: const [_provider],
      models: const [_model],
      interfaces: {for (final task in LauncherInterface.values) task: slot},
      providerHasApiKey: const {},
    );

PromptAssistantRequest _request({ProviderConfig provider = _provider}) =>
    PromptAssistantRequest(
      sessionId: 'offline-session',
      provider: provider,
      model: _model.name,
      modelConfig: effectiveTaskModel(
        _config(slot: _slot.copyWith(reasoningEffort: 'none')),
        LauncherInterface.translate,
        _model,
      ),
      taskName: LauncherInterface.translate.title,
      systemPrompt: '完整系统规则',
      userParts: const [PromptAssistantTextPart('完整输入正文')],
      apiKey: 'synthetic-key',
    );

ResponseBody _reply({int status = 200, bool responses = false}) =>
    ResponseBody.fromString(
      jsonEncode(
        status == 200
            ? responses
                  ? {'output_text': '完整模型输出'}
                  : {
                      'choices': [
                        {
                          'message': {'content': '完整模型输出'},
                        },
                      ],
                      'usage': {'total_tokens': 123},
                      'debug': {'api_key': 'different-sensitive-value'},
                    }
            : {
                'error': {'message': '失败：synthetic-key', 'code': 'test'},
              },
      ),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        'x-request-id': ['offline-request-id'],
        'set-cookie': ['synthetic-cookie'],
      },
    );

void main() {
  for (final custom in [false, true]) {
    test(
      'Wiki requests preserve free semantic headings for ${custom ? 'custom' : 'built-in'} preset',
      () async {
        const preset = TaskPresetConfig(
          id: 'user:wiki-test',
          name: '离线测试',
          task: LauncherInterface.wikiTranslate,
          prompt: 'Translate faithfully.',
        );
        final config = custom
            ? _config(
                slot: _slot.copyWith(presetId: preset.id),
              ).copyWith(presets: [preset])
            : _config();
        final storage = _Memory()
          ..values[StorageKeys.promptAssistantConfigJson] = config.encode();
        const translated =
            '## 适用范围\n\n蓝眼睛。\n\n### 示例\n\n- [blue eyes](wof-tag:blue_eyes)';
        const original =
            '## Scope\n\nBlue eyes.\n\n### Examples\n\n- [blue eyes](wof-tag:blue_eyes)';
        final api = _CaptureApi(
          output: jsonEncode({
            'tag': 'blue_eyes',
            'name_zh': '蓝眼睛',
            'wiki_zh': translated,
            'wiki_original': original,
          }),
        );
        final container = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWithValue(storage),
            secureStorageServiceProvider.overrideWithValue(_Secrets()),
            promptAssistantServiceProvider.overrideWith(
              (ref) => PromptAssistantService(ref: ref, apiClient: api),
            ),
          ],
        );
        addTearDown(container.dispose);
        final result = await container
            .read(promptAssistantServiceProvider)
            .translateVisibleTag(
              tag: 'blue_eyes',
              wikiBody: 'Blue eyes. Examples: blue_eyes.',
              includeWikiTranslation: true,
              sessionId: 'wiki-structure-offline',
            );
        final sent = api.requests.single.systemPrompt;
        expect(
          sent,
          contains(PromptAssistantService.wikiArticleStructureRules),
        );
        expect(sent, contains('short articles may remain unsectioned'));
        expect(
          sent,
          contains(
            'Keep all source facts, examples, canonical tags and external links complete',
          ),
        );
        expect(sent, isNot(contains('do not add headings')));
        if (custom) expect(sent, contains(preset.prompt));
        expect(result.wikiZh, translated);
        expect(result.wikiOriginal, original);
      },
    );
  }
  test('task reasoning alone overrides model defaults for every interface', () {
    for (final task in LauncherInterface.values) {
      final configured = _config(slot: _slot.copyWith(reasoningEffort: 'none'));
      final resolved = effectiveTaskModel(configured, task, _model);
      expect(resolved.reasoningEffort, 'none');
      expect(resolved.temperature, _model.temperature);
      expect(resolved.topP, _model.topP);
      expect(resolved.maxOutputTokens, _model.maxOutputTokens);
      expect(
        effectiveTaskModel(_config(), task, _model).reasoningEffort,
        'high',
      );
      expect(
        effectiveTaskModel(
          _config(slot: _slot.copyWith(reasoningEffort: 'max')),
          task,
          _model,
        ).reasoningEffort,
        'high',
      );
    }
    final roundTrip = PromptAssistantConfigState.decode(
      _config(slot: _slot.copyWith(reasoningEffort: 'none')).encode(),
    );
    expect(roundTrip.models.single.reasoningEfforts, ['none', 'low', 'high']);
    expect(
      roundTrip.interfaceFor(LauncherInterface.translate).reasoningEffort,
      'none',
    );
    expect(
      ModelConfig.fromJson(
        _model.toJson()..remove('reasoningEfforts'),
      ).availableReasoningEfforts,
      ['high'],
    );
    expect(
      _model.copyWith(reasoningEfforts: []).availableReasoningEfforts,
      isEmpty,
    );
  });

  test(
    'new preset saves and applies atomically while keeping the model route',
    () async {
      final storage = _Memory()
        ..values[StorageKeys.promptAssistantConfigJson] = _config().encode();
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          secureStorageServiceProvider.overrideWithValue(_Secrets()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(promptAssistantConfigProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      final preset = TaskPresetConfig(
        id: 'user:test',
        name: '原文 → 阅读语言',
        task: LauncherInterface.translate,
        prompt: LauncherInterface.translate.builtinPreset.prompt,
      );
      await notifier.savePreset(preset, applyToInterface: true);
      final saved = PromptAssistantConfigState.decode(
        storage.values[StorageKeys.promptAssistantConfigJson]! as String,
      );
      expect(saved.presets.single.id, preset.id);
      expect(saved.interfaceFor(preset.task).presetId, preset.id);
      expect(saved.interfaceFor(preset.task).providerId, 'test');
      expect(saved.interfaceFor(preset.task).model, 'test-model');
      expect(
        saved.interfaceFor(LauncherInterface.tagTranslate).presetId,
        isNull,
      );
      await expectLater(
        notifier.saveInterface(
          preset.task,
          _slot.copyWith(reasoningEffort: 'max'),
        ),
        throwsStateError,
      );
      await notifier.deletePreset(preset.id);
      expect(
        presetFor(
          container.read(promptAssistantConfigProvider),
          preset.task,
        ).id,
        preset.task.builtinPreset.id,
      );
    },
  );

  test(
    'draft interface test uses its own thinking setting without saving it',
    () async {
      final storage = _Memory()
        ..values[StorageKeys.promptAssistantConfigJson] = _config().encode();
      final api = _CaptureApi();
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          secureStorageServiceProvider.overrideWithValue(_Secrets()),
          promptAssistantServiceProvider.overrideWith(
            (ref) => PromptAssistantService(ref: ref, apiClient: api),
          ),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(promptAssistantServiceProvider);
      await service.testTaskDraft(
        LauncherInterface.tagTranslate,
        _slot.copyWith(reasoningEffort: 'low'),
        LauncherInterface.tagTranslate.builtinPreset,
        sessionId: 'draft-offline',
      );
      expect(api.requests.single.modelConfig!.reasoningEffort, 'low');
      expect(
        container
            .read(promptAssistantConfigProvider)
            .interfaceFor(LauncherInterface.tagTranslate)
            .reasoningEffort,
        isNull,
      );
    },
  );

  for (final protocol in [
    ProviderProtocol.openaiChatCompletions,
    ProviderProtocol.openaiResponses,
  ]) {
    test(
      'full HTTP diagnostics and explicit thinking off: ${protocol.name}',
      () async {
        final history = ModelRequestHistory();
        addTearDown(history.dispose);
        final adapter = _OfflineAdapter(
          (_, _) =>
              _reply(responses: protocol == ProviderProtocol.openaiResponses),
        );
        final dio = Dio()..httpClientAdapter = adapter;
        addTearDown(() => dio.close(force: true));
        final api = PromptAssistantApiClient(dio: dio, history: history);
        final provider = _provider.copyWith(
          protocol: protocol,
          requestHeaders: {'X-Client-Secret': 'synthetic-header'},
        );
        final chunks = await api
            .complete(request: _request(provider: provider))
            .toList();
        expect(chunks.first.delta, '完整模型输出');
        final sent = adapter.requests.single;
        expect(sent.headers['Authorization'], 'Bearer synthetic-key');
        final payload = sent.data as Map;
        expect(
          protocol == ProviderProtocol.openaiResponses
              ? (payload['reasoning'] as Map)['effort']
              : payload['reasoning_effort'],
          'none',
        );
        final record = history.records.single;
        expect(record.status, ModelRequestStatus.success);
        expect(record.parameters['reasoningEffort'], 'none');
        expect(record.parameters.containsKey('contextWindow'), isFalse);
        final exchange = record.exchanges.single;
        expect(exchange.method, 'POST');
        expect(
          exchange.url,
          endsWith(
            protocol == ProviderProtocol.openaiResponses
                ? '/v1/responses'
                : '/v1/chat/completions',
          ),
        );
        expect(jsonEncode(exchange.requestBody), contains('完整系统规则'));
        expect(jsonEncode(exchange.requestBody), contains('完整输入正文'));
        expect(exchange.requestHeaders['Authorization'], '[已脱敏]');
        expect(exchange.requestHeaders['X-Client-Secret'], '[已脱敏]');
        expect(exchange.responseHeaders['set-cookie'], '[已脱敏]');
        expect(exchange.statusCode, 200);
        expect(jsonEncode(exchange.responseBody), contains('完整模型输出'));
        expect(
          jsonEncode(exchange.responseBody),
          isNot(contains('different-sensitive-value')),
        );
      },
    );
  }

  test(
    'every physical retry retains its response without leaking credentials',
    () async {
      final history = ModelRequestHistory();
      addTearDown(history.dispose);
      final adapter = _OfflineAdapter(
        (_, count) => _reply(status: count == 1 ? 429 : 200),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      addTearDown(() => dio.close(force: true));
      await PromptAssistantApiClient(dio: dio, history: history)
          .complete(
            request: _request(provider: _provider.copyWith(retryAttempts: 1)),
          )
          .toList();
      final record = history.records.single;
      expect(record.attempts, 2);
      expect(record.exchanges.map((e) => e.statusCode), [429, 200]);
      expect(
        jsonEncode(record.exchanges.first.response),
        isNot(contains('synthetic-key')),
      );
      expect(record.exchanges.first.error, isNotNull);
      expect(record.status, ModelRequestStatus.success);
    },
  );

  test('DeepSeek endpoint fallback is recorded as two HTTP requests', () async {
    final history = ModelRequestHistory();
    addTearDown(history.dispose);
    final adapter = _OfflineAdapter(
      (_, count) => _reply(status: count == 1 ? 404 : 200),
    );
    final dio = Dio()..httpClientAdapter = adapter;
    addTearDown(() => dio.close(force: true));
    await PromptAssistantApiClient(dio: dio, history: history)
        .complete(
          request: _request(
            provider: _provider.copyWith(preset: ProviderPreset.deepseek),
          ),
        )
        .toList();
    final record = history.records.single;
    expect(record.attempts, 1);
    expect(record.exchanges.map((e) => e.statusCode), [404, 200]);
    expect(record.exchanges.last.url, 'https://example.test/chat/completions');
  });

  test('failed HTTP and cancellation remain inspectable', () async {
    final history = ModelRequestHistory();
    addTearDown(history.dispose);
    final dio = Dio()
      ..httpClientAdapter = _OfflineAdapter((_, _) => _reply(status: 401));
    addTearDown(() => dio.close(force: true));
    final api = PromptAssistantApiClient(dio: dio, history: history);
    await expectLater(
      api.complete(request: _request()).toList(),
      throwsStateError,
    );
    expect(history.records.single.status, ModelRequestStatus.failed);
    expect(history.records.single.exchanges.single.statusCode, 401);
    expect(
      jsonEncode(history.records.single.exchanges.single.response),
      isNot(contains('synthetic-key')),
    );
    final entered = Completer<void>();
    final release = Completer<ResponseBody>();
    dio.httpClientAdapter = _OfflineAdapter((_, _) {
      entered.complete();
      return release.future;
    });
    final pending = api.complete(request: _request()).toList();
    final expectation = expectLater(pending, throwsStateError);
    await entered.future;
    api.cancelCurrentRequest(sessionId: 'offline-session');
    await expectation;
    release.complete(_reply());
    expect(history.records.first.status, ModelRequestStatus.cancelled);
    expect(history.records.first.exchanges.single.error, isNotNull);
  });

  test(
    'retention, clearing, and nested redaction preserve useful public content',
    () {
      final history = ModelRequestHistory();
      addTearDown(history.dispose);
      final id = history.begin(_request());
      for (var i = 0; i < 100; i++) {
        history.begin(_request());
      }
      expect(history.records.length, 100);
      expect(history.records.any((r) => r.id == id), isFalse);
      history.clear();
      history.update(id, ModelRequestStatus.success);
      expect(history.records, isEmpty);
      final redactor = ModelDiagnosticRedactor(['synthetic-key']);
      final value = redactor.value({
        'messages': [
          {'content': '正文完整 synthetic-key'},
        ],
        'authorization': 'Bearer not-in-known-secrets',
        'nested': {'api_key': 'unknown-value'},
      });
      final encoded = jsonEncode(value);
      expect(encoded, contains('正文完整'));
      expect(encoded, isNot(contains('synthetic-key')));
      expect(encoded, isNot(contains('unknown-value')));
      expect(encoded, isNot(contains('not-in-known-secrets')));
      expect(
        redactor.url(
          Uri.parse(
            'https://user:pass@example.test/v1?key=another-secret&q=public',
          ),
        ),
        isNot(contains('another-secret')),
      );
    },
  );
}
