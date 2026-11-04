import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_scroll_behavior.dart';

Future<ScrollPosition> _list(WidgetTester tester, {int count = 20}) async {
  await tester.pumpWidget(
    MaterialApp(
      scrollBehavior: const StudioScrollBehavior(),
      home: Center(
        child: SizedBox(
          height: 200,
          width: 200,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: count,
            itemExtent: 40,
            itemBuilder: (_, i) => Text('Row $i'),
          ),
        ),
      ),
    ),
  );
  return tester.state<ScrollableState>(find.byType(Scrollable)).position;
}

void main() {
  final mac = TargetPlatformVariant.only(TargetPlatform.macOS);

  testWidgets('a short macOS list stays still during a two-finger pull', (
    tester,
  ) async {
    final position = await _list(tester, count: 2);
    final point = tester.getCenter(find.byType(Scrollable));
    final trackpad = await tester.createGesture(
      kind: PointerDeviceKind.trackpad,
    );
    await trackpad.panZoomStart(point);
    await trackpad.moveBy(const Offset(0, 12));
    await trackpad.moveBy(const Offset(0, 80));
    expect(position.pixels, 0);
    await trackpad.up();
    await tester.pumpAndSettle();
    expect(position.pixels, 0);
  }, variant: mac);

  testWidgets(
    'macOS resists the first pull past either edge and settles back',
    (tester) async {
      final position = await _list(tester);
      final point = tester.getCenter(find.byType(Scrollable));
      for (final direction in [1.0, -1.0]) {
        final edge = direction > 0
            ? position.minScrollExtent
            : position.maxScrollExtent;
        position.jumpTo(edge + direction * 60);
        final trackpad = await tester.createGesture(
          kind: PointerDeviceKind.trackpad,
        );
        await trackpad.panZoomStart(point);
        await trackpad.moveBy(Offset(0, direction * 20));
        final before = position.pixels;
        final distance = (before - edge).abs();
        await trackpad.moveBy(Offset(0, direction * (distance + 80)));
        final beyond = direction * (edge - position.pixels);
        expect(beyond, greaterThan(0));
        expect(
          beyond,
          lessThan(40),
          reason: 'one trackpad event crossed the edge by 80 px',
        );
        await trackpad.up();
        await tester.pumpAndSettle();
        expect(position.pixels, closeTo(edge, .01));
      }
    },
    variant: mac,
  );

  testWidgets(
    'edge resistance is consistent for grouped and fine-grained trackpad updates',
    (tester) async {
      final position = await _list(tester);
      final point = tester.getCenter(find.byType(Scrollable));
      Future<double> pull(int updates) async {
        position.jumpTo(60);
        final trackpad = await tester.createGesture(
          kind: PointerDeviceKind.trackpad,
        );
        await trackpad.panZoomStart(point);
        await trackpad.moveBy(const Offset(0, 20));
        for (var i = 0; i < updates; i++) {
          await trackpad.moveBy(Offset(0, 460 / updates));
        }
        final beyond = -position.pixels;
        await trackpad.up();
        await tester.pumpAndSettle();
        return beyond;
      }

      final coarse = await pull(1);
      final fine = await pull(46);
      expect(coarse, greaterThan(0));
      expect(coarse, closeTo(fine, 1));
    },
    variant: mac,
  );

  testWidgets(
    'a fast two-finger scroll coasts until the trackpad sends its stop signal',
    (tester) async {
      final position = await _list(tester, count: 200);
      final point = tester.getCenter(find.byType(Scrollable));
      final trackpad = await tester.createGesture(
        kind: PointerDeviceKind.trackpad,
      );
      await trackpad.panZoomStart(point);
      for (var i = 1; i <= 12; i++) {
        await trackpad.moveBy(
          const Offset(0, -10),
          timeStamp: Duration(milliseconds: i * 8),
        );
        await tester.pump(const Duration(milliseconds: 8));
      }
      final release = position.pixels;
      await trackpad.up(timeStamp: const Duration(milliseconds: 100));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(position.pixels, greaterThan(release));
      await tester.sendEventToBinding(
        PointerScrollInertiaCancelEvent(
          position: point,
          kind: PointerDeviceKind.trackpad,
        ),
      );
      final stopped = position.pixels;
      await tester.pump(const Duration(milliseconds: 150));
      expect(position.pixels, stopped);
    },
    variant: mac,
  );

  testWidgets('Windows lists keep their clamped bounds', (tester) async {
    final position = await _list(tester);
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.trackpad,
    );
    await gesture.panZoomStart(tester.getCenter(find.byType(Scrollable)));
    await gesture.moveBy(const Offset(0, 160));
    expect(position.pixels, 0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(position.pixels, 0);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets(
    'wheel ticks keep their distance and stop at both macOS list edges',
    (tester) async {
      final position = await _list(tester);
      final point = tester.getCenter(find.byType(Scrollable));
      Future<void> wheel(double dy) => tester.sendEventToBinding(
        PointerScrollEvent(position: point, scrollDelta: Offset(0, dy)),
      );
      await wheel(23);
      expect(position.pixels, 23);
      await wheel(1000);
      expect(position.pixels, 600);
      await wheel(20);
      expect(position.pixels, 600);
      await wheel(-1000);
      expect(position.pixels, 0);
    },
    variant: mac,
  );
}
