import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../kit/app_visibility_scope.dart';
import '../kit/ui_colors.dart';
import 'channel_contract.dart';
import 'channel_format.dart';
import 'channel_geometry.dart';
import 'channel_paint.dart';
import 'channel_scene.dart';

/// 画在图块**下面**的通道层：底色、主题装饰、过渡层、全局地图、图片光台、时间刻度。
///
/// 接线：放在画布引擎世界层（`CanvasWorldViewport`）的下面、铺满视口，传当前相机即可；
/// 本层不接收指针。空闲微动由本层以约 30 帧的节拍推进，生成中、系统“减少动态效果”、
/// 设置关掉微动或模式为“关闭”时停在静止帧。
class ChannelBackdrop extends StatefulWidget {
  const ChannelBackdrop({super.key, required this.data});
  final ChannelViewData data;

  @override
  State<ChannelBackdrop> createState() => _ChannelBackdropState();
}

class _ChannelBackdropState extends State<ChannelBackdrop> {
  static const _frameInterval = Duration(milliseconds: 33);
  final _time = ValueNotifier<double>(0);
  Timer? _timer;
  ValueListenable<bool>? _visibility;
  bool _tickersEnabled = true;
  bool _reduceMotion = false;
  Object? _annotationKey;
  List<String?> _labels = const [];
  List<String?> _days = const [];
  Locale? _namesLocale;
  Map<ChannelTheme, String> _names = const {};

  bool get _motion {
    final d = widget.data;
    return d.settings.motion &&
        !d.generating &&
        d.settings.mode != ChannelMode.off &&
        !_reduceMotion;
  }

  void _sync() {
    if (!_tickersEnabled || _visibility?.value == false || !_motion) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    final base = _time.value;
    _timer ??= Timer.periodic(_frameInterval, (timer) {
      _time.value = base + timer.tick * _frameInterval.inMilliseconds / 1000;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visibility = AppVisibilityScope.maybeOf(context);
    if (_visibility != visibility) {
      _visibility?.removeListener(_sync);
      _visibility = visibility;
      visibility?.addListener(_sync);
    }
    _tickersEnabled = TickerMode.valuesOf(context).enabled;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(ChannelBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _visibility?.removeListener(_sync);
    _timer?.cancel();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final c = context.ui;
    final batches = d.batches;
    final locale = Localizations.localeOf(context);
    final annotationKey = (
      batches,
      d.settings.ruler,
      locale,
      d.now.year,
      d.now.month,
      d.now.day,
    );
    if (_annotationKey != annotationKey) {
      _annotationKey = annotationKey;
      _labels = const [];
      _days = const [];
      if (d.settings.ruler) {
        _labels = [
          for (final (i, b) in batches.indexed)
            ChannelFormat.batch(context, b, newest: i == 0),
        ];
        _days = [
          for (final (i, b) in batches.indexed)
            if (b.time != null &&
                (i == 0 ||
                    batches[i - 1].time == null ||
                    !ChannelFormat.sameDay(batches[i - 1].time!, b.time!)))
              ChannelFormat.day(context, b.time!, d.now)
            else
              null,
        ];
      }
    }
    if (_namesLocale != locale) {
      _namesLocale = locale;
      _names = ChannelFormat.names(context);
    }
    final motion = _motion;
    final split = motion && batches.isNotEmpty;
    Widget layer(Key key, ChannelPaintPass pass) => RepaintBoundary(
      child: CustomPaint(
        key: key,
        size: Size.infinite,
        painter: ChannelBackdropPainter(
          data: d,
          colors: c,
          names: _names,
          labels: _labels,
          days: _days,
          motion: motion,
          time: _time,
          pass: pass,
        ),
      ),
    );
    final scene = layer(
      const Key('channel-backdrop'),
      split ? ChannelPaintPass.scene : ChannelPaintPass.all,
    );
    return IgnorePointer(
      child: split
          ? Stack(
              fit: StackFit.expand,
              children: [
                scene,
                layer(
                  const Key('channel-annotations'),
                  ChannelPaintPass.annotations,
                ),
              ],
            )
          : scene,
    );
  }
}

enum ChannelPaintPass { all, scene, annotations }

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
    this.pass = ChannelPaintPass.all,
  }) : env = ChannelEnv.of(data.settings),
       super(
         repaint: motion && pass != ChannelPaintPass.annotations ? time : null,
       );

  final ChannelViewData data;
  final UiColors colors;
  final Map<ChannelTheme, String> names;

  /// 和 [ChannelViewData.batches] 一一对应：左上角标签、上方换日分隔（null = 不画）。
  final List<String?> labels;
  final List<String?> days;
  final bool motion;
  final ValueNotifier<double> time;
  final ChannelEnv env;
  final ChannelPaintPass pass;

  /// 日期分隔线离组顶边的世界距离（组间距 340 的一半）。
  static const dayGap = 170.0;

  @override
  void paint(Canvas canvas, Size size) {
    final camera = data.camera;
    if (!data.welcome) {
      _paintFrame(canvas, size, camera);
      return;
    }
    final factor = camera.scale / ChannelCamera.welcomeZoom;
    canvas
      ..save()
      ..scale(factor);
    _paintFrame(
      canvas,
      size / factor,
      ChannelCamera(
        offset: camera.offset / factor,
        scale: ChannelCamera.welcomeZoom,
      ),
    );
    canvas.restore();
  }

  void _paintFrame(Canvas canvas, Size size, ChannelCamera cam) {
    final s = data.settings;
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
    if (pass != ChannelPaintPass.annotations) {
      paintChannelScene(canvas, size, spec);
    }
    if (pass == ChannelPaintPass.scene) return;
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
      old.pass != pass ||
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
