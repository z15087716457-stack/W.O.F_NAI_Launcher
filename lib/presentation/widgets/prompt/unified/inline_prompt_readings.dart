import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/prompt_reading_units.dart';
import '../../../../data/models/prompt_reading.dart';
import '../../../ui/kit/ui_text.dart';
import '../../../ui/kit/ui_colors.dart';
import '../nai_syntax_controller.dart';

/// Reading layout and editing stay separate. The native editor stays mounted
/// and owns source offsets, composing ranges, selection and undo.
class InlinePromptReadings extends StatelessWidget {
  const InlinePromptReadings({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.readings,
    required this.style,
    required this.builder,
    required this.padding,
    this.enabled = true,
    this.expands = false,
    this.minLines = 1,
    this.maxLines,
  });
  final NaiSyntaxController controller;
  final FocusNode focusNode;
  final List<PromptReading> readings;
  final TextStyle style;
  final WidgetBuilder builder;
  final EdgeInsetsGeometry padding;
  final bool enabled, expands;
  final int minLines;
  final int? maxLines;

  /// Existing block drops must use the visible source, rather than the
  /// differently wrapped native editor retained offstage during reading.
  static int? offsetForPoint(BuildContext? root, Offset global) {
    _ReadingSource? closest;
    var distance = double.infinity;
    void visit(Element element) {
      if (element.widget case final _ReadingSource source) {
        final box =
            source.textKey.currentContext!.findRenderObject()!
                as RenderParagraph;
        final rect = MatrixUtils.transformRect(
          box.getTransformTo(null),
          Offset.zero & box.size,
        );
        final nearest = Offset(
          global.dx.clamp(rect.left, rect.right),
          global.dy.clamp(rect.top, rect.bottom),
        );
        final next = (global - nearest).distanceSquared;
        if (next < distance) {
          closest = source;
          distance = next;
        }
      }
      element.visitChildren(visit);
    }

    root?.visitChildElements(visit);
    return closest?.positionForPoint(global);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller, focusNode]),
    child: builder(context),
    builder: (context, editor) {
      final text = controller.text;
      // Input can precede the provider's annotation snapshot by one frame.
      final current = readings
          .where(
            (reading) =>
                reading.end <= text.length &&
                text.substring(reading.start, reading.end) == reading.source,
          )
          .toList();
      final show =
          enabled &&
          !focusNode.hasFocus &&
          current.any(
            (reading) =>
                reading.needsReview ||
                !reading.perSegment ||
                reading.translation != PromptReadingUnit.clean(reading.source),
          );
      return Stack(
        fit: expands ? StackFit.expand : StackFit.loose,
        children: [
          Offstage(offstage: show, child: editor!),
          if (show)
            _ReadingFlow(
              controller: controller,
              readings: current,
              style: style,
              padding: padding,
              minLines: minLines,
              maxLines: maxLines,
              expands: expands,
              onEdit: (offset) {
                controller.selection = TextSelection.collapsed(offset: offset);
                focusNode.requestFocus();
              },
            ),
        ],
      );
    },
  );
}

typedef _SourceSpan = ({int start, int end, InlineSpan span});

class _ReadingFlow extends StatelessWidget {
  const _ReadingFlow({
    required this.controller,
    required this.readings,
    required this.style,
    required this.padding,
    required this.minLines,
    required this.maxLines,
    required this.expands,
    required this.onEdit,
  });
  final NaiSyntaxController controller;
  final List<PromptReading> readings;
  final TextStyle style;
  final EdgeInsetsGeometry padding;
  final int minLines;
  final int? maxLines;
  final bool expands;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final text = controller.text;
    final spans = <_SourceSpan>[];
    var offset = 0;
    void flatten(InlineSpan span, TextStyle inherited) {
      if (span is TextSpan) {
        final resolved = inherited.merge(span.style).copyWith(height: 1.4);
        if (span.text case final value? when value.isNotEmpty) {
          spans.add((
            start: offset,
            end: offset + value.length,
            span: TextSpan(text: value, style: resolved),
          ));
          offset += value.length;
        }
        for (final child in span.children ?? const <InlineSpan>[]) {
          flatten(child, resolved);
        }
      } else {
        spans.add((start: offset, end: offset + 1, span: span));
        offset++;
      }
    }

    flatten(controller.buildReadingSpan(context, style), style);
    TextSpan slice(int start, int end) => TextSpan(
      children: [
        for (final item in spans)
          if (item.start < end && item.end > start)
            if (item.span case TextSpan(:final text, :final style))
              TextSpan(
                text: text!.substring(
                  (start - item.start).clamp(0, text.length),
                  (end - item.start).clamp(0, text.length),
                ),
                style: style,
              )
            else
              item.span,
      ],
    );
    Widget source(int start, int end) =>
        _ReadingSource(span: slice(start, end), offset: start, onEdit: onEdit);
    final rows = <Widget>[];
    var row = <Widget>[];
    final scaler = MediaQuery.textScalerOf(context);
    final lineHeight = scaler.scale(style.fontSize ?? 14) * 1.4;
    void flush() {
      rows.add(
        row.isEmpty
            ? SizedBox(height: lineHeight)
            : Wrap(
                spacing: 4,
                runSpacing: 3,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: row,
              ),
      );
      row = [];
    }

    void plain(int start, int end) {
      var from = start;
      for (var i = start; i < end; i++) {
        if (text.codeUnitAt(i) != 10) continue;
        if (text.substring(from, i).trim().isNotEmpty) row.add(source(from, i));
        flush();
        from = i + 1;
      }
      if (text.substring(from, end).trim().isNotEmpty) {
        row.add(source(from, end));
      }
    }

    var cursor = 0;
    for (final unit in PromptReadingUnit.parse(text)) {
      var start = unit.start, end = unit.end;
      while (start < end && text[start].trim().isEmpty) {
        start++;
      }
      while (end > start && text[end - 1].trim().isEmpty) {
        end--;
      }
      plain(cursor, start);
      PromptReading? reading;
      for (final item in readings) {
        if (item.start <= unit.textStart && item.end >= unit.textEnd) {
          reading = item;
          break;
        }
      }
      final pending =
          reading != null && (reading.needsReview || !reading.perSegment);
      final caption = pending
          ? context.l10n.promptReading_pending
          : reading == null || reading.translation == unit.text
          ? ''
          : reading.translation;
      row.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (start < unit.textStart) source(start, unit.textStart),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  source(unit.textStart, end),
                  if (caption.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    IgnorePointer(
                      child: Text(
                        caption,
                        key: ValueKey('prompt-reading-${unit.textStart}'),
                        style: UiText.sans(
                          11,
                          height: 1.35,
                          color: pending ? context.ui.faint : context.ui.muted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
      cursor = end;
    }
    plain(cursor, text.length);
    if (row.isNotEmpty) flush();
    Widget result = Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minLines * lineHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: rows,
        ),
      ),
    );
    if (expands || maxLines != null) {
      result = SingleChildScrollView(child: result);
      if (!expands) {
        result = SizedBox(
          height: maxLines! * (lineHeight + scaler.scale(11) * 1.35 + 4),
          child: result,
        );
      }
    }
    return result;
  }
}

class _ReadingSource extends StatelessWidget {
  _ReadingSource({
    required this.span,
    required this.offset,
    required this.onEdit,
  });
  final TextSpan span;
  final int offset;
  final ValueChanged<int> onEdit;
  final textKey = GlobalKey();

  int positionForPoint(Offset global) {
    final paragraph =
        textKey.currentContext!.findRenderObject()! as RenderParagraph;
    return offset +
        paragraph.getPositionForOffset(paragraph.globalToLocal(global)).offset;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          onEdit(positionForPoint(details.globalPosition));
        },
        child: Text.rich(
          span,
          key: textKey,
          textWidthBasis: TextWidthBasis.longestLine,
        ),
      ),
    );
  }
}
