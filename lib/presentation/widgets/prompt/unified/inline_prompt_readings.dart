import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/prompt_reading_units.dart';
import '../../../../data/models/prompt_reading.dart';
import '../../../utils/text_editing_projection.dart';
import '../../../ui/kit/ui_colors.dart';
import '../../../ui/kit/ui_glyph.dart';
import '../../../ui/kit/ui_text.dart';
import '../../common/continuous_text_selection.dart';
import '../nai_syntax_controller.dart';

/// One native editor; annotation placeholders exist only in its view buffer.
class InlinePromptReadings extends StatefulWidget {
  const InlinePromptReadings({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.readings,
    required this.style,
    required this.builder,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.enabled = true,
    this.readOnly = false,
  });
  final NaiSyntaxController controller;
  final FocusNode focusNode;
  final List<PromptReading> readings;
  final TextStyle style;
  final EdgeInsetsGeometry padding;
  final Widget Function(BuildContext, ReadingEditingController) builder;
  final bool enabled;
  final bool readOnly;
  @override
  State<InlinePromptReadings> createState() => _InlinePromptReadingsState();
}

class _InlinePromptReadingsState extends State<InlinePromptReadings> {
  late final ReadingEditingController view;
  final history = UndoHistoryController();
  @override
  void initState() {
    super.initState();
    view = ReadingEditingController(widget.controller);
  }

  @override
  void dispose() {
    view.dispose();
    history.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final padding = widget.padding.resolve(Directionality.of(context));
      // RenderEditable reserves its default 2px cursor and a 1px caret gap.
      final width = math.max(
        1.0,
        constraints.maxWidth - padding.horizontal - 3,
      );
      view.readOnly = widget.readOnly;
      view.configure(
        context,
        widget.readings,
        widget.style,
        width,
        widget.enabled,
      );
      return UndoHistory<TextEditingValue>(
        controller: history,
        value: widget.controller,
        focusNode: widget.focusNode,
        shouldChangeUndoStack: (before, after) =>
            after.selection.isValid &&
            before?.text != after.text &&
            (!after.composing.isValid || after.composing.isCollapsed),
        undoStackModifier: (value) =>
            value.copyWith(composing: TextRange.empty),
        onTriggered: (value) {
          widget.controller.value = value;
          view.onSourceCommand?.call(value.text);
        },
        child: Actions(
          actions: {
            UndoTextIntent: CallbackAction<UndoTextIntent>(
              onInvoke: (_) {
                if (!widget.readOnly) history.undo();
                return null;
              },
            ),
            RedoTextIntent: CallbackAction<RedoTextIntent>(
              onInvoke: (_) {
                if (!widget.readOnly) history.redo();
                return null;
              },
            ),
            CopySelectionTextIntent: CallbackAction<CopySelectionTextIntent>(
              onInvoke: (intent) {
                if (intent.collapseSelection) {
                  view.cutSource();
                } else {
                  view.copySource();
                }
                return null;
              },
            ),
            ExtendSelectionByCharacterIntent:
                CallbackAction<ExtendSelectionByCharacterIntent>(
                  onInvoke: (intent) {
                    view.moveCharacter(
                      intent.forward,
                      intent.collapseSelection,
                    );
                    return null;
                  },
                ),
          },
          child: _ReadingEditorMetrics(child: widget.builder(context, view)),
        ),
      );
    },
  );
}

class _ReadingPlan {
  const _ReadingPlan({
    required this.start,
    required this.end,
    required this.atomicEnd,
    required this.label,
    required this.pending,
    required this.block,
    required this.sourceWidth,
    required this.prefixWidth,
    required this.extraWidth,
    required this.captionWidth,
    required this.captionHeight,
    required this.descent,
  });
  final int start, end, atomicEnd;
  final String label;
  final bool pending, block;
  final double sourceWidth,
      prefixWidth,
      extraWidth,
      captionWidth,
      captionHeight,
      descent;
}

class ReadingEditingController extends TextEditingController {
  ReadingEditingController(this.source) : super.fromValue(source.value) {
    _viewValue = source.value;
    projection = EditingTextProjection.identity(source.text);
    _sourceText = source.text;
    source.addListener(_sourceChanged);
  }
  static const joiner = '\u2060', placeholder = '\uFFFC';
  static final _prefix = RegExp(
    r'(?:(?:[-+]?(?:\d+(?:\.\d*)?|\.\d+)::)|[\[{])+\s*$',
  );
  static final _tail = RegExp(r'\s+$');
  static final _separators = RegExp(r'^[\s,，;；:\]}]*');
  final NaiSyntaxController source;
  bool readOnly = false;
  ValueChanged<String>? onSourceCommand;
  TextInputFormatter? _inputFormatter;
  late EditingTextProjection projection;
  late TextEditingValue _viewValue;
  late String _sourceText;
  String? _externalText;
  String? _layoutText;
  TextRange _layoutComposing = TextRange.empty;
  List<PromptReading> _readings = const [], _externalReadings = const [];
  List<_ReadingPlan> _plans = const [];
  TextStyle _style = const TextStyle(fontSize: 14, height: 1.5);
  TextStyle _captionStyle = const TextStyle(fontSize: 11, height: 1.5);
  TextScaler _scaler = TextScaler.noScaling;
  TextDirection _direction = TextDirection.ltr;
  String _pendingLabel = '';
  double _width = 1;
  bool _enabled = false, _updating = false, _disposed = false;
  TextEditingValue? _pendingSource, _pendingDisplay;

  @override
  TextEditingValue get value => _viewValue;
  @override
  set value(TextEditingValue next) {
    if (_updating) return;
    final raw = next == _pendingDisplay
        ? _pendingSource!
        : projection.sourceEdit(_viewValue, next);
    _pendingSource = _pendingDisplay = null;
    _updating = true;
    source.value = raw;
    _updating = false;
    _refresh();
    notifyListeners();
  }

  TextInputFormatter sourceFormatter(TextInputFormatter formatter) {
    _inputFormatter = formatter;
    return TextInputFormatter.withFunction((before, after) {
      _pendingSource = formatter.formatEditUpdate(
        source.value,
        projection.sourceEdit(before, after),
      );
      _pendingDisplay = after;
      return after;
    });
  }

  void configure(
    BuildContext context,
    List<PromptReading> readings,
    TextStyle style,
    double width,
    bool enabled,
  ) {
    if (!_sameReadings(readings, _externalReadings)) {
      _readings = readings;
      _externalReadings = readings;
      _externalText = source.text;
      _layoutText = null;
    }
    final theme = Theme.of(context);
    final sourceStyle =
        (theme.useMaterial3
                ? theme.textTheme.bodyLarge!
                : theme.textTheme.titleMedium!)
            .merge(style);
    final captionStyle = UiText.sans(11, height: 1.5, color: context.ui.muted);
    final pendingLabel = context.l10n.promptReading_pending;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    if (_style != sourceStyle ||
        _captionStyle != captionStyle ||
        _pendingLabel != pendingLabel ||
        _scaler != scaler ||
        _direction != direction ||
        _width != width ||
        _enabled != enabled) {
      _layoutText = null;
    }
    _style = sourceStyle;
    _captionStyle = captionStyle;
    _pendingLabel = pendingLabel;
    _scaler = scaler;
    _direction = direction;
    _width = width;
    _enabled = enabled;
    final before = _viewValue;
    _refresh();
    if (before != _viewValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    }
  }

  static bool _sameReadings(List<PromptReading> a, List<PromptReading> b) =>
      a.length == b.length &&
      Iterable.generate(a.length).every((i) => a[i] == b[i]);

  void _sourceChanged() {
    if (_sourceText != source.text) {
      _readings = source.text == _externalText
          ? _externalReadings
          : PromptReading.rebase(_readings, _sourceText, source.text);
      _sourceText = source.text;
    }
    if (!_updating) {
      _refresh();
      notifyListeners();
    }
  }

  TextPainter _measure(
    String text,
    TextStyle style, {
    double maxWidth = double.infinity,
  }) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: _direction,
    textScaler: _scaler,
    strutStyle: StrutStyle.fromTextStyle(style),
  )..layout(maxWidth: maxWidth);

  void _refresh() {
    final text = source.text;
    // Selection movement reuses the measured pairs and their offset mapping.
    if (_layoutText == text && _layoutComposing == source.value.composing) {
      _viewValue = projection.toDisplayValue(source.value);
      return;
    }
    _layoutText = text;
    _layoutComposing = source.value.composing;
    final current = _enabled
        ? _readings
              .where(
                (r) =>
                    r.end <= text.length &&
                    text.substring(r.start, r.end) == r.source,
              )
              .expand((reading) {
                if (reading.perSegment &&
                    PromptReadingUnit.isSingleSection(reading.source)) {
                  return [reading];
                }
                return PromptReadingUnit.parse(reading.source).map((unit) {
                  final start = reading.start + unit.start;
                  final end = reading.start + unit.end;
                  return PromptReading(
                    start: start,
                    end: end,
                    source: text.substring(start, end),
                    translation: '',
                    needsReview: true,
                    perSegment: true,
                  );
                });
              })
              .toList()
        : <PromptReading>[];
    final plans = <_ReadingPlan>[];
    var previous = 0;
    for (var i = 0; i < current.length; i++) {
      final reading = current[i], composing = source.value.composing;
      if (composing.isValid &&
          !composing.isCollapsed &&
          reading.start < composing.end &&
          reading.end > composing.start) {
        continue;
      }
      final clean = PromptReadingUnit.cover(reading.source);
      if (clean == null) continue;
      final pending =
          reading.needsReview ||
          !reading.perSegment ||
          !PromptReadingUnit.isSingleSection(reading.source);
      if (!pending && reading.translation == clean.text) continue;
      var start = reading.start;
      while (start < reading.end && text[start].trim().isEmpty) {
        start++;
      }
      final prefix = _prefix.firstMatch(text.substring(previous, start));
      if (prefix != null) start = previous + prefix.start;
      var end = reading.end;
      final next = i + 1 < current.length ? current[i + 1].start : text.length;
      var gap = text.substring(end, next);
      final newline = gap.indexOf('\n'), markup = gap.indexOf('<');
      final limit = [
        gap.length,
        if (newline >= 0) newline,
        if (markup >= 0) markup,
      ].reduce(math.min);
      gap = gap.substring(0, limit);
      final nextPrefix = _prefix.firstMatch(gap);
      if (nextPrefix != null) gap = gap.substring(0, nextPrefix.start);
      end += _separators.firstMatch(gap)!.end;
      final tail = _tail.firstMatch(text.substring(start, end));
      final atomicEnd = tail == null ? end : start + tail.start;
      if (atomicEnd <= start) continue;
      final label = pending ? _pendingLabel : reading.translation;
      final original = text.substring(start, atomicEnd);
      final atomic = original.characters.map((c) => c + joiner).join();
      final sourceMeasure = _measure(atomic, _style);
      final prefixEnd = reading.start + clean.textStart;
      final prefixMeasure = _measure(
        text.substring(start, prefixEnd.clamp(start, atomicEnd)),
        _style,
      );
      final labelMeasure = _measure(label, _captionStyle);
      final labelWidth = labelMeasure.width + (pending ? 16 : 0);
      final pairWidth = math.max(
        sourceMeasure.width,
        prefixMeasure.width + labelWidth,
      );
      final block =
          clean.text.split(RegExp(r'\s+')).length > 5 ||
          (!clean.text.startsWith('artist:') &&
              RegExp(r'[,，;；:.!?。！？]').hasMatch(clean.text)) ||
          pairWidth > _width ||
          original.contains('\n');
      final contentMeasure = _measure(
        block ? original : atomic,
        _style,
        maxWidth: _width,
      );
      final lines = contentMeasure.computeLineMetrics();
      final captionWidth = block
          ? math.max(1.0, _width - prefixMeasure.width)
          : math.max(labelWidth, sourceMeasure.width - prefixMeasure.width);
      final captionMeasure = _measure(
        label,
        _captionStyle,
        maxWidth: math.max(1.0, captionWidth - (pending ? 16 : 0)),
      );
      plans.add(
        _ReadingPlan(
          start: start,
          end: end,
          atomicEnd: atomicEnd,
          label: label,
          pending: pending,
          block: block,
          sourceWidth: block ? lines.last.width : sourceMeasure.width,
          prefixWidth: prefixMeasure.width,
          extraWidth: block ? 0 : pairWidth - sourceMeasure.width,
          captionWidth: captionWidth,
          captionHeight: math.max(captionMeasure.height, pending ? 12 : 0),
          descent: lines.last.descent,
        ),
      );
      previous = end;
      sourceMeasure.dispose();
      prefixMeasure.dispose();
      labelMeasure.dispose();
      contentMeasure.dispose();
      captionMeasure.dispose();
    }
    _plans = plans;
    _project(text, plans);
  }

  void _project(String text, List<_ReadingPlan> plans) {
    final parts = <EditingProjectionPart>[];
    var cursor = 0;
    var breakBeforeSource = false;
    void virtual(String value, {int? annotation}) {
      parts.add(
        EditingProjectionPart(
          start: cursor,
          end: cursor,
          text: value,
          annotation: annotation,
        ),
      );
    }

    void raw(int end, {bool atomic = false}) {
      if (cursor >= end) return;
      final value = text.substring(cursor, end);
      if (breakBeforeSource &&
          value.trim().isNotEmpty &&
          !value.startsWith('\n')) {
        virtual('\n');
        breakBeforeSource = false;
      }
      if (value.contains('\n')) breakBeforeSource = false;
      if (atomic) {
        for (final character in value.characters) {
          parts.add(
            EditingProjectionPart(
              start: cursor,
              end: cursor + character.length,
              text: character + joiner,
            ),
          );
          cursor += character.length;
        }
      } else {
        parts.add(EditingProjectionPart(start: cursor, end: end, text: value));
        cursor = end;
      }
    }

    for (final (i, plan) in plans.indexed) {
      raw(plan.start);
      if ((breakBeforeSource || plan.block) &&
          parts.isNotEmpty &&
          !parts.last.text.endsWith('\n')) {
        virtual('\n');
      }
      breakBeforeSource = false;
      raw(plan.atomicEnd, atomic: !plan.block);
      if (plan.block) virtual(joiner);
      virtual(placeholder, annotation: i);
      raw(plan.end);
      breakBeforeSource = plan.block;
    }
    raw(text.length);
    projection = EditingTextProjection(text, parts);
    _viewValue = projection.toDisplayValue(source.value);
  }

  Future<void> copySource() async {
    final selection = source.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    await Clipboard.setData(
      ClipboardData(
        text: source.text.substring(selection.start, selection.end),
      ),
    );
  }

  void cutSource() {
    if (readOnly) return;
    final selection = source.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    copySource();
    final updated = TextEditingValue(
      text: source.text.replaceRange(selection.start, selection.end, ''),
      selection: TextSelection.collapsed(offset: selection.start),
    );
    source.value =
        _inputFormatter?.formatEditUpdate(source.value, updated) ?? updated;
    onSourceCommand?.call(source.text);
  }

  void moveCharacter(bool forward, bool collapse) {
    final value = source.value, selection = value.selection;
    if (!selection.isValid) return;
    var offset = selection.extentOffset;
    if (collapse && !selection.isCollapsed) {
      offset = forward ? selection.end : selection.start;
    } else if (forward && offset < value.text.length) {
      offset += value.text.substring(offset).characters.first.length;
    } else if (!forward && offset > 0) {
      offset -= value.text.substring(0, offset).characters.last.length;
    }
    source.selection = TextSelection(
      baseOffset: collapse ? offset : selection.baseOffset,
      extentOffset: offset,
      affinity: TextAffinity.upstream,
      isDirectional: !collapse,
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final original = source.buildTextSpan(
      context: context,
      style: style,
      withComposing: withComposing,
    );
    if (_plans.isEmpty) {
      return SourceMappedTextSpan(
        projection: projection,
        style: original.style,
        children: [original],
      );
    }
    final runs = <({int start, int end, InlineSpan span, TextStyle? style})>[];
    var rawOffset = 0;
    void flatten(InlineSpan span, TextStyle? inherited) {
      if (span is TextSpan) {
        final merged = inherited?.merge(span.style) ?? span.style;
        if (span.text case final text? when text.isNotEmpty) {
          runs.add((
            start: rawOffset,
            end: rawOffset + text.length,
            span: span,
            style: merged,
          ));
          rawOffset += text.length;
        }
        for (final child in span.children ?? const <InlineSpan>[]) {
          flatten(child, merged);
        }
      } else {
        runs.add((
          start: rawOffset,
          end: rawOffset + 1,
          span: span,
          style: inherited,
        ));
        rawOffset++;
      }
    }

    flatten(original, null);
    final children = <InlineSpan>[];
    var runIndex = 0;
    final buffer = StringBuffer();
    TextStyle? bufferedStyle;
    void flush() {
      if (buffer.isEmpty) return;
      final text = buffer.toString();
      buffer.clear();
      final background = bufferedStyle?.backgroundColor;
      children.add(
        background != null && background.a > 0
            ? TextLineBackgroundSpan(
                text: text,
                style: bufferedStyle,
                backgroundColor: background,
              )
            : TextSpan(text: text, style: bufferedStyle),
      );
    }

    for (final part in projection.parts) {
      if (part.annotation case final index?) {
        flush();
        final plan = _plans[index];
        final color = plan.pending ? context.ui.warn : context.ui.muted;
        final content = Row(
          key: ValueKey('prompt-reading-${plan.start}'),
          mainAxisSize: MainAxisSize.min,
          children: [
            if (plan.pending) ...[
              UiGlyph(UiGlyphs.wrench, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                plan.label,
                softWrap: true,
                style: _captionStyle.copyWith(color: color),
              ),
            ),
          ],
        );
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _ReadingDescent(
              child: IgnorePointer(
                child: SizedBox(
                  width: plan.extraWidth,
                  height:
                      plan.descent +
                      3 +
                      plan.captionHeight +
                      (plan.block ? 8 : 3),
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: plan.captionWidth,
                    maxWidth: plan.captionWidth,
                    minHeight: plan.captionHeight,
                    maxHeight: plan.captionHeight,
                    child: Transform.translate(
                      offset: Offset(
                        plan.prefixWidth - plan.sourceWidth,
                        plan.descent + 3,
                      ),
                      child: SizedBox(
                        width: plan.captionWidth,
                        height: plan.captionHeight,
                        child: content,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      } else if (!part.hasSource) {
        flush();
        children.add(TextSpan(text: part.text, style: style));
      } else {
        var offset = part.start;
        while (offset < part.end) {
          while (runIndex < runs.length - 1 && runs[runIndex].end <= offset) {
            runIndex++;
          }
          final run = runs[runIndex];
          final end = math.min(part.end, run.end);
          if (run.span is! TextSpan) {
            flush();
            children.add(run.span);
          } else {
            if (bufferedStyle != run.style) {
              flush();
              bufferedStyle = run.style;
            }
            buffer.write(source.text.substring(offset, end));
          }
          offset = end;
        }
        if (part.text.length > part.end - part.start) {
          buffer.write(part.text.substring(part.end - part.start));
        }
      }
    }
    flush();
    return SourceMappedTextSpan(
      projection: projection,
      style: original.style,
      children: children,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    source.removeListener(_sourceChanged);
    super.dispose();
  }
}

/// The annotation contributes descent only, retaining normal source ascent.
class _ReadingDescent extends SingleChildRenderObjectWidget {
  const _ReadingDescent({required super.child});
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReadingDescent();
}

class _RenderReadingDescent extends RenderProxyBox {
  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) => 0;
  @override
  double computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => 0;
}

class _ReadingEditorMetrics extends SingleChildRenderObjectWidget {
  const _ReadingEditorMetrics({required super.child});
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReadingEditorMetrics();
}

class _RenderReadingEditorMetrics extends RenderProxyBox {
  @override
  void performLayout() {
    void visit(RenderObject node) {
      if (node is RenderEditable) {
        node.selectionHeightStyle = ui.BoxHeightStyle.strut;
        return;
      }
      node.visitChildren(visit);
    }

    if (child case final field?) visit(field);
    super.performLayout();
  }
}
