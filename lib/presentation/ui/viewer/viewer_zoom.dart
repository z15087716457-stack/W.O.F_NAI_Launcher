import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 大图缩放 / 平移状态（界面自己的，不回调）。
///
/// - [scale] 是相对原图像素的倍数（1 = 100%）；null 表示“适应”（[fitScale] 由舞台按可用区域算好写进来）。
/// - [center] 是视野中心落在原图上的位置（0–1）；图比视野小的那一轴固定在 0.5。
/// - 以鼠标处缩放：缩放前后鼠标下面的原图点不动。
class ViewerZoom extends ChangeNotifier {
  static const minScale = .05;
  static const maxScale = 8.0;
  static const step = 1.25;

  double? _scale;
  Offset _center = const Offset(.5, .5);
  Size _image = const Size(1, 1);
  Size _view = Size.zero;
  double _fit = 1;

  /// 第一次从“适应”放大（舞台用它弹出操作提示）。
  var zoomedOnce = false;

  bool get fitted => _scale == null;
  double get fitScale => _fit;
  double get scale => _scale ?? _fit;
  Offset get center => _center;
  Size get image => _image;
  Size get view => _view;

  /// 放大后图比视野大，可以拖动、显示小地图。
  bool get pannable =>
      !fitted &&
      (_image.width * scale > _view.width + .5 ||
          _image.height * scale > _view.height + .5);

  /// 换图时回到适应。
  void reset() {
    if (_scale == null && _center == const Offset(.5, .5)) return;
    _scale = null;
    _center = const Offset(.5, .5);
    notifyListeners();
  }

  /// 舞台布局时写入：原图尺寸、放大时的视野（整块图片区）、适应比例（扣掉箭头留白后的区域）。
  void layout({required Size image, required Size view, required double fit}) {
    final changed = image != _image || view != _view || fit != _fit;
    _image = image;
    _view = view;
    _fit = fit;
    if (changed) {
      _center = _clamp(_center, scale);
      // 布局里写入，不能当场通知；下一帧让顶栏的百分比跟上。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }

  void setScale(double? s, {Offset? focal}) {
    if (s == null) {
      reset();
      return;
    }
    final next = s.clamp(math.min(minScale, _fit), maxScale).toDouble();
    final prev = scale;
    var c = _center;
    if (focal != null && _view.width > 0) {
      final d = focal - _view.center(Offset.zero);
      final p =
          c +
          Offset(d.dx / (_image.width * prev), d.dy / (_image.height * prev));
      c =
          p -
          Offset(d.dx / (_image.width * next), d.dy / (_image.height * next));
    }
    if (_scale == null && next > _fit) zoomedOnce = true;
    _scale = next <= _fit + 1e-6 && next >= _fit - 1e-6 ? null : next;
    _center = _clamp(c, next);
    notifyListeners();
  }

  /// 放大 / 缩小一档；缩到不大于适应时回到适应。
  void zoomBy(double factor, {Offset? focal}) {
    final next = scale * factor;
    if (factor < 1 && next <= _fit) {
      reset();
      return;
    }
    setScale(next, focal: focal);
  }

  /// 双击：适应 ↔ 原始大小（原图本来就比视野小时放大到 2 倍）。
  void toggle({Offset? focal}) {
    if (!fitted) {
      reset();
      return;
    }
    setScale(_fit >= 1 ? _fit * 2 : 1, focal: focal);
  }

  /// 拖动大图（视野里的像素位移）。
  void panBy(Offset delta) {
    if (!pannable) return;
    final s = scale;
    _center = _clamp(
      _center -
          Offset(delta.dx / (_image.width * s), delta.dy / (_image.height * s)),
      s,
    );
    notifyListeners();
  }

  /// 小地图里拖框（按原图比例的位移）。
  void moveCenter(Offset normalizedDelta) {
    _center = _clamp(_center + normalizedDelta, scale);
    notifyListeners();
  }

  /// 视野在原图上的范围（0–1），小地图画框用。
  Rect get visible {
    final s = scale;
    final w = math.min(1.0, _view.width / (_image.width * s));
    final h = math.min(1.0, _view.height / (_image.height * s));
    return Rect.fromCenter(center: _center, width: w, height: h);
  }

  /// 图在视野里的位置（放大时）。适应时由舞台居中画在留白区里。
  Rect rectIn(Size view) {
    final s = scale;
    final size = Size(_image.width * s, _image.height * s);
    final topLeft =
        view.center(Offset.zero) -
        Offset(_center.dx * size.width, _center.dy * size.height);
    return topLeft & size;
  }

  Offset _clamp(Offset c, double s) {
    double axis(double v, double img, double view) {
      final shown = img * s;
      if (shown <= view || view <= 0) return .5;
      final half = view / 2 / shown;
      return v.clamp(half, 1 - half);
    }

    return Offset(
      axis(c.dx, _image.width, _view.width),
      axis(c.dy, _image.height, _view.height),
    );
  }
}
