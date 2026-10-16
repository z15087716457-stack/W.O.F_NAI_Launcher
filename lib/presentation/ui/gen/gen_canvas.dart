import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/inpaint_mask_utils.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../channel/channel_settings.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import '../kit/ui_tip.dart';
import 'gen_contract.dart';
import 'gen_format.dart';
import 'gen_page.dart';
import 'gen_parts.dart';

/// 画布：底纹 │ 图（自带舞台或接线方的画布引擎）│ 三条浮动工具条 / 空态 / 失败卡 / 定位板。
class GenCanvas extends StatefulWidget {
  const GenCanvas({super.key});

  /// 舞台留白（原型：图距顶 50、距底 70，左右至少 40）。
  static const pad = EdgeInsets.fromLTRB(40, 50, 40, 70);

  static EdgeInsets focusPadding(double width, bool hasOriginal) =>
      hasOriginal && width < 500 ? pad.copyWith(bottom: 118) : pad;

  /// 落下面板 / 放大进度条的顶边：工具条（顶 10、高 38）下面再空 12。
  static const sheetTop = 60.0;

  /// 顶部空白拖窗区略低于窗口按钮，浮动工具条保留独立点击范围。
  static const windowDragHeight = 44.0;

  @override
  State<GenCanvas> createState() => _GenCanvasState();

  static Widget _tile(
    BuildContext context,
    GenTile tile, {
    bool focused = false,
  }) => GenCanvasTile(tile: tile, focused: focused);
}

class _GenCanvasState extends State<GenCanvas> {
  final _enhanceLink = LayerLink();
  final _upscaleLink = LayerLink();
  String? _comparedId;
  String? _focusId;

  @override
  Widget build(BuildContext context) {
    final scope = GenScope.of(context);
    final cv = scope.data.canvas;
    final c = context.ui;
    final info = cv.info;
    final empty = cv.focus == null;
    final bar = info != null && !empty;
    final sheet = bar ? cv.sheet : null;
    final strip = bar && cv.upscale.running && cv.upscale.progress != null;
    if (_focusId != info?.tileId ||
        cv.locked ||
        cv.positioning ||
        !bar ||
        !info.canCompareOriginal) {
      _comparedId = null;
    }
    _focusId = info?.tileId;
    return _OriginalScope(
      tileId: _comparedId,
      onChanged: (id, active) {
        if (!mounted) return;
        if (active && (cv.locked || id != _focusId)) return;
        if (!active && _comparedId != id) return;
        setState(() => _comparedId = active ? id : null);
      },
      child: ClipRect(
        key: const Key('gen-canvas'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (scope.slots.panelBackdrop == null)
              Positioned.fill(child: CustomPaint(painter: _Ticks(c))),
            if (cv.positioning)
              const GenPositionBoard()
            else ...[
              if (scope.slots.canvas case final b?)
                b(context, GenCanvas._tile)
              else if (!empty)
                const _Stage(),
              if (empty && cv.error == null)
                if (scope.slots.emptyCanvas case final welcome?)
                  welcome(context)
                else
                  const _Empty(),
            ],
            if (!cv.positioning && WindowChromeScope.activeOf(context))
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: math.max(
                  GenCanvas.windowDragHeight,
                  WindowChromeScope.heightOf(context),
                ),
                child: const WindowDragArea(key: Key('gen-canvas-window-drag')),
              ),
            if (!cv.positioning) ...[
              if (bar) ...[
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: _CanvasBarViewport(
                    child: _TopBar(
                      enhanceLink: _enhanceLink,
                      upscaleLink: _upscaleLink,
                    ),
                  ),
                ),
                const Positioned.fill(child: _BottomBars()),
              ],
              if (strip && sheet == null)
                const Positioned(
                  top: GenCanvas.sheetTop,
                  left: 16,
                  right: 16,
                  child: Center(child: _UpscaleStrip()),
                ),
              if (sheet != null && scope.slots.toolSheet != null) ...[
                Positioned(
                  top: GenCanvas.sheetTop,
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: scope.slots.toolSheet,
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: CompositedTransformFollower(
                    link: sheet == GenToolSheet.enhance
                        ? _enhanceLink
                        : _upscaleLink,
                    showWhenUnlinked: false,
                    targetAnchor: Alignment.bottomCenter,
                    followerAnchor: Alignment.topCenter,
                    offset: const Offset(0, 9),
                    child: const IgnorePointer(
                      child: GenSheetCaret(key: Key('gen-sheet-caret')),
                    ),
                  ),
                ),
              ],
              if (cv.error case final e?)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: info != null && !empty ? 64 : 24,
                  child: Center(child: _ErrorCard(error: e)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Display-only comparison. The result identity and all image actions stay intact.
class _OriginalScope extends InheritedWidget {
  const _OriginalScope({
    required this.tileId,
    required this.onChanged,
    required super.child,
  });
  final String? tileId;
  final void Function(String id, bool active) onChanged;
  static _OriginalScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_OriginalScope>();
  @override
  bool updateShouldNotify(_OriginalScope oldWidget) =>
      tileId != oldWidget.tileId;
}

/// 画布底纹：稀疏像素刻度（原型 `bg()`：200 方一格，正文色 10%）。
class _Ticks extends CustomPainter {
  _Ticks(this.c);
  final UiColors c;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = c.bg);
    final p = Paint()
      ..color = c.ink.withValues(alpha: .10)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = c.ink.withValues(alpha: .10);
    const marks = [
      Offset(20, 30),
      Offset(130, 18),
      Offset(80, 96),
      Offset(170, 120),
      Offset(36, 160),
      Offset(110, 170),
    ];
    for (var y = 0.0; y < size.height; y += 200) {
      for (var x = 0.0; x < size.width; x += 200) {
        for (final m in marks) {
          final o = Offset(x, y) + m;
          canvas.drawLine(o, o + const Offset(6, 0), p);
          canvas.drawLine(o, o + const Offset(0, 6), p);
        }
        canvas.drawRect(Rect.fromLTWH(x + 60, y + 50, 2, 2), dot);
        canvas.drawRect(Rect.fromLTWH(x + 150, y + 70, 2, 2), dot);
      }
    }
  }

  @override
  bool shouldRepaint(_Ticks old) => old.c != c;
}

/// 透明图垫底（和 `CanvasImageBackdrop` 同色）：棋盘格 8 方一格；`none` / 非法值不画。
class GenBackdropPainter extends CustomPainter {
  const GenBackdropPainter(this.value, this.c);
  final String value;
  final UiColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final (Color? base, Color? alt) = switch (value) {
      'checker' => (
        c.control,
        c.dark ? const Color(0xFF333333) : const Color(0xFFDDDDDD),
      ),
      'checkerLight' => (const Color(0xFFFFFFFF), const Color(0xFFCCCCCC)),
      'checkerDark' => (const Color(0xFF2A2A2A), const Color(0xFF494949)),
      'black' => (Colors.black, null),
      'white' => (Colors.white, null),
      'gray' => (const Color(0xFF808080), null),
      'red' => (const Color(0xFFFF0000), null),
      'green' => (const Color(0xFF00FF00), null),
      'blue' => (const Color(0xFF0000FF), null),
      _ when value.startsWith('#') && GenBackdrop.isValid(value) => (
        Color(0xFF000000 | int.parse(value.substring(1), radix: 16)),
        null,
      ),
      _ => (null, null),
    };
    if (base == null) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    if (alt == null) return;
    const s = 8.0;
    final p = Paint()..color = alt;
    for (var y = 0; y * s < size.height; y++) {
      for (var x = 0; x * s < size.width; x++) {
        if ((x + y).isOdd) {
          canvas.drawRect(Rect.fromLTWH(x * s, y * s, s, s), p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(GenBackdropPainter old) =>
      old.value != value || old.c != c;
}

/// 自带舞台：把焦点组摆在画布中间。一张按原型留白缩放（不放大小图，除非“放大填满”）；
/// 多张试 1–N 列，取每张最大的排法，间距 16。
class _Stage extends StatelessWidget {
  const _Stage();

  @override
  Widget build(BuildContext context) {
    final scope = GenScope.of(context);
    final cv = scope.data.canvas;
    final tiles = cv.focus!.tiles;
    return LayoutBuilder(
      builder: (context, box) {
        final padding = GenCanvas.focusPadding(
          box.maxWidth,
          cv.info?.canCompareOriginal == true,
        );
        final area = padding.deflateSize(box.biggest);
        const gap = 16.0;
        var best = (cols: 1, scale: 0.0);
        for (var cols = 1; cols <= tiles.length; cols++) {
          final rows = (tiles.length / cols).ceil();
          final cw = (area.width - gap * (cols - 1)) / cols;
          final rh = (area.height - gap * (rows - 1)) / rows;
          var s = double.infinity;
          for (final t in tiles) {
            s = math.min(s, math.min(cw / t.width, rh / t.height));
          }
          if (s > best.scale) best = (cols: cols, scale: s);
        }
        final scale = cv.zoomToFill || tiles.length > 1
            ? best.scale
            : math.min(best.scale, 1.0);
        final rows = <List<GenTile>>[];
        for (var i = 0; i < tiles.length; i += best.cols) {
          rows.add(tiles.sublist(i, math.min(i + best.cols, tiles.length)));
        }
        return Padding(
          padding: padding,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: gap,
              children: [
                for (final r in rows)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: gap,
                    children: [
                      for (final t in r)
                        SizedBox(
                          width: t.width * scale,
                          height: t.height * scale,
                          child: GenCanvasTile(
                            tile: t,
                            focused:
                                tiles.length > 1 && cv.info?.tileId == t.id,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 接线方提供图片菜单；简单舞台与无限画布使用同一个右击入口。
class GenCanvasMenuScope extends InheritedWidget {
  const GenCanvasMenuScope({
    super.key,
    required this.onOpen,
    required super.child,
  });

  final void Function(BuildContext context, String id, Offset position) onOpen;

  static GenCanvasMenuScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GenCanvasMenuScope>();

  @override
  bool updateShouldNotify(GenCanvasMenuScope oldWidget) =>
      onOpen != oldWidget.onOpen;
}

/// 画布引擎提供选中回调与可选的合成流式预览，图块视觉由新页面绘制。
class GenCanvasTileScope extends InheritedWidget {
  const GenCanvasTileScope({
    super.key,
    required this.onFocus,
    required this.allowTap,
    this.preview,
    this.generating,
    this.failedPreview,
    required super.child,
  });

  final VoidCallback onFocus;
  final bool Function() allowTap;
  final Widget? preview;
  final Widget? generating;
  final Widget? failedPreview;

  static GenCanvasTileScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GenCanvasTileScope>();

  @override
  bool updateShouldNotify(GenCanvasTileScope oldWidget) =>
      onFocus != oldWidget.onFocus ||
      allowTap != oldWidget.allowTap ||
      preview != oldWidget.preview ||
      generating != oldWidget.generating ||
      failedPreview != oldWidget.failedPreview;
}

/// 画布上的一张：圆角 6。单击选中，300ms 内再点一次开大图。
class GenCanvasTile extends StatefulWidget {
  const GenCanvasTile({super.key, required this.tile, this.focused = false});
  final GenTile tile;

  /// 组里多张时，选中的那张画 2px 强调色外圈。
  final bool focused;

  @override
  State<GenCanvasTile> createState() => _GenCanvasTileState();
}

class _GenCanvasTileState extends State<GenCanvasTile> {
  DateTime? _last;
  Uint8List? _maskBytes;
  Future<Uint8List?>? _maskOverlay;
  ImageProvider? _cachedOriginal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheOriginal();
  }

  @override
  void didUpdateWidget(GenCanvasTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _precacheOriginal();
  }

  void _precacheOriginal() {
    final original = widget.tile.originalImage;
    if (original == null || original == _cachedOriginal) return;
    _cachedOriginal = original;
    unawaited(precacheImage(original, context, onError: (_, _) {}));
  }

  void _tap(GenScope scope) {
    final t = widget.tile;
    final interaction = GenCanvasTileScope.maybeOf(context);
    if (interaction != null && !interaction.allowTap()) return;
    final now = DateTime.now();
    final double =
        _last != null &&
        now.difference(_last!) < const Duration(milliseconds: 300);
    _last = now;
    if (t.state != GenTileState.done && interaction?.failedPreview == null) {
      interaction?.onFocus();
      return;
    }
    if (double) {
      _last = null;
      scope.actions.onOpenViewer(t.id);
    } else {
      if (interaction == null) {
        scope.actions.onFocusTile(t.id);
      } else {
        interaction.onFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    final t = widget.tile;
    final l = context.l10n;
    final comparing =
        _OriginalScope.maybeOf(context)?.tileId == t.id &&
        t.originalImage != null &&
        t.state == GenTileState.done;
    if (!identical(_maskBytes, t.inpaintMaskBytes)) {
      _maskBytes = t.inpaintMaskBytes;
      _maskOverlay = null;
    }
    if (scope.data.canvas.info?.tileId == t.id && _maskBytes != null) {
      _maskOverlay ??= InpaintMaskUtils.maskToComparisonOverlayAsync(
        _maskBytes!,
      );
    }
    final body = switch (t.state) {
      GenTileState.done when t.image != null => CustomPaint(
        painter: scope.data.canvas.backdrop == null
            ? null
            : GenBackdropPainter(scope.data.canvas.backdrop!, c),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: t.image!,
              fit: BoxFit.fill,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
            if (comparing)
              IgnorePointer(
                child: Stack(
                  key: Key('gen-original-${t.id}'),
                  fit: StackFit.expand,
                  children: [
                    Image(
                      image: t.originalImage!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                    if (_maskOverlay != null)
                      FutureBuilder<Uint8List?>(
                        future: _maskOverlay,
                        builder: (context, snapshot) => snapshot.data == null
                            ? const SizedBox.shrink()
                            : Image.memory(
                                snapshot.data!,
                                key: Key('gen-original-mask-${t.id}'),
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.none,
                              ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      GenTileState.streaming || GenTileState.pending => Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: GenFormat.softBg(c)),
          if (t.preview != null)
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child:
                  GenCanvasTileScope.maybeOf(context)?.preview ??
                  Image(
                    image: t.preview!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
            ),
          if (t.preview != null &&
              GenCanvasTileScope.maybeOf(context)?.generating != null)
            ColoredBox(color: c.bg.withValues(alpha: .35)),
          Center(
            child:
                GenCanvasTileScope.maybeOf(context)?.generating ??
                const _Dots(),
          ),
          if (t.progress != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 3,
                color: c.control,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: t.progress!.clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: ColoredBox(color: c.accent),
                ),
              ),
            ),
        ],
      ),
      _ =>
        GenCanvasTileScope.maybeOf(context)?.failedPreview ??
            ColoredBox(
              color: GenFormat.softBg(c),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      UiGlyph(UiGlyphs.alert, size: 22, color: c.error),
                      Text(
                        l.gen_tileFailed,
                        style: UiText.sans(
                          13,
                          weight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      if (t.error != null)
                        Text(
                          t.error!,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(12, color: c.muted),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    };
    final tile = UiPressable(
      key: Key('gen-tile-${t.id}'),
      onTap: () => _tap(scope),
      builder: (context, hover) => Container(
        foregroundDecoration: widget.focused
            ? BoxDecoration(
                border: Border.all(
                  color: c.accent,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
                borderRadius: BorderRadius.circular(8),
              )
            : t.state == GenTileState.done
            ? null
            : BoxDecoration(
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(6),
              ),
        child: ClipRRect(borderRadius: BorderRadius.circular(6), child: body),
      ),
    );
    final menu = GenCanvasMenuScope.maybeOf(context);
    if (menu == null ||
        t.state == GenTileState.pending ||
        t.state == GenTileState.streaming) {
      return tile;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) =>
          menu.onOpen(context, t.id, details.globalPosition),
      child: tile,
    );
  }
}

/// 三点跳动（官网 `image-grid-generating`）；减少动态效果时静止。
class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _a.stop();
    } else if (!_a.isAnimating) {
      _a.repeat();
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return AnimatedBuilder(
      animation: _a,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          for (var i = 0; i < 3; i++)
            Transform.translate(
              offset: Offset(
                0,
                -4 * math.max(0, math.sin((_a.value - i * .15) * math.pi * 2)),
              ),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: c.ink.withValues(alpha: .45),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 空画布：一句引导 + 生成快捷键。
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    final l = context.l10n;
    final keys = scope.data.canvas.generateShortcut.split('+');
    return Center(
      key: const Key('gen-canvas-empty'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: GenFormat.softBg(c),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.line),
            ),
            child: Center(
              child: GenNaiIcon('enhance', size: 24, color: c.faint),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l.gen_emptyTitle,
            style: UiText.sans(15, weight: FontWeight.w600, color: c.ink),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(l.gen_emptyPress, style: UiText.sans(12.5, color: c.muted)),
              UiKeycaps(keys),
              Text(l.gen_emptyOr, style: UiText.sans(12.5, color: c.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 顶部工具条（原型 top `.float`）：增强 / 变体 / 放大（价格 + 方案箭头）‖ 设为图生图 / 编辑 / 局部重绘 / 发到画布工具。
class _TopBar extends StatelessWidget {
  const _TopBar({required this.enhanceLink, required this.upscaleLink});

  /// 落下面板的尖角跟着这两个按钮。
  final LayerLink enhanceLink;
  final LayerLink upscaleLink;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    final cv = scope.data.canvas;
    final info = cv.info!;
    final a = scope.actions;
    final l = context.l10n;
    final id = info.tileId;
    final input = info.canUseAsInput;
    final busy = cv.locked || !input;
    final up = cv.upscale;
    final settings = a.onUpscaleSettings;
    Widget nai(String n, {double size = 17, Color? color}) =>
        GenNaiIcon(n, size: size, color: color ?? c.ink);
    Widget tip(String title, String body, [Widget? price]) =>
        GenBarTipContent(title: title, body: body, price: price);
    Widget cost(int? v) => v == null
        ? Text(l.tools_free, style: UiTipStyle.number(context))
        : GenAnlas('$v', size: 12, iconSize: 11, color: c.tipInk);
    final ring = up.running && up.progress != null;
    return GenFloat(
      key: const Key('gen-bar-top'),
      children: [
        CompositedTransformTarget(
          link: enhanceLink,
          child: GenFloatButton(
            key: const Key('gen-enhance'),
            selected: cv.sheet == GenToolSheet.enhance,
            richTip: tip(
              l.gen_enhance,
              l.tools_tipEnhance,
              info.enhanceCost == null ? null : cost(info.enhanceCost),
            ),
            onTap: busy ? null : () => a.onEnhance(id),
            child: nai(
              'enhance',
              color: cv.sheet == GenToolSheet.enhance ? c.accent : null,
            ),
          ),
        ),
        GenFloatButton(
          key: const Key('gen-variations'),
          richTip: tip(
            l.gen_variations,
            l.tools_tipVariations,
            info.variationsCostLoading
                ? Text(l.common_loading, style: UiTipStyle.number(context))
                : info.variationsCost == null
                ? null
                : cost(info.variationsCost),
          ),
          width: null,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          onTap: busy ? null : () => a.onVariations(id),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              nai('variations'),
              _VariationCost(info: info),
            ],
          ),
        ),
        GenFloatButton(
          key: const Key('gen-upscale'),
          width: null,
          padding: EdgeInsets.only(left: 4, right: ring ? 6 : 4),
          selected: ring || cv.sheet == GenToolSheet.upscale,
          richTip: up.running
              ? tip(l.gen_upscaleStop, l.tools_tipUpscaleRunning)
              : tip(l.gen_upscale, l.tools_tipUpscale, cost(up.cost)),
          onTap: up.running || (!busy && up.available)
              ? () => a.onUpscale(id)
              : null,
          child: ring
              ? Row(
                  key: const Key('gen-upscale-ring'),
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    CustomPaint(
                      size: const Size.square(18),
                      painter: GenProgressRing(up.progress!, c.accent),
                    ),
                    Text(
                      '${(up.progress! * 100).round()}%',
                      style: UiText.mono(
                        12,
                        weight: FontWeight.w600,
                        color: c.accent,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 5,
                  children: [
                    if (up.running)
                      UiGlyph(
                        UiGlyphs.stop,
                        size: 14,
                        filled: true,
                        color: c.ink,
                      )
                    else
                      nai('upscale'),
                    GenFloatCost(
                      key: const Key('gen-upscale-cost'),
                      child: up.running
                          ? const SizedBox(
                              width: 22,
                              child: Center(child: UiSpinner(size: 12)),
                            )
                          : up.cost == null
                          ? Text(
                              up.selected == 'novelai' ? '—' : l.tools_free,
                              style: UiText.sans(
                                12,
                                weight: FontWeight.w700,
                                color: c.ink,
                                height: 1,
                              ),
                            )
                          : GenAnlas('${up.cost}', iconSize: 10),
                    ),
                  ],
                ),
        ),
        if (!ring)
          Builder(
            builder: (ctx) => CompositedTransformTarget(
              link: upscaleLink,
              child: GenFloatButton(
                key: const Key('gen-upscale-menu'),
                width: 22,
                richTip: settings == null
                    ? null
                    : tip(l.gen_upscaleOptions, l.tools_tipUpscaleSettings),
                tooltip: l.gen_upscaleOptions,
                active: scope.controller.popoverTag == #upscale,
                selected: cv.sheet == GenToolSheet.upscale,
                onTap:
                    settings ??
                    (up.options.isEmpty
                        ? null
                        : () => scope.controller.openMenu(
                            genBelow(ctx, dy: 8),
                            [
                              for (final o in up.options)
                                UiMenuItem(
                                  label: o.label,
                                  trailing: o.detail,
                                  checked: o.id == up.selected,
                                  onTap: () => a.onUpscaleOption(o.id),
                                ),
                            ],
                            tag: #upscale,
                            width: 240,
                          )),
                child: UiGlyph(
                  UiGlyphs.chevronDown,
                  size: 13,
                  color: cv.sheet == GenToolSheet.upscale ? c.accent : c.ink,
                ),
              ),
            ),
          ),
        const GenFloatDivider(),
        GenFloatButton(
          key: const Key('gen-set-init'),
          richTip: tip(l.gen_setInit, l.tools_tipSetInit),
          onTap: input ? () => a.onSetInit(id) : null,
          child: nai('set-init'),
        ),
        GenFloatButton(
          key: const Key('gen-edit'),
          richTip: tip(l.gen_editImage, l.tools_tipEdit),
          onTap: input ? () => a.onEditImage(id) : null,
          child: nai('edit'),
        ),
        GenFloatButton(
          key: const Key('gen-inpaint'),
          richTip: tip(l.gen_inpaint, l.tools_tipInpaint),
          onTap: busy ? null : () => a.onInpaint(id),
          child: nai('inpaint'),
        ),
        GenFloatButton(
          key: const Key('gen-send-tools'),
          richTip: tip(l.gen_sendToTools, l.tools_tipDirector),
          onTap: input ? () => a.onSendToTools(id) : null,
          child: nai('send-tools', size: 16),
        ),
      ],
    );
  }
}

/// Keep the price slot stable across loading, unavailable and numeric quotes.
/// The invisible sample follows the real font/text scale; longer prices fit
/// inside that slot rather than shifting every other toolbar action.
class _VariationCost extends StatelessWidget {
  const _VariationCost({required this.info});

  final GenFocusInfo info;

  @override
  Widget build(BuildContext context) => GenFloatCost(
    key: const Key('gen-variations-cost'),
    child: Stack(
      alignment: Alignment.center,
      children: [
        const ExcludeSemantics(
          child: Opacity(opacity: 0, child: GenAnlas('0000', iconSize: 10)),
        ),
        Positioned.fill(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Semantics(
                label: info.variationsCostLoading
                    ? context.l10n.common_loading
                    : null,
                excludeSemantics: info.variationsCostLoading,
                child: GenAnlas(
                  info.variationsCost?.toString() ??
                      (info.variationsCostLoading ? '…' : '—'),
                  iconSize: 10,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// 放大进度圈（原型 `uprun`）：强调色 25% 底圈 + 进度弧，中间一个小停止方块。
class GenProgressRing extends CustomPainter {
  const GenProgressRing(this.value, this.color);
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 20;
    final center = size.center(Offset.zero);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * k
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, 8 * k, p..color = color.withValues(alpha: .25));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 8 * k),
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      p..color = color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 5.6 * k, height: 5.6 * k),
        Radius.circular(k),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(GenProgressRing old) =>
      old.value != value || old.color != color;
}

/// 放大进行中（原型 `upscaleRunStrip`）：工具条下面一条毛玻璃进度——状态 + 百分比 + 取消，
/// 进度条，一句结果去向。
class _UpscaleStrip extends StatelessWidget {
  const _UpscaleStrip();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    final up = scope.data.canvas.upscale;
    final l = context.l10n;
    final v = up.progress!.clamp(0.0, 1.0);
    return Container(
      key: const Key('gen-upscale-strip'),
      width: 340,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.raised.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: c.line.withValues(alpha: .8)),
        boxShadow: [
          BoxShadow(
            color: GenFormat.shadow(c),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: up.status ?? l.gen_upscale,
                    children: [
                      TextSpan(
                        text: '   ${(v * 100).round()}%',
                        style: UiText.mono(12, color: c.muted),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(12, weight: FontWeight.w600, color: c.ink),
                ),
              ),
              UiBtn(
                key: const Key('gen-upscale-cancel'),
                size: UiBtnSize.small,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                onTap: () =>
                    scope.actions.onUpscale(scope.data.canvas.info!.tileId),
                children: [Text(l.tools_cancel)],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.control,
              borderRadius: BorderRadius.circular(2),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: v,
              heightFactor: 1,
              child: ColoredBox(color: c.accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(l.tools_upscaleRunHint, style: UiText.sans(11, color: c.faint)),
        ],
      ),
    );
  }
}

/// 落下面板上方的小尖角：12 方旋转 45°，左上两条边描边，盖住面板顶边。
class GenSheetCaret extends StatelessWidget {
  const GenSheetCaret({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: c.raised,
          border: Border(
            left: BorderSide(color: c.line),
            top: BorderSide(color: c.line),
          ),
        ),
      ),
    );
  }
}

/// 左下信息条（原型）：宽 × 高 ‖ 显示设置 │ 种子（点了弹“用这个种子 / 复制”）。
class _InfoBar extends StatelessWidget {
  const _InfoBar();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    final info = scope.data.canvas.info!;
    final a = scope.actions;
    final l = context.l10n;
    return GenFloat(
      key: const Key('gen-bar-info'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${info.width} × ${info.height}',
            style: UiText.mono(12.5, weight: FontWeight.w500, color: c.ink),
          ),
        ),
        Builder(
          builder: (ctx) => GenFloatButton(
            key: const Key('gen-display'),
            tooltip: l.gen_display,
            active: scope.controller.popoverTag == #display,
            onTap: () => scope.controller.openPopover(
              genAbove(ctx, dy: 10),
              (_) => const _DisplayPopover(),
              tag: #display,
            ),
            child: GenNaiIcon('settings', size: 16, color: c.ink),
          ),
        ),
        if (info.seed != null)
          Builder(
            builder: (ctx) => UiPressable(
              key: const Key('gen-seed-pill'),
              onTap: () => scope.controller.openMenu(
                genAbove(ctx, dy: 10),
                [
                  UiMenuItem(
                    key: const Key('gen-use-seed'),
                    label: l.gen_useSeed,
                    glyph: UiGlyphs.lock,
                    onTap: () => a.onUseSeed(info.tileId),
                  ),
                  UiMenuItem(
                    label: l.gen_copySeed,
                    glyph: UiGlyphs.copy,
                    onTap: () => a.onCopySeed(info.tileId),
                  ),
                ],
                tag: #seed,
                width: 190,
              ),
              builder: (context, hover) => Container(
                height: 30,
                padding: const EdgeInsets.only(left: 2, right: 8),
                decoration: BoxDecoration(
                  color: hover ? c.control : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 5,
                  children: [
                    GenNaiIcon('seed', size: 13, color: c.ink),
                    Text(
                      '${info.seed}',
                      style: UiText.mono(
                        12.5,
                        weight: FontWeight.w500,
                        color: c.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Only the visible bar scrolls; surrounding blank space keeps its canvas or
/// window drag handling. Overflowing bars remain scrollable on narrow canvases.
class _CanvasBarViewport extends StatelessWidget {
  const _CanvasBarViewport({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: child,
    ),
  );
}

class _BottomBars extends StatelessWidget {
  const _BottomBars();
  @override
  Widget build(BuildContext context) {
    final hasOriginal = GenScope.of(
      context,
    ).data.canvas.info!.canCompareOriginal;
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth < 360
          ? const Stack(
              children: [
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 14,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      _CanvasBarViewport(child: _InfoBar()),
                      _CanvasBarViewport(child: _ActionBar()),
                    ],
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                Positioned(
                  left: 16,
                  bottom: hasOriginal && box.maxWidth < 500 ? 62 : 14,
                  child: const _InfoBar(),
                ),
                const Positioned(right: 16, bottom: 14, child: _ActionBar()),
              ],
            ),
    );
  }
}

/// 右下操作条：OLD / 钉住 / 复制 / 保存 / 信息（开大图）。
class _ActionBar extends StatelessWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    final info = scope.data.canvas.info!;
    final a = scope.actions;
    final l = context.l10n;
    final id = info.tileId;
    return GenFloat(
      key: const Key('gen-bar-actions'),
      children: [
        if (info.canCompareOriginal) ...[
          _OriginalCompareButton(
            key: ValueKey('gen-old-${info.tileId}'),
            id: info.tileId,
            enabled: !scope.data.canvas.locked,
          ),
          const GenFloatDivider(),
        ],
        GenFloatButton(
          key: const Key('gen-pin'),
          tooltip: info.pinned ? l.gen_unpinImage : l.gen_pinImage,
          active: info.pinned,
          onTap: () => a.onPin(id, !info.pinned),
          child: GenNaiIcon(
            info.pinned ? 'pin-filled' : 'pin',
            size: 16,
            color: info.pinned ? c.accent : c.ink,
          ),
        ),
        GenFloatButton(
          key: const Key('gen-copy'),
          tooltip: l.gen_copyImage,
          onTap: () => a.onCopyImage(id),
          child: GenNaiIcon('copy', size: 16, color: c.ink),
        ),
        GenFloatButton(
          key: const Key('gen-save'),
          tooltip: l.gen_saveImage,
          onTap: () => a.onSaveImage(id),
          child: GenNaiIcon('save', size: 16, color: c.ink),
        ),
        GenFloatButton(
          key: const Key('gen-info'),
          tooltip: l.gen_openViewer,
          onTap: () => a.onOpenViewer(id),
          child: GenNaiIcon('info', size: 16, color: c.ink),
        ),
      ],
    );
  }
}

/// Website parity: pointer/key down shows OLD, up/cancel/focus loss restores it.
class _OriginalCompareButton extends StatefulWidget {
  const _OriginalCompareButton({
    super.key,
    required this.id,
    required this.enabled,
  });
  final String id;
  final bool enabled;
  @override
  State<_OriginalCompareButton> createState() => _OriginalCompareButtonState();
}

class _OriginalCompareButtonState extends State<_OriginalCompareButton>
    with WidgetsBindingObserver {
  final _focus = FocusNode(debugLabel: 'canvas-old-compare');
  int? _pointer;
  bool _keyHeld = false;
  _OriginalScope? _scope;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focus.dispose();
    super.dispose();
  }

  void _release() {
    _pointer = null;
    _keyHeld = false;
    _scope?.onChanged(widget.id, false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _release();
  }

  @override
  Widget build(BuildContext context) {
    _scope = _OriginalScope.maybeOf(context);
    final active = _scope?.tileId == widget.id;
    final l = context.l10n;
    final c = context.ui;
    return Focus(
      focusNode: _focus,
      onFocusChange: (focused) {
        if (!focused && _keyHeld) _release();
      },
      onKeyEvent: (_, event) {
        if (event.logicalKey != LogicalKeyboardKey.space &&
            event.logicalKey != LogicalKeyboardKey.enter) {
          return KeyEventResult.ignored;
        }
        if (event is KeyUpEvent) {
          _release();
        } else if (event is KeyDownEvent && widget.enabled) {
          _keyHeld = true;
          _scope?.onChanged(widget.id, true);
        }
        return KeyEventResult.handled;
      },
      child: Listener(
        onPointerDown: (event) {
          if (!widget.enabled || event.buttons != 1 || _pointer != null) return;
          _pointer = event.pointer;
          _focus.requestFocus();
          _scope?.onChanged(widget.id, true);
        },
        onPointerUp: (event) {
          if (event.pointer == _pointer) _release();
        },
        onPointerCancel: (event) {
          if (event.pointer == _pointer) _release();
        },
        child: GenFloatButton(
          key: const Key('gen-old'),
          width: null,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          active: active,
          tooltip: l.gen_compareOriginal,
          onTap: widget.enabled ? () {} : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              GenNaiIcon('enhance', size: 16, color: active ? c.accent : c.ink),
              Text(
                l.gen_oldImageLabel,
                style: UiText.mono(11.5, weight: FontWeight.w600, color: c.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 显示设置：放大填满开关 + （出透明图的模型）垫底十选一和自定义色。
class _DisplayPopover extends StatelessWidget {
  const _DisplayPopover();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    final cv = scope.data.canvas;
    final l = context.l10n;
    Widget swatch(String b) {
      final on = cv.backdrop == b;
      final label = switch (b) {
        'checker' => l.gen_bdChecker,
        'checkerLight' => l.gen_bdCheckerLight,
        'checkerDark' => l.gen_bdCheckerDark,
        'none' => l.gen_bdNone,
        'black' => l.gen_bdBlack,
        'white' => l.gen_bdWhite,
        'gray' => l.gen_bdGray,
        'red' => l.gen_bdRed,
        'green' => l.gen_bdGreen,
        'blue' => l.gen_bdBlue,
        _ => b,
      };
      return Tooltip(
        message: label,
        child: UiPressable(
          key: Key('gen-bd-$b'),
          onTap: () => scope.actions.onBackdropChanged(b),
          builder: (context, hover) => Container(
            width: 30,
            height: 30,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: on ? c.accent : (hover ? c.strong : Colors.transparent),
                width: 2,
              ),
            ),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: c.line),
              ),
              child: CustomPaint(
                painter: b == 'none'
                    ? _Slash(c.error)
                    : GenBackdropPainter(b, c),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
    }

    final channel = cv.channel;
    final onChannel = scope.actions.onChannelChanged;
    final showChannel = channel != null && onChannel != null;
    return UiPopoverSurface(
      key: const Key('gen-display-popover'),
      width: showChannel ? 316 : 260,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          if (cv.backdrop case final bd?) ...[
            Text(
              l.gen_backdrop,
              style: UiText.sans(12, weight: FontWeight.w600, color: c.muted),
            ),
            Text(
              l.gen_backdropSub,
              style: UiText.sans(11.5, color: c.faint, height: 1.35),
            ),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final b in GenBackdrop.presets) swatch(b),
                if (bd.startsWith('#')) swatch(bd),
              ],
            ),
            _HexField(current: bd),
            Container(height: 1, color: c.line),
          ],
          UiPressable(
            key: const Key('gen-zoom-fill'),
            onTap: () => scope.actions.onZoomToFillChanged(!cv.zoomToFill),
            builder: (context, _) => Row(
              spacing: 10,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.gen_zoomToFill,
                        style: UiText.sans(13, color: c.ink),
                      ),
                      Text(
                        l.gen_zoomToFillSub,
                        style: UiText.sans(11.5, color: c.muted, height: 1.35),
                      ),
                    ],
                  ),
                ),
                UiSwitch(value: cv.zoomToFill),
              ],
            ),
          ),
          if (showChannel) ...[
            Container(height: 1, color: c.line),
            ChannelSettingsSection(
              settings: channel,
              onChanged: onChannel,
              anchorY: cv.channelTop,
              generating: scope.data.generate.state == GenRunState.generating,
            ),
          ],
        ],
      ),
    );
  }
}

/// “无”色块里的斜线。
class _Slash extends CustomPainter {
  const _Slash(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawLine(
    Offset(size.width - 3, 3),
    Offset(3, size.height - 3),
    Paint()
      ..color = color
      ..strokeWidth = 1.5,
  );

  @override
  bool shouldRepaint(_Slash old) => old.color != color;
}

/// 自定义垫底色：`#RRGGBB`，回车提交，格式不对就恢复。
class _HexField extends StatefulWidget {
  const _HexField({required this.current});
  final String current;

  @override
  State<_HexField> createState() => _HexFieldState();
}

class _HexFieldState extends State<_HexField> {
  late final _c = TextEditingController(text: _hex(widget.current));

  static String _hex(String v) => v.startsWith('#') ? v : '';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    return Row(
      spacing: 8,
      children: [
        Text(context.l10n.gen_bdCustom, style: UiText.sans(12, color: c.muted)),
        Expanded(
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: c.control,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.centerLeft,
            child: TextField(
              key: const Key('gen-bd-hex'),
              controller: _c,
              style: UiText.mono(12, color: c.ink, height: 1.2),
              cursorColor: c.accent,
              decoration: uiBareDecoration(
                hintText: '#RRGGBB',
                hintStyle: UiText.mono(12, color: c.faint, height: 1.2),
              ),
              onSubmitted: (v) {
                final raw = v.trim();
                final t = (raw.startsWith('#') ? raw : '#$raw').toUpperCase();
                if (GenBackdrop.isValid(t)) {
                  scope.actions.onBackdropChanged(t);
                } else {
                  _c.text = _hex(widget.current);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// 生成失败卡：红色感叹号 │ 标题 + 说明 │ 复制详情、重试、关闭。
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});
  final GenError error;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    final l = context.l10n;
    return Container(
      key: const Key('gen-error'),
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.error.withValues(alpha: .35)),
        boxShadow: [
          BoxShadow(
            color: GenFormat.shadow(c),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: c.error.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: UiGlyph(UiGlyphs.alert, size: 15, color: c.error),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  error.title,
                  style: UiText.sans(
                    13.5,
                    weight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
                if (error.hint != null)
                  Text(
                    error.hint!,
                    style: UiText.sans(12, color: c.muted, height: 1.45),
                  ),
                const SizedBox(height: 6),
                Row(
                  spacing: 6,
                  children: [
                    UiBtn(
                      key: const Key('gen-retry'),
                      size: UiBtnSize.small,
                      tone: UiBtnTone.primary,
                      onTap: scope.actions.onRetry,
                      children: [
                        const UiGlyph(UiGlyphs.retry, size: 12),
                        Text(l.gen_retry),
                      ],
                    ),
                    if (error.detail != null)
                      _CopyDetail(detail: error.detail!),
                  ],
                ),
              ],
            ),
          ),
          GenIb(
            key: const Key('gen-error-close'),
            glyph: UiGlyphs.close,
            glyphSize: 14,
            tooltip: l.gen_close,
            onTap: scope.actions.onDismissError,
          ),
        ],
      ),
    );
  }
}

/// “复制详情”：点了把原始错误放进剪贴板，按钮变“已复制” 1.5 秒。
class _CopyDetail extends StatefulWidget {
  const _CopyDetail({required this.detail});
  final String detail;

  @override
  State<_CopyDetail> createState() => _CopyDetailState();
}

class _CopyDetailState extends State<_CopyDetail> {
  var _done = false;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UiBtn(
    key: const Key('gen-error-copy'),
    size: UiBtnSize.small,
    tone: UiBtnTone.ghost,
    tooltip: widget.detail,
    onTap: () {
      unawaited(Clipboard.setData(ClipboardData(text: widget.detail)));
      setState(() => _done = true);
      _t?.cancel();
      _t = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _done = false);
      });
    },
    children: [
      UiGlyph(_done ? UiGlyphs.check : UiGlyphs.copy, size: 12),
      Text(_done ? context.l10n.gen_copied : context.l10n.gen_copyDetail),
    ],
  );
}

// ───────────────────────── 角色定位板 ─────────────────────────

/// 角色定位板：画布换成按图比例的板子（V4.5 5 × 5 格，V5 自由坐标），角色是可拖的彩色圆片；
/// 没放的角色在下方托盘，拖上去就放。AI 选择时板子变灰，给“切到自定义”。
class GenPositionBoard extends StatelessWidget {
  const GenPositionBoard({super.key});

  static const palette = [
    Color(0xFFE5484D),
    Color(0xFF0090FF),
    Color(0xFF30A46C),
    Color(0xFFF76B15),
    Color(0xFF8E4EC6),
    Color(0xFF12A594),
    Color(0xFFD6409F),
    Color(0xFFAD7F58),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    final chars = scope.data.characters;
    final img = scope.data.image;
    final l = context.l10n;
    if (chars == null) return const SizedBox.shrink();
    final unplaced = [
      for (final (i, ch) in chars.list.indexed)
        if (ch.position == null) i,
    ];
    return Column(
      key: const Key('gen-position-board'),
      children: [
        WindowHeaderDragSurface(
          key: const Key('gen-position-window-drag-header'),
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                spacing: 10,
                children: [
                  UiGlyph(UiGlyphs.grid, size: 16, color: c.ink),
                  Text(
                    l.gen_positionBoard,
                    style: UiText.sans(
                      14,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      chars.aiPosition
                          ? l.gen_positionAiHint
                          : (chars.freeform
                                ? l.gen_positionFreeHint
                                : l.gen_positionGridHint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(12, color: c.muted),
                    ),
                  ),
                  UiBtn(
                    key: const Key('gen-position-done'),
                    tone: UiBtnTone.primary,
                    onTap: () => scope.actions.onPositioningChanged(false),
                    children: [
                      const UiGlyph(UiGlyphs.check, size: 13, strokeWidth: 2.4),
                      Text(l.gen_done),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final area = const EdgeInsets.fromLTRB(
                40,
                8,
                40,
                24,
              ).deflateSize(box.biggest);
              final s = math.min(
                area.width / img.width,
                area.height / img.height,
              );
              final size = Size(img.width * s, img.height * s);
              return Center(
                child: SizedBox.fromSize(
                  size: size,
                  child: _Board(size: size, chars: chars),
                ),
              );
            },
          ),
        ),
        if (unplaced.isNotEmpty && !chars.aiPosition)
          Container(
            key: const Key('gen-position-tray'),
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.raised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                Text(
                  l.gen_positionUnplaced,
                  style: UiText.sans(12, color: c.muted),
                ),
                for (final i in unplaced)
                  Draggable<int>(
                    data: i,
                    feedback: _Chip(
                      index: i,
                      name: _name(context, chars, i),
                      lifted: true,
                    ),
                    childWhenDragging: Opacity(
                      opacity: .3,
                      child: _Chip(index: i, name: _name(context, chars, i)),
                    ),
                    child: _Chip(index: i, name: _name(context, chars, i)),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  static String _name(BuildContext context, GenCharactersData chars, int i) =>
      chars.list[i].name ?? context.l10n.gen_characterN(i + 1);
}

class _Board extends StatelessWidget {
  const _Board({required this.size, required this.chars});
  final Size size;
  final GenCharactersData chars;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    final l = context.l10n;
    Offset norm(Offset local) => Offset(
      (local.dx / size.width).clamp(0.0, 1.0),
      (local.dy / size.height).clamp(0.0, 1.0),
    );
    return DragTarget<int>(
      onAcceptWithDetails: (d) {
        final box = context.findRenderObject()! as RenderBox;
        // 反馈圆片的中心（圆片 28 高，拖动点在左上角附近）。
        final p = norm(box.globalToLocal(d.offset + const Offset(14, 14)));
        scope.actions.onCharacterPosition(
          d.data,
          chars.freeform ? p : GenFormat.snap(p),
        );
      },
      builder: (context, candidate, _) => Container(
        decoration: BoxDecoration(
          color: c.raised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: candidate.isNotEmpty ? c.accent : c.line,
            width: candidate.isNotEmpty ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: GenFormat.shadow(c),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _Grid(c: c, freeform: chars.freeform),
              ),
            ),
            if (!chars.freeform)
              for (var r = 0; r < 5; r++)
                for (var col = 0; col < 5; col++)
                  Positioned(
                    left: size.width * col / 5 + 6,
                    top: size.height * r / 5 + 4,
                    child: Text(
                      '${String.fromCharCode(65 + col)}${r + 1}',
                      style: UiText.mono(10, color: c.faint),
                    ),
                  ),
            for (final (i, ch) in chars.list.indexed)
              if (ch.position case final p?)
                Positioned(
                  left: p.dx * size.width - 14,
                  top: p.dy * size.height - 14,
                  child: Draggable<int>(
                    data: i,
                    feedback: _Chip(
                      index: i,
                      name: GenPositionBoard._name(context, chars, i),
                      lifted: true,
                    ),
                    childWhenDragging: const SizedBox.shrink(),
                    child: Opacity(
                      opacity: ch.enabled ? 1 : .45,
                      child: _Chip(
                        key: Key('gen-position-chip-$i'),
                        index: i,
                        name: GenPositionBoard._name(context, chars, i),
                      ),
                    ),
                  ),
                ),
            if (chars.aiPosition)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: c.bg.withValues(alpha: .78),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 10,
                      children: [
                        Text(
                          l.gen_positionAiOverlay,
                          textAlign: TextAlign.center,
                          style: UiText.sans(13, color: c.muted),
                        ),
                        UiBtn(
                          key: const Key('gen-position-switch-custom'),
                          onTap: () => scope.actions.onAiPositionChanged(false),
                          children: [Text(l.gen_positionToCustom)],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Grid extends CustomPainter {
  _Grid({required this.c, required this.freeform});
  final UiColors c;
  final bool freeform;

  @override
  void paint(Canvas canvas, Size size) {
    final n = freeform ? 10 : 5;
    final p = Paint()
      ..color = c.line.withValues(alpha: freeform ? .5 : 1)
      ..strokeWidth = 1;
    for (var i = 1; i < n; i++) {
      final x = size.width * i / n;
      final y = size.height * i / n;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    final cross = Paint()
      ..color = c.strong.withValues(alpha: .6)
      ..strokeWidth = 1;
    final m = size.center(Offset.zero);
    canvas.drawLine(m - const Offset(6, 0), m + const Offset(6, 0), cross);
    canvas.drawLine(m - const Offset(0, 6), m + const Offset(0, 6), cross);
  }

  @override
  bool shouldRepaint(_Grid old) => old.c != c || old.freeform != freeform;
}

/// 角色圆片：28 高胶囊，左边彩色圆点写序号，右边名字。
class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.index,
    required this.name,
    this.lifted = false,
  });
  final int index;
  final String name;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final color =
        GenPositionBoard.palette[index % GenPositionBoard.palette.length];
    return Material(
      type: MaterialType.transparency,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Container(
          height: 28,
          padding: const EdgeInsets.only(left: 3, right: 10),
          decoration: BoxDecoration(
            color: c.raised,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: .6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: lifted ? .25 : .1),
                blurRadius: lifted ? 14 : 4,
                offset: Offset(0, lifted ? 6 : 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: UiText.mono(
                      11,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
              Text(
                name,
                style: UiText.sans(
                  12,
                  weight: FontWeight.w600,
                  color: c.ink,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
