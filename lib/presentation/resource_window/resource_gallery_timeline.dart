import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/utils/localization_extension.dart';
import '../../data/services/gallery/gallery_view_mode.dart';
import '../ui/kit/ui_controls.dart';
import '../ui/resource_window/resource_window_cards.dart';
import '../widgets/gallery/timeline/gallery_timeline_header.dart';
import '../widgets/gallery/timeline/gallery_timeline_layout.dart';
import '../widgets/gallery/timeline/gallery_timeline_scrubber.dart';
import 'resource_window_controller.dart';

/// Same layout, date rail, headers and buffered visible-window policy as the
/// main gallery. Full records are requested in batches only for this window.
class ResourceGalleryTimeline extends StatefulWidget {
  const ResourceGalleryTimeline({
    super.key,
    required this.controller,
    required this.scroll,
    required this.cell,
  });
  final ResourceWindowController controller;
  final ScrollController scroll;
  final double cell;
  @override
  State<ResourceGalleryTimeline> createState() =>
      _ResourceGalleryTimelineState();
}

class _ResourceGalleryTimelineState extends State<ResourceGalleryTimeline> {
  final _window = GalleryTimelineWindow();
  GalleryTimelineLayout _layout = GalleryTimelineLayout.empty;
  Object? _layoutKey, _notifiedWindow;
  double _viewport = 0;
  String? _selection;
  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ResourceGalleryTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scroll != widget.scroll) {
      oldWidget.scroll.removeListener(_onScroll);
      widget.scroll.addListener(_onScroll);
    }
    final selected = widget.controller.data.selectedId;
    if (_selection != selected) {
      _selection = selected;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !widget.scroll.hasClients ||
            widget.controller.data.selectedId != selected) {
          return;
        }
        final offset = _layout.offsetToReveal(
          widget.controller.selectedGalleryIndex,
          widget.scroll.offset,
          _viewport,
        );
        if (offset != null) {
          widget.scroll.jumpTo(
            offset.clamp(0.0, widget.scroll.position.maxScrollExtent),
          );
        }
      });
    }
  }

  void _onScroll() {
    if (!widget.scroll.hasClients) return;
    if (_window.needsUpdate(widget.scroll.offset, _viewport)) {
      setState(() => _window.reset(widget.scroll.offset, _viewport));
    }
  }

  @override
  void dispose() {
    widget.scroll.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final data = controller.data;
    final entries = controller.galleryTimeline;
    final mode = controller.effectiveGalleryGroupMode;
    if (entries.isEmpty) {
      return Center(
        child: data.loading
            ? const UiSpinner(size: 16)
            : data.error != null
            ? TextButton(
                onPressed: controller.refresh,
                child: Text(context.l10n.common_retry),
              )
            : Text(context.l10n.floating_empty),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final key = (entries, box.maxWidth, widget.cell, data.layout, mode);
        if (key != _layoutKey) {
          _layoutKey = key;
          _layout = computeGalleryTimelineLayout(
            entries: entries,
            viewMode: GalleryViewMode.values.byName(data.layout.name),
            groupMode: mode,
            width: box.maxWidth,
            tileSize: widget.cell,
            gap: galleryTimelineGap,
            leftPadding: galleryTimelineLeftPadding,
            rightPadding: galleryTimelineRightPadding,
            headerHeight: galleryTimelineHeaderHeight,
          );
        }
        if (_viewport != box.maxHeight) {
          _viewport = box.maxHeight;
          _window.reset(
            widget.scroll.hasClients ? widget.scroll.offset : 0,
            _viewport,
          );
        }
        final layout = _layout;
        final indices = layout.indicesIn(_window.top, _window.bottom);
        final windowKey = (layout, _window.top, _window.bottom);
        if (_notifiedWindow != windowKey) {
          _notifiedWindow = windowKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && identical(entries, controller.galleryTimeline)) {
              unawaited(controller.ensureGalleryItems(indices));
            }
          });
        }
        Widget header(GalleryTimelineSection section, {bool opaque = false}) =>
            GalleryTimelineGroupHeader(
              section: section,
              groupMode: mode,
              opaque: opaque,
            );
        return Stack(
          children: [
            Positioned.fill(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  key: const Key('rw-gallery-timeline-scroll'),
                  controller: widget.scroll,
                  child: SizedBox(
                    height: math.max(layout.extent, box.maxHeight),
                    width: box.maxWidth,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final section in layout.sections)
                          if (section.hasHeader &&
                              section.headerTop + layout.headerHeight >=
                                  _window.top &&
                              section.headerTop <= _window.bottom)
                            Positioned(
                              key: ValueKey('header-${section.start}'),
                              left: 0,
                              right: galleryTimelineRightPadding,
                              top: section.headerTop,
                              height: layout.headerHeight,
                              child: header(section),
                            ),
                        for (final index in indices)
                          Positioned(
                            key: ValueKey(entries[index].path),
                            left: layout.tiles[index].left,
                            top: layout.tiles[index].top,
                            width: layout.tiles[index].width,
                            height: layout.tiles[index].height,
                            child: RepaintBoundary(
                              child: Builder(
                                builder: (context) {
                                  final item = controller.galleryItem(index);
                                  final card = ResourceGalleryCard(
                                    key: Key('rw-item-${item.id}'),
                                    item: item,
                                    width: layout.tiles[index].width,
                                    height: layout.tiles[index].height,
                                    selected: item.id == data.selectedId,
                                    onTap: () =>
                                        unawaited(controller.select(item.id)),
                                    onDouble: () => controller.open(item.id),
                                    onFavorite: () => unawaited(
                                      controller.command(
                                        'resources.favorite',
                                        item.id,
                                      ),
                                    ),
                                    onAction: (action) => unawaited(
                                      controller.command(
                                        'resources.action',
                                        item.id,
                                        action: action,
                                      ),
                                    ),
                                  );
                                  return controller.dragWrap(item, card);
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (layout.headerHeight > 0)
              Positioned(
                left: 0,
                right: galleryTimelineRightPadding,
                top: 0,
                height: layout.headerHeight,
                child: GalleryTimelineStickyHeader(
                  layout: layout,
                  scrollController: widget.scroll,
                  headerBuilder: (section) => header(section, opaque: true),
                ),
              ),
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: galleryTimelineRightPadding,
              child: GalleryTimelineScrubber(
                layout: layout,
                entries: entries,
                groupMode: controller.galleryGroupMode,
                scrollController: widget.scroll,
              ),
            ),
          ],
        );
      },
    );
  }
}
