import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/wiki/wiki_example_repository.dart';
import 'package:nai_launcher/data/datasources/remote/danbooru_api_service.dart';

Map<String, dynamic> _media(int id, {bool asset = false}) {
  final variants = [
    {
      'type': '360x360',
      'url': 'https://cdn.donmai.us/${asset ? 'asset' : 'post'}/$id.jpg',
    },
    {
      'type': '720x720',
      'url': 'https://cdn.donmai.us/${asset ? 'asset' : 'post'}/$id.webp',
    },
  ];
  return asset
      ? {'id': id, 'status': 'active', 'variants': variants}
      : {
          'id': id,
          'media_asset': {'variants': variants},
        };
}

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '[]',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'post and asset IDs do not collide; captions are not metadata cache keys',
    () async {
      final calls = <String>[];
      final repo = WikiExampleRepository(
        fetchWiki: (_, {cancelToken}) async =>
            throw StateError('local references need no Wiki request'),
        fetchPosts: (ids, {cancelToken}) async {
          calls.add('post');
          return ids.map((id) => _media(id)).toList();
        },
        fetchAssets: (ids, {cancelToken}) async {
          calls.add('asset');
          return ids.map((id) => _media(id, asset: true)).toList();
        },
      );
      final refs = [
        const WikiExampleReference(1, 'A'),
        const WikiExampleReference(1, 'B', kind: WikiImageKind.asset),
      ];
      final loaded = await repo.forReferences(refs);
      expect(calls, ['post', 'asset']);
      expect(loaded[0].thumbnailUrl, contains('/post/1'));
      expect(loaded[1].thumbnailUrl, contains('/asset/1'));
      expect(loaded[1].sourceUrl, endsWith('/media_assets/1'));
      final again = await repo.forReferences([
        const WikiExampleReference(1, 'another chapter'),
      ]);
      expect(calls, hasLength(2));
      expect(again.single.reference.caption, 'another chapter');
      expect(repo.footprint.bytes, greaterThan(0));
      repo.clearCache();
      expect(repo.footprint.bytes, 0);
    },
  );

  test('64 is a request bound; 130 references are all returned', () async {
    final batches = <List<int>>[];
    final repo = WikiExampleRepository(
      fetchWiki: (_, {cancelToken}) async => null,
      fetchPosts: (ids, {cancelToken}) async {
        batches.add(ids);
        return ids.map((id) => _media(id)).toList();
      },
    );
    final loaded = await repo.forReferences(
      List.generate(130, (i) => WikiExampleReference(i + 1, '')),
    );
    expect(batches.map((b) => b.length), [64, 64, 2]);
    expect(loaded, hasLength(130));
    expect(loaded.last.largeUrl, contains('/130.webp'));
  });

  test('cancellation and cache clear cannot publish late metadata', () async {
    final pending = Completer<List<Map<String, dynamic>>>();
    var calls = 0;
    final repo = WikiExampleRepository(
      fetchWiki: (_, {cancelToken}) async => null,
      fetchPosts: (ids, {cancelToken}) {
        calls++;
        return pending.future;
      },
    );
    final token = CancelToken();
    final future = repo.forReferences([
      const WikiExampleReference(1, ''),
    ], cancelToken: token);
    final expected = expectLater(future, throwsA(isA<DioException>()));
    token.cancel();
    repo.clearCache();
    pending.complete([_media(1)]);
    await expected;
    expect(repo.footprint.bytes, 0);
    await repo.forReferences([const WikiExampleReference(1, '')]);
    expect(calls, 2);
  });

  test(
    'unavailable media keeps its reference without inventing a replacement',
    () async {
      final repo = WikiExampleRepository(
        fetchWiki: (_, {cancelToken}) async => null,
        fetchPosts: (ids, {cancelToken}) async => [],
        fetchAssets: (ids, {cancelToken}) async => [
          {'id': 1, 'status': 'deleted', 'variants': []},
        ],
      );
      final loaded = await repo.forReferences([
        const WikiExampleReference(
          1,
          'original caption',
          kind: WikiImageKind.asset,
        ),
      ]);
      expect(loaded.single.reference.caption, 'original caption');
      expect(loaded.single.thumbnailUrl, isNull);
      expect(loaded.single.sourceUrl, endsWith('/media_assets/1'));
    },
  );

  test(
    'media asset batch uses its own endpoint and bounded ID search',
    () async {
      final adapter = _Adapter(), dio = Dio();
      dio.httpClientAdapter = adapter;
      addTearDown(() => dio.close(force: true));
      await DanbooruApiService(dio).getWikiExampleAssets([12, 13]);
      final request = adapter.requests.single;
      expect(request.path, endsWith('/media_assets.json'));
      expect(request.queryParameters['search[id]'], '12,13');
      expect(request.queryParameters['limit'], 2);
      expect(request.queryParameters['only'], 'id,status,is_public,variants');
    },
  );
}
