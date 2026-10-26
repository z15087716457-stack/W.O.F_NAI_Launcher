import 'dart:async';
import 'dart:math' as math;

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';

import '../../../../core/autocomplete/completion_models.dart';
import '../../../../core/autocomplete/prompt_token_parser.dart';
import '../../../../core/utils/draft_history.dart';
import '../../../../core/utils/prompt_translation_edit.dart';
import '../../../../core/utils/prompt_translation_language.dart';
import '../../../../core/utils/tag_normalizer.dart';
import '../../../../data/models/prompt_block/pill_document.dart';
import '../../tag_expansion/tag_expansion_wrapper.dart';
import '../../common/translation_modified_badge.dart';
import 'translation_editing_controller.dart';
import 'translation_editor_labels.dart';
import '../../common/translation_icon.dart';
import '../../../../core/utils/localization_extension.dart';

class TranslationPillEditHandle {
  const TranslationPillEditHandle({
    required this.result,
    required this.dismiss,
  });

  final Future<Object?> result;
  final VoidCallback dismiss;
}

class TranslationPillPlainText {
  const TranslationPillPlainText(this.source);

  final String source;
}

typedef PromptDraftConverter =
    Future<PromptTranslationEditResult> Function(
      PromptTranslationEditRequest request,
      String sessionId,
    );

/// Open a compact editor at the click position, without dimming the canvas.
TranslationPillEditHandle showTranslationPillEditor({
  required BuildContext context,
  required TranslationPill initial,
  required Offset globalPosition,
  PromptDraftConverter? converter,
  ValueChanged<String>? cancelConversion,
  bool enableTagExpansion = false,
  bool highlightEnabled = true,
  bool numericEmphasisEnabled = true,
  Future<List<TranslationTagMark>> Function(String, bool)? annotations,
  bool Function()? isModelConfigured,
  Future<void> Function()? onConfigure,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final completer = Completer<Object?>();
  final visibility = ValueNotifier(true);
  late final OverlayEntry entry;

  void finish(Object? value) {
    if (completer.isCompleted) return;
    entry.remove();
    entry.dispose();
    visibility.dispose();
    completer.complete(value);
  }

  entry = OverlayEntry(
    builder: (overlayContext) {
      final overlayBox = overlay.context.findRenderObject()! as RenderBox;
      final localPosition = overlayBox.globalToLocal(globalPosition);
      final screen = overlayBox.size;
      final cardWidth = math.min(380.0, math.max(0.0, screen.width - 16));
      return ValueListenableBuilder<bool>(
        valueListenable: visibility,
        builder: (_, visible, __) => Visibility(
          visible: visible,
          maintainState: true,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => finish(null),
                ),
              ),
              Positioned.fill(
                child: CustomSingleChildLayout(
                  delegate: _TranslationPopoverLayout(localPosition),
                  child: SizedBox(
                    width: cardWidth,
                    child: _TranslationPillEditPopover(
                      initial: initial,
                      onComplete: finish,
                      converter: converter,
                      cancelConversion: cancelConversion,
                      enableTagExpansion: enableTagExpansion,
                      highlightEnabled: highlightEnabled,
                      numericEmphasisEnabled: numericEmphasisEnabled,
                      annotations: annotations,
                      isModelConfigured: isModelConfigured,
                      onConfigure: onConfigure == null
                          ? null
                          : () async {
                              visibility.value = false;
                              try {
                                await onConfigure();
                              } finally {
                                if (!completer.isCompleted) {
                                  visibility.value = true;
                                }
                              }
                            },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  overlay.insert(entry);
  return TranslationPillEditHandle(
    result: completer.future,
    dismiss: () => finish(null),
  );
}

class _TranslationPopoverLayout extends SingleChildLayoutDelegate {
  const _TranslationPopoverLayout(this.anchor);

  final Offset anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: math.max(0, constraints.maxWidth - 16),
        maxHeight: math.max(0, constraints.maxHeight - 16),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final left = anchor.dx
        .clamp(8.0, math.max(8.0, size.width - childSize.width - 8))
        .toDouble();
    final below = anchor.dy + 10;
    final top = below + childSize.height <= size.height - 8
        ? below
        : (anchor.dy - childSize.height - 10)
              .clamp(8.0, math.max(8.0, size.height - childSize.height - 8))
              .toDouble();
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_TranslationPopoverLayout oldDelegate) =>
      oldDelegate.anchor != anchor;
}

class _TranslationPillEditPopover extends StatefulWidget {
  const _TranslationPillEditPopover({
    required this.initial,
    required this.onComplete,
    this.converter,
    this.cancelConversion,
    this.enableTagExpansion = false,
    this.highlightEnabled = true,
    this.numericEmphasisEnabled = true,
    this.annotations,
    this.isModelConfigured,
    this.onConfigure,
  });

  final TranslationPill initial;
  final ValueChanged<Object?> onComplete;
  final PromptDraftConverter? converter;
  final ValueChanged<String>? cancelConversion;
  final bool enableTagExpansion;
  final bool highlightEnabled;
  final bool numericEmphasisEnabled;
  final Future<List<TranslationTagMark>> Function(String, bool)? annotations;
  final bool Function()? isModelConfigured;
  final Future<void> Function()? onConfigure;

  @override
  State<_TranslationPillEditPopover> createState() =>
      _TranslationPillEditPopoverState();
}

class _TranslationPillEditPopoverState
    extends State<_TranslationPillEditPopover> {
  late final TranslationEditingController _source =
      TranslationEditingController(
        text: widget.initial.source,
        highlightEnabled: widget.highlightEnabled,
        numericEmphasisEnabled: widget.numericEmphasisEnabled,
      );
  late final TranslationEditingController _zh = TranslationEditingController(
    text: widget.initial.zh,
    highlightEnabled: widget.highlightEnabled,
    numericEmphasisEnabled: widget.numericEmphasisEnabled,
  );
  final _sourcePaintKey = GlobalKey();
  final _zhPaintKey = GlobalKey();
  final _sourceScroll = ScrollController();
  final _zhScroll = ScrollController();
  Timer? _annotationTimer;
  int _annotationVersion = 0;
  final _sourceFocus = FocusNode();
  final _zhFocus = FocusNode();
  late final TextDraftHistory _sourceHistory;
  late final TextDraftHistory _zhHistory;
  late String _lastZh = widget.initial.zh;
  late String _baselineSource = widget.initial.source;
  late String _baselineZh = widget.initial.zh;
  late String? _synchronizedSource = widget.initial.needsReview
      ? null
      : widget.initial.source;
  late String? _synchronizedReading = widget.initial.translationEdited
      ? null
      : widget.initial.zh;
  late PromptTranslationLanguage _language = PromptTranslationLanguage.fromCode(
    widget.initial.languageCode,
  );
  List<TranslationTagMark> _marks = const [];
  List<PromptSelectedTerm> _pickedTerms = const [];
  final Map<String, List<PromptSelectedTerm>> _termVersions = {};
  final Map<String, List<TranslationTagMark>> _markVersions = {};
  final Map<String, PromptTranslationLanguage> _readingLanguages = {};
  PromptTranslationDirection? _busy;
  int _revision = 0;
  bool _applyingResult = false;
  bool _configuring = false;
  String? _message;
  late final String _sessionId = 'prompt-edit-${identityHashCode(this)}';
  bool get _needsReview =>
      _synchronizedSource == null || _source.text != _synchronizedSource;
  bool get _translationEdited =>
      _synchronizedReading == null || _zh.text != _synchronizedReading;
  TranslationEditorLabels get _labels => TranslationEditorLabels(context);

  @override
  void initState() {
    super.initState();
    _sourceHistory = TextDraftHistory(_source);
    _zhHistory = TextDraftHistory(_zh);
    _marks = widget.initial.marks;
    _rememberReadingLanguage();
    _source.addListener(_sourceChanged);
    _zh.addListener(_zhChanged);
    _zh.updateMarks(_marks);
    _scheduleAnnotations();
  }

  void _sourceChanged() {
    if (_applyingResult) return;
    // Controller listeners also see selection changes. Only text changes
    // invalidate an outstanding request or its annotations.
    if (_lastSource == _source.text) return;
    _lastSource = _source.text;
    _revision++;
    _marks = const [];
    _markVersions.clear();
    _source.updateMarks(const []);
    _zh.updateMarks(const []);
    _scheduleAnnotations();
    if (mounted) setState(() {});
  }

  late String _lastSource = widget.initial.source;

  void _zhChanged() {
    if (_applyingResult || _lastZh == _zh.text) return;
    _language = _readingLanguages[_zh.text] ?? _language;
    _rememberReadingLanguage();
    _rememberTerms(_lastZh, _pickedTerms);
    _pickedTerms =
        _termVersions[_zh.text] ??
        PromptSelectedTerm.afterEdit(_pickedTerms, _lastZh, _zh.text);
    _rememberTerms(_zh.text, _pickedTerms);
    _markVersions[_lastZh] = _marks;
    _marks =
        _markVersions[_zh.text] ??
        PromptSelectedTerm.afterEdit(
              [
                for (final mark in _marks)
                  if (mark.start >= 0 &&
                      mark.end <= _lastZh.length &&
                      mark.end > mark.start)
                    PromptSelectedTerm(
                      start: mark.start,
                      text: _lastZh.substring(mark.start, mark.end),
                      tag: mark.tag,
                      iconId: mark.iconId,
                    ),
              ],
              _lastZh,
              _zh.text,
            )
            .map(
              (term) => TranslationTagMark(
                start: term.start,
                end: term.end,
                tag: term.tag,
                iconId: term.iconId!,
              ),
            )
            .toList();
    _markVersions[_zh.text] = _marks;
    if (_markVersions.length > 100) {
      _markVersions.remove(_markVersions.keys.first);
    }
    _lastZh = _zh.text;
    _revision++;
    _source.updateMarks(const []);
    _zh.updateMarks(_marks);
    _scheduleAnnotations();
    if (mounted) setState(() {});
  }

  Future<void> _convert(PromptTranslationDirection direction) async {
    if (_busy != null || widget.converter == null) return;
    final request = PromptTranslationEditRequest(
      direction: direction,
      source: _source.text,
      zh: _zh.text,
      baselineSource: _baselineSource,
      baselineZh: _baselineZh,
      selectedTerms: List.unmodifiable(_pickedTerms),
      languageCode: _language.code,
      targetLanguageCode: _labels.language.code,
    );
    if (request.input.trim().isEmpty) return;
    final revision = _revision;
    setState(() {
      _busy = direction;
      _message = null;
    });
    try {
      final result = await widget.converter!(request, _sessionId);
      if (!mounted) return;
      if (revision != _revision) {
        setState(() => _message = context.l10n.promptTranslation_draftChanged);
        return;
      }
      (direction == PromptTranslationDirection.toChinese
              ? _zhFocus
              : _sourceFocus)
          .requestFocus();
      _applyingResult = true;
      _rememberTerms(_zh.text, _pickedTerms);
      (direction == PromptTranslationDirection.toChinese
              ? _zhHistory
              : _sourceHistory)
          .replace(
            TextEditingValue(
              text: result.text,
              selection: TextSelection.collapsed(offset: result.text.length),
            ),
          );
      _lastSource = _source.text;
      _lastZh = _zh.text;
      _pickedTerms = direction == PromptTranslationDirection.toChinese
          ? const []
          : _pickedTerms;
      _rememberTerms(_zh.text, _pickedTerms);
      _marks = direction == PromptTranslationDirection.toChinese
          ? result.marks
          : const [];
      _synchronizedSource = _source.text;
      _synchronizedReading = _zh.text;
      if (direction == PromptTranslationDirection.toChinese) {
        _language = PromptTranslationLanguage.fromCode(
          request.targetLanguageCode,
        );
      }
      _rememberReadingLanguage();
      _baselineSource = _source.text;
      _baselineZh = _zh.text;
      _revision++;
      _applyingResult = false;
      _source.updateMarks(const []);
      _zh.updateMarks(_marks);
      _scheduleAnnotations();
      setState(() {});
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _message = context.l10n.promptTranslation_convertFailed('$error'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _scheduleAnnotations() {
    _annotationTimer?.cancel();
    final version = ++_annotationVersion;
    final pickedMarks = [
      for (final term in _pickedTerms)
        if (term.iconId != null)
          TranslationTagMark(
            start: term.start,
            end: term.end,
            tag: term.tag,
            iconId: term.iconId!,
          ),
    ];
    final knownMarks = [
      ..._marks,
      for (final mark in pickedMarks)
        if (!_marks.any((m) => mark.start < m.end && mark.end > m.start)) mark,
    ];
    _zh.updateMarks(knownMarks);
    if (widget.annotations == null) return;
    _annotationTimer = Timer(const Duration(milliseconds: 160), () async {
      final source = _source.text;
      final zh = _zh.text;
      try {
        final results = await Future.wait([
          widget.annotations!(source, false),
          widget.annotations!(zh, _language.isChinese),
        ]);
        if (!mounted ||
            version != _annotationVersion ||
            _source.text != source ||
            _zh.text != zh) {
          return;
        }
        _source.updateMarks(results[0]);
        _zh.updateMarks([
          ...knownMarks,
          for (final mark in results[1])
            if (!knownMarks.any(
              (m) => mark.start < m.end && mark.end > m.start,
            ))
              mark,
        ]);
      } catch (_) {
        // Optional local decoration must never interrupt editing.
      }
    });
  }

  void _insertCandidate(
    CompletionCandidate candidate, {
    required bool chinese,
  }) {
    final controller = chinese ? _zh : _source;
    final selected = controller.selection;
    final caret = selected.isValid
        ? selected.extentOffset
        : controller.text.length;
    final reading = candidate.translation?.trim() ?? '';
    final label = chinese && _language.isChinese
        ? (reading.isNotEmpty
              ? reading
              : TagNormalizer.toDisplay(candidate.canonicalTag))
        : candidate.canonicalTag;
    final result = PromptTokenParser.insertAtCaret(
      text: controller.text,
      cursorPosition: caret,
      canonicalTag: label,
      autoInsertComma: true,
    );
    if (result.text == controller.text) return;
    (chinese ? _zhHistory : _sourceHistory).replace(
      TextEditingValue(
        text: result.text,
        selection: TextSelection.collapsed(offset: result.cursorPosition),
      ),
    );
    if (chinese) {
      final start = result.text.lastIndexOf(label, result.cursorPosition);
      if (start >= 0) {
        _pickedTerms = [
          ..._pickedTerms,
          PromptSelectedTerm(
            start: start,
            text: label,
            tag: candidate.canonicalTag,
            iconId: candidate.category.name,
          ),
        ];
        _rememberTerms(_zh.text, _pickedTerms);
        _scheduleAnnotations();
      }
    }
    (chinese ? _zhFocus : _sourceFocus).requestFocus();
  }

  void _rememberTerms(String text, List<PromptSelectedTerm> terms) {
    _termVersions[text] = List.unmodifiable(terms);
    if (_termVersions.length > 100) {
      _termVersions.remove(_termVersions.keys.first);
    }
  }

  void _rememberReadingLanguage() {
    _readingLanguages[_zh.text] = _language;
    if (_readingLanguages.length > 100) {
      _readingLanguages.remove(_readingLanguages.keys.first);
    }
  }

  @override
  void dispose() {
    if (_busy != null) widget.cancelConversion?.call(_sessionId);
    _annotationTimer?.cancel();
    _sourceScroll.dispose();
    _zhScroll.dispose();
    _source.removeListener(_sourceChanged);
    _zh.removeListener(_zhChanged);
    _sourceHistory.dispose();
    _zhHistory.dispose();
    _source.dispose();
    _zh.dispose();
    _sourceFocus.dispose();
    _zhFocus.dispose();
    super.dispose();
  }

  void _save() {
    final sourceChanged = _source.text != widget.initial.source;
    widget.onComplete(
      TranslationPill(
        source: _source.text,
        zh: _zh.text.trim(),
        marks: _marks,
        showOriginal: sourceChanged || widget.initial.showOriginal,
        needsReview: _needsReview,
        languageCode: _language.code,
        translationEdited: _translationEdited,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      key: const Key('translation-pill-editor-popover'),
      elevation: 5,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TranslationIcon(
                  size: 17,
                  color: scheme.primary,
                  busy: _busy != null,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _labels.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _labels.close,
                  onPressed: () => widget.onComplete(null),
                  icon: const Icon(Icons.close),
                  iconSize: 17,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sourceHeader(context),
                    const SizedBox(height: 4),
                    _field(_source),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _fieldLabel(
                            context,
                            _labels.reading(_language),
                            _labels.editable,
                          ),
                        ),
                        _directionButton(PromptTranslationDirection.toSource),
                        const SizedBox(width: 6),
                        _directionButton(PromptTranslationDirection.toChinese),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _field(_zh),
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _message!,
                          key: const Key('translation-pill-message'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                      ),
                    if (widget.isModelConfigured?.call() == false)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const Key('translation-pill-configure'),
                          onPressed: _configuring || widget.onConfigure == null
                              ? null
                              : () async {
                                  setState(() => _configuring = true);
                                  try {
                                    await widget.onConfigure!();
                                  } finally {
                                    if (mounted) {
                                      setState(() => _configuring = false);
                                    }
                                  }
                                },
                          icon: const Icon(Icons.settings_outlined, size: 14),
                          label: Text(_labels.configure),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 7),
            Row(
              children: [
                IconButton(
                  key: const Key('translation-pill-delete'),
                  tooltip: _labels.delete,
                  onPressed: () => widget.onComplete('delete'),
                  icon: const Icon(Icons.delete_outline),
                  color: scheme.error,
                  iconSize: 19,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 4),
                IconButton(
                  key: const Key('translation-pill-plain-text'),
                  tooltip: _labels.restore,
                  onPressed: _source.text.isEmpty
                      ? null
                      : () => widget.onComplete(
                          TranslationPillPlainText(_source.text),
                        ),
                  icon: const Text(
                    'A',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
                const Spacer(),
                FilledButton.icon(
                  key: const Key('translation-pill-save'),
                  onPressed:
                      _busy != null ||
                          _source.text.trim().isEmpty ||
                          _zh.text.trim().isEmpty
                      ? null
                      : _save,
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(_labels.save),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(72, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceHeader(BuildContext context) {
    final label = _fieldLabel(context, _labels.source, _labels.generation);
    if (!_needsReview && !_translationEdited) return label;
    final badges = [
      if (_needsReview)
        TranslationModifiedBadge(
          key: const Key('translation-pill-modified'),
          prefix: _labels.sourcePrefix,
          label: _labels.modified,
          tooltip: _labels.sourceWarning(_language),
        ),
      if (_translationEdited)
        TranslationEditedBadge(
          key: const Key('translation-pill-edited'),
          prefix: _language.badgePrefix,
          label: _labels.edited,
          tooltip: _labels.editHint,
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep the statuses paired above the source field even with long labels
        // or large accessibility text; never insert a status row over the reading.
        final style = Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontSize: 11);
        double width(String text) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final result = painter.width;
          painter.dispose();
          return result;
        }

        final badgeWidth =
            (_needsReview
                ? width(_labels.sourcePrefix) + width(_labels.modified) + 46
                : 0) +
            (_translationEdited
                ? width(_language.badgePrefix) + width(_labels.edited) + 40
                : 0) +
            (badges.length > 1 ? 6 : 0);
        final statuses = Wrap(
          key: const Key('translation-pill-statuses'),
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: badges,
        );
        if (badgeWidth + 80 > constraints.maxWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              label,
              const SizedBox(height: 4),
              Align(alignment: Alignment.centerRight, child: statuses),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: label),
            const SizedBox(width: 6),
            statuses,
          ],
        );
      },
    );
  }

  Widget _fieldLabel(BuildContext context, String title, String hint) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 5,
    runSpacing: 2,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      Text(
        '· $hint',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _directionButton(PromptTranslationDirection direction) {
    final chinese = direction == PromptTranslationDirection.toChinese;
    final input = chinese ? _source : _zh;
    return IconButton.filledTonal(
      key: Key(
        chinese ? 'translation-pill-to-chinese' : 'translation-pill-to-source',
      ),
      tooltip: chinese
          ? '${_labels.source} → ${_labels.reading(_labels.language)}'
          : '${_labels.reading(_language)} → ${_labels.source}',
      constraints: const BoxConstraints.tightFor(width: 34, height: 28),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      onPressed:
          _busy != null ||
              input.text.trim().isEmpty ||
              widget.converter == null ||
              widget.isModelConfigured?.call() == false
          ? null
          : () => _convert(direction),
      icon: _busy == direction
          ? const TranslationIcon(size: 16, busy: true)
          : Icon(chinese ? Icons.arrow_downward : Icons.arrow_upward, size: 17),
    );
  }

  Widget _field(TranslationEditingController controller) {
    final chinese = identical(controller, _zh);
    final focus = chinese ? _zhFocus : _sourceFocus;
    final history = chinese ? _zhHistory : _sourceHistory;
    Widget field = Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyY, control: true): RedoTextIntent(
          SelectionChangedCause.keyboard,
        ),
      },
      child: Actions(
        actions: {
          UndoTextIntent: CallbackAction<UndoTextIntent>(
            onInvoke: (_) {
              history.undo();
              return null;
            },
          ),
          RedoTextIntent: CallbackAction<RedoTextIntent>(
            onInvoke: (_) {
              history.redo();
              return null;
            },
          ),
        },
        child: TextField(
          key: Key(
            chinese
                ? 'translation-pill-zh-field'
                : 'translation-pill-source-field',
          ),
          controller: controller,
          focusNode: focus,
          scrollController: chinese ? _zhScroll : _sourceScroll,
          minLines: 1,
          maxLines: null,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.3),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
    field = TranslationFieldIcons(
      controller: controller,
      scrollController: chinese ? _zhScroll : _sourceScroll,
      fieldKey: chinese ? _zhPaintKey : _sourcePaintKey,
      child: field,
    );
    if (widget.enableTagExpansion) {
      field = TagExpansionWrapper(
        controller: controller,
        focusNode: focus,
        onCandidateSelected: (candidate) =>
            _insertCandidate(candidate, chinese: chinese),
        child: field,
      );
    }
    return field;
  }
}
