import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file/file.dart' as fs;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/wiki_example_repository.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_knowledge_tools.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_wiki_images.dart';
import 'package:nai_launcher/presentation/widgets/common/wiki_example_gallery.dart';

class _Cache extends Fake implements BaseCacheManager {
  _Cache(this.file);
  final fs.File file;
  final urls = <String>[];
  @override
  Future<fs.File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async {
    expect(headers, isNull);
    urls.add(url);
    return file;
  }
}

class _Wiki implements TagWikiRepository {
  @override
  Future<TagWikiEntry?> find(String tag) async => TagWikiEntry(
    tag: tag,
    body: 'Local wiki text',
    sourceUrl: 'https://danbooru.donmai.us/wiki_pages/$tag',
  );
}

void main() {
  late Directory dir;
  late ProviderContainer container;
  late _Cache cache;
  var metadataCalls = 0;
  var offline = false;
  Completer<Map<String, dynamic>?>? pending;
  CancelToken? networkToken;
  late NaiAgentWikiImages images;
  late NaiAgentStudioTools studio;
  setUp(() async {
    metadataCalls = 0;
    offline = false;
    pending = null;
    dir = await Directory.systemTemp.createTemp('agent-wiki-images-');
    final file = await File(
      '${dir.path}/preview.png',
    ).writeAsBytes(img.encodePng(img.Image(width: 6, height: 4)));
    cache = _Cache(const LocalFileSystem().file(file.path));
    container = ProviderContainer(
      overrides: [
        tagWikiRepositoryProvider.overrideWithValue(_Wiki()),
        wikiExampleImageCacheProvider.overrideWithValue(cache),
        wikiExampleRepositoryProvider.overrideWithValue(
          WikiExampleRepository(
            fetchWiki: (tag, {cancelToken}) async {
              metadataCalls++;
              networkToken = cancelToken;
              if (offline) throw StateError('offline');
              if (pending != null) return pending!.future;
              return {
                'body': 'h4. Examples\n!post #11: [[solo]]\n!post #22: missing',
              };
            },
            fetchPosts: (ids, {cancelToken}) async => [
              {
                'id': 11,
                'media_asset': {
                  'variants': [
                    {
                      'type': '360x360',
                      'url': 'https://cdn.donmai.us/360x360/11.png',
                    },
                    {
                      'type': '720x720',
                      'url': 'https://cdn.donmai.us/720x720/11.png',
                    },
                  ],
                },
              },
            ],
          ),
        ),
      ],
    );
    images = container.read(
      Provider((ref) => NaiAgentWikiImages(ref, () => true)),
    );
    final knowledge = container.read(
      Provider((ref) => naiAgentKnowledgeTools(ref, images: images)),
    );
    studio = NaiAgentStudioTools(
      workspaceDirectory: dir,
      allowsImages: true,
      readSummary: () => {},
      readDraft: () => throw UnimplementedError(),
      isGenerating: () => false,
      backupDraft: (_) async => '',
      writeDraft: (_) => [],
      readImage: (_) => null,
      loadImageById: images.load,
      domainTools: {
        'wiki_query': (p, t) => knowledge['wiki_query']!('wiki_query', p, t),
      },
    );
  });
  tearDown(() async {
    container.dispose();
    await dir.delete(recursive: true);
  });
  Future<Map> query([Map<String, dynamic> fields = const {}]) async =>
      (await studio.execute('wiki_query', {
            'tags': ['1girl'],
            ...fields,
          }, NaiAgentCancellation()))['details']
          as Map;

  test(
    'default offline text, explicit metadata and pixels are fetched in separate steps',
    () async {
      expect((await query())['pages'][0]['body'], 'Local wiki text');
      expect(metadataCalls, 0);
      expect(cache.urls, isEmpty);
      final result = await query({
        'include_examples': true,
        'example_limit': 1,
      });
      expect(result['example_count'], 2);
      expect(result['next_example_offset'], 1);
      expect(cache.urls, isEmpty);
      final id = result['examples'][0]['image_id'];
      final pixels = await studio.execute('image_read', {
        'image_id': id,
      }, NaiAgentCancellation());
      expect(pixels['content'][1]['type'], 'image');
      expect(
        pixels['details']['metadata']['source_url'],
        'https://danbooru.donmai.us/posts/11',
      );
      expect(cache.urls.single, contains('/720x720/'));
      expect(metadataCalls, 1);
    },
  );
  test(
    'missing official illustrations and failed network retain local text and source links',
    () async {
      final result = await query({
        'include_examples': true,
        'example_offset': 1,
      });
      expect(result['examples'][0]['image_id'], isNull);
      expect(result['examples'][0]['source_url'], endsWith('/22'));
      offline = true;
      final other = await query({
        'tags': ['long_hair'],
        'include_examples': true,
      });
      expect(other['examples_error'], 'unavailable');
      expect(other['pages'][0]['body'], 'Local wiki text');
      expect(cache.urls, isEmpty);
    },
  );
  test(
    'forged posts, malformed IDs, invalid page sizes and mixed tags cannot load arbitrary URLs',
    () async {
      await expectLater(
        images.load('wiki:99:1girl', NaiAgentCancellation()),
        throwsA(isA<NaiAgentToolError>()),
      );
      await expectLater(
        images.load('wiki:11:%GG', NaiAgentCancellation()),
        throwsA(isA<NaiAgentToolError>()),
      );
      await expectLater(
        query({'include_examples': true, 'example_limit': 9}),
        throwsA(isA<NaiAgentToolError>()),
      );
      await expectLater(
        query({
          'tags': ['1girl', 'solo'],
          'include_examples': true,
        }),
        throwsA(isA<NaiAgentToolError>()),
      );
      expect(cache.urls, isEmpty);
    },
  );
  test(
    'cancelled metadata requests never publish stale examples or image pixels',
    () async {
      pending = Completer();
      final token = NaiAgentCancellation();
      final future = images.list('1girl', {}, token);
      final assertion = expectLater(
        future,
        throwsA(
          isA<NaiAgentToolError>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      token.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(networkToken!.isCancelled, isTrue);
      pending!.complete({'body': ''});
      await assertion;
      expect(cache.urls, isEmpty);
    },
  );
}
