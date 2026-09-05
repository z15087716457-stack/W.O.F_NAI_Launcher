import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/nai_api_endpoint_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/nai_prompt_segments.dart';
import '../../models/tag/tag_suggestion.dart';

part 'nai_tag_suggestion_api_service.g.dart';

/// NovelAI Tag Suggestion API 服务
class NAITagSuggestionApiService {
  static const Duration _timeout = Duration(seconds: 5);

  final Dio _dio;
  final NaiApiEndpointService _endpointService;

  NAITagSuggestionApiService(this._dio, this._endpointService);

  /// 获取标签建议
  Future<List<TagSuggestion>> suggestTags(String input, {String? model}) async {
    if (input.trim().length < 2) return [];

    try {
      final queryParams = <String, dynamic>{
        'prompt': input.trim(),
        if (model != null) 'model': model,
      };

      final response = await _dio.get(
        _endpointService.imageUrl(ApiConstants.suggestTagsEndpoint),
        queryParameters: queryParams,
        options: Options(receiveTimeout: _timeout, sendTimeout: _timeout),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('tags')) {
        return (data['tags'] as List)
            .map((t) => TagSuggestion.fromJson(t as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      AppLogger.w(
        'Tag suggestion request failed: ${e.message}',
        'NAITagSuggestion',
      );
      return [];
    } catch (e, stack) {
      AppLogger.e('Tag suggestion error', e, stack, 'NAITagSuggestion');
      return [];
    }
  }

  /// 根据当前提示词获取下一个标签建议
  Future<List<TagSuggestion>> suggestNextTag(
    String prompt, {
    String? model,
  }) async {
    final parts = splitNaiPromptSegments(prompt);
    if (parts.isEmpty || !prompt.trimRight().endsWith(parts.last)) return [];

    final lastPart = parts.last;
    if (lastPart.length < 2) return [];

    return suggestTags(lastPart, model: model);
  }
}

/// NAITagSuggestionApiService Provider
@Riverpod(keepAlive: true)
NAITagSuggestionApiService naiTagSuggestionApiService(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  final endpointService = ref.watch(naiApiEndpointServiceProvider);
  return NAITagSuggestionApiService(dio, endpointService);
}
