import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/wiki/auto_tag_translation_controller.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/visible_tag_translation_cache.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/models/danbooru/danbooru_user.dart';
import 'package:nai_launcher/data/models/online_gallery/gelbooru_credentials.dart';
import 'package:nai_launcher/presentation/wiring/online_generation_target.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_item.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_source.dart';
import 'package:nai_launcher/data/repositories/online_favorites_repository.dart'
    as repository;
import 'package:nai_launcher/data/services/danbooru_auth_service.dart';
import 'package:nai_launcher/data/services/gelbooru_auth_service.dart';
import 'package:nai_launcher/data/services/gallery/online_gallery_download_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_service.dart';
import 'package:nai_launcher/presentation/providers/online_favorites_provider.dart'
    as fav;
import 'package:nai_launcher/presentation/providers/online_gallery_blacklist_provider.dart';
import 'package:nai_launcher/presentation/providers/online_gallery_provider.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/online/online_contract.dart';
import 'package:nai_launcher/presentation/ui/online/online_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'package:nai_launcher/presentation/wiring/online_wiring.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/studio_capture_fonts.dart';

void main() {
  late Directory temporary;
  setUpAll(() async {
    await loadStudioCaptureFonts();
    temporary = await Directory.systemTemp.createTemp('online_wiring_test_');
    Hive.init(temporary.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() async {
    await Hive.box(StorageKeys.settingsBox).clear();
    await Hive.box(StorageKeys.historyBox).clear();
  });
  tearDownAll(() async {
    await Hive.close();
    await temporary.delete(recursive: true);
  });

  testWidgets(
    'source and mode actions use backend state without editing the shell',
    (tester) async {
      final harness = await _pump(tester);
      _actions(tester).onModeChanged(OnlineMode.ranking);
      await tester.pumpAndSettle();
      expect(_data(tester).mode, OnlineMode.ranking);
      expect(_data(tester).source, OnlineSource.aiTag);
      _actions(tester).onSourceChanged(OnlineSource.danbooru);
      await tester.pumpAndSettle();
      expect(_data(tester).source, OnlineSource.danbooru);
      expect(
        harness.container.read(onlineGalleryNotifierProvider).popularSourceId,
        GallerySourceId.danbooru,
      );
      expect(
        harness.container.read(onlineGalleryNotifierProvider).sourceId,
        GallerySourceId.aiTag,
      );
    },
  );

  testWidgets(
    'selection respects loading, stale completions and cache identity',
    (tester) async {
      final harness = await _pump(tester);
      final first = Completer<GalleryDetail>();
      final second = Completer<GalleryDetail>();
      harness.gallery.pending[1] = first;
      harness.gallery.pending[2] = second;
      _actions(tester).onSelect('ai_tag:1');
      await tester.pump();
      expect(_data(tester).detail!.loading, isTrue);
      _actions(tester).onSelect('ai_tag:2');
      second.complete(harness.gallery.detail(_items[1]));
      await tester.pumpAndSettle();
      expect(_data(tester).detail!.prompt, 'prompt2');
      first.complete(harness.gallery.detail(_items[0]));
      await tester.pumpAndSettle();
      expect(_data(tester).detail!.key, 'ai_tag:2');
      _actions(tester).onSearch(const OnlineQuery(work: 'new'));
      await tester.pumpAndSettle();
      expect(_data(tester).selectedKey, isNull);
      expect(_data(tester).detail, isNull);
    },
  );

  testWidgets(
    'copy and browser actions use stable keys and preserve selection order',
    (tester) async {
      final harness = await _pump(tester);
      _actions(tester).onCopyPrompt(['ai_tag:2', 'ai_tag:1']);
      _actions(tester).onOpenInBrowser('ai_tag:1');
      await tester.pumpAndSettle();
      expect(harness.platform.copied.single, 'prompt2\n\nprompt1');
      expect(harness.platform.opened.single, _items.first.postUrl);
    },
  );

  testWidgets(
    'downloads forward all/current media options and the exact selected items',
    (tester) async {
      final harness = await _pump(tester);
      _actions(tester).onDownload(['ai_tag:2'], all: false, mediaIndex: 1);
      await tester.pumpAndSettle();
      expect(harness.platform.downloads.single, (
        ['ai_tag:2'].join(),
        false,
        1,
      ));
    },
  );

  testWidgets(
    'bulk favorites add missing items without removing existing favorites',
    (tester) async {
      final harness = await _pump(tester);
      _actions(tester).onFavoriteMany(
        ['ai_tag:1', 'ai_tag:2'],
        null,
        newCollection: 'new set',
      );
      await tester.pumpAndSettle();
      expect(harness.favorites.toggled, [2]);
      expect(harness.favorites.moves, [(1, 'new'), (2, 'new')]);
      expect(harness.favorites.created, ['new set']);
    },
  );

  testWidgets(
    'author search records a reusable recent and restores its prior query',
    (tester) async {
      final harness = await _pump(tester);
      _actions(tester).onOnlyAuthor('ai_tag:1');
      await tester.pumpAndSettle();
      expect(_data(tester).canReturn, isTrue);
      expect(_data(tester).query.work, '8');
      final recent = _data(tester).recent.single;
      expect(recent.kind, OnlineRecentKind.author);
      _actions(tester).onReturn();
      await tester.pumpAndSettle();
      expect(_data(tester).query.work, 'initial');
      expect(_data(tester).canReturn, isFalse);
      _actions(tester).onRecent(recent);
      await tester.pumpAndSettle();
      expect(
        harness.container.read(onlineGalleryNotifierProvider).searchQuery,
        '8',
      );
    },
  );

  testWidgets(
    'paging and blacklist controls dispatch to the existing notifiers',
    (tester) async {
      final harness = await _pump(tester);
      final actions = _actions(tester);
      actions.onLoadMore();
      actions.onRetryPage();
      actions.onJumpToPage(4);
      actions.onScrollOffset(123);
      actions.onBlacklistAdd('foo');
      actions.onBlacklistRemove('bar');
      actions.onDanbooruSyncChanged(true);
      await tester.pumpAndSettle();
      expect(
        harness.gallery.events,
        containsAll(['more', 'retryAppend', 'page:4', 'scroll:123.0']),
      );
      expect(
        harness.blacklist.events,
        containsAll(['add:foo', 'remove:bar', 'auto:true', 'sync']),
      );
    },
  );

  testWidgets('preference callbacks immediately update the contract', (
    tester,
  ) async {
    await _pump(tester);
    final actions = _actions(tester);
    actions.onCardSizeChanged(OnlineCardSize.large);
    actions.onSidebarChanged(false);
    actions.onInspectorChanged(false);
    await tester.pumpAndSettle();
    expect(_data(tester).cardSize, OnlineCardSize.large);
    expect(_data(tester).sidebarOpen, isFalse);
    expect(_data(tester).inspectorOpen, isFalse);
  });

  testWidgets(
    'account dialogs use explicit sources and stale actions are harmless after disposal',
    (tester) async {
      final harness = await _pump(tester);
      final actions = _actions(tester);
      actions.onLogin(OnlineSource.gelbooru);
      actions.onApiKeyHelp(OnlineSource.gelbooru);
      await tester.pumpAndSettle();
      expect(harness.platform.logins, [OnlineSource.gelbooru]);
      expect(harness.platform.opened.single, contains('page=account'));
      await tester.pumpWidget(const SizedBox.shrink());
      actions.onSearch(const OnlineQuery(work: 'late'));
      actions.onLogin(OnlineSource.danbooru);
      expect(await actions.onSuggest('late', prompt: false), isEmpty);
      expect(harness.platform.logins, [OnlineSource.gelbooru]);
      expect(tester.takeException(), isNull);
    },
  );

  for (final source in [GallerySourceId.danbooru, GallerySourceId.gelbooru]) {
    testWidgets(
      '$source account changes clear private favorites and reload the active list',
      (tester) async {
        final harness = await _pump(tester);
        harness.gallery.primePrivateFavorites(source);
        await tester.pumpAndSettle();
        if (source == GallerySourceId.danbooru) {
          (harness.container.read(danbooruAuthProvider.notifier) as _Danbooru)
              .changeUser(2);
        } else {
          (harness.container.read(gelbooruAuthProvider.notifier) as _Gelbooru)
              .changeUser(2);
        }
        await tester.pumpAndSettle();
        final state = harness.container.read(onlineGalleryNotifierProvider);
        expect(state.currentCache.posts, isEmpty);
        expect(state.favoritedPostKeys, isEmpty);
        expect(harness.gallery.events, ['load']);
      },
    );
  }

  for (final mode in OnlineSendMode.values) {
    testWidgets(
      '$mode dispatches the target, remembers the choice and navigates',
      (tester) async {
        final harness = await _pump(tester);
        _actions(tester).onSend('ai_tag:2', mode, remember: true);
        await tester.pumpAndSettle();
        expect(
          (harness.container.read(onlineGenerationTargetProvider) as _Target)
              .calls,
          [('ai_tag:2', mode, true)],
        );
        expect(_data(tester).send.remembered, mode);
        expect(harness.platform.generated, 1);
      },
    );
  }

  testWidgets(
    'tag taps retain ranking mode and use its query rather than the search draft',
    (tester) async {
      final harness = await _pump(tester);
      _actions(tester).onModeChanged(OnlineMode.ranking);
      await tester.pumpAndSettle();
      _actions(tester).onSearch(const OnlineQuery(work: 'rank'));
      await tester.pumpAndSettle();
      _actions(tester).onTagTap('blue_eyes');
      await tester.pumpAndSettle();
      final state = harness.container.read(onlineGalleryNotifierProvider);
      expect(state.viewMode, GalleryViewMode.popular);
      expect(state.popularQuery, 'rank blue_eyes');
      expect(state.searchQuery, 'initial');
    },
  );

  testWidgets(
    'a prior source scroll callback cannot overwrite the new source offset',
    (tester) async {
      final harness = await _pump(tester);
      final old = _actions(tester);
      old.onSourceChanged(OnlineSource.danbooru);
      await tester.pumpAndSettle();
      _actions(tester).onScrollOffset(44);
      old.onScrollOffset(999);
      await tester.pumpAndSettle();
      expect(
        harness.container
            .read(onlineGalleryNotifierProvider)
            .currentCache
            .scrollOffset,
        44,
      );
    },
  );
}

OnlineActions _actions(WidgetTester tester) =>
    tester.widget<OnlineGalleryPage>(find.byType(OnlineGalleryPage)).actions;
OnlineViewData _data(WidgetTester tester) =>
    tester.widget<OnlineGalleryPage>(find.byType(OnlineGalleryPage)).data;

Future<_Harness> _pump(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1600, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final gallery = _Gallery();
  final favorites = _Favorites();
  final platform = _Platform();
  late _Blacklist blacklist;
  final container = ProviderContainer(
    overrides: [
      onlineGalleryNotifierProvider.overrideWith(() => gallery),
      fav.onlineFavoritesNotifierProvider.overrideWith((ref) => favorites),
      onlineGalleryPlatformProvider.overrideWithValue(platform),
      onlineGenerationTargetProvider.overrideWith(_Target.new),
      onlineGalleryBlacklistNotifierProvider.overrideWith(
        (ref) =>
            blacklist = _Blacklist(ref, ref.read(localStorageServiceProvider)),
      ),
      danbooruAuthProvider.overrideWith(_Danbooru.new),
      gelbooruAuthProvider.overrideWith(_Gelbooru.new),
      autoTagTranslationProvider.overrideWith((ref) => _Readings()),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: GeistTheme.light,
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const Scaffold(body: WindowChromeScope(child: OnlineWiring())),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(container, gallery, favorites, blacklist, platform);
}

class _Harness {
  const _Harness(
    this.container,
    this.gallery,
    this.favorites,
    this.blacklist,
    this.platform,
  );
  final ProviderContainer container;
  final _Gallery gallery;
  final _Favorites favorites;
  final _Blacklist blacklist;
  final _Platform platform;
}

const _items = [
  GalleryItem(
    id: 1,
    sourceId: GallerySourceId.aiTag,
    title: 'first',
    author: 'artist',
    uploaderId: 8,
  ),
  GalleryItem(
    id: 2,
    sourceId: GallerySourceId.aiTag,
    title: 'second',
    author: 'artist',
    uploaderId: 8,
  ),
];

class _Target extends OnlineGenerationTarget {
  _Target(Ref ref) : super(ref, const OnlineDraftBackup());
  final calls = <(String, OnlineSendMode, bool)>[];
  @override
  OnlineGenerationSnapshot capture() =>
      const OnlineGenerationSnapshot('v', 'p', 'j');
  @override
  Future<void> apply(
    GalleryDetail detail,
    OnlineSendMode mode, {
    required OnlineGenerationSnapshot snapshot,
    required bool Function() alive,
  }) async {
    calls.add((detail.item.stableKey, mode, alive()));
  }
}

class _Gallery extends OnlineGalleryNotifier {
  void primePrivateFavorites(GallerySourceId source) {
    final cache = ModeCache(posts: [GalleryItem(id: 9, sourceId: source)]);
    state = state
        .copyWith(
          viewMode: GalleryViewMode.favorites,
          favoritesSourceId: source,
          favoritedPostKeys: {'${source.key}:9'},
        )
        .updateCurrentCache(cache);
  }

  final events = <String>[];
  final pending = <int, Completer<GalleryDetail>>{};
  final resolved = <int, GalleryDetail>{};
  @override
  OnlineGalleryState build() => const OnlineGalleryState(
    searchQuery: 'initial',
  ).updateCurrentCache(const ModeCache(posts: _items));
  @override
  Future<void> loadPosts({bool refresh = false}) async {
    events.add('load');
  }

  @override
  Future<void> loadMore() async {
    events.add('more');
  }

  @override
  Future<void> retryAppend() async {
    events.add('retryAppend');
  }

  @override
  Future<void> goToPage(int page) async {
    events.add('page:$page');
  }

  @override
  void saveScrollOffset(double offset) {
    events.add('scroll:$offset');
    super.saveScrollOffset(offset);
  }

  GalleryDetail detail(GalleryItem item) => GalleryDetail(
    item: item,
    media: [
      GalleryMedia(
        id: 'p0',
        prompt: 'prompt${item.id}',
        negativePrompt: '',
        naiMetadata: NaiImageMetadata(
          prompt: 'prompt${item.id}',
          model: 'nai-diffusion-5-full',
        ),
      ),
    ],
  );
  @override
  Future<GalleryDetail> loadDetail(
    GalleryItem item, {
    bool forceRefresh = false,
  }) async {
    final value =
        await (pending[item.id]?.future ?? Future.value(detail(item)));
    resolved[item.id] = value;
    return value;
  }

  @override
  GalleryDetail? cachedDetailFor(GalleryItem item) => resolved[item.id];
}

class _Favorites extends fav.OnlineFavoritesNotifier {
  _Favorites() : super(_Repository()) {
    state = const fav.OnlineFavoritesState(
      sourceKey: 'ai_tag',
      favoritedWorkIds: {1},
    );
  }
  final toggled = <int>[];
  final moves = <(int, String?)>[];
  final created = <String>[];
  @override
  Future<void> bindSource(GallerySourceId source) async {}
  @override
  Future<bool> toggleFavorite(GalleryItem item) async {
    toggled.add(item.id);
    state = state.copyWith(
      favoritedWorkIds: {...state.favoritedWorkIds, item.id},
    );
    return true;
  }

  @override
  Future<String> createCollection(String name) async {
    created.add(name);
    return 'new';
  }

  @override
  Future<void> moveToCollection(int workId, String? collectionId) async {
    moves.add((workId, collectionId));
  }
}

class _Repository extends Mock
    implements repository.OnlineFavoritesRepository {}

class _Platform extends OnlineGalleryPlatform {
  int generated = 0;
  @override
  void generate(BuildContext context) {
    generated++;
  }

  final copied = <String>[];
  final opened = <String>[];
  final logins = <OnlineSource>[];
  final downloads = <(String, bool, int)>[];
  @override
  Future<void> copy(String value) async {
    copied.add(value);
  }

  @override
  Future<void> open(String url) async {
    opened.add(url);
  }

  @override
  Future<void> login(BuildContext context, OnlineSource source) async {
    logins.add(source);
  }

  @override
  Future<void> download(
    BuildContext context,
    OnlineGalleryDownloadService service,
    List<GalleryItem> items,
    Future<GalleryDetail> Function(GalleryItem) resolve, {
    required bool all,
    required int mediaIndex,
  }) async {
    downloads.add((
      items.map((item) => item.stableKey).join(),
      all,
      mediaIndex,
    ));
  }
}

class _Danbooru extends DanbooruAuth {
  void changeUser(int id) => state = DanbooruAuthState(
    credentials: DanbooruCredentials(username: 'user$id', apiKey: 'test'),
    user: DanbooruUser(id: id, name: 'user$id'),
    lastVerifiedAt: DateTime.now(),
  );
  @override
  DanbooruAuthState build() => const DanbooruAuthState();
}

class _Gelbooru extends GelbooruAuth {
  void changeUser(int id) => state = GelbooruAuthState(
    credentials: GelbooruCredentials(userId: id, apiKey: 'test'),
    status: GelbooruAuthStatus.authenticated,
  );
  @override
  GelbooruAuthState build() =>
      const GelbooruAuthState(status: GelbooruAuthStatus.unconfigured);
}

class _Blacklist extends OnlineGalleryBlacklistNotifier {
  _Blacklist(super.ref, super.storage);
  final events = <String>[];
  @override
  Future<void> syncOnStartup() async {}
  @override
  Future<void> addLocalTag(String input) async {
    events.add('add:$input');
  }

  @override
  Future<void> removeLocalTag(String tag) async {
    events.add('remove:$tag');
  }

  @override
  Future<void> setAutoSyncOnStartup(bool value) async {
    events.add('auto:$value');
  }

  @override
  Future<void> syncNow({bool triggeredByStartup = false}) async {
    events.add('sync');
  }
}

class _Readings extends AutoTagTranslationController {
  _Readings()
    : super(
        assistant: _Assistant(),
        wiki: _Wiki(),
        cache: VisibleTagTranslationCache(),
      );
  @override
  void observe({
    required String surface,
    required String tag,
    required bool visible,
    String? existingNameZh,
    AutoTagTranslationContext? tagContext,
  }) {}
}

class _Assistant extends Mock implements PromptAssistantService {}

class _Wiki extends Mock implements TagWikiRepository {}
