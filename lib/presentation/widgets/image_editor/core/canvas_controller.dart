// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

/// 画布控制器
/// 管理画布的缩放、平移、旋转、镜像等变换
class CanvasController extends ChangeNotifier {
  /// 缩放比例
  double _scale = 1.0;
  double get scale => _scale;

  /// 最小缩放
  static const double minScale = 0.1;

  /// 最大缩放
  static const double maxScale = 32.0;

  /// 偏移量
  Offset _offset = Offset.zero;
  Offset get offset => _offset;

  /// 视口尺寸
  Size _viewportSize = Size.zero;
  Size get viewportSize => _viewportSize;

  /// 画布旋转角度（弧度）
  double _rotation = 0.0;
  double get rotation => _rotation;

  /// 画布是否水平镜像
  bool _isMirroredHorizontally = false;
  bool get isMirroredHorizontally => _isMirroredHorizontally;

  int _batchDepth = 0;
  bool _pendingNotification = false;

  bool get _isBatching => _batchDepth > 0;

  void beginBatch() {
    _batchDepth++;
  }

  void endBatch() {
    if (_batchDepth == 0) {
      return;
    }

    _batchDepth--;
    if (_batchDepth == 0 && _pendingNotification) {
      _pendingNotification = false;
      notifyListeners();
    }
  }

  T runBatch<T>(T Function() body) {
    beginBatch();
    try {
      return body();
    } finally {
      endBatch();
    }
  }

  void _notifyChanged() {
    if (_isBatching) {
      _pendingNotification = true;
      return;
    }

    notifyListeners();
  }

  /// 设置缩放
  void setScale(double scale, {Offset? focalPoint}) {
    final newScale = scale.clamp(minScale, maxScale);
    if (newScale != _scale) {
      if (focalPoint != null) {
        // 以焦点为中心缩放
        final oldScale = _scale;
        _scale = newScale;
        final scaleRatio = newScale / oldScale;
        _offset = focalPoint - (focalPoint - _offset) * scaleRatio;
      } else {
        _scale = newScale;
      }
      _notifyChanged();
    }
  }

  /// 增加缩放
  void zoomIn({Offset? focalPoint}) {
    setScale(_scale * 1.25, focalPoint: focalPoint);
  }

  /// 减少缩放
  void zoomOut({Offset? focalPoint}) {
    setScale(_scale / 1.25, focalPoint: focalPoint);
  }

  /// 设置偏移
  void setOffset(Offset offset) {
    if (_offset != offset) {
      _offset = offset;
      _notifyChanged();
    }
  }

  /// 平移
  void pan(Offset delta) {
    _offset += delta;
    _notifyChanged();
  }

  /// 设置视口尺寸
  void setViewportSize(Size size) {
    _viewportSize = size;
  }

  /// 适应视口
  void fitToViewport(
    Size canvasSize, {
    double padding = 40.0,
    EdgeInsets? insets,
  }) {
    if (_viewportSize == Size.zero) return;
    // 防止除零错误
    if (canvasSize.width <= 0 || canvasSize.height <= 0) return;

    final frame = insets ?? EdgeInsets.all(padding);
    final availableWidth = _viewportSize.width - frame.horizontal;
    final availableHeight = _viewportSize.height - frame.vertical;
    // 防止负数或零
    if (availableWidth <= 0 || availableHeight <= 0) return;

    final scaleX = availableWidth / canvasSize.width;
    final scaleY = availableHeight / canvasSize.height;
    _scale = (scaleX < scaleY ? scaleX : scaleY).clamp(minScale, maxScale);

    // 居中
    final scaledWidth = canvasSize.width * _scale;
    final scaledHeight = canvasSize.height * _scale;
    _offset = Offset(
      frame.left + (availableWidth - scaledWidth) / 2,
      frame.top + (availableHeight - scaledHeight) / 2,
    );

    _notifyChanged();
  }

  /// 重置视图
  void reset() {
    _scale = 1.0;
    _offset = Offset.zero;
    _notifyChanged();
  }

  /// 重置到100%
  void resetTo100({Size? canvasSize}) {
    _scale = 1.0;
    if (_viewportSize != Size.zero && canvasSize != null) {
      // 居中显示：计算画布在视口中居中的偏移量
      _offset = Offset(
        (_viewportSize.width - canvasSize.width) / 2,
        (_viewportSize.height - canvasSize.height) / 2,
      );
    } else {
      _offset = Offset.zero;
    }
    _notifyChanged();
  }

  /// 适应视口高度
  void fitToHeight(Size canvasSize, {double padding = 40.0}) {
    if (_viewportSize == Size.zero) return;
    if (canvasSize.height <= 0) return;

    final availableHeight = _viewportSize.height - padding * 2;
    if (availableHeight <= 0) return;

    _scale = (availableHeight / canvasSize.height).clamp(minScale, maxScale);

    // 居中
    final scaledWidth = canvasSize.width * _scale;
    final scaledHeight = canvasSize.height * _scale;
    _offset = Offset(
      (_viewportSize.width - scaledWidth) / 2,
      (_viewportSize.height - scaledHeight) / 2,
    );

    _notifyChanged();
  }

  /// 适应视口宽度
  void fitToWidth(Size canvasSize, {double padding = 40.0}) {
    if (_viewportSize == Size.zero) return;
    if (canvasSize.width <= 0) return;

    final availableWidth = _viewportSize.width - padding * 2;
    if (availableWidth <= 0) return;

    _scale = (availableWidth / canvasSize.width).clamp(minScale, maxScale);

    // 居中
    final scaledWidth = canvasSize.width * _scale;
    final scaledHeight = canvasSize.height * _scale;
    _offset = Offset(
      (_viewportSize.width - scaledWidth) / 2,
      (_viewportSize.height - scaledHeight) / 2,
    );

    _notifyChanged();
  }

  /// 向左旋转（默认15度）
  void rotateLeft({double degrees = 15.0}) {
    _rotation -= degrees * math.pi / 180.0;
    _notifyChanged();
  }

  /// 向右旋转（默认15度）
  void rotateRight({double degrees = 15.0}) {
    _rotation += degrees * math.pi / 180.0;
    _notifyChanged();
  }

  /// 重置旋转
  void resetRotation() {
    _rotation = 0.0;
    _notifyChanged();
  }

  /// 切换水平镜像
  void toggleMirrorHorizontal() {
    _isMirroredHorizontally = !_isMirroredHorizontally;
    _notifyChanged();
  }

  /// 重置视图（包括旋转和镜像）
  void resetView(Size canvasSize) {
    _rotation = 0.0;
    _isMirroredHorizontally = false;
    fitToViewport(canvasSize);
  }

  /// 将屏幕坐标转换为画布坐标，使用绘制矩阵的逆变换。
  Offset screenToCanvas(Offset screenPoint, {Size? canvasSize}) {
    final matrix = canvasSize == null
        ? transformMatrix
        : getTransformMatrix(canvasSize);
    return MatrixUtils.transformPoint(Matrix4.inverted(matrix), screenPoint);
  }

  /// 将画布坐标转换为屏幕坐标，保持与绘制变换一致。
  Offset canvasToScreen(Offset canvasPoint, {Size? canvasSize}) {
    final matrix = canvasSize == null
        ? transformMatrix
        : getTransformMatrix(canvasSize);
    return MatrixUtils.transformPoint(matrix, canvasPoint);
  }

  /// 获取变换矩阵（包含旋转和镜像）
  Matrix4 getTransformMatrix(Size canvasSize) {
    final matrix = Matrix4.identity();

    // 1. 移动到偏移位置
    matrix.translate(_offset.dx, _offset.dy);

    // 2. 移动到画布中心进行旋转和镜像
    final centerX = canvasSize.width * _scale / 2;
    final centerY = canvasSize.height * _scale / 2;
    matrix.translate(centerX, centerY);

    // 3. 应用旋转
    if (_rotation != 0) {
      matrix.rotateZ(_rotation);
    }

    // 4. 应用水平镜像
    if (_isMirroredHorizontally) {
      matrix.scale(-1.0, 1.0, 1.0);
    }

    // 5. 移回原点
    matrix.translate(-centerX, -centerY);

    // 6. 应用缩放
    matrix.scale(_scale);

    return matrix;
  }

  /// 获取简单变换矩阵（仅缩放和平移，用于兼容）
  Matrix4 get transformMatrix {
    return Matrix4.identity()
      ..translate(_offset.dx, _offset.dy)
      ..scale(_scale);
  }

  /// 获取视口边界（用于空间剔除优化）
  ///
  /// 返回当前视口在画布坐标系中的矩形边界
  /// 图层如果与这个矩形不相交，则可以被跳过渲染
  Rect get viewportBounds {
    if (_viewportSize == Size.zero) {
      return Rect.zero;
    }

    // 将视口左上角和右下角转换为画布坐标
    final topLeft = screenToCanvas(Offset.zero);
    final bottomRight = screenToCanvas(
      Offset(_viewportSize.width, _viewportSize.height),
    );

    return Rect.fromPoints(topLeft, bottomRight);
  }
}
