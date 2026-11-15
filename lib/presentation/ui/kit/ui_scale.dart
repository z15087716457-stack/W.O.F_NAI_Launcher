import 'package:flutter/material.dart';

/// One logical viewport for the complete Navigator, including its overlays.
/// Painting and hit testing use the same transform; text is not scaled again.
class UiScale extends StatelessWidget {
  const UiScale({super.key, required this.scale, required this.child});
  final double scale;
  final Widget child;

  static double factorOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_UiScaleFactor>()?.scale ?? 1;

  static Rect globalRectOf(RenderBox box) => MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final media = MediaQuery.of(context);
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: constraints.maxWidth / scale,
          maxWidth: constraints.maxWidth / scale,
          minHeight: constraints.maxHeight / scale,
          maxHeight: constraints.maxHeight / scale,
          child: Transform.scale(
            alignment: Alignment.topLeft,
            scale: scale,
            child: _UiScaleFactor(
              scale: scale,
              child: MediaQuery(
                data: media.copyWith(
                  size: constraints.biggest / scale,
                  padding: media.padding / scale,
                  viewPadding: media.viewPadding / scale,
                  viewInsets: media.viewInsets / scale,
                  systemGestureInsets: media.systemGestureInsets / scale,
                  textScaler: TextScaler.noScaling,
                ),
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _UiScaleFactor extends InheritedWidget {
  const _UiScaleFactor({required this.scale, required super.child});
  final double scale;
  @override
  bool updateShouldNotify(_UiScaleFactor oldWidget) => scale != oldWidget.scale;
}
