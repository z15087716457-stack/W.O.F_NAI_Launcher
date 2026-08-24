import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  @override
  GallerySourceCapabilities get capabilities =>
      gallerySourceCapabilities[sourceId]!;

  @override
  Future<GalleryPage> search(
    GallerySearchRequest request, {
    CancelToken? cancelToken,
  }) {
    searchCursors.add(request.cursor);
    return onSearch(request, cancelToken);
  }

  @override
  Future<GalleryPage> ranking(
    GalleryRankingRequest request, {
    CancelToken? cancelToken,
  }) {
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
