import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nai_launcher/core/cache/danbooru_image_cache_manager.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/datasources/remote/online_gallery/ai_tag_gallery_source_adapter.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_item.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_source.dart';
import 'package:nai_launcher/data/repositories/online_favorites_repository.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import 'package:nai_launcher/presentation/providers/online_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/online_favorites_provider.dart'
    show OnlineFavoritesState;
import 'package:nai_launcher/presentation/wiring/online_mapping.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../tool/online_gallery/verify_live_sources.dart' as live;

const _runLive = bool.fromEnvironment('LIVE_AI_TAG');
const _workId = int.fromEnvironment(
  'LIVE_AI_TAG_WORK',
  defaultValue: 149295769,
);
const _proxy = String.fromEnvironment('LIVE_AI_TAG_PROXY');
const _maxImageBytes = 8 * 1024 * 1024;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('live image signature detection does not trust the extension', () {
    expect(live.liveImageFormat([137, 80, 78, 71, 13, 10, 26, 10]), 'png');
    expect(live.liveImageFormat([255, 216, 255]), 'jpeg');
    expect(live.liveImageFormat(ascii.encode('RIFF0000WEBP')), 'webp');
    expect(live.liveImageFormat(ascii.encode('<html>403</html>')), 'unknown');
  });

  test(
    'AI TAG production config/detail/images/favorites live smoke',
    () async {
      final parent = Directory('tool/.tmp')..createSync(recursive: true);
      final directory = parent.createTempSync('q5_live_');
      final previousPaths = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _LivePaths(directory.absolute.path);
      AppLogger.debugSetMinimumLevelForTesting(Level.off);
      sqfliteFfiInit();
      final repository = OnlineFavoritesRepository.forTesting(
        '${directory.path}/favorites.db',
      );
      DanbooruImageCacheManager? cacheToDispose;
      try {
        await HttpOverrides.runWithHttpOverrides(() async {
          final cache = DanbooruImageCacheManager.instance;
          cacheToDispose = cache;
          final dio = live.createLiveSourceDio();
          dio.interceptors.add(
            InterceptorsWrapper(
              onResponse: (response, handler) {
                if (response.requestOptions.uri.host == 'aitag.win') {
                  stdout.writeln(
                    'API ${response.requestOptions.uri.path}: status=${response.statusCode} content-type=${response.headers.value(Headers.contentTypeHeader)} bytes=${utf8.encode(jsonEncode(response.data)).length}',
                  );
                }
                handler.next(response);
              },
            ),
          );
          try {
            final adapter = AiTagGallerySourceAdapter(dio: dio);
            final config = await adapter.getConfig();
            expect(await adapter.getConfig(), same(config));
            stdout.writeln(
              'CONFIG asset-host=${Uri.parse(config.assetBaseUrl).host} cached=true',
            );
            final detail = await adapter.detail(
              const GalleryItem(id: _workId, sourceId: GallerySourceId.aiTag),
            );
            expect(detail.item.id, _workId);
            expect(detail.media, isNotEmpty);
            stdout.writeln(
              'DETAIL work=$_workId media-count=${detail.media.length}',
            );
            final pages = onlineDetail(
              detail,
              const OnlineFavoritesState(),
            ).media;
            expect(pages.length, detail.media.length);
            for (final (index, original) in detail.media.indexed) {
              expect(
                pages[index].prompt,
                original.prompt,
                reason: 'page ${index + 1}',
              );
              expect(
                pages[index].negative,
                original.negativePrompt,
                reason: 'page ${index + 1}',
              );
              expect(
                pages[index].params?.seed,
                original.naiMetadata?.seed,
                reason: 'page ${index + 1}',
              );
            }
            final distinct = pages
                .map((p) => p.prompt)
                .whereType<String>()
                .toSet()
                .length;
            stdout.writeln(
              'Page metadata verified: ${pages.length} pages, $distinct distinct positive prompts'
              '${pages.length >= 4 ? ", page 4 differs from cover: ${pages[3].prompt != pages.first.prompt}" : ""}',
            );
            final media = detail.media.first;
            for (final (label, url) in [
              ('detail-main', media.displayUrl),
              ('detail-thumbnail', media.previewUrl),
            ]) {
              final headers = onlineGalleryImageHeadersForUrl(url);
              expect(headers['Referer'], 'https://aitag.win/');
              expect(headers['Accept'], contains('image/'));
              expect(headers['User-Agent'], isNotEmpty);
              expect(onlineGalleryImageCacheKeyForUrl(url), isNull);
              final evidence = await live.verifyLiveMedia(
                dio,
                url,
                label,
                headers: headers,
                maxBytes: _maxImageBytes,
              );
              expect(evidence.status, 200);
              expect(evidence.format, isNot('unknown'));
              stdout.writeln(
                '$label: host=${Uri.parse(url).host} status=${evidence.status} content-type=${evidence.contentType} bytes=${evidence.bytes} format=${evidence.format}',
              );
            }
            await repository.addFavorite(detail.item);
            final favorite = (await repository.listFavorites(
              GallerySourceId.aiTag,
            )).single.item;
            final url = favorite.cover.downloadUrl;
            expect(url, media.downloadUrl);
            expect(await cache.getFileFromCache(url), isNull);
            final file = await cache
                .getSingleFile(
                  url,
                  key: onlineGalleryImageCacheKeyForUrl(url),
                  headers: onlineGalleryImageHeadersForUrl(url),
                )
                .timeout(const Duration(seconds: 60));
            final bytes = await file.readAsBytes();
            expect(bytes.length, inInclusiveRange(1024, _maxImageBytes));
            final format = live.liveImageFormat(bytes);
            expect(format, isNot('unknown'));
            expect(await cache.getFileFromCache(url), isNotNull);
            final cachedFile = await cache.getSingleFile(
              url,
              key: onlineGalleryImageCacheKeyForUrl(url),
              headers: onlineGalleryImageHeadersForUrl(url),
            );
            expect(cachedFile.path, file.path);

            final container = ProviderContainer(
              overrides: [
                onlineGallerySourceAdaptersProvider.overrideWith(
                  (ref) => {GallerySourceId.aiTag: adapter},
                ),
              ],
            );
            try {
              final studio = container.read(naiAgentStudioFactoryProvider)(
                directory.absolute,
                directory.absolute,
                true,
              );
              final token = NaiAgentCancellation();
              final search = await studio.execute('online_gallery', {
                'action': 'search',
                'source': 'ai_tag',
                'limit': 1,
              }, token);
              expect(search['details']['source'], 'ai_tag');
              expect(search['details']['items'], isA<List>());
              final online = await studio.execute('online_gallery', {
                'action': 'detail',
                'image_id': 'online:ai_tag:$_workId:1',
              }, token);
              final pageMetadata = online['details'] as Map;
              final id = pageMetadata['image_id'];
              final sourceMetadata = detail.media.first.naiMetadata;
              expect(
                pageMetadata,
                containsPair('use_coords', sourceMetadata?.characterUseCoords),
              );
              if (sourceMetadata?.characterUseCoords == true) {
                expect(pageMetadata['positions'], [
                  for (final character in sourceMetadata!.characterInfos)
                    if (character.centerX == null || character.centerY == null)
                      null
                    else
                      {'x': character.centerX, 'y': character.centerY},
                ]);
              } else {
                expect(pageMetadata.containsKey('positions'), isFalse);
              }
              if (sourceMetadata?.seed != null) {
                expect(
                  pageMetadata['generation']['seed'],
                  sourceMetadata!.seed,
                );
              }
              stdout.writeln(
                'Agent page modes: custom=${detail.media.where((m) => m.naiMetadata?.characterUseCoords == true).length}, auto=${detail.media.where((m) => m.naiMetadata?.characterUseCoords == false).length}, total=${detail.media.length}',
              );
              expect(online['details']['page_count'], detail.media.length);
              final view = await studio.execute('image_read', {
                'image_id': id,
              }, token);
              expect(view['content'].last['type'], 'image');
              expect(
                view['details']['metadata']['use_coords'],
                pageMetadata['use_coords'],
              );
              expect(
                view['details']['metadata']['positions'],
                pageMetadata['positions'],
              );
              final download = await studio.execute('online_gallery', {
                'action': 'download',
                'image_id': id,
              }, token);
              expect(download['details']['ok'], isTrue);
              final path =
                  download['details']['files'].single['path'] as String;
              expect(p.isRelative(path), isTrue);
              expect(
                await File(p.join(directory.path, path)).readAsBytes(),
                bytes,
              );
              stdout.writeln(
                'Agent search/detail/image_read/workspace download: verified bytes=${bytes.length}',
              );
            } finally {
              container.dispose();
            }
            final codec = await ui.instantiateImageCodec(bytes);
            try {
              final frame = await codec.getNextFrame();
              try {
                expect(frame.image.width, greaterThan(0));
                expect(frame.image.height, greaterThan(0));
                stdout.writeln(
                  'favorite-getSingleFile: result=success initially-cached=false bytes=${bytes.length} format=$format decoded=${frame.image.width}x${frame.image.height} URL-key=true cached-repeat=true',
                );
              } finally {
                frame.image.dispose();
              }
            } finally {
              codec.dispose();
            }
          } finally {
            dio.close(force: true);
          }
        }, _LiveHttpOverrides(_proxy));
      } finally {
        await repository.close();
        await cacheToDispose?.dispose();
        PathProviderPlatform.instance = previousPaths;
        AppLogger.debugSetMinimumLevelForTesting(null);
        if (directory.existsSync()) directory.deleteSync(recursive: true);
      }
    },
    skip: !_runLive
        ? 'Opt in with --dart-define=LIVE_AI_TAG=true; public reads only'
        : false,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

class _LivePaths extends PathProviderPlatform {
  _LivePaths(this.path);
  final String path;

  @override
  Future<String?> getTemporaryPath() async => path;

  @override
  Future<String?> getApplicationSupportPath() async => path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

class _LiveHttpOverrides extends HttpOverrides {
  _LiveHttpOverrides(this.proxy);
  final String proxy;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionTimeout = const Duration(seconds: 30);
    if (proxy.isNotEmpty) {
      final uri = Uri.parse(proxy);
      if (uri.scheme != 'http' || uri.host.isEmpty || !uri.hasPort) {
        throw ArgumentError(
          'LIVE_AI_TAG_PROXY must be an HTTP proxy URL with a port',
        );
      }
      client.findProxy = (_) => 'PROXY ${uri.host}:${uri.port}';
    }
    return client;
  }
}
