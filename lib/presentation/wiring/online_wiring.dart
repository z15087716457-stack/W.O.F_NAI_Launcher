import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/tag_expansion/tag_expansion_providers.dart';
import '../../core/wiki/auto_tag_translation_controller.dart';
import '../../core/utils/file_picker_utils.dart';
import '../../core/utils/localization_extension.dart';
import '../../data/datasources/remote/danbooru_api_service.dart';
import '../../data/models/online_gallery/gallery_item.dart';
import '../../data/models/online_gallery/gallery_source.dart';
import '../../data/services/danbooru_auth_service.dart';
import '../../data/services/gelbooru_auth_service.dart';
import '../../data/services/gallery/online_gallery_download_service.dart';
import '../providers/canvas_settings_provider.dart';
import '../providers/character_prompt_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/online_favorites_provider.dart';
import '../providers/online_gallery_blacklist_provider.dart';
import '../providers/online_gallery_preferences_provider.dart';
import '../providers/online_gallery_provider.dart';
import '../router/app_router.dart';
import '../ui/online/online_contract.dart';
import '../ui/online/online_page.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/visible_tag_readings.dart';
import '../widgets/danbooru_login_dialog.dart';
import '../widgets/gelbooru_credentials_dialog.dart';
import 'online_generation_target.dart';
import 'online_mapping.dart';

final onlineGalleryPlatformProvider = Provider<OnlineGalleryPlatform>(
  (ref) => const OnlineGalleryPlatform(),
);
final onlineGalleryDownloadServiceProvider =
    Provider<OnlineGalleryDownloadService>(
      (ref) => const OnlineGalleryDownloadService(),
    );

class OnlineGalleryPlatform {
  const OnlineGalleryPlatform();

  void generate(BuildContext context) => context.go(AppRoutes.generation);
  Future<void> copy(String value) =>
      Clipboard.setData(ClipboardData(text: value));
  Future<void> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !['http', 'https'].contains(uri.scheme)) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError(currentL10n.common_error);
    }
  }

  Future<void> login(BuildContext context, OnlineSource source) async {
    if (source != OnlineSource.danbooru && source != OnlineSource.gelbooru) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => source == OnlineSource.danbooru
          ? const DanbooruLoginDialog()
          : const GelbooruCredentialsDialog(),
    );
  }

  Future<void> download(
    BuildContext context,
    OnlineGalleryDownloadService service,
    List<GalleryItem> items,
    Future<GalleryDetail> Function(GalleryItem) resolve, {
    required bool all,
    required int mediaIndex,
  }) async {
    final l10n = context.l10n;
    final directory = await FilePickerUtils.pickDirectoryModal(
      dialogTitle: l10n.onlineGallery_chooseDownloadDirectory,
    );
    if (directory == null || !context.mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    final progress = ValueNotifier<(int, int)>((0, 0));
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: ValueListenableBuilder<(int, int)>(
          valueListenable: progress,
          builder: (_, value, _) => SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: value.$2 == 0 ? null : value.$1 / value.$2,
                ),
                const SizedBox(height: 12),
                Text('${value.$1} / ${value.$2}'),
              ],
            ),
          ),
        ),
      ),
    );
    unawaited(navigator.push(route));
    try {
      final (success, failed) = await service.download(
        items: items,
        directory: directory,
        resolve: resolve,
        all: all,
        mediaIndex: mediaIndex,
        progress: (done, total) => progress.value = (done, total),
      );
      if (context.mounted) {
        if (failed == 0) {
          AppToast.success(
            context,
            l10n.onlineGallery_downloadSelectedCompleted(success, failed),
          );
        } else {
          AppToast.warning(
            context,
            l10n.onlineGallery_downloadSelectedCompleted(success, failed),
          );
        }
      }
    } finally {
      if (route.isActive && navigator.mounted) navigator.removeRoute(route);
      await route.completed;
      progress.dispose();
    }
  }
}

class OnlineWiring extends ConsumerStatefulWidget {
  const OnlineWiring({super.key});
  @override
  ConsumerState<OnlineWiring> createState() => _OnlineWiringState();
}

class _OnlineWiringState extends ConsumerState<OnlineWiring>
    with VisibleTagReadings<OnlineWiring> {
  String? _selectedKey;
  String? _selectionCacheKey;
  GalleryDetail? _detail;
  OnlineGalleryErrorCode? _detailError;
  int _selectionGeneration = 0;
  int _sendGeneration = 0;
  bool _sending = false;
  bool _downloading = false;
  String? _collectionId;
  int? _authorId;
  String _favoritesFilter = '';
  final Map<String, double> _localOffsets = {};

  OnlineGalleryNotifier get _gallery =>
      ref.read(onlineGalleryNotifierProvider.notifier);
  OnlineFavoritesNotifier get _favorites =>
      ref.read(onlineFavoritesNotifierProvider.notifier);
  OnlineGalleryPreferencesNotifier get _preferences =>
      ref.read(onlineGalleryPreferencesProvider.notifier);
  OnlineGalleryPlatform get _platform =>
      ref.read(onlineGalleryPlatformProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _run(() async {
        await _favorites.bindSource(GallerySourceId.aiTag);
        if (!mounted) return;
        final blacklist = ref.read(
          onlineGalleryBlacklistNotifierProvider.notifier,
        );
        unawaited(blacklist.syncOnStartup());
        final state = ref.read(onlineGalleryNotifierProvider);
        if (state.posts.isEmpty) await _gallery.loadPosts();
      }),
    );
  }

  void _run(Future<dynamic> Function() operation) {
    if (!mounted) return;
    unawaited(() async {
      try {
        await operation();
      } catch (error) {
        if (mounted) {
          AppToast.error(
            context,
            error is StateError
                ? error.message.toString()
                : onlineError(context.l10n, _gallery.errorCodeFor(error)),
          );
        }
      }
    }());
  }

  bool _local(OnlineGalleryState state) =>
      state.viewMode == GalleryViewMode.favorites &&
      state.currentSourceId == GallerySourceId.aiTag;
  String _localKey(OnlineGalleryState state) =>
      '${state.currentCacheKey}:$_collectionId:$_authorId:$_favoritesFilter';

  List<GalleryItem> _items() {
    final state = ref.read(onlineGalleryNotifierProvider);
    return _local(state)
        ? onlineLocalFavorites(
            ref.read(onlineFavoritesNotifierProvider),
            collectionId: _collectionId,
            authorId: _authorId,
            filter: _favoritesFilter,
          )
        : state.posts;
  }

  GalleryItem? _item(String key) {
    final item = _items().where((item) => item.stableKey == key).firstOrNull;
    return item == null ? null : _gallery.cachedDetailFor(item)?.item ?? item;
  }

  void _clearSelection() {
    _selectionGeneration++;
    _sendGeneration++;
    setState(() {
      _selectedKey = null;
      _detail = null;
      _detailError = null;
    });
  }

  Future<void> _select(String key) async {
    final item = _item(key);
    if (item == null) return;
    final generation = ++_selectionGeneration;
    final gallery = _gallery;
    setState(() {
      _selectedKey = key;
      final state = ref.read(onlineGalleryNotifierProvider);
      _selectionCacheKey = _local(state)
          ? _localKey(state)
          : state.currentCacheKey;
      _detail = gallery.cachedDetailFor(item);
      _detailError = null;
    });
    try {
      final detail = await gallery.loadDetail(item);
      if (mounted && generation == _selectionGeneration) {
        setState(() => _detail = detail);
      }
    } catch (error) {
      if (mounted && generation == _selectionGeneration) {
        setState(() => _detailError = gallery.errorCodeFor(error));
      }
    }
  }

  Future<void> _search(OnlineQuery query) async {
    final state = ref.read(onlineGalleryNotifierProvider);
    _clearSelection();
    if (_local(state)) {
      setState(() => _favoritesFilter = query.favoritesFilter);
      return;
    }
    final source = onlineSource(state.currentSourceId);
    final work = state.currentSourceId == GallerySourceId.aiTag
        ? query.work
        : query.tags.join(' ');
    for (final recent in [
      OnlineRecent(kind: OnlineRecentKind.work, text: work),
      OnlineRecent(kind: OnlineRecentKind.prompt, text: query.prompt),
    ]) {
      _run(() => _preferences.addRecent(source, recent));
    }
    await _gallery.submitQuery(
      query: work,
      prompt: query.prompt,
      fuzzy: query.fuzzy,
    );
  }

  Future<List<OnlineSuggestion>> _suggest(
    String fragment, {
    required bool prompt,
  }) async {
    if (!mounted || fragment.trim().isEmpty) return const [];
    final service = ref.read(localTagExpansionServiceProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final items = await service.search(fragment, locale: locale, limit: 8);
    if (!mounted) return const [];
    return [
      for (final item in items.take(8))
        OnlineSuggestion(
          item.canonicalTag,
          translation:
              ref.read(autoTagTranslationProvider).nameFor(item.canonicalTag) ??
              item.translation,
          count: item.postCount,
        ),
    ];
  }

  Future<void> _authorWorks(int id, {String? name}) async {
    if (id <= 0) return;
    final state = ref.read(onlineGalleryNotifierProvider);
    _clearSelection();
    _run(
      () => _preferences.addRecent(
        OnlineSource.aiTag,
        OnlineRecent(
          kind: OnlineRecentKind.author,
          text: name == null || name.isEmpty ? '$id' : '$id · $name',
        ),
      ),
    );
    await _gallery.searchAiTagAuthor(
      id,
      drafts: OnlineGalleryQueryDrafts(
        searchQuery: state.searchQuery,
        searchPrompt: state.promptQuery,
        popularQuery: state.popularQuery,
        popularPrompt: state.popularPromptQuery,
      ),
    );
  }

  Future<void> _tagTap(String tag) async {
    final state = ref.read(onlineGalleryNotifierProvider);
    final ranking = state.viewMode == GalleryViewMode.popular;
    final work = ranking ? state.popularQuery : state.searchQuery;
    final prompt = ranking ? state.popularPromptQuery : state.promptQuery;
    final tags = work
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .toList();
    final next = tags.contains(tag)
        ? work
        : work.isEmpty
        ? tag
        : '$work $tag';
    _clearSelection();
    _run(
      () => _preferences.addRecent(
        onlineSource(state.currentSourceId),
        OnlineRecent(kind: OnlineRecentKind.work, text: next),
      ),
    );
    await _gallery.submitQuery(
      query: next,
      prompt: prompt,
      fuzzy: state.fuzzySearchEnabled,
    );
  }

  Future<void> _recent(OnlineRecent recent) async {
    if (recent.kind == OnlineRecentKind.author) {
      final id = int.tryParse(recent.text.split(' · ').first);
      if (id != null) {
        await _authorWorks(
          id,
          name: recent.text.split(' · ').skip(1).join(' · '),
        );
      }
      return;
    }
    final state = ref.read(onlineGalleryNotifierProvider);
    final ranking = state.viewMode == GalleryViewMode.popular;
    final work = recent.kind == OnlineRecentKind.work
        ? recent.text
        : ranking
        ? state.popularQuery
        : state.searchQuery;
    await _search(
      OnlineQuery(
        work: work,
        tags: work
            .split(RegExp(r'\s+'))
            .where((tag) => tag.isNotEmpty)
            .toList(),
        prompt: recent.kind == OnlineRecentKind.prompt
            ? recent.text
            : ranking
            ? state.popularPromptQuery
            : state.promptQuery,
        fuzzy: state.fuzzySearchEnabled,
      ),
    );
  }

  Future<void> _toggleFavorite(String key) async {
    final item = _item(key);
    if (item == null) return;
    if (item.sourceId == GallerySourceId.aiTag) {
      await _favorites.toggleFavorite(item);
    } else if (item.sourceId == GallerySourceId.danbooru) {
      if (!ref.read(danbooruAuthProvider).isLoggedIn) {
        await _platform.login(context, OnlineSource.danbooru);
        return;
      }
      await _gallery.toggleFavorite(item);
    }
  }

  Future<void> _favoriteMany(
    List<String> keys,
    String? collectionId, {
    String? newCollection,
  }) async {
    final items = keys.map(_item).whereType<GalleryItem>().toList();
    if (items.isEmpty) return;
    final favorites = _favorites;
    final gallery = _gallery;
    if (items.first.sourceId == GallerySourceId.aiTag) {
      if (newCollection != null) {
        collectionId = await favorites.createCollection(newCollection);
      }
      for (final item in items) {
        if (!mounted) return;
        if (!ref
            .read(onlineFavoritesNotifierProvider)
            .isFavorite(item.sourceId, item.id)) {
          await favorites.toggleFavorite(item);
        }
        if (!mounted) return;
        await favorites.moveToCollection(
          item.id,
          collectionId?.isEmpty == true ? null : collectionId,
        );
      }
    } else if (items.first.sourceId == GallerySourceId.danbooru) {
      if (!ref.read(danbooruAuthProvider).isLoggedIn) {
        await _platform.login(context, OnlineSource.danbooru);
        return;
      }
      for (final item in items) {
        if (!mounted) return;
        if (!gallery.isFavorited(item)) await gallery.addFavorite(item);
      }
    }
  }

  Future<void> _copy(List<String> keys) async {
    final items = keys.map(_item).whereType<GalleryItem>().toList();
    final gallery = _gallery;
    final platform = _platform;
    final text = <String>[];
    for (final item in items) {
      if (!mounted) return;
      final detail = item.sourceId == GallerySourceId.aiTag
          ? await gallery.loadDetail(item)
          : null;
      text.add(
        detail?.media.firstOrNull?.prompt ??
            detail?.prompt ??
            item.tags.join(', '),
      );
    }
    if (!mounted || text.isEmpty) return;
    await platform.copy(text.join('\n\n'));
    if (mounted) AppToast.success(context, context.l10n.onlineGallery_copied);
  }

  Future<void> _send(
    String key,
    OnlineSendMode mode, {
    bool remember = false,
  }) async {
    final item = _item(key);
    if (item == null || _sending) return;
    final target = ref.read(onlineGenerationTargetProvider);
    final snapshot = target.capture();
    final gallery = _gallery;
    final platform = _platform;
    final preferences = _preferences;
    final generation = ++_sendGeneration;
    _sending = true;
    try {
      final detail = await gallery.loadDetail(item);
      if (!mounted || generation != _sendGeneration) return;
      await target.apply(
        detail,
        mode,
        snapshot: snapshot,
        alive: () => mounted && generation == _sendGeneration,
      );
      if (!mounted) return;
      if (remember) await preferences.rememberSend(mode);
      if (mounted) platform.generate(context);
    } finally {
      _sending = false;
    }
  }

  Future<void> _download(
    List<String> keys, {
    bool all = false,
    int mediaIndex = 0,
  }) async {
    if (_downloading) return;
    final items = keys.map(_item).whereType<GalleryItem>().toList();
    if (items.isEmpty) return;
    _downloading = true;
    try {
      final gallery = _gallery;
      await _platform.download(
        context,
        ref.read(onlineGalleryDownloadServiceProvider),
        items,
        gallery.loadDetail,
        all: all,
        mediaIndex: mediaIndex,
      );
    } finally {
      _downloading = false;
    }
  }

  void _accountChanged(GallerySourceId source) {
    _gallery.invalidateRemoteFavorites(source);
    final state = ref.read(onlineGalleryNotifierProvider);
    if (state.currentSourceId == source) {
      _clearSelection();
      if (state.viewMode == GalleryViewMode.favorites) {
        _run(() => _gallery.loadPosts(refresh: true));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(danbooruAuthProvider, (previous, next) {
      if (previous?.credentials != next.credentials ||
          previous?.user?.id != next.user?.id ||
          previous?.isLoggedIn != next.isLoggedIn) {
        _accountChanged(GallerySourceId.danbooru);
      }
    });
    ref.listen(gelbooruAuthProvider, (previous, next) {
      if (previous?.credentials?.userId != next.credentials?.userId ||
          previous?.credentials?.apiKey != next.credentials?.apiKey ||
          previous?.isAuthenticated != next.isAuthenticated) {
        _accountChanged(GallerySourceId.gelbooru);
      }
    });
    final state = ref.watch(onlineGalleryNotifierProvider);
    final saved = ref.watch(onlineFavoritesNotifierProvider);
    final preferences = ref.watch(onlineGalleryPreferencesProvider);
    final blacklist = ref.watch(onlineGalleryBlacklistNotifierProvider);
    final params = ref.watch(generationParamsNotifierProvider);
    final characters = ref.watch(characterPromptNotifierProvider);
    final cacheKey = _local(state) ? _localKey(state) : state.currentCacheKey;
    final selected = _selectionCacheKey == cacheKey
        ? _items().where((item) => item.stableKey == _selectedKey).firstOrNull
        : null;
    observeTagReadings(
      selected == null || selected.sourceId == GallerySourceId.aiTag
          ? const []
          : _detail?.item.tags ?? const [],
    );
    final data = onlineViewData(
      state: state,
      saved: saved,
      preferences: preferences,
      blacklist: blacklist,
      danbooru: ref.watch(danbooruAuthProvider),
      gelbooru: ref.watch(gelbooruAuthProvider),
      l10n: context.l10n,
      collectionId: _collectionId,
      authorId: _authorId,
      favoritesFilter: _favoritesFilter,
      selectedKey: selected?.stableKey,
      detail: selected == null
          ? null
          : _detailError != null
          ? OnlineDetail(
              key: selected.stableKey,
              error: onlineError(context.l10n, _detailError),
            )
          : _detail == null
          ? OnlineDetail(key: selected.stableKey, loading: true)
          : onlineDetail(_detail!, saved, translation: tagReading),
      cachedDetail: _gallery.cachedDetailFor,
      promptLength: params.prompt.length,
      characterCount: characters.characters.length,
      reducedMotion: ref.watch(canvasReducedMotionNotifierProvider),
      localOffset: _localOffsets[cacheKey] ?? 0,
    );
    return Material(
      type: MaterialType.transparency,
      child: OnlineGalleryPage(
        data: data,
        actions: OnlineActions(
          onSourceChanged: (source) => _run(() {
            _clearSelection();
            return _gallery.setActiveSource(gallerySource(source));
          }),
          onModeChanged: (mode) => _run(() {
            _clearSelection();
            return _gallery.setViewMode(galleryMode(mode));
          }),
          onSearch: (query) => _run(() => _search(query)),
          onSuggest: _suggest,
          onRecent: (recent) => _run(() => _recent(recent)),
          onClearRecent: () => _run(
            () => _preferences.clearRecent(
              onlineSource(
                ref.read(onlineGalleryNotifierProvider).currentSourceId,
              ),
            ),
          ),
          onNaiOnlyChanged: (value) =>
              _run(() => _gallery.setAiTagNaiOnly(value)),
          onModelChanged: (value) =>
              _run(() => _gallery.setAiTagModelVersion(galleryModel(value))),
          onTimeRangeChanged: (value) =>
              _run(() => _gallery.setAiTagTimeRange(value)),
          onRatingsChanged: (value) =>
              _run(() => _gallery.setRatings(value.map(galleryRating).toSet())),
          onDateRangeChanged: (value) =>
              _run(() => _gallery.setDateRange(value?.start, value?.end)),
          onRankPeriodChanged: (value) =>
              _run(() => _gallery.setAiTagPopularPeriod(value)),
          onRankScaleChanged: (value) => _run(
            () => _gallery.setPopularScale(PopularScale.values[value.index]),
          ),
          onRankDateChanged: (value) =>
              _run(() => _gallery.setPopularDate(value)),
          onCollectionSelected: (value) => _run(() async {
            _clearSelection();
            setState(() {
              _collectionId = value;
              _authorId = null;
            });
            await _gallery.setViewMode(GalleryViewMode.favorites);
          }),
          onAuthorSelected: (value) => _run(() async {
            _clearSelection();
            setState(() => _authorId = value);
            await _gallery.setViewMode(GalleryViewMode.favorites);
          }),
          onCreateCollection: (name) async =>
              mounted ? _favorites.createCollection(name) : '',
          onRenameCollection: (id, name) =>
              _run(() => _favorites.renameCollection(id, name)),
          onDeleteCollection: (id) => _run(() async {
            final favorites = _favorites;
            await favorites.deleteCollection(id);
            if (mounted && _collectionId == id) {
              setState(() => _collectionId = null);
            }
          }),
          onMoveToCollection: (keys, id) => _run(() async {
            final items = keys
                .map(_item)
                .whereType<GalleryItem>()
                .where((item) => item.sourceId == GallerySourceId.aiTag)
                .toList();
            final favorites = _favorites;
            for (final item in items) {
              await favorites.moveToCollection(
                item.id,
                id?.isEmpty == true ? null : id,
              );
            }
          }),
          onAuthorWorks: (id) => _run(
            () => _authorWorks(
              id,
              name: saved.authors
                  .where((author) => author.authorId == id)
                  .firstOrNull
                  ?.authorName,
            ),
          ),
          onUnfavoriteAuthor: (id) => _run(() => _favorites.removeAuthor(id)),
          onReturn: () => _run(() async {
            _clearSelection();
            _gallery.returnFromAiTagAuthorSearch();
          }),
          onBlacklistAdd: (tag) => _run(() async {
            final gallery = _gallery;
            await ref
                .read(onlineGalleryBlacklistNotifierProvider.notifier)
                .addLocalTag(tag);
            if (mounted) await gallery.refresh();
          }),
          onBlacklistRemove: (tag) => _run(() async {
            final gallery = _gallery;
            await ref
                .read(onlineGalleryBlacklistNotifierProvider.notifier)
                .removeLocalTag(tag);
            if (mounted) await gallery.refresh();
          }),
          onDanbooruSyncChanged: (value) => _run(() async {
            final blacklist = ref.read(
              onlineGalleryBlacklistNotifierProvider.notifier,
            );
            await blacklist.setAutoSyncOnStartup(value);
            if (value) await blacklist.syncNow();
            if (mounted) await _gallery.refresh();
          }),
          onCardSizeChanged: (value) =>
              _run(() => _preferences.setCardSize(value)),
          onSidebarChanged: (value) =>
              _run(() => _preferences.setSidebar(value)),
          onInspectorChanged: (value) =>
              _run(() => _preferences.setInspector(value)),
          onSelect: (key) => _run(() => _select(key)),
          onLoadMore: () => _run(() => _gallery.loadMore()),
          onRetryPage: () => _run(() => _gallery.retryAppend()),
          onRetry: () => _run(
            () => _local(ref.read(onlineGalleryNotifierProvider))
                ? _favorites.refresh()
                : _gallery.loadPosts(refresh: true),
          ),
          onJumpToPage: (page) => _run(() => _gallery.goToPage(page)),
          onRefresh: () => _run(
            () => _local(ref.read(onlineGalleryNotifierProvider))
                ? _favorites.refresh()
                : _gallery.refresh(),
          ),
          onScrollOffset: (value) => _run(() async {
            final state = ref.read(onlineGalleryNotifierProvider);
            if ((_local(state) ? _localKey(state) : state.currentCacheKey) !=
                cacheKey) {
              return;
            }
            if (_local(state)) {
              _localOffsets[_localKey(state)] = value;
            } else {
              _gallery.saveScrollOffset(value);
            }
          }),
          onToggleFavorite: (key) => _run(() => _toggleFavorite(key)),
          onFavoriteMany: (keys, id, {newCollection}) =>
              _run(() => _favoriteMany(keys, id, newCollection: newCollection)),
          onCopyPrompt: (keys) => _run(() => _copy(keys)),
          onDownload: (keys, {all = false, mediaIndex = 0}) =>
              _run(() => _download(keys, all: all, mediaIndex: mediaIndex)),
          onSend: (key, mode, {remember = false}) =>
              _run(() => _send(key, mode, remember: remember)),
          onOpenInBrowser: (key) => _run(() async {
            final item = _item(key);
            if (item != null) await _platform.open(item.postUrl);
          }),
          onTagTap: (tag) => _run(() => _tagTap(tag)),
          onToggleAuthorFavorite: (key) => _run(() async {
            final item = _item(key);
            if (item != null &&
                item.sourceId == GallerySourceId.aiTag &&
                item.uploaderId > 0) {
              await _favorites.toggleAuthor(item.uploaderId, item.author ?? '');
            }
          }),
          onOnlyAuthor: (key) => _run(() async {
            final item = _item(key);
            if (item != null && item.sourceId == GallerySourceId.aiTag) {
              await _authorWorks(item.uploaderId, name: item.author);
            }
          }),
          onLogin: (source) => _run(() => _platform.login(context, source)),
          onApiKeyHelp: (source) => _run(
            () => _platform.open(
              source == OnlineSource.gelbooru
                  ? 'https://gelbooru.com/index.php?page=account&s=options'
                  : 'https://danbooru.donmai.us/profile',
            ),
          ),
        ),
      ),
    );
  }
}
