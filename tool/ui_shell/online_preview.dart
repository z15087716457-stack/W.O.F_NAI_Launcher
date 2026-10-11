// 在线画廊预览：一个本地模拟器，按契约回调改假数据，让每个按钮在预览里都“真的”起作用。
// 只给 preview_main.dart 用，不进应用。
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nai_launcher/presentation/ui/online/online_contract.dart';
import 'package:nai_launcher/presentation/ui/online/online_fixture.dart';

/// 列表状态的预设（预览顶栏切换）。
enum OnlineScene { ready, loading, appendError, end, empty, error, signedOut }

final _images = <String, ImageProvider>{};

/// 优先用原型图（.devin/mockups/online/assets），没有就用生成的渐变图。
ImageProvider previewImage(String key) => _images.putIfAbsent(key, () {
  final f = File('../../mockups/online/assets/$key.jpg');
  return f.existsSync() ? FileImage(f) : OnlineFixture.gradient(key);
});

class OnlinePreviewSim extends ChangeNotifier {
  OnlinePreviewSim({required this.log});

  final ValueChanged<String> log;

  var scene = OnlineScene.ready;
  var source = OnlineSource.aiTag;
  final _modes = <OnlineSource, OnlineMode>{};
  final _queries = <OnlineSource, OnlineQuery>{
    OnlineSource.aiTag: const OnlineQuery(work: 'ocean'),
    OnlineSource.danbooru: const OnlineQuery(
      tags: ['shiroko_(blue_archive)', '1girl', '-comic'],
    ),
  };
  var filters = const OnlineFilters(timeRanges: OnlineFixture.timeRanges);
  var booruRatings = {OnlineRating.general, OnlineRating.sensitive};
  DateTimeRange? dateRange;
  var rankPeriod = 'current';
  var rankScale = OnlineRankScale.day;
  var rankDate = DateTime(2026, 10, 5);
  var recent = [...OnlineFixture.recent];
  var blacklist = [...OnlineFixture.blacklist.tags];
  var sync = true;
  var cardSize = OnlineCardSize.medium;
  var sidebar = true;
  var inspector = true;
  String? selected = 'c03';
  final _loadingDetail = <String>{};
  final favorited = <String>{'c16'};
  var collections = [
    const OnlineCollection(id: 'style', name: '画风参考', count: 58),
    const OnlineCollection(id: 'comp', name: '构图', count: 22),
    const OnlineCollection(id: 'color', name: '色彩', count: 42),
  ];
  String? collection;
  int? author;
  var pages = 1;
  var loadingMore = false;
  OnlineSendMode? remembered;
  var canReturn = false;

  OnlineMode get mode => _modes[source] ?? OnlineMode.search;
  OnlineQuery get query => _queries[source] ?? const OnlineQuery();

  void _set(VoidCallback f) {
    f();
    notifyListeners();
  }

  OnlineViewData get data {
    final statuses = [
      for (final s in OnlineFixture.sources)
        s.source == OnlineSource.danbooru && scene == OnlineScene.signedOut
            ? OnlineSourceStatus(
                source: s.source,
                ranking: true,
                favorites: true,
                favoritesWritable: true,
                ratings: true,
                dateRange: true,
                fuzzy: true,
                account: OnlineAccountState.signedOut,
              )
            : s,
    ];
    final booru = source != OnlineSource.aiTag;
    final base = OnlineFixture.view(
      image: previewImage,
      source: source,
      mode: mode,
      statuses: statuses,
      selectedKey: null,
      authorId: author,
      collectionId: collection,
    );
    var items = [
      for (var p = 0; p < pages; p++)
        for (final w in base.list.items)
          _work(
            w,
            p,
            favorited.contains(w.key) || mode == OnlineMode.favorites,
          ),
    ];
    final q = query;
    if (mode == OnlineMode.favorites && q.favoritesFilter.isNotEmpty) {
      final f = q.favoritesFilter.toLowerCase();
      items = [
        for (final w in items)
          if ('${w.title} ${w.author}'.toLowerCase().contains(f)) w,
      ];
    }
    final ended = scene == OnlineScene.end || pages >= 4;
    final list = switch (scene) {
      OnlineScene.loading => OnlineList(key: _listKey, loading: true),
      OnlineScene.empty => OnlineList(key: _listKey),
      OnlineScene.error => OnlineList(
        key: _listKey,
        error: 'AI TAG 响应超时（15 秒）',
      ),
      _ => OnlineList(
        key: _listKey,
        items: items,
        pages: pages,
        hasMore: !ended && mode != OnlineMode.favorites,
        loadingMore: loadingMore,
        blocked: ended ? 6 : null,
        appendError: scene == OnlineScene.appendError
            ? OnlineAppendError(page: pages + 1, reason: 'AI TAG 响应超时')
            : null,
      ),
    };
    final sel = list.items.where((w) => w.key == selected).firstOrNull;
    return OnlineViewData(
      source: source,
      sources: statuses,
      mode: mode,
      query: q,
      filters: booru
          ? OnlineFilters(ratings: booruRatings, dateRange: dateRange)
          : filters,
      ranking: OnlineRanking(
        period: rankPeriod,
        months: OnlineFixture.months,
        scale: rankScale,
        date: rankDate,
      ),
      recent: recent,
      favorites: source == OnlineSource.aiTag
          ? OnlineFavorites(
              total: favorited.length + 160,
              ungrouped: 41,
              collections: collections,
              authors: base.favorites?.authors ?? const [],
              collectionId: collection,
              authorId: author,
            )
          : null,
      blacklist: OnlineBlacklist(
        tags: blacklist,
        danbooruSync: sync,
        danbooruCount: 5,
      ),
      list: list,
      selectedKey: sel?.key,
      detail: sel == null
          ? null
          : booru
          ? OnlineFixture.booruDetail(sel)
          : OnlineFixture.aiTagDetail(
              sel,
              image: previewImage,
              loading: _loadingDetail.contains(sel.key),
            ),
      cardSize: cardSize,
      sidebarOpen: sidebar,
      inspectorOpen: inspector,
      send: OnlineSendContext(
        promptLength: 386,
        characterCount: 2,
        remembered: remembered,
      ),
      canReturn: canReturn,
    );
  }

  String get _listKey =>
      '${source.name}:${mode.name}:${query.work}:${query.prompt}:'
      '${query.tags.join(' ')}:$collection:$author:$rankPeriod';

  OnlineWork _work(OnlineWork w, int page, bool fav) => OnlineWork(
    key: page == 0 ? w.key : '${w.key}~$page',
    id: w.id + page * 10000,
    thumb: w.thumb,
    width: w.width,
    height: w.height,
    title: w.title,
    author: w.author,
    views: w.views,
    favorites: w.favorites,
    score: w.score,
    rating: w.rating,
    mediaCount: w.mediaCount,
    rank: w.rank == null ? null : w.rank! + page * 28,
    model: w.model,
    favorited: fav || favorited.contains('${w.key}~$page'),
  );

  OnlineActions get actions => OnlineActions(
    onSourceChanged: (s) => _set(() {
      source = s;
      selected = null;
      pages = 1;
    }),
    onModeChanged: (m) => _set(() {
      _modes[source] = m;
      pages = 1;
      selected = null;
    }),
    onSearch: (q) => _set(() {
      _queries[source] = q;
      pages = 1;
      final text = q.work.isNotEmpty ? q.work : q.tags.join(' ');
      if (text.isNotEmpty) {
        recent = [
          OnlineRecent(kind: OnlineRecentKind.work, text: text),
          ...recent.where((r) => r.text != text),
        ].take(8).toList();
      }
      log(
        'onSearch(work: ${q.work}, prompt: ${q.prompt}, tags: ${q.tags}, '
        'fuzzy: ${q.fuzzy}, fav: ${q.favoritesFilter})',
      );
    }),
    onSuggest: (frag, {required prompt}) async {
      const tags = [
        ('ocean', '海洋', 182000),
        ('ocean_view', '海景', 3400),
        ('1girl', '1个女孩', 5400000),
        ('white_hair', '白发', 820000),
        ('artist:ciloranko', null, 12000),
        ('artist:wlop', null, 9800),
        ('sailor_collar', '水手领', 410000),
        ('shiroko_(blue_archive)', '砂狼白子', 22000),
      ];
      return [
        for (final (t, zh, n) in tags)
          if (t.contains(frag.toLowerCase()))
            OnlineSuggestion(t, translation: zh, count: n),
      ];
    },
    onRecent: (r) => _set(() {
      _queries[source] = source == OnlineSource.aiTag
          ? (r.kind == OnlineRecentKind.prompt
                ? OnlineQuery(prompt: r.text)
                : OnlineQuery(work: r.text))
          : OnlineQuery(tags: r.text.split(' '));
    }),
    onClearRecent: () => _set(() => recent = []),
    onNaiOnlyChanged: (v) => _set(
      () => filters = OnlineFilters(
        naiOnly: v,
        model: v ? filters.model : null,
        timeRange: filters.timeRange,
        timeRanges: filters.timeRanges,
      ),
    ),
    onModelChanged: (m) => _set(
      () => filters = OnlineFilters(
        naiOnly: m != null || filters.naiOnly,
        model: m,
        timeRange: filters.timeRange,
        timeRanges: filters.timeRanges,
      ),
    ),
    onTimeRangeChanged: (t) => _set(
      () => filters = OnlineFilters(
        naiOnly: filters.naiOnly,
        model: filters.model,
        timeRange: t,
        timeRanges: filters.timeRanges,
      ),
    ),
    onRatingsChanged: (r) => _set(() => booruRatings = r),
    onDateRangeChanged: (r) => _set(() => dateRange = r),
    onRankPeriodChanged: (p) => _set(() => rankPeriod = p),
    onRankScaleChanged: (s) => _set(() => rankScale = s),
    onRankDateChanged: (d) => _set(() => rankDate = d),
    onCollectionSelected: (id) => _set(() {
      collection = id;
      author = null;
    }),
    onAuthorSelected: (id) => _set(() => author = id),
    onCreateCollection: (name) async {
      final id = 'c${collections.length}';
      _set(
        () => collections = [
          ...collections,
          OnlineCollection(id: id, name: name, count: 0),
        ],
      );
      return id;
    },
    onRenameCollection: (id, name) => _set(
      () => collections = [
        for (final c in collections)
          c.id == id ? OnlineCollection(id: id, name: name, count: c.count) : c,
      ],
    ),
    onDeleteCollection: (id) => _set(() {
      collections = collections.where((c) => c.id != id).toList();
      if (collection == id) collection = null;
    }),
    onMoveToCollection: (keys, id) => log('onMoveToCollection($keys → $id)'),
    onAuthorWorks: (id) => _set(() {
      _modes[source] = OnlineMode.search;
      _queries[source] = const OnlineQuery(work: 'LaraZoa');
      author = null;
      canReturn = true;
    }),
    onUnfavoriteAuthor: (id) => _set(() => author = null),
    onReturn: () => _set(() {
      _queries[source] = const OnlineQuery(work: 'ocean');
      canReturn = false;
    }),
    onBlacklistAdd: (t) => _set(() => blacklist = [...blacklist, t]),
    onBlacklistRemove: (t) =>
        _set(() => blacklist = blacklist.where((x) => x != t).toList()),
    onDanbooruSyncChanged: (v) => _set(() => sync = v),
    onCardSizeChanged: (s) => _set(() => cardSize = s),
    onSidebarChanged: (v) => _set(() => sidebar = v),
    onInspectorChanged: (v) => _set(() => inspector = v),
    onSelect: (key) {
      _set(() {
        selected = key;
        _loadingDetail.add(key);
      });
      Timer(const Duration(milliseconds: 450), () {
        _set(() => _loadingDetail.remove(key));
      });
    },
    onLoadMore: () {
      if (loadingMore) return;
      _set(() => loadingMore = true);
      Timer(const Duration(milliseconds: 700), () {
        _set(() {
          loadingMore = false;
          pages++;
        });
      });
    },
    onRetryPage: () => _set(() => scene = OnlineScene.ready),
    onRetry: () => _set(() => scene = OnlineScene.ready),
    onJumpToPage: (p) => _set(() => pages = p.clamp(1, 4)),
    onRefresh: () => _set(() => pages = 1),
    onScrollOffset: (_) {},
    onToggleFavorite: (key) => _set(() {
      if (!favorited.remove(key)) favorited.add(key);
    }),
    onFavoriteMany: (keys, id, {newCollection}) => _set(() {
      favorited.addAll(keys);
      log('onFavoriteMany(${keys.length} → ${newCollection ?? id})');
    }),
    onCopyPrompt: (keys) {
      Clipboard.setData(const ClipboardData(text: OnlineFixture.prompt));
      log('onCopyPrompt(${keys.length})');
    },
    onDownload: (keys, {all = false, mediaIndex = 0}) =>
        log('onDownload($keys, all: $all, index: $mediaIndex)'),
    onSend: (key, mode, {remember = false}) {
      if (remember) remembered = mode;
      log('onSend($key, ${mode.name}, remember: $remember)');
    },
    onOpenInBrowser: (key) => log('onOpenInBrowser($key)'),
    onTagTap: (tag) => _set(() {
      final q = query;
      _queries[source] = source == OnlineSource.aiTag
          ? OnlineQuery(work: tag, prompt: q.prompt)
          : OnlineQuery(tags: [...q.tags, tag], fuzzy: q.fuzzy);
    }),
    onToggleAuthorFavorite: (key) => log('onToggleAuthorFavorite($key)'),
    onOnlyAuthor: (key) => _set(() {
      _queries[source] = const OnlineQuery(work: 'アイんむー');
      canReturn = true;
    }),
    onLogin: (s) => _set(() => scene = OnlineScene.ready),
    onApiKeyHelp: (s) => log('onApiKeyHelp(${s.name})'),
  );
}
