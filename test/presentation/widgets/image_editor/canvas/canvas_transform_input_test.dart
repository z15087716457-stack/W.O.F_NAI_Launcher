import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/canvas_controller.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/input_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final degrees in [0.0, 15.0, 90.0, -30.0, 180.0, 270.0]) {
    for (final mirror in [false, true]) {
      for (final scale in [0.1, 1.0, 4.0]) {
        test(
          'input and display agree at rotation=$degrees mirror=$mirror scale=$scale',
          () {
            final controller = CanvasController()
              ..setScale(scale)
              ..setOffset(const Offset(83, -21))
              ..rotateRight(degrees: degrees);
            if (mirror) controller.toggleMirrorHorizontal();
            addTearDown(controller.dispose);
            const size = Size(320, 180);
            for (final point in [
              Offset.zero,
              const Offset(67, 99),
              const Offset(320, 180),
            ]) {
              final rendered = MatrixUtils.transformPoint(
                controller.getTransformMatrix(size),
                point,
              );
              expect(
                (controller.canvasToScreen(point, canvasSize: size) - rendered)
                    .distance,
                lessThan(1e-8),
              );
              expect(
                (controller.screenToCanvas(rendered, canvasSize: size) - point)
                    .distance,
                lessThan(1e-8),
              );
            }
          },
        );
      }
    }
  }

  test('brush receives the pixel visible under a rotated mirrored pointer', () {
    final state = EditorState(inpaint: true)
      ..initNewCanvas(const Size(128, 80));
    final focus = FocusNode();
    addTearDown(focus.dispose);
    addTearDown(state.dispose);
    state.canvasController
      ..setScale(2)
      ..setOffset(const Offset(30, 17))
      ..rotateRight(degrees: 90)
      ..toggleMirrorHorizontal();
    final handler = InputHandler(
      state: state,
      focusNode: focus,
      onStateChanged: () {},
    );
    const point = Offset(25, 36);
    final rendered = MatrixUtils.transformPoint(
      state.canvasController.getTransformMatrix(state.canvasSize),
      point,
    );
    handler.handlePointerDown(PointerDownEvent(position: rendered, buttons: 1));
    expect((state.currentStrokePoints.single - point).distance, lessThan(1e-8));
    state.cancelStroke();
  });

  test(
    'callers without canvas size retain the simple pan and zoom coordinates',
    () {
      final controller = CanvasController()
        ..setScale(2)
        ..setOffset(const Offset(10, 20))
        ..rotateRight(degrees: 90)
        ..toggleMirrorHorizontal();
      addTearDown(controller.dispose);
      expect(
        controller.canvasToScreen(const Offset(5, 8)),
        const Offset(20, 36),
      );
      expect(
        controller.screenToCanvas(const Offset(20, 36)),
        const Offset(5, 8),
      );
    },
  );
}
