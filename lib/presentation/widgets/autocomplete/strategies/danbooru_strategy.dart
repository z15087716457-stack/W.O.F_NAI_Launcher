import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/autocomplete/completion_models.dart';
import '../../../../core/autocomplete/prompt_token_parser.dart';
import '../../../../core/utils/tag_normalizer.dart';
import '../../../../data/models/tag/tag_suggestion.dart';
import '../../../providers/danbooru_suggestion_provider.dart';
import '../autocomplete_strategy.dart';
import '../generic_suggestion_tile.dart';

/// Danbooru 配置
class DanbooruConfig {
  /// 是否替换整个搜索文本（false 则只替换光标处的词）
  final bool replaceAll;

  final String separator;
  final bool appendSeparator;
  final int minQueryLength;

  /// 提示词模式保留 NAI 结构并插入空格；搜索模式保留 canonical 标签。
  final bool promptMode;

  const DanbooruConfig({
    this.replaceAll = false,
    this.separator = ' ',
    this.appendSeparator = true,
    this.minQueryLength = 2,
    this.promptMode = false,
  });
}

/// Danbooru 远程补全策略
///
/// 使用 Danbooru API 进行标签搜索
class DanbooruStrategy extends AutocompleteStrategy<TagSuggestion> {
  final WidgetRef _ref;
  final DanbooruConfig _config;

  /// 当前搜索词
  String _currentQuery = '';

  /// Provider 订阅
  ProviderSubscription<TagSuggestionState>? _subscription;

  DanbooruStrategy._({required WidgetRef ref, required DanbooruConfig config})
    : _ref = ref,
      _config = config {
    // 监听 Provider 状态变化
    _subscription = _ref.listenManual(danbooruSuggestionNotifierProvider, (
      previous,
      next,
    ) {
      notifyListeners();
    });
  }

  /// 工厂方法：创建 DanbooruStrategy
  static DanbooruStrategy create(
    WidgetRef ref, {
    bool replaceAll = false,
    String separator = ' ',
    bool appendSeparator = true,
    int minQueryLength = 2,
    bool promptMode = false,
  }) {
    return DanbooruStrategy._(
      ref: ref,
      config: DanbooruConfig(
        replaceAll: replaceAll,
        separator: separator,
        appendSeparator: appendSeparator,
        minQueryLength: minQueryLength,
        promptMode: promptMode,
      ),
    );
  }

  /// 获取配置
  DanbooruConfig get config => _config;

  @override
  List<TagSuggestion> get suggestions =>
      _ref.read(danbooruSuggestionNotifierProvider).suggestions;

  @override
  bool get isLoading => _ref.read(danbooruSuggestionNotifierProvider).isLoading;

  @override
  Future<void> search(
    String text,
    int cursorPosition, {
    bool immediate = false,
  }) async {
    final parsed = _query(text, cursorPosition);
    final query = parsed.kind == CompletionQueryKind.libraryAlias
        ? ''
        : parsed.token;

    // 检测是否为中文输入（中文1个字符即可触发搜索）
    final isChinese = RegExp(r'[\u4e00-\u9fa5]').hasMatch(query);
    final effectiveMinLength = isChinese ? 1 : _config.minQueryLength;

    if (query.length < effectiveMinLength) {
      clear();
      return;
    }

    // 如果查询相同，不重复搜索
    if (query == _currentQuery && suggestions.isNotEmpty) {
      return;
    }

    _currentQuery = query;

    // 直接搜索（中文搜索功能暂时简化，直接搜索中文关键词）
    _ref
        .read(danbooruSuggestionNotifierProvider.notifier)
        .search(query, immediate: immediate);
  }

  CompletionQuery _query(String text, int cursorPosition) {
    if (_config.promptMode) {
      return PromptTokenParser.parse(
        text: text,
        cursorPosition: cursorPosition,
        limit: 20,
        locale: 'en',
      );
    }
    final cursor = cursorPosition.clamp(0, text.length);
    var start = 0;
    var end = text.length;
    if (!_config.replaceAll) {
      for (final separator in _separatorPattern.allMatches(text)) {
        if (separator.start < cursor && cursor < separator.end) {
          start = cursor;
          end = cursor;
          break;
        }
        if (separator.end <= cursor) start = separator.end;
        if (separator.start >= cursor) {
          end = separator.start;
          break;
        }
      }
    }
    return CompletionQuery(
      fullText: text,
      cursorPosition: cursor,
      token: TagNormalizer.normalize(text.substring(start, end)),
      replacementRange: TextReplacementRange(start: start, end: end),
      existingTags: const {},
      limit: 20,
      locale: 'en',
    );
  }

  /// 逗号分隔模式同时接受空白，兼容 Danbooru 原生的空格分隔语法。
  RegExp get _separatorPattern => _config.separator == ','
      ? RegExp(r'[,，\s]+')
      : RegExp(RegExp.escape(_config.separator));

  @override
  void clear() {
    _currentQuery = '';
    _ref.read(danbooruSuggestionNotifierProvider.notifier).clear();
    notifyListeners();
  }

  @override
  SuggestionData toSuggestionData(TagSuggestion item) {
    return SuggestionData(
      tag: item.tag,
      category: item.category,
      count: item.count,
      translation: item.translation,
      alias: item.alias,
    );
  }

  @override
  (String, int) applySuggestion(
    TagSuggestion item,
    String text,
    int cursorPosition,
  ) {
    final query = _query(text, cursorPosition);
    if (query.kind == CompletionQueryKind.libraryAlias) {
      return (text, cursorPosition);
    }
    if (_config.promptMode) {
      final result = PromptTokenParser.apply(
        text: text,
        query: query,
        canonicalTag: item.tag,
        autoInsertComma: _config.appendSeparator,
        closeOpenWeight: true,
      );
      return (result.text, result.cursorPosition);
    }
    final range = query.replacementRange;
    final before = text.substring(0, range.start);
    var after = text.substring(range.end);
    var insertion = item.tag;
    if (_config.appendSeparator) {
      final existingSeparator = _separatorPattern.matchAsPrefix(after);
      if (existingSeparator != null) {
        insertion += existingSeparator.group(0)!;
        after = after.substring(existingSeparator.end);
      } else {
        insertion += _config.separator == ',' ? ', ' : _config.separator;
      }
    }
    return ('$before$insertion$after', before.length + insertion.length);
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }
}
