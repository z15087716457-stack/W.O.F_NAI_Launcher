import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../widgets/library/library_toolbar.dart';
import '../../generation/widgets/resize_handle.dart';

/// Three panes retain their positions when the block library overlays the stage.
class ExploreWorkbench extends StatelessWidget {
  const ExploreWorkbench({
    super.key,
    required this.editor,
    required this.stageBuilder,
    required this.inspector,
    required this.editorWidth,
    required this.inspectorWidth,
    required this.onEditorResize,
    required this.onInspectorResize,
    required this.onCloseInspector,
    this.inspectorVisible,
    this.blockLibrary,
  });

  final Widget editor, inspector;
  final VoidCallback onCloseInspector;
  final Widget Function(BuildContext context, bool inspectorVisible)
  stageBuilder;
  final double editorWidth, inspectorWidth;
  final bool? inspectorVisible;
  final ValueChanged<double> onEditorResize, onInspectorResize;
  final Widget? blockLibrary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final showInspector =
          inspectorVisible ??
          constraints.maxWidth >= editorWidth + 480 + inspectorWidth;
      // A manual open that cannot dock without crushing the editor below its
      // 352 floor floats over the stage edge, as the U1 library inspector does.
      final docked =
          showInspector &&
          constraints.maxWidth >=
              math.min(352.0, editorWidth) + 480 + inspectorWidth;
      final rightWidth = docked ? inspectorWidth : 0.0;
      final visibleEditorWidth = math.min(
        editorWidth,
        math.max(0.0, constraints.maxWidth - 480 - rightWidth),
      );
      // Reflow down to the 352 floor first; only narrower windows clip.
      final editorLayoutWidth = math.max(
        math.min(352.0, editorWidth),
        visibleEditorWidth,
      );
      final contentWidth = math.max(
        constraints.maxWidth,
        visibleEditorWidth + 480 + rightWidth,
      );
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: contentWidth,
          maxWidth: contentWidth,
          child: SizedBox(
            width: contentWidth,
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      key: const Key('style-explore-main-editor'),
                      width: visibleEditorWidth,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topLeft,
                          minWidth: editorLayoutWidth,
                          maxWidth: editorLayoutWidth,
                          child: SizedBox(
                            width: editorLayoutWidth,
                            child: editor,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        key: const Key('style-explore-stage'),
                        fit: StackFit.expand,
                        children: [stageBuilder(context, showInspector)],
                      ),
                    ),
                    if (docked)
                      SizedBox(
                        key: const Key('style-explore-inspector'),
                        width: inspectorWidth,
                        child: inspector,
                      ),
                  ],
                ),
                if (docked)
                  Positioned(
                    right: inspectorWidth - 4,
                    top: 0,
                    bottom: 0,
                    child: ResizeHandle(
                      key: const Key('style-explore-inspector-resize-handle'),
                      onDrag: (dx) => onInspectorResize(-dx),
                    ),
                  ),
                if (blockLibrary != null)
                  Positioned(
                    left: visibleEditorWidth,
                    top: 0,
                    bottom: 0,
                    width: contentWidth - visibleEditorWidth - rightWidth,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: blockLibrary!,
                      ),
                    ),
                  ),
                Positioned(
                  left: math.max(0, visibleEditorWidth - 4),
                  top: 0,
                  bottom: 0,
                  child: ResizeHandle(
                    key: const Key('style-explore-editor-resize-handle'),
                    onDrag: onEditorResize,
                  ),
                ),
                if (showInspector && !docked)
                  Positioned(
                    key: const Key('style-explore-inspector'),
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: math.min(
                      inspectorWidth,
                      contentWidth - visibleEditorWidth,
                    ),
                    child: Material(
                      elevation: 12,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: Stack(
                        children: [
                          Positioned.fill(child: inspector),
                          Positioned(
                            top: 12,
                            right: 146,
                            child: LibraryIconButton(
                              key: const Key('style-explore-inspector-close'),
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
            ),
          ),
        ),
      );
    },
  );
}
