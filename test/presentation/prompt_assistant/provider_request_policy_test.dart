import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/model_catalog_entry.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/model_request_overrides.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/anthropic_messages_adapter.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/gemini_generate_content_adapter.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/openai_chat_completions_adapter.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/openai_responses_adapter.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/prompt_assistant_adapter.dart';

class _Dio extends Mock implements Dio {}

void main() {
  setUpAll(() => registerFallbackValue(RequestOptions(path: '/')));
  const adapters = <ProviderProtocol, PromptAssistantProviderAdapter>{
    ProviderProtocol.openaiChatCompletions: OpenAiChatCompletionsAdapter(),
    ProviderProtocol.ollamaChatCompletions: OpenAiChatCompletionsAdapter(),
    ProviderProtocol.openaiResponses: OpenAiResponsesAdapter(),
    ProviderProtocol.anthropicMessages: AnthropicMessagesAdapter(),
    ProviderProtocol.geminiGenerateContent: GeminiGenerateContentAdapter(),
  };
  for (final entry in adapters.entries) {
    for (final providerFlag in [true, false]) {
      for (final vision in [true, false]) {
        for (final custom in [true, false]) {
          test(
            '${entry.key.name} provider=$providerFlag vision=$vision custom=$custom',
            () async {
              final dio = _Dio();
              late Map<String, dynamic> payload;
              when(
                () => dio.post<dynamic>(
                  any(),
                  data: any(named: 'data'),
                  options: any(named: 'options'),
                  cancelToken: any(named: 'cancelToken'),
                ),
              ).thenAnswer((invocation) async {
                payload =
                    invocation.namedArguments[#data] as Map<String, dynamic>;
                return Response<dynamic>(
                  requestOptions: RequestOptions(path: '/'),
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
              final google =
                  entry.key == ProviderProtocol.geminiGenerateContent;
              final overrides = google
                  ? {
                      'generationConfig': {
                        'temperature': .25,
                        'topP': .75,
                        'custom_field': true,
                      },
                    }
                  : {'temperature': .25, 'top_p': .75, 'custom_field': true};
              final model = ModelConfig(
                providerId: 'p',
                name: 'test',
                displayName: 'test',
                // Explicit model capability must win over opposite catalog data.
                supportsVision: vision,
                catalogEntry: ModelCatalogEntry(
                  id: 'test',
                  vendor: 'test',
                  name: 'test',
                  supportsVision: !vision,
                ),
                temperature: 1.5,
                topP: .9,
                maxOutputTokens: 500,
                requestOverrides: custom
                    ? ModelRequestOverrides(body: overrides)
                    : null,
              );
              await entry.value.complete(
                dio: dio,
                cancelToken: CancelToken(),
                request: PromptAssistantRequest(
                  sessionId: 'test',
                  provider: ProviderConfig(
                    id: 'p',
                    name: 'p',
                    baseUrl: 'https://example.test/v1',
                    protocol: entry.key,
                    allowImageInput: providerFlag,
                  ),
                  model: 'test',
                  modelConfig: model,
                  systemPrompt: 'system',
                  apiKey: null,
                  userParts: [
                    PromptAssistantContentPart.text('text'),
                    PromptAssistantContentPart.image(
                      bytes: Uint8List.fromList([1, 2, 3]),
                      mimeType: 'image/png',
                    ),
                  ],
                ),
              );
              final sampling = google
                  ? payload['generationConfig'] as Map
                  : payload;
              expect(sampling.containsKey('temperature'), custom);
              expect(sampling.containsKey(google ? 'topP' : 'top_p'), custom);
              if (custom) {
                expect(sampling['temperature'], .25);
                expect(sampling[google ? 'topP' : 'top_p'], .75);
                expect(sampling['custom_field'], true);
              }
              final wire = payload.toString();
              expect(wire.contains('AQID'), vision);
              expect(wire, contains('text'));
              expect(RequestParameters.fromModel(model).toJson(), {
                'maxOutputTokens': 500,
              });
              expect(
                RequestParameters.fromModel(model).validateFor(entry.key),
                isNull,
              );
              expect(ModelConfig.fromJson(model.toJson()).temperature, 1.5);
              expect(ModelConfig.fromJson(model.toJson()).topP, .9);
            },
          );
        }
      }
    }
  }

  test(
    'catalog vision fallback and unknown capability ignore legacy provider flag',
    () {
      PromptAssistantRequest request(ModelConfig model) =>
          PromptAssistantRequest(
            sessionId: 'test',
            provider: const ProviderConfig(
              id: 'p',
              name: 'p',
              baseUrl: '',
              allowImageInput: false,
            ),
            model: 'test',
            modelConfig: model,
            systemPrompt: '',
            apiKey: null,
            userParts: [
              PromptAssistantContentPart.image(
                bytes: Uint8List(1),
                mimeType: 'image/png',
              ),
            ],
          );
      const model = ModelConfig(
        providerId: 'p',
        name: 'test',
        displayName: 'test',
      );
      expect(request(model).modelUserParts, isEmpty);
      expect(
        request(
          model.copyWith(
            catalogEntry: const ModelCatalogEntry(
              id: 'test',
              vendor: 'test',
              name: 'test',
              supportsVision: true,
            ),
          ),
        ).modelUserParts,
        hasLength(1),
      );
      final provider = ProviderConfig.fromJson(
        const ProviderConfig(
          id: 'p',
          name: 'p',
          baseUrl: '',
          allowImageInput: true,
        ).toJson(),
      );
      expect(provider.allowImageInput, true);
    },
  );
}
