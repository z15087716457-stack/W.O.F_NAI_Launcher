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
  });
  final bool enabled;

  static const height = 36.0;
  static const controlsWidth = 138.0;
  static const dragWidth = 64.0;
  static bool activeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<WindowChromeScope>()
          ?.enabled ??
      false;

  @override
  bool updateShouldNotify(WindowChromeScope oldWidget) =>
      enabled != oldWidget.enabled;
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
  });
  final Widget child;
  final bool enabled;
  final double minimumInlineWidth;

  @override
  Widget build(BuildContext context) {
    if (!enabled || !WindowChromeScope.activeOf(context)) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < minimumInlineWidth;
        return ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Stack(
            children: [
              Padding(
                padding: narrow
                    ? const EdgeInsets.only(top: WindowChromeScope.height)
                    : const EdgeInsets.only(
                        right:
                            WindowChromeScope.controlsWidth +
                            WindowChromeScope.dragWidth,
                      ),
                child: child,
              ),
              Positioned(
                top: 0,
                left: narrow ? 0 : null,
                right: WindowChromeScope.controlsWidth,
                width: narrow ? null : WindowChromeScope.dragWidth,
                height: WindowChromeScope.height,
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
          padding: const EdgeInsets.only(top: WindowChromeScope.height),
          child: child,
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: WindowChromeScope.height,
          child: WindowDragArea(),
        ),
      ],
    );
  }
}
