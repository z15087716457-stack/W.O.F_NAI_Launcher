import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/datasources/remote/danbooru_api_service.dart';
import 'package:nai_launcher/data/models/danbooru/danbooru_user.dart';
import 'package:nai_launcher/data/services/danbooru_auth_service.dart';
import 'package:nai_launcher/presentation/providers/online_gallery_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Danbooru 收藏视图回归：走真实 DanbooruApiService + mock HTTP，
/// 覆盖扁平收藏回填上屏与 401 鉴权错误两条链路。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer createContainer(_DanbooruFavoritesAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final service = DanbooruApiService(dio)
      ..setAuthHeader('Basic dXNlcjprZXk=');
    return ProviderContainer(
      overrides: [
        danbooruAuthProvider.overrideWith(_StubDanbooruAuth.new),
        danbooruApiServiceProvider.overrideWithValue(service),
        onlineGalleryHttpClientProvider.overrideWithValue(dio),
      ],
    );
  }

  test('favorites view backfills flat entries and fills state', () async {
    final adapter = _DanbooruFavoritesAdapter(
      favorites: [
        _favoriteEntry(301),
        _favoriteEntry(302),
        _favoriteEntry(303),
      ],
      postsForTags: (tags) =>
          _idsFromTags(tags).reversed.map(_postJson).toList(),
    );
    final container = createContainer(adapter);
    addTearDown(container.dispose);

    final notifier = container.read(onlineGalleryNotifierProvider.notifier);
    await notifier.setSource('danbooru');
    await notifier.switchToFavorites();

    final state = container.read(onlineGalleryNotifierProvider);
    expect(state.viewMode, GalleryViewMode.favorites);
    expect(state.errorCode, isNull);
    expect(state.posts.map((post) => post.id), [301, 302, 303]);
    // 收藏条目数(3)不足一页(40)，分页应终止
    expect(state.hasMore, isFalse);
  });

  test('favorites request 401 surfaces credentialsInvalid', () async {
    final adapter = _DanbooruFavoritesAdapter(favoritesStatus: 401);
    final container = createContainer(adapter);
    addTearDown(container.dispose);

    final notifier = container.read(onlineGalleryNotifierProvider.notifier);
    await notifier.setSource('danbooru');
    await notifier.switchToFavorites();

    final state = container.read(onlineGalleryNotifierProvider);
    expect(state.errorCode, OnlineGalleryErrorCode.credentialsInvalid);
    expect(state.posts, isEmpty);
    expect(state.isLoading, isFalse);
  });
}

class _StubDanbooruAuth extends DanbooruAuth {
  @override
  DanbooruAuthState build() {
    return DanbooruAuthState(
      credentials: const DanbooruCredentials(username: 'tester', apiKey: 'key'),
      user: const DanbooruUser(id: 9, name: 'tester'),
      lastVerifiedAt: DateTime.now(),
    );
  }

  @override
  Future<void> ensureInitialized() async {}
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
