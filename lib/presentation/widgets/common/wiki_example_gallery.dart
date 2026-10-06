import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../core/wiki/wiki_example_repository.dart';

final wikiExampleImageCacheProvider = Provider<BaseCacheManager>(
  (ref) => _WikiExampleImageCache.instance,
);

class _WikiExampleImageCache extends CacheManager with ImageCacheManager {
  _WikiExampleImageCache()
    : super(
        Config(
          'wikiExampleImages',
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 200,
        ),
      );
  static final instance = _WikiExampleImageCache();
}

/// Owns only the illustration lane; local prose remains the offline fallback.
class WikiExampleGallery extends ConsumerStatefulWidget {
  const WikiExampleGallery({
    super.key,
    required this.tag,
    required this.fallback,
    required this.captionBuilder,
  });
  final String tag;
  final Widget fallback;
  final Widget Function(String markdown) captionBuilder;

  @override
  ConsumerState<WikiExampleGallery> createState() => _WikiExampleGalleryState();
}

class _WikiExampleGalleryState extends ConsumerState<WikiExampleGallery> {
  WikiExampleSet? _examples;
  CancelToken? _token;
  bool _visible = false;
  bool _failed = false;

  @override
  void didUpdateWidget(WikiExampleGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tag != widget.tag) {
      _token?.cancel();
      _token = null;
      _examples = null;
      _failed = false;
      if (_visible) _load();
    }
  }

  @override
  void dispose() {
    _token?.cancel();
    super.dispose();
  }

  void _visibility(VisibilityInfo info) {
    _visible = info.visibleFraction > 0;
    if (_visible && _examples == null && !_failed) {
      _load();
    } else if (!_visible && _token != null) {
      _token!.cancel();
      _token = null;
    }
  }

  Future<void> _load() async {
    if (_token != null || !_visible) return;
    final token = CancelToken();
    _token = token;
    final tag = widget.tag;
    try {
      final value = await ref
          .read(wikiExampleRepositoryProvider)
          .forTag(tag, cancelToken: token);
      if (!mounted ||
          token.isCancelled ||
          _token != token ||
          tag != widget.tag) {
        return;
      }
      setState(() {
        _examples = value;
        _failed = false;
      });
    } catch (error) {
      if (mounted && !token.isCancelled && _token == token) {
        setState(() => _failed = true);
      }
    } finally {
      if (_token == token) _token = null;
    }
  }

  @override
  Widget build(BuildContext context) => VisibilityDetector(
    key: ObjectKey(this),
    onVisibilityChanged: _visibility,
    child: _examples?.items.isNotEmpty == true
        ? _gallery(context, _examples!)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.fallback,
              if (_failed)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        context.l10n.wiki_exampleImagesUnavailable,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _failed = false);
                          _load();
                        },
                        child: Text(context.l10n.common_retry),
                      ),
                    ],
                  ),
                ),
            ],
          ),
  );

  Widget _gallery(
    BuildContext context,
    WikiExampleSet examples,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = (constraints.maxWidth / 200).floor().clamp(1, 3);
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final example in examples.items)
                Container(
                  key: ValueKey('wiki-example-card-${example.postId}'),
                  width: width,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WikiExampleImage(example: example),
                      if (example.reference.caption.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          child: widget.captionBuilder(
                            example.reference.captionMarkdown,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          if (examples.truncated)
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.https('danbooru.donmai.us', '/wiki_pages/${widget.tag}'),
              ),
              icon: const Icon(Icons.open_in_new, size: 14),
              label: Text(context.l10n.wiki_source),
            ),
        ],
      );
    },
  );
}

class _WikiExampleImage extends ConsumerStatefulWidget {
  const _WikiExampleImage({required this.example});
  final WikiExample example;
  @override
  ConsumerState<_WikiExampleImage> createState() => _WikiExampleImageState();
}

class _WikiExampleImageState extends ConsumerState<_WikiExampleImage> {
  bool _visible = false;
  int _revision = 0;

  Future<void> _retry(String url) async {
    await CachedNetworkImage.evictFromCache(
      url,
      cacheManager: ref.read(wikiExampleImageCacheProvider),
    );
    if (mounted) setState(() => _revision++);
  }

  @override
  Widget build(BuildContext context) {
    final example = widget.example;
    final scheme = Theme.of(context).colorScheme;
    final url = example.thumbnailUrl;
    Widget missing() => Center(
      child: IconButton(
        tooltip: context.l10n.wiki_source,
        onPressed: () => launchUrl(Uri.parse(example.sourceUrl)),
        icon: Icon(Icons.image_not_supported_outlined, color: scheme.outline),
      ),
    );
    return VisibilityDetector(
      key: ObjectKey(this),
      onVisibilityChanged: (info) {
        final visible = info.visibleFraction > 0;
        if (mounted && visible != _visible) {
          setState(() => _visible = visible);
        }
      },
      child: Material(
        color: scheme.surfaceContainerLow,
        child: InkWell(
          key: ValueKey('wiki-example-open-${example.postId}'),
          onTap: url == null ? null : () => _preview(context, example),
          child: SizedBox(
            height: 180,
            child: url == null
                ? missing()
                : !_visible
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: CachedNetworkImage(
                      key: ValueKey(
                        'wiki-example-${example.postId}-$_revision',
                      ),
                      cacheManager: ref.watch(wikiExampleImageCacheProvider),
                      imageUrl: url,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: IconButton(
                          tooltip: context.l10n.wiki_exampleImagesUnavailable,
                          onPressed: () => _retry(url),
                          icon: const Icon(Icons.refresh),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _preview(BuildContext context, WikiExample example) {
    final url = example.largeUrl;
    if (url == null) return;
    final cache = ref.read(wikiExampleImageCacheProvider);
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 850),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8, top: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(context.l10n.wiki_exampleImages)),
                    TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse(example.sourceUrl)),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: Text(context.l10n.wiki_source),
                    ),
                    IconButton(
                      tooltip: context.l10n.common_close,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: CachedNetworkImage(
                    key: ValueKey('wiki-example-large-${example.postId}'),
                    imageUrl: url,
                    cacheManager: cache,
                    fit: BoxFit.contain,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(context.l10n.wiki_exampleImagesUnavailable),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
