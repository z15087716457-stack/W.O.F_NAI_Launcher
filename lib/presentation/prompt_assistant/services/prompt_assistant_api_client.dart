import 'dart:convert';
import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/utils/app_logger.dart';
import '../models/prompt_assistant_models.dart';
import '../providers/model_request_history_provider.dart';
import 'provider_adapters/anthropic_messages_adapter.dart';
import 'provider_adapters/gemini_generate_content_adapter.dart';
import 'provider_adapters/openai_chat_completions_adapter.dart';
import 'provider_adapters/openai_responses_adapter.dart';
import 'provider_adapters/prompt_assistant_adapter.dart';

class PromptAssistantApiClient {
  PromptAssistantApiClient({
    required Dio dio,
    this.imageUploadMaxBytes = promptAssistantImageUploadMaxBytes,
    this.history,
  }) : _dio = dio;

  final Dio _dio;
  final ModelRequestHistory? history;
  final _gates = <String, _RequestGate>{};
  final int imageUploadMaxBytes;
  final Map<String, CancelToken> _cancelTokens = {};

  void cancelCurrentRequest({String? sessionId}) {
    if (sessionId == null || sessionId.isEmpty) {
      for (final token in _cancelTokens.values) {
        token.cancel('cancelled by user');
      }
      _cancelTokens.clear();
      return;
    }

    final token = _cancelTokens.remove(sessionId);
    token?.cancel('cancelled by user');
  }

  Future<List<String>> fetchModels({
    required ProviderConfig provider,
    required String? apiKey,
    bool usePresetFallback = true,
  }) {
    final defaults = provider.preset?.defaultModelNames ?? const [];
    return _adapterFor(provider)
        .fetchModels(dio: _dio, provider: provider, apiKey: apiKey)
        .then(
          (models) => models.isEmpty && usePresetFallback ? defaults : models,
        );
  }

  Stream<StreamingChunk> complete({
    required PromptAssistantRequest request,
  }) async* {
    _cancelTokens.remove(request.sessionId)?.cancel('replaced by new request');
    final cancelToken = CancelToken();
    _cancelTokens[request.sessionId] = cancelToken;
    final record = history?.begin(request);
    final watch = Stopwatch()..start();
    final gate = _gates.putIfAbsent(request.provider.id, _RequestGate.new);
    var acquired = false;
    var attempts = 0;
    try {
      final parameters = request.modelConfig;
      if (parameters != null) {
        final error = RequestParameters.fromModel(
          parameters,
        ).validateFor(request.provider.protocol);
        if (error != null) throw FormatException(error);
      }
      await gate.acquire(
        request.provider.maxConcurrentRequests.clamp(1, 20),
        cancelToken,
      );
      acquired = true;
      if (record != null) history?.update(record, '请求中');
      final upload = await optimizePromptAssistantRequestImagesForUpload(
        request,
        maxBytes: imageUploadMaxBytes,
      );
      String content;
      while (true) {
        if (cancelToken.isCancelled) throw cancelToken.cancelError!;
        attempts++;
        try {
          content = await _adapterFor(
            upload.provider,
          ).complete(dio: _dio, request: upload, cancelToken: cancelToken);
          break;
        } on DioException catch (error) {
          final status = error.response?.statusCode;
          final retryable =
              error.type == DioExceptionType.connectionError ||
              const [429, 502, 503, 504].contains(status);
          if (!retryable ||
              attempts > request.provider.retryAttempts ||
              cancelToken.isCancelled) {
            rethrow;
          }
          await Future.any([
            Future<void>.delayed(Duration(milliseconds: 400 * attempts)),
            cancelToken.whenCancel.then<void>((error) => throw error),
          ]);
        }
      }
      final trimmed = content.trim();
      if (trimmed.isEmpty) throw StateError('模型返回了空内容。');
      AppLogger.d(
        'response done provider=${request.provider.id} model=${request.model} outputLen=${trimmed.length}',
        'PromptAssistant',
      );
      if (record != null) {
        history?.update(
          record,
          '成功',
          elapsedMs: watch.elapsedMilliseconds,
          attempts: attempts,
        );
      }
      yield StreamingChunk(delta: trimmed);
      yield const StreamingChunk(delta: '', done: true);
    } on DioException catch (error) {
      if (record != null) {
        history?.update(
          record,
          cancelToken.isCancelled ? '已取消' : '失败',
          elapsedMs: watch.elapsedMilliseconds,
          attempts: attempts,
          error: error.response?.statusCode == null
              ? error.type.name
              : 'HTTP ${error.response!.statusCode}',
        );
      }
      throw StateError(_formatDioException(error, request));
    } catch (error) {
      if (record != null) {
        history?.update(
          record,
          '失败',
          elapsedMs: watch.elapsedMilliseconds,
          attempts: attempts,
          error: error.runtimeType.toString(),
        );
      }
      rethrow;
    } finally {
      if (acquired) gate.release();
      if (identical(_cancelTokens[request.sessionId], cancelToken)) {
        _cancelTokens.remove(request.sessionId);
      }
    }
  }

  // Legacy wrapper kept so older tests/callers that already build OpenAI-style
  // messages continue to work while the service layer migrates to typed parts.
  Stream<StreamingChunk> streamChat({
    required String sessionId,
    required ProviderConfig provider,
    required String model,
    required List<Map<String, dynamic>> messages,
    required String? apiKey,
  }) {
    return complete(
      request: PromptAssistantRequest(
        sessionId: sessionId,
        provider: provider,
        model: model,
        systemPrompt: _extractSystemPrompt(messages),
        userParts: _extractUserParts(messages),
        apiKey: apiKey,
      ),
    );
  }

  PromptAssistantProviderAdapter _adapterFor(ProviderConfig provider) {
    switch (provider.protocol) {
      case ProviderProtocol.openaiChatCompletions:
        return const OpenAiChatCompletionsAdapter();
      case ProviderProtocol.openaiResponses:
        return const OpenAiResponsesAdapter();
      case ProviderProtocol.anthropicMessages:
        return const AnthropicMessagesAdapter();
      case ProviderProtocol.geminiGenerateContent:
        return const GeminiGenerateContentAdapter();
      case ProviderProtocol.ollamaChatCompletions:
        return const OpenAiChatCompletionsAdapter(ollamaTagsFallback: true);
    }
  }

  static String _extractSystemPrompt(List<Map<String, dynamic>> messages) {
    for (final message in messages) {
      if (message['role'] == 'system') {
        return contentToText(message['content']);
      }
    }
    return '';
  }

  static List<PromptAssistantContentPart> _extractUserParts(
    List<Map<String, dynamic>> messages,
  ) {
    final parts = <PromptAssistantContentPart>[];
    for (final message in messages) {
      if (message['role'] != 'user') continue;
      _appendContentParts(parts, message['content']);
    }
    return parts.isEmpty ? const [PromptAssistantTextPart('')] : parts;
  }

  static void _appendContentParts(
    List<PromptAssistantContentPart> parts,
    dynamic content,
  ) {
    if (content is String) {
      parts.add(PromptAssistantTextPart(content));
      return;
    }
    if (content is List) {
      for (final item in content) {
        if (item is Map<String, dynamic>) {
          final type = item['type'];
          if (type == 'text') {
            parts.add(PromptAssistantTextPart(contentToText(item['text'])));
          } else if (type == 'image_url') {
            final imageUrl = item['image_url'];
            final url = imageUrl is Map ? imageUrl['url'] : null;
            if (url is String) {
              final parsed = parseDataUriImage(url);
              if (parsed != null) {
                parts.add(
                  PromptAssistantImagePart(
                    bytes: parsed.bytes,
                    mimeType: parsed.mimeType,
                  ),
                );
              }
            }
          }
        } else {
          final text = contentToText(item);
          if (text.isNotEmpty) {
            parts.add(PromptAssistantTextPart(text));
          }
        }
      }
      return;
    }
    final text = contentToText(content);
    if (text.isNotEmpty) {
      parts.add(PromptAssistantTextPart(text));
    }
  }

  String _previewBody(String raw) {
    final normalized = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 300) {
      return normalized;
    }
    return '${normalized.substring(0, 300)}...';
  }

  String _formatDioException(
    DioException error,
    PromptAssistantRequest request,
  ) {
    final response = error.response;
    final status = response?.statusCode;
    final target = _safeRequestTarget(response?.requestOptions);
    final detail =
        _extractDioErrorDetail(response?.data) ??
        error.message ??
        error.error?.toString();

    return [
      'LLM request failed',
      if (status != null) 'HTTP $status',
      'provider=${request.provider.name}',
      'model=${request.model}',
      if (target != null) 'endpoint=$target',
      if (detail != null && detail.trim().isNotEmpty) detail.trim(),
    ].join(': ');
  }

  String? _extractDioErrorDetail(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      final message = extractErrorMessage(data);
      if (message != null) return message;
      return _previewBody(_encodeErrorData(data));
    }
    if (data is Map) {
      final normalized = data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final message = extractErrorMessage(normalized);
      if (message != null) return message;
      return _previewBody(_encodeErrorData(normalized));
    }
    if (data is String) {
      final trimmed = data.trim();
      return trimmed.isEmpty ? null : _previewBody(trimmed);
    }
    return _previewBody(_encodeErrorData(data));
  }

  String _encodeErrorData(dynamic data) {
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }

  String? _safeRequestTarget(RequestOptions? options) {
    if (options == null) return null;
    final uri = options.uri;
    if (uri.hasScheme && uri.host.isNotEmpty) {
      final port = uri.hasPort ? ':${uri.port}' : '';
      final query = uri.hasQuery ? '?<redacted>' : '';
      return '${uri.scheme}://${uri.host}$port${uri.path}$query';
    }
    final query = uri.hasQuery ? '?<redacted>' : '';
    return '${uri.path}$query';
  }
}

class _RequestGate {
  int active = 0;
  final waiting = <Completer<void>>[];
  Future<void> acquire(int limit, CancelToken token) async {
    while (active >= limit) {
      final waiter = Completer<void>();
      waiting.add(waiter);
      try {
        await Future.any([
          waiter.future,
          token.whenCancel.then<void>((error) => throw error),
        ]);
      } finally {
        waiting.remove(waiter);
      }
    }
    if (token.isCancelled) throw token.cancelError!;
    active++;
  }

  void release() {
    active--;
    for (final waiter in waiting.toList()) {
      if (!waiter.isCompleted) waiter.complete();
    }
  }
}
