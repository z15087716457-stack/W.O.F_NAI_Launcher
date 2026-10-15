import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_text.dart';
import 'channel_contract.dart';
import 'channel_format.dart';
import 'channel_geometry.dart';
import 'channel_palette.dart';

/// 画在图块**上面**的通道层：右边缘的刻度条、进入时的“本次通道”提示。
///
/// 接线：放在画布引擎的屏幕层（图块之上、浮动工具条之下），铺满画布区域。只有刻度条那一条
/// 接收指针，其余区域透传给画布。
class ChannelOverlay extends StatefulWidget {
  const ChannelOverlay({super.key, required this.data, required this.actions});
  final ChannelViewData data;
  final ChannelActions actions;

  /// 刻度条离画布上下边的距离（让开浮动工具条）。
  static const scrubInset = 64.0;

  @override
  State<ChannelOverlay> createState() => _ChannelOverlayState();
}

class _ChannelOverlayState extends State<ChannelOverlay> {
  Timer? _hide;
  var _toast = false;
  int? _seed;
  ChannelMode? _mode;

  @override
  void initState() {
    super.initState();
    _seed = widget.data.settings.seed;
    _mode = widget.data.settings.mode;
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  @override
  void didUpdateWidget(ChannelOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final s = widget.data.settings;
    if (s.seed != _seed || s.mode != _mode) {
      _seed = s.seed;
      _mode = s.mode;
      _show();
    }
  }

  void _show() {
    if (!mounted || widget.data.settings.mode != ChannelMode.random) return;
    setState(() => _toast = true);
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 4200), () {
      if (mounted) setState(() => _toast = false);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 350);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (d.settings.ruler && d.batches.isNotEmpty)
          Positioned(
            right: 6,
            top: ChannelOverlay.scrubInset,
            bottom: ChannelOverlay.scrubInset,
            width: 24 + 300,
            child: _Scrubber(data: d, actions: widget.actions),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 60,
          child: IgnorePointer(
            child: Center(
              child: AnimatedSlide(
                duration: duration,
                offset: _toast ? Offset.zero : const Offset(0, .25),
                child: AnimatedOpacity(
                  duration: duration,
                  opacity: _toast ? 1 : 0,
                  child: _toast || !reduce
                      ? _Toast(data: d)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// “本次通道  ■ 回廊 → ■ 青海波 → ■ 星图 → ■ 植物标本 …”
class _Toast extends StatelessWidget {
  const _Toast({required this.data});
  final ChannelViewData data;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final env = ChannelEnv.of(data.settings);
    final top = data.batches.isEmpty ? 0.0 : data.batches.first.rect.top + 300;
    final n = env.order.length < 4 ? env.order.length : 4;
    final seq = env.sequenceFrom(top, n);
    final arrow = Text('→', style: UiText.sans(11, color: c.muted));
    return Container(
      key: const Key('channel-toast'),
      padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
      decoration: BoxDecoration(
        color: c.raised.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.dark ? .4 : .14),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(
            context.l10n.channel_toastTitle,
            style: UiText.sans(12, color: c.muted),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              for (final (i, t) in seq.indexed) ...[
                if (i > 0) arrow,
                ChannelSwatchLabel(theme: t, size: 12),
              ],
              if (env.order.length > n)
                Text('…', style: UiText.sans(11, color: c.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 色块 + 主题名。
class ChannelSwatchLabel extends StatelessWidget {
  const ChannelSwatchLabel({
    super.key,
    required this.theme,
    this.size = 12,
    this.weight = FontWeight.w400,
    this.swatch = 8,
  });
  final ChannelTheme theme;
  final double size;
  final FontWeight weight;
  final double swatch;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Container(
          width: swatch,
          height: swatch,
          decoration: BoxDecoration(
            color: ChannelPalette.of(theme).swatch,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          ChannelFormat.name(context, theme),
          maxLines: 1,
          style: UiText.sans(size, weight: weight, color: c.ink),
        ),
      ],
    );
  }
}

/// 右边缘的刻度条：彩色段 = 主题，短横 = 批次，长横 = 换日，空心框 = 当前视口。
/// 平时半透明，悬停 / 拖动时不透明并在左边出一张小卡（主题 + 日期时间）；点或拖直接跳。
class _Scrubber extends StatefulWidget {
  const _Scrubber({required this.data, required this.actions});
  final ChannelViewData data;
  final ChannelActions actions;

  @override
  State<_Scrubber> createState() => _ScrubberState();
}

class _ScrubberState extends State<_Scrubber> {
  double? _hoverY;
  var _drag = false;

  (double, double) get _range {
    final b = widget.data.batches;
    return (b.first.rect.top - 1600, b.last.rect.bottom + 1600);
  }

  double _worldAt(double y, double h) {
    final (t0, t1) = _range;
    return lerpD(t0, t1, (y / h).clamp(0.0, 1.0));
  }

  void _jump(double y, double h) => widget.actions.onJumpTo(_worldAt(y, h));

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        final hover = _hoverY;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 24,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onHover: (e) => setState(() => _hoverY = e.localPosition.dy),
                onExit: (_) {
                  if (!_drag) setState(() => _hoverY = null);
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (e) => _jump(e.localPosition.dy, h),
                  onVerticalDragStart: (e) {
                    setState(() {
                      _drag = true;
                      _hoverY = e.localPosition.dy;
                    });
                    _jump(e.localPosition.dy, h);
                  },
                  onVerticalDragUpdate: (e) {
                    setState(() => _hoverY = e.localPosition.dy);
                    _jump(e.localPosition.dy, h);
                  },
                  onVerticalDragEnd: (_) => setState(() {
                    _drag = false;
                    _hoverY = null;
                  }),
                  child: AnimatedOpacity(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 150),
                    opacity: hover != null || _drag ? 1 : .55,
                    child: CustomPaint(
                      key: const Key('channel-scrubber'),
                      size: Size(24, h),
                      painter: _ScrubPainter(
                        data: widget.data,
                        range: _range,
                        ink: c.ink,
                        viewport: _viewportOf(h),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (hover != null)
              Positioned(
                right: 28,
                top: hover.clamp(0.0, h) - 14,
                child: IgnorePointer(child: _tip(context, _worldAt(hover, h))),
              ),
          ],
        );
      },
    );
  }

  /// 画布视口的世界竖向范围：刻度条高度 + 上下留白 = 画布高。
  (double, double) _viewportOf(double scrubHeight) {
    final h = scrubHeight + ChannelOverlay.scrubInset * 2;
    final cam = widget.data.camera;
    final top = -cam.offset.dy / cam.scale;
    return (top, top + h / cam.scale);
  }

  Widget _tip(BuildContext context, double y) {
    final c = context.ui;
    final d = widget.data;
    var best = d.batches.first;
    var dist = double.infinity;
    for (final b in d.batches) {
      final dd = (b.rect.center.dy - y).abs();
      if (dd < dist) {
        dist = dd;
        best = b;
      }
    }
    final env = ChannelEnv.of(d.settings);
    final theme = env.off
        ? null
        : env.themeOf(ChannelGeo.zoneOf(y / ChannelGeo.decorScale));
    final t = best.time;
    final when = t == null
        ? null
        : context.l10n.channel_scrubWhen(
            ChannelFormat.day(context, t, d.now),
            ChannelFormat.clock(t),
          );
    return Container(
      key: const Key('channel-scrub-tip'),
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.dark ? .4 : .14),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          if (theme != null) ChannelSwatchLabel(theme: theme),
          if (when != null) Text(when, style: UiText.sans(12, color: c.muted)),
        ],
      ),
    );
  }
}

class _ScrubPainter extends CustomPainter {
  _ScrubPainter({
    required this.data,
    required this.range,
    required this.ink,
    required this.viewport,
  });
  final ChannelViewData data;
  final (double, double) range;
  final Color ink;
  final (double, double) viewport;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final (t0, t1) = range;
    double y(double w) => (w - t0) / (t1 - t0) * h;
    canvas.drawRect(
      Rect.fromLTWH(11.5, 0, 1, h),
      Paint()..color = ink.withValues(alpha: .14),
    );
    final env = ChannelEnv.of(data.settings);
    const k = ChannelGeo.decorScale;
    if (!env.off) {
      for (
        var z = ChannelGeo.zoneOf(t0 / k);
        z <= ChannelGeo.zoneOf(t1 / k);
        z++
      ) {
        final zs = ChannelGeo.zoneStart(z);
        final a = (env.fixed ? zs : zs + ChannelGeo.transition / 2) * k;
        final b =
            (env.fixed
                ? zs + ChannelGeo.zone
                : zs + ChannelGeo.zone - ChannelGeo.transition / 2) *
            k;
        final ya = y(a).clamp(0.0, h), yb = y(b).clamp(0.0, h);
        if (yb <= ya) continue;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(10.5, ya, 13.5, yb),
            const Radius.circular(1.5),
          ),
          Paint()
            ..color = ChannelPalette.of(
              env.themeOf(z),
            ).swatch.withValues(alpha: .8),
        );
      }
    }
    for (final (i, b) in data.batches.indexed) {
      final t = b.time, prev = i == 0 ? null : data.batches[i - 1].time;
      final day =
          i == 0 ||
          (t != null && prev != null && !ChannelFormat.sameDay(t, prev));
      canvas.drawRect(
        Rect.fromLTWH(
          day ? 2 : 5,
          y(b.rect.center.dy).roundToDouble(),
          day ? 6 : 4,
          1,
        ),
        Paint()..color = ink.withValues(alpha: day ? .55 : .3),
      );
    }
    final (v0, v1) = viewport;
    final a = y(v0).clamp(0.0, h - 6), b = y(v1).clamp(a + 6, h);
    final thumb = RRect.fromRectAndRadius(
      Rect.fromLTRB(15.5, a + .5, 21.5, b - .5),
      const Radius.circular(3),
    );
    canvas
      ..drawRRect(thumb, Paint()..color = ink.withValues(alpha: .07))
      ..drawRRect(
        thumb,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = ink.withValues(alpha: .42),
      );
  }

  @override
  bool shouldRepaint(_ScrubPainter old) =>
      old.data != data ||
      old.range != range ||
      old.ink != ink ||
      old.viewport != viewport;
}
