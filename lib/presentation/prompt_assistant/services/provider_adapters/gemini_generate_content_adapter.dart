import 'dart:convert';

import 'package:dio/dio.dart';

import '../../models/prompt_assistant_models.dart';
import 'prompt_assistant_adapter.dart';

class GeminiGenerateContentAdapter extends PromptAssistantProviderAdapter {
  const GeminiGenerateContentAdapter();

  @override
  Future<List<String>> fetchModels({
    required Dio dio,
    required ProviderConfig provider,
    required String? apiKey,
  }) async {
    final response = await dio.get<dynamic>(
      _resolveModelsEndpoint(provider),
      options: Options(
        headers: _headers(apiKey),
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
      _resolveGenerateEndpoint(request.provider, request.model),
      data: {
        'system_instruction': {
          'parts': [
            {'text': request.systemPrompt},
          ],
        },
        'contents': [
          {'role': 'user', 'parts': _parts(request.userParts)},
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
      if (apiKey != null && apiKey.trim().isNotEmpty)
        'x-goog-api-key': apiKey.trim(),
    };
  }

  List<Map<String, dynamic>> _parts(List<PromptAssistantContentPart> parts) {
    return [
      for (final part in parts)
        if (part is PromptAssistantTextPart)
          {'text': part.text}
        else if (part is PromptAssistantImagePart)
          {
            'inline_data': {
              'mime_type': part.mimeType,
              'data': base64Encode(part.bytes),
            },
          },
    ];
  }

  String _resolveGenerateEndpoint(ProviderConfig provider, String model) {
    final base = _resolveGeminiRoot(provider);
    final normalizedModel = model.startsWith('models/')
        ? model
        : 'models/$model';
    return '$base/$normalizedModel:generateContent';
  }

  String _resolveModelsEndpoint(ProviderConfig provider) {
    return '${_resolveGeminiRoot(provider)}/models';
  }

  String _resolveGeminiRoot(ProviderConfig provider) {
    final base = normalizedBaseUrl(provider.baseUrl);
    if (base.endsWith('/v1beta') || base.endsWith('/v1')) {
      return base;
    }
    return '$base/v1beta';
  }

  String _extractResponseContent(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final error = extractErrorMessage(raw);
      if (error != null) {
        throw StateError('LLM service returned an error: $error');
      }
      final candidates = raw['candidates'];
      if (candidates is List) {
        final parts = <String>[];
        for (final candidate in candidates) {
          if (candidate is Map<String, dynamic>) {
            final content = candidate['content'];
            if (content is Map<String, dynamic>) {
              final rawParts = content['parts'];
              if (rawParts is List) {
                parts.addAll(rawParts.map(contentToText));
              }
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
