import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/nai_prompt_syntax.dart';
import '../../../../core/utils/prompt_reading_units.dart';
import '../../../../data/models/prompt_reading.dart';
import '../../../ui/kit/ui_colors.dart';
import '../../../ui/kit/ui_glyph.dart';
import '../../../ui/kit/ui_text.dart';
import '../../common/continuous_text_selection.dart';
import '../nai_syntax_controller.dart';

/// The native editor always owns source layout, input and selection. Captions
/// follow its actual glyph boxes and never enter the editable text.
class InlinePromptReadings extends StatelessWidget {
  const InlinePromptReadings({
    super.key,
    required this.controller,
    required this.readings,
    required this.style,
    required this.builder,
    this.enabled = true,
  });

  final NaiSyntaxController controller;
  final List<PromptReading> readings;
  final TextStyle style;
  final WidgetBuilder builder;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final text = controller.text;
      final current = readings.where(
        (r) =>
            r.end <= text.length && text.substring(r.start, r.end) == r.source,
      );
      final captions = <_Caption>[];
      final captionStyle = UiText.sans(
        11,
        height: 1.35,
        color: context.ui.muted,
      );
      final scaler = MediaQuery.textScalerOf(context);
      final sourceStyle = Theme.of(context).textTheme.bodyLarge!.merge(style);
      final fontSize = style.fontSize ?? 14;
      final sourceHeight = fontSize * (style.height ?? 1.4);
      const readingSpace = 11 * 1.35 + 4;
      double widthOf(String value, TextStyle metrics) {
        final painter = TextPainter(
          text: TextSpan(text: value, style: metrics),
          textDirection: Directionality.of(context),
          textScaler: scaler,
        )..layout();
        final width = painter.width;
        painter.dispose();
        return width;
      }

      if (enabled) {
        final translated =
            <PromptReadingUnit, ({String label, bool pending})>{};
        for (final reading in current) {
          final pending =
              reading.needsReview ||
              !reading.perSegment ||
              !PromptReadingUnit.isSingleSection(reading.source);
          final units = pending
              ? PromptReadingUnit.parse(reading.source)
              : [
                  if (PromptReadingUnit.cover(reading.source) case final unit?)
                    unit,
                ];
          for (final unit in units) {
            if (!pending && reading.translation == unit.text) continue;
            translated[unit.shifted(reading.start)] = (
              label: pending
                  ? context.l10n.promptReading_pending
                  : reading.translation,
              pending: pending,
            );
          }
        }
        for (final entry in translated.entries) {
          final unit = entry.key;
          final (:label, :pending) = entry.value;
          var end = unit.end;
          while (end > unit.textEnd && text[end - 1].trim().isEmpty) {
            end--;
          }
          final newline = text.indexOf('\n', end);
          final endsLine = PromptReadingUnit.isSyntaxOnly(
            text.substring(end, newline < 0 ? text.length : newline),
            structuralMarkup: NaiPromptSyntax.isXml(text),
          );
          final labelWidth = widthOf(label, captionStyle) + (pending ? 16 : 0);
          final nextNewline = newline < 0
              ? -1
              : text.indexOf('\n', newline + 1);
          final nextUnit = newline < 0
              ? null
              : translated.keys
                    .where(
                      (u) =>
                          u.textStart > newline &&
                          u.textStart <
                              (nextNewline < 0 ? text.length : nextNewline),
                    )
                    .firstOrNull;
          final leavesPlainRow = endsLine && newline >= 0 && nextUnit == null;
          captions.add(
            _Caption(
              unit.textStart,
              end,
              label,
              pending,
              end - text.substring(unit.textStart, end).characters.last.length,
              endsLine
                  ? 0
                  : math.max(
                      0,
                      labelWidth -
                          widthOf(
                            text.substring(unit.textStart, end),
                            sourceStyle,
                          ),
                    ),
              endsLine ? labelWidth : 0,
              // A hard break can lead to an empty or untranslated source row.
              // Its caret needs the full caption below this row, with no
              // dependence on extra ascent in the following source row.
              (sourceHeight + readingSpace * (leavesPlainRow ? 2 : 1)) /
                  fontSize,
            ),
          );
        }
      }
      final captionHeight = scaler.scale(11) * 1.35 + 1;
      controller.readingDecorator = captions.isEmpty
          ? null
          : (span) => _decorate(span, captions);
      return _ReadingLayout(
        captions: captions,
        captionHeight: captionHeight,
        children: [
          builder(context),
          for (final caption in captions)
            IgnorePointer(
              child: Row(
                key: ValueKey('prompt-reading-${caption.start}'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (caption.pending) ...[
                    UiGlyph(UiGlyphs.wrench, size: 12, color: context.ui.warn),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      caption.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: captionStyle.copyWith(
                        color: caption.pending ? context.ui.warn : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );

  static TextSpan _decorate(TextSpan span, List<_Caption> captions) {
    var offset = 0;
    InlineSpan visit(InlineSpan item) {
      if (item is! TextSpan) {
        offset++;
        return item;
      }
      final children = <InlineSpan>[];
      final text = item.text ?? '';
      final cuts = <int>{0, text.length};
      for (final c in captions) {
        for (final boundary in [c.start, c.tailStart, c.end]) {
          if (boundary > offset && boundary < offset + text.length) {
            cuts.add(boundary - offset);
          }
        }
      }
      final bounds = cuts.toList()..sort();
      for (var i = 1; i < bounds.length; i++) {
        final start = bounds[i - 1], end = bounds[i];
        final position = offset + start;
        final caption = captions
            .where((c) => c.start <= position && position < c.end)
            .firstOrNull;
        final advance = caption != null && offset + end == caption.end
            ? caption.extraWidth
            : 0.0;
        final metrics = caption == null
            ? item.style
            : item.style?.copyWith(
                height: position >= caption.tailStart
                    ? caption.endLineHeight
                    : item.style?.height,
                leadingDistribution: TextLeadingDistribution.even,
                letterSpacing: (item.style?.letterSpacing ?? 0) + advance,
              );
        final background = item.style?.backgroundColor;
        children.add(
          background != null && background.a > 0
              ? TextLineBackgroundSpan(
                  text: text.substring(start, end),
                  style: metrics,
                  backgroundColor: background,
                  horizontalInset: advance / 2,
                )
              : TextSpan(text: text.substring(start, end), style: metrics),
        );
      }
      offset += text.length;
      children.addAll((item.children ?? const <InlineSpan>[]).map(visit));
      return TextSpan(
        style: item.style?.copyWith(backgroundColor: Colors.transparent),
        children: children,
      );
    }

    return visit(span) as TextSpan;
  }
}

class _Caption {
  const _Caption(
    this.start,
    this.end,
    this.label,
    this.pending,
    this.tailStart,
    this.extraWidth,
    this.freeCaptionWidth,
    this.endLineHeight,
  );
  final int start, end, tailStart;
  final String label;
  final bool pending;
  final double extraWidth;
  final double freeCaptionWidth;
  final double endLineHeight;
}

class _ReadingLayout extends MultiChildRenderObjectWidget {
  const _ReadingLayout({
    required this.captions,
    required this.captionHeight,
    required super.children,
  });
  final List<_Caption> captions;
  final double captionHeight;
  @override
  _RenderReadingLayout createRenderObject(BuildContext context) =>
      _RenderReadingLayout(captions, captionHeight);
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderReadingLayout renderObject,
  ) {
    renderObject
      ..captions = captions
      ..captionHeight = captionHeight
      ..markNeedsLayout();
  }
}

class _ReadingParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderReadingLayout extends RenderBox
    with
        ContainerRenderObjectMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        >,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        > {
  _RenderReadingLayout(this.captions, this.captionHeight);
  List<_Caption> captions;
  double captionHeight;
  RenderEditable? _editable;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ContainerBoxParentData<RenderBox>) {
      child.parentData = _ReadingParentData();
    }
  }

  RenderEditable? _findEditor(RenderObject node) {
    if (node is RenderEditable) return node;
    RenderEditable? result;
    node.visitChildren((child) {
      result ??= _findEditor(child);
    });
    return result;
  }

  @override
  void performLayout() {
    final editor = firstChild!;
    final editable = _findEditor(editor);
    if (_editable != editable) {
      _editable?.offset.removeListener(markNeedsLayout);
      _editable = editable;
      editable?.offset.addListener(markNeedsLayout);
    }
    if (editable != null) {
      invokeLayoutCallback<BoxConstraints>((_) {
        editable.textHeightBehavior = captions.isEmpty
            ? null
            : const ui.TextHeightBehavior(applyHeightToFirstAscent: false);
        editable.selectionHeightStyle = captions.isEmpty
            ? ui.BoxHeightStyle.max
            : ui.BoxHeightStyle.strut;
      });
    }
    final extra = captions.isEmpty ? 0.0 : captionHeight;
    editor.layout(
      constraints.deflate(EdgeInsets.only(bottom: extra)),
      parentUsesSize: true,
    );
    size = constraints.constrain(
      Size(editor.size.width, editor.size.height + extra),
    );
    var child = childAfter(editor);
    for (final caption in captions) {
      final boxes = editable!.getBoxesForSelection(
        TextSelection(baseOffset: caption.start, extentOffset: caption.end),
      );
      var rect = Rect.zero;
      for (final box in boxes) {
        rect = rect == Rect.zero || (box.top - rect.top).abs() > 1
            ? box.toRect()
            : rect.expandToInclude(box.toRect());
      }
      final origin = MatrixUtils.transformPoint(
        editable.getTransformTo(this),
        rect.bottomLeft,
      );
      child!.layout(
        BoxConstraints(
          maxWidth: math.max(
            0,
            math.min(
              math.max(rect.width, caption.freeCaptionWidth),
              size.width - origin.dx,
            ),
          ),
        ),
        parentUsesSize: true,
      );
      (child.parentData! as ContainerBoxParentData<RenderBox>).offset =
          origin + const Offset(0, 1);
      child = childAfter(child);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (context, offset) => defaultPaint(context, offset),
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      firstChild!.hitTest(result, position: position);

  @override
  void dispose() {
    _editable?.offset.removeListener(markNeedsLayout);
    super.dispose();
  }
}
