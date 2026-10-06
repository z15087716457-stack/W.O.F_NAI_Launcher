import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/wiki/wiki_example_repository.dart';
import 'package:nai_launcher/data/datasources/remote/danbooru_api_service.dart';

const _body = '''
!post #99: outside
h4. Examples
* !post #11: [[1girl]] [[solo]]
h5. More examples
* !post #22: [[1girl]] with [[1boy]]
* !post #11: duplicate
* post #33: ordinary link
h4. See also
* !post #44: outside
''';

Map<String, dynamic> _post(int id) => {
  'id': id,
  'preview_file_url': 'https://cdn.donmai.us/180x180/$id.jpg',
  'media_asset': {
    'variants': [
      {'type': '360x360', 'url': 'https://cdn.donmai.us/360x360/$id.jpg'},
      {'type': '720x720', 'url': 'https://cdn.donmai.us/720x720/$id.webp'},
      {'type': 'original', 'url': 'https://cdn.donmai.us/original/$id.png'},
    ],
  },
};

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      options.path.contains('wiki_pages')
          ? '{"body":"h4. Examples\\n* !post #11: example"}'
          : '[{"id":11,"preview_file_url":"https://cdn.donmai.us/11.jpg"}]',
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
  if (Platform.environment['LIVE_WIKI_EXAMPLES'] == '1') {
    test(
      'public Danbooru example metadata and thumbnail URLs resolve',
      () async {
        final overrides = HttpOverrides.current;
        HttpOverrides.global = null;
        final dio = Dio(
          BaseOptions(connectTimeout: const Duration(seconds: 10)),
        );
        try {
          final api = DanbooruApiService(dio);
          final repo = WikiExampleRepository(
            fetchWiki: api.getWikiPage,
            fetchPosts: api.getWikiExamplePosts,
          );
          final result = await repo.forTag('1girl');
          expect(result.items.length, greaterThanOrEqualTo(2));
          final checked = <Map<String, dynamic>>[];
          for (final example in result.items.take(3)) {
            expect(example.thumbnailUrl, isNotNull);
            expect(example.largeUrl, isNotNull);
            final head = await dio.head(example.thumbnailUrl!);
            expect(head.statusCode, 200);
            checked.add({
              'post_id': example.postId,
              'thumbnail_url': example.thumbnailUrl,
              'large_url': example.largeUrl,
              'thumbnail_head_status': head.statusCode,
              'thumbnail_bytes': head.headers.value('content-length'),
            });
          }
          final target = File(
            '.dart_tool/wiki-examples-20261006/public-api-verification.json',
          );
          await target.parent.create(recursive: true);
          await target.writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'checked_at': DateTime.now().toUtc().toIso8601String(),
              'tag': '1girl',
              'examples': checked,
              'authenticated': false,
              'image_bytes_downloaded': false,
              'anlas_spent': 0,
            }),
          );
        } finally {
          dio.close(force: true);
          HttpOverrides.global = overrides;
        }
      },
    );
  }

  test(
    'official section order, nested headings and caption links are retained',
    () {
      final refs = WikiExampleReference.parse(_body);
      expect(refs.map((r) => r.postId), [11, 22]);
      expect(refs.first.captionMarkdown, contains('[solo]'));
      expect(refs.last.captionMarkdown, contains('/wiki_pages/1boy'));
      final inline = WikiExampleReference.parse(
        'h4. Examples\n!post #1: left !post #2: right',
      );
      expect(inline.map((r) => r.postId), [1, 2]);
      expect(inline.first.caption, 'left');
      expect(inline.last.caption, 'right');
    },
  );

  test(
    'one metadata batch restores source order and uses bounded image variants',
    () async {
      final batches = <List<int>>[];
      var wikiCalls = 0;
      final repo = WikiExampleRepository(
        fetchWiki: (tag, {cancelToken}) async {
          wikiCalls++;
          expect(tag, '1girl');
          return {'body': _body};
        },
        fetchPosts: (ids, {cancelToken}) async {
          batches.add(ids);
          return [_post(22), _post(11), _post(99)];
        },
      );
      final result = await repo.forTag('1girl');
      expect(result.items.map((r) => r.postId), [11, 22]);
      expect(batches, [
        [11, 22],
      ]);
      expect(result.items.first.thumbnailUrl, contains('360x360'));
      expect(result.items.first.largeUrl, contains('720x720'));
      await repo.forTag('1girl');
      expect(wikiCalls, 1);
      expect(batches.length, 1);
    },
  );

  test(
    'deleted, unavailable and foreign image URLs retain their captions',
    () async {
      final repo = WikiExampleRepository(
        fetchWiki: (tag, {cancelToken}) async => {'body': _body},
        fetchPosts: (ids, {cancelToken}) async => [
          {..._post(11), 'is_deleted': true},
          {
            'id': 22,
            'preview_file_url': 'https://unrelated.example/22.jpg',
            'media_asset': {
              'variants': [
                {
                  'type': '360x360',
                  'url': 'https://donmai.us.evil.test/22.jpg',
                },
                {'type': '720x720', 'url': 'http://cdn.donmai.us/22.jpg'},
              ],
            },
          },
        ],
      );
      final result = await repo.forTag('1girl');
      expect(result.items, hasLength(2));
      expect(
        result.items.every((r) => r.thumbnailUrl == null && r.largeUrl == null),
        isTrue,
      );
      expect(result.items.first.reference.caption, contains('solo'));
    },
  );

  test(
    'a page without explicit example embeds never searches for substitute images',
    () async {
      var postCalls = 0;
      final repo = WikiExampleRepository(
        fetchWiki: (tag, {cancelToken}) async => {
          'body': 'Plain text. post #11',
        },
        fetchPosts: (ids, {cancelToken}) async {
          postCalls++;
          return [];
        },
      );
      expect((await repo.forTag('tag')).items, isEmpty);
      expect(postCalls, 0);
    },
  );

  test('cancel between page and metadata stops the second request', () async {
    final token = CancelToken();
    var postCalls = 0;
    final repo = WikiExampleRepository(
      fetchWiki: (tag, {cancelToken}) async {
        token.cancel();
        return {'body': _body};
      },
      fetchPosts: (ids, {cancelToken}) async {
        postCalls++;
        return [];
      },
    );
    await expectLater(
      repo.forTag('1girl', cancelToken: token),
      throwsA(isA<DioException>()),
    );
    expect(postCalls, 0);
  });

  test(
    'failed requests retry and metadata cache expires and stays bounded',
    () async {
      var calls = 0;
      var now = DateTime(2026, 10, 6);
      final repo = WikiExampleRepository(
        now: () => now,
        fetchWiki: (tag, {cancelToken}) async {
          calls++;
          if (calls == 1) throw StateError('offline');
          return null;
        },
        fetchPosts: (ids, {cancelToken}) async => [],
      );
      await expectLater(repo.forTag('first'), throwsStateError);
      await repo.forTag('first');
      await repo.forTag('first');
      expect(calls, 2);
      now = now.add(const Duration(hours: 7));
      await repo.forTag('first');
      expect(calls, 3);
      for (var i = 0; i < 33; i++) {
        await repo.forTag('tag_$i');
      }
      final previous = calls;
      await repo.forTag('first');
      expect(calls, previous + 1);
    },
  );

  test(
    'large example sections cap metadata batches and expose the source fallback',
    () async {
      List<int>? requested;
      final repo = WikiExampleRepository(
        fetchWiki: (tag, {cancelToken}) async => {
          'body':
              'h4. Examples\n${List.generate(70, (i) => '* !post #${i + 1}').join('\n')}',
        },
        fetchPosts: (ids, {cancelToken}) async {
          requested = ids;
          return [];
        },
      );
      final result = await repo.forTag('tag');
      expect(requested, hasLength(64));
      expect(result.items, hasLength(64));
      expect(result.truncated, isTrue);
    },
  );

  test(
    'API stays on Danbooru and requests only illustration metadata',
    () async {
      final adapter = _Adapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final api = DanbooruApiService(dio)..setAuthHeader('Basic test-only');
      final repo = WikiExampleRepository(
        fetchWiki: api.getWikiPage,
        fetchPosts: api.getWikiExamplePosts,
      );
      expect((await repo.forTag('1girl')).items.single.postId, 11);
      expect(adapter.requests, hasLength(2));
      for (final request in adapter.requests) {
        expect(request.uri.host, 'danbooru.donmai.us');
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Basic test-only');
      }
      expect(adapter.requests.last.queryParameters['tags'], 'id:11');
      expect(
        adapter.requests.last.queryParameters['only'],
        isNot(contains('tag_string')),
      );
      dio.close();
    },
  );
}
