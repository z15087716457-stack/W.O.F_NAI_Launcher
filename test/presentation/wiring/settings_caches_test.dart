import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/cache/gallery_cache_manager.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_inventory.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_cache_database.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_providers.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/danbooru_completion_source.dart';
import 'package:nai_launcher/core/wiki/visible_tag_translation_cache.dart';
import 'package:nai_launcher/core/wiki/wiki_example_repository.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_item.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_source.dart';
import 'package:nai_launcher/presentation/providers/online_gallery_provider.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_caches.dart';
import 'package:path/path.dart' as p;

import '../../helpers/app_logger_test_isolation.dart';

class _Manager extends Mock implements GalleryCacheManager {}

class _Gallery extends OnlineGalleryNotifier {
  _Gallery(this.initial);
  final OnlineGalleryState initial;
  @override
  OnlineGalleryState build() {
    ref.keepAlive();
    return initial;
  }
}

class _Api implements HttpClientAdapter {
  int requests = 0;
  Completer<ResponseBody>? blocked;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    return blocked?.future ??
        ResponseBody.fromString(
          '[{"name":"blue_eyes","category":0,"post_count":100}]',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
  }

  @override
  void close({bool force = false}) {}
}

CompletionQuery _query() => const CompletionQuery(
  token: 'blue',
  fullText: 'blue',
  cursorPosition: 4,
  replacementRange: TextReplacementRange(start: 0, end: 4),
  existingTags: {},
  limit: 10,
  locale: 'en',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory temp;
  late AutocompleteCacheDatabase legacy;
  late VisibleTagTranslationCache visible;
  late ProviderContainer container;
  late DanbooruCompletionSource completion;
  late WikiExampleRepository examples;
  late _Api api;
  late SettingsCaches caches;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('settings_caches_');
    legacy = AutocompleteCacheDatabase(
      databasePath: () async => p.join(temp.path, 'legacy.db'),
    );
    visible = VisibleTagTranslationCache(
      databasePath: () async => p.join(temp.path, 'visible.db'),
    );
    api = _Api();
    completion = DanbooruCompletionSource(
      cache: legacy,
      dio: Dio(BaseOptions(baseUrl: 'https://synthetic.invalid'))
        ..httpClientAdapter = api,
    );
    examples = WikiExampleRepository(
      fetchWiki: (tag, {cancelToken}) async => {
        'body': 'h2. Examples\n!post #42: sample',
      },
      fetchPosts: (ids, {cancelToken}) async => [
        {'id': 42, 'preview_file_url': 'https://cdn.donmai.us/42.jpg'},
      ],
    );
    const danbooru = GalleryItem(
      id: 1,
      sourceId: GallerySourceId.danbooru,
      tagString: 'blue_eyes',
    );
    const other = GalleryItem(
      id: 2,
      sourceId: GallerySourceId.aiTag,
      tagString: 'keep',
    );
    const initial = OnlineGalleryState(
      sourceId: GallerySourceId.danbooru,
      searchQuery: 'keep query draft',
      favoritedPostKeys: {'danbooru:1', 'ai_tag:2'},
      caches: {
        'search:danbooru:fixture': ModeCache(posts: [danbooru]),
        'search:ai_tag:fixture': ModeCache(posts: [other]),
      },
      searchCache: ModeCache(posts: [danbooru]),
    );
    container = ProviderContainer(
      overrides: [
        autocompleteCacheDatabaseProvider.overrideWithValue(legacy),
        visibleTagTranslationCacheProvider.overrideWithValue(visible),
        danbooruCompletionSourceProvider.overrideWithValue(completion),
        wikiExampleRepositoryProvider.overrideWithValue(examples),
        onlineGalleryNotifierProvider.overrideWith(() => _Gallery(initial)),
      ],
    );
    caches = container.read(settingsCachesProvider);
  });
  tearDown(() async {
    container.dispose();
    await legacy.dispose();
    await visible.close();
    await temp.delete(recursive: true);
  });

  Future<void> seedTranslations() async {
    await legacy.putAiTranslations(
      translations: {'old_tag': '旧译文'},
      locale: 'zh',
      routeFingerprint: 'fixture',
      promptVersion: 1,
    );
    await visible.put(
      tag: 'blue_eyes',
      route: 'fixture',
      promptVersion: 1,
      wikiHash: 'hash',
      nameZh: '蓝眼',
      definition: '蓝色眼睛。',
      wikiZh: '中文正文',
      wikiOriginal: 'Original.',
    );
  }

  test(
    'statistics refresh bypasses TTL and follows invalidation callbacks',
    () async {
      final manager = _Manager();
      final callbacks = <void Function()>[];
      when(() => manager.registerOnStatisticsInvalidated(any())).thenAnswer((
        call,
      ) {
        callbacks.add(call.positionalArguments.single as void Function());
      });
      when(() => manager.unregisterOnStatisticsInvalidated(any())).thenAnswer((
        call,
      ) {
        callbacks.remove(call.positionalArguments.single);
      });
      when(() => manager.getStatistics(refresh: true)).thenAnswer(
        (_) async => CacheStatistics(
          l1MemorySize: 2,
          l1HitRate: .33,
          l1MemoryBytes: 4,
          l2HiveSize: 5,
          l2HitRate: .5,
          l2HiveBytes: 6,
          l3DatabaseImageCount: 9,
          l3DatabaseMetadataCount: 8,
          totalHitRate: .4,
          lastUpdated: DateTime(2026),
        ),
      );
      final statsContainer = ProviderContainer(
        overrides: [
          settingsGalleryCacheManagerProvider.overrideWithValue(manager),
        ],
      );
      final subscription = statsContainer.listen(
        settingsCacheStatsProvider,
        (_, __) {},
      );
      expect(
        (await statsContainer.read(
          settingsCacheStatsProvider.future,
        )).l3DatabaseImageCount,
        9,
      );
      callbacks.single();
      await statsContainer.pump();
      await statsContainer.read(settingsCacheStatsProvider.future);
      verify(() => manager.getStatistics(refresh: true)).called(2);
      subscription.close();
      statsContainer.dispose();
      expect(callbacks, isEmpty);
    },
  );

  test(
    'counts current translations in UTF-8 and clears each category independently',
    () async {
      await seedTranslations();
      await completion.search(_query());
      // Instantiate only the caches actually used, as happens in the app.
      container.read(danbooruCompletionSourceProvider);
      container.read(onlineGalleryNotifierProvider);
      await container.read(wikiExampleRepositoryProvider).forTag('blue_eyes');
      final before = await caches.footprint();
      expect(before[SettingsCacheKind.translation]!.entries, 2);
      expect(
        before[SettingsCacheKind.translation]!.bytes,
        utf8.encode('旧译文蓝眼蓝色眼睛。中文正文Original.').length,
      );
      expect(
        before[SettingsCacheKind.danbooru]!.entries,
        4,
      ); // SQL + completion RAM + gallery + Wiki
      expect(before[SettingsCacheKind.danbooru]!.bytes, greaterThan(0));
      await caches.clear(SettingsCacheKind.danbooru);
      final after = await caches.footprint();
      expect(after[SettingsCacheKind.danbooru]!.entries, 0);
      expect(after[SettingsCacheKind.danbooru]!.bytes, 0);
      expect(after[SettingsCacheKind.translation]!.entries, 2);
      final gallery = container.read(onlineGalleryNotifierProvider);
      expect(gallery.searchQuery, 'keep query draft');
      expect(gallery.favoritedPostKeys, {'danbooru:1', 'ai_tag:2'});
      expect(gallery.caches['search:ai_tag:fixture']!.posts.single.id, 2);
      expect(gallery.caches.containsKey('search:danbooru:fixture'), isFalse);
      // A fresh lookup must go to the stub again, not the old five-minute RAM hit.
      await completion.search(_query());
      expect(api.requests, 2);
      await caches.clear(SettingsCacheKind.translation);
      expect(
        (await caches.footprint())[SettingsCacheKind.translation]!.entries,
        0,
      );
      expect(await visible.chineseTerms(['blue_eyes']), isEmpty);
      expect((await legacy.statistics())['danbooruCache'], 1);
    },
  );

  test(
    'clear rejects old database writers and permits new generations',
    () async {
      final oldRemote = legacy.remoteGeneration;
      final oldTranslation = legacy.translationGeneration;
      final oldVisible = visible.generation;
      await caches.clear(SettingsCacheKind.danbooru);
      await caches.clear(SettingsCacheKind.translation);
      await legacy.putRemote('late', [
        {'tag': 'late'},
      ], expectedGeneration: oldRemote);
      await legacy.putAiTranslations(
        translations: {'late': '迟到'},
        locale: 'zh',
        routeFingerprint: 'fixture',
        promptVersion: 1,
        expectedGeneration: oldTranslation,
      );
      await visible.put(
        tag: 'late',
        route: 'fixture',
        promptVersion: 1,
        wikiHash: 'hash',
        nameZh: '迟到',
        expectedGeneration: oldVisible,
      );
      final empty = await caches.footprint();
      expect(empty.values.map((v) => v.entries), everyElement(0));
      await seedTranslations();
      expect(
        (await caches.footprint())[SettingsCacheKind.translation]!.entries,
        2,
      );
    },
  );

  test(
    'a pre-clear completion request cannot resurrect disk or RAM entries',
    () async {
      api.blocked = Completer<ResponseBody>();
      container.read(danbooruCompletionSourceProvider);
      final pending = completion.search(_query());
      while (api.requests == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      await caches.clear(SettingsCacheKind.danbooru);
      api.blocked!.complete(
        ResponseBody.fromString(
          '[]',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
      expect(await pending, isEmpty);
      expect(completion.footprint.entries, 0);
      expect((await legacy.statistics())['danbooruCache'], 0);
    },
  );

  test('Wiki results finishing after clear are not retained', () async {
    final blocked = Completer<Map<String, dynamic>?>();
    final repository = WikiExampleRepository(
      fetchWiki: (tag, {cancelToken}) => blocked.future,
      fetchPosts: (ids, {cancelToken}) async => [],
    );
    final pending = repository.forTag('blue_eyes');
    repository.clearCache();
    blocked.complete({'body': ''});
    await pending;
    expect(repository.footprint.entries, 0);
    await repository.forTag('blue_eyes');
    expect(repository.footprint.entries, 1);
  });
}
