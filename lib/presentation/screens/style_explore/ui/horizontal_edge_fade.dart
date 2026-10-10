import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

class HorizontalEdgeFade extends StatefulWidget {
  const HorizontalEdgeFade({super.key, required this.child, this.extent = 20});
  final Widget child;
  final double extent;
  @override
  State<HorizontalEdgeFade> createState() => _EdgeFadeState();
}

class _EdgeFadeState extends State<HorizontalEdgeFade> {
  bool _left = false, _right = false;
  void _update(ScrollMetrics metrics) {
    if (axisDirectionToAxis(metrics.axisDirection) != Axis.horizontal) return;
    final before = metrics.extentBefore > .5, after = metrics.extentAfter > .5;
    final reverse = metrics.axisDirection == AxisDirection.left;
    final left = reverse ? after : before, right = reverse ? before : after;
    if (left != _left || right != _right) {
      setState(() {
        _left = left;
        _right = right;
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollMetricsNotification>(
        onNotification: (event) {
          _update(event.metrics);
          return false;
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (event) {
            _update(event.metrics);
            return false;
          },
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) {
              final edge = rect.width == 0
                  ? 0.0
                  : (widget.extent / rect.width).clamp(0.0, .4);
              return LinearGradient(
                colors: [
                  _left ? Colors.transparent : Colors.white,
                  Colors.white,
                  Colors.white,
                  _right ? Colors.transparent : Colors.white,
                ],
                stops: [0, edge, 1 - edge, 1],
              ).createShader(rect);
            },
            child: widget.child,
          ),
        ),
      );
}
