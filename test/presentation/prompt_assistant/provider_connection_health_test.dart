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
import 'package:nai_launcher/presentation/prompt_assistant/providers/model_request_history_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/provider_connection_health_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_api_client.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_service.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/prompt_assistant_adapter.dart';

const _provider = ProviderConfig(
  id: 'test-service',
  name: '服务',
  baseUrl: 'https://example.test/v1',
);
const _model = ModelConfig(
  providerId: 'test-service',
  name: 'model',
  displayName: 'Model',
);

class _Memory extends LocalStorageService {
  final values = <String, Object?>{};
  bool failCache = false;
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values[key] as T? ?? defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    if (failCache && key == StorageKeys.providerConnectionHealthV1) {
      throw StateError('cache unavailable');
    }
    values[key] = value;
  }
}

class _Secrets extends SecureStorageService {
  final keys = <String, String>{'test-service': 'synthetic-key'};
  final headers = <String, String>{};
  bool failKeyWrite = false;
  @override
  Future<String?> getPromptAssistantApiKey(String id) async => keys[id];
  @override
  Future<void> savePromptAssistantApiKey(String id, String key) async {
    if (failKeyWrite) throw StateError('simulated credential failure');
    keys[id] = key;
  }

  @override
  Future<void> deletePromptAssistantApiKey(String id) async => keys.remove(id);
  @override
  Future<String?> getPromptAssistantHeaders(String id) async => headers[id];
  @override
  Future<void> savePromptAssistantHeaders(String id, String value) async =>
      headers[id] = value;
  @override
  Future<void> deletePromptAssistantHeaders(String id) async =>
      headers.remove(id);
}

class _OfflineAdapter implements HttpClientAdapter {
  _OfflineAdapter(this.reply);
  final FutureOr<ResponseBody> Function(RequestOptions, int) reply;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return reply(options, requests.length);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _response([
  int status = 200,
  ProviderProtocol protocol = ProviderProtocol.openaiChatCompletions,
]) => ResponseBody.fromString(
  jsonEncode(
    status == 200
        ? switch (protocol) {
            ProviderProtocol.openaiResponses => {
              'output': [
                {
                  'type': 'message',
                  'content': [
                    {'type': 'output_text', 'text': 'OK'},
                  ],
                },
              ],
            },
            ProviderProtocol.anthropicMessages => {
              'content': [
                {'type': 'text', 'text': 'OK'},
              ],
            },
            ProviderProtocol.geminiGenerateContent => {
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
            _ => {
              'choices': [
                {
                  'message': {'content': 'OK'},
                },
              ],
            },
          }
        : {
            'error': {'message': 'synthetic-key private-body private-header'},
          },
  ),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

PromptAssistantRequest _request(
  String id, {
  ProviderConfig provider = _provider,
  ModelConfig? model = _model,
}) => PromptAssistantRequest(
  sessionId: id,
  provider: provider,
  model: 'model',
  modelConfig: model,
  systemPrompt: 'private-prompt',
  userParts: [PromptAssistantContentPart.text('private-body')],
  apiKey: 'synthetic-key',
);

ProviderConnectionHealth _health(
  _Memory storage, [
  ProviderConfig provider = _provider,
]) {
  final health = ProviderConnectionHealth(
    storage: storage,
    providers: [provider],
  );
  addTearDown(health.dispose);
  return health;
}

PromptAssistantApiClient _client(
  _OfflineAdapter adapter,
  ProviderConnectionHealth health, {
  ModelRequestHistory? history,
}) {
  final dio = Dio()..httpClientAdapter = adapter;
  addTearDown(() => dio.close(force: true));
  return PromptAssistantApiClient(
    dio: dio,
    connectionHealth: health,
    history: history,
  );
}

Future<ProviderContainer> _container(
  _Memory storage,
  _Secrets secrets,
  _OfflineAdapter adapter,
) async {
  storage.values[StorageKeys.promptAssistantConfigJson] =
      PromptAssistantConfigState.defaults()
          .copyWith(
            providers: [_provider],
            models: [_model],
            interfaces: {
              LauncherInterface.translate: const InterfaceSlotConfig(
                providerId: 'test-service',
                model: 'model',
              ),
            },
          )
          .encode();
  final dio = Dio()..httpClientAdapter = adapter;
  final container = ProviderContainer(
    overrides: [
      localStorageServiceProvider.overrideWithValue(storage),
      secureStorageServiceProvider.overrideWithValue(secrets),
      promptAssistantDioProvider.overrideWithValue(dio),
    ],
  );
  addTearDown(() {
    container.dispose();
    dio.close(force: true);
  });
  container.read(promptAssistantConfigProvider);
  await Future<void>.delayed(Duration.zero);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(ModelCatalogRepository.load);

  for (final protocol in [
    ProviderProtocol.openaiChatCompletions,
    ProviderProtocol.openaiResponses,
    ProviderProtocol.anthropicMessages,
    ProviderProtocol.geminiGenerateContent,
  ]) {
    test(
      '${protocol.name} actual requests change green to red and recover with safe persistent outcomes',
      () async {
        final provider = _provider.copyWith(
          protocol: protocol,
          requestHeaders: {'X-Secret': 'private-header'},
        );
        final storage = _Memory();
        final persistent = _health(storage, provider);
        final adapter = _OfflineAdapter(
          (_, call) => _response(call == 2 ? 401 : 200, protocol),
        );
        final client = _client(adapter, persistent);
        expect(
          persistent.resultFor(provider.id).status,
          ProviderConnectionStatus.unverified,
        );
        await client
            .complete(request: _request('first', provider: provider))
            .toList();
        expect(
          persistent.resultFor(provider.id).status,
          ProviderConnectionStatus.healthy,
        );
        await expectLater(
          client
              .complete(request: _request('second', provider: provider))
              .toList(),
          throwsStateError,
        );
        expect(
          persistent.resultFor(provider.id).status,
          ProviderConnectionStatus.failed,
        );
        expect(
          persistent.resultFor(provider.id).issue,
          ProviderConnectionIssue.authentication,
        );
        await persistent.whenPersisted;
        final reopened = _health(storage, provider);
        expect(
          reopened.resultFor(provider.id).status,
          ProviderConnectionStatus.failed,
        );
        expect(reopened.resultFor(provider.id).checkedAt, isNotNull);
        final cached =
            storage.values[StorageKeys.providerConnectionHealthV1] as String;
        for (final secret in [
          'synthetic-key',
          'private-body',
          'private-header',
          'private-prompt',
          'https://example.test',
        ]) {
          expect(cached, isNot(contains(secret)));
        }
        await client
            .complete(request: _request('third', provider: provider))
            .toList();
        expect(
          persistent.resultFor(provider.id).status,
          ProviderConnectionStatus.healthy,
        );
        expect(adapter.requests, hasLength(3));
      },
    );
  }

  test(
    'production service updates status for later translation requests and draft tests',
    () async {
      final storage = _Memory(), secrets = _Secrets();
      final adapter = _OfflineAdapter(
        (_, call) => _response(call == 2 ? 503 : 200),
      );
      final container = await _container(storage, secrets, adapter);
      final health = container.read(providerConnectionHealthProvider);
      final service = container.read(promptAssistantServiceProvider);
      await service.testModelForDraft(_provider, _model, 'synthetic-key', {});
      expect(
        health.resultFor(_provider.id).status,
        ProviderConnectionStatus.healthy,
      );
      await expectLater(
        service.translatePromptGroup('{}', sessionId: 'translation'),
        throwsStateError,
      );
      expect(
        health.resultFor(_provider.id).status,
        ProviderConnectionStatus.failed,
      );
      await service.translatePromptGroup('{}', sessionId: 'recovery');
      expect(
        health.resultFor(_provider.id).status,
        ProviderConnectionStatus.healthy,
      );
      await health.whenPersisted;
      expect(storage.values[StorageKeys.providerConnectionHealthV1], isNotNull);
      final reopened = await _container(
        storage,
        secrets,
        _OfflineAdapter((_, _) => _response()),
      );
      expect(
        reopened
            .read(providerConnectionHealthProvider)
            .resultFor(_provider.id)
            .status,
        ProviderConnectionStatus.healthy,
      );
    },
  );

  test(
    'testing changed draft credentials or endpoint leaves the saved connection status intact',
    () async {
      final container = await _container(
        _Memory(),
        _Secrets(),
        _OfflineAdapter((_, call) => _response(call == 1 ? 200 : 401)),
      );
      final health = container.read(providerConnectionHealthProvider),
          service = container.read(promptAssistantServiceProvider);
      await service.testModelForDraft(_provider, _model, 'synthetic-key', {});
      for (final draft in [
        (_provider, 'different-key', <String, String>{}),
        (_provider, 'synthetic-key', {'X-Client': 'draft-header'}),
        (
          _provider.copyWith(baseUrl: 'https://draft.test/v1'),
          'synthetic-key',
          <String, String>{},
        ),
        (_provider.copyWith(id: 'draft'), 'synthetic-key', <String, String>{}),
      ]) {
        await expectLater(
          service.testModelForDraft(draft.$1, _model, draft.$2, draft.$3),
          throwsStateError,
        );
        expect(
          health.resultFor(_provider.id).status,
          ProviderConnectionStatus.healthy,
        );
        expect(
          health.resultFor('draft').status,
          ProviderConnectionStatus.unverified,
        );
      }
    },
  );

  test(
    'rate limiting is yellow and cancellation and local validation preserve the previous result',
    () async {
      final health = _health(_Memory());
      health.succeeded(health.begin(_provider));
      final adapter = _OfflineAdapter((options, call) {
        if (call == 1) return _response(429);
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
        );
      });
      final client = _client(adapter, health);
      await expectLater(
        client.complete(request: _request('limited')).toList(),
        throwsStateError,
      );
      expect(
        health.resultFor(_provider.id).status,
        ProviderConnectionStatus.limited,
      );
      final limited = health.resultFor(_provider.id);
      await expectLater(
        client.complete(request: _request('canceled')).toList(),
        throwsStateError,
      );
      expect(health.resultFor(_provider.id), same(limited));
      await expectLater(
        client
            .complete(
              request: _request(
                'invalid',
                model: _model.copyWith(temperature: -1),
              ),
            )
            .toList(),
        throwsFormatException,
      );
      expect(health.resultFor(_provider.id), same(limited));
      expect(adapter.requests, hasLength(2));
    },
  );

  test(
    'successful automatic retry does not overwrite status with an intermediate failure',
    () async {
      final provider = _provider.copyWith(retryAttempts: 1);
      final health = _health(_Memory(), provider);
      final observed = <ProviderConnectionStatus>[];
      health.addListener(
        () => observed.add(health.resultFor(provider.id).status),
      );
      final client = _client(
        _OfflineAdapter((_, call) => _response(call == 1 ? 503 : 200)),
        health,
      );
      await client
          .complete(request: _request('retry', provider: provider))
          .toList();
      expect(observed, [ProviderConnectionStatus.healthy]);
    },
  );

  test('an older concurrent success cannot hide a newer failure', () async {
    final pending = Completer<ResponseBody>();
    final health = _health(_Memory());
    final adapter = _OfflineAdapter(
      (_, call) => call == 1 ? pending.future : _response(503),
    );
    final client = _client(adapter, health);
    final old = client.complete(request: _request('older')).toList();
    await Future<void>.delayed(Duration.zero);
    await expectLater(
      client.complete(request: _request('newer')).toList(),
      throwsStateError,
    );
    pending.complete(_response());
    await old;
    expect(
      health.resultFor(_provider.id).status,
      ProviderConnectionStatus.failed,
    );
  });

  test(
    'address and credential changes reset health, failed saves and renames preserve it, deletion removes it',
    () async {
      final storage = _Memory(), secrets = _Secrets();
      final container = await _container(
        storage,
        secrets,
        _OfflineAdapter((_, _) => _response()),
      );
      final health = container.read(providerConnectionHealthProvider);
      final notifier = container.read(promptAssistantConfigProvider.notifier);
      health.succeeded(health.begin(_provider));
      await notifier.saveServiceDraft(
        provider: _provider.copyWith(name: '别名'),
        models: [_model],
        headers: {},
      );
      expect(
        health.resultFor(_provider.id).status,
        ProviderConnectionStatus.healthy,
      );
      secrets.failKeyWrite = true;
      await expectLater(
        notifier.saveServiceDraft(
          provider: _provider,
          models: [_model],
          headers: {},
          apiKey: 'changed-key',
        ),
        throwsStateError,
      );
      expect(
        health.resultFor(_provider.id).status,
        ProviderConnectionStatus.healthy,
      );
      secrets.failKeyWrite = false;
      final old = health.begin(_provider);
      await notifier.setProviderApiKey(_provider.id, 'changed-key');
      health.succeeded(old);
      expect(
        health.resultFor(_provider.id).status,
        ProviderConnectionStatus.unverified,
      );
      health.succeeded(health.begin(_provider));
      await notifier.setProviderHeaders(_provider.id, {'X-Client': 'changed'});
      expect(
        health.resultFor(_provider.id).status,
        ProviderConnectionStatus.unverified,
      );
      health.succeeded(health.begin(_provider));
      final newAddress = _provider.copyWith(baseUrl: 'https://new.test/v1');
      await notifier.upsertProvider(newAddress);
      expect(
        health.resultFor(_provider.id).status,
        ProviderConnectionStatus.unverified,
      );
      health.succeeded(health.begin(newAddress));
      await notifier.deleteProvider(_provider.id);
      expect(
        health.resultFor(_provider.id).status,
        ProviderConnectionStatus.unverified,
      );
      await health.whenPersisted;
      expect(
        storage.values[StorageKeys.providerConnectionHealthV1],
        isNot(contains(_provider.id)),
      );
    },
  );

  test(
    'catalog requests including Pollinations use real responses without preset fallback',
    () async {
      final health = _health(_Memory());
      final client = _client(
        _OfflineAdapter(
          (_, _) => ResponseBody.fromString(
            '{"data":[{"id":"model"}]}',
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          ),
        ),
        health,
      );
      await client.fetchModels(provider: _provider, apiKey: 'synthetic-key');
      expect(
        health.resultFor(_provider.id).status,
        ProviderConnectionStatus.healthy,
      );
      final pollinations = _provider.copyWith(
        preset: ProviderPreset.pollinations,
        type: ProviderType.pollinations,
      );
      final local = _health(_Memory(), pollinations);
      final adapter = _OfflineAdapter(
        (_, _) => ResponseBody.fromString(
          '{"data":[{"id":"returned-model"}]}',
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );
      final names = await _client(
        adapter,
        local,
      ).fetchModels(provider: pollinations, apiKey: null);
      expect(
        local.resultFor(pollinations.id).status,
        ProviderConnectionStatus.healthy,
      );
      expect(names, ['returned-model']);
      expect(
        adapter.requests.single.uri.toString(),
        'https://gen.pollinations.ai/v1/models',
      );
      final empty = await _client(
        _OfflineAdapter(
          (_, _) => ResponseBody.fromString(
            '{"data":[]}',
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          ),
        ),
        local,
      ).fetchModels(provider: pollinations, apiKey: null);
      expect(empty, isEmpty);
    },
  );

  test(
    'invalid cache and cache-write failure never fail a successful request',
    () async {
      final storage = _Memory()
        ..values[StorageKeys.providerConnectionHealthV1] = '{invalid cache'
        ..failCache = true;
      final health = _health(storage);
      final client = _client(_OfflineAdapter((_, _) => _response()), health);
      await client.complete(request: _request('success')).toList();
      await health.whenPersisted;
      expect(
        health.resultFor(_provider.id).status,
        ProviderConnectionStatus.healthy,
      );
    },
  );
}
