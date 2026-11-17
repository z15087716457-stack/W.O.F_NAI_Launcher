import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/danbooru_api_service.dart';
import '../utils/tag_normalizer.dart';
import '../cache/cache_footprint.dart';
import 'wiki_image_document.dart';

export 'wiki_image_document.dart';

class WikiExample {
  const WikiExample({
    required this.reference,
    this.thumbnailUrl,
    this.largeUrl,
  });
  final WikiExampleReference reference;
  final String? thumbnailUrl;
  final String? largeUrl;
  int get postId => reference.postId;
  String get sourceUrl => reference.sourceUrl;
}

class WikiExampleSet {
  const WikiExampleSet(this.items, {this.truncated = false});
  final List<WikiExample> items;
  final bool truncated;
}

typedef WikiPageFetch =
    Future<Map<String, dynamic>?> Function(
      String tag, {
      CancelToken? cancelToken,
    });
typedef WikiPostFetch =
    Future<List<Map<String, dynamic>>> Function(
      List<int> ids, {
      CancelToken? cancelToken,
    });

/// Separate online illustration metadata. Never replaces local Wiki prose or
/// invalidates translation caches. Only pages actually opened are requested.
class WikiExampleRepository {
  WikiExampleRepository({
    required this.fetchWiki,
    required this.fetchPosts,
    this.fetchAssets,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  final WikiPageFetch fetchWiki;
  final WikiPostFetch fetchPosts;
  final WikiPostFetch? fetchAssets;
  final DateTime Function() _now;
  final _cache = <String, ({DateTime at, WikiExampleSet value})>{};
  final _media = <String, ({DateTime at, String? thumbnail, String? large})>{};

  int _cacheGeneration = 0;

  CacheFootprint get footprint => CacheFootprint.json([
    for (final entry in _cache.values)
      [
        for (final item in entry.value.items)
          [
            item.postId,
            item.reference.caption,
            item.thumbnailUrl,
            item.largeUrl,
          ],
      ],
    for (final MapEntry(key: key, value: urls) in _media.entries)
      [key, urls.thumbnail, urls.large],
  ]);

  void clearCache() {
    _cacheGeneration++;
    _cache.clear();
    _media.clear();
  }

  Future<WikiExampleSet> forTag(String tag, {CancelToken? cancelToken}) async {
    final generation = _cacheGeneration;
    final name = TagNormalizer.normalize(tag);
    if (name.isEmpty) return const WikiExampleSet([]);
    final cached = _cache.remove(name);
    if (cached != null &&
        _now().difference(cached.at) < const Duration(hours: 6)) {
      _cache[name] = cached;
      return cached.value;
    }
    final page = await fetchWiki(name, cancelToken: cancelToken);
    if (cancelToken?.isCancelled == true) {
      throw cancelToken!.cancelError!;
    }
    final body = page?['body'];
    if (page != null && body is! String) {
      throw const FormatException('Invalid Wiki body');
    }
    final references = WikiExampleReference.parse(body is String ? body : '');
    final selected = references.take(64).toList(growable: false);
    final items = await forReferences(selected, cancelToken: cancelToken);
    final result = WikiExampleSet(
      items,
      truncated: references.length > selected.length,
    );
    if (generation != _cacheGeneration) return result;
    _cache[name] = (at: _now(), value: result);
    while (_cache.length > 32) {
      _cache.remove(_cache.keys.first);
    }
    return result;
  }

  static String? _url(dynamic value) {
    if (value is! String) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        !(uri.host == 'donmai.us' || uri.host.endsWith('.donmai.us'))) {
      return null;
    }
    return value;
  }

  /// Cache metadata by typed identity, keeping captions and section occurrences
  /// article-owned. The batch size bounds requests, never the article's size.
  Future<List<WikiExample>> forReferences(
    List<WikiExampleReference> references, {
    CancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled == true) throw cancelToken!.cancelError!;
    final generation = _cacheGeneration;
    final missing = <String, WikiExampleReference>{};
    for (final ref in references) {
      final cached = _media[ref.key];
      if (cached == null ||
          _now().difference(cached.at) >= const Duration(hours: 6)) {
        missing[ref.key] = ref;
      }
    }
    final resolved =
        <String, ({DateTime at, String? thumbnail, String? large})>{};
    final values = missing.values.toList();
    for (var start = 0; start < values.length; start += 64) {
      final batch = values.skip(start).take(64).toList();
      final posts = batch
          .where((r) => r.kind == WikiImageKind.post)
          .map((r) => r.id)
          .toList();
      final assets = batch
          .where((r) => r.kind == WikiImageKind.asset)
          .map((r) => r.id)
          .toList();
      final responses = await Future.wait([
        posts.isEmpty
            ? Future.value(<Map<String, dynamic>>[])
            : fetchPosts(posts, cancelToken: cancelToken),
        assets.isEmpty || fetchAssets == null
            ? Future.value(<Map<String, dynamic>>[])
            : fetchAssets!(assets, cancelToken: cancelToken),
      ]);
      if (cancelToken?.isCancelled == true) throw cancelToken!.cancelError!;
      final postMap = {for (final post in responses[0]) post['id']: post};
      final assetMap = {for (final asset in responses[1]) asset['id']: asset};
      for (final ref in batch) {
        final raw = ref.kind == WikiImageKind.post
            ? postMap[ref.id]
            : assetMap[ref.id];
        final urls = _urls(raw, ref.kind);
        resolved[ref.key] = (at: _now(), thumbnail: urls.$1, large: urls.$2);
      }
    }
    if (generation == _cacheGeneration) {
      _media.addAll(resolved);
      while (_media.length > 2048) {
        _media.remove(_media.keys.first);
      }
    }
    return [
      for (final ref in references)
        WikiExample(
          reference: ref,
          thumbnailUrl: (resolved[ref.key] ?? _media[ref.key])?.thumbnail,
          largeUrl: (resolved[ref.key] ?? _media[ref.key])?.large,
        ),
    ];
  }

  (String?, String?) _urls(Map<String, dynamic>? item, WikiImageKind kind) {
    if (item == null ||
        item['is_deleted'] == true ||
        (kind == WikiImageKind.asset && item['status'] != 'active')) {
      return (null, null);
    }
    final asset = kind == WikiImageKind.asset ? item : item['media_asset'];
    final raw = asset is Map ? asset['variants'] : null;
    final variants = raw is List ? raw.whereType<Map>() : const <Map>[];
    String? variant(String type) => variants
        .where((v) => v['type'] == type)
        .map((v) => _url(v['url']))
        .whereType<String>()
        .firstOrNull;
    final thumbnail = variant('360x360') ?? _url(item['preview_file_url']);
    return (thumbnail, variant('720x720') ?? thumbnail);
  }
}

final wikiExampleRepositoryProvider = Provider<WikiExampleRepository>((ref) {
  final api = ref.watch(danbooruApiServiceProvider);
  return WikiExampleRepository(
    fetchWiki: api.getWikiPage,
    fetchPosts: api.getWikiExamplePosts,
    fetchAssets: api.getWikiExampleAssets,
  );
});
