import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart'
    show
        GestureBinding,
        PointerScrollEvent,
        PointerSignalEvent,
        kBackMouseButton,
        kForwardMouseButton;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/autocomplete/autocomplete_providers.dart';
import '../../../core/autocomplete/completion_models.dart';
import '../../../core/tag_expansion/tag_expansion_providers.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/tag_normalizer.dart';
import '../../../core/wiki/tag_wiki_repository.dart';
import '../../../core/wiki/auto_tag_translation_controller.dart';
import '../../../core/wiki/wiki_bilingual.dart';
import '../../../core/wiki/wiki_bookmark_store.dart';
import '../../../core/wiki/wiki_directory.dart';
import '../../../core/wiki/wiki_directory_labels.dart';
import '../../../core/wiki/wiki_example_repository.dart';
import '../../providers/data_source_cache_provider.dart';
import '../../themes/studio_typography.dart';
import '../../wiring/blocks_edit_wiring.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/prototype_typography_scope.dart';
import '../../widgets/common/studio_icons.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../../widgets/autocomplete/tag_category_visuals.dart';
import 'wiki_sidebar.dart';
import 'wiki_tag_preview.dart';
import 'wiki_tag_row.dart';
import 'wiki_article_outline.dart';
import '../../widgets/common/translation_icon.dart';
import '../../widgets/common/wiki_linked_body.dart';
import '../../widgets/common/wiki_retranslate_button.dart';

/// Which body the article pane shows: source only, translation only, or the
/// two interleaved block by block.
enum WikiReadingMode { original, translation, bilingual }

class _WikiVisit {
  const _WikiVisit({
    required this.query,
    required this.scope,
    required this.category,
    required this.hasArticle,
    required this.alphabetical,
    required this.searchAll,
    required this.selected,
    required this.items,
    required this.article,
    required this.total,
    required this.more,
    required this.loading,
    required this.loadError,
    required this.listOffset,
    required this.articleOffset,
    required this.readingMode,
    required this.linkedCandidate,
  });
  final TextEditingValue query;
  final WikiScope? scope;
  final TagCategory? category;
  final bool? hasArticle;
  final bool alphabetical, searchAll, more, loading;
  final WikiReadingMode readingMode;
  final String selected;
  final String? loadError;
  final List<CompletionCandidate> items;
  final Future<TagWikiEntry?>? article;
  final int? total;
  final double listOffset, articleOffset;
  final CompletionCandidate? linkedCandidate;
}

class TagWikiScreen extends StatelessWidget {
  const TagWikiScreen({super.key, this.initialTag, this.directory});

  final String? initialTag;
  final WikiDirectory? directory;

  @override
  Widget build(BuildContext context) => PrototypeTypographyScope(
    family: StudioTypography.cjk,
    height: 0, // CSS normal: use the face's intrinsic line metrics.
    child: _TagWikiContents(initialTag: initialTag, directory: directory),
  );
}

class _TagWikiContents extends ConsumerStatefulWidget {
  const _TagWikiContents({this.initialTag, this.directory});
  final String? initialTag;
  final WikiDirectory? directory;

  @override
  ConsumerState<_TagWikiContents> createState() => _TagWikiScreenState();
}

class _TagWikiScreenState extends ConsumerState<_TagWikiContents> {
  static const _pageSize = 80;
  final _search = TextEditingController();
  // The node's own key handler runs before EditableText shortcuts consume
  // arrows, so ↑/↓ keep moving the list selection while the field has focus.
  late final _searchFocus = FocusNode(onKeyEvent: _onSearchKey);
  final _listScroll = ScrollController();
  final _articleScroll = ScrollController();
  final _history = <_WikiVisit>[];
  final _forward = <_WikiVisit>[];
  CompletionCandidate? _linkedCandidate;
  double? _restoreArticleOffset;
  late final AutoTagTranslationController _autoTranslation;
  bool _visibilityScheduled = false;
  Set<String> _listVisible = {};
  late final String _listSurface = 'tag-wiki-list-${identityHashCode(this)}';
  late final String _articleSurface =
      'tag-wiki-article-${identityHashCode(this)}';
  Timer? _searchTimer;
  WikiDirectory? _directory;
  WikiScope? _scope;
  TagCategory? _category;
  bool? _hasArticle;
  bool _alphabetical = false;
  bool _searchAll = false;
  bool _loading = false;
  bool _more = false;
  bool _singlePane = false;
  bool _compactNavigation = false;
  bool _showCompactArticle = false;
  String? _outlineBody;
  String? _outlineTag;
  List<WikiArticleHeading> _headings = [];
  final _articleStart = GlobalKey();
  final _relatedAnchor = GlobalKey();
  final _directoryAnchor = GlobalKey();
  final _articleViewport = GlobalKey();
  final _toolbarKey = GlobalKey();
  final _resultsToolbarKey = GlobalKey();
  double _toolbarHeight = 47;
  double _resultsToolbarHeight = 94;
  final _typeFilterScroll = ScrollController();
  bool _typeFilterOverflows = false;
  bool _savingTagToBlock = false;
  bool _headerScheduled = false;
  GlobalKey? _activeOutline;
  GlobalKey? _clampedOutline;
  double? _clampedOutlineOffset;
  bool _outlineScheduled = false;
  bool _wideArticle = false;
  WikiReadingMode _readingMode = WikiReadingMode.translation;
  WikiTagPreviewHost? _preview;
  double _fontSize = 14;
  int _epoch = 0;
  int? _total;
  String? _selected;
  String? _loadError;
  List<CompletionCandidate> _items = const [];
  Future<TagWikiEntry?>? _article;
  TagWikiEntry? _articleEntry;
  Set<String>? _articleTags;
  final _relatedRequested = <String>{};
  final _relatedItems = <String, List<CompletionCandidate>>{};

  @override
  void initState() {
    super.initState();
    _autoTranslation = ref.read(autoTagTranslationProvider);
    _listScroll.addListener(_scheduleVisibleUpdate);
    _articleScroll.addListener(_onArticleScroll);
    _searchFocus.addListener(_onSearchFocusChange);
    _initialize();
  }

  void _onSearchFocusChange() {
    if (mounted) setState(() {});
  }

  Future<void> _initialize() async {
    try {
      final directory = widget.directory ?? await WikiDirectory.load();
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _directory = directory;
        _scope = WikiScope(WikiScopeKind.all, null, context.l10n.wiki_allTags);
        _fontSize = prefs.getDouble('wiki_text_size') ?? 14;
        _wideArticle = prefs.getBool('wiki_wide_article') ?? false;
        _readingMode = (prefs.getBool('wiki_show_translation') ?? true)
            ? (prefs.getBool('wiki_bilingual') ?? false)
                  ? WikiReadingMode.bilingual
                  : WikiReadingMode.translation
            : WikiReadingMode.original;
      });
      if (widget.initialTag case final tag?) {
        final normalized = TagNormalizer.normalize(tag);
        _search.text = TagNormalizer.toDisplay(normalized);
        _selectTag(normalized, remember: false);
      }
      await _load();
    } catch (error) {
      if (mounted) setState(() => _loadError = '$error');
    }
  }

  @override
  void didUpdateWidget(covariant _TagWikiContents oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTag == oldWidget.initialTag ||
        _directory == null ||
        widget.initialTag == null) {
      return;
    }
    final tag = TagNormalizer.normalize(widget.initialTag!);
    _search.text = TagNormalizer.toDisplay(tag);
    _scope = WikiScope(WikiScopeKind.all, null, context.l10n.wiki_allTags);
    _category = null;
    _hasArticle = null;
    _history.clear();
    _forward.clear();
    _selectTag(tag, remember: false);
    _load();
  }

  @override
  void dispose() {
    _autoTranslation.clearSurface(_listSurface);
    _autoTranslation.clearSurface(_articleSurface);
    _searchTimer?.cancel();
    _searchFocus.dispose();
    _search.dispose();
    _listScroll.dispose();
    _articleScroll.dispose();
    _typeFilterScroll.dispose();
    _preview?.dispose();
    super.dispose();
  }

  void _selectScope(WikiScope scope) {
    if (_scope?.matches(scope) == true) return;
    setState(() {
      _scope = scope;
      _searchAll = false;
      _selected = null;
      _article = null;
      _articleEntry = null;
      _forward.clear();
    });
    ref.read(autoTagTranslationProvider).clearSurface(_articleSurface);
    if (_listScroll.hasClients) _listScroll.jumpTo(0);
    _load();
  }

  _WikiVisit _snapshot() => _WikiVisit(
    query: _search.value,
    scope: _scope,
    category: _category,
    hasArticle: _hasArticle,
    alphabetical: _alphabetical,
    searchAll: _searchAll,
    selected: _selected!,
    items: _items,
    article: _article,
    total: _total,
    more: _more,
    loading: _loading,
    loadError: _loadError,
    readingMode: _readingMode,
    listOffset: _listScroll.hasClients ? _listScroll.offset : 0,
    articleOffset: _articleScroll.hasClients ? _articleScroll.offset : 0,
    linkedCandidate: _linkedCandidate,
  );

  void _selectTag(
    String tag, {
    bool remember = true,
    bool reveal = true,
    CompletionCandidate? linkedCandidate,
  }) {
    _preview?.dismiss();
    if (_selected == tag) {
      if (reveal && !_showCompactArticle) {
        setState(() => _showCompactArticle = true);
      }
      return;
    }
    if (remember && _selected != null) {
      _history.add(_snapshot());
      _forward.clear();
    }
    _linkedCandidate = linkedCandidate;
    _restoreArticleOffset = null;
    if (_articleScroll.hasClients) _articleScroll.jumpTo(0);
    ref.read(autoTagTranslationProvider).clearSurface(_articleSurface);
    final article = ref.read(tagWikiRepositoryProvider).find(tag);
    setState(() {
      _selected = tag;
      _showCompactArticle = reveal;
      _article = article;
      _articleEntry = null;
    });
    _loadRelated(tag);
    unawaited(
      article.then((entry) {
        if (!mounted || _selected != tag) return;
        setState(() => _articleEntry = entry);
        if (entry?.body.trim().isNotEmpty != true) {
          return;
        }
        ref
            .read(autoTagTranslationProvider)
            .requestWiki(
              surface: _articleSurface,
              tag: tag,
              tagContext: _items
                  .where((item) => item.canonicalTag == tag)
                  .map(
                    (item) => AutoTagTranslationContext(
                      category: item.category.name,
                      aliases: item.aliases,
                      postCount: item.postCount,
                    ),
                  )
                  .firstOrNull,
            );
      }, onError: (Object _) {}),
    );
  }

  void _applyVisit(_WikiVisit visit) {
    _searchTimer?.cancel();
    _epoch++;
    _preview?.dismiss();
    _autoTranslation.clearSurface(_listSurface);
    _autoTranslation.clearSurface(_articleSurface);
    _listVisible.clear();
    setState(() {
      _search.value = visit.query;
      _scope = visit.scope;
      _category = visit.category;
      _hasArticle = visit.hasArticle;
      _alphabetical = visit.alphabetical;
      _searchAll = visit.searchAll;
      _selected = visit.selected;
      _items = visit.items;
      _article = visit.article;
      _articleEntry = null;
      _total = visit.total;
      _more = visit.more;
      _loading = false;
      _loadError = visit.loadError;
      _readingMode = visit.readingMode;
      _linkedCandidate = visit.linkedCandidate;
      _restoreArticleOffset = visit.articleOffset;
    });
    if (visit.loading) _load();
    _saveReadingSettings();
    _loadRelated(visit.selected);
    _article?.then((entry) {
      if (!mounted || _selected != visit.selected) return;
      setState(() => _articleEntry = entry);
      if (entry != null) {
        _autoTranslation.requestWiki(
          surface: _articleSurface,
          tag: visit.selected,
        );
      }
    }, onError: (Object _) {});
    final epoch = _epoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || epoch != _epoch || _selected != visit.selected) return;
      if (_listScroll.hasClients) {
        _listScroll.jumpTo(
          visit.listOffset.clamp(0, _listScroll.position.maxScrollExtent),
        );
      }
      _scheduleVisibleUpdate();
    });
  }

  void _goBack() {
    if (_history.isEmpty) return;
    final visit = _history.removeLast();
    if (_selected != null) _forward.add(_snapshot());
    _applyVisit(visit);
  }

  void _goForward() {
    if (_forward.isEmpty) return;
    final visit = _forward.removeLast();
    if (_selected != null) _history.add(_snapshot());
    _applyVisit(visit);
  }

  Set<String>? _scopeTags() {
    final scope = _scope;
    if (scope == null || _searchAll) return null;
    final bookmarks = ref.read(wikiBookmarkStoreProvider);
    return switch (scope.kind) {
      WikiScopeKind.all => null,
      WikiScopeKind.bookmarks => bookmarks.tagsIn(null),
      WikiScopeKind.collection => bookmarks.tagsIn(scope.id),
      WikiScopeKind.directory => _directory!.tagsForNode(scope.node!),
    };
  }

  Future<List<CompletionCandidate>> _searchCandidates(String text) async {
    final source = ref.read(unifiedTagRepositoryProvider);
    final normalized = TagNormalizer.normalize(text);
    final query = CompletionQuery(
      fullText: text,
      cursorPosition: text.length,
      token: normalized,
      replacementRange: TextReplacementRange(start: 0, end: text.length),
      existingTags: const {},
      limit: 500,
      locale: Localizations.localeOf(context).toLanguageTag(),
    );
    final prefix = await source.search(query);
    final contains = await source.searchContains(normalized, limit: 100);
    final byName = <String, CompletionCandidate>{
      for (final candidate in contains) candidate.canonicalTag: candidate,
      for (final candidate in prefix) candidate.canonicalTag: candidate,
    };
    return byName.values.toList();
  }

  Future<void> _load({bool append = false}) async {
    if (_directory == null || _scope == null || (append && !_more)) return;
    if (!append) {
      _autoTranslation.clearSurface(_listSurface);
      _listVisible.clear();
    }
    final epoch = ++_epoch;
    final offset = append ? _items.length : 0;
    final query = _search.text.trim();
    final source = ref.read(unifiedTagRepositoryProvider);
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
        if (!append) {
          _items = const [];
          _total = null;
          _articleTags = null;
        }
      });
    }
    try {
      final scoped = _scopeTags();
      List<CompletionCandidate> page;
      int? total;
      bool more;
      if (query.isEmpty && scoped == null) {
        page = await source.browse(
          category: _category,
          hasWiki: _hasArticle,
          alphabetical: _alphabetical,
          offset: offset,
          limit: _pageSize,
        );
        total = await source.count(category: _category, hasWiki: _hasArticle);
        more = offset + page.length < total;
      } else {
        final candidates = query.isNotEmpty
            ? await _searchCandidates(query)
            : await source.byNames(scoped ?? const {});
        final allowed = scoped == null
            ? candidates
            : candidates
                  .where((candidate) => scoped.contains(candidate.canonicalTag))
                  .toList();
        final byType = _category == null
            ? allowed
            : allowed
                  .where((candidate) => candidate.category == _category)
                  .toList();
        List<CompletionCandidate> filtered = byType;
        if (_hasArticle != null) {
          final available = await ref
              .read(tagWikiRepositoryProvider)
              .available(filtered.map((candidate) => candidate.canonicalTag));
          filtered = filtered
              .where(
                (candidate) =>
                    available.contains(candidate.canonicalTag) == _hasArticle,
              )
              .toList();
        }
        filtered.sort((a, b) {
          if (_alphabetical) return a.canonicalTag.compareTo(b.canonicalTag);
          if (query.isNotEmpty) {
            final relevance = a.matchKind.index.compareTo(b.matchKind.index);
            if (relevance != 0) return relevance;
          }
          final count = b.postCount.compareTo(a.postCount);
          return count != 0 ? count : a.canonicalTag.compareTo(b.canonicalTag);
        });
        total = filtered.length;
        page = filtered.skip(offset).take(_pageSize).toList();
        more = offset + page.length < filtered.length;
      }
      if (!mounted || epoch != _epoch) return;
      setState(() {
        _items = append ? [..._items, ...page] : page;
        _total = total;
        _more = more;
        _loading = false;
        if (_hasArticle == true) {
          _articleTags = {for (final item in _items) item.canonicalTag};
        } else if (_hasArticle == false) {
          _articleTags = const {};
        }
      });
      if (_hasArticle == null) unawaited(_refreshArticleTags(epoch));
      if (!append && _selected == null && page.isNotEmpty) {
        _selectTag(
          page.first.canonicalTag,
          remember: false,
          reveal: !_singlePane,
        );
      }
    } catch (error) {
      if (!mounted || epoch != _epoch) return;
      setState(() {
        _loading = false;
        _loadError = '$error';
      });
    }
  }

  Future<void> _refreshArticleTags(int epoch) async {
    final tags = [for (final item in _items) item.canonicalTag];
    if (tags.isEmpty) {
      if (mounted && epoch == _epoch) setState(() => _articleTags = const {});
      return;
    }
    Set<String> found;
    try {
      found = await ref.read(tagWikiRepositoryProvider).available(tags);
    } catch (_) {
      return;
    }
    if (!mounted || epoch != _epoch) return;
    setState(() => _articleTags = found);
  }

  Future<void> _loadRelated(String tag) async {
    if (!_relatedRequested.add(tag)) return;
    try {
      final source = ref.read(cooccurrenceCompletionSourceProvider);
      final results = await source.search(
        CompletionQuery(
          fullText: '',
          cursorPosition: 0,
          token: '',
          replacementRange: const TextReplacementRange(start: 0, end: 0),
          existingTags: const {},
          limit: 24,
          locale: Localizations.localeOf(context).toLanguageTag(),
          relatedTag: tag,
        ),
      );
      final picked = results
          .where((item) => item.category != TagCategory.meta)
          .take(9)
          .toList();
      var merged = picked;
      if (picked.isNotEmpty) {
        try {
          final details = await ref
              .read(unifiedTagRepositoryProvider)
              .byNames(picked.map((item) => item.canonicalTag));
          final byTag = {for (final item in details) item.canonicalTag: item};
          merged = [
            for (final item in picked)
              byTag[item.canonicalTag]?.copyWith(
                    relatedScore: item.relatedScore,
                    cooccurrenceCount: item.cooccurrenceCount,
                    translation:
                        byTag[item.canonicalTag]!.translation ??
                        item.translation,
                  ) ??
                  item,
          ];
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _relatedItems[tag] = merged);
    } catch (_) {
      if (mounted) setState(() => _relatedItems[tag] = const []);
    }
  }

  void _changeFilter(VoidCallback change) {
    ref.read(autoTagTranslationProvider).clearSurface(_articleSurface);
    setState(() {
      change();
      _selected = null;
      _article = null;
      _articleEntry = null;
      _forward.clear();
    });
    if (_listScroll.hasClients) _listScroll.jumpTo(0);
    _load();
  }

  void _queueSearch({bool immediate = false}) {
    ref.read(autoTagTranslationProvider).clearSurface(_articleSurface);
    setState(() {
      _selected = null;
      _article = null;
      _articleEntry = null;
      _forward.clear();
    });
    _searchTimer?.cancel();
    if (immediate) {
      _load();
    } else {
      _searchTimer = Timer(const Duration(milliseconds: 180), _load);
    }
  }

  Future<void> _addTagToBlock(String tag) async {
    if (_savingTagToBlock) return;
    _savingTagToBlock = true;
    _preview?.dismiss();
    final display = TagNormalizer.toDisplay(tag);
    final candidate = _items
        .where((item) => item.canonicalTag == tag)
        .firstOrNull;
    try {
      await BlocksEditWiring.createWithDialog(
        context,
        ref,
        initialTitle:
            candidate?.translation ?? _autoTranslation.nameFor(tag) ?? display,
        initialContent: display,
      );
    } catch (error) {
      if (mounted) AppToast.error(context, error.toString());
    } finally {
      _savingTagToBlock = false;
    }
  }

  void _onTypeFilterPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_typeFilterScroll.hasClients) return;
    final position = _typeFilterScroll.position;
    if (position.maxScrollExtent <= position.minScrollExtent) return;
    final delta = event.scrollDelta.dx != 0
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if (delta == 0) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      if (!mounted || !_typeFilterScroll.hasClients) return;
      final position = _typeFilterScroll.position;
      _typeFilterScroll.jumpTo(
        (position.pixels + delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }

  bool get _focusInEditable {
    final focus = FocusManager.instance.primaryFocus;
    final element = focus?.context;
    return element != null &&
        element.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  KeyEventResult _onSearchKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isAltPressed ||
        keyboard.isControlPressed ||
        keyboard.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final alt = HardwareKeyboard.instance.isAltPressed;
    if (_focusInEditable) return KeyEventResult.ignored;
    if (alt && key == LogicalKeyboardKey.arrowLeft) {
      _goBack();
      return KeyEventResult.handled;
    }
    if (alt && key == LogicalKeyboardKey.arrowRight) {
      _goForward();
      return KeyEventResult.handled;
    }
    final keyboard = HardwareKeyboard.instance;
    if (alt || keyboard.isControlPressed || keyboard.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.slash) {
      _searchFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final tag = _selected;
      if (tag != null) _addTagToBlock(tag);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyB) {
      final tag = _selected;
      if (tag != null) {
        _toggleBookmark(ref.read(wikiBookmarkStoreProvider), tag);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handlePointerButtons(PointerDownEvent event) {
    if ((event.buttons & kBackMouseButton) != 0) {
      _goBack();
    } else if ((event.buttons & kForwardMouseButton) != 0) {
      _goForward();
    }
  }

  void _moveSelection(int delta) {
    if (_singlePane || _items.isEmpty) return;
    var index = _selected == null
        ? -1
        : _items.indexWhere((item) => item.canonicalTag == _selected);
    index = (index + delta).clamp(0, _items.length - 1);
    _selectTag(_items[index].canonicalTag, remember: false);
    _ensureListVisible(index);
  }

  void _ensureListVisible(int index) {
    if (!_listScroll.hasClients) return;
    final extent = WikiTagRow.extentOf(context);
    final min = index * extent - _listScroll.offset;
    final max = (index + 1) * extent - _listScroll.offset;
    final visible = _listScroll.position.viewportDimension;
    if (min < 0) {
      _listScroll.jumpTo(index * extent);
    } else if (max > visible) {
      _listScroll.jumpTo((index + 1) * extent - visible);
    }
  }

  String _categoryName(TagCategory category) {
    final l10n = context.l10n;
    return switch (category) {
      TagCategory.general => l10n.wiki_categoryGeneral,
      TagCategory.artist => l10n.wiki_categoryArtist,
      TagCategory.copyright => l10n.wiki_categoryCopyright,
      TagCategory.character => l10n.wiki_categoryCharacter,
      TagCategory.meta => l10n.wiki_categoryMeta,
      TagCategory.contributor => l10n.wiki_categoryContributor,
      TagCategory.species => l10n.wiki_categorySpecies,
      TagCategory.lore => l10n.wiki_categoryLore,
      TagCategory.library => l10n.wiki_categoryLibrary,
    };
  }

  String _postCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}m';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  Future<void> _saveReadingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('wiki_text_size', _fontSize);
    await prefs.setBool('wiki_wide_article', _wideArticle);
    // bilingual implies show_translation so pre-bilingual installs upgrade
    // cleanly and downgrades keep their last mode.
    await prefs.setBool(
      'wiki_show_translation',
      _readingMode != WikiReadingMode.original,
    );
    await prefs.setBool(
      'wiki_bilingual',
      _readingMode == WikiReadingMode.bilingual,
    );
  }

  Future<void> _copyTag(String tag) async {
    try {
      await Clipboard.setData(
        ClipboardData(text: TagNormalizer.toDisplay(tag)),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.common_copied)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _syncTags() async {
    try {
      await ref.read(danbooruTagsCacheNotifierProvider.notifier).refresh();
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(autoTagTranslationProvider);
    _scheduleVisibleUpdate();
    _scheduleHeaderUpdate();
    final directory = _directory;
    if (directory == null || _scope == null) {
      return Center(
        child: _loadError == null
            ? const CircularProgressIndicator()
            : Text(_loadError!),
      );
    }
    final bookmarks = ref.watch(wikiBookmarkStoreProvider);
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Listener(
        onPointerDown: _handlePointerButtons,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
            _compactNavigation = constraints.maxWidth < 1000;
            _singlePane = constraints.maxWidth < 720 * scale.clamp(1, 1.25);
            _scheduleVisibleUpdate();
            final listWidth = 300.0 * scale.clamp(1, 1.25);
            return Row(
              children: [
                if (!_compactNavigation)
                  WikiSidebar(
                    allowWindowDrag: true,
                    headerHeight: _toolbarHeight - 1,
                    navigationHeight: _resultsToolbarHeight,
                    width: 216.0 * scale.clamp(1, 1.12),
                    directory: directory,
                    bookmarks: bookmarks,
                    selection: _scope!,
                    onSelect: _selectScope,
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _toolbar(),
                      Expanded(
                        child: _singlePane
                            ? (_showCompactArticle && _selected != null
                                  ? _detail(bookmarks)
                                  : _results(bookmarks))
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: listWidth,
                                    child: _results(bookmarks),
                                  ),
                                  Expanded(child: _detail(bookmarks)),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDirectory() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .8,
          child: WikiSidebar(
            width: double.infinity,
            directory: _directory!,
            bookmarks: ref.watch(wikiBookmarkStoreProvider),
            selection: _scope!,
            onSelect: (scope) {
              Navigator.pop(context);
              _selectScope(scope);
              setState(() => _showCompactArticle = false);
            },
          ),
        ),
      ),
    );
  }

  Widget _toolbar() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _squareButton(
          key: const ValueKey('wiki-history-back'),
          tooltip: context.l10n.wiki_back,
          size: 28,
          radius: 6,
          onPressed: _history.isEmpty ? null : _goBack,
          child: const Icon(Icons.chevron_left, size: 19),
        ),
        const SizedBox(width: 4),
        _squareButton(
          key: const ValueKey('wiki-history-forward'),
          tooltip: context.l10n.wiki_forward,
          size: 28,
          radius: 6,
          onPressed: _forward.isEmpty ? null : _goForward,
          child: const Icon(Icons.chevron_right, size: 19),
        ),
        const SizedBox(width: 8),
        if (_compactNavigation) ...[
          IconButton(
            key: const ValueKey('wiki-directory-button'),
            tooltip: context.l10n.wiki_officialDirectory,
            onPressed: _showDirectory,
            icon: const Icon(Icons.menu, size: 19),
          ),
          Text(
            context.l10n.wiki_title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
    final searchBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: theme.dividerColor),
    );
    final search = SizedBox(
      height: 36,
      child: TextField(
        key: const ValueKey('wiki-search'),
        controller: _search,
        focusNode: _searchFocus,
        style: const TextStyle(fontSize: 13),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: scheme.onSurface.withValues(alpha: .04),
          prefixIcon: const Icon(Icons.search, size: 17),
          hintText: context.l10n.wiki_searchHint,
          hintStyle: const TextStyle(fontSize: 12.5),
          suffixIcon: _search.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    _search.clear();
                    _queueSearch(immediate: true);
                  },
                )
              : _searchFocus.hasFocus
              ? null
              : IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Center(
                      widthFactor: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '/',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          border: searchBorder,
          enabledBorder: searchBorder,
          focusedBorder: searchBorder,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: (_) => _queueSearch(),
      ),
    );
    return WindowHeader(
      dragBackground: true,
      key: _toolbarKey,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: constraints.maxWidth < 560
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: title),
                        _dataMenu(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    search,
                  ],
                )
              : Row(
                  children: [
                    title,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: search,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _dataMenu(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _resultsToolbar() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: _resultsToolbarKey,
      padding: const EdgeInsets.fromLTRB(12, 11, 8, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        _scope?.label ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_total != null) ...[
                      const SizedBox(width: 7),
                      Text(
                        '$_total',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_search.text.isNotEmpty && _scope?.kind != WikiScopeKind.all)
                _toolbarChoice(
                  value: _searchAll,
                  label: _searchAll
                      ? context.l10n.wiki_scopeAll
                      : context.l10n.wiki_scopeCurrent,
                  onTap: () => _changeFilter(() => _searchAll = !_searchAll),
                ),
              Tooltip(
                message: _alphabetical
                    ? context.l10n.wiki_sortName
                    : context.l10n.wiki_sortPopular,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    key: const ValueKey('wiki-sort-filter'),
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.swap_vert),
                    onPressed: () =>
                        _changeFilter(() => _alphabetical = !_alphabetical),
                  ),
                ),
              ),
              PopupMenuButton<bool?>(
                key: const ValueKey('wiki-coverage-filter'),
                tooltip: context.l10n.wiki_coverageAll,
                padding: EdgeInsets.zero,
                iconSize: 17,
                icon: Icon(
                  Icons.filter_list,
                  color: _hasArticle != null ? scheme.primary : null,
                ),
                itemBuilder: (context) => [
                  for (final value in const <bool?>[null, true, false])
                    PopupMenuItem<bool?>(
                      value: value,
                      // Selecting 全部 pops with a null result, which the menu
                      // reports as a cancellation rather than a selection, so
                      // apply the filter from onTap (which runs after the pop).
                      onTap: value == null
                          ? () => _changeFilter(() => _hasArticle = null)
                          : null,
                      height: 35,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            child: _hasArticle == value
                                ? const Icon(Icons.check, size: 15)
                                : null,
                          ),
                          Text(
                            value == null
                                ? context.l10n.wiki_coverageAll
                                : value
                                ? context.l10n.wiki_withArticle
                                : context.l10n.wiki_withoutArticle,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) => _changeFilter(() => _hasArticle = value),
              ),
            ],
          ),
          const SizedBox(height: 7),
          NotificationListener<ScrollMetricsNotification>(
            onNotification: (notification) {
              final overflows = notification.metrics.maxScrollExtent > .5;
              if (overflows != _typeFilterOverflows) {
                setState(() => _typeFilterOverflows = overflows);
              }
              return false;
            },
            child: Listener(
              key: const ValueKey('wiki-type-scroll-area'),
              onPointerSignal: _onTypeFilterPointerSignal,
              child: ListenableBuilder(
                listenable: _typeFilterScroll,
                builder: (context, child) => ShaderMask(
                  shaderCallback: (bounds) {
                    if (!_typeFilterOverflows || bounds.width <= 48) {
                      return const LinearGradient(
                        colors: [Colors.white, Colors.white],
                      ).createShader(bounds);
                    }
                    final position = _typeFilterScroll.hasClients
                        ? _typeFilterScroll.position
                        : null;
                    final fade = 24 / bounds.width;
                    return LinearGradient(
                      colors: [
                        position != null && position.extentBefore > .5
                            ? Colors.transparent
                            : Colors.white,
                        Colors.white,
                        Colors.white,
                        position == null || position.extentAfter > .5
                            ? Colors.transparent
                            : Colors.white,
                      ],
                      stops: [0, fade, 1 - fade, 1],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: child,
                ),
                child: SingleChildScrollView(
                  controller: _typeFilterScroll,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    key: const ValueKey('wiki-type-filter'),
                    children: [
                      for (final category in const <TagCategory?>[
                        null,
                        TagCategory.general,
                        TagCategory.artist,
                        TagCategory.copyright,
                        TagCategory.character,
                        TagCategory.meta,
                      ])
                        _typeChip(
                          key: ValueKey('wiki-type-${category?.name ?? 'all'}'),
                          category: category,
                          label: category == null
                              ? context.l10n.wiki_typeAllShort
                              : _categoryName(category),
                          selected: _category == category,
                          onTap: () =>
                              _changeFilter(() => _category = category),
                        ),
                      _moreCategoriesChip(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _extraCategories = [
    TagCategory.contributor,
    TagCategory.species,
    TagCategory.lore,
  ];

  Widget _typeChip({
    Key? key,
    required TagCategory? category,
    required String label,
    required bool selected,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chip = InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? scheme.onSurface : null,
          border: Border.all(
            color: selected ? scheme.onSurface : theme.dividerColor,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != null) ...[
              Icon(
                TagCategoryVisuals.icon(category),
                size: 14,
                color: selected
                    ? scheme.surface
                    : TagCategoryVisuals.color(context, category),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: selected ? scheme.surface : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(
      key: key,
      padding: const EdgeInsets.only(right: 4),
      child: chip,
    );
  }

  Widget _moreCategoriesChip() {
    final selected = _extraCategories.contains(_category);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      key: const ValueKey('wiki-type-more'),
      padding: const EdgeInsets.only(right: 4),
      child: PopupMenuButton<TagCategory>(
        borderRadius: BorderRadius.circular(999),
        tooltip: context.l10n.wiki_moreCategories,
        position: PopupMenuPosition.under,
        offset: const Offset(0, 4),
        itemBuilder: (context) => [
          for (final category in _extraCategories)
            PopupMenuItem<TagCategory>(
              key: ValueKey('wiki-type-${category.name}'),
              value: category,
              height: 35,
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: _category == category
                        ? const Icon(Icons.check, size: 15)
                        : null,
                  ),
                  Text(
                    _categoryName(category),
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ],
              ),
            ),
        ],
        onSelected: (category) => _changeFilter(() => _category = category),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? scheme.onSurface : null,
            border: Border.all(
              color: selected ? scheme.onSurface : theme.dividerColor,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selected
                    ? _categoryName(_category!)
                    : context.l10n.wiki_moreCategories,
                style: TextStyle(
                  fontSize: 11.5,
                  color: selected ? scheme.surface : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down,
                size: 13,
                color: selected ? scheme.surface : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dataMenu() => PopupMenuButton<String>(
    tooltip: context.l10n.wiki_dataStatus,
    child: const Padding(
      padding: EdgeInsets.all(5),
      child: Icon(Icons.storage_outlined, size: 18),
    ),
    itemBuilder: (context) {
      final state = ref.read(danbooruTagsCacheNotifierProvider).valueOrNull;
      return [
        PopupMenuItem<String>(
          enabled: false,
          value: 'status',
          child: Text(
            '${context.l10n.wiki_dataStatus}: ${state?.totalTags ?? 0} · '
            '${state?.lastUpdate?.toLocal().toString().split('.').first ?? '—'}',
          ),
        ),
        PopupMenuItem<String>(
          value: 'sync',
          child: Text(context.l10n.wiki_syncTags),
        ),
        PopupMenuItem<String>(
          enabled: false,
          value: 'directory',
          child: Text(context.l10n.wiki_directorySource),
        ),
      ];
    },
    onSelected: (value) {
      if (value == 'sync') _syncTags();
    },
  );

  Widget _toolbarChoice({
    required bool value,
    required String label,
    required VoidCallback onTap,
  }) => TextButton.icon(
    key: const ValueKey('wiki-search-scope'),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      minimumSize: const Size(0, 28),
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    onPressed: onTap,
    icon: Icon(value ? Icons.public : Icons.folder_outlined, size: 15),
    label: Text(label, style: const TextStyle(fontSize: 11.5)),
  );

  void _scheduleVisibleUpdate() {
    if (_visibilityScheduled) return;
    _visibilityScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityScheduled = false;
      if (!mounted) return;
      if (!_listScroll.hasClients ||
          (_singlePane && _showCompactArticle && _selected != null)) {
        if (_listVisible.isNotEmpty) {
          _autoTranslation.clearSurface(_listSurface);
          _listVisible.clear();
        }
        return;
      }
      final position = _listScroll.position;
      final extent = WikiTagRow.extentOf(context);
      final first = ((position.pixels - 5) / extent).floor().clamp(
        0,
        _items.length,
      );
      final last = ((position.pixels + position.viewportDimension - 5) / extent)
          .ceil()
          .clamp(0, _items.length);
      final visible = <String>{};
      for (var index = first; index < last; index++) {
        final candidate = _items[index];
        visible.add(candidate.canonicalTag);
        _autoTranslation.observe(
          surface: _listSurface,
          tag: candidate.canonicalTag,
          visible: true,
          existingNameZh: candidate.translation,
          tagContext: AutoTagTranslationContext(
            category: candidate.category.name,
            aliases: candidate.aliases,
            postCount: candidate.postCount,
          ),
        );
      }
      for (final tag in _listVisible.difference(visible)) {
        _autoTranslation.observe(
          surface: _listSurface,
          tag: tag,
          visible: false,
        );
      }
      _listVisible = visible;
    });
  }

  Widget _results(WikiBookmarkStore bookmarks) {
    _scheduleVisibleUpdate();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('wiki-results-pane'),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          _resultsToolbar(),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_loadError!),
                    ),
                  )
                : _items.isEmpty && !_loading
                ? Center(
                    child: Text(
                      context.l10n.wiki_noResults,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    key: const ValueKey('wiki-results-list'),
                    controller: _listScroll,
                    itemExtent: WikiTagRow.extentOf(context),
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    itemCount: _items.length + (_more ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _items.length) {
                        return TextButton(
                          onPressed: _loading
                              ? null
                              : () => _load(append: true),
                          child: Text(context.l10n.wiki_loadMore),
                        );
                      }
                      final candidate = _items[index];
                      final tag = candidate.canonicalTag;
                      final selected = tag == _selected;
                      final translatedName =
                          ref.read(autoTagTranslationProvider).nameFor(tag) ??
                          candidate.translation;
                      final articleTags = _articleTags;
                      return WikiTagRow(
                        key: ValueKey('wiki-row-$tag'),
                        candidate: candidate,
                        subtitle:
                            translatedName ?? _categoryName(candidate.category),
                        countLabel: _postCount(candidate.postCount),
                        selected: selected,
                        bookmarked: bookmarks.contains(tag),
                        bookmarkLabel: bookmarks.contains(tag)
                            ? context.l10n.wiki_removeBookmark
                            : context.l10n.wiki_addBookmark,
                        translationIndicator: TagTranslationIndicator(
                          tag: tag,
                          surface: _listSurface,
                        ),
                        onSelect: () => _selectTag(tag),
                        onBookmark: () => _toggleBookmark(bookmarks, tag),
                        noArticleLabel:
                            articleTags != null && !articleTags.contains(tag)
                            ? context.l10n.wiki_noArticle
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBookmark(WikiBookmarkStore bookmarks, String tag) async {
    await bookmarks.toggle(tag);
    if (!mounted) return;
    if (_scope?.kind == WikiScopeKind.bookmarks ||
        _scope?.kind == WikiScopeKind.collection) {
      _load();
    }
  }

  Widget _squareButton({
    Key? key,
    String? tooltip,
    required VoidCallback? onPressed,
    required Widget child,
    double size = 32,
    double radius = 7,
  }) {
    final button = SizedBox(
      width: size,
      height: size,
      child: OutlinedButton(
        key: key,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size(size, size),
          maximumSize: Size(size, size),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }

  Widget _articleHeader(
    WikiBookmarkStore bookmarks,
    CompletionCandidate? candidate,
  ) {
    final tag = _selected!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final baseStyle = DefaultTextStyle.of(context).style;
    final translation =
        ref.read(autoTagTranslationProvider).nameFor(tag) ??
        candidate?.translation;
    final categoryColor = candidate == null
        ? null
        : TagCategoryVisuals.color(context, candidate.category);
    final pill = candidate == null
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: categoryColor!.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  TagCategoryVisuals.icon(candidate.category),
                  key: const ValueKey('wiki-article-category-icon'),
                  size: 14,
                  color: categoryColor,
                ),
                const SizedBox(width: 5),
                Text(
                  _categoryName(candidate.category),
                  key: const ValueKey('wiki-article-category-label'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
          );
    final aliases = candidate?.aliases ?? const <String>[];
    final shownAliases = aliases.take(3).toList();
    final exactCount = candidate == null
        ? null
        : NumberFormat.decimalPattern(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(candidate.postCount);
    final metadata = candidate == null
        ? null
        : Wrap(
            key: const ValueKey('wiki-article-metadata'),
            spacing: 14,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Tooltip(
                message: '$exactCount ${context.l10n.wiki_posts}',
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                    children: [
                      TextSpan(
                        text: _postCount(candidate.postCount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' ${context.l10n.wiki_posts}'),
                    ],
                  ),
                ),
              ),
              if (aliases.isNotEmpty)
                Tooltip(
                  message: aliases.join(', '),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(text: '${context.l10n.wiki_aliases} '),
                        TextSpan(text: shownAliases.join(', ')),
                        if (aliases.length > shownAliases.length)
                          TextSpan(
                            text: ' +${aliases.length - shownAliases.length}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
    final actions = Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.icon(
          key: const ValueKey('wiki-add-to-block'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
            textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 12.5),
          ),
          icon: const Icon(StudioIcons.promptBlockPalette, size: 16),
          label: Text(context.l10n.wiki_addToBlock),
          onPressed: () => _addTagToBlock(tag),
        ),
        _squareButton(
          key: const ValueKey('wiki-copy-tag'),
          tooltip: context.l10n.common_copy,
          onPressed: () => _copyTag(tag),
          child: const Icon(Icons.content_copy_outlined, size: 17),
        ),
        _squareButton(
          key: const ValueKey('wiki-article-bookmark'),
          tooltip: bookmarks.contains(tag)
              ? context.l10n.wiki_removeBookmark
              : context.l10n.wiki_addBookmark,
          onPressed: () => _toggleBookmark(bookmarks, tag),
          child: Icon(
            bookmarks.contains(tag) ? Icons.bookmark : Icons.bookmark_border,
            size: 17,
            color: bookmarks.contains(tag) ? scheme.primary : null,
          ),
        ),
        _readingMenuAnchor(),
        if (bookmarks.collections.isNotEmpty) _collectionMenu(bookmarks, tag),
      ],
    );
    final back = _singlePane
        ? IconButton(
            key: const ValueKey('wiki-article-back'),
            tooltip: context.l10n.wiki_allTags,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            visualDensity: VisualDensity.standard,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => setState(() => _showCompactArticle = false),
            icon: const Icon(
              Icons.arrow_back,
              key: ValueKey('wiki-back-glyph'),
              size: 19,
            ),
          )
        : null;
    return Container(
      key: const ValueKey('wiki-article-header'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final compact = constraints.maxWidth < 650 * scale;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (back != null) ...[back, const SizedBox(width: 10)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (pill != null) ...[pill, const SizedBox(height: 7)],
                        Tooltip(
                          message: TagNormalizer.toDisplay(tag),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  TagNormalizer.toDisplay(tag),
                                  key: const ValueKey('wiki-article-title'),
                                  style: baseStyle.copyWith(
                                    fontSize: 30,
                                    fontFamily: StudioTypography.mono,
                                    fontFamilyFallback:
                                        StudioTypography.fallback,
                                    height: 0,
                                    leadingDistribution:
                                        TextLeadingDistribution.even,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TagTranslationIndicator(
                                tag: tag,
                                surface: _articleSurface,
                                wiki: true,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                        if (translation != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            translation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (metadata != null) ...[
                          const SizedBox(height: 11),
                          metadata,
                        ],
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 18),
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: actions,
                    ),
                  ],
                ],
              ),
              if (compact) ...[const SizedBox(height: 12), actions],
              const SizedBox(height: 18),
              const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }

  Widget _collectionMenu(WikiBookmarkStore bookmarks, String tag) =>
      PopupMenuButton<String>(
        tooltip: context.l10n.wiki_addToCollection,
        itemBuilder: (context) => [
          for (final collection in bookmarks.collections)
            PopupMenuItem<String>(
              value: collection.id,
              child: Row(
                children: [
                  Icon(
                    bookmarks.isInCollection(tag, collection.id)
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(collection.name)),
                ],
              ),
            ),
        ],
        onSelected: (id) {
          if (bookmarks.isInCollection(tag, id)) {
            bookmarks.removeFromCollection(tag, id);
          } else {
            bookmarks.addToCollection(tag, id);
          }
          if (_scope?.kind == WikiScopeKind.collection) _load();
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(Icons.more_vert, size: 17),
        ),
      );

  /// The markdown rendered as the primary body — the translation when shown,
  /// otherwise the article's source text. In bilingual mode this is the
  /// translated side, which also owns the outline headings.
  String _visibleBody(TagWikiEntry? article) {
    if (article?.body.trim().isNotEmpty != true) {
      return context.l10n.wiki_articleMissing;
    }
    final auto = ref.read(autoTagTranslationProvider);
    return switch (_readingMode) {
      WikiReadingMode.translation => auto.wikiFor(_selected!) ?? article!.body,
      WikiReadingMode.bilingual => auto.wikiFor(_selected!) ?? article!.body,
      WikiReadingMode.original =>
        auto.wikiOriginalFor(_selected!) ?? article!.body,
    };
  }

  /// Both sides aligned, or null when bilingual rendering must fall back.
  List<WikiBilingualBlock>? _bilingualBlocks(TagWikiEntry? article) {
    if (_readingMode != WikiReadingMode.bilingual ||
        article?.body.trim().isNotEmpty != true) {
      return null;
    }
    final auto = ref.read(autoTagTranslationProvider);
    final translated = auto.wikiFor(_selected!);
    final original = auto.wikiOriginalFor(_selected!);
    if (translated == null || original == null) return null;
    return alignWikiBlocks(translated, original);
  }

  List<WikiArticleHeading> _outlineFor(String body) {
    if (_outlineTag != _selected || _outlineBody != body) {
      _outlineTag = _selected;
      _outlineBody = body;
      _headings = wikiArticleHeadings(body);
      _activeOutline = null;
      _clampedOutline = null;
      _clampedOutlineOffset = null;
    }
    _scheduleOutlineUpdate();
    return _headings;
  }

  void _scheduleHeaderUpdate() {
    if (_headerScheduled) return;
    _headerScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _headerScheduled = false;
      if (!mounted) return;
      final render = _toolbarKey.currentContext?.findRenderObject();
      final results = _resultsToolbarKey.currentContext?.findRenderObject();
      final toolbarHeight = render is RenderBox && render.hasSize
          ? render.size.height
          : _toolbarHeight;
      final resultsHeight = results is RenderBox && results.hasSize
          ? results.size.height
          : _resultsToolbarHeight;
      if ((toolbarHeight - _toolbarHeight).abs() > .1 ||
          (resultsHeight - _resultsToolbarHeight).abs() > .1) {
        setState(() {
          _toolbarHeight = toolbarHeight;
          _resultsToolbarHeight = resultsHeight;
        });
      }
    });
  }

  bool get _relatedVisible => _relatedItems[_selected]?.isNotEmpty == true;

  bool get _directoryVisible =>
      _selected != null &&
      _directory?.pathsForTag(_selected!).isNotEmpty == true;

  List<GlobalKey> _sectionAnchors() => [
    for (final heading in _headings) heading.anchor,
    if (_relatedVisible) _relatedAnchor,
    if (_directoryVisible) _directoryAnchor,
  ];

  void _jumpToOutline(GlobalKey anchor) {
    if (!_articleScroll.hasClients) return;
    _clampedOutline = null;
    _clampedOutlineOffset = null;
    if (anchor == _articleStart) {
      _articleScroll.jumpTo(0);
      _scheduleOutlineUpdate();
      return;
    }
    final target = anchor.currentContext?.findRenderObject();
    if (target == null || !target.attached) return;
    final viewport = RenderAbstractViewport.of(target);
    // Use the heading itself and a fixed inset, independent of window height.
    // The scroll tracker uses 28px, so a clicked heading is always included.
    final offset = viewport.getOffsetToReveal(target, 0).offset - 8;
    _articleScroll.jumpTo(
      offset.clamp(0, _articleScroll.position.maxScrollExtent),
    );
    if (offset > _articleScroll.position.maxScrollExtent || offset < 0) {
      // At the end of a short article the target cannot reach the top. Keep
      // the clicked section until the reader scrolls or the body changes.
      _clampedOutline = anchor;
      _clampedOutlineOffset = _articleScroll.offset;
    }
    _scheduleOutlineUpdate();
  }

  void _onArticleScroll() {
    _preview?.dismiss();
    _scheduleOutlineUpdate();
  }

  void _scheduleOutlineUpdate() {
    if (_outlineScheduled) return;
    _outlineScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _outlineScheduled = false;
      if (!mounted) return;
      final viewport = _articleViewport.currentContext?.findRenderObject();
      if (viewport is! RenderBox || !viewport.hasSize) return;
      final top = viewport.localToGlobal(Offset.zero).dy + 28;
      GlobalKey? active;
      if (_clampedOutlineOffset != null &&
          _articleScroll.hasClients &&
          (_articleScroll.offset - _clampedOutlineOffset!).abs() < .5) {
        active = _clampedOutline;
      } else {
        _clampedOutline = null;
        _clampedOutlineOffset = null;
        for (final anchor in _sectionAnchors()) {
          final render = anchor.currentContext?.findRenderObject();
          if (render is RenderBox &&
              render.hasSize &&
              render.localToGlobal(Offset.zero).dy <= top) {
            active = anchor;
          }
        }
      }
      if (active != _activeOutline) setState(() => _activeOutline = active);
    });
  }

  Widget _tocLink(
    String label,
    GlobalKey anchor, {
    required bool selected,
    Key? key,
    double indent = 0,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(3),
      onTap: () => _jumpToOutline(anchor),
      child: Container(
        constraints: const BoxConstraints(minHeight: 26),
        padding: EdgeInsets.only(left: indent, top: 5, bottom: 5),
        child: Row(
          children: [
            Container(
              width: 2,
              height: 14,
              color: selected ? scheme.primary : theme.dividerColor,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                softWrap: true,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toc() {
    final tag = _selected;
    final headings = _headings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 30, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.wiki_onThisPage,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 7),
          _tocLink(
            context.l10n.wiki_overview,
            _articleStart,
            selected: _activeOutline == null,
            key: const ValueKey('wiki-outline-intro'),
          ),
          for (var index = 0; index < headings.length; index++)
            _tocLink(
              headings[index].label,
              headings[index].anchor,
              selected: _activeOutline == headings[index].anchor,
              key: ValueKey('wiki-outline-$index'),
              indent: (headings[index].level - 1).clamp(0, 2) * 8.0,
            ),
          if (_relatedVisible)
            _tocLink(
              context.l10n.wiki_relatedTitle,
              _relatedAnchor,
              selected: _activeOutline == _relatedAnchor,
              key: const ValueKey('wiki-outline-related'),
            ),
          if (tag != null && _directoryVisible)
            _tocLink(
              context.l10n.wiki_inDirectory,
              _directoryAnchor,
              selected: _activeOutline == _directoryAnchor,
              key: const ValueKey('wiki-outline-directory'),
            ),
        ],
      ),
    );
  }

  WikiTagPreviewHost get _previewHost =>
      _preview ??= WikiTagPreviewHost(context: context, builder: _previewCard);

  Widget _previewCard(CompletionCandidate candidate) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tag = candidate.canonicalTag;
    final translation =
        ref.read(autoTagTranslationProvider).nameFor(tag) ??
        candidate.translation;
    final definition = ref.read(autoTagTranslationProvider).definitionFor(tag);
    return Material(
      key: const ValueKey('wiki-tag-preview-card'),
      elevation: 8,
      color: scheme.surface,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  TagCategoryVisuals.icon(candidate.category),
                  size: 14,
                  color: TagCategoryVisuals.color(context, candidate.category),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    TagNormalizer.toDisplay(tag),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _postCount(candidate.postCount),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (translation != null) ...[
              const SizedBox(height: 2),
              Text(
                translation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (definition != null && definition.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                definition,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const ValueKey('wiki-preview-open'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 28),
                    textStyle: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () {
                    _preview?.dismiss();
                    _selectTag(tag, linkedCandidate: candidate);
                  },
                  child: Text(context.l10n.wiki_open),
                ),
                const SizedBox(width: 4),
                TextButton(
                  key: const ValueKey('wiki-preview-add'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 28),
                    textStyle: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () {
                    _preview?.dismiss();
                    _addTagToBlock(tag);
                  },
                  child: Text('＋ ${context.l10n.wiki_addToBlock}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The article body: single markdown body in original/translation modes, or
  /// interleaved translated/original blocks in bilingual mode.
  Widget _articleBody(TagWikiEntry? article, String tag, String? translated) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final body = _visibleBody(article);
    final blocks = _bilingualBlocks(article);
    final hint = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    Widget linked(
      String markdown, {
      Key? key,
      List<GlobalKey> headingAnchors = const [],
      TextStyle? style,
      TextStyle? headingStyle,
      String? initialSection,
      bool includeExampleImages = true,
    }) => WikiLinkedBody(
      key: key,
      body: markdown,
      headingAnchors: headingAnchors,
      linkListsAsChips: true,
      exampleCards: true,
      exampleTag: includeExampleImages ? tag : null,
      initialSectionTitle: initialSection,
      onTagAdd: (candidate) => _addTagToBlock(candidate.canonicalTag),
      onTagHover: _previewHost.hover,
      onTagLeave: _previewHost.leave,
      style:
          style ??
          TextStyle(fontSize: _fontSize, height: 1.68, color: scheme.onSurface),
      headingStyle: headingStyle,
      onTagTap: (candidate) =>
          _selectTag(candidate.canonicalTag, linkedCandidate: candidate),
    );
    if (_readingMode == WikiReadingMode.bilingual && blocks != null) {
      return KeyedSubtree(
        key: _articleStart,
        child: _bilingualBody(tag, blocks, linked),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_readingMode == WikiReadingMode.bilingual &&
            translated != null &&
            article?.body.trim().isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              context.l10n.wiki_bilingualUnavailable,
              key: const Key('wiki-bilingual-unavailable'),
              style: hint,
            ),
          ),
        KeyedSubtree(
          key: _articleStart,
          child: linked(
            body,
            key: ValueKey('wiki-body-$tag'),
            headingAnchors: _outlineFor(
              body,
            ).map((heading) => heading.anchor).toList(),
          ),
        ),
        if (_readingMode != WikiReadingMode.original &&
            translated == null &&
            article?.body.trim().isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              context.l10n.wiki_untranslated,
              key: const Key('wiki-untranslated'),
              style: hint,
            ),
          ),
      ],
    );
  }

  /// Interleaved translated/original blocks. Translated headings keep their
  /// outline anchors; matching original blocks render smaller and muted with
  /// a divider-colored leading rule.
  Widget _bilingualBody(
    String tag,
    List<WikiBilingualBlock> blocks,
    Widget Function(
      String markdown, {
      Key? key,
      List<GlobalKey> headingAnchors,
      TextStyle? style,
      TextStyle? headingStyle,
      String? initialSection,
      bool includeExampleImages,
    })
    linked,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final headings = _headings;
    var headingIndex = 0;
    // Section titles carry across blocks so example-card detection works in
    // list blocks that arrive after the heading that opened their section.
    var translatedSection = '';
    var originalSection = '';
    int? exampleBlock;
    var exampleSection = '';
    for (var index = 0; index < blocks.length; index++) {
      final headings = wikiArticleHeadings(blocks[index].translated);
      if (headings.isNotEmpty) exampleSection = headings.last.label;
      if (isWikiExampleHeading(exampleSection) &&
          RegExp(
            r'^\s*(?:[-*+]|\d+\.)\s+',
            multiLine: true,
          ).hasMatch(blocks[index].translated)) {
        exampleBlock = index;
        break;
      }
    }
    final originalStyle = TextStyle(
      fontSize: _fontSize - 1,
      height: 1.6,
      color: scheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          if (index > 0) const SizedBox(height: 14),
          Builder(
            builder: (context) {
              final block = blocks[index];
              // Count headings with the same parser the outline uses so
              // fenced code and setext headings stay consistent.
              final translatedHeadings = wikiArticleHeadings(block.translated);
              final originalHeadings = wikiArticleHeadings(block.original);
              final count = translatedHeadings.length;
              final start = math.min(headingIndex, headings.length);
              final anchors = headings
                  .sublist(start, math.min(start + count, headings.length))
                  .map((heading) => heading.anchor)
                  .toList();
              headingIndex = start + count;
              final translatedSeed = translatedSection;
              final originalSeed = originalSection;
              if (translatedHeadings.isNotEmpty) {
                translatedSection = translatedHeadings.last.label;
              }
              if (originalHeadings.isNotEmpty) {
                originalSection = originalHeadings.last.label;
              }
              final originalHeading = block.original.replaceFirst(
                RegExp(r'^#{1,6}\s+'),
                '',
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  linked(
                    block.translated,
                    key: ValueKey('wiki-bilingual-$tag-$index'),
                    headingAnchors: anchors,
                    initialSection: translatedSeed.isEmpty
                        ? null
                        : translatedSeed,
                    includeExampleImages: index == exampleBlock,
                  ),
                  const SizedBox(height: 4),
                  if (block.heading)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        originalHeading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: originalStyle,
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: theme.dividerColor, width: 2),
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 10),
                      child: linked(
                        block.original,
                        headingStyle: originalStyle.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        style: originalStyle,
                        initialSection: originalSeed.isEmpty
                            ? null
                            : originalSeed,
                        includeExampleImages: false,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _detail(WikiBookmarkStore bookmarks) {
    final tag = _selected;
    if (tag == null) {
      return Center(child: Text(context.l10n.wiki_noSelection));
    }
    // Refresh the heading cache here (not inside the FutureBuilder) so the
    // table of contents rebuilds once the article future resolves.
    _outlineFor(_visibleBody(_articleEntry));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final candidate =
        _linkedCandidate ??
        _items.where((item) => item.canonicalTag == tag).firstOrNull;
    return Container(
      color: scheme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final readingWidth = _wideArticle ? 1040.0 : 760.0;
          const tocWidth = 168.0;
          final hasTocEntries =
              _headings.isNotEmpty || _relatedVisible || _directoryVisible;
          final showToc =
              hasTocEntries && constraints.maxWidth >= 560 + tocWidth + 48;
          final columnWidth = showToc
              ? (constraints.maxWidth - tocWidth - 48)
                    .clamp(560.0, readingWidth)
                    .toDouble()
              : math.min(readingWidth, math.max(0.0, constraints.maxWidth));
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  key: _articleViewport,
                  controller: _articleScroll,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      key: const ValueKey('wiki-reading-column'),
                      constraints: BoxConstraints.tightFor(width: columnWidth),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 25, 24, 35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _articleHeader(bookmarks, candidate),
                            const SizedBox(height: 22),
                            FutureBuilder<TagWikiEntry?>(
                              future: _article,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState !=
                                    ConnectionState.done) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(30),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return Text('${snapshot.error}');
                                }
                                final article = snapshot.data;
                                if (_restoreArticleOffset case final offset?) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (!mounted ||
                                        _selected != tag ||
                                        _restoreArticleOffset != offset) {
                                      return;
                                    }
                                    _restoreArticleOffset = null;
                                    if (_articleScroll.hasClients) {
                                      _articleScroll.jumpTo(
                                        offset.clamp(
                                          0,
                                          _articleScroll
                                              .position
                                              .maxScrollExtent,
                                        ),
                                      );
                                    }
                                  });
                                }
                                final translated = ref
                                    .read(autoTagTranslationProvider)
                                    .wikiFor(tag);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _articleBody(article, tag, translated),
                                    _relatedSection(tag, candidate),
                                    _directorySection(tag),
                                    const SizedBox(height: 26),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Wrap(
                                        key: const ValueKey(
                                          'wiki-article-footer',
                                        ),
                                        alignment:
                                            article?.sourceUrl.isNotEmpty ==
                                                true
                                            ? WrapAlignment.spaceBetween
                                            : WrapAlignment.end,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: [
                                          if (article != null &&
                                              article.sourceUrl.isNotEmpty)
                                            TextButton.icon(
                                              key: const ValueKey(
                                                'wiki-article-source',
                                              ),
                                              icon: const Icon(
                                                Icons.open_in_new,
                                                size: 17,
                                              ),
                                              label: Text(
                                                context.l10n.wiki_source,
                                              ),
                                              style: TextButton.styleFrom(
                                                textStyle: theme
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(fontSize: 14),
                                                minimumSize: const Size(0, 32),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 6,
                                                    ),
                                                visualDensity:
                                                    VisualDensity.standard,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              onPressed: () => launchUrl(
                                                Uri.parse(article.sourceUrl),
                                              ),
                                            ),
                                          if (translated != null)
                                            WikiArticleActions(
                                              compact: false,
                                              tag: tag,
                                              surface: _articleSurface,
                                              showTranslation:
                                                  _readingMode !=
                                                  WikiReadingMode.original,
                                              onToggle: () {
                                                // The footer toggle stays
                                                // two-state: from bilingual it
                                                // switches to the source.
                                                setState(
                                                  () => _readingMode =
                                                      _readingMode ==
                                                          WikiReadingMode
                                                              .original
                                                      ? WikiReadingMode
                                                            .translation
                                                      : WikiReadingMode
                                                            .original,
                                                );
                                                _saveReadingSettings();
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (showToc)
                SizedBox(
                  width: tocWidth,
                  child: SingleChildScrollView(child: _toc()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _relatedSection(String tag, CompletionCandidate? candidate) {
    final items = _relatedItems[tag];
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final postCount = candidate?.postCount;
    final sorted = [...items];
    if (postCount != null && postCount > 0) {
      sorted.sort(
        (a, b) =>
            (b.cooccurrenceCount ?? 0).compareTo(a.cooccurrenceCount ?? 0),
      );
    }
    return KeyedSubtree(
      key: _relatedAnchor,
      child: Container(
        key: const ValueKey('wiki-related-section'),
        margin: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  context.l10n.wiki_relatedTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    context.l10n.wiki_relatedHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 560 ? 2 : 3;
                final width =
                    (constraints.maxWidth - (columns - 1) * 6) / columns;
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final item in sorted)
                      SizedBox(
                        width: width,
                        child: _relatedCell(item, postCount, theme, scheme),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _relatedCell(
    CompletionCandidate item,
    int? postCount,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    final share =
        postCount != null && postCount > 0 && item.cooccurrenceCount != null
        ? (item.cooccurrenceCount! / postCount).clamp(0.0, 1.0)
        : null;
    final percent = share == null ? null : '${(share * 100).round()}%';
    final translation =
        item.translation ?? _autoTranslation.nameFor(item.canonicalTag);
    return MouseRegion(
      onEnter: (event) => _previewHost.hover(item, event.position),
      onHover: (event) => _previewHost.hover(item, event.position),
      onExit: (_) => _previewHost.leave(),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('wiki-related-${item.canonicalTag}'),
          onTap: () {
            if (HardwareKeyboard.instance.isShiftPressed) {
              _addTagToBlock(item.canonicalTag);
            } else {
              _selectTag(item.canonicalTag, linkedCandidate: item);
            }
          },
          child: SizedBox(
            height: 34,
            child: Stack(
              children: [
                if (share != null && share > 0)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: share,
                        child: Container(
                          color: scheme.primary.withValues(alpha: .09),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  TagNormalizer.toDisplay(item.canonicalTag),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (translation != null) ...[
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    translation,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (percent != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            percent,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: scheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _directorySection(String tag) {
    final directory = _directory;
    if (directory == null) return const SizedBox.shrink();
    final paths = directory.pathsForTag(tag);
    if (paths.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final language = context.appLanguage;
    return KeyedSubtree(
      key: _directoryAnchor,
      child: Container(
        key: const ValueKey('wiki-directory-paths'),
        margin: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.wiki_inDirectory,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            for (final path in paths)
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  final node = path.last;
                  _selectScope(
                    WikiScope(
                      WikiScopeKind.directory,
                      _directoryNodeId(directory, path),
                      WikiDirectoryLabels.display(node.label, language),
                      node: node,
                    ),
                  );
                  if (_singlePane) {
                    setState(() => _showCompactArticle = false);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text.rich(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    TextSpan(
                      style: TextStyle(fontSize: 13, color: scheme.onSurface),
                      children: [
                        for (var i = 0; i < path.length; i++) ...[
                          if (i > 0)
                            TextSpan(
                              text: ' › ',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          TextSpan(
                            text: WikiDirectoryLabels.display(
                              path[i].label,
                              language,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Matches the id rule in `WikiSidebar._directoryNode` so the sidebar can
  /// highlight the node the article links to.
  String _directoryNodeId(
    WikiDirectory directory,
    List<WikiDirectoryNode> path,
  ) {
    var id = '';
    for (var i = 0; i < path.length; i++) {
      final node = path[i];
      final group = node.group;
      if (group != null) {
        id = group;
        continue;
      }
      if (i == 0) {
        id = 'root-${directory.roots.indexOf(node)}';
      } else {
        id = '$id/${path[i - 1].children.indexOf(node)}';
      }
    }
    return id;
  }

  ButtonStyle _readingSegmentStyle() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final track = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: .065),
      scheme.surface,
    );
    final selected = dark
        ? Color.alphaBlend(
            scheme.onSurface.withValues(alpha: .16),
            scheme.surface,
          )
        : scheme.surface;
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? selected : track,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.onSurface
            : scheme.onSurfaceVariant,
      ),
      textStyle: WidgetStateProperty.resolveWith(
        (states) => theme.textTheme.labelMedium?.copyWith(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      side: WidgetStatePropertyAll(BorderSide(color: theme.dividerColor)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _readingLabel(String text) =>
      Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);

  Widget _readingMenuAnchor() => MenuAnchor(
    builder: (context, controller, _) => _squareButton(
      key: const ValueKey('wiki-reading-button'),
      tooltip: context.l10n.wiki_readingSettings,
      onPressed: () =>
          controller.isOpen ? controller.close() : controller.open(),
      child: const Text(
        'Aa',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    menuChildren: [
      Padding(
        padding: const EdgeInsets.all(13),
        child: StatefulBuilder(
          builder: (context, update) => SizedBox(
            width: 236,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.wiki_textSize,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 9),
                _textSizeChoice(refreshDialog: () => update(() {})),
                const SizedBox(height: 18),
                Text(
                  context.l10n.wiki_readingWidth,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                _widthChoice(refreshDialog: () => update(() {})),
                const SizedBox(height: 18),
                _readingLanguage(refreshDialog: () => update(() {})),
                const SizedBox(height: 13),
                Text(
                  context.l10n.wiki_shortcutsHint,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _textSizeChoice({
    VoidCallback? refreshDialog,
  }) => SegmentedButton<double>(
    key: const ValueKey('wiki-text-size'),
    style: _readingSegmentStyle(),
    showSelectedIcon: false,
    segments: [
      ButtonSegment(value: 12, label: _readingLabel(context.l10n.wiki_small)),
      ButtonSegment(
        value: 14,
        label: _readingLabel(context.l10n.wiki_standard),
      ),
      ButtonSegment(value: 17, label: _readingLabel(context.l10n.wiki_large)),
    ],
    selected: {_fontSize},
    onSelectionChanged: (values) {
      setState(() => _fontSize = values.first);
      refreshDialog?.call();
      _saveReadingSettings();
    },
  );

  Widget _widthChoice({VoidCallback? refreshDialog}) => SegmentedButton<bool>(
    key: const ValueKey('wiki-reading-width'),
    style: _readingSegmentStyle(),
    showSelectedIcon: false,
    segments: [
      ButtonSegment(
        value: false,
        label: _readingLabel(context.l10n.wiki_standard),
      ),
      ButtonSegment(value: true, label: _readingLabel(context.l10n.wiki_wide)),
    ],
    selected: {_wideArticle},
    onSelectionChanged: (values) {
      setState(() => _wideArticle = values.first);
      refreshDialog?.call();
      _saveReadingSettings();
    },
  );

  Widget _autoTranslateButton() => Consumer(
    builder: (context, ref, _) {
      final auto = ref.watch(autoTagTranslationProvider);
      final scheme = Theme.of(context).colorScheme;
      final label = context.l10n.wiki_autoTranslateTagsArticles;
      final status = auto.activeRequests > 0
          ? wikiTranslatingLabel(context)
          : auto.lastError;
      return Semantics(
        toggled: auto.enabled,
        child: IconButton(
          key: const ValueKey('wiki-auto-translate'),
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.standard,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          tooltip: status == null ? label : '$label\n$status',
          onPressed: () => unawaited(auto.setEnabled(!auto.enabled)),
          icon: TranslationIcon(
            busy: auto.activeRequests > 0,
            size: 18,
            color: auto.lastError != null
                ? scheme.error
                : auto.enabled
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      );
    },
  );

  Widget _readingLanguage({VoidCallback? refreshDialog}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        context.l10n.wiki_readingContent,
        style: Theme.of(context).textTheme.labelMedium,
      ),
      const SizedBox(height: 8),
      Row(
        key: const ValueKey('wiki-reading-content-controls'),
        children: [
          Expanded(
            child: SegmentedButton<WikiReadingMode>(
              key: const Key('wiki-reading-language'),
              style: _readingSegmentStyle(),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: WikiReadingMode.original,
                  label: _readingLabel(wikiReadingStateLabel(context, false)),
                ),
                ButtonSegment(
                  value: WikiReadingMode.translation,
                  label: _readingLabel(wikiReadingStateLabel(context, true)),
                ),
                ButtonSegment(
                  value: WikiReadingMode.bilingual,
                  label: _readingLabel(context.l10n.wiki_readingBilingual),
                ),
              ],
              selected: {_readingMode},
              onSelectionChanged: (values) {
                setState(() => _readingMode = values.first);
                refreshDialog?.call();
                _saveReadingSettings();
              },
            ),
          ),
          const SizedBox(width: 8),
          _autoTranslateButton(),
        ],
      ),
    ],
  );
}
