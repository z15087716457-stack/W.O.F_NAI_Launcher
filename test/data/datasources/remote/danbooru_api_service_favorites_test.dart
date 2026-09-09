import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/datasources/remote/danbooru_api_service.dart';
import 'package:nai_launcher/data/datasources/remote/online_gallery/gallery_source_adapter.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_source.dart';

void main() {
  group('DanbooruApiService.getFavorites', () {
    test(
      'flat favorites backfill via id lookup keeps favorite order',
      () async {
        final adapter = _DanbooruFavoritesAdapter(
          favorites: [
            _favoriteEntry(301),
            _favoriteEntry(302),
            _favoriteEntry(303),
          ],
          // posts.json 故意乱序返回，回填后必须按收藏列表顺序输出
          postsForTags: (tags) =>
              _idsFromTags(tags).reversed.map(_postJson).toList(),
        );
        final service = _service(adapter);

        final result = await service.getFavorites(
          userId: 9,
          page: 1,
          limit: 40,
        );

        expect(result.rawCount, 3);
        expect(result.posts.map((post) => post.id), [301, 302, 303]);
        final favoritesRequest = adapter.requests.singleWhere(
          (request) => request.uri.path == '/favorites.json',
        );
        expect(favoritesRequest.queryParameters['search[user_id]'], 9);
        final postsRequests = adapter.requests
            .where((request) => request.uri.path == '/posts.json')
            .toList();
        expect(postsRequests, hasLength(1));
        expect(postsRequests.single.queryParameters['tags'], 'id:301,302,303');
        expect(postsRequests.single.queryParameters['limit'], 3);
      },
    );

    test('embedded post entries skip the backfill requests', () async {
      final adapter = _DanbooruFavoritesAdapter(
        favorites: [
          {..._favoriteEntry(301), 'post': _postJson(301)},
          {..._favoriteEntry(302), 'post': _postJson(302)},
        ],
      );
      final service = _service(adapter);

      final result = await service.getFavorites(userId: 9);

      expect(result.rawCount, 2);
      expect(result.posts.map((post) => post.id), [301, 302]);
      expect(
        adapter.requests.where((request) => request.uri.path == '/posts.json'),
        isEmpty,
      );
    });

    test('empty favorites return empty without backfill requests', () async {
      final adapter = _DanbooruFavoritesAdapter(favorites: []);
      final service = _service(adapter);

      final result = await service.getFavorites(userId: 9);

      expect(result.rawCount, 0);
      expect(result.posts, isEmpty);
      expect(adapter.requests, hasLength(1));
    });

    test('deleted posts drop out but still count toward rawCount', () async {
      final adapter = _DanbooruFavoritesAdapter(
        favorites: [_favoriteEntry(401), _favoriteEntry(402)],
        // 402 已删除，posts.json 不返回
        postsForTags: (tags) =>
            _idsFromTags(tags).where((id) => id != 402).map(_postJson).toList(),
      );
      final service = _service(adapter);

      final result = await service.getFavorites(userId: 9);

      expect(result.rawCount, 2);
      expect(result.posts.map((post) => post.id), [401]);
    });

    test('more than 100 ids split into batched requests', () async {
      final ids = List<int>.generate(150, (index) => 1000 + index);
      final adapter = _DanbooruFavoritesAdapter(
        favorites: ids.map(_favoriteEntry).toList(),
        postsForTags: (tags) => _idsFromTags(tags).map(_postJson).toList(),
      );
      final service = _service(adapter);

      final result = await service.getFavorites(userId: 9, limit: 200);

      expect(result.rawCount, 150);
      expect(result.posts.map((post) => post.id), ids);
      final postsRequests = adapter.requests
          .where((request) => request.uri.path == '/posts.json')
          .toList();
      expect(postsRequests, hasLength(2));
      final firstIds = _idsFromTags(
        postsRequests[0].queryParameters['tags'] as String,
      );
      final secondIds = _idsFromTags(
        postsRequests[1].queryParameters['tags'] as String,
      );
      expect(firstIds, hasLength(100));
      expect(secondIds, hasLength(50));
      expect(postsRequests[1].queryParameters['limit'], 50);
    });

    test(
      'auth header is attached to favorites and backfill requests',
      () async {
        final adapter = _DanbooruFavoritesAdapter(
          favorites: [_favoriteEntry(301)],
          postsForTags: (tags) => _idsFromTags(tags).map(_postJson).toList(),
        );
        final service = _service(adapter)..setAuthHeader('Basic dXNlcjprZXk=');

        await service.getFavorites(userId: 9);

        for (final request in adapter.requests) {
          expect(
            request.headers['Authorization'],
            'Basic dXNlcjprZXk=',
            reason: 'missing auth header on ${request.uri.path}',
          );
        }
      },
    );

    test('401 from favorites endpoint propagates as DioException', () async {
      final adapter = _DanbooruFavoritesAdapter(favoritesStatus: 401);
      final service = _service(adapter);

      await expectLater(
        service.getFavorites(userId: 9),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });
  });

  group('mapGalleryDioException status mapping', () {
    test('401 maps to credentialsInvalid', () {
      final error = _dioError(401);

      final mapped = mapGalleryDioException(error, GallerySourceId.danbooru);

      expect(mapped.code, GallerySourceErrorCode.credentialsInvalid);
      expect(mapped.statusCode, 401);
    });

    test('403 stays non-credential (ban/CDN semantics ambiguous)', () {
      final mapped = mapGalleryDioException(
        _dioError(403),
        GallerySourceId.danbooru,
      );

      expect(mapped.code, isNot(GallerySourceErrorCode.credentialsInvalid));
    });
  });
}

DanbooruApiService _service(_DanbooruFavoritesAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return DanbooruApiService(dio);
}

DioException _dioError(int statusCode) {
  final options = RequestOptions(
    path: 'https://danbooru.donmai.us/favorites.json',
  );
  return DioException(
    requestOptions: options,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
      data: '',
    ),
    type: DioExceptionType.badResponse,
  );
}

Map<String, dynamic> _favoriteEntry(int postId) => {
  'id': postId * 10,
  'user_id': 9,
  'post_id': postId,
};

Map<String, dynamic> _postJson(int id) => {
  'id': id,
  'rating': 'g',
  'image_width': 640,
  'image_height': 480,
  'tag_string_general': 'solo',
  'file_ext': 'jpg',
  'preview_file_url': 'https://cdn.donmai.us/preview/$id.jpg',
};

List<int> _idsFromTags(String tags) {
  final list = tags.startsWith('id:') ? tags.substring(3) : tags;
  return list
      .split(',')
      .map(int.tryParse)
      .whereType<int>()
      .toList(growable: false);
}

class _DanbooruFavoritesAdapter implements HttpClientAdapter {
  _DanbooruFavoritesAdapter({
    this.favorites = const <Map<String, dynamic>>[],
    this.favoritesStatus = 200,
    this.postsForTags,
  });

  final List<Map<String, dynamic>> favorites;
  final int favoritesStatus;
  final List<Map<String, dynamic>> Function(String tags)? postsForTags;

  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.uri.path == '/favorites.json') {
      if (favoritesStatus != 200) {
        throw DioException(
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: favoritesStatus,
            data: '',
          ),
          type: DioExceptionType.badResponse,
        );
      }
      return _jsonBody(favorites);
    }
    if (options.uri.path == '/posts.json') {
      final tags = options.queryParameters['tags'] as String? ?? '';
      return _jsonBody(postsForTags?.call(tags) ?? const []);
    }
    return _jsonBody(const []);
  }

  static ResponseBody _jsonBody(Object body) {
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
