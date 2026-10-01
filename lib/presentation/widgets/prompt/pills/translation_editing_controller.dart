import 'package:flutter/material.dart';

import '../../../../core/autocomplete/completion_models.dart';
import '../../../../data/models/prompt_block/pill_document.dart';
import '../../autocomplete/tag_category_visuals.dart';
import '../nai_syntax_controller.dart';

/// Editable syntax spans contain text only: icons never change caret offsets.
class TranslationEditingController extends NaiSyntaxController {
  TranslationEditingController({
    super.text,
    super.highlightEnabled,
    super.numericEmphasisEnabled,
  });
  List<TranslationTagMark> _marks = const [];
  List<TranslationTagMark> get marks => _marks;
  void updateMarks(List<TranslationTagMark> value) {
    _marks = List.unmodifiable(value);
    notifyListeners();
  }

  static TagCategory? category(TranslationTagMark mark) => TagCategory.values
      .where((c) => c.name == mark.iconId && c != TagCategory.general)
      .firstOrNull;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final syntax = super.buildTextSpan(
      context: context,
      style: style,
      withComposing: withComposing,
    );
    final output = <InlineSpan>[];
    var offset = 0;
    for (final child in syntax.children ?? [TextSpan(text: text)]) {
      if (child is! TextSpan || child.text == null) return syntax;
      final value = child.text!;
      final boundaries = <int>{0, value.length};
      for (final mark in _marks) {
        if (category(mark) == null ||
            mark.start < 0 ||
            mark.end > text.length ||
            mark.start >= mark.end) {
          continue;
        }
        if (mark.start > offset && mark.start < offset + value.length) {
          boundaries.add(mark.start - offset);
        }
        if (mark.end > offset && mark.end < offset + value.length) {
          boundaries.add(mark.end - offset);
        }
      }
      final composing = this.value.composing;
      if (withComposing && composing.isValid && !composing.isCollapsed) {
        for (final position in [composing.start, composing.end]) {
          if (position > offset && position < offset + value.length) {
            boundaries.add(position - offset);
          }
        }
      }
      final cuts = boundaries.toList()..sort();
      for (var i = 0; i < cuts.length - 1; i++) {
        final start = offset + cuts[i];
        final end = offset + cuts[i + 1];
        var resolved = child.style ?? const TextStyle();
        final mark = _marks
            .where(
              (m) => m.start <= start && m.end >= end && category(m) != null,
            )
            .firstOrNull;
        if (mark != null) {
          resolved = resolved.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: TagCategoryVisuals.color(context, category(mark)!),
            decorationThickness: 1.4,
          );
        }
        if (withComposing &&
            composing.isValid &&
            composing.start <= start &&
            composing.end >= end &&
            !composing.isCollapsed) {
          resolved = resolved.copyWith(decoration: TextDecoration.underline);
        }
        output.add(
          TextSpan(
            text: value.substring(cuts[i], cuts[i + 1]),
            style: resolved,
          ),
        );
      }
      offset += value.length;
    }
    return TextSpan(style: syntax.style, children: output);
  }
}

/// Category glyphs are painted over the field, outside its editable text span.
class TranslationFieldIcons extends StatelessWidget {
  const TranslationFieldIcons({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.fieldKey,
    required this.child,
  });
  final TranslationEditingController controller;
  final ScrollController scrollController;
  final GlobalKey fieldKey;
  final Widget child;
  @override
  Widget build(BuildContext context) => CustomPaint(
    key: fieldKey,
    foregroundPainter: _FieldIcons(
      context,
      controller,
      scrollController,
      fieldKey,
    ),
    child: child,
  );
}

class _FieldIcons extends CustomPainter {
  _FieldIcons(
    this.context,
    this.controller,
    ScrollController scroll,
    this.fieldKey,
  ) : super(repaint: Listenable.merge([controller, scroll]));
  final BuildContext context;
  final TranslationEditingController controller;
  final GlobalKey fieldKey;
  @override
  void paint(Canvas canvas, Size size) {
    final fieldContext = fieldKey.currentContext;
    if (fieldContext == null) return;
    EditableTextState? state;
    void find(Element element) {
      if (element is StatefulElement && element.state is EditableTextState) {
        state = element.state as EditableTextState;
        return;
      }
      if (state == null) element.visitChildren(find);
    }

    (fieldContext as Element).visitChildren(find);
    if (state == null) return;
    final editable = state!.renderEditable;
    final box = fieldContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.globalToLocal(editable.localToGlobal(Offset.zero));
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final mark in controller.marks) {
      final category = TranslationEditingController.category(mark);
      if (category == null ||
          mark.end > controller.text.length ||
          mark.end <= mark.start ||
          mark.start < 0) {
        continue;
      }
      final boxes = editable.getBoxesForSelection(
        TextSelection(baseOffset: mark.end - 1, extentOffset: mark.end),
      );
      if (boxes.isEmpty) continue;
      final last = boxes.last;
      final icon = TagCategoryVisuals.icon(category);
      final painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: 8,
            color: TagCategoryVisuals.color(context, category),
          ),
        ),
      )..layout();
      // Superscript cue overlaps only the tag's own upper edge, not the next
      // character; the text, selection and pointer hit regions stay native.
      painter.paint(
        canvas,
        origin + Offset(last.right - painter.width, last.top - 4),
      );
      painter.dispose();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FieldIcons oldDelegate) => true;
}
