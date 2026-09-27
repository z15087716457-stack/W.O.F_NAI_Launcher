import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// Set only by the desktop window shell. Standalone pages and other platforms
/// keep their normal layout; retained routes share the same caption geometry.
class WindowChromeScope extends InheritedWidget {
  const WindowChromeScope({
    super.key,
    required super.child,
    this.enabled = true,
    this.extraWidth = 0,
    this.captionHeight = height,
  });
  final bool enabled;
  final double extraWidth;
  final double captionHeight;

  static const height = 36.0;
  static const controlsWidth = 138.0;
  static const dragWidth = 64.0;
  static bool activeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<WindowChromeScope>()
          ?.enabled ??
      false;

  static double heightOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<WindowChromeScope>()
          ?.captionHeight ??
      height;

  static double reservedWidthOf(BuildContext context) =>
      controlsWidth +
      (context
              .dependOnInheritedWidgetOfExactType<WindowChromeScope>()
              ?.extraWidth ??
          0);

  @override
  bool updateShouldNotify(WindowChromeScope oldWidget) =>
      enabled != oldWidget.enabled ||
      extraWidth != oldWidget.extraWidth ||
      captionHeight != oldWidget.captionHeight;
}

/// An intentionally empty region: no text fields or buttons can become drag
/// targets. Windows performs the move, including edge snapping and restoration.
class WindowDragArea extends StatelessWidget {
  const WindowDragArea({super.key});

  Future<void> _call(Future<void> Function() action) async {
    try {
      await action();
    } on MissingPluginException {
      // Widget tests / unsupported desktop hosts.
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onPanStart: (_) => unawaited(_call(windowManager.startDragging)),
    onDoubleTap: () => unawaited(
      _call(() async {
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      }),
    ),
    child: const SizedBox.expand(),
  );
}

/// Reserve the top-right caption footprint within an existing page header.
/// Narrow panes keep their controls on a second row, with no whole-window bar.
class WindowHeader extends StatelessWidget {
  const WindowHeader({
    super.key,
    required this.child,
    this.enabled = true,
    this.minimumInlineWidth = 620,
    this.decoration,
  });
  final Widget child;
  final bool enabled;
  final double minimumInlineWidth;
  final Decoration? decoration;

  @override
  Widget build(BuildContext context) {
    if (!enabled || !WindowChromeScope.activeOf(context)) {
      return decoration == null
          ? child
          : Container(decoration: decoration!, child: child);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final reserved = WindowChromeScope.reservedWidthOf(context);
        final narrow =
            constraints.maxWidth <
            minimumInlineWidth + reserved - WindowChromeScope.controlsWidth;
        return Container(
          decoration:
              decoration ??
              BoxDecoration(color: Theme.of(context).colorScheme.surface),
          child: Stack(
            children: [
              Padding(
                padding: narrow
                    ? EdgeInsets.only(top: WindowChromeScope.heightOf(context))
                    : EdgeInsets.only(
                        right: reserved + WindowChromeScope.dragWidth,
                      ),
                child: child,
              ),
              Positioned(
                top: 0,
                left: narrow ? 0 : null,
                right: reserved,
                width: narrow ? null : WindowChromeScope.dragWidth,
                height: WindowChromeScope.heightOf(context),
                child: const WindowDragArea(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Used only on the rightmost dock, or the exposed canvas when it is collapsed.
/// Its own surface extends to the top; only this pane's controls move down.
class WindowPaneInset extends StatelessWidget {
  const WindowPaneInset({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled || !WindowChromeScope.activeOf(context)) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Padding(
          padding: EdgeInsets.only(top: WindowChromeScope.heightOf(context)),
          child: child,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: WindowChromeScope.heightOf(context),
          child: const WindowDragArea(),
        ),
      ],
    );
  }
}

/// A short panel title beside the window controls. Empty space is draggable;
/// only panes too narrow to hold both rows place their title below the captions.
class WindowPanelHeader extends StatelessWidget {
  const WindowPanelHeader({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!WindowChromeScope.activeOf(context)) {
      return SizedBox(height: 48, child: child);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final reserved = WindowChromeScope.reservedWidthOf(context);
        final narrow = constraints.maxWidth < reserved + 182;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: narrow ? WindowChromeScope.height : 48,
              child: Row(
                children: [
                  if (!narrow) SizedBox(width: 166, child: child),
                  const Expanded(child: WindowDragArea()),
                  SizedBox(width: reserved.clamp(0.0, constraints.maxWidth)),
                ],
              ),
            ),
            if (narrow)
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(width: 166, child: child),
                ),
              ),
          ],
        );
      },
    );
  }
}
