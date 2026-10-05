import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/inpaint_outpaint_utils.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/canvas_controller.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/outpaint_edge_drag_overlay.dart';

Widget wrap(
  CanvasController controller, {
  OutpaintFrameResizeCommitted? commit,
  OutpaintEdgeDragPreviewChanged? preview,
  bool enabled = true,
  Size size = const Size(512, 512),
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: OutpaintEdgeDragOverlay(
      canvasSize: size,
      controller: controller,
      enabled: enabled,
      onPreviewChanged: preview,
      onFrameResizeCommitted: commit,
      onCommitted:
          (
            edges, {
            required horizontalSnapTarget,
            required verticalSnapTarget,
          }) async {},
    ),
  ),
);

void main() {
  late CanvasController controller;
  setUp(() {
    controller = CanvasController()
      ..setScale(.5)
      ..setOffset(const Offset(100, 100));
  });
  tearDown(() => controller.dispose());

  testWidgets('thin eight zones stay transparent until hovered', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(controller));
    for (final name in [
      'left',
      'right',
      'top',
      'bottom',
      'top_left',
      'top_right',
      'bottom_left',
      'bottom_right',
    ]) {
      final region = find.byKey(Key('outpaint_edge_$name'));
      expect(region, findsOneWidget);
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: region,
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.color!.a, 0);
      expect(decoration.boxShadow, isNull);
    }
    final right = find.byKey(const Key('outpaint_edge_right'));
    expect(tester.getSize(right).width, 8);
    expect(
      tester.getSize(find.byKey(const Key('outpaint_edge_top_left'))),
      const Size(12, 12),
    );
    expect(
      tester.widget<MouseRegion>(right).cursor,
      SystemMouseCursors.resizeLeftRight,
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(right));
    await tester.pump();
    expect(find.byKey(const Key('outpaint_highlight_right')), findsOneWidget);
    await mouse.moveTo(const Offset(40, 40));
    await tester.pump();
    expect(find.byKey(const Key('outpaint_highlight_right')), findsNothing);
    await mouse.removePointer();
  });

  final directions = <String, Offset>{
    'left': const Offset(-48, 0),
    'right': const Offset(48, 0),
    'top': const Offset(0, -48),
    'bottom': const Offset(0, 48),
    'top_left': const Offset(-48, -48),
    'top_right': const Offset(48, -48),
    'bottom_left': const Offset(-48, 48),
    'bottom_right': const Offset(48, 48),
  };
  for (final entry in directions.entries) {
    testWidgets(
      '${entry.key} converts scaled drag and snaps preview and commit identically',
      (tester) async {
        OutpaintFrameDelta? applied;
        OutpaintHorizontalSnapTarget? horizontal;
        OutpaintVerticalSnapTarget? vertical;
        await tester.pumpWidget(
          wrap(
            controller,
            commit:
                (
                  delta, {
                  required horizontalSnapTarget,
                  required verticalSnapTarget,
                }) async {
                  applied = delta;
                  horizontal = horizontalSnapTarget;
                  vertical = verticalSnapTarget;
                },
          ),
        );
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(Key('outpaint_edge_${entry.key}'))),
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveBy(entry.value);
        await tester.pump();
        final horizontalChange = entry.value.dx == 0 ? 0 : 128;
        final verticalChange = entry.value.dy == 0 ? 0 : 128;
        expect(
          find.text('${512 + horizontalChange} × ${512 + verticalChange}'),
          findsOneWidget,
        );
        expect(applied, isNull);
        await gesture.up();
        await tester.pump();
        expect(
          (applied!.left, applied!.right, applied!.top, applied!.bottom),
          (
            entry.value.dx < 0 ? 128 : 0,
            entry.value.dx > 0 ? 128 : 0,
            entry.value.dy < 0 ? 128 : 0,
            entry.value.dy > 0 ? 128 : 0,
          ),
        );
        expect(
          horizontal,
          entry.value.dx < 0
              ? OutpaintHorizontalSnapTarget.left
              : OutpaintHorizontalSnapTarget.right,
        );
        expect(
          vertical,
          entry.value.dy < 0
              ? OutpaintVerticalSnapTarget.top
              : OutpaintVerticalSnapTarget.bottom,
        );
        expect(find.byKey(const Key('outpaint_drag_size')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final example in [
    (const Offset(-40, 0), -64),
    (const Offset(-600, 0), -448),
    (const Offset(2500, 0), 3584),
  ]) {
    testWidgets(
      'inward or outward ${example.$1} respects 64..4096 dimensions',
      (tester) async {
        OutpaintFrameDelta? applied;
        await tester.pumpWidget(
          wrap(
            controller,
            commit:
                (
                  delta, {
                  required horizontalSnapTarget,
                  required verticalSnapTarget,
                }) async {
                  applied = delta;
                },
          ),
        );
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('outpaint_edge_right'))),
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveBy(example.$1);
        await tester.pump();
        expect(find.text('${512 + example.$2} × 512'), findsOneWidget);
        await gesture.up();
        await tester.pump();
        expect(applied!.right, example.$2);
      },
    );
  }

  testWidgets(
    'held pointer never commits on idle, including outside the viewport',
    (tester) async {
      var commits = 0;
      await tester.pumpWidget(
        wrap(
          controller,
          commit:
              (
                delta, {
                required horizontalSnapTarget,
                required verticalSnapTarget,
              }) async {
                commits++;
              },
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('outpaint_edge_left'))),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(const Offset(-200, 230));
      await tester.pump(const Duration(seconds: 2));
      expect(commits, 0);
      expect(find.byKey(const Key('outpaint_drag_size')), findsOneWidget);
      await gesture.up();
      await tester.pump();
      expect(commits, 1);
    },
  );
  testWidgets('cancel, sub-step and return-to-origin do not commit', (
    tester,
  ) async {
    var commits = 0;
    await tester.pumpWidget(
      wrap(
        controller,
        commit:
            (
              delta, {
              required horizontalSnapTarget,
              required verticalSnapTarget,
            }) async {
              commits++;
            },
      ),
    );
    final start = tester.getCenter(
      find.byKey(const Key('outpaint_edge_right')),
    );
    var gesture = await tester.startGesture(
      start,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(32, 0));
    await tester.pump();
    await gesture.cancel();
    await tester.pump();
    expect(commits, 0);
    expect(find.byKey(const Key('outpaint_drag_size')), findsNothing);
    gesture = await tester.startGesture(start, kind: PointerDeviceKind.mouse);
    await gesture.moveBy(const Offset(15, 0));
    await gesture.up();
    await tester.pump();
    expect(commits, 0);
    gesture = await tester.startGesture(start, kind: PointerDeviceKind.mouse);
    await gesture.moveBy(const Offset(32, 0));
    await gesture.moveTo(start);
    await gesture.up();
    await tester.pump();
    expect(commits, 0);
  });
  testWidgets('pending commit freezes geometry and blocks a second resize', (
    tester,
  ) async {
    final pending = Completer<void>();
    var commits = 0;
    Future<void> commit(
      OutpaintFrameDelta delta, {
      required OutpaintHorizontalSnapTarget horizontalSnapTarget,
      required OutpaintVerticalSnapTarget verticalSnapTarget,
    }) async {
      commits++;
      await pending.future;
    }

    await tester.pumpWidget(wrap(controller, commit: commit));
    await tester.drag(
      find.byKey(const Key('outpaint_edge_right')),
      const Offset(32, 0),
    );
    await tester.pump();
    expect(commits, 1);
    expect(find.text('576 × 512'), findsOneWidget);
    await tester.pumpWidget(
      wrap(controller, commit: commit, size: const Size(576, 512)),
    );
    expect(find.text('576 × 512'), findsOneWidget);
    expect(find.byKey(const Key('outpaint_edge_right')), findsNothing);
    pending.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('outpaint_edge_right')), findsOneWidget);
    expect(find.byKey(const Key('outpaint_drag_size')), findsNothing);
  });
  testWidgets('preview notification ignores moves within one snapped step', (
    tester,
  ) async {
    final previews = <int>[];
    await tester.pumpWidget(
      wrap(controller, preview: (e) => previews.add(e.right)),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('outpaint_edge_right'))),
    );
    await gesture.moveBy(const Offset(17, 0));
    await gesture.moveBy(const Offset(1, 0));
    await gesture.moveBy(const Offset(31, 0));
    await gesture.up();
    await tester.pump();
    expect(previews, [64, 128]);
  });
  testWidgets('offscreen edge is not replaced with a floating handle', (
    tester,
  ) async {
    controller.setOffset(const Offset(-20, 100));
    await tester.pumpWidget(wrap(controller));
    expect(find.byKey(const Key('outpaint_edge_left')), findsNothing);
    expect(find.byKey(const Key('outpaint_edge_right')), findsOneWidget);
  });
  testWidgets(
    'disabled, rotated and mirrored canvases expose no resize zones',
    (tester) async {
      await tester.pumpWidget(wrap(controller, enabled: false));
      expect(find.byKey(const Key('outpaint_edge_right')), findsNothing);
      controller.rotateRight();
      await tester.pumpWidget(wrap(controller));
      expect(find.byKey(const Key('outpaint_edge_right')), findsNothing);
      controller.rotateLeft();
      controller.toggleMirrorHorizontal();
      await tester.pump();
      expect(find.byKey(const Key('outpaint_edge_right')), findsNothing);
    },
  );
  testWidgets(
    'resize hit zones do not suppress painting six pixels inside an edge',
    (tester) async {
      expect(
        OutpaintEdgeDragOverlay.isResizeInteractionPoint(
          localPosition: const Offset(356, 228),
          viewportSize: const Size(800, 600),
          canvasSize: const Size(512, 512),
          controller: controller,
        ),
        isTrue,
      );
      expect(
        OutpaintEdgeDragOverlay.isResizeInteractionPoint(
          localPosition: const Offset(350, 228),
          viewportSize: const Size(800, 600),
          canvasSize: const Size(512, 512),
          controller: controller,
        ),
        isFalse,
      );
      await tester.pumpWidget(wrap(controller));
    },
  );
  testWidgets('disposal removes active global pointer route', (tester) async {
    var commits = 0;
    await tester.pumpWidget(
      wrap(
        controller,
        commit:
            (
              delta, {
              required horizontalSnapTarget,
              required verticalSnapTarget,
            }) async {
              commits++;
            },
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('outpaint_edge_right'))),
    );
    await gesture.moveBy(const Offset(32, 0));
    await tester.pumpWidget(const SizedBox());
    await gesture.up();
    await tester.pump();
    expect(commits, 0);
    expect(tester.takeException(), isNull);
  });
}
