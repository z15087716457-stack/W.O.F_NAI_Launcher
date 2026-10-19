import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/model_catalog_entry.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/model_request_overrides.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_model_provider.dart';

void main() {
  const provider = ProviderConfig(
    id: 'test',
    name: 'Synthetic',
    baseUrl: 'http://localhost:1',
    allowImageInput: true,
    requestHeaders: {'Authorization': 'provider-header', 'X-test': 'one'},
  );
  const model = ModelConfig(
    providerId: 'test',
    name: 'model',
    displayName: 'Model',
    supportsVision: true,
    supportsTools: true,
    temperature: 0.4,
    topP: 0.6,
    reasoningEffort: 'medium',
    maxOutputTokens: 8192,
    contextWindow: 100000,
    requestOverrides: ModelRequestOverrides(
      headers: {'authorization': 'model-header', 'x-test': 'two'},
      body: {'stream': false, 'custom_flag': 1},
    ),
  );

  test(
    'existing headers, parameters and limits map; public descriptions omit credentials',
    () {
      final connection = mapNaiAgentModel(
        provider,
        model,
        apiKey: 'synthetic-key',
      );
      final value = connection.toPrivateJson();
      expect(value['headers'], {
        'authorization': 'model-header',
        'x-test': 'two',
      });
      expect(value['temperature'], 0.4);
      expect(value['payloadParameters'], {
        'reasoning_effort': 'medium',
        'top_p': 0.6,
      });
      expect(value['contextWindow'], 100000);
      expect(value['maxTokens'], 8192);
      expect(connection.allowsImages, isTrue);
      expect(connection.toString(), isNot(contains('synthetic-key')));
      expect(connection.toString(), isNot(contains('model-header')));
      expect(connection.description['costKnown'], isFalse);
    },
  );
  test(
    'Responses, Anthropic and Gemini keep their existing reasoning formats',
    () {
      final plain = model.copyWith(
        clearTemperature: true,
        clearTopP: true,
        requestOverrides: ModelRequestOverrides.empty,
      );
      final responses = mapNaiAgentModel(
        provider.copyWith(protocol: ProviderProtocol.openaiResponses),
        plain,
      ).toPrivateJson();
      expect(responses['payloadParameters'], {
        'reasoning': {'effort': 'medium'},
      });
      final adaptive = plain.copyWith(
        reasoningProtocol: ModelReasoningProtocol.adaptive,
      );
      final anthropic = mapNaiAgentModel(
        provider.copyWith(protocol: ProviderProtocol.anthropicMessages),
        adaptive,
      ).toPrivateJson();
      expect(anthropic['allowsSampling'], isFalse);
      expect(anthropic['payloadParameters'], {
        'thinking': {'type': 'adaptive'},
        'output_config': {'effort': 'medium'},
      });
      final gemini = mapNaiAgentModel(
        provider.copyWith(protocol: ProviderProtocol.geminiGenerateContent),
        plain,
      ).toPrivateJson();
      expect(gemini['payloadParameters'], {
        'generationConfig': {
          'thinkingConfig': {'thinkingLevel': 'MEDIUM'},
        },
      });
    },
  );
  test(
    'Agent thinking override changes the request without changing the saved model',
    () {
      final selectable = model.copyWith(
        reasoningEfforts: const ['none', 'low', 'medium', 'high'],
      );
      final connection = mapNaiAgentModel(provider, selectable);
      final changed = connection.withReasoningEffort('high').toPrivateJson();
      expect(changed['thinkingLevel'], 'high');
      expect((changed['payloadParameters'] as Map)['reasoning_effort'], 'high');
      expect(selectable.reasoningEffort, 'medium');
      expect(
        () => connection.withReasoningEffort('xhigh'),
        throwsFormatException,
      );
    },
  );
  test(
    'Agent thinking wins over old request reasoning without mutating secure options',
    () {
      final configured = model.copyWith(
        reasoningEfforts: const ['none', 'medium', 'high'],
        requestOverrides: const ModelRequestOverrides(
          headers: {'X-test': 'two'},
          body: {
            'reasoning_effort': 'low',
            'reasoning': {'effort': 'low', 'summary': 'brief'},
            'custom_flag': 1,
          },
        ),
      );
      final changed = mapNaiAgentModel(
        provider,
        configured,
      ).withReasoningEffort('high').toPrivateJson();
      expect((changed['payloadParameters'] as Map)['reasoning_effort'], 'high');
      expect(changed['body'], {
        'reasoning': {'summary': 'brief'},
        'custom_flag': 1,
      });
      expect(configured.requestOverrides!.body['reasoning_effort'], 'low');
      expect(configured.reasoningEffort, 'medium');
    },
  );
  test('image access reports the provider gate only for a vision model', () {
    final blocked = mapNaiAgentModel(
      provider.copyWith(allowImageInput: false),
      model,
    );
    expect(blocked.allowsImages, isFalse);
    expect(blocked.visionBlockedByProvider, isTrue);
    expect(blocked.providerName, 'Synthetic');
    expect(blocked.visionAccess.unavailableMessage, contains('Synthetic'));
    expect(blocked.visionAccess.unavailableMessage, contains('请求 → 图片输入'));
    expect(blocked.visionAccess.unavailableMessage, contains('“允许”'));
    final unsupported = mapNaiAgentModel(
      provider.copyWith(allowImageInput: false),
      model.copyWith(supportsVision: false),
    );
    expect(unsupported.allowsImages, isFalse);
    expect(unsupported.visionBlockedByProvider, isFalse);
    expect(unsupported.visionAccess.unavailableMessage, contains('Synthetic'));
    expect(unsupported.visionAccess.unavailableMessage, contains('模型 → 能力'));
    expect(
      unsupported.visionAccess.unavailableMessage,
      isNot(contains('请求 →')),
    );
  });

  test(
    'unknown capabilities remain unknown, image access requires known support',
    () {
      const unknown = ModelConfig(
        providerId: 'test',
        name: 'unknown',
        displayName: 'unknown',
      );
      final connection = mapNaiAgentModel(provider, unknown);
      expect(connection.description['tools'], isNull);
      expect(connection.description['vision'], isNull);
      expect(connection.allowsImages, isFalse);
      expect(
        mapNaiAgentModel(
          provider.copyWith(allowImageInput: false),
          model,
        ).allowsImages,
        isFalse,
      );
      expect(
        () => mapNaiAgentModel(provider, model.copyWith(supportsTools: false)),
        throwsStateError,
      );
      expect(
        () => mapNaiAgentModel(provider.copyWith(enabled: false), model),
        throwsStateError,
      );
    },
  );
}
