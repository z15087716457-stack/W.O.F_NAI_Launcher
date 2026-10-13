import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/studio_tools.dart';
import '../../../core/utils/tag_normalizer.dart';
import '../../../core/wiki/wiki_example_repository.dart';
import '../../widgets/common/wiki_example_gallery.dart';

class NaiAgentWikiImages {
  NaiAgentWikiImages(this.ref, this.isAlive);
  final Ref ref;
  final bool Function() isAlive;

  Future<WikiExampleSet> _examples(
    String tag,
    NaiAgentCancellation token,
  ) async {
    _check(token);
    final cancel = CancelToken();
    var finished = false;
    token.whenCancelled.then((_) {
      if (!finished) cancel.cancel();
    });
    try {
      final result = await ref
          .read(wikiExampleRepositoryProvider)
          .forTag(tag, cancelToken: cancel);
      _check(token);
      return result;
    } catch (_) {
      _check(token);
      rethrow;
    } finally {
      finished = true;
    }
  }

  Future<Map<String, dynamic>> list(
    String tag,
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    final offset = params['example_offset'] ?? 0;
    final limit = params['example_limit'] ?? 4;
    if (offset is! int ||
        offset < 0 ||
        limit is! int ||
        limit < 1 ||
        limit > 8) {
      throw const NaiAgentToolError(
        'invalid_page',
        'Examples use offset >= 0 and limit 1..8',
      );
    }
    final set = await _examples(tag, token);
    return {
      'examples': [
        for (final item in set.items.skip(offset).take(limit))
          {
            'post_id': item.postId,
            'caption': item.reference.caption,
            'source_url': item.sourceUrl,
            'thumbnail_url': item.thumbnailUrl,
            'preview_url': item.largeUrl,
            'available': item.largeUrl != null,
            'image_id': item.largeUrl == null
                ? null
                : 'wiki:${item.postId}:${Uri.encodeComponent(TagNormalizer.normalize(tag))}',
          },
      ],
      'example_count': set.items.length,
      'examples_truncated': set.truncated,
      'next_example_offset': offset + limit < set.items.length
          ? offset + limit
          : null,
    };
  }

  Future<NaiAgentImage?> load(String id, NaiAgentCancellation token) async {
    final match = RegExp(r'^wiki:([1-9][0-9]*):(.+)$').firstMatch(id);
    if (match == null) {
      throw const NaiAgentToolError(
        'invalid_image',
        'Use an image_id from wiki_query',
      );
    }
    late final String tag;
    try {
      tag = TagNormalizer.normalize(Uri.decodeComponent(match[2]!));
    } on ArgumentError {
      throw const NaiAgentToolError('invalid_image', 'Malformed Wiki image ID');
    }
    final set = await _examples(tag, token);
    final item = set.items
        .where((item) => item.postId.toString() == match[1])
        .firstOrNull;
    final url = item?.largeUrl;
    if (url == null) {
      throw const NaiAgentToolError(
        'image_missing',
        'Official Wiki example is unavailable',
      );
    }
    final cache = ref.read(wikiExampleImageCacheProvider);
    final file = await Future.any<File>([
      cache.getSingleFile(url),
      token.whenCancelled.then((_) {
        token.check();
        throw StateError('cancelled');
      }),
    ]);
    _check(token);
    if (await file.length() > 16 * 1024 * 1024) {
      throw const NaiAgentToolError(
        'image_too_large',
        'Wiki preview exceeds 16 MiB',
      );
    }
    final bytes = await file.readAsBytes();
    _check(token);
    return NaiAgentImage(
      id: id,
      bytes: bytes,
      metadata: {
        'source': 'danbooru_wiki_example',
        'tag': tag,
        'post_id': item!.postId,
        'source_url': item.sourceUrl,
        'caption': item.reference.caption,
        'preview_url': url,
        'is_static_preview': true,
      },
    );
  }

  void _check(NaiAgentCancellation token) {
    token.check();
    if (!isAlive()) {
      throw const NaiAgentToolError('closed', 'Wiki image binding closed');
    }
  }
}
