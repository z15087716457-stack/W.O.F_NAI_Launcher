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
    onTap: () {},
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

/// Place the drag target behind the header's controls. Only uncovered space
/// reaches it; fields, buttons and menus retain their own pointer handling.
/// Painted containers belong outside this surface so they do not intercept
/// its blank areas.
class WindowHeaderDragSurface extends StatelessWidget {
  const WindowHeaderDragSurface({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled || !WindowChromeScope.activeOf(context)) return child;
    return Stack(
      children: [
        const Positioned.fill(
          child: WindowDragArea(key: Key('window-header-background-drag')),
        ),
        child,
      ],
    );
  }
}

/// Reserve the top-right caption footprint within an existing page header.
/// Narrow panes keep their controls on a second row, with no whole-window bar.
class WindowHeader extends StatelessWidget {
  const WindowHeader({
    super.key,
    required this.child,
    this.enabled = true,
    this.minimumInlineWidth = 620,
    this.inlineDragWidth = WindowChromeScope.dragWidth,
    this.showCaptionDivider = false,
    this.outsideRightWidth = 0,
    this.dragBelowCaptions = false,
    this.dragBackground = false,
    this.decoration,
  });
  final Widget child;
  final bool enabled;
  final double minimumInlineWidth;
  final double inlineDragWidth;
  final bool showCaptionDivider;

  /// Width of an adjacent pane already underneath the window controls.
  final double outsideRightWidth;

  /// Headers taller than the caption cluster: the reserved strip below the
  /// window controls also moves the window instead of being dead space.
  final bool dragBelowCaptions;

  /// Enable dragging over uncovered header space, even when an adjacent pane
  /// owns the caption reserve and [enabled] is false.
  final bool dragBackground;
  final Decoration? decoration;

  @override
  Widget build(BuildContext context) {
    if (!enabled || !WindowChromeScope.activeOf(context)) {
      final content = WindowHeaderDragSurface(
        enabled: dragBackground,
        child: child,
      );
      return decoration == null
          ? content
          : Container(decoration: decoration!, child: content);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final reserved =
            (WindowChromeScope.reservedWidthOf(context) - outsideRightWidth)
                .clamp(0.0, double.infinity);
        final narrow =
            constraints.maxWidth <
            minimumInlineWidth + reserved - WindowChromeScope.controlsWidth;
        return Container(
          decoration:
              decoration ??
              BoxDecoration(color: Theme.of(context).colorScheme.surface),
          child: WindowHeaderDragSurface(
            enabled: dragBackground,
            child: Stack(
              children: [
                Padding(
                  padding: narrow
                      ? EdgeInsets.only(
                          top: WindowChromeScope.heightOf(context),
                        )
                      : EdgeInsets.only(right: reserved + inlineDragWidth),
                  child: child,
                ),
                if (dragBelowCaptions && !narrow)
                  Positioned(
                    top: WindowChromeScope.heightOf(context),
                    right: 0,
                    bottom: 0,
                    width: reserved + inlineDragWidth,
                    child: const WindowDragArea(
                      key: Key('window-header-drag-below-captions'),
                    ),
                  ),
                Positioned(
                  top: 0,
                  left: narrow ? 0 : null,
                  right: reserved,
                  width: narrow ? null : inlineDragWidth,
                  height: WindowChromeScope.heightOf(context),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const WindowDragArea(),
                      if (showCaptionDivider)
                        Align(
                          alignment: Alignment.centerRight,
                          child: IgnorePointer(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Container(
                                key: const Key('window-header-caption-divider'),
                                width: 1,
                                height: 18,
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shared library toolbar surface and divider, including the caption reserve.
class LibraryWindowHeader extends StatelessWidget {
  const LibraryWindowHeader({
    super.key,
    required this.child,
    this.enabled = true,
    this.minimumInlineWidth = 620,
    this.inlineDragWidth = WindowChromeScope.dragWidth,
    this.showCaptionDivider = false,
    this.outsideRightWidth = 0,
    this.dragBelowCaptions = false,
    this.dragBackground = false,
  });
  final Widget child;
  final bool enabled;
  final double minimumInlineWidth;
  final double inlineDragWidth;
  final bool showCaptionDivider;
  final double outsideRightWidth;
  final bool dragBelowCaptions;
  final bool dragBackground;
  @override
  Widget build(BuildContext context) => WindowHeader(
    enabled: enabled,
    minimumInlineWidth: minimumInlineWidth,
    inlineDragWidth: inlineDragWidth,
    showCaptionDivider: showCaptionDivider,
    outsideRightWidth: outsideRightWidth,
    dragBelowCaptions: dragBelowCaptions,
    dragBackground: dragBackground,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: child,
  );
}

/// Used only on the rightmost dock, or the exposed canvas when it is collapsed.
/// Its own surface extends to the top; only this pane's controls move down.
class WindowPaneInset extends StatelessWidget {
  const WindowPaneInset({
    super.key,
    required this.child,
    this.enabled = true,
    this.horizontal = false,
  });
  final Widget child;
  final bool enabled;

  /// Short stage headers reserve caption width rather than adding another row.
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return WindowHeader(
        enabled: enabled,
        minimumInlineWidth: 0,
        inlineDragWidth: 0,
        dragBackground: true,
        decoration: const BoxDecoration(color: Colors.black),
        child: child,
      );
    }
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
    final height = WindowChromeScope.heightOf(context);
    if (!WindowChromeScope.activeOf(context)) {
      return SizedBox(height: height, child: child);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final reserved = WindowChromeScope.reservedWidthOf(context);
        final narrow = constraints.maxWidth < reserved + 182;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height,
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
                height: height,
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

/// Reserve only the part of the caption cluster that reaches this canvas.
/// Keep a centered toolbar unless it actually overlaps; the image stays full size.
class WindowSafeTopToolbar extends StatelessWidget {
  const WindowSafeTopToolbar({
    super.key,
    required this.child,
    required this.outsideRightWidth,
    this.topInset = 16,
  });
  final Widget child;
  final double outsideRightWidth;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final active = WindowChromeScope.activeOf(context);
    return CustomSingleChildLayout(
      delegate: _WindowToolbarLayout(
        rightOverlap: active
            ? (WindowChromeScope.reservedWidthOf(context) - outsideRightWidth)
                  .clamp(0.0, double.infinity)
            : 0,
        topOverlap: active
            ? (WindowChromeScope.heightOf(context) - topInset).clamp(
                0.0,
                double.infinity,
              )
            : 0,
      ),
      child: child,
    );
  }
}

class _WindowToolbarLayout extends SingleChildLayoutDelegate {
  const _WindowToolbarLayout({
    required this.rightOverlap,
    required this.topOverlap,
  });
  final double rightOverlap;
  final double topOverlap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final centeredX = (size.width - childSize.width) / 2;
    final safeRight = size.width - rightOverlap;
    if (topOverlap <= 0 || centeredX + childSize.width <= safeRight) {
      return Offset(centeredX, 0);
    }
    if (childSize.width <= safeRight) {
      return Offset(safeRight - childSize.width, 0);
    }
    // A narrow canvas keeps the toolbar below the captions, without shrinking
    // the image viewport or reducing the toolbar's touch targets.
    return Offset(centeredX, topOverlap + 4);
  }

  @override
  bool shouldRelayout(_WindowToolbarLayout oldDelegate) =>
      rightOverlap != oldDelegate.rightOverlap ||
      topOverlap != oldDelegate.topOverlap;
}
