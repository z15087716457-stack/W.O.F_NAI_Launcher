import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../data/models/prompt_block/pill_document.dart';
import '../../../../core/utils/prompt_input_normalization.dart';
import '../nai_syntax_controller.dart';
import 'translation_tag_span.dart';
import '../../common/translation_icon.dart';

export 'translation_pill_editor.dart';

class TranslationPillView extends StatefulWidget {
  const TranslationPillView({
    super.key,
    required this.pill,
    required this.onToggle,
    required this.onEdit,
    this.onSourceChanged,
    this.sourceHandleBuilder,
    this.highlightEnabled = true,
    this.numericEmphasisEnabled = true,
    this.autoFormat = false,
  });

  final TranslationPill pill;
  final VoidCallback onToggle;
  final ValueChanged<Offset> onEdit;
  final ValueChanged<String>? onSourceChanged;
  final Widget Function(Widget handle)? sourceHandleBuilder;
  final bool highlightEnabled;
  final bool numericEmphasisEnabled;
  final bool autoFormat;

  @override
  State<TranslationPillView> createState() => _TranslationPillViewState();
}

class _TranslationPillViewState extends State<TranslationPillView> {
  late final NaiSyntaxController _syntaxController;
  final FocusNode _sourceFocus = FocusNode();
  // EditableText actions are overridable. A field inside a WidgetSpan would
  // otherwise inherit the containing editor's delete, selection and history
  // actions, which operate on its marker text instead of this source.
  final Map<Type, Action<Intent>> _sourceActions = {
    DeleteCharacterIntent: _LocalTextEditingAction<DeleteCharacterIntent>(),
    DeleteToNextWordBoundaryIntent:
        _LocalTextEditingAction<DeleteToNextWordBoundaryIntent>(),
    DeleteToLineBreakIntent: _LocalTextEditingAction<DeleteToLineBreakIntent>(),
    ExtendSelectionByCharacterIntent:
        _LocalTextEditingAction<ExtendSelectionByCharacterIntent>(),
    ExtendSelectionToNextWordBoundaryIntent:
        _LocalTextEditingAction<ExtendSelectionToNextWordBoundaryIntent>(),
    ExtendSelectionToNextParagraphBoundaryIntent:
        _LocalTextEditingAction<ExtendSelectionToNextParagraphBoundaryIntent>(),
    ExtendSelectionToLineBreakIntent:
        _LocalTextEditingAction<ExtendSelectionToLineBreakIntent>(),
    ExtendSelectionVerticallyToAdjacentLineIntent:
        _LocalTextEditingAction<
          ExtendSelectionVerticallyToAdjacentLineIntent
        >(),
    ExtendSelectionVerticallyToAdjacentPageIntent:
        _LocalTextEditingAction<
          ExtendSelectionVerticallyToAdjacentPageIntent
        >(),
    ExtendSelectionToNextParagraphBoundaryOrCaretLocationIntent:
        _LocalTextEditingAction<
          ExtendSelectionToNextParagraphBoundaryOrCaretLocationIntent
        >(),
    ExtendSelectionToDocumentBoundaryIntent:
        _LocalTextEditingAction<ExtendSelectionToDocumentBoundaryIntent>(),
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent:
        _LocalTextEditingAction<
          ExtendSelectionToNextWordBoundaryOrCaretLocationIntent
        >(),
    ScrollToDocumentBoundaryIntent:
        _LocalTextEditingAction<ScrollToDocumentBoundaryIntent>(),
    ExpandSelectionToLineBreakIntent:
        _LocalTextEditingAction<ExpandSelectionToLineBreakIntent>(),
    ExpandSelectionToDocumentBoundaryIntent:
        _LocalTextEditingAction<ExpandSelectionToDocumentBoundaryIntent>(),
    SelectAllTextIntent: _LocalTextEditingAction<SelectAllTextIntent>(),
    CopySelectionTextIntent: _LocalTextEditingAction<CopySelectionTextIntent>(),
    PasteTextIntent: _LocalTextEditingAction<PasteTextIntent>(),
    TransposeCharactersIntent:
        _LocalTextEditingAction<TransposeCharactersIntent>(),
    UndoTextIntent: _LocalTextEditingAction<UndoTextIntent>(),
    RedoTextIntent: _LocalTextEditingAction<RedoTextIntent>(),
  };

  String _displayText(TranslationPill pill) {
    if (!pill.showOriginal) return pill.zh;
    return PromptInputNormalization.normalize(
      pill.source,
      autoFormat: widget.autoFormat,
      sdAutoConvert: false,
    ).text;
  }

  @override
  void initState() {
    super.initState();
    _syntaxController = NaiSyntaxController(
      text: _displayText(widget.pill),
      highlightEnabled: widget.highlightEnabled,
      numericEmphasisEnabled: widget.numericEmphasisEnabled,
    );
    _sourceFocus.addListener(_handleSourceFocus);
  }

  void _handleSourceFocus() {
    if (!mounted || !widget.pill.showOriginal) return;
    if (!_sourceFocus.hasFocus) _syncText(_displayText(widget.pill));
    setState(() {});
  }

  void _syncText(String text) {
    if (_syntaxController.text == text) return;
    final selection = _syntaxController.selection;
    _syntaxController.value = TextEditingValue(
      text: text,
      selection: selection.isValid
          ? TextSelection(
              baseOffset: selection.baseOffset.clamp(0, text.length),
              extentOffset: selection.extentOffset.clamp(0, text.length),
              affinity: selection.affinity,
              isDirectional: selection.isDirectional,
            )
          : TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void didUpdateWidget(TranslationPillView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syntaxController.highlightEnabled = widget.highlightEnabled;
    _syntaxController.numericEmphasisEnabled = widget.numericEmphasisEnabled;
    final old = oldWidget.pill;
    final pill = widget.pill;
    if (!pill.showOriginal) _sourceFocus.unfocus();
    if (old.showOriginal != pill.showOriginal ||
        old.source != pill.source ||
        old.zh != pill.zh ||
        oldWidget.autoFormat != widget.autoFormat) {
      _syncText(
        pill.showOriginal && _sourceFocus.hasFocus
            ? pill.source
            : _displayText(pill),
      );
    }
  }

  @override
  void dispose() {
    _syntaxController.dispose();
    _sourceFocus
      ..removeListener(_handleSourceFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pill = widget.pill;
    final original = pill.showOriginal;
    final editableSource = original && widget.onSourceChanged != null;
    final accent = scheme.primary.withValues(alpha: original ? .62 : .70);
    final fill = scheme.primary.withValues(alpha: original ? .035 : .065);
    final textStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
          height: 1.25,
        ) ??
        TextStyle(color: scheme.onSurface, height: 1.25);
    return Semantics(
      button: !editableSource,
      label: original ? '翻译块，显示原文' : '翻译块，显示译文',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 300.0;
          Widget text;
          if (editableSource) {
            final available = math.max(
              1.0,
              maxWidth - 14 - 18 - (pill.needsReview ? 18 : 0),
            );
            final painter = TextPainter(
              text: _syntaxController.buildTextSpan(
                context: context,
                style: textStyle,
                withComposing: false,
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: math.max(1.0, available - 4));
            // EditableText reserves cursor width plus a gap; round up so the
            // last word does not wrap solely because of that reserved space.
            final width = (painter.width.ceilToDouble() + 4)
                .clamp(math.min(24.0, available), available)
                .toDouble();
            painter.dispose();
            text = SizedBox(
              width: width,
              child: Actions(
                actions: _sourceActions,
                child: TextField(
                  key: const Key('translation-pill-source-input'),
                  controller: _syntaxController,
                  focusNode: _sourceFocus,
                  style: textStyle,
                  minLines: 1,
                  maxLines: null,
                  scrollPadding: EdgeInsets.zero,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                  onTapOutside: (_) => _sourceFocus.unfocus(),
                  onChanged: (source) {
                    setState(() {});
                    widget.onSourceChanged!(source);
                  },
                ),
              ),
            );
          } else {
            text = Text.rich(
              TranslationTagSpan.annotate(
                context,
                _syntaxController.buildTextSpan(
                  context: context,
                  style: textStyle,
                  withComposing: false,
                ),
                pill.zh,
                original ? const [] : pill.marks,
              ),
              softWrap: true,
            );
          }
          final content = Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(6),
              border: original ? null : Border.all(color: accent, width: 1),
            ),
            foregroundDecoration: original
                ? ShapeDecoration(
                    shape: _DashedRoundedBorder(color: accent, radius: 6),
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (original) ...[
                  widget.sourceHandleBuilder?.call(
                        TranslationIcon(size: 13, color: accent),
                      ) ??
                      TranslationIcon(size: 13, color: accent),
                  const SizedBox(width: 5),
                ],
                Flexible(child: text),
                if (pill.needsReview) ...[
                  const SizedBox(width: 5),
                  Tooltip(
                    message: '原文已修改 · 译文待更新',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) =>
                          widget.onEdit(details.globalPosition),
                      child: Icon(
                        Icons.build_outlined,
                        size: 13,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
          return GestureDetector(
            onTapUp: editableSource
                ? null
                : (details) => widget.onEdit(details.globalPosition),
            onTertiaryTapUp: (_) => widget.onToggle(),
            child: content,
          );
        },
      ),
    );
  }
}

/// Keeps an inner EditableText's native action instead of its ancestor's.
class _LocalTextEditingAction<T extends Intent> extends ContextAction<T> {
  @override
  bool get isActionEnabled => callingAction?.isActionEnabled ?? false;

  @override
  bool isEnabled(T intent, [BuildContext? context]) => switch (callingAction) {
    final ContextAction<T> action => action.isEnabled(intent, context),
    final Action<T> action => action.isEnabled(intent),
    null => false,
  };

  @override
  bool consumesKey(T intent) => callingAction?.consumesKey(intent) ?? false;

  @override
  Object? invoke(T intent, [BuildContext? context]) => switch (callingAction) {
    final ContextAction<T> action => action.invoke(intent, context),
    final Action<T> action => action.invoke(intent),
    null => null,
  };
}

class _DashedRoundedBorder extends ShapeBorder {
  const _DashedRoundedBorder({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(1);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius)),
    );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final path = getOuterPath(rect.deflate(.5));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + 4).clamp(0, metric.length)),
          paint,
        );
        distance += 7;
      }
    }
  }

  @override
  ShapeBorder scale(double t) =>
      _DashedRoundedBorder(color: color, radius: radius * t);
}
