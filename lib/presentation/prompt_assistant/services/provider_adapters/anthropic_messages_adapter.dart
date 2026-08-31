import 'dart:convert';

import 'package:dio/dio.dart';

import '../../models/prompt_assistant_models.dart';
import 'prompt_assistant_adapter.dart';

class AnthropicMessagesAdapter extends PromptAssistantProviderAdapter {
  const AnthropicMessagesAdapter();

  @override
  Future<List<String>> fetchModels({
    required Dio dio,
    required ProviderConfig provider,
    required String? apiKey,
  }) async {
    final headers = _headers(apiKey);
    final response = await dio.get<dynamic>(
      _resolveModelsEndpoint(provider),
      options: Options(
        headers: headers,
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    return extractModelNames(response.data);
  }

  @override
  Future<String> complete({
    required Dio dio,
    required PromptAssistantRequest request,
    required CancelToken cancelToken,
  }) async {
    final response = await dio.post<dynamic>(
      _resolveMessagesEndpoint(request.provider),
      data: {
        'model': request.model,
        'max_tokens': 2048,
        'system': request.systemPrompt,
        'messages': [
          {'role': 'user', 'content': _contentParts(request.userParts)},
        ],
      },
      options: Options(
        headers: _headers(request.apiKey),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
      ),
      cancelToken: cancelToken,
    );
    return _extractResponseContent(response.data);
  }

  Map<String, dynamic> _headers(String? apiKey) {
    return {
      'Content-Type': 'application/json',
      'anthropic-version': '2023-06-01',
      if (apiKey != null && apiKey.trim().isNotEmpty)
        'x-api-key': apiKey.trim(),
    };
  }

  List<Map<String, dynamic>> _contentParts(
    List<PromptAssistantContentPart> parts,
  ) {
    return [
      for (final part in parts)
        if (part is PromptAssistantTextPart)
          {'type': 'text', 'text': part.text}
        else if (part is PromptAssistantImagePart)
          {
            'type': 'image',
            'source': {
              'type': 'base64',
              'media_type': part.mimeType,
              'data': base64Encode(part.bytes),
            },
          },
    ];
  }

  String _resolveMessagesEndpoint(ProviderConfig provider) {
    final base = normalizedBaseUrl(provider.baseUrl);
    if (base.endsWith('/messages')) {
      return base;
    }
    if (base.endsWith('/v1')) {
      return '$base/messages';
    }
    return '$base/v1/messages';
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

  String _extractResponseContent(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final error = extractErrorMessage(raw);
      if (error != null) {
        throw StateError('LLM service returned an error: $error');
      }
      final content = raw['content'];
      if (content is List) {
        return content.map(contentToText).where((e) => e.isNotEmpty).join();
      }
    }
    return contentToText(raw);
  }
}
