import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../tag_expansion/local_tag_expansion_service.dart';
import 'completion_models.dart';
import 'prompt_token_parser.dart';

typedef PromptAutocompleteSearch =
    Future<List<CompletionCandidate>> Function(CompletionQuery query);

@immutable
class PromptAutocompleteState {
  const PromptAutocompleteState({
    this.query,
    this.candidates = const [],
    this.selectedIndex = 0,
    this.loading = false,
    this.error,
  });
  final CompletionQuery? query;
  final List<CompletionCandidate> candidates;
  final int selectedIndex;
  final bool loading;
  final Object? error;
  bool get visible => candidates.isNotEmpty;
  int get anchorTextOffset => query?.replacementRange.start ?? 0;
}

/// Local-only, focus-free completion. The owner supplies current editing values
/// and applies the value returned by accept; this object never edits a draft.
class PromptAutocompleteController
    extends ValueNotifier<PromptAutocompleteState> {
  PromptAutocompleteController({
    required PromptAutocompleteSearch search,
    this.debounce = const Duration(milliseconds: 120),
    this.limit = 12,
    bool enabled = false,
  }) : _search = search,
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
  );

  final PromptAutocompleteSearch _search;
  final Duration debounce;
  final int limit;
  bool _enabled;
  bool _disposed = false;
  int _revision = 0;
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
    return TextEditingValue(
      text: result.text,
      selection: TextSelection.collapsed(offset: result.cursorPosition),
    );
  }

  void move(int delta) {
    if (!value.visible) return;
    value = PromptAutocompleteState(
      query: value.query,
      candidates: value.candidates,
      selectedIndex: (value.selectedIndex + delta) % value.candidates.length,
    );
  }

  void dismiss() {
    _revision++;
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
      dismiss();
    } else if (key == LogicalKeyboardKey.tab ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final result = accept(null, autoInsertComma);
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
