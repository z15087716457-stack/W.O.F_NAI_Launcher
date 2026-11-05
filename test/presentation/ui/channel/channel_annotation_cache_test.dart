import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_format.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_layer.dart';
import 'package:nai_launcher/presentation/ui/kit/app_visibility_scope.dart';

import '../gen/gen_test_harness.dart';

void main() {
  test('same-day checks use calendar dates across time representations', () {
    expect(
      ChannelFormat.sameDay(
        DateTime(2026, 10, 16),
        DateTime.utc(2026, 10, 16, 23, 59),
      ),
      isTrue,
    );
    expect(
      ChannelFormat.sameDay(
        DateTime(2026, 10, 16, 23, 59),
        DateTime(2026, 10, 17),
      ),
      isFalse,
    );
    expect(
      ChannelFormat.sameDay(DateTime(2025, 12, 31), DateTime(2026, 1, 1)),
      isFalse,
    );
    expect(
      ChannelFormat.sameDay(
        DateTime.utc(2024, 2, 29),
        DateTime(2024, 2, 29, 12),
      ),
      isTrue,
    );
  });

  testWidgets(
    'camera frames reuse annotations; date, locale, ruler and batches invalidate them',
    (tester) async {
      var batches = [
        ChannelBatch(
          id: 'a',
          rect: const Rect.fromLTWH(-416, 0, 832, 1216),
          time: DateTime(2026, 10, 16, 12),
          count: 2,
        ),
      ];
      var now = DateTime(2026, 10, 16, 23, 59);
      const base = ChannelSettings(seed: 7, motion: false);
      Future<ChannelBackdropPainter> pump({
        String locale = 'zh',
        bool ruler = true,
        double y = 0,
      }) async {
        await tester.pumpWidget(
          genApp(
            ChannelBackdrop(
              data: ChannelViewData(
                settings: base.copyWith(ruler: ruler),
                camera: ChannelCamera(offset: Offset(400, y), scale: .5),
                batches: batches,
                now: now,
              ),
            ),
            locale: locale,
          ),
        );
        return tester
                .widget<CustomPaint>(find.byKey(const Key('channel-backdrop')))
                .painter!
            as ChannelBackdropPainter;
      }

      final first = await pump();
      final moved = await pump(y: 50);
      expect(moved.labels, same(first.labels));
      expect(moved.days, same(first.days));
      expect(moved.names, same(first.names));
      expect(moved.labels.single, '12:00 · 2 张 · 最新');
      expect(moved.days.single, startsWith('今天'));
      now = DateTime(2026, 10, 17);
      final midnight = await pump(y: 50);
      expect(midnight.days.single, startsWith('昨天'));
      final english = await pump(locale: 'en');
      expect(english.days, isNot(midnight.days));
      expect(english.names, isNot(midnight.names));
      expect((await pump(ruler: false)).labels, isEmpty);
      final enabled = await pump();
      expect(enabled.labels.single, contains('2 张'));
      batches = [
        ChannelBatch(
          id: 'a',
          rect: batches.single.rect,
          time: now,
          count: 4,
          pending: true,
        ),
      ];
      final pending = await pump();
      expect(pending.labels.single, '生成中 · 4 张');
      expect(pending.days.single, startsWith('今天'));
    },
  );
  testWidgets('30 fps motion pauses when hidden and only repaints the scene', (
    tester,
  ) async {
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    final data = ChannelViewData(
      settings: const ChannelSettings(
        mode: ChannelMode.fixed,
        fixed: ChannelTheme.stars,
      ),
      camera: const ChannelCamera(offset: Offset(400, 80), scale: .5),
      batches: const [
        ChannelBatch(
          id: 'a',
          rect: Rect.fromLTWH(-416, 0, 832, 1216),
          count: 1,
        ),
      ],
      now: DateTime(2026, 11, 5),
    );
    final scene = find.byKey(
      const Key('channel-backdrop'),
      skipOffstage: false,
    );
    final annotations = find.byKey(const Key('channel-annotations'));
    RenderRepaintBoundary boundary(Finder layer) => tester.renderObject(
      find.ancestor(of: layer, matching: find.byType(RepaintBoundary)).first,
    );
    await tester.pumpWidget(
      genApp(
        AppVisibilityScope(
          visibility: visible,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: ChannelBackdrop(data: data),
          ),
        ),
      ),
    );
    final painter =
        tester.widget<CustomPaint>(scene).painter! as ChannelBackdropPainter;
    expect(painter.pass, ChannelPaintPass.scene);
    final sceneBoundary = boundary(scene);
    final staticBoundary = boundary(annotations);
    sceneBoundary.debugResetMetrics();
    staticBoundary.debugResetMetrics();

    await tester.pump(const Duration(milliseconds: 32));
    expect(painter.time.value, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(painter.time.value, closeTo(.033, .0001));
    await tester.pump(const Duration(milliseconds: 33));
    expect(sceneBoundary.debugAsymmetricPaintCount, greaterThan(0));
    expect(staticBoundary.debugAsymmetricPaintCount, 0);
    expect(staticBoundary.debugSymmetricPaintCount, 0);
    final phase = painter.time.value;
    visible.value = false;
    await tester.pump(const Duration(seconds: 1));
    expect(painter.time.value, phase);
    visible.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 33));
    expect(painter.time.value, closeTo(phase + .033, .0001));
    await tester.pumpWidget(const SizedBox());
  });
}
