import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

/// Keep the last layout while a native edge is dragged. The compositor scales
/// that layout to the current viewport; release lays out the final size once.
class WindowResizeViewport extends StatefulWidget {
  const WindowResizeViewport({super.key, required this.child});

  final Widget child;

  @override
  State<WindowResizeViewport> createState() => _WindowResizeViewportState();
}

class _WindowResizeViewportState extends State<WindowResizeViewport>
    with WindowListener {
  Size? _layoutSize;
  bool _resizing = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowResize() {
    if (!_resizing) setState(() => _resizing = true);
  }

  @override
  void onWindowResized() {
    if (_resizing) setState(() => _resizing = false);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!_resizing || _layoutSize == null) {
        _layoutSize = constraints.biggest;
      }
      final size = _layoutSize!;
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: size.width,
          maxWidth: size.width,
          minHeight: size.height,
          maxHeight: size.height,
          child: Transform.scale(
            alignment: Alignment.topLeft,
            scaleX: constraints.maxWidth / size.width,
            scaleY: constraints.maxHeight / size.height,
            filterQuality: _resizing ? FilterQuality.low : null,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(size: size),
                child: TickerMode(
                  enabled: !_resizing,
                  child: RepaintBoundary(child: widget.child),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
