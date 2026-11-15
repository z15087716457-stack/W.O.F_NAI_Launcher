import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/prompt_reading_units.dart';
import '../../../../data/models/prompt_reading.dart';
import '../../../ui/kit/ui_colors.dart';
import '../../../ui/kit/ui_glyph.dart';
import '../../../ui/kit/ui_text.dart';
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
        for (final unit in PromptReadingUnit.parse(text)) {
          final reading = current
              .where((r) => r.start <= unit.textStart && r.end >= unit.textEnd)
              .firstOrNull;
          if (reading == null) continue;
          final pending = reading.needsReview || !reading.perSegment;
          if (!pending && reading.translation == unit.text) continue;
          final label = pending
              ? context.l10n.promptReading_pending
              : reading.translation;
          var end = unit.end;
          while (end > unit.textEnd && text[end - 1].trim().isEmpty) {
            end--;
          }
          captions.add(
            _Caption(
              unit.textStart,
              end,
              label,
              pending,
              end - text.substring(unit.textStart, end).characters.last.length,
              math.max(
                0,
                widthOf(label, captionStyle) +
                    (pending ? 16 : 0) -
                    widthOf(text.substring(unit.textStart, end), sourceStyle),
              ),
            ),
          );
        }
      }
      final fontSize = style.fontSize ?? 14;
      final captionHeight = scaler.scale(11) * 1.35 + 1;
      final readingHeight =
          (fontSize * (style.height ?? 1.4) + 11 * 1.35 + 4) / fontSize;
      controller.readingDecorator = captions.isEmpty
          ? null
          : (span) => _decorate(span, captions, readingHeight);
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

  static TextSpan _decorate(
    TextSpan span,
    List<_Caption> captions,
    double height,
  ) {
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
        children.add(
          TextSpan(
            text: text.substring(start, end),
            style: caption == null
                ? null
                : TextStyle(
                    height: height,
                    letterSpacing: (item.style?.letterSpacing ?? 0) + advance,
                  ),
          ),
        );
      }
      offset += text.length;
      children.addAll((item.children ?? const <InlineSpan>[]).map(visit));
      return TextSpan(style: item.style, children: children);
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
  );
  final int start, end, tailStart;
  final String label;
  final bool pending;
  final double extraWidth;
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
        if (rect != Rect.zero && (box.top - rect.top).abs() > 1) break;
        rect = rect == Rect.zero
            ? box.toRect()
            : rect.expandToInclude(box.toRect());
      }
      final origin = MatrixUtils.transformPoint(
        editable.getTransformTo(this),
        rect.bottomLeft,
      );
      child!.layout(
        BoxConstraints(
          maxWidth: math.max(0, math.min(rect.width, size.width - origin.dx)),
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
