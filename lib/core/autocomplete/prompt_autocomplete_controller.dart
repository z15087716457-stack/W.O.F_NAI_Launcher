import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../tag_expansion/local_tag_expansion_service.dart';
import 'completion_models.dart';
import 'prompt_token_parser.dart';

typedef PromptAutocompleteSearch =
    Future<List<CompletionCandidate>> Function(CompletionQuery query);
typedef PromptAutocompleteRelatedSearch =
    Future<List<CompletionCandidate>> Function(
      String sourceTag, {
      required String locale,
      required Set<String> existingTags,
    });
typedef PromptAutocompleteRelatedFor = ({int index, String canonicalTag});

@immutable
class PromptAutocompleteState {
  const PromptAutocompleteState({
    this.query,
    this.candidates = const [],
    this.selectedIndex = 0,
    this.loading = false,
    this.error,
    this.relatedFor,
    this.related = const [],
    this.relatedLoading = false,
    this.relatedSelected = 0,
    this.relatedAdded = const {},
    this.relatedError,
  });
  final CompletionQuery? query;
  final List<CompletionCandidate> candidates;
  final int selectedIndex;
  final bool loading;
  final Object? error;
  final PromptAutocompleteRelatedFor? relatedFor;
  final List<CompletionCandidate> related;
  final bool relatedLoading;
  final int relatedSelected;
  final Set<String> relatedAdded;
  final Object? relatedError;
  bool get visible => candidates.isNotEmpty;
  int get anchorTextOffset => query?.replacementRange.start ?? 0;

  /// Tags available to the popup. The UI reports only viewport-visible rows to
  /// AutoTagTranslationController.observe(surface: ..., tag: ..., visible: ...)
  /// and removes that surface on dismissal. This never starts translations.
  List<String> get visibleTags => List.unmodifiable({
    ...candidates.map((c) => c.canonicalTag),
    ...related.map((c) => c.canonicalTag),
  });

  PromptAutocompleteState copyWith({
    CompletionQuery? query,
    int? selectedIndex,
    PromptAutocompleteRelatedFor? relatedFor,
    List<CompletionCandidate>? related,
    bool? relatedLoading,
    int? relatedSelected,
    Set<String>? relatedAdded,
    Object? relatedError,
    bool clearRelated = false,
  }) => PromptAutocompleteState(
    query: query ?? this.query,
    candidates: candidates,
    selectedIndex: selectedIndex ?? this.selectedIndex,
    loading: loading,
    error: error,
    relatedFor: clearRelated ? null : relatedFor ?? this.relatedFor,
    related: clearRelated ? const [] : related ?? this.related,
    relatedLoading: clearRelated
        ? false
        : relatedLoading ?? this.relatedLoading,
    relatedSelected: clearRelated ? 0 : relatedSelected ?? this.relatedSelected,
    relatedAdded: clearRelated ? const {} : relatedAdded ?? this.relatedAdded,
    relatedError: clearRelated ? null : relatedError ?? this.relatedError,
  );
}

/// Local-only, focus-free completion. The owner supplies current editing values
/// and applies the values returned by accept/acceptRelated; this never edits a draft.
class PromptAutocompleteController
    extends ValueNotifier<PromptAutocompleteState> {
  PromptAutocompleteController({
    required PromptAutocompleteSearch search,
    PromptAutocompleteRelatedSearch? relatedSearch,
    this.debounce = const Duration(milliseconds: 120),
    this.limit = 12,
    bool enabled = false,
  }) : _search = search,
       _relatedSearch = relatedSearch,
       _enabled = enabled,
       super(const PromptAutocompleteState());

  factory PromptAutocompleteController.local({
    required LocalTagExpansionService service,
    bool enabled = false,
  }) => PromptAutocompleteController(
    enabled: enabled,
    search: (query) => service.search(
      query.token,
      locale: query.locale,
      existingTags: query.existingTags,
      limit: query.limit,
    ),
    relatedSearch: (sourceTag, {required locale, required existingTags}) =>
        service.related(sourceTag, locale: locale, existingTags: existingTags),
  );

  final PromptAutocompleteSearch _search;
  final PromptAutocompleteRelatedSearch? _relatedSearch;
  final Duration debounce;
  final int limit;
  bool _enabled;
  bool _disposed = false;
  int _revision = 0;
  int _relatedRevision = 0;
  int? _relatedInsertionOffset;
  Timer? _timer;
  TextEditingValue? _editing;

  bool get enabled => _enabled;
  set enabled(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    dismiss();
  }

  void update(TextEditingValue editing, {required String locale}) {
    _editing = editing;
    dismiss();
    if (!_enabled ||
        !editing.selection.isValid ||
        !editing.selection.isCollapsed ||
        (editing.composing.isValid && !editing.composing.isCollapsed)) {
      return;
    }
    final query = PromptTokenParser.parse(
      text: editing.text,
      cursorPosition: editing.selection.extentOffset,
      limit: limit,
      locale: locale,
    );
    if (query.kind != CompletionQueryKind.tag ||
        query.token.runes.length < (query.isChinese ? 1 : 2) ||
        query.cursorPosition < query.replacementRange.start ||
        query.cursorPosition > query.replacementRange.end) {
      return;
    }
    final revision = _revision;
    _timer = Timer(debounce, () async {
      value = PromptAutocompleteState(query: query, loading: true);
      try {
        final candidates = await _search(query);
        if (_disposed || revision != _revision) return;
        value = PromptAutocompleteState(
          query: query,
          candidates: List.unmodifiable(candidates),
        );
      } catch (error) {
        if (_disposed || revision != _revision) return;
        value = PromptAutocompleteState(query: query, error: error);
      }
    });
  }

  TextEditingValue? accept([int? index, bool autoInsertComma = true]) {
    final state = value;
    final editing = _editing;
    final selected = index ?? state.selectedIndex;
    if (!state.visible ||
        editing == null ||
        selected < 0 ||
        selected >= state.candidates.length) {
      return null;
    }
    final result = PromptTokenParser.apply(
      text: editing.text,
      query: state.query!,
      canonicalTag: state.candidates[selected].canonicalTag,
      autoInsertComma: autoInsertComma,
    );
    dismiss();
    return _editing = _editingValue(result);
  }

  Future<void> openRelated(int index) async {
    final state = value;
    final search = _relatedSearch;
    if (!state.visible ||
        index < 0 ||
        index >= state.candidates.length ||
        search == null) {
      return;
    }
    closeRelated();
    final revision = _relatedRevision;
    final source = state.candidates[index].canonicalTag;
    value = value.copyWith(
      relatedFor: (index: index, canonicalTag: source),
      relatedLoading: true,
    );
    try {
      final related = await search(
        source,
        locale: state.query!.locale,
        existingTags: {...state.query!.existingTags, source},
      );
      if (_disposed || revision != _relatedRevision) return;
      value = value.copyWith(
        related: List.unmodifiable(related),
        relatedLoading: false,
        relatedAdded: Set.unmodifiable(
          related
              .where(
                (c) => PromptTokenParser.containsTag(
                  _editing!.text,
                  c.canonicalTag,
                ),
              )
              .map((c) => c.canonicalTag),
        ),
      );
    } catch (error) {
      if (_disposed || revision != _relatedRevision) return;
      value = value.copyWith(relatedLoading: false, relatedError: error);
    }
  }

  void closeRelated() {
    _relatedRevision++;
    _relatedInsertionOffset = null;
    if (!_disposed && value.relatedFor != null) {
      value = value.copyWith(clearRelated: true);
    }
  }

  /// Completes the source once, then appends tags at a stable insertion point.
  /// A null return means no text change (including an already-present tag).
  TextEditingValue? acceptRelated(int index, [bool autoInsertComma = true]) {
    final state = value;
    final source = state.relatedFor;
    final editing = _editing;
    if (source == null ||
        editing == null ||
        index < 0 ||
        index >= state.related.length) {
      return null;
    }
    final tag = state.related[index].canonicalTag;
    if (state.relatedAdded.contains(tag) ||
        PromptTokenParser.containsTag(editing.text, tag)) {
      return null;
    }

    final offset = _relatedInsertionOffset;
    final ({String text, int cursorPosition}) result;
    if (offset == null) {
      final completed = PromptTokenParser.apply(
        text: editing.text,
        query: state.query!,
        canonicalTag: source.canonicalTag,
        autoInsertComma: false,
      );
      result = PromptTokenParser.insertAtCaret(
        text: completed.text,
        cursorPosition: state.query!.replacementRange.start,
        canonicalTag: tag,
        autoInsertComma: autoInsertComma,
      );
    } else {
      result = PromptTokenParser.apply(
        text: editing.text,
        query: state.query!.copyWith(
          relatedTag: source.canonicalTag,
          replacementRange: TextReplacementRange(start: offset, end: offset),
        ),
        canonicalTag: tag,
        autoInsertComma: autoInsertComma,
      );
    }
    _relatedInsertionOffset = result.cursorPosition;
    _editing = _editingValue(result);
    value = state.copyWith(
      query: PromptTokenParser.parse(
        text: result.text,
        cursorPosition: state.query!.replacementRange.start,
        limit: limit,
        locale: state.query!.locale,
      ),
      relatedAdded: Set.unmodifiable({...state.relatedAdded, tag}),
      relatedSelected: index,
    );
    return _editing;
  }

  static TextEditingValue _editingValue(
    ({String text, int cursorPosition}) result,
  ) => TextEditingValue(
    text: result.text,
    selection: TextSelection.collapsed(offset: result.cursorPosition),
  );

  void move(int delta) {
    if (!value.visible) return;
    if (value.relatedFor != null) {
      if (value.related.isEmpty) return;
      value = value.copyWith(
        relatedSelected: (value.relatedSelected + delta) % value.related.length,
      );
    } else {
      value = value.copyWith(
        selectedIndex: (value.selectedIndex + delta) % value.candidates.length,
      );
    }
  }

  void dismiss() {
    _revision++;
    _relatedRevision++;
    _relatedInsertionOffset = null;
    _timer?.cancel();
    _timer = null;
    if (!_disposed) value = const PromptAutocompleteState();
  }

  /// Returns false when hidden, preserving normal editor shortcuts/newlines.
  bool handleKeyEvent(
    KeyEvent event, {
    required ValueChanged<TextEditingValue> onAccept,
    bool autoInsertComma = true,
  }) {
    if (!value.visible ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent) ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed ||
        HardwareKeyboard.instance.isShiftPressed) {
      return false;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      move(key == LogicalKeyboardKey.arrowUp ? -1 : 1);
    } else if (key == LogicalKeyboardKey.escape) {
      if (value.relatedFor != null) {
        closeRelated();
      } else {
        dismiss();
      }
    } else if (key == LogicalKeyboardKey.tab ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final result = value.relatedFor != null
          ? acceptRelated(value.relatedSelected, autoInsertComma)
          : accept(null, autoInsertComma);
      if (result != null) onAccept(result);
    } else {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    dismiss();
    _disposed = true;
    super.dispose();
  }
}
