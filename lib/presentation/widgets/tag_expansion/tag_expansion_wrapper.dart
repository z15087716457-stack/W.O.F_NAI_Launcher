import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/autocomplete/autocomplete_settings.dart';
import '../../../core/autocomplete/completion_models.dart';
import '../../../core/autocomplete/prompt_token_parser.dart';
import '../../../core/tag_expansion/tag_expansion_providers.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/tag_normalizer.dart';
import '../../../core/wiki/tag_wiki_repository.dart';

/// Explicit, local-only tag search for prompt editors. It does not listen to
/// typed prompt text and never enters the old autocomplete query pipeline.
class TagExpansionWrapper extends ConsumerStatefulWidget {
  const TagExpansionWrapper({
    super.key,
    required this.child,
    required this.controller,
    this.focusNode,
    this.enabled = true,
    this.onApplied,
    this.onActiveChanged,
  });

  final Widget child;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final ValueChanged<String>? onApplied;
  final ValueChanged<bool>? onActiveChanged;

  @override
  ConsumerState<TagExpansionWrapper> createState() =>
      _TagExpansionWrapperState();
}

class _TagExpansionWrapperState extends ConsumerState<TagExpansionWrapper>
    with WidgetsBindingObserver {
  final _anchorKey = GlobalKey(debugLabel: 'tag-expansion-anchor');
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _searchScroll = ScrollController();
  Timer? _debounce;
  OverlayEntry? _entry;
  Offset? _pointerDown;
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
  String? _hoveredId;
  String? _focusedId;
  String? _contextTag;
  bool _usingContext = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onEditorChanged);
    _searchFocus.onKeyEvent = _onSearchKey;
  }

  @override
  void didChangeMetrics() => _markNeedsBuild();

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
    _pointerDown = event.position;
    final keyboard = HardwareKeyboard.instance;
    _controlAtDown = keyboard.isControlPressed || keyboard.isMetaPressed;
  }

  void _onPointerUp(PointerUpEvent event) {
    final control = _controlAtDown;
    final moved =
        _pointerDown != null && (event.position - _pointerDown!).distance > 4;
    _pointerDown = null;
    _controlAtDown = false;
    if (!control || !widget.enabled) return;
    if (!ref.read(autocompleteSettingsProvider).relatedTagsEnabled) return;

    // EditableText finalizes its selection after the pointer callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.enabled) return;
      final selection = widget.controller.selection;
      if (!selection.isValid) return;
      if (moved && selection.isCollapsed) return;
      final selectedText = moved
          ? widget.controller.text.substring(selection.start, selection.end)
          : '';
      final selectedQuery = selectedText.trim();
      final source = moved
          ? _selectedTag(widget.controller.text, selection)
          : null;
      final offset = selection.extentOffset.clamp(
        0,
        widget.controller.text.length,
      );
      final contextTag = moved
          ? null
          : PromptTokenParser.parseRelated(
              text: widget.controller.text,
              cursorPosition: offset,
              limit: 1,
              locale: Localizations.localeOf(context).toLanguageTag(),
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
    );
    _existingTags = {
      ...parsed.existingTags,
      if (parsed.kind == CompletionQueryKind.tag && parsed.token.isNotEmpty)
        parsed.token,
    };
    final caret = _caretOffset(anchor!, anchorBox);
    _anchorGlobal = anchorBox.localToGlobal(caret);
    _searchController.text = TagNormalizer.toDisplay(query);
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
    _relatedSequence++;
    _relatedTag = null;
    _relatedResults = const [];
    _relatedLoading = false;
    _wikiSequence++;
    _wikiCandidate = null;
    _wikiEntry = null;
    _queueSearch();
  }

  void _queueSearch({bool immediate = false}) {
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
              limit: 12,
            );
      final usingContext = results.isNotEmpty;
      if (!usingContext) {
        results = await service.popular(
          locale: locale,
          existingTags: _existingTags,
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
    _wikiCandidate = candidate;
    _wikiEntry = null;
    _wikiLoading = true;
    _wikiFailed = false;
    final sequence = ++_wikiSequence;
    _markNeedsBuild();
    unawaited(() async {
      try {
        final entry = await ref
            .read(tagWikiRepositoryProvider)
            .find(candidate.canonicalTag);
        if (!mounted || !_active || sequence != _wikiSequence) return;
        _wikiEntry = entry;
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
    if (_results.isEmpty) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final delta = event.logicalKey == LogicalKeyboardKey.arrowDown
          ? _gridColumns
          : -_gridColumns;
      _selectedIndex = (_selectedIndex + delta).clamp(0, _results.length - 1);
      _markNeedsBuild();
      _scrollToSelected();
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
    final top = (_selectedIndex ~/ _gridColumns) * 66.0;
    final bottom = top + 66;
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
    _debounce?.cancel();
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
        : math.min(240.0, math.max(0.0, screen.width - 22 - width));
    final combinedWidth =
        width + (hasRelated && !relatedOnly ? relatedWidth + 6 : 0);
    final hasWiki = _wikiCandidate != null;
    final availableHeight = math.max(0.0, screen.height - 16);
    final height = math.min(460.0, availableHeight - (hasWiki ? 96 : 0));
    if (width <= 0 || height <= 0) return const SizedBox.shrink();
    final theme = Theme.of(overlayContext);
    final wikiBody =
        _wikiEntry?.body ??
        (_wikiFailed
            ? overlayContext.l10n.common_error
            : overlayContext.l10n.tagExpansion_wikiUnavailable);
    final bodyMeasure = TextPainter(
      text: TextSpan(text: wikiBody, style: theme.textTheme.bodySmall),
      textDirection: Directionality.of(overlayContext),
      textScaler: MediaQuery.textScalerOf(overlayContext),
    )..layout(maxWidth: math.max(1, width - 32));
    final wikiHeight = hasWiki
        ? math.min(
            (68 + bodyMeasure.height).clamp(90.0, 230.0),
            math.max(0.0, availableHeight - height - 6),
          )
        : 0.0;
    bodyMeasure.dispose();
    final totalHeight = height + (hasWiki ? wikiHeight + 6 : 0);
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
                    height: 44,
                    child: TextField(
                      key: const ValueKey('tag-expansion-search'),
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: overlayContext.l10n.tagExpansion_searchHint,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
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
            left: relatedOnly ? left : left + width + 6,
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
            top: top + height + 6,
            width: width,
            height: wikiHeight,
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
        Text(
          context.l10n.prompt_cooccurrenceRecommendation,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const Spacer(),
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
            if (showCompletion)
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
    return LayoutBuilder(
      builder: (context, constraints) {
        _gridColumns = constraints.maxWidth >= 380 ? 2 : 1;
        return GridView.builder(
          key: const ValueKey('tag-expansion-results'),
          controller: _searchScroll,
          padding: const EdgeInsets.all(3),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridColumns,
            mainAxisExtent: 64,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
          ),
          itemCount: _results.length,
          itemBuilder: (context, index) => _candidateRow(
            context,
            _results[index],
            selected: index == _selectedIndex,
            onTap: () {
              _selectedIndex = index;
              _openWiki(_results[index]);
            },
          ),
        );
      },
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
    return ListView.builder(
      key: const ValueKey('tag-expansion-related-results'),
      itemExtent: 64,
      itemCount: _relatedResults.length,
      itemBuilder: (context, index) => _candidateRow(
        context,
        _relatedResults[index],
        related: true,
        onTap: () => _openWiki(_relatedResults[index]),
      ),
    );
  }

  Widget _candidateRow(
    BuildContext context,
    CompletionCandidate candidate, {
    required VoidCallback onTap,
    bool selected = false,
    bool related = false,
  }) {
    final theme = Theme.of(context);
    final translation = candidate.translation;
    final alias = candidate.matchedAlias;
    final detail = translation?.isNotEmpty == true
        ? translation!
        : alias != null
        ? TagNormalizer.toDisplay(alias)
        : _categoryLabel(context, candidate.category);
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
              padding: const EdgeInsets.fromLTRB(9, 4, 6, 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TagNormalizer.toDisplay(candidate.canonicalTag),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      color: candidate.isExisting
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (candidate.postCount > 0)
                        Text(
                          _formatCount(candidate.postCount),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(width: 3),
                      SizedBox(
                        width: 52,
                        height: 26,
                        child: AnimatedOpacity(
                          opacity: showActions ? 1 : 0,
                          duration: const Duration(milliseconds: 100),
                          child: IgnorePointer(
                            ignoring: !showActions,
                            child: Row(
                              children: [
                                _rowAction(
                                  tooltip:
                                      context.l10n.tagExpansion_showRelated,
                                  icon: Icons.hub_outlined,
                                  onPressed: () =>
                                      _loadRelated(candidate.canonicalTag),
                                ),
                                _rowAction(
                                  tooltip: context.l10n.tagExpansion_insert,
                                  icon: Icons.add,
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
    required IconData icon,
    required VoidCallback? onPressed,
  }) => SizedBox(
    width: 26,
    height: 26,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      iconSize: 16,
      icon: Icon(icon),
    ),
  );

  Widget _buildWikiPanel(BuildContext context) {
    final theme = Theme.of(context);
    final candidate = _wikiCandidate!;
    final translatedName = candidate.translation;
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
          SizedBox(
            height: 42,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${context.l10n.tagExpansion_wikiTitle} · ${TagNormalizer.toDisplay(candidate.canonicalTag)}${translatedName == null || translatedName.isEmpty ? '' : ' · $translatedName'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.common_close,
                  onPressed: () {
                    _wikiSequence++;
                    _wikiCandidate = null;
                    _wikiEntry = null;
                    _markNeedsBuild();
                  },
                  icon: const Icon(Icons.close, size: 16),
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
                    padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
                    child: SelectableText(
                      _wikiEntry?.body ??
                          (_wikiFailed
                              ? context.l10n.common_error
                              : context.l10n.tagExpansion_wikiUnavailable),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static String _formatCount(int count) => count >= 1000000
      ? '${(count / 1000000).toStringAsFixed(1)}m'
      : count >= 1000
      ? '${(count / 1000).toStringAsFixed(1)}k'
      : '$count';

  static String _categoryLabel(BuildContext context, TagCategory category) =>
      switch (category) {
        TagCategory.general => context.l10n.autocomplete_categoryGeneral,
        TagCategory.artist => context.l10n.autocomplete_categoryArtist,
        TagCategory.copyright => context.l10n.autocomplete_categoryCopyright,
        TagCategory.character => context.l10n.autocomplete_categoryCharacter,
        TagCategory.meta => context.l10n.autocomplete_categoryMeta,
        TagCategory.contributor =>
          context.l10n.autocomplete_categoryContributor,
        TagCategory.species => context.l10n.autocomplete_categorySpecies,
        TagCategory.lore => context.l10n.autocomplete_categoryLore,
        TagCategory.library => context.l10n.autocomplete_categoryLibrary,
      };

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
        onPointerUp: _onPointerUp,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onEditorChanged);
    _close(notify: false);
    _searchScroll.dispose();
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
