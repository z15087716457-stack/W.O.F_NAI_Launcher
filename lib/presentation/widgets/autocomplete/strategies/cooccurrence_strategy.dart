import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/autocomplete/prompt_token_parser.dart';
import '../../../../core/services/smart_tag_recommendation_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../providers/image_generation_provider.dart';
import '../autocomplete_controller.dart';
import '../autocomplete_strategy.dart';
import '../generic_suggestion_tile.dart';

/// 共现标签推荐策略
///
/// 触发条件：光标前有 "tag," 模式且后面没有新输入时
/// 显示与该标签共现的相关标签推荐
class CooccurrenceStrategy extends AutocompleteStrategy<RecommendedTag> {
  final Future<SmartTagRecommendationService> _recommendationServiceFuture;
  SmartTagRecommendationService? _recommendationService;
  final AutocompleteConfig _config;
  final WidgetRef _ref;

  /// 当前建议列表
  List<RecommendedTag> _suggestions = [];

  /// 是否正在加载
  bool _isLoading = false;

  CooccurrenceStrategy._({
    required Future<SmartTagRecommendationService> recommendationServiceFuture,
    required AutocompleteConfig config,
    required WidgetRef ref,
  }) : _recommendationServiceFuture = recommendationServiceFuture,
       _config = config,
       _ref = ref;

  /// 工厂方法：创建 CooccurrenceStrategy
  static CooccurrenceStrategy create(WidgetRef ref, AutocompleteConfig config) {
    return CooccurrenceStrategy._(
      recommendationServiceFuture: ref.watch(
        smartTagRecommendationServiceProvider.future,
      ),
      config: config,
      ref: ref,
    );
  }

  @override
  List<RecommendedTag> get suggestions => _suggestions;

  @override
  bool get isLoading => _isLoading;

  @override
  Future<void> search(
    String text,
    int cursorPosition, {
    bool immediate = false,
  }) async {
    // 检查共现推荐设置是否开启
    final enabled = _ref.read(cooccurrenceSettingsProvider);
    if (!enabled) {
      clear();
      return;
    }

    // 检查是否满足触发条件
    final previousTag = _extractPreviousTag(text, cursorPosition);

    if (previousTag == null) {
      clear();
      return;
    }

    AppLogger.d(
      () => 'CooccurrenceStrategy: extracted previous tag: "$previousTag"',
      'CooccurrenceStrategy',
    );

    // 确保服务已加载
    _recommendationService ??= await _recommendationServiceFuture;

    // 检查共现数据是否可用
    if (!_recommendationService!.isDataAvailable) {
      clear();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 获取推荐标签
      final maxSuggestions = _config.maxSuggestions ?? 20;
      final recommendations = await _recommendationService!
          .getRecommendationsForTag(
            previousTag,
            limit: maxSuggestions * 2, // 获取更多以便过滤
          );

      // 提取文本中已有的标签（用于去重）
      final existingTags = _extractExistingTags(text, cursorPosition);

      // 过滤掉已存在的标签
      final filteredRecommendations = recommendations
          .where((rec) {
            final normalizedRec = rec.tag.toLowerCase().trim();
            final exists = existingTags.contains(normalizedRec);
            return !exists;
          })
          .take(maxSuggestions)
          .toList();

      _suggestions = filteredRecommendations;
      AppLogger.d(
        () =>
            'CooccurrenceStrategy: showing ${filteredRecommendations.length} '
            'suggestions for "$previousTag": '
            '${filteredRecommendations.map((r) => '"${r.tag}"').join(', ')}',
        'CooccurrenceStrategy',
      );
    } catch (e) {
      AppLogger.w(
        'CooccurrenceStrategy: error getting recommendations for "$previousTag": $e',
        'CooccurrenceStrategy',
      );
      _suggestions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void clear() {
    _suggestions = [];
    _isLoading = false;
    notifyListeners();
  }

  @override
  SuggestionData toSuggestionData(RecommendedTag item) {
    return SuggestionData(
      tag: item.tag,
      category: 0, // 共现标签默认分类
      count: item.cooccurrence, // 使用共现次数代替使用次数
      translation: item.translation,
      // 共现标签的特殊标记
      isCooccurrence: true,
    );
  }

  @override
  (String, int) applySuggestion(
    RecommendedTag item,
    String text,
    int cursorPosition,
  ) {
    if (cursorPosition < 0 || cursorPosition > text.length) {
      return (text, cursorPosition);
    }
    final before = text.substring(0, cursorPosition);
    final afterComma = RegExp(r'[,，]\s*$').hasMatch(before);
    final query = PromptTokenParser.parseRelated(
      text: afterComma ? before : text,
      cursorPosition: cursorPosition,
      limit: _config.maxSuggestions ?? 20,
      locale: 'en',
      splitOnSpaces: _config.treatSpacesAsSeparators,
    );
    if (query == null) return (text, cursorPosition);
    final result = PromptTokenParser.apply(
      text: text,
      query: query,
      canonicalTag: item.tag,
      autoInsertComma: _config.autoInsertComma,
      splitOnSpaces: _config.treatSpacesAsSeparators,
    );
    return (result.text, result.cursorPosition);
  }

  String? _extractPreviousTag(String text, int cursorPosition) {
    if (cursorPosition <= 0 || cursorPosition > text.length) return null;
    final before = text.substring(0, cursorPosition).trimRight();
    if (!before.endsWith(',') && !before.endsWith('，')) return null;
    return PromptTokenParser.parseRelated(
      text: text.substring(0, cursorPosition),
      cursorPosition: cursorPosition,
      limit: _config.maxSuggestions ?? 20,
      locale: 'en',
      splitOnSpaces: _config.treatSpacesAsSeparators,
    )?.relatedTag;
  }

  Set<String> _extractExistingTags(String text, int cursorPosition) {
    final query = PromptTokenParser.parse(
      text: text,
      cursorPosition: cursorPosition,
      limit: _config.maxSuggestions ?? 20,
      locale: 'en',
      splitOnSpaces: _config.treatSpacesAsSeparators,
    );
    return {...query.existingTags, if (query.token.isNotEmpty) query.token};
  }
}
