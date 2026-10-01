import 'dart:async';

import 'package:flutter/material.dart';
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
import '../../../data/models/prompt_block/prompt_block.dart';
import '../../providers/data_source_cache_provider.dart';
import '../../providers/prompt_block_library_provider.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import 'wiki_sidebar.dart';
import '../../widgets/common/translation_icon.dart';

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
  bool _wideArticle = false;
  bool _showTranslation = true;
  double _fontSize = 14;
  int _epoch = 0;
  int? _total;
  String? _selected;
  String? _importingTag;
  String? _loadError;
  List<CompletionCandidate> _items = const [];
  Future<TagWikiEntry?>? _article;
  Future<String?>? _translation;

  @override
  void initState() {
    super.initState();
    _autoTranslation = ref.read(autoTagTranslationProvider);
    _listScroll.addListener(_scheduleVisibleUpdate);
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
        _selectTag(normalized);
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
    _selectTag(tag);
    _load();
  }

  @override
  void dispose() {
    _autoTranslation.clearSurface(_listSurface);
    _autoTranslation.clearSurface(_articleSurface);
    _searchTimer?.cancel();
    _search.dispose();
    _listScroll.dispose();
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

  void _selectTag(String tag) {
    if (_selected == tag) return;
    ref.read(autoTagTranslationProvider).clearSurface(_articleSurface);
    final article = ref.read(tagWikiRepositoryProvider).find(tag);
    setState(() {
      _selected = tag;
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
        _selectTag(page.first.canonicalTag);
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

  Color _categoryColor(BuildContext context, TagCategory category) =>
      switch (category) {
        TagCategory.artist => Colors.red.shade700,
        TagCategory.copyright => Colors.purple.shade700,
        TagCategory.character => Colors.green.shade700,
        TagCategory.meta => Colors.orange.shade800,
        _ => Theme.of(context).colorScheme.onSurfaceVariant,
      };

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

  bool _isInBlockLibrary(String tag) {
    final state = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    if (state == null) return false;
    return state.blocks.any((block) => _singleTagBlock(block, tag));
  }

  bool _singleTagBlock(PromptBlock block, String tag) {
    final atoms = block.atomsOrSplit;
    return atoms.length == 1 &&
        TagNormalizer.normalize(atoms.first) == tag &&
        block.negativeAtomsOrSplit.isEmpty;
  }

  Future<void> _importBlock(String tag) async {
    if (_importingTag != null) return;
    setState(() => _importingTag = tag);
    try {
      await ref.read(promptBlockLibraryNotifierProvider.future);
      if (_isInBlockLibrary(tag)) return;
      final content = TagNormalizer.toDisplay(tag);
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .createBlock(title: content, content: content, atoms: [content]);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _importingTag = null);
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
        final showRail = constraints.maxWidth >= 1270 && _railOpen;
        final listWidth = constraints.maxWidth < 1040 ? 252.0 : 312.0;
        return Row(
          children: [
            WikiSidebar(
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
                    child: Row(
                      children: [
                        SizedBox(width: listWidth, child: _results(bookmarks)),
                        Expanded(child: _detail(bookmarks)),
                        if (showRail) _readingRail(),
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

  Widget _toolbar() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reserved = WindowChromeScope.activeOf(context)
        ? WindowChromeScope.reservedWidthOf(context)
        : 0.0;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 54,
            child: Padding(
              padding: EdgeInsets.only(left: 17, right: reserved + 10),
              child: Row(
                children: [
                  Text(
                    context.l10n.wiki_title,
                    style: theme.textTheme.titleMedium?.copyWith(
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
                  IconButton(
                    key: const ValueKey('wiki-auto-translate'),
                    tooltip:
                        ref.read(autoTagTranslationProvider).lastError ??
                        (Localizations.localeOf(context).languageCode == 'zh'
                            ? '自动翻译可见标签与打开的百科'
                            : 'Auto-translate visible tags and open articles'),
                    onPressed: () {
                      final auto = ref.read(autoTagTranslationProvider);
                      unawaited(auto.setEnabled(!auto.enabled));
                    },
                    icon: TranslationIcon(
                      busy:
                          ref.read(autoTagTranslationProvider).activeRequests >
                          0,
                      size: 18,
                      color:
                          ref.read(autoTagTranslationProvider).lastError != null
                          ? scheme.error
                          : ref.read(autoTagTranslationProvider).enabled
                          ? scheme.primary
                          : null,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: TextField(
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
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 7,
                          ),
                        ),
                        onChanged: (_) => _queueSearch(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 43,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _scope?.label ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_search.text.isNotEmpty &&
                      _scope?.kind != WikiScopeKind.all)
                    _toolbarChoice(
                      value: _searchAll,
                      label: _searchAll
                          ? context.l10n.wiki_scopeAll
                          : context.l10n.wiki_scopeCurrent,
                      onTap: () =>
                          _changeFilter(() => _searchAll = !_searchAll),
                    ),
                  const Spacer(),
                  _menu<TagCategory?>(
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
                  const SizedBox(width: 5),
                  _menu<bool?>(
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
                  const SizedBox(width: 5),
                  _menu<bool>(
                    tooltip: context.l10n.wiki_sortPopular,
                    label: _alphabetical
                        ? context.l10n.wiki_sortName
                        : context.l10n.wiki_sortPopular,
                    items: const [false, true],
                    itemLabel: (item) => item
                        ? context.l10n.wiki_sortName
                        : context.l10n.wiki_sortPopular,
                    onSelect: (item) =>
                        _changeFilter(() => _alphabetical = item),
                  ),
                  const SizedBox(width: 5),
                  PopupMenuButton<String>(
                    tooltip: context.l10n.wiki_dataStatus,
                    icon: const Icon(Icons.storage_outlined, size: 18),
                    itemBuilder: (context) {
                      final state = ref
                          .read(danbooruTagsCacheNotifierProvider)
                          .valueOrNull;
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
                  ),
                  if (!_railOpen || MediaQuery.sizeOf(context).width < 1330)
                    IconButton(
                      tooltip: context.l10n.wiki_readingSettings,
                      icon: const Icon(Icons.tune, size: 18),
                      onPressed: () => _showReadingDialog(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarChoice({
    required bool value,
    required String label,
    required VoidCallback onTap,
  }) => TextButton.icon(
    onPressed: onTap,
    icon: Icon(value ? Icons.public : Icons.folder_outlined, size: 15),
    label: Text(label, style: const TextStyle(fontSize: 11.5)),
  );

  Widget _menu<T>({
    required String tooltip,
    required String label,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T> onSelect,
  }) => PopupMenuButton<T>(
    tooltip: tooltip,
    onSelected: onSelect,
    itemBuilder: (context) => [
      for (final item in items)
        PopupMenuItem<T>(
          value: item,
          height: 35,
          child: Text(itemLabel(item), style: const TextStyle(fontSize: 12.5)),
        ),
    ],
    child: Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(6),
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
      if (!mounted || !_listScroll.hasClients) return;
      final position = _listScroll.position;
      final first = (position.pixels / 57).floor().clamp(0, _items.length);
      final last = ((position.pixels + position.viewportDimension) / 57)
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
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
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
                    controller: _listScroll,
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
                      return Material(
                        color: selected
                            ? scheme.primaryContainer.withValues(alpha: .48)
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectTag(tag),
                          child: SizedBox(
                            height: 57,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? scheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          TagNormalizer.toDisplay(tag),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          translatedName ??
                                              _categoryName(candidate.category),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: translatedName == null
                                                ? _categoryColor(
                                                    context,
                                                    candidate.category,
                                                  )
                                                : scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _postCount(candidate.postCount),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  IconButton(
                                    tooltip: bookmarks.contains(tag)
                                        ? context.l10n.wiki_removeBookmark
                                        : context.l10n.wiki_addBookmark,
                                    visualDensity: VisualDensity.compact,
                                    iconSize: 17,
                                    onPressed: () async {
                                      await bookmarks.toggle(tag);
                                      if (_scope?.kind ==
                                              WikiScopeKind.bookmarks ||
                                          _scope?.kind ==
                                              WikiScopeKind.collection) {
                                        _load();
                                      }
                                    },
                                    icon: Icon(
                                      bookmarks.contains(tag)
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detail(WikiBookmarkStore bookmarks) {
    ref.watch(promptBlockLibraryNotifierProvider);
    final tag = _selected;
    if (tag == null) return Center(child: Text(context.l10n.wiki_noSelection));
    final scheme = Theme.of(context).colorScheme;
    final candidate = _items
        .where((item) => item.canonicalTag == tag)
        .firstOrNull;
    return Container(
      color: scheme.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 17, 15, 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TagNormalizer.toDisplay(tag),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          if (candidate != null) ...[
                            Icon(
                              Icons.label_outline,
                              size: 15,
                              color: _categoryColor(
                                context,
                                candidate.category,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _categoryName(candidate.category),
                              style: TextStyle(
                                fontSize: 12,
                                color: _categoryColor(
                                  context,
                                  candidate.category,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _postCount(candidate.postCount),
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(width: 12),
                          Flexible(
                            child: FutureBuilder<String?>(
                              future: _translation,
                              builder: (context, snapshot) => Text(
                                snapshot.data ??
                                    ref
                                        .read(autoTagTranslationProvider)
                                        .nameFor(tag) ??
                                    '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: bookmarks.contains(tag)
                      ? context.l10n.wiki_removeBookmark
                      : context.l10n.wiki_addBookmark,
                  onPressed: () => bookmarks.toggle(tag),
                  icon: Icon(
                    bookmarks.contains(tag)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    size: 21,
                  ),
                ),
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
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _wideArticle ? 1040 : 760,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 25, 28, 35),
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
                        final translated = ref
                            .read(autoTagTranslationProvider)
                            .wikiFor(tag);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              article?.body.trim().isNotEmpty == true
                                  ? (_showTranslation
                                        ? translated ?? article!.body
                                        : article!.body)
                                  : context.l10n.wiki_articleMissing,
                              style: TextStyle(
                                fontSize: _fontSize,
                                height: 1.68,
                                color: scheme.onSurface,
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
                            if (article != null && article.sourceUrl.isNotEmpty)
                              TextButton.icon(
                                icon: const Icon(Icons.open_in_new, size: 15),
                                label: Text(context.l10n.wiki_source),
                                onPressed: () =>
                                    launchUrl(Uri.parse(article.sourceUrl)),
                              ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              icon: const Icon(
                                Icons.library_add_outlined,
                                size: 17,
                              ),
                              label: Text(
                                _isInBlockLibrary(tag)
                                    ? context.l10n.wiki_inBlockLibrary
                                    : context.l10n.wiki_importBlock,
                              ),
                              onPressed:
                                  _isInBlockLibrary(tag) ||
                                      _importingTag != null
                                  ? null
                                  : () => _importBlock(tag),
                            ),
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

  Widget _readingRail() {
    final theme = Theme.of(context);
    return Container(
      width: 186,
      padding: const EdgeInsets.fromLTRB(15, 19, 14, 15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
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
          Text(context.l10n.wiki_textSize, style: theme.textTheme.labelMedium),
          const SizedBox(height: 9),
          SegmentedButton<double>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 12, label: Text(context.l10n.wiki_small)),
              ButtonSegment(value: 14, label: Text(context.l10n.wiki_standard)),
              ButtonSegment(value: 17, label: Text(context.l10n.wiki_large)),
            ],
            selected: {_fontSize},
            onSelectionChanged: (values) {
              setState(() => _fontSize = values.first);
              _saveReadingSettings();
            },
          ),
          const SizedBox(height: 22),
          Text(
            context.l10n.wiki_readingWidth,
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                label: Text(context.l10n.wiki_standard),
              ),
              ButtonSegment(value: true, label: Text(context.l10n.wiki_wide)),
            ],
            selected: {_wideArticle},
            onSelectionChanged: (values) {
              setState(() => _wideArticle = values.first);
              _saveReadingSettings();
            },
          ),
          const SizedBox(height: 22),
          _readingLanguage(),
        ],
      ),
    );
  }

  Widget _readingLanguage({VoidCallback? refreshDialog}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('阅读内容', style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 8),
      SegmentedButton<bool>(
        key: const Key('wiki-reading-language'),
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: false, label: Text('原文')),
          ButtonSegment(value: true, label: Text('译文')),
        ],
        selected: {_showTranslation},
        onSelectionChanged: (values) {
          setState(() => _showTranslation = values.first);
          refreshDialog?.call();
          _saveReadingSettings();
        },
      ),
    ],
  );

  Future<void> _showReadingDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.wiki_readingSettings),
        content: StatefulBuilder(
          builder: (context, update) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.wiki_textSize),
              const SizedBox(height: 8),
              SegmentedButton<double>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: 12,
                    label: Text(context.l10n.wiki_small),
                  ),
                  ButtonSegment(
                    value: 14,
                    label: Text(context.l10n.wiki_standard),
                  ),
                  ButtonSegment(
                    value: 17,
                    label: Text(context.l10n.wiki_large),
                  ),
                ],
                selected: {_fontSize},
                onSelectionChanged: (values) {
                  update(() => _fontSize = values.first);
                  setState(() {});
                  _saveReadingSettings();
                },
              ),
              const SizedBox(height: 18),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.wiki_readingWidth),
                subtitle: Text(
                  _wideArticle
                      ? context.l10n.wiki_wide
                      : context.l10n.wiki_standard,
                ),
                value: _wideArticle,
                onChanged: (value) {
                  update(() => _wideArticle = value);
                  setState(() {});
                  _saveReadingSettings();
                },
              ),
              const SizedBox(height: 18),
              _readingLanguage(refreshDialog: () => update(() {})),
            ],
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
