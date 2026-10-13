import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:nai_launcher/core/cache/danbooru_image_cache_manager.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_item.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_source.dart';
import 'package:nai_launcher/data/repositories/online_favorites_repository.dart'
    as repository;
import 'package:nai_launcher/data/services/danbooru_auth_service.dart';
import 'package:nai_launcher/data/services/gelbooru_auth_service.dart';
import 'package:nai_launcher/l10n/app_localizations_en.dart';
import 'package:nai_launcher/presentation/providers/online_favorites_provider.dart'
    as favorites;
import 'package:nai_launcher/presentation/providers/online_gallery_blacklist_provider.dart';
import 'package:nai_launcher/presentation/providers/online_gallery_preferences_provider.dart';
import 'package:nai_launcher/presentation/providers/online_gallery_provider.dart';
import 'package:nai_launcher/presentation/ui/online/online_contract.dart';
import 'package:nai_launcher/presentation/wiring/online_mapping.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cacheDirectory;
  setUpAll(() async {
    cacheDirectory = await Directory.systemTemp.createTemp(
      'online_mapping_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => cacheDirectory.path,
        );
    await DanbooruImageCacheManager.instance.getFileFromCache('test-init');
  });
  tearDownAll(() async {
    await DanbooruImageCacheManager.instance.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await cacheDirectory.delete(recursive: true);
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'selecting a model enables the NAI filter in a single request',
    () async {
      final notifier = _Gallery(const OnlineGalleryState(aiTagNaiOnly: false));
      final container = _container(notifier);
      await container
          .read(onlineGalleryNotifierProvider.notifier)
          .setAiTagModelVersion('5');
      final state = container.read(onlineGalleryNotifierProvider);
      expect(state.aiTagNaiOnly, isTrue);
      expect(state.aiTagModelVersion, '5');
      expect(notifier.loads, 1);
    },
  );

  test('disabling NAI clears the selected model', () async {
    final container = _container(
      _Gallery(const OnlineGalleryState(aiTagModelVersion: '4.5')),
    );
    await container
        .read(onlineGalleryNotifierProvider.notifier)
        .setAiTagNaiOnly(false);
    final state = container.read(onlineGalleryNotifierProvider);
    expect(state.aiTagNaiOnly, isFalse);
    expect(state.aiTagModelVersion, isNull);
  });

  test('source mapping is bijective without relying on enum ordinals', () {
    for (final source in GallerySourceId.values) {
      expect(gallerySource(onlineSource(source)), source);
    }
    for (final source in OnlineSource.values) {
      expect(onlineSource(gallerySource(source)), source);
    }
  });

  test(
    'mode changes follow the active source and reject unsupported modes',
    () async {
      final notifier = _Gallery(const OnlineGalleryState());
      final container = _container(notifier);
      container.read(onlineGalleryNotifierProvider);
      await notifier.setActiveSource(GallerySourceId.danbooru);
      await notifier.setViewMode(GalleryViewMode.popular);
      expect(
        container.read(onlineGalleryNotifierProvider).currentSourceId,
        GallerySourceId.danbooru,
      );
      await notifier.setViewMode(GalleryViewMode.favorites);
      await notifier.setActiveSource(GallerySourceId.gelbooru);
      expect(
        container.read(onlineGalleryNotifierProvider).activeCapabilities,
        GallerySourceId.gelbooru.capabilities,
      );
      await notifier.setViewMode(GalleryViewMode.popular);
      expect(
        container.read(onlineGalleryNotifierProvider).viewMode,
        GalleryViewMode.favorites,
      );
      expect(
        container.read(onlineGalleryNotifierProvider).currentSourceId,
        GallerySourceId.gelbooru,
      );
      await notifier.setViewMode(GalleryViewMode.search);
      expect(
        container.read(onlineGalleryNotifierProvider).sourceId,
        GallerySourceId.gelbooru,
      );
    },
  );

  test(
    'source switching restores queries and the exact cached scroll offset',
    () async {
      final initial =
          const OnlineGalleryState(
            searchQuery: 'first',
            promptQuery: 'sunset',
          ).updateCurrentCache(
            const ModeCache(
              posts: [GalleryItem(id: 1, sourceId: GallerySourceId.aiTag)],
              scrollOffset: 123,
            ),
          );
      final notifier = _Gallery(initial);
      final container = _container(notifier);
      container.read(onlineGalleryNotifierProvider);
      await notifier.setActiveSource(GallerySourceId.danbooru);
      await notifier.submitQuery(query: 'solo', prompt: '', fuzzy: true);
      await notifier.setActiveSource(GallerySourceId.aiTag);
      final restored = container.read(onlineGalleryNotifierProvider);
      expect(restored.searchQuery, 'first');
      expect(restored.promptQuery, 'sunset');
      expect(restored.scrollOffset, 123);
      expect(restored.posts.single.id, 1);
    },
  );

  test(
    'query and fuzzy flag are submitted atomically in the active mode',
    () async {
      final notifier = _Gallery(
        const OnlineGalleryState(
          viewMode: GalleryViewMode.popular,
          popularSourceId: GallerySourceId.danbooru,
        ),
      );
      final container = _container(notifier);
      container.read(onlineGalleryNotifierProvider);
      await notifier.submitQuery(query: ' solo ', prompt: '', fuzzy: true);
      final state = container.read(onlineGalleryNotifierProvider);
      expect(state.viewMode, GalleryViewMode.popular);
      expect(state.popularQuery, 'solo');
      expect(state.fuzzySearchEnabled, isTrue);
      expect(notifier.loads, 1);
    },
  );

  test('preferences survive rebuilding and use three card widths', () async {
    final first = _Preferences(const OnlineGalleryPreferencesStore());
    await first.ready;
    await first.setCardSize(OnlineCardSize.large);
    await first.setSidebar(false);
    await first.setInspector(false);
    await first.rememberSend(OnlineSendMode.promptOnly);
    first.dispose();
    final second = _Preferences(const OnlineGalleryPreferencesStore());
    addTearDown(second.dispose);
    await second.ready;
    expect(second.value.cardSize, OnlineCardSize.large);
    expect(second.value.sidebarOpen, isFalse);
    expect(second.value.inspectorOpen, isFalse);
    expect(second.value.sendMode, OnlineSendMode.promptOnly);
    expect(OnlineCardSize.values.map(onlineCardWidth), [160, 210, 280]);
  });

  test(
    'legacy width rounds to nearest size and unknown send modes stay unset',
    () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.onlineGalleryColumnWidth: 200.0,
        StorageKeys.onlineGallerySendMode: 'unknown',
      });
      final state = await const OnlineGalleryPreferencesStore().load();
      expect(state.cardSize, OnlineCardSize.medium);
      expect(state.sendMode, isNull);
    },
  );

  test(
    'recent searches are source-isolated, deduplicated, bounded and clearable',
    () async {
      final notifier = _Preferences(const OnlineGalleryPreferencesStore());
      addTearDown(notifier.dispose);
      for (var index = 0; index < 10; index++) {
        await notifier.addRecent(
          OnlineSource.aiTag,
          OnlineRecent(kind: OnlineRecentKind.work, text: 'word$index'),
        );
      }
      const prompt = OnlineRecent(
        kind: OnlineRecentKind.prompt,
        text: 'sunset',
      );
      await notifier.addRecent(OnlineSource.danbooru, prompt);
      await notifier.addRecent(
        OnlineSource.aiTag,
        const OnlineRecent(kind: OnlineRecentKind.work, text: 'word8'),
      );
      final restored = await const OnlineGalleryPreferencesStore().load();
      expect(restored.recent[OnlineSource.aiTag], hasLength(8));
      expect(restored.recent[OnlineSource.aiTag]!.first.text, 'word8');
      expect(restored.recent[OnlineSource.danbooru], [prompt]);
      await notifier.clearRecent(OnlineSource.aiTag);
      final cleared = await const OnlineGalleryPreferencesStore().load();
      expect(cleared.recent[OnlineSource.aiTag], isEmpty);
      expect(cleared.recent[OnlineSource.danbooru], [prompt]);
    },
  );

  test(
    'malformed recent entries are skipped without discarding valid history',
    () async {
      SharedPreferences.setMockInitialValues({
        'online_gallery_recent_ai_tag': [
          '{',
          jsonEncode({'kind': 'unknown', 'text': 'x'}),
          jsonEncode({'kind': 'work', 'text': 'solo'}),
        ],
      });
      final restored = await const OnlineGalleryPreferencesStore().load();
      expect(restored.recent[OnlineSource.aiTag], [
        const OnlineRecent(kind: OnlineRecentKind.work, text: 'solo'),
      ]);
    },
  );

  test(
    'late preference restoration does not overwrite newer user choices',
    () async {
      final store = _SlowPreferences();
      final notifier = _Preferences(store);
      addTearDown(notifier.dispose);
      final write = notifier.setSidebar(false);
      final remember = notifier.rememberSend(OnlineSendMode.withParams);
      store.result.complete(
        const OnlineGalleryPreferences(
          sidebarOpen: true,
          inspectorOpen: false,
          cardSize: OnlineCardSize.large,
        ),
      );
      await write;
      await remember;
      expect(notifier.value.sidebarOpen, isFalse);
      expect(notifier.value.inspectorOpen, isFalse);
      expect(notifier.value.cardSize, OnlineCardSize.large);
      expect(notifier.value.sendMode, OnlineSendMode.withParams);
    },
  );

  test(
    'view mapping keeps capabilities, list state, preferences and send context',
    () {
      final state =
          const OnlineGalleryState(
            isLoadingMore: true,
            viewMode: GalleryViewMode.popular,
            popularSourceId: GallerySourceId.danbooru,
            popularQuery: 'solo',
          ).updateCurrentCache(
            const ModeCache(
              posts: [
                GalleryItem(
                  id: 42,
                  sourceId: GallerySourceId.danbooru,
                  score: 12,
                  rating: 'q',
                ),
              ],
              page: 3,
              scrollOffset: 321,
              appendErrorCode: OnlineGalleryErrorCode.timeout,
            ),
          );
      final data = onlineViewData(
        state: state,
        saved: const favorites.OnlineFavoritesState(),
        preferences: const OnlineGalleryPreferences(
          cardSize: OnlineCardSize.small,
          sidebarOpen: false,
          sendMode: OnlineSendMode.replace,
        ),
        blacklist: const OnlineGalleryBlacklistState(
          localTags: {'foo'},
          remoteTags: {'bar'},
          autoSyncOnStartup: false,
        ),
        danbooru: const DanbooruAuthState(),
        gelbooru: const GelbooruAuthState(status: GelbooruAuthStatus.invalid),
        l10n: AppLocalizationsEn(),
        promptLength: 14,
        characterCount: 2,
        reducedMotion: true,
      );
      expect(data.source, OnlineSource.danbooru);
      expect(data.mode, OnlineMode.ranking);
      expect(data.query.tags, ['solo']);
      expect(data.list.items.single.key, 'danbooru:42');
      expect(data.list.items.single.rating, OnlineRating.questionable);
      expect(data.list.loadingMore, isTrue);
      expect(data.list.pages, 3);
      expect(data.list.appendError!.page, 4);
      expect(data.list.initialOffset, 321);
      expect(data.sources.first.favoritesLocal, isTrue);
      expect(data.sources.first.favoritesWritable, isTrue);
      expect(data.sources.last.account, OnlineAccountState.keyInvalid);
      expect(data.blacklist.tags, ['foo']);
      expect(data.blacklist.danbooruCount, 1);
      expect(data.send.promptLength, 14);
      expect(data.send.characterCount, 2);
      expect(data.send.remembered, OnlineSendMode.replace);
      expect(data.sidebarOpen, isFalse);
      expect(data.reducedMotion, isTrue);
    },
  );

  test(
    'favorites filtering respects all, ungrouped, subsets, author and text',
    () {
      final saved = favorites.OnlineFavoritesState(
        entries: [
          repository.OnlineFavoriteEntry(
            item: const GalleryItem(
              id: 1,
              title: 'Sunset',
              uploaderId: 8,
              tags: ['solo'],
            ),
            collectionId: null,
            savedAt: DateTime(2026),
          ),
          repository.OnlineFavoriteEntry(
            item: const GalleryItem(id: 2, author: 'Artist', uploaderId: 9),
            collectionId: 'set',
            savedAt: DateTime(2026),
          ),
        ],
      );
      expect(onlineLocalFavorites(saved), hasLength(2));
      expect(onlineLocalFavorites(saved, collectionId: '').single.id, 1);
      expect(onlineLocalFavorites(saved, collectionId: 'set').single.id, 2);
      expect(
        onlineLocalFavorites(saved, collectionId: 'set', authorId: 8).single.id,
        1,
      );
      expect(onlineLocalFavorites(saved, filter: 'SUN').single.id, 1);
      expect(onlineLocalFavorites(saved, filter: 'solo').single.id, 1);
      expect(onlineLocalFavorites(saved, filter: 'artist').single.id, 2);
    },
  );

  test('detail retains full metadata and uses the shared image cache', () {
    const media = GalleryMedia(
      id: 'p0',
      displayUrl: 'https://example.test/a.png',
      width: 832,
      height: 1216,
      prompt: 'solo',
      negativePrompt: '',
      naiMetadata: NaiImageMetadata(
        prompt: 'solo',
        model: 'nai-diffusion-5-full',
        seed: 123,
        steps: 28,
        scale: 5.5,
        width: 832,
        height: 1216,
        sampler: 'k_euler_ancestral',
      ),
    );
    const detail = GalleryDetail(
      item: GalleryItem(
        id: 1,
        sourceId: GallerySourceId.aiTag,
        title: 'work',
        uploaderId: 8,
      ),
      media: [media],
    );
    final mapped = onlineDetail(detail, const favorites.OnlineFavoritesState());
    expect(mapped.canSendParams, isTrue);
    expect(mapped.params!.model, 'NAI Diffusion V5 (Full)');
    expect(mapped.params!.seed, 123);
    expect(mapped.params!.sampler, 'Euler Ancestral');
    expect(mapped.negative, '');
    expect(mapped.media.single.image, isA<CachedNetworkImageProvider>());
    expect(media.copyWith(width: 1024).naiMetadata, media.naiMetadata);
    final restored = GalleryItem.fromSnapshotJson(
      detail.item.copyWith(cover: media).toSnapshotJson(),
    );
    expect(restored.cover.naiMetadata, media.naiMetadata);
    expect(restored.cover.prompt, 'solo');
  });

  test(
    'video metadata retains a poster rather than decoding the video as an image',
    () {
      final detail = onlineDetail(
        const GalleryDetail(
          item: GalleryItem(
            id: 1,
            sourceId: GallerySourceId.danbooru,
            fileExt: 'webm',
          ),
          media: [
            GalleryMedia(
              id: 'p0',
              previewUrl: 'https://example.test/poster.png',
              displayUrl: 'https://example.test/video.webm',
            ),
          ],
        ),
        const favorites.OnlineFavoritesState(),
      );
      expect(
        (detail.media.single.image as CachedNetworkImageProvider).url,
        'https://example.test/poster.png',
      );
      expect(detail.fileType, 'WEBM');
    },
  );
  test(
    'local favorites load failures are not displayed as an empty collection',
    () async {
      final repo = _BrokenFavoritesRepository();
      when(
        repo.initialize,
      ).thenAnswer((_) async => throw StateError('offline'));
      final notifier = _LocalFavorites(repo);
      addTearDown(notifier.dispose);
      await notifier.bindSource(GallerySourceId.aiTag);
      final data = onlineViewData(
        state: const OnlineGalleryState(viewMode: GalleryViewMode.favorites),
        saved: notifier.value,
        preferences: const OnlineGalleryPreferences(),
        blacklist: const OnlineGalleryBlacklistState(),
        danbooru: const DanbooruAuthState(),
        gelbooru: const GelbooruAuthState(),
        l10n: AppLocalizationsEn(),
      );
      expect(data.list.error, isNotNull);
    },
  );
}

ProviderContainer _container(_Gallery notifier) {
  final container = ProviderContainer(
    overrides: [onlineGalleryNotifierProvider.overrideWith(() => notifier)],
  );
  addTearDown(container.dispose);
  return container;
}

class _BrokenFavoritesRepository extends Mock
    implements repository.OnlineFavoritesRepository {}

class _LocalFavorites extends favorites.OnlineFavoritesNotifier {
  _LocalFavorites(super.repository);
  favorites.OnlineFavoritesState get value => state;
}

class _Preferences extends OnlineGalleryPreferencesNotifier {
  _Preferences(super.store);
  OnlineGalleryPreferences get value => state;
}

class _Gallery extends OnlineGalleryNotifier {
  _Gallery(this.initial);
  final OnlineGalleryState initial;
  int loads = 0;
  @override
  OnlineGalleryState build() => initial;
  @override
  Future<void> loadPosts({bool refresh = false}) async {
    loads++;
  }
}

class _SlowPreferences extends OnlineGalleryPreferencesStore {
  final result = Completer<OnlineGalleryPreferences>();
  @override
  Future<OnlineGalleryPreferences> load() => result.future;
}
