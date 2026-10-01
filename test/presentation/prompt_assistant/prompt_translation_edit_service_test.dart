import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_api_client.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_service.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/prompt_assistant_adapter.dart';

void main() {
  ProviderContainer container(_Api api, {Completer<String?>? key}) {
    final result = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWith((ref) => _Local()),
        promptAssistantConfigProvider.overrideWith((ref) => _Config(ref, key)),
        promptAssistantServiceProvider.overrideWith(
          (ref) => PromptAssistantService(ref: ref, apiClient: api),
        ),
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  test(
    'draft conversion uses the explicitly selected translation route and built-in instructions',
    () async {
      final api = _Api();
      final service = container(api).read(promptAssistantServiceProvider);
      expect(
        await service.translatePromptEdit(
          '{"direction":"toSource"}',
          sessionId: 'edit',
        ),
        '{"text":"green eyes"}',
      );
      final request = api.requests.single;
      expect(request.provider.id, 'test');
      expect(request.model, 'translate-model');
      expect(request.systemPrompt, contains('including deletions'));
      expect(request.systemPrompt, contains('NAI numeric weights'));
      expect(request.systemPrompt, contains('optional reference material'));
    },
  );
  test(
    'closing while credentials resolve prevents delayed API dispatch',
    () async {
      final api = _Api();
      final key = Completer<String?>();
      final service = container(
        api,
        key: key,
      ).read(promptAssistantServiceProvider);
      final result = service.translatePromptEdit('{}', sessionId: 'closed');
      await service.cancelCurrentTask(sessionId: 'closed');
      final assertion = expectLater(result, throwsStateError);
      key.complete(null);
      await assertion;
      expect(api.requests, isEmpty);
      expect(api.canceled, ['closed']);
    },
  );
}

class _Api extends PromptAssistantApiClient {
  _Api() : super(dio: Dio());
  final requests = <PromptAssistantRequest>[];
  final canceled = <String?>[];
  @override
  Stream<StreamingChunk> complete({required PromptAssistantRequest request}) {
    requests.add(request);
    return Stream.value(const StreamingChunk(delta: '{"text":"green eyes"}'));
  }

  @override
  void cancelCurrentRequest({String? sessionId}) => canceled.add(sessionId);
}

class _Local extends LocalStorageService {
  @override
  T? getSetting<T>(String key, {T? defaultValue}) => defaultValue;
}

class _Config extends PromptAssistantConfigNotifier {
  _Config(super.ref, this.key) {
    state = const PromptAssistantConfigState(
      providers: [
        ProviderConfig(
          id: 'test',
          name: 'Test',
          baseUrl: 'https://example.test',
        ),
      ],
      models: [
        ModelConfig(
          providerId: 'test',
          name: 'translate-model',
          displayName: 'Translation',
        ),
      ],
      interfaces: {
        LauncherInterface.translate: InterfaceSlotConfig(
          providerId: 'test',
          model: 'translate-model',
        ),
      },
      providerHasApiKey: {},
    );
  }
  final Completer<String?>? key;
  @override
  Future<String?> getProviderApiKey(String providerId) async => key?.future;
  @override
  Future<Map<String, String>> getProviderHeaders(String providerId) async =>
      const {};
}
