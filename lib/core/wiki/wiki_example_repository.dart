import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/danbooru_api_service.dart';
import '../utils/tag_normalizer.dart';

bool isWikiExampleHeading(String title) => RegExp(
  r'^(examples?|示例|范例|範例|例子|示范|示範|用例|使用例|实例|實例|事例|作例|サンプル|例|예시|예제)(?:\s|[:：]|$)',
  caseSensitive: false,
).hasMatch(title.trim());

class WikiExampleReference {
  const WikiExampleReference(this.postId, this.caption);
  final int postId;
  final String caption;

  /// Read only explicit image embeds in example sections, not ordinary links.
  static List<WikiExampleReference> parse(String body) {
    final found = <int, WikiExampleReference>{};
    int? level;
    for (final line in body.split(RegExp(r'\r?\n'))) {
      final heading = RegExp(r'^h([1-6])\.\s*(.*)$').firstMatch(line.trim());
      if (heading != null) {
        final next = int.parse(heading[1]!);
        if (isWikiExampleHeading(heading[2]!)) {
          level = next;
        } else if (level != null && next <= level) {
          level = null;
        }
        continue;
      }
      if (level == null) continue;
      final embeds = RegExp(r'!post\s+#(\d+)\b').allMatches(line).toList();
      for (var index = 0; index < embeds.length; index++) {
        final match = embeds[index];
        final id = int.tryParse(match[1]!);
        if (id == null || id <= 0) continue;
        final end = index + 1 < embeds.length
            ? embeds[index + 1].start
            : line.length;
        final caption = line
            .substring(match.end, end)
            .replaceFirst(RegExp(r'^\s*:\s*'), '')
            .trim();
        found.putIfAbsent(
          id,
          () => WikiExampleReference(
            id,
            String.fromCharCodes(caption.runes.take(240)),
          ),
        );
      }
    }
    return found.values.toList(growable: false);
  }

  String get captionMarkdown => caption.replaceAllMapped(
    RegExp(r'\[\[([^\]\r\n]+)\]\]'),
    (match) {
      final parts = match[1]!.split('|');
      final tag = TagNormalizer.normalize(parts.first);
      final label = parts.length > 1 && parts.last.isNotEmpty
          ? parts.last
          : TagNormalizer.toDisplay(tag);
      final safeLabel = label.replaceAll('[', r'\[').replaceAll(']', r'\]');
      return '[$safeLabel](https://danbooru.donmai.us/wiki_pages/${Uri.encodeComponent(tag)})';
    },
  );
}

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
  String get sourceUrl => 'https://danbooru.donmai.us/posts/$postId';
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
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  final WikiPageFetch fetchWiki;
  final WikiPostFetch fetchPosts;
  final DateTime Function() _now;
  final _cache = <String, ({DateTime at, WikiExampleSet value})>{};

  Future<WikiExampleSet> forTag(String tag, {CancelToken? cancelToken}) async {
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
    final posts = selected.isEmpty
        ? const <Map<String, dynamic>>[]
        : await fetchPosts(
            selected.map((r) => r.postId).toList(),
            cancelToken: cancelToken,
          );
    if (cancelToken?.isCancelled == true) {
      throw cancelToken!.cancelError!;
    }
    final byId = {for (final post in posts) post['id']: post};
    final result = WikiExampleSet([
      for (final reference in selected)
        _image(reference, byId[reference.postId]),
    ], truncated: references.length > selected.length);
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

  WikiExample _image(
    WikiExampleReference reference,
    Map<String, dynamic>? post,
  ) {
    if (post == null || post['is_deleted'] == true) {
      return WikiExample(reference: reference);
    }
    final asset = post['media_asset'];
    final raw = asset is Map ? asset['variants'] : null;
    final variants = raw is List ? raw.whereType<Map>() : const <Map>[];
    String? variant(String type) => variants
        .where((v) => v['type'] == type)
        .map((v) => _url(v['url']))
        .whereType<String>()
        .firstOrNull;
    final thumbnail = variant('360x360') ?? _url(post['preview_file_url']);
    return WikiExample(
      reference: reference,
      thumbnailUrl: thumbnail,
      // A static preview is bounded even when the original is a huge animation.
      largeUrl: variant('720x720') ?? thumbnail,
    );
  }
}

final wikiExampleRepositoryProvider = Provider<WikiExampleRepository>((ref) {
  final api = ref.watch(danbooruApiServiceProvider);
  return WikiExampleRepository(
    fetchWiki: api.getWikiPage,
    fetchPosts: api.getWikiExamplePosts,
  );
});
