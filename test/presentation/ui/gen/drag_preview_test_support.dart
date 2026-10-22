import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/common/drag_preview_divider.dart';

class DragCounts {
  int builds = 0, layouts = 0;
  (int, int) get snapshot => (builds, layouts);
}

class DragCountProbe extends StatelessWidget {
  const DragCountProbe(this.counts, {super.key, this.child});
  final DragCounts counts;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    counts.builds++;
    return _LayoutProbe(counts, child: child ?? const SizedBox.expand());
  }
}

class _LayoutProbe extends SingleChildRenderObjectWidget {
  const _LayoutProbe(this.counts, {super.child});
  final DragCounts counts;
  @override
  RenderObject createRenderObject(BuildContext context) => _CountLayout(counts);
}

class _CountLayout extends RenderProxyBox {
  _CountLayout(this.counts);
  final DragCounts counts;
  @override
  void performLayout() {
    counts.layouts++;
    super.performLayout();
  }
}

DragPreviewPainter? previewPainter(WidgetTester t, String key) {
  final paints = find.descendant(
    of: find.byKey(Key('$key-preview')),
    matching: find.byType(CustomPaint),
  );
  if (paints.evaluate().isEmpty) return null;
  return t.widget<CustomPaint>(paints).painter! as DragPreviewPainter;
}

Future<TestGesture> beginDividerDrag(WidgetTester t, String key) async {
  final g = await t.startGesture(
    t.getCenter(find.byKey(Key(key))),
    kind: PointerDeviceKind.mouse,
  );
  // Recognize, then return to the committed position (mouse slop may be
  // included in the first update). Subsequent steps have a zero-net origin.
  await g.moveBy(const Offset(24, 0));
  await t.pump();
  await g.moveBy(const Offset(-24, 0));
  await t.pump();
  expect(previewPainter(t, key), isNotNull);
  return g;
}

Future<void> cancelDividerDrag(
  WidgetTester t,
  TestGesture g,
  String key, {
  required bool escape,
}) async {
  if (escape) {
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    // Further updates and release of the already-cancelled pointer are ignored.
    await g.moveBy(const Offset(30, 0));
    await g.up();
  } else {
    await g.cancel();
  }
  await t.pumpAndSettle();
  expect(previewPainter(t, key), isNull);
}

/// Real light/dark raster smoke without recording or changing any golden.
Future<void> checkPreviewPaint(WidgetTester t, String key) async {
  final painter = previewPainter(t, key)!;
  expect(painter.color.a, closeTo(.8, .001));
  final overlay = find.byKey(Key('$key-preview'));
  final region = find.descendant(
    of: overlay,
    matching: find.byType(MouseRegion),
  );
  expect(t.widget<MouseRegion>(region).cursor, SystemMouseCursors.resizeColumn);
  // The pointer is well outside the original 8px hit area at this point.
  expect(
    RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
    SystemMouseCursors.resizeColumn,
  );
  final boundary = find.descendant(
    of: overlay,
    matching: find.byType(RepaintBoundary),
  );
  await t.runAsync(() async {
    final image = await t
        .renderObject<RenderRepaintBoundary>(boundary)
        .toImage();
    final bytes = (await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    ))!;
    final x = painter.position.floor().clamp(0, image.width - 1);
    for (final y in [0, image.height ~/ 2, image.height - 1]) {
      final offset = (y * image.width + x) * 4;
      expect(bytes.getUint8(offset + 3), closeTo(204, 1));
      expect(bytes.getUint8(offset), closeTo(painter.color.r * 255, 2));
      expect(bytes.getUint8(offset + 1), closeTo(painter.color.g * 255, 2));
      expect(bytes.getUint8(offset + 2), closeTo(painter.color.b * 255, 2));
    }
    image.dispose();
  });
}
