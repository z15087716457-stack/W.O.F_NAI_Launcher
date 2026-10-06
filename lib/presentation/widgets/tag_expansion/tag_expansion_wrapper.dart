import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kPrimaryMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/autocomplete/autocomplete_settings.dart';
import '../../../core/autocomplete/completion_models.dart';
import '../../../core/autocomplete/prompt_token_parser.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/tag_expansion/tag_expansion_providers.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/tag_normalizer.dart';
import '../../../core/wiki/tag_wiki_repository.dart';
import '../../../core/wiki/auto_tag_translation_controller.dart';
import '../autocomplete/tag_category_visuals.dart';
import '../autocomplete/tag_candidate_title.dart';
import '../../router/app_router.dart';
import '../common/translation_icon.dart';
import '../common/related_tags_icon.dart';
import '../common/wiki_linked_body.dart';
import '../common/wiki_retranslate_button.dart';

class _ExpansionVisit {
  const _ExpansionVisit({
    required this.query,
    required this.results,
    required this.relatedResults,
    required this.relatedTag,
    required this.wikiCandidate,
    required this.wikiEntry,
    required this.contextTag,
    required this.usingContext,
    required this.selectedIndex,
    required this.searchOffset,
    required this.relatedOffset,
    required this.wikiOffset,
    required this.showWikiTranslation,
    required this.searchLoading,
    required this.relatedLoading,
    required this.wikiLoading,
    required this.searchFailed,
    required this.relatedFailed,
    required this.wikiFailed,
  });
  final TextEditingValue query;
  final List<CompletionCandidate> results, relatedResults;
  final String? relatedTag, contextTag;
  final CompletionCandidate? wikiCandidate;
  final TagWikiEntry? wikiEntry;
  final bool usingContext, searchLoading, relatedLoading, wikiLoading;
  final bool searchFailed, relatedFailed, wikiFailed;
  final bool showWikiTranslation;
  final int selectedIndex;
  final double searchOffset, relatedOffset, wikiOffset;
}

/// Explicit, local-only tag search for editable tag fields. It does not listen
/// to typed text and never enters the old autocomplete query pipeline.
class TagExpansionWrapper extends ConsumerStatefulWidget {
  const TagExpansionWrapper({
    super.key,
    required this.child,
    required this.controller,
    this.focusNode,
    this.enabled = true,
    this.splitOnSpaces = false,
    this.onTagSelected,
    this.onCandidateSelected,
    this.onApplied,
    this.onActiveChanged,
  });

  final Widget child;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;

  /// Use space-separated tokens for gallery queries; prompts use commas.
  final bool splitOnSpaces;

  /// Commits a canonical tag using the host field's own input semantics.
  /// Prompt editors use the default caret insertion when this is omitted.
  final ValueChanged<String>? onTagSelected;

  /// Bilingual editors need the reading and category as well as the tag ID.
  final ValueChanged<CompletionCandidate>? onCandidateSelected;
  final ValueChanged<String>? onApplied;
  final ValueChanged<bool>? onActiveChanged;

  @override
  ConsumerState<TagExpansionWrapper> createState() =>
      _TagExpansionWrapperState();
}

class _TagExpansionWrapperState extends ConsumerState<TagExpansionWrapper>
    with WidgetsBindingObserver {
  static const _limitOptions = [12, 24, 40, 80];
  static const _compactRowHeight = 44.0;
  static const _columnGap = 2.0;
  static const _listInset = 4.0;
  static const _panelGap = 3.0;

  final _anchorKey = GlobalKey(debugLabel: 'tag-expansion-anchor');
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _searchScroll = ScrollController();
  final _relatedScroll = ScrollController();
  final _wikiScroll = ScrollController();
  Object? _wikiMeasurementKey;
  double? _wikiMeasuredHeight;
  final _history = <_ExpansionVisit>[];
  late final AutoTagTranslationController _autoTranslation;
  bool _visibilityScheduled = false;
  Set<String> _searchVisible = {};
  Set<String> _relatedVisible = {};
  double _relatedWidth = 240;
  late final String _searchSurface =
      'tag-expansion-search-${identityHashCode(this)}';
  late final String _relatedSurface =
      'tag-expansion-related-${identityHashCode(this)}';
  late final String _wikiSurface =
      'tag-expansion-wiki-${identityHashCode(this)}';
  int _surfaceEpoch = 0;
  final _limitButtonKey = GlobalKey(debugLabel: 'tag-expansion-limit-button');
  Timer? _debounce;
  OverlayEntry? _entry;
  OverlayEntry? _limitMenuEntry;
  int? _pointerId;
  Offset? _pointerDown;
  TextSelection? _selectionAtDown;
  String? _textAtDown;
  bool _dragged = false;
  int _gestureGeneration = 0;
  Offset? _anchorGlobal;
  bool _controlAtDown = false;
  bool _active = false;
  String _openedText = '';
  int _insertionOffset = 0;
  Set<String> _existingTags = const {};
  int _searchSequence = 0;
  int _relatedSequence = 0;
  int _wikiSequence = 0;
  int _selectedIndex = 0;
  int _gridColumns = 2;
  int _resultLimit = 40;
  List<double> _rowHeights = const [];
  final _rowKeys = <int, GlobalKey>{};
  final _relatedRowKeys = <int, GlobalKey>{};
  bool _searchLoading = false;
  bool _relatedLoading = false;
  bool _searchFailed = false;
  bool _relatedFailed = false;
  List<CompletionCandidate> _results = const [];
  List<CompletionCandidate> _relatedResults = const [];
  String? _relatedTag;
  CompletionCandidate? _wikiCandidate;
  TagWikiEntry? _wikiEntry;
  bool _wikiLoading = false;
  bool _wikiFailed = false;
  bool _showWikiTranslation = true;
  String? _hoveredId;
  String? _focusedId;
  String? _contextTag;
  bool _usingContext = false;

  @override
  void initState() {
    super.initState();
    _autoTranslation = ref.read(autoTagTranslationProvider);
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onEditorChanged);
    _autoTranslation.addListener(_markNeedsBuild);
    _searchScroll.addListener(_scheduleVisibleUpdate);
    _relatedScroll.addListener(_scheduleVisibleUpdate);
    _searchFocus.onKeyEvent = _onSearchKey;
    if (Hive.isBoxOpen(StorageKeys.settingsBox)) {
      final stored = Hive.box(
        StorageKeys.settingsBox,
      ).get(StorageKeys.tagExpansionResultLimit);
      if (stored is int && _limitOptions.contains(stored)) {
        _resultLimit = stored;
      }
    }
  }

  @override
  void didChangeMetrics() {
    _closeLimitMenu();
    _markNeedsBuild();
  }

  @override
  void didUpdateWidget(covariant TagExpansionWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onEditorChanged);
      widget.controller.addListener(_onEditorChanged);
      _close();
    } else if (oldWidget.enabled && !widget.enabled) {
      _close();
    }
  }

  void _onEditorChanged() {
    if (_active && widget.controller.text != _openedText) _close();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_pointerId != null || event.buttons & kPrimaryMouseButton == 0) {
      return;
    }
    _gestureGeneration++;
    _pointerId = event.pointer;
    _pointerDown = event.position;
    _selectionAtDown = widget.controller.selection;
    _textAtDown = widget.controller.text;
    _dragged = false;
    final keyboard = HardwareKeyboard.instance;
    _controlAtDown = keyboard.isControlPressed || keyboard.isMetaPressed;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_pointerId != event.pointer || _pointerDown == null) return;
    if ((event.position - _pointerDown!).distance > 4) _dragged = true;
  }

  void _resetPointer() {
    _pointerId = null;
    _pointerDown = null;
    _selectionAtDown = null;
    _textAtDown = null;
    _dragged = false;
    _controlAtDown = false;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_pointerId != event.pointer) return;
    _gestureGeneration++;
    _resetPointer();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_pointerId != event.pointer) return;
    final control = _controlAtDown;
    final dragged =
        _dragged ||
        (_pointerDown != null && (event.position - _pointerDown!).distance > 4);
    final originalSelection = _selectionAtDown;
    final originalText = _textAtDown;
    final generation = _gestureGeneration;
    _resetPointer();
    if (!control || !widget.enabled) return;
    if (!ref.read(autocompleteSettingsProvider).relatedTagsEnabled) return;

    // Read the final selection after the entire pointer event has dispatched.
    // A post-frame callback costs an extra frame and can stall when pointer-up
    // does not schedule one; the microtask lets the overlay paint next frame.
    scheduleMicrotask(() {
      if (!mounted ||
          !widget.enabled ||
          generation != _gestureGeneration ||
          widget.controller.text != originalText ||
          !ref.read(autocompleteSettingsProvider).relatedTagsEnabled) {
        return;
      }
      final selection = widget.controller.selection;
      if (!selection.isValid) return;
      final hasNewSelection =
          !selection.isCollapsed && selection != originalSelection;
      final selectedByDrag = dragged || hasNewSelection;
      if (selectedByDrag && selection.isCollapsed) return;
      final selectedText = selectedByDrag
          ? widget.controller.text.substring(selection.start, selection.end)
          : '';
      final selectedQuery = selectedText.trim();
      final source = selectedByDrag
          ? _selectedTag(widget.controller.text, selection)
          : null;
      final offset = selection.extentOffset.clamp(
        0,
        widget.controller.text.length,
      );
      final contextTag = selectedByDrag
          ? null
          : PromptTokenParser.parseRelated(
              text: widget.controller.text,
              cursorPosition: offset,
              limit: 1,
              locale: Localizations.localeOf(context).toLanguageTag(),
              splitOnSpaces: widget.splitOnSpaces,
            )?.relatedTag;
      _open(
        offset: offset,
        query: selectedQuery,
        relatedTag: source,
        contextTag: contextTag,
      );
    });
  }

  String? _selectedTag(String text, TextSelection selection) {
    if (selection.isCollapsed || !selection.isValid) return null;
    final selectedText = text.substring(selection.start, selection.end).trim();
    if (selectedText.isEmpty || selectedText.contains(RegExp(r'[,，\r\n]'))) {
      return null;
    }
    final query = PromptTokenParser.parse(
      text: text,
      cursorPosition: selection.start,
      limit: 1,
      locale: Localizations.localeOf(context).toLanguageTag(),
      splitOnSpaces: widget.splitOnSpaces,
    );
    return query.kind == CompletionQueryKind.tag &&
            query.token.isNotEmpty &&
            TagNormalizer.normalize(selectedText) == query.token &&
            selection.start <= query.replacementRange.start &&
            selection.end >= query.replacementRange.end
        ? query.token
        : null;
  }

  void _open({
    required int offset,
    required String query,
    String? relatedTag,
    String? contextTag,
  }) {
    _close();
    _surfaceEpoch++;
    final anchor = _anchorKey.currentContext;
    final anchorBox = anchor?.findRenderObject();
    if (anchorBox is! RenderBox || !anchorBox.hasSize) return;

    _openedText = widget.controller.text;
    _insertionOffset = offset;
    final parsed = PromptTokenParser.parse(
      text: _openedText,
      cursorPosition: offset,
      limit: 1,
      locale: Localizations.localeOf(context).toLanguageTag(),
      splitOnSpaces: widget.splitOnSpaces,
    );
    _existingTags = {
      ...parsed.existingTags,
      if (parsed.kind == CompletionQueryKind.tag && parsed.token.isNotEmpty)
        parsed.token,
    };
    final caret = _caretOffset(anchor!, anchorBox);
    _anchorGlobal = anchorBox.localToGlobal(caret);
    _searchController.text = TagNormalizer.toDisplay(query);
    _history.clear();
    _selectedIndex = 0;
    _results = const [];
    _relatedResults = const [];
    _relatedTag = relatedTag;
    _wikiCandidate = null;
    _wikiEntry = null;
    _contextTag = contextTag;
    _usingContext = contextTag != null;
    _active = true;
    widget.onActiveChanged?.call(true);
    _entry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context, rootOverlay: true).insert(_entry!);
    _queueSearch(immediate: true);
    if (relatedTag != null) _loadRelated(relatedTag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _active) _searchFocus.requestFocus();
    });
  }

  Offset _caretOffset(BuildContext anchor, RenderBox anchorBox) {
    RenderEditable? editable;
    void visit(Element element) {
      if (editable != null) return;
      if (element.renderObject case final RenderEditable found) {
        editable = found;
        return;
      }
      element.visitChildren(visit);
    }

    (anchor as Element).visitChildren(visit);
    final selection = widget.controller.selection;
    if (editable == null || !selection.isValid) {
      return Offset(0, anchorBox.size.height);
    }
    final field = editable!;
    final rect = field.getLocalRectForCaret(
      TextPosition(offset: selection.extentOffset),
    );
    return field.localToGlobal(
      Offset(rect.left, rect.top + field.preferredLineHeight),
      ancestor: anchorBox,
    );
  }

  void _onSearchChanged(String value) {
    ref.read(autoTagTranslationProvider).clearSurface(_searchSurface);
    ref.read(autoTagTranslationProvider).clearSurface(_relatedSurface);
    ref.read(autoTagTranslationProvider).clearSurface(_wikiSurface);
    _relatedVisible.clear();
    _relatedSequence++;
    _relatedTag = null;
    _relatedResults = const [];
    _relatedLoading = false;
    _wikiSequence++;
    _wikiCandidate = null;
    _wikiEntry = null;
    _queueSearch();
  }

  void _visitTag(CompletionCandidate candidate) {
    if (_wikiCandidate?.canonicalTag == candidate.canonicalTag &&
        TagNormalizer.normalize(_searchController.text) ==
            candidate.canonicalTag) {
      return;
    }
    _history.add(
      _ExpansionVisit(
        query: _searchController.value,
        results: _results,
        relatedResults: _relatedResults,
        relatedTag: _relatedTag,
        wikiCandidate: _wikiCandidate,
        wikiEntry: _wikiEntry,
        contextTag: _contextTag,
        usingContext: _usingContext,
        selectedIndex: _selectedIndex,
        searchOffset: _searchScroll.hasClients ? _searchScroll.offset : 0,
        relatedOffset: _relatedScroll.hasClients ? _relatedScroll.offset : 0,
        wikiOffset: _wikiScroll.hasClients ? _wikiScroll.offset : 0,
        showWikiTranslation: _showWikiTranslation,
        searchLoading: _searchLoading,
        relatedLoading: _relatedLoading,
        wikiLoading: _wikiLoading,
        searchFailed: _searchFailed,
        relatedFailed: _relatedFailed,
        wikiFailed: _wikiFailed,
      ),
    );
    _searchController.text = TagNormalizer.toDisplay(candidate.canonicalTag);
    _onSearchChanged(_searchController.text);
    _results = const [];
    _queueSearch(immediate: true);
    if (_searchScroll.hasClients) _searchScroll.jumpTo(0);
    _openWiki(candidate);
  }

  void _goBack() {
    if (_history.isEmpty) return;
    final visit = _history.removeLast();
    _debounce?.cancel();
    _searchSequence++;
    _relatedSequence++;
    _wikiSequence++;
    _surfaceEpoch++;
    _autoTranslation.clearSurface(_searchSurface);
    _autoTranslation.clearSurface(_relatedSurface);
    _autoTranslation.clearSurface(_wikiSurface);
    _searchVisible.clear();
    _relatedVisible.clear();
    _searchController.value = visit.query;
    _results = visit.results;
    _relatedResults = visit.relatedResults;
    _relatedTag = visit.relatedTag;
    _contextTag = visit.contextTag;
    _usingContext = visit.usingContext;
    _selectedIndex = visit.selectedIndex;
    _wikiCandidate = visit.wikiCandidate;
    _wikiEntry = visit.wikiEntry;
    _showWikiTranslation = visit.showWikiTranslation;
    _searchLoading = false;
    _relatedLoading = false;
    _wikiLoading = false;
    _searchFailed = visit.searchFailed;
    _relatedFailed = visit.relatedFailed;
    _wikiFailed = visit.wikiFailed;
    _hoveredId = null;
    _focusedId = null;
    if (visit.searchLoading) _queueSearch(immediate: true);
    if (visit.relatedLoading && visit.relatedTag != null) {
      _loadRelated(visit.relatedTag!);
    }
    if (visit.wikiLoading && visit.wikiCandidate != null) {
      _openWiki(visit.wikiCandidate!);
    } else if (visit.wikiEntry != null && visit.wikiCandidate != null) {
      _autoTranslation.requestWiki(
        surface: _wikiSurface,
        tag: visit.wikiCandidate!.canonicalTag,
      );
    }
    _markNeedsBuild();
    final sequence = _searchSequence;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_active || sequence != _searchSequence) return;
      void restore(ScrollController controller, double offset) {
        if (controller.hasClients) {
          controller.jumpTo(
            offset.clamp(0, controller.position.maxScrollExtent),
          );
        }
      }

      restore(_searchScroll, visit.searchOffset);
      restore(_relatedScroll, visit.relatedOffset);
      restore(_wikiScroll, visit.wikiOffset);
      _scheduleVisibleUpdate();
    });
  }

  void _setResultLimit(int limit) {
    _closeLimitMenu();
    if (_resultLimit == limit) return;
    _resultLimit = limit;
    if (Hive.isBoxOpen(StorageKeys.settingsBox)) {
      unawaited(
        Hive.box(
          StorageKeys.settingsBox,
        ).put(StorageKeys.tagExpansionResultLimit, limit),
      );
    }
    _queueSearch(immediate: true);
  }

  void _closeLimitMenu() {
    final menu = _limitMenuEntry;
    _limitMenuEntry = null;
    menu?.remove();
    menu?.dispose();
  }

  void _toggleLimitMenu() {
    if (_limitMenuEntry != null) {
      _closeLimitMenu();
      return;
    }
    final overlay = Overlay.of(context, rootOverlay: true);
    final root = overlay.context.findRenderObject();
    final button = _limitButtonKey.currentContext?.findRenderObject();
    if (root is! RenderBox || button is! RenderBox) return;
    final origin = root.globalToLocal(button.localToGlobal(Offset.zero));
    const menuWidth = 112.0;
    const menuHeight = 4 * 36.0;
    final left = (origin.dx + button.size.width - menuWidth)
        .clamp(8.0, math.max(8.0, root.size.width - menuWidth - 8))
        .toDouble();
    final below = origin.dy + button.size.height + 3;
    final top =
        (below + menuHeight <= root.size.height - 8
                ? below
                : origin.dy - menuHeight - 3)
            .clamp(8.0, math.max(8.0, root.size.height - menuHeight - 8))
            .toDouble();
    _limitMenuEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeLimitMenu,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: menuWidth,
            height: menuHeight,
            child: Material(
              key: const ValueKey('tag-expansion-limit-menu'),
              elevation: 16,
              color: Theme.of(context).colorScheme.surface,
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.circular(7),
              child: Column(
                children: [
                  for (final option in _limitOptions)
                    SizedBox(
                      height: 36,
                      child: InkWell(
                        onTap: () => _setResultLimit(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                child: option == _resultLimit
                                    ? const Icon(Icons.check, size: 16)
                                    : null,
                              ),
                              Text('$option'),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_limitMenuEntry!);
  }

  void _queueSearch({bool immediate = false}) {
    _autoTranslation.clearSurface(_searchSurface);
    _searchVisible.clear();
    _debounce?.cancel();
    final sequence = ++_searchSequence;
    if (_searchController.text.trim().isEmpty) {
      _results = const [];
      _searchLoading = true;
      _searchFailed = false;
      _markNeedsBuild();
      unawaited(_runContextSuggestions(sequence));
      return;
    }
    _usingContext = false;
    _searchLoading = true;
    _searchFailed = false;
    _markNeedsBuild();
    if (immediate) {
      unawaited(_runSearch(sequence));
    } else {
      _debounce = Timer(
        const Duration(milliseconds: 150),
        () => unawaited(_runSearch(sequence)),
      );
    }
  }

  Future<void> _runContextSuggestions(int sequence) async {
    try {
      final service = ref.read(localTagExpansionServiceProvider);
      final locale = Localizations.localeOf(context).toLanguageTag();
      var results = _contextTag == null
          ? const <CompletionCandidate>[]
          : await service.related(
              _contextTag!,
              locale: locale,
              existingTags: _existingTags,
              limit: _resultLimit,
            );
      final usingContext = results.isNotEmpty;
      if (!usingContext) {
        results = await service.popular(
          locale: locale,
          existingTags: _existingTags,
          limit: _resultLimit,
        );
      }
      if (!mounted || !_active || sequence != _searchSequence) return;
      _results = results;
      _usingContext = usingContext;
      _selectedIndex = 0;
      _searchFailed = false;
    } catch (_) {
      if (!mounted || !_active || sequence != _searchSequence) return;
      _results = const [];
      _searchFailed = true;
    }
    _searchLoading = false;
    _markNeedsBuild();
  }

  Future<void> _runSearch(int sequence) async {
    try {
      final results = await ref
          .read(localTagExpansionServiceProvider)
          .search(
            _searchController.text,
            locale: Localizations.localeOf(context).toLanguageTag(),
            existingTags: _existingTags,
            limit: _resultLimit,
          );
      if (!mounted || !_active || sequence != _searchSequence) return;
      _results = results;
      _selectedIndex = 0;
      _searchFailed = false;
    } catch (_) {
      if (!mounted || !_active || sequence != _searchSequence) return;
      _results = const [];
      _searchFailed = true;
    }
    _searchLoading = false;
    _markNeedsBuild();
  }

  void _loadRelated(String tag) {
    _autoTranslation.clearSurface(_relatedSurface);
    _relatedVisible.clear();
    if (_relatedScroll.hasClients) _relatedScroll.jumpTo(0);
    _relatedTag = tag;
    _relatedResults = const [];
    _relatedLoading = true;
    _relatedFailed = false;
    final sequence = ++_relatedSequence;
    _markNeedsBuild();
    unawaited(() async {
      try {
        final results = await ref
            .read(localTagExpansionServiceProvider)
            .related(
              tag,
              locale: Localizations.localeOf(context).toLanguageTag(),
              existingTags: _existingTags,
            );
        if (!mounted || !_active || sequence != _relatedSequence) return;
        _relatedResults = results;
      } catch (_) {
        if (!mounted || !_active || sequence != _relatedSequence) return;
        _relatedResults = const [];
        _relatedFailed = true;
      }
      _relatedLoading = false;
      _markNeedsBuild();
    }());
  }

  void _openWiki(CompletionCandidate candidate) {
    ref.read(autoTagTranslationProvider).clearSurface(_wikiSurface);
    _wikiCandidate = candidate;
    _wikiEntry = null;
    _wikiLoading = true;
    _wikiFailed = false;
    if (_wikiScroll.hasClients) _wikiScroll.jumpTo(0);
    final sequence = ++_wikiSequence;
    _markNeedsBuild();
    unawaited(() async {
      try {
        final entry = await ref
            .read(tagWikiRepositoryProvider)
            .find(candidate.canonicalTag);
        if (!mounted || !_active || sequence != _wikiSequence) return;
        _wikiEntry = entry;
        if (entry != null && entry.body.trim().isNotEmpty) {
          ref
              .read(autoTagTranslationProvider)
              .requestWiki(
                surface: _wikiSurface,
                tag: candidate.canonicalTag,
                tagContext: AutoTagTranslationContext(
                  category: candidate.category.name,
                  aliases: candidate.aliases,
                  postCount: candidate.postCount,
                  relatedTo: _relatedTag ?? _contextTag,
                ),
              );
        }
      } catch (_) {
        if (!mounted || !_active || sequence != _wikiSequence) return;
        _wikiFailed = true;
      }
      _wikiLoading = false;
      _markNeedsBuild();
    }());
  }

  KeyEventResult _onSearchKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _close(restoreFocus: true);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab &&
        _results.isNotEmpty &&
        _searchController.value.composing.isCollapsed) {
      final completion = TagNormalizer.toDisplay(
        _results[_selectedIndex].canonicalTag,
      );
      if (completion != _searchController.text) {
        if (event is KeyDownEvent) {
          _searchController.value = TextEditingValue(
            text: completion,
            selection: TextSelection.collapsed(offset: completion.length),
          );
          _onSearchChanged(completion);
        }
        return KeyEventResult.handled;
      }
    }
    if (_results.isEmpty || !_searchController.value.composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    int? nextIndex;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      final delta = key == LogicalKeyboardKey.arrowDown
          ? _gridColumns
          : -_gridColumns;
      nextIndex = (_selectedIndex + delta).clamp(0, _results.length - 1);
    } else if (_gridColumns > 1 &&
        (key == LogicalKeyboardKey.arrowRight ||
            key == LogicalKeyboardKey.arrowLeft)) {
      final column = _selectedIndex % _gridColumns;
      final nextColumn =
          column + (key == LogicalKeyboardKey.arrowRight ? 1 : -1);
      nextIndex = nextColumn < 0 || nextColumn >= _gridColumns
          ? _selectedIndex
          : (_selectedIndex ~/ _gridColumns) * _gridColumns + nextColumn;
      if (nextIndex >= _results.length) nextIndex = _selectedIndex;
    }
    if (nextIndex != null) {
      if (nextIndex != _selectedIndex) {
        _selectedIndex = nextIndex;
        _markNeedsBuild();
        _scrollToSelected();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (event is KeyDownEvent) _insert(_results[_selectedIndex]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _scrollToSelected() {
    if (!_searchScroll.hasClients) return;
    final position = _searchScroll.position;
    if (!position.hasContentDimensions) return;
    final row = _selectedIndex ~/ _gridColumns;
    if (row >= _rowHeights.length) return;
    final top =
        _listInset +
        _rowHeights.take(row).fold<double>(0, (sum, height) => sum + height);
    final bottom = top + _rowHeights[row];
    final target = top < position.pixels
        ? top
        : bottom > position.pixels + position.viewportDimension
        ? bottom - position.viewportDimension
        : null;
    if (target == null) return;
    _searchScroll.jumpTo(target.clamp(0.0, position.maxScrollExtent));
  }

  void _insert(CompletionCandidate candidate) {
    if (candidate.isExisting || widget.controller.text != _openedText) {
      _close();
      return;
    }
    if (widget.onCandidateSelected case final selectCandidate?) {
      _close(restoreFocus: true);
      selectCandidate(candidate);
      return;
    }
    if (widget.onTagSelected case final selectTag?) {
      _close(restoreFocus: true);
      selectTag(candidate.canonicalTag);
      return;
    }
    final result = PromptTokenParser.insertAtCaret(
      text: widget.controller.text,
      cursorPosition: _insertionOffset,
      canonicalTag: candidate.canonicalTag,
      autoInsertComma: true,
    );
    _close(restoreFocus: true);
    if (result.text == widget.controller.text) return;
    widget.controller.value = TextEditingValue(
      text: result.text,
      selection: TextSelection.collapsed(offset: result.cursorPosition),
    );
    widget.onApplied?.call(result.text);
  }

  void _markNeedsBuild() => _entry?.markNeedsBuild();

  void _close({bool restoreFocus = false, bool notify = true}) {
    _surfaceEpoch++;
    _visibilityScheduled = false;
    _autoTranslation.clearSurface(_searchSurface);
    _autoTranslation.clearSurface(_relatedSurface);
    _autoTranslation.clearSurface(_wikiSurface);
    _searchVisible.clear();
    _relatedVisible.clear();
    _debounce?.cancel();
    _closeLimitMenu();
    _searchSequence++;
    _relatedSequence++;
    _wikiSequence++;
    final entry = _entry;
    _entry = null;
    entry?.remove();
    entry?.dispose();
    if (!_active) return;
    _active = false;
    if (restoreFocus) widget.focusNode?.requestFocus();
    if (notify) widget.onActiveChanged?.call(false);
  }

  TextStyle? _tagTitleStyle(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, height: 1.2);

  double _candidateHeight(
    BuildContext context,
    CompletionCandidate candidate,
    double cellWidth,
  ) {
    final titleWidth = math.max(
      1.0,
      cellWidth -
          12 -
          18 -
          TagTranslationIndicator.extent -
          (candidate.postCount > 0 ? 48 : 0),
    );
    final painter = TextPainter(
      text: TextSpan(
        text: TagNormalizer.toDisplay(candidate.canonicalTag),
        style: _tagTitleStyle(context),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: titleWidth);
    final lines = painter.computeLineMetrics().length;
    final lineHeight = math.max(
      TagTranslationIndicator.extent,
      (painter.height / math.max(1, lines)).ceilToDouble(),
    );
    painter.dispose();
    final detailPainter = TextPainter(
      text: TextSpan(
        text:
            _autoTranslation.nameFor(candidate.canonicalTag) ??
            candidate.translation ??
            (candidate.matchedAlias == null
                ? TagCategoryVisuals.label(context, candidate.category)
                : TagNormalizer.toDisplay(candidate.matchedAlias!)),
        style: Theme.of(context).textTheme.labelSmall,
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: titleWidth);
    final detailHeight = detailPainter.height;
    detailPainter.dispose();
    // Match the two actual text lines, row gap and padding. Theme fonts can
    // have taller metrics than the former fixed 16 px line assumption.
    return math.max(
          _compactRowHeight,
          math.max(lineHeight, detailHeight) + 2 + detailHeight + 14,
        ) +
        lineHeight * math.max(0, lines - 1);
  }

  List<double> _measureSearchRows(BuildContext context, double panelWidth) {
    final usableWidth = math.max(1.0, panelWidth - _listInset * 2);
    final cellWidth =
        (usableWidth - (_gridColumns - 1) * _columnGap) / _gridColumns;
    return List<double>.generate(
      (_results.length + _gridColumns - 1) ~/ _gridColumns,
      (row) {
        var height = _compactRowHeight;
        for (var column = 0; column < _gridColumns; column++) {
          final index = row * _gridColumns + column;
          if (index >= _results.length) break;
          height = math.max(
            height,
            _candidateHeight(context, _results[index], cellWidth),
          );
        }
        return height + 2;
      },
    );
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final root = Overlay.of(
      context,
      rootOverlay: true,
    ).context.findRenderObject();
    if (root is! RenderBox || !root.hasSize || _anchorGlobal == null) {
      return const SizedBox.shrink();
    }
    final screen = root.size;
    final anchor = root.globalToLocal(_anchorGlobal!);
    final hasRelated = _relatedTag != null;
    final relatedOnly = hasRelated && screen.width < 560;
    final width = math.min(
      480.0,
      math.max(0.0, screen.width - 16 - (hasRelated && !relatedOnly ? 226 : 0)),
    );
    final relatedWidth = relatedOnly
        ? width
        : math.min(240.0, math.max(0.0, screen.width - 19 - width));
    final combinedWidth =
        width + (hasRelated && !relatedOnly ? relatedWidth + _panelGap : 0);
    _gridColumns = width >= 380 ? 2 : 1;
    _rowHeights = _measureSearchRows(overlayContext, width);
    _relatedWidth = relatedWidth;
    _scheduleVisibleUpdate();
    final hasWiki = _wikiCandidate != null;
    final availableHeight = math.max(0.0, screen.height - 16);
    final desiredHeight =
        (103.0 + _rowHeights.fold<double>(0, (total, row) => total + row))
            .clamp(320.0, 460.0);
    final theme = Theme.of(overlayContext);
    final translatedWiki = _wikiCandidate == null
        ? null
        : ref
              .read(autoTagTranslationProvider)
              .wikiFor(_wikiCandidate!.canonicalTag);
    final wikiBody =
        (_showWikiTranslation ? translatedWiki : null) ??
        (_wikiCandidate == null
            ? null
            : _autoTranslation.wikiOriginalFor(_wikiCandidate!.canonicalTag)) ??
        _wikiEntry?.body ??
        (_wikiFailed
            ? overlayContext.l10n.common_error
            : overlayContext.l10n.tagExpansion_wikiUnavailable);
    final titleMeasure =
        TextPainter(
          text: TextSpan(
            text: hasWiki ? _wikiTitle(overlayContext) : '',
            style: theme.textTheme.labelMedium,
          ),
          textDirection: Directionality.of(overlayContext),
          textScaler: MediaQuery.textScalerOf(overlayContext),
        )..layout(
          maxWidth: math.max(1, width - 76 - TagTranslationIndicator.extent),
        );
    final headerHeight = math.max(28.0, titleMeasure.height) + 10;
    titleMeasure.dispose();
    final footerHeight = translatedWiki == null ? 0.0 : 36.0;
    final minimumWiki = headerHeight + footerHeight + 44;
    final measurementKey = (
      wikiBody,
      width - 24,
      MediaQuery.textScalerOf(overlayContext).scale(14),
      theme.textTheme.bodySmall,
    );
    final bodyMeasure = TextPainter(
      text: TextSpan(text: wikiBody, style: theme.textTheme.bodySmall),
      textDirection: Directionality.of(overlayContext),
      textScaler: MediaQuery.textScalerOf(overlayContext),
    )..layout(maxWidth: math.max(1, width - 32));
    final desiredWikiHeight = hasWiki
        ? (headerHeight +
                  footerHeight +
                  22 +
                  (_wikiMeasurementKey == measurementKey
                      ? _wikiMeasuredHeight!
                      : bodyMeasure.height))
              .clamp(minimumWiki, math.max(280.0, minimumWiki))
        : 0.0;
    bodyMeasure.dispose();
    // Reserve the article's preferred space before sizing the result list.
    // On short screens the list can scroll, while both panels stay visible.
    final reservedWikiHeight = math.min(
      desiredWikiHeight,
      math.max(minimumWiki, availableHeight - 200),
    );
    final height = math.min(
      desiredHeight,
      availableHeight - (hasWiki ? reservedWikiHeight + _panelGap : 0),
    );
    if (width <= 0 || height <= 0) return const SizedBox.shrink();
    final wikiHeight = math.min(
      desiredWikiHeight,
      math.max(0.0, availableHeight - height - _panelGap),
    );
    final totalHeight = height + (hasWiki ? wikiHeight + _panelGap : 0);
    final below = anchor.dy + 8;
    final top =
        (below + totalHeight <= screen.height - 8
                ? below
                : anchor.dy - totalHeight - 8)
            .clamp(8.0, math.max(8.0, screen.height - totalHeight - 8))
            .toDouble();
    final left = (anchor.dx - 48)
        .clamp(8.0, math.max(8.0, screen.width - combinedWidth - 8))
        .toDouble();
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        if (!relatedOnly)
          Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
            child: Material(
              key: const ValueKey('tag-expansion-popup'),
              elevation: 14,
              color: theme.colorScheme.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  _buildHeader(overlayContext),
                  const Divider(height: 1),
                  SizedBox(
                    height: math.max(
                      36,
                      MediaQuery.textScalerOf(
                            overlayContext,
                          ).scale(theme.textTheme.bodyMedium?.fontSize ?? 14) +
                          16,
                    ),
                    child: TextField(
                      key: const ValueKey('tag-expansion-search'),
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: _onSearchChanged,
                      style: theme.textTheme.bodyMedium,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: overlayContext.l10n.tagExpansion_searchHint,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        suffixIcon: _history.isEmpty
                            ? null
                            : IconButton(
                                key: const ValueKey('tag-expansion-back'),
                                tooltip: wikiBackLabel(overlayContext),
                                onPressed: _goBack,
                                icon: const Icon(Icons.undo, size: 18),
                              ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSearchAssist(overlayContext),
                  const Divider(height: 1),
                  Expanded(child: _buildSearchList(overlayContext)),
                ],
              ),
            ),
          ),
        if (hasRelated)
          Positioned(
            left: relatedOnly ? left : left + width + _panelGap,
            top: top,
            width: relatedWidth,
            height: height,
            child: Material(
              key: const ValueKey('tag-expansion-related-panel'),
              elevation: 14,
              color: theme.colorScheme.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${overlayContext.l10n.tagExpansion_relatedTitle} · ${TagNormalizer.toDisplay(_relatedTag!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: overlayContext.l10n.common_close,
                          onPressed: () {
                            _relatedSequence++;
                            _relatedTag = null;
                            _relatedResults = const [];
                            _autoTranslation.clearSurface(_relatedSurface);
                            _relatedVisible.clear();
                            _markNeedsBuild();
                          },
                          icon: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildRelatedList(overlayContext)),
                ],
              ),
            ),
          ),
        if (hasWiki && wikiHeight > 0)
          Positioned(
            left: left,
            top: top + height + _panelGap,
            width: width,
            height: wikiHeight.toDouble(),
            child: _buildWikiPanel(overlayContext),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) => SizedBox(
    height: 34,
    child: Row(
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.l10n.prompt_cooccurrenceRecommendation,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Builder(
          builder: (context) {
            final translation = ref.read(autoTagTranslationProvider);
            final label = context.l10n.tagExpansion_autoTranslateVisible;
            return IconButton(
              key: const ValueKey('tag-expansion-auto-translate'),
              tooltip: translation.activeRequests > 0
                  ? wikiTranslatingLabel(context)
                  : translation.lastError == null
                  ? label
                  : '$label · ${translation.lastError}',
              onPressed: () =>
                  unawaited(translation.setEnabled(!translation.enabled)),
              icon: TranslationIcon(
                busy: translation.activeRequests > 0,
                size: 16,
                color: translation.lastError != null
                    ? Theme.of(context).colorScheme.error
                    : translation.enabled
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              padding: EdgeInsets.zero,
            );
          },
        ),
        Container(
          key: const ValueKey('tag-expansion-header-separator'),
          width: 1,
          height: 13,
          margin: const EdgeInsets.only(left: 6, right: 8),
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        Text(
          context.l10n.tagExpansion_localOnly,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        IconButton(
          tooltip: context.l10n.common_close,
          onPressed: () => _close(restoreFocus: true),
          icon: const Icon(Icons.close, size: 16),
          visualDensity: VisualDensity.compact,
        ),
      ],
    ),
  );

  Widget _buildSearchAssist(BuildContext context) {
    final theme = Theme.of(context);
    final emptyQuery = _searchController.text.trim().isEmpty;
    final source = !emptyQuery
        ? ''
        : _usingContext && _contextTag != null
        ? '${context.l10n.tagExpansion_relatedTitle} · ${TagNormalizer.toDisplay(_contextTag!)}'
        : context.l10n.tagExpansion_popularSource;
    final selected = _results.isEmpty ? null : _results[_selectedIndex];
    final completion = selected == null
        ? null
        : TagNormalizer.toDisplay(selected.canonicalTag);
    final showCompletion =
        completion != null &&
        completion != _searchController.text &&
        !_searchLoading;
    return SizedBox(
      height: 26,
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Row(
          children: [
            if (source.isNotEmpty)
              Flexible(
                child: Text(
                  source,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const Spacer(),
            if (showCompletion) ...[
              Flexible(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${context.l10n.tagExpansion_tabComplete} $completion',
                    key: const ValueKey('tag-expansion-tab-hint'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 1,
                height: 14,
                color: theme.colorScheme.outlineVariant,
              ),
              const SizedBox(width: 6),
            ],
            SizedBox(
              key: _limitButtonKey,
              height: 24,
              child: Tooltip(
                message: context.l10n.autocomplete_resultLimit,
                child: InkWell(
                  key: const ValueKey('tag-expansion-result-limit'),
                  onTap: _toggleLimitMenu,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${context.l10n.autocomplete_resultLimit} $_resultLimit',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchList(BuildContext context) {
    if (_searchLoading && _results.isEmpty) return _loadingIndicator();
    if (_results.isEmpty) {
      return _message(
        _searchFailed
            ? context.l10n.common_error
            : _searchController.text.trim().isEmpty
            ? context.l10n.tagExpansion_empty
            : context.l10n.tagExpansion_noResults,
      );
    }
    return ListView.builder(
      key: const ValueKey('tag-expansion-results'),
      controller: _searchScroll,
      padding: const EdgeInsets.symmetric(horizontal: _listInset, vertical: 2),
      itemCount: _rowHeights.length,
      itemBuilder: (context, row) => ConstrainedBox(
        key: _rowKeys.putIfAbsent(row, GlobalKey.new),
        constraints: const BoxConstraints(minHeight: _compactRowHeight + 2),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var column = 0; column < _gridColumns; column++) ...[
                  if (column > 0) const SizedBox(width: _columnGap),
                  Expanded(
                    child: row * _gridColumns + column < _results.length
                        ? _candidateRow(
                            context,
                            _results[row * _gridColumns + column],
                            selected:
                                row * _gridColumns + column == _selectedIndex,
                            onTap: () {
                              final index = row * _gridColumns + column;
                              _selectedIndex = index;
                              _openWiki(_results[index]);
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRelatedList(BuildContext context) {
    if (_relatedLoading && _relatedResults.isEmpty) return _loadingIndicator();
    if (_relatedResults.isEmpty) {
      return _message(
        _relatedFailed
            ? context.l10n.common_error
            : context.l10n.tagExpansion_noResults,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => ListView.builder(
        key: const ValueKey('tag-expansion-related-results'),
        controller: _relatedScroll,
        padding: const EdgeInsets.symmetric(
          horizontal: _listInset,
          vertical: 2,
        ),
        itemCount: _relatedResults.length,
        itemBuilder: (context, index) => ConstrainedBox(
          key: _relatedRowKeys.putIfAbsent(index, GlobalKey.new),
          constraints: const BoxConstraints(minHeight: _compactRowHeight + 2),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _candidateRow(
              context,
              _relatedResults[index],
              related: true,
              onTap: () => _openWiki(_relatedResults[index]),
            ),
          ),
        ),
      ),
    );
  }

  void _scheduleVisibleUpdate() {
    if (_visibilityScheduled || !_active) return;
    _visibilityScheduled = true;
    final epoch = _surfaceEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityScheduled = false;
      if (!mounted || !_active || epoch != _surfaceEpoch) return;
      _refreshVisible();
    });
  }

  void _refreshVisible() {
    if (_searchScroll.hasClients && _rowHeights.isNotEmpty) {
      _rowHeights = [
        for (var row = 0; row < _rowHeights.length; row++)
          _rowKeys[row]?.currentContext?.size?.height ?? _rowHeights[row],
      ];
      final position = _searchScroll.position;
      final top = position.pixels;
      final bottom = top + position.viewportDimension;
      var cursor = 2.0;
      final visible = <String>{};
      for (var row = 0; row < _rowHeights.length; row++) {
        final next = cursor + _rowHeights[row];
        if (next > top && cursor < bottom) {
          for (var col = 0; col < _gridColumns; col++) {
            final index = row * _gridColumns + col;
            if (index < _results.length) {
              final candidate = _results[index];
              visible.add(candidate.canonicalTag);
              _autoTranslation.observe(
                surface: _searchSurface,
                tag: candidate.canonicalTag,
                visible: true,
                existingNameZh: candidate.translation,
                tagContext: AutoTagTranslationContext(
                  category: candidate.category.name,
                  aliases: candidate.aliases,
                  postCount: candidate.postCount,
                  relatedTo: _contextTag,
                ),
              );
            }
          }
        }
        cursor = next;
        if (cursor >= bottom) break;
      }
      for (final tag in _searchVisible.difference(visible)) {
        _autoTranslation.observe(
          surface: _searchSurface,
          tag: tag,
          visible: false,
        );
      }
      _searchVisible = visible;
    }
    if (_relatedScroll.hasClients && _relatedResults.isNotEmpty) {
      final position = _relatedScroll.position;
      final top = position.pixels;
      final bottom = top + position.viewportDimension;
      var cursor = 2.0;
      final visible = <String>{};
      for (final candidate in _relatedResults) {
        final height =
            _relatedRowKeys[_relatedResults.indexOf(candidate)]
                ?.currentContext
                ?.size
                ?.height ??
            (_candidateHeight(
                  context,
                  candidate,
                  _relatedWidth - _listInset * 2,
                ) +
                2);
        final next = cursor + height;
        if (next > top && cursor < bottom) {
          visible.add(candidate.canonicalTag);
          _autoTranslation.observe(
            surface: _relatedSurface,
            tag: candidate.canonicalTag,
            visible: true,
            existingNameZh: candidate.translation,
            tagContext: AutoTagTranslationContext(
              category: candidate.category.name,
              aliases: candidate.aliases,
              postCount: candidate.postCount,
              relatedTo: _relatedTag,
            ),
          );
        }
        cursor = next;
        if (cursor >= bottom) break;
      }
      for (final tag in _relatedVisible.difference(visible)) {
        _autoTranslation.observe(
          surface: _relatedSurface,
          tag: tag,
          visible: false,
        );
      }
      _relatedVisible = visible;
    }
  }

  Widget _candidateRow(
    BuildContext context,
    CompletionCandidate candidate, {
    required VoidCallback onTap,
    bool selected = false,
    bool related = false,
  }) {
    final theme = Theme.of(context);
    final translation =
        ref.read(autoTagTranslationProvider).nameFor(candidate.canonicalTag) ??
        candidate.translation;
    final alias = candidate.matchedAlias;
    final detail = translation?.isNotEmpty == true
        ? translation!
        : alias != null
        ? TagNormalizer.toDisplay(alias)
        : TagCategoryVisuals.label(context, candidate.category);
    final id = '${related ? 'related' : 'search'}:${candidate.stableId}';
    final showActions = _hoveredId == id || _focusedId == id;
    return MouseRegion(
      onEnter: (_) {
        _hoveredId = id;
        _markNeedsBuild();
      },
      onExit: (_) {
        if (_hoveredId == id) _hoveredId = null;
        _markNeedsBuild();
      },
      child: Focus(
        onFocusChange: (focused) {
          _focusedId = focused ? id : (_focusedId == id ? null : _focusedId);
          _markNeedsBuild();
        },
        child: Material(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TagCandidateTitle(
                              title: TagNormalizer.toDisplay(
                                candidate.canonicalTag,
                              ),
                              category: candidate.category,
                              maxLines: null,
                              trailing: TagTranslationIndicator(
                                tag: candidate.canonicalTag,
                                surface: related
                                    ? _relatedSurface
                                    : _searchSurface,
                              ),
                              iconKey: ValueKey(
                                'tag-expansion-category-${candidate.category.name}',
                              ),
                              style: _tagTitleStyle(context)?.copyWith(
                                color: candidate.isExisting
                                    ? theme.colorScheme.onSurfaceVariant
                                    : null,
                              ),
                            ),
                          ),
                          if (candidate.postCount > 0) ...[
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 44,
                              child: Text(
                                _formatCount(candidate.postCount),
                                textAlign: TextAlign.right,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: EdgeInsets.only(right: showActions ? 42 : 0),
                        child: Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: AnimatedOpacity(
                      opacity: showActions ? 1 : 0,
                      duration: const Duration(milliseconds: 100),
                      child: IgnorePointer(
                        ignoring: !showActions,
                        child: Row(
                          children: [
                            _rowAction(
                              tooltip: context.l10n.tagExpansion_showRelated,
                              icon: const RelatedTagsIcon(size: 14),
                              onPressed: () =>
                                  _loadRelated(candidate.canonicalTag),
                            ),
                            _rowAction(
                              tooltip: context.l10n.tagExpansion_insert,
                              icon: const Icon(Icons.add, size: 13),
                              onPressed: candidate.isExisting
                                  ? null
                                  : () => _insert(candidate),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rowAction({
    required String tooltip,
    required Widget icon,
    required VoidCallback? onPressed,
  }) => SizedBox(
    width: 20,
    height: 18,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 20, height: 18),
      iconSize: 13,
      icon: icon,
    ),
  );

  Widget _buildWikiPanel(BuildContext context) {
    final theme = Theme.of(context);
    final candidate = _wikiCandidate!;
    final autoTranslation = ref.read(autoTagTranslationProvider);
    final translated = autoTranslation.wikiFor(candidate.canonicalTag);
    return Material(
      key: const ValueKey('tag-expansion-wiki-panel'),
      elevation: 14,
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _wikiTitle(context),
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                      TagTranslationIndicator(
                        tag: candidate.canonicalTag,
                        surface: _wikiSurface,
                        wiki: true,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.wiki_openFull,
                  onPressed: () {
                    final route = Uri(
                      path: AppRoutes.tagWiki,
                      queryParameters: {'tag': candidate.canonicalTag},
                    ).toString();
                    final router = GoRouter.of(context);
                    _close();
                    router.go(route);
                  },
                  icon: const Icon(Icons.open_in_new, size: 15),
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 28,
                  ),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  tooltip: context.l10n.common_close,
                  onPressed: () {
                    _wikiSequence++;
                    _wikiCandidate = null;
                    _wikiEntry = null;
                    ref
                        .read(autoTagTranslationProvider)
                        .clearSurface(_wikiSurface);
                    _markNeedsBuild();
                  },
                  icon: const Icon(Icons.close, size: 16),
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 28,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _wikiLoading
                ? _loadingIndicator()
                : SingleChildScrollView(
                    key: const ValueKey('tag-expansion-wiki-scroll'),
                    controller: _wikiScroll,
                    padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final body =
                            (_showWikiTranslation ? translated : null) ??
                            autoTranslation.wikiOriginalFor(
                              candidate.canonicalTag,
                            ) ??
                            _wikiEntry?.body ??
                            (_wikiFailed
                                ? context.l10n.common_error
                                : context.l10n.tagExpansion_wikiUnavailable);
                        final key = (
                          body,
                          constraints.maxWidth,
                          MediaQuery.textScalerOf(context).scale(14),
                          theme.textTheme.bodySmall,
                        );
                        return _WikiBodySizeReporter(
                          key: ValueKey(key),
                          onSize: (size) {
                            if (!mounted ||
                                (_wikiMeasurementKey == key &&
                                    _wikiMeasuredHeight == size.height)) {
                              return;
                            }
                            _wikiMeasurementKey = key;
                            _wikiMeasuredHeight = size.height;
                            _markNeedsBuild();
                          },
                          child: WikiLinkedBody(
                            body: body,
                            style: theme.textTheme.bodySmall,
                            onTagTap: _visitTag,
                          ),
                        );
                      },
                    ),
                  ),
          ),
          if (translated != null && !_wikiLoading)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 4),
                child: WikiArticleActions(
                  tag: candidate.canonicalTag,
                  surface: _wikiSurface,
                  showTranslation: _showWikiTranslation,
                  onToggle: () {
                    _showWikiTranslation = !_showWikiTranslation;
                    _markNeedsBuild();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _wikiTitle(BuildContext context) {
    final candidate = _wikiCandidate!;
    final translatedName =
        _autoTranslation.nameFor(candidate.canonicalTag) ??
        candidate.translation;
    return '${context.l10n.tagExpansion_wikiTitle} · ${TagNormalizer.toDisplay(candidate.canonicalTag)}${translatedName == null || translatedName.isEmpty ? '' : ' · $translatedName'}';
  }

  static String _formatCount(int count) => count >= 1000000
      ? '${(count / 1000000).toStringAsFixed(1)}m'
      : count >= 1000
      ? '${(count / 1000).toStringAsFixed(1)}k'
      : '$count';

  Widget _loadingIndicator() => const Center(
    child: SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );

  Widget _message(String message) =>
      Center(child: Text(message, textAlign: TextAlign.center));

  @override
  Widget build(BuildContext context) {
    ref.listen<AutocompleteSettings>(autocompleteSettingsProvider, (_, next) {
      if (!next.relatedTagsEnabled) _close();
    });
    return SizedBox(
      key: _anchorKey,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onEditorChanged);
    _autoTranslation.removeListener(_markNeedsBuild);
    _close(notify: false);
    _searchScroll.dispose();
    _relatedScroll.dispose();
    _wikiScroll.dispose();
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

/// Measures the rendered Markdown, including heading and list spacing.
class _WikiBodySizeReporter extends SingleChildRenderObjectWidget {
  const _WikiBodySizeReporter({
    super.key,
    required this.onSize,
    required super.child,
  });
  final ValueChanged<Size> onSize;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _WikiBodySizeRender(onSize);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant _WikiBodySizeRender renderObject,
  ) {
    renderObject.onSize = onSize;
  }
}

class _WikiBodySizeRender extends RenderProxyBox {
  _WikiBodySizeRender(this.onSize);
  ValueChanged<Size> onSize;
  Size? _last;
  @override
  void performLayout() {
    super.performLayout();
    if (size == _last) return;
    _last = size;
    final measured = size, callback = onSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) callback(measured);
    });
  }
}
