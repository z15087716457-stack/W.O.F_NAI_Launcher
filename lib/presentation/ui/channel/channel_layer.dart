import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../kit/ui_colors.dart';
import 'channel_contract.dart';
import 'channel_format.dart';
import 'channel_geometry.dart';
import 'channel_paint.dart';
import 'channel_scene.dart';

/// 画在图块**下面**的通道层：底色、主题装饰、过渡层、全局地图、图片光台、时间刻度。
///
/// 接线：放在画布引擎世界层（`CanvasWorldViewport`）的下面、铺满视口，传当前相机即可；
/// 本层不接收指针。
///
/// 空闲微动三档（[ChannelMotion]，默认关）：
/// - 防烧屏：整层每秒挪一小格（见 [ChannelBackdrop.shiftOrbit]）。场景只画一次（静止帧）
///   存成图层，挪动只改这层图层的位置、不重画。
/// - 原本效果：和上游一样的逐个元素动画。画面每 [ChannelBackdrop.frameInterval] 换一次，
///   就只按这个节拍出帧（不再每次屏幕刷新都出一帧）；场景上面的图片光台和时间刻度单独
///   一层，不跟着每帧重录。
///
/// 生成中、系统 / 应用“减少动态效果”、模式为“关闭”时停在静止帧（防烧屏回到原位）；窗口
/// 看不见（`TickerMode` 关，见 `AppVisibility`）时停在当前这一帧，看得见时——哪怕不在
/// 前台——接着动。
class ChannelBackdrop extends StatefulWidget {
  const ChannelBackdrop({super.key, required this.data});
  final ChannelViewData data;

  /// 防烧屏的节拍。
  static const shiftInterval = Duration(seconds: 1);

  /// 原本效果的画面节拍：原来就是 33ms 换一次画面，帧也就出这么多（约 30 帧）。
  static const frameInterval = Duration(milliseconds: 33);

  /// 微动一圈走过的位置（单位：一格，见 [shiftStep]）：3×3 的格子绕一圈，每次只挪到
  /// 相邻的一格，9 秒回到原位。
  static const shiftOrbit = <Offset>[
    Offset.zero,
    Offset(1, 0),
    Offset(1, 1),
    Offset(0, 1),
    Offset(-1, 1),
    Offset(-1, 0),
    Offset(-1, -1),
    Offset(0, -1),
    Offset(1, -1),
  ];

  /// 一格多远（逻辑像素）：约一个逻辑像素，按物理像素取整（2 倍屏 2 个物理像素）。
  /// 挪完仍对齐物理像素，线条的抗锯齿和原位时一样，只是整体换了位置。
  static double shiftStep(double devicePixelRatio) =>
      math.max(1, devicePixelRatio.roundToDouble()) / devicePixelRatio;

  @override
  State<ChannelBackdrop> createState() => _ChannelBackdropState();
}

class _ChannelBackdropState extends State<ChannelBackdrop> {
  Timer? _timer;
  ChannelMotion? _running;
  final _orbit = ValueNotifier<int>(0);

  /// 原本效果的动画时间（秒）：只在动的时候走，停下再开接着走。
  final _time = ValueNotifier<double>(0);
  Object? _annotationKey;
  List<String?> _labels = const [];
  List<String?> _days = const [];
  Locale? _namesLocale;
  Map<ChannelTheme, String> _names = const {};
  (ChannelViewData, double, ChannelViewData)? _inflated;

  /// 现在该是哪一档（不管窗口看不看得见）：生成中、减少动态效果、模式“关闭”都算关。
  ChannelMotion _wanted(BuildContext context) {
    final d = widget.data;
    if (d.generating ||
        d.settings.mode == ChannelMode.off ||
        MediaQuery.disableAnimationsOf(context)) {
      return ChannelMotion.off;
    }
    return d.settings.motion;
  }

  void _sync() {
    final wanted = _wanted(context);
    final run =
        wanted != ChannelMotion.off && TickerMode.valuesOf(context).enabled
        ? wanted
        : null;
    if (run != _running) {
      _timer?.cancel();
      _timer = null;
      _running = run;
      if (run == ChannelMotion.antiBurnIn) {
        _timer = Timer.periodic(ChannelBackdrop.shiftInterval, (_) {
          _orbit.value = (_orbit.value + 1) % ChannelBackdrop.shiftOrbit.length;
        });
      } else if (run == ChannelMotion.original) {
        // tick 是开始以来过了几个 33ms（定时器被耽误时也按实际过去的时间算）
        final from = _time.value;
        const step = ChannelBackdrop.frameInterval;
        _timer = Timer.periodic(step, (timer) {
          _time.value = from + timer.tick * step.inMicroseconds / 1e6;
        });
      }
    }
    // 不是防烧屏就回原位；窗口看不见只是暂停，回来接着挪
    if (wanted != ChannelMotion.antiBurnIn) _orbit.value = 0;
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
    _timer?.cancel();
    _orbit.dispose();
    _time.dispose();
    super.dispose();
  }

  /// 同一份数据、同样的外扩只算一次：窗口看不见 / 看得见切换时本层会重建，场景不跟着重画。
  ChannelViewData _paintData(ChannelViewData d, double step) {
    if (step == 0) return d;
    final hit = _inflated;
    if (hit != null && identical(hit.$1, d) && hit.$2 == step) return hit.$3;
    final inflated = _inflate(d, step);
    _inflated = (d, step, inflated);
    return inflated;
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
    final wanted = _wanted(context);
    // 防烧屏时整层四周多画一格，挪动时边上不露底
    final step = wanted == ChannelMotion.antiBurnIn
        ? ChannelBackdrop.shiftStep(MediaQuery.devicePixelRatioOf(context))
        : 0.0;
    final data = _paintData(d, step);
    Widget layer(ChannelPaintPass pass, Key key, {bool animated = false}) =>
        RepaintBoundary(
          child: CustomPaint(
            key: key,
            size: Size.infinite,
            painter: ChannelBackdropPainter(
              data: data,
              colors: c,
              names: _names,
              labels: _labels,
              days: _days,
              pass: pass,
              time: animated ? _time : null,
            ),
          ),
        );
    // 原本效果：场景每 33ms 重画；上面的图片光台和时间刻度和它无关，单独一层录一次
    final content = wanted == ChannelMotion.original
        ? Stack(
            fit: StackFit.expand,
            children: [
              layer(
                ChannelPaintPass.scene,
                const Key('channel-backdrop'),
                animated: true,
              ),
              layer(
                ChannelPaintPass.annotations,
                const Key('channel-annotations'),
              ),
            ],
          )
        : layer(ChannelPaintPass.all, const Key('channel-backdrop'));
    return IgnorePointer(
      child: RepaintBoundary(
        child: _ShiftedLayer(step: step, orbit: _orbit, child: content),
      ),
    );
  }
}

/// 画布四周各多画 [margin]：相机跟着挪，世界里的东西还落在视口原来的位置。
ChannelViewData _inflate(ChannelViewData d, double margin) => ChannelViewData(
  settings: d.settings,
  camera: ChannelCamera(
    offset: d.camera.offset + Offset(margin, margin),
    scale: d.camera.scale,
  ),
  batches: d.batches,
  now: d.now,
  generating: d.generating,
  pinboard: d.pinboard,
);

/// 微动：子组件比自己四周各大 [step]，按 [orbit] 指的那一格平移着画。
///
/// 子组件是重绘边界：挪一格只改它那层图层的偏移、不重画场景。[step] 为 0 时子组件和自己
/// 一样大、原位画，和没有这一层一样。
class _ShiftedLayer extends SingleChildRenderObjectWidget {
  const _ShiftedLayer({
    required this.step,
    required this.orbit,
    required super.child,
  });

  final double step;
  final ValueListenable<int> orbit;

  @override
  _RenderShiftedLayer createRenderObject(BuildContext context) =>
      _RenderShiftedLayer(step, orbit);

  @override
  void updateRenderObject(BuildContext context, _RenderShiftedLayer r) => r
    ..step = step
    ..orbit = orbit;
}

class _RenderShiftedLayer extends RenderProxyBox {
  _RenderShiftedLayer(this._step, this._orbit);

  double _step;
  set step(double value) {
    if (value == _step) return;
    _step = value;
    markNeedsLayout();
  }

  ValueListenable<int> _orbit;
  set orbit(ValueListenable<int> value) {
    if (identical(value, _orbit)) return;
    if (attached) _orbit.removeListener(markNeedsPaint);
    _orbit = value;
    if (attached) _orbit.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _orbit.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _orbit.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    size = constraints.biggest;
    child?.layout(
      BoxConstraints.tight(
        Size(size.width + _step * 2, size.height + _step * 2),
      ),
    );
  }

  Offset get _shift {
    if (_step == 0) return Offset.zero;
    const orbit = ChannelBackdrop.shiftOrbit;
    final cell = orbit[_orbit.value % orbit.length];
    return Offset(-_step, -_step) + cell * _step;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      false;

  final _clip = LayerHandle<ClipRectLayer>();

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (_step == 0) {
      _clip.layer = null;
      context.paintChild(child, offset);
      return;
    }
    _clip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (context, offset) => context.paintChild(child, offset + _shift),
      oldLayer: _clip.layer,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final shift = _shift;
    transform.translateByDouble(shift.dx, shift.dy, 0, 1);
  }

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }
}

/// [ChannelBackdropPainter] 画哪些：全部；只画场景（底色、主题装饰、过渡层、全局地图）；
/// 只画场景上面的图片光台和时间刻度。分开画时按这个顺序一层叠一层，和一起画一样。
enum ChannelPaintPass { all, scene, annotations }

/// 通道层的画家（也给缩略图、测试直接用）。
///
/// [time] 为 null 时画静止帧；给了就按它的时间画“原本效果”的动画帧，它一变就重画。
class ChannelBackdropPainter extends CustomPainter {
  ChannelBackdropPainter({
    required this.data,
    required this.colors,
    required this.names,
    this.labels = const [],
    this.days = const [],
    this.pass = ChannelPaintPass.all,
    this.time,
  }) : env = ChannelEnv.of(data.settings),
       super(repaint: time);

  final ChannelViewData data;
  final UiColors colors;
  final Map<ChannelTheme, String> names;

  /// 和 [ChannelViewData.batches] 一一对应：左上角标签、上方换日分隔（null = 不画）。
  final List<String?> labels;
  final List<String?> days;
  final ChannelPaintPass pass;
  final ValueListenable<double>? time;
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
      t: time?.value ?? 0,
      motion: time != null,
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
      old.pass != pass ||
      old.time != time ||
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
