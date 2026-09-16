import 'package:flutter/material.dart';

/// 横向滚动区两端边缘虚化：仅在对应方向还有滚动余量时显影，
/// 作为「还能滚」的视觉提示（画廊筛选排 / 谱系家族 chips 行共用）。
///
/// 直接包在滚动件外层即可，内部经 ScrollMetricsNotification 读余量，
/// 不接管滚动件的 ScrollController（避免外部 controller 与视口
/// position 分叉导致滚动失效）。
class HorizontalEdgeFade extends StatefulWidget {
  const HorizontalEdgeFade({super.key, required this.child, this.extent = 20});

  /// 被包住的横向滚动件。
  final Widget child;

  /// 虚化宽度（px）。
  final double extent;

  @override
  State<HorizontalEdgeFade> createState() => _HorizontalEdgeFadeState();
}

class _HorizontalEdgeFadeState extends State<HorizontalEdgeFade> {
  bool _fadeStart = false;
  bool _fadeEnd = false;

  // ScrollMetricsNotification 在滚动、首帧 metrics 就绪与内容尺寸变化
  // （applyNewDimensions）时都会派发，chips 增删后余量评估自动跟随。
  bool _onMetrics(ScrollMetricsNotification notification) {
    final metrics = notification.metrics;
    final start = metrics.pixels > metrics.minScrollExtent + 0.5;
    final end = metrics.pixels < metrics.maxScrollExtent - 0.5;
    if (start != _fadeStart || end != _fadeEnd) {
      setState(() {
        _fadeStart = start;
        _fadeEnd = end;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = NotificationListener<ScrollMetricsNotification>(
      onNotification: _onMetrics,
      child: widget.child,
    );
    if (!_fadeStart && !_fadeEnd) return child;
    child = ShaderMask(
      shaderCallback: (rect) {
        final stop = (widget.extent / rect.width).clamp(0.0, 0.4);
        return LinearGradient(
          colors: [
            _fadeStart ? Colors.transparent : Colors.white,
            Colors.white,
            Colors.white,
            _fadeEnd ? Colors.transparent : Colors.white,
          ],
          stops: [0.0, stop, 1 - stop, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
    return child;
  }
}
