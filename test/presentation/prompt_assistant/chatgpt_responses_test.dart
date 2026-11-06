import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/openai_responses_adapter.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_adapters/prompt_assistant_adapter.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_api_client.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/model_request_history_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/model_request_overrides.dart';

class _Transport implements HttpClientAdapter {
  _Transport(this.reply);
  final ResponseBody Function(RequestOptions) reply;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => reply(options);
  @override
  void close({bool force = false}) {}
}

void main() {
  PromptAssistantRequest request() => PromptAssistantRequest(
    sessionId: 'test',
    provider: ProviderPreset.chatgpt.createConfig(),
    model: 'gpt-6-astra',
    apiKey: 'synthetic-private-token',
    modelConfig: const ModelConfig(
      name: 'gpt-6-astra',
      displayName: 'GPT-6-Astra',
      providerId: 'chatgpt',
      maxOutputTokens: 131072,
      reasoningEffort: 'medium',
      requestOverrides: ModelRequestOverrides(
        body: {'temperature': 0.5, 'max_output_tokens': 128},
      ),
    ),
    systemPrompt: 'Reply OK',
    userParts: const [PromptAssistantTextPart('OK')],
  );

  test(
    'plan completion omits unsupported catalog limits and overrides, records success',
    () async {
      final dio = Dio()
        ..httpClientAdapter = _Transport((options) {
          final body = options.data as Map;
          expect(options.uri.toString(), 'https://api.openai.com/v1/responses');
          expect(body.keys, isNot(contains('max_output_tokens')));
          expect(body.keys, isNot(contains('temperature')));
          expect(body['store'], false);
          expect(body['stream'], true);
          expect(body['reasoning'], {'effort': 'medium'});
          return ResponseBody.fromString(
            'data: {"type":"response.output_text.delta","delta":"OK"}\n\ndata: {"type":"response.completed"}\n\n',
            200,
            headers: {
              'content-type': ['text/event-stream'],
            },
          );
        });
      final history = ModelRequestHistory();
      final client = PromptAssistantApiClient(dio: dio, history: history);
      final chunks = await client.complete(request: request()).toList();
      expect(chunks.first.delta, 'OK');
      expect(history.records.single.status, ModelRequestStatus.success);
      dio.close();
      history.dispose();
    },
  );

  test(
    'HTTP error body on SSE requests remains readable and redacted in history',
    () async {
      final dio = Dio()
        ..httpClientAdapter = _Transport(
          (_) => ResponseBody.fromString(
            '{"error":{"message":"Unsupported parameter: max_output_tokens synthetic-private-token","code":"unsupported_parameter"}}',
            400,
            headers: {
              'content-type': ['application/json'],
            },
          ),
        );
      final history = ModelRequestHistory();
      final client = PromptAssistantApiClient(dio: dio, history: history);
      await expectLater(
        client.complete(request: request()).toList(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'detail',
            contains('Unsupported parameter: max_output_tokens'),
          ),
        ),
      );
      final response = history.records.single.exchanges.single;
      expect(response.statusCode, 400);
      expect(
        response.responseBody.toString(),
        contains('unsupported_parameter'),
      );
      expect(
        response.responseBody.toString(),
        isNot(contains('synthetic-private-token')),
      );
      dio.close();
      history.dispose();
    },
  );
  Stream<List<int>> events(List<Map<String, dynamic>> values) async* {
    final bytes = utf8.encode(
      values.map((e) => 'data: ${jsonEncode(e)}\r\n\r\n').join(),
    );
    for (final byte in bytes) {
      yield [byte];
    }
  }

  test('catalog uses visible server slugs, labels and order', () {
    expect(
      chatGptModels({
        'models': [
          {'slug': 'second', 'display_name': 'Second', 'visibility': 'list'},
          {'slug': 'hidden', 'display_name': 'Hidden', 'visibility': 'hide'},
          {'slug': 'first', 'display_name': 'First', 'visibility': 'list'},
        ],
      }),
      {'second': 'Second', 'first': 'First'},
    );
  });
  test('stream returns Unicode text only after completed', () async {
    expect(
      await readChatGptResponse(
        events([
          {'type': 'response.output_text.delta', 'delta': '你好'},
          {'type': 'response.completed'},
        ]),
      ),
      '你好',
    );
  });
  test(
    'partial text is not success after a usage failure, incomplete response or EOF',
    () async {
      for (final terminal in [
        'response.failed',
        'response.incomplete',
        'error',
        'EOF',
      ]) {
        await expectLater(
          readChatGptResponse(
            events([
              {'type': 'response.output_text.delta', 'delta': 'partial'},
              if (terminal != 'EOF') {'type': terminal},
            ]),
          ),
          throwsStateError,
        );
      }
    },
  );
  test(
    'ChatGPT preset preserves OAuth routing through settings serialization',
    () {
      final provider = ProviderPreset.chatgpt.createConfig();
      final restored = ProviderConfig.fromJson(provider.toJson());
      expect(restored.usesChatGptPlan, true);
      expect(restored.protocol, ProviderProtocol.openaiResponses);
      restored.validateChatGptRoute();
      expect(
        () => restored
            .copyWith(baseUrl: 'https://example.invalid/v1')
            .validateChatGptRoute(),
        throwsStateError,
      );
      expect(
        () => restored
            .copyWith(protocol: ProviderProtocol.openaiChatCompletions)
            .validateChatGptRoute(),
        throwsStateError,
      );
    },
  );
}
