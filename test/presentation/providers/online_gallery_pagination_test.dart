import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/datasources/remote/danbooru_api_service.dart';
import 'package:nai_launcher/data/datasources/remote/online_gallery/gallery_source_adapter.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_item.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_source.dart';
import 'package:nai_launcher/presentation/providers/online_gallery_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'source caches are isolated and restored without a repeated request',
    () async {
      final danbooru = _FakeGalleryAdapter(
        GallerySourceId.danbooru,
        onSearch: (request, _) async =>
            _page(request.cursor, [_item(11)], nextCursor: null),
      );
      final safebooru = _FakeGalleryAdapter(
        GallerySourceId.safebooru,
        onSearch: (request, _) async => _page(request.cursor, [
          _item(22, source: GallerySourceId.safebooru),
        ], nextCursor: null),
      );
      final container = _container(danbooru: danbooru, safebooru: safebooru);
      addTearDown(container.dispose);
      final notifier = container.read(onlineGalleryNotifierProvider.notifier);

      await notifier.loadPosts();
      await notifier.setSource(GallerySourceId.safebooru);
      expect(container.read(onlineGalleryNotifierProvider).posts.single.id, 22);
      await notifier.setSource(GallerySourceId.danbooru);

      expect(container.read(onlineGalleryNotifierProvider).posts.single.id, 11);
      expect(danbooru.searchCursors, ['1']);
      expect(safebooru.searchCursors, ['1']);
    },
  );

  test(
    'switching to a cached source clears loading from the cancelled request',
    () async {
      final pendingRefresh = Completer<GalleryPage>();
      var danbooruRequests = 0;
      final danbooru = _FakeGalleryAdapter(
        GallerySourceId.danbooru,
        onSearch: (request, _) {
          danbooruRequests++;
          if (danbooruRequests == 1) {
            return Future.value(
              _page(request.cursor, [_item(11)], nextCursor: null),
            );
          }
          return pendingRefresh.future;
        },
      );
      final safebooru = _FakeGalleryAdapter(
        GallerySourceId.safebooru,
        onSearch: (request, _) async => _page(request.cursor, [
          _item(22, source: GallerySourceId.safebooru),
        ], nextCursor: null),
      );
      final container = _container(danbooru: danbooru, safebooru: safebooru);
      addTearDown(container.dispose);
      final notifier = container.read(onlineGalleryNotifierProvider.notifier);

      await notifier.loadPosts();
      await notifier.setSource(GallerySourceId.safebooru);
      await notifier.setSource(GallerySourceId.danbooru);
      final refresh = notifier.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(onlineGalleryNotifierProvider).isLoading, isTrue);

      await notifier.setSource(GallerySourceId.safebooru);

      var state = container.read(onlineGalleryNotifierProvider);
      expect(state.posts.single.id, 22);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingMore, isFalse);
      pendingRefresh.complete(_page('1', [_item(99)], nextCursor: null));
      await refresh;
      state = container.read(onlineGalleryNotifierProvider);
      expect(state.posts.single.id, 22);
      expect(state.isLoading, isFalse);
    },
  );

  test(
    'late results from a cancelled source cannot overwrite the new source',
    () async {
      final latePage = Completer<GalleryPage>();
      final danbooru = _FakeGalleryAdapter(
        GallerySourceId.danbooru,
        onSearch: (_, __) => latePage.future,
      );
      final safebooru = _FakeGalleryAdapter(
        GallerySourceId.safebooru,
        onSearch: (request, _) async => _page(request.cursor, [
          _item(22, source: GallerySourceId.safebooru),
        ], nextCursor: null),
      );
      final container = _container(danbooru: danbooru, safebooru: safebooru);
      addTearDown(container.dispose);
      final notifier = container.read(onlineGalleryNotifierProvider.notifier);

      final oldRequest = notifier.loadPosts();
      await Future<void>.delayed(Duration.zero);
      await notifier.setSource(GallerySourceId.safebooru);
      latePage.complete(_page('1', [_item(99)], nextCursor: null));
      await oldRequest;

      final state = container.read(onlineGalleryNotifierProvider);
      expect(state.sourceId, GallerySourceId.safebooru);
      expect(state.posts.single.id, 22);
    },
  );

  test(
    'AiTag author search returns to search cache without a new request',
    () async {
      final aiTag = _FakeGalleryAdapter(
        GallerySourceId.aiTag,
        onSearch: (request, _) async => _page(request.cursor, [
          _item(int.parse(request.query), source: GallerySourceId.aiTag),
        ], nextCursor: '2'),
      );
      final container = _authorContainer(
        aiTag: aiTag,
        notifierBuilder: _AuthorSearchGalleryNotifier.new,
      );
      addTearDown(container.dispose);
      final notifier = container.read(onlineGalleryNotifierProvider.notifier);
      final original = container.read(onlineGalleryNotifierProvider);
      final originalCacheKey = original.currentCacheKey;

      await notifier.searchAiTagAuthor(88, drafts: _authorDrafts);

      expect(aiTag.searchRequests, hasLength(1));
      final request = aiTag.searchRequests.single;
      expect(request.query, '88');
      expect(request.prompt, '');
      expect(request.timeRange, 'all');
      expect(request.dateStart, isNull);
      expect(request.dateEnd, isNull);

      var state = container.read(onlineGalleryNotifierProvider);
      expect(state.sourceId, GallerySourceId.aiTag);
      expect(state.viewMode, GalleryViewMode.search);
      expect(state.searchQuery, '88');
      expect(state.promptQuery, '');
      expect(state.aiTagTimeRange, 'all');
      expect(state.aiTagNaiOnly, isFalse);
      expect(state.aiTagModelVersion, isNull);
      expect(state.dateRangeStart, isNull);
      expect(state.dateRangeEnd, isNull);
      expect(state.authorReturnContext, isNotNull);
      expect(
        () => state.authorReturnContext!.selectedRatings.add('e'),
        throwsUnsupportedError,
      );

      final returnedDrafts = notifier.returnFromAiTagAuthorSearch();

      expect(aiTag.searchRequests, hasLength(1));
      expect(returnedDrafts, isNotNull);
      expect(returnedDrafts!.searchQuery, _authorDrafts.searchQuery);
      expect(returnedDrafts.searchPrompt, _authorDrafts.searchPrompt);
      expect(returnedDrafts.popularQuery, _authorDrafts.popularQuery);
      expect(returnedDrafts.popularPrompt, _authorDrafts.popularPrompt);
      state = container.read(onlineGalleryNotifierProvider);
      expect(state.currentCacheKey, originalCacheKey);
      expect(state.sourceId, GallerySourceId.aiTag);
      expect(state.viewMode, GalleryViewMode.search);
      expect(state.searchQuery, 'saved search');
      expect(state.promptQuery, 'saved prompt');
      expect(state.fuzzySearchEnabled, isTrue);
      expect(state.selectedRatings, {'g', 's'});
      expect(state.aiTagTimeRange, 'y2025');
      expect(state.aiTagNaiOnly, isTrue);
      expect(state.aiTagModelVersion, '5');
      expect(state.dateRangeStart, DateTime(2025, 1, 1));
      expect(state.dateRangeEnd, DateTime(2025, 12, 31));
      expect(state.posts.single.id, 71);
      expect(state.page, 3);
      expect(state.currentCache.nextCursor, '4');
      expect(state.scrollOffset, 345);
      expect(state.authorReturnContext, isNull);
      expect(state.error, isNull);
      expect(state.notice, isNull);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingMore, isFalse);
    },
  );

  test('AiTag author search returns to the previous popular page', () async {
    final aiTag = _FakeGalleryAdapter(
      GallerySourceId.aiTag,
      onSearch: (request, _) async => _page(request.cursor, [
        _item(88, source: GallerySourceId.aiTag),
      ], nextCursor: null),
    );
    final container = _authorContainer(
      aiTag: aiTag,
      notifierBuilder: _AuthorPopularGalleryNotifier.new,
    );
    addTearDown(container.dispose);
    final notifier = container.read(onlineGalleryNotifierProvider.notifier);
    final originalCacheKey = container
        .read(onlineGalleryNotifierProvider)
        .currentCacheKey;

    await notifier.searchAiTagAuthor(88, drafts: _authorDrafts);
    final returnedDrafts = notifier.returnFromAiTagAuthorSearch();

    expect(aiTag.searchRequests, hasLength(1));
    expect(aiTag.rankingRequests, isEmpty);
    expect(returnedDrafts!.popularQuery, _authorDrafts.popularQuery);
    final state = container.read(onlineGalleryNotifierProvider);
    expect(state.currentCacheKey, originalCacheKey);
    expect(state.viewMode, GalleryViewMode.popular);
    expect(state.sourceId, GallerySourceId.gelbooru);
    expect(state.popularSourceId, GallerySourceId.aiTag);
    expect(state.popularQuery, 'saved popular');
    expect(state.popularPromptQuery, 'saved popular prompt');
    expect(state.popularScale, PopularScale.month);
    expect(state.popularDate, DateTime(2026, 7, 15));
    expect(state.aiTagPopularPeriod, '2026-07');
    expect(state.posts.single.id, 72);
    expect(state.page, 4);
    expect(state.currentCache.nextCursor, '5');
    expect(state.scrollOffset, 222);
    expect(state.authorReturnContext, isNull);
  });

  test('AiTag author search keeps a one-level return snapshot', () async {
    final aiTag = _FakeGalleryAdapter(
      GallerySourceId.aiTag,
      onSearch: (request, _) async => _page(request.cursor, [
        _item(int.parse(request.query), source: GallerySourceId.aiTag),
      ], nextCursor: null),
    );
    final container = _authorContainer(
      aiTag: aiTag,
      notifierBuilder: _AuthorSearchGalleryNotifier.new,
    );
    addTearDown(container.dispose);
    final notifier = container.read(onlineGalleryNotifierProvider.notifier);

    await notifier.searchAiTagAuthor(88, drafts: _authorDrafts);
    await notifier.searchAiTagAuthor(99, drafts: _secondAuthorDrafts);

    expect(aiTag.searchRequests.map((request) => request.query), ['88', '99']);
    final authorState = container.read(onlineGalleryNotifierProvider);
    expect(authorState.searchQuery, '99');
    expect(
      authorState.authorReturnContext!.drafts.searchQuery,
      _authorDrafts.searchQuery,
    );

    final returnedDrafts = notifier.returnFromAiTagAuthorSearch();

    expect(aiTag.searchRequests, hasLength(2));
    expect(returnedDrafts!.searchQuery, _authorDrafts.searchQuery);
    final state = container.read(onlineGalleryNotifierProvider);
    expect(state.searchQuery, 'saved search');
    expect(state.posts.single.id, 71);
    expect(state.page, 3);
    expect(state.scrollOffset, 345);
  });

  test(
    'return cancels a pending author request and rejects its late result',
    () async {
      final requestStarted = Completer<void>();
      final latePage = Completer<GalleryPage>();
      final aiTag = _FakeGalleryAdapter(
        GallerySourceId.aiTag,
        onSearch: (request, _) {
          if (!requestStarted.isCompleted) requestStarted.complete();
          return latePage.future;
        },
      );
      final container = _authorContainer(
        aiTag: aiTag,
        notifierBuilder: _AuthorSearchGalleryNotifier.new,
      );
      addTearDown(container.dispose);
      final notifier = container.read(onlineGalleryNotifierProvider.notifier);

      final pending = notifier.searchAiTagAuthor(88, drafts: _authorDrafts);
      await requestStarted.future;
      expect(container.read(onlineGalleryNotifierProvider).isLoading, isTrue);

      final returnedDrafts = notifier.returnFromAiTagAuthorSearch();

      expect(returnedDrafts!.searchQuery, _authorDrafts.searchQuery);
      var state = container.read(onlineGalleryNotifierProvider);
      expect(state.searchQuery, 'saved search');
      expect(state.posts.single.id, 71);
      expect(state.page, 3);
      expect(state.scrollOffset, 345);
      expect(state.isLoading, isFalse);
      expect(state.authorReturnContext, isNull);

      latePage.complete(
        _page('1', [
          _item(999, source: GallerySourceId.aiTag),
        ], nextCursor: null),
      );
      await pending;

      state = container.read(onlineGalleryNotifierProvider);
      expect(aiTag.searchRequests, hasLength(1));
      expect(state.searchQuery, 'saved search');
      expect(state.posts.single.id, 71);
      expect(state.page, 3);
      expect(state.scrollOffset, 345);
      expect(state.isLoading, isFalse);
    },
  );
}

ProviderContainer _container({
  required _FakeGalleryAdapter danbooru,
  _FakeGalleryAdapter? safebooru,
}) {
  final safe =
      safebooru ??
      _FakeGalleryAdapter(
        GallerySourceId.safebooru,
        onSearch: (request, _) async =>
            _page(request.cursor, const [], nextCursor: null),
      );
  final gelbooru = _FakeGalleryAdapter(
    GallerySourceId.gelbooru,
    onSearch: (request, _) async =>
        _page(request.cursor, const [], nextCursor: null),
  );
  final aiTag = _FakeGalleryAdapter(
    GallerySourceId.aiTag,
    onSearch: (request, _) async =>
        _page(request.cursor, const [], nextCursor: null),
  );
  return ProviderContainer(
    overrides: [
      onlineGallerySourceAdaptersProvider.overrideWithValue({
        GallerySourceId.danbooru: danbooru,
        GallerySourceId.safebooru: safe,
        GallerySourceId.gelbooru: gelbooru,
        GallerySourceId.aiTag: aiTag,
      }),
    ],
  );
}

ProviderContainer _authorContainer({
  required _FakeGalleryAdapter aiTag,
  required OnlineGalleryNotifier Function() notifierBuilder,
}) {
  final emptyAdapters = <GallerySourceId, GallerySourceAdapter>{
    for (final sourceId in GallerySourceId.values)
      sourceId: sourceId == GallerySourceId.aiTag
          ? aiTag
          : _FakeGalleryAdapter(
              sourceId,
              onSearch: (request, _) async =>
                  _page(request.cursor, const [], nextCursor: null),
            ),
  };
  return ProviderContainer(
    overrides: [
      onlineGallerySourceAdaptersProvider.overrideWithValue(emptyAdapters),
      onlineGalleryNotifierProvider.overrideWith(notifierBuilder),
    ],
  );
}

GalleryPage _page(
  String cursor,
  List<GalleryItem> items, {
  required String? nextCursor,
  int? rawItemCount,
}) {
  return GalleryPage(
    items: items,
    cursor: cursor,
    nextCursor: nextCursor,
    hasMore: nextCursor != null,
    rawItemCount: rawItemCount ?? items.length,
  );
}

GalleryItem _item(int id, {GallerySourceId source = GallerySourceId.danbooru}) {
  return GalleryItem(
    id: id,
    sourceId: source,
    createdAt: '2026-08-09',
    uploaderId: 1,
    width: 768,
    height: 1024,
    rating: 'g',
    tags: const ['1girl'],
    cover: GalleryMedia(
      id: '$id',
      previewUrl: 'https://example.test/${source.key}/$id-preview.webp',
      displayUrl: 'https://example.test/${source.key}/$id.webp',
      downloadUrl: 'https://example.test/${source.key}/$id.webp',
      width: 768,
      height: 1024,
      extension: 'webp',
    ),
  );
}

const _authorDrafts = OnlineGalleryQueryDrafts(
  searchQuery: 'draft search',
  searchPrompt: 'draft prompt',
  popularQuery: 'draft popular',
  popularPrompt: 'draft popular prompt',
);

const _secondAuthorDrafts = OnlineGalleryQueryDrafts(
  searchQuery: '88',
  searchPrompt: '',
  popularQuery: 'changed popular draft',
  popularPrompt: 'changed popular prompt',
);

class _AuthorSearchGalleryNotifier extends OnlineGalleryNotifier {
  @override
  OnlineGalleryState build() {
    return OnlineGalleryState(
      viewMode: GalleryViewMode.search,
      sourceId: GallerySourceId.aiTag,
      searchQuery: 'saved search',
      promptQuery: 'saved prompt',
      popularQuery: 'saved inactive popular',
      popularPromptQuery: 'saved inactive popular prompt',
      fuzzySearchEnabled: true,
      selectedRatings: const {'g', 's'},
      aiTagTimeRange: 'y2025',
      aiTagPopularPeriod: '2026-06',
      aiTagNaiOnly: true,
      aiTagModelVersion: '5',
      dateRangeStart: DateTime(2025, 1, 1),
      dateRangeEnd: DateTime(2025, 12, 31),
      searchCache: ModeCache(
        posts: [_item(71, source: GallerySourceId.aiTag)],
        page: 3,
        nextCursor: '4',
        total: 180,
        scrollOffset: 345,
      ),
      error: 'stale error',
      notice: OnlineGalleryNotice.gelbooruCredentialsInvalid,
    );
  }
}

class _AuthorPopularGalleryNotifier extends OnlineGalleryNotifier {
  @override
  OnlineGalleryState build() {
    return OnlineGalleryState(
      viewMode: GalleryViewMode.popular,
      sourceId: GallerySourceId.gelbooru,
      popularSourceId: GallerySourceId.aiTag,
      searchQuery: 'saved inactive search',
      promptQuery: 'saved inactive prompt',
      popularQuery: 'saved popular',
      popularPromptQuery: 'saved popular prompt',
      selectedRatings: const {'q', 'e'},
      popularScale: PopularScale.month,
      popularDate: DateTime(2026, 7, 15),
      aiTagTimeRange: 'y2024',
      aiTagPopularPeriod: '2026-07',
      aiTagNaiOnly: true,
      aiTagModelVersion: '4.5',
      dateRangeStart: DateTime(2024, 1, 1),
      popularCache: ModeCache(
        posts: [_item(72, source: GallerySourceId.aiTag)],
        page: 4,
        nextCursor: '5',
        total: 240,
        scrollOffset: 222,
      ),
    );
  }
}

class _FakeGalleryAdapter implements GallerySourceAdapter {
  _FakeGalleryAdapter(this.sourceId, {required this.onSearch});

  @override
  final GallerySourceId sourceId;
  final Future<GalleryPage> Function(
    GallerySearchRequest request,
    CancelToken? cancelToken,
  )
  onSearch;
  final List<String> searchCursors = [];
  final List<GallerySearchRequest> searchRequests = [];
  final List<GalleryRankingRequest> rankingRequests = [];

  @override
  GallerySourceCapabilities get capabilities =>
      gallerySourceCapabilities[sourceId]!;

  @override
  Future<GalleryPage> search(
    GallerySearchRequest request, {
    CancelToken? cancelToken,
  }) {
    searchCursors.add(request.cursor);
    searchRequests.add(request);
    return onSearch(request, cancelToken);
  }

  @override
  Future<GalleryPage> ranking(
    GalleryRankingRequest request, {
    CancelToken? cancelToken,
  }) {
    rankingRequests.add(request);
    return search(
      GallerySearchRequest(cursor: request.cursor, pageSize: request.pageSize),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<GalleryDetail> detail(
    GalleryItem item, {
    CancelToken? cancelToken,
  }) async {
    return GalleryDetail(item: item, media: [item.cover]);
  }
}
