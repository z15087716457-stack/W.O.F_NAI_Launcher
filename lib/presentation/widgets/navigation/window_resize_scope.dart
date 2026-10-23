import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

/// Native resize phase only. Layout and MediaQuery keep the live window size.
class WindowResizeScope extends StatefulWidget {
  const WindowResizeScope({super.key, required this.child});

  final Widget child;

  static bool activeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ResizePhase>()?.active ??
      false;

  @override
  State<WindowResizeScope> createState() => _WindowResizeScopeState();
}

class _WindowResizeScopeState extends State<WindowResizeScope>
    with WindowListener {
  bool _active = false;

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
    if (!_active) setState(() => _active = true);
  }

  @override
  void onWindowResized() {
    if (_active) setState(() => _active = false);
  }

  @override
  Widget build(BuildContext context) =>
      _ResizePhase(active: _active, child: widget.child);
}

class _ResizePhase extends InheritedWidget {
  const _ResizePhase({required this.active, required super.child});

  final bool active;

  @override
  bool updateShouldNotify(_ResizePhase oldWidget) => active != oldWidget.active;
}
