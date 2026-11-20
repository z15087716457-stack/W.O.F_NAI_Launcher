import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';
import 'package:nai_launcher/data/datasources/remote/online_gallery/gallery_source_adapter.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_item.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_source.dart';
import 'package:nai_launcher/data/services/gallery/online_gallery_download_service.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_online_gallery.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import 'package:nai_launcher/presentation/providers/online_gallery_media_provider.dart';
import 'package:nai_launcher/presentation/providers/online_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:path/path.dart' as p;

class _Source extends GallerySourceAdapter {
  @override
  final sourceId = GallerySourceId.aiTag;
  final requests = <GallerySearchRequest>[];
  @override
  Future<GalleryPage> search(
    GallerySearchRequest request, {
    CancelToken? cancelToken,
  }) async {
    requests.add(request);
    return GalleryPage(
      items: [
        for (final id in [1, 2, 3])
          GalleryItem(
            id: id,
            sourceId: sourceId,
            aiType: id == 2 ? 'Other' : 'NAI_X',
            mediaCount: 3,
          ),
      ],
      cursor: '1',
      nextCursor: '2',
      hasMore: true,
      rawItemCount: 3,
    );
  }

  @override
  Future<GalleryDetail> detail(
    GalleryItem item, {
    CancelToken? cancelToken,
  }) async => GalleryDetail(
    item: item,
    media: [
      for (final page in [1, 2, 3])
        GalleryMedia(
          id: 'p$page',
          displayUrl: 'preview$page',
          downloadUrl: page == 3 ? '' : 'original$page',
          prompt: 'prompt$page',
          negativePrompt: 'negative$page',
          metadata: {'seed': page},
          naiMetadata: NaiImageMetadata(
            seed: page,
            steps: 28,
            scale: 5.5,
            characterUseCoords: page == 3 ? null : page == 2,
            characterInfos: [
              CharacterPromptInfo(
                prompt: 'character$page',
                centerX: page == 2 ? .75 : .5,
                centerY: .5,
              ),
            ],
            characterPrompts: ['character$page'],
            characterNegativePrompts: ['characterNegative$page'],
          ),
        ),
    ],
  );
}

class _Media extends OnlineGalleryDownloadService {
  final urls = <String>[];
  final preview = img.encodePng(img.Image(width: 4, height: 3));
  final original = img.encodePng(img.Image(width: 12, height: 8));
  Completer<Uint8List>? pending;
  final secondPageStarted = Completer<void>();
  @override
  Future<Uint8List> bytesForUrl(String url) async {
    urls.add(url);
    if (url == 'original2' && pending != null) {
      secondPageStarted.complete();
      return pending!.future;
    }
    return url.startsWith('original') ? original : preview;
  }
}

class _Library extends LocalGalleryNotifier {
  final indexed = <String>[];
  @override
  LocalGalleryState build() => const LocalGalleryState();
  @override
  Future<int> addNewlySavedImages(List<String> paths) async {
    indexed.addAll(paths);
    return paths.length;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root, library;
  late ProviderContainer container;
  late _Source source;
  late _Media media;
  late _Library index;
  late NaiAgentStudioTools studio;
  const selected = GalleryItem(
    id: 1,
    sourceId: GallerySourceId.aiTag,
    mediaCount: 3,
  );
  setUp(() async {
    root = await Directory.systemTemp.createTemp('online-agent-');
    library = await Directory(p.join(root.path, 'gallery')).create();
    source = _Source();
    media = _Media();
    index = _Library();
    container = ProviderContainer(
      overrides: [
        onlineGallerySourceAdaptersProvider.overrideWith(
          (ref) => {source.sourceId: source},
        ),
        onlineGalleryDownloadServiceProvider.overrideWithValue(media),
        onlineGalleryLibraryDirectoryProvider.overrideWithValue(
          () async => library,
        ),
        localGalleryNotifierProvider.overrideWith(() => index),
      ],
    );
    studio = container.read(naiAgentStudioFactoryProvider)(root, root, true);
  });
  tearDown(() async {
    container.dispose();
    await root.delete(recursive: true);
  });
  Future<Map> call(
    String action, [
    Map<String, dynamic> args = const {},
  ]) async =>
      (await studio.execute('online_gallery', {
            'action': action,
            ...args,
          }, NaiAgentCancellation()))['details']
          as Map;
  test(
    'current uses the displayed page, pure metadata and actual preview pixels',
    () async {
      final selection = container.read(onlineGallerySelectionProvider)
        ..select(selected)
        ..setMedia(selected.stableKey, 1);
      final current = await call('current');
      expect(current, containsPair('image_id', 'online:ai_tag:1:2'));
      expect(current, containsPair('prompt', 'prompt2'));
      expect(current, containsPair('negative_prompt', 'negative2'));
      expect(current, containsPair('seed', 2));
      expect(current['character_prompts'], ['character2']);
      expect(current['character_negative_prompts'], ['characterNegative2']);
      expect(current['use_coords'], true);
      expect(current['positions'], [
        {'x': .75, 'y': .5},
      ]);
      expect(current['generation'], containsPair('cfg_scale', 5.5));
      final automatic = await call('detail', {
        'image_id': current['image_id'],
        'page': 1,
      });
      expect(automatic['use_coords'], false);
      expect(automatic.containsKey('positions'), false);
      final unknown = await call('detail', {
        'image_id': current['image_id'],
        'page': 3,
      });
      expect(unknown, containsPair('use_coords', null));
      expect(unknown.containsKey('positions'), false);
      expect(media.urls, isEmpty);
      final picture = await studio.execute('image_read', {
        'image_id': current['image_id'],
      }, NaiAgentCancellation());
      expect(picture['content'].last['type'], 'image');
      expect(picture['details']['width'], 4);
      expect(media.urls, ['preview2']);
      final original = await studio.loadImage({
        'image_id': current['image_id'],
      }, NaiAgentCancellation());
      expect(original.bytes, media.original);
      final info = await studio.execute('image_read', {
        'image_id': current['image_id'],
        'metadata_only': true,
      }, NaiAgentCancellation());
      expect(info['details']['width'], 12);
      expect(info['content'], hasLength(1));
      for (final r in [info, picture]) {
        expect(r['details']['metadata']['positions'], current['positions']);
        expect(r['details']['metadata']['use_coords'], true);
      }
      selection.select(null);
      await expectLater(
        call('current'),
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'no_selection',
          ),
        ),
      );
    },
  );
  test(
    'independent search keeps filters, pagination and the user selection',
    () async {
      final selection = container.read(onlineGallerySelectionProvider)
        ..select(selected)
        ..setMedia(selected.stableKey, 1);
      final before = container.read(onlineGalleryNotifierProvider);
      final first = await call('search', {
        'query': 'rain',
        'prompt': 'backlight',
        'limit': 1,
      });
      final next = await call('search', {
        'query': 'rain',
        'prompt': 'backlight',
        'limit': 1,
        'cursor': first['next_cursor'],
      });
      expect(first['items'].single['image_id'], 'online:ai_tag:1:1');
      expect(next['items'].single['image_id'], 'online:ai_tag:3:1');
      expect(next['next_cursor'], '2');
      expect(source.requests.last.prompt, 'backlight');
      expect(container.read(onlineGalleryNotifierProvider), same(before));
      expect(selection.page, 2);
      expect(media.urls, isEmpty);
    },
  );
  test(
    'downloads return original bytes and reusable workspace or library paths',
    () async {
      final result = await call('download', {'image_id': 'online:ai_tag:1:2'});
      final relative = result['files'].single['path'] as String;
      expect(p.isRelative(relative), isTrue);
      expect(
        await File(p.join(root.path, relative)).readAsBytes(),
        media.original,
      );
      final reread = await studio.execute('image_read', {
        'path': relative,
        'metadata_only': true,
      }, NaiAgentCancellation());
      expect(reread['details']['width'], 12);
      final existing = await File(
        p.join(library.path, 'ai_tag_1_p02.png'),
      ).writeAsBytes([9]);
      final batch = await call('download', {
        'image_id': 'online:ai_tag:1:2',
        'destination': 'library',
        'all_pages': true,
      });
      expect(batch['ok'], false);
      expect(batch['files'].map((e) => e['page']), [1, 2]);
      expect(batch['failures'].single['code'], 'original_unavailable');
      expect(await existing.readAsBytes(), [9]);
      expect(index.indexed.map(p.basename), [
        'ai_tag_1_p01.png',
        'ai_tag_1_p02_1.png',
      ]);
      expect(batch['files'].map((e) => e['path']), index.indexed);
      expect(media.urls, ['original2', 'original1', 'original2']);
    },
  );
  test(
    'bad IDs, pages and destinations cannot save the cover or an external path',
    () async {
      for (final args in [
        {'image_id': 'https://example.test/1.png'},
        {'image_id': 'online:invalid:1:1'},
        {'image_id': 'online:ai_tag:1:4'},
        {'image_id': 'online:ai_tag:1:2', 'destination': '../outside'},
      ]) {
        await expectLater(
          call('download', args),
          throwsA(isA<NaiAgentToolError>()),
        );
      }
      expect(media.urls, isEmpty);
      expect(library.listSync(), isEmpty);
    },
  );
  test(
    'stopping a whole work indexes the library pages already saved',
    () async {
      media.pending = Completer();
      final token = NaiAgentCancellation();
      final result = studio.execute('online_gallery', {
        'action': 'download',
        'image_id': 'online:ai_tag:1:1',
        'destination': 'library',
        'all_pages': true,
      }, token);
      await media.secondPageStarted.future;
      token.cancel();
      media.pending!.complete(media.original);
      await expectLater(
        result,
        throwsA(
          isA<NaiAgentToolError>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );
      expect(index.indexed.map(p.basename), ['ai_tag_1_p01.png']);
      expect(library.listSync().length, 1);
    },
  );

  test('cancelling during the transfer leaves no exported file', () async {
    media.pending = Completer();
    final token = NaiAgentCancellation();
    final result = studio.execute('online_gallery', {
      'action': 'download',
      'image_id': 'online:ai_tag:1:2',
    }, token);
    await media.secondPageStarted.future;
    expect(media.urls, ['original2']);
    token.cancel();
    media.pending!.complete(media.original);
    await expectLater(
      result,
      throwsA(
        isA<NaiAgentToolError>().having((e) => e.code, 'code', 'cancelled'),
      ),
    );
    expect(
      Directory(p.join(root.path, '.W.O.F', 'outputs')).existsSync(),
      false,
    );
  });
}
