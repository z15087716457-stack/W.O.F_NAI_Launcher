import 'package:dio/dio.dart';

import '../../models/prompt_assistant_models.dart';
import 'openai_chat_completions_adapter.dart';
import 'prompt_assistant_adapter.dart';

class OpenAiResponsesAdapter extends PromptAssistantProviderAdapter {
  const OpenAiResponsesAdapter();

  @override
  Future<List<String>> fetchModels({
    required Dio dio,
    required ProviderConfig provider,
    required String? apiKey,
  }) {
    return const OpenAiChatCompletionsAdapter().fetchModels(
      dio: dio,
      provider: provider,
      apiKey: apiKey,
    );
  }

  @override
  Future<String> complete({
    required Dio dio,
    required PromptAssistantRequest request,
    required CancelToken cancelToken,
  }) async {
    final headers = <String, dynamic>{'Content-Type': 'application/json'};
    if (request.apiKey != null && request.apiKey!.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${request.apiKey!.trim()}';
    }

    final response = await dio.post<dynamic>(
      _resolveEndpoint(request.provider),
      data: {
        'model': request.model,
        'stream': false,
        'instructions': request.systemPrompt,
        'input': [
          {'role': 'user', 'content': _inputParts(request.userParts)},
        ],
      },
      options: Options(
        headers: headers,
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
      ),
      cancelToken: cancelToken,
    );

    return _extractResponseContent(response.data);
  }

  List<Map<String, dynamic>> _inputParts(
    List<PromptAssistantContentPart> parts,
  ) {
    return [
      for (final part in parts)
        if (part is PromptAssistantTextPart)
          {'type': 'input_text', 'text': part.text}
        else if (part is PromptAssistantImagePart)
          {
            'type': 'input_image',
            'image_url': imageDataUri(part),
            'detail': 'auto',
          },
    ];
  }

  String _resolveEndpoint(ProviderConfig provider) {
    final base = normalizedBaseUrl(provider.baseUrl);
    if (base.endsWith('/responses')) {
      return base;
    }
    if (base.endsWith('/v1')) {
      return '$base/responses';
    }
    return '$base/v1/responses';
  }

  String _extractResponseContent(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final error = extractErrorMessage(raw);
      if (error != null) {
        throw StateError('LLM service returned an error: $error');
      }
      final outputText = contentToText(raw['output_text']);
      if (outputText.isNotEmpty) return outputText;

      final output = raw['output'];
      if (output is List) {
        final parts = <String>[];
        for (final item in output) {
          if (item is Map<String, dynamic>) {
            final content = item['content'];
            if (content is List) {
              for (final part in content) {
                parts.add(contentToText(part));
              }
            } else {
              parts.add(contentToText(content));
            }
          }
        }
        final joined = parts.where((e) => e.isNotEmpty).join();
        if (joined.isNotEmpty) return joined;
      }
    }
    return contentToText(raw);
  }
}
