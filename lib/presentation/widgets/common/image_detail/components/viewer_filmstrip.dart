import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'viewer_icon.dart';
import 'viewer_stage.dart';

/// Common item data; callers can use image, video poster, or custom content.
class ViewerFilmstripItem {
  const ViewerFilmstripItem({
    this.thumbnail,
    this.thumbnailBuilder,
    this.aspectRatio,
    this.groupDate,
    this.semanticLabel,
  });
  final ImageProvider? thumbnail;
  final WidgetBuilder? thumbnailBuilder;
  final double? aspectRatio;
  final DateTime? groupDate;
  final String? semanticLabel;
}

class ViewerFilmstrip extends StatefulWidget {
  const ViewerFilmstrip({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.scrollController,
  });
  final List<ViewerFilmstripItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final ScrollController? scrollController;
  static const thumbnailHeight = 52.0, selectedHeight = 60.0;

  /// A large-image provider may already be resized. Decode the source once.
  static ImageProvider thumbnailProvider(ImageProvider provider) {
    while (provider is ResizeImage) {
      provider = provider.imageProvider;
    }
    return ResizeImage(provider, height: 120);
  }

  @override
  State<ViewerFilmstrip> createState() => _ViewerFilmstripState();
}

class _ViewerFilmstripState extends State<ViewerFilmstrip> {
  final _ownedController = ScrollController();
  ScrollController get _controller =>
      widget.scrollController ?? _ownedController;
  int? _geometrySignature;
  bool _scheduled = false, _hasCentered = false;
  double _selectedCenter = 0, _viewportWidth = 0;

  void _scheduleCenter() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || !_controller.hasClients) return;
      final position = _controller.position;
      final offset = (_selectedCenter - _viewportWidth / 2).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (!_hasCentered || MediaQuery.disableAnimationsOf(context)) {
        _controller.jumpTo(offset);
      } else if ((_controller.offset - offset).abs() > .5) {
        _controller.animateTo(
          offset,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
      _hasCentered = true;
    });
  }

  static bool _sameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: ViewerStage.filmstripHeight,
    child: LayoutBuilder(
      builder: (context, box) {
        final locale = Localizations.localeOf(context).toString();
        final textScaler = MediaQuery.textScalerOf(context);
        final dateStyle = TextStyle(
          fontFamily: 'HarmonyOS Sans SC',
          fontFamilyFallback: const ['Pretendard', 'Geist'],
          fontSize: 11,
          color: Colors.white.withValues(alpha: .55),
        );
        final dates = <String?>[],
            dateWidths = <double>[],
            widths = <double>[],
            imageWidths = <double>[];
        var offset = 14.0;
        for (var i = 0; i < widget.items.length; i++) {
          final item = widget.items[i];
          final date = item.groupDate;
          final label =
              date != null &&
                  (i == 0 || !_sameDay(widget.items[i - 1].groupDate, date))
              ? DateFormat.MMMd(locale).format(date)
              : null;
          var dateWidth = 0.0;
          if (label != null) {
            final painter = TextPainter(
              text: TextSpan(text: label, style: dateStyle),
              textDirection: Directionality.of(context),
              textScaler: textScaler,
            )..layout();
            dateWidth = painter.width.ceilToDouble() + 15;
            painter.dispose();
          }
          final selected = i == widget.currentIndex;
          final rawRatio = item.aspectRatio;
          final ratio = rawRatio != null && rawRatio.isFinite && rawRatio > 0
              ? rawRatio.clamp(.4, 2.5)
              : 1.0;
          final imageWidth =
              ((selected
                          ? ViewerFilmstrip.selectedHeight
                          : ViewerFilmstrip.thumbnailHeight) *
                      ratio)
                  .roundToDouble();
          final width =
              dateWidth +
              imageWidth +
              (selected ? 8 : 0) +
              (i == widget.items.length - 1 ? 0 : 4);
          dates.add(label);
          dateWidths.add(dateWidth);
          imageWidths.add(imageWidth);
          widths.add(width);
          if (selected) {
            _selectedCenter =
                offset + dateWidth + (selected ? 4 : 0) + imageWidth / 2;
          }
          offset += width;
        }
        _viewportWidth = box.maxWidth;
        final signature = Object.hash(
          widget.currentIndex,
          box.maxWidth,
          locale,
          Object.hashAll(widths),
          Object.hashAll(dates),
        );
        if (signature != _geometrySignature) {
          _geometrySignature = signature;
          _scheduleCenter();
        }
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListView.builder(
                key: const Key('viewer-filmstrip-list'),
                controller: _controller,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: widget.items.length,
                // Exact extents keep centering correct even for distant lazy items.
                itemExtentBuilder: (i, _) => widths[i],
                itemBuilder: (context, i) => Row(
                  children: [
                    if (dates[i] != null)
                      SizedBox(
                        width: dateWidths[i],
                        height: 40,
                        child: Container(
                          key: Key('viewer-filmstrip-date-$i'),
                          padding: const EdgeInsets.only(left: 8, right: 6),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Colors.white.withValues(alpha: .12),
                              ),
                            ),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            dates[i]!,
                            style: dateStyle,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                    if (i == widget.currentIndex) const SizedBox(width: 4),
                    _FilmThumbnail(
                      key: Key('viewer-filmstrip-item-$i'),
                      item: widget.items[i],
                      width: imageWidths[i],
                      selected: i == widget.currentIndex,
                      onTap: () => widget.onTap(i),
                    ),
                    if (i == widget.currentIndex) const SizedBox(width: 4),
                    if (i != widget.items.length - 1) const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            for (final left in [true, false])
              Positioned(
                top: 0,
                bottom: 0,
                left: left ? 0 : null,
                right: left ? null : 0,
                width: 60,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: left
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        end: left
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        colors: const [Colors.black, Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );

  @override
  void dispose() {
    _ownedController.dispose();
    super.dispose();
  }
}

class _FilmThumbnail extends StatefulWidget {
  const _FilmThumbnail({
    super.key,
    required this.item,
    required this.width,
    required this.selected,
    required this.onTap,
  });
  final ViewerFilmstripItem item;
  final double width;
  final bool selected;
  final VoidCallback onTap;
  @override
  State<_FilmThumbnail> createState() => _FilmThumbnailState();
}

class _FilmThumbnailState extends State<_FilmThumbnail> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    cursor: SystemMouseCursors.click,
    child: Semantics(
      button: true,
      selected: widget.selected,
      label: widget.item.semanticLabel,
      child: SizedBox(
        width: widget.width,
        height: widget.selected ? 60 : 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .6),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                    const BoxShadow(color: Colors.white, spreadRadius: 2),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                child: AnimatedOpacity(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 150),
                  opacity: widget.selected
                      ? 1
                      : _hovered
                      ? .85
                      : .5,
                  child:
                      widget.item.thumbnailBuilder?.call(context) ??
                      (widget.item.thumbnail != null
                          ? Image(
                              image: ViewerFilmstrip.thumbnailProvider(
                                widget.item.thumbnail!,
                              ),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Center(
                                child: ViewerIcon('img', size: 20),
                              ),
                            )
                          : const Center(child: ViewerIcon('img', size: 20))),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
