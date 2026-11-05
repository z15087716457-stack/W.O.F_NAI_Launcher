import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Keeps the current route mounted and lets timers stop before the next frame.
class AppVisibilityScope extends InheritedWidget {
  AppVisibilityScope({
    super.key,
    required this.visibility,
    required Widget child,
  }) : super(
         child: ValueListenableBuilder<bool>(
           valueListenable: visibility,
           builder: _build,
           child: child,
         ),
       );

  final ValueListenable<bool> visibility;

  static ValueListenable<bool>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AppVisibilityScope>()
      ?.visibility;

  static Widget _build(BuildContext context, bool visible, Widget? child) =>
      Offstage(
        offstage: !visible,
        child: TickerMode(enabled: visible, child: child!),
      );

  @override
  bool updateShouldNotify(AppVisibilityScope oldWidget) =>
      visibility != oldWidget.visibility;
}
