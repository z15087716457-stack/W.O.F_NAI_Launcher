import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/tag_normalizer.dart';
import '../../../core/wiki/wiki_example_repository.dart';
import '../../ui/kit/ui_colors.dart';
import '../../ui/kit/ui_controls.dart';
import '../../ui/kit/ui_text.dart';
import 'wiki_example_gallery.dart';

typedef WikiImageSelection = ({List<WikiExample> items, int index});

/// Article-owned identities and captions; metadata is fetched only for the
/// selected section, in explicit batches, through the shared illustration cache.
class WikiImagePanel extends ConsumerStatefulWidget {
  const WikiImagePanel({
    super.key,
    required this.tag,
    required this.references,
    required this.onClose,
    required this.onPreview,
    this.selectedKey,
  });
  final String tag;
  final List<WikiExampleReference> references;
  final VoidCallback onClose;
  final ValueChanged<WikiImageSelection?> onPreview;
  final String? selectedKey;
  @override
  ConsumerState<WikiImagePanel> createState() => _WikiImagePanelState();
}

class _WikiImagePanelState extends ConsumerState<WikiImagePanel> {
  final _scroll = ScrollController();
  final _images = <String, WikiExample>{};
  CancelToken? _token;
  int? _group;
  int _limit = 64;
  bool _loading = false, _failed = false;

  Map<int, List<WikiExampleReference>> get _groups {
    final result = <int, List<WikiExampleReference>>{};
    for (final r in widget.references) {
      result.putIfAbsent(r.sectionId, () => []).add(r);
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(WikiImagePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.references.map((r) => r.occurrenceKey).toList();
    final after = widget.references.map((r) => r.occurrenceKey).toList();
    if (oldWidget.tag != widget.tag || !listEquals(before, after)) {
      _token?.cancel();
      _token = null;
      _images.clear();
      _group = null;
      _limit = 64;
      _failed = false;
      if (_scroll.hasClients) _scroll.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  @override
  void dispose() {
    _token?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final groups = _groups;
    if (groups.isEmpty) return;
    _group = groups.containsKey(_group) ? _group : groups.keys.first;
    final missing = groups[_group]!
        .take(_limit)
        .where((r) => !_images.containsKey(r.key))
        .toList();
    _token?.cancel();
    if (missing.isEmpty) {
      setState(() {
        _loading = false;
        _failed = false;
      });
      return;
    }
    final token = CancelToken();
    _token = token;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final loaded = await ref
          .read(wikiExampleRepositoryProvider)
          .forReferences(missing, cancelToken: token);
      if (!mounted || token.isCancelled || _token != token) return;
      for (final image in loaded) {
        _images[image.reference.key] = image;
      }
    } catch (_) {
      if (mounted && !token.isCancelled && _token == token) _failed = true;
    } finally {
      if (mounted && _token == token) {
        _token = null;
        setState(() => _loading = false);
      }
    }
  }

  String _label(List<WikiExampleReference> refs) {
    final section = refs.first.sectionText;
    return section.isEmpty ? context.l10n.wiki_imageOtherGroup : section;
  }

  void _select(int id) {
    widget.onPreview(null);
    setState(() {
      _group = id;
      _limit = 64;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    if (groups.isEmpty) return const SizedBox.shrink();
    final selected = groups.containsKey(_group) ? _group! : groups.keys.first;
    final references = groups[selected]!;
    final count = references.length < _limit ? references.length : _limit;
    final c = context.ui;
    return Material(
      key: const Key('tag-expansion-image-panel'),
      elevation: 14,
      color: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
            child: Row(
              children: [
                Icon(Icons.collections_outlined, size: 15, color: c.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${context.l10n.wiki_imagePanelTitle} ${widget.references.length}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.wiki_imageHide,
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (groups.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  String title(int id) =>
                      '${_label(groups[id]!)} ${groups[id]!.length}';
                  final values = groups.keys.toList();
                  final requiredWidth = values.fold<double>(
                    0,
                    (sum, id) =>
                        sum +
                        TextPainter.computeWidth(
                          text: TextSpan(
                            text: title(id),
                            style: UiText.sans(12.5, weight: FontWeight.w600),
                          ),
                          textDirection: Directionality.of(context),
                          textScaler: MediaQuery.textScalerOf(context),
                        ) +
                        26,
                  );
                  if (values.length == 2 &&
                      requiredWidth <= constraints.maxWidth) {
                    return UiSegmented<int>(
                      values: values,
                      selected: selected,
                      labelOf: title,
                      onChanged: _select,
                      itemPadding: 9,
                    );
                  }
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.control,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          key: const Key('wiki-image-group'),
                          value: selected,
                          isExpanded: true,
                          isDense: true,
                          itemHeight: null,
                          style: UiText.sans(12, color: c.ink),
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          selectedItemBuilder: (context) => [
                            for (final id in values)
                              Tooltip(
                                message: title(id),
                                child: Text(
                                  title(id),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          items: [
                            for (final id in values)
                              DropdownMenuItem(
                                value: id,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Text(title(id)),
                                ),
                              ),
                          ],
                          onChanged: (id) {
                            if (id != null) _select(id);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_failed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.wiki_imageLoadFailed,
                      style: UiText.sans(11, color: c.muted),
                    ),
                  ),
                  TextButton(
                    onPressed: _load,
                    child: Text(context.l10n.common_retry),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Listener(
              // Consume wheel at this pane even at its edges, keeping the prompt
              // editor's scroll position unchanged.
              onPointerSignal: (event) {
                if (event is PointerScrollEvent && _scroll.hasClients) {
                  GestureBinding.instance.pointerSignalResolver.register(
                    event,
                    (_) {
                      final p = _scroll.position;
                      _scroll.jumpTo(
                        (_scroll.offset + event.scrollDelta.dy).clamp(
                          p.minScrollExtent,
                          p.maxScrollExtent,
                        ),
                      );
                    },
                  );
                }
              },
              child: ListView.separated(
                key: const Key('wiki-image-list'),
                controller: _scroll,
                padding: const EdgeInsets.all(8),
                itemCount: count + (count < references.length ? 1 : 0),
                separatorBuilder: (_, index) => const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  if (index == count) {
                    return TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() => _limit += 64);
                              _load();
                            },
                      child: Text(
                        context.l10n.wiki_imageMore(count, references.length),
                      ),
                    );
                  }
                  final r = references[index], urls = _images[r.key];
                  final image = WikiExample(
                    reference: r,
                    thumbnailUrl: urls?.thumbnailUrl,
                    largeUrl: urls?.largeUrl,
                  );
                  final caption = r.captionText.isNotEmpty
                      ? r.captionText
                      : r.sectionText.isNotEmpty
                      ? r.sectionText
                      : TagNormalizer.toDisplay(widget.tag);
                  return WikiExampleCard(
                    key: ValueKey('wiki-image-card-${r.occurrenceKey}'),
                    example: image,
                    imageHeight: 134,
                    selected: widget.selectedKey == r.occurrenceKey,
                    loading: _loading && !_images.containsKey(r.key),
                    caption: Text(
                      caption,
                      style: UiText.sans(12, color: c.ink, height: 1.5),
                    ),
                    source: Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () => launchUrl(Uri.parse(r.sourceUrl)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${r.kind.name} #${r.id}',
                            style: UiText.mono(11, color: c.muted),
                          ),
                        ),
                      ),
                    ),
                    onOpen: () {
                      final items = [
                        for (final ref in references.take(count))
                          if (_images[ref.key]?.largeUrl != null)
                            WikiExample(
                              reference: ref,
                              thumbnailUrl: _images[ref.key]?.thumbnailUrl,
                              largeUrl: _images[ref.key]?.largeUrl,
                            ),
                      ];
                      final selected = items.indexWhere(
                        (item) =>
                            item.reference.occurrenceKey == r.occurrenceKey,
                      );
                      if (selected >= 0) {
                        widget.onPreview((items: items, index: selected));
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
