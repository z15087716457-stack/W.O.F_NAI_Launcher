import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../kit/ui_block_pill.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_inputs.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_resource_kind.dart';
import '../kit/ui_text.dart';
import '../refs/refs_format.dart';
import '../refs/refs_parts.dart';
import 'resource_window_contract.dart';

/// 点击 / 双击：单击立刻选中，第二下在系统双击间隔与距离内算双击（同本地画廊卡片），
/// 不等双击超时，也不和原生拖动手势抢。
class ResourceTapRegion extends StatefulWidget {
  const ResourceTapRegion({
    super.key,
    required this.onTap,
    required this.onDouble,
    required this.child,
  });
  final VoidCallback onTap, onDouble;
  final Widget child;

  @override
  State<ResourceTapRegion> createState() => _ResourceTapRegionState();
}

class _ResourceTapRegionState extends State<ResourceTapRegion> {
  DateTime? _last;
  Offset? _lastAt;

  void _up(TapUpDetails d) {
    final now = DateTime.now();
    final isDouble =
        _last != null &&
        _lastAt != null &&
        now.difference(_last!) <= kDoubleTapTimeout &&
        (d.globalPosition - _lastAt!).distance <= kDoubleTapSlop;
    widget.onTap();
    if (isDouble) {
      _last = null;
      _lastAt = null;
      widget.onDouble();
    } else {
      _last = now;
      _lastAt = d.globalPosition;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapUp: _up,
    child: widget.child,
  );
}

// ── 图库：本地画廊卡片同款（圆角 6、悬停底部渐变 + 磨砂版本标签与按钮、选中双描边） ──

class ResourceGalleryCard extends StatefulWidget {
  const ResourceGalleryCard({
    super.key,
    required this.item,
    required this.width,
    required this.height,
    required this.selected,
    required this.onTap,
    required this.onDouble,
    required this.onFavorite,
    required this.onAction,
    this.libraryReadOnly = false,
  });
  final ResourceItem item;
  final double width, height;
  final bool selected;
  final VoidCallback onTap, onDouble, onFavorite;
  final ValueChanged<String> onAction;
  final bool libraryReadOnly;

  static const radius = 6.0;

  @override
  State<ResourceGalleryCard> createState() => _ResourceGalleryCardState();
}

class _ResourceGalleryCardState extends State<ResourceGalleryCard> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final it = widget.item;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 140);
    final compact = widget.width < 150;
    final image = ResourceTapRegion(
      onTap: widget.onTap,
      onDouble: widget.onDouble,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: c.control),
          if (it.thumb != null)
            Image(
              image: it.thumb!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 24,
                  color: c.muted,
                ),
              ),
            ),
          if (it.favorite && !_hover)
            const Positioned(
              top: 8,
              right: 8,
              child: IgnorePointer(
                child: Icon(
                  StudioIcons.galleryHeartFilled,
                  size: 16,
                  color: Colors.white,
                  shadows: [Shadow(color: Color(0x8C000000), blurRadius: 3)],
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 64,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _hover ? 1 : 0,
                duration: duration,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x9E000000)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.selected)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  key: const Key('rw-card-highlight'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      ResourceGalleryCard.radius,
                    ),
                    border: Border.all(color: c.accent, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          ResourceGalleryCard.radius - 2,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .85),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ResourceGalleryCard.radius),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              image,
              if (_hover)
                Positioned(
                  left: 10,
                  right: 8,
                  bottom: 8,
                  child: Row(
                    children: [
                      if (it.badge != null && !compact)
                        Flexible(
                          flex: 0,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _Frosted(
                              radius: 4,
                              opacity: .2,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                child: Text(
                                  it.badge!,
                                  key: Key('rw-badge-${it.id}'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: UiText.sans(
                                    11,
                                    weight: FontWeight.w500,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: it.meta != null && widget.width >= 190
                            ? Text(
                                it.meta!,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: UiText.sans(
                                  11.5,
                                  color: Colors.white.withValues(alpha: .92),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (!widget.libraryReadOnly)
                        _HoverAction(
                          key: Key('rw-fav-${it.id}'),
                          icon: it.favorite
                              ? StudioIcons.galleryHeartFilled
                              : StudioIcons.galleryHeart,
                          tooltip: l.common_favorite,
                          onTap: widget.onFavorite,
                        ),
                      if (!widget.libraryReadOnly && !compact)
                        _HoverAction(
                          icon: StudioIcons.galleryCopy,
                          tooltip: l.common_copy,
                          onTap: () => widget.onAction('copy'),
                        ),
                      if (!widget.libraryReadOnly)
                        _HoverAction(
                          key: Key('rw-reuse-${it.id}'),
                          icon: StudioIcons.gallerySend,
                          tooltip: l.imageViewer_reuse,
                          onTap: () => widget.onAction('reuse'),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverAction extends StatelessWidget {
  const _HoverAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2),
    child: Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _Frosted(
          radius: 5,
          opacity: .16,
          child: SizedBox(
            width: 26,
            height: 26,
            child: Icon(icon, size: 14, color: Colors.white),
          ),
        ),
      ),
    ),
  );
}

class _Frosted extends StatelessWidget {
  const _Frosted({
    required this.radius,
    required this.opacity,
    required this.child,
  });
  final double radius, opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: r,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── 块：块库卡片同款（封面 + 标题行 + 项数 · 使用次数 + 负面 / 参数小标） ──

class ResourceBlockCard extends StatefulWidget {
  const ResourceBlockCard({
    super.key,
    required this.item,
    required this.width,
    required this.coverH,
    required this.selected,
    required this.onTap,
    required this.onDouble,
    required this.onFavorite,
    required this.onAction,
  });
  final ResourceItem item;
  final double width;

  /// 方格：固定封面高；null = 瀑布流（有图按原图比例，无图文字自然高）。
  final double? coverH;
  final bool selected;
  final VoidCallback onTap, onDouble, onFavorite;
  final ValueChanged<String> onAction;

  /// 标题区高度（方格的 `mainAxisExtent = coverH + titleH`）。
  static const titleH = 58.0;

  @override
  State<ResourceBlockCard> createState() => _ResourceBlockCardState();
}

class _ResourceBlockCardState extends State<ResourceBlockCard> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final b = widget.item;
    final color = b.color ?? c.accent;
    Widget hoverBtn(
      String glyph,
      String tip,
      VoidCallback onTap, {
      String? label,
      Key? key,
      bool filled = false,
      Color? tint,
    }) => UiPressable(
      key: key,
      onTap: onTap,
      builder: (context, h) => Tooltip(
        message: tip,
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: h ? Colors.white.withValues(alpha: .16) : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              UiGlyph(
                glyph,
                size: 14,
                filled: filled,
                color: tint ?? Colors.white,
              ),
              if (label != null)
                Text(
                  label,
                  style: UiText.sans(12, color: Colors.white, height: 1.2),
                ),
            ],
          ),
        ),
      ),
    );

    final Widget coverContent;
    if (b.thumb != null) {
      final crop = b.crop ?? const ResourceThumbCrop();
      coverContent = widget.coverH != null
          ? UiCroppedImage(
              image: b.thumb!,
              offsetX: crop.offsetX,
              offsetY: crop.offsetY,
              scale: crop.scale,
            )
          : _MasonryThumb(image: b.thumb!, crop: crop, width: widget.width);
    } else {
      coverContent = _TextCover(
        item: b,
        color: color,
        natural: widget.coverH == null,
      );
    }
    final cover = SizedBox(
      key: Key('rw-cover-${b.id}'),
      height: widget.coverH,
      child: Stack(
        fit: widget.coverH == null ? StackFit.loose : StackFit.expand,
        children: [
          coverContent,
          if (b.favorite)
            Positioned(
              right: 7,
              top: 7,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xEBFFFFFF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: UiGlyph(
                  UiGlyphs.star,
                  size: 13,
                  filled: true,
                  color: c.star,
                ),
              ),
            ),
          if (_hover)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xBD141414),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    hoverBtn(
                      UiGlyphs.plus,
                      l.blocks_insertToPrompt,
                      () => widget.onAction('positive'),
                      label: l.blocks_insert,
                      key: Key('rw-insert-${b.id}'),
                    ),
                    hoverBtn(
                      UiGlyphs.star,
                      b.favorite ? l.blocks_unfavorite : l.blocks_favorite,
                      widget.onFavorite,
                      key: Key('rw-fav-${b.id}'),
                      filled: b.favorite,
                      tint: b.favorite ? c.star : null,
                    ),
                    hoverBtn(
                      UiGlyphs.pencil,
                      l.blocks_edit,
                      () => widget.onAction('edit'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    final card = AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 120),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.selected ? c.accent : (_hover ? c.strong : c.line),
        ),
        boxShadow: [
          if (widget.selected)
            BoxShadow(color: c.accent.withValues(alpha: .14), spreadRadius: 3),
          if (_hover && !widget.selected)
            BoxShadow(
              color: Colors.black.withValues(alpha: c.dark ? .3 : .07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          cover,
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 3,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    UiBlockIcon(b.iconKey, size: 14, color: color),
                    Expanded(
                      child: Text(
                        b.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          13,
                          weight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 6,
                  children: [
                    Expanded(
                      child: Text(
                        [
                          if (b.itemCount != null) l.blocks_items(b.itemCount!),
                          if (b.useCount != null)
                            l.blocks_usedTimes(b.useCount!),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(11.5, color: c.faint),
                      ),
                    ),
                    if (b.negative?.isNotEmpty ?? false)
                      _Mini(l.blocks_miniNegative, negative: true),
                    if (b.hasParams) _Mini(l.blocks_miniParams),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: ResourceTapRegion(
        onTap: widget.onTap,
        onDouble: widget.onDouble,
        child: card,
      ),
    );
  }
}

/// 瀑布流封面（有预览图）：按原图比例显示整张图，比例夹在 0.5 ~ 1.6 倍宽之间；
/// 图还没解码时先按 4:3 占位（同块库）。
class _MasonryThumb extends StatefulWidget {
  const _MasonryThumb({
    required this.image,
    required this.crop,
    required this.width,
  });
  final ImageProvider image;
  final ResourceThumbCrop crop;
  final double width;

  @override
  State<_MasonryThumb> createState() => _MasonryThumbState();
}

class _MasonryThumbState extends State<_MasonryThumb> {
  static final _aspects = <ImageProvider, double>{};
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_MasonryThumb old) {
    super.didUpdateWidget(old);
    if (old.image != widget.image) _resolve();
  }

  void _resolve() {
    _stop();
    final image = widget.image;
    if (_aspects.containsKey(image)) return;
    final stream = image.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, _) {
      final i = info.image;
      if (i.width > 0 && i.height > 0 && mounted) {
        _aspects[image] = i.width / i.height;
        if (SchedulerBinding.instance.schedulerPhase !=
            SchedulerPhase.persistentCallbacks) {
          setState(() {});
        }
      }
      _stop();
    }, onError: (_, _) => _stop());
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void _stop() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aspect = _aspects[widget.image] ?? 4 / 3;
    final w = widget.width;
    final h = (w / aspect).clamp(w * .5, w * 1.6).roundToDouble();
    return SizedBox(
      height: h,
      width: double.infinity,
      child: Image(
        image: widget.image,
        fit: BoxFit.cover,
        alignment: Alignment(
          widget.crop.offsetX.clamp(-1, 1),
          widget.crop.offsetY.clamp(-1, 1),
        ),
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const SizedBox.expand(),
      ),
    );
  }
}

/// 无预览图的文字封面（块库 `BlockTextCover` / `_MasonryTextCover` 同款）。
class _TextCover extends StatelessWidget {
  const _TextCover({
    required this.item,
    required this.color,
    required this.natural,
  });
  final ResourceItem item;
  final Color color;
  final bool natural;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final text = (item.positive?.isNotEmpty ?? false)
        ? item.positive!
        : (item.negative ?? '');
    return Container(
      constraints: natural ? const BoxConstraints(minHeight: 72) : null,
      width: double.infinity,
      color: Color.alphaBlend(
        color.withValues(alpha: c.dark ? .10 : .07),
        c.raised,
      ),
      padding: EdgeInsets.fromLTRB(12, 11, 12, natural ? 12 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              text,
              maxLines: natural ? 8 : 4,
              overflow: TextOverflow.ellipsis,
              style: UiText.mono(
                11,
                height: 1.6,
                color: Color.lerp(c.muted, color, .55),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: natural ? -4 : 8,
            child: UiBlockIcon(
              item.iconKey,
              size: natural ? 34 : 46,
              color: color.withValues(alpha: natural ? .22 : .26),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.text, {this.negative = false});
  final String text;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 17,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: negative ? c.error.withValues(alpha: .09) : c.control,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: UiText.sans(
          10.5,
          weight: FontWeight.w600,
          color: negative ? c.error : c.muted,
          height: 1.2,
        ),
      ),
    );
  }
}

// ── Vibe / 精准：参考库卡片同款（4:5 图、悬停暗条、名称行 + 参数行） ──

class ResourceRefsCard extends StatefulWidget {
  const ResourceRefsCard({
    super.key,
    required this.item,
    required this.kind,
    required this.selected,
    required this.onTap,
    required this.onDouble,
    required this.onFavorite,
    required this.onAction,
  });
  final ResourceItem item;
  final FloatingResourceKind kind;
  final bool selected;
  final VoidCallback onTap, onDouble, onFavorite;
  final ValueChanged<String> onAction;

  static double heightFor(double width) => RefsLayout.cardHeight(width);

  @override
  State<ResourceRefsCard> createState() => _ResourceRefsCardState();
}

class _ResourceRefsCardState extends State<ResourceRefsCard> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final e = widget.item;
    final vibe = widget.kind == FloatingResourceKind.vibe;
    final selected = widget.selected;
    final image = AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          if (selected) ...[
            BoxShadow(color: c.accent.withValues(alpha: .16), spreadRadius: 5),
            BoxShadow(color: c.accent, spreadRadius: 2),
          ] else if (_hover)
            BoxShadow(
              color: Colors.black.withValues(alpha: c.dark ? .45 : .14),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: c.control),
            RefsImage(
              e.thumb,
              alignment: vibe ? Alignment.center : const Alignment(0, -.6),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.ink.withValues(alpha: .07)),
              ),
            ),
            if (e.inGeneration)
              const Positioned(left: 7, top: 7, child: RefsInGenBadge()),
            if (e.favorite || _hover)
              Positioned(
                right: 7,
                top: 7,
                child: RefsStarButton(
                  key: Key('rw-fav-${e.id}'),
                  on: e.favorite,
                  onTap: widget.onFavorite,
                ),
              ),
            if (e.bundleCount > 0 && !_hover)
              Positioned(
                right: 7,
                bottom: 7,
                child: RefsDarkBadge(
                  glyph: UiGlyphs.stack,
                  text: '${e.bundleCount}',
                ),
              ),
            if (_hover)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: RefsDarkBar(
                  children: [
                    RefsBarButton(
                      key: Key('rw-add-${e.id}'),
                      primary: true,
                      glyph: UiGlyphs.plus,
                      label: vibe ? l.refs_addShort : l.refs_sendPrecise,
                      onTap: () => widget.onAction('add'),
                    ),
                    const Spacer(),
                    RefsBarButton(
                      glyph: UiGlyphs.pencil,
                      tooltip: l.blocks_edit,
                      onTap: () => widget.onAction('edit'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    TextSpan pair(String label, double v) => TextSpan(
      children: [
        TextSpan(text: '$label '),
        TextSpan(
          text: RefsFormat.two(v),
          style: TextStyle(fontWeight: FontWeight.w500, color: c.muted),
        ),
      ],
    );
    final caption = SizedBox(
      height: RefsLayout.caption,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 7, 2, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 2,
          children: [
            SizedBox(
              height: 18.85,
              child: Row(
                spacing: 6,
                children: [
                  Expanded(
                    child: Text(
                      e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(
                        13,
                        weight: FontWeight.w600,
                        color: c.ink,
                        height: 1.45,
                      ),
                    ),
                  ),
                  if (e.badge != null)
                    Flexible(
                      flex: 0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 96),
                        child: UiMini(
                          e.badge!,
                          tone: switch (e.badgeTone) {
                            ResourceBadgeTone.ok => UiMiniTone.ok,
                            ResourceBadgeTone.warn => UiMiniTone.warn,
                            ResourceBadgeTone.accent => UiMiniTone.accent,
                            ResourceBadgeTone.plain => UiMiniTone.plain,
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (e.strength != null)
              SizedBox(
                height: 15.4,
                child: Text.rich(
                  TextSpan(
                    children: [
                      pair(l.refs_strengthShort, e.strength!),
                      if (e.secondary != null) ...[
                        const TextSpan(text: '  '),
                        vibe
                            ? pair(l.refs_infoShort, e.secondary!)
                            : pair(l.refs_fidelityShort, e.secondary!),
                      ],
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: UiText.mono(11, color: c.faint, height: 1.4),
                ),
              ),
          ],
        ),
      ),
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: ResourceTapRegion(
        onTap: widget.onTap,
        onDouble: widget.onDouble,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: image),
            caption,
          ],
        ),
      ),
    );
  }
}

/// 列表行（块库 / 参考列表模式；图库没有列表）。
class ResourceListRow extends StatelessWidget {
  const ResourceListRow({
    super.key,
    required this.item,
    required this.kind,
    required this.selected,
    required this.onTap,
    required this.onDouble,
    required this.onFavorite,
  });
  final ResourceItem item;
  final FloatingResourceKind kind;
  final bool selected;
  final VoidCallback onTap, onDouble, onFavorite;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final blocks = kind == FloatingResourceKind.blocks;
    final tint = item.color ?? c.accent;
    final body = blocks
        ? [
            item.positive,
            item.negative,
          ].where((s) => s?.isNotEmpty ?? false).join('  ·  − ')
        : (item.positive ?? '');
    return ResourceTapRegion(
      onTap: onTap,
      onDouble: onDouble,
      child: UiPressable(
        onTap: null,
        builder: (context, hover) => Container(
          height: 44,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? c.accent.withValues(alpha: c.dark ? .14 : .07)
                : hover
                ? c.hover
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            spacing: 10,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: blocks ? tint.withValues(alpha: .16) : c.control,
                  borderRadius: BorderRadius.circular(6),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.thumb != null
                    ? Image(
                        image: item.thumb!,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(),
                      )
                    : blocks
                    ? UiBlockIcon(item.iconKey, size: 14, color: tint)
                    : null,
              ),
              SizedBox(
                width: math.min(180, MediaQuery.sizeOf(context).width * .22),
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(13, weight: FontWeight.w500, color: c.ink),
                ),
              ),
              Expanded(
                child: Text(
                  blocks || item.strength == null
                      ? body
                      : '${l.refs_strengthShort} ${RefsFormat.two(item.strength!)}'
                            '${item.secondary == null ? '' : '  ${kind == FloatingResourceKind.vibe ? l.refs_infoShort : l.refs_fidelityShort} ${RefsFormat.two(item.secondary!)}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.mono(11.5, color: c.muted),
                ),
              ),
              if (blocks && item.itemCount != null)
                Text(
                  l.blocks_items(item.itemCount!),
                  style: UiText.sans(11.5, color: c.faint),
                ),
              if (!blocks && item.badge != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: UiMini(item.badge!),
                ),
              UiIconBox(
                key: Key('rw-fav-${item.id}'),
                glyph: UiGlyphs.star,
                size: 26,
                glyphSize: 13,
                filled: item.favorite,
                color: item.favorite ? c.star : null,
                onTap: onFavorite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
