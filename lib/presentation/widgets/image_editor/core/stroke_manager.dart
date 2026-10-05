import 'package:flutter/material.dart';

/// 笔画状态管理器
/// 负责当前绘制笔画的状态管理
class StrokeManager extends ChangeNotifier {
  /// 当前绘制的临时笔画点
  List<Offset> _currentStrokePoints = [];
  List<Offset> get currentStrokePoints => _currentStrokePoints;

  /// 是否正在绘制
  List<double> pressures = [];
  bool _isDrawing = false;
  bool get isDrawing => _isDrawing;

  /// 开始绘制
  void startStroke(Offset point, {double pressure = 1}) {
    _isDrawing = true;
    _currentStrokePoints = [point];
    pressures = [pressure];
    notifyListeners();
  }

  /// 更新绘制
  void updateStroke(Offset point, {double pressure = 1}) {
    if (_isDrawing) {
      _currentStrokePoints.add(point);
      pressures.add(pressure);
      notifyListeners();
    }
  }

  /// 结束绘制
  void endStroke() {
    _isDrawing = false;
    _currentStrokePoints = [];
    pressures = [];
    notifyListeners();
  }

  /// 取消绘制
  void cancelStroke() {
    _isDrawing = false;
    _currentStrokePoints = [];
    pressures = [];
    notifyListeners();
  }

  /// 重置
  void reset() {
    _isDrawing = false;
    _currentStrokePoints = [];
    pressures = [];
    notifyListeners();
  }

  /// 获取当前笔画点数
  int get pointCount => _currentStrokePoints.length;

  /// 是否有当前笔画
  bool get hasCurrentStroke => _currentStrokePoints.isNotEmpty;
}
