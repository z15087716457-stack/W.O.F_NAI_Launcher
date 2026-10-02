import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/model_catalog_entry.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/model_request_options.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/prompt_assistant_adapter.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/openai_chat_completions_adapter.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/openai_responses_adapter.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/anthropic_messages_adapter.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/gemini_generate_content_adapter.dart';

void main() {
  final catalog = ModelCatalogRepository.decode(
    File('assets/data/model_catalog.json').readAsStringSync(),
  );
  ModelConfig model(String name) => ModelConfig(
    providerId: 'test',
    name: name,
    displayName: name,
    customFields: const {},
  );
  test(
    'snapshot includes complete hosted facts and valid provider bindings',
    () {
      final snapshot =
          jsonDecode(File('assets/data/model_catalog.json').readAsStringSync())
              as Map;
      expect(snapshot['schemaVersion'], 2);
      expect(catalog.providers.length, greaterThanOrEqualTo(200));
      expect(catalog.providerEntries.length, greaterThanOrEqualTo(8000));
      for (final entry in catalog.providerEntries.entries) {
        final facts = entry.value;
        expect(entry.key, facts.id.toLowerCase());
        expect(facts.outputModalities, contains('text'));
        if (facts.contextLimit != null) {
          expect(facts.contextLimit, greaterThan(0));
        }
        if (facts.outputLimit != null) {
          expect(facts.outputLimit, greaterThan(0));
        }
        if (facts.defaultReasoningEffort != null) {
          expect(
            facts.reasoningEfforts,
            contains(facts.defaultReasoningEffort),
          );
        }
      }
      for (final entry in catalog.bindings.entries) {
        expect(catalog.entries, contains(entry.value.toLowerCase()));
      }
    },
  );
  test(
    'same base model keeps each serving platform limits and reasoning controls',
    () {
      final groq = catalog.lookup(ProviderPreset.groq, 'openai/gpt-oss-120b')!;
      final siliconflow = catalog.lookup(
        ProviderPreset.siliconflow,
        'openai/gpt-oss-120b',
      )!;
      expect(groq.outputLimit, 65536);
      expect(groq.contextLimit, 131072);
      expect(siliconflow.outputLimit, 8000);
      expect(siliconflow.contextLimit, 131000);
      expect(groq.reasoningOptions.single['values'], ['low', 'medium', 'high']);
      expect(siliconflow.reasoningOptions.single['type'], 'budget_tokens');
      expect(siliconflow.budgetMax, 32768);
      expect(groq.supportsToolCalling, isTrue);
      expect(groq.supportsStructuredOutput, isTrue);
      expect(groq.cost['input'], .15);
      expect(catalog.lookup(null, 'groq/openai/gpt-oss-120b'), same(groq));
    },
  );
  test(
    'standalone hosted IDs and modality facts survive without a lab binding',
    () {
      final standalone = catalog.lookup(
        ProviderPreset.openrouter,
        'aion-labs/aion-3.5',
      )!;
      expect(standalone.id, 'openrouter/aion-labs/aion-3.5');
      expect(standalone.canonicalId, isNull);
      expect(standalone.contextLimit, greaterThan(0));
      final claude = catalog.lookup(
        ProviderPreset.anthropic,
        'claude-opus-5-5',
      )!;
      expect(claude.supportsPdf, isTrue);
      expect(claude.supportsTemperature, isFalse);
      expect(claude.supportsReasoning, isTrue);
      expect(claude.releasedAt, isNotEmpty);
    },
  );
  test(
    'hosted enrichment preserves user overrides instead of copying another platform',
    () {
      final initial = catalog.enrich(
        model('openai/gpt-oss-120b'),
        ProviderPreset.groq,
      );
      expect(initial.maxOutputTokens, 65536);
      final changed = initial.copyWith(
        contextWindow: 312000,
        maxOutputTokens: 16000,
        clearReasoningEffort: true,
        customFields: {'contextWindow', 'maxOutputTokens', 'reasoningEffort'},
      );
      final restored = catalog.enrich(
        ModelConfig.fromJson(changed.toJson()),
        ProviderPreset.groq,
      );
      expect(restored.contextWindow, 312000);
      expect(restored.maxOutputTokens, 16000);
      expect(restored.reasoningEffort, isNull);
      expect(restored.catalogEntry!.outputLimit, 65536);
      expect(restored.name, 'openai/gpt-oss-120b');
    },
  );
  Future<Map<String, dynamic>> wire(
    PromptAssistantProviderAdapter adapter,
    ProviderPreset preset,
    ModelConfig model,
  ) async {
    final dio = Dio();
    Map<String, dynamic>? payload;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          payload = (options.data as Map).cast<String, dynamic>();
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
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
              },
            ),
          );
        },
      ),
    );
    await adapter.complete(
      dio: dio,
      request: PromptAssistantRequest(
        sessionId: 'offline',
        provider: preset.createConfig(),
        model: model.name,
        modelConfig: model.copyWith(displayName: '请求不能使用此别名'),
        systemPrompt: 'Test',
        userParts: const [PromptAssistantTextPart('Test')],
        apiKey: null,
      ),
      cancelToken: CancelToken(),
    );
    dio.close();
    return payload!;
  }

  test(
    'actual adapters serialize model defaults using each vendor wire protocol',
    () async {
      final ds = catalog
          .enrich(model('deepseek-flash'), ProviderPreset.deepseek)
          .copyWith(reasoningEffort: 'none');
      final chat = await wire(
        const OpenAiChatCompletionsAdapter(),
        ProviderPreset.deepseek,
        ds,
      );
      expect(chat['model'], 'deepseek-flash');
      expect(chat['thinking'], {'type': 'disabled'});
      expect(chat, isNot(contains('reasoning_effort')));
      expect(chat['max_tokens'], ds.catalogEntry!.outputLimit);
      final gemini = catalog
          .enrich(model('gemini-2.5-flash'), ProviderPreset.gemini)
          .copyWith(reasoningEffort: 'low');
      final google = await wire(
        const GeminiGenerateContentAdapter(),
        ProviderPreset.gemini,
        gemini,
      );
      expect((google['generationConfig'] as Map)['thinkingConfig'], {
        'thinkingBudget': 1024,
      });
      final claude = catalog.enrich(
        model('claude-opus-5-5'),
        ProviderPreset.anthropic,
        protocol: ProviderProtocol.anthropicMessages,
      );
      final anthropic = await wire(
        const AnthropicMessagesAdapter(),
        ProviderPreset.anthropic,
        claude.copyWith(temperature: .4, topP: .9),
      );
      expect(anthropic['thinking'], {'type': 'adaptive'});
      expect(anthropic['output_config'], {'effort': 'medium'});
      expect(anthropic, isNot(contains('tools')));
      expect(anthropic, isNot(contains('temperature')));
      expect(anthropic, isNot(contains('top_p')));
      final legacySampling = claude.copyWith(temperature: .4, topP: .9);
      expect(
        RequestParameters.fromModel(
          legacySampling,
        ).validateFor(ProviderProtocol.anthropicMessages),
        isNull,
      );
      expect(legacySampling.toJson()['temperature'], .4);
      final openai = catalog
          .enrich(model('gpt-6.1-sol'), ProviderPreset.openaiResponses)
          .copyWith(temperature: .5);
      final responses = await wire(
        const OpenAiResponsesAdapter(),
        ProviderPreset.openaiResponses,
        openai,
      );
      expect(responses['model'], 'gpt-6.1-sol');
      expect(responses['reasoning'], {'effort': 'medium'});
      if (openai.catalogEntry!.supportsTemperature == false) {
        expect(responses, isNot(contains('temperature')));
      }
    },
  );
  test('offline facts resolve vendor aliases and exact gateway suffixes', () {
    final deepseek = catalog.enrich(
      model('deepseek-flash'),
      ProviderPreset.deepseek,
    );
    expect(deepseek.reasoningEfforts, ['none', 'low', 'high', 'max']);
    expect(deepseek.reasoningEffort, 'high');
    expect(deepseek.catalogEntry!.contextLimit, greaterThanOrEqualTo(1000000));
    expect(deepseek.contextWindow, deepseek.catalogEntry!.contextLimit);
    expect(deepseek.maxOutputTokens, deepseek.catalogEntry!.outputLimit);
    final gemini = catalog.enrich(
      model('models/gemini-3-flash-preview'),
      ProviderPreset.gemini,
    );
    expect(gemini.reasoningEfforts, ['minimal', 'low', 'medium', 'high']);
    expect(gemini.supportsVision, isTrue);
    expect(gemini.supportsNativeSearch, isTrue);
    final claude = catalog.enrich(
      model('devin/claude-opus-5-5'),
      ProviderPreset.openaiCompatibleChat,
    );
    expect(claude.catalogEntry!.name, 'Claude Opus 5.5');
    expect(claude.reasoningEfforts, contains('max'));
    expect(claude.reasoningProtocol, ModelReasoningProtocol.standard);
    expect(catalog.lookup(null, 'not-a-real-model'), isNull);
    expect(
      catalog.enrich(model('not-a-real-model'), null).supportsVision,
      isNull,
    );
  });
  test(
    'user values and explicit inheritance survive catalog enrichment and serialization',
    () {
      final initial = catalog.enrich(
        model('deepseek-flash'),
        ProviderPreset.deepseek,
      );
      final changed = initial.copyWith(
        displayName: '翻译模型',
        contextWindow: 312000,
        maxOutputTokens: 16000,
        reasoningEfforts: ['none', 'low'],
        clearReasoningEffort: true,
        supportsVision: false,
        customFields: {
          'displayName',
          'contextWindow',
          'maxOutputTokens',
          'reasoningEfforts',
          'reasoningEffort',
          'supportsVision',
        },
      );
      final restored = catalog.enrich(
        ModelConfig.fromJson(changed.toJson()),
        ProviderPreset.deepseek,
      );
      expect(restored.displayName, '翻译模型');
      expect(restored.contextWindow, 312000);
      expect(restored.maxOutputTokens, 16000);
      expect(restored.reasoningEffort, isNull);
      expect(restored.supportsVision, isFalse);
      expect(
        restored.catalogEntry!.contextLimit,
        initial.catalogEntry!.contextLimit,
      );
      expect(restored.name, 'deepseek-flash');
      expect(restored.toJson(), isNot(contains('catalogEntry')));
    },
  );
  test(
    'native reasoning maps toggles, budgets and adaptive mode without enabling search',
    () {
      final ds = catalog.enrich(
        model('deepseek-flash'),
        ProviderPreset.deepseek,
      );
      final provider = ProviderPreset.deepseek.createConfig();
      expect(
        chatReasoningOptions(provider, ds.copyWith(reasoningEffort: 'none')),
        {
          'thinking': {'type': 'disabled'},
        },
      );
      expect(chatReasoningOptions(provider, ds), {
        'thinking': {'type': 'enabled'},
        'reasoning_effort': 'high',
      });
      final oldGemini = catalog
          .enrich(model('gemini-2.5-flash'), ProviderPreset.gemini)
          .copyWith(reasoningEffort: 'none');
      expect(geminiThinkingOptions(oldGemini), {'thinkingBudget': 0});
      expect(
        geminiThinkingOptions(oldGemini.copyWith(reasoningEffort: 'low')),
        {'thinkingBudget': 1024},
      );
      final claude = catalog.enrich(
        model('claude-opus-5-5'),
        ProviderPreset.anthropic,
        protocol: ProviderProtocol.anthropicMessages,
      );
      expect(anthropicReasoningOptions(claude), {
        'thinking': {'type': 'adaptive'},
        'output_config': {'effort': 'medium'},
      });
      expect(anthropicReasoningOptions(claude), isNot(contains('tools')));
    },
  );
  test('provider model ordering survives configuration round trip', () {
    final config = PromptAssistantConfigState.defaults().copyWith(
      models: [model('z'), model('a'), model('m')],
    );
    expect(
      PromptAssistantConfigState.decode(
        config.encode(),
      ).modelsForProvider(providerId: 'test').map((m) => m.name),
      ['z', 'a', 'm'],
    );
  });
}
