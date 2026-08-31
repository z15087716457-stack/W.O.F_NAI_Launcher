import 'package:dio/dio.dart';

import '../../models/prompt_assistant_models.dart';
import 'prompt_assistant_adapter.dart';

class OpenAiChatCompletionsAdapter extends PromptAssistantProviderAdapter {
  const OpenAiChatCompletionsAdapter({this.ollamaTagsFallback = false});

  final bool ollamaTagsFallback;

  @override
  Future<List<String>> fetchModels({
    required Dio dio,
    required ProviderConfig provider,
    required String? apiKey,
  }) async {
    if (provider.preset == ProviderPreset.pollinations ||
        provider.type == ProviderType.pollinations) {
      return const ['openai-large'];
    }

    final headers = <String, dynamic>{};
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${apiKey.trim()}';
    }

    final endpoints = <String>[
      _resolveModelsEndpoint(provider),
      if (ollamaTagsFallback ||
          provider.protocol == ProviderProtocol.ollamaChatCompletions)
        _resolveOllamaTagsEndpoint(provider),
    ];

    DioException? lastError;
    for (final endpoint in endpoints.toSet()) {
      try {
        final response = await dio.get<dynamic>(
          endpoint,
          options: Options(
            headers: headers,
            sendTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );
        final names = extractModelNames(response.data);
        if (names.isNotEmpty) {
          return names;
        }
      } on DioException catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
    return provider.preset?.defaultModelNames ?? const [];
  }

  @override
  Future<String> complete({
    required Dio dio,
    required PromptAssistantRequest request,
    required CancelToken cancelToken,
  }) async {
    final endpoint = _resolveEndpoint(request.provider);
    final payload = <String, dynamic>{
      'model': request.model,
      'stream': false,
      'messages': _buildMessages(request),
    };

    final response = await _postWithFallback(
      dio: dio,
      request: request,
      endpoint: endpoint,
      payload: payload,
      cancelToken: cancelToken,
    );
    return _extractResponseContent(response.data);
  }

  Future<Response<dynamic>> _postWithFallback({
    required Dio dio,
    required PromptAssistantRequest request,
    required String endpoint,
    required Map<String, dynamic> payload,
    required CancelToken cancelToken,
  }) async {
    final headers = <String, dynamic>{'Content-Type': 'application/json'};
    if (request.apiKey != null && request.apiKey!.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${request.apiKey!.trim()}';
    }

    try {
      return await dio.post<dynamic>(
        endpoint,
        data: payload,
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 2),
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final shouldRetryDeepSeek =
          request.provider.preset == ProviderPreset.deepseek &&
          (status == 400 || status == 404) &&
          endpoint.endsWith('/v1/chat/completions');
      if (shouldRetryDeepSeek) {
        return dio.post<dynamic>(
          endpoint.replaceFirst('/v1/chat/completions', '/chat/completions'),
          data: payload,
          options: Options(
            headers: headers,
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(minutes: 2),
          ),
          cancelToken: cancelToken,
        );
      }
      if (status == 400) {
        return dio.post<dynamic>(
          endpoint,
          data: {
            'model': payload['model'],
            'stream': false,
            'messages': payload['messages'],
          },
          options: Options(
            headers: headers,
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(minutes: 2),
          ),
          cancelToken: cancelToken,
        );
      }
      rethrow;
    }
  }

  List<Map<String, dynamic>> _buildMessages(PromptAssistantRequest request) {
    return [
      if (request.systemPrompt.trim().isNotEmpty)
        {'role': 'system', 'content': request.systemPrompt.trim()},
      {'role': 'user', 'content': _buildUserContent(request.userParts)},
    ];
  }

  Object _buildUserContent(List<PromptAssistantContentPart> parts) {
    final hasImage = parts.any((part) => part is PromptAssistantImagePart);
    if (!hasImage) {
      return parts.map(_partText).where((e) => e.isNotEmpty).join('\n');
    }

    return [
      for (final part in parts)
        if (part is PromptAssistantTextPart)
          {'type': 'text', 'text': part.text}
        else if (part is PromptAssistantImagePart)
          {
            'type': 'image_url',
            'image_url': {'url': imageDataUri(part)},
          },
    ];
  }

  String _partText(PromptAssistantContentPart part) {
    if (part is PromptAssistantTextPart) {
      return part.text;
    }
    return '';
  }

  String _resolveEndpoint(ProviderConfig provider) {
    if (provider.preset == ProviderPreset.pollinations ||
        provider.type == ProviderType.pollinations) {
      return 'https://gen.pollinations.ai/v1/chat/completions';
    }

    final base = normalizedBaseUrl(provider.baseUrl);
    if (base.endsWith('/chat/completions')) {
      return base;
    }
    if (base.endsWith('/v1')) {
      return '$base/chat/completions';
    }
    return '$base/v1/chat/completions';
  }

  String _resolveModelsEndpoint(ProviderConfig provider) {
    final base = normalizedBaseUrl(provider.baseUrl);
    if (base.endsWith('/models')) {
      return base;
    }
    if (base.endsWith('/v1')) {
      return '$base/models';
    }
    return '$base/v1/models';
  }

  String _resolveOllamaTagsEndpoint(ProviderConfig provider) {
    final base = normalizedBaseUrl(provider.baseUrl);
    if (base.endsWith('/v1')) {
      return '${base.substring(0, base.length - 3)}/api/tags';
    }
    return '$base/api/tags';
  }

  String _extractResponseContent(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final error = extractErrorMessage(raw);
      if (error != null) {
        throw StateError('LLM service returned an error: $error');
      }
      final choices = raw['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map<String, dynamic>) {
          final delta = first['delta'];
          if (delta is Map<String, dynamic>) {
            return contentToText(delta['content']);
          }
          final message = first['message'];
          if (message is Map<String, dynamic>) {
            return contentToText(message['content']);
          }
          return contentToText(first['text']);
        }
      }
      final outputText = contentToText(raw['output_text']);
      if (outputText.isNotEmpty) return outputText;
      final message = raw['message'];
      if (message is Map<String, dynamic>) {
        return contentToText(message['content']);
      }
      final text = contentToText(raw['text']);
      if (text.isNotEmpty) return text;
      final response = contentToText(raw['response']);
      if (response.isNotEmpty) return response;
    }
    return contentToText(raw);
  }
}
