import 'package:flutter/material.dart';
import 'library_toolbar.dart';

/// Shared desktop library dimensions from UIUX U1. The host owns persistence.
class LibraryShell extends StatelessWidget {
  const LibraryShell({
    super.key,
    required this.nav,
    required this.main,
    this.inspector,
    this.tray,
    this.selectionBar,
    this.navVisible,
    this.inspectorVisible,
    this.hasSelection = false,
    this.onCloseInspector,
    this.onOpenNav,
  });

  static const navWidth = 240.0;
  static const mainMinWidth = 560.0;
  static const inspectorWidth = 340.0;
  static const headerHeight = 62.0;
  static const filterHeight = 46.0;
  final Widget nav, main;
  final Widget? inspector, tray, selectionBar;
  final bool? navVisible, inspectorVisible;
  final bool hasSelection;
  final VoidCallback? onCloseInspector, onOpenNav;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final colors = Theme.of(context).colorScheme;
      final showInspector =
          inspector != null &&
          (inspectorVisible ??
              c.maxWidth >= navWidth + mainMinWidth + inspectorWidth);
      final showNav =
          navVisible ??
          c.maxWidth >=
              navWidth + mainMinWidth + (showInspector ? inspectorWidth : 0);
      Widget pane(Widget child, double width, {bool right = false}) => SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            border: Border(
              left: right
                  ? BorderSide(color: colors.outlineVariant)
                  : BorderSide.none,
              right: !right
                  ? BorderSide(color: colors.outlineVariant)
                  : BorderSide.none,
            ),
          ),
          child: child,
        ),
      );
      return Stack(
        children: [
          Row(
            children: [
              if (showNav) pane(nav, navWidth),
              Expanded(
                child: ColoredBox(
                  color: colors.surface,
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: main),
                          if (tray != null) tray!,
                        ],
                      ),
                      if (selectionBar != null)
                        Positioned(
                          left: 18,
                          right: 18,
                          bottom: 18 + (tray == null ? 0 : 76),
                          child: Center(child: selectionBar),
                        ),
                    ],
                  ),
                ),
              ),
              if (showInspector) pane(inspector!, inspectorWidth, right: true),
            ],
          ),
          if (!showInspector && inspector != null && hasSelection)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: inspectorWidth.clamp(0, c.maxWidth),
              child: Material(
                elevation: 12,
                color: colors.surfaceContainerLow,
                child: Stack(
                  children: [
                    Positioned.fill(child: inspector!),
                    if (onCloseInspector != null)
                      Positioned(
                        top: 17,
                        right: 146,
                        child: LibraryIconButton(
                          icon: 'x',
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          onPressed: onCloseInspector,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
