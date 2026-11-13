import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_inputs.dart';
import '../kit/ui_text.dart';
import 'blocks_contract.dart';

// Content viewports exclude the existing surface/inspector borders and padding.
const blockHoverPreviewSize = Size(298, 150);
const blockInspectorPreviewSize = Size(307, 176);

// Keep previews sharp without decoding each source at its full resolution.
ImageProvider blockThumbnailProvider(
  BlockThumb thumb,
  double size,
  double pixelRatio,
) => ResizeImage.resizeIfNeeded(
  (size * pixelRatio * thumb.scale * 2).ceil(),
  null,
  thumb.image,
);

/// Fit width so wide source images and the complete consumer crop stay visible.
Rect blockEditorImageRect(
  Size image,
  Size editor,
  BlockThumb thumb, {
  Size target = blockHoverPreviewSize,
}) {
  final width = editor.width * thumb.scale;
  final height = width * image.height / image.width;
  if (image.aspectRatio > editor.aspectRatio) {
    // Center the consumer crop in a letterboxed editor. Aligning the image to
    // positive spare space would otherwise reverse its visual pan direction.
    final ratio =
        editor.width /
        image.width /
        math.max(target.width / image.width, target.height / image.height);
    final cropWidth = target.width * ratio;
    final cropHeight = target.height * ratio;
    return Rect.fromLTWH(
      (editor.width - cropWidth) / 2 +
          (cropWidth - width) * (thumb.offsetX + 1) / 2,
      (editor.height - cropHeight) / 2 +
          (cropHeight - height) * (thumb.offsetY + 1) / 2,
      width,
      height,
    );
  }
  return Rect.fromLTWH(
    (editor.width - width) * (thumb.offsetX + 1) / 2,
    (editor.height - height) * (thumb.offsetY + 1) / 2,
    width,
    height,
  );
}

Rect blockPreviewRange(Size image, Size editor, Size target, BlockThumb thumb) {
  final shown = blockEditorImageRect(image, editor, thumb, target: target);
  final scale =
      math.max(target.width / image.width, target.height / image.height) *
      thumb.scale;
  final left = (target.width - image.width * scale) * (thumb.offsetX + 1) / 2;
  final top = (target.height - image.height * scale) * (thumb.offsetY + 1) / 2;
  final ratio = shown.width / image.width / scale;
  return Rect.fromLTWH(
    shown.left - left * ratio,
    shown.top - top * ratio,
    target.width * ratio,
    target.height * ratio,
  );
}

class BlockPreviewGuidePainter extends CustomPainter {
  const BlockPreviewGuidePainter(this.range);
  final Rect range;

  @override
  void paint(Canvas canvas, Size size) {
    final cutout = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(range);
    canvas.drawPath(cutout, Paint()..color = const Color(0x52000000));
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius(range, const Radius.circular(4)));
    final pen = Paint()
      ..color = const Color(0xC2FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in outline.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 7) {
        canvas.drawPath(
          metric.extractPath(offset, math.min(offset + 4, metric.length)),
          pen,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BlockPreviewGuidePainter oldDelegate) =>
      oldDelegate.range != range;
}

/// Shared image navigation. Pointer focus never keeps the arrows visible.
class BlockGalleryFrame extends StatefulWidget {
  const BlockGalleryFrame({
    super.key,
    required this.child,
    this.onPrevious,
    this.onNext,
    this.counter,
  });
  final Widget child;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String? counter;

  @override
  State<BlockGalleryFrame> createState() => _BlockGalleryFrameState();
}

class _BlockGalleryFrameState extends State<BlockGalleryFrame> {
  bool _hover = false;
  bool _keyboard = false;
  bool _touch = false;

  @override
  Widget build(BuildContext context) {
    final visible = _hover || _keyboard || _touch;
    Widget arrow(bool previous) => Positioned(
      left: previous ? 8 : null,
      right: previous ? null : 8,
      top: 0,
      bottom: 0,
      child: Center(
        child: IgnorePointer(
          ignoring: !visible,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 120),
            child: Tooltip(
              message: previous
                  ? context.l10n.blocks_previousPreview
                  : context.l10n.blocks_nextPreview,
              child: SizedBox(
                width: 24,
                height: 32,
                child: IconButton(
                  key: Key('block-gallery-${previous ? 'previous' : 'next'}'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 24,
                    height: 32,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: .57),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                    side: const BorderSide(color: Color(0x19FFFFFF)),
                  ),
                  iconSize: 20,
                  onPressed: previous ? widget.onPrevious : widget.onNext,
                  icon: Icon(
                    previous ? Icons.chevron_left : Icons.chevron_right,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return MouseRegion(
      onEnter: (_) => setState(() {
        _hover = true;
        _touch = false;
      }),
      onExit: (_) => setState(() {
        _hover = false;
        _touch = false;
      }),
      child: Listener(
        onPointerDown: (event) {
          if (event.kind == PointerDeviceKind.touch && !_touch) {
            setState(() => _touch = true);
          }
        },
        child: FocusableActionDetector(
          onShowFocusHighlight: (value) => setState(() => _keyboard = value),
          child: CallbackShortcuts(
            bindings: {
              if (widget.onPrevious != null)
                const SingleActivator(LogicalKeyboardKey.arrowLeft):
                    widget.onPrevious!,
              if (widget.onNext != null)
                const SingleActivator(LogicalKeyboardKey.arrowRight):
                    widget.onNext!,
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.child,
                if (widget.onPrevious != null) arrow(true),
                if (widget.onNext != null) arrow(false),
                if (widget.counter != null)
                  Positioned(
                    top: 8,
                    right: 9,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .56),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          widget.counter!,
                          style: UiText.sans(10, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BlockThumbnailStrip extends StatefulWidget {
  const BlockThumbnailStrip({
    super.key,
    required this.images,
    required this.selected,
    required this.onSelected,
    this.onAdd,
    this.compact = false,
  });
  final List<BlockThumb> images;
  final int selected;
  final ValueChanged<int> onSelected;
  final VoidCallback? onAdd;
  final bool compact;

  @override
  State<BlockThumbnailStrip> createState() => _BlockThumbnailStripState();
}

class _BlockThumbnailStripState extends State<BlockThumbnailStrip> {
  final _scroll = ScrollController();
  bool _left = false;
  bool _right = false;
  double get _size => widget.compact ? 38 : 44;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_edges);
    _reveal();
  }

  @override
  void didUpdateWidget(BlockThumbnailStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected ||
        widget.images.length != oldWidget.images.length) {
      _reveal();
    }
  }

  void _edges() {
    if (!_scroll.hasClients) return;
    final left = _scroll.offset > 2;
    final right = _scroll.offset < _scroll.position.maxScrollExtent - 2;
    if (mounted && (left != _left || right != _right)) {
      setState(() {
        _left = left;
        _right = right;
      });
    }
  }

  void _reveal() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || !_scroll.hasClients) return;
    final position = _scroll.position;
    final target =
        (widget.selected * (_size + 7) -
                (position.viewportDimension - _size) / 2 +
                3)
            .clamp(0.0, position.maxScrollExtent);
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
    _edges();
  });

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget fade(bool left) => Positioned(
      left: left ? 0 : null,
      right: left ? null : 0,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          key: Key('block-thumbnails-fade-${left ? 'left' : 'right'}'),
          width: 25,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: left ? Alignment.centerRight : Alignment.centerLeft,
              end: left ? Alignment.centerLeft : Alignment.centerRight,
              colors: [c.panel.withValues(alpha: 0), c.panel],
            ),
          ),
        ),
      ),
    );
    return SizedBox(
      height: _size + 6,
      child: Row(
        spacing: 9,
        children: [
          Expanded(
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (_) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _edges();
                });
                return false;
              },
              child: Listener(
                onPointerSignal: (event) {
                  if (event is! PointerScrollEvent ||
                      !_scroll.hasClients ||
                      _scroll.position.maxScrollExtent <= 0) {
                    return;
                  }
                  GestureBinding.instance.pointerSignalResolver.register(
                    event,
                    (_) {
                      final delta =
                          event.scrollDelta.dx.abs() >
                              event.scrollDelta.dy.abs()
                          ? event.scrollDelta.dx
                          : event.scrollDelta.dy;
                      _scroll.jumpTo(
                        (_scroll.offset + delta).clamp(
                          0.0,
                          _scroll.position.maxScrollExtent,
                        ),
                      );
                    },
                  );
                },
                child: Stack(
                  children: [
                    ListView.separated(
                      key: const Key('block-thumbnail-scroll'),
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(3),
                      itemCount: widget.images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 7),
                      itemBuilder: (context, index) {
                        final thumb = widget.images[index];
                        final selected = widget.selected == index;
                        return Tooltip(
                          message: context.l10n.blocks_previewNumber(index + 1),
                          child: Semantics(
                            selected: selected,
                            button: true,
                            label: context.l10n.blocks_previewNumber(index + 1),
                            child: UiPressable(
                              key: Key('block-thumbnail-$index'),
                              onTap: () => widget.onSelected(index),
                              builder: (context, hover) => Container(
                                width: _size,
                                foregroundDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: selected ? c.accent : c.line,
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Opacity(
                                    opacity: selected || hover ? 1 : .74,
                                    child: UiCroppedImage(
                                      image: blockThumbnailProvider(
                                        thumb,
                                        _size,
                                        MediaQuery.devicePixelRatioOf(context),
                                      ),
                                      offsetX: thumb.offsetX,
                                      offsetY: thumb.offsetY,
                                      scale: thumb.scale,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_left) fade(true),
                    if (_right) fade(false),
                  ],
                ),
              ),
            ),
          ),
          if (widget.onAdd != null)
            SizedBox(
              width: 38,
              height: 44,
              child: Tooltip(
                message: context.l10n.blocks_addThumb,
                child: OutlinedButton(
                  key: const Key('block-edit-add-thumbnails'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                    foregroundColor: c.muted,
                  ),
                  onPressed: widget.onAdd,
                  child: const Icon(Icons.add, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The same carousel is used in hover cards and the library inspector.
class BlockImageGallery extends StatefulWidget {
  const BlockImageGallery({
    super.key,
    required this.images,
    required this.height,
    this.overlay,
    this.borderRadius = const BorderRadius.all(Radius.circular(9)),
  });
  final List<BlockThumb> images;
  final double height;
  final Widget? overlay;
  final BorderRadius borderRadius;

  @override
  State<BlockImageGallery> createState() => _BlockImageGalleryState();
}

class _BlockImageGalleryState extends State<BlockImageGallery> {
  int _index = 0;
  @override
  void didUpdateWidget(BlockImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.images.elementAtOrNull(_index)?.image;
    final retained = widget.images.indexWhere(
      (image) => image.image == previous,
    );
    _index = retained >= 0
        ? retained
        : math.min(_index, math.max(0, widget.images.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();
    final image = widget.images[_index];
    final multiple = widget.images.length > 1;
    void move(int delta) => setState(
      () => _index =
          (_index + delta + widget.images.length) % widget.images.length,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          key: const Key('block-gallery-viewport'),
          height: widget.height,
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: BlockGalleryFrame(
              counter: multiple
                  ? '${_index + 1} / ${widget.images.length}'
                  : null,
              onPrevious: multiple ? () => move(-1) : null,
              onNext: multiple ? () => move(1) : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  UiCroppedImage(
                    image: image.image,
                    offsetX: image.offsetX,
                    offsetY: image.offsetY,
                    scale: image.scale,
                  ),
                  if (widget.overlay != null) widget.overlay!,
                ],
              ),
            ),
          ),
        ),
        if (multiple)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
            child: BlockThumbnailStrip(
              images: widget.images,
              selected: _index,
              compact: true,
              onSelected: (index) => setState(() => _index = index),
            ),
          ),
      ],
    );
  }
}
