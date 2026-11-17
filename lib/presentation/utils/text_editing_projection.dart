import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

/// A display fragment tied to a range in the original text. Extra display
/// characters (annotation placeholders and joining controls) have no source.
class EditingProjectionPart {
  const EditingProjectionPart({
    required this.start,
    required this.end,
    required this.text,
    this.annotation,
  });
  final int start, end;
  final String text;
  final int? annotation;
  bool get hasSource => end > start;
}

/// Maps a native editor's view buffer to the unchanged source buffer. Offsets
/// are UTF-16 throughout, including surrogate pairs and composing ranges.
class EditingTextProjection {
  EditingTextProjection(this.source, this.parts) {
    final view = StringBuffer();
    viewToSource = [0];
    first = List.filled(source.length + 1, -1);
    last = List.filled(source.length + 1, -1);
    final ranges = <TextRange>[];
    var offset = 0;
    void boundary(int sourceOffset) {
      if (first[sourceOffset] < 0) first[sourceOffset] = offset;
      last[sourceOffset] = offset;
    }

    boundary(0);
    for (final part in parts) {
      boundary(part.start);
      final begin = offset;
      view.write(part.text);
      for (var i = 0; i < part.text.length; i++) {
        offset++;
        final raw = part.start + (i + 1).clamp(0, part.end - part.start);
        viewToSource.add(raw);
        boundary(raw);
      }
      if (part.hasSource) {
        if (ranges.isNotEmpty && ranges.last.end == begin) {
          ranges[ranges.length - 1] = TextRange(
            start: ranges.last.start,
            end: offset,
          );
        } else {
          ranges.add(TextRange(start: begin, end: offset));
        }
      }
    }
    text = view.toString();
    sourceRanges = List.unmodifiable(ranges);
  }

  factory EditingTextProjection.identity(String text) =>
      EditingTextProjection(text, [
        if (text.isNotEmpty)
          EditingProjectionPart(start: 0, end: text.length, text: text),
      ]);

  final String source;
  final List<EditingProjectionPart> parts;
  late final String text;
  late final List<int> viewToSource, first, last;
  late final List<TextRange> sourceRanges;

  int toSource(int offset) =>
      offset < 0 ? offset : viewToSource[offset.clamp(0, text.length)];
  int toDisplay(int offset, {TextAffinity affinity = TextAffinity.downstream}) {
    if (offset < 0) return offset;
    final raw = offset.clamp(0, source.length);
    // A caret at the end of source stays before its caption's reserve. Only
    // an inserted paragraph break moves a downstream caret to the next row.
    return affinity == TextAffinity.downstream &&
            text.substring(first[raw], last[raw]).contains('\n')
        ? last[raw]
        : first[raw];
  }

  TextEditingValue toDisplayValue(TextEditingValue value) {
    final selection = value.selection;
    return ProjectedEditingValue(
      projection: this,
      selection: selection.isValid
          ? selection.isCollapsed
                ? TextSelection.collapsed(
                    offset: toDisplay(
                      selection.extentOffset,
                      affinity: selection.affinity,
                    ),
                    affinity: selection.affinity,
                  )
                : TextSelection(
                    baseOffset: toDisplay(
                      selection.baseOffset,
                      affinity: selection.baseOffset == selection.start
                          ? TextAffinity.downstream
                          : TextAffinity.upstream,
                    ),
                    extentOffset: toDisplay(
                      selection.extentOffset,
                      affinity: selection.extentOffset == selection.start
                          ? TextAffinity.downstream
                          : TextAffinity.upstream,
                    ),
                    affinity: selection.affinity,
                    isDirectional: selection.isDirectional,
                  )
          : selection,
      // A valid empty range starts/finishes an IME composition. Preserve it;
      // replacing it with TextRange.empty sends a cancellation to the IME.
      composing: value.composing.isValid
          ? TextRange(
              start: toDisplay(value.composing.start),
              end: toDisplay(
                value.composing.end,
                affinity: value.composing.isCollapsed
                    ? TextAffinity.downstream
                    : TextAffinity.upstream,
              ),
            )
          : TextRange.empty,
    );
  }

  TextSelection sourceSelection(TextSelection selection) {
    if (!selection.isValid) return selection;
    final raw = toSource(selection.extentOffset);
    final affinity = selection.isCollapsed && first[raw] != last[raw]
        ? (selection.extentOffset <= first[raw]
              ? TextAffinity.upstream
              : TextAffinity.downstream)
        : selection.affinity;
    return selection.copyWith(
      baseOffset: toSource(selection.baseOffset),
      extentOffset: raw,
      affinity: affinity,
    );
  }

  /// Resolve a platform edit against the previous display snapshot. Deleting
  /// only a generated placeholder still deletes the neighboring source
  /// grapheme; the view's annotations never enter the saved text.
  TextEditingValue sourceEdit(TextEditingValue before, TextEditingValue after) {
    if (after is ProjectedEditingValue && !identical(after.projection, this)) {
      final snapshot = after.projection;
      return TextEditingValue(
        text: snapshot.source,
        selection: snapshot.sourceSelection(after.selection),
        composing: after.composing.isValid
            ? TextRange(
                start: snapshot.toSource(after.composing.start),
                end: snapshot.toSource(after.composing.end),
              )
            : TextRange.empty,
      );
    }
    if (before.text == after.text) {
      return TextEditingValue(
        text: source,
        selection: sourceSelection(after.selection),
        composing: after.composing.isValid
            ? TextRange(
                start: toSource(after.composing.start),
                end: toSource(after.composing.end),
              )
            : TextRange.empty,
      );
    }
    final change = _changedRange(before, after);
    final prefix = change.start;
    final oldEnd = change.oldEnd, newEnd = change.newEnd;
    final removed = before.text.length - after.text.length;
    var start = toSource(prefix), end = toSource(oldEnd);
    final inserted = after.text.substring(prefix, newEnd);
    if (start == end && inserted.isEmpty && removed > 0) {
      if (prefix < before.selection.extentOffset && start > 0) {
        start -= source.substring(0, start).characters.last.length;
      } else if (end < source.length) {
        end += source.substring(end).characters.first.length;
      }
    }
    final updated = source.replaceRange(start, end, inserted);
    final delta = inserted.length - (end - start);
    int position(int offset) {
      if (offset < 0) return offset;
      if (offset < prefix) return toSource(offset).clamp(0, updated.length);
      if (offset <= newEnd) {
        return (start + offset - prefix).clamp(0, updated.length);
      }
      return (toSource(offset + oldEnd - newEnd) + delta).clamp(
        0,
        updated.length,
      );
    }

    return TextEditingValue(
      text: updated,
      selection: after.selection.copyWith(
        baseOffset: position(after.selection.baseOffset),
        extentOffset: position(after.selection.extentOffset),
      ),
      composing: after.composing.isValid
          ? TextRange(
              start: position(after.composing.start),
              end: position(after.composing.end),
            )
          : TextRange.empty,
    );
  }

  /// Keep the native IME buffer unchanged, including existing annotation
  /// placeholders. Reflowing it sends setEditingState to Windows, whose
  /// SetText resets the active composition even when its range is preserved.
  EditingTextProjection retainDisplayEdit(
    TextEditingValue before,
    TextEditingValue after,
    String updatedSource,
  ) {
    if (before.text == after.text) return this;
    final change = _changedRange(before, after);
    final inserted = after.text.substring(change.start, change.newEnd);
    final start = toSource(change.start);
    return EditingTextProjection(updatedSource, [
      ..._displaySlice(0, change.start),
      if (inserted.isNotEmpty)
        EditingProjectionPart(
          start: start,
          end: start + inserted.length,
          text: inserted,
        ),
      ..._displaySlice(
        change.oldEnd,
        text.length,
        delta: updatedSource.length - source.length,
      ),
    ]);
  }

  Iterable<EditingProjectionPart> _displaySlice(
    int start,
    int end, {
    int delta = 0,
  }) sync* {
    var offset = 0;
    for (final part in parts) {
      final from = start.clamp(offset, offset + part.text.length);
      final to = end.clamp(offset, offset + part.text.length);
      if (from < to) {
        yield EditingProjectionPart(
          start: toSource(from) + delta,
          end: toSource(to) + delta,
          text: part.text.substring(from - offset, to - offset),
          annotation: part.annotation,
        );
      }
      offset += part.text.length;
    }
  }

  static ({int start, int oldEnd, int newEnd}) _changedRange(
    TextEditingValue before,
    TextEditingValue after,
  ) {
    var prefix = 0;
    final limit = before.selection.isValid
        ? before.selection.start
        : before.text.length;
    while (prefix < before.text.length &&
        prefix < after.text.length &&
        prefix < limit &&
        before.text.codeUnitAt(prefix) == after.text.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < before.text.length - prefix &&
        suffix < after.text.length - prefix &&
        before.text.codeUnitAt(before.text.length - 1 - suffix) ==
            after.text.codeUnitAt(after.text.length - 1 - suffix)) {
      suffix++;
    }
    var oldEnd = before.text.length - suffix;
    var newEnd = after.text.length - suffix;
    final removed = before.text.length - after.text.length;
    if (removed > 0 &&
        before.selection.isCollapsed &&
        after.selection.isCollapsed) {
      final candidate = after.selection.extentOffset;
      if (candidate >= 0 &&
          candidate + removed <= before.text.length &&
          before.text.replaceRange(candidate, candidate + removed, '') ==
              after.text) {
        prefix = candidate;
        oldEnd = candidate + removed;
        newEnd = candidate;
      }
    }
    return (start: prefix, oldEnd: oldEnd, newEnd: newEnd);
  }
}

/// Native undo retains the mapping of its display snapshot. A normal text
/// change becomes an ordinary platform value and is decoded against the
/// current mapping instead.
class ProjectedEditingValue extends TextEditingValue {
  ProjectedEditingValue({
    required this.projection,
    required super.selection,
    super.composing,
  }) : super(text: projection.text);
  final EditingTextProjection projection;
  @override
  TextEditingValue copyWith({
    String? text,
    TextSelection? selection,
    TextRange? composing,
  }) => text == null || text == projection.text
      ? ProjectedEditingValue(
          projection: projection,
          selection: selection ?? this.selection,
          composing: composing ?? this.composing,
        )
      : TextEditingValue(
          text: text,
          selection: selection ?? this.selection,
          composing: composing ?? this.composing,
        );
}

/// Carries the mapping with the actual native paragraph, so pointer consumers
/// and selection painting use the same display/source coordinate conversion.
class SourceMappedTextSpan extends TextSpan {
  const SourceMappedTextSpan({
    required this.projection,
    super.style,
    super.children,
  });
  final EditingTextProjection projection;

  @override
  bool operator ==(Object other) =>
      other is SourceMappedTextSpan &&
      super == other &&
      identical(projection, other.projection);
  @override
  int get hashCode => Object.hash(super.hashCode, projection);
  @override
  RenderComparison compareTo(InlineSpan other) {
    final result = super.compareTo(other);
    return other is SourceMappedTextSpan &&
            !identical(projection, other.projection) &&
            result.index < RenderComparison.paint.index
        ? RenderComparison.paint
        : result;
  }
}

TextPosition sourcePositionForEditable(
  RenderEditable editable,
  TextPosition position,
) => switch (editable.text) {
  SourceMappedTextSpan(:final projection) => TextPosition(
    offset: projection.toSource(position.offset),
    affinity: position.affinity,
  ),
  _ => position,
};

TextPosition displayPositionForEditable(
  RenderEditable editable,
  TextPosition position,
) => switch (editable.text) {
  SourceMappedTextSpan(:final projection) => TextPosition(
    offset: projection.toDisplay(position.offset, affinity: position.affinity),
    affinity: position.affinity,
  ),
  _ => position,
};
