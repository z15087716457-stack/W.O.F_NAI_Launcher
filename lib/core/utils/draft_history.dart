import 'dart:async';

import 'package:flutter/widgets.dart';

/// Immediate snapshot history. Only consecutive user edits share a 500 ms
/// group; programmatic replacements and undo/redo always close that group.
class DraftHistory<T> {
  DraftHistory(T initial, {bool Function(T, T)? sameContent})
    : _values = [initial],
      _sameContent = sameContent ?? ((a, b) => a == b);

  final List<T> _values;
  final bool Function(T, T) _sameContent;
  int _index = 0;
  bool _groupOpen = false;
  Timer? _groupTimer;

  bool get canUndo => _index > 0;
  bool get canRedo => _index + 1 < _values.length;

  void record(T value, {bool merge = false}) {
    if (!merge) closeGroup();
    if (_sameContent(value, _values[_index])) {
      _values[_index] = value;
      return;
    }
    _values.removeRange(_index + 1, _values.length);
    if (merge && _groupOpen && _index > 0) {
      _values[_index] = value;
    } else {
      _values.add(value);
      _index++;
    }
    if (merge) {
      _groupOpen = true;
      _groupTimer?.cancel();
      _groupTimer = Timer(const Duration(milliseconds: 500), closeGroup);
    }
  }

  void closeGroup() {
    _groupTimer?.cancel();
    _groupOpen = false;
  }

  T? undo() {
    closeGroup();
    return canUndo ? _values[--_index] : null;
  }

  T? redo() {
    closeGroup();
    return canRedo ? _values[++_index] : null;
  }

  void dispose() => closeGroup();
}

/// Controller adapter used by the translation draft fields. Selection-only
/// changes update the current snapshot; incomplete IME composition is not saved.
class TextDraftHistory {
  TextDraftHistory(this.controller)
    : _history = DraftHistory(
        controller.value,
        sameContent: (a, b) => a.text == b.text,
      ) {
    controller.addListener(_record);
  }

  final TextEditingController controller;
  final DraftHistory<TextEditingValue> _history;
  bool _applying = false;

  void _record() {
    if (_applying ||
        !controller.value.composing.isCollapsed &&
            controller.value.composing.isValid) {
      return;
    }
    _history.record(
      controller.value.copyWith(composing: TextRange.empty),
      merge: true,
    );
  }

  void replace(TextEditingValue value) {
    _history.closeGroup();
    controller.value = value;
    _history.closeGroup();
  }

  void undo() => _restore(_history.undo());
  void redo() => _restore(_history.redo());

  void _restore(TextEditingValue? value) {
    if (value == null) return;
    _applying = true;
    try {
      controller.value = value.copyWith(
        selection: value.selection.isValid
            ? value.selection
            : TextSelection.collapsed(offset: value.text.length),
      );
    } finally {
      _applying = false;
    }
  }

  void dispose() {
    _history.dispose();
    controller.removeListener(_record);
  }
}
