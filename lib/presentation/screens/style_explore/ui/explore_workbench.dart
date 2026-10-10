import 'dart:math' as math;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../../generation/widgets/resize_handle.dart';
import 'explore_controls.dart';
import 'explore_style.dart';

/// The prototype's editor, stage and inspector remain independently resizable.
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
  final Widget Function(BuildContext, bool) stageBuilder;
  final double editorWidth, inspectorWidth;
  final ValueChanged<double> onEditorResize, onInspectorResize;
  final VoidCallback onCloseInspector;
  final bool? inspectorVisible;
  final Widget? blockLibrary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final visible =
          inspectorVisible ??
          size.maxWidth >= editorWidth + 480 + inspectorWidth;
      final dock =
          visible &&
          size.maxWidth >= math.min(352.0, editorWidth) + 480 + inspectorWidth;
      final right = dock ? inspectorWidth : 0.0;
      final left = math.min(
        editorWidth,
        math.max(0.0, size.maxWidth - 480 - right),
      );
      final editorLayout = math.max(math.min(352.0, editorWidth), left);
      final width = math.max(size.maxWidth, left + 480 + right);
      Widget pane() => DecoratedBox(
        decoration: BoxDecoration(
          color: ExploreStyle.panel(Theme.of(context)),
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: inspector,
      );
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: width,
          maxWidth: width,
          child: SizedBox(
            width: width,
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      key: const Key('style-explore-main-editor'),
                      width: left,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topLeft,
                          minWidth: editorLayout,
                          maxWidth: editorLayout,
                          child: SizedBox(width: editorLayout, child: editor),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        key: const Key('style-explore-stage'),
                        fit: StackFit.expand,
                        children: [stageBuilder(context, visible)],
                      ),
                    ),
                    if (dock)
                      SizedBox(
                        key: const Key('style-explore-inspector'),
                        width: right,
                        child: pane(),
                      ),
                  ],
                ),
                if (blockLibrary != null)
                  Positioned(
                    left: left,
                    top: 0,
                    bottom: 0,
                    width: width - left - right,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: blockLibrary,
                      ),
                    ),
                  ),
                Positioned(
                  left: math.max(0, left - 4),
                  top: 0,
                  bottom: 0,
                  child: ResizeHandle(
                    key: const Key('style-explore-editor-resize-handle'),
                    onDrag: onEditorResize,
                  ),
                ),
                if (dock)
                  Positioned(
                    right: right - 4,
                    top: 0,
                    bottom: 0,
                    child: ResizeHandle(
                      key: const Key('style-explore-inspector-resize-handle'),
                      onDrag: (dx) => onInspectorResize(-dx),
                    ),
                  ),
                if (visible && !dock)
                  Positioned(
                    key: const Key('style-explore-inspector'),
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: math.min(inspectorWidth, width - left),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .15),
                            blurRadius: 24,
                            offset: const Offset(-6, 0),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(child: pane()),
                          Positioned(
                            top: 12,
                            right: 146,
                            child: ExploreIconButton(
                              'x',
                              key: const Key('style-explore-inspector-close'),

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
