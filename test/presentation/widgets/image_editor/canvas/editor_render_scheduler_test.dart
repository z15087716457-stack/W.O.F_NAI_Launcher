import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';

void main() {
  testWidgets(
    'coalesces high-frequency stroke preview notifications to one per frame',
    (tester) async {
      final state = EditorState()..setCanvasSize(const Size(128, 128));
      addTearDown(state.dispose);

      var renderNotifications = 0;
      var previewNotifications = 0;
      state.renderNotifier.addListener(() {
        renderNotifications++;
      });
      state.strokePreviewNotifier.addListener(() {
        previewNotifications++;
      });

      state.startStroke(const Offset(1, 1));
      renderNotifications = 0;
      previewNotifications = 0;

      state.updateStroke(const Offset(2, 2));
      state.updateStroke(const Offset(3, 3));
      state.updateStroke(const Offset(4, 4));

      expect(state.currentStrokePoints, hasLength(4));
      expect(renderNotifications, 0);
      expect(previewNotifications, 0);

      await tester.pump();

      expect(renderNotifications, 0);
      expect(previewNotifications, 1);

      state.updateStroke(const Offset(5, 5));
      state.updateStroke(const Offset(6, 6));

      expect(state.currentStrokePoints, hasLength(6));
      expect(renderNotifications, 0);
      expect(previewNotifications, 1);

      await tester.pump();

      expect(renderNotifications, 0);
      expect(previewNotifications, 2);
    },
  );

  testWidgets(
    'endStroke flushes pending stroke preview before clearing preview',
    (tester) async {
      final state = EditorState()..setCanvasSize(const Size(128, 128));
      addTearDown(state.dispose);

      var renderNotifications = 0;
      final previewPointCounts = <int>[];
      state.renderNotifier.addListener(() {
        renderNotifications++;
      });
      state.strokePreviewNotifier.addListener(() {
        previewPointCounts.add(state.currentStrokePoints.length);
      });

      state.startStroke(const Offset(1, 1));
      renderNotifications = 0;
      previewPointCounts.clear();

      state.updateStroke(const Offset(2, 2));
      state.updateStroke(const Offset(3, 3));

      expect(state.currentStrokePoints, hasLength(3));
      expect(renderNotifications, 0);
      expect(previewPointCounts, isEmpty);

      state.endStroke();

      expect(renderNotifications, 0);
      expect(previewPointCounts, <int>[3, 0]);
      expect(state.currentStrokePoints, isEmpty);
      expect(state.isDrawing, isFalse);

      await tester.pump();

      expect(renderNotifications, 0);
      expect(previewPointCounts, <int>[3, 0]);
    },
  );

  testWidgets('cancelStroke clears a pending preview immediately', (
    tester,
  ) async {
    final state = EditorState()..setCanvasSize(const Size(128, 128));
    addTearDown(state.dispose);

    var renderNotifications = 0;
    final previewPointCounts = <int>[];
    state.renderNotifier.addListener(() {
      renderNotifications++;
    });
    state.strokePreviewNotifier.addListener(() {
      previewPointCounts.add(state.currentStrokePoints.length);
    });

    state.startStroke(const Offset(1, 1));
    renderNotifications = 0;
    previewPointCounts.clear();

    state.updateStroke(const Offset(2, 2));

    expect(state.currentStrokePoints, hasLength(2));
    expect(renderNotifications, 0);
    expect(previewPointCounts, isEmpty);

    state.cancelStroke();

    expect(renderNotifications, 0);
    expect(previewPointCounts, <int>[0]);
    expect(state.currentStrokePoints, isEmpty);
    expect(state.isDrawing, isFalse);

    await tester.pump();

    expect(renderNotifications, 0);
    expect(previewPointCounts, <int>[0]);
  });

  testWidgets('runBatch defers state toolNotifier until batch completion', (
    tester,
  ) async {
    final state = EditorState()..setCanvasSize(const Size(128, 128));
    addTearDown(state.dispose);

    final toolEvents = <String?>[];
    state.toolNotifier.addListener(() {
      toolEvents.add(state.toolNotifier.value);
    });

    state.runBatch(() {
      state.setToolById('rect_selection');

      expect(state.currentTool?.id, 'rect_selection');
      expect(state.toolNotifier.value, 'brush');
      expect(toolEvents, isEmpty);
    });

    expect(state.toolNotifier.value, 'rect_selection');
    expect(toolEvents, equals(['rect_selection']));
  });
}
