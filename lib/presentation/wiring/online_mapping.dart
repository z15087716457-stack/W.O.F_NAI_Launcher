import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/cache/danbooru_image_cache_manager.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/online_gallery/gallery_item.dart';
import '../../data/models/online_gallery/gallery_source.dart';
import '../../data/services/danbooru_auth_service.dart';
import '../../data/services/gelbooru_auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../providers/online_favorites_provider.dart' as favorites;
import '../providers/online_gallery_blacklist_provider.dart';
import '../providers/online_gallery_preferences_provider.dart';
import '../providers/online_gallery_provider.dart';
import '../ui/online/online_contract.dart';

OnlineSource onlineSource(GallerySourceId source) => switch (source) {
  GallerySourceId.aiTag => OnlineSource.aiTag,
  GallerySourceId.danbooru => OnlineSource.danbooru,
  GallerySourceId.safebooru => OnlineSource.safebooru,
  GallerySourceId.gelbooru => OnlineSource.gelbooru,
};

GallerySourceId gallerySource(OnlineSource source) => switch (source) {
  OnlineSource.aiTag => GallerySourceId.aiTag,
  OnlineSource.danbooru => GallerySourceId.danbooru,
  OnlineSource.safebooru => GallerySourceId.safebooru,
  OnlineSource.gelbooru => GallerySourceId.gelbooru,
};

OnlineMode onlineMode(GalleryViewMode mode) => switch (mode) {
  GalleryViewMode.search => OnlineMode.search,
  GalleryViewMode.popular => OnlineMode.ranking,
  GalleryViewMode.favorites => OnlineMode.favorites,
};
GalleryViewMode galleryMode(OnlineMode mode) => switch (mode) {
  OnlineMode.search => GalleryViewMode.search,
  OnlineMode.ranking => GalleryViewMode.popular,
  OnlineMode.favorites => GalleryViewMode.favorites,
};

String galleryRating(OnlineRating rating) =>
    const ['g', 's', 'q', 'e'][rating.index];
OnlineRating? onlineRating(String? rating) => switch (rating) {
  'g' => OnlineRating.general,
  's' => OnlineRating.sensitive,
  'q' => OnlineRating.questionable,
  'e' => OnlineRating.explicit,
  _ => null,
};
String? galleryModel(OnlineModel? model) => switch (model) {
  OnlineModel.v3 => '3',
  OnlineModel.v4 => '4',
  OnlineModel.v45 => '4.5',
  OnlineModel.v5 => '5',
  null => null,
};

ImageProvider? onlineImage(String url) => url.isEmpty
    ? null
    : CachedNetworkImageProvider(
        url,
        cacheManager: DanbooruImageCacheManager.instance,
        cacheKey: onlineGalleryImageCacheKeyForUrl(url),
        headers: onlineGalleryImageHeadersForUrl(url),
      );

String onlineError(
  AppLocalizations l10n,
  OnlineGalleryErrorCode? code,
) => switch (code) {
  OnlineGalleryErrorCode.gelbooruCredentialsRequired =>
    l10n.onlineGallery_gelbooruCredentialsRequired,
  OnlineGalleryErrorCode.gelbooruCredentialsInvalid =>
    l10n.onlineGallery_gelbooruCredentialsInvalid,
  OnlineGalleryErrorCode.gelbooruRateLimited =>
    l10n.onlineGallery_gelbooruRateLimited,
  OnlineGalleryErrorCode.gelbooruTimeout => l10n.onlineGallery_gelbooruTimeout,
  OnlineGalleryErrorCode.gelbooruServer =>
    l10n.onlineGallery_gelbooruServerError,
  OnlineGalleryErrorCode.gelbooruNetwork =>
    l10n.onlineGallery_gelbooruNetworkError,
  OnlineGalleryErrorCode.gelbooruMalformedResponse =>
    l10n.onlineGallery_gelbooruMalformedResponse,
  OnlineGalleryErrorCode.credentialsRequired ||
  OnlineGalleryErrorCode.credentialsInvalid => l10n.onlineGallery_pleaseLogin,
  OnlineGalleryErrorCode.rateLimited => l10n.onlineGallery_sourceRateLimited,
  OnlineGalleryErrorCode.timeout => l10n.onlineGallery_sourceTimeout,
  OnlineGalleryErrorCode.server ||
  OnlineGalleryErrorCode.network => l10n.onlineGallery_sourceNetworkError,
  OnlineGalleryErrorCode.malformedResponse =>
    l10n.onlineGallery_sourceMalformedResponse,
  OnlineGalleryErrorCode.detailNotFound => l10n.onlineGallery_detailNotFound,
  OnlineGalleryErrorCode.imageUnavailable =>
    l10n.onlineGallery_imageUnavailable,
  OnlineGalleryErrorCode.rankingProcessing =>
    l10n.onlineGallery_aiTagRankingProcessing,
  OnlineGalleryErrorCode.configurationUnavailable =>
    l10n.onlineGallery_sourceConfigUnavailable,
  OnlineGalleryErrorCode.gelbooruRequestFailed =>
    l10n.onlineGallery_gelbooruRequestFailed,
  _ => l10n.common_error,
};

OnlineWork onlineWork(
  GalleryItem item, {
  GalleryDetail? detail,
  bool favorited = false,
}) {
  final resolved = detail?.item ?? item;
  final metadata =
      detail?.media.firstOrNull?.naiMetadata ?? resolved.cover.naiMetadata;
  final model = metadata?.model;
  final shortModel = model == null
      ? null
      : switch (model) {
          final String m when m.contains('diffusion-5') => 'V5',
          final String m when m.contains('diffusion-4-5') => 'V4.5',
          final String m when m.contains('diffusion-4') => 'V4',
          final String m when m.contains('diffusion-3') => 'V3',
          _ => model,
        };
  final ai = item.sourceId == GallerySourceId.aiTag;
  return OnlineWork(
    key: item.stableKey,
    id: item.id,
    thumb: onlineImage(item.previewUrl),
    width: resolved.width,
    height: resolved.height,
    title: ai ? resolved.title ?? '' : null,
    author: ai ? resolved.author ?? '' : null,
    authorId: ai && resolved.uploaderId > 0 ? resolved.uploaderId : null,
    views: resolved.viewCount,
    favorites: resolved.favoriteCount,
    score: ai ? null : resolved.score,
    rating: onlineRating(resolved.rating),
    mediaCount: resolved.mediaCount,
    rank: resolved.rank,
    model: shortModel,
    favorited: favorited,
    mediaLabel: resolved.mediaTypeLabel,
  );
}

OnlineDetail onlineDetail(
  GalleryDetail detail,
  favorites.OnlineFavoritesState saved, {
  String? Function(String)? translation,
}) {
  final item = detail.item;
  final metadata = detail.media.firstOrNull?.naiMetadata;
  final model = metadata?.model;
  final authorEntries = saved.entries.where(
    (entry) => entry.item.uploaderId == item.uploaderId,
  );
  final groups = {
    OnlineTagGroup.artist: item.artistTags,
    OnlineTagGroup.copyright: item.copyrightTags,
    OnlineTagGroup.character: item.characterTags,
    OnlineTagGroup.general: item.generalTags.isEmpty
        ? item.tags
              .where(
                (tag) => ![
                  ...item.artistTags,
                  ...item.copyrightTags,
                  ...item.characterTags,
                  ...item.metaTags,
                ].contains(tag),
              )
              .toList()
        : item.generalTags,
    OnlineTagGroup.meta: item.metaTags,
  };
  return OnlineDetail(
    key: item.stableKey,
    media: [
      for (final media in detail.media)
        OnlineMedia(
          thumb: onlineImage(media.previewUrl),
          image: onlineImage(
            item.isVideo ? media.previewUrl : media.displayUrl,
          ),
          width: media.width,
          height: media.height,
        ),
    ],
    createdAt: DateTime.tryParse(item.createdAt),
    prompt: detail.media.firstOrNull?.prompt ?? detail.prompt,
    negative: detail.media.firstOrNull?.negativePrompt ?? detail.negativePrompt,
    params: metadata == null
        ? null
        : OnlineParams(
            model:
                ImageModels.modelDisplayNames[model] ??
                model ??
                metadata.source,
            width: metadata.width,
            height: metadata.height,
            seed: metadata.seed,
            sampler: metadata.displaySampler,
            steps: metadata.steps,
            cfg: metadata.scale,
          ),
    siteTags: item.sourceId == GallerySourceId.aiTag ? item.tags : const [],
    tagGroups: item.sourceId == GallerySourceId.aiTag
        ? const {}
        : {
            for (final entry in groups.entries)
              entry.key: [
                for (final tag in entry.value)
                  OnlineTag(tag, translation: translation?.call(tag)),
              ],
          },
    fileType: item.fileExt?.toUpperCase(),
    fileBytes: item.fileSize,
    authorFavorited: saved.authors.any(
      (author) =>
          author.authorId == item.uploaderId && author.source == item.sourceId,
    ),
    authorSavedCount: authorEntries.length,
    authorAvatar: onlineImage(authorEntries.firstOrNull?.item.previewUrl ?? ''),
    canSendParams: metadata != null && item.sourceId == GallerySourceId.aiTag,
  );
}

List<GalleryItem> onlineLocalFavorites(
  favorites.OnlineFavoritesState saved, {
  String? collectionId,
  int? authorId,
  String filter = '',
}) {
  final query = filter.trim().toLowerCase();
  return [
    for (final entry in saved.entries)
      if ((authorId != null
              ? entry.item.uploaderId == authorId
              : collectionId == null ||
                    entry.collectionId ==
                        (collectionId.isEmpty ? null : collectionId)) &&
          (query.isEmpty ||
              [
                entry.item.title ?? '',
                entry.item.author ?? '',
                ...entry.item.tags,
              ].any((text) => text.toLowerCase().contains(query))))
        entry.item,
  ];
}

OnlineViewData onlineViewData({
  required OnlineGalleryState state,
  required favorites.OnlineFavoritesState saved,
  required OnlineGalleryPreferences preferences,
  required OnlineGalleryBlacklistState blacklist,
  required DanbooruAuthState danbooru,
  required GelbooruAuthState gelbooru,
  required AppLocalizations l10n,
  String? collectionId,
  int? authorId,
  String favoritesFilter = '',
  String? selectedKey,
  OnlineDetail? detail,
  GalleryDetail? Function(GalleryItem)? cachedDetail,
  int promptLength = 0,
  int characterCount = 0,
  bool reducedMotion = false,
  double localOffset = 0,
}) {
  final source = state.currentSourceId;
  final local =
      source == GallerySourceId.aiTag &&
      state.viewMode == GalleryViewMode.favorites;
  final items = local
      ? onlineLocalFavorites(
          saved,
          collectionId: collectionId,
          authorId: authorId,
          filter: favoritesFilter,
        )
      : state.posts;
  final cache = state.currentCache;
  final sources = [
    for (final uiSource in OnlineSource.values)
      () {
        final backend = gallerySource(uiSource);
        final c = backend.capabilities;
        final ai = backend == GallerySourceId.aiTag;
        return OnlineSourceStatus(
          source: uiSource,
          ranking: c.supportsRanking,
          favorites: ai || c.supportsFavorites,
          favoritesWritable: ai || c.supportsWritableFavorites,
          favoritesLocal: ai,
          ratings: c.supportsRatings,
          dateRange: c.supportsDateRange,
          fuzzy: c.supportsFuzzySearch,
          promptQuery: c.supportsPromptQuery,
          multiMedia: c.supportsMultipleMedia,
          account: switch (backend) {
            GallerySourceId.danbooru =>
              danbooru.isLoggedIn
                  ? OnlineAccountState.signedIn
                  : OnlineAccountState.signedOut,
            GallerySourceId.gelbooru =>
              gelbooru.status == GelbooruAuthStatus.invalid
                  ? OnlineAccountState.keyInvalid
                  : gelbooru.isAuthenticated
                  ? OnlineAccountState.keyConfigured
                  : OnlineAccountState.keyMissing,
            _ => OnlineAccountState.none,
          },
          accountName:
              backend == GallerySourceId.danbooru && danbooru.isLoggedIn
              ? danbooru.user?.name
              : null,
        );
      }(),
  ];
  final ranking = state.viewMode == GalleryViewMode.popular;
  final query = ranking ? state.popularQuery : state.searchQuery;
  return OnlineViewData(
    source: onlineSource(source),
    sources: sources,
    mode: onlineMode(state.viewMode),
    query: OnlineQuery(
      work: query,
      prompt: ranking ? state.popularPromptQuery : state.promptQuery,
      tags: query.split(RegExp(r'\s+')).where((tag) => tag.isNotEmpty).toList(),
      fuzzy: state.fuzzySearchEnabled,
      favoritesFilter: favoritesFilter,
    ),
    filters: OnlineFilters(
      naiOnly: state.aiTagNaiOnly,
      model: OnlineModel.values
          .where((model) => galleryModel(model) == state.aiTagModelVersion)
          .firstOrNull,
      timeRange: state.aiTagTimeRange,
      timeRanges: state.aiTagConfig?.searchTimeRanges ?? const ['all'],
      ratings: state.selectedRatings
          .map(onlineRating)
          .whereType<OnlineRating>()
          .toSet(),
      dateRange: state.dateRangeStart == null || state.dateRangeEnd == null
          ? null
          : DateTimeRange(
              start: state.dateRangeStart!,
              end: state.dateRangeEnd!,
            ),
    ),
    ranking: OnlineRanking(
      period: state.aiTagPopularPeriod,
      months: state.aiTagConfig?.availableMonths ?? const [],
      scale: OnlineRankScale.values[state.popularScale.index],
      date: state.popularDate,
    ),
    recent: preferences.recent[onlineSource(source)] ?? const [],
    favorites: source != GallerySourceId.aiTag
        ? null
        : OnlineFavorites(
            total: saved.favoritedWorkIds.length,
            ungrouped: saved.entries
                .where((entry) => entry.collectionId == null)
                .length,
            collections: [
              for (final collection in saved.collections)
                OnlineCollection(
                  id: collection.id,
                  name: collection.name,
                  count: collection.itemCount,
                ),
            ],
            authors: [
              for (final author in saved.authors)
                OnlineFavoriteAuthor(
                  id: author.authorId,
                  name: author.authorName,
                  savedAt: author.savedAt,
                  count: saved.entries
                      .where(
                        (entry) => entry.item.uploaderId == author.authorId,
                      )
                      .length,
                  avatar: onlineImage(
                    saved.entries
                            .where(
                              (entry) =>
                                  entry.item.uploaderId == author.authorId,
                            )
                            .firstOrNull
                            ?.item
                            .previewUrl ??
                        '',
                  ),
                ),
            ],
            collectionId: collectionId,
            authorId: authorId,
          ),
    blacklist: OnlineBlacklist(
      tags: blacklist.localTags.toList()..sort(),
      danbooruSync: blacklist.autoSyncOnStartup,
      danbooruCount: blacklist.remoteTags.length,
    ),
    list: OnlineList(
      key: local
          ? '${state.currentCacheKey}:$collectionId:$authorId:$favoritesFilter'
          : state.currentCacheKey,
      items: [
        for (final item in items)
          onlineWork(
            item,
            detail: cachedDetail?.call(item),
            favorited: item.sourceId == GallerySourceId.aiTag
                ? saved.isFavorite(item.sourceId, item.id)
                : state.favoritedPostKeys.contains(item.stableKey),
          ),
      ],
      loading: local ? saved.loading : state.isLoading,
      loadingMore: !local && state.isLoadingMore,
      pages: local ? (items.isEmpty ? 0 : 1) : cache.page,
      hasMore: !local && cache.hasMore,
      appendError: local || cache.appendErrorCode == null
          ? null
          : OnlineAppendError(
              page: cache.page + 1,
              reason: onlineError(l10n, cache.appendErrorCode),
            ),
      error: local
          ? saved.failed
                ? l10n.common_error
                : null
          : state.hasError
          ? onlineError(l10n, state.errorCode)
          : null,
      initialOffset: local ? localOffset : cache.scrollOffset,
    ),
    selectedKey: selectedKey,
    detail: detail,
    cardSize: preferences.cardSize,
    sidebarOpen: preferences.sidebarOpen,
    inspectorOpen: preferences.inspectorOpen,
    send: OnlineSendContext(
      promptLength: promptLength,
      characterCount: characterCount,
      remembered: preferences.sendMode,
    ),
    canReturn: state.authorReturnContext != null,
    reducedMotion: reducedMotion,
  );
}
