import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    this.inspectorVisible,
    this.blockLibrary,
  });

  final Widget editor, inspector;
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
      final rightWidth = showInspector ? inspectorWidth : 0.0;
      final visibleEditorWidth = math.min(
        editorWidth,
        math.max(0.0, constraints.maxWidth - 480 - rightWidth),
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
                          minWidth: editorWidth,
                          maxWidth: editorWidth,
                          child: SizedBox(width: editorWidth, child: editor),
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
                    if (showInspector)
                      SizedBox(
                        key: const Key('style-explore-inspector'),
                        width: inspectorWidth,
                        child: inspector,
                      ),
                  ],
                ),
                if (showInspector)
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
              ],
            ),
          ),
        ),
      );
    },
  );
}
