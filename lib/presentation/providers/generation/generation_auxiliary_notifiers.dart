import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/datasources/remote/nai_tag_suggestion_api_service.dart';
import '../../../data/models/tag/tag_suggestion.dart';

part 'generation_auxiliary_notifiers.g.dart';

// ==================== 标签建议 Provider ====================

/// 标签建议状态
class TagSuggestionState {
  final List<TagSuggestion> suggestions;
  final bool isLoading;
  final String? error;

  const TagSuggestionState({
    this.suggestions = const [],
    this.isLoading = false,
    this.error,
  });

  TagSuggestionState copyWith({
    List<TagSuggestion>? suggestions,
    bool? isLoading,
    String? error,
  }) {
    return TagSuggestionState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 标签建议 Notifier
@riverpod
class TagSuggestionNotifier extends _$TagSuggestionNotifier {
  Timer? _debounceTimer;

  @override
  TagSuggestionState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const TagSuggestionState();
  }

  /// 获取标签建议 (带防抖)
  void fetchSuggestions(String input, {String? model}) {
    _debounceTimer?.cancel();

    if (input.trim().length < 2) {
      state = const TagSuggestionState();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      state = state.copyWith(isLoading: true, error: null);

      try {
        final apiService = ref.read(naiTagSuggestionApiServiceProvider);
        final suggestions = await apiService.suggestTags(input, model: model);
        state = state.copyWith(suggestions: suggestions, isLoading: false);
      } catch (e) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    });
  }

  /// 清除建议
  void clearSuggestions() {
    _debounceTimer?.cancel();
    state = const TagSuggestionState();
  }
}
