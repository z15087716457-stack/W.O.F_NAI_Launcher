import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../kit/ui_colors.dart';
import 'channel_contract.dart';
import 'channel_format.dart';
import 'channel_geometry.dart';
import 'channel_paint.dart';
import 'channel_scene.dart';

/// 画在图块**下面**的通道层：底色、主题装饰、过渡层、全局地图、图片光台、时间刻度。
///
/// 接线：放在画布引擎世界层（`CanvasWorldViewport`）的下面、铺满视口，传当前相机即可；
/// 本层不接收指针。空闲微动由本层自己的 ticker 驱动（约 30 帧），生成中、系统“减少动态效果”、
/// 设置关掉微动或模式为“关闭”时停在静止帧。
class ChannelBackdrop extends StatefulWidget {
  const ChannelBackdrop({super.key, required this.data});
  final ChannelViewData data;

  @override
  State<ChannelBackdrop> createState() => _ChannelBackdropState();
}

class _ChannelBackdropState extends State<ChannelBackdrop>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _time = ValueNotifier<double>(0);
  var _base = 0.0;
  var _last = Duration.zero;

  bool _animate(BuildContext context) {
    final d = widget.data;
    return d.settings.motion &&
        !d.generating &&
        d.settings.mode != ChannelMode.off &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
  }

  void _tick(Duration elapsed) {
    if (elapsed - _last < const Duration(milliseconds: 33)) return;
    _last = elapsed;
    _time.value = _base + elapsed.inMicroseconds / 1e6;
  }

  void _sync() {
    final on = _animate(context);
    if (on == _ticker.isActive) return;
    if (on) {
      _last = Duration.zero;
      _ticker.start();
    } else {
      _base = _time.value;
      _ticker.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ChannelBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final c = context.ui;
    final batches = d.batches;
    final labels = <String?>[];
    final days = <String?>[];
    for (final (i, b) in batches.indexed) {
      labels.add(
        d.settings.ruler
            ? ChannelFormat.batch(context, b, newest: i == 0)
            : null,
      );
      final t = b.time;
      final prev = i == 0 ? null : batches[i - 1].time;
      days.add(
        d.settings.ruler &&
                t != null &&
                (prev == null || !ChannelFormat.sameDay(prev, t))
            ? ChannelFormat.day(context, t, d.now)
            : null,
      );
    }
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          key: const Key('channel-backdrop'),
          size: Size.infinite,
          painter: ChannelBackdropPainter(
            data: d,
            colors: c,
            names: ChannelFormat.names(context),
            labels: labels,
            days: days,
            motion: _animate(context),
            time: _time,
          ),
        ),
      ),
    );
  }
}

/// 通道层的画家（也给缩略图、测试直接用）。
class ChannelBackdropPainter extends CustomPainter {
  ChannelBackdropPainter({
    required this.data,
    required this.colors,
    required this.names,
    this.labels = const [],
    this.days = const [],
    this.motion = false,
    required this.time,
  }) : env = ChannelEnv.of(data.settings),
       super(repaint: time);

  final ChannelViewData data;
  final UiColors colors;
  final Map<ChannelTheme, String> names;

  /// 和 [ChannelViewData.batches] 一一对应：左上角标签、上方换日分隔（null = 不画）。
  final List<String?> labels;
  final List<String?> days;
  final bool motion;
  final ValueNotifier<double> time;
  final ChannelEnv env;

  /// 日期分隔线离组顶边的世界距离（组间距 340 的一半）。
  static const dayGap = 170.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = data.settings;
    final cam = data.camera;
    final spec = ChannelSceneSpec(
      env: env,
      camera: cam,
      dark: colors.dark,
      base: colors.bg,
      level: s.level.factor,
      seed: s.seed,
      names: names,
      t: time.value,
      motion: motion,
      pinboard: data.pinboard,
    );
    paintChannelScene(canvas, size, spec);
    final view = cam.visibleWorldRect(size).inflate(200);
    const k = ChannelGeo.decorScale;

    // 图片光台：底色晕开压住装饰，图片永远是最清楚的那一层
    if (!env.off) {
      for (final b in data.batches) {
        if (!b.rect.overlaps(view)) continue;
        final r = Rect.fromPoints(
          cam.worldToScreen(b.rect.topLeft),
          cam.worldToScreen(b.rect.bottomRight),
        );
        final pc = spec.tint(b.rect.center.dy / k);
        final soft = Paint()
          ..color = pc
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11);
        canvas
          ..drawRect(r.inflate(10), soft)
          ..drawRect(r.inflate(10), soft)
          ..drawRect(r.inflate(4), Paint()..color = pc);
      }
    }

    // 时间刻度（屏幕尺寸固定，世界位置锚定）
    if (!s.ruler || cam.scale <= 0.1) return;
    final c = colors;
    for (final (i, b) in data.batches.indexed) {
      if (!b.rect.overlaps(view)) continue;
      final tl = cam.worldToScreen(b.rect.topLeft);
      if (i < labels.length && labels[i] != null) {
        ChannelText.paint(
          canvas,
          labels[i]!,
          Offset(tl.dx, tl.dy - 8),
          11,
          ChannelFont.mono,
          c.muted,
          weight: FontWeight.w500,
        );
      }
      final day = i < days.length ? days[i] : null;
      if (day == null) continue;
      final dy = b.rect.top - dayGap;
      final at = cam.worldToScreen(Offset(0, dy));
      final half = ChannelGeo.dayLineHalf * cam.scale;
      canvas.drawRect(
        Rect.fromLTWH(at.dx - half, at.dy - 0.5, half * 2, 1),
        Paint()
          ..shader = LinearGradient(
            colors: [
              c.border.withValues(alpha: 0),
              c.border,
              c.border,
              c.border.withValues(alpha: 0),
            ],
            stops: const [0, .3, .7, 1],
          ).createShader(Rect.fromLTWH(at.dx - half, at.dy - 1, half * 2, 2)),
      );
      final tp = ChannelText.layout(
        day,
        11.5,
        ChannelFont.sans,
        c.ink,
        FontWeight.w500,
      );
      final lx = cam.worldToScreen(const Offset(-416, 0)).dx;
      final pill = RRect.fromRectAndRadius(
        Rect.fromLTWH(lx - 2, at.dy - 11, tp.width + 20, 22),
        const Radius.circular(11),
      );
      canvas
        ..drawRRect(pill, Paint()..color = env.off ? c.bg : spec.tint(dy / k))
        ..drawRRect(
          pill,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = c.border,
        );
      ChannelText.paint(
        canvas,
        day,
        Offset(lx + 8, at.dy + 4),
        11.5,
        ChannelFont.sans,
        c.ink,
        weight: FontWeight.w500,
      );
    }
  }

  @override
  bool shouldRepaint(ChannelBackdropPainter old) =>
      old.data != data ||
      old.colors != colors ||
      old.motion != motion ||
      !_listEq(old.labels, labels) ||
      !_listEq(old.days, days) ||
      !_mapEq(old.names, names);
}

bool _listEq(List<String?> a, List<String?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEq(Map<ChannelTheme, String> a, Map<ChannelTheme, String> b) =>
    a.length == b.length && a.keys.every((k) => a[k] == b[k]);
