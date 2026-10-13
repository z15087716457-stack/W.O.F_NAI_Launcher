import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'viewer_contract.dart';
import 'viewer_filmstrip.dart';
import 'viewer_format.dart';
import 'viewer_page.dart';
import 'viewer_parts.dart';
import 'viewer_zoom.dart';

/// 黑底舞台：顶栏 61 · 大图（左右箭头、小地图、提示） · 胶片条 82。
/// [fullscreen] 时只剩大图，右上角一个角标，鼠标移到底部浮出胶片条。
class ViewerStage extends StatelessWidget {
  const ViewerStage({super.key, this.fullscreen = false});
  final bool fullscreen;

  static const topHeight = 61.0;

  @override
  Widget build(BuildContext context) {
    if (!fullscreen) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ViewerTopBar(),
          Expanded(child: _View()),
          ViewerFilmstrip(),
        ],
      );
    }
    final ctrl = ViewerPageScope.of(context).controller;
    return Stack(
      children: [
        const Positioned.fill(child: _View(fullscreen: true)),
        if (ctrl.chromeVisible) ...[
          const Positioned(right: 16, top: 14, child: _FullscreenBadge()),
          if (!ctrl.filmstripPeek)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Center(child: _FullscreenHint()),
            ),
        ],
        if (ctrl.filmstripPeek)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ColoredBox(
              color: Color(0xCC000000),
              child: ViewerFilmstrip(),
            ),
          ),
      ],
    );
  }
}

/// 顶栏：返回（Esc）· 位置 / 范围 —— 缩放 · 1:1 · 全屏 · 信息栏。
/// 信息栏不在右边时（收起 / 窄窗口）窗口按钮落在这里，让出位置。
class ViewerTopBar extends StatelessWidget {
  const ViewerTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scope = ViewerPageScope.of(context);
    final data = scope.data;
    final ctrl = scope.controller;
    final gen = data.mode == ViewerMode.generation;
    final reserve = ctrl.narrow || !data.infoOpen;
    final chrome = WindowChromeScope.activeOf(context);
    final item = data.current;

    final Widget where;
    if (gen) {
      final saved = item?.saved ?? false;
      where = Row(
        spacing: 8,
        children: [
          UiMini(
            saved ? l10n.imageViewer_saved : l10n.imageViewer_unsaved,
            background: saved ? const Color(0xFF10301F) : ViewerInk.amberBg,
            foreground: saved ? const Color(0xFF3DD68C) : ViewerInk.amber,
          ),
          Flexible(
            child: Text(
              l10n.imageViewer_batch(data.items.length),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(13, color: const Color(0xFFDDDDDD)),
            ),
          ),
        ],
      );
    } else {
      final s = data.scope;
      final scopeText = [
        s?.name ?? l10n.imageViewer_scopeAll,
        if (s?.sort != null) viewerSortLabel(l10n, s!.sort!),
      ].join(' · ');
      where = Row(
        children: [
          Text.rich(
            key: const Key('viewer-position'),
            TextSpan(
              children: [
                TextSpan(
                  text: viewerNumber(context, data.position + 1),
                  style: const TextStyle(color: ViewerInk.strong),
                ),
                TextSpan(text: ' / ${viewerNumber(context, data.total)}'),
              ],
            ),
            style: UiText.mono(
              12.5,
              weight: FontWeight.w500,
              color: const Color(0xFFBDBDBD),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              scopeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12, color: ViewerInk.faint),
            ),
          ),
        ],
      );
    }

    return WindowHeader(
      key: const Key('viewer-topbar'),
      enabled: reserve,
      minimumInlineWidth: 0,
      inlineDragWidth: 12,
      dragBackground: true,
      decoration: const BoxDecoration(color: ViewerInk.stage),
      child: Container(
        height: ViewerStage.topHeight,
        padding: EdgeInsets.only(left: 10, right: reserve && chrome ? 0 : 12),
        child: Row(
          spacing: 8,
          children: [
            ViewerDarkButton(
              key: const Key('viewer-back'),
              onTap: () => scope.actions.onClose(keyboard: false),
              children: [
                const UiGlyph(
                  UiGlyphs.arrowLeft,
                  size: 15,
                  color: ViewerInk.text,
                ),
                Text(
                  data.backLabel ??
                      (gen
                          ? l10n.imageViewer_backGeneration
                          : l10n.imageViewer_backGallery),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: ViewerKeycap('Esc'),
                ),
              ],
            ),
            const ViewerDarkSep(margin: 6),
            Expanded(child: where),
            const _ZoomControl(),
            ListenableBuilder(
              listenable: ctrl.zoom,
              builder: (context, _) => ViewerDarkIcon(
                key: const Key('viewer-actual'),
                tooltip: l10n.imageViewer_actualSize,
                label: '1:1',
                on: !ctrl.zoom.fitted && (ctrl.zoom.scale - 1).abs() < 1e-6,
                onTap: () => ctrl.run(ViewerCommand.zoomActual),
              ),
            ),
            const ViewerDarkSep(),
            ViewerDarkIcon(
              key: const Key('viewer-fullscreen'),
              tooltip: l10n.imageViewer_fullscreen,
              glyph: _G.full,
              onTap: () => ctrl.run(ViewerCommand.fullscreen),
            ),
            ViewerDarkIcon(
              key: const Key('viewer-info-toggle'),
              tooltip: l10n.imageViewer_infoPanel,
              glyph: UiGlyphs.panel,
              on: ctrl.infoVisible,
              onTap: ctrl.toggleInfo,
            ),
          ],
        ),
      ),
    );
  }
}

/// 缩放：− │ 适应 · 68% ▾ │ +（点中间选比例）。
class _ZoomControl extends StatelessWidget {
  const _ZoomControl();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scope = ViewerPageScope.of(context);
    final ctrl = scope.controller;
    final item = scope.data.current;
    final ready = item != null && item.image != null && !item.missing;
    return ListenableBuilder(
      listenable: ctrl.zoom,
      builder: (context, _) {
        final z = ctrl.zoom;
        final pct = (z.scale * 100).round();
        final label = !ready
            ? l10n.imageViewer_zoomFitPending
            : z.fitted
            ? l10n.imageViewer_zoomFit(pct)
            : '$pct%';
        Widget side(String glyph, String tip, ViewerCommand cmd, Key key) =>
            Tooltip(
              message: tip,
              child: UiPressable(
                key: key,
                onTap: ready ? () => ctrl.run(cmd) : null,
                builder: (context, hover) => Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  color: hover ? ViewerInk.fill : null,
                  child: UiGlyph(
                    glyph,
                    size: 14,
                    color: const Color(0xFFCFCFCF),
                  ),
                ),
              ),
            );
        return Container(
          key: const Key('viewer-zoom'),
          height: 30,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0x12FFFFFF),
            border: Border.all(color: ViewerInk.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              side(
                UiGlyphs.minus,
                l10n.imageViewer_zoomOut,
                ViewerCommand.zoomOut,
                const Key('viewer-zoom-out'),
              ),
              Builder(
                builder: (bctx) => UiPressable(
                  key: const Key('viewer-zoom-menu'),
                  onTap: ready
                      ? () {
                          final box = bctx.findRenderObject()! as RenderBox;
                          ctrl.openZoomMenu(
                            UiPopoverAnchor(
                              box.localToGlobal(
                                box.size.bottomCenter(const Offset(-80, 6)),
                              ),
                            ),
                          );
                        }
                      : null,
                  builder: (context, hover) => Container(
                    height: 28,
                    constraints: const BoxConstraints(minWidth: 74),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: hover ? ViewerInk.fill : null,
                      border: const Border.symmetric(
                        vertical: BorderSide(color: ViewerInk.border),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          label,
                          style: UiText.mono(
                            12,
                            weight: FontWeight.w500,
                            color: ViewerInk.strong,
                          ),
                        ),
                        const Opacity(
                          opacity: .6,
                          child: UiGlyph(
                            UiGlyphs.chevronDown,
                            size: 12,
                            color: ViewerInk.strong,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              side(
                UiGlyphs.plus,
                l10n.imageViewer_zoomIn,
                ViewerCommand.zoomIn,
                const Key('viewer-zoom-in'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 原型图标（mock.html 的 `P`）里 kit 还没有的。
abstract final class _G {
  static const full = 'M4 9V4h5M15 4h5v5M20 15v5h-5M9 20H4v-5';
  static const hand =
      'M8 13V6a1.5 1.5 0 013 0v5M11 11V4.5a1.5 1.5 0 013 0V11M14 11V6a1.5 1.5 0 013 0v7c0 4-2.5 7-6 7-2.5 0-4-1.5-5.5-4L4 13.2a1.6 1.6 0 012.6-1.8L8 13';
  static const undo = 'M9 14L4 9l5-5M4 9h10a6 6 0 010 12h-3';
  static const trash = 'M5 7h14M10 7V4h4v3M7 7l1 13h8l1-13';
}

/// 大图区：适应时居中画在留白区里（左右各 72 给箭头，窄窗口 56，全屏 20），小图按原尺寸不放大；
/// 放大后铺满整块、可拖动。
class _View extends StatefulWidget {
  const _View({this.fullscreen = false});
  final bool fullscreen;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  Offset? _tapAt;
  var _dragging = false;

  @override
  Widget build(BuildContext context) {
    final scope = ViewerPageScope.of(context);
    final data = scope.data;
    final ctrl = scope.controller;
    final item = data.current;
    if (item == null) return const SizedBox.expand();
    final pad = widget.fullscreen
        ? const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
        : EdgeInsets.fromLTRB(
            ctrl.narrow ? 56 : 72,
            8,
            ctrl.narrow ? 56 : 72,
            14,
          );
    final index = data.items.indexWhere((e) => e.key == item.key);
    final gen = data.mode == ViewerMode.generation;
    final canPrev = gen ? index > 0 : data.position > 0;
    final canNext = gen
        ? index < data.items.length - 1
        : data.position < data.total - 1;
    final showChrome = !widget.fullscreen || ctrl.chromeVisible;

    return LayoutBuilder(
      builder: (context, box) {
        final view = box.biggest;
        final area = pad.deflateSize(view);
        final img = Size(item.width.toDouble(), item.height.toDouble());
        // 适应：缩小到放得下，但不放大小图（放大会糊；要看细节自己缩放）。
        final fit = math.max(
          .01,
          math.min(
            1.0,
            math.min(area.width / img.width, area.height / img.height),
          ),
        );
        final z = ctrl.zoom..layout(image: img, view: view, fit: fit);
        return ListenableBuilder(
          listenable: z,
          builder: (context, _) {
            final Rect rect;
            if (z.fitted) {
              final size = Size(img.width * fit, img.height * fit);
              rect = Rect.fromCenter(
                center: pad.topLeft + area.center(Offset.zero),
                width: size.width,
                height: size.height,
              );
            } else {
              rect = z.rectIn(view);
            }
            return Listener(
              onPointerSignal: (e) {
                if (e is PointerScrollEvent && !item.missing) {
                  z.zoomBy(
                    e.scrollDelta.dy < 0 ? 1.15 : 1 / 1.15,
                    focal: e.localPosition,
                  );
                }
              },
              child: ClipRect(
                child: Stack(
                  children: [
                    // 手势只挂在图片层上：箭头、小地图、提示条的单击不用等双击判定。
                    Positioned.fill(
                      child: MouseRegion(
                        cursor: z.pannable
                            ? (_dragging
                                  ? SystemMouseCursors.grabbing
                                  : SystemMouseCursors.grab)
                            : MouseCursor.defer,
                        child: GestureDetector(
                          key: const Key('viewer-view'),
                          behavior: HitTestBehavior.opaque,
                          onDoubleTapDown: (d) => _tapAt = d.localPosition,
                          onDoubleTap: item.missing
                              ? null
                              : () => z.toggle(focal: _tapAt),
                          onPanStart: (_) => setState(() => _dragging = true),
                          onPanUpdate: (d) => z.panBy(d.delta),
                          onPanEnd: (_) => setState(() => _dragging = false),
                          child: Stack(
                            children: [
                              if (!item.missing)
                                Positioned.fromRect(
                                  rect: rect,
                                  child: _Picture(
                                    item: item,
                                    rounded: z.fitted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (item.missing)
                      Positioned.fill(child: _Missing(item: item)),
                    // 放大到能拖动时收起左右箭头（同原型）：箭头压在图上还会和拖动抢手势，翻页用方向键。
                    if (showChrome && canPrev && !z.pannable)
                      _Arrow(
                        left: true,
                        onTap: () => ctrl.run(ViewerCommand.previous),
                      ),
                    if (showChrome && canNext && !z.pannable)
                      _Arrow(
                        left: false,
                        onTap: () => ctrl.run(ViewerCommand.next),
                      ),
                    if (z.pannable && item.thumb != null)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: _Minimap(item: item, zoom: z),
                      ),
                    if (ctrl.zoomHint && !z.fitted)
                      const Positioned(
                        left: 0,
                        right: 0,
                        top: 14,
                        child: Center(child: _ZoomHint()),
                      ),
                    if (data.undo != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 20,
                        child: Center(child: _UndoToast(undo: data.undo!)),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 原图：读完之前用缩略图模糊垫底 + “读取原图”小条，读完淡入。
class _Picture extends StatelessWidget {
  const _Picture({required this.item, required this.rounded});
  final ViewerItem item;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Loading(item: item);
    final image = item.image;
    final Widget child = image == null
        ? placeholder
        : Image(
            key: const Key('viewer-image'),
            image: image,
            fit: BoxFit.fill,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            frameBuilder: (context, child, frame, sync) =>
                frame == null && !sync ? placeholder : child,
            errorBuilder: (_, _, _) => placeholder,
          );
    return rounded
        ? ClipRRect(borderRadius: BorderRadius.circular(3), child: child)
        : child;
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.item});
  final ViewerItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = item.sizeBytes == null
        ? l10n.imageViewer_loadingOriginal
        : l10n.imageViewer_loadingOriginalSize(viewerBytes(item.sizeBytes!));
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 120;
        return Stack(
          key: const Key('viewer-loading'),
          fit: StackFit.expand,
          children: [
            if (item.thumb != null)
              ImageFiltered(
                imageFilter: const ColorFilter.mode(
                  Color(0x40000000),
                  BlendMode.srcATop,
                ),
                child: ImageFiltered(
                  imageFilter: _blur,
                  child: Image(
                    image: item.thumb!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: box.maxHeight < 64 ? (box.maxHeight - 32) / 2 : 16,
              child: Center(
                child: Tooltip(
                  message: message,
                  child: Semantics(
                    label: compact ? message : null,
                    liveRegion: true,
                    child: ViewerGlass(
                      height: 32,
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 2 : 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          const _WhiteSpinner(),
                          if (!compact)
                            Flexible(
                              child: Text(
                                message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: UiText.sans(
                                  12,
                                  color: const Color(0xFFCCCCCC),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

final _blur = ui.ImageFilter.blur(
  sigmaX: 14,
  sigmaY: 14,
  tileMode: TileMode.decal,
);

class _WhiteSpinner extends StatelessWidget {
  const _WhiteSpinner();

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: Colors.white,
        outline: const Color(0xFF555555),
      ),
    ),
    child: const UiSpinner(),
  );
}

class _Missing extends StatelessWidget {
  const _Missing({required this.item});
  final ViewerItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scope = ViewerPageScope.of(context);
    final can = scope.data.actions.contains(ViewerAction.showInFolder);
    return Center(
      child: Column(
        key: const Key('viewer-missing'),
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          const UiGlyph(
            UiGlyphs.picture,
            size: 44,
            strokeWidth: 1.3,
            color: Color(0x66FFFFFF),
          ),
          Text(
            l10n.imageViewer_missingTitle,
            style: UiText.sans(
              15,
              weight: FontWeight.w700,
              color: ViewerInk.text,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              [?item.path, l10n.imageViewer_missingHint].join('\n'),
              textAlign: TextAlign.center,
              style: UiText.sans(
                12,
                color: const Color(0x8CFFFFFF),
                height: 1.7,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                if (can)
                  ViewerDarkButton(
                    key: const Key('viewer-missing-folder'),
                    onTap: () => scope.actions.onAction(
                      item.key,
                      ViewerAction.showInFolder,
                    ),
                    children: [
                      const UiGlyph(
                        UiGlyphs.folder,
                        size: 14,
                        color: ViewerInk.text,
                      ),
                      Text(l10n.imageViewer_openFolder),
                    ],
                  ),
                ViewerDarkButton(
                  key: const Key('viewer-missing-next'),
                  onTap: () => scope.controller.run(ViewerCommand.next),
                  children: [
                    const UiGlyph(
                      UiGlyphs.chevronRight,
                      size: 14,
                      color: ViewerInk.text,
                    ),
                    Text(l10n.imageViewer_nextImage),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.left, required this.onTap});
  final bool left;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Positioned(
      left: left ? 16 : null,
      right: left ? null : 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: Tooltip(
          message: left ? l10n.imageViewer_previous : l10n.imageViewer_next,
          child: UiPressable(
            key: Key(left ? 'viewer-prev' : 'viewer-next'),
            onTap: onTap,
            builder: (context, hover) => Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              // 深色半透明底 + 细白边：压在黑底和亮图上都看得见（原型只有 8% 白底，压在亮图上会消失）。
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: hover ? .55 : .32),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .14)),
              ),
              child: UiGlyph(
                left ? UiGlyphs.chevronLeft : UiGlyphs.chevronRight,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 小地图：缩略图 + 白框（当前视野，框外压暗），拖框或点一下移动视野。
class _Minimap extends StatelessWidget {
  const _Minimap({required this.item, required this.zoom});
  final ViewerItem item;
  final ViewerZoom zoom;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = item.aspect;
    final w = a >= 170 / 120 ? 170.0 : 120 * a;
    final h = w / a;
    final v = zoom.visible;
    return ViewerGlass(
      key: const Key('viewer-minimap'),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          GestureDetector(
            onTapDown: (d) => zoom.moveCenter(
              Offset(d.localPosition.dx / w, d.localPosition.dy / h) -
                  zoom.center,
            ),
            onPanUpdate: (d) =>
                zoom.moveCenter(Offset(d.delta.dx / w, d.delta.dy / h)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                width: w,
                height: h,
                child: CustomPaint(
                  foregroundPainter: _FramePainter(
                    Rect.fromLTRB(
                      v.left * w,
                      v.top * h,
                      v.right * w,
                      v.bottom * h,
                    ),
                  ),
                  child: Image(
                    image: item.thumb!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: w,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Text(
                  '${(zoom.scale * 100).round()}%',
                  style: UiText.mono(11, color: ViewerInk.strong),
                ),
                const Spacer(),
                Text(
                  l10n.imageViewer_dragFrame,
                  style: UiText.sans(11, color: const Color(0xFFAAAAAA)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter(this.frame);
  final Rect frame;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(3)));
    canvas.drawPath(dim, Paint()..color = const Color(0x73000000));
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame.deflate(1), const Radius.circular(3)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.frame != frame;
}

/// 第一次放大时的操作提示（几秒后消失，看过不再出）。
class _ZoomHint extends StatelessWidget {
  const _ZoomHint();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final keys = ViewerPageScope.of(context).data.keys;
    String key(ViewerCommand c, String fallback) {
      final a = keys[c]?.firstOrNull ?? ViewerKeys.defaults[c]?.firstOrNull;
      return a == null ? fallback : viewerKeyLabels(a).join(' ');
    }

    return ViewerGlass(
      key: const Key('viewer-zoom-hint'),
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DefaultTextStyle.merge(
        style: UiText.sans(12, color: const Color(0xFFBBBBBB)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            const UiGlyph(_G.hand, size: 15, color: Color(0xFFBBBBBB)),
            Text(l10n.imageViewer_hintPan),
            const ViewerDarkSep(margin: 0),
            Text(l10n.imageViewer_hintWheel),
            const ViewerDarkSep(margin: 0),
            Text(l10n.imageViewer_hintDouble),
            ViewerKeycap(key(ViewerCommand.zoomFit, '0')),
            Text(l10n.imageViewer_hintFit),
            const ViewerDarkSep(margin: 0),
            ViewerKeycap(key(ViewerCommand.zoomActual, '1')),
            Text(l10n.imageViewer_hintActual),
          ],
        ),
      ),
    );
  }
}

/// 删除后的提示条：已移到回收站 · 文件名 · 撤销（Ctrl Z）。
class _UndoToast extends StatelessWidget {
  const _UndoToast({required this.undo});
  final ViewerUndo undo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scope = ViewerPageScope.of(context);
    final keys =
        scope.data.keys[ViewerCommand.undo]?.firstOrNull ??
        ViewerKeys.defaults[ViewerCommand.undo]!.first;
    return Container(
      key: const Key('viewer-undo'),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: ViewerInk.toast,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          const UiGlyph(_G.trash, size: 15, color: ViewerInk.toastInk),
          Text(
            l10n.imageViewer_movedToTrash,
            style: UiText.sans(13, color: ViewerInk.toastInk),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              _middle(undo.fileName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12, color: ViewerInk.toastMuted),
            ),
          ),
          UiPressable(
            key: const Key('viewer-undo-button'),
            onTap: scope.actions.onUndoDelete,
            builder: (context, hover) => Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: hover ? const Color(0xFFE6E6E6) : Colors.white,
                border: Border.all(color: ViewerInk.toastBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  const UiGlyph(_G.undo, size: 13, color: ViewerInk.toastInk),
                  Text(
                    l10n.imageViewer_undo,
                    style: UiText.sans(
                      12,
                      weight: FontWeight.w500,
                      color: ViewerInk.toastInk,
                    ),
                  ),
                  _LightKey(viewerKeyLabels(keys).join(' ')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 长文件名中间省略，保留扩展名：“A50F2026-08-28-1812…png”。
String _middle(String s) =>
    s.length <= 26 ? s : '${s.substring(0, 19)}…${s.substring(s.length - 3)}';

class _LightKey extends StatelessWidget {
  const _LightKey(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: Color(0xFFE6E6E6));
    return Container(
      height: 18,
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          top: side,
          left: side,
          right: side,
          bottom: side.copyWith(width: 2),
        ),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: UiText.mono(
            10.5,
            weight: FontWeight.w500,
            height: 1,
            color: const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

/// 全屏角标：位置 │ I 信息 │ F11 退出全屏。
class _FullscreenBadge extends StatelessWidget {
  const _FullscreenBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scope = ViewerPageScope.of(context);
    final data = scope.data;
    final keys = {...ViewerKeys.defaults, ...data.keys};
    List<String> k(ViewerCommand c) => viewerKeyLabels(keys[c]!.first);
    Widget link(ViewerCommand c, String label, Key key) => UiPressable(
      key: key,
      onTap: () => scope.controller.run(c),
      builder: (context, hover) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          ViewerKeycaps(k(c)),
          Text(
            label,
            style: UiText.sans(
              12,
              color: hover ? ViewerInk.strong : const Color(0xFFBBBBBB),
            ),
          ),
        ],
      ),
    );
    final gen = data.mode == ViewerMode.generation;
    final index = data.items.indexWhere((e) => e.key == data.currentKey);
    return ViewerGlass(
      key: const Key('viewer-fullscreen-badge'),
      height: 34,
      padding: const EdgeInsets.only(left: 12, right: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: viewerNumber(
                    context,
                    gen ? index + 1 : data.position + 1,
                  ),
                  style: const TextStyle(color: ViewerInk.strong),
                ),
                TextSpan(
                  text:
                      ' / ${viewerNumber(context, gen ? data.items.length : data.total)}',
                ),
              ],
            ),
            style: UiText.mono(
              12.5,
              weight: FontWeight.w500,
              color: const Color(0xFFBDBDBD),
            ),
          ),
          const ViewerDarkSep(margin: 0),
          link(
            ViewerCommand.toggleInfo,
            l10n.imageViewer_infoShort,
            const Key('viewer-fullscreen-info'),
          ),
          const ViewerDarkSep(margin: 0),
          link(
            ViewerCommand.fullscreen,
            l10n.imageViewer_exitFullscreen,
            const Key('viewer-fullscreen-exit'),
          ),
        ],
      ),
    );
  }
}

class _FullscreenHint extends StatelessWidget {
  const _FullscreenHint();

  @override
  Widget build(BuildContext context) => ViewerGlass(
    height: 30,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Center(
      widthFactor: 1,
      child: Text(
        context.l10n.imageViewer_fullscreenHint,
        style: UiText.sans(12, color: const Color(0xFF888888)),
      ),
    ),
  );
}
