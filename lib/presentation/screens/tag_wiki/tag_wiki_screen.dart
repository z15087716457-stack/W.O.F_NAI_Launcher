import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/autocomplete/completion_models.dart';
import '../../../core/autocomplete/tag_translation_lookup.dart';
import '../../../core/tag_expansion/tag_expansion_providers.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/tag_normalizer.dart';
import '../../../core/wiki/tag_wiki_repository.dart';
import '../../../core/wiki/auto_tag_translation_controller.dart';
import '../../../core/wiki/wiki_bookmark_store.dart';
import '../../../core/wiki/wiki_directory.dart';
import '../../providers/data_source_cache_provider.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../../widgets/autocomplete/tag_category_visuals.dart';
import 'wiki_sidebar.dart';
import 'wiki_tag_row.dart';
import 'wiki_article_outline.dart';
import '../../widgets/common/translation_icon.dart';
import '../../widgets/common/wiki_linked_body.dart';
import '../../widgets/common/wiki_retranslate_button.dart';

class _WikiMenuValue<T> {
  const _WikiMenuValue(this.value);
  final T value;
}

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
    required this.translation,
    required this.total,
    required this.more,
    required this.loading,
    required this.loadError,
    required this.listOffset,
    required this.articleOffset,
    required this.showTranslation,
    required this.linkedCandidate,
  });
  final TextEditingValue query;
  final WikiScope? scope;
  final TagCategory? category;
  final bool? hasArticle;
  final bool alphabetical, searchAll, more, loading, showTranslation;
  final String selected;
  final String? loadError;
  final List<CompletionCandidate> items;
  final Future<TagWikiEntry?>? article;
  final Future<String?>? translation;
  final int? total;
  final double listOffset, articleOffset;
  final CompletionCandidate? linkedCandidate;
}

class TagWikiScreen extends ConsumerStatefulWidget {
  const TagWikiScreen({super.key, this.initialTag, this.directory});

  final String? initialTag;
  final WikiDirectory? directory;

  @override
  ConsumerState<TagWikiScreen> createState() => _TagWikiScreenState();
}

class _TagWikiScreenState extends ConsumerState<TagWikiScreen> {
  static const _pageSize = 80;
  final _search = TextEditingController();
  final _listScroll = ScrollController();
  final _articleScroll = ScrollController();
  final _history = <_WikiVisit>[];
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
  bool _railOpen = true;
  bool _singlePane = false;
  bool _compactNavigation = false;
  bool _showCompactArticle = false;
  bool _showRail = false;
  bool _railAvailable = false;
  bool _outlineOpen = true;
  String? _outlineBody;
  String? _outlineTag;
  List<WikiArticleHeading> _headings = [];
  final _articleStart = GlobalKey();
  final _articleViewport = GlobalKey();
  final _toolbarKey = GlobalKey();
  double _toolbarHeight = 63;
  bool _headerScheduled = false;
  GlobalKey? _activeOutline;
  bool _outlineScheduled = false;
  bool _wideArticle = false;
  bool _showTranslation = true;
  double _fontSize = 14;
  int _epoch = 0;
  int? _total;
  String? _selected;
  String? _loadError;
  List<CompletionCandidate> _items = const [];
  Future<TagWikiEntry?>? _article;
  Future<String?>? _translation;

  @override
  void initState() {
    super.initState();
    _autoTranslation = ref.read(autoTagTranslationProvider);
    _listScroll.addListener(_scheduleVisibleUpdate);
    _articleScroll.addListener(_scheduleOutlineUpdate);
    _initialize();
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
        _showTranslation = prefs.getBool('wiki_show_translation') ?? true;
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
  void didUpdateWidget(covariant TagWikiScreen oldWidget) {
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
    _selectTag(tag, remember: false);
    _load();
  }

  @override
  void dispose() {
    _autoTranslation.clearSurface(_listSurface);
    _autoTranslation.clearSurface(_articleSurface);
    _searchTimer?.cancel();
    _search.dispose();
    _listScroll.dispose();
    _articleScroll.dispose();
    super.dispose();
  }

  void _selectScope(WikiScope scope) {
    if (_scope?.matches(scope) == true) return;
    setState(() {
      _scope = scope;
      _searchAll = false;
      _selected = null;
      _article = null;
      _translation = null;
    });
    ref.read(autoTagTranslationProvider).clearSurface(_articleSurface);
    if (_listScroll.hasClients) _listScroll.jumpTo(0);
    _load();
  }

  void _selectTag(
    String tag, {
    bool remember = true,
    bool reveal = true,
    CompletionCandidate? linkedCandidate,
  }) {
    if (_selected == tag) {
      if (reveal && !_showCompactArticle) {
        setState(() => _showCompactArticle = true);
      }
      return;
    }
    if (remember && _selected != null) {
      _history.add(
        _WikiVisit(
          query: _search.value,
          scope: _scope,
          category: _category,
          hasArticle: _hasArticle,
          alphabetical: _alphabetical,
          searchAll: _searchAll,
          selected: _selected!,
          items: _items,
          article: _article,
          translation: _translation,
          total: _total,
          more: _more,
          loading: _loading,
          loadError: _loadError,
          showTranslation: _showTranslation,
          listOffset: _listScroll.hasClients ? _listScroll.offset : 0,
          articleOffset: _articleScroll.hasClients ? _articleScroll.offset : 0,
          linkedCandidate: _linkedCandidate,
        ),
      );
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
      _translation = ref.read(tagTranslationLookupProvider).translate(tag);
    });
    unawaited(
      article.then((entry) {
        if (!mounted ||
            _selected != tag ||
            entry?.body.trim().isNotEmpty != true) {
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

  void _goBack() {
    if (_history.isEmpty) return;
    final visit = _history.removeLast();
    _searchTimer?.cancel();
    _epoch++;
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
      _translation = visit.translation;
      _total = visit.total;
      _more = visit.more;
      _loading = false;
      _loadError = visit.loadError;
      _showTranslation = visit.showTranslation;
      _linkedCandidate = visit.linkedCandidate;
      _restoreArticleOffset = visit.articleOffset;
    });
    if (visit.loading) _load();
    _saveReadingSettings();
    _article?.then((entry) {
      if (mounted && _selected == visit.selected && entry != null) {
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
    if (RegExp(r'[\u3400-\u9fff]').hasMatch(normalized)) {
      final translated = await ref
          .read(localTagExpansionServiceProvider)
          .search(
            text,
            locale: Localizations.localeOf(context).toLanguageTag(),
            limit: 300,
          );
      final canonical = await source.byNames(
        translated.map((candidate) => candidate.canonicalTag),
      );
      final byName = {
        for (final candidate in translated) candidate.canonicalTag: candidate,
      };
      return [
        for (final candidate in canonical)
          candidate.copyWith(
            translation: byName[candidate.canonicalTag]?.translation,
          ),
      ];
    }
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
      });
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

  void _changeFilter(VoidCallback change) {
    ref.read(autoTagTranslationProvider).clearSurface(_articleSurface);
    setState(() {
      change();
      _selected = null;
      _article = null;
      _translation = null;
    });
    if (_listScroll.hasClients) _listScroll.jumpTo(0);
    _load();
  }

  void _queueSearch({bool immediate = false}) {
    ref.read(autoTagTranslationProvider).clearSurface(_articleSurface);
    setState(() {
      _selected = null;
      _article = null;
      _translation = null;
    });
    _searchTimer?.cancel();
    if (immediate) {
      _load();
    } else {
      _searchTimer = Timer(const Duration(milliseconds: 180), _load);
    }
  }

  String _categoryName(TagCategory category) {
    final chinese = Localizations.localeOf(context).languageCode == 'zh';
    return switch (category) {
      TagCategory.general => chinese ? '一般' : 'General',
      TagCategory.artist => chinese ? '画师' : 'Artist',
      TagCategory.copyright => chinese ? '作品' : 'Copyright',
      TagCategory.character => chinese ? '角色' : 'Character',
      TagCategory.meta => chinese ? '元标签' : 'Meta',
      TagCategory.contributor => chinese ? '贡献者' : 'Contributor',
      TagCategory.species => chinese ? '物种' : 'Species',
      TagCategory.lore => chinese ? '设定' : 'Lore',
      TagCategory.library => chinese ? '本地' : 'Library',
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
    await prefs.setBool('wiki_show_translation', _showTranslation);
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        _compactNavigation = constraints.maxWidth < 1000;
        _singlePane = constraints.maxWidth < 720 * scale.clamp(1, 1.25);
        _railAvailable = constraints.maxWidth >= 1340 * scale.clamp(1, 1.2);
        _showRail = _railAvailable && _railOpen;
        _scheduleVisibleUpdate();
        final listWidth = 300.0 * scale.clamp(1, 1.25);
        return Row(
          children: [
            if (!_compactNavigation)
              WikiSidebar(
                headerHeight: _toolbarHeight - 1,
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
                              if (_showRail) _readingRail(),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
        if (_compactNavigation)
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
        if (_total != null) ...[
          const SizedBox(width: 7),
          Text(
            '$_total',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (!_showRail)
          IconButton(
            key: const ValueKey('wiki-reading-button'),
            tooltip: context.l10n.wiki_readingSettings,
            onPressed: () {
              if (_railAvailable && !_railOpen) {
                setState(() => _railOpen = true);
              } else {
                _showReadingDialog();
              }
            },
            icon: const Icon(Icons.tune, size: 18),
          ),
      ],
    );
    final search = TextField(
      key: const ValueKey('wiki-search'),
      controller: _search,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.search, size: 17),
        hintText: context.l10n.wiki_searchHint,
        hintStyle: const TextStyle(fontSize: 12.5),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  _search.clear();
                  _queueSearch(immediate: true);
                },
              ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      onChanged: (_) => _queueSearch(),
    );
    return WindowHeader(
      key: _toolbarKey,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: constraints.maxWidth < 700
              ? Column(
                  children: [
                    Align(alignment: Alignment.centerLeft, child: title),
                    const SizedBox(height: 4),
                    search,
                  ],
                )
              : Row(
                  children: [
                    title,
                    const SizedBox(width: 14),
                    Expanded(child: search),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _resultsToolbar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
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
              if (_search.text.isNotEmpty && _scope?.kind != WikiScopeKind.all)
                _toolbarChoice(
                  value: _searchAll,
                  label: _searchAll
                      ? context.l10n.wiki_scopeAll
                      : context.l10n.wiki_scopeCurrent,
                  onTap: () => _changeFilter(() => _searchAll = !_searchAll),
                ),
              _dataMenu(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _menu<TagCategory?>(
                  key: const ValueKey('wiki-type-filter'),
                  tooltip: context.l10n.wiki_typeAll,
                  label: _category == null
                      ? context.l10n.wiki_typeAll
                      : _categoryName(_category!),
                  items: [
                    null,
                    ...TagCategory.values.where(
                      (item) => item != TagCategory.library,
                    ),
                  ],
                  itemLabel: (item) => item == null
                      ? context.l10n.wiki_typeAll
                      : _categoryName(item),
                  onSelect: (item) => _changeFilter(() => _category = item),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _menu<bool?>(
                  key: const ValueKey('wiki-coverage-filter'),
                  tooltip: context.l10n.wiki_coverageAll,
                  label: _hasArticle == null
                      ? context.l10n.wiki_coverageAll
                      : _hasArticle!
                      ? context.l10n.wiki_withArticle
                      : context.l10n.wiki_withoutArticle,
                  items: const [null, true, false],
                  itemLabel: (item) => item == null
                      ? context.l10n.wiki_coverageAll
                      : item
                      ? context.l10n.wiki_withArticle
                      : context.l10n.wiki_withoutArticle,
                  onSelect: (item) => _changeFilter(() => _hasArticle = item),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _menu<bool>(
                  key: const ValueKey('wiki-sort-filter'),
                  tooltip: context.l10n.wiki_sortPopular,
                  label: _alphabetical
                      ? context.l10n.wiki_sortName
                      : context.l10n.wiki_sortPopular,
                  items: const [false, true],
                  itemLabel: (item) => item
                      ? context.l10n.wiki_sortName
                      : context.l10n.wiki_sortPopular,
                  onSelect: (item) => _changeFilter(() => _alphabetical = item),
                ),
              ),
            ],
          ),
        ],
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

  Widget _menu<T>({
    Key? key,
    required String tooltip,
    required String label,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T> onSelect,
  }) => PopupMenuButton<_WikiMenuValue<T>>(
    key: key,
    tooltip: tooltip,
    onSelected: (item) => onSelect(item.value),
    itemBuilder: (context) => [
      for (final item in items)
        PopupMenuItem<_WikiMenuValue<T>>(
          value: _WikiMenuValue(item),
          height: 35,
          child: Text(itemLabel(item), style: const TextStyle(fontSize: 12.5)),
        ),
    ],
    child: Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5),
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 16),
        ],
      ),
    ),
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
                        onSelect: () => _selectTag(tag),
                        onBookmark: () => _toggleBookmark(bookmarks, tag),
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

  Widget _articleHeader(
    WikiBookmarkStore bookmarks,
    CompletionCandidate? candidate,
  ) {
    final tag = _selected!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = Tooltip(
      message: TagNormalizer.toDisplay(tag),
      child: Text(
        TagNormalizer.toDisplay(tag),
        key: const ValueKey('wiki-article-title'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 23,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final metadata = Wrap(
      key: const ValueKey('wiki-article-metadata'),
      spacing: 10,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (candidate != null) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                TagCategoryVisuals.icon(candidate.category),
                key: const ValueKey('wiki-article-category-icon'),
                size: 14,
                color: TagCategoryVisuals.color(context, candidate.category),
              ),
              const SizedBox(width: 4),
              Text(
                _categoryName(candidate.category),
                key: const ValueKey('wiki-article-category-label'),
                style: TextStyle(
                  fontSize: 12,
                  color: TagCategoryVisuals.color(context, candidate.category),
                ),
              ),
            ],
          ),
          Text(
            _postCount(candidate.postCount),
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
        FutureBuilder<String?>(
          future: _translation,
          builder: (context, snapshot) => Text(
            snapshot.data ??
                ref.read(autoTagTranslationProvider).nameFor(tag) ??
                candidate?.translation ??
                '',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: scheme.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      minimumSize: const Size(0, 30),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: theme.textTheme.labelMedium?.copyWith(fontSize: 12),
    );
    final actions = Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Tooltip(
          message: bookmarks.contains(tag)
              ? context.l10n.wiki_removeBookmark
              : context.l10n.wiki_addBookmark,
          child: OutlinedButton.icon(
            key: const ValueKey('wiki-article-bookmark'),
            style: buttonStyle,
            onPressed: () => _toggleBookmark(bookmarks, tag),
            icon: Icon(
              bookmarks.contains(tag) ? Icons.bookmark : Icons.bookmark_border,
              size: 17,
            ),
            label: Text(
              bookmarks.contains(tag)
                  ? context.l10n.common_unfavorite
                  : context.l10n.common_favorite,
            ),
          ),
        ),
        OutlinedButton.icon(
          key: const ValueKey('wiki-copy-tag'),
          style: buttonStyle,
          icon: const Icon(Icons.content_copy_outlined, size: 17),
          label: Text(context.l10n.common_copy),
          onPressed: () => _copyTag(tag),
        ),
        if (bookmarks.collections.isNotEmpty) _collectionMenu(bookmarks, tag),
      ],
    );
    final back = (_history.isNotEmpty || _singlePane)
        ? IconButton(
            key: const ValueKey('wiki-article-back'),
            tooltip: _history.isNotEmpty
                ? wikiBackLabel(context)
                : context.l10n.wiki_allTags,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            visualDensity: VisualDensity.standard,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _history.isNotEmpty
                ? _goBack
                : () => setState(() => _showCompactArticle = false),
            icon: const Icon(
              Icons.arrow_back,
              key: ValueKey('wiki-back-glyph'),
              size: 19,
            ),
          )
        : null;
    return Container(
      key: const ValueKey('wiki-article-header'),
      // Compensate for the arrow's 4.5px optical inset inside its 28px target.
      padding: EdgeInsets.fromLTRB(back == null ? 24 : 19.5, 20, 24, 18),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final compact = constraints.maxWidth < 650 * scale;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (back != null) ...[back, const SizedBox(width: 8)],
                  Expanded(child: title),
                  if (!compact) ...[const SizedBox(width: 18), actions],
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.only(left: back == null ? 0 : 36),
                child: metadata,
              ),
              if (compact) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: EdgeInsets.only(left: back == null ? 0 : 4.5),
                  child: actions,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _collectionMenu(WikiBookmarkStore bookmarks, String tag) =>
      PopupMenuButton<String>(
        tooltip: context.l10n.wiki_addToCollection,
        icon: const Icon(Icons.more_vert, size: 20),
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
      );

  String _visibleBody(TagWikiEntry? article) {
    if (article?.body.trim().isNotEmpty != true) {
      return context.l10n.wiki_articleMissing;
    }
    final auto = ref.read(autoTagTranslationProvider);
    return _showTranslation
        ? auto.wikiFor(_selected!) ?? article!.body
        : auto.wikiOriginalFor(_selected!) ?? article!.body;
  }

  List<WikiArticleHeading> _outlineFor(String body) {
    if (_outlineTag != _selected || _outlineBody != body) {
      _outlineTag = _selected;
      _outlineBody = body;
      _headings = wikiArticleHeadings(body);
      _activeOutline = null;
    }
    _scheduleOutlineUpdate();
    return _headings;
  }

  void _scheduleHeaderUpdate() {
    if (_headerScheduled) return;
    _headerScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _headerScheduled = false;
      if (!mounted || _compactNavigation) return;
      final render = _toolbarKey.currentContext?.findRenderObject();
      if (render is RenderBox &&
          render.hasSize &&
          (render.size.height - _toolbarHeight).abs() > .1) {
        setState(() => _toolbarHeight = render.size.height);
      }
    });
  }

  void _jumpToOutline(GlobalKey anchor) {
    if (!_articleScroll.hasClients) return;
    if (anchor == _articleStart) {
      _articleScroll.jumpTo(0);
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
      for (final heading in _headings) {
        final render = heading.anchor.currentContext?.findRenderObject();
        if (render is RenderBox &&
            render.hasSize &&
            render.localToGlobal(Offset.zero).dy <= top) {
          active = heading.anchor;
        }
      }
      if (active != _activeOutline) setState(() => _activeOutline = active);
    });
  }

  Widget _articleOutline() => FutureBuilder<TagWikiEntry?>(
    future: _article,
    builder: (context, snapshot) {
      if (_selected == null ||
          snapshot.connectionState != ConnectionState.done ||
          snapshot.hasError) {
        return const SizedBox.shrink();
      }
      final headings = _outlineFor(_visibleBody(snapshot.data));
      if (headings.isEmpty) return const SizedBox.shrink();
      final lang = Localizations.localeOf(context).languageCode;
      final label = switch (lang) {
        'zh' => '本文目录',
        'ja' => '目次',
        'ko' => '목차',
        _ => 'On this page',
      };
      final intro = switch (lang) {
        'zh' => '简介',
        'ja' => '概要',
        'ko' => '개요',
        _ => 'Overview',
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _outlineOpen = !_outlineOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _outlineOpen ? Icons.expand_less : Icons.expand_more,
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
          if (_outlineOpen) ...[
            _outlineLink(
              intro,
              _articleStart,
              selected: _activeOutline == null,
            ),
            for (var index = 0; index < headings.length; index++)
              _outlineLink(
                headings[index].label,
                headings[index].anchor,
                selected: _activeOutline == headings[index].anchor,
                index: index,
                indent: (headings[index].level - 1).clamp(0, 2) * 8.0,
              ),
          ],
        ],
      );
    },
  );

  Widget _outlineLink(
    String label,
    GlobalKey anchor, {
    required bool selected,
    int? index,
    double indent = 0,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton(
      key: index == null
          ? const ValueKey('wiki-outline-intro')
          : ValueKey('wiki-outline-$index'),
      style: TextButton.styleFrom(
        foregroundColor: selected ? scheme.primary : scheme.onSurfaceVariant,
        padding: EdgeInsets.only(left: indent, right: 4, top: 9, bottom: 9),
        minimumSize: const Size(0, 32),
        visualDensity: VisualDensity.compact,
      ),
      onPressed: () => _jumpToOutline(anchor),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 15,
            color: selected ? scheme.primary : Colors.transparent,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(WikiBookmarkStore bookmarks) {
    final tag = _selected;
    if (tag == null) return Center(child: Text(context.l10n.wiki_noSelection));
    final scheme = Theme.of(context).colorScheme;
    final candidate =
        _linkedCandidate ??
        _items.where((item) => item.canonicalTag == tag).firstOrNull;
    return Container(
      color: scheme.surface,
      child: Column(
        children: [
          _articleHeader(bookmarks, candidate),
          Expanded(
            child: SingleChildScrollView(
              key: _articleViewport,
              controller: _articleScroll,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  key: const ValueKey('wiki-reading-column'),
                  constraints: BoxConstraints.tightFor(
                    width: _wideArticle ? 1040 : 760,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 25, 24, 35),
                    child: FutureBuilder<TagWikiEntry?>(
                      future: _article,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(30),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (snapshot.hasError) return Text('${snapshot.error}');
                        final article = snapshot.data;
                        if (_restoreArticleOffset case final offset?) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
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
                                  _articleScroll.position.maxScrollExtent,
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
                            KeyedSubtree(
                              key: _articleStart,
                              child: WikiLinkedBody(
                                key: ValueKey('wiki-body-$tag'),
                                body: _visibleBody(article),
                                headingAnchors: _outlineFor(
                                  _visibleBody(article),
                                ).map((heading) => heading.anchor).toList(),
                                style: TextStyle(
                                  fontSize: _fontSize,
                                  height: 1.68,
                                  color: scheme.onSurface,
                                ),
                                onTagTap: (candidate) => _selectTag(
                                  candidate.canonicalTag,
                                  linkedCandidate: candidate,
                                ),
                              ),
                            ),
                            if (_showTranslation &&
                                translated == null &&
                                article?.body.trim().isNotEmpty == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  '暂未翻译',
                                  key: const Key('wiki-untranslated'),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            const SizedBox(height: 26),
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                key: const ValueKey('wiki-article-footer'),
                                alignment: article?.sourceUrl.isNotEmpty == true
                                    ? WrapAlignment.spaceBetween
                                    : WrapAlignment.end,
                                crossAxisAlignment: WrapCrossAlignment.center,
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
                                      label: Text(context.l10n.wiki_source),
                                      style: TextButton.styleFrom(
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(fontSize: 14),
                                        minimumSize: const Size(0, 32),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        visualDensity: VisualDensity.standard,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
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
                                      showTranslation: _showTranslation,
                                      onToggle: () {
                                        setState(
                                          () => _showTranslation =
                                              !_showTranslation,
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
      final label = switch (Localizations.localeOf(context).languageCode) {
        'zh' => '自动翻译标签与百科',
        'ja' => 'タグと百科を自動翻訳',
        'ko' => '태그 및 백과 자동 번역',
        _ => 'Auto-translate tags and articles',
      };
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

  Widget _readingRail() {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('wiki-reading-rail'),
      width:
          216 * (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1, 1.3),
      padding: const EdgeInsets.fromLTRB(15, 19, 14, 15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.wiki_readingSettings,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.wiki_hide,
                  icon: const Icon(Icons.chevron_right, size: 18),
                  onPressed: () => setState(() => _railOpen = false),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.wiki_textSize,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 9),
            _textSizeChoice(),
            const SizedBox(height: 22),
            Text(
              context.l10n.wiki_readingWidth,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            _widthChoice(),
            const SizedBox(height: 22),
            _readingLanguage(),
            _articleOutline(),
          ],
        ),
      ),
    );
  }

  Widget _readingLanguage({VoidCallback? refreshDialog}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(switch (Localizations.localeOf(context).languageCode) {
        'zh' => '阅读内容',
        'ja' => '表示内容',
        'ko' => '읽기 내용',
        _ => 'Content',
      }, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 8),
      Row(
        key: const ValueKey('wiki-reading-content-controls'),
        children: [
          Expanded(
            child: SegmentedButton<bool>(
              key: const Key('wiki-reading-language'),
              style: _readingSegmentStyle(),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: false,
                  label: _readingLabel(wikiReadingStateLabel(context, false)),
                ),
                ButtonSegment(
                  value: true,
                  label: _readingLabel(wikiReadingStateLabel(context, true)),
                ),
              ],
              selected: {_showTranslation},
              onSelectionChanged: (values) {
                setState(() => _showTranslation = values.first);
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

  Future<void> _showReadingDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(context.l10n.wiki_readingSettings),
        content: SizedBox(
          width: 300,
          child: StatefulBuilder(
            builder: (context, update) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.wiki_textSize),
                const SizedBox(height: 8),
                _textSizeChoice(refreshDialog: () => update(() {})),
                const SizedBox(height: 18),
                Text(context.l10n.wiki_readingWidth),
                const SizedBox(height: 8),
                _widthChoice(refreshDialog: () => update(() {})),
                const SizedBox(height: 18),
                _readingLanguage(refreshDialog: () => update(() {})),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.wiki_hide),
          ),
        ],
      ),
    );
  }
}
