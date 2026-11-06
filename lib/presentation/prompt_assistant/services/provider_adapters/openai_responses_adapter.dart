import 'dart:convert';

import 'package:dio/dio.dart';

import '../../models/prompt_assistant_models.dart';
import 'openai_chat_completions_adapter.dart';
import 'prompt_assistant_adapter.dart';
import '../../../../core/utils/localization_extension.dart';

class OpenAiResponsesAdapter extends PromptAssistantProviderAdapter {
  const OpenAiResponsesAdapter();

  @override
  Future<List<String>> fetchModels({
    required Dio dio,
    required ProviderConfig provider,
    required String? apiKey,
  }) async {
    provider.validateChatGptRoute();
    if (provider.usesChatGptPlan) {
      final response = await dio.get<dynamic>(
        'https://api.openai.com/v1/models',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );
      return chatGptModels(response.data).keys.toList();
    }
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
    request.provider.validateChatGptRoute();
    if (request.provider.usesChatGptPlan &&
        (request.modelConfig?.requestOverrides?.headers.isNotEmpty ?? false)) {
      throw StateError(currentL10n.chatGpt_invalidRoute);
    }
    final headers = <String, dynamic>{'Content-Type': 'application/json'};
    if (request.apiKey != null && request.apiKey!.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${request.apiKey!.trim()}';
    }
    final requestHeaders = promptAssistantHeaders(
      request.provider,
      headers,
      model: request.modelConfig,
    );

    final payload = <String, dynamic>{
      'model': request.model,
      'stream': false,
      'instructions': request.systemPrompt,
      'input': [
        {'role': 'user', 'content': _inputParts(request.modelUserParts)},
      ],
      if (request.modelConfig?.maxOutputTokens case final int limit)
        'max_output_tokens': limit,
      if (request.modelConfig?.reasoningEffort case final String effort)
        'reasoning': {'effort': effort},
    };

    final body = promptAssistantRequestBody(request, payload);
    if (request.provider.usesChatGptPlan) {
      // ChatGPT plan usage is a restricted Responses route, even when a
      // catalog or a saved request override supplies ordinary API parameters.
      for (final field in chatGptUnsupportedFields) {
        body.remove(field);
      }
      body['store'] = false;
      body['stream'] = true;
      final response = await dio.post<ResponseBody>(
        _resolveEndpoint(request.provider),
        data: body,
        options: Options(
          headers: requestHeaders,
          responseType: ResponseType.stream,
          receiveTimeout: promptAssistantTimeout(request.provider),
        ),
        cancelToken: cancelToken,
      );
      return readChatGptResponse(response.data!.stream);
    }
    final response = await dio.post<dynamic>(
      _resolveEndpoint(request.provider),
      data: body,
      options: Options(
        headers: requestHeaders,
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: promptAssistantTimeout(request.provider),
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

const chatGptUnsupportedFields = {
  'background',
  'conversation',
  'max_output_tokens',
  'max_tool_calls',
  'metadata',
  'moderation',
  'multi_agent',
  'prompt',
  'prompt_cache_retention',
  'safety_identifier',
  'temperature',
  'top_logprobs',
  'top_p',
  'truncation',
  'user',
  'previous_response_id',
};

/// The ChatGPT plan catalog differs from the API-key catalog (slug, not id).
Map<String, String> chatGptModels(dynamic raw) {
  final models = (raw as Map<String, dynamic>)['models'] as List;
  return {
    for (final entry in models.cast<Map<String, dynamic>>())
      if (entry['visibility'] == 'list')
        entry['slug'] as String: entry['display_name'] as String,
  };
}

Future<String> readChatGptResponse(Stream<List<int>> stream) async {
  final text = StringBuffer();
  final data = <String>[];
  await for (final line
      in utf8.decoder.bind(stream).transform(const LineSplitter())) {
    if (line.startsWith('data:')) {
      data.add(line.substring(5).trimLeft());
    } else if (line.isEmpty && data.isNotEmpty) {
      final raw = data.join('\n');
      data.clear();
      if (raw == '[DONE]') break;
      final event = jsonDecode(raw) as Map<String, dynamic>;
      switch (event['type']) {
        case 'response.output_text.delta':
          text.write(event['delta'] as String);
        case 'response.completed':
          return text.toString();
        case 'response.failed':
        case 'error':
          throw StateError(currentL10n.chatGpt_inferenceFailed);
        case 'response.incomplete':
          throw StateError(currentL10n.chatGpt_incomplete);
      }
    }
  }
  throw StateError(currentL10n.chatGpt_incomplete);
}
