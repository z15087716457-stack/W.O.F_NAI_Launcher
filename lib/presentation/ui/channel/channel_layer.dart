import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../kit/app_visibility_scope.dart';
import '../kit/ui_colors.dart';
import 'channel_contract.dart';
import 'channel_format.dart';
import 'channel_geometry.dart';
import 'channel_scene.dart';

/// 标记宿主页面已在最底层挂载贯通全窗口的统一动态通道背景。
///
/// 命中时，中央画布内的 [ChannelBackdrop] 仅绘制前景图片光台与时间刻度，
/// 不再重复绘制或遮挡底层全窗口动态场景。
class ChannelHostBackdropScope extends InheritedWidget {
  const ChannelHostBackdropScope({
    super.key,
    required this.active,
    required super.child,
  });

  final bool active;

  static bool activeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ChannelHostBackdropScope>()
          ?.active ??
      false;

  @override
  bool updateShouldNotify(ChannelHostBackdropScope oldWidget) =>
      active != oldWidget.active;
}

/// 画在图块**下面**的通道层：底色、字符艺术主题、过渡层、全局地图、图片光台、时间刻度。
///
/// 接线：放在画布引擎世界层（`CanvasWorldViewport`）的下面、铺满视口，传当前相机即可；
/// 本层不接收指针。空闲微动由本层以约 30 帧的节拍推进，系统“减少动态效果”、
/// 设置关掉微动或模式为“关闭”时停在静止帧。
class ChannelBackdrop extends StatefulWidget {
  const ChannelBackdrop({super.key, required this.data, this.pass});
  final ChannelViewData data;

  /// 指定固定绘制通道（`scene` 或 `annotations`）；留空时按需自动拆分。
  final ChannelPaintPass? pass;

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
    if (widget.pass == ChannelPaintPass.annotations) return false;
    final d = widget.data;
    return d.settings.motion &&
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
    final fixedPass = widget.pass;
    final split = fixedPass == null && motion && batches.isNotEmpty;
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
    final primaryKey = fixedPass == ChannelPaintPass.annotations
        ? const Key('channel-annotations')
        : const Key('channel-backdrop');
    final primaryPass =
        fixedPass ?? (split ? ChannelPaintPass.scene : ChannelPaintPass.all);
    final scene = layer(primaryKey, primaryPass);
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
    // 始终以 1:1 逻辑像素绘制字符艺术，避免大屏下 canvas.scale 放大字形位图变粗糙、
    // 或窄窗下将字符缩成像素点；构图等比适配由主题内等比舞台坐标系负责。
    _paintFrame(canvas, size, data.camera);
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
      welcome: data.welcome,
      pinboard: data.pinboard,
      stageCenterX: data.stageCenterX,
    );
    if (pass != ChannelPaintPass.annotations) {
      paintChannelScene(canvas, size, spec);
    }
    // 图片四周不绘制外扩实色光台与冗余时间文字；图片边界由图块自身的轻柔贴边外阴影区分。
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
